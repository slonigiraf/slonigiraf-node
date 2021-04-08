use strict;
use warnings FATAL => 'all';

my $default_spec_file = $ARGV[0];
my $output_dir = $ARGV[1];
$output_dir =~ s/\/$//;

unless (-e "$output_dir") {
    system("mkdir -p $output_dir");
}
if (-e "$default_spec_file") {
    create_project($default_spec_file, $output_dir);
}
else {
    print("Can't open file: $default_spec_file!\n");
}

sub create_project {
    my ($default_spec_file, $output_dir) = @_;

    #Configure file and directories names. Remove old data
    my $output_spec_file = "$output_dir/chain-plain.json";
    my $output_keys_dir = "$output_dir/chain_keys";

    system("rm -Rf $output_spec_file");
    system("rm -Rf $output_keys_dir");
    system("mkdir $output_keys_dir");

    my $output_alice_babe_config_file = "$output_keys_dir/alice_babe_config.json";
    my $output_alice_gran_config_file = "$output_keys_dir/alice_gran_config.json";
    my $output_bob_babe_config_file = "$output_keys_dir/bob_babe_config.json";
    my $output_bob_gran_config_file = "$output_keys_dir/bob_gran_config.json";

    system("rm -Rf $output_alice_babe_config_file");
    system("rm -Rf $output_alice_gran_config_file");
    system("rm -Rf $output_bob_babe_config_file");
    system("rm -Rf $output_bob_gran_config_file");


    #We're going to substitute these keys.
    my $alice_sr25519 = "5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY";
    my $bob_sr25519 = "5FHneW46xGXgs5mUiveU4sbTyGBzmstUspZC92UhjJM694ty";
    my $validators_sr25519 = {};
    $validators_sr25519->{$alice_sr25519} = "";
    $validators_sr25519->{$bob_sr25519} = "";

    #sr25519 and ed2551 are different representation of the same key
    my $alice_ed2551 = "5FA9nQDVg267DEd8m1ZypXLBnvN7SFxYwV7ndqSYGiN9TTpu";
    my $bob_ed2551 = "5GoNkf6WdbxCFnPdAnYYQyCjAKPJgLNxXwPjwTh6DGg6gN3E";
    my $validators_ed2551 = {};
    $validators_ed2551->{$alice_ed2551} = "";
    $validators_ed2551->{$bob_ed2551} = "";

    my $old_to_new_address = {};

    open(INPUT, "<$default_spec_file") or die "Can't open file: $default_spec_file!\n";
    while (my $str = <INPUT>) {
        if ($str =~ m/\"(.{48})\"/) {
            $old_to_new_address->{$1} = "";
        }
    }
    close INPUT;

    #generate new sr25519 keys
    for my $old_address (keys %$old_to_new_address) {
        unless (exists $validators_ed2551->{$old_address}) {
            my $file_name = $output_keys_dir . "/" . $old_address;
            generate_sr25519_key($file_name);
        }
    }
    #generate new ed2551 keys
    generate_ed2551_key("$output_keys_dir/$alice_sr25519", "$output_keys_dir/$alice_ed2551");
    generate_ed2551_key("$output_keys_dir/$bob_sr25519", "$output_keys_dir/$bob_ed2551");

    #write the result
    open(INPUT2, "<$default_spec_file") or die "Can't open file: $default_spec_file!\n";
    open(OUTPUT, ">$output_spec_file") or die "Can't open file: $output_spec_file!\n";
    while (my $str = <INPUT2>) {
        if ($str =~ m/\"(.{48})\"/) {
            my $old_address = $1;
            my ($phrase, $address, $public_key) = read_key_file("$output_keys_dir/$old_address");
            $str =~ s/$old_address/$address/;
        }
        print OUTPUT $str;
    }
    close OUTPUT;
    close INPUT2;

    #write keys json data
    #($type, $key_file, $output_file)
    write_insert_key_json("babe", "$output_keys_dir/$alice_sr25519", $output_alice_babe_config_file);
    write_insert_key_json("gran", "$output_keys_dir/$alice_ed2551", $output_alice_gran_config_file);
    write_insert_key_json("babe", "$output_keys_dir/$bob_sr25519", $output_bob_babe_config_file);
    write_insert_key_json("gran", "$output_keys_dir/$bob_ed2551", $output_bob_gran_config_file);

    #Encrypt keys directory
    encrypt_keys_directory($output_keys_dir,"123456");
}

sub generate_ed2551_key {
    my ($sr25519_file, $ed2551_file) = @_;
    my ($phrase, $address, $public_key) = read_key_file($sr25519_file);
    system("subkey inspect --scheme ed25519 \"$phrase\" > $ed2551_file");
}

sub encrypt_keys_directory {
    my ($output_keys_dir, $password) = @_;
    system("zip -er $output_keys_dir.zip $output_keys_dir");
    if (-e "$output_keys_dir.zip") {
        system("rm -Rf $output_keys_dir");
    }
}

sub generate_sr25519_key {
    my $file_name = shift;
    system("subkey generate --scheme sr25519 > $file_name");
}

sub read_key_file {
    my $file_name = shift;
    my $phrase = "";
    my $address = "";
    my $public_key = "";
    open(INPUT, "<$file_name") or die "Can't open file: $file_name!\n";
    while (my $str = <INPUT>) {
        if ($str =~ m/`(.+)`/) {
            $phrase = $1;
        }
        elsif ($str =~ m/\s(.{48})\s/) {
            $address = $1;
        }
        elsif ($str =~ m/\s(.{66})\s/) {
            $public_key = $1;
        }
    }
    close INPUT;
    return ($phrase, $address, $public_key);
}

sub write_insert_key_json {
    my ($type, $key_file, $output_file) = @_;
    my ($phrase, $address, $public_key) = read_key_file($key_file);

    my $json_data = <<"json_delimeter";
{
  "jsonrpc":"2.0",
  "id":1,
  "method":"author_insertKey",
  "params": [
    "$type",
    "$phrase",
    "$public_key"
  ]
}
json_delimeter

    open(OUT_JSON, ">$output_file") or die "Can't open file: $output_file!\n";
    print OUT_JSON $json_data;
    close OUT_JSON;
}