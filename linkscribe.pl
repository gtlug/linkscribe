# IRSSI URL Logger - Logs URL's posted in IRC channels 
#
#    Version .1
#
#	Originally written by Carl Blakemore, 2010
#  Taken over by gtlug Februrary 2011
#
# -- this script is little more than a hack I threw together a while ago, 
# ----  It works, but it could use with some enhancements. :)
#
# table format;
#
#+-----------+---------------+------+-----+---------+-------+
#| Field     | Type          | Null | Key | Default | Extra |
#+-----------+---------------+------+-----+---------+-------+
#| insertime | timestamp(14) | YES  |     | NULL    |       |
#| nick      | char(10)      | YES  |     | NULL    |       |
#| target    | char(255)     | YES  |     | NULL    |       |
#| line      | char(255)     | YES  |     | NULL    |       |
#+-----------+---------------+------+-----+---------+-------+
#
#  I should verify that, it has been a while since I've looked at the database.


use DBI;
use Irssi;
use Irssi::Irc;
use WWW::Mechanize;
use URI::Find::Rule;
use Data::Dumper;

use vars qw($VERSION %IRSSI);

$VERSION = "1.0";
%IRSSI = (
        authors     => "speedy, jvanb",
        contact     => "clake777\@gmail.com",
        name        => "linkscribe",
        description => "logs url's to a database",
        license     => "?",
    );

my $dsn = 'DBI:mysql:urls:<IPAddress>';
my $db_user_name = '<username>';
my $db_password = '<password>';

my $selfnick = "linkscribe"; # I know irssi probably has a way to retrieve this, but for now, I'll just do this...
my $URLLogWebSite = "http://spdy.us";

my @blocknicks = ( "wjr", "ChanServ" );
my @ignoreurls = ( "spdy.us", "pastebin.com", "svn.gtwebdev.org" );
my %forceQuietChannels = ( ); ## i.e., "wjr" => 1 }

## Intimidated Variables
my %intimidatedby = ( "wjr"=>1 );
## Next two set by functions, don't worry about them
my %intimQuietChannels = ( );
my %isIntimidated=( ); 

sub cmd_logurl {
	my ($server, $data, $nick, $mask, $target) = @_;
	($checkcmd,undef) = split(/ /, $data);
	if ($checkcmd eq "!$selfnick")  { &cmd_PublicCommand($server, $data, $nick, $target); return; }
	if ($intimidatedby{$nick} and not $isIntimidated{"$nick$target"}) { &addIntim($nick,$target); }
	my @urls = URI::Find::Rule->in($data,true);
	if (! &ignoredNick($nick) ) {
		foreach $url (@urls) {
		  if ($url and $url ne "") {
			$nopost=undef;
			if (substr($url,-1,1) eq "/") { chop($url); }
			foreach (@ignoreurls) { $ignoreurl=$_; for ($url) { if (/$ignoreurl/) { $nopost=1; } } }
			$urlstatus = &GoodURL($target, $url);
			$urlstatus =~ s/\[nick\]/$nick/g;
			if (!$nopost) {
				for ($urlstatus) {
					if (/URLEXISTS:/) {
						(undef, $urlinfo) = split(/URLEXISTS\:/,$urlstatus);
						&printOut($server, $target, "MSG $target $urlinfo");
					} elsif (/FAIL:/) {
						print "$url failed GET";
					} else {
						my $id=&db_insert($nick, $target, $server->{chatnet}, $url, $urlstatus);
						for ($id) {
							if (/FAIL:/) {
								$postmsg = (split(/FAIL\:/,$id))[1];
							} else {
								$postmsg = "MSG $target $URLLogWebSite/$id ($urlstatus) [ share: $URLLogWebSite/$id/a ]";
							}
							$cleantarget = $target;
							$cleantarget =~ s/#//g;
							&printOut($server, $target, $postmsg);
						}
					}
				}
			}
		  } #end if($url)
		} # End foreach
	}
}

sub cmd_own {
	my ($server, $data, $target) = @_;
	return cmd_logurl($server, $data, $server->{nick}, $server->{chatnet}, $target);
}

