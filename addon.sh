mkdir /root/backup
rm /root/backup/init.d -r
mkdir /root/backup/init.d
echo
echo Bereite System vor
#psad
cpan App::cpanminus
cpan Bit::Vector
cpan Date::Calc
cpan IPTables::ChainMgr
cpan IPTables::Parse
cpan NetAddr::IP
cpan Storable
cpan Unix::Syslog
cpan Carp::Clan
cpan Digest::MD5
echo
echo instaliere psad
apt-get install -y psad

systemctl stop psad

cp /etc/init.d/psad /root/backup/init.d/

#cd ~/sources
#wget http://cipherdyne.org/psad/download/psad-2.4.1.tar.gz
tar -xzvf psad-2.4.1.tar.gz
cd psad-2.4.1
./install.pl

cp /root/backup/init.d/psad /etc/init.d/

systemctl daemon-reload
systemctl stop psad

sed -i '100s/.*/ENABLE_PSADWATCHD   					Y;/' /etc/psad/psad.conf
sed -i '116s/.*/ENABLE_PERSISTENCE   					N;/' /etc/psad/psad.conf
sed -i '169s/.*/IPT_SYSLOG_FILE   					\/var\/log\/arno-iptables-firewall;/' /etc/psad/psad.conf
sed -i '300s/.*/IMPORT_OLD_SCANS   					Y;/' /etc/psad/psad.conf
sed -i '380s/.*/ENABLE_AUTO_IDS   					Y;/' /etc/psad/psad.conf
sed -i '384s/.*/AUTO_IDS_DANGER_LEVEL   					2;/' /etc/psad/psad.conf
sed -i '400s/.*/ENABLE_AUTO_IDS_REGEX   					Y;/' /etc/psad/psad.conf
#sed -i '412s/.*/ENABLE_AUTO_IDS_EMAILS   					N;/' /etc/psad/psad.conf
sed -i '449s/.*/FLUSH_IPT_AT_INIT   					N;/' /etc/psad/psad.conf
sed -i '456s/.*/TCPWRAPPERS_BLOCK_METHOD   					Y;/' /etc/psad/psad.conf
sed -i '248s/.*/MIN_DANGER_LEVEL   					2;/' /etc/psad/psad.conf
sed -i '251s/.*/MAIL_ALERT_DANGER_LEVEL   					4;/' /etc/psad/psad.conf

iptables -A INPUT -j LOG
iptables -A FORWARD -j LOG 

systemctl start psad
psad --sig-update
psad -H

#fwsnort
apt-get install -y fwsnort
fwsnort --update-rules
fwsnort
fwsnort --no-ipt-test --verbose
/var/lib/fwsnort/fwsnort.sh
/var/lib/fwsnort/fwsnort_iptcmds.sh

cat > /etc/cron.d/psda <<END
# /etc/cron.d/psda: crontab fragment for psda and fwsnort

45 4 * * * root /usr/sbin/psad --sig-update	>/dev/null 2>&1
47 4 * * * root /usr/sbin/psad -H	>/dev/null 2>&1
10 5 * * 3 root /usr/sbin/fwsnort --update-rules >/dev/null 2>&1
15 5 * * 3 root /usr/sbin/fwsnort >/dev/null 2>&1
30 5 * * 3 root /var/lib/fwsnort/fwsnort.sh >/dev/null 2>&1

# EOF

END