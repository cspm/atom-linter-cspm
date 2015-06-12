{Range} = require 'atom'
linterPath = atom.packages.getLoadedPackage('linter').path
Linter = require "#{linterPath}/lib/linter"
findFile = require "#{linterPath}/lib/util"
{CompositeDisposable} = require "atom"

splitRange = (string) ->
  if string == "<unknown location>"
    return null
  minus = string.lastIndexOf("-")
  if minus == -1
    return [parseInt(string), parseInt(string)]
  else
    return [parseInt(string.slice(0, minus)), parseInt(string.slice(minus+1, string.length))]

class LinterCSPM extends Linter
  # The syntax that the linter handles. May be a string or
  # list/tuple of strings. Names should be all lowercase.
  @syntax: ['source.cspm']

  # A string, list, tuple or callable that returns a string, list or tuple,
  # containing the command line (with arguments) used to lint.
  cmd: ['refines'+(if process.platform == 'win32' then ".exe" else ''), '--typecheck']
  
  linterName: 'FDR'

  errorStream: 'stderr'

  constructor: (editor) ->
    super(editor)
    
    @disposables = new CompositeDisposable
    @disposables.add atom.config.observe 'linter-cspm.fdrInstallDirectory', @createShellCommand
    
  destroy: ->
    super
    @disposables.dispose()
    
  createShellCommand: =>
    @executablePath = atom.config.get 'linter-cspm.fdrInstallDirectory'
    
  processMessage: (message, callback) ->
    if message instanceof Array and message.length == 0
      callback []
      return
    
    messages = []
    currentMessage = null
    messageLines = message.split("\n")
    for line in messageLines
      if line == ""
        continue

      if currentMessage == null or line.indexOf("    ") != 0
        # Start a new message
        if currentMessage
          messages.push currentMessage

        columnsStart = line.lastIndexOf(":", line.length-2)
        lineNumPos = line.lastIndexOf(":", columnsStart-1)
        [colStart, colEnd] = splitRange(line.slice(columnsStart+1, line.length-1))
        [lineStart, lineEnd] = splitRange(line.slice(lineNumPos+1, columnsStart))
        fileName = line.slice(0, lineNumPos)

        currentMessage = {
          line: lineStart,
          col: colStart,
          level: 'error',
          message: "",
          linter: @linterName,
          range: new Range([lineStart-1, colStart-1], [lineEnd-1, colEnd-1])
        }
      
      else
        if currentMessage.message.length == 0
          currentMessage.message += line.slice(4)+"\n"

    if currentMessage
      messages.push currentMessage

    callback messages

module.exports = LinterCSPM
