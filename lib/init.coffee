path = require 'path'
fs = require 'fs'
{BufferedProcess, CompositeDisposable, Range} = require 'atom'

splitRange = (string) ->
  if string == "<unknown location>"
    return null
  minus = string.lastIndexOf("-")
  if minus == -1
    return [parseInt(string), parseInt(string)]
  else
    return [parseInt(string.slice(0, minus)), parseInt(string.slice(minus+1, string.length))]

getRootCSPFile = (fileName) ->
  fileContents = fs.readFileSync(fileName)
  firstLine = fileContents.slice(0, fileContents.indexOf('\n'))
  prefixMarker = "-- root: "
  if firstLine.indexOf(prefixMarker) == 0
    rootFile = firstLine.slice(prefixMarker.length).toString().trim()
    currentFileDir = path.dirname(fileName)
    return path.normalize(path.join(currentFileDir, rootFile))
  else
    return fileName

module.exports =
  config:
    fdrInstallDirectory:
      default:
        switch process.platform
          when 'win32' then "C:\\Program Files\\FDR3\\bin\\"
          when 'darwin' then "/Applications/FDR3.app/Contents/MacOS/"
          when 'linux' then "/opt/fdr/bin/"
      title: "Path to directory containing fdr3"
      type: "string"
  
  activate: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.config.observe 'linter-cspm.fdrInstallDirectory', @createShellCommand
      
  deactivate: ->
    @subscriptions.dispose()
  
  createShellCommand: =>
    fdrDir = atom.config.get 'linter-cspm.fdrInstallDirectory'
    executable = 'refines'+(if process.platform == 'win32' then ".exe" else '')
    @executablePath = path.join(fdrDir, executable)

  provideLinter: ->
    provider =
      grammarScopes: ['source.cspm']
      scope: 'file'
      lintOnFly: false
      lint: (textEditor) =>
        fdrDir = atom.config.get 'linter-cspm.fdrInstallDirectory'
        executable = 'refines'+(if process.platform == 'win32' then ".exe" else '')
        executablePath = path.join(fdrDir, executable)
        return new Promise (resolve, reject) =>
          filePath = getRootCSPFile(textEditor.getPath())
          lines = []
          process = new BufferedProcess
            command: executablePath
            args: ['--typecheck', filePath]
            stderr: (data) ->
              for line in data.split("\n")
                lines.push line
            exit: (code) ->
              console.log 'linter-cspm refines exited with', code, lines.length
              messages = []
              currentMessage = null
              console.log lines
              for line in lines
                if line == ""
                  continue
                console.log line, typeof(line)
                if currentMessage == null or line.indexOf("    ") != 0
                  # Start a new message
                  if currentMessage
                    messages.push currentMessage
                    
                  if line == "<unknown location>:"
                    currentMessage = {
                      type: 'error',
                      text: "Could not open #{filePath}",
                      filePath: textEditor.getPath(),
                    }
                  else
                    columnsStart = line.lastIndexOf(":", line.length-2)
                    lineNumPos = line.lastIndexOf(":", columnsStart-1)
                    columnsRange = splitRange(line.slice(columnsStart+1, line.length-1))
                    linesRange = splitRange(line.slice(lineNumPos+1, columnsStart))
                    currentMessage = {
                      type: 'error',
                      text: "",
                      filePath: line.slice(0, lineNumPos),
                    }
                    if columnsRange and linesRange
                      [colStart, colEnd] = columnsRange
                      [lineStart, lineEnd] = linesRange
                      currentMessage.range = new Range([lineStart-1, colStart-1], [lineEnd-1, colEnd-1])
                else
                  if currentMessage.text.length == 0
                    currentMessage.text += line.slice(4)+"\n"

              if currentMessage
                messages.push currentMessage
              
              resolve messages 

          process.onWillThrowError ({error,handle}) ->
            atom.notifications.addError "Failed to run #{@executablePath}",
              detail: "#{error.text}"
              dismissable: true
            handle()
            resolve []
