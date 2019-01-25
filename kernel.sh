#!/usr/bin/env bash

color_default='\033[0m'
color_warning='\033[0;33m'
color_info='\033[0;36m'
color_success='\033[0;32m'
color_error='\033[0;31m'
certificate_certgen_sample="# Origin company country (2 letters)\n
country='FR';\n
# Origin company state (leave blank for france)\n
state='';\n
# Origin company city\n
city='Example';\n
# Company name\n
company_name='ExampleCompany';\n
# Company Unit Name\n
company_unit_name='TE';\n
# Company website Hostname\n
# Example : 'example.fr'\n
hostname_company='example.fr';\n
"
# $1 = delimiter
# $2 = string
# $3 = newVar
explode() {
    local delimiter=$1
    local string=$2
    local newVar=$3
    local array=()
#    echo "delimiter $delimiter"
#    echo "string $string"
#    echo "newVar $newVar"
#    if [[ $delimiter = '|' ]]
#    then
#        delimiter='\|'
#    fi
    delimiter="\\${delimiter}"
#    echo "delimiter $delimiter"
    while [[ $string =~ ([^$delimiter]*)$delimiter(.*) ]]
    do
        array+=(${BASH_REMATCH[1]})
        string=${BASH_REMATCH[2]}
    done
    array+=(${string})
#    teste=(${array[@]})
#
#     for test in ${teste[@]}
#     do
#         echo "test : $test"
#     done
     eval "${newVar}"="(${array[@]})"


}
#explode '-' 'salutje-suis-LA' 'test'
#echo -e ${test[@]}
echoDataByStr() {
    eval echo "\$$1"
}


# $1 = varname
addKSlash() {
    local varname=$1
    local value=$(echoDataByStr $varname)
#    echo "$value"
    if [[ $value =~ ^(.*[^\/])\/+$ ]]
    then
#        echo "change value ${BASH_REMATCH[1]}"
        value=${BASH_REMATCH[1]}
#        echo "change value $value"
    fi
    eval "${varname}"="${value}/"
#    path_to_pki_tls_certificates_directory="${path_to_pki_tls_certificates_directory}/"

}
#temp_dir='./newCertificates/////'
#addKSlash 'temp_dir'
#echo $temp_dir
# $1 = text
# $2 = error_text *BOOLEAN* **OPTIONAL**
create_prompt_message() {
    local text=$1
    local error_text=$2

    if [[ $error_text = true ]]
    then
        prompt_message="${color_error}${text}${color_default}"
    else
        prompt_message="${color_default}Type ${color_success}${text}${color_default} and press ${color_success}ENTER :"
    fi
}

# $1 = var name
# $2 = placeholder  **OPTIONAL**
# $3 = text  **OPTIONAL**
#
# return --> ${prompt_result}
prompt() {
    local varname=$1
    local placeholder=$2
    local text=$3

    if [[ $2 ]]
    then
        if [[ $3 ]]
        then
            echo "yeah 3 $3"
            create_prompt_message "${text}\n${color_info}Probably : ${placeholder}${color_default}"
        else
            create_prompt_message "${varname//_/ }\n${color_info}Probably : ${placeholder}${color_default}"
        fi
        echo -e "${prompt_message}"
        read -e -r -p "$ " -i ${placeholder} result
    elif [[ $1 ]]
    then
        create_prompt_message "${varname//_/ }"
        echo -e "${prompt_message}"
        read -e -r -p "$ " result
    else
        exit
    fi
    prompt_result=${result}
}

