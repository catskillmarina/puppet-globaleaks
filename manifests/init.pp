# == Class: globaleaks
#
# Full description of class globaleaks here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { globaleaks:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2014 Your name here, unless otherwise noted.
#
class globaleaks {
  package { ['tor','geoip-database','curl']:
    ensure => latest,
  }
  service { 'tor':
    ensure => 'running',
    enable => true,
  }
  service { 'apparmor':
    ensure => running,
    notify => Service['tor'],
  }
  file { '/etc/tor/torrc':
    ensure  => file,
    source  => 'puppet:///modules/globaleaks/torrc',
    owner   => root,
    group   => root,
    mode    => '0644',
    notify  => Service[apparmor],
    require => Package['tor'],
  }
  file { '/opt/globaleaks':
    ensure => 'directory',
  }
  exec { 'get-globaleaks':
    command  => 'wget https://raw.github.com/globaleaks/GlobaLeaks/master/scripts/install-ubuntu-12_04.sh',
    cwd      => '/opt/globaleaks',
    creates  => '/opt/globaleaks/install-ubuntu-12_04.sh',
    path     => '/usr/bin',
  }
  file { '/opt/globaleaks/install-ubuntu-12_04.sh':
    owner    => 'root',
    group    => 'root',
    mode     => '0755',
    require  => Exec['get-globaleaks'],
  }
  exec { 'install-globaleaks':
    command     => '/opt/globaleaks/install-ubuntu-12_04.sh -y',
    cwd         => '/opt/globaleaks',
    creates     => '/var/globaleaks',
    require     => File['/opt/globaleaks/install-ubuntu-12_04.sh'],
    logoutput   => true,
    refreshonly => true,
    timeout     => 1800,
    path        => '/bin:/sbin:/usr/bin:/usr/sbin',
  }
  service { 'globaleaks':
    enable  =>  true,
    ensure  =>  running,
    require =>  Exec['install-globaleaks'],
  }
  file { '/etc/sysctl.conf':
    content => 'fs.file-max=100000
',
  }
  exec { 'reload-sysctl':
    command     =>  '/sbin/sysctl -p',
    refreshonly => true,
    subscribe   => File['/etc/sysctl.conf'],
  }
}
