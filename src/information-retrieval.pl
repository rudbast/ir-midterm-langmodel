#!/usr/bin/perl

use strict;
use warnings;

use feature "say";
use Data::Dumper qw (Dumper);


#### Main Program

my $doc = "../res/Koleksi.dat";
my $stw = "../res/stopwords-ina.dat";

my $res = "../out/hasil.txt";
my $index = "../out/indeks.txt";

## preprocessing
my %list = indexing($doc, $res, $index);

# print Dumper \%list;

say "selesai.";

####

sub tokenizing {
    $file = shift;

    open RESOURCE, $file or die "can't open resource file";

    close RESOURCE;
}

sub stopwords_removal {
    # body...
}

sub stemming {
    # body...
}

sub indexing {
    ## open dokumen awal
    open(FILE, "$_[0]") or die "can't open data source";

    ## open stopwords file
    open(STOP,"$_[3]") or die "can't open ";

    ## open file hasil reduksi
    open(RESULT, "> $_[1]") or die "can't open result file";

    ## open file indeks kata
    open(INDEX, "> $_[2]") or die "can't open index file";

    ## simpan list stopwords dalam hash
    # my %stopwords = ();

    # while(<STOP>) {
    #     chomp;
    #     $stopwords{$_} = 1;
    # }

    ## total kata muncul pada berapa dokumen
    my %termfreq = ();

    ## total banyaknya dokumen
    my $totalDoc = 0;

    ## frekuensi tiap docid - docno
    my %result = ();

    ## frekuensi per dokumen
    my %hashKata = ();

    ## nomor dokumen
    my $curr_doc_id;
    my $curr_doc_no;

    ## total banyaknya kata tiap dokumen
    my $totalWordsEachDoc = 0;

    while(<FILE>) {
        chomp;
        s/\s+/ /gi;

        ## update informasi docid
        if (/<DOCID>/) {
            s/<.*?>/ /gi;
            s/\s+/ /gi;
            s/^\s+//;
            s/\s+$//;

            ## inisialisasi ulang doc id baru
            $curr_doc_id = $_;
        }

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

        if (/<\/DOC>/) {
            ## simpan frekuensi tiap kata dalam tiap docid - docno
            $result{$curr_doc_id}{$curr_doc_no} = { %hashKata };
            ## simpan total banyaknya kata dalam tiap docid - docno
            $result{$curr_doc_id}{$curr_doc_no}{"totalWordsEachDoc"} = $totalWordsEachDoc;

            ## hitung frekuensi kemunculan kata untuk seluruh dokumen
            foreach my $kata (keys %hashKata) {
                if (exists($termfreq{$kata})) {
                    $termfreq{$kata} += 1;
                } else {
                    $termfreq{$kata} = 1;
                }
            }

            # say scalar keys %hashKata;
            # say $totalWordsEachDoc;

            ## kosongkan daftar frekuensi kata untuk dokumen selanjutnya
            %hashKata = ();
            $totalWordsEachDoc = 0;
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

            foreach my $kata(@splitKorpus) {
                ## cek kata apakah termasuk dalam list stopwords
                # unless (exists($stopwords{$kata})) {
                    if (exists($hashKata{$kata})) {
                        $hashKata{$kata} += 1;
                    } else {
                        $hashKata{$kata} = 1;
                    }
                # }
            }

            ## increment jumlah frekuensi kata dalam dokumen
            $totalWordsEachDoc += scalar @splitKorpus;
        }
    }

    ## hitung idf
    my %IDF = ();

    foreach my $word (keys %termfreq) {
        $IDF{$word} = $termfreq{$word} / $totalDoc;
    }

    ## hitung tf-idf
    foreach my $docid (sort keys %result) {
        foreach my $docno (sort keys %{ $result{$docid} }) {
            say RESULT "<DOCID> $docid </DOCID>";
            say RESULT "<DOCNO> $docno </DOCNO>";

            foreach my $word (sort keys %{ $result{$docid}{$docno} }) {
                if ($word ne "totalWordsEachDoc") {
                    my $currTotalFreq = $result{$docid}{$docno}{"totalWordsEachDoc"};
                    my $TFIDF = $result{$docid}{$docno}{$word} / $currTotalFreq * $IDF{$word};

                    printf RESULT "%20s : %.9f\n", $word, $TFIDF;
                }
            }

            say RESULT "";
        }
    }

    foreach my $word (sort {$termfreq{$b} <=> $termfreq{$a}
        or $a cmp $b} keys %termfreq) {
        printf INDEX "%20s : %4d\n", $word, $termfreq{$word};
    }

    ## tutup file
    # close STOP;
    close FILE;
    close RESULT;
    close INDEX;

    return %result;
}

sub computeTfIdf {
    # body...
}

sub normalization {
    # body...
}