sub cmd_topic {
	my ($server, $target, $data, $nick, $mask) = @_;
	return cmd_logurl($server, $data, $nick, $server->{chatnet}, $target);
}

sub db_insert {
	my ($nick, $target, $ircserver, $line, $urltitle, $id)=@_;

	eval {
		my $dbh = DBI->connect($dsn, $db_user_name, $db_password);
		#$dbh->do("SET NAMES 'utf8'");
		#$dbh->do("SET character_set_results = 'utf8', character_set_client = 'utf8', character_set_connection = 'utf8', character_set_database = 'utf8', character_set_server = 'utf8'");
		my $sql="insert into urllog (PostTime, Nick, Server, Channel, URL, WebpageTitle) values (NOW()" . "," . $dbh->quote($nick) . "," . $dbh->quote($ircserver) . "," . $dbh->quote($target) . "," . $dbh->quote($line) . "," . $dbh->quote($urltitle) . ")";
		my $sth = $dbh->do($sql);
		$id = $dbh->last_insert_id(undef, undef, qw{urllog, URLID});
		$dbh->disconnect();
	};
	if ($@) {
		return "FAIL:error contacting database";
	}
	return $id
}

sub GoodURL {
	my ($postedto, $url) = @_;
	print $url;
	my $posted = &CheckPosted($postedto, $url);
	$returnmsg = undef;
	if ( ! $posted ) {
		my $page = &VerifyPage($url);
		if ( $page and $page !~ /NOTITLE::/ and $page ne "FAIL") {
			$returnmsg = $page;
		} elsif ($page eq "FAIL::") {
			$returnmsg = "FAIL";
		} else {
			$smallurl = undef;
			if ($page !~ /NOTITLE::/) { (undef, $url)=split(/NOTITLE::/,$page) }
			if (length($url) > 30) { $url = substr($url,0,26); $url = $url . "..."; }
			$returnmsg = "[nick] posted $url";
		}
	} else {
		$returnmsg = "URLEXISTS:$posted";
	}
	return $returnmsg;
}

sub ignoredNick {
	my ($nick) = @_;
	$ignorenick = undef;
	foreach (@blocknicks) { if ($nick eq $_) { $ignorenick = 1; } }
	return $ignorenick;
}

sub printOut {
	my ($server, $channel, $message) = @_;

	my $quiet = undef;
	if ($forceQuietChannels{$channel}) { $quiet = 1 } 
	if ($intimQuietChannels{$channel}) { $quiet = 1; } #print "too scared to talk in $channel"; } 
	#foreach (@intimquietchannels) { if ($channel eq $_) { $quiet = 1 } }
	if (!$quiet) { $server->command($message); }
}

sub CheckPosted {
	my ($postedto, $url) = @_;
	my $dbh = DBI->connect($dsn, $db_user_name, $db_password);

	my $sql = "select *, DATE_FORMAT(PostTime, '%a %b %D at %l:%i %p') as PostDateTime from urllog where URL = " . $dbh->quote($url) . " and Channel = " . $dbh->quote($postedto);
	my $sth = $dbh->prepare($sql);
	$sth->execute();
	my ($urlid, $posttime, $nick, $server, $channel, $postedurl, $WebpageTitle, $Visits);
	$sth->bind_columns( \$urlid, undef , \$nick, \$server, \$channel, \$postedurl, \$WebpageTitle, \$Visits, \$posttime );
	$row = $sth->fetch();
	if ($row) {
		if ($channel ne $postedto) { }
		## URL exists, return record info
		$channel=~s/#//g;
		$retmsg="$URLLogWebSite/$urlid (originally posted by $nick on $posttime, $Visits views.) ('$WebpageTitle') [ share: $URLLogWebSite/$urlid/a ]";
	} else {
		## URL has not been posted before, return ok to continue
		return;
	}	
	$sth->finish();
	$dbh->disconnect();
	return $retmsg;
}

