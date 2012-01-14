use PDL::Core::Dev;
use ExtUtils::MakeMaker;
PDL::Core::Dev->import();

$package = ["color_space.pp",ColorSpace,PDL::Graphics::ColorSpace];
%hash = pdlpp_stdargs($package);
$hash{'OBJECT'} .= ' color_space$(OBJ_EXT)';
$hash{'clean'}{FILES} .= ' color_space$(OBJ_EXT)';
$hash{'PM'} = {
    'ColorSpace.pm'           => '$(INST_LIBDIR)/ColorSpace.pm',
    'ColorSpace/RGBSpace.pm'  => '$(INST_LIBDIR)/ColorSpace/RGBSpace.pm',
};

WriteMakefile( %hash );

sub MY::postamble {pdlpp_postamble($package)};
