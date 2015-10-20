#!/usr/bin/perl

use strict;
use warnings;

use feature "say";
use Data::Dumper qw (Dumper);

use Stemmer qw ( prefixSuffixStem  suffixPrefixStem );


#### Main Program

## File input & output path
my $resourcePath = "./res";
my $outputPath   = "./out";

## Input data
my $doc          = "$resourcePath/test.dat";
my $stw          = "$resourcePath/stopwords-ina.dat";

## Output data
my $index        = "$outputPath/indeks.txt";

my %list = preprocess($doc, $index, $stw);

$Data::Dumper::Sortkeys = 1;
print Dumper \%list;

say "selesai.";

####

sub preprocess {
    my $docs = shift;
    ## open file input dokumen
    open DOCS, "$docs" or die "can't open resource file";

    my $file = shift;
    ## open file indeks kata
    open INDEX, "> $file" or die "can't open index file";

    my $stop = shift;
    ## open file stopwords
    open STOP, "$stop" or die "can't open stopwords file";

    ## simpan list stopwords dalam hash
    my %stopwords = ();

    while (<STOP>) {
        chomp;
        $stopwords{ $_ } = 1;
    }

    ## total kata muncul pada berapa dokumen
    my %dft = ();

    ## total frekuensi kata pada seluruh dokumen
    my %cft = ();

    ## total banyaknya dokumen
    my $totalDoc = 0;

    ## frekuensi tiap dokumen (DOCNO)
    my %docTermFreq = ();

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

            ## hitung total kata tiap dokumen
            $totalWordsEachDoc += tokenize(\@splitKorpus, \%hashKata, \%cft, \%stopwords);
        }

        if (/<\/DOC>/) {
            ## simpan frekuensi tiap kata dalam tiap docno
            $docTermFreq{ $curr_doc_no } = { %hashKata };
            ## simpan total banyaknya kata dalam tiap docno
            $docTermFreq{ $curr_doc_no }{ "totalWordsEachDoc" } = $totalWordsEachDoc;

            ## hitung frekuensi kemunculan kata pada berapa bayak dokumen
            foreach my $kata (keys %hashKata) {
                if (exists($dft{ $kata })) {
                    $dft{ $kata } += 1;
                } else {
                    $dft{ $kata } = 1;
                }
            }

            # say scalar keys %hashKata;
            # say $totalWordsEachDoc;

            ## kosongkan daftar frekuensi kata untuk dokumen selanjutnya
            %hashKata = ();
            $totalWordsEachDoc = 0;
        }
    }

    ## hitung tft tiap dokumen
    my %tft = ();

    foreach my $word (keys %dft) {
        # $tft{$word} = $dft{$word} / $totalDoc;
        foreach my $doc (keys %docTermFreq) {
            if (exists($docTermFreq{ $doc }{ $word })) {
                $tft{ $doc }{ $word } = $docTermFreq{ $doc }{ $word };
            } else {
                $tft{ $doc }{ $word } = 0;
            }
        }
    }

    # ## hitung tf-idf
    # my %TFIDF = ();

    # foreach my $docno (sort keys %docTermFreq) {
    #     foreach my $word (sort keys %{ $docTermFreq{$docno} }) {
    #         if ($word ne "totalWordsEachDoc") {
    #             my $currTotalFreq = $docTermFreq{$docno}{"totalWordsEachDoc"};
    #             $TFIDF{$docno} = $docTermFreq{$docno}{$word} / $currTotalFreq * $IDF{$word};
    #         }
    #     }
    # }

    # foreach my $word (sort {$dft{$b} <=> $dft{$a}
    #     or $a cmp $b} keys %dft) {
    #     printf INDEX "%20s : %4d\n", $word, $dft{$word};
    # }

    ## tutup file
    close STOP;
    close DOCS;
    close INDEX;

    return %tft;
}

sub tokenize {
    my $splitKorpus = shift;
    my $hashKata    = shift;
    my $cft         = shift;
    my $stopwords   = shift;

    my $totalWordsEachDoc = 0;

    ## TOKENIZATION
    foreach my $kata (@$splitKorpus) {

        ## STOPWORDS REMOVAL
        # unless (exists($$stopwords{ $kata })) {

            ## STEMMING
            # my $rootKata = stem($kata);
            my $rootKata = $kata;

            ## hitung frekuensi tiap kata
            if (exists($$hashKata{ $rootKata })) {
                $$hashKata{ $rootKata } += 1;
            } else {
                $$hashKata{ $rootKata } = 1;
            }

            ## hitung frekuensi kata pada seluruh dokumen
            if (exists($$cft{ $rootKata })) {
                $$cft{ $rootKata } += 1;
            } else {
                $$cft{ $rootKata } = 1;
            }

            $totalWordsEachDoc += 1;
        # }
    }

    return $totalWordsEachDoc;
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
    my $choice = shift // 0;

    if ($choice eq 0) {
        return &prefixSuffixStem($word);
    } else {
        return &suffixPrefixStem($word);
    }
}

sub computeTfIdf {
    # body...
}

sub normalization {
    # body...
}
