#!/usr/bin/env coffee
fs = require 'fs'
_  = require 'lodash'
commander = require 'commander'

class ParseChannelSchemaToJSONSchema
  constructor: (options={}) ->
    @channel_filename = options.channel_filename

  channel: =>
    JSON.parse fs.readFileSync @channel_filename

  run: =>
    channel = @channel()
    matches = []

    _.each channel.application.resources, (resource) =>
      unless resource.params
        resource.params = []
      @names = _.pluck resource.params, 'name'
      _.each @names, (name) =>
        resource.properties = resource.params.push resource.params[name]
        resource.properties[name] = {'displayName': resource.params.displayName,'type': resource.params.type, 'style': resource.params.style}
        console.log(resource)

    prettyChannel = JSON.stringify channel, null, 2
    fs.writeFileSync @channel_filename, prettyChannel

commander
  .version 0.1
  .option '-f, --filename [path]',  'Path to the channel file to augment'
  .parse(process.argv);

commander.help() unless commander.filename?

converter = new ParseChannelSchemaToJSONSchema channel_filename: commander.filename
converter.run()
