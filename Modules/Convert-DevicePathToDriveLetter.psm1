function Convert-DevicePathToDriveLetter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] $Path
    )
    begin {
        # Build System Assembly in order to call Kernel32:QueryDosDevice.
        $DynamicAssembly = New-Object -TypeName System.Reflection.AssemblyName('SysUtils') -Verbose
        $AssemblyBuilder = [AppDomain]::CurrentDomain.DefineDynamicAssembly($DynamicAssembly, [Reflection.Emit.AssemblyBuilderAccess]::Run)
        $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule('SysUtils', $false)
 
        # Define [Kernel32]::QueryDosDevice method
        $TypeBuilder = $ModuleBuilder.DefineType('Kernel32', 'Public, Class')
        $PInvokeMethod = $TypeBuilder.DefinePInvokeMethod('QueryDosDevice', 'kernel32.dll', ([Reflection.MethodAttributes]::Public -bor [Reflection.MethodAttributes]::Static), [Reflection.CallingConventions]::Standard, [UInt32], [Type[]]@([String], [Text.StringBuilder], [UInt32]), [Runtime.InteropServices.CallingConvention]::Winapi, [Runtime.InteropServices.CharSet]::Auto)
        $DllImportConstructor = [Runtime.InteropServices.DllImportAttribute].GetConstructor(@([String]))
        $SetLastError = [Runtime.InteropServices.DllImportAttribute].GetField('SetLastError')
        $SetLastErrorCustomAttribute = New-Object -TypeName Reflection.Emit.CustomAttributeBuilder($DllImportConstructor, @('kernel32.dll'), [Reflection.FieldInfo[]]@($SetLastError), @($true)) -Verbose
        $PInvokeMethod.SetCustomAttribute($SetLastErrorCustomAttribute)
        $Kernel32 = $TypeBuilder.CreateType()
 
        $Max = 65536
        $StringBuilder = New-Object -TypeName System.Text.StringBuilder($Max) -Verbose
    }
    process {
        $DeviceList = Get-WmiObject -Class Win32_Volume | Where-Object -FilterScript { $_.DriveLetter } | ForEach-Object -Process {
            $ReturnLength = $Kernel32::QueryDosDevice($_.DriveLetter, $StringBuilder, $Max)
            if ($ReturnLength) {
                $DriveMapping = @{
                    DriveLetter = $_.DriveLetter
                    DevicePath = $StringBuilder.ToString().ToLower()
                }
                New-Object -TypeName PSObject -Property $DriveMapping
            }
        }
        foreach ($Device in $DeviceList) {
            if ($Path.Contains($Device.DevicePath)) {
                $ConvertedPath = $Path.Replace($Device.DevicePath, $Device.DriveLetter)
            }
        }
    }
    end {
        return $ConvertedPath
    }
}