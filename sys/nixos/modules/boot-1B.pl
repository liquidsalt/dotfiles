# usage: perl boot-1B.pl /boot/grub/grub.cfg   names NixOS's boot entries Docked and Undocked, Docked first
# An entry it doesn't recognise keeps the name NixOS gave it, so a change in NixOS's wording only brings the stock names back
use strict;
use warnings;

my $file = shift or die "usage: boot-1B.pl <grub.cfg>\n";
open my $in, '<', $file or die "$file: $!\n";
my $cfg = do { local $/; <$in> };
close $in;

sub retitle {
    my ($entry, $title) = @_;
    $entry =~ s/^menuentry "[^"]*"/menuentry "$title"/;
    return $entry;
}

# NixOS writes each base entry with its docked specialisation right after it, an entry's body never has a line starting with }
$cfg =~ s{
    (menuentry\ "NixOS(?:\ -\ Configuration\ \d+)?\ -\ Default[^"]*"[^\n]*\{\n.*?^\}\n\n?)
    (menuentry\ "NixOS(?:\ -\ Configuration\ \d+)?\ -\ (?:docked|\(docked\ [^"]*\))"[^\n]*\{\n.*?^\}\n\n?)
}{
    my ($base, $docked) = ($1, $2);
    my $latest = $base =~ /^menuentry "NixOS - Default"/;
    retitle($docked, $latest ? "Docked   - latest" : "Docked") . retitle($base, $latest ? "Undocked - latest" : "Undocked");
}gmsxe;

$cfg =~ s/^submenu "NixOS - All configurations"/submenu "All configs:"/m;
$cfg =~ s/^submenu "NixOS - Configuration (\d+) \((\d{4}-\d\d-\d\d) - [^"]*\)"/submenu "$1 - $2"/gm;

# Swapped in whole, a crash halfway never leaves a broken menu
open my $out, '>', "$file.tmp" or die "$file.tmp: $!\n";
print $out $cfg;
close $out or die "$file.tmp: $!\n";
rename "$file.tmp", $file or die "$file: $!\n";
