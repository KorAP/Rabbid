![Rabbid](https://raw.githubusercontent.com/KorAP/Rabbid/master/dev/demo/img/rabbid.png)

Rabbid is a rapid application development environment for
[KorAP Corpus Analysis Platform](http://korap.ids-mannheim.de/)
and used in production for the creation and management of
collections of textual examples in the area
of discourse analysis and discourse lexicography.

![Rabbid Screenshot](https://raw.githubusercontent.com/KorAP/Rabbid/master/dev/demo/img/screenshot.png)

Unlike KorAP, Rabbid provides a rather limited set of search operators
for small, non-annotated corpora.

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
you need NodeJS > 0.8.
For processing Sass, you will need Ruby with
the sass gem in addition.
This will probably need administration
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
$ cpanm git://github.com/Akron/Mojolicious-Plugin-TagHelpers-ContentBlock.git
```

Then install the dependencies as always and run the test suite.

```
$ SQLITE_ENABLE_FTS3_TOKENIZER=1 cpanm --installdeps .
$ perl Makefile.PL
$ make test
```

There is no need to install Rabbid on your system,
but you have to initialize the database before you can start.

```
$ perl script/rabbid rabbid_init
```

### Start Server

First you may want to import the example corpus from ```t/example/```:

```
$ perl script/rabbid rabbid_import -c example -d t/example
```

Rabbid can be deployed like all
[Mojolicious apps](http://mojolicio.us/perldoc/Mojolicious/Guides/Cookbook#DEPLOYMENT).
The easiest way is to start the built-in server:

```
$ perl script/rabbid daemon
```

Rabbid will then be available at ```localhost:3000``` in your browser.

### Format

The input format of Rabbid is a simplified XHTML document.
The ```<head />``` contains the ```<title />``` of the document,
further meta data fields like ```doc_id``` are given as ```<meta />```
elements. In the body only ```<p />``` elements are of relevance -
they divide the text body into snippets used by Rabbid.
Optional ```<span />``` elements can be used to subdivide long paragraphs
in shorter snippets.
Optional pagebreaks may be given in the form of empty
```<br class="pb" data-after="1" />``` elements,
with the ```data-after``` attribute
telling the page number following the element.

An example document may look like this:

``` html
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta charset="utf-8" />
    <title>Example 1</title>
    <meta name="doc_id" content="5" />
    <meta name="author" content="John Doe" />
    <meta name="year" content="1919" />
  </head>
  <body>
    <p>This is an example text.</p>
    <p>Each paragraph resembles one snippet in Rabbid's view.</p>
    <p>
      <span>Long paragraphs can be subdivided.</span>
      <span>By using the span element, each span makes one snippet.</span>
    </p>
    <p>The End.</p>
  </body>
</html>

```

### Tools

To convert documents to Rabbidml, see

```
$ perl script/rabbid rabbid_convert
```

Currently supported input formats include I5 and some Gutenberg Project conventions.


### Bugs and Caveats

New versions of ```DBD::SQLite``` do not include support
for fulltext search tokenizers by default.
To compile SQLite with support, use

```
$ SQLITE_ENABLE_FTS3_TOKENIZER=1 cpanm DBD::SQLite --force
```

## COPYRIGHT AND LICENSE

### Bundled Software and Data

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
The Example Corpus is released under the
[Project Gutenberg License](http://gutenberg.net/license):
"This eBook is for the use of anyone anywhere at no cost and with almost no restrictions whatsoever. You may copy it, give it away or re-use it under the terms of the Project Gutenberg License included with this eBook or online at www.gutenberg.net"


### Original Software

Copyright (C) 2015-2016, [IDS Mannheim](http://www.ids-mannheim.de/)<br>
Author: [Nils Diewald](http://nils-diewald.de/),
[Ruth Maria Mell](http://www.ruth-mell.de)

Rabbid is developed as part of the [KorAP](http://korap.ids-mannheim.de/)
and
[Demokratiediskurs 1918-1925](http://www1.ids-mannheim.de/lexik/zeitreflexion18.html)
projects at the
[Institute for the German Language (IDS)](http://ids-mannheim.de/),
member of the
[Leibniz-Gemeinschaft](http://www.leibniz-gemeinschaft.de/en/about-us/leibniz-competition/projekte-2011/2011-funding-line-2/).

Rabbid is free software published under the
[BSD-2 License](https://raw.githubusercontent.com/KorAP/Rabbid/master/LICENSE).
