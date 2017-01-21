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
    if $osfamily == 'RedHat' {
        include bird::centos
    }
    include bird::v4::conf
    class  { 'bird::service':
        service_ipv4 => $service_ipv4,
        service_ipv6 => $service_ipv6;
    }
}

class bird::service (
    $service_ipv4 = true,
    $service_ipv6 = false,
    ) {
    if $service_ipv4 {
        service {'bird':
            ensure => running,
            enable => true,
            require => Package['bird'],
        }
    }
    else {
        service {'bird':
            ensure => stopped,
            enable => false,
            require => Package['bird'],
        }
    }
    if $service_ipv6 {
        service {'bird6':
            ensure => running,
            enable => true,
            require => Package['bird'],
        }
    }
    else {
        service {'bird6':
            ensure => stopped,
            enable => false,
            require => Package['bird'],
        }
    }
}

class bird::v4::conf {
    require bird
    $router_id = $bird::router_id
    File {
        mode => "644",
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
        command     => 'systemctl reload bird',
        require     => Exec['validate-bird-config'],
        refreshonly => true,
    }
    # this is here so there will be alert when config is bad
    exec { 'validate-bird-config':
        unless     => '/usr/sbin/bird -p -c /etc/bird/bird.conf',
        command    => '/usr/sbin/bird -p -c /etc/bird/bird.conf',
        logoutput  => true,
    }
}

class bird::v6::conf {
    require bird
    $router_id = $bird::router_id
    File {
        mode => "644",
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
    $prio = false,
    $config,
)   {
    require bird
    if $version == 4 or $version=="4" {
        include bird::v4::conf
    }
    elsif $version == 6 or $version=="6" {
        include bird::v6::conf
    }
    else {
        fail('bad version')
    }
    if $prio {
        $prio_c = $prio
    }
    else {
        # filters need to be defined before they are used
        if $title =~ /filter/ {
            $prio_c = 500
        }
        elsif $title =~ /bfd/ {
            $prio_c = 999
        }
        else {
            $prio_c = 1000
        }
    }

    $padded_prio = sprintf('%04d',$prio_c) # 4 -> 0004
    file {"/etc/bird/v${version}.d/${padded_prio}-${title}.conf":
        content => template('bird/part.conf'),
        owner   => bird,
        group   => bird,
        mode    => "640",
        notify  => Exec['reload-bird'],
    }
}


class bird::centos {
    File {
        mode => 644,
        owner  => bird,
        group  => bird,
    }

    # fix centos crap (possibly fixed in later pacakages)
    user { 'bird':
        ensure => present,
        shell  => '/bin/false',
        system => true,
    }
    group { bird:
        ensure   => present,
        provider => groupadd,
        system   => true,
    }

    file {'/etc/bird':
        ensure => directory,
    }
    file {'/etc/bird.conf':
        ensure => link,
        target => '/etc/bird/bird.conf',
    }

}
