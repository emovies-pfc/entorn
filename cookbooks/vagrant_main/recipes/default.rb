include_recipe "apt"

apt_repository "php54" do
	uri "http://ppa.launchpad.net/ondrej/php5/ubuntu"
	distribution "precise"
	components ["main"]
	keyserver "keyserver.ubuntu.com"
	key "E5267A6C"
	action :add
	notifies :run, "execute[apt-get update]", :immediately
	deb_src true
end

apt_repository "gearman" do
	uri "http://ppa.launchpad.net/gearman-developers/ppa/ubuntu"
	distribution "precise"
	components ["main"]
	keyserver "keyserver.ubuntu.com"
	key "1C73E014"
	action :add
	notifies :run, "execute[apt-get update]", :immediately
	deb_src true
end

include_recipe "apache2"
include_recipe "mysql"
include_recipe "mysql::server"
include_recipe "apache2::mod_php5"
include_recipe "php"
include_recipe "git"
include_recipe "memcached"
include_recipe "java"
include_recipe "python"
include_recipe "supervisor"

package "curl" do
    action :install
end

package "gearman" do
	action :install
end

package "php-pear" do
	action :install
end

package "libgearman-dev" do
	action :install
end

package "php5-mysql" do
	action :install
end

package "php5-intl" do
	action :install
end

package "php-apc" do
	action :install
end

package "php5-memcached" do
  action :install
end

package "vim" do
	action :install
end

package "php5-curl" do
	action :install
end

package "php5-xdebug" do
	action :install
end

package "acl" do
	action :install
end

package "make" do
	action :install
end

php_pear "gearman" do
	action :install
end

file "#{node['vagrant_main']['php']['apache_conf_dir']}/php.ini" do
	action :delete
end

link "#{node['vagrant_main']['php']['apache_conf_dir']}/php.ini" do
	action :create
	to "#{node['php']['conf_dir']}/php.ini"
	notifies :reload, resources(:service => "apache2"), :delayed
end

if File.exists?("/usr/local/bin/composer")
    execute "update-composer" do
        command "composer self-update"
    end
else
    execute "download-composer" do
        command "curl -s https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer"
    end
end

apache_site "default" do
  enable false
end

execute "clone-emovies-project" do
  command "git clone git://github.com/emovies-pfc/emovies-web.git /var/www"
  only_if {(Dir.entries('/var/www') - %w{ . .. }).empty?}
end

directory "/var/www/application/app/cache" do
  owner node['apache']['user']
  group node['apache']['group']
end

directory "/var/www/application/app/logs" do
  owner node['apache']['user']
  group node['apache']['group']
end

execute "set-shared-permisions" do
  command "setfacl -R -m u:#{node['apache']['user']}:rwX -m u:vagrant:rwX /var/tmp/cache /var/log/emovies && setfacl -dR -m u:#{node['apache']['user']}:rwx -m u:vagrant:rwx /var/www/application/app/cache /var/www/application/app/logs"
  returns [0, 1]
end

execute "composer-install" do
  command "composer install"
  cwd "/var/www"
end

web_app "e-movies" do
  server_name "e-movies.local"
  server_aliases ["www.e-movies.local"]
  docroot "/var/www/approot"
  cookbook "apache2"
end

execute "create-database" do
  command "mysql -u root -p#{node[:mysql][:server_root_password]} -e \"CREATE DATABASE IF NOT EXISTS emovie\""
end

supervisor_service "recommender" do
	command "java -jar /vagrant/recomender-1.0-SNAPSHOT-jar-with-dependencies.jar"
end