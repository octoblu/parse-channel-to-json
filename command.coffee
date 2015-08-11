#!/usr/bin/env coffee

fs = require 'fs'
_  = require 'lodash'
commander = require 'commander'
debug = require('debug')('channel-to-json-schema')

ChannelToJsonSchema = require './channel-to-json-schema'
ChannelToForm = require './channel-to-form'
ChannelToProxyGenerator = require './channel-to-proxy-generator'

commander
  .version 1.0
  .option '-i, --infile [path]',  'Path to the channel file to input'
  .option '-j, --json-schema [path]', 'Path to the json schema file to output'
  .option '-f, --form [path]',  'Path to the schema form file to output'
  .option '-p, --proxy-generator [path]',  'Path to the proxy generator file to output'
  .parse process.argv

commander.help() unless commander.infile?

channel = JSON.parse fs.readFileSync(commander.infile)

if commander.jsonSchema?
  console.log 'generating json schema'
  channel2Json = new ChannelToJsonSchema()
  jsonSchema = channel2Json.transform channel
  fs.writeFileSync(commander.jsonSchema, JSON.stringify(jsonSchema, null, 2))

if commander.form?
  console.log 'generating form'
  channel2Form = new ChannelToForm()
  form = channel2Form.transform channel
  fs.writeFileSync(commander.form, JSON.stringify(form, null, 2))

if commander.proxyGenerator?
  console.log 'generating proxy generator file'
  channel2Proxy = new ChannelToProxyGenerator()
  proxyGenerator = channel2Proxy.transform channel
  fs.writeFileSync(commander.proxyGenerator, JSON.stringify(proxyGenerator, null, 2))
