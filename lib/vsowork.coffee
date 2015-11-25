VsoWorkView = require './vsowork-view'
{CompositeDisposable, ConfigObserver} = require 'atom'

module.exports =
  config:
    vsoApiUrl:
      type        : 'string'
      description : 'VSO Work Item REST url'
      title       : 'test'
      default     : 'https://[username].visualstudio.com/DefaultCollection/[project]/_apis'
    vsoQueryID:
      type        : 'string'
      default     : ''
      description : 'VSO Work Item Query ID'
    vsoUsername:
      type        : 'string'
      default     : ''
      description : 'VSO Username to Authenticate with'
    vsoToken:
      type        : 'string'
      default     : ''
      description : 'VSO Token/Password'


  view: null
  subscriptions: null

  activate: (state) ->
    @view = new VsoWorkView(state.myPackageViewState)
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', \
                                         'vsowork:search': => @search()

  deactivate: ->
    @subscriptions.dispose()

  search: ->
    @view.show()

  serialize: ->
