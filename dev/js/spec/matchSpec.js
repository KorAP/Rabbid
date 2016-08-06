function matchLiFactory () {
  var matchUl = document.createElement('div').appendChild(document.createElement('ul'));
  matchUl.innerHTML = '<li data-end-page="0" data-start-page="0" data-right-ext="0" data-left-ext="0" data-marks="2 0 1158 7" data-para="724" data-id="1" class="flip" tabindex="0">' +
'  <div>' +
'    <div class="flag"></div>' +
'    <div class="snippet">' +
    '<span class="context-left">aaa </span><span class="match"><mark>bbb</mark></span><span class="context-right"> ccc</span>' +
    // <span class="buttons"><span class="extend left"></span><span class="collapse left"></span></span>
    // <span class="buttons"><span class="collapse right"></span><span class="extend right"></span></span>
    
'    </div>' +
'    <p class="ref">Theodor Fontane: Effi Briest' +
' (1894);' +
'<a href="/search?q=Versuch&amp;startPage=1&amp;filterBy=polDir&amp;filterOp=equals&amp;filterValue=radikal-demokratisch">radikal-demokratisch</a>, ' +
'<a href="/search?q=Versuch&amp;startPage=1&amp;filterBy=genre&amp;filterOp=equals&amp;filterValue=Roman">Roman</a>, ' +
'<a href="/search?q=Versuch&amp;startPage=1&amp;filterBy=domain&amp;filterOp=equals&amp;filterValue=Belletristik">Belletristik</a>, ' +
'      <span style="display: none;"></span><span class="button store" title="Speichern"><span>Speichern</span></span>' +
'      <span class="button close" title="Schließen"><span>Schließen</span></span>' +
'    </p>' +
'  </div>' +
'</li>';
  return matchUl.getElementsByTagName('li')[0];
};

/*
<li tabindex="0" class="flip "
 data-id="1" data-para="317" data-marks="2 0 77 7" data-left-ext="0" data-right-ext="2" data-start-page="0" data-end-page="0">
  <div>
    <div class="flag"></div>
    <div class="snippet">
<span class="context-left"><span class="buttons"><span class="extend left"></span><span class="collapse left"></span></span>Und damit verließ Johanna das Zimmer, während Effi noch einen Blick in den </span><span class="match"><mark>Spiegel</mark></span><span class="context-right"> tat und dann über den Flur fort, der bei der Tagesbeleuchtung viel von seinem Zauber vom Abend vorher eingebüßt hatte, bei Geert eintrat.<span class="ext">Dieser saß an seinem Schreibtisch, einem etwas schwerfälligen Zylinderbüro, das er aber, als Erbstück aus dem elterlichen Hause, nicht missen mochte.</span><span class="ext">Effi stand hinter ihm und umarmte und küßte ihn, noch eh euch von seinem Platz erheben konnte.</span><span class="buttons"><span class="collapse right"></span><span class="extend right"></span></span></span>
    </div>
    <p class="ref">Theodor Fontane: Effi Briest
 (1894);
<a href="/collection/2?q=Spiegel&amp;startPage=1&amp;filterBy=polDir&amp;filterOp=equals&amp;filterValue=radikal-demokratisch">radikal-demokratisch</a>, 
<a href="/collection/2?q=Spiegel&amp;startPage=1&amp;filterBy=genre&amp;filterOp=equals&amp;filterValue=Roman">Roman</a>, 
<a href="/collection/2?q=Spiegel&amp;startPage=1&amp;filterBy=domain&amp;filterOp=equals&amp;filterValue=Belletristik">Belletristik</a>, 

      <span title="Speichern" class="button store"><span>Speichern</span></span>
      <span title="Schließen" class="button close"><span>Schließen</span></span>
    </p>
  </div>
</li>
*/

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
      expect(match.leftExt).toEqual(0);
      expect(match.rightExt).toEqual(0);
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
      expect(match._element.classList.contains('active')).toBeFalsy();

      // This should show pagerange
    });
    
    it('should have incremental extensions', function () {
      var matchLi = matchLiFactory();

      var match = matchClass.create(matchLi);
      match.incrLeftExt();
      expect(match.leftExt).toEqual(1);
      match.incrLeftExt();
      expect(match.leftExt).toEqual(2);

      match.incrRightExt();
      expect(match.rightExt).toEqual(1);
      match.incrRightExt();
      expect(match.rightExt).toEqual(2);
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
	.toEqual("abc[723]aaa bbb ccc    ");
      expect(match.extendLeft()).toBeTruthy();
      expect(matchLi.querySelector("div.snippet").textContent)
	.toEqual("abc[722]abc[723]aaa bbb ccc    ");
      expect(match.extendLeft()).toBeTruthy();
      expect(matchLi.querySelector("div.snippet").textContent)
	.toEqual("abc[721]abc[722]abc[723]aaa bbb ccc    ");
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
	.toEqual("aaa bbb cccabc[725]    ");
      expect(match.extendRight()).toBeTruthy();
      expect(matchLi.querySelector("div.snippet").textContent)
	.toEqual("aaa bbb cccabc[725]abc[726]    ");
      expect(match.extendRight()).toBeTruthy();
      expect(matchLi.querySelector("div.snippet").textContent)
	.toEqual("aaa bbb cccabc[725]abc[726]abc[727]    ");
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
	.toEqual("abc[721]abc[722]abc[723]aaa bbb ccc    ");

      expect(match.collapseLeft()).toBeTruthy();
      expect(matchLi.querySelector("div.snippet").textContent)
	.toEqual("abc[722]abc[723]aaa bbb ccc    ");

      expect(match.collapseLeft()).toBeTruthy();
      expect(matchLi.querySelector("div.snippet").textContent)
	.toEqual("abc[723]aaa bbb ccc    ");
      expect(match.collapseLeft()).toBeTruthy();
      expect(matchLi.querySelector("div.snippet").textContent)
	.toEqual("aaa bbb ccc    ");
      expect(match.collapseLeft()).toBeFalsy();
      expect(matchLi.querySelector("div.snippet").textContent)
	.toEqual("aaa bbb ccc    ");
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
	.toEqual("aaa bbb cccabc[725]abc[726]abc[727]    ");

      expect(match.collapseRight()).toBeTruthy();
      expect(matchLi.querySelector("div.snippet").textContent)
	.toEqual("aaa bbb cccabc[725]abc[726]    ");
      expect(match.collapseRight()).toBeTruthy();
      expect(matchLi.querySelector("div.snippet").textContent)
	.toEqual("aaa bbb cccabc[725]    ");
      expect(match.collapseRight()).toBeTruthy();
      expect(matchLi.querySelector("div.snippet").textContent)
	.toEqual("aaa bbb ccc    ");
      expect(match.collapseRight()).toBeFalsy();
      expect(matchLi.querySelector("div.snippet").textContent)
	.toEqual("aaa bbb ccc    ");     
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

    xit('should be created from element correctly', function () {
     /*
 var span = document.createElement('span');
      span.setAttribute('class', 'ext');
      span.setAttribute('data-');
      var snippet = snippetClass.create(

      );
*/
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

  });
});
