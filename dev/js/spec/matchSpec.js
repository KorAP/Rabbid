function matchLiFactory () {
  var matchUl = document.createElement('div').appendChild(document.createElement('ul'));
  matchUl.innerHTML = '<li data-end-page="0" data-start-page="0" data-marks="2 0 1158 7" data-para="724" data-id="1" class="flip" tabindex="0">' +
		'  <div>' +
		'    <div class="flag"></div>' +
		'    <div class="snippet">' +
		'    <span class="context-left">aaa </span><span class="match"><mark>bbb</mark></span><span class="context-right"> ccc</span>' +
		'    </div>' +
		'    <p class="ref">Theodor Fontane: Effi Briest' +
		' (1894);' +
		'<a href="/search?q=Versuch&amp;startPage=1&amp;filterBy=polDir&amp;filterOp=equals&amp;filterValue=radikal-demokratisch">radikal-demokratisch</a>, ' +
		'<a href="/search?q=Versuch&amp;startPage=1&amp;filterBy=genre&amp;filterOp=equals&amp;filterValue=Roman">Roman</a>, ' +
		'<a href="/search?q=Versuch&amp;startPage=1&amp;filterBy=domain&amp;filterOp=equals&amp;filterValue=Belletristik">Belletristik</a>' +
		'    </p>' +
		'  </div>' +
		'</li>';
  return matchUl.getElementsByTagName('li')[0];
};

function matchLiFactory2 () {
  var matchUl = document.createElement('div').appendChild(document.createElement('ul'));
  matchUl.innerHTML = '<li tabindex="0" class="flip" data-id="1" data-para="317" data-marks="2 0 77 7" data-start-page="4" data-end-page="4">'+
    '  <div>'+
    '    <div class="flag"></div>'+
    '    <div class="snippet">'+
    '      <span class="context-left"><span class="ext" class="nobr" data-start-page="4">abc</span>Und damit verließ Johanna das Zimmer, während Effi noch einen Blick in den </span><span class="match"><mark>Spiegel</mark></span><span class="context-right"> tat und dann über den Flur fort, der bei der Tagesbeleuchtung viel von seinem Zauber vom Abend vorher eingebüßt hatte, bei Geert eintrat.<span class="ext" data-end-page="4">abc</span><span class="ext" data-end-page="4">def</span></span>'+
    '    </div>'+
    '    <p class="ref">Theodor Fontane: Effi Briest'+
    ' (1894);'+
    '<a href="/collection/2?q=Spiegel&amp;startPage=1&amp;filterBy=polDir&amp;filterOp=equals&amp;filterValue=radikal-demokratisch">radikal-demokratisch</a>, '+
    '<a href="/collection/2?q=Spiegel&amp;startPage=1&amp;filterBy=genre&amp;filterOp=equals&amp;filterValue=Roman">Roman</a>, '+
    '<a href="/collection/2?q=Spiegel&amp;startPage=1&amp;filterBy=domain&amp;filterOp=equals&amp;filterValue=Belletristik">Belletristik</a>'+
    '    </p>'+
    '  </div>'+
    '</li>';
  return matchUl.getElementsByTagName('li')[0];
};

function matchLiFactory3 () {
  var matchUl = document.createElement('div').appendChild(document.createElement('ul'));
  matchUl.innerHTML = '<li data-end-page="0" data-start-page="0" data-marks="2 0 0 3 2 0 18 3 2 0 68 3" data-para="25" data-id="3" class="flip" tabindex="0">' +
    '  <div>' +
    '    <div class="flag"></div>' +
    '    <div class="snippet">' +
    '      <span class="context-left"></span>' +
    '        <span class="match"><mark>Der</mark> Wettbewerb in <mark>der</mark> Gaswirtschaft hat noch gar nicht begonnen, in <mark>der</mark></span>' +
    '        <span class="context-right"></span>' +
    '      </span>' +
    '    </div>' +
    '    <p class="ref">Hustedt, Michaele: Energiewirtschaft;</p>' +
    '  </div>' +
    '</li>';
  return matchUl.getElementsByTagName('li')[0];
};


/*
  for (var prop in defaults) {
  newObj[prop] = defaults[prop];
  };
  for (var prop in overwrites) {
  newObj[prop] = overwrites[prop];
  };
*/


