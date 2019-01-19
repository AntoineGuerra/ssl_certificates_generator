#!/usr/bin/env bash
color_default='\033[0m'
color_warning='\033[0;33m'
color_info='\033[0;36m'
color_success='\033[0;32m'
color_error='\033[0;31m'

path_to_certificates_directory=''
name_of_middle_certificate=''
certificates=()
# $1 = path_to_certificates_directory
createVal() {
    varName=$1
    echo -ne "${color_default}Type ${color_success}${varName//_/ }${color_default} and press ${color_success}ENTER :\n"
    if [[ ${path_to_certificates_directory} != '' && ${varName} = 'path_to_certificates_directory' ]]
    then
        read -e -r -p "$ " -i ${path_to_certificates_directory} result
    else
        read -e -r -p "$ " result
    fi
    eval "${varName}"="${result}"
    echo -ne "${color_default}"
}

getOptions() {
    options=('path_to_certificates_directory')
    for option in ${options[@]};
    do
        createVal ${option}
    done
}


# $1 = ${path_to_certificates_directory} dir/*.crt&file.pem
# $2 = name_of_middle_certificate --> file.pem
renameCertificates() {
    echo $1
    for file in $1/*
    do
        if [[ $file =~ (.*)\/([^\/]*)\.crt$ ]];
        then
            fileName=${BASH_REMATCH[2]}
            path=${BASH_REMATCH[1]}/
            mv $file ${path}${fileName}-$(date +"%Y").crt
            certificates+=(${path}${fileName}-$(date +"%Y").crt)
        elif [[ $file =~ ([^\/]*)\.pem$ ]]
        then
            name_of_middle_certificate=${file}
        fi
    done
}


# $1 = path_to_certificates_directory
# $2 = name_of_middle_certificate
createFullChain() {
    echo 'yeah'
    for certificate in ${certificates[@]}
    do
        echo $certificate
        if [[ $certificate =~ (.*)\/([^\/]*)\.crt$ ]];
        then
            fileName=${BASH_REMATCH[2]}
            cat ${certificate} ${name_of_middle_certificate} > ${path_to_certificates_directory}/${fileName}-fullchain.crt
        fi
    done

}

if [[ $1 ]]
then
    path_to_certificates_directory=$1
fi

getOptions
renameCertificates ${path_to_certificates_directory}
createFullChain
