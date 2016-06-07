name             'geoserver'
maintainer       'YOUR_COMPANY_NAME'
maintainer_email 'YOUR_EMAIL'
license          'All rights reserved'
description      'Installs/Configures geoserver'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.2.0'

depends "ark", "~> 1.0"
depends "java", "~> 1.0"
depends "openssl", "~> 4.0"
depends "tomcat", "~> 2.0"
