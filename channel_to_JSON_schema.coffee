fs = require 'fs'
_  = require 'lodash'
commander = require 'commander'

class ParseChannelSchemaToJSONSchema
  constructor: (options={}) ->
    @channel_infile = "schema_test_email.json"
    #options.channel_infile
    @channel_outfile = "schema_test_email_new.json"
    #options.channel_outfile

  channel: =>
    console.log @channel_infile
    JSON.parse fs.readFileSync @channel_infile

  run: =>
    channel = @channel()

    _.each channel.application.resources, (resource) => 
      
      resourceParams = _.map resource.params, (param) => 
         resourceParam = {}
         resourceParam[param.name] = {
           type : param.type, 
           description : param.displayName, 
           style : param.style, 
         }

         if param.required
          resourceParam[param.required].required = param.required

         if param.hidden
          resourceParam[param.name].hidden = param.hidden

         if param.default
          resourceParam[param.name].default = param.default

         resourceParam

      resource.description = resource.displayName
      delete resource.displayName

      resource.params = resource.properties  
      resource.properties = resourceParams
      console.log resourceParams

    prettyChannel = JSON.stringify channel, null, 2
    fs.writeFileSync @channel_outfile, prettyChannel
    console.log(prettyChannel)

commander
  .version 0.1
  .option '-i, --infile [path]',  'Path to the channel file to input'
  .option '-o, --outfile [path]',  'Path to the channel file to output'
  .parse(process.argv);

commander.help() unless commander.infile?

converter = new ParseChannelSchemaToJSONSchema channel_infile: commander.infile?,
  channel_outfile: commander.outfile?
converter.run()
