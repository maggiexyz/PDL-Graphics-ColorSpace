#include <stdio.h>
#include <math.h>

#define epsilon   0.008856
#define kappa   903.3

struct pixel {
	double a;
	double b;
	double c;
};


/*** function defs ***/
double  rgb_quant( double p, double q, double h );
void    rgb2hsl( double *, double * );
void    rgb2xyz( double *rgb, double gamma, double *m0, double *m1, double *m2, double *xyz );
double  _apow( double a, double p );
double  _rad2deg( double rad );
double  _deg2rad( double deg );
void    _mult_v3_m33( struct pixel *p, double *m0, double *m1, double *m2, double *result );
void    xyY2xyz( double *xyY, double *xyz );
void    xyz2lab( double *xyz, double *w, double *lab );
void	lab2lch( double *lab, double *lch );
void    lch2lab( double *lch, double *lab );


/* ~~~~~~~~~~:> */
double rgb_quant( double p, double q, double h )
{
	while (h < 0)     { h += 360; }
	while (h >= 360 ) { h -= 360; }

	if (h < 60)       { return p + (q-p)*h/60; }
	else if (h < 180) { return q; }
	else if (h < 240) { return p + (q-p)*(240-h)/60; }
	else              { return p; }
}

void rgb2hsl( double *rgb, double *hsl )  {
    double r = *rgb;
    double g = *(rgb+1);
    double b = *(rgb+2);

	/* compute the min and max */
	double max = r;
	if (max < g) max = g;
	if (max < b) max = b;
	double min = r;
	if (g < min) min = g;
	if (b < min) min = b;
	
	/* Set the sum and delta */
	double delta = max - min;
	double sum   = max + min;

	/* luminance */
	*(hsl+2) = sum / 2.0;
	
	/* set up a greyscale if rgb values are identical */
	/* Note: automatically includes max = 0 */
	if (delta == 0.0) {
		*hsl = 0.0;
		*(hsl+1) = 0.0;
	}
	else {
		/* satuaration */
		if (*(hsl+2) <= 0.5) {
			*(hsl+1) = delta / sum;
		}
		else {
			*(hsl+1) = delta / (2.0 - sum);
		}
		
		/* compute hue */
		if (r == max) {
			*hsl = (g - b) / delta;
		}
		else if (g == max) {
			*hsl = 2.0 + (b - r) / delta;
		}
		else {
			*hsl = 4.0 + (r - g) / delta;
		}
		*hsl *= 60.0;
		if (*hsl < 0.0) *hsl += 360.0;
    }
}


void rgb2xyz( double *rgb, double gamma, double *m0, double *m1, double *m2, double *xyz )
{
	/* weighted RGB */
	struct pixel  p = { *rgb, *(rgb+1), *(rgb+2) };

	if (gamma < 0) {
		/* special case for sRGB gamma curve */
		if ( fabs(p.a) <= 0.04045 ) { p.a /= 12.92; }
		else { p.a =_apow( (p.a + 0.055)/1.055, 2.4 ); }

		if ( fabs(p.b) <= 0.04045 ) { p.b /= 12.92; }
		else { p.b =_apow( (p.b + 0.055)/1.055, 2.4 ); }

		if ( fabs(p.c) <= 0.04045 ) { p.c /= 12.92; }
		else { p.c =_apow( (p.c + 0.055)/1.055, 2.4 ); }
	}
	else {
		p.a = _apow(p.a, gamma);
		p.b = _apow(p.b, gamma);
		p.c = _apow(p.c, gamma);
	}

	_mult_v3_m33( &p, m0, m1, m2, xyz );
}


double _apow (double a, double p) {
	return a >= 0.0?   pow(a, p) : -pow(-a, p);
}

void _mult_v3_m33( struct pixel *p, double *m0, double *m1, double *m2, double *result )
{
	*result     = p->a  *  *m0      +  p->b  *  *m1      +  p->c  *  *m2;
	*(result+1) = p->a  *  *(m0+1)  +  p->b  *  *(m1+1)  +  p->c  *  *(m2+1);
	*(result+2) = p->a  *  *(m0+2)  +  p->b  *  *(m1+2)  +  p->c  *  *(m2+2);
}


void xyY2xyz( double *xyY, double *xyz )
{

	*(xyz+1) = *(xyY+2);

	if ( *(xyY+1) != 0.0 ) {
		*xyz     = *xyY  *  *(xyY+2)  /  *(xyY+1);
		*(xyz+2) = (1.0 - *xyY - *(xyY+1))  *  *(xyY+2)  /  *(xyY+1);
	}
	else {
		*xyz = *(xyz+1) = *(xyz+2) = 0.0;
	}
}


void xyz2lab( double *xyz, double *w, double *lab )
{
	double xr, yr, zr;

	xr = *xyz / *w;
	yr = *(xyz+1) / *(w+1);
	zr = *(xyz+2) / *(w+2);

	double fx, fy, fz;

	fx = (xr > epsilon)?  pow(xr, 1.0/3.0) : (kappa * xr + 16.0) / 116.0;
	fy = (yr > epsilon)?  pow(yr, 1.0/3.0) : (kappa * yr + 16.0) / 116.0;
	fz = (zr > epsilon)?  pow(zr, 1.0/3.0) : (kappa * zr + 16.0) / 116.0;

	*lab     = 116.0 * fy - 16.0;
	*(lab+1) = 500.0 * (fx - fy);
	*(lab+2) = 200.0 * (fy - fz);
}

void lab2lch( double *lab, double *lch )
{
	*lch = *lab;

	*(lch+1) = sqrt( pow(*(lab+1), 2) + pow(*(lab+2), 2) );
	*(lch+2) = _rad2deg( atan2( *(lab+2), *(lab+1) ) );

	while (*(lch+2) < 0.0)   { *(lch+2) += 360; }
	while (*(lch+2) > 360.0) { *(lch+2) -= 360; }
}

void lch2lab( double *lch, double *lab )
{
    /* l is set */
    *lab = *lch;

    double c = *(lch+1);
    double h = _deg2rad( *(lch+2) );
    double th = tan(h);

    double *a;
    double *b;

    a = lab+1;
    b = lab+2;

    *a = c / sqrt( pow(th,2) + 1 );
    *b = sqrt( pow(c, 2) - pow(*a, 2) );

    if (h < 0.0)
        h += 2*M_PI;
    if (h > M_PI/2 && h < M_PI*3/2)
        *a = -*a;
    if (h > M_PI)
        *b = -*b;
}


double _rad2deg( double rad )
{
	return 180.0 * rad / M_PI;
}

double _deg2rad( double deg )
{
    return deg * (M_PI / 180.0); 
}
