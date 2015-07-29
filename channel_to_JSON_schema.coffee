#!/usr/bin/env coffee

#{
#    "type": "object",
#    "properties": {
#      "on": {
#        "type": "boolean",
#        "required": true,
#        "default": false
#      },
#      "color": {
#        "type": "string",
#        "required": true
#      }
#    }
#  }


fs = require 'fs'
_  = require 'lodash'
commander = require 'commander'
debug = require('debug')('channel-to-json-schema')

class ParseChannelSchemaToJSONSchema
  constructor: () ->
    @channel_infile = commander.infile
    @channel_outfile = commander.outfile
    @channel_form_outfile = commander.form

  channel: =>
    JSON.parse fs.readFileSync @channel_infile

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
        newName = "#{resource.method}-#{@sanitizeUrl(resource.url)}##{param.name}"
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
      key: "#{method}-#{@sanitizeUrl(url)}##{param.name}"
      title: param.displayName
      condition: "model.url === '#{url}' && model.method === '#{method}'"

    if param.hidden?
      formParam.type = 'hidden'
      formParam.notitle = true

    formParam

  sanitizeUrl: (url) =>
    url.replace(/\./g, '-')

  writeOutput: (channel) =>
    prettyChannel = JSON.stringify channel, null, 2
    fs.writeFileSync @channel_outfile, prettyChannel
    debug 'channel output:', prettyChannel

  writeForm: (form) =>
    prettyForm = JSON.stringify form, null, 2
    fs.writeFileSync @channel_form_outfile, prettyForm
    debug 'form output:', prettyForm

commander
  .version 0.1
  .option('-i, --infile [path]',  'Path to the channel file to input')
  .option('-o, --outfile [path]',  'Path to the channel file to output')
  .option('-f, --form [path]',  'Path to the schema form file to output')
  .parse(process.argv);

commander.help() unless commander.infile?

converter = new ParseChannelSchemaToJSONSchema channel_infile: commander.infile?,
  channel_outfile: commander.outfile?
converter.run()
