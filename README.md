# Djangoweb #

----------
A portable Puppet module for deploying one or multiple Django based sites optionally fronted with Gunicon / Nginx. Sites can be configured with a variety of parameters.


## Provisioning ##
Djangoweb supports direct parameter entry or can ingress facts via hiera. 
1. 


----------

     == Define: djangoweb::approots

     This define will ensure a document root and settings are both present
     and contains a copy of production code from github.com. It also
     will create an nginx conf based on the $host_name.

     This module will also ensure the presence of the Deploy user key. All
     github repos use this account for read-only interactions

     == Parameters:

     $approot::        The dirname inside /webappas (defaults to linkoverflow)
     $gitrep::         The github remote repository
     $gitsettings::    The repo for the settings document
     $gitbranch::      The branch to checkout for document (defaults to master)
     $vhostroot::      The virtual host root (*currently not used)
     $owner::          The user that will own the deployment
     $host_port::      The server port for nginx (defaults to 80)
     $host_name::      The server hostname for nginx
     $dyanmicredir::   Do we wish to enable dynamic redirection
     $authbasic::      Enable to make the whole site auth protected
     $authuser::       Array of tuples, each with l+p for basic auth
     $redirectdomain:: Domain to redirect all requests for this domain

     == Sample Usage:

     approots {'approots::sitename':
       approot => 'linkoverflow',
       gitrepo => 'git@github.com:nerdshack604/linkoverflow.git',
       host_port => '82',
       host_name => 'linkoverflow.com'
     }



