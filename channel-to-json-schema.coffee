_ = require 'lodash'

class ChannelToJsonSchema
  transform: (channel) =>
    @getMessageSchema channel?.application?.resources

  getMessageSchema: (resources)=>
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

  getSubschemaProperties: (resources, subschema) =>
    console.log 'resources', resources, 'subschema', subschema
    resource = _.findWhere resources, subschema: subschema
    properties = {}
    _.each resource.params, (param) =>
      properties["#{@sanitizeParam param.name}"] = @convertParam param

    properties

  sanitizeParam: (param) =>
    param.replace(/^:/, '')

  convertParam: (param) =>
    resourceParam =
      type: param.type
      description: param.displayName
      required: param.required

module.exports = ChannelToJsonSchema
