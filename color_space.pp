#!/usr/bin/perl

pp_add_exported('', 'hsl_to_rgb', 'rgb_to_hsl', 'rgb_to_xyz', 'xyY_to_xyz', 'xyz_to_lab', 'lab_to_lch', 'rgb_to_lch');

pp_addpm({At=>'Top'}, <<'EOD');

=head1 NAME

PDL::Graphics::ColorSpace


=head1 DESCRIPTION

Derived from Graphics::ColorObject (Izvorski & Reibenschuh, 2005). Converts between color spaces. Some conversions require specifying the RGB space. Supported RGB space include (aliases in square brackets):

	Adobe RGB (1998) [Adobe]
	Apple RGB [Apple]
	BestRGB
	Beta RGB
	BruceRGB
	CIE
	ColorMatch
	DonRGB4
	ECI
	Ekta Space PS5
	NTSC [601] [CIE Rec 601]
	PAL/SECAM [PAL] [CIE ITU]
	ProPhoto
	SMPTE-C [SMPTE]
	WideGamut
	sRGB [709] [CIE Rec 709]


=head1 SYNOPSIS

	use PDL::LiteF;
	use PDL::IO::Pic;
	use PDL::Graphics::ColorSpace;

	my $image_rgb = PDL->rpic('photo.jpg') if PDL->rpiccan('JPEG');
	my $image_xyz = $image_rgb->rgb_to_xyz( 'sRGB' );

Or

	my $image_xyz = rgb_to_xyz( $image_rgb, 'sRGB' );


=cut

use strict;
use warnings;

use PDL::LiteF;
use PDL::Graphics::ColorSpace::RGBSpace;

$PDL::onlinedoc->scan(__FILE__) if $PDL::onlinedoc;

my $RGB_SPACE   = $PDL::Graphics::ColorSpace::RGBSpace::RGB_SPACE;
my $WHITE_POINT = $PDL::Graphics::ColorSpace::RGBSpace::WHITE_POINT;



EOD

pp_addhdr('
#include <math.h>
#include "color_space.h"  /* Local decs */
'
);

my $hsl_to_rgb_code = q{
	h = $hsl(n=>0);
	s = $hsl(n=>1);
	l = $hsl(n=>2);

	if ( l <= 0.5) {
		p = l*(1 - s);
		q = 2*l - p;
	}
	else {
		q = l + s - (l*s);
		p = 2*l - q;
	}
	
	$rgb(m=>0) = round( rgb_quant(p, q, h+120) * 255 );
	$rgb(m=>1) = round( rgb_quant(p, q, h) * 255 );
	$rgb(m=>2) = round( rgb_quant(p, q, h-120) * 255 );
};

pp_def('hsl_to_rgb',
    Pars => 'float+ hsl(n=3); int [o]rgb(m=3)',
    Code => q[
        $GENERIC(hsl) h, s, l, p, q;
        
        threadloop %{
            ] . $hsl_to_rgb_code . q[
        %}
    ],
    HandleBad => 1,
    BadCode => q[
        $GENERIC(hsl) h, s, l, p, q;
        
        threadloop %{
            /* First check for bad values */
            if ($ISBAD(hsl(n=>0)) || $ISBAD(hsl(n=>1)) || $ISBAD(hsl(n=>2))) {
                loop (m) %{
                    $SETBAD(rgb());
                %}
                /* skip to the next hsl triple */
            }
            else {
            ] . $hsl_to_rgb_code . q[
            }
        %}
    ],

    Doc => <<DOCUMENTATION,

=pod

=for ref

Converts an HSL color triple to an RGB color triple

HSL stands for hue-saturation-Lightness and is nicely represented by a cirle in a color palette. In this representation, the numbers representing saturation and value must be between 0 and 1; anything less than zero or greater than 1 will be truncated to the closest limit. The hue must be a value between 0 and 360, and again it will be truncated to the corresponding limit if that is not the case. For more information about HSL, see L<http://en.wikipedia.org/wiki/HSL_and_HSL>.

The first dimension of the piddles holding the hsl and rgb values must be size 3, i.e. the dimensions must look like (3, m, n, ...).

=cut

DOCUMENTATION
    BadDoc => <<BADDOC,

=for bad

If C<hsl_to_rgb> encounters a bad value in any of the H, S, or V quantities, the output piddle will be marked as bad and the associated R, G, and B color values will all be marked as bad.

=cut

BADDOC
);


