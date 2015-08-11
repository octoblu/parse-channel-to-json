_ = require 'lodash'

class ChannelGeneratorFile
  transform: (channel) =>
    return unless channel?
    generatorFile = name: channel.name
    @getChannelGeneratorFile channel.application.resources

  getChannelGeneratorFile: (resources) =>
    subschemas = _.pluck resources, 'action'
    _.each subschemas, (subschema) =>
      actionProperties = @getGeneratorForAction resources, subschema

    messageSchema

  getGeneratorForAction: (resources, subschema) =>
    resource = _.findWhere resources, action: subschema
    properties = {}
    _.each resource.params, (param) =>
      properties["#{@sanitizeParam param.name}"] = @convertParam param

    properties

  sanitizeParam: (param) =>
    param.replace /^:/, ''

  convertParam: (param) =>
    resourceParam =
      type: param.type
      description: param.displayName
      required: param.required

module.exports = ChannelGeneratorFile
