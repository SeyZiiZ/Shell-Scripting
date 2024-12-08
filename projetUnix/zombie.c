#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main() {
    pid_t pid = fork();

    if (pid < 0) {
        perror("Erreur lors du fork");
        exit(1);
    } else if (pid == 0) {
        printf("Je suis le processus enfant (PID: %d), je vais terminer.\n", getpid());
        exit(0);
    } else {
        printf("Je suis le processus parent (PID: %d), l'enfant (PID: %d) est terminé, mais je ne vais pas attendre.\n", getpid(), pid);
        sleep(60);
    }

    return 0;
}
