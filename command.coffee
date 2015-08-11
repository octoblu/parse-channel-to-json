#!/usr/bin/env coffee

fs = require 'fs'
_  = require 'lodash'
commander = require 'commander'
debug = require('debug')('channel-to-json-schema')

ChannelToJsonSchema = require './channel-to-json-schema'
class ParseChannelSchemaToJSONSchema
  # constructor: (@channelFile, @messageSchemaFile, @formFile, @proxyGeneratorFile) ->
  #
  # run: =>
  #   channel = JSON.parse fs.readFileSync @channelFile
  #   messageSchema = @getMessageSchema channel.application.resources
  #   form = @getForm channel.application.resources
  #
  #   @writeMessageSchema messageSchema
  #   @writeForm form
  #
  # writeMessageSchema: (messageSchema) =>
  #   prettyMessageSchema = JSON.stringify(messageSchema, null, 2)
  #   fs.writeFileSync @messageSchemaFile, prettyMessageSchema
  #   debug 'message schema:', prettyMessageSchema
  #
  # writeForm: (form) =>
  #   prettyForm = JSON.stringify(form, null, 2)
  #   fs.writeFileSync @formFile, prettyForm
  #   debug 'form:', prettyForm
  #
  # sanitizeUrl: (url) =>
  #   url.replace(/\./g, '-')
  #
  # writeOutput: (channel) =>
  #   prettyChannel = JSON.stringify channel, null, 2
  #   fs.writeFileSync @messageSchemaFile, prettyChannel
  #   debug 'channel output:', prettyChannel
  #
  # writeForm: (form) =>
  #   prettyForm = JSON.stringify form, null, 2
  #   fs.writeFileSync @formFile, prettyForm
  #   debug 'form output:', prettyForm

commander
  .version 0.1
  .option '-i, --infile [path]',  'Path to the channel file to input'
  .option '-j, --json-schema [path]', 'Path to the json schema file to output'
  .option '-f, --form [path]',  'Path to the schema form file to output'
  .option '-p, --proxy-generator-file [path]',  'Path to the proxy generator file to output'
  .parse process.argv

commander.help() unless commander.infile?

channelConverter = new ChannelToJsonSchema()

channel = JSON.parse fs.readFileSync(commander.infile)

console.log JSON.stringify channelConverter.transform(channel), null, 2
