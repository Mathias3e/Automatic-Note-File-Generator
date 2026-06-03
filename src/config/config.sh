# daily weekly monthly yearly
# 1     2      3       4

function addVariabelsToConfig {
    jq --arg k "$2" --arg v "$3" '.variabels += {($k): $v}' $1.json > tmp.json && mv tmp.json $1.json
}

function removeVariabelsFromConfig {
    jq --arg k "$2" 'del(.variabels[$k])' "$1.json" > tmp.json && mv tmp.json "$1.json"
}

function createNewConfig {
    cat << EOF > "$1.json"
{
    "config_id": "$1",
    "aktive": $2,
    "name": "$3",
    "tamplate": "$4",
    "destination": "$5",
    "date": {
        "start": "$6",
        "end": $7
    },
    "repetition": {
        "advanced": $8,
        "type": $9,
        "day_offset": $10,
        "interval": $11
    },
    "variabels": {
        
    }
}
EOF
echo $id
}

function editConfig {
    jq --arg v "$3" --arg k "$2" '.[$k] = $v' "$1.json" > tmp.json && mv tmp.json "$1.json"
}

function deleteConfig {
    rm $1.json
}

# createNewConfig true "M122_Config" "M122_{{date}}" "template 2" "D:/03BBZW/02Semester/M122/Notes" "03-06-2026" null true 2 2 3
# addVariabelsToConfig 123 modul M122
# addVariabelsToConfig 123 test del
# removeVariabelsFromConfig 123 test
# editConfig 123 tamplate "tamplate 2"
# deleteConfig 123