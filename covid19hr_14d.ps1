$data = Invoke-RestMethod -Uri "https://www.koronavirus.hr/json/?action=podaci"

$derivedData = $data | ForEach-Object {
  $dtDateTime = [datetime]::parseexact($_.Datum, 'yyyy-MM-dd HH:mm', $null);
  $dtDateOnly = $dtDateTime.AddHours(-$dtDateTime.Hour).AddMinutes(-$dtDateTime.Minute);
  return [pscustomobject]@{
    Date = $dtDateOnly;
    DateText = $dtDateOnly.tostring("dd.MM.yyyy.");
    Total = $_.SlucajeviHrvatska
  } 
} | Sort-Object -Property Date

foreach ($ix in (1..($derivedData.Count - 1)))
{
  $new =  $derivedData[$ix].Total - $derivedData[$ix - 1].Total
  $derivedData[$ix] | Add-Member -MemberType NoteProperty -Name "New" -Value $new -Force
}

$lastDays = 14

$start = Get-Date (Get-Date).AddDays(-$lastDays)
$filteredData = $derivedData | Where-Object { $_.Date -ge $start }
$filteredData | Format-Table -Property DateText,Total,New

$totalCasesInScope = ($filteredData | Measure-Object -Property New -Sum).Sum
Write-Host "Total cases in last $lastDays days: $totalCasesInScope"

$totalCitizens2019 = 4058165
Write-Host "Number of citizens: $totalCitizens2019"

$totalCasesPer100k = 100000 * $totalCasesInScope / 4058165
$totalCasesPer100kText = "{0:N2}" -f $totalCasesPer100k
Write-Host "Number of cases per 100k: $totalCasesPer100kText"

$percentUntilCritical = ($totalCasesPer100k / 40) * 100
$percentOverCritical = $percentUntilCritical - 100
$percentUntilCriticalText = "{0:N2}" -f $percentUntilCritical
$percentOverCriticalText = "{0:N2}" -f $percentOverCritical
if($percentUntilCritical -lt 100) {
  Write-Host "Percent until critical: $percentUntilCriticalText%"
} else {
  Write-Host "Percent OVER critical: $percentOverCriticalText%"
}
