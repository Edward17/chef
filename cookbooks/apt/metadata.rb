maintainer       "Tom Hughes"
maintainer_email "tom@compton.nu"
license          "Apache 2.0"
description      "Installs/Configures apt"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version          "0.1"
supports         "debian"
supports         "ubuntu"
recipe           "apt", "Installs and configures apt"