#!usr/bin/perl -l

use strict;
use warnings;
use AnyEvent::HTTP;
use URI;
use DDP;
use Web::Query;

my $threads = 100;
my %vizited_urls = ();
my %page_sizes = ();
my $pages_size = 0;
my $run;
$AnyEvent::HTTP::MAX_PER_HOST = $threads;

=head
my $url = 'https://github.com/Nikolo/Technosfera-perl/tree/anosov-crawler/';
my $base = URI->new($url);
print $base;

my $rel = '../../../';
my $uri = URI->new_abs($rel, $base);
print $uri;

sub async {
    my $cb = pop;
    my $w;$w = AE::timer rand(0.1), 0, sub {
        undef $w;
        $cb->();
    };
    return;
}


my $cv = AE::cv;
my @array = 1..10;
my $i = 0;
my $next;
$next = sub {
    my $cur = $i++;
    if ($cur > $#array) {
        $cv->send;
        return
    }
    #print "Process $array[$cur]";
    async sub {
        #print "Processed $array[$cur]";
        $next->();
    };
};
$next->() for 1..3;
#$cv->send;
=cut
my $cv = AE::cv;
#my $url = 'https://github.com/Nikolo/Technosfera-perl/tree/anosov-crawler';
#my $url = 'https://github.com/Nikolo/Technosfera-perl/tree/anosov-crawler/viewer';
my $url = 'https://github.com/Nikolo/Technosfera-perl/tree/anosov-crawler/projects';
my @urls_to_vizit = ($url);
my $base = URI->new($url);
$" = "\n";

=h
my $finder = URI::Find->new(sub {
    my $uri = shift;
    print "Find urls in $uri";
    #my $rel = $uri;
    $uri = URI->new_abs($uri, $url);
    print "URI: ".$uri;
    if ($uri !~ /^$url/ or $vizited_urls{$uri}) {
        print "Not our url";
        return "";
    }
    else {
        print "OUR URI";
        push @uris, $uri;
    }

});
#$finder->find(\$text);
=cut

my $f;
$f = sub {
    my ($j, $elem) = @_;
    #print $i, $elem->attr('href');
    my $uri = URI->new_abs($elem->attr('href'), $base);
    #my $found_url = ;
    if ($uri !~ m|#| && $uri =~ /^$url/ && !$vizited_urls{$uri}) {
        print "BUILDED URL: ".$uri;
        push @urls_to_vizit, $uri;
        #$run->();
    }
};

my $get_head;
my $get_body;
$get_head = sub {
    my $url = shift;
    print "GET HEAD: ".$url;
    $cv->begin;
    http_head $url, sub {
            my ($body, $hdr) = @_;
            if ($hdr->{Status} == 200) {
                $vizited_urls{$url}++;
                if ($hdr->{"content-type"} =~ m|^text/html|) {
                    $get_body->($url);
                }
                else {
                    $run->();
                    $cv->end
                }
            }
            else {
                print "Fail_head: @$hdr{qw(Status Reason)}";
                $cv->end
            }
            #$cv->send;
        }
};

$get_body = sub {
    my $url = shift;
    print "GET BODY: ".$url;
    http_get $url, sub {
            my ($body, $hdr) = @_;
            if ($hdr->{Status} == 200) {
                my $cur_size = length $body;
                print "Success: ".$cur_size;
                $page_sizes{$url} = $cur_size;
                $pages_size += $cur_size;
                #$finder->find(\$body);
                my $q = wq( $body );
                $q->find( 'a' )->each($f);
                #print $body
            }
            else {
                print "Fail_get: @$hdr{qw(Status Reason)}";
            }
            $run->();
            $cv->end
            #$cv->send;
        }
};

sub min {
    my ($x, $y) = @_;
    return $x < @$y ? $x : @$y
}

$cv->begin;
my $i = 0;

$run = sub {
    print "-------------------\nINCREMENTING I";
    my $cur = $i++;
    if ($cur > $#urls_to_vizit || $i > 1000) {
        #--$i;
        return
    }
    if ($vizited_urls{$urls_to_vizit[$cur]}) {
        $i--;
        return
    }
    print "CUR POS: ".$cur;
    $cv->begin;
    $get_head->($urls_to_vizit[$cur]);
    #$run->();
    $cv->end;
    #print "ELEVEN: 11";
    print "URLS TO VIZIT: @urls_to_vizit";
    #$run->() for 1..min($threads, \@urls_to_vizit);
};
#$run->() for 1..$threads;
$run->() for @urls_to_vizit;
$cv->end;
$cv->recv;

#print "URLS TO VIZIT: @urls_to_vizit";

__DATA__

my $cv = AE::cv; $cv->begin;
my @array = 1..10; #URLs to vizit
my $i = 0;
my $next;
$next = sub {
    my $cur = $i++;
    return if $cur > $#array;
    print "Process $array[$cur]"; got url in queue
    $cv->begin;
    async sub { #perform url
        print "Processed $array[$cur]";
        $next->();
        $cv->end;
    };
};
$next->() for 1..3; 1..$threads
#$cv->send;
$cv->end;
$cv->recv;
