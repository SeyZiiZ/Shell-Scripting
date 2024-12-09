#!/bin/bash

# Fichiers de logs et rapports
LOG_FILE="$HOME/process_monitor.log"
REPORT_FILE="$HOME/daily_report.log"
SUSPECT_LOG="$HOME/process_suspects.log"
LOCK_FILE="./process_monitor.lock"

# Seuils d'anomalies
CPU_THRESHOLD=80
AUTHORIZED_USERS=("root")

# Fonction pour notifier l'utilisateur
notify_action() {
    local pid=$1
    local anomaly_type=$2
    local user=$3

    # Vérifie si une instance de xterm est déjà en cours d'exécution
    if [ -f "$LOCK_FILE" ]; then
        echo "Une notification est déjà en cours. Ignorer cette anomalie." | tee -a "$LOG_FILE"
        return
    fi

    # Crée un fichier de verrouillage
    touch "$LOCK_FILE"

    xterm -e bash -c '
    trap "rm -f '"$LOCK_FILE"'" EXIT
    echo "Anomalie détectée : '"$anomaly_type"' pour le PID '"$pid"', utilisateur '"$user"'" | tee -a "'"$LOG_FILE"'"
    echo -e "Quelle action souhaitez-vous entreprendre ?\n1. Tuer le processus\n2. Baisser la priorité (renice)\n3. Ignorer"
    read -p "Entrez votre choix (1/2/3) : " action

    case "$action" in
        1)
            echo "Action : Tuer le processus (PID: '"$pid"')" | tee -a "'"$LOG_FILE"'"
            sudo kill -9 '"$pid"' && echo "Processus tué avec succès." | tee -a "'"$LOG_FILE"'" || echo "Erreur lors de la tentative de tuer le processus." | tee -a "'"$LOG_FILE"'"
            ;;
        2)
            echo "Action : Baisser la priorité du processus (PID: '"$pid"')" | tee -a "'"$LOG_FILE"'"
            renice 10 '"$pid"' && echo "Priorité modifiée avec succès." | tee -a "'"$LOG_FILE"'" || echo "Erreur lors de la modification de la priorité." | tee -a "'"$LOG_FILE"'"
            ;;
        3)
            echo "Action ignorée pour le processus (PID: '"$pid"')" | tee -a "'"$LOG_FILE"'"
            ;;
        *)
            echo "Option invalide. Aucune action entreprise." | tee -a "'"$LOG_FILE"'"
            ;;
    esac

    read -p "Appuyer sur entrer pour fermer..."
    rm -f "'"$LOCK_FILE"'"
    ' &
}

# Fonction pour collecter des informations sur un processus suspect
collect_process_info() {
    local pid=$1
    echo "Collecte des informations pour le processus suspect (PID: $pid)..." | tee -a "$SUSPECT_LOG"
    ps -p "$pid" -o pid,ppid,user,%cpu,%mem,cmd >> "$SUSPECT_LOG"
    echo "Informations collectées dans $SUSPECT_LOG." | tee -a "$LOG_FILE"
}

# Fonction pour surveiller les processus
monitor_processes() {
    echo "Début de la surveillance des processus..." | tee -a "$LOG_FILE"

    while true; do
        # Liste des processus triés par utilisation CPU
        ps aux --sort=-%cpu | awk -v threshold=$CPU_THRESHOLD '
        NR>1 {
            print $0
        }' | while read -r process; do
            # Extraction des informations du processus
            user=$(echo "$process" | awk '{print $1}')
            pid=$(echo "$process" | awk '{print $2}')
            cpu=$(echo "$process" | awk '{print $3}')
            command=$(echo "$process" | awk '{print $11}')

            # Vérification si l'utilisateur est non autorisé
            if [[ ! " ${AUTHORIZED_USERS[@]} " =~ " ${user} " ]]; then
                anomaly="Utilisateur non autorisé"
                echo "ALERTE : $anomaly (Utilisateur: $user, PID: $pid, Commande: $command)" | tee -a "$LOG_FILE"
                collect_process_info "$pid"
                notify_action "$pid" "$anomaly" "$user"
            fi

            # Vérification de l'utilisation CPU élevée
            if (( $(echo "$cpu > $CPU_THRESHOLD" | bc -l) )); then
                anomaly="Utilisation CPU élevée ($cpu%)"
                echo "ALERTE : $anomaly (Utilisateur: $user, PID: $pid, Commande: $command)" | tee -a "$LOG_FILE"
                collect_process_info "$pid"
                notify_action "$pid" "$anomaly" "$user"
            fi
        done

        # Détection des processus zombies
        ps -eo pid,ppid,stat,comm | awk '$3 ~ /Z/ {print $1, $2, $4}' | while read -r zombie_process; do
            pid=$(echo "$zombie_process" | awk '{print $1}')
            ppid=$(echo "$zombie_process" | awk '{print $2}')
            command=$(echo "$zombie_process" | awk '{print $3}')

            anomaly="Processus zombie détecté"
            echo "ALERTE : $anomaly (PID: $pid, PPID: $ppid, Commande: $command)" | tee -a "$LOG_FILE"
            notify_action "$pid" "$anomaly" "N/A"
        done

        # Pause entre les cycles de surveillance
        sleep 10
    done
}

# Fonction pour générer un rapport quotidien
generate_daily_report() {
    echo "Génération du rapport quotidien..." | tee -a "$REPORT_FILE"
    echo "Rapport du $(date)" > "$REPORT_FILE"
    echo "---------------------------" >> "$REPORT_FILE"
    echo "Résumé des anomalies détectées :" >> "$REPORT_FILE"
    grep "ALERTE" "$LOG_FILE" >> "$REPORT_FILE"
    echo "---------------------------" >> "$REPORT_FILE"
    echo "Statistiques des anomalies :" >> "$REPORT_FILE"
    echo "Utilisateurs les plus impliqués :" >> "$REPORT_FILE"
    grep "Utilisateur:" "$LOG_FILE" | awk '{print $2}' | sort | uniq -c | sort -nr >> "$REPORT_FILE"
    echo "---------------------------" >> "$REPORT_FILE"
    echo "Rapport généré avec succès : $REPORT_FILE"
}

# Exécution
monitor_processes &
MONITOR_PID=$!

trap "kill $MONITOR_PID; generate_daily_report; exit" SIGINT SIGTERM

wait
