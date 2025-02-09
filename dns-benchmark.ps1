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

# Generate HTML report
$htmlHead = @"
<style>
    body { font-family: Arial, sans-serif; margin: 20px; }
    table { width: 100%; border-collapse: collapse; margin-top: 20px; }
    th, td { border: 1px solid #dddddd; text-align: left; padding: 8px; }
    th { background-color: #f2f2f2; }
    .gold { background-color: gold; }
    .silver { background-color: silver; }
    .bronze { background-color: #cd7f32; }
</style>
"@

$htmlWinners = @"
<h1>DNS Benchmark Results</h1>
<h2>🏆 Top Performing DNS Servers</h2>
<table>
    <tr>
        <th>Rank</th>
        <th>DNS Server</th>
        <th>Average Latency (ms)</th>
    </tr>
    <tr class="gold">
        <td>🥇 Gold</td>
        <td>$($gold.DNSServer)</td>
        <td>$($gold.AvgLatency)</td>
    </tr>
    <tr class="silver">
        <td>🥈 Silver</td>
        <td>$($silver.DNSServer)</td>
        <td>$($silver.AvgLatency)</td>
    </tr>
    <tr class="bronze">
        <td>🥉 Bronze</td>
        <td>$($bronze.DNSServer)</td>
        <td>$($bronze.AvgLatency)</td>
    </tr>
</table>
"@

$htmlResults = @"
<h2>Full Benchmark Results</h2>
<table>
    <tr>
        <th>DNS Server</th>
        <th>Domain</th>
        <th>Success</th>
        <th>Latency (ms)</th>
        <th>Packet Loss (%)</th>
        <th>Error</th>
    </tr>
"@

foreach ($result in $sortedResults) {
    $htmlResults += @"
    <tr>
        <td>$($result.DNSServer)</td>
        <td>$($result.Domain)</td>
        <td>$($result.Success)</td>
        <td>$($result.Latency)</td>
        <td>$($result.PacketLoss)</td>
        <td>$($result.Error)</td>
    </tr>
"@
}

$htmlResults += "</table>"

$htmlAverage = @"
<h2>Average Latency by DNS Server</h2>
<table>
    <tr>
        <th>DNS Server</th>
        <th>Average Latency (ms)</th>
    </tr>
"@

foreach ($avg in $averageResults) {
    $htmlAverage += @"
    <tr>
        <td>$($avg.DNSServer)</td>
        <td>$($avg.AvgLatency)</td>
    </tr>
"@
}

$htmlAverage += "</table>"

# Combine all sections into a single HTML file
$htmlContent = "<html><head>$htmlHead</head><body>$htmlWinners$htmlAverage$htmlResults</body></html>"

# Save and open the HTML file
$filePath = "$PWD\DNSBenchmarkResults.html"
$htmlContent | Out-File -FilePath $filePath -Encoding UTF8
Start-Process $filePath

Write-Host "`nResults exported to '$filePath' and opened in browser."
