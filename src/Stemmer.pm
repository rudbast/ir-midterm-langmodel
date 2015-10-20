#!/usr/bin/perl

# Source:
# https://abdullahhafidh.files.wordpress.com/2010/11/laporan-tugas-ii-stemmer.pdf

package Stemmer;

use string;
use warnings;
use Exporter;


our @ISA = qw( Exporter );

our @EXPORT_OK = qw( prefixSuffixStem suffixPrefixStem );

our @EXPORT = qw( prefixSuffixStem suffixPrefixStem );


sub prefixSuffixStem() {
    my $word = $_[0];
    my $temporary;
    my @numberOfStemAwalan = (0, 0, 0, 0, 0, 0, 0);
    my @numberOfStemAkhiran = (0, 0, 0);
    my @temp;
    # Preffix Disallowed suffixes
    # be- -i
    # di- -an
    # ke- -i, -kan
    # me- -an
    # se- -i,-kan
    # te- -an
    do {
        $temporary = $word;
        # me, be, pe, di, ke, te, se
        @temp = &stemmingAwalan($temporary, $numberOfStemAwalan[0],
        $numberOfStemAwalan[1], $numberOfStemAwalan[2], $numberOfStemAwalan[3],
        $numberOfStemAwalan[4], $numberOfStemAwalan[5], $numberOfStemAwalan[6]);
        $index = 0;
        foreach $i(@temp) {
            if($index != $#temp) {
                $numberOfStemAwalan[$index] = $temp[$index];
            } else {
                $word = $temp[$index];
            }
            $index++;
        }
    } while ($word !~ $temporary);

    do {
        $temporary = $word;
        @temp = &stemmingAkhiran($temporary, $numberOfStemAkhiran[0],
        $numberOfStemAkhiran[1], $numberOfStemAkhiran[2]);
        $index = 0;

        foreach $i(@temp) {
            if($index != $#temp){
                $numberOfStemAkhiran[$index] = $temp[$index];
            } else {
                $word = $temp[$index];
            }
            $index++;
        }
    } while ($word !~ $temporary);
    return $word;
}

sub suffixPrefixStem() {
    my $word = $_[0];
    my $temporary;
    my @numberOfStemAwalan = (0, 0, 0, 0, 0, 0, 0);
    my @numberOfStemAkhiran = (0, 0, 0);
    my @temp;

    do {
        $temporary = $word;
        @temp = &stemmingAkhiran($temporary, $numberOfStemAkhiran[0],
        $numberOfStemAkhiran[1], $numberOfStemAkhiran[2]);
        #me, be, pe, di, ke, te, se
        $index = 0;
        foreach $i(@temp) {
            if($index != $#temp){
                $numberOfStemAkhiran[$index] = $temp[$index];
            } else {
                $word = $temp[$index];
            }
            $index++;
        }
    } while ($word !~ $temporary);

    do {
        $temporary = $word;
        @temp = &stemmingAwalan($temporary, $numberOfStemAwalan[0],
        $numberOfStemAwalan[1], $numberOfStemAwalan[2], $numberOfStemAwalan[3],
        $numberOfStemAwalan[4], $numberOfStemAwalan[5], $numberOfStemAwalan[6]);
        $index = 0;
        foreach $i(@temp) {
            if($index != $#temp) {
                $numberOfStemAwalan[$index] = $temp[$index];
            } else{
                $word = $temp[$index];
            }
            $index++;
        }
    } while ($word !~ $temporary);
    return $word;
}

