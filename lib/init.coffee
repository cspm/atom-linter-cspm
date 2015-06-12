path = require 'path'

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
            
    activate:
        console.log 'activate linter-cspm'
