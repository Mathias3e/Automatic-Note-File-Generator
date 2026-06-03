# daily weekly monthly yearly
# 1     2      3       4

function addVariabelsToConfig {
    jq --arg k "$2" --arg v "$3" '.variabels += {($k): $v}' $1.json > tmp.json && mv tmp.json $1.json
}

function createNewConfig {
    local id
    id=$(uuidgen | tr 'A-Z' 'a-z')
    id="123"
    cat << EOF > "$id.json"
{
    "id": "$id",
    "aktive": $1,
    "name": "$2",
    "tamplate": "$3",
    "date": {
        "start": "$4",
        "end": $5
    },
    "repetition": {
        "advanced": $6,
        "type": $7,
        "day_offset": $8,
        "interval": $9
    },
    "variabels": {
        
    }
}
EOF
}

function editConfig {
    echo "hallo"
}

function deleteConfig {
    echo "hallo"
}

createNewConfig true "Schedule 1" "template 1" "03-06-2026" null true 2 2 3
addVariabelsToConfig 123 modul M122