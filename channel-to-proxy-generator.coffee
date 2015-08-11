_ = require 'lodash'

class ChannelToProxyGenerator
  transform: (channel) =>
    return {} unless channel?.application?.resources?

    generatorFile = name: channel.name
    @getChannelGeneratorFile channel.application.resources

  getChannelGeneratorFile: (resources) =>    
    actions = _.pluck resources, 'action'
    generatorActions = {}
    _.each actions, (action) =>
      generatorActions[action] = @getGeneratorForAction resources, action

    generatorActions

  getGeneratorForAction: (resources, action) =>
    resource = _.findWhere resources, action: action
    generator =
      url: resource.url
      httpMethod: resource.httpMethod.toLowerCase()
      properties: {}

    _.each resource.params, (param) =>
      generator.properties["#{@sanitizeParam param.name}"] = @convertParam param

    generator

  sanitizeParam: (param) =>
    console.log param
    param.replace /^:/, ''

  convertParam: (param) =>
    resourceParam =
      style: param.style
      name: param.name

module.exports = ChannelToProxyGenerator
