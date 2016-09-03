Get-Content "settings.txt" | foreach-object -begin {$h=@{}} -process { $k = [regex]::split($_,'='); if(($k[0].CompareTo("") -ne 0) -and ($k[0].StartsWith("[") -ne $True)) { $h.Add($k[0], $k[1]) } }

Write-Host "Setting up variables..."
$Date = Get-Date -Format yyyyMMddHHmmss
$PGDumpPath = Join-Path -Path $h.PostgreSQLPath -ChildPath pg_dump.exe
$APGDiffPath = Join-Path $h.APGDiffPath -ChildPath $h.APGDiffExecutable
$awsDumpFile = Join-Path -Path $h.OutputPath -ChildPath "awsDump$Date.backup"
$awsSQLDumpFile = Join-Path -Path $h.OutputPath -ChildPath "awsSQLDump$Date.sql"
$localDumpFile = Join-Path -Path $h.OutputPath -ChildPath "localDump$Date.backup"
$localSQLDumpFile = Join-Path -Path $h.OutputPath -ChildPath "localSqlDump$Date.sql"
$upgradeSQLFile = Join-Path -Path $h.OutputPath -ChildPath "updateSQL$Date.sql"
Write-Host "Dumping remote database schema..."
Start-Process -FilePath $PGDumpPath -ArgumentList "-h $($h.RemoteHost) -p $($h.DatabasePort) -U postgres -F c -b -v -f $awsDumpFile -s $($h.DatabaseName)" -Wait -RedirectStandardOutput "output.txt" -RedirectStandardError "error.txt"
Start-Process -FilePath $PGDumpPath -ArgumentList "-h $($h.RemoteHost) -p $($h.DatabasePort) -U postgres -F p -b -f $awsSQLDumpFile -s $($h.DatabaseName)" -Wait -RedirectStandardOutput "output.txt" -RedirectStandardError "error.txt"

Write-Host "Dumping local database schema..."
Set-Item -Force -Path env:PGPASSWORD -Value $h.DatabasePassword
Start-Process -FilePath $PGDumpPath -ArgumentList "-h localhost -p $($h.DatabasePort) -U postgres -F c -b -v -f $localDumpFile -s $($h.DatabaseName)" -Wait
Start-Process -FilePath $PGDumpPath -ArgumentList "-h localhost -p $($h.DatabasePort) -U postgres -F p -b -f $localSQLDumpFile -s $($h.DatabaseName)" -Wait

Write-Host "Running comparison..."
$argumentAPGDiff = "java -jar $APGDiffPath ""$awsSQLDumpFile"" ""$localSQLDumpFile"" > ""$upgradeSQLFile"""
$outputAPGDiff = Invoke-Expression $argumentAPGDiff -Verbose
Write-Host $outputAPGDiff



