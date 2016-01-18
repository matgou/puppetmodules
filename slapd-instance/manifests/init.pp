class slapd-instance::base {
    include application

    file { "appli-slapddir":
        ensure => directory,
        path => "/mnt/",
    }

    package { "slapd":
        ensure => "present",
    }
}
define slapd-instance-install (
        $instancename="default",
        $ldap_port=389,
) {
    include slapd-instance::base

    user { "slapd_$instancename":
        ensure  => present,
        comment => "Slapd $instancename Daemon",
        shell   => "/usr/sbin/nologin",
        home    => "/var/empty",
    }

    file { "/mnt/$instancename":
        ensure => directory,
        require => User["slapd_$instancename"],
        path => "/mnt/$instancename",
   }

    file { "/mnt/$instancename/shell":
        ensure => directory,
        require => File["/mnt/$instancename"],
        path => "/mnt/$instancename/shell",
        owner => "slapd_$instancename",
        group => "openldap",
   }

    file { "/mnt/$instancename/config":
        ensure => directory,
        require => File["/mnt/$instancename"],
        path => "/mnt/$instancename/config",
        owner => "slapd_$instancename",
        group => "openldap",
   }

    file { "/mnt/$instancename/data":
        ensure => directory,
        require => File["/mnt/$instancename"],
        path => "/mnt/$instancename/data",
        owner => "slapd_$instancename",
        group => "openldap",
   }

    file { "/mnt/$instancename/tmp":
        ensure => directory,
        require => File["/mnt/$instancename"],
        path => "/mnt/$instancename/tmp",
        owner => "slapd_$instancename",
        group => "openldap",
   }

    file { "/mnt/$instancename/ldap-accesslog":
        ensure => directory,
        require => File["/mnt/$instancename"],
        path => "/mnt/$instancename/ldap-accesslog",
        owner => "slapd_$instancename",
        group => "openldap",
   }

    file { "/mnt/$instancename/ldap-datafile":
        ensure => directory,
        require => File["/mnt/$instancename"],
        path => "/mnt/$instancename/ldap-datafile",
        mode => 777,
        owner => "slapd_$instancename",
        group => "openldap",
   }

    file { "/mnt/$instancename/run":
        ensure => directory,
        require => File["/mnt/$instancename"],
        path => "/mnt/$instancename/run",
        owner => "slapd_$instancename",
        group => "openldap",
   }

   file { "/mnt/$instancename/config/slapd.d.tar.gz":
        ensure => directory,
        source => "puppet:///slapd-instance/slapd.d.tar.gz",
        mode => 644,
        owner => "slapd_$instancename",
        group => "openldap",
        require => File["/mnt/$instancename/config/"]
   }
  
   file { "/mnt/$instancename/config/config.sh":
        ensure => file,
        mode => 600,
        owner => "slapd_$instancename",
        group => "openldap",
        content => template('slapd-instance/config.sh.erb'),
        require => File["/mnt/$instancename/config/"]
   }

   file { "/mnt/$instancename/shell/init_config.sh":
        ensure => file,
        mode => 755,
        owner => "slapd_$instancename",
        source => "puppet:///slapd-instance/init_config.sh",
        group => "openldap",
        require => File["/mnt/$instancename/shell/"]
   }

   file { "/mnt/$instancename/shell/remote_ldap_copy.sh":
        ensure => file,
        mode => 755,
        owner => "slapd_$instancename",
        source => "puppet:///slapd-instance/remote_ldap_copy.sh",
        group => "openldap",
        require => File["/mnt/$instancename/shell/"]
   }

   file { "/mnt/$instancename/shell/ldapadd.sh":
        ensure => file,
        mode => 755,
        owner => "slapd_$instancename",
        source => "puppet:///slapd-instance/ldapadd.sh",
        group => "openldap",
        require => File["/mnt/$instancename/shell/"]
   }

   file { "/mnt/$instancename/shell/ldapsearch.sh":
        ensure => file,
        mode => 755,
        owner => "slapd_$instancename",
        source => "puppet:///slapd-instance/ldapsearch.sh",
        group => "openldap",
        require => File["/mnt/$instancename/shell/"]
   }

   file { "/mnt/$instancename/shell/exploit.sh":
        ensure => file,
        mode => 755,
        owner => "slapd_$instancename",
        source => "puppet:///slapd-instance/exploit.sh",
        group => "openldap",
        require => File["/mnt/$instancename/shell/"]
   }

   file { "/mnt/$instancename/shell/clean.sh":
        ensure => file,
        mode => 755,
        owner => "slapd_$instancename",
        source => "puppet:///slapd-instance/clean.sh",
        group => "openldap",
        require => File["/mnt/$instancename/shell/"]
   }

   file { "/mnt/$instancename/shell/hotback.sh":
        ensure => file,
        mode => 755,
        owner => "slapd_$instancename",
        source => "puppet:///slapd-instance/hotback.sh",
        group => "openldap",
        require => File["/mnt/$instancename/shell/"]
   }

   exec { "init_config_$instancename":
        command => "/mnt/$instancename/shell/init_config.sh",
        creates => "/mnt/$instancename/shell/init_config.log",
        user    => "root",
        cwd     => "/mnt/$instancename/shell",
        group => "root",
        require => [ File["/mnt/$instancename/shell/init_config.sh"],
                      File["/mnt/$instancename/config/slapd.d.tar.gz"] ] 
   }
}



define slapd-instance(
	$name="default",
        $port_ldap=389,
){

	slapd-instance-install { "slapd-instance-$name":
		instancename => $name,
                ldap_port=>$port_ldap,
	}
}
