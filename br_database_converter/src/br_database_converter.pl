#!/usr/bin/perl -w
#
# Converts an SQLite2 BRenBot database to SQLite3. Includes all necessary code to update
# and convert databases
#


use DBI;
use File::Copy;


my $oldDb;
my $newDb;

# Check for presence of old database file, and move it to a backup folder
if ( -e "brenbot.dat" )
{
	print "\n\nBeginning database conversion to SQLite3\n\n\n";

	# Move to backup folder
	mkdir "backup";
	copy ( "brenbot.dat", "backup/brenbot.dat" );
	unlink ( "brenbot.dat" );

	# Open old database
	$oldDb = DBI->connect("dbi:SQLite2:dbname=backup/brenbot.dat","","");

	# Run functions from brenbot 1.52 to fully update the old database to 1.52 spec
	check_tables();
	check_database();


	# Now create new database
	$newDb = DBI->connect( "dbi:SQLite:dbname=brenbot.dat", "", "" );


	# Create tables for new DB
	execute_query_newDB ( "CREATE TABLE IF NOT EXISTS globals ( name TEXT PRIMARY KEY, value TEXT )", 1 );
	execute_query_newDB ( "CREATE TABLE IF NOT EXISTS kicks ( id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, ip TEXT, serial TEXT, kicker TEXT, reason TEXT, timestamp INTEGER )", 1 );
	execute_query_newDB ( "CREATE TABLE IF NOT EXISTS bans ( id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, ip TEXT, serial TEXT, banner TEXT, reason TEXT, timestamp INTEGER )", 1 );
	execute_query_newDB ( "CREATE TABLE IF NOT EXISTS logs ( id INTEGER PRIMARY KEY AUTOINCREMENT, logCode INTEGER, log TEXT, timestamp INTEGER )", 1 );
	execute_query_newDB ( "CREATE TABLE IF NOT EXISTS modules ( name TEXT PRIMARY KEY, description TEXT, status INTEGER, locked INTEGER DEFAULT 0 )", 1 );
	execute_query_newDB ( "CREATE TABLE IF NOT EXISTS auth_users ( id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE, password TEXT )", 1 );
	#execute_query_newDB ( "CREATE TABLE IF NOT EXISTS auth_user_aliases ( user_id INTEGER REFERENCES auth_users( user_id ) ON DELETE CASCADE, alias TEXT UNIQUE )", 1 );
	execute_query_newDB ( "CREATE TABLE IF NOT EXISTS recommendations ( name TEXT PRIMARY KEY, recommendations INTEGER DEFAULT 0, n00bs INTEGER DEFAULT 0  )", 1 );
	execute_query_newDB ( "CREATE TABLE IF NOT EXISTS recommendations_ignored_users ( name TEXT PRIMARY KEY )", 1 );
	execute_query_newDB ( "CREATE TABLE IF NOT EXISTS join_messages ( name TEXT PRIMARY KEY, message TEXT )", 1 );


	# After conversion the database version will be 1.53.4
	execute_query_newDB ( "INSERT INTO globals ( name, value ) VALUES ( 'version', '1.53' )", 1 );
	execute_query_newDB ( "INSERT INTO globals ( name, value ) VALUES ( 'build', '4' )", 1 );


	# Copy globals table
	print "Converting globals...\n";
	my @oldDbRecords = execute_query ( "SELECT name, value FROM globals WHERE name <> 'version' AND name <> 'build'" );
	my $processedRecords = 0;
	my $totalRecords = scalar(@oldDbRecords);
	foreach ( @oldDbRecords )
	{
		print "\t$processedRecords/$totalRecords\r";

		# Replace any ' in fields with '' (SQLite escape style)
		$_->{'name'} =~ s/'/''/g;
		$_->{'value'} =~ s/'/''/g;

		# Insert the ban into the new table
		execute_query_newDB ( "INSERT INTO globals ( name, value ) VALUES ( '".$_->{'name'}."', '".$_->{'value'}."' )", 1 );

		$processedRecords++;
	}
	print "\tDone\t\t\t\n";


	# Copy bans table
	print "Converting bans...\n";
	@oldDbRecords = execute_query ( "SELECT * FROM bans" );
	$processedRecords = 0;
	$totalRecords = scalar(@oldDbRecords);
	foreach ( @oldDbRecords )
	{
		print "\t$processedRecords/$totalRecords\r";

		# Replace any ' in fields with '' (SQLite escape style)
		$_->{'name'} =~ s/'/''/g;
		$_->{'banner'} =~ s/'/''/g;
		$_->{'reason'} =~ s/'/''/g;

		# Insert the ban into the new table
		execute_query_newDB ( "INSERT INTO bans ( name, ip, serial, banner, reason, timestamp ) VALUES ( '".$_->{'name'}."', '".$_->{'ip'}."', '".$_->{'serial'}."', '".$_->{'banner'}."', '".$_->{'reason'}."', ".$_->{'timestamp'}." )", 1 );

		$processedRecords++;
	}
	print "\tDone\t\t\t\n";


	# Copy logs table
	print "Converting logs...\n";
	@oldDbRecords = execute_query ( "SELECT * FROM logs" );
	$processedRecords = 0;
	$totalRecords = scalar(@oldDbRecords);
	foreach ( @oldDbRecords )
	{
		print "\t$processedRecords/$totalRecords\r";

		# Replace any ' in fields with '' (SQLite escape style)
		$_->{'content'} =~ s/'/''/g;

		# Swap log codes for kicks and bans
		# logtype 1 = kick (old) = ban (new)
		# logtype 2 = ban (old) = kick (new)
		if ( $_->{'logtype'} == 1 )			{ $_->{'logtype'} = 2; }
		elsif ( $_->{'logtype'} == 2 )		{ $_->{'logtype'} = 1; }

		# Insert the log into the new table
		execute_query_newDB ( "INSERT INTO logs ( logCode, log, timestamp ) VALUES ( ".$_->{'logtype'}.", '".$_->{'content'}."', ".$_->{'timestamp'}." )", 1 );

		$processedRecords++;
	}
	print "\tDone\t\t\t\n";


	# Copy modules table
	print "Converting modules...\n";
	@oldDbRecords = execute_query ( "SELECT * FROM modules" );
	$processedRecords = 0;
	$totalRecords = scalar(@oldDbRecords);
	foreach ( @oldDbRecords )
	{
		print "\t$processedRecords/$totalRecords\r";

		# Replace any ' in fields with '' (SQLite escape style)
		$_->{'name'} =~ s/'/''/g;
		$_->{'description'} =~ s/'/''/g;

		# Insert the user into the new table
		execute_query_newDB ( "INSERT INTO modules ( name, description, status, locked ) VALUES ( '".$_->{'name'}."', '".$_->{'description'}."', ".$_->{'status'}.", ".$_->{'locked'}." )", 1 );

		$processedRecords++;
	}
	print "\tDone\t\t\t\n";


	# Copy users table to auth_users
	print "Converting users...\n";
	@oldDbRecords = execute_query ( "SELECT * FROM users" );
	$processedRecords = 0;
	$totalRecords = scalar(@oldDbRecords);
	foreach ( @oldDbRecords )
	{
		print "\t$processedRecords/$totalRecords\r";

		# Replace any ' in fields with '' (SQLite escape style)
		$_->{'name'} =~ s/'/''/g;

		# Insert the user into the new table
		execute_query_newDB ( "INSERT INTO auth_users ( name, password ) VALUES ( '".$_->{'name'}."', '".$_->{'password'}."' )", 1 );

		$processedRecords++;
	}
	print "\tDone\t\t\t\n";


	# Copy recommendations
	print "Converting recommendations...\n";
	@oldDbRecords = execute_query ( "SELECT LOWER(name) AS name, COUNT(*) AS recommendations FROM recommendation GROUP BY LOWER(name)" );
	$processedRecords = 0;
	$totalRecords = scalar(@oldDbRecords);
	foreach ( @oldDbRecords )
	{
		print "\t$processedRecords/$totalRecords\r";

		# Replace any ' in fields with '' (SQLite escape style)
		$_->{'name'} =~ s/'/''/g;

		# Insert the recommendations into the new table
		execute_query_newDB ( "INSERT INTO recommendations ( name, recommendations ) VALUES ( '".$_->{'name'}."', ".$_->{'recommendations'}." )", 1 );

		$processedRecords++;
	}
	print "\tDone\t\t\t\n";


	# Copy n00bs
	print "Converting n00bs...\n";
	@oldDbRecords = execute_query ( "SELECT LOWER(name) AS name, COUNT(*) AS n00bs FROM n00bs GROUP BY LOWER(name)" );
	$processedRecords = 0;
	$totalRecords = scalar(@oldDbRecords);
	foreach ( @oldDbRecords )
	{
		print "\t$processedRecords/$totalRecords\r";

		# Replace any ' in fields with '' (SQLite escape style)
		$_->{'name'} =~ s/'/''/g;

		# Does a record exist for this user?
		my @recData = execute_query_newDB ( "SELECT * FROM recommendations WHERE LOWER(name) = '".$_->{'name'}."'" );
		if ( scalar(@recData) > 0 )
			# Record exists, update it
			{ execute_query_newDB ( "UPDATE recommendations SET n00bs = ".$_->{'n00bs'}." WHERE LOWER(name) = '".$_->{'name'}."'", 1 ); }
		else
			# Record does not exist, insert as new record
			{ execute_query_newDB ( "INSERT INTO recommendations ( name, n00bs ) VALUES ( '".$_->{'name'}."', ".$_->{'n00bs'}." )", 1 ); }

		$processedRecords++;
	}
	print "\tDone\t\t\t\n";


	# Copy rec_ignore table to recommendations_ignored_users
	print "Converting recommendation ignored users...\n";
	@oldDbRecords = execute_query ( "SELECT * FROM rec_ignore" );
	$processedRecords = 0;
	$totalRecords = scalar(@oldDbRecords);
	foreach ( @oldDbRecords )
	{
		print "\t$processedRecords/$totalRecords\r";

		# Replace any ' in fields with '' (SQLite escape style)
		$_->{'name'} =~ s/'/''/g;

		# Insert the user into the new table
		execute_query_newDB ( "INSERT INTO recommendations_ignored_users ( name ) VALUES ( '".$_->{'name'}."' )", 1 );

		$processedRecords++;
	}
	print "\tDone\t\t\t\n";


	# Copy jointext table to join_messages
	print "Converting join messages...\n";
	@oldDbRecords = execute_query ( "SELECT * FROM jointext" );
	$processedRecords = 0;
	$totalRecords = scalar(@oldDbRecords);
	foreach ( @oldDbRecords )
	{
		print "\t$processedRecords/$totalRecords\r";

		# Replace any ' in fields with '' (SQLite escape style)
		$_->{'name'} =~ s/'/''/g;
		$_->{'text'} =~ s/'/''/g;

		# Insert the user into the new table
		execute_query_newDB ( "INSERT INTO join_messages ( name, message ) VALUES ( '".$_->{'name'}."', '".$_->{'text'}."' )", 1 );

		$processedRecords++;
	}
	print "\tDone\t\t\t\n";



	# DONE!
	print "\n\nDatabase conversion complete\n\n\n";
}

