pp_def('rgb_to_hsl',
    Pars => 'double rgb(n=3); double [o]hsl(m=3)',
    Code => '
        rgb2hsl($P(rgb), $P(hsl));
    ',

    HandleBad => 1,
    BadCode => '
        /* First check for bad values */
        if ($ISBAD(rgb(n=>0)) || $ISBAD(rgb(n=>1)) || $ISBAD(rgb(n=>2))) {
            loop (m) %{
                $SETBAD(hsl());
            %}
            /* skip to the next hsl triple */
        }
        else {
            rgb2hsl($P(rgb), $P(hsl));
        }
    ',

    Doc => <<DOCUMENTATION,

=pod

=for ref

Converts an RGB color triple to an HSL color triple.

HSL stands for hue-saturation-lightness and is nicely represented by a cirle in a color palette. In this representation, the numbers representing saturation and lightness will run between 0 and 1. The hue will be a value between 0 and 360. For more information about HSL, see L<http://en.wikipedia.org/wiki/HSL_and_HSL>.

The first dimension of the piddles holding the hsl and rgb values must be size 3, i.e. the dimensions must look like (3, m, n, ...).

=cut

DOCUMENTATION
    BadDoc => <<BADDOC,

=for bad

If C<rgb_to_hsl> encounters a bad value in any of the R, G, or B values the output piddle will be marked as bad and the associated H, S, and L values will all be marked as bad.

=cut

BADDOC
);

pp_def('xyY_to_xyz',
    Pars => 'double xyY(c=3); double [o]xyz(c=3)',
    Code => '
		xyY2xyz($P(xyY), $P(xyz));
    ',

    HandleBad => 1,
    BadCode => '
        /* First check for bad values */
        if ($ISBAD(xyY(c=>0)) || $ISBAD(xyY(c=>1)) || $ISBAD(xyY(c=>2))) {
            loop (c) %{
                $SETBAD(xyz());
            %}
            /* skip to the next hsl triple */
        }
        else {
			xyY2xyz($P(xyY), $P(xyz));
        }
    ',
);


pp_def('_rgb_to_xyz',
    Pars => 'double rgb(c=3); double gamma(); double l(i=3); double m(i=3); double n(i=3); double [o]xyz(c=3)',
    Code => '
        rgb2xyz($P(rgb), $gamma(), $P(l), $P(m), $P(n), $P(xyz));
    ',

    HandleBad => 1,
    BadCode => '
        /* First check for bad values */
        if ($ISBAD(rgb(c=>0)) || $ISBAD(rgb(c=>1)) || $ISBAD(rgb(c=>2))) {
            loop (c) %{
                $SETBAD(xyz());
            %}
            /* skip to the next xyz triple */
        }
        else {
        	rgb2xyz($P(rgb), $gamma(), $P(l), $P(m), $P(n), $P(xyz));
        }
    ',
	Doc => undef,
);


pp_def('_xyz_to_lab',
    Pars => 'double xyz(c=3); double w(d=2);  double [o]lab(c=3)',
    Code => '
		/* construct white point */
		double xyY[3] = { $w(d=>0), $w(d=>1), 1.0 };
		double xyz_white[3];
		xyY2xyz( &xyY, &xyz_white );

		threadloop %{
	        xyz2lab( $P(xyz), &xyz_white, $P(lab) );
		%}
    ',
	Doc => undef,

    HandleBad => 1,
    BadCode => '
        /* First check for bad values */
        if ($ISBAD(xyz(c=>0)) || $ISBAD(xyz(c=>1)) || $ISBAD(xyz(c=>2))) {
            loop (c) %{
                $SETBAD(lab());
            %}
            /* skip to the next xyz triple */
        }
        else {
			/* construct white point */
			double xyY[3] = { $w(d=>0), $w(d=>1), 1.0 };
			double xyz_white[3];
			xyY2xyz( &xyY, &xyz_white );

			threadloop %{
				xyz2lab( $P(xyz), &xyz_white, $P(lab) );
			%}
        }
    ',
);


