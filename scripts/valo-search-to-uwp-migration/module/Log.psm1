<#
 .Synopsis
  Module to write log messages.

 .Description
  Writes log message to console and log file.

 .Parameter log
  The message to log. Use the message as first parameter
  and you can just skip setting the parameter name.
  See exmaple below.

 .Parameter level
  The 'severity level' of the message. Defaults to "Info".
  Valid levels are (in order of ascending severity):
  Debug, Info, Waring, Error

 .Parameter logFileName
  The full path of the log file to write to. If you don't want
  to specify a log file on every call, just set the global variable:
  $global:logFileName in the calling script to the desired log file to use.

 .Example
   # Log a message with severity level "Debug"
   Log "hello world" -level Debug
#>
function Log 
{
    
    param (
        [string]$log,
        [string]$level = "debug",
        [string]$logFileName,
        [string]$logLevel
    )

    if (!$logLevel -or $logLevel.Length -lt 1)
    {
        $logLevel = $global:logLevel;
    }
    if ($logLevel)
    {
       $logLevel = $logLevel.ToLower(); 
    }
    else 
    {
        $logLevel = "warning";
    }    

    $level = $level.ToLower();
    
    $logLevelSeverity = Get-Severity -Level $logLevel;
    $currentSeverity = Get-Severity -Level $level;

    if ($currentSeverity -ge $logLevelSeverity)
    {    
        $color = switch ($level)
        {
            "trace" { 
                "DarkGray";
            }
            "debug" { 
                "Blue";
            }
            "info" { 
                "DarkGreen";
            }
            "ok" { 
                "DarkGreen";
            }
            "warn" { 
                "Yellow";
            }
            "warning" { 
                "Yellow";
            }
            "error" {
                "Red";
            }                    
            default { 
                "Gray";
            }
        }

        $wrappedLog = "[$([DateTime]::Now.ToString("yyyy-MM-dd-hh:mm:ss"))] [$level]: $log"

        Write-Host $wrappedLog -ForegroundColor $color

        $filePath = $logFileName;
        if (!$filePath -or $filePath.Length -lt 1)
        {
            $filePath = $global:logFileName;
        }
        if ($filePath) 
        {            
            Add-Content -Path $filePath -Value $wrappedLog
        }
    }
}

function Get-Severity($level)
{
    $severity = $null;

    $null = @(
        $severity =  switch ($level)
        {
            "trace" { 
                0;
            }
            "debug" { 
                1;
            }
            "info" { 
                2;
            }
            "ok" { 
                2;
            }
            "warn" { 
                3;
            }
            "warning" { 
                3;
            }
            "error" {
                4;
            }                    
            default { 
                4;
            }
        }
    );

    return $severity;
}

Export-ModuleMember -Function Log;