####################################
# Functions copied from brenbot 1.52 that are useful
# when using databases in perl
####################################

# Runs a database query on the old database
sub execute_query
{
	$| = 1;
	my $sth;
	my $query = shift;
	my $flag = shift;

	#print "DEBUG: $query\n";
	$sth = $oldDb->prepare ( "$query" );
	$sth -> execute;

	# If the flag is undef or 0 return the result of the query
	if (!$flag)
	{
		my $attrib_nr = 0;
		my @array_of_hash_refs;
		my @new_array;
		my $db_line;

	    while ($db_line = $sth->fetchrow_hashref())
	    {
	    	$array_of_hash_refs[$attrib_nr] = $db_line;
			$attrib_nr++;
		}
		undef $attrib_nr;

		foreach (@array_of_hash_refs)
		{
			my %hash = %$_;
			my %hash_lc;
			while ((my $k, my $v) = each %hash)
			{
				 $k = lc($k);
				 $hash_lc{$k} = $v;
			}
			push (@new_array,\%hash_lc);
		}

		# Clear the hash refs array by setting its length to -1
		$#array_of_hash_refs = -1;

		return (@new_array);
	}
}

# Runs a database query on the new database
sub execute_query_newDB
{
	$| = 1;
	my $sth;
	my $query = shift;
	my $flag = shift;

	#print "DEBUG: $query\n";
	$sth = $newDb->prepare ( "$query" );
	$sth -> execute;

	# If the flag is undef or 0 return the result of the query
	if (!$flag)
	{
		my $attrib_nr = 0;
		my @array_of_hash_refs;
		my @new_array;
		my $db_line;

	    while ($db_line = $sth->fetchrow_hashref())
	    {
	    	$array_of_hash_refs[$attrib_nr] = $db_line;
			$attrib_nr++;
		}
		undef $attrib_nr;

		foreach (@array_of_hash_refs)
		{
			my %hash = %$_;
			my %hash_lc;
			while ((my $k, my $v) = each %hash)
			{
				 $k = lc($k);
				 $hash_lc{$k} = $v;
			}
			push (@new_array,\%hash_lc);
		}

		# Clear the hash refs array by setting its length to -1
		$#array_of_hash_refs = -1;

		return (@new_array);
	}
}


