use strict;
use warnings;

use Test::More;

use PDL::LiteF;
use PDL::NiceSlice;
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

	$a = hsl_to_rgb( pdl([0,0,1], [0,0,0], [350.204081632653, 1, 0.519607843137255]) );
	$ans = pdl([255, 255, 255], [0,0,0], [255,10,50]) / 255;
	is( tapprox( sum(abs($a - $ans)), 0 ), 1, 'hsl_to_rgb' ) or diag($a, $ans);
}

# rgb_to_xyz
{   
	my $rgb = pdl( [255,255,255],[0,0,0],[255,10,50],[1,48,199] );
	my $a   = rgb_to_xyz( $rgb / 255, 'sRGB' );

	my $ans = pdl( [0.950467757575757, 1, 1.08897436363636],
		           [0,0,0],
		           [0.419265223936783, 0.217129144548417, 0.0500096992920757],
		           [0.113762127389896, 0.0624295703768394, 0.546353858701224] );

	is( tapprox( sum(abs($a - $ans)), 0 ), 1, 'rgb_to_xyz sRGB' ) or diag($a, $ans);

	$rgb = pdl(255, 10, 50);
	$a = rgb_to_xyz( $rgb/255, 'Adobe' );
	$ans = pdl( 0.582073320819542, 0.299955362786115, 0.0546021884576833 ); 
	is( tapprox( sum(abs($a - $ans)), 0 ), 1, 'rgb_to_xyz Adobe' ) or diag($a, $ans);
}

# xyY_to_xyz
{
	my $xyY = pdl(0.312713, 0.329016, 1);
	my $a   = xyY_to_xyz($xyY);
	my $ans = pdl(0.950449218275099, 1, 1.08891664843047);
	is( tapprox( sum(abs($a - $ans)), 0 ), 1, 'xyY_to_xyz' ) or diag($a, $ans);
}

# xyz_to_lab
{
	my $xyz = pdl([0.4, 0.2, 0.02], [0,0,1]);
	my $a   = $xyz->xyz_to_lab('sRGB');
	my $ans = pdl([51.8372115265385, 82.2953523409701, 64.1921650722979], [0,0,-166.814773017556]);
	is( tapprox( sum(abs($a - $ans)), 0 ), 1, 'xyz_to_lab sRGB' ) or diag($a, $ans);

	$xyz->setbadat(0,1);
	$a   = $xyz->xyz_to_lab('sRGB');
	is( tapprox( sum(abs($a - $ans)), 0 ), 1, 'xyz_to_lab sRGB with bad value' ) or diag($a, $ans);
}

# lab_to_lch
{
	my $lab = pdl([53.380244, 79.817473, 64.822569], [0,0,1]);
	my $a   = lab_to_lch($lab);
	my $ans = pdl([53.380244, 102.824094685368, 39.081262060261], [0,1,90]);
	is( tapprox( sum(abs($a - $ans)), 0 ), 1, 'lab_to_lch' ) or diag($a, $ans);
}

# rgb_to_lch
{
	my $rgb = pdl([25, 10, 243], [0,0,1]) / 255;
	my $a   = rgb_to_lch($rgb, 'sRGB');
	my $ans = pdl([31.5634666908367, 126.828356633829, 306.221274674578],
		          [ 0.0197916632671635, 0.403227926549451, 290.177020167939 ]);
	is( tapprox( sum(abs($a - $ans)), 0 ), 1, 'rgb_to_lch sRGB' ) or diag($a, $ans);

	$rgb->setbadat(1,1);
	$a = $rgb->rgb_to_lch('sRGB');
	is( tapprox( sum(abs($a - $ans)), 0 ), 1, 'rgb_to_lch sRGB with bad value' ) or diag($a, $ans);
}

done_testing();
