node default {

 class { 'cron-puppet': }

 class { 'accounts': }

 class { "nginx": }

 class { "djangoweb":
       owner   => "deploy",
       require => User [ "deploy"],
     }
}

