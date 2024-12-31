function Test-NetworkRange {
    param(
        [Parameter(Mandatory=$true)]
        [string]$StartIP,

        [Parameter(Mandatory=$true)]
        [string]$EndIP,

        [Parameter(Mandatory=$false)]
        [int]$TimeoutMilliseconds = 1000
    )

    Write-Host "Testing network range from $StartIP to $EndIP" -ForegroundColor Cyan

    # Validate IP range
    function Test-IPValidity {
        param([string]$ip)
        return [System.Net.IPAddress]::TryParse($ip, [ref]([System.Net.IPAddress]::Any))
    }

    if (-not (Test-IPValidity -ip $StartIP) -or -not (Test-IPValidity -ip $EndIP)) {
        Write-Host "Invalid IP address provided." -ForegroundColor Red
        return
    }

    # Convert IP addresses to numbers for comparison
    function Convert-IPToInt {
        param([string]$ip)
        return [System.Net.IPAddress]::Parse($ip).GetAddressBytes() | ForEach-Object { $_ }
    }

    function Convert-IntToIP {
        param([int64]$int)
        return [System.Net.IPAddress]::Parse($int.ToString())
    }

    $startInt = Convert-IPToInt -ip $StartIP
    $endInt = Convert-IPToInt -ip $EndIP

    if ($startInt -gt $endInt) {
        Write-Host "Start IP must be less than or equal to End IP." -ForegroundColor Red
        return
    }

    # Results array
    $results = @()

    # Create jobs in smaller batches to prevent overwhelming the system
    $batchSize = 256
    $totalIPs = $endInt - $startInt + 1
    $processed = 0
    $currentInt = $startInt

    while ($currentInt -le $endInt) {
        $batchEnd = [math]::Min($currentInt + $batchSize - 1, $endInt)
        $batchIPs = $currentInt..$batchEnd

        $results += $batchIPs | ForEach-Object -Parallel {
            param($ipInt, $timeout)

            $ip = [System.Net.IPAddress]::Parse($ipInt.ToString()).ToString()
            $ping = New-Object System.Net.NetworkInformation.Ping
            
            try {
                $reply = $ping.Send($ip, $timeout)
                if ($reply.Status -eq 'Success') {
                    $hostname = "N/A"
                    $macAddress = "N/A"

                    try {
                        $hostname = [System.Net.Dns]::GetHostEntry($ip).HostName
                    } catch {}

                    try {
                        $arpEntry = arp -a | Select-String $ip | ForEach-Object { ($_ -split '\s+')[1] }
                        $macAddress = if ($arpEntry) { $arpEntry } else { "N/A" }
                    } catch {}

                    return @{
                        IP = $ip
                        Hostname = $hostname
                        Status = $reply.Status
                        ResponseTime = $reply.RoundtripTime
                        MacAddress = $macAddress
                    }
                }
            } catch {
                Write-Host "Error pinging $ip $_" -ForegroundColor Red
            }
        } -ArgumentList $_, $TimeoutMilliseconds -ThrottleLimit $batchSize

        $currentInt = $batchEnd + 1
        $processed += $batchIPs.Count

        Write-Progress -Activity "Scanning Network Range" -Status "$processed/$totalIPs IPs" -PercentComplete (($processed / $totalIPs) * 100)
    }

    # Output results
    $results | Sort-Object IP | Format-Table -AutoSize

    # Export to CSV
    $exportPath = ".\network_scan_results_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    $results | Export-Csv -Path $exportPath -NoTypeInformation
    Write-Host "Scan results exported to $exportPath" -ForegroundColor Green

    return $results
}
