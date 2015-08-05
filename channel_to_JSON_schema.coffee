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

  channel: =>
    JSON.parse fs.readFileSync @channelFile

  run: =>
    channel = @channel()
    messageSchema = @getMessageSchema channel.application.resources
    form = @getForm channel.application.resources

    @writeMessageSchema messageSchema
    @writeForm form

  writeMessageSchema: (messageSchema) =>
    prettyMessageSchema = JSON.stringify(messageSchema, null, 2)
    fs.writeFileSync @messageSchemaFile, prettyMessageSchema
    debug 'message schema:', prettyMessageSchema

  writeForm: (form) =>
    prettyForm = JSON.stringify(form, null, 2)
    fs.writeFileSync @formFile, prettyForm
    debug 'form:', prettyForm

  getMessageSchema : (resources)=>
    subschemas = _.pluck resources, 'subschema'
    messageSchema =
      type: 'object'
      properties:
        subschema:
          type: "string"
          enum : subschemas

    _.each subschemas, (subschema) =>
      actionProperties = @getSubschemaProperties resources, subschema
      messageSchema.properties[subschema] =
        type: "object"
        properties: actionProperties

    messageSchema

  getForm: (resources) =>
    form = [
      key: 'subschema'
      title: 'Action'
      titleMap: @getSubschemaTitleMap resources
    ]

    resourceForms = _.flatten( _.map resources, @getFormFromResource )

    form.concat resourceForms

  getFormFromResource: (resource) =>
    form = [
      key: "#{resource.subschema}"
      notitle: true
      type: 'hidden'
    ]

    _.each resource.params, (param) =>
      form.push(@getFormFromParam resource.subschema, param)

    form

  getFormFromParam: (subschema, param) =>
    formParam =
      key: "#{subschema}.#{@sanitizeParam param.name}"
      title: param.displayName
      condition: "model.subschema === '#{subschema}'"
      required: param.required

    if param.hidden?
      formParam.type = 'hidden'
      formParam.notitle = true

    formParam

  getSubschemaTitleMap: (resources) =>
    _.map resources, (resource) =>
      value: resource.subschema, name: resource.displayName

  getSubschemaProperties: (resources, subschema) =>
    resource = _.findWhere resources, subschema: subschema
    properties = {}
    _.each resource.params, (param) =>
      properties["#{@sanitizeParam param.name}"] = @convertParam param

    properties

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
  .parse process.argv

commander.help() unless commander.infile?

converter = new ParseChannelSchemaToJSONSchema()
converter.run()
