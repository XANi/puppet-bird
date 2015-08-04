# == Class: bird
#
# Full description of class bird here.
#
# === Parameters
#
# Document parameters here.
#
# [*version*]
#   Version of package to use, defaults to "installed" to avoid uncontrolled upgrade
#
# [*service_ipv4*]
#   Run IPv4 bird service. Defaults to true
# [*service_ipv6*]
#   Run IPv6 bird service. Defaults to false
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
#  class { 'bird':
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2015 Your name here, unless otherwise noted.
#
class bird (
    $version = "installed",
    $service_ipv4 = true,
    $service_ipv6 = false,
    $router_id = $ipaddress,
)   {
    package {"bird":
        ensure => $version
    }
    if $service_ipv4 {
        service {'bird':
            ensure => running,
            enable => true,
        }
    }
    else {
        service {'bird':
            ensure => stopped,
            enable => false,
        }
    }
    if $service_ipv6 {
        service {'bird6':
            ensure => running,
            enable => true,
        }
    }
    else {
        service {'bird6':
            ensure => stopped,
            enable => false,
        }
    }
    include bird::v4::conf
}

class bird::v4::conf {
    require bird
    $router_id = $bird::router_id
    File {
        mode => 644,
        owner  => bird,
        group  => bird,
    }
    file {'/etc/bird/v4.d':
        ensure => directory,
        purge  => true,
        recurse => true,
    }
    file {'/etc/bird/bird.conf':
        content => template('bird/bird.conf'),
    }
    exec { 'reload-bird':
        onlyif     => '/usr/sbin/bird -p -c /etc/bird/bird.conf',
        command    => 'systemctl reload bird',
        refreshonly => true
    }
}

class bird::v6::conf {
    require bird
    $router_id = $bird::router_id
    File {
        mode => 644,
        owner  => bird,
        group  => bird,
    }
    file {'/etc/bird/v6.d':
        ensure => directory,
        purge  => true,
        recurse => true,
    }
    file {'/etc/bird/bird6.conf':
        content => template('bird/bird6.conf'),
    }
    exec { 'reload-bird':
        onlyif     => '/usr/sbin/bird6 -p -c /etc/bird/bird6.conf',
        command    => 'systemctl reload bird6',
        refreshonly => true
    }
}

define bird::config (
    $version = "4",
    $prio = '1000',
    $config,
)   {
    require bird
    if $version == 4 {
        include bird::v4::conf
    }
    elsif $version == 6 {
        include bird::v6::conf
    }
    else {
        fail('bad version')
    }

    $padded_prio = sprintf('%04d',$prio) # 4 -> 0004
    file {"/etc/bird/v${version}.d/${padded_prio}-${title}.conf":
        content => template('bird/part.conf'),
        owner   => bird,
        group   => bird,
        mode    => 640,
#        notify  => Exec['reload-bird'],
    }
}
