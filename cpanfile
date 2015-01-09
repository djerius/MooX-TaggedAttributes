requires 'Moo';
requires 'Class::Method::Modifiers';
requires 'Sub::Name';
requires 'namespace::clean';

on test => sub {

   requires 'Test::More';
   requires 'Test::Deep';

};

on develop => sub {

    requires 'Module::Install';
    requires 'Module::Install::AuthorRequires';
    requires 'Module::Install::AuthorTests';
    requires 'Module::Install::AutoLicense';
    requires 'Module::Install::CPANfile';

    requires 'Test::NoBreakpoints';
    requires 'Test::Pod';
    requires 'Test::Pod::Coverage';
    requires 'Test::Perl::Critic';

};
