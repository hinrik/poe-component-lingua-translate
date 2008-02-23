use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'POE::Component::Lingua::Translate',
    AUTHOR        => 'Hinrik Örn Sigurðsson <hinrik.sig@gmail.com>',
    ABSTRACT_FROM => 'lib/POE/Component/Lingua/Translate.pm',
    VERSION_FROM  => 'lib/POE/Component/Lingua/Translate.pm',
    LICENSE       => 'perl',
    PREREQ_PM     => {
        # lib/POE/Component/Lingua/Translate.pm
        'POE'                     => '0',
        'POE::Component::Generic' => '0',
        'Lingua::Translate'       => '0.08',

        # t/
        'Test::More' => '0',
    },
);
