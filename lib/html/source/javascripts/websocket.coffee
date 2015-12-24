#= require vendor/jquery.js
#= require status.coffee

class WSClient
  constructor: ->
    host = $qs.get("host") || "localhost"
    console.log "Path: #{$qs.get("path")}, Port: #{$qs.get("port")}, Host: #{host}"
    @ws = new WebSocket "ws://#{host}:#{$qs.get("port")}/#{$qs.get("path")}"
    @actions["__parent"] = this
    document.title = $qs.get("title") || "Flammarion Unconnected"
    @ws.onopen = (msg) ->
      $('body').addClass("connected")

    @ws.onclose = (msg) ->
      $('body').removeClass("connected")

    @ws.onmessage = (msg) =>
      console.log(msg)
      data = $.parseJSON(msg.data)
      if @actions[data.action]
        @actions[data.action](data)
      else
        console.error("No such action: #{data.action}")

    @status = new StatusDisplay(this, $('#status > .right'))

  send: (data) ->
    @ws.send JSON.stringify(data)

  check_target: (data) ->
    return data.target_element if data.target_element
    data.target = "default" unless data.target
    @actions.addpane {name:data.target} if $("#console-#{data.target}").size() is 0
    @resize_panes
    return $("#console-#{data.target}")

  resize_panes: (data) ->
    if data.target
      target = @check_target(data)
    else
      target = $('#panes')

    allPanes =  target.find('> .pane')
    height = (100.0 / allPanes.size()).toFixed(0) + "%"
    if target.hasClass('horizontal')
      orientation = 'horizontal'
    else
      orientation = 'vertical'

    console.log target, allPanes.size(), 100.0 / allPanes.size(), height, orientation
    for pane in allPanes
      if orientation is 'horizontal'
        $(pane).css "width", height
        $(pane).css "height", '100%'
      else
        $(pane).css "height", height
        $(pane).css "width", '100%'

  escape: (text, input_options) ->
    options =
      raw: false
      colorize: true
      escape_html: true
      escape_icons: false
    $.extend(options, input_options)
    return text if options.raw
    text = "#{text}"
    text = ansi_up.escape_for_html(text) if options.escape_html
    text = ansi_up.ansi_to_html(text, {use_classes:true}) if options.colorize
    text = text.replace(/:[\w-]+:/g, (match) ->
      "<i class='fa fa-#{match[1..-2]}'></i>") if options.escape_icons
    return text

  add: (object, target, data) ->
    if data.replace
      target.html(object)
    else
      target.append(object)

  actions:
    __parent: null

$(document).ready ->
  window.$ws = new WSClient

window.WSClient = WSClient
