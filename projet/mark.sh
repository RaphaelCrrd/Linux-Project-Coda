#!/bin/bash

NOTE=0
CSV_FILE="note.csv"

FOLDER=$(basename "$(pwd)")
NOM=$(echo "$FOLDER" | cut -d'_' -f1)
PRENOM=$(echo "$FOLDER" | cut -d'_' -f2)

if [ -z "$NOM" ] || [ -z "$PRENOM" ]; then
    NOM="Inconnu"
    PRENOM="Inconnu"
fi

make > /dev/null 2>&1

if [ ! -f "factorielle" ]; then
    echo "Compilation échouée → note : 0"
    if [ ! -f "$CSV_FILE" ]; then
        echo "Nom,Prenom,Note" > "$CSV_FILE"
    fi
    echo "'$NOM','$PRENOM',0" >> "$CSV_FILE"
    exit 0
fi

NOTE=$((NOTE + 2))
echo "[+2] Compilation réussie"

EXPECTED=(1 2 6 24 120 720 5040 40320 362880 3628800)
GENERAL_OK=true

for i in $(seq 1 10); do
    RESULT=$(./factorielle $i 2>/dev/null)
    IDX=$((i - 1))
    if [ "$RESULT" != "${EXPECTED[$IDX]}" ]; then
        GENERAL_OK=false
        break
    fi
done

if [ "$GENERAL_OK" = true ]; then
    NOTE=$((NOTE + 5))
    echo "[+5] Factorielles 1 à 10 correctes"
else
    echo "[+0] Factorielles 1 à 10 incorrectes"
fi

RESULT_ZERO=$(./factorielle 0 2>/dev/null)
if [ "$RESULT_ZERO" = "1" ]; then
    NOTE=$((NOTE + 3))
    echo "[+3] Factorielle(0) = 1 correcte"
else
    echo "[+0] Factorielle(0) incorrecte (obtenu: $RESULT_ZERO)"
fi

if grep -qF "int factorielle( int number )" main.c 2>/dev/null || \
   grep -qF "int factorielle( int number )" header.h 2>/dev/null; then
    NOTE=$((NOTE + 2))
    echo "[+2] Signature correcte"
else
    echo "[+0] Signature incorrecte ou absente"
fi

MSG_NO_ARG=$(./factorielle 2>/dev/null)
if [ "$MSG_NO_ARG" = "Erreur: Mauvais nombre de parametres" ]; then
    NOTE=$((NOTE + 4))
    echo "[+4] Message 'aucun argument' correct"
else
    echo "[+0] Message 'aucun argument' incorrect (obtenu: '$MSG_NO_ARG')"
fi

MSG_NEG=$(./factorielle -1 2>/dev/null)
if [ "$MSG_NEG" = "Erreur: nombre negatif" ]; then
    NOTE=$((NOTE + 4))
    echo "[+4] Message 'nombre négatif' correct"
else
    echo "[+0] Message 'nombre négatif' incorrect (obtenu: '$MSG_NEG')"
fi

LONG_LINE=false
for FILE in main.c header.h; do
    if [ -f "$FILE" ]; then
        while IFS= read -r line; do
            if [ ${#line} -gt 80 ]; then
                LONG_LINE=true
                break 2
            fi
        done < "$FILE"
    fi
done

if [ "$LONG_LINE" = true ]; then
    NOTE=$((NOTE - 2))
    echo "[-2] Ligne(s) dépassant 80 caractères"
else
    echo "[ok] Longueur des lignes correcte"
fi

BAD_INDENT=false

check_indent() {
    local file="$1"
    local depth=0

    while IFS= read -r line; do
        [ -z "$line" ] && continue

        if echo "$line" | grep -qE '^\s*\}'; then
            depth=$((depth - 1))
        fi

        expected_spaces=$((depth * 2))
        actual_spaces=$(echo "$line" | sed 's/[^ ].*//' | wc -c)
        actual_spaces=$((actual_spaces - 1))

        if echo "$line" | grep -qE '^\s*#'; then
            :
        elif [ "$actual_spaces" -ne "$expected_spaces" ] && ! echo "$line" | grep -qE '^\s*$'; then
            BAD_INDENT=true
            break
        fi

        if echo "$line" | grep -qE '^\s*\{'; then
            depth=$((depth + 1))
        fi

    done < "$file"
}

[ -f "main.c" ] && check_indent "main.c"

if [ "$BAD_INDENT" = true ]; then
    NOTE=$((NOTE - 2))
    echo "[-2] Mauvaise indentation"
else
    echo "[ok] Indentation correcte"
fi

make clean > /dev/null 2>&1
if [ -f "factorielle" ]; then
    NOTE=$((NOTE - 2))
    echo "[-2] make clean ne fonctionne pas"
else
    echo "[ok] make clean fonctionne"
fi
make > /dev/null 2>&1

if [ ! -f "header.h" ]; then
    NOTE=$((NOTE - 2))
    echo "[-2] Fichier header.h absent"
else
    echo "[ok] header.h présent"
fi

if [ $NOTE -lt 0 ]; then
    NOTE=0
fi

echo "  NOTE FINALE : $NOTE / 20"

if [ ! -f "$CSV_FILE" ]; then
    echo "Nom,Prenom,Note" > "$CSV_FILE"
fi
echo "'$NOM','$PRENOM',$NOTE" >> "$CSV_FILE"