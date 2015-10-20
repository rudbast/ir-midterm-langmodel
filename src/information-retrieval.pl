#!/usr/bin/perl

use strict;
use warnings;

use feature "say";
use Data::Dumper qw (Dumper);

use Stemmer qw ( prefixSuffixStem  suffixPrefixStem );

###############################################################################

main();

###############################################################################

=item main()

Main program.

=cut
sub main {
    ## File input & output path
    my $resourcePath = "./res";
    my $outputPath   = "./out";

    ## Input data
    my $doc          = "$resourcePath/test.dat";
    my $stw          = "$resourcePath/stopwords-ina.dat";

    ## Output data
    my $index        = "$outputPath/indeks.txt";

    my %stopwords = loadStopwords($stw);
    ## Hasil preprocessing dari data dokumen
    my %processed = preprocessDocument($doc, $index, \%stopwords);

    # $Data::Dumper::Sortkeys = 1;
    # print Dumper \%processed;

    test(\%stopwords, \%processed);

    say "\nselesai.";

    return;
}

=item loadStopwords()

Membuka file stopwords kemudian dimasukkan kedalam memory
dalam bentuk hash-array / dictionary kemudian mengembalikan
hash ke program utama / pemanggil.

=cut
sub loadStopwords {
    my $stop = shift;
    ## open file stopwords
    open STOPWORDS, "$stop" or die "can't open stopwords file";

    ## simpan list stopwords dalam hash
    my %stopwords = ();

    while (<STOPWORDS>) {
        chomp;
        $stopwords{ $_ } = 1;
    }

    close STOPWORDS;

    return %stopwords;
}

=item preprocessInput()

Preprocessing pada dokumen.

=cut
sub preprocessDocument {
    my $docs         = shift;
    my $file         = shift;
    my $refStopwords = shift;

    my %stopwords = %{ $refStopwords };

    ## open file input dokumen
    open DOCS, "$docs" or die "can't open resource file";

    ## open file indeks kata
    open INDEX, "> $file" or die "can't open index file";

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
            $dld += tokenize(\%stopwords, \%hashKata, \@splitKorpus, \%cft);
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

    ## PERHITUNGAN LANGUAGE MODEL

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
    ## container hasil p(t | Md) & smoothing
    my %p       = ();

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

            ## Rt = (1 / (1 + ft) * ft) / (1 + ft) ^ tft
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
    close DOCS;
    close INDEX;

    return %p;
}

=item tokenize()

Tahap tokenisasi pada fase preprocessing, mencakupi stopwords
removal & stemming.

=cut
sub tokenize {
    my $stopwords   = shift;
    my $hashKata    = shift;
    my $splitKorpus = shift;
    my $cft         = shift;

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


=item test()

Fase percobaan pada sistem, menerima input query kemudian melakukan
preprocessing dan menghitung relevansi dokumen.

=cut
sub test {
    my $refStopwords = shift;
    my $refProcessed = shift;

    ## input query
    print "Query ? ";
    chomp(my $query = <STDIN>);

    my @cleanQueries = preprocessQuery($refStopwords, $query);

    ## hitung hasil query
    my %result = computeLMQuery($refProcessed, \@cleanQueries);

    ## output hasil beserta kesimpulan
    outputTestResult(\%result);
}

=item preprocessQuery()

Tahap preprocessing pada input query, mencakupi proses tokenisasi,
stopwords removal dan stemming.

=cut
sub preprocessQuery {
    my $refStopwords = shift;
    my $query        = shift;

    my %stopwords    = %{ $refStopwords };
    ## TOKENIZATION
    my @queries = split /\s+/, $query;

    ## container hasil preprocessing terhadap query
    my @cleanQueries = ();

    foreach my $query (@queries) {
        ## STOPWORDS REMOVAL
        unless (exists($stopwords{ $query })) {
            ## STEMMING
            push @cleanQueries, stem($query);
        }
    }

    return @cleanQueries;
}

=item computeLMQuery()

Perhitungan query similarity dengan Language Model.

=cut
sub computeLMQuery {
    my $refData    = shift;
    my $refQueries = shift;

    my %data    = %{ $refData };
    my @queries = @{ $refQueries };

    my %result = ();

    foreach my $doc (keys %data) {

        ## container untuk hasil kali dari p(t | Md)
        my $include = 1;
        ## container untuk hasil kali dari 1 - p(t | Md)
        my $inverse = 1;

        foreach my $word (keys $data{ $doc }) {
            ## counter untuk mengecek apakah kata yang diproses
            ## sekarang termasuk dalam query yang di input
            my $check = 0;

            foreach my $query (@queries) {
                ## cek apakah yang dicocokan berada dalam query
                if ($query eq $word) {
                    $include *= $data{ $doc }{ $word };

                    ## berhenti mengecek query lainnya jika kata
                    ## yang diproses sudah termasuk dalam query
                    last;
                } else {
                    $check += 1;
                }
            }

            ## kata tidak termasuk dalam query
            if ($check eq scalar @queries) {
                $inverse *= (1 - $data{ $doc }{ $word });
            }
        }

        ## simpan hasil perhitungan similarity per dokumen
        $result{ $doc } = $include * $inverse;
    }

    return %result;
}

=item outpuTestResult()

Output hasil test diurutkan berdasarkan relevansi.

=cut
sub outputTestResult {
    my $refResult = shift;

    my %result = %{ $refResult };

    say "";
    say ":: Hasil Perhitungan dengan Language Model ::";
    say "";

    foreach my $doc (sort {$result{ $b } <=> $result{ $a }} keys %result) {
        printf "%5s : %2.9f\n", $doc, $result{ $doc };
    }

    say "";
    say "* p.s: dokumen diurutkan berdasarkan relevansi dengan query."
}

sub normalization {
    # body...
}

=item clearScreen()

Simulasi pembersihan layar dengan karakter \n (newline).

=cut
sub clearScreen {
    print "\n" * 60;
}
