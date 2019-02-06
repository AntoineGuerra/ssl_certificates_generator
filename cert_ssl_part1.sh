#!/usr/bin/env bash
color_default='\033[0m'
color_warning='\033[0;33m'
color_info='\033[0;36m'
color_success='\033[0;32m'
color_error='\033[0;31m'

if [[ ! (-f kernel.sh) ]]
then
    echo -e "${color_error}You must have kernel.sh !${color_default}"
fi
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
    echo -ne "${color_default}Type ${color_success}${varName//_/ }${color_default} and press ${color_success}ENTER :\n${color_default}"
    if [[ ${varName} = 'path_to_pki_tls_certificates_directory' && ${path_to_pki_tls_certificates_directory} != '' ]]
    then
        read -e -r -p "$ " -i ${path_to_pki_tls_certificates_directory} result
    else

        read -e -r -p "$ " result
        if [[ !(-d ${result}) && ${varName} = 'path_to_pki_tls_certificates_directory' ]]
        then
            echo -e "${color_error}This directory does not exist !${color_default}"
            exit
        elif [[ (${result} = '' && $varName != 'state') || $result =~ .*\s.* ]]
        then
            echo -e "${color_error}This value could not be NULL OR contain white space !${color_default}"
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
        if [[ ! (-d ${path_to_pki_tls_certificates_directory}${company_name}) ]]
        then
            mkdir ${path_to_pki_tls_certificates_directory}${company_name}
        fi
        if [[ -f ./${company_name}-${year}.key ]]
        then
            mv ${company_name}-${year}.key ${path_to_pki_tls_certificates_directory}${company_name}/
        else
            echo -e "${color_error}ERROR ${company_name}-${year}.key does not exist !"
        fi
        if [[ -f ./${company_name}-${year}.key ]]
        then
            mv ${company_name}.csr ${path_to_pki_tls_certificates_directory}${company_name}/
        else
            echo -e "${color_error}ERROR ${company_name}.csr does not exist !"
        fi
    else
        if [[ ! (-d ./${company_name}) ]]
        then
            mkdir ./${company_name}
        fi
    fi

}

# $1 = file data checked
checkCertFilesData() {
    file=$1
    echo -e "${color_info}Test ${file} Begining${color_default}"
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
        echo -e "${color_error}ERROR in ${file} Verifications${color_default}"
        exit
    else
        echo -e "${color_success}Success ${file} Verifications${color_default}"
    fi
}

# $1 = file created
createdFile_message() {
    file=$1
    if [[ -f $file ]]
    then
        textResult="${color_success}${company_name}.csr generated with success !${color_default}"
        textResult="${textResult}${color_info} in ${file}${color_default}\n"
        textResult="${textResult}${color_info}The following file content of ${color_success}${company_name}.csr${color_info} was copy to your clipboard${color_default}\n"
        textResult="${textResult}${color_default}To send at SSL distributor example : GANDI SSL certificate => https://shop.gandi.net/fr/00000000-0000-0000-0000-000000000000/certificate/create${color_default}"
    else
        textResult="${color_error}ERROR ! The ${company_name}.csr cannot create${color_default}\n"
        textResult="${textResult}${color_warning}Please try again OR contact admin of this script${color_default}"
    fi
    echo -e "${textResult}"
    read -n 1 -s -r -p "Press any key to continue"
}

generateCertificate() {
    checkScript ./newcert.expect
    if [[ -f ./newcert.expect ]]
    then
        ./newcert.expect ${company_name} ${company_unit_name} ${hostname_company} ${year} ${country} ${city} ${email} ${state} ${password}
    fi
    moveCerts
    addSlash
    if [[ ! (-f ${path_to_pki_tls_certificates_directory}${company_name}/${company_name}.csr) ]]
    then
        echo -e "${color_error}ERROR ! Cannot create : ${color_warning}${path_to_pki_tls_certificates_directory}${company_name}/${company_name}.csr${color_default}"
    fi
    if [[ ${OSTYPE} == "linux-gnu" ]]
    then
    # ...
        checkFile "./${path_to_pki_tls_certificates_directory}${company_name}/${company_name}.csr" "cert"
        if [[ ${cert} = true ]]
        then
            echo -e $(cat ${path_to_pki_tls_certificates_directory}${company_name}/${company_name}.csr) | xclip -selection clipboard
        fi
    elif [[ ${OSTYPE} == "darwin"* ]]
    then
    # Mac OSX
        checkFile "./${path_to_pki_tls_certificates_directory}${company_name}/${company_name}.csr" "cert"
        if [[ ${cert} = true ]]
        then
            echo -e "$(cat ${path_to_pki_tls_certificates_directory}${company_name}/${company_name}.csr)" | pbcopy -selection clipboard
#        else
#            echo -e "${color_error}ERROR "
        fi
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
    echo -e "${color_error}ERROR ! You must have newcert.expect in the same directory !${color_default}"
    exit
fi

certificatesFile=($(ls ./newCertificates/*.certgen 2> /dev/null))


if [[ ! (-f ./config.conf) ]]
then
    if [[ -f ./config.conf.sample ]]
    then
        echo -e "${color_warning}Please run :\n${color_default}$ cp config.conf.sample config.conf\n${color_warning}Edit it :\n${color_default}$ vi config.conf"
    else
        echo -e "${color_warning}Please go here : https://github.com/AntoineGuerra/ssl_certificates_generator#example-configconf${color_default}"
    fi
    exit
fi
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
    echo -e "${color_default}Do you want generate another certificate ? :${color_default}"
    read -e -r -p "$ " result
    if [[ ${result} =~ ^[yY]{1}[eE]?[sS]?.*$ ]]
    then
        checkScript ./cert_ssl_part1.sh
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



