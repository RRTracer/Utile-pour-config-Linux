#!/bin/bash

declare -a dom=("org" "info" "net" "com" "co" "uk" "eu" "es" "sl")

value=$(cat /dev/urandom | tr -dc '0-8' | fold -w 256 | head -n 1 | head --bytes 1)

#echo ${dom[$value]}

for ((i = 0; i < 5 ; i++ ))
  do 
    number=$(cat /dev/urandom | tr -dc '0-9' | fold -w 256 | head -n 1 | head --bytes 1)
    string[i]=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $(( 1 + $number ))  | head -n 1)
    #echo ${string[$i]}
done

echo "email = ${string[0]}@${string[1]}.${dom[$value]}" "name = ${string[2]} ${string[3]}" >> ~/nominatif/fakelist

cat > ~/.gitconfig_nowhere << EOF
[user]
    email = ${string[0]}@${string[1]}.${dom[$value]}
    name = ${string[2]} ${string[3]}
[push]
    default = matching

EOF


#A1=$(cat /dev/urandom | tr -dc '0-9' | fold -w 256 | head -n 1 | head --bytes 1)
#A2=$(cat /dev/urandom | tr -dc '0-9' | fold -w 256 | head -n 1 | head --bytes 1)
#A3=$(cat /dev/urandom | tr -dc '0-9' | fold -w 256 | head -n 1 | head --bytes 1)
#A4=$(cat /dev/urandom | tr -dc '0-9' | fold -w 256 | head -n 1 | head --bytes 1)
#A5=$(cat /dev/urandom | tr -dc '0-9' | fold -w 256 | head -n 1 | head --bytes 1)

#A=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $(( 1 + $A1 ))  | head -n 1)
#B=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $(( 1 + $A2 )) | head -n 1)
#C=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $(( 1 + $A3 ))  | head -n 1)
#D=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $(( 1 + $A4 )) | head -n 1)
#E=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $(( 5 + $A5 )) | head -n 1)

#cat > ~/.gitconfig_nowhere << EOF

rm -f ~/.gitconfig
ln -s ~/.gitconfig_nowhere ~/.gitconfig

cat ~/.gitconfig
#[user]
#    email = $A@$B.com
#    name = $C $D
#[push]
#    default = matching

#EOF
