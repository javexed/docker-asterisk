FROM centos:centos6
MAINTAINER Doug Smith <info@laboratoryb.org>
ENV build_date 2015-08-21

RUN yum update -y
RUN yum install -y epel-release
RUN yum install -y kernel-headers gcc gcc-c++ cpp ncurses ncurses-devel libxml2 libxml2-devel sqlite sqlite-devel openssl-devel newt-devel kernel-devel libuuid-devel net-snmp-devel xinetd tar jansson-devel

ENV AUTOBUILD_UNIXTIME 1418234402

# Download asterisk.
# Currently Certified Asterisk 13.6
RUN curl -sf -o /tmp/asterisk.tar.gz -L http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-13.6.0.tar.gz

# gunzip asterisk
RUN mkdir /tmp/asterisk
RUN tar -xzf /tmp/asterisk.tar.gz -C /tmp/asterisk --strip-components=1
WORKDIR /tmp/asterisk

# make asterisk.
ENV rebuild_date 2014-10-07
# Configure
RUN ./configure --libdir=/usr/lib64 1> /dev/null
# Remove the native build option
RUN make menuselect.makeopts
RUN sed -i "s/BUILD_NATIVE//" menuselect.makeopts
# Continue with a standard make.
RUN make 1> /dev/null
RUN make install 1> /dev/null
RUN make samples 1> /dev/null
WORKDIR /

# Update max number of open files.
RUN sed -i -e 's/# MAXFILES=/MAXFILES=/' /usr/sbin/safe_asterisk

# enable and configure ami
#RUN yum install -y epel-release
RUN yum install -y crudini
RUN crudini --set /etc/asterisk/manager.conf general enabled yes
RUN crudini --set /etc/asterisk/manager.conf general port 5038
RUN crudini --set /etc/asterisk/manager.conf general bindaddr 0.0.0.0
RUN crudini --set /etc/asterisk/manager.conf adhearsion secret adhearsion_pw
RUN crudini --set /etc/asterisk/manager.conf adhearsion read all
RUN crudini --set /etc/asterisk/manager.conf adhearsion write all
RUN crudini --set /etc/asterisk/manager.conf adhearsion eventfilter "!Event: RTCP*"
RUN crudini --set --list /etc/asterisk/manager.conf adhearsion eventfilter "!Variable: RTPAUDIOQOS*"

# Create recording folder
RUN mkdir -p /var/punchblock/record

RUN mkdir -p /etc/asterisk
# ADD modules.conf /etc/asterisk/
ADD iax.conf /etc/asterisk/
ADD sip.conf /etc/asterisk/
ADD extensions.conf /etc/asterisk/

CMD asterisk -f
