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

my %result = preprocess($doc, $index, $stw);

$Data::Dumper::Sortkeys = 1;
print Dumper \%result;

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
    my %dft         = ();

    ## total frekuensi kata pada seluruh dokumen
    my %cft         = ();

    ## total banyaknya kata pada seluruh dokumen
    my $cs          = 0;

    ## frekuensi tiap dokumen (DOCNO)
    my %docTermFreq = ();

    ## frekuensi per dokumen
    my %hashKata    = ();

    ## nomor dokumen
    my $curr_doc_no;

    ## total banyaknya kata tiap dokumen
    my $dld = 0;

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
            $dld += tokenize(\@splitKorpus, \%hashKata, \%cft, \%stopwords);
        }

        if (/<\/DOC>/) {
            ## simpan frekuensi tiap kata dalam tiap docno
            $docTermFreq{ $curr_doc_no } = { %hashKata };
            ## simpan total banyaknya kata dalam tiap docno
            $docTermFreq{ $curr_doc_no }{ "dld" } = $dld;
            ## simpan total banyaknya kata pada seluruh dokumen
            $cs += $dld;

            ## hitung frekuensi kemunculan kata pada berapa bayak dokumen
            foreach my $kata (keys %hashKata) {
                if (exists($dft{ $kata })) {
                    $dft{ $kata } += 1;
                } else {
                    $dft{ $kata } = 1;
                }
            }

            ## kosongkan daftar frekuensi kata untuk dokumen selanjutnya
            %hashKata = ();
            $dld = 0;
        }
    }

    ## container hasil hitung tft tiap dokumen
    my %tft = ();

    ## hitung tft
    foreach my $word (keys %dft) {
        foreach my $doc (keys %docTermFreq) {
            if (exists($docTermFreq{ $doc }{ $word })) {
                $tft{ $doc }{ $word } = $docTermFreq{ $doc }{ $word };
            } else {
                $tft{ $doc }{ $word } = 0;
            }
        }
    }

    ## container hasil hitung pml(t | Md) tiap dokumen
    my %pml     = ();
    ## container hasil hitung pavg
    my %pavg    = ();
    ## container hasil hitung ft tiap dokumen
    my %ft      = ();
    ## container hasil hitung R t tiap dokumen
    my %Rt      = ();
    ## container hasil p(t | Md)
    my %p       = ();
    ## container hasil smoothing

    foreach my $word (keys %dft) {
        my $avg = 0;

        ## hitung pml(t | Md)
        foreach my $doc (keys %docTermFreq) {
            my $dld = $docTermFreq{ $doc }{ "dld" };

            ## pml(t | Md) = tft / dld
            $pml{ $doc }{ $word } = $tft{ $doc }{ $word } / $dld;

            $avg += $pml{ $doc }{ $word };
        }

        ## pavg = avg(pml(d1, d2, d3)) / dft
        $pavg{ $word } = $avg / $dft{ $word };

        ## hitung ft, Rt, p(t | Md)
        foreach my $doc (keys %docTermFreq) {
            my $dld = $docTermFreq{ $doc }{ "dld" };

            ## ft = pavg * dld
            $ft{ $doc }{ $word } = $pavg{ $word } * $dld;

            my $currFt  = $ft{ $doc }{ $word };
            my $currTft = $tft{ $doc }{ $word };

            ## Rt = (1 / (1 + ft) * ft / (1 + ft)) ^ tft
            $Rt{ $doc }{ $word } = (1 / (1 + $currFt ) * $currFt / (1 + $currFt)) ** $currTft;

            my $currPml  = $pml{ $doc }{ $word };
            my $currRt   = $Rt{ $doc }{ $word };
            my $currPavg = $pavg{ $word };

            ## p(t | Md) = pml ^ (1 - Rt) * pavg ^ Rt
            if ($currPml eq 0) {
                ## kasus khusus ketika currPml 0, maka akan terjadi pemangkatan
                ## 0 dengan angka lain (Cth: 0^x)
                # $p{ $doc }{ $word } = $currPml;
                ## smoothing untuk nilai 0, = cft / cs
                $p{ $doc }{ $word } = $cft{ $word } / $cs;
            } else {
                $p{ $doc }{ $word } = ($currPml ** (1 - $currRt)) * ($currPavg ** $currRt);
            }
        }
    }

    ## tutup file
    close STOP;
    close DOCS;
    close INDEX;

    return %p;
}

sub tokenize {
    my $splitKorpus = shift;
    my $hashKata    = shift;
    my $cft         = shift;
    my $stopwords   = shift;

    ## Total banyaknya kata dalam suatu dokumen
    my $dld = 0;

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

            $dld += 1;
        # }
    }

    return $dld;
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
