FILE="note-file-generator.sh"

if [ -f "$FILE" ]; then
    echo "Already installed!"
else
    sudo cp ./src/ /bin/note-file-generator
fi

