# = Define: djangoweb::approots
#
# This define will ensure a document root and settings are both present
# and contains a copy of production code from github.com. It also
# will create an nginx conf based on the $host_name.
#
# This module will also ensure the presence of the Deploy user key. All
# github repos use this account for read-only interactions
#
# == Parameters:
#
# $approot::        The dirname inside /webappas (defaults to linkunderflow)
# $gitrep::         The github remote repository
# $gitsettings::    The repo for the settings document
# $gitbranch::      The branch to checkout for document (defaults to master)
# $gsitbranch::     The branch to checkout for settings (defaults to production)
# $vhostroot::      The virtual host root (*currently not used)
# $owner::          The user that will own the deployment
# $host_port::      The server port for nginx (defaults to 80)
# $host_name::      The server hostname for nginx
# $dyanmicredir::   Do we wish to enable dynamic redirection
# $authbasic::      Enable to make the whole site auth protected
# $authuser::       Array of tuples, each with l+p for basic auth
# $redirectdomain:: Domain to redirect all requests for this domain
#
# == Sample Usage:
#
# approots {'approots::sitename':
#   approot => 'linkunderflow',
#   gitrepo => 'git@github.com:incendia/nerdshack604/linkunderflow.git',
#   host_port => '82',
#   host_name => 'linkunderflow.com'
# }
#

define djangoweb::approots (
    $approot        = 'default',
    $gitrepo        = '',
    $gitbranch      = master,
    $vhostroot      = '/webapps/',
    $owner          = 'deploy',
    $host_port      = '',
    $host_name      = 'default.com',
    $dynamicredir   = false,
    $authbasic      = false,
    $authuser       = [],
    $expires_max    = 'max',
    $redirectdomain = '',
    $wwwdomain      = 'true'
    ) {

    file { "${approot}_app_folder":
      path    => "/webapps/${approot}",
      ensure  => "directory",
      owner   => $owner,
      group   => "nginx",
      mode    => 2775,
      #notify  => Exec [ "startproject_${approot}" ],
    } 

    file { "${approot}_systemd_service":
      path    => "/etc/systemd/system/${approot}.service",
      mode    => 644,
      owner   => "root",
      group   => "root",
      checksum => 'md5',
      content => template('djangoweb/systemd.erb'),
      require => File [ "${approot}_app_folder" ],
      notify  => Exec["restart_${approot}_service"]
    }
	
    exec { "startproject_${approot}":
      command => "/usr/bin/su ${owner} -c  '/etc/puppet/modules/djangoweb/files/django-folder-maint.sh ${approot} /webapps/${approot}'",
      require => File [ "${approot}_app_folder" ],
      #notify  => Service [ "${approot}_service" ],
      }

    service { "${approot}_service":
       name     => "${approot}",
       ensure   => "running",
       require  => File [ "${approot}_systemd_service" ],
     }

  if ( $gitrepo == '' ) {
    notify{"No gitrepo specified. Assuming ${approot} tarballs in place..": }
    #fail( "Parameter 'gitrepo' must be set for ${owner}" )
  }
  else {
    $_gitconfigdir = "${vhostroot}${approot}/.git/"

    include vcsrepo

    notify{"This vhost has a WWW host prefix? ${wwwdomain}":}

    # Deploy the app straight from Git into the approot
    vcsrepo { "${vhostroot}${approot}":
      ensure => present,
      provider => git,
      user => $owner,
      require => [ File["/home/${owner}/.ssh/github-deploy.rsa"] ],
      notify => File["${approot}_cp_template_over"],
      source => $gitrepo,
      #require => User[$owner],
    }

    file { "${approot}_cp_template_over":
      path    => "${_gitconfigdir}/._puppet.tmp",
      mode    => 644,
      owner   => $owner,
      group   => $owner,
      content => template('djangoweb/extra_git_settings.erb'),
      notify  => Exec[ "${approot}_update_git_config" ],
    }

    # next we will set the denyCurrentBranch
    exec { "${approot}_update_git_config":
      cwd => $_gitconfigdir,
      unless => 'grep -i "denyCurrentBranch" config',
      command => 'cat ._puppet.tmp >> config',
      notify  => File [ "${approot}_update_githooks" ],
    }

    # Here we will create the post receive hook
    file { "${approot}_update_githooks":
      path    => "${_gitconfigdir}/hooks/post-receive",
      mode    => 755,
      owner   => $owner,
      group   => $owner,
      content => template('djangoweb/post_receive_hook.sh'),
    }
  }

    exec {"restart_${approot}_service":
      command => "/usr/bin/systemctl daemon-reload; /usr/bin/systemctl enable ${approot}.service; /usr/bin/systemctl restart ${approot}.service",
      refreshonly => true,
    }


  # obviously, only configure nginx if we passed a port over
  if ( $host_port != '') {
    # not the best place for this, but putting it into
    # fpmfrontends causes a cyclical loop .. not good.
    # Even putting Service['nginx'] here causes problems
    exec {"restart_${approot}_nginx":
      command => "/usr/sbin/service nginx reload",
      refreshonly => true,
      subscribe => File["${approot}_updated_nginx_conf"],
    }

    # if basic auth is enabled, create the htpassword file
    if ( $authbasic == true ) {
      file {"/etc/nginx/htpasswd_${host_name}":
        ensure => file,
        content => template('djangoweb/htpassword.template'),
        mode => '0644',
        checksum => 'md5'
      }
    }

    file { "${approot}_updated_nginx_conf":
      path    => "/etc/nginx/conf.d/${host_name}.conf",
      mode    => 644,
      owner   => $owner,
      group   => $owner,
      checksum => 'md5',
      content => template('djangoweb/nginx_host.erb'),
      require => [ User[$owner]],
      notify  => Exec["restart_${approot}_nginx"]
    }

  }

}

