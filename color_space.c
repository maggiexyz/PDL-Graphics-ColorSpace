#include <stdio.h>
#include <math.h>

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
void    _mult_v3_m33( struct pixel *p, double *m0, double *m1, double *m2, double *result );


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
	*(hsl+2) = sum / 2;
	
	/* set up a greyscale if rgb values are identical */
	/* Note: automatically includes max = 0 */
	if (delta == 0) {
		*hsl = 0;
		*(hsl+1) = 0;
	}
	else {
		/* satuaration */
		if (*(hsl+2) <= 0.5) {
			*(hsl+1) = delta / sum;
		}
		else {
			*(hsl+1) = delta / (2 - sum);
		}
		
		/* compute hue */
		if (r == max) {
			*hsl = (g - b) / delta;
		}
		else if (g == max) {
			*hsl = 2 + (b - r) / delta;
		}
		else {
			*hsl = 4 + (r - g) / delta;
		}
		*hsl *= 60;
		if (*hsl < 0) *hsl += 360;
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
	return a >= 0?   pow(a, p) : -pow(-a, p);
}

void _mult_v3_m33( struct pixel *p, double *m0, double *m1, double *m2, double *result )
{
	*result     = p->a  *  *m0      +  p->b  *  *m1      +  p->c  *  *m2;
	*(result+1) = p->a  *  *(m0+1)  +  p->b  *  *(m1+1)  +  p->c  *  *(m2+1);
	*(result+2) = p->a  *  *(m0+2)  +  p->b  *  *(m1+2)  +  p->c  *  *(m2+2);
}




