client = null

$(document).ready ->
  $.getJSON 'config.json', (data) ->
    client = new Dropbox.Client key: data.dropbox_key
    client.authenticate interactive: false, (error, client) ->
      if error?
        handleError error

      if client.isAuthenticated()
        signedIn()
        init client
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
      init client

    return false

  $('#settingslink').click ->
    $('#musicpath').val localStorage.getItem 'musicpath'
    $('#settings').toggle()
    return false

  $('#savesettings').click ->
    localStorage.setItem 'musicpath', $('#musicpath').val()
    $('#settings').hide()
    handleSuccess 'Settings saved.'
    init client
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
  destroy client

init = (client) ->
  if !localStorage.getItem 'musicpath'
    $('#settings').show()
  else
    client.readdir (localStorage.getItem 'musicpath'), (error, entries) ->
      if error?
        return handleError error

      alert entries.join ', '

destroy = (client) ->
  localStorage.removeItem 'musicpath'
