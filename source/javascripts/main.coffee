# Extensions
unless String::trim then String::trim = -> @replace /^\s+|\s+$/g, ""
unless window.console and console.log
  (->
    noop = ->

    methods = ["assert", "clear", "count", "debug", "dir", "dirxml", "error", "exception", "group", "groupCollapsed", "groupEnd", "info", "log", "markTimeline", "profile", "profileEnd", "markTimeline", "table", "time", "timeEnd", "timeStamp", "trace", "warn"]
    length = methods.length
    console = window.console = {}
    console[methods[length]] = noop  while length--
  )()



# History Support
HistorySupportAvailable = -> !!(window.history && history.pushState)



# Challenge
challengePath = ''
challengeAnswerable = false
ChallengeInitialize = ->
  challengePath = ''
  challengeAnswerable = false
  $jsChallenge = $('#js-challenge')
  if $jsChallenge? && $jsChallenge.length > 0
    challengePath = $jsChallenge.data('path')
    challengeAnswerable = $jsChallenge.data('answerable')
  $challengeCodePrefill = $ '#code-prefill'
  if $challengeCodePrefill? && $challengeCodePrefill.length > 0
    SnippetEditorSetValue $challengeCodePrefill.text().trim() + "\n# Ketik jawaban di bawah ini\n"
  if HistorySupportAvailable()
    $(".js-challenge-link").on 'click', ->
      ChallengeNavigateToURL $(this).attr('href')
      return false

popstateIsBoundToWindow = false
ChallengeNavigateToURL = (challengeURL) ->
  if HistorySupportAvailable()
    unless popstateIsBoundToWindow
      popstateIsBoundToWindow = true
      $(window).on 'popstate', (e) ->
        ChallengeNavigateToURL window.location.href

    $.get challengeURL, {}, (data, textStatus, xhr) ->
      questionId = "#js-question"
      $question = $(questionId)
      ChallengeContentUpdate = ->
        $data = $(data)
        $question.html $data.find(questionId).html()
        ChallengeInitialize()
        history.pushState {}, $data.find('title').text(), challengeURL

      if $.support.transition
        $question.transition opacity: 0, scale: 0.9, 350, 'out', ->
          ChallengeContentUpdate()
          $question.transition opacity: 1, scale: 1, 400, 'out'
      else
        ChallengeContentUpdate()
  else
    window.location.href = challengeURL

ChallengeNavigateToPath = (challengePath) ->
  ChallengeNavigateToURL [challengeRoot, challengePath].join('/') + ".html"



# Snippet Editor
editor = null
editorInitialized = false
SnippetEditorSetValue = (snippet) ->
  if editorInitialized
    editor.getSession().setValue snippet
  else
    $("#snippet-runner-code-content").html "<pre>" + snippet + "</pre>"
SnippetEditorGetValue = ->
  if editorInitialized
    editor.getSession().getValue()
  else
    $("#snippet-runner-code-content").text()
SnippetEditorInitialize = ->
  if window.ace
    editor = ace.edit("code-editor")
    editor.setTheme "ace/theme/solarized_light"
    editor.getSession().setMode "ace/mode/ruby"
    editorInitialized = true



# Initialize Elements
$body = $("body")
$loadingIndicator = $ '#loading-indicator'
snippetRequestError = $("#snippet-request-error-template").text()
$runner = $("#snippet-runner")
$("#snippet-request-error-template").remove()

SnippetEditorInitialize()
ChallengeInitialize()

$(".btn-run").on 'click', ->
  $outputTarget = $("#run-output")
  snippet = SnippetEditorGetValue()
  $loadingIndicator.text "Memproses..."

  $.post(rubyEvalRoot + "/coba-ruby.json", snippet: snippet, challenge_path: challengePath, (data, textStatus, xhr) ->
    if challengeAnswerable && data.is_correct
      ChallengeNavigateToPath data.next_challenge_path

    $loadingIndicator.text ""
    $outputTarget.text data.output
  ).fail ->
    $loadingIndicator.text ""
    $outputTarget.text snippetRequestError
