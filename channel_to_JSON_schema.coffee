#!/usr/bin/env coffee

fs = require 'fs'
_  = require 'lodash'
commander = require 'commander'
debug = require('debug')('channel-to-json-schema')

class ParseChannelSchemaToJSONSchema
  constructor: ->
    @channel_infile = commander.infile
    @messageSchemaFile = commander.outfile
    @formFile = commander.form
    @channelConfigFile = commander.channelConfig

  channel: =>
    JSON.parse fs.readFileSync @channel_infile

  run2: =>
    channel = @channel()
    messageSchema = @getMessageSchema channel.application.resources
    form = @getForm channel.application.resources
    channelConfig = @getChannelConfig channel

    @writeMessageSchema messageSchema
    @writeForm form
    @writeChannelConfig channelConfig

  writeMessageSchema: (messageSchema) =>
    prettyMessageSchema = JSON.stringify(messageSchema, null, 2)
    fs.writeFileSync @messageSchemaFile, prettyMessageSchema
    debug 'message schema:', prettyMessageSchema

  writeForm: (form) =>
    prettyForm = JSON.stringify(form, null, 2)
    fs.writeFileSync @formFile, prettyForm
    debug 'form:', prettyForm

  writeChannelConfig: (channelConfig) =>
    prettyChannelConfig = JSON.stringify(channelConfig, null, 2)
    fs.writeFileSync @channelConfigFile, prettyChannelConfig
    debug 'form:', prettyChannelConfig

  getMessageSchema : (resources)=>
    actions = _.pluck resources, 'action'
    messageSchema =
      type: 'object'
      properties:
          action:
            type: "string"
            enum : actions

    _.each actions, (action) =>
      actionProperties = @getActionProperties resources, action
      messageSchema.properties[action] =
        type: "object"
        properties: actionProperties

    messageSchema

  getForm: (resources) =>
    form = _.map resources, @getFormFromResource
    actionForm =
      key: 'action'
      title: 'Action'
      titleMap: @getActionTitleMap resources

    form.unshift actionForm

    form

  getFormFromResource: (resource) =>
    key: "#{resource.action}"
    notitle: true
    condition: "model.action === '#{resource.action}'"


  getActionTitleMap: (resources) =>
    _.map resources, (resource) =>
      value: resource.action, name: resource.displayName

  getActionProperties: (resources, action) =>
    resource = _.findWhere resources, action: action
    properties = {}
    _.each resource.params, (param) =>
      properties["#{@sanitizeParam param.name}"] = @convertParam param

    properties

  getChannelConfig: =>
    "I'm empty"
  run: =>
    newForm = []
    newChannel =
      type: 'object'
      properties: {}
    channel = @channel()

    _.each channel.application.resources, (resource) =>
      resource.method = resource.httpMethod.toLocaleUpperCase()

    newChannel.properties.endpoint =
      type: 'string'
      enum: _.map channel.application.resources, (resource) =>
        "#{resource.method}-#{resource.url}"

    newChannel.properties.url =
      type: 'string'
      required: true
      enum: _.uniq _.pluck channel.application.resources, 'url'

    newChannel.properties.method =
      type: 'string'
      required: true
      enum: _.uniq _.pluck channel.application.resources, 'method'

    form =
      key: 'endpoint'
      title: 'Endpoint'
      titleMap: []

    _.each channel.application.resources, (resource) =>
      form.titleMap.push {value: "#{resource.method}-#{resource.url}", name: resource.displayName}

    newForm.push form

    _.each channel.application.resources, (resource) =>
      newForm.push
        type: "help"
        helpvalue: "#{resource.method.toLocaleUpperCase()} #{resource.url}"
        condition: "model.url === '#{resource.url}' && model.method === '#{resource.method}'"

      _.each resource.params, (param) =>
        newName = "#{@sanitizeParam param.name}"
        newForm.push @convertFormParam param, resource.url, resource.method
        newChannel.properties[newName] = @convertParam param

    @writeOutput newChannel
    @writeForm newForm

  convertParam: (param) =>
    resourceParam =
      type: param.type
      description: param.displayName
      required: param.required

  convertFormParam: (param, url, method) =>
    formParam =
      key: "#{@sanitizeParam param.name}"
      title: param.displayName
      condition: "model.url === '#{url}' && model.method === '#{method}'"

    if param.hidden?
      formParam.type = 'hidden'
      formParam.notitle = true

    formParam

  sanitizeUrl: (url) =>
    url.replace(/\./g, '-')

  sanitizeParam: (param) =>
    param.replace(/^:/, '')

  writeOutput: (channel) =>
    prettyChannel = JSON.stringify channel, null, 2
    fs.writeFileSync @messageSchemaFile, prettyChannel
    debug 'channel output:', prettyChannel

  writeForm: (form) =>
    prettyForm = JSON.stringify form, null, 2
    fs.writeFileSync @formFile, prettyForm
    debug 'form output:', prettyForm

commander
  .version 0.1
  .option('-i, --infile [path]',  'Path to the channel file to input')
  .option('-o, --outfile [path]',  'Path to the channel file to output')
  .option('-f, --form [path]',  'Path to the schema form file to output')
  .option('-c, --channel-config [path]',  'Path to the channel-config file to output')
  .parse(process.argv);

commander.help() unless commander.infile?

converter = new ParseChannelSchemaToJSONSchema channel_infile: commander.infile?,
  messageSchemaFile: commander.outfile?
converter.run2()
