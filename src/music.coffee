client = null

$.expr[':'].containsic = (a, i, m) ->
  (a.textContent || a.innerText || "").toUpperCase().indexOf(m[3].toUpperCase()) >= 0

$(document).ready ->
  $('.signedin').hide()
  $.getJSON 'config.json', (data) ->
    client = new Dropbox.Client key: data.dropbox_key
    client.authenticate interactive: false, (error, client) ->
      if error?
        handleError 'Dropbox Error', getMsgFromDropboxError error

      if client.isAuthenticated()
        signedIn()
        init()
      else
        $('#signin').show()

  $('#signout a').click ->
    client.signOut (error) ->
      if error?
        return handleError 'Dropbox Error', getMsgFromDropboxError error

      signedOut()
      return false

  $('#signin a').click ->
    client.authenticate (error, client) ->
      if error?
        return handleError 'Dropbox Error', getMsgFromDropboxError error

      signedIn()
      init()

    return false

  $('#settingslink').click ->
    bootbox.prompt
      title: 'Album Path'
      value: localStorage.getItem 'musicpath'
      callback: (result) ->
        if result?
          localStorage.setItem 'musicpath', result
          init()

  $('#togglealbums').click ->
    $('#wrapper').toggleClass 'toggled'

  $('#search').change ->
    filter = $(this).val()
    if filter == ''
      $('#albums').find('li').show()
    else
      $('#albums').find('a:containsic(' + filter + ')').parent().show()
      $('#albums').find('a:not(:containsic(' + filter + '))').parent().hide()
  .keyup ->
    $(this).change()

getMsgFromDropboxError = (error) ->
  message = "An unknown error occurred, please refresh the page and try again."
  switch error.status
    when Dropbox.ApiError.INVALID_TOKEN then message = "Invalid authentication token, try signing out and back in to Dropbox."
    when Dropbox.ApiError.NOT_FOUND then message = "The specified path was not found."
    when Dropbox.ApiError.RATE_LIMITED then message = "You've exceeded your API rate limit, try again later."
    when Dropbox.ApiError.NETWORK_ERROR then message = "There was a network error, check your internet connection."
  return message

handleError = (title, message) ->
  loading false
  bootbox.dialog
    title: title
    message: message
    buttons:
      "Close":
        className: 'btn-danger'
  return false

signedIn = ->
  $('#signin').hide()
  $('#signout').show()
  $('.signedin').show()
  client.getAccountInfo (error, accountInfo) ->
    if error?
      return handleError 'Dropbox Error', getMsgFromDropboxError error

signedOut = ->
  $('#signout').hide()
  $('#signin').show()
  $('.signedin').hide()
  destroy()

stopPlaying = ->
  $('#page-content-wrapper').css 'background-image', 'url("generic.png")'
  $('#player').data('bbplayer')?.bbaudio?.pause()
  $('#player').hide().empty()
  $('#dummyplayer').show()
  $('#songs ul').empty()

init = ->
  stopPlaying()
  $('#albums').empty()
  root = localStorage.getItem 'musicpath'
  $('#musicpath').val root
  if !root?
    $('#settingslink').click()
  else
    loading true
    readAlbums(root).then ->
      loading false

destroy = ->
  stopPlaying()
  $('#albums').empty()
  $('#search').val ''
  localStorage.removeItem 'musicpath'

readAlbums = (path) ->
  new Promise (resolve, reject) ->
    subs = []
    client.readdir path, (error, entries) ->
      if error?
        handleError 'Dropbox Error', getMsgFromDropboxError error
        resolve()
      if entries?
        for entry in entries
          if !entry.match /\.(mp3|ogg|m4a|png|jpg)$/i
            album = $('<a href="#">').attr('data-path', path + '/' + entry).html(entry).click ->
              $('#albums li').removeClass 'active'
              $(this).parent('li').addClass 'active'
              loadAlbum $(this).attr 'data-path'
            $('#albums').append($('<li>').append album)
            if entry.match /^_/
              subs.push readAlbums path + '/' + entry
      if subs.length > 0
        P.all(subs).then ->
          resolve()
      else
        resolve()

loadAlbum = (album) ->
  loading true
  stopPlaying()
  client.readdir album, (error, entries) ->
    if error?
      return handleError 'Dropbox Error', getMsgFromDropboxError error
    $.get 'player.html', (data) ->
      $('#player').html data
      $('#player').find('.bb-album').html album
      makeUrls = []
      for entry in entries
        if entry.match /\.(mp3|ogg|m4a|jpg|png)$/i
          makeUrls.push getUrlData album, entry
      Promise.all(makeUrls).then (urlData) ->
        track = 0
        coverset = false
        for data in urlData
          if data.name.match /\.(mp3|ogg|m4a)$/i
            source = $('<source>').attr 'src', data.url
            source.attr 'data-album', album
            $('#playlist').append source
            $('#songs ul').append $('<li>').append $('<a href="#">').attr('data-track', track++).html(data.name).click ->
              $('#player').data('bbplayer').loadTrack $(this).attr 'data-track'
              $('#player').data('bbplayer').bbaudio.play()
              return false
          else if !coverset and data.name.match /\.(jpg|png)$/i
            $('#page-content-wrapper').css 'background-image', 'url("' + data.url + '")'
            coverset = true
        $('#dummyplayer').hide()
        $('#player').show()
        bbplayer = new BBPlayer $('#player .bbplayer')[0]
        $('#player').data 'bbplayer', bbplayer
        loading false
        $('#player').data('bbplayer').bbaudio.play()
  return false

getUrlData = (album, name) ->
  new Promise (resolve, reject) ->
    path = album + '/' + name
    client.makeUrl path, download: true, (error, urlData) ->
      if error?
        reject 'Error retrieving url for ' + name
      else
        resolve
          name: name
          url: urlData.url

loading = (show) ->
  if show
    $('#loader').show()
  else
    $('#loader').hide()