pp_def('lab_to_lch',
    Pars => 'double lab(c=3); double [o]lch(c=3)',
    Code => '
		lab2lch( $P(lab), $P(lch) );
    ',

    HandleBad => 1,
    BadCode => '
        /* First check for bad values */
        if ($ISBAD(lab(c=>0)) || $ISBAD(lab(c=>1)) || $ISBAD(lab(c=>2))) {
            loop (c) %{
                $SETBAD(lch());
            %}
            /* skip to the next lch triple */
        }
        else {
			lab2lch( $P(lab), $P(lch) );
        }
    ',
    Doc => <<DOCUMENTATION,

=pod

=for ref

Converts an Lab color triple to an LCH color triple.

LCH stands for lightness-chroma-hue and is nicely represented by a sphere in a color palette. In this representation, the numbers representing lightness and chroma should be between 0 and 100. The hue will be a value between 0 and 360. For more information about LCH, see L<http://www.colourphil.co.uk/lab_lch_colour_space.html>.

The first dimension of the piddles holding the hsl and rgb values must be size 3, i.e. the dimensions must look like (3, m, n, ...).

=cut

DOCUMENTATION
    BadDoc => <<BADDOC,

=for bad

If C<lab_to_lch> encounters a bad value in any of the L, a, or b values the output piddle will be marked as bad and the associated L, C, and H values will all be marked as bad.

=cut

BADDOC
);



pp_addpm(<<'EOD');


=head2 rgb_to_xyz

=for ref

Converts an RGB color triple to an XYZ color triple.

The first dimension of the piddles holding the rgb and xyz values must be size 3, i.e. the dimensions must look like (3, m, n, ...).

=for bad

If C<rgb_to_xyz> encounters a bad value in any of the R, G, or B values the output piddle will be marked as bad and the associated X, Y, and Z values will all be marked as bad.

=for usage

Usage:

	my $xyz = rgb_to_xyz( $rgb, 'sRGB' );

=cut

*rgb_to_xyz = \&PDL::rgb_to_xyz;
sub PDL::rgb_to_xyz {
    my ($rgb, $s) = @_;

    my @m = pdl( $RGB_SPACE->{$s}{m} )->dog;

    return _rgb_to_xyz( $rgb, $RGB_SPACE->{$s}{gamma}, @m );
}


=head2 xyz_to_lab

=for ref

Converts an XYZ color triple to an Lab color triple.

A Lab color space is a color-opponent space with dimension L for lightness and a and b for the color-opponent dimensions, based on nonlinearly compressed CIE XYZ color space coordinates.

The first dimension of the piddles holding the xyz values must be size 3, i.e. the dimensions must look like (3, m, n, ...).

=for bad

If C<xyz_to_lab> encounters a bad value in any of the X, Y, or Z values the output piddle will be marked as bad and the associated L, a, and b values will all be marked as bad.

=for usage

Usage:

	my $lab = xyz_to_lab( $xyz, 'sRGB' );

=cut

*xyz_to_lab = \&PDL::xyz_to_lab;
sub PDL::xyz_to_lab {
	my ($xyz, $space) = @_;

	my $w = pdl $WHITE_POINT->{ $RGB_SPACE->{$space}{white_point} };

	return _xyz_to_lab( $xyz, $w );
}


=head2 rgb_to_lch

=for ref

Converts an RGB color triple to an LCH color triple.

The first dimension of the piddles holding the rgb values must be size 3, i.e. the dimensions must look like (3, m, n, ...).

=for bad

If C<rgb_to_lch> encounters a bad value in any of the R, G, or B values the output piddle will be marked as bad and the associated L, C, and H values will all be marked as bad.

=for usage

Usage:

	my $lch = rgb_to_lch( $rgb, 'sRGB' );

=cut

*rgb_to_lch = \&PDL::rgb_to_lch;
sub PDL::rgb_to_lch {
	my ($rgb, $space) = @_;

	my $lab = xyz_to_lab( rgb_to_xyz( $rgb, $space ), $space );

	return lab_to_lch( $lab );
}



=head1 SEE ALSO

Graphics::ColorObject

=head1 AUTHOR

Copyright (C) 2012 Maggie J. Xiong <maggiexyz+github@gmail.com>

All rights reserved. There is no warranty. You are allowed to redistribute this software / documentation as described in the file COPYING in the PDL distribution.

=cut

EOD

pp_done();