sub stemmingAwalan() {
    my $word = $_[0];
    my $temp = $word;
    my @awalan = ($_[1], $_[2], $_[3], $_[4], $_[5], $_[6], $_[7]);

    if(length $word <= 2) {
        return $word;
    }

    if($word =~ /^me/ && $awalan[0] == 0) {
        $word = stemmingAwalanMe($word);
        $awalan[0]++;
    }
    # stemming awalan be
    elsif($word =~ /^be/ && $awalan[1] == 0) {
        $word = stemmingAwalanBe($word);
        $awalan[1]++;
    }
    # stemming awalan pe
    elsif($word =~ /^pe/ && $awalan[2] == 0) {
        $word = stemmingAwalanPe($word);
        $awalan[2]++;
    }
    # stemming awalan di
    elsif($word =~ /^di/ && $awalan[3] == 0) {
        $word = stemmingAwalanDi($word);
        $awalan[3]++;
    }
    # stemming awalan ke
    elsif($word =~ /^ke/ && $awalan[4] == 0) {
        $word = stemmingAwalanKe($word);
        $awalan[4]++;
    }
    # stemming awalan te
    elsif($word =~ /^te/ && $awalan[5] == 0) {
        $word = stemmingAwalanTe($word);
        $awalan[5]++;
    }
    # stemming awalan se
    elsif($word =~ /^se/ && $awalan[6] == 0) {
        $word = stemmingAwalanSe($word);
        $awalan[6]++;
    }

    if(length $word <= 2) {
        $word = $temp;
    }
    push @awalan, $word;
    return @awalan;
}

sub stemmingAwalanMe() {
    my $word = $_[0];
    my $temp = $word;

    $temp =~ s/^mem(b|f|v|p)(.)/$1$2/i;
    if($temp !~ $word) {
        return $temp;
    }

    $temp =~ s/^mem([aiueo][^aiueo])(.)/p$1$2/i; # peluruhan p
    if($temp !~ $word) {
        return $temp;
    }

    # me + kata dasar dengan huruf awal s berubah menjadi meny-
    $temp = $word;
    $temp =~ s/^meny(.*)/s$1/i;
    if($temp !~ $word) {
        return $temp;
    }

    $temp = $word;
    $temp =~ s/^men(c|d|t|j|z|[a-zA-Z]y)(.)/$1$2/i;
    if($temp !~ $word) {
        return $temp;
    }

    $temp = $word;
    $temp =~ s/^men([^aiueo][aiueo][^aiueo])$/$1/i;
    if($temp !~ $word) {
        return $temp;
    }

    $temp = $word;
    $temp =~ s/^men([aiueo])(.)/t$1$2/i; # peluruhan t
    if($temp !~ $word) {
        return $temp;
    }

    $temp = $word;
    $temp =~ s/^menge([^aiueo]+[aiueo][^aiueo])$/$1/i;
    if($temp !~ $word) {
        return $temp;
    }

    # me + kata dasar dengan huruf awal huruf vokal, g, h
    $temp = $word;
    $temp =~ s/^meng([aiueo]|k|g|h|[^aiueo][^aiueo])(.)/$1$2/i;
    if($temp !~ $word) {
        return $temp;
    }

    $temp = $word;
    $temp =~ s/^me(.)/$1$2/i;
    if($temp !~ $word) {
        return $temp;
    }
    return $word;
}

sub stemmingAwalanBe() {
    my $word = $_[0];
    my $temp = $word;

    $temp =~ s/^bel(ajar)/$1/i;
    if($temp !~ $word) {
        return $temp;
    }

    $temp = $word;
    $temp =~ s/^be([a-zA-Z]er)/$1/i;
    if($temp !~ $word && $temp) {
        return $temp;
    }

    $temp = $word;
    $temp =~ s/^be(r[aiueo])(.)/$1$2/i;
    if($temp !~ $word && $temp) {
        return $temp;
    }

    $temp = $word;
    $temp =~ s/^be(r)(.)/$2/i;
    if($temp !~ $word) {
        return $temp;
    }

    $temp = $word;
    $temp =~ s/^be(.)/$1/i;
    if($temp !~ $word) {
        return $temp;
    }
    return $word;
}

