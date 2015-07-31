#!/usr/bin/env coffee

fs = require 'fs'
_  = require 'lodash'
commander = require 'commander'
debug = require('debug')('channel-to-json-schema')

class ParseChannelSchemaToJSONSchema
  constructor: ->
    @channelFile = commander.infile
    @messageSchemaFile = commander.outfile
    @formFile = commander.form
    @channelConfigFile = commander.channelConfig

  channel: =>
    JSON.parse fs.readFileSync @channelFile

  run: =>
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
    debug 'channel config:', prettyChannelConfig

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
    form = [
      key: 'action'
      title: 'Action'
      titleMap: @getActionTitleMap resources
    ]

    resourceForms = _.flatten( _.map resources, @getFormFromResource )

    form.concat resourceForms

  getFormFromResource: (resource) =>
    form = [
      key: "#{resource.action}"
      notitle: true
      type: 'hidden'
    ]

    _.each resource.params, (param) =>
      form.push(@getFormFromParam resource.action, param)

    form

  getFormFromParam: (action, param) =>
    formParam =
      key: "#{action}.#{@sanitizeParam param.name}"
      title: param.displayName
      condition: "model.action === '#{action}'"
      required: param.required

    if param.hidden?
      formParam.type = 'hidden'
      formParam.notitle = true

    formParam


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
    "I'm empty. I really should be doing something with all the http data"

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
  .option '-i, --infile [path]',  'Path to the channel file to input'
  .option '-o, --outfile [path]',  'Path to the channel file to output'
  .option '-f, --form [path]',  'Path to the schema form file to output'
  .option '-c, --channel-config [path]',  'Path to the channel-config file to output'
  .parse process.argv

commander.help() unless commander.infile?

converter = new ParseChannelSchemaToJSONSchema()
converter.run()
