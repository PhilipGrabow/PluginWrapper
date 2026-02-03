#!/bin/bash

# Verzeichnis für Plugins sicherstellen
mkdir -p plugins

echo "--- Starte Jenkins Plugin Sync ---"

auth_args=()
if [[ -n "${JENKINS_USER}" && -n "${JENKINS_TOKEN}" ]]; then
    auth_args=(-u "${JENKINS_USER}:${JENKINS_TOKEN}")
fi

if [[ -n "${PLUGIN_LIST}" ]]; then
    echo "Plugin-Liste erkannt. Starte Download..."
    download_failures=0
    while IFS= read -r entry; do
        entry="$(echo "${entry}" | xargs)"
        [[ -z "${entry}" ]] && continue
        IFS=':' read -r job artifact output <<< "${entry}"
        if [[ -z "${job}" || -z "${artifact}" ]]; then
            echo "Überspringe ungültigen Eintrag: ${entry}"
            continue
        fi
        output="${output:-$(basename "${artifact}")}"
        artifact_url="${JENKINS_URL}/job/${job}/lastSuccessfulBuild/artifact/${artifact}"
        echo "Download von: ${artifact_url} -> plugins/${output}"
        if ! curl -L -f -s "${auth_args[@]}" -o "./plugins/${output}" "${artifact_url}"; then
            echo "FEHLER: Download fehlgeschlagen für ${entry}"
            download_failures=$((download_failures + 1))
        fi
    done < <(printf '%s\n' "${PLUGIN_LIST}" | tr ',' '\n')

    if [[ "${download_failures}" -eq 0 ]]; then
        echo "Sync erfolgreich!"
    else
        echo "WARNUNG: ${download_failures} Plugin(s) konnten nicht geladen werden. Starte mit alten Plugins..."
    fi
else
    echo "Keine Plugin-Liste gesetzt. Verwende optionalen Standard-Job."
    artifact_url="${JENKINS_URL}/job/${JENKINS_JOB}/lastSuccessfulBuild/artifact/target/my-plugin.jar"
    echo "Download von: ${artifact_url}"
    if curl -L -f -s "${auth_args[@]}" -o ./plugins/my-plugin.jar "${artifact_url}"; then
        echo "Sync erfolgreich!"
    else
        echo "FEHLER: Download fehlgeschlagen. Starte mit alten Plugins..."
    fi
fi

echo "--- Starte Minecraft Server ---"

# 'exec' ist entscheidend: Es ersetzt die Shell durch den Java-Prozess.
# Dadurch sieht AMP die PID von Java direkt.
exec java -Xmx${MEMORY}M -Xms${MEMORY}M -jar ${SERVER_JAR} nogui
