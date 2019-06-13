# continuous-delivery-helpers

## How it works

We make use of CGI with apache2 to allow an authorized user to spawn arbitrary docker images on a deploy machine.

The basic idea is that we have a virtual host for controlling deployments to a deploy machine, that deploy machine can be the same or a remote one, considering the scripts in this repository, it is more suited for remote machines, but you could still configure it to ssh into `localhost` to deploy on the same machine as the controlling one.

## apache2

We will need CGI so it needs to be enabled, you can do so with `a2enmod cgi` then restart apache2.

On Ubuntu Bionic, there's a pre-written configuration for CGI at `/etc/apache2/conf-available/serve-cgi-bin.conf`.

```
<IfModule mod_alias.c>
	<IfModule mod_cgi.c>
		Define ENABLE_USR_LIB_CGI_BIN
	</IfModule>

	<IfModule mod_cgid.c>
		Define ENABLE_USR_LIB_CGI_BIN
	</IfModule>

	<IfDefine ENABLE_USR_LIB_CGI_BIN>
		ScriptAlias /cgi-bin/ /usr/lib/cgi-bin/
		<Directory "/usr/lib/cgi-bin">
			AllowOverride None
			Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
			Require all granted
		</Directory>
	</IfDefine>
</IfModule>

# vim: syntax=apache ts=4 sw=4 sts=4 sr noet
```

You can simply add `Include /etc/apache2/conf-available/serve-cgi-bin.conf` in your virtual host configuration.

With that CGI configuration, for the CGI script to be called by apache2, it needs to be inside the `/usr/lib/cgi-bin` folder, after cloning this repositority, you can simply copy the `cgi/docker-deploy.bash` script over to that folder.

The CGI script at `cgi/docker-deploy.bash` needs configuration, for that, it uses the environment.
Apache2 provides a way to pass down environment within a virtual host, therefore, there is an example configuration at `apache2_conf/docker-deploy.conf` that you can write at `/etc/apache2/conf-available/docker-deploy.conf` and use in similar ways to the above CGI configuration.

Note that for ssh to work properly, the identity private key must be owned by the user that will execute the CGI script, for the case of apache2, it is likely to be `www-data`. You can create the `/var/www/.ssh` folder then make sure that folder and all files insides it are owned by `www-data` with `chown -R www-data /var/www/.ssh`. A `known_hosts` file should also exist within that `/var/www/.ssh` folder with the deploy machine's ssh host key already filled in.

Below you can find commands that will configure this properly; run these as root.

```
ssh-keygen # Generate an ssh identity key
ssh-copy-id <user>@<deploy-machine-ip> # Copy the public identity key over, logging in to the machine makes the .ssh/known_hosts file filled in too. 
cp ~/.ssh /var/www/.ssh
chown -R www-data /var/www/.ssh
```