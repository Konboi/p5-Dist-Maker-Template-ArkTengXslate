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
requires 'JSON::XS';
requires 'String::CamelCase';
requires 'Teng';

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

@@ dev.psgi
use 5.016;
use warnings;
use utf8;
use Plack::Builder;
use Plack::Middleware::Static;
use lib 'lib';
use <: $dist.module :>;

my $app = <: $dist.module :>->new;
$app->setup;

builder {
    enable 'Plack::Middleware::Static',
        path => qr{^/(js/|css/|swf/|images?/|imgs?/|static/|[^/]+\.[^/]+$)},
        root => $app->path_to('root')->stringify;
    $app->handler;
};


@@ lib/<: $dist.path :>.pm
package <: $dist.module :>;

use Ark;
use_model '<: $dist.module :>::Models';
our $VERSION = '0.01';

1;

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

@@ lib/<: $dist.path :>/Controller.pm

package <: $dist.module :>::Controller;
use Ark 'Controller';

sub error_404 :path :Args {
    my ($self, $c) = @_;
    $c->res->status(404);
    $c->res->body('404 Not Found');
}

sub index :Path {
    my ($self, $c) = @_;
    $c->stash->{title} = 'Ark Default Index by Xslate';
}

sub end :Private {
    my ($self, $c) = @_;

    unless ($c->res->body || ($c->res->status == 302)) {
        $c->forward($c->view('Xslate'));
    }

    unless ($c->res->content_type()) {
        $c->res->header('content-type' => 'text/html')
    }
}

__PACKAGE__->meta->make_immutable;

@@ lib/<: $dist.path :>/DB.pm

package <: $dist.module :>::DB;

use strict;
use warnings;
use utf8;

use parent 'Teng';

__PACKAGE__->load_plugin('Pager::MySQLFoundRows');
__PACKAGE__->load_plugin('Count');
__PACKAGE__->load_plugin('FindOrCreate');

1;

@@ lib/<: $dist.path :>/DB/.gitkeep
 
@@ lib/<: $dist.path :>/DB/Row/.gitkeep
 
@@ lib/<: $dist.path :>/DB/ResultSet/.gitkeep

@@ lib/<: $dist.path :>/Exteption.pm
package <: $dist.module :>::Exception;

use 5.016;
use warnings;
use utf8;
use parent 'Exception::Tiny';

use Class::Accessor::Lite (
    rw => [qw/ code log log_level/]
);

use throw {
    my $class = $_[0];

    if (@_ == 2 && ref $_[1] && $_[1]->isa('<: $dist.path :>::Exception')] {
       $_[1]->rethrow;
    }

    goto $class->can('SUPER::throw');

}

sub throwf {
    my $class  = shift;
    my $format = shift;

    my $message = sprintf($format, @_);
    @_ = ($class, $message);

    goto \&throw;
}


sub as_string {
    my ($self) = @_;
    state $consts = {reverse %{ <: $dist.path :>::ErrorConst->constants } };
    my $code = $self->code ? $self->code : $self->message;

    my $message;
    if (my $e = $consts->{$code}) {
        $message = $e;
    }
    else {
        $message = $self->message;
    }

    sprintf '%s at %s line %s.', $message, $self->file, $self->line;
}

1;

@@ lib/<: $dist.path :>/View/.gitkeep

@@ lib/<: $dist.path :>/View/JSON.pm

package <: $dist.module :>::View::JSON;
use Ark 'View::JSON';

use JSON::XS;

has '+expose_stash' => default => 'json';
has '+json_driver'  => default => sub { JSON::XS->new };

__PACKAGE__->meta->make_immutable;

@@ lib/<: $dist.path :>/View/Xslate.pm

package <: $dist.module :>::View::Xslate;
use utf8;
use Ark 'View::Xslate';
use <: $dist.module :>::View::Xslate::ContextFunctions;

sub BUILD {
    my $self = shift;

    my $function = <: $dist.module :>::View::Xslate::ContextFunctions->context_functions(sub {$self->context});

     $self->options({
         cache     => 1,
         function  => $function,
         module    => ['Text::Xslate::Bridge::Star'],
     });
}

1;

@@ lib/<: $dist.module :>/View/Xslate/ContextFunctions.pm

package <: $dist.module :>::View::Xslate::ContextFunctions;
use 5.016;
use warnings;
use utf8;

sub context_functions {
    my ($kls, $sub) = @_;

    return {
        link_for => sub {
            my $c = $sub->();
            return $c->link_for(@_);
        },
        asset => sub {
            my $c = $sub->();
            return $c->asset_url_with_query(@_);
        }
    };
}

1;

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
