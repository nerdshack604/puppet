# = Class: djangoweb
# 
# This class will call over to one or more approots. 
# It will also ensure the presence of the Deploy user key. 
# For more approot information, please refer to approots.pp
#
# == Parameters: 
#
# $owner::        The user that will own the deployment
# 
# == Sample Usage:
#
# class { 'djangoweb':
#   owner => 'deploy',
#   stage => post
# }
#
# The class itself contains approots, these definitions are the main
# guts of the system. It is possible to have multiple copies.
#

class djangoweb($owner = 'deploy') {

# All djanoweb applications live here
file { "/webapps":
    ensure  => "directory",
    mode    => 2755,
    owner   => "deploy",
    group   => "nginx",
    }

# This is a workaround. Recent python-pip package releases have removed /usr/bin/pip-python. This breaks Puppet's pip provider.
file { "/usr/bin/pip-python": 
    ensure => "link",
    target => "/usr/bin/pip",
    }

file { "/var/run/gunicorn":
    ensure  => "directory",
    owner   => "nginx",
    group   => "nginx",
    require => Package [ "nginx" ]
   }
 
$requiredpackages = [ "epel-release", "python-pip", "python-devel", "gcc", "git" ]

package { $requiredpackages:
    ensure => "installed",
}

$requiredpippackages = [ "gunicorn", "virtualenv", "django", ]

package { $requiredpippackages:
    ensure   => installed, 
    provider => pip,
    require  => File [ "/usr/bin/pip-python" ]
}

  create_resources(djangoweb::approots, hiera(approots))
#  create_resources(djangoweb::approots::aliases, hiera(approots_aliases))
}
