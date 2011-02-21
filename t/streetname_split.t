#!perl

use strict;
use utf8;

use Test::More  tests => 60;
use Geo::Names::Russian qw{ :all };

use Encode::Locale;
use Encode;

my @tests = (
    [ 'ул.Иванова'              => [ 'УЛИЦА',       'Иванова',      '',         '',     '' ]],
    [ 'Новая Кузнецовская пл'   => [ 'ПЛОЩАДЬ',     'Кузнецовская', 'Новая',    '',     '' ]],
    [ '2-й б-р Сидорова'        => [ 'БУЛЬВАР',     'Сидорова',     '',         '2-й',  '' ]],
    [ 'Лесная Нижн.'            => [ 'УЛИЦА',       'Лесная',       'Нижн.',    '',     '' ]],
    [ '7 Петровский 1673км'     => [ 'ПЕРЕУЛОК',    'Петровский',   '',         '7',    '1673 км' ]],
    [ '8 Марта 5-й километр'    => [ 'УЛИЦА',       '8 Марта',      '',         '',     '5-й километр' ]],
    [ '4-ая улица 8 Марта'      => [ 'УЛИЦА',       '8 Марта',      '',         '4-ая', '' ]],
    [ '9-й стрелковой дивизии'  => [ 'УЛИЦА',       '9-й стрелковой дивизии', '', '',   '' ]],
    [ 'Проектируемый проезд N 777' => [ 'ПРОЕЗД',   'Проектируемый N777', '',   '',     '' ]],
    [ 'В.Мухиной'               => [ 'УЛИЦА',       'Мухиной В.', '',           '',     '' ]],
    [ 'В.Красносельская'        => [ 'УЛИЦА',       'Красносельская', 'В.',   '',     '' ]],
    [ 'Адмирала Ш. М.Макарова'  => [ 'УЛИЦА',       'Макарова Ш.М.', 'Адмирала', '',    '' ]],
);


for my $test ( @tests ) {
    my @res = streetname_split( $test->[0] );
    is( lc($res[0]), lc($test->[1][0]), encode( 'console_out', "status $test->[0]" ) );
    is( lc($res[1]), lc($test->[1][1]), encode( 'console_out', "name $test->[0]" ) );
    is( lc($res[2]), lc($test->[1][2]), encode( 'console_out', "addition $test->[0]" ) );
    is( lc($res[3]), lc($test->[1][3]), encode( 'console_out', "number $test->[0]" ) );
    is( lc($res[4]), lc($test->[1][4]), encode( 'console_out', "km $test->[0]" ) );
}

