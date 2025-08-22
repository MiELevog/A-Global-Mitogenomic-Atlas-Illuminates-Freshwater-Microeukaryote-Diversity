#!/usr/bin/perl
use strict;
use warnings;

# Initialize variables
my %contigs;
my $current_fosmid = "";

# Open input file
my $filename = shift @ARGV // 'New_representatives_jackass_res_simplified.txt';
open(my $fh, '<', $filename)
  or die "Could not open '$filename': $!";

while (my $line = <$fh>) {
    chomp $line;

    # Identify start of a new contig
    if ($line =~ /^FOSMID_ID=(\S+)/) {
        $current_fosmid = $1;
        $contigs{$current_fosmid} = [];
    }
    # Identify end of a contig
    elsif ($line eq "//") {
        $current_fosmid = "";
    }
    # Store taxonomy information, ignoring absent taxonomy "-"
    elsif ($current_fosmid && $line =~ /\S+/ && $line ne '-') {
        push @{$contigs{$current_fosmid}}, $line;
    }
}
close($fh);

# Function to find the LCA based on priority, starting from level 4 to level 1
sub find_lca {
    my @taxonomies = @_;
    my @levels;

    # Split each taxonomy into levels and store in an array of arrays
    foreach my $tax (@taxonomies) {
        next if $tax eq '-';  # Ensure "-" does not contribute to the LCA calculation
        my @split_tax = split(/\s*;\s*/, $tax);
        push @levels, \@split_tax;
    }

    # Determine LCA by starting from level 4 to level 1
    my $max_levels = 0;
    foreach my $tax (@levels) {
        $max_levels = scalar(@$tax) if scalar(@$tax) > $max_levels;
    }

    my @lca;
    for (my $i = 0; $i < $max_levels; $i++) {
        my %level_count;
        foreach my $tax (@levels) {
            next unless defined $tax->[$i];
            $level_count{$tax->[$i]}++;
        }

        # Find the most common taxonomic level at this depth
        my $most_common = "";
        my $highest_count = 0;
        foreach my $level (keys %level_count) {
            if ($level_count{$level} > $highest_count) {
                $highest_count = $level_count{$level};
                $most_common = $level;
            }
        }

        # Debugging output to check counts at each level
        print STDERR "Level $i: Most common = $most_common, Count = $highest_count, Total = ", scalar(@levels), "\n";

        # If the most common level has the majority count, add it to the LCA
        if ($highest_count > scalar(@levels) / 2) {
            push @lca, $most_common;
        } else {
            last;
        }
    }

    return scalar(@lca) ? join(" ; ", @lca) : "No Classification";
}

# Process each contig and find the LCA classification
foreach my $fosmid (keys %contigs) {
    my $lca = find_lca(@{$contigs{$fosmid}});
    print "FOSMID_ID=$fosmid\n";
    print "LCA Classification: $lca\n\n";
}

__END__

# Explanation:
# 1. The script reads the input file line by line, capturing the contig data between "FOSMID_ID=" and "//".
# 2. For each contig, it stores taxonomy lines in a hash structure, ignoring lines with "-".
# 3. The function "find_lca" is then used to determine the LCA classification for each contig based on the priority from level 4 to level 1.
#    It starts from the deepest level and moves upwards to find the level with a majority consensus, stopping as soon as it cannot find a consensus.
# 4. Debugging output has been added to help identify issues with the majority calculation at each level.
# 5. The LCA is printed for each contig along with the contig ID.
