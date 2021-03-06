#!/usr/bin/env bash

color_default='\033[0m'
color_warning='\033[0;33m'
color_info='\033[0;36m'
color_success='\033[0;32m'
color_error='\033[0;31m'

path_to_certificates_directory=''
name_of_middle_certificate=''
certificates=()

if [[ ! (-f kernel.sh) ]]
then
    echo -e "${color_error}You must have kernel.sh !${color_default}"
fi
source ./kernel.sh

addSlash() {
    if [[ ${path_to_certificates_directory} =~ (.*[^\/])\/+$ ]]
    then
        path_to_certificates_directory=${BASH_REMATCH[1]}
    fi
    path_to_certificates_directory="${path_to_certificates_directory}/"
}


# $1 = file data checked
checkCertFilesData() {
    file=$1
    source $file
    if [[ ${file} = './config.conf' ]]
    then
        datas=('use_conf_generator')
    else
        datas=('company_name' 'hostname_company')
    fi
    for data in ${datas[@]}
    do
        local value=$(echoDataByStr $data)
        if [[ $value = '' ]]
        then
            echo -e "There is an ${color_error}ERROR ${color_default} in ${color_info}${file}"
            echo -e "${color_error}${data//_/ } is REQUIRED !${color_default}"
            exit

        elif [[ $data = 'use_conf_generator' && ($value != true && $value != false) ]]
        then
            echo -e "There is an${color_error} ERROR ${color_default} in ${color_info}${file}${color_default}"
            echo -e "${color_error}${data//_/ } could be a boolean !${color_default}"
            exit
        fi
    done
}

# $1 = path_to_certificates_directory
# $2 = value
createVal() {
    varName=$1
    value=$2
    echo -ne "${color_default}Type ${color_success}${varName//_/ }${color_default} and press ${color_success}ENTER :${color_default}\n"
    if [[ ${path_to_certificates_directory} != '' && ${varName} = 'path_to_certificates_directory' && -d ${path_to_certificates_directory} ]]
    then
        read -e -r -p "$ " -i ${path_to_certificates_directory} result
    elif [[ $value ]]
    then
        read -e -r -p "$ " -i $value result
    else
        read -e -r -p "$ " result
    fi
    if [[ $result = '' ]]
    then
        echo -e "${color_error} ERROR !\n${varName//_/ } could not be empty !${color_default}"
        createVal $1 $2
    elif [[ $varName = document_website_root_in_server && $result =~ (.*[^\/])\/+$ ]]
    then
        echo -e "${color_error} ERROR !\n${varName//_/ } could not end by '/' !\n${color_warning}Try with ${BASH_REMATCH[1]}${color_default}"
        createVal $1 ${BASH_REMATCH[1]}
    fi
    eval "${varName}"="${result}"
    echo -ne "${color_default}"
}

getOptions() {
    options=('path_to_certificates_directory')
#    for option in ${options[@]};
#    do
#        createVal ${option}
#    done
#    createVal 'path_to_certificates_directory' './downloadedCertificate/'
    prompt_dir 'path_to_certificates_directory' './downloadedCertificate/'
}


# $1 = ${path_to_certificates_directory} dir/*.crt&file.pem
# $2 = name_of_middle_certificate --> file.pem
renameCertificates() {
    for file in $1/*
    do
        if [[ $file =~ (.*)\/([^\/]*)\.crt$ ]];
        then
            fileName=${BASH_REMATCH[2]}
            path=${BASH_REMATCH[1]}
            if [[ ! (${path} =~ "(.*)\/$") ]]
            then
                path="${path}/"
            fi
#            cp $file ${path}${fileName}-$(date +"%Y").crt
            certificates+=(${path}${fileName}.crt)
        elif [[ $file =~ ([^\/]*)\.pem$ ]]
        then
            name_of_middle_certificate=${file}
        fi
    done
}




# $1 = PATH/TO/file
createdFileMessage() {
    file=$1
    if [[ -f ${file} ]]
    then
        echo -e "${color_success}File created with success ${color_info}${file}${color_default}"
    else
        echo -e "${color_error}ERROR ! ${color_default}Cannot create file ${color_info}${file}${color_default}"
    fi
}


# $1 = path_to_certificates_directory
# $2 = name_of_middle_certificate
createFullChain() {
    addSlash

    echo -e "Do you want use the ${color_success}apache/nginx${color_default} conf template generator ?"
    if [[ ${use_conf_generator} ]]
    then
        read -e -r -p "$ " -i "yes" result
    else
        read -e -r -p "$ " result
    fi
    if [[ ${result} =~ ^[yY]{1}e?s?.*$ ]]
    then
        use_conf_generator=true
        checkLastUse 'conf_gen'
        echo -e "${color_success}You use the conf template generator${color_default}"
    else
        echo -e "${color_warning}You don't use the conf template generator${color_default}"
        use_conf_generator=false
    fi
    for certificate in ${certificates[@]}
    do
        if [[ $certificate =~ (.*)\/([^\/]*)\.crt$ ]];
        then
            fileName=${BASH_REMATCH[2]}
            echo -e "${color_info}$fileName beginning"
            createVal 'company_name'
            if [[ !(-d ${path_to_certificates_directory}${company_name}) ]]
            then
                mkdir ${path_to_certificates_directory}${company_name}
            fi

            checkFile ${certificate} "certificate_test"
            checkFile ${name_of_middle_certificate} "middle_certificate"
            if [[ ${certificate_test} = true && ${middle_certificate} = true ]]
            then
                cat ${certificate} ${name_of_middle_certificate} > ${path_to_certificates_directory}${company_name}/${company_name}-$(date +"%Y")-fullchain.crt
                createdFileMessage "${path_to_certificates_directory}${company_name}/${company_name}-$(date +"%Y")-fullchain.crt"
                cat ${certificate} ${name_of_middle_certificate} > ${path_to_certificates_directory}${company_name}/${company_name}-$(date +"%Y")-fullchain.pem
                createdFileMessage "${path_to_certificates_directory}${company_name}/${company_name}-$(date +"%Y")-fullchain.pem"
            elif [[ ${certificate} = true ]]
            then
                cat ${certificate} > ${path_to_certificates_directory}${company_name}/${company_name}-$(date +"%Y").crt
                createdFileMessage "${path_to_certificates_directory}${company_name}/${company_name}-$(date +"%Y").crt"
            fi
            if [[ $use_conf_generator = true ]]
            then
                createVal 'hostname_without_www' ${fileName}
                createVal 'path_to_certificate_in_server' "/etc/pki/tls/certs/${company_name}"
                createVal 'document_website_root_in_server' "/var/www/html/${company_name}"
                checkScript ./conf_generator.sh
                if [[ -f ./conf_generator.sh ]]
                then
                    ./conf_generator.sh ${company_name} ${hostname_without_www} ${path_to_certificate_in_server} ${document_website_root_in_server}
                fi
            fi
        fi
    done

}



if [[ $1 ]]
then
    path_to_certificates_directory=$1
fi

checkLastUse 'part2'

checkCertFilesData "./config.conf"
getOptions
renameCertificates ${path_to_certificates_directory}
createFullChain
