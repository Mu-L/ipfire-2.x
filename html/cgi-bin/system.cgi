#!/usr/bin/perl
###############################################################################
#                                                                             #
# IPFire.org - A linux based firewall                                         #
# Copyright (C) 2005-2010  IPFire Team                                        #
#                                                                             #
# This program is free software: you can redistribute it and/or modify        #
# it under the terms of the GNU General Public License as published by        #
# the Free Software Foundation, either version 3 of the License, or           #
# (at your option) any later version.                                         #
#                                                                             #
# This program is distributed in the hope that it will be useful,             #
# but WITHOUT ANY WARRANTY; without even the implied warranty of              #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the               #
# GNU General Public License for more details.                                #
#                                                                             #
# You should have received a copy of the GNU General Public License           #
# along with this program.  If not, see <http://www.gnu.org/licenses/>.       #
#                                                                             #
###############################################################################

use strict;

# enable only the following on debugging purpose
#use warnings;
#use CGI::Carp 'fatalsToBrowser';

require '/var/ipfire/general-functions.pl';
require "${General::swroot}/header.pl";

my %mainsettings = ();
&General::readhash("${General::swroot}/main/settings", \%mainsettings);

&Header::showhttpheaders();

&Header::openpage($Lang::tr{'status information'}, 1, '');

# Processor Graph
&Header::graph("$Lang::tr{'processors'}", "system.cgi", "cpu", "day");

# CPU Frequency
if ( -e "$mainsettings{'RRDLOG'}/collectd/localhost/cpufreq-0/cpufreq.rrd"){
	&Header::graph("$Lang::tr{'cpu frequency'}", "system.cgi", "cpufreq", "day");
}

# Load Average
&Header::graph("$Lang::tr{'load average'}", "system.cgi", "load", "day");

&Header::closepage();
