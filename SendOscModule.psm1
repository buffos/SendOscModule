function Send-OscMessage {
    param (
        [string]$IPAddress = "127.0.0.1",
        [int]$Port = 8000,
        [string]$AddressPattern,
        [array]$Arguments,
        [switch]$Debug
    )

    # Helper functions
    function Convert-To-OscBytes {
        param ([string]$String)
        # Convert string to bytes
        $bytes = [System.Text.Encoding]::ASCII.GetBytes($String)
        # Pad bytes to 4-byte alignment
        $padding = 4 - ($bytes.Length % 4) # Calculate how many bytes to pad
        if ($padding -eq 4) { $padding = 0 } # If padding is 4, set it to 0
        $result = New-Object byte[] ($bytes.Length + $padding) # Create a new byte array with the padded length
        [Array]::Copy($bytes, $result, $bytes.Length) # Copy the bytes to the new array
        return $result
    }

    function Convert-To-OscIntBytes {
        param ([int]$Integer)
        # Convert integer to bytes (big-endian). Network order is big-endian.
        # Big-endian means the most significant byte is at the smallest address.
        # Example: 0x12345678 is stored as 0x12, 0x34, 0x56, 0x78.
        return [BitConverter]::GetBytes([System.Net.IPAddress]::HostToNetworkOrder($Integer))
    }

    function Convert-To-OscFloatBytes {
        param ([float]$Float)
        $bytes = [BitConverter]::GetBytes($Float)
        [Array]::Reverse($bytes) # Convert to big-endian as OSC requires
        return $bytes
    }

    try {
        $messageBytes = @()

        # Add address pattern
        $addressBytes = Convert-To-OscBytes -String $AddressPattern
        $messageBytes += $addressBytes
        if ($Debug) {
            Write-Host "Address Pattern: $AddressPattern"
            Write-Host "Address Pattern Bytes: $($addressBytes | ForEach-Object { $_.ToString('X2') })"
        }

        # Build type tag
        $typeTag = ","
        foreach ($arg in $Arguments) {
            if ($arg -is [string]) { $typeTag += "s" }
            elseif ($arg -is [int]) { $typeTag += "i" }
            elseif ($arg -is [float] -or $arg -is [double]) { $typeTag += "f" }
        }

        # Get type tag bytes with proper padding
        $typeTagBytes = [System.Text.Encoding]::ASCII.GetBytes($typeTag)
        $paddedLength = if ($Arguments.Count -ge 3) { 8 } else { 4 }
        $paddedTypeTag = New-Object byte[] $paddedLength
        [Array]::Copy($typeTagBytes, $paddedTypeTag, $typeTagBytes.Length)
        $messageBytes += $paddedTypeTag

        if ($Debug) {
            Write-Host "Type Tag: $typeTag"
            Write-Host "Raw Type Tag Bytes: $($typeTagBytes | ForEach-Object { $_.ToString('X2') })"
            Write-Host "Padded Type Tag Bytes: $($paddedTypeTag | ForEach-Object { $_.ToString('X2') })"
            Write-Host "Type Tag Length: $($paddedTypeTag.Length)"
        }

        # Add arguments
        foreach ($arg in $Arguments) {
            if ($Debug) { Write-Host "Processing argument: $arg (Type: $($arg.GetType().Name))" }

            if ($arg -is [string]) {
                $argBytes = Convert-To-OscBytes -String $arg
                $messageBytes += $argBytes
                if ($Debug) { Write-Host "String Arg Bytes: $($argBytes | ForEach-Object { $_.ToString('X2') })" }
            }
            elseif ($arg -is [int]) {
                $argBytes = Convert-To-OscIntBytes -Integer $arg
                $messageBytes += $argBytes
                if ($Debug) { Write-Host "Int Arg Bytes: $($argBytes | ForEach-Object { $_.ToString('X2') })" }
            }
            elseif ($arg -is [float] -or $arg -is [double]) {
                if ($arg -is [double]) { $arg = [float]$arg }
                $argBytes = Convert-To-OscFloatBytes -Float $arg
                $messageBytes += $argBytes
                if ($Debug) { Write-Host "Float Arg Bytes: $($argBytes | ForEach-Object { $_.ToString('X2') })" }
            }
        }

        if ($Debug) {
            Write-Host "Total message length: $($messageBytes.Length) bytes"
            Write-Host "Final message bytes: $($messageBytes | ForEach-Object { $_.ToString('X2') })"
        }

        # Send message
        $udpClient = New-Object System.Net.Sockets.UdpClient
        $udpClient.Connect($IPAddress, $Port)
        $udpClient.Send($messageBytes, $messageBytes.Length) | Out-Null
        $udpClient.Close()
    }
    catch {
        Write-Error "Error sending OSC message: $_"
        throw
    }
}

# Example: Send a universal OSC message
# Send-OscMessage -IPAddress "127.0.0.1" -Port 8000 -AddressPattern "/reset_headphones" -Arguments @(1)
