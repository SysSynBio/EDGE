#! /usr/bin/perl -w
use strict;
use Getopt::Long;
use FindBin qw($Bin);
use lib $Bin;
use gi2lineage;

$|=1;

my $cutoff=$ARGV[0];
$cutoff||=0;
my %opt;

loadTaxonomy();

#print STDERR "Loading gi_taxid_nucl.dat...\n";
#my $gi2taxid = retrieve('/users/218817/scratch/opt/src/krona/taxonomy/gi_taxid_nucl.dat');

my %major_level = (
	'superkingdom' => 10,
	'phylum'       => 20,
	'class'        => 30,
	'order'        => 40,
	'family'       => 50,
	'genus'        => 60,
	'species'      => 70,
    #'strain'       => 80,
    #'replicon'     => 90
);

my @headers;
my $taxa;

while(<STDIN>)
{
	chomp;
	next if /^#/;
	next if /^$/;

	my @fields = split /\t/, $_;

	my $gi = $fields[0];
	my $taxID = getTaxIDFromGI($gi);

    unless ( $taxID ){
	    print STDERR "[WARNING] Can't find GI#$gi\n";
        next;
    }

    my @ranks;

    my $upper_rank_name="root";
    foreach my $rank ( sort {$major_level{$a}<=>$major_level{$b}} keys %major_level ){
        my $name = gi2rank($gi,$rank);
        $name ||= "no rank - $upper_rank_name";
        $name =~ s/([\(\),:])//g;
        push @ranks, $name;
        $upper_rank_name = $name;
    }

    my $out = join "\t", @ranks;

    $taxa->{$out} ||= 0;
    $taxa->{$out} += $fields[1];
}

foreach my $lineage ( sort {$taxa->{$b}<=>$taxa->{$a}} keys %$taxa ){
	next if $taxa->{$lineage} < $cutoff;
    print $taxa->{$lineage}."\t".$lineage."\n";
}
