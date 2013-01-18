include_recipe "apt"
include_recipe "apache2"
include_recipe "mysql"
include_recipe "mysql::server"
include_recipe "apache2::mod_php5"

package "php5-mysql" do
	action :install
end

package "php5-intl" do
	action :install
end

execute "disable-default-site" do
  command "sudo a2dissite default"
  notifies :reload, resources(:service => "apache2"), :delayed
end

web_app "project" do
  template "project.conf.erb"
  notifies :reload, resources(:service => "apache2"), :delayed
end
