#!/usr/bin/perl

use strict;
use warnings;

use feature "say";
use Data::Dumper qw (Dumper);

use Stemmer qw ( prefixSuffixStem suffixPrefixStem )


#### Main Program

## Input data
my $doc   = "../res/docs.dat";
my $stw   = "../res/stopwords-ina.dat";
## Output data
my $res   = "../out/hasil.txt";
my $index = "../out/indeks.txt";

## main process
my %list = indexing($doc, $res, $index);

# print Dumper \%list;

say "selesai.";

####

sub preprocess {
    $file = shift;
    ## open file indeks kata
    open INDEX, "> $file" or die "can't open index file";

    ## open file
    open DOCS, "$file" or die "can't open resource file";

    ## open file stopwords
    open(STOP,"$file") or die "can't open stopwords file";

    ## simpan list stopwords dalam hash
    my %stopwords = ();

    while (<STOP>) {
        chomp;
        $stopwords{ $_ } = 1;
    }

    ## total kata muncul pada berapa dokumen
    my %termfreq = ();

    ## total banyaknya dokumen
    my $totalDoc = 0;

    ## frekuensi tiap docid - docno
    my %result = ();

    ## frekuensi per dokumen
    my %hashKata = ();

    ## nomor dokumen
    my $curr_doc_no;

    ## total banyaknya kata tiap dokumen
    my $totalWordsEachDoc = 0;

    while (<DOCS>) {
        chomp;
        s/\s+/ /gi;

        ## update informasi docno
        if (/<DOCNO>/) {
            s/<.*?>/ /gi;
            s/\s+/ /gi;
            s/^\s+//;
            s/\s+$//;

            ## inisialisasi ulang daftar kata dan docno tiap dokumen baru
            %hashKata = ();
            $curr_doc_no = $_;

            ## increment informasi banyaknya dokumen
            $totalDoc += 1;
        }

        if (/<TEXT>/../<\/TEXT>/) {
            s/<.*?>/ /gi;
            s/[#\%\$\&\/\\,;:!?\.\@+`'"\*()_{}^=|]/ /g;
            s/\s+/ /gi;
            s/^\s+//;
            s/\s+$//;
            tr/[A-Z]/[a-z]/;

            ## tokenisasi
            my @splitKorpus = split;

            ## TOKENIZATION
            foreach my $kata (@splitKorpus) {

                ## STOPWORDS REMOVAL
                unless (exists($stopwords{ $kata })) {

                    ## STEMMING
                    $rootKata = stem($kata);

                    ## hitung frekuensi tiap kata
                    if (exists($hashKata{ $rootKata })) {
                        $hashKata{ $rootKata } += 1;
                    } else {
                        $hashKata{ $rootKata } = 1;
                    }
                }
            }

            ## increment jumlah frekuensi kata dalam dokumen
            $totalWordsEachDoc += scalar @splitKorpus;
        }

        if (/<\/DOC>/) {
            ## simpan frekuensi tiap kata dalam tiap docno
            $result{ $curr_doc_no } = { %hashKata };
            ## simpan total banyaknya kata dalam tiap docno
            $result{ $curr_doc_no }{ "totalWordsEachDoc" } = $totalWordsEachDoc;

            ## hitung frekuensi kemunculan kata untuk seluruh dokumen
            foreach my $kata (keys %hashKata) {
                if (exists($termfreq{ $kata })) {
                    $termfreq{ $kata } += 1;
                } else {
                    $termfreq{ $kata } = 1;
                }
            }

            # say scalar keys %hashKata;
            # say $totalWordsEachDoc;

            ## kosongkan daftar frekuensi kata untuk dokumen selanjutnya
            %hashKata = ();
            $totalWordsEachDoc = 0;
        }
    }

    ## hitung idf
    my %IDF = ();

    foreach my $word (keys %termfreq) {
        $IDF{$word} = $termfreq{$word} / $totalDoc;
    }

    ## hitung tf-idf
    my %TFIDF = ();

    foreach my $docno (sort keys %result) {
        foreach my $word (sort keys %{ $result{$docno} }) {
            if ($word ne "totalWordsEachDoc") {
                my $currTotalFreq = $result{$docno}{"totalWordsEachDoc"};
                $TFIDF{$docno} = $result{$docno}{$word} / $currTotalFreq * $IDF{$word};
            }
        }

        say RESULT "";
    }

    foreach my $word (sort {$termfreq{$b} <=> $termfreq{$a}
        or $a cmp $b} keys %termfreq) {
        printf INDEX "%20s : %4d\n", $word, $termfreq{$word};
    }

    ## tutup file
    close STOP;
    close DOCS;
    close INDEX;

    return %result;
}

=item stem()

Melakukan stemming pada kata dari parameter menggunakan modul perl
yang di-export dari file Stemmer.pm.

Hasil yang di-return adalah root dari kata yang dihasilkan oleh
'prefixSuffixStem()' / 'suffixPrefixStem()', secara default akan
menggunakan 'prefixSuffixStem()', tambahkan parameter (value: 0/1)
untuk memilih secara eksplisit.

=cut
sub stem {
    ## kata yang akan di-stem
    my $word = shift;
    ## pilihan metode yang digunakan (default: 0)
    my $choice = shift or 0;

    if ($choice eq 0) {
        return prefixSuffixStem($word);
    } else {
        return suffixPrefixStem($word);
    }
}

sub computeTfIdf {
    # body...
}

sub normalization {
    # body...
}
