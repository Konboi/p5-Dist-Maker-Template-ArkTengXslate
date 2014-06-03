package Dist::Maker::Template::ArkTengXslate;

use 5.016;
use strict;
use warnings;

use Mouse;
use MouseX::StrictConstructor;

extends 'Dist::Maker::Base';
with    'Dist::Maker::Template';

sub dist_init {
}

sub distribution {

    return <<'DIST';

@@.gitignore
.*
!.gitkeep
!.gitignore
/carton.lock
/local/
/.carton/

*.swp
*.DS_Store

@@cpanfile
requires 'Ark', '1.20';
requires 'Teng';3

@@ lib/<: $dist.path :>.pm
package <: $dist.module :>;

use Ark;
use_model <: $dist.module :>::Models';
our $VERSION = '0.01';

1;

@@ root/content/index.tx

<!DOCTYPE html>
<html lang="ja">

<head>
<meta charset="utf-8">
<title></title>
</head>

<body>
<h1><: $title :></h1>

</body>
</html>

@@ lib/<: $dist.path :>/Models.pm
package <: $dist.module :>::Models;
use strict;
use warnings;
use Ark::Models '-base';
use Teng::Schema::Loader;
use String::CamelCase 'camelize';

use constant PROJECT_NAME => (split /::/, __PACKAGE__)[0];

register DB => sub {
    my $self = shift;
    my $cls = PROJECT_NAME."::DB";

    my $conf;

    $conf = $self->get('conf')->{database}{master}
        or die 'Require database config';

    $self->adaptor({
        class       => $cls,
        constructor => 'load',
        args        => {
            connect_info  => $conf,
        }
    });
};

autoloader qr/^DB::/ => sub {
    my ($self, $name) = @_;

    my $db = $self->get('DB');
    my $schema = $db->schema;

    for my $table (keys %{$schema->tables}) {
        my $kls = camelize $table;
        register "DB::${kls}" => sub {
            my $rs = $db->rs($table);
            $rs->{sth} = undef;
            $rs;
        };
    }
};

1;

@@ lib/<: $dist.path :>/Model/.gitkeep
 
@@ lib/<: $dist.path :>/Controller/.gitkeep
 
@@ lib/<: $dist.path :>/DB/.gitkeep
 
@@ lib/<: $dist.path :>/DB/Row/.gitkeep
 
@@ lib/<: $dist.path :>/DB/ResultSet/.gitkeep
gitkeep
 
@@ lib/<: $dist.path :>/View/.gitkeep

@@ lib/<: $dist.path :>/View/JSON.pm

package <: $dist.module :>::View::JSON;
use Ark 'View::JSON';

use JSON::XS;

has '+expose_stash' => default => 'json';
has '+json_driver'  => default => sub { JSON::XS->new };

__PACKAGE__->meta->make_immutable;


@@ t/.gitkeep
 
@@ README.md

# Dist::Maker::Template::ArkTengXslate

## Install

``````
$ cpanm Dist::Maker::Template::ArkTengXslate
``````

```
$ dim init MyApp ArkTengXslate
```
DIST
}

1;
__END__

=head1 NAME

Dist::Maker::Template::ArkTengXslate - Perl extension to do something

=head1 VERSION

This document describes Dist::Maker::Template::ArkTengXslate version 0.01.

=head1 SYNOPSIS

    use Dist::Maker::Template::ArkTengXslate;

=head1 DESCRIPTION

# TODO

=head1 INTERFACE

=head2 Functions

=head3 C<< hello() >>

# TODO

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

<<YOUR NAME HERE>> E<lt><<YOUR EMAIL ADDRESS HERE>>E<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2014, <<YOUR NAME HERE>>. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
