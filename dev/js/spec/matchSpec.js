var matchUl = document.createElement('ul');
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
var matchLi = matchUl.getElementsByTagName('li')[0];


function extensionFactory (overwrites) {
  var defaultObj = {
    "content" : "abc",
    "in_doc_id" : 1,
    "next" : 381,
    "para" : 380,
    "previous" : 379
  };
  
  var newObj = {};
  for (var prop in defaultObj) {
    newObj[prop] = defaults[prop];
  };
  for (var prop in overwrites) {
    newObj[prop] = overwrites[prop];
  };
  
  return function (url, cb) {
    cb(newObj);
  };
};


define(['match'], function (matchClass) {
  describe('Rabbid.Match', function () {
    it('should be initializable', function () {
      expect(function() { matchClass.create() }
	    ).toThrow(new Error("Missing parameters"));

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
      var match = matchClass.create(matchLi);
      expect(match._element.classList.contains('active')).toBeFalsy();
      expect(match.open()).toBeTruthy();
      expect(match._element.classList.contains('active')).toBeTruthy();
      expect(match.close()).toBeTruthy();
      expect(match._element.classList.contains('active')).toBeFalsy();

      // This should show pagerange
    });
    
    it('should have incremental extensions', function () {
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

    xit('should extend correctly', function () {
      var match = matchClass.create(matchLi);
      match.sendJSON = function () {};
      match.getJSON = extensionFactory({
	para : match.para,
	next : match.para + 1,
	previous : match.para - 1
      });
    });
  });
});
