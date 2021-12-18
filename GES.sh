#!/bin/sh

read_mail(){
        printf "\rEnter the Id of the email you want to read: "
        read id
        contents=$(curl -s "https://api.guerrillamail.com/ajax.php?f=fetch_email&sid_token=$1&email_id=$id")
        body=$(printf "%s" "$contents" | jq '.mail_body')
        excerpt=$(printf "%s" "$contents" | jq '.mail_excerpt')
        echo ${body:-${excerpt:-No Body}} | sed 's/<[^>]*>//g' | less
}

# Request email
header="$(curl -s 'https://api.guerrillamail.com/ajax.php?f=get_email_address')"
# Email params
sid=$(echo $header | jq -j '.sid_token')
addr=$(echo $header | jq -j '.email_addr')
timestamp=$(echo $header | jq -j '.email_timestamp')
alias=$(echo $header | jq -j '.alias')

stty -icanon
while true; do
        list=$(curl -s "https://api.guerrillamail.com/ajax.php?f=get_email_list&sid_token=$sid&offset=0")
        stats=$(printf "%s" "$list" | jq '.stats')
        count=$(printf "%s" "$list" | jq -j '.count')

        clear
        for i in $(seq -s ' ' ${count:-0} -1 0); do
                printf "Email from: "
                printf "%s" "$list" | jq -j ".list[$i] .mail_from"
                printf "\nDate: "
                printf "%s" "$list" | jq -j ".list[$i] .mail_date"
                printf "\tId: "
                printf "%s" "$list" | jq -j ".list[$i] .mail_id"
                printf "\nSubject: "
                printf "%s" "$list" | jq -j ".list[$i] .mail_subject"
                printf "\n\n"
        done
        printf "\n\nYour email is: %s\nYou have %s emails\nPress 'q' to quit, 'o' to open mail, or any other key to refresh\n" "$addr" "$((count + 1))"

        key=$(dd ibs=1 count=1 2>/dev/null)
        [ "$key" = "q" ] && break
        [ "$key" = "o" ] && read_mail $sid
done
