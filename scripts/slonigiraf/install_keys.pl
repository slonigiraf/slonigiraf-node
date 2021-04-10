use strict;
use warnings FATAL => 'all';

my $project_dir = $ARGV[0];
$project_dir =~ s/\/$//;
my $chain_keys = "chain_keys";

my $node_tag = $ARGV[1];# alice | bob
my $url = $ARGV[2];# Ex: http://localhost:9933

if (-e "$project_dir") {
    if($node_tag eq "alice" || $node_tag eq "bob"){
        if( defined $url && $url =~ m/http/){
            system("unzip $project_dir/$chain_keys.zip -d $project_dir");
            upload($node_tag, "babe", $url);
            upload($node_tag, "gran", $url);
            system("rm -Rf $project_dir/$chain_keys");
        }else{
            print("Wrong url! Example: http://localhost:9933\n");
        }
    } else{
        print("Wrong node tag: $node_tag! Should be: alice | bob\n");
    }

} else {
    print("There is no such directory: $project_dir!\n");
}

sub upload{
    my ($node_tag, $type, $url) = @_;
    my $file = $project_dir . "/$chain_keys/". $node_tag . "_".  $type . "_config.json";
    my $command = "curl $url -H \"Content-Type:application/json;charset=utf-8\" -d \"\@$file\"";
    print($command, "\n");
    system($command);
}