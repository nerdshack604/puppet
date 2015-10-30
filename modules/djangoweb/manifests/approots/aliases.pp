# = Define: djangoweb::approots::aliases
#
# This define is to configure vhost aliases for nginx for an
# already defined approot. Failure to call this on an already
# existing (or to be created) approot may lead to nginx failure.
#
# == Parameters: 
#
# $approot::        The dirname inside /ebs/websites/ (defaults to linkunderflow)
# $vhostroot::      The virtual host root (*currently not used)
# $owner::          The user that will own the deployment
# $host_port::      The server port for nginx (defaults to 80)
# $host_name::      The server hostname for nginx 
# $dyanmicredir::   Do we wish to enable dynamic redirection 
# $authbasic::      Enable to make the whole site auth protected
# $authuser::       Array of tuples, each with l+p for basic auth
# $redirectdomain:: Domain to redirect all requests for this domain

define djangoweb::approots::aliases (
    $approot        = 'linkunderflow',
    $vhostroot      = '/webapps',
    $owner          = 'deploy',
    $host_port      = '',
    $host_name      = 'linkunderflow.com',
    $dynamicredir   = false,
    $authbasic      = false,
    $authuser       = [],
    $expires_max    = 'max',
    $redirectdomain = '',
    $wwwdomain      = 'true'
) {
  # obviously, only configure nginx if we passed a port over
  if ( $host_port != '') {
    exec {"restart_${host_name}_nginx":
      command => "/usr/sbin/service nginx reload",
      refreshonly => true,
      subscribe => File["${host_name}_updated_nginx_conf"],
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

    file { "${host_name}_updated_nginx_conf":
      path    => "/etc/nginx/conf.d/${host_name}.conf",
      mode    => 644,
      owner   => $owner,
      group   => $owner,
      checksum => 'md5',
      content => template('djangoweb/nginx_host.erb'),
      require => User[$owner],
      notify  => Exec["restart_${host_name}_nginx"]
    }
  }

}
