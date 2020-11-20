
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
function Log {
    
    param (
        [string]$log,
        [string]$level = "Info",
        [string]$logFileName
    )

    $wrappedLog = "[$([DateTime]::Now.ToString("yyyy-MM-dd-hh:mm:ss"))] [$level]: $log"
    
    $color = "White";
    if($level -eq "Debug")
	{
		$color = "Blue";
	}
	if($level -eq "Info" -or $Level -eq "OK")
	{
		$color = "darkgreen";
	}
	if($level -eq "Warning")
	{
		$color = "Yellow";
	}
	if($level -eq "Error")
	{
		$color = "Red";
	}

    Write-Host $wrappedLog -ForegroundColor $color

    $filePath = $logFileName;
    if (!$filePath -or $filePath -eq "")
    {
        $filePath = $global:logFileName;
    }
    if ($filePath) {
        Add-Content -Path $filePath -Value $wrappedLog
    }
}

Export-ModuleMember -Function Log