# BibleGateway HTML structure

There is a _tremendous_ amount of guff in the file. The key parts, which I have reverse-engineered, are:
- lots of header guff until <body ...
- then lots of menu, login, and search options
- then more options
- Alternatively, it seems all the interesting content is in `<section class="content"> ... </section>` that is followed by the `<footer>...</footer>`.
- finally after 650 lines in the start of the actual content!
    ```html
    <h1 class="passage-display">
    <div class='bcv'><div class="dropdown-display"><div class="dropdown-display-text">John 3:1-3</div></div></div>
    ...
    <div class='translation'><div class="dropdown-display"><div class="dropdown-display-text">New English Translation (NET Bible)</div></div></div></h1>
    ```
  - apart from single-chapter **Jude** which has: 
    ```html
    <h1 class="passage-display"> <span class="passage-display-bcv">Jude</span> <span class="passage-display-version">New International Version - UK (NIVUK)</span></h1>
    ```
- hundreds of uninteresting translation `<option>`s
- Editorial headings:
  ```html
  <h3><span id="en-NET-26112" class="text John-3-1">Conversation with Nicodemus</span></h3>
  ```
- Chapter starts:
    ```html
    <p class="chapter-1"><span class="text John-3-1"><span class="chapternum">3 </span>
    ```
- Verses (including footnote refs):
    ```html
    <sup data-fn='...' class='footnote' ... >
  Pharisee<sup data-fn='#fen-NET-26112a' class='footnote' data-link='[&lt;a href=&quot;#fen-NET-26112a&quot; title=&quot;See footnote a&quot;&gt;a&lt;/a&gt;]'>[<a href="#fen-NET-26112a" title="See footnote a">a</a>]</sup> named Nicodemus, who was a member of the Jewish ruling council,<sup data-fn='#fen-NET-26112b' class='footnote' data-link='[&lt;a href=&quot;#fen-NET-26112b&quot; title=&quot;See footnote b&quot;&gt;b&lt;/a&gt;]'>[<a href="#fen-NET-26112b" title="See footnote b">b</a>]</sup> </span> <span id="en-NET-26113" class="text John-3-2"><sup class="versenum">2 </sup>came to Jesus<sup data-fn='#fen-NET-26113c' class='footnote' data-link='[&lt;a href=&quot;#fen-NET-26113c&quot; title=&quot;See footnote c&quot;&gt;c&lt;/a&gt;]'>[<a href="#fen-NET-26113c" title="See footnote c">c</a>]</sup> at night<sup data-fn='#fen-NET-26113d' class='footnote' data-link='[&lt;a href=&quot;#fen-NET-26113d&quot; title=&quot;See footnote d&quot;&gt;d&lt;/a&gt;]'>[<a href="#fen-NET-26113d" title="See footnote d">d</a>]</sup> and said to him, “Rabbi, we know that you are a teacher who has come from God. For no one could perform the miraculous signs<sup data-fn='#fen-NET-26113e' class='footnote' data-link='[&lt;a href=&quot;#fen-NET-26113e&quot; title=&quot;See footnote e&quot;&gt;e&lt;/a&gt;]'>[<a href="#fen-NET-26113e" title="See footnote e">e</a>]</sup> that you do unless God is with him.” </span> <span id="en-NET-26114" class="text John-3-3"><sup class="versenum">3 </sup>Jesus replied,<sup data-fn='#fen-NET-26114f' class='footnote' data-link='[&lt;a href=&quot;#fen-NET-26114f&quot; title=&quot;See footnote f&quot;&gt;f&lt;/a&gt;]'>[<a href="#fen-NET-26114f" title="See footnote f">f</a>]</sup> “I tell you the solemn truth,<sup data-fn='#fen-NET-26114g' class='footnote' data-link='[&lt;a href=&quot;#fen-NET-26114g&quot; title=&quot;See footnote g&quot;&gt;g&lt;/a&gt;]'>[<a href="#fen-NET-26114g" title="See footnote g">g</a>]</sup> unless a person is born from above,<sup data-fn='#fen-NET-26114h' class='footnote' data-link='[&lt;a href=&quot;#fen-NET-26114h&quot; title=&quot;See footnote h&quot;&gt;h&lt;/a&gt;]'>[<a href="#fen-NET-26114h" title="See footnote h">h</a>]</sup> he cannot see the kingdom of God.”<sup data-fn='#fen-NET-26114i' class='footnote' data-link='[&lt;a href=&quot;#fen-NET-26114i&quot; title=&quot;See footnote i&quot;&gt;i&lt;/a&gt;]'>[<a href="#fen-NET-26114i" title="See footnote i">i</a>]</sup> </span> </p>
  ```
- Chapters are marked as:
    ```html
    <span class="chapternum">4 </span>
    ```
    Note: verse number '1' seems to be omitted if start of a new chapter, and the chapter number is given.
- Verse numbers are marked as:
    ```html
    <span id="en-NLT-28073" class="text Rom-7-20"><sup class="versenum">20 </sup>
    ```
    Except for version MSG:
    ```html
    <sup class="versenum">5-8</sup>"
    ```
    Note: The extra space after the verse number is actually a Unicode NBSP character, not a standard space.
    Note: Sometimes it seems that the character after `<sup` is also not a standard space character.
- The words of Jesus (where available) are marked as:
    ```html
    <span class="woj">...</span>
    ```
- Footnotes:
    ```html
    <h4>Footnotes</h4>
  <li id="..."><a href="#..." title="Go to John 3:1">John 3:1</a> <span class='footnote-text'>..text....</span></li>
  ```
- other uninteresting stuff
- Publisher and Copyright info
    ```html
    <div class="publisher-info-bottom ... <a href="...">New English Translation</a> (NET)</strong> <p>NET Bible® copyright ©1996-2017 by Biblical Studies Press, L.L.C. http://netbible.com All rights reserved.</p></div></div>
    ```
- other stuff starts `<section class="other-resources">` (by 2024) or earlier it was `<section class="sponsors">`

Other important notes:
- The character before the verse number in `<sup class="versenum">20 </sup>` is actually Unicode Character U+00A0 No-Break Space (NBSP). This was a tough one to find! These are converted to ordinary ASCII spaces.
- LEB includes some italicised words (e.g. `<I class="trans-change">things</I>`) with various class names. I am stripping the class names.
- LEB and WEB contain some extra classes after 'versenum' e.g. `<sup class="versenum mid-line">18</sup>`
- At end-2020, NIV has cross-references, but NIVUK does not. The part in the passage is:
```html
<sup class='crossreference' data-cr='#cen-NIV-28102S' data-link='(&lt;a href=&quot;#cen-NIV-28102S&quot;
title=&quot;See cross-reference S&quot;&gt;S&lt;/a&gt;)'>(<a href="#cen-NIV-28102S" 
title="See cross-reference S">S</a>)</sup>
```
  and the later detail is:
```html
<li id="cen-NIV-28102S"><a href="#en-NIV-28102" title="Go to Romans 7:10">Romans 7:10</a> : <a
class="crossref-link"
href="/passage/?search=Leviticus+18%3A5%2CLuke+10%3A26-Luke+10%3A28%2CRomans+10%3A5%2CGalatians+3%3A12&version=NIV"
data-bibleref="Leviticus 18:5, Luke 10:26-Luke 10:28, Romans 10:5, Galatians 3:12">Lev 18:5; Lk 10:26-28;
S Ro 10:5; Gal 3:12</a></li>
```