# Sets a global variable, useful for storing information which does
# not fit in any other tables but must not be lost at shutdown
#
# PARAM		String		Global Name
# PARAM		String		Global Value
sub set_global
{
	my $name = shift;
	my $value = shift;

	if ( defined ( get_global ( $name ) ) )
	{
		execute_query ( "UPDATE globals SET value='$value' WHERE name='$name'", 1 );
	}
	else
	{
		execute_query ( "INSERT INTO globals ( name, value ) VALUES ( '$name', '$value' )", 1 );
	}
	return undef;
}



# Retrieves a stored global variable from the database
#
# PARAM		String		Global Name
#
# RETURN ( $value )
# undef - Not found
# db value - Found
sub get_global
{
	my $name = shift;

	my @result = execute_query ( "SELECT value FROM globals WHERE name = '$name'" );

	if ( @result )
	{
		return ( $result[0]->{value} );
	}
	return undef;
}







####################################
# Functions copied from brenbot 1.52 to update old database
# to the 1.52.1 state before conversion
####################################

# Checks that all required tables are present in the database
sub check_tables
{
	my %required_tables =
	(
		jointext => "CREATE TABLE jointext ( id INTEGER PRIMARY KEY, name TEXT, text TEXT ) ",
		recommendation => "CREATE TABLE recommendation ( id INTEGER PRIMARY KEY, name TEXT, comment TEXT, poster TEXT, timestamp DATETIME ) ",
		n00bs => "CREATE TABLE n00bs ( id INTEGER PRIMARY KEY, name TEXT, comment TEXT, poster TEXT, timestamp DATETIME ) ",
		bans => "CREATE TABLE bans ( id INTEGER PRIMARY KEY, name TEXT, ip TEXT, serial TEXT, reason TEXT, banner TEXT, timestamp INTEGER ) ",
		users_aliases => "CREATE TABLE users_aliases ( id INTEGER PRIMARY KEY, name TEXT, userid INTEGER )",
		users => "CREATE TABLE users ( id INTEGER PRIMARY KEY, name TEXT, password TEXT )",
		modules => "CREATE TABLE modules ( id INTEGER PRIMARY KEY, name TEXT, description TEXT, status INTEGER, locked INTEGER );",
		rec_ignore => "CREATE TABLE rec_ignore ( id INTEGER PRIMARY KEY, name TEXT );",
		globals => "CREATE TABLE globals ( id INTEGER PRIMARY KEY, name TEXT, value TEXT );",
		forcerg => "CREATE TABLE forcerg ( id INTEGER PRIMARY KEY, name TEXT, ip TEXT );",
		rg_stats => "CREATE TABLE rg_stats ( day CHAR(6) PRIMARY KEY, rg_count INT, non_rg_count INT );",
		logs => "CREATE TABLE logs ( id INTEGER PRIMARY KEY, logType INTEGER, content TEXT, timestamp INTEGER );",
		kicks => "CREATE TABLE kicks ( id INTEGER PRIMARY KEY, name TEXT, ip TEXT, serial TEXT, time INTEGER, kicker TEXT, reason TEXT );"
	);

	my @array = execute_query("select name from sqlite_master");
	while ((my $k, my $v) = each %required_tables)
	{
		my $found=0;
		foreach (@array)
		{
			if ($_->{'name'} eq $k)
			{
				$found=1;
			}
		}
		if ($found == 0)
		{
			execute_query("$v",1);
		}

		delete $required_tables{$k};
	} # end of while
}





