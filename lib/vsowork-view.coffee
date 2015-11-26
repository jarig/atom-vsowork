{SelectListView} = require 'atom-space-pen-views'
shell = require 'shell'
_ = require 'lodash'
$ = require 'jquery'

atom.themes.requireStylesheet(require.resolve('../styles/vsowork.less'))

module.exports = class VsoWorkViewSelectListView extends SelectListView
  initialize: ->
    super
    @addClass('overlay from-top')
    @maxItems = 10
    @executeVSOQuery()

  viewForItem: (item) ->
    status = if item['System.AssignedTo'] then \
    "#{item['System.State']} - #{item['System.AssignedTo'].replace(/\s<.+/g, '')}" \
    else "#{item['System.State']}"

    "<li class='vsowork two-lines'>
      <div class='item #{item['System.WorkItemType'].replace(' ', '')}'>
        <div class='primary-line'>#{$('<div/>').text(item['System.Title']).html()}</div>
        <div class='secondary-line'>
          <span class='item_id'>\##{item['System.Id']}</span>
          <span class='pull-right key-binding'>#{status}</span>
        </div>
      </div>
    </li>"

  confirmed: (item) ->
    atom.clipboard.write("\##{item['System.Id']}", item)
    atom.notifications.addInfo("Item #{}#{item['System.Id']} copied to the clipboard", \
                               {'.icon': 'person'})
    @hide()

  cancelled: ->
    @hide()

  getFilterKey: ->
    'System.Title'

  show: ->
    @panel ?= atom.workspace.addModalPanel(item: this)
    @panel.show()
    @setLoading('Running VSO query...')
    @executeVSOQuery()
    @focusFilterEditor()

  hide: ->
    @panel.hide()

  executeVSOQuery: ->
    @vsoCollectionUrl = atom.config.get("vsowork.vsoCollectionUrl")
    @vsoProjectPath = atom.config.get("vsowork.vsoProjectPath")
    @vsoQueryPath = atom.config.get("vsowork.vsoQueryPath")
    @vsoUsername = atom.config.get("vsowork.vsoUsername")
    @vsoToken = atom.config.get("vsowork.vsoToken")
    if @vsoQueryId
      @getVSOItems @vsoQueryId
    else
      credentials = btoa("#{@vsoUsername}:#{@vsoToken}")
      # get query id
      $.ajax
        url: "#{@vsoCollectionUrl}/#{@vsoProjectPath}/_apis/wit/queries/#{@vsoQueryPath}?api-version=1.0"
        beforeSend: (xhr) ->
          xhr.withCredentials = true
          xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest')
          xhr.setRequestHeader("Authorization", "Basic #{credentials}")
        success: (data) =>
          @vsoQueryId = data.id
          @getVSOItems data.id


  getVSOItems: (queryId) ->
    # We must query issue id if we are sure that it's in right format
    credentials = btoa("#{@vsoUsername}:#{@vsoToken}")
    $.ajax
      url: "#{@vsoCollectionUrl}/#{@vsoProjectPath}/_apis/wit/wiql/#{queryId}?api-version=1.0"
      beforeSend: (xhr) ->
        xhr.withCredentials = true
        xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest')
        xhr.setRequestHeader("Authorization", "Basic #{credentials}")
      success: (data) =>
        if data.queryType is 'flat'
          issuesIds = _.map data.workItems, (wItem) ->
            wItem.id
          # make 2nd hop query
          $.ajax
            url: "#{@vsoCollectionUrl}/_apis/wit/WorkItems?ids=#{issuesIds.join(',')}&fields=System.Id,System.WorkItemType,System.Title,System.State,System.AssignedTo&api-version=1.0"
            beforeSend: (xhr) ->
              xhr.withCredentials = true
              xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest')
              xhr.setRequestHeader("Authorization", "Basic #{credentials}")
            success: (data) =>
              list = []
              if data.count > 0
                @setError(null)
                for i in [0...Math.min(data.count, @maxItems)]
                  item = data.value[i].fields
                  list.push(item)
                @setItems(list)
        else
          atom.notifications.addError("VSOWork: Not supporting non-flat type queries: #{data.queryType}")
      error: ->
        atom.notifications.addError("VSOWork: Error executing search.")
