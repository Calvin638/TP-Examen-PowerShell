# maintenance-securite.ps1

Write-Host "--- Profils de pare-feu actifs ---" -ForegroundColor Cyan
Get-NetFirewallProfile | Where-Object { $_.Enabled } | Format-Table Name, Enabled, DefaultInboundAction, DefaultOutboundAction

# Définir le port à bloquer
$port = 4444
$ruleName = "BlocageSortantTCP_$port"

Write-Host "\n--- Création de la règle de blocage sortant sur le port TCP $port ---" -ForegroundColor Cyan
New-NetFirewallRule -DisplayName $ruleName -Direction Outbound -Action Block -Protocol TCP -LocalPort $port

Write-Host "\n--- Vérification de la règle ---" -ForegroundColor Cyan
Get-NetFirewallRule -DisplayName $ruleName | Format-Table Name, DisplayName, Enabled, Direction, Action

Write-Host "\n--- Suppression de la règle ---" -ForegroundColor Cyan
Remove-NetFirewallRule -DisplayName $ruleName

Write-Host "\nOpérations terminées." -ForegroundColor Green 

# --- Politique de pare-feu restrictive pour accès VPN ---

Write-Host "\n--- Application d'une politique restrictive sur le profil Privé ---" -ForegroundColor Yellow

# 1. Tout bloquer par défaut sur le profil Privé
Set-NetFirewallProfile -Profile Private -DefaultInboundAction Block -DefaultOutboundAction Block

# 2. Autoriser les services nécessaires (exemples à adapter)
# DNS (UDP 53)
New-NetFirewallRule -DisplayName "Autoriser DNS sortant" -Profile Private -Direction Outbound -Action Allow -Protocol UDP -RemotePort 53
# DHCP (UDP 67-68)
New-NetFirewallRule -DisplayName "Autoriser DHCP sortant" -Profile Private -Direction Outbound -Action Allow -Protocol UDP -RemotePort 67,68
# VPN (exemple : OpenVPN UDP 1194)
New-NetFirewallRule -DisplayName "Autoriser OpenVPN sortant" -Profile Private -Direction Outbound -Action Allow -Protocol UDP -RemotePort 1194
# HTTP/HTTPS
New-NetFirewallRule -DisplayName "Autoriser HTTP sortant" -Profile Private -Direction Outbound -Action Allow -Protocol TCP -RemotePort 80
New-NetFirewallRule -DisplayName "Autoriser HTTPS sortant" -Profile Private -Direction Outbound -Action Allow -Protocol TCP -RemotePort 443


# 3. Afficher la configuration finale
Write-Host "`n--- Profils de pare-feu (Privé) ---" -ForegroundColor Cyan
Get-NetFirewallProfile -Profile Private | Format-Table Name, Enabled, DefaultInboundAction, DefaultOutboundAction

Write-Host "`n--- Règles personnalisées (Privé) ---" -ForegroundColor Cyan
Get-NetFirewallRule | Where-Object { $_.Profile -eq 'Private' -and $_.DisplayName -like 'Autoriser*' } | Format-Table Name, DisplayName, Direction, Action, Enabled, Profile

Write-Host "`nPolitique restrictive appliquée. N'oubliez pas d'adapter les ports/services selon vos besoins VPN !" -ForegroundColor Green 

# --- Suppression des règles de la politique VPN si besoin ---

$reponse = Read-Host "Voulez-vous supprimer toutes les règles de la politique VPN ? (o/n)"
if ($reponse -eq 'o' -or $reponse -eq 'O') {
    Get-NetFirewallRule | Where-Object { $_.DisplayName -like 'Autoriser*' } | Remove-NetFirewallRule
    Write-Host "Règles de la politique VPN supprimées." -ForegroundColor Yellow
} else {
    Write-Host "Aucune règle supprimée." -ForegroundColor Gray
} 


# --- Vérification de la conformité du poste et génération d'une note de synthèse ---

Write-Host "\n--- Vérification de la conformité du poste ---" -ForegroundColor Yellow

# 1. Antivirus/Defender actif
$defenderStatus = $null
$antivirusActif = $false
try {
    $defenderStatus = Get-MpComputerStatus -ErrorAction Stop
    $antivirusActif = $defenderStatus.AntispywareEnabled -and $defenderStatus.RealTimeProtectionEnabled
} catch {
    $antivirusActif = $false
}

# 2. Mises à jour Windows appliquées
$updatesPending = $null
try {
    $pendingUpdates = (Get-WindowsUpdate -IsPending | Measure-Object).Count
    $updatesPending = $pendingUpdates -eq 0
} catch {
    $updatesPending = $false
}

# 3. Chiffrement BitLocker
$bitlockerStatus = $null
try {
    $bitlocker = Get-BitLockerVolume -MountPoint "C:" -ErrorAction Stop
    $bitlockerStatus = $bitlocker.ProtectionStatus -eq 1
} catch {
    $bitlockerStatus = $false
}

# 4. Journalisation locale
$journalisationActive = $null
try {
    $logSecurity = Get-WinEvent -ListLog Security -ErrorAction Stop
    $logSystem = Get-WinEvent -ListLog System -ErrorAction Stop
    $journalisationActive = $logSecurity.IsEnabled -and $logSystem.IsEnabled
} catch {
    $journalisationActive = $false
}

# 5. Génération de la note de synthèse
$synthese = @()
$synthese += "Note de synthèse de conformité du poste"
$synthese += "======================================="
$synthese += ""
$synthese += "- Antivirus/Defender actif : " + ($(if ($antivirusActif) {"Oui"} else {"Non"}))
$synthese += "- Mises à jour Windows appliquées : " + ($(if ($updatesPending) {"Oui"} else {"Non ou inconnu"}))
$synthese += "- Chiffrement BitLocker : " + ($(if ($bitlockerStatus) {"Oui"} else {"Non ou inconnu"}))
$synthese += "- Journalisation locale : " + ($(if ($journalisationActive) {"Oui"} else {"Non ou inconnu"}))
$synthese += ""
$synthese += "Commentaires :"
if (-not $antivirusActif) { $synthese += "- Antivirus ou protection en temps réel désactivé !" }
if (-not $updatesPending) { $synthese += "- Des mises à jour Windows sont en attente ou l'état n'a pas pu être vérifié." }
if (-not $bitlockerStatus) { $synthese += "- Le chiffrement BitLocker n'est pas actif ou n'a pas pu être vérifié." }
if (-not $journalisationActive) { $synthese += "- La journalisation locale n'est pas active ou n'a pas pu être vérifiée." }
if ($antivirusActif -and $updatesPending -and $bitlockerStatus -and $journalisationActive) {
    $synthese += "- Poste conforme aux exigences de sécurité de base."
}

$synthese | Set-Content -Path "synthese_conformite.txt" -Encoding UTF8

Write-Host "\nNote de synthèse générée dans synthese_conformite.txt" -ForegroundColor Green 