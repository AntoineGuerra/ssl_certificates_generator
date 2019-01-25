#!/usr/bin/env bash

source ./kernel.sh

# Current Year
year=$(date +"%Y")

# example :  /etc/pki/tls/certs/walter/<company_name>
path_to_pki_tls_certificates_directory=''
# example : company_name='facebook'
company_name=''
# example : company_unit_name='EC' ==> Expert Comptable
company_unit_name=''
# example : hostname_company='facebook.com'  ==>  url without www.
hostname_company=''


help="
${color_info}1${color_default} the path to put all the generate certificate :
  - ${color_info}example :  /etc/pki/tls/certs\n
${color_info}2${color_default} The Owner Website Company Name :
  - ${color_info}example : 'facebook'\n
${color_info}2${color_default} The Unit Section company :
  - ${color_info}example : 'EC' ==> Expert Comptable\n
${color_info}2${color_default} The Hostname Domain Company :
  - ${color_info}example : 'facebook.com' ==>  url without www.\n"




createVal() {
    varName=$1
    rec=false
    echo -ne "${color_default}Type ${color_success}${varName//_/ }${color_default} and press ${color_success}ENTER :\n"
    if [[ ${varName} = 'path_to_pki_tls_certificates_directory' && ${path_to_pki_tls_certificates_directory} != '' ]]
    then
        read -e -r -p "$ " -i ${path_to_pki_tls_certificates_directory} result
    else

        read -e -r -p "$ " result
        if [[ !(-d ${result}) && ${varName} = 'path_to_pki_tls_certificates_directory' ]]
        then
            echo -e "${color_error}This directory does not exist !"
            exit
        elif [[ (${result} = '' && $varName != 'state') || $result =~ .*\s.* ]]
        then
            echo -e "${color_error}This value could not be NULL OR contain white space!"
            createVal ${varName}
            rec=true
        elif [[ $varName = 'country' && !(${result} =~ ^.{2}$) ]]
        then
            echo -e "${color_info} 2 (letters)${color_default}"
            createVal ${varName}
            rec=true
        fi
    fi
    if [[ $rec = false ]]
    then
        echo "eval $result"
        eval "${varName}"="${result}"

        echo -ne "${color_default}"
    fi
}


getOptions() {
    options=(
#    'path_to_pki_tls_certificates_directory'
#    'country'
#    'city'
#    'company_name'
#    'company_unit_name'
#    'hostname_company'
    )
    if [[ -z 'path_to_pki_tls_certificates_directory' || ${path_to_pki_tls_certificates_directory} = '' ]]
    then
        path_to_pki_tls_certificates_directory='./newCertificates'
    fi
    prompt_dir 'path_to_pki_tls_certificates_directory' ${path_to_pki_tls_certificates_directory}
    prompt_2letters 'country'
    prompt 'state'
    save_prompt 'state'
    prompt_no_space 'city'
    prompt_no_space 'company_name'
    prompt_2letters 'company_unit_name'
    prompt_host 'hostname_company'

#    for option in ${options[@]};
#    do
#        createVal ${option}
#    done
}

addSlash() {
    if [[ ${path_to_pki_tls_certificates_directory} =~ (.*[^\/])\/+$ ]]
    then
        path_to_pki_tls_certificates_directory=${BASH_REMATCH[1]}
    fi
    path_to_pki_tls_certificates_directory="${path_to_pki_tls_certificates_directory}/"

}

moveCerts() {
    if [[ ${path_to_pki_tls_certificates_directory} != './' && ${path_to_pki_tls_certificates_directory} != '.' ]]
    then
        addSlash
        if [[ !(-d ${path_to_pki_tls_certificates_directory}${company_name}) ]]
        then
            mkdir ${path_to_pki_tls_certificates_directory}${company_name}
        fi
        mv ${company_name}-${year}.key ${path_to_pki_tls_certificates_directory}${company_name}/
        mv ${company_name}.csr ${path_to_pki_tls_certificates_directory}${company_name}/
    else
        if [[ !(-d ./${company_name}) ]]
        then
            mkdir ./${company_name}
        fi
    fi

}