# $1 = varname string example : company_name || ... **REQUIRED**
# $2 = method string  example : 2letters || dir      **REQUIRED**
#
# Return --> ${prompt_valid} = true | false
checkPrompt() {
    local varname=$1
    local method=$2
#    local mixed=$2
    local result=${prompt_result}
    local message=''

#    echo $method
#    echo $regex
#    echo "prompt :$result:"
#    echo "condition "
    if [[ ${result} = '' ]]
    then
        message="${varname//_/ } could not be null"
        prompt_valid=false
    elif [[ $method = '2letters' && ! (${result} =~ ^[A-Z]{2}$) ]]
    then
#        echo "country false"
        message="${varname//_/ } must contains 2 A-Z Letters"
        prompt_valid=false
    elif [[ $method = 'dir' && ! (-d ${result}) ]]
    then
        message="This directory does not exist !"
        prompt_valid=false
    elif [[ $method = 'no-space' && ! (${result} =~ ^[^[:space:]]*$) ]]
    then
        message="${varname//_/ } could not be null and can't contain white space"
        prompt_valid=false
    elif [[ $method = 'host' && ! (${result} =~ ^[a-zA-Z0-9_\.-]+$) ]]
    then
        echo $result
        message="${varname//_/ } must be an host name \n${color_warning}Example : facebook.com"
        prompt_valid=false
    elif [[ ($method = 'mail' && ! (${result} =~ ^[a-z0-9._-]+@[a-z.]+$)) ]]
    then
        message="${varname//_/ } must be an mail address \n${color_warning}Example : example.example@example.com"
        prompt_valid=false
    else
        prompt_valid=true
    fi
    if [[ ${prompt_valid} = false ]]
    then
        create_prompt_message "${message}" true
        echo -e ${prompt_message}
        prompt_message=''
        message=''
    fi

}

# $1 = varname
save_prompt() {
    local varname=$1
    if [[ $1 ]]
    then
        eval "${varname}"="${prompt_result}"
    fi

}

# $1 = var name to create
# $2 = placeholder  **OPTIONAL**
# $3 = text  **OPTIONAL**
prompt_dir() {
    local varname=$1
    local placeholder=$2
    local text=$3
    local rec=false

    prompt ${varname} ${placeholder} ${text}

    checkPrompt ${varname} 'dir'

    if [[ ${prompt_valid} = false ]]
    then
        prompt_dir ${varname} ${placeholder} ${text}
        rec=true
    fi

    if [[ $rec = false ]]
    then
        save_prompt ${varname}
        prompt_result=''
    fi
}



# $1 = var name to create
# $2 = placeholder  **OPTIONAL**
# $3 = text  **OPTIONAL**
prompt_2letters() {
    local varname=$1
    local placeholder=$2
    local text=$3

    local rec=false

    prompt ${varname} ${placeholder} ${text}

    checkPrompt ${varname} '2letters'

    if [[ ${prompt_valid} = false ]]
    then
        prompt_2letters ${varname} ${placeholder} ${text}
        rec=true
    fi

    if [[ $rec = false ]]
    then
        save_prompt ${varname}
    fi
}

prompt_no_space() {
    local varname=$1
    local placeholder=$2
    local text=$3

    local rec=false

    prompt ${varname} ${placeholder} ${text}

    checkPrompt ${varname} 'no-space'

    if [[ ${prompt_valid} = false ]]
    then
        prompt_no_space ${varname} ${placeholder} ${text}
        rec=true
    fi

    if [[ $rec = false ]]
    then
        save_prompt ${varname}
        prompt_result=''
    fi

}

prompt_host() {
    
    local varname=$1
    local placeholder=$2
    local text=$3

    local rec=false

    prompt ${varname} ${placeholder} ${text}

    checkPrompt ${varname} 'host'

    if [[ ${prompt_valid} = false ]]
    then
        prompt_host ${varname} ${placeholder} ${text}
        rec=true
    fi

    if [[ $rec = false ]]
    then
        save_prompt ${varname}
        prompt_result=''
    fi
}

# $1 = PATH/TO/DIR
checkRemovedDirectorys() {
    temp_dir=$1
    addKSlash 'temp_dir'
    local directorys=$(find ${temp_dir}* -type d 2> /dev/null)
    if [[ $directorys != '' ]]
    then
        echo -e "${color_error}Can't remove these following directory :\n ${color_warning}${directorys[@]}"
#        for dir in $directorys[@]
#        do
#            echo $dir
#        done
    fi
    unset temp_dir
}

