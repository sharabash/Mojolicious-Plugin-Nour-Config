package Mojolicious::Plugin::Nour::Config;
use Mojo::Base 'Mojolicious::Plugin';
use Nour::Config; has '_nour_config';
# ABSTRACT: Robustly imports config from a ./config sub-directory loaded with nested YAML files

sub register {
    my ( $self, $app, $opts ) = @_;
    my $helpers = delete $opts->{ '-helpers' };
    my $silence = delete $opts->{ '-silence' };

    $self->_nour_config( new Nour::Config ( %{ $opts } ) );

    if ( $helpers ) { # inherit some helpers from Nour::Base
        do { my $method = $_; eval qq|
        \$app->helper( $method => sub {
            my ( \$ctrl, \@args ) = \@_;
            return \$self->_nour_config->$method( \@args );
        } )| } for qw/path merge_hash write_yaml/;
    }

    my $config = $self->_nour_config->config;
    my $current = $app->defaults( config => $app->config )->config;
    %{ $current } = ( %{ $current }, %{ $config } );

    $app->log->debug( 'config', $app->dumper( $current ) ) unless $silence;

    return $current;
}

1;

=encoding utf-8

=head1 USAGE

Place your YAML configuration files under a ./config sub-directory from your mojo app's home directory.
There's an example in the package tarball you can look at, but roughly something like this:

     $ find ./config/
    ./config/
    ./config/application
    ./config/application/nested
    ./config/application/nested/example.yml
    ./config/application.yml
    ./config/database
    ./config/database/private
    ./config/database/private/production.yml
    ./config/database/private/README.md
    ./config/database/config.yml

Somewhere in your startup routine, include something like this:

    $self->plugin( 'Mojolicious::Plugin::Nour::Config', {
        -base => 'config'
        , -helpers => 1 # adds some unrelated helper methods i wrote
        , -silence => 1 # turning this on disables the config dump on startup in the debug log
    } );

On application startup, if you haven't turned the silence option on you can see your configuration from the debug log:

    [Tue Apr  8 12:10:21 2014] [debug] config
    {
      'application' => {
        'nested' => {
          'example' => {
            'wow' => 'amazing'
          }
        },
        'secret' => 'don\'t tell anyone'
      },
      'database' => {
        'default' => {
          'database' => 'production',
          'option' => {
            'AutoCommit' => '1',
            'PrintError' => '1',
            'RaiseError' => '1',
            'pg_bool_tf' => '0',
            'pg_enable_utf8' => '1'
          },
          'password' => 'nour',
          'username' => 'nour'
        },
        'development' => {
          'dsn' => 'dbi:Pg:dbname=nourdb_dev',
          'password' => 'sharabash',
          'username' => 'nour'
        },
        'production' => {
          'dsn' => 'dbi:Pg:dbname=nourdb_prod;host=secret.com',
          'password' => 'secret',
          'username' => 'override'
        }
      }
    }

Neat, right? Yeah.

=cut

