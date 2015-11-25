{SelectListView} = require 'atom-space-pen-views'
shell = require 'shell'
_ = require 'lodash'
$ = require 'jquery'

module.exports = class VsoWorkViewSelectListView extends SelectListView
  initialize: ->
    super
    # Initialize with dummy data to avoid "Loading icon" from appearing
    @setItems("")
    @addClass('overlay from-top')

  viewForItem: (item) ->
    status = if item.fields['System.AssignedTo'] then \
    "#{item.fields['System.State']} - #{item.fields['System.AssignedTo']}" \
    else "#{item.status}"

    "<li class='two-lines'>
      <div class='primary-line'>#{item.fields['System.Title']}</div>
      <div class='secondary-line'>\##{item.fields['System.Id']}
        <span class='pull-right key-binding'>#{status}</span>
      </div>
    </li>"

  confirmed: (item) ->
    shell.openExternal(item.url)

  cancelled: ->
    @hide()

  show: ->
    @panel ?= atom.workspace.addModalPanel(item: this)
    @panel.show()
    @focusFilterEditor()
    @vsoRestUrl = atom.config.get("vsowork.vsoApiUrl")
    @vsoQueryID = atom.config.get("vsowork.vsoQueryID")
    @vsoUsername = atom.config.get("vsowork.vsoUsername")
    @vsoToken = atom.config.get("vsowork.vsoToken")

  hide: ->
    @panel.hide()

  # overridden populateList that fetches data from VSO
  # This is not an optimal solution as SelectListView documentation
  # says that overridden populateList-method should always call super
  # However, that way it seems hard (impossible?) to get this working
  populateList: ->
    q = @getFilterQuery()
    if q.length < 2 then return

    # We must query issue id if we are sure that it's in right format
    $.ajax
      url: "#{@vsoRestUrl}/wit/wiql/#{@vsoQueryID}?api-version=1.0"
      beforeSend: (xhr)->
        credentials = $.base64.encode("#{@vsoUsername}:#{@vsoToken}")
        xhr.withCredentials = true
        xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest')
        xhr.setRequestHeader("Authorization", "Basic " + credentials)
      success: (data) =>
        if data.queryType is 'flat'
          issuesIds = _.map data.workItemRelations, (wItem) ->
            wItem.id
          console.log("Ids: #{issuesIds}")
          # make 2nd hop query
          $.ajax
            url: "#{@vsoRestUrl}/wit/WorkItems/ids?=#{issuesIds.join(',')}&fields=System.Id,System.Title,System.State,System.AssignedTo&api-version=1.0"
            beforeSend: (xhr)->
              credentials = $.base64.encode("#{@vsoUsername}:#{@vsoToken}")
              xhr.withCredentials = true
              xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest')
              xhr.setRequestHeader("Authorization", "Basic " + credentials)
            success: (data) =>
              @list.empty()
              if data.value > 0
                @setError(null)
                for i in [0...Math.min(issues.length, @maxItems)]
                  item = data.value[i]
                  itemView = $(@viewForItem(item))
                  itemView.data('select-list-item', item)
                  @list.append(itemView)
                @selectItemView(@list.find('li:first'))
        else
          atom.notifications.addError("Not supporting tree type queries.")
      error: () ->
        atom.notifications.addError("Error executing search.")