# $2 = extension file
checkRemovedFiles() {
    local ext=$2
    temp_file=$1
    addKSlash 'temp_file'
    local files=$(find ${temp_file}*.${ext} -type f 2> /dev/null)
    if [[ $files != '' ]]
    then
        echo -e "${color_error}Can't remove these following file :\n ${color_warning}${files[@]}"
#        for dir in $files[@]
#        do
#            echo $dir
#        done
    fi
    unset temp_file
}
#checkRemovedFiles ./newCertificates/ 'certgen'

clean_part1() {
    rm -rf ./newCertificates/*/ ./newCertificates/*.certgen

    checkRemovedDirectorys ./newCertificates/
    checkRemovedFiles ./newCertificates/ 'certgen'

    if [[ -f ./newCertificates/certificate.certgen.sample ]]
    then
        echo $(cat ./newCertificates/certificate.certgen.sample) > ./newCertificates/certificate.certgen
        echo $(cat ./newCertificates/certificate.certgen.sample) > ./newCertificates/certificate2.certgen
    else
        echo $certificate_certgen_sample > ./newCertificates/certificate.certgen
        echo $certificate_certgen_sample > ./newCertificates/certificate2.certgen
    fi

}


clean_part2() {
    rm -rf ./downloadedCertificate/*/ ./downloadedCertificate/*.pem ./downloadedCertificate/*.crt
    checkRemovedDirectorys ./downloadedCertificate/
    checkRemovedFiles ./downloadedCertificate/ 'pem'
    checkRemovedFiles ./downloadedCertificate/ 'crt'
}

clean_conf_gen() {
    rm -rf ./serverTemplates/apache/*/ ./serverTemplates/nginx/*/
    checkRemovedDirectorys ./serverTemplates/apache/
    checkRemovedDirectorys ./serverTemplates/nginx/

}

#last_time_use_part1=0
#last_time_use_part2=0
#last_time_use_conf_gen=0
# $1 = script 'part2' || 'part1' || 'conf_gen'
checkLastUse() {
    script=$1
    varname="last_time_use_${script}"

#    source ./.time.tm
    timeTm=$(cat ./.time.tm)
    timestamp=$(date +%s)
    echo -e $timeTm
    if [[ $timeTm =~ (.*)$varname\=([0-9]+)\;{1}(.*)$ ]]
    then
        local newFile="${BASH_REMATCH[1]}${varname}=${timestamp};${BASH_REMATCH[3]}"
#        newFile=${newFile// /}
        echo  ${newFile//[[:space:]]/}> ./.time.tm
        local lastUse=${BASH_REMATCH[2]}
        local time_dont_use=$((${timestamp} - ${lastUse}))
        local max_expiration_time=604800

        echo "last time use ${BASH_REMATCH[2]}"
        echo "timestamp ${timestamp}"
        echo "time dont use ${time_dont_use}"
        echo "one week time ${max_expiration_time}"
        echo "cond $(($time_dont_use > $max_expiration_time))"

        if [[ ($time_dont_use -gt $max_expiration_time) && ${lastUse} -gt 0 ]]
        then
            day_dont_use=$(($time_dont_use / 86400))
            date_format='days'
            if (( $day_dont_use > 365 ))
            then
                date_format='years'
                day_dont_use=$(( $day_dont_use / 365 ))
            elif (( $day_dont_use > 30 ))
            then
                date_format='month'
                day_dont_use=$(( $day_dont_use / 30 ))
            fi
            echo -e "${color_warning}Your last use of ${script} script is ${color_error}${day_dont_use} ${color_warning}${date_format} past"
            echo -e "${color_warning}Save old use is useless and can create bugs !\n${color_info}Do you want clean use ?${color_default}"
            read -e -r -p "$ " -i "yes" result
            if [[ ${result} =~ ^[yY]{1}e?s?.*$ ]]
            then
                clean_${script}
            fi
        elif [[ ${lastUse} = 0 ]]
        then
            echo -e "${color_info}Welcome $(whoami) ;)${color_default}\nYou can find all your need here https://github.com/AntoineGuerra/ssl_certificates_generator#getting-started"
        fi
    else
        echo "${varname}=${timestamp};" >> ./.time.tm
    fi
}


checkScript() {
file=$1
    if [[ !(-x $file) ]]
    then
        chmod +x $file
    fi
}