sub VerifyPage {
	my ($url) = @_;
	my $mech = WWW::Mechanize->new( onerror => \&urlErrFunc, onwarn => \&urlErrFunc );
	my ($url) = @_;
	my $retmsg = "";
	$mech->agent_alias( 'Windows IE 6' );
	$mech->get($url);
	if ($mech->success()) {
		$retmsg = &getTitle(\$mech);
	} else { 
		$retmsg = "FAIL::";
	}
	return $retmsg;
}

sub getTitle {
	my ($mech) = @_;
	$$mech->get($url);
	$title = $$mech->title; 
	if ($title and $$mech->is_html) {
		return ($title);
	} else {
		$ext =~ m/\.*$/;
		if ($ext) {
			return ("NOTITLE::[".$ext."] " .$url);
		} else {
			return ("NOTITLE::[non-html] ". $url); 
		}
	}
}

sub urlErrFunc {
	#to keep Mechanize from killing the script
	return 1;
}

sub cmd_join {
	my ($server, $channel, $nick, $address) = @_;
	if ($intimidatedby{$nick}) { &addIntim($nick,$channel); } 
}

sub cmd_part {
	my ($server, $channel, $nick, $address, $reason) = @_;
	if ($isIntimidated{"$nick$channel"}) { &removeIntim($nick,$channel); }
}

sub cmd_quit {
	my ($server, $nick, $address, $reason) = @_;
	my $channel = $server->{channel};
	if ($isIntimidated{"$nick$channel"}) { &removeIntim($nick,$channel); }
}

sub addIntim {
	my ($nick,$channel) = @_;
	print "$nick has logged on, going quiet on $channel";
	$intimQuietChannels{$channel}=1; 
	$isIntimidated{"$nick$channel"}=$channel; 
}

sub removeIntim {
	my ($nick, $channel) = @_;
	print "$nick has logged off, going vocal on $channel if not intimidated by anyone else";
	$isIntimidated{"$nick$channel"}=undef;
	$intimQuietChannels{$channel}=undef;
	##Run through to see if anyone else intimidating is on...
	while (($key,$value)=each(%isIntimidated)) { $intimQuietChannels{$value}=1; }
}

