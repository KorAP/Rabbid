![Rabbid](https://raw.githubusercontent.com/KorAP/Rabbid/master/dev/demo/img/rabbid.png)

Rabbid is a rapid application development environment for
[KorAP Corpus Analysis Platform](http://korap.ids-mannheim.de/)
and used in production for the collection of textual examples for lexicographic work.

![Rabbid Screenshot](https://raw.githubusercontent.com/KorAP/Rabbid/master/dev/demo/img/screenshot.png)

**! This software is in its early stages and not stable yet! Use it on your own risk!**

## INSTALLATION

### Setup

To fetch the latest version of Rabbid ...

```
$ git clone https://github.com/KorAP/Rabbid
$ cd Rabbid
```

### Generate Static Asset Files

To generate the static asset files (scripts, styles, images ...),
you need NodeJS > 0.8. This will probably need administration
rights.

```
$ npm install
$ grunt
```

### Install Perl Dependencies

Rabbid uses the [Mojolicious](http://mojolicio.us/) framework,
that expects a Perl version of at least 5.10.1.
The recommended environment is based on [Perlbrew](http://perlbrew.pl/)
with [App::cpanminus](http://search.cpan.org/~miyagawa/App-cpanminus/).

Some perl modules are not on CPAN yet, so you need to install them from GitHub.
The easiest way to do this is using
[App::cpanminus](http://search.cpan.org/~miyagawa/App-cpanminus/).
This will probably need administration rights.

```
$ cpanm git://github.com/Akron/DBIx-Oro.git
$ cpanm git://github.com/Akron/Mojolicious-Plugin-Oro.git
$ cpanm git://github.com/Akron/Mojolicious-Plugin-Oro-Viewer.git
```

Then install the dependencies as always and run the test suite.
There is no need to install Rabbid on your system.

```
$ perl Makefile.PL
$ make test
```

### Start Example Server

First import the example corpus from ```t/example/```:

```
$ perl script/rabbid rabbid_import -c example -d t/example
```

Rabbid can then be deployed like all
[Mojolicious apps](http://mojolicio.us/perldoc/Mojolicious/Guides/Cookbook#DEPLOYMENT).
The easiest way is to start the built-in server:

```
$ perl script/rabbid daemon
```

Rabbid will then be available at *localhost:3000* in your browser.

## COPYRIGHT AND LICENSE

### Bundled Software

[ALERTIFY.js](https://fabien-d.github.io/alertify.js/)
is released under the terms of the MIT License.
[Almond](https://github.com/jrburke/almond)
is released under the terms of the BSD License.
[Jasmine](https://jasmine.github.io/)
is released under the terms of the MIT License.
[RequireJS](http://requirejs.org/)
is released under the terms of the BSD License.
[Font Awesome](http://fontawesome.io)
by Dave Gandy
is released under the terms of the
[SIL OFL 1.1](http://scripts.sil.org/OFL).

### Original Software

Copyright (C) 2015-2016, [IDS Mannheim](http://www.ids-mannheim.de/)<br>
Author: [Nils Diewald](http://nils-diewald.de/),
[Ruth Maria Mell](http://ruth-mell.de)

Rabbid is developed as part of the [KorAP](http://korap.ids-mannheim.de/)
and
[Demokratiediskurs 1918/1925](http://www1.ids-mannheim.de/lexik/zeitreflexion18.html)
projects at the
[Institute for the German Language (IDS)](http://ids-mannheim.de/),
member of the
[Leibniz-Gemeinschaft](http://www.leibniz-gemeinschaft.de/en/about-us/leibniz-competition/projekte-2011/2011-funding-line-2/).

Rabbid is free software published under the
[BSD-2 License](https://raw.githubusercontent.com/KorAP/Rabbid/master/LICENSE).
