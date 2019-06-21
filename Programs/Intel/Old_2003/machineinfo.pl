 use Win32::MachineInfo;

    my $host = shift || "";
    if (Win32::MachineInfo::GetMachineInfo($host, \%info)) {
        for $key (sort keys %info) {
            print "$key=", $info{$key}, "\n";
        }
    } else {
        print "Error: $^E\n";
    }


