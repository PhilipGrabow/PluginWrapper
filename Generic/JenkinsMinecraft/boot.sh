#!/bin/bash

# Verzeichnis für Plugins sicherstellen
mkdir -p plugins

echo "--- Starte Jenkins Plugin Sync ---"

# Beispiel: Lädt das letzte erfolgreiche Artefakt
# Du musst ggf. den Pfad 'artifact/target/plugin.jar' an deinen Jenkins anpassen
ARTIFACT_URL="${JENKINS_URL}/job/${JENKINS_JOB}/lastSuccessfulBuild/artifact/target/my-plugin.jar"

echo "Download von: $ARTIFACT_URL"
curl -L -s -o ./plugins/my-plugin.jar "$ARTIFACT_URL"

if [ $? -eq 0 ]; then
    echo "Sync erfolgreich!"
else
    echo "FEHLER: Download fehlgeschlagen. Starte mit alten Plugins..."
fi

echo "--- Starte Minecraft Server ---"

# 'exec' ist entscheidend: Es ersetzt die Shell durch den Java-Prozess.
# Dadurch sieht AMP die PID von Java direkt.
exec java -Xmx${MEMORY}M -Xms${MEMORY}M -jar ${SERVER_JAR} nogui