_ = require 'lodash'

class ChannelToForm
  transform: (channel) =>
    return unless channel?
    @getForm channel?.application?.resources

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
      key: "#{resource.action}"
      notitle: true
      type: 'hidden'
    ]

    _.each resource.params, (param) =>
      form.push(@getFormFromParam resource.action, param)

    form

  getFormFromParam: (action, param) =>
    formParam =
      key: "#{action}.#{@sanitizeParam param.name}"
      title: param.displayName
      condition: "model.subschema === '#{action}'"
      required: param.required

    if param.hidden?
      formParam.type = 'hidden'
      formParam.notitle = true

    formParam

  getSubschemaTitleMap: (resources) =>
    _.map resources, (resource) =>
      value: resource.action, name: resource.displayName

  convertFormParam: (param, url, method) =>
    formParam =
      key: "#{@sanitizeParam param.name}"
      title: param.displayName
      condition: "model.url === '#{url}' && model.method === '#{method}'"

    if param.hidden?
      formParam.type = 'hidden'
      formParam.notitle = true

    formParam

  sanitizeParam: (param) =>
    param.replace(/^:/, '')


module.exports = ChannelToForm
