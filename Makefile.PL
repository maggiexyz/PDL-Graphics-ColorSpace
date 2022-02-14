use strict;
use warnings;
use PDL::Core::Dev;
use ExtUtils::MakeMaker;

my $pack = [qw(color_space.pp ColorSpace PDL::Graphics::ColorSpace), undef, 1];
my %hash = pdlpp_stdargs($pack);
$hash{OBJECT} .= ' color_space$(OBJ_EXT)';
$hash{clean}{FILES} .= ' color_space$(OBJ_EXT)';

WriteMakefile( %hash,
    AUTHOR              => 'Maggie J. Xiong  <maggiexyz+github gmail.com>',
    PM => {
      'ColorSpace.pm'           => '$(INST_LIBDIR)/ColorSpace.pm',
      'ColorSpace/RGBSpace.pm'  => '$(INST_LIBDIR)/ColorSpace/RGBSpace.pm',
    },
    PREREQ_PM => {
        'Test::More' => 0,
        'PDL'        => '2.074', # multi-C etc
    },
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);

sub MY::postamble {pdlpp_postamble($pack)};
