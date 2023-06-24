param(
    [string]$path,
    [string[]]$extensions
)

function Find-ReplaceToken {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$String, #String that you want to replace tokens in
        [string]$TokenPrefix = "#{",
        [string]$TokenSuffix = "}#"
    )
    $ret = [System.Text.StringBuilder]::new($String)
    $found = New-Object 'System.Collections.Stack'
    $charArr = $String.ToCharArray() 
    $start = -1
    $stop = -1
    $token = [System.Text.StringBuilder]::new()
    For ($i=0; $i -le $charArr.Length; $i++) {
        if ($start -ne -1){
            $null = $token.Append($charArr[$i])
        }
        if ($charArr[$i] -eq "`n"){
            $start = -1
            $stop = -1
            $null = $token.Clear()
        }
        elseif($start -ne -1 -and $String.Substring($i-$TokenPrefix.Length, $TokenPrefix.Length) -eq $TokenPrefix -and $charArr[$i - $TokenPrefix.Length] -eq $TokenPrefix[$TokenPrefix.Length-1]){
            $start = -1
            $stop = -1
            $null = $token.Clear()
            $i--
        }
        elseif ($start -ne -1 -and $i -lt $String.Length - $TokenPrefix.Length -and $String.Substring($i-$TokenSuffix.Length+1, $TokenSuffix.Length) -eq $TokenSuffix){
            $stop = $i+1
            $found.Push([System.Tuple]::Create($start, $stop, $token.ToString()))
            write-host "TOKEN FOUND - $($token.ToString())"
            $i--
            $start = -1
            $stop = -1
            $null = $token.Clear()
    }
        elseif ($i -ge $TokenPrefix.Length -and $String.Substring($i-$TokenPrefix.Length, $TokenPrefix.Length) -eq $TokenPrefix){
            if ($start -eq -1){
                $start = $i-$TokenPrefix.Length
                $null = $token.Append($TokenPrefix)
                $null = $token.Append($charArr[$i])
            }
        }
    }
    $replacedTokens = $false
    while ($found.Count -gt 0){
        $t = $found.Pop()
        $var = $t.Item3.TrimStart($TokenPrefix).TrimEnd($TokenSuffix)
        if ($null -ne [System.Environment]::GetEnvironmentVariable($var)){
            write-host "REPLACING $($t.Item3) with $([System.Environment]::GetEnvironmentVariable($var))"
            $replacedTokens = $true
            $null = $ret.Remove($t.Item1, $t.Item2 - $t.Item1)
            $null = $ret.Insert($t.Item1, [System.Environment]::GetEnvironmentVariable($var), 1)
        }else{
            write-host "Environment Variable $var not found."
        }
    }
    if ($replacedTokens){
        return $ret.ToString()
    }
    return [string]::Empty
}
 
gci $path -Include $extensions -Recurse -File | ForEach-Object{
    $FileContents = "$(Get-Content $_.FullName -Raw)"

    if([string]::IsNullOrWhiteSpace($FileContents))
    {
        Write-Host "Skipping empty file $($_.FullName)"
        return
    }

    $contents = Find-ReplaceToken -String $FileContents
    if (-not [string]::IsNullOrWhiteSpace($contents)){
        write-host "Replacing tokens in file: $($_.FullName)"
        Set-Content -Path $_.FullName -Value $contents
    }
}

<# Reference to the string replace function above
$fullName = $path.Fullname 
$contents = Find-ReplaceToken -String "$(Get-Content $fullName -Raw)"
if (-not [string]::IsNullOrWhiteSpace($contents)){
    write-host "Replacing tokens in file: $fullName"
    Set-Content -Path $fullName -Value $contents
}#>
