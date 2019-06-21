package intel;

use vars qw(@ORIG_INC);
use Carp;
use Config;

my $debug=0;
my $archname = $Config{'archname'};
my $prefix   = "/usr/intel/pkgs/perl-modules/$]";
my $config   = "$prefix/intel.cfg";

@ORIG_INC = @INC;	# keep a copy of previous @INC value

###
# Obtain the version number for the module in $dir given a
# user preference for $version.
###
sub get_version {
    my ($module, $version) = @_;
    my $modulename = $module;
    my (@versions, $dir);

    $module =~ s@::@/@g;
    $module = "/$module";
    print "module=$module\nversion=$version\n" if $debug;
    
    while ($module) {
	$dir = "${prefix}${module}";
	print "$dir\n" if $debug;
	
    	if (opendir(MODDIR, $dir)) {
	    @versions = readdir MODDIR;
	    closedir(MODDIR);
	    if (grep {$version eq $_} @versions) {
		return("$dir/$version");
	    }
        }
	$module = substr($module, 0, rindex($module, '/'));
    }
    
    Carp::carp("Module $modulename version $version is unavailable");    
    return('');
}

sub import {
    shift;
    my %modules = @_;
    my ($module, $directory);

    foreach $module (keys %modules) {
	print "$module\t$modules{$module}\n" if $debug;

	if ($modules{$module} ne 'current' and ($modules{$module} !~ /^[\d\.]+$/)) {
	    Carp::carp("Invalid module version number format");
	    next;
	}
	next unless ($directory = get_version($module, $modules{$module}));
        unshift(@INC, $directory);
	###
	# Put a corresponding archlib directory in front of $_ if it
	# looks like $_ has an archlib directory below it.
	###
	if (-d "$directory/$archname") {
	    unshift(@INC,"$directory/$archname")    if -d "$directory/$archname/auto";
	    unshift(@INC,"$directory/$archname/$]") if -d "$directory/$archname/$]/auto";
	}
    }
}

sub load_default_versions {
    my (%modules, $name, $version);

    open(CONFIG, $config) or Carp::carp("Couldn't read config file $config: $!");
    while (<CONFIG>) {
	next if /^#/;
	next if /^$/;
	($name, $version) = split;
	print "name=$name\tversion=$version\n" if $debug;
	$modules{$name} = $version;
    }
    close(CONFIG);
    import(1, %modules);
}

load_default_versions();

1;
__END__

=head1 NAME

intel - manipulate @INC at compile time to load module paths for specified versions

=head1 SYNOPSIS

    use intel (module => version,
	       module2 => version2,
	       ...);

=head1 DESCRIPTION

This module makes directories appropriate to the requested module versions
available for later C<use> or C<require> statements.  This task is performed
by finding the appropriate directories in the C</usr/intel/pkgs> directory
structure and adding them to @INC at compile time.  These directories are
added to the beginning of the Perl search path.  If an architecture specific
subdirectory of a module exists, it is automatically added to the search path.

Note that since the arguments are passed in a hash there is no guarantee as
to the order in which the paths to the specified modules with be added to @INC.

=head1 RESTORING ORIGINAL @INC

When the intel module is first loaded it records the current value of @INC
in an array C<@intel::ORIG_INC>.  Use the following statement to restore @INC
to that value:

    @INC = @intel::ORIG_INC;

=head1 SEE ALSO

use lib - module to add specific paths to the beginning of the search path

=head1 AUTHOR

James Walden

=cut
