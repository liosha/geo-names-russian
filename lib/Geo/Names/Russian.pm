#
# $Id$
#

use 5.010;
use strict;
use warnings;
use utf8;

package Geo::Names::Russian;
# ABSTRACT: parse and split russian geographical names

=head1 NAME

Geo::Names::Russian - parse and split russian geographical names

=head1 SYNOPSIS

    use Geo::Names::Russian qw{ :all };

    for my $street ( @streetnames )
        $count{ streetname_keystring( $street ) } ++;
    }

=cut


use base qw{ Exporter };

our @EXPORT_OK = qw{
    streetname_split
    streetname_keystring
    housenumber_keystring
};

our %EXPORT_TAGS = (
    all =>  \@EXPORT_OK,
);



use List::MoreUtils qw{ any first_index };



my @statuses = (
    [ 'улица'       =>  'ул'                ],
    [ 'переулок'    =>  'пер(?:еул)?'       ],
    [ 'проспект'    =>  'пр(?:-к?т|осп)'    ],
    [ 'проезд'      =>  'пр(?:-з?д)?'       ],
    [ 'площадь'     =>  'пл'                ],
    [ 'шоссе'       =>  'ш'                 ],
    [ 'тупик'       =>  'туп'               ],
    [ 'бульвар'     =>  'б(?:ул|ульв|-р)'   ],
    [ 'набережная'  =>  'наб'               ],
    [ 'аллея'       =>  'ал'                ],
    [ 'мост'        =>  'м'                 ],
    [ 'тракт'       =>  'тр'                ],
    [ 'просек'      =>  'прос'              ],
    [ 'линия'       =>  'лин'               ],
    [ 'квартал'     =>  'кв(?:арт)?'        ],
    [ 'микрорайон'  =>  'мк?рн?'            ],
    [ 'территория'  =>  'тер'               ],
    [ 'посёлок'     =>  'пос(?:[её]лок)?'   ],
    [ 'городок'     =>  'гор'               ],
    [ 'станция'     =>  'ст(?:анц)?'        ],
    [ 'хутор'       =>  'х(?:ут)'           ],
    [ 'разъезд'     =>  'р(?:аз)-д'         ],
);

for my $rec ( @statuses ) {
    $rec->[1] = qr{ ^ (?: $rec->[0] | $rec->[1] ) \.? $ }ixms;
}


my @addition_words = (
    [ 'Ниж'     =>  'НИЖН(?:\.|ИЙ|ОЕ|ЯЯ)'       ],
    [ 'Сред'    =>  'СР\.?|СРЕДН(?:\.|ИЙ|ЕЕ|ЯЯ)'],
    [ 'Верх'    =>  'ВЕРХН?(?:\.|ИЙ|ЕЕ|ЯЯ)'     ],
    [ 'Стар'    =>  'СТ\.?|СТАР(?:ЫЙ|АЯ|ОЕ|\.)' ],
    [ 'Нов'     =>  'НОВ(?:АЯ|ЫЙ|ОЕ|\.)'        ],
    [ 'Мал'     =>  'МАЛ(?:АЯ|ЫЙ|ОЕ|\.)'        ],
    [ 'Бол'     =>  'БОЛЬШ(?:АЯ|ОЙ|ОЕ|\.)'      ],
);

for my $rec ( @addition_words ) {
    $rec->[1] = qr{ ^ (?: $rec->[0] \.? | $rec->[1] ) $ }ixms;
}


my @prof_words = qw{
        академика архитектора
        адмирала генерала маршала
    };

=head1 FUNCTIONS    

=head2 streetname_split

Splits streetname into meaningful parts

    my $street = '2-я Тверская-Ямская ул.';
    my ( $status, $name, $addition, $number, $km ) = streetname_split( $street );
    #  ( 'улица', 'Тверская-Ямская', '', '2-я', '' )

=cut

