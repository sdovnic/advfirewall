function Show-MessageBox {
    <#
        .SYNOPSIS
            Show a Message Box.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)] [String] $Caption,
        [Parameter(Mandatory=$true)] [String] $Text,
        [Parameter(Mandatory=$false)] [ValidateSet(
            "AbortRetryIgnore",
            "OK",
            "OKCancel",
            "RetryCancel",
            "YesNo",
            "YesNoCancel"
        )] [String] $Buttons = "OK",
        [Parameter(Mandatory=$false)] [ValidateSet(
            "Error",
            "Information",
            "None",
            "Question",
            "Warning"
        )] [String] $Icon = "Information"
    )
    Begin {
        Add-Type -AssemblyName System.Windows.Forms
    }
    Process {
        $Result = [System.Windows.Forms.MessageBox]::Show(
            $Text, $Caption, $Buttons, [System.Windows.Forms.MessageBoxIcon]::$Icon
        )
        return $Result
    }
}
