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

    newChannel.properties.url =
      type: 'string'
      enum: _.pluck channel.application.resources, 'url'

    form =
      key: 'url'
      title: 'Endpoint'
      titleMap: []

    _.each channel.application.resources, (resource) =>
      form.titleMap.push {value: resource.url, name: resource.displayName}

    newForm.push form

    _.each channel.application.resources, (resource) =>
      newForm.push
        type: "help"
        helpvalue: "#{resource.httpMethod.toLocaleUpperCase()} #{resource.url}"
        condition: "model.url === '#{resource.url}'"

      _.each resource.params, (param) =>
        newName = "#{resource.url}##{param.name}"
        newForm.push @convertFormParam param, resource.url
        newChannel.properties[newName] = @convertParam param

    @writeOutput newChannel
    @writeForm newForm

  convertParam: (param) =>
    resourceParam =
      type: param.type
      description: param.displayName
      required: param.required

  convertFormParam: (param, url) =>
    formParam =
      key: "#{url}##{param.name}"
      title: param.displayName
      condition: "model.url === '#{url}'"

    if param.hidden?
      formParam.type = 'hidden'
      formParam.notitle = true

    formParam

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
