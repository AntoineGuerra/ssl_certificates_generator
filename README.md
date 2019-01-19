# ssl_certificates_generator

Simple ssl certificate generator :
It work in two step, the [first Step](https://github.com/AntoineGuerra/ssl_certificates_generator/blob/master/README.md#step-1) generate your certificate with open ssl and configure the name with `${company}-${currentYear}.key` and `${company}.csr`.
<br>
You can Generate [multi certificate](https://github.com/AntoineGuerra/ssl_certificates_generator/blob/master/README.md#only-if-youve-to-generate-multi-certificate-)<br>
The [second step](https://github.com/AntoineGuerra/ssl_certificates_generator/blob/master/README.md#step-2) work after you've downloaded you certificate by an SSL Distributor like [Gandi](https://www.gandi.net/fr)<br>
This step create a full chain certificate with (`certificate.crt` + `middleCert.pem`)

## Getting Started

Please, run :

```
$ git clone https://github.com/AntoineGuerra/ssl_certificates_generator.git
$ cd ssl_certificates_generator
```
The SSL certificate generator has 2 parts, you can generate your `certificate.csr` `certificate.key`  with the first
AND you can create the full chain certificate with the second

### Prerequisites

##### BASH version >= 4.0 is required
To update it please run :
###### On Linux
```
$ sudo apt-get update && sudo apt-get install --only-upgrade bash
```
###### On MAC OS 
consider you have brew installed <https://brew.sh/>
```
$ brew update && brew install bash
```
##### Expect is required :
###### On Linux
```
$ sudo apt-get update && sudo apt-get install expect
```
###### On MAC OS
consider you have brew installed <https://brew.sh/>
```
$ brew install expect
```

### Installing
Please run :
```
$ cd PATH/TO/ssl_certificates_generator/
$ chmod +x *.sh
```
#### Step 1 
The step 1 generate your `${company_name}.csr` and `${company_name}-${currentYear}.key`<br>
##### Please configure the `config.txt`

##### ONLY IF you've to generate multi certificate :
Prepare your certificates, run :
```
$ cd PATH/TO/ssl_certificates_generator/newCertificates/
```
AND 
```
$ cp certificate.certgen.sample certificate.certgen
$ cp certificate2.certgen.sample certificate2.certgen
```
OR 
```
$ cat certificate.certgen.sample > certificate.certgen
$ cat certificate.certgen.sample > certificate2.certgen
```
certificate.certgen example :
```
# Company country (2 letters)
country='FR';
# Company state (leave blank for france)
state='';
# Company city
city='Lyon';
# Company name
company_name='testCompany';
# Company Unit Name
company_unit_name='TE';
# Company website Hostname
# Example : 'example.fr'
hostname_company='example.fr';
```
Please replace data of each file by your data
##### END ONLY 
##### Run :
```
$ PATH/TO/ssl_certificates_generator/cert_ssl_part1.sh
```
#### Step 2
The Step 2 create the : `certificate-${currentYear}-fullchain.crt` (full chain file) with an `middleCertificate.pem` and multi `certificate.crt`


Download and put all your certificate file in the same directory potentially in : 

Please have sure You've one `middleCertificate.pem` and one or more `certificate.crt`
```
ssl_certificate_generator/downloadedCertificate/
```
Run 
```
./cert_ssl_part2.sh ./downloadedCertificate/
```

## Authors

* **Antoine Guerra** - *Initial work* - [ssl_certificates_generator](https://github.com/AntoineGuerra/ssl_certificates_generator.git)