sub stemmingAwalanPe() {
    my $word = $_[0];
    my $temp = $word;

    $temp =~ s/^pel(ajar)/$1/i;
    if($temp !~ $word) {
        return $temp;
    }

    $temp =~ s/^penge([^aiueo]+[aiueo][^aiueo])/$1/i;
    if($temp !~ $word) {
        return $temp;
    }

    $temp = $word;
    $temp =~ s/^peng([aiueo]|k|g|h|[^aiueo][^aiueo])(.)/$1$2/i;
    if($temp !~ $word) {
        return $temp;
    }

    $temp = $word;
    $temp =~ s/^pen(d|c|j|l)(.)/$1$2/i;
    if($temp !~ $word) {
        return $temp;
    }

    $temp = $word;
    $temp =~ s/^peny(.)/s$1/i;
    if($temp !~ $word) {
        return $temp;
    }

    $temp = $word;
    $temp =~ s/^pem(b|p)(.)/$1$2/i;
    if($temp !~ $word) {
        return $temp;
    }

    # aturan untuk per
    $temp = $word;
    $temp =~ s/^per([aiueo].)/$1/i;
    if($temp !~ $word) {
        return $temp;
    }

    $temp = $word;
    $temp =~ s/^per(.)/$1/i;
    if($temp !~ $word) {
        return $temp;
    }

    $temp = $word;
    $temp =~ s/^pe(l|r|w|y)(.)/$1$2/i;
    if($temp !~ $word) {
        return $temp;
    }

    $temp = $word;
    $temp =~ s/^pe(m|n|ng|ny)([aiueo])(.)/$1$2$3/i;
    if($temp !~ $word) {
        return $temp;
    }
    return $word;
}

sub stemmingAwalanDi() {
    my $word = $_[0];
    my $temp = $word;

    $temp =~ s/^di(.)/$1/i;
    if($temp !~ $word) {
        return $temp;
    }
    return $word;
}

sub stemmingAwalanKe() {
    my $word = $_[0];
    my $temp = $word;

    $temp =~ s/^ke(.)/$1/i;
    if($temp !~ $word) {
        return $temp;
    }
    return $word;
}
sub stemmingAwalanTe() {
    my $word = $_[0];
    my $temp = $word;
    $word =~ s/^te(.)/$1/i;
    if($word =~ /^r/) { # set 1
        $word =~ s/^r(.)/$1/i;
        if($word =~ /^r/i) { # set 2
            return $temp;
        } elsif($word =~ /^[raiueo]/i) { # set 2
            return $word;
        } elsif($word =~ /^[^raiueo]/i) { # set 2
            $word =~ s/^[^raiueo](.)/$1/i;
            if($word =~ /^er/) { # set 3
                $word =~ s/^er(.)/$1/i;
                if($word =~ /^[aiueo]/i) {
                $temp =~ s/^ter(.)/$1/i;
                    return $temp;
                } elsif($word =~ /^[^aiueo]/i) {
                    return $temp;
                }
            } elsif($word !~ /^er/) { # set 3
                $temp =~ s/^ter(.*)/$1/i;
                return $temp;
            }
        }
    } elsif($word =~ /^[^raiueo]/) {
        $word =~ s/^[^raiueo](.)/$1/i;
        if($word =~ /^er/) {
            $word =~ s/^er(.)/$1/i;
            if($word =~ /^[aiueo]/) {
                return $temp;
            }
            if($word !~ /^[aiueo]/) {
                $temp =~ s/^te(.)/$1/i;
                return $temp;
            }
        }
    }
    return $temp;
}

sub stemmingAwalanSe() {
    my $word = $_[0];
    my $temp = $word;
    $temp =~ s/^se(.)/$1/i;
    if($temp !~ $word) {
        return $temp;
    }
    return $word;
}

