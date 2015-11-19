client = null

$(document).ready ->
  $.getJSON 'config.json', (data) ->
    client = new Dropbox.Client key: data.dropbox_key
    client.authenticate interactive: false, (error, client) ->
      if error?
        handleError error

      if client.isAuthenticated()
        signedIn()
        init()
      else
        $('#signin').show()

  $('#signout a').click ->
    client.signOut (error) ->
      if error?
        return handleError error

      signedOut()
      return false

  $('#signin a').click ->
    client.authenticate (error, client) ->
      if error?
        return handleError error

      signedIn()
      init()

    return false

  $('#settingslink').click ->
    $('#musicpath').val localStorage.getItem 'musicpath'
    $('#settings').toggle()
    return false

  $('#settingsform').submit ->
    localStorage.setItem 'musicpath', $('#musicpath').val()
    $('#settings').hide()
    handleSuccess 'Settings saved.'
    init()
    return false

handleError = (error) ->
  alert error
  return false

handleSuccess = (message) ->
  alert message
  return false

signedIn = ->
  $('#signin').hide()
  $('#signout').show()
  $('.signedin').show()
  client.getAccountInfo (error, accountInfo) ->
    if error?
      return handleError error
    $('#user').html accountInfo.email

signedOut = ->
  $('#signout').hide()
  $('#signin').show()
  $('.signedin').hide()
  $('#settings').hide()
  destroy()

stopPlaying = ->
  $('#player').data('bbplayer')?.bbaudio?.pause()
  $('#player').hide().empty()
  $('#dummyplayer').show()
  $('#songs ul').empty()

init = ->
  stopPlaying()
  $('#coverart img').attr 'src', 'generic.png'
  $('#albums ul').empty()
  if !localStorage.getItem 'musicpath'
    $('#settings').show()
  else
    readAlbums()

destroy = ->
  stopPlaying()
  $('#albums ul').empty()
  localStorage.removeItem 'musicpath'

readAlbums = ->
  client.readdir (localStorage.getItem 'musicpath'), (error, entries) ->
    if error?
      return handleError error
    for entry in entries
      album = $('<a href="#">').html(entry).click ->
        loadAlbum $(this).text()
      $('#albums ul').append($('<li>').append album)

loadAlbum = (album) ->
  stopPlaying()
  root = localStorage.getItem 'musicpath'
  client.readdir root + '/' + album,  (error, entries) ->
    if error?
      return handleError error
    $.get 'player.html', (data) ->
      $('#player').html data
      $('#player').find('.bb-album').html album
      makeUrls = []
      for entry in entries
        if entry.match /\.(mp3|ogg|jpg|png)$/i
          makeUrls.push getUrlData album, entry
      Promise.all(makeUrls).then (urlData) ->
        track = 0
        coverset = false
        for data in urlData
          if data.name.match /\.(mp3|ogg)$/i
            source = $('<source>').attr 'src', data.url
            source.attr 'data-album', album
            $('#playlist').append source
            $('#songs ul').append $('<li>').append $('<a href="#">').attr('data-track', track++).html(data.name).click ->
              $('#player').data('bbplayer').loadTrack $(this).attr 'data-track'
              $('#player').data('bbplayer').bbaudio.play()
              return false
          else if !coverset and data.name.match /\.(jpg|png)$/i
            $('#coverart img').attr 'src', data.url
            coverset = true
        if !coverset
          $('#coverart img').attr 'src', 'generic.png'
        $('#dummyplayer').hide()
        $('#player').show()
        bbplayer = new BBPlayer $('#player .bbplayer')[0]
        $('#player').data 'bbplayer', bbplayer
        $('#player').data('bbplayer').bbaudio.play()
  return false

getUrlData = (album, name) ->
  new Promise (resolve, reject) ->
    path = (localStorage.getItem 'musicpath') + '/' + album + '/' + name
    client.makeUrl path, download: true, (error, urlData) ->
      if error?
        reject error
      else
        resolve
          name: name
          url: urlData.url
