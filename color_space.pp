#!/usr/bin/perl

pp_add_exported('', 'hsl_to_rgb', 'rgb_to_hsl', 'rgb_to_xyz', 'xyY_to_xyz', 'xyz_to_lab', 'lab_to_lch', 'rgb_to_lch');

pp_addpm({At=>'Top'}, <<'EOD');

=head1 NAME

PDL::Graphics::ColorSpace


=head1 DESCRIPTION

Derived from Graphics::ColorObject (Izvorski & Reibenschuh, 2005). Converts between color spaces.

Often the conversion will return out-of-gamut values. Retaining out-of-gamut values allows chained conversions to be lossless and reverse conversions to produce the original values. You can clip the values to be within-gamut if necessary. Please check the specific color space for the gamut range.

=head1 COLOR SPACES

=head2 RGB

Red, green, and blue. Normalized to be in the range of [0,1]. If you have / need integer value between [0,255], divide or multiply the values by 255.

=head2 HSL

Hue, Saturation and Luminance (or brightness).

The HSL color space defines colors more naturally: Hue specifies the base color, the other two values then let you specify the saturation of that color and how bright the color should be.

Hue is specified here as degrees ranging from 0 to 360. There are 6 base colors:

	0	red
	60	yellow
	120	green
	180	cyan
	240	blue
	300	magenta
	360	red

Saturation specifies the distance from the middle of the color wheel. So a saturation value of 0 (0%) means "center of the wheel", i.e. a grey value, whereas a saturation value of 1 (100%) means "at the border of the wheel", where the color is fully saturated.

Luminance describes how "bright" the color is. 0 (0%) means 0 brightness and the color is black. 1 (100%) means maximum brightness and the color is white.

For more info see L<http://www.chaospro.de/documentation/html/paletteeditor/colorspace_hsl.htm>.

=head2 XYZ and xyY

=head2 Lab

=head2 LCH

This is possibly a little easier to comprehend than the Lab colour space, with which it shares several features. It is more correctly known as  L*C*H*.  Essentially it is in the form of a sphere. There are three axes; L* and C* and H°. 

The L* axis represents Lightness. This is vertical; from 0, which has no lightness (i.e. absolute black), at the bottom; through 50 in the middle, to 100 which is maximum lightness (i.e. absolute white) at the top.

The C* axis represents Chroma or "saturation". This ranges from 0 at the centre of the circle, which is completely unsaturated (i.e. a neutral grey, black or white) to 100 or more at the edge of the circle for very high Chroma (saturation) or "colour purity".

If we take a horizontal slice through the centre, we see a coloured circle. Around the edge of the circle we see every possible saturated colour, or Hue. This circular axis is known as H° for Hue. The units are in the form of degrees° (or angles), ranging from 0 (red) through 90 (yellow), 180 (green), 270 (blue) and back to 0. 

For more info see L<http://www.colourphil.co.uk/lab_lch_colour_space.html>.

=head1 SYNOPSIS

	use PDL::LiteF;
	use PDL::IO::Pic;
	use PDL::Graphics::ColorSpace;

	my $image_rgb = PDL->rpic('photo.jpg') if PDL->rpiccan('JPEG');

	# convert RGB value from [0,255] to [0,1]
	$image_rgb = $image_rgb->double / 255;

	my $image_xyz = $image_rgb->rgb_to_xyz( 'sRGB' );

Or

	my $image_xyz = rgb_to_xyz( $image_rgb, 'sRGB' );

=head1 OPTIONS

Some conversions require specifying the RGB space. Supported RGB space include (aliases in square brackets):

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


=cut

use strict;
use warnings;

use Carp;
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
	
	$rgb(m=>0) = rgb_quant(p, q, h+120);
	$rgb(m=>1) = rgb_quant(p, q, h);
	$rgb(m=>2) = rgb_quant(p, q, h-120);
};

pp_def('hsl_to_rgb',
    Pars => 'double hsl(n=3); double [o]rgb(m=3)',
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
		/* construct white point */
		double xyY[3] = { $w(d=>0), $w(d=>1), 1.0 };
		double xyz_white[3];
		xyY2xyz( &xyY, &xyz_white );

		threadloop %{
			/* First check for bad values */
			if ($ISBAD(xyz(c=>0)) || $ISBAD(xyz(c=>1)) || $ISBAD(xyz(c=>2))) {
				loop (c) %{
					$SETBAD(lab());
				%}
				/* skip to the next xyz triple */
			}
			else {
				xyz2lab( $P(xyz), &xyz_white, $P(lab) );
			}
		%}
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
    my ($rgb, $space) = @_;

	croak "Please specify RGB Space ('sRGB' for generic JPEG images)!"
		if !$space;

    my @m = pdl( $RGB_SPACE->{$space}{m} )->dog;

    return _rgb_to_xyz( $rgb, $RGB_SPACE->{$space}{gamma}, @m );
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

	croak "Please specify RGB Space ('sRGB' for generic JPEG images)!"
		if !$space;

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

	croak "Please specify RGB Space ('sRGB' for generic JPEG images)!"
		if !$space;

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
