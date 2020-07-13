#!/bin/bash

KEYSERVER=$(cat ./preferences | grep KEYSERVER | awk '{print $2}')
VERSION=$(cat ./version)
BACKUPMESSAGE=$(cat ./preferences | grep BACKUPMESSAGE | awk '{print $2}')
DATE=$(date +"%s")

functionEND(){
  echo "Done"
  sleep 1
}

header(){
  echo "*********************************************"
  echo "GPG Menu                       Version: ${VERSION}"
}

menu(){
  echo "*********************************************"
  echo "1. Encrypt Message"
  echo "2. Decrypt Message"
  echo "3. Create Key"
  echo "4. Delete Key"
  echo "5. Import Public Key"
  echo "6. Import Private Key"
  echo "7. Sign Key"
  echo "8. Verify File"
  echo "9. Generate Fingerprint"
  echo "10. Export Public Key"
  echo "11. Export Private Key"
  echo "99. Exit"
  echo "*********************************************"
  read -rp ":" -e choice
}

encryptMessage(){
  if [ $BACKUPMESSAGE = True && -f New_Message ]; then
    mv New_Message New_Message.$DATE
  fi
  cat New_Message.template > New_Message
  nano New_Message
  echo "Message Saved"
  declare -a RECIPIANTS
  FILE=New_Message
  MESSAGEFILE=Message.$DATE
  I=1 # Starting Line
  while read line; do
    # Finds all recipiants
    if [[ $line = *"Recipiant"* ]]; then
      recipiant=$(echo $line | awk '{print $2}')
      RECIPIANTS+=("-r $recipiant")
    fi
    # Extracts the message
    if [[ $line = *"Message"* ]]; then
      MESSAGESTARTLINE=$I
      MESSAGEENDLINE=$(wc -l $FILE | awk '{print $1}')
      MESSAGE=$(sed -n "${MESSAGESTARTLINE}, ${MESSAGEENDLINE}p" $FILE)
      MESSAGE=$(echo $MESSAGE | sed -e "s/Message://")
    fi
    I=$((I+1))
  done < $FILE
  echo $MESSAGE > $MESSAGEFILE
  gpg --encrypt -sign --armor ${RECIPIANTS[@]} ${MESSAGEFILE}
  read -rp "Delete plain text file? [Y/n]: " CHOICE
  CHOICE=$(echo $CHOICE | awk '{print tolower($0)}')
  if [ $CHOICE = "y" ]; then
    erase $MESSAGEFILE
  fi
  echo "Message encrypted and stored as ${MESSAGEFILE}.asc"
  sleep 1
}

decryptMessage(){
  read -rp "Encrypted Filename: " FILE
  gpg --decrypt $FILE > $FILE.plaintext
  less $FILE.plaintext
}

createKey(){
  gpg --full-gen-key
  functionEND
}

deleteKey(){
  read -rp "Key ID: " KEYID
  read -rp "Delete Secret Key? [Y/n]: " CHOICE
  CHOICE=$(echo $CHOICE | awk '{print tolower($0)}')
  if [ $CHOICE = "y" ]; then
    gpg --delete-secret-and-public-keys ${KEYID}
  else
    gpg --delete-keys ${KEYID}
  fi
  functionEND
}

importPublicKey(){
  read -rp "Import from public key server? [Y/n]: " CHOICE
  CHOICE=$(echo $CHOICE | awk '{print tolower($0)}')
  if [ $CHOICE = "y" ]; then
    read "Using keyserver ${KEYSERVER}. Change? [Y/n]: " CHOICE
    CHOICE=$(echo $CHOICE | awk '{print tolower($0)}')
    if [ $CHOICE = "y" ]; then
      read -rp "Keyserver: " KEYSERVERNEW
      KEYSERVERNEW=$(echo $KEYSERVERNEW | awk '{print tolower($0)}')
      sed -i "s/${KEYSERVER}/${KEYSERVERNEW}/g" preferences
      KEYSERVER=$KEYSERVERNEW
    fi
    read -rp "Name or Email To Search: " SEARCH_PARAM
    gpg --keyserver ${KEYSERVER} --search-keys ${SEARCH_PARAM}
  else
    read -rp "Public Key File Name: " KEYFILE
    gpg --import ${KEYFILE}
  fi
  functionEND
}

importPrivateKey(){
  read -rp "Private Key File Name: " KEYFILE
  gpg --import ${KEYFILE}
  functionEND
}

signKey(){
  read -rp "Key ID: " KEYID
  gpg --sign-key ${KEYID}
  read -rp "Output Signed Key? [Y/n]: " CHOICE
  CHOICE=$(echo $CHOICE | awk '{print tolower($0)}')
  if [ $CHOICE = "y" ]; then
    gpg --output signed.key --export --armor ${KEYID}
  fi
  functionEND
}

verifyFile(){
  read -rp "File Name: " FILENAME
  read -rp "Signiture File Name: " SIGFILENAME
  gpg --verify ${SIGFILENAME} ${FILENAME}
  functionEND
}

generateFingerprint(){
  read -rp "Key ID: " KEYID
  gpg --fingerprint ${KEYID}
  functionEND
}

exportPublicKey(){
  read -rp "Public Key ID: " KEYID
  gpg --output ${KEYID}.pub --armor --export ${KEYID}
  functionEND
}

exportPrivateKey(){
  read -rp "Private Key ID: " KEYID
  gpg --output ${KEYID}.private --armor --export-secret-key ${KEYID}
  functionEND
}

while :; do
  clear
  header
  menu
  case $choice in
    1) encryptMessage;;
    2) decryptMessage;;
    3) createKey;;
    4) deleteKey;;
    5) importPublicKey;;
    6) importPrivateKey;;
    7) signKey;;
    8) verifyFile;;
    9) generateFingerprint;;
    10) exportPublicKey;;
    11) exportPrivateKey;;
    99) exit;;
  esac
done