# Gets the current database version, checks it against the program version
# and runs any nessicary updates.
sub check_database
{
	my $dbVersion;
	my $dbBuild;

	my @getVersion = execute_query ( "SELECT * FROM globals WHERE name = 'version' OR name = 'build'" );

	foreach ( @getVersion )
 	{
 		my %hash = %{$_};
 		if ( $hash{name} eq 'version' )
 			{ $dbVersion = $hash{value} }
 		elsif ( $hash{name} eq 'build' )
 			{ $dbBuild = $hash{value} }
 	}

 	if ( !$dbVersion )
 	{
	 	# If we are missing the version number assume we are updating from
	 	# 1.43, build 17 or earlier
	 	$dbVersion = 1.43;
	 	$dbBuild = 17;
 	}

 	if ( $dbVersion != '1.52' || $dbBuild != '1' )
 	{
	 	print "\nDatabase is out of date, updating to latest version...\n";
	 	# Something is out of date, see which updates need doing...

	 	if ( $dbVersion <= 1.43 )
	 	{
		 	print "  Running updates for BRenBot version 1.43...\n";
		 	# Updates for 1.43 and lower
		 	if ( $dbBuild <= 17 )
		 	{
			 	# Updates for build 17 and lower
			 	print "    Doing updates for build 18...\n";
			 	print "      Deleting redundant table version...\n";
			 	execute_query ( "DROP TABLE version", 1 );
			 	print "      Deleting redundant modules teams and seen...\n";
			 	execute_query ( "DELETE FROM modules WHERE name = 'seen' OR name = 'teams'", 1 );
		 	}
		 	if ( $dbBuild <= 18 )
		 	{
			 	# Updates for build 18 and lower
			 	print "    Doing updates for build 19...\n";
			 	print "      Updating several module descriptions...\n";
			 	execute_query ( "UPDATE modules SET description='Displays team (f3) chat messages in IRC' WHERE name='teammessages'", 1 );
			 	execute_query ( "UPDATE modules SET description='Enables automatic recommendations after each map' WHERE name='gameresults'", 1 );
			 	execute_query ( "UPDATE modules SET description='Displays vehicle purchases in IRC' WHERE name='vehicle_purchase'", 1 );
			 	execute_query ( "UPDATE modules SET description='!gi shows info on one line instead of five lines' WHERE name='new_gi'", 1 );
			 	execute_query ( "UPDATE modules SET description='Allows players to donate money to their teammates (bhs only)' WHERE name='donate'", 1 );
			 	execute_query ( "UPDATE modules SET description='Support for ssgm logging (Beacon, Game Results, BW alerts etc)' WHERE name='ssgmlog'", 1 );
		 	}
		 	if ( $dbBuild <= 19 )
		 	{
			 	# Updates for build 19 and lower
			 	print "    Doing updates for build 20...\n";
			 	print "      Flushing bad data from the globals table...\n";
			 	execute_query ( "DELETE FROM globals", 1 );
			 	print "      Deleting redundant table seen...\n";
			 	execute_query ( "DROP TABLE seen", 1 );
			 	print "      Deleting redundant table joinlist...\n";
			 	execute_query ( "DROP TABLE joinlist", 1 );
			 	print "      Rebuilding rg_stats table...\n";
			 	execute_query ( "DROP TABLE rg_stats", 1 );
			 	execute_query ( "CREATE TABLE rg_stats ( day CHAR(6) PRIMARY KEY, rg_count INT, non_rg_count INT )", 1 );
			}
			if ( $dbBuild <= 20 )
		 	{
			 	# Updates for build 20 and lower
			 	print "    Doing updates for build 21...\n";
			 	print "      Deleting redundant tables gamelist and playerlist...\n";
			 	execute_query ( "DROP TABLE gamelist", 1 );
			 	execute_query ( "DROP TABLE playerlist", 1 );
			 	print "      Deleting redundant module htmloutput...\n";
			 	execute_query ( "DELETE FROM modules WHERE name = 'htmloutput'", 1 );
			}
			if ( $dbBuild <= 23 )
		 	{
			 	# Updates for build 23 and lower
			 	print "    Doing updates for build 24...\n";
			 	print "      Deleting redundant modules vehicle_purchase and killmsg...\n";
			 	execute_query ( "DELETE FROM modules WHERE name = 'vehicle_purchase' OR name = 'killmsg' OR name = 'cratemsg' OR name = 'renguard'", 1 );
			}
			if ( $dbBuild <= 24 )
		 	{
			 	# Updates for build 24 and lower
			 	print "    Doing updates for build 25...\n";
			 	print "      Moving logs to logs table... this may take a few minutes...\n";

			 	# For each ban make a record in the logs table
			 	my @bansArray = execute_query ( "SELECT * FROM banlist ORDER BY id ASC", 0 );
			 	foreach ( @bansArray )
			 	{
				 	my $timestamp = $_->{'timestamp'};
				 	$timestamp =~ s/\.\d+//i;		# Trim any decimals off the timestamp
				 	execute_query ( "INSERT INTO logs ( logType, content, timestamp ) VALUES ( 2, \"[BAN] $_->{name} was banned by $_->{banner} for '$_->{comment}'. (Ban ID $_->{id})\", $timestamp )", 1 );
			 	}

			 	# Read in kick logs from kicklog.brf
			 	open ( KICKLOGOLD, "<kicklog.brf" );
			 	use Time::Local;

			 	while ( <KICKLOGOLD> )
			 	{
				 	# Strip end of line and any spaces in VOTEKICK ->
				 	$_ =~ s/\n//i;			 	$_ =~ s/VOTEKICK\s->/VOTEKICK->/i;		$_ =~ s/"/'/;
				 	if ( $_ =~ m/^(\d+)\/(\d+)\/(\d+)-(\d+):(\d+):\d+\s(.+)\s(QKICK->|VOTEKICK->|->)\s(.+)@.+\s:\s(.+)?$/i )
				 	{
					 	my $kickDesc;
					 	my $kickComment;
					 	my $kickType = $7;

					 	if ( $kickType eq "->" )
					 	{
						 	$kickType = "KICK";			 	$kickDesc = "kicked";			$kickComment = $9;
					 	}
					 	elsif ( $kickType eq "QKICK->" )
					 	{
						 	$kickType = "QKICK";		 	$kickDesc = "q-kicked";			$kickComment = $9;
					 	}
					 	elsif ( $kickType eq "VOTEKICK->" )
					 	{
						 	$kickType = "VOTEKICK";		 	$kickDesc = "vote kicked";		$kickComment = "N/A";
					 	}

					 	my $timestamp = timelocal( 0, $5, $4, $2, ($1 -1), $3 );

					 	execute_query ( "INSERT INTO logs ( logType, content, timestamp ) VALUES ( 1, \"[$kickType] $8 was $kickDesc by $6 for '$kickComment'.\", $timestamp )", 1 );
				 	}
			 	}

			 	close ( KICKLOGOLD );
			}
	 	}
	 	if ( $dbVersion <= 1.51 )
	 	{
		 	print "  Running updates for BRenBot version 1.51...\n";
		 	# Updates for 1.51 and lower
		 	if ( $dbVersion < 1.51 )
		 	{
			 	print "    Doing updates for build 1...\n";
			 	print "      Renaming module ssaowlog to ssgmlog...\n";
			 	execute_query ( "DELETE FROM modules WHERE name='ssaowlog'", 1 );
		 	}
		 	if ( $dbBuild <= 3 || $dbVersion < 1.51 )
			{
				print "    Doing updates for build 4...\n";
				print "      Replacing module minelimit with map_settings...\n";
				execute_query ( "DELETE FROM modules WHERE name='minelimit'", 1 );
				print "      Renaming module usermessages to join_messages...\n";
				execute_query ( "DELETE FROM modules WHERE name='usermessages'", 1 );

				# Encrypt all user passwords with MD5 encryption
				use Digest::MD5 qw(md5 md5_hex md5_base64);
				print "      Protecting user passwords with MD5 encryption...\n";
				my @pwArray = execute_query ( "SELECT * FROM users", 0 );
			 	foreach ( @pwArray )
			 	{
				 	my $pw = md5_hex($_->{'password'});
				 	my $name = $_->{'name'};
				 	execute_query ( "UPDATE users SET password = '$pw' WHERE name = '$name'" );
			 	}
			}
			if ( $dbBuild <= 15 || $dbVersion < 1.51 )
			{
				print "    Doing updates for build 16...\n";
				print "      Replacing banlist, ip_bans and rg_bans tables with bans table...  this may take a few minutes...\n";

				my @bansArray = execute_query( "SELECT * FROM banlist" );
				foreach ( @bansArray )
				{
					# See if we can get a serial and / or ip that matches this ban record
					my @banSerialArray = execute_query ( "SELECT serial FROM rg_ban WHERE LOWER(name) = '".lc($_->{'name'})."'" );
					my @banIPArray = execute_query ( "SELECT ip FROM ip_ban WHERE LOWER(name) = '".lc($_->{'name'})."'" );

					my $banSerial = ( scalar(@banSerialArray) > 0 ) ? $banSerialArray[0]->{'serial'} : '';
					my $banIP = ( scalar(@banIPArray) > 0 ) ? $banIPArray[0]->{'ip'} : '';

					# Replace any ' in player names with '' (SQLite escape style)
					$_->{'name'} =~ s/'/''/g;

					# Insert the ban into the new table
					execute_query ( "INSERT INTO bans ( name, ip, serial, banner, reason, timestamp ) VALUES ( '".$_->{'name'}."', '$banIP', '$banSerial', '".$_->{'banner'}."', '".$_->{'comment'}."', '".$_->{'timestamp'}."' )", 1 );
				}

				execute_query ( "DROP TABLE banlist" );
				execute_query ( "DROP TABLE ip_ban" );
				execute_query ( "DROP TABLE rg_ban" );
			}
	 	}

	 	# Finally set all the globals to the current version
	 	set_global ( 'version', '1.52' );
	 	set_global ( 'build', '1' );
 	}
}