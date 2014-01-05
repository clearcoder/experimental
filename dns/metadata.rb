maintainer "Mustafa Munjid"
description "Update dns when cluster members."
version "0.1"
name "dns"

recipe "dns::default", "Default recipe"
recipe "dns::add_instance", "Add an instance's hostname to the dns when it comes up."
recipe "dns::remove_instances", "Remove an instance's hostname from dns when it leaves."