# $1 = file data checked
checkCertFilesData() {
    file=$1
    echo -e "${color_info}Test ${file} Begining"
    if [[ ${file} = './config.conf' ]]
    then
        datas=('email')
    else
        datas=('country' 'city' 'company_name' 'company_unit_name' 'hostname_company')
    fi
    for data in ${datas[@]}
    do
        value=$(eval echo "\$$data")
#        echo $value
        prompt_result=$value
        if [[ $data = 'country' || $data = 'company_unit_name' ]]
        then
            checkPrompt $data '2letters'
        elif [[ $data = 'hostname_company' ]]
        then
            checkPrompt $data 'host'
        elif [[ $data = 'email' ]]
        then
            checkPrompt $data 'mail'
        else
            checkPrompt $data 'no-space'
        fi
    done
    prompt_result=''
    if [[ ${prompt_valid} = false ]]
    then
        echo -e "${color_error}ERROR in ${file} Verifications"
        exit
    else
        echo -e "${color_success}Success ${file} Verifications"
    fi
}

# $1 = file created
createdFile_message() {
    file=$1
    if [[ -f $file ]]
    then
        textResult="${color_success}${company_name}.csr generated with success !"
        textResult="${textResult}${color_info} in ${file}\n"
        textResult="${textResult}${color_info}The following file content of ${color_success}${company_name}.csr${color_info} was copy to your clipboard\n"
        textResult="${textResult}${color_default}To send at SSL distributor example : GANDI SSL certificate => https://shop.gandi.net/fr/00000000-0000-0000-0000-000000000000/certificate/create"
    else
        textResult="${color_error}ERROR ! The ${company_name}.csr cannot create\n"
        textResult="${textResult}${color_warning}Please try again OR contact admin of this script${color_default}"
    fi
    echo -e "${textResult}"
    read -n 1 -s -r -p "Press any key to continue"
}

generateCertificate() {
    ./newcert.expect ${company_name} ${company_unit_name} ${hostname_company} ${year} ${country} ${city} ${email} ${state} ${password}
    moveCerts
    addSlash
    if [[ "$OSTYPE" == "linux-gnu" ]]; then
    # ...
        echo -e $(cat ${path_to_pki_tls_certificates_directory}${company_name}/${company_name}.csr) | xclip -selection clipboard
    elif [[ "$OSTYPE" == "darwin"* ]]; then
    # Mac OSX
        echo -e "$(cat ${path_to_pki_tls_certificates_directory}${company_name}/${company_name}.csr)" | pbcopy -selection clipboard
    fi
    createdFile_message "${path_to_pki_tls_certificates_directory}${company_name}/${company_name}.csr"
}

if [[ $1 = '-h' || $1 = '--help' || $1 = '-help' ]]
then
    echo -e ${help}
    exit
fi

if [[ $1 ]]
then
    path_to_pki_tls_certificates_directory=$1
fi
checkLastUse 'part1'
if [[ !(-f ./newcert.expect) ]]
then
    echo -e "${color_error}You should have newcert.expect in the same directory !"
    exit;
fi

certificatesFile=($(ls ./newCertificates/*.certgen 2> /dev/null))

source ./config.conf
checkCertFilesData ./config.conf
if [[ ${#certificatesFile[@]} -eq 0 ]]
then
    getOptions
    generateCertificate
    echo -e "\n${color_info}If your server run on nginx Don't forget add this to your conf :
    ${color_default}location ^~ /.well-known/pki-validation/ {
        allow all;
        default_type "text/plain";
    }"
    echo -e "${color_default}Do you want generate another certificate ? :"
    read -e -r -p "$ " result
    if [[ ${result} =~ ^[yY]{1}[eE]?[sS]?.*$ ]]
    then

        ./cert_ssl_part1.sh ${path_to_pki_tls_certificates_directory}
    else
        echo -e "Nice, all cards are in your hands"
    fi
else
    for certificate in ${certificatesFile[@]}
    do
        source $certificate
        checkCertFilesData $certificate
        generateCertificate
    done
fi