define(['match', 'snippet'], function (matchClass, snippetClass) {
  describe('Rabbid.Match', function () {
    it('should be initializable', function () {
      expect(function() { matchClass.create() }
						).toThrow(new Error("Missing parameters"));

      var matchLi = matchLiFactory();
      var match = matchClass.create(matchLi);
      expect(match).toBeTruthy();

      // Has a reference to the match object
      expect(matchLi._match).toBeTruthy();

      expect(match.ID).toEqual(1);
      expect(match.para).toEqual(724);
      expect(match.marks).toEqual('2 0 1158 7');
      expect(match.marked).toBeFalsy();
      expect(match.pageStart).toEqual(0);
      expect(match.pageEnd).toEqual(0);
    });

    it('should open and close', function () {
      var matchLi = matchLiFactory();
      
      var match = matchClass.create(matchLi);
      expect(match._element.classList.contains('active')).toBeFalsy();
      expect(match.open()).toBeTruthy();
      expect(match._element.classList.contains('active')).toBeTruthy();
      expect(match.close()).toBeTruthy();
      expect(match.open()).toBeTruthy();

      // This should show pagerange
    });

    it('should have buttons', function () {
      var matchLi = matchLiFactory();
      var match = matchClass.create(matchLi);
      expect(match.open()).toBeTruthy();
      expect(matchLi.getElementsByClassName('buttons').length).toEqual(3);
      expect(matchLi.querySelector('span.extend.left')).toBeTruthy();
      expect(matchLi.querySelector('span.extend.right')).toBeTruthy();
      expect(matchLi.querySelector('span.collapse.left')).toBeTruthy();
      expect(matchLi.querySelector('span.collapse.right')).toBeTruthy();
      expect(matchLi.querySelector('span.close')).toBeTruthy();
      expect(matchLi.querySelector('span.store')).toBeTruthy();

      expect(match.close()).toBeTruthy();
      expect(match.open()).toBeTruthy();
      expect(matchLi.getElementsByClassName('buttons').length).toEqual(3);
    });
    
    it('should extend left correctly', function () {

      var matchLi = matchLiFactory();
      var match = matchClass.create(matchLi);

      match.sendJSON = function () {};
      match.getSnippet = function (paraNumber, cb) {
				cb(snippetClass.create({
					"content" : "abc[" + paraNumber + "]",
					"in_doc_id" : 1,
					"para" : paraNumber,
					"next" : paraNumber + 1,
					"previous" : paraNumber - 1
				}));
      };

      match.getSnippet(5, function (para) {
				expect(para.previous).toEqual(4);
				expect(para.para).toEqual(5);
				expect(para.next).toEqual(6);
				expect(para.content).toEqual("abc[5]");
      });

      expect(match.extendLeft()).toBeTruthy();
      expect(matchLi.querySelector("div.snippet").textContent)
				.toEqual("    abc[723]aaa bbb ccc    ");
      expect(match.extendLeft()).toBeTruthy();
      expect(matchLi.querySelector("div.snippet").textContent)
				.toEqual("    abc[722]abc[723]aaa bbb ccc    ");
      expect(match.extendLeft()).toBeTruthy();
      expect(matchLi.querySelector("div.snippet").textContent)
				.toEqual("    abc[721]abc[722]abc[723]aaa bbb ccc    ");

      expect(matchLi.querySelector("div.snippet > span:first-of-type").classList.contains('context-left')).toBeTruthy();
      expect(matchLi.querySelector("div.snippet > span:first-of-type > span:first-of-type").classList.contains('buttons')).toBeTruthy();
    });
    
    it('should extend right correctly', function () {

      var matchLi = matchLiFactory();
      var match = matchClass.create(matchLi);

      match.sendJSON = function () {};
      match.getSnippet = function (paraNumber, cb) {
				cb(snippetClass.create({
					"content" : "abc[" + paraNumber + "]",
					"in_doc_id" : 1,
					"para" : paraNumber,
					"next" : paraNumber + 1,
					"previous" : paraNumber - 1
				}));
      };

      expect(match.extendRight()).toBeTruthy();
      expect(matchLi.querySelector("div.snippet").textContent)
				.toEqual("    aaa bbb cccabc[725]    ");
      expect(match.extendRight()).toBeTruthy();
      expect(matchLi.querySelector("div.snippet").textContent)
				.toEqual("    aaa bbb cccabc[725]abc[726]    ");
      expect(match.extendRight()).toBeTruthy();
      expect(matchLi.querySelector("div.snippet").textContent)
				.toEqual("    aaa bbb cccabc[725]abc[726]abc[727]    ");

      expect(matchLi.querySelector("div.snippet > span:last-of-type").classList.contains('context-right')).toBeTruthy();
      expect(matchLi.querySelector("div.snippet > span:last-of-type > span:last-of-type").classList.contains('buttons')).toBeTruthy();
    });

    it('should extend correctly (no contexts)', function () {
      var matchLi = matchLiFactory3();
      var match = matchClass.create(matchLi);

      match.sendJSON = function () {};
      match.getSnippet = function (paraNumber, cb) {
				cb(snippetClass.create({
					"content" : "abc[" + paraNumber + "]",
					"in_doc_id" : 1,
					"para" : paraNumber,
					"next" : paraNumber + 1,
					"previous" : paraNumber - 1
				}));
      };

      expect(match.extendLeft()).toBeTruthy();
      expect(matchLi.querySelector("div.snippet span.context-left").textContent)
				.toEqual("abc[24]");
      expect(match.extendLeft()).toBeTruthy();
      expect(matchLi.querySelector("div.snippet span.context-left").textContent)
				.toEqual("abc[23]abc[24]");
      expect(match.extendRight()).toBeTruthy();
      expect(matchLi.querySelector("div.snippet span.context-right").textContent)
				.toEqual("abc[26]");
    });
    
    
    it('should collapse left correctly', function () {

      var matchLi = matchLiFactory();
      var match = matchClass.create(matchLi);
      match.sendJSON = function () {};
      match.getSnippet = function (paraNumber, cb) {
				cb(snippetClass.create({
					"content" : "abc[" + paraNumber + "]",
					"in_doc_id" : 1,
					"para" : paraNumber,
					"next" : paraNumber + 1,
					"previous" : paraNumber - 1
				}));
      };

      expect(match.extendLeft()).toBeTruthy();
      expect(match.extendLeft()).toBeTruthy();
      expect(match.extendLeft()).toBeTruthy();
      expect(matchLi.querySelector("div.snippet").textContent)
				.toEqual("    abc[721]abc[722]abc[723]aaa bbb ccc    ");

      expect(match.collapseLeft()).toBeTruthy();
      expect(matchLi.querySelector("div.snippet").textContent)
				.toEqual("    abc[722]abc[723]aaa bbb ccc    ");

      expect(match.collapseLeft()).toBeTruthy();
      expect(matchLi.querySelector("div.snippet").textContent)
				.toEqual("    abc[723]aaa bbb ccc    ");
      expect(match.collapseLeft()).toBeTruthy();
      expect(matchLi.querySelector("div.snippet").textContent)
				.toEqual("    aaa bbb ccc    ");
      expect(match.collapseLeft()).toBeFalsy();
      expect(matchLi.querySelector("div.snippet").textContent)
				.toEqual("    aaa bbb ccc    ");
    });

    it('should collapse right correctly', function () {
      var matchLi = matchLiFactory();
      var match = matchClass.create(matchLi);
      match.sendJSON = function () {};
      match.getSnippet = function (paraNumber, cb) {
				cb(snippetClass.create({
					"content" : "abc[" + paraNumber + "]",
					"in_doc_id" : 1,
					"para" : paraNumber,
					"next" : paraNumber + 1,
					"previous" : paraNumber - 1
				}));
      };

      expect(match.extendRight()).toBeTruthy();
      expect(match.extendRight()).toBeTruthy();
      expect(match.extendRight()).toBeTruthy();
      expect(matchLi.querySelector("div.snippet").textContent)
				.toEqual("    aaa bbb cccabc[725]abc[726]abc[727]    ");

      expect(match.collapseRight()).toBeTruthy();
      expect(matchLi.querySelector("div.snippet").textContent)
				.toEqual("    aaa bbb cccabc[725]abc[726]    ");
      expect(match.collapseRight()).toBeTruthy();
      expect(matchLi.querySelector("div.snippet").textContent)
				.toEqual("    aaa bbb cccabc[725]    ");
      expect(match.collapseRight()).toBeTruthy();
      expect(matchLi.querySelector("div.snippet").textContent)
				.toEqual("    aaa bbb ccc    ");
      expect(match.collapseRight()).toBeFalsy();
      expect(matchLi.querySelector("div.snippet").textContent)
				.toEqual("    aaa bbb ccc    ");     
    });    

		it('should be created from element with extensions', function () {
      var matchLi = matchLiFactory2();
			var match = matchClass.create(matchLi);
			expect(match.open()).toBeTruthy();
			expect(match.getRightSnippet(1)).toBeTruthy();
		});
    
  });


  describe('Rabbid.Snippet', function () {
    it('should be initializable', function () {
      expect(function() { snippetClass.create() }
						).toThrow(new Error("Missing parameters"));

      var snippet = snippetClass.create({
				"content" : "abc[1]",
				"in_doc_id" : 1,
				"para" : 4,
				"next" : 5,
				"previous" : 3
      });

      expect(snippet).toBeTruthy();
      expect(snippet.content).toEqual("abc[1]");
      expect(snippet.inDocID).toEqual(1);
      expect(snippet.para).toEqual(4);
      expect(snippet.next).toEqual(5);
      expect(snippet.previous).toEqual(3);
      expect(snippet.content).toEqual("abc[1]");

      snippet = snippetClass.create({
				"content" : "abc[1]",
				"in_doc_id" : "1",
				"para" : "4",
				"next" : "5",
				"previous" : "3"
      });

      expect(snippet).toBeTruthy();
      expect(snippet.content).toEqual("abc[1]");
      expect(snippet.inDocID).toEqual(1);
      expect(snippet.para).toEqual(4);
      expect(snippet.next).toEqual(5);
      expect(snippet.previous).toEqual(3);
      expect(snippet.content).toEqual("abc[1]");
    });
		
    it('should create element correctly', function () {
      var snippet = snippetClass.create({
      	"content" : "abc",
				"in_doc_id" : 1,
				"para" : 7,
				"next" : 8,
				"previous" : 9
      });

      expect(snippet.element().outerHTML).toEqual('<span class="ext">abc</span>');
    });

		it('should view pagerange correctly', function () {
			var matchLi = matchLiFactory2();
      var match = matchClass.create(matchLi);
      match.sendJSON = function () {};
      match.getSnippet = function (paraNumber, cb) {
				cb(snippetClass.create({
					"content" : "abc[" + paraNumber + "]",
					"in_doc_id" : 1,
					"para" : paraNumber,
					"next" : paraNumber + 1,
					"previous" : paraNumber - 1,
					"start_page" : 5,
					"end_page" : 5
				}));
      };

			expect(match.open()).toBeTruthy();
			expect(match.pageStart).toEqual(4);
			expect(match.pageEnd).toEqual(4);
			expect(match.element().getElementsByClassName('pageRange')[0].textContent).toEqual("4");

			expect(match.extendRight()).toBeTruthy();
			expect(match.element().getElementsByClassName('pageRange')[0].textContent).toEqual("4-5");
			expect(match.collapseRight()).toBeTruthy();
			expect(match.element().getElementsByClassName('pageRange')[0].textContent).toEqual("4");
			expect(match.extendRight()).toBeTruthy();
			expect(match.element().getElementsByClassName('pageRange')[0].textContent).toEqual("4-5");
			
      match.getSnippet = function (paraNumber, cb) {
				cb(snippetClass.create({
					"content" : "abc[" + paraNumber + "]",
					"in_doc_id" : 1,
					"para" : paraNumber,
					"next" : paraNumber + 1,
					"previous" : paraNumber - 1,
					"start_page" : 3,
					"end_page" : 4
				}));
      };

			expect(match.extendLeft()).toBeTruthy();
			expect(match.element().getElementsByClassName('pageRange')[0].textContent).toEqual("3-5");
			expect(match.collapseRight()).toBeTruthy();
			expect(match.element().getElementsByClassName('pageRange')[0].textContent).toEqual("3-4");
			expect(match.collapseLeft()).toBeTruthy();
			expect(match.element().getElementsByClassName('pageRange')[0].textContent).toEqual("4");
			expect(match.collapseLeft()).toBeTruthy();
			expect(match.element().getElementsByClassName('pageRange')[0].textContent).toEqual("4");
		});

		it('should view pagerange correctly', function () {
			var matchLi = matchLiFactory2();
      var match = matchClass.create(matchLi);
      match.sendJSON = function () {};
      match.getSnippet = function (paraNumber, cb) {
				cb(snippetClass.create({
					"content" : "uvw[[PB=5]]xy[[PB=6]]z",
					"in_doc_id" : 1,
					"para" : paraNumber,
					"next" : paraNumber + 1,
					"previous" : paraNumber - 1,
					"start_page" : 4,
					"end_page" : 6
				}));
      };

			expect(match.open()).toBeTruthy();
			expect(
				match.element().getElementsByClassName('ext')[0].outerHTML
			).toEqual('<span class="ext" data-start-page="4">abc</span>');

			expect(
				match.element().getElementsByClassName('ext')[1].outerHTML
			).toEqual('<span class="ext" data-end-page="4">abc</span>');

			expect(
				match.element().getElementsByClassName('ext')[2].outerHTML
			).toEqual('<span class="ext" data-end-page="4">def</span>');

			expect(match.element().getElementsByClassName('pageRange')[0].textContent).toEqual("4");
			expect(match.extendRight()).toBeTruthy();
			expect(match.element().getElementsByClassName('pageRange')[0].textContent).toEqual("4-6");

			var last = match.element().getElementsByClassName('ext')[3];
			expect(last.getElementsByClassName('pb').length).toEqual(2);
			expect(last.getElementsByClassName('pb')[0].getAttribute('data-after')).toEqual('5');
			expect(last.getElementsByClassName('pb')[1].getAttribute('data-after')).toEqual('6');
		});
		
  });
});
