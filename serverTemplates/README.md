#Conf generator template
Generate template for nginx and apache conf

## USAGE 
Please add these modifications to your server

### Test Your conf :
#### NGINX
```
$ nginx -t
```
#### APACHE
```
$ apachectl -t
```
### Restart them :
#### NGINX
```
$ service nginx reload
```
#### APACHE
```
$ sudo apachectl restart
```

##### Possibly have to run :
```
$ sudo apachectl startssl
```