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
    $service_ipv4 = false,
)   {
    package {"bird":
        version => installed
    }
}