sub stemmingAkhiran() {
    my $word = $_[0];
    my $temp = $word;
    #root-word [[+DS][+PP][+P]]
    my @akhiran = ($_[1], $_[2], $_[3]);
    if(length $word <= 2) {
        return $word;
    }
    #derivation suffix, hanya sekali saja.
    if(($word =~ /an$/ || $word =~ /i$/) && $akhiran[0] == 0) {
        $akhiran[0]++;
        if(($word =~ /^me/ && $word =~ /[^k]an$/) | ($word =~ /^be/ && $word =~ /i$/) |($word =~
        /^di/ && $word =~ /[^k]an$/) | ($word =~ /^ke/ && ($word =~ /i$/ || $word =~
        /kan$/)) | ($word =~ /^te/ && $word =~ /[^k]an$/) | ($word =~ /^se/ && ($word =~
        /i$/ || $word =~ /kan$/))){
            return $word;
        }
        if($word =~ /kan$/){
            $word = stemmingAkhiranKan($word);
        } elsif($word =~ /an$/){
            $word = stemmingAkhiranAn($word);
        } elsif($word =~ /i$/){
            $word = stemmingAkhiranI($word);
        }
    }
    # Possessive pronouns, hanya sekali saja
    elsif(($word =~ /ku$/ || $word =~ /mu$/ || $word =~ /nya$/) && $akhiran[1] == 0) {
        $akhiran[1]++;
        if($word =~ /ku$/){
            $word = stemmingAkhiranKu($word);
        } elsif($word =~ /mu$/){
            $word = stemmingAkhiranMu($word);
        } elsif($word =~ /nya$/){
            $word = stemmingAkhiranNya($word);
        }
    }
    # Particles, hanya sekali saja.
    elsif(($word =~ /kah$/ || $word =~ /lah$/ || $word =~ /tah$/ || $word =~ /pun$/) && $akhiran[2] == 0) {
        $akhiran[2]++;
        if($word =~ /lah$/){
            $word = stemmingAkhiranLah($word);
        } elsif($word =~ /kah$/){
            $word = stemmingAkhiranKah($word);
        } elsif($word =~ /tah$/){
            $word = stemmingAkhiranTah($word);
        } elsif($word =~ /pun$/){
            $word = stemmingAkhiranPun($word);
        }
    }

    if(length $word <= 2) {
        $word = $temp;
    }
    push @akhiran, $word;
    return @akhiran;
}

sub stemmingAkhiranKan() {
    my $word = $_[0];
    my $temp = $word;
    $temp =~ s/(.)kan$/$1/i;
    return $temp;
}

sub stemmingAkhiranWan() {
    my $word = $_[0];
    my $temp = $word;
    $temp =~ s/(.)wan$/$1/i;
    return $temp;
}

sub stemmingAkhiranWati() {
    my $word = $_[0];
    my $temp = $word;
    $temp =~ s/(.)wati$/$1/i;
    return $temp;
}

sub stemmingAkhiranAn() {
    my $word = $_[0];
    my $temp = $word;
    $temp =~ s/(.)an$/$1/i;
    return $temp;
}

sub stemmingAkhiranI() {
    my $word = $_[0];
    my $temp = $word;
    $temp =~ s/(.)i$/$1/i;
    return $temp;
}

sub stemmingAkhiranLah() {
    my $word = $_[0];
    my $temp = $word;
    $temp =~ s/(.)lah$/$1/i;
    return $temp;
}

sub stemmingAkhiranKah() {
    my $word = $_[0];
    my $temp = $word;
    $temp =~ s/(.)kah$/$1/i;
    return $temp;
}

sub stemmingAkhiranTah() {
    my $word = $_[0];
    my $temp = $word;
    $temp =~ s/(.)tah$/$1/i;
    return $temp;
}

sub stemmingAkhiranNya() {
    my $word = $_[0];
    my $temp = $word;
    $temp =~ s/(.)nya$/$1/i;
    return $temp;
}

sub stemmingAkhiranMu() {
    my $word = $_[0];
    my $temp = $word;
    $temp =~ s/(.)mu$/$1/i;
    return $temp;
}

sub stemmingAkhiranKu() {
    my $word = $_[0];
    my $temp = $word;
    $temp =~ s/(.)ku$/$1/i;
    return $temp;
}

sub stemmingAkhiranPun() {
    my $word = $_[0];
    my $temp = $word;
    $temp =~ s/(.)pun$/$1/i;
    return $temp;
}

1;
