#!/usr/bin/perl

use DBI;
use Net::SNMP;
use Config::IniFiles;
use FindBin '$Bin';

# A simple trap handler
my $TRAP_FILE = "$Bin/Traplog.log";

my $host = <STDIN>;	# Read the Hostname - First line of input from STDIN
 chomp($host);
my $ip = <STDIN>;	# Read the IP - Second line of input
 chomp($ip);

while(<STDIN>) {
        chomp($_);
        push(@vars,$_);
}

open(TRAPFILE, ">> $TRAP_FILE");
$date = `date`;
chomp($date);
print(TRAPFILE "New trap received: $date for \nHOST: $host\nIP: $ip\n");

foreach(@vars) 
{
        #print(TRAPFILE "TRAP: $_\n");
	@var=split(/\ /,$_);
	if("$var[0]" eq "iso.3.6.1.4.1.41717.10.1")
	{
	 $IP=$var[1];
	 $IP=~s/"//g;
	}
	if("$var[0]" eq "iso.3.6.1.4.1.41717.10.2") 
	{
	 if($var[1]==0)
	 {
	  $status = "OK";
	 }
	 if($var[1]==1)
	 {
	  $status = "PROBLEM";
	 }
	 if($var[1]==2)
	 {	
	  $status = "DANGER";
	 }
	 if($var[1]==3)
	 {	
	  $status = "FAIL";
	 }
	}
}

#Create a MySQL Database to store the values
my $cfg = Config::IniFiles->new( -file => "$Bin/../db.conf");

my $driver= "mysql";
my $ip_data= $cfg->val( 'ip_data', 'IP');
#print "Value: $cfg\n";
#print (TRAPFILE "DONE FILING: $cfg\n");
my $database= $cfg->val( 'Database', 'DBname');
my $port = $cfg->val( 'ip_data', 'Port');
my $dsn= "DBI:$driver:database=$database;host=$ip_data;port=$port";
#my $directory=$cfg->val('ip_data', 'ServerDirectory');
my $userid= $cfg->val('Database', 'Username');
my $password= $cfg->val('Database', 'Password');

$dbh=DBI->connect($dsn, $userid, $password) or die $DBI::errstr;

#Create a Table to store the values of the input given from the terminal
$sth = $dbh->prepare("CREATE TABLE IF NOT EXISTS `Trapo`( `id` int(11) NOT NULL AUTO_INCREMENT, `STATUS` tinytext NOT NULL, `Message` tinytext NOT NULL, `TIME` tinytext NOT NULL, `prev_status` tinytext NOT NULL, `prev_time` tinytext NOT NULL, PRIMARY KEY (`id`) )ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1");
$sth->execute();

$time=time;
print (TRAPFILE "DONE FILING: $IP, $status\n");
print(TRAPFILE "\n----------\n");
#close(TRAPFILE);

if($IP && $status)
{
$sth=$dbh->prepare("select `STATUS`,`TIME` from `Trapo` where Message='$IP'");
$sth->execute();
	if($sth->rows>0)
	{

		while($stat=$sth->fetchrow_hashref())
		{
			$prevstat=$stat->{'STATUS'};
			$prevtime=$stat->{'TIME'};
			$sth=$dbh->prepare("UPDATE `Trapo` SET `prev_status`='$prevstat',`prev_time`='$prevtime' where `Message`='$IP'");
			$sth->execute();
		}

		$sth=$dbh->prepare("UPDATE `Trapo` SET `STATUS`='$status', `TIME`='$time' where `Message`='$IP'");
		$sth->execute();
	}

	else
	{
		$sth=$dbh->prepare("INSERT into `Trapo` (Message,STATUS,TIME) VALUES ('$IP','$status','$time')");
		$sth->execute();
	}

}


if("$status" eq "FAIL")
{
	$sth=$dbh->prepare("SELECT * from `Trapo` where `Message`='$IP'");
	$sth->execute(); 
	while($fail=$sth->fetchrow_hashref())
	{
		$revtime=$fail->{'TIME'};
		$prevst=$fail->{'prev_status'};
		$prevtim=$fail->{'prev_time'};	
	}
	$sth=$dbh->prepare("Select * from `Fail`");
	$sth->execute();

	while(@abt=$sth->fetchrow_array())
	{
		$i=$abt[1];
		$p=$abt[2];
		$c=$abt[3];
	}

	$host="$i:$p";
	$community="$c";
	my($session,$error)=Net::SNMP->session(
						-hostname=>$host,
						-community=>$community,	
						-version=>1,
						);

	$trapoid= '1.3.6.1.4.1.41717.20.1';
	@trapoids=($trapoid,OCTET_STRING,$IP);
	push(@trapoids,"1.3.6.1.4.1.41717.20.2",UNSIGNED32,$revtime);

	unless($prevst==' ' && $prevtim==' '){
	if($prevst eq "OK")
	 {
	  $prevstatus = 0;
	 }
	if($prevst eq "PROBLEM")
	 {
	  $prevstatus = 1;
	 }
	if($prevst eq "DANGER")
	 {
	  $prevstatus = 2;
	 }
	if($prevst eq "FAIL")
	 {
	  $prevstatus = 3;
	 }
	push(@trapoids,"1.3.6.1.4.1.41717.20.3",INTEGER,$prevstatus);
	push(@trapoids,"1.3.6.1.4.1.41717.20.4",UNSIGNED32,$prevtim);
	}
	my $result= $session->trap(-varbindlist=>\@trapoids);
}


if("$status" eq "DANGER")
{
 
	$sth= $dbh->prepare("SELECT * FROM `Fail`");
	$sth->execute();
	while(@abt=$sth->fetchrow_array())
	{
		$i=$abt[1];
		$p=$abt[2];
		$c=$abt[3];
	}
	
	$host="$i:$p";
	$community="$c";
	my($session,$error)=Net::SNMP->session(
					-hostname=>$host,
					-community=>$community,	
					-version=>1,
					);

	$sth=$dbh->prepare("SELECT * FROM `Trapo` where `STATUS`='DANGER'");
	$sth->execute;
	$t=1;
	$numrows = $sth->rows;
	if($numrows > 1){
	while($axt=$sth->fetchrow_hashref())
	{
		$fqdn=$axt->{'Message'};
		$rtime=$axt->{'TIME'};
		$prevst=$axt->{'prev_status'};
		$prevtim=$axt->{'prev_time'};	

		$trapoid = "1.3.6.1.4.1.41717.30.$t";

		push(@trapoids,$trapoid,OCTET_STRING,$fqdn);
		push(@trapoids,"1.3.6.1.4.1.41717.30.".++$t,UNSIGNED32,$rtime);

		unless($prevst==' ' && $prevtim==' '){
		if($prevst eq 'OK'){
	  	$prevstatus = 0;
	 	}
		if($prevst eq 'PROBLEM'){
	  	$prevstatus= 1;
	 	}	
		if($prevst eq 'DANGER'){
	  	$prevstatus = 2;
	 	}
		if($prevst eq 'FAIL'){
	  	$prevstatus = 3;
	 	}
		push(@trapoids,"1.3.6.1.4.1.41717.30.".++$t,INTEGER,$prevstatus);
		push(@trapoids,"1.3.6.1.4.1.41717.30.".++$t,UNSIGNED32,$prevtim);
		}
		
		if($prevst==' ' && $prevtim==' '){
			$t+=2;
		}
		$t++;

	}
	

	my $result = $session->trap(-varbindlist  => \@trapoids);
	$session->close();
	}
}

