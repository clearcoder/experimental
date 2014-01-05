maintainer "Mustafa Munjid"
description "Update dns when cluster members join/leave the cluster."
version "0.1"
name "dns"

recipe "dns::base", "Contains base script."
recipe "dns::add", "Add an instance's hostname to the dns when it comes up."
recipe "dns::remove", "Remove an instance's hostname from dns when it leaves."
