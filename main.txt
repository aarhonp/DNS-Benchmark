# DNS Benchmark Script
# Tests multiple DNS servers for latency and packet loss, then generates an HTML report.

# Define DNS servers and domains
$dnsServers = @("8.8.8.8", "8.8.4.4", "1.1.1.1", "1.0.0.1", "9.9.9.9", "208.67.222.222")
$domains = @("google.com", "yahoo.com", "microsoft.com")

# Initialize an empty array to hold the results
$results = @()

# Notify user the script is running
Write-Host "Please wait, processing DNS benchmark results..."

# Function to test DNS latency and packet loss
function Test-Dns {
    param ($DNSServer, $Domain)

    $startTime = Get-Date
    $response = Resolve-DnsName -Server $DNSServer -Name $Domain -ErrorAction SilentlyContinue
    $endTime = Get-Date

    if ($response) {
        $latency = ($endTime - $startTime).TotalMilliseconds
        $packetLoss = 0
        $success = $true
        $error = ""
    } else {
        $latency = "N/A"
        $packetLoss = "N/A"
        $success = $false
        $error = "Failed to resolve"
    }

    return [PSCustomObject]@{
        DNSServer = $DNSServer
        Domain = $Domain
        Success = $success
        Latency = $latency
        PacketLoss = $packetLoss
        Error = $error
    }
}

# Run DNS benchmark for each server and domain
foreach ($server in $dnsServers) {
    foreach ($domain in $domains) {
        $testResult = Test-Dns -DNSServer $server -Domain $domain
        $results += $testResult
    }
}

# Sort results by latency (lowest first)
$sortedResults = $results | Where-Object { $_.Latency -ne "N/A" } | Sort-Object Latency

# Calculate average latency for each DNS server
$averageResults = $sortedResults | Group-Object -Property DNSServer | ForEach-Object {
    $avgLatency = ($_.Group | Measure-Object -Property Latency -Average).Average
    [PSCustomObject]@{
        DNSServer = $_.Name
        AvgLatency = [math]::Round($avgLatency, 2)
    }
} | Sort-Object AvgLatency

# Assign medals based on average latency
$gold = $averageResults[0]
$silver = $averageResults[1]
$bronze = $averageResults[2]

# 
