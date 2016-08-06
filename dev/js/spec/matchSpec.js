function matchLiFactory () {
  var matchUl = document.createElement('div').appendChild(document.createElement('ul'));
  matchUl.innerHTML = '<li data-end-page="0" data-start-page="0" data-right-ext="0" data-left-ext="0" data-marks="2 0 1158 7" data-para="724" data-id="1" class="flip" tabindex="0">' +
'  <div>' +
'    <div class="flag"></div>' +
'    <div class="snippet">' +
'<span class="context-left"><span class="buttons"><span class="extend left"></span><span class="collapse left"></span></span>aaa </span><span class="match"><mark>bbb</mark></span><span class="context-right"> ccc<span class="buttons"><span class="collapse right"></span><span class="extend right"></span></span></span>' +
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
  for (var prop in defaults) {
  newObj[prop] = defaults[prop];
  };
  for (var prop in overwrites) {
  newObj[prop] = overwrites[prop];
  };
*/


define(['match'], function (matchClass) {
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


    it('should create para correctly', function () {
      var matchLi = matchLiFactory();

      var match = matchClass.create(matchLi);
      var elem = match._createPara({
      	"content" : "abc",
	"in_doc_id" : 1,
	"para" : 7,
	"next" : 8,
	"previous" : 9
      });

      expect(elem.outerHTML).toEqual('<span class="ext">abc</span>');
    });

    
    it('should extend correctly', function () {

      var matchLi = matchLiFactory();
      var match = matchClass.create(matchLi);

      match.sendJSON = function () {};
      match.getPara = function (paraNumber, cb) {
	cb({
	  "content" : "abc[" + paraNumber + "]",
	  "in_doc_id" : 1,
	  "para" : paraNumber,
	  "next" : paraNumber + 1,
	  "previous" : paraNumber - 1
	});
      };

      match.getPara(5, function (para) {
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
    });
  });
});
