Clear-Host
Write-Host "Windows Server csv / txt file generator"
Write-Host "                __  _       _             __ _ _                     
  __ ____ __   / / | |___ _| |_    ___   / _(_) |___   __ _ ___ _ _  
 / _(_-< V /  / /  |  _\ \ /  _|  |___| |  _| | / -_) / _` / -_) ' \ 
 \__/__/\_/  /_/    \__/_\_\\__|        |_| |_|_\___| \__, \___|_||_|
                                                      |___/          "
Write-Host "   __                           _       _    ____                    __  
  / /  __ __    __ _  ___ _____(_)__   (_)__/ / /  _______ ___  ___ / /__
 / _ \/ // /   /  ' \/ _ `/ __/ / -_) / / _  / _ \/ __/_ // _ \(_-</  '_/
/_.__/\_, /   /_/_/_/\_,_/\__/_/\__/_/ /\_,_/_.__/_/  /__/_//_/___/_/\_\ 
     /___/                        |___/                                  "
Write-Host ""
Write-Host ""
Write-Host "-----------------| NIE UZYWAC POLSKICH ZNAKOW! |-----------------" -ForegroundColor Red -BackgroundColor Blue
Write-Host ""
Write-Host ""

$wybor = Read-Host "Co chcesz zrobic? Wpisz 'ldif' lub 'csv'"

if ($wybor -ieq "ldif") {
    
    $outputFile = "user.txt"
    if (Test-Path $outputFile) { Remove-Item $outputFile }

    $domena = Read-Host "Podaj domene (np. elektronik.local)"
    $dcPart = ($domena -split '\.') -join ",DC="
    $dcPart = "DC=" + $dcPart

    $akcja = Read-Host "Chcesz dodac czy usunac obiekt? (wpisz 'add' lub 'delete')"
    $typObiektu = Read-Host "Jaki obiekt chcesz przetworzyc? (wpisz 'user' lub 'group')"
    $kontenerInput = Read-Host "Podaj kontener/ou (wpisz 'Users' lub nazwe OU)"
    if ($kontenerInput -ieq "Users") {
        $kontener = "CN=Users"
    } else {
        $kontener = "OU=" + $kontenerInput
    }

    if ($akcja -ieq "delete") {
        do {
            $cn = Read-Host "Podaj CN obiektu do usuniecia (np. James JB. Bond lub Testowa)"
            $dnLine = "DN: CN=$cn,$kontener,$dcPart"
            $ldif = @"
$dnLine
changetype: delete
"@
            $ldif | Out-File -FilePath $outputFile -Encoding UTF8 -Append
            $kolejny = Read-Host "Czy chcesz usunac kolejny obiekt? (wpisz 'tak' lub 'nie')"
        } while ($kolejny -ieq "tak")
        Write-Host "Plik LDIF utworzony: $outputFile"
    }

    elseif ($akcja -ieq "add" -and $typObiektu -ieq "user") {
        $cn = Read-Host "Wpisz CN (pelna nazwa, np. James JB. Bond)"
        $sn = Read-Host "Wpisz nazwisko (np. Bond)"
        $givenName = Read-Host "Wpisz imie (np. James)"
        $initials = Read-Host "Wpisz inicjaly (np. JB)"
        $userAccountControl = Read-Host "Wpisz userAccountControl (domyslnie 544)"
        $sAMAccountName = $cn
        $dnLine = "DN: CN=$cn,$kontener,$dcPart"
        $ldif = @"
$dnLine
changetype: add
objectClass: user
cn: $cn
sn: $sn
givenName: $givenName
initials: $initials
userAccountControl $userAccountControl
sAMAccountName: $sAMAccountName
"@
        $ldif | Out-File -FilePath $outputFile -Encoding UTF8 -Append
        Write-Host "Plik LDIF utworzony: $outputFile"
    }
    elseif ($akcja -ieq "add" -and $typObiektu -ieq "group") {
        $cn = Read-Host "Podaj CN grupy (np. Testowa)"
        $description = Read-Host "Podaj opis grupy (np. Testowa Grupa)"
        $dnLine = "DN: CN=$cn,$kontener,$dcPart"
        $ldif = @"
$dnLine
changetype: add
objectClass: group
cn: $cn
description: $description
name: $cn
"@
        $dodacUzytkownikow = Read-Host "Czy chcesz dodac uzytkownikow do grupy? (wpisz 'tak' lub 'nie')"
        if ($dodacUzytkownikow -ieq "tak") {
            do {
                $member = Read-Host "Podaj CN uzytkownika do dodania (np. James JB. Bond)"
                $memberContainer = Read-Host "Podaj kontener/OU uzytkownika (np. Users lub Informatycy)"
                if ($memberContainer -ieq "Users") {
                    $memberDN = "CN=$member,CN=Users,$dcPart"
                } else {
                    $memberDN = "CN=$member,OU=$memberContainer,$dcPart"
                }
                $ldif += "member: $memberDN`n"
                $kolejny = Read-Host "Czy chcesz dodac kolejnego uzytkownika? (wpisz 'tak' lub 'nie')"
            } while ($kolejny -ieq "tak")
        }
        $ldif | Out-File -FilePath $outputFile -Encoding UTF8 -Append
        Write-Host "Plik LDIF utworzony: $outputFile"
    }
}

elseif ($wybor -ieq "csv") {
    $csvFile = "users.csv"
    $header = "sAMAccountName,Name,surname,GivenName,password,UserPrincipalName,Description,Company,Department"
    $header | Out-File -FilePath $csvFile -Encoding UTF8

    $n = Read-Host "Podaj liczbe uzytkownikow do dodania"
    
    $sAMAccountName   = Read-Host "Podaj sAMAccountName (np. James JB. Bond)"
    $Name             = Read-Host "Podaj Name (np. James JB. Bond)"
    $surname          = Read-Host "Podaj surname (np. Bond)"
    $GivenName        = Read-Host "Podaj GivenName (np. James)"
    $password         = Read-Host "Podaj password (np. 1qazXSW@)"
    $UserPrincipalName= Read-Host "Podaj UserPrincipalName (np. jamesbond@elektronik.local)"
    $Description      = Read-Host "Podaj Description (np. Opis)"
    $Company          = Read-Host "Podaj Company (np. ZSE)"
    $Department       = Read-Host "Podaj Department (np. Informatyka)"

    for ($i = 0; $i -lt [int]$n; $i++) {
        $newSAMAccountName = "$sAMAccountName$i"
        $newName = "$Name$i"
        $emailParts = $UserPrincipalName -split "@"
        $newUserPrincipalName = "$($emailParts[0])$i@$($emailParts[1])"
        $newLine = "$newSAMAccountName,$newName,$surname,$GivenName,$password,$newUserPrincipalName,$Description,$Company,$Department"
        $newLine | Out-File -FilePath $csvFile -Append -Encoding UTF8
    }
    Write-Host "Plik CSV utworzony: $csvFile"
}
else {
    Write-Host "Niepoprawna opcja."
}