sub cmd_PrivMsg {
	my ($server, $msg, $nick, $address) = @_;
	
	@words = split(/ /, $msg);
	
	for (uc($words[0])) {
		if (/TAG/) {
			if ($words[1] ne undef and $words[2] ne undef) {
				my $taglist=undef;
				for( $i = 2; $i <= $#words; $i++ ) { $taglist .= $words[$i] . " "; }
				chop($taglist);
				$server->command("MSG $nick -- tagging URL $words[1] with tag(s) $taglist.");
				$taglist =~ s/, /,/g;
				@tags = split(/\,/, $taglist);
				foreach $tag (@tags) { print "adding tag: $tag"; &addTag($server, $nick, $words[1], $tag); }
			} else {
				$server->command("MSG $nick Invalid usage, see \"HELP TAG\"");
			}
		} elsif (/SHOW/) {
			my $errmsg = "Invalid use of SHOW.  Msg \"HELP SHOW\" for more information.";
			
			if ($words[1]) {
				for (uc($words[1])) {
					if (/RECENT/) {
						if ($words[2]) {
							## Find recent 10 for channel
							$server->command("MSG $nick Retrieving list of 10 most recently added links on $words[2]");
							&returnList($server, $nick, $words[2]);
						} else {
							## List recent 10 for all
							$server->command("MSG $nick Retrieving list of 10 most recently added links");
							&returnList($server, $nick, undef);
						}
					} elsif (/INFO/) {
						&returnInfo($server, $nick, $words[2]);
					}
				}
			} else {
				$server->command("MSG $nick -- $errmsg");
			}
		} else {
			if (uc($words[0]) != "HELP") {   
				$server->command("MSG $nick -- Unrecognized Command: $words[0]");
			}
			$server->command("MSG $nick  ");
			$server->command("MSG $nick Acceptable Commands:");
			$server->command("MSG $nick    show");
			$server->command("MSG $nick       show recent <CHANNEL> (optional)");
			$server->command("MSG $nick       show info <URLID>");
			$server->command("MSG $nick  ");
			$server->command("MSG $nick    tag <URLID> <LIST_OF_TAGS_SEPARATED_BY_COMMA>");
		}
	}
}

sub returnList {
	my ($server, $nick, $channel) = @_;
	#$server->command("MSG $nick searching on channel: $channel ");
	my $dbh = DBI->connect($dsn, $db_user_name, $db_password);
	my $sql= "SELECT *, DATE_FORMAT(PostTime, '%a %b %D at %l:%i %p') as PostDateTime FROM urllog";

	if ($channel) { 
		$channel =~ s/\;//;
		$sql=$sql . " WHERE Channel=".$dbh->quote($channel); 
	}
	
	$sql = $sql . " ORDER BY URLID DESC LIMIT 10";
	#print $sql; 
	my $sth = $dbh->prepare($sql);
	$sth->execute();
	my ($urlid, $posttime, $urlnick, $urlserver, $urlchannel, $postedurl, $WebpageTitle, $Visits);
	$sth->bind_columns( \$urlid, undef, \$urlnick, \$urlserver, \$urlchannel, \$postedurl, \$WebpageTitle, \$Visits, \$posttime );
	
	while ($sth->fetch()) {
		## URL exists, return record info
		$server->send_message($nick, "$URLLogWebSite/$urlid (posted by $urlnick at $posttime, $Visits views.) ('$WebpageTitle') [ share: $URLLogWebSite/$urlid/a ]", 1);
	}
	$sth->finish();
	$dbh->disconnect();
}

sub returnInfo {
	my ($server, $nick, $requrlid) = @_;

	my $dbh = DBI->connect($dsn, $db_user_name, $db_password);
	my $sql= "SELECT *, DATE_FORMAT(PostTime, '%a %b %D at %l:%i %p') as PostDateTime FROM urllog";

	$requrlid =~ s/\;//;
	$sql=$sql . " WHERE URLID=".$dbh->quote($requrlid); 
	
	#print $sql; 
	my $sth = $dbh->prepare($sql);
	$sth->execute();
	my ($urlid, $posttime, $urlnick, $urlserver, $urlchannel, $postedurl, $WebpageTitle, $Visits);
	$sth->bind_columns( \$urlid, undef, \$urlnick, \$urlserver, \$urlchannel, \$postedurl, \$WebpageTitle, \$Visits, \$posttime );
	
	while ($sth->fetch()) {
		## URL exists, return record info
		my $tags = undef;
		my $taginfo = undef;
		$tags = &retrieveTags($urlid);
		if ($tags) { $taginfo = "[ tags: $tags ]"; }
		$server->send_message($nick, "$URLLogWebSite/$urlid (posted by $urlnick at $posttime, $Visits views.) ('$WebpageTitle') [ share: $URLLogWebSite/$urlid/a ] $taginfo", 1);
		
	}
	$sth->finish();
	$dbh->disconnect();
}

sub addTag {
	my ($server, $nick, $requrlid, $tag) = @_;

	$requrlid =~ s/;//g;
	$tag =~ s/;//g;
	my $tagid=undef;
	my $dbh = DBI->connect($dsn, $db_user_name, $db_password);
	my $sql="select * from tags where tag=".$dbh->quote($tag);
	my $sth = $dbh->prepare($sql);
	$sth->execute();
	my ($rtagid, $rtag);
	$sth->bind_columns( \$rtagid, \$rtag );
	$row = $sth->fetch();
	if ($row) {
		## URL exists, return record info
		$tagid = $rtagid;
	} else {
		$sql2="insert into tags (tag) values (". $dbh->quote($tag) .")";
		$sth2 = $dbh->do($sql2);
		$tagid = $dbh->last_insert_id(undef, undef, qw{tags, tagid});
	}
	$sth->finish();
	
	#verify not already added
	$sql="select * from urltags where urlid=$requrlid and tagid=$tagid";
	$sth=$dbh->prepare($sql);
	$sth->execute();
	$row = $sth->fetch();
	if ($row) {
		#entry already exists, don't do it again.
		#print "tag [$tag] for $requrlid already exists.";
		return;
	}
	$sth->finish();
	
	$sql="insert into urltags (urlid, tagid) values ($requrlid,$tagid)";
	$sth = $dbh->do($sql);
	#my $id = $dbh->last_insert_id(undef, undef, qw{urltags, tagid});
	$dbh->disconnect();
	return;
}

sub retrieveTags {
	my ($rurlid) = @_;
	
	$rurlid =~ s/;//g;
	
	my $dbh = DBI->connect($dsn, $db_user_name, $db_password);
	my $sql="select urltagid, urlid, tags.tagid, tags.tag from urltags JOIN tags ON urltags.tagid = tags.tagid WHERE urltags.urlid=$rurlid";
	
	my $sth = $dbh->prepare($sql);
	$sth->execute();
	
	my ($found, $tags, $separator) = undef;
	my ($urltagid, $urlid, $tagid, $tag );
	$sth->bind_columns( \$urltagid, \$urlid, \$tagid, \$tag );
	
	while ($sth->fetch()) {
		## URL exists, return record info
		$tags .= $separator . $tag;
		$separator = ", ";
	}

	$sth->finish();
	$dbh->disconnect();
	
	return $tags;
}

sub cmd_ChanJoined {
	my ($channel) = @_;
	foreach my $nick (sort {(($a->{'op'}?'1':$a->{'halfop'}?'2':$a->{'voice'}?'3':'4').lc($a->{'nick'}))
							cmp (($b->{'op'}?'1':$b->{'halfop'}?'2':$b->{'voice'}?'3':'4').lc($b->{'nick'}))} $channel->nicks()) {
		$thisnick = {'nick' => $nick->{'nick'}, 'mode' => ($nick->{'op'}?$MODE_OP:$nick->{'halfop'}?$MODE_HALFOP:$nick->{'voice'}?$MODE_VOICE:$MODE_NORMAL)};
		#calc_text($thisnick);
		#push @nicklist, $thisnick;
		$cnick = $thisnick->{'nick'};
		$cname = $channel->{'name'};
		if ($intimidatedby{$cnick} and not $isIntimidated{"$cnick$cname"}) { &addIntim($cnick,$cname); }
	}
}

sub cmd_PublicCommand {
	my ($server, $msg, $nick, $target) = @_;

	@words = split(/ /, $msg);
	
	for(uc($words[1])) {
		if (/NSFW/) {
			my $retmsg = undef;
			if ($words[2]) { 
				$retmsg = "Warning, $nick has marked url $words[2] as being NSFW!";
			
			} else {
				$retmsg = "Warning, $nick has marked the previoulsy posted URL as being NSFW!";
				my $dbh = DBI->connect($dsn, $db_user_name, $db_password);
				my $sql="select urlid, nick, WebpageTitle from urllog where Channel = ". $dbh->quote($target) . " ORDER BY URLID DESC LIMIT 1";
				
				my $sth = $dbh->prepare($sql);
				$sth->execute();
				
				my ( $urlid, $postnick, $pagetitle, $urlinfo );
				$sth->bind_columns( \$urlid, \$postnick, \$pagetitle );
				
				while ($sth->fetch()) {
					## Add tag for URL and finish response message
					&addTag($server, $target, $urlid, "NSFW");
					$urlinfo = "[ $URLLogWebSite/$urlid ($pagetitle) ]"
				}
				$sth->finish();
				$dbh->disconnect();

				$retmsg = "Warning, $nick has marked the previoulsy posted URL as being NSFW! $urlinfo";
			}
			$server->command("MSG $target $retmsg");
		}
	}
}

Irssi::signal_add_last('message public',  'cmd_logurl');
#Irssi::signal_add_last('message own_public', 'cmd_own');
Irssi::signal_add_last('message topic',   'cmd_topic');
Irssi::signal_add_last('message quit',    'cmd_quit');
Irssi::signal_add_last('message part',    'cmd_part');
Irssi::signal_add_last('message join',    'cmd_join');
Irssi::signal_add_last('message private', 'cmd_PrivMsg');
Irssi::signal_add_last('channel joined',  'cmd_ChanJoined');
Irssi::print("URL logger by speedy loaded.");

Irssi::theme_register(['url_post', '$1 %W$2%n $3-']);