sub streetname_split {

    my ( $name ) = @_;
    return unless $name;


    $name =~ s/ ( No? | № ) \s* (?=\d) /$1/gix; 

    # делим строку на слова
    my @words = grep {$_} split / \s+ | (?<=[.,]) \s* /x, $name;

    # прицепляем инициалы к фамилии
    for my $i ( reverse 0 .. $#words-1 ) {
        next unless $words[$i] =~ / ^ \p{IsUpper} \.? $ /xms;
        $words[$i] .= q{.} unless $words[$i] =~ /\.$/xms;
        $words[$i] .= splice @words, $i+1, 1;
    }
    # и переносим их в конец
    for my $word ( @words ) {
        $word =~ s/ ^ ( (?:\p{Alpha}\.)+ ) ( \p{Alpha}{3,} ) $ /$2 $1/xms;
    }

    # вытаскиваем километр
    my $km = q{};
    my $km_re = qr{ km | км | километр }xi;
    for my $i ( 1 .. $#words ) {
        if ( @words > 2  &&  $words[$i-1] =~ / ^ \d+ (?: -? \S{1,3} ) $ /xms  &&  $words[$i] =~ / ^ $km_re $ /xms ) {
            $km = join q{ }, splice @words, $i-1, 2;
            last;
        }
        if ( my @res = $words[$i] =~ / ^ (\d+) ($km_re) $ /xms ) {
            $km = join q{ }, @res;
            splice @words, $i, 1;
            last;
        }
    }

    # вычленяем статус
    my $status;
    if ( @words > 1 ) {
        for my $rec ( @statuses ) {
            my $i = first_index { $_ =~ $rec->[1] } @words;
            next if $i < 0;
            $status = $rec->[0];
            splice @words, $i, 1;
            last;
        }
    }
    
    # вытаскиваем правильно заданный номер
    my $number = q{};
    for my $i ( 0 .. $#words ) {
        next unless 
            ( !$status || $status =~ /[аяь]$/ixms ) && $words[$i] =~ m{ ^ \d{1,2} -? а?я $ }ixms        # женский род
            || $status && $status =~ /[е]$/ixms     && $words[$i] =~ m{ ^ \d{1,2} -? о?е $ }ixms        # средний
            || $status && $status =~ /[^еаяь]$/ixms && $words[$i] =~ m{ ^ \d{1,2} -? [ыио]?й $ }ixms;   # мужской
        $number = lc $words[$i];
        splice @words, $i, 1;
        last;
    }

    # пробуем вытащить кривой номер
    if ( @words > 1  &&  !$number  
            && $words[0]  =~ / ^ \d{1,2} $ /xms
            && $words[-1] =~ / (?: [ая]я | [ыи]й ) $ /xms ) {
        $number = shift @words;
    }
    if ( @words > 1  &&  !$number  
            && $words[-1] =~ / ^ \d{1,2} $ /xms
            && $words[-2] =~ / (?: [ая]я | [ыи]й ) $ /xms ) {
        $number = pop @words;
    }

    # вытаскиваем вспомогательные имена
    my @additions;
    for my $i ( reverse 0 .. $#words ) {
        last unless @words > 1;
        next unless any { $words[$i] =~ $_->[1] } @addition_words;
        push @additions, splice @words, $i, 1;
    }

    # и профессию
    my $i = first_index { my $w = lc $_; any { $w eq $_ } @prof_words } @words;
    if ( @words > 1 && $i >= 0 ) {
        unshift @additions, splice @words, $i, 1;
    }

    # статус по дефолту, если не нашли
    $status ||=  $words[-1] =~ /[ыи]й $/ix  ?  'переулок' : 'улица';

    return( $status, join( q{ }, @words ), join( q{ }, @additions ), $number, $km );
}


=head2 streetname_keystring

Returns unified keystring for street

    my $street = '2-й пр. Марьиной Рощи';
    my $key = streetname_keystring( $street );
    # 'ПРОЕЗД 2 МАРЬИНОЙ РОЩИ'

=cut

sub streetname_keystring {
    my ($street, $suburb) = @_;

    ( $suburb ||= q{} ) =~ s/^(дер|г|пос)[\.\s]+//i;
    return uc $suburb unless $street;

    my ( $status, $name, $addition, $number, $km ) = streetname_split( $street );

    ( $number ||= q{} ) =~ s/ - \S+ //xms;
    $name =~ s/ (?<=\d) - \S+ //xms;
    $name =~ s/ ^ (?: No? | № ) (?=\d) //xms;
    $name =~ s/ (?<=\p{IsAlpha}) \s+ (?=\p{IsUpper}\.) /_/gxms;

    if ( my ($n) = $km =~ / ^ (\d+) /xms ) {
        $km = "${n}км";
    }

    if ( $addition ||= q{} ) {
        for my $rec ( @addition_words ) {
            next unless $addition =~ $rec->[1];
            $addition = $rec->[0];
            last;
        }
    }

    my $result = join( q{ }, grep {$_}
                    uc($suburb || q{}),
                    uc($status), 
                    sort map {uc}
                        split( /\s+/, $name ),
                        split( /\s+/, $addition ),
                        $number, $km ) ;

    $result =~ s/Ё/Е/gi;
    return $result;
}

=head2 housenumber_keystring

Returns unified keystring for house

    my $house = '1А к3 с5';
    my $key = housenumber_keystring( $house );
    # '1АК3С5'

=cut

sub housenumber_keystring {

    my ( $name ) = @_;

    return q{} if $name eq q{};

    my $key  = uc $name;
    $key =~ s/[\. ]//g;
    $key =~ s/КОРП(?:УС)/К/gi;
    $key =~ s/СТР/С/gi;
    $key =~ s/k/К/gi;
    $key =~ s/c/С/gi;

    $key =~ s/^вл?\.?\s*(\d.*)/$1/i;

    return $key;
}




1;
