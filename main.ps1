# Sample DNS servers and domains with added entries
$dnsServers = @("8.8.8.8", "1.1.1.1", "9.9.9.9", "208.67.222.222", "8.8.4.4", "1.0.0.1")
$domains = @("google.com", "yahoo.com", "microsoft.com")

# Initialize an empty array to hold the results
$results = @()

# Notify user the script is working
Write-Host "Please wait, processing DNS benchmark results..."

# Test each DNS server and domain combination
foreach ($server in $dnsServers) {
    foreach ($domain in $domains) {
        $testResult = Test-Dns -DNSServer $server -Domain $domain
        # Add the test result to the results array
        $results += $testResult
    }
}

# After testing, check if the results array contains data
Write-Host "`nResults collected:`n"
$results | Format-Table -AutoSize

# Sort the results by DNS Server and then by latency (ascending)
$sortedResults = $results | Sort-Object DNSServer, Latency

# Calculate the average latency and packet loss for each DNS server
$dnsAverages = @()

# Group the results by DNS Server and calculate averages
$groupedResults = $sortedResults | Group-Object DNSServer
foreach ($group in $groupedResults) {
    $totalLatency = 0
    $totalPacketLoss = 0
    $domainCount = 0
    foreach ($result in $group.Group) {
        $totalLatency += $result.Latency
        $totalPacketLoss += $result.PacketLoss
        $domainCount++
    }
    
    # Calculate the average for this DNS server
    $averageLatency = [math]::round($totalLatency / $domainCount, 4)
    $averagePacketLoss = [math]::round($totalPacketLoss / $domainCount, 4)
    
    # Add the average results to the dnsAverages array
    $dnsAverages += [PSCustomObject]@{
        DNSServer = $group.Name
        AverageLatency = $averageLatency
        AveragePacketLoss = $averagePacketLoss
    }
}

# Sort the averages by AverageLatency (ascending)
$sortedAverages = $dnsAverages | Sort-Object AverageLatency

# Define the path to save the HTML file in the Documents folder
$documentsPath = [System.Environment]::GetFolderPath('MyDocuments')
$filePath = Join-Path -Path $documentsPath -ChildPath "dns_results.html"

# Prepare the basic HTML content with a more organized table structure
$htmlContent = "<html><head><style>body {font-family: Arial, sans-serif; background-color: #f9f9f9;} table {width: 100%; border-collapse: collapse; margin: 20px 0;} th, td {border: 1px solid #ddd; padding: 10px; text-align: left;} th {background-color: #4CAF50; color: white;} tr:nth-child(even) {background-color: #f2f2f2;} tr:hover {background-color: #ddd;} .header {font-size: 24px; font-weight: bold; text-align: center; margin: 20px 0;} .dnsServer {font-size: 20px; font-weight: bold; color: #4CAF50; margin-top: 20px;} .winners {font-size: 20px; font-weight: bold; color: gold; text-align: center;} .gold {color: gold;} .silver {color: silver;} .bronze {color: #cd7f32;}</style></head><body>"

# Add title to the HTML content
$htmlContent += "<div class='header'>DNS Benchmark Results</div>"

# Add the "Winners" table at the top of the page
$htmlContent += "<div class='winners'>Winners: Top 3 DNS Servers</div>"
$htmlContent += "<table><thead><tr><th>Rank</th><th>DNS Server</th><th>Average Latency (ms)</th><th>Average Packet Loss (%)</th></tr></thead><tbody>"

# Add Gold, Silver, and Bronze rows for the top 3 DNS servers
$rank = 1
foreach ($server in $sortedAverages[0..2]) {
    $medalClass = ""
    switch ($rank) {
        1 { $medalClass = "gold" }
        2 { $medalClass = "silver" }
        3 { $medalClass = "bronze" }
    }

    $htmlContent += "<tr class='$medalClass'><td>$rank</td><td>$($server.DNSServer)</td><td>$([math]::round($server.AverageLatency, 4))</td><td>$([math]::round($server.AveragePacketLoss, 4))</td></tr>"
    $rank++
}

# Close the Winners table
$htmlContent += "</tbody></table>"

# Group the results by DNS Server again to create the detailed table below
# Group the results by DNS Server
$groupedResults = $sortedResults | Group-Object DNSServer

# Loop through each grouped DNS server and build HTML content
foreach ($group in $groupedResults) {
    $htmlContent += "<div class='dnsServer'>DNS Server: $($group.Name)</div>"
    
    # Start the table for each DNS server
    $htmlContent += "<table><thead><tr><th>Domain</th><th>Success</th><th>Latency (ms)</th><th>PacketLoss (%)</th><th>Error</th></tr></thead><tbody>"

    # Add rows for each domain under this DNS server
    $totalLatency = 0
    $totalPacketLoss = 0
    $domainCount = 0
    foreach ($result in $group.Group) {
        $htmlContent += "<tr>"
        $htmlContent += "<td>$($result.Domain)</td>"
        $htmlContent += "<td>$($result.Success)</td>"
        $htmlContent += "<td>$([math]::round($result.Latency, 4))</td>"  # Round latency to 4 decimal places
        $htmlContent += "<td>$($result.PacketLoss)</td>"
        $htmlContent += "<td>$($result.Error)</td>"
        $htmlContent += "</tr>"
        
        # Add to totals for average calculation
        $totalLatency += $result.Latency
        $totalPacketLoss += $result.PacketLoss
        $domainCount++
    }

    # Calculate the averages for this DNS server
    $averageLatency = [math]::round($totalLatency / $domainCount, 4)
    $averagePacketLoss = [math]::round($totalPacketLoss / $domainCount, 4)

    # Add an average row after listing domains
    $htmlContent += "<tr style='font-weight: bold;'><td>Average</td><td>-</td><td>$averageLatency</td><td>$averagePacketLoss</td><td>-</td></tr>"
    
    # Close the table for this DNS server
    $htmlContent += "</tbody></table>"
}

# Close the HTML tags
$htmlContent += "</body></html>"

# Save the HTML content to the file
$htmlContent | Out-File -FilePath $filePath

# Open the HTML file
Start-Process $filePath

Write-Host "`nResults exported to '$filePath' and opened in browser."
