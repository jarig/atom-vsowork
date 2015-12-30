VsoWorkView = require './vsowork-view'
{CompositeDisposable, ConfigObserver} = require 'atom'

module.exports =
  config:
    vsoCollectionUrl:
      type: 'string'
      title: 'VSO Collection URL'
      default: 'https://[username].visualstudio.com/DefaultCollection'
    vsoProjectPath:
      type: 'string'
      title: 'VSO Project Name'
      default: ''
    vsoQueryPath:
      type: 'string'
      default: 'My Queries/Assigned to me'
      title: 'VSO Work Item Query Path'
      description: 'Get it using rest: '
    vsoUsername:
      type: 'string'
      default: ''
      description: 'VSO Username to Authenticate with'
    vsoToken:
      type: 'string'
      default: ''
      description: 'VSO Token/Password'
    maxItems:
      type: 'int'
      default: 30
      description: 'How many items to show maximum'


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
