/* prototypes of functions in color_space.c */
double  rgb_quant( double p, double q, double h );
void    rgb2hsl( double *, double * );
void    rgb2xyz( double *rgb, double gamma, double *m0, double *m1, double *m2, double *xyz );
void    xyY2xyz( double *xyY, double *xyz );
void    xyz2lab( double *xyz, double *w, double *lab );
void    lab2lch( double *lab, double *lch );
void    lch2lab( double *lch, double *lab );
