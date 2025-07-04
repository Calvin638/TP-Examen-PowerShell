# gestion-locale.ps1

# Vérifie si le script est lancé en admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Ce script doit être exécuté en tant qu'administrateur. Relance automatique..."
    # Relance le script en admin
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Demander les informations à l'utilisateur
$nom = Read-Host "Entrez le nom"
$prenom = Read-Host "Entrez le prénom"
$email = Read-Host "Entrez l'email"
$license = Read-Host "Entrez la licence (E1, E3, E5)"

# Générer un nom d'utilisateur (ex: prenom.nom)
$username = "$prenom.$nom"

# Vérifier si l'utilisateur existe déjà
if (Get-LocalUser -Name $username -ErrorAction SilentlyContinue) {
    Write-Host "L'utilisateur $username existe déjà." -ForegroundColor Red
    exit
}

# Créer un mot de passe temporaire
$password = Read-Host "Entrez un mot de passe temporaire" -AsSecureString

try {
    New-LocalUser -Name $username -FullName "$prenom $nom" -Description "Email: $email, Licence: $license" -Password $password -ErrorAction Stop
    Write-Host "Utilisateur $username créé avec succès !" -ForegroundColor Green
    Add-LocalGroupMember -Group "Utilisateurs" -Member $username
} catch {
    Write-Host "Erreur lors de la création de l'utilisateur : $_" -ForegroundColor Red
    exit
}

# Charger ou initialiser users.json
$usersPath = "./users.json"
if (Test-Path $usersPath) {
    $users = Get-Content $usersPath | ConvertFrom-Json
    if ($users -isnot [System.Collections.IEnumerable]) {
        $users = @($users)
    }
} else {
    $users = @()
}

# Saisie des groupes (optionnelle, séparés par virgule)
$groupInput = Read-Host "Entrez le(s) groupe(s) (séparés par virgule, laissez vide si aucun)"
$groupList = @()
if ($groupInput -ne "") {
    $groupList = $groupInput -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
}

# Charger ou initialiser groups.json
$groupsPath = "./groups.json"
if (Test-Path $groupsPath) {
    $groups = Get-Content $groupsPath | ConvertFrom-Json
    if ($groups -isnot [System.Collections.IEnumerable]) {
        $groups = @($groups)
    }
} else {
    $groups = @()
}

# Mettre à jour/ajouter les groupes
foreach ($group in $groupList) {
    $existingGroup = $groups | Where-Object { $_.Nom -eq $group }
    if (-not $existingGroup) {
        # Nouveau groupe
        $newGroup = [PSCustomObject]@{
            Nom = $group
            Membres = @($username)
        }
        $groups += $newGroup
    } else {
        # Groupe existant, ajouter l'utilisateur si pas déjà membre
        if ($existingGroup.Membres -notcontains $username) {
            $existingGroup.Membres += $username
        }
    }
}

# Ajouter l'utilisateur à users.json
$userObj = [PSCustomObject]@{
    Nom      = $nom
    Prenom   = $prenom
    Email    = $email
    Username = $username
    Licence  = $license
    Groupes  = $groupList
}
$users += $userObj

# Sauvegarder les fichiers JSON
$users | ConvertTo-Json -Depth 4 | Set-Content $usersPath
$groups | ConvertTo-Json -Depth 4 | Set-Content $groupsPath

# Générer le rapport CSV
$rapport = $users | ForEach-Object {
    [PSCustomObject]@{
        Nom      = $_.Nom
        Prenom   = $_.Prenom
        Email    = $_.Email
        Licence  = $_.Licence
        Groupes  = ($_.Groupes -join ", ")
    }
}
$rapport | Export-Csv -Path "./rapport.csv" -NoTypeInformation

Write-Host "Toutes les opérations sont terminées. Rapport généré dans rapport.csv." -ForegroundColor Green


# --- Audit des utilisateurs, groupes et licences ---

# Charger les données
$usersPath = "./users.json"
$groupsPath = "./groups.json"
$users = @()
$groups = @()
if (Test-Path $usersPath) {
    $users = Get-Content $usersPath | ConvertFrom-Json
    if ($users -isnot [System.Collections.IEnumerable]) { $users = @($users) }
}
if (Test-Path $groupsPath) {
    $groups = Get-Content $groupsPath | ConvertFrom-Json
    if ($groups -isnot [System.Collections.IEnumerable]) { $groups = @($groups) }
}

# Nombre d'utilisateurs
$nbUsers = $users.Count
# Groupes créés
$groupNames = $groups | ForEach-Object { $_.Nom }
# Licences utilisées
$licenses = $users | Group-Object Licence | Select-Object Name,Count

Write-Host "\n--- AUDIT ---" -ForegroundColor Cyan
Write-Host "Nombre d'utilisateurs : $nbUsers"
Write-Host "Groupes créés : $($groupNames -join ', ')"
Write-Host "Licences utilisées :"
foreach ($lic in $licenses) {
    Write-Host "  $($lic.Name) : $($lic.Count) utilisateur(s)"
}

# Générer un fichier audit.txt
$audit = @()
$audit += "AUDIT DE LA GESTION LOCALE"
$audit += "==========================="
$audit += "Nombre d'utilisateurs : $nbUsers"
$audit += "Groupes créés : $($groupNames -join ', ')"
$audit += "Licences utilisées :"
foreach ($lic in $licenses) {
    $audit += "  $($lic.Name) : $($lic.Count) utilisateur(s)"
}
$audit | Set-Content -Path "audit.txt" -Encoding UTF8

Write-Host "\nAudit enregistré dans audit.txt" -ForegroundColor Green 