use strict;
use warnings FATAL => 'all';

my $input_spec_file = $ARGV[0];
my $output_spec_file = $ARGV[1];

my $one_twelfth_of_total_emission = "2000000000000000000000000000";

if (-e "$input_spec_file") {
    create_specification($input_spec_file, $output_spec_file);
}
else {
    print("Input file doesn't exist: ", $input_spec_file, "\n");
}

sub create_specification {
    my ($input_spec_file, $output_spec_file) = @_;

    open(INPUT, "<$input_spec_file") or die "Can't open file: $input_spec_file!\n";
    open(OUTPUT, ">$output_spec_file") or die "Can't open file: $output_spec_file!\n";
    my $json_data = <<"json_delimeter";
{
  "name": "Slonigiraf",
  "id": "slonigiraf",
  "chainType": "Live",
  "bootNodes": [],
  "telemetryEndpoints": [
    [
      "/dns/telemetry.polkadot.io/tcp/443/x-parity-wss/%2Fsubmit%2F",
      0
    ]
  ],
  "protocolId": "slon",
  "properties": {
    "tokenDecimals": 12,
    "tokenSymbol": "SLON"
  },
  "forkBlocks": null,
  "badBlocks": null,
  "consensusEngine": null,
  "lightSyncState": null,
  "genesis": {
json_delimeter

    print OUTPUT $json_data;

    #skip everything before genesis and genesis
    while (my $str = <INPUT>) {
        if ($str =~ m/\"genesis\"/) {
            last;
        }
    }
    while (my $str = <INPUT>) {
        if ($str =~ m/\s1000000000000000000\s/) {
            $str =~ s/1000000000000000000/$one_twelfth_of_total_emission/;
        }
        if ($str =~ m/validatorCount/) {
            $str =~ s/2/4/;
        }
        if ($str =~ m/minimumValidatorCount/) {
            $str =~ s/1/2/;
        }
        print OUTPUT $str;
    }
    close OUTPUT;
    close INPUT;
}