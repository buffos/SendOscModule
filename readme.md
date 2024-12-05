# SendOscModule

## Introduction

SendOscModule is a PowerShell module that enables sending OSC (Open Sound Control) messages from PowerShell scripts. OSC is a protocol for networking sound synthesizers, computers, and other multimedia devices for purposes such as musical performance or show control.

This module is particularly useful for:
- Automating audio software that accepts OSC commands
- Controlling lighting systems via OSC
- Testing OSC-enabled applications
- Integrating PowerShell scripts with multimedia systems
- Show control and automation

## What This Module Does

SendOscModule provides a simple way to:
1. Construct properly formatted OSC messages
2. Send these messages via UDP to any OSC-capable receiver
3. Handle different data types (integers, floats, strings)
4. Debug OSC message construction and transmission

## Installation

1. Copy the `SendOscModule.psm1` file to your PowerShell modules directory:
   ```powershell
   $env:PSModulePath.Split(';')[0]
   ```
2. Import the module:
   ```powershell
   Import-Module SendOscModule
   ```

## Usage Guide

### Basic Concepts

OSC messages consist of three main components:
1. An address pattern (like "/volume" or "/light/1")
2. A type tag string indicating the types of arguments
3. The argument values themselves

### Common Use Cases

1. **Simple Control Messages**
   ```powershell
   # Turn something on
   Send-OscMessage -AddressPattern "/power" -Arguments @(1)
   
   # Set a volume level
   Send-OscMessage -AddressPattern "/volume" -Arguments @(0.75)
   ```

2. **Multiple Parameters**
   ```powershell
   # Control RGB values
   Send-OscMessage -AddressPattern "/color" -Arguments @(255, 128, 0)
   
   # Set multiple properties
   Send-OscMessage -AddressPattern "/instrument/1" -Arguments @("piano", 0.8, 1)
   ```

3. **Show Control**
   ```powershell
   # Trigger cues
   Send-OscMessage -AddressPattern "/cue/1" -Arguments @("START")
   
   # Set multiple parameters
   Send-OscMessage -AddressPattern "/scene" -Arguments @(5, "fade", 3.5)
   ```

4. **Debugging**
   ```powershell
   # See exactly what's being sent
   Send-OscMessage -AddressPattern "/test" -Arguments @(1, 2) -Debug
   ```

### Integration Examples

1. **Audio Software Control**
   ```powershell
   # Create a simple volume fade
   1..100 | ForEach-Object {
       $volume = $_ / 100
       Send-OscMessage -AddressPattern "/volume" -Arguments @($volume)
       Start-Sleep -Milliseconds 50
   }
   ```

2. **Lighting Control**
   ```powershell
   # Create a light chase effect
   1..4 | ForEach-Object {
       $light = $_
       Send-OscMessage -AddressPattern "/light/$light" -Arguments @(1)
       Start-Sleep -Milliseconds 200
       Send-OscMessage -AddressPattern "/light/$light" -Arguments @(0)
   }
   ```

3. **Batch Processing**
   ```powershell
   # Send multiple related commands
   $cues = @(
       @{Pattern="/cue/1"; Args=@(1)},
       @{Pattern="/cue/2"; Args=@(0.5)},
       @{Pattern="/cue/3"; Args=@("start")}
   )
   
   foreach ($cue in $cues) {
       Send-OscMessage -AddressPattern $cue.Pattern -Arguments $cue.Args
       Start-Sleep -Seconds 1
   }
   ```

### Best Practices

1. **Error Handling**
   ```powershell
   try {
       Send-OscMessage -AddressPattern "/important" -Arguments @(1)
   }
   catch {
       Write-Error "Failed to send OSC message: $_"
   }
   ```

2. **Testing Connectivity**
   ```powershell
   # Test with debug output first
   Send-OscMessage -AddressPattern "/test" -Arguments @(1) -Debug
   ```

3. **Performance Considerations**
   - For rapid message sequences, consider adding small delays
   - Be mindful of network capacity when sending large numbers of messages
   - Use arrays efficiently when sending multiple arguments


### Debug Output

When using the `-Debug` switch, the function outputs detailed information about the OSC message construction:
- Address pattern bytes
- Type tag construction
- Argument processing
- Final message bytes

This is useful for troubleshooting OSC communication issues.

## Technical Details

- Messages are constructed according to the OSC 1.0 specification
- All strings are null-padded to 4-byte boundaries
- Type tags are automatically generated based on argument types
- Integers are sent in big-endian format
- Floating-point numbers are converted to 32-bit format
- UDP is used for message transmission

## Error Handling

The module includes error handling for:
- UDP transmission errors
- Invalid argument types
- Message construction issues

Errors are reported through PowerShell's error stream and can be caught using standard try/catch blocks.

## Requirements

- PowerShell 5.1 or later
- Network connectivity to the target OSC server
- Appropriate firewall settings for UDP communication

## License

This module is provided as-is under the MIT license.