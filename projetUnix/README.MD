# Process Monitor Script

## Description
Ce script shell surveille les processus système pour détecter des anomalies telles qu'une utilisation élevée de CPU, des processus exécutés par des utilisateurs non autorisés, et des processus zombies. Il propose des actions interactives pour traiter ces anomalies et génère un rapport quotidien basé sur les anomalies détectées.

## Fonctionnalités
- **Surveillance continue des processus** : Identifie les processus utilisant une forte proportion de CPU, exécutés par des utilisateurs non autorisés, ou ayant un état zombie.
- **Notification interactive** : Lorsqu'une anomalie est détectée, une notification via `xterm` permet de choisir une action (tuer le processus, ajuster sa priorité, ou ignorer).
- **Rapports journaliers** : Génère un rapport récapitulatif des anomalies lors de l'arrêt du script.

## Prérequis
1. **Système d'exploitation** : Linux.
2. **Permissions** : Accès root ou droits `sudo` pour exécuter certaines commandes (ex. `kill`, `renice`).
3. **Logiciels nécessaires** :
   - `xterm` : Pour les notifications interactives.
   - `bc` : Pour les calculs de seuils.
4. **Dépendances** :
   Installez les dépendances avec la commande suivante si nécessaire :
   ```bash
   sudo apt-get install xterm bc
