if ($PSVersionTable.PSVersion.Major -lt 3) {
    [string] $PSScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
}

if ($PSVersionTable.PSVersion.Major -lt 3) {
    [string] $PSCommandPath = $MyInvocation.MyCommand.Definition
}

$Administrator = (
        [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole(
        [Security.Principal.WindowsBuiltInRole] "Administrator"
    )

if (-not $Administrator) {
    Start-Process -FilePath "powershell" -WindowStyle Hidden -WorkingDirectory $PSScriptRoot -Verb runAs `
                  -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File $PSCommandPath $args"
    return
}

Import-LocalizedData -BaseDirectory $PSScriptRoot\Locales -BindingVariable Messages

Import-Module -Name (Join-Path -Path $PSScriptRoot\Modules -ChildPath Show-Balloon)

if ($args.Length -gt 1) {
    $dir, $rest = $args
    $Program = "$rest"
    [string] $DisplayName = [io.path]::GetFileNameWithoutExtension($Program)
    [hashtable] $Directions = @{ "in" = "Inbound"; "out" = "Outbound"; }
    [string] $Direction = $Directions[$dir]
    [string] $TipIcon = "Info"
    [hashtable] $TipTexts = @{
        "in" = $Messages."Incoming Firewall Rule for `"{0}`" created." -f $DisplayName;
        "out" = $Messages."Outgoing Firewall Rule for `"{0}`" created." -f $DisplayName;
    }
    [array] $ArgumentList = @(
        "advfirewall", "firewall", "add", "rule", "name=`"$DisplayName`"",
        "program=`"$Program`"", "action=allow", "dir=$dir", "profile=any",
        "enable=yes"
    )
    [string] $LogFile = (Join-Path -Path $PSScriptRoot -ChildPath "advfirewall-rules.log")
    [string] $LogEntry = "netsh", "$ArgumentList"
    if (Get-Command -Name Get-NetFirewallRule -ErrorAction SilentlyContinue) {
        if (
            Get-NetFirewallApplicationFilter -Program $Program | `
            Get-NetFirewallRule | `
            Where-Object {$_.Direction -eq $Direction -and $_.DisplayName -eq $DisplayName}
        ) {
            Write-Warning -Message $Messages."Rule already exist!"
            [hashtable] $TipTexts = @{
                "in" = $Messages."Incoming Firewall Rule for `"{0}`" already exists!" -f $DisplayName;
                "out" = $Messages."Outgoing Firewall Rule for `"{0}`" already exists!" -f $DisplayName;
            }
            [string] $TipIcon = "Error"
        } else {
            New-NetFirewallRule -DisplayName $DisplayName -Program $Program -Direction $Direction `
                                -Action Allow -Enabled True -Profile Any
            Add-Content -Path $LogFile -Value $LogEntry
        }
    } else {
        Write-Warning -Message $Messages."Get-NetFirewallRule not supported, using Netsh."
        $Show = (netsh advfirewall firewall show rule name="$DisplayName" dir=$dir verbose) | Out-String
        if ($Show.Contains($Program)) {
            Write-Warning -Message $Messages."Rule already exist!"
            [hashtable] $TipTexts = @{
                "in" = $Messages."Incoming Firewall Rule for `"{0}`" already exists!" -f $DisplayName;
                "out" = $Messages."Outgoing Firewall Rule for `"{0}`" already exists!" -f $DisplayName;
            }
            [string] $TipIcon = "Error"
        } else {
            Start-Process -FilePath "netsh" -ArgumentList $ArgumentList -WindowStyle Hidden
            Add-Content -Path $LogFile -Value $LogEntry
        }
    }
    Show-Balloon -TipTitle "Windows Firewall" -TipText $TipTexts[$dir] `
                 -TipIcon $TipIcon -Icon "$env:SystemRoot\system32\FirewallControlPanel.dll"
}
