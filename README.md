# TP-Examen-PowerShell

Ce projet regroupe des scripts PowerShell pour la gestion locale des utilisateurs/groupes et la sécurisation d'un poste Windows (pare-feu, conformité, etc.).

## Arborescence du projet

```
.
├── Exercice1
│   ├── audit.txt
│   ├── rapport.csv
│   ├── groups.json
│   ├── users.json
│   └── gestion-locale.ps1
├── Exercice2
│   ├── synthese_conformite.txt
│   ├── maintenance-securite.ps1
│   └── explication_politique_firewall.txt
└── README.md
```

## Description des principaux fichiers/scripts

### Exercice1
- **gestion-locale.ps1** : Script interactif pour ajouter des utilisateurs, gérer les groupes, attribuer des licences, générer des rapports et un audit.
- **users.json** : Liste des utilisateurs créés et leurs informations.
- **groups.json** : Liste des groupes et leurs membres.
- **rapport.csv** : Rapport synthétique des utilisateurs et groupes.
- **audit.txt** : Audit automatique (nombre d'utilisateurs, groupes, licences).

### Exercice2
- **maintenance-securite.ps1** : Script pour gérer le pare-feu, appliquer une politique restrictive, vérifier la conformité du poste (antivirus, mises à jour, BitLocker, journalisation) et générer une synthèse.
- **explication_politique_firewall.txt** : Explication détaillée de la politique de pare-feu appliquée.
- **synthese_conformite.txt** : Note de synthèse sur la conformité du poste.

## Utilisation
- Exécutez les scripts PowerShell en mode administrateur pour garantir leur bon fonctionnement.
- Adaptez les paramètres (ports, services, profils) selon vos besoins spécifiques.

## Contributeurs
- Calvin Davion

## License
Ce projet est sous licence MIT. N'hésitez pas à utiliser et modifier le code pour vos propres projets.

---
*Projet réalisé dans le cadre d'un Examen*

