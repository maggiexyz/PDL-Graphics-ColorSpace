use strict;
use warnings;

use Test::More;

BEGIN {
	plan tests => 4;
}

use PDL::LiteF;
use PDL::Graphics::ColorSpace;

sub tapprox {
  my($a,$b, $eps) = @_;
  $eps ||= 1e-6;
  my $diff = abs($a-$b);
    # use max to make it perl scalar
  ref $diff eq 'PDL' and $diff = $diff->max;
  return $diff < $eps;
}

# rgb_to_hsl
{   
	my $rgb = pdl( [255,255,255],[0,0,0],[255,10,50],[1,48,199] );
	my $a   = rgb_to_hsl( $rgb / 255 );

	my $ans = pdl( [0,0,1], [0,0,0], [350.204081632653,1,0.519607843137255], [225.757575757576,0.99,0.392156862745098] );

	is( tapprox( sum(abs($a - $ans)), 0 ), 1, 'rgb_to_hsl' ) or diag($a, $ans);
}

# hsl_to_rgb
{
	my( $a, $ans );

	$a = hsl_to_rgb( pdl(0,0,1) );
	$ans = pdl(255, 255, 255);
	is( tapprox( sum(abs($a - $ans)), 0 ), 1 ) or diag($a, $ans);
	
	$a = hsl_to_rgb( pdl(0,0,0) );
	$ans = pdl(0, 0, 0);
	is( tapprox( sum(abs($a - $ans)), 0 ), 1 ) or diag($a, $ans);
	
	$a = hsl_to_rgb( pdl(350.204081632653, 1, 0.519607843137255) );
	$ans = pdl(255,10,50);
	is( tapprox( sum(abs($a - $ans)), 0 ), 1 ) or diag($a, $ans);
}
