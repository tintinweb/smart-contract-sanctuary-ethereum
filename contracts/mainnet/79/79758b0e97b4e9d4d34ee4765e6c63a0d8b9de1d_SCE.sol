// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SCE Pass Genesis
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//    ttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttOzlttttttttttttttttttttttttttttttttttttttttO    //
//    ltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltltlz11zttltltltltltltltltltltltltltltltltltltltl>.    //
//    tttltttltttltttltttltttltttltttltttltttltttltttltttltttltttltttltttltttltttltttltttltttltttltltttltttltttltttltttltttltttltttltttltttltttltttltttlttlv1?1ztltlttltttltttltttltttltttltttltttltttlttt<_.~    //
//    tlttltttltttltttltttltttltttltttltttltttltttltttltttltttltttltttltttltttltttltttltttltttltttttOzlttlttltttltttltttltttltttltttltttltttltttltttlttv1???zlttttlttlttlttltttltttltttltttltttltttltttlv_..~.    //
//    ttlttlttltlttlttltlttlttltltz`?OtlttltlttlttltlttlttltlttlttltlttlttltlttlttltlttlttltlttltltlttzzOttltlttltlttlttltlttlttltlttlttltlttlttltlOz1???1zttttlttttlttlttltltO>`jttlttltlttlttltlttlt<_...~..    //
//    tlttlttltttlttlttlttltlttlttO - ?tlttlttltlttlOztltltttlttlttlttltlttlttltlttlttltlttlttltttlttltOz1ztttlttlttltlttlttltlttlttltlttlttltltv1?????zlttttlttlltlttlttlttt<`. zttltltttlttlttlttlv_...~..~.    //
//    ttlttlttlttlttlttttltttlttttt_(O..1ltttltttlt1ztttlttlttlttltttltttltttltttltttltttltv!`  ?tttlttttz?1ztlttttltttltttltttltttltttltttlOz1?????1ztttltlttltttlttlttlttv!.z{.ttltttlttlttlttttv~..~...~...    //
//    tlttlttlttlttlttltlttlttltltt>.tt&.?Otlttltv?zttltttlttlttlttlttlttlttlttlttlttlttltv  _~  zlttltltlOz?<?<<<1ztlttlttlttlttlttlttltv1??????1ztttltttlttlttltttlttltO!.Jtt!(tttlttlttlttltlv~...~..~...~.    //
//    ttlttlttlttlttlttlttlttlttlttO`ztll- ?ttlO1?1ttttlttltttlttlttlttlttlttlttlttlttlttlz  ~.  ?????ztttv!     .   ?zO<` `???1Oz11zOz1???????ztttlttltltttlttlttlttlttv`.lttv`jlttlttlttltttv~.......~...~..    //
//    tlttlttlttlttlttlttlttlttltltt_(tttlO..1z??1tltlttlttlttlttlttlttlttlttlttlttltlttO?`  ~~- .... .tv!  -~~___~~_  !  _-...        ?<???1zttttlttltttltlttlttlttltv!.zlttl>.ttlttlttlttlv!....~.~...~....~    //
//    ttlttlttlttlttlttltttlttltttlt;.ttlttl1._<1lttlttlttlttlttlttlttlttlttlttO<?!`   (! .~~.~.__``` .v` .~_  ..   ~~.     `~~._~~~~~.  ?zlttltlttlttlttlttltttlttlv!.Jtlttlt:.tlttlttlttv!..~.~..~.~.~.~.~..    //
//    tlttlttlttlttlttlttlttlttlttlv> llttl1??< 1tltttlttlttltv!  _ztttlttlttlv` ._~~~  -    ~~` ...(zt! .~`  ???!`  ~_  i-  ~~_`     _~- (ttlttltttlttlttlttlttlttv (tttttltt`(zltttlttv!.~...~..~...~...~..~    //
//    ttlttlttlttlttlttlttlttlttv<~..ztttv??<~.Jtttltttlttv<<! +l_ (lv<?`   1t>     ~~  ltz~ ~~_ (ttv1v  ~~_.........~~  ?<  ~.` .?z+. _~_ (tttltv<<1zlttlttlttlttlt&._1tlttltO-..?zttv!..~.~..~..~..~..~...~.    //
//    tlttlttlttlttlttlttlttltv!..zttltO1?>`.(ztlttltltv?`..-((+=1 -` .._~_ (ttz++. .~  ztt: _~_ (v!     ~.````````____  ?<  ~~  ztttv  ~. .ttv!`      ?1ttlttlttlttttz. ?OttltttO-._!...~...~..~..~..~..~.~..    //
//    ttlttlttlttlttlttlttltt!.Jttttlt1<! .+?zlttlttlv! .zl<<<<1ll-  _` _~_  llttt_ _~. jtt{  ~_ (>  ~_  ~_  ......     (?>  ~_ .tttlv  ~~  lv!  .~~~~_.  1ttlttlttlttttO-.?ztlttlv!_  .~..~..~...~..~..~...~.    //
//    tlttlttlttlttlttlttlttlO.(Otltv?! .???zlttlttt< .=v! .... 1=1  ..  .~  jttlt>  ~_ (lt>  ~_ (>  ~`  _~_ _1ltv! .~_ (?:  ~_ .tltt>  ~_ .l:  ~~_`  `_~. (Otltttlttlttttt<.?ltO>..` .~..~..~..~...~..~..~..~    //
//    ttlttlttlttlttlttlttlttlt-.1v1?? (???zttlttlt> J=!.(tlltz .1< .tl:  ~_ .tltlz  ~_ .<?1. .~.   ~_  . _~_.     .~_  ``` .~_ (ttlt>  ~_ .v` ~._  ...  __ .zttlttlttllttlt> t>.._  .~..~..~..~......~..~....    //
//    tlttlttlttltv!?1ttlttlttlti <??? (??1tttlttl> (=:.ztlttlt&...~` ?O. _~_ (ttv! .~~_... <  _~~~_` .JO-. `_~~~._`  .  -..~~_  _?<1: -~_ (>  ~~~.   ?1- __ .tlttltttttlttl> _.._  .~..~..~.._` _~.....~..~~.    //
//    ttlttlttltv~.tO,?OOzzz11???<.(?? (?1ttlttltt`.=v (ttttttltl> .=+ (o  ~~_    .~_ _``  .xO+......+lttttz-... ...(+?-   ```_~~_     ~~` j>  ~.``~~-  _  ~_ jttlttlltttlt>_`..` ..~..~..~..` ... `.....~...~    //
//    tlttltOz<_(1????+.??????????<.(? (1ttttlttlv (lz (tlltlttttl (=l_ ll. `_~~~_`  ...++zltlltltllltltltlttllttO???????+(((..     _~~.~.  <  ~_    `~_.  ~~ .v!   _?Otl<_._`.` -~...~..~.` .~.~.._  ....~...    //
//    ?????<!.+?????<???<.???????<??-. (ttlttltttz (l=..Ottltltltt:.l=! ttt&-.....(xlltltttttttltttttltttlttlttltz????????ztltttzzz..   `_~_   _~  z-.  _~~~~  `  ...  ?_..~_`  ..```````` ....~..~.~_   ..~..    //
//    ????~._-...(((-(???????<!-.????_`(ttltttlttO..==i (zttttlttv`.lv`.ttttltllltttttttltltltttltltttlttttlttttv????????ztlttlttttttlz+.       ~_ (ttz-  `~.    ~~~~~_  _.._` .....  _....~..` -....  `  ...~    //
//    ???????????????--<?<<~.(1zzz?????<??????1ltt> <l=1. ?ztltv> .=z!.zlltltttttlttltlttlttltlttltlttltltlttltO????????1tlttltttttttttlltz((zo  ~_  ?1v`     .  ~_   _~.  _....~....._. `..~` ...............    //
//    ????????????11zz&.-.zttttlttOz<`  ..__..  1tt- ?==l<.    .(z=?`.ztltttltlttltltlttlttttlttltttlttltttlttl1???????1ltttlttltlltlttttlttttll. _~-    .~.  `  ~_     ~. ` ..~.~.~..~....  ..~..~........~..    //
//    ?=zzzzzlttttttltlttltttlttlt<` .~``  ~~~` ,ttti. ?1=======v?`.Jtttttlttlttlttttttlttlttttlttlttlttlttlttv????????ztlttltttlttltltlttttttttO-  `~~~~~_      _~  __  ~~_ _......~...~..~....~..~........~.    //
//    ttttttttttlttltttltttlttltt!  ~_ .-  `` .(tllttti.  ~!!!``..Jlttltlttltttlttltltlttltltlttlttlttlttlttlv????????ztttlttlttttttttlttltlltlttlOi.         ~_  _~.    ~.   ~..~...~...~..~.~...............    //
//    tltltlttlttlttlttlttlttltv!  _~  _<+(((?ztttlltltttlz+++zttlttlttlttlttlttlttltttlttttlttlttlttlttlttlt1???????ztlttlttltltlltltttlttttltlttltttz+(Jz! .~     ~-   ~`  ..~..~...~...~....~.~........~.~.    //
//    ttlttltlttlttlttlttlttlt>  -_~.~.    ~?<><!   _Olttltltttttltttltttlttlttlttlttlttltltttlttlttlttlttltz???????1tltlttlttlttttlttlttlttltttlttttttttv! .~~. ._  ~_  _  _`    _~...~...~..~............~..    //
//    ttttltttlttlttlttlttltv! .~````_~~~~_..   ._` .ttlttltttltttltttltttlttlttlttlttlttlttlttltttlttlttltv???????1lttttlttlttlttlttlttlttlttlttltlltlv!._  ` _  ._  ~_       ..   _~..~...~...~........~....    //
//    ltlttlttlttlttlttltttv  __` ....    `__~~~` .zltttltttlttltltlttltlttlttlttlttlttltttlttlttlttltttltO????????zttlttlttlttltlttlttlttlttlttlttttv!...._   __   ` .~  .  .~~~~_.  ..~..~...~........~..~..    //
//    ttlttlttlttlttlttltltO-    ???1ztOz+.  ._ .(??zlttlttlttltttlttltttlttlttlttlttlttltttlttlttlttltttt1???????zttlttlttlttltttltttlttlttlttlttlO>....~....  _~-. .~_  `  ~_   `~-  ..~...~............~..~    //
//    tlttlttlttlttlttltlv!`  ......  _!?<` _` .+????zlttlttlttlttttlttlttlttlttlttlttlttlttlttlttlttltltv???????ztlttlttlttlttltttlttltttltttlttv>...~...~..~.   _~~_`      ~_  .  ~_   ...~.........~..~....    //
//    ttlttlttlttlttltl<` .~~_```~~`  .-.  ...+z???????zttlttlttltlttlttlttlttlttlttlttlttlttlttlttlttltv???????1tlttlttlttlttltlttltttltttlttlO>..~..~..~..~..~_        ~_  ~_  ._  ~..  .......`.....~...~..    //
//    tlttlttlttlttltv! .~_  .  .~`   `~~. (ttllz???????zttlttlttlttlttlttlttlttlttlttlttlttlttlttltttrt1??????1ltttlttlttlttltttlttlttltlttlO>.....~..~............`  .~`    ~_  `  ~.`  ~.............~...~.    //
//    ttlttlttlttlttv` .~` .v` .~` (z_  ~` (ttttlOz??????1zttltttttlttlttlttlttlttlttlttlttlttlttlttZ<rv???????zttlttltttlttlttlttlttlttlttl<_.~.~......~.~.~.~.~.._  ~~_  .   ~_  .~`   .......`....~...~...~    //
//    tlttlttlttlttt>  ~.  ?` -~` (tv! __ .ttltttttz???????zttltltlttlttlttlttlttlttlttlttlttlttlttc`.Z???????zttlttlttlttltttlttlttlttlttv_....~..~.~.....~...~..~_   __  ..  ~~      .............~..~..~...    //
//    ttlttlttlttltl:  ~~.   .~` (v<` -_ .ztltltlttlO???????1ztttlttlttlttlttlttlttlttlttlttlttltt>``.O???????ztlttlttlttlttlttlttlttlttv~..~.~...~...~.~....~......._  ~-     ~_  ............`......~....~..    //
//    tlttlttlttltttz.  ~~_.-~`    ..~` .ztttttltltttOz???????zttttlttlttlttlttlttlttlttlttlttttZ~.``.Oz???????zttlttlttlttlttlttlttltv~.....~...~...~...~..~..~.~..._  _~~__~_`  -..~...... ......~...~.~..~.    //
//    ttlttlttlttltltO-   _~~~~~~~~_` .Jtttltlttttltttlz???????1Otlttlttlttlttlttlttlttlttltttwv_.. `` ??zzz????zttltttlttlttlttlttlv~....~....~...~...~..~.....~..~.._         -.~...~...      ..~.~.....~...    //
//    tlttlttlttltttv<<!`          ..xtttlttlttlttltltttO????????ztltttlttlttlttlttlttlttlttO1zO&--....  ` ?7O???zttlttltttltttlttv!....~..~..~...~...~....~.~....~.~.~.........~..~......  <=- .....~..~...~.    //
//    ttlttlttlttv>`  .......   ?1tttltlttltttlttltttltttlz???????1Ottlttlttlttlttlttlttltv1??????zOO--.. ``.I????zttlttltttlttlv!...~...~..~...~...~...~.....~..~.....~..```_.~..........   11  .~...~..~...~    //
//    tlttlttltt>  .~~_____~~~~_  ?Oltttlttlttltttlttltltttz????????ztltttltttlttlttlttlv1????????????zo_``.Z??????zttlttlttltv!...~..~......~...~...~..~.~..~..~...~...~  .-. ...        ...==_ ..~...~..~...    //
//    ttlttlttl>  ~_` ......   _~- (ttlttlttlttlttltttlttltlOz???????zllllllllllllllllz????????????zz??zo .O1???????zttlttltv!..~...~..~.~.~..~...~...~....~...~...~..~.._ (=1    ...(+zl==l=ll> _..~......~..    //
//    tlttlttlt! .~` (tllltlli. _~  zttlttlttlttlttlttttltttttz???????????????????????????????1ugggggggayldgHNmmQgg&xzttltv!...~..~.......~....~...~...~..~..~...~...~...._ .=l=l=l==l=l=<<<?1lz. .~..~.~...~.    //
//    ttlttlttl:  ~  1ltttlttt>  ~  ltttlttlttlttlttlltlttltltlz?????????????????????????uggMMB961??1zOv1O1???????1vTWMNas_......~..~.~.....~...~...~...~.....~...~....~...  (l=z<?!` (=>     (=_ .....~.~...~    //
//    tlttlttttv  __. ??1zOttv! __ .!`?1ttlttlttlttlttttlttltttlOz???????zu&gg&&z????1ggM93?????????=????????????z??????zTHNJ-~...._(((((---_.~..~..~..~..~..~..~..~........  1=.      1z  `   => ........~...    //
//    ttlttltlt:  ~~~_..    `  -_    _  zlttlttlttlttlttltttltttttz?1ugMB"T111zTTWMNgM6??=??====?=??=???????=?=?=????????????HN,(+MH96<<??7T"HNaJ.~..~.....~...~............. .l_ .    +l- ..  1z  ........~..    //
//    tlttltttt:  ~``__~~~~~~~~...  .. .lttlttlttlttlttlttlttltlttAg#Y~(+????=???=??vWk=???????=?=????==?=??===??????????????=1TMez??==???+-_~_..7BNJ_..~...~....~...........  1>   J1=l===ll_ +l. .........~.    //
//    ttlttlttt: -~  ...     ```__~~._ (ttlttlttlttlttlttlttlttlwdB:(+?????=????=?=???ZC???=?=?==?=?????=uXHHHmz?????=???????1gkQQkmz??=?=????+-__- ?Wm-.~...~...........`...  +z   ?<?!`````  +=~ .`.........    //
//    tlttltlltO-   .lttltzz+(-.... -_`(tttltttlttlttlttlttltttqM=(??????==??=?===?=?=???=?=?=?=????=???dHWVfWHI?=??=????????dHyVVWqHx???????=?==1+__.,Wm-.~...........`..`.._ (=      ..     .l=: ...`.......    //
//    ttltttttlv!` ~??11Ottlt>   ->  _ ([email protected](+=????==??=??=???==????=?===???????????vTUB9C?=??=??????=??=?vHkWWWI4y???==?=??????1-~-(Me........`..`....... (l-. ...  .+z=l==l{ ...........    //
//    tlttlttltz  ~_..      `` __ (i...tttlttlttltttlttlttttqM3(???=?===?????=??????????=?????????=????=????=??==?????????????=?zOC1?<TR?=????=????????+_~7N,....`..........._ +===l==>  .<<<????` .....`.....    //
//    ttlttlttll_ ~~____~~~.~__~_ (tttttlttlttlttlttltttltOd#<+???=??????=??=???=????<??===?==??==?????=??????????=?==??=???=?????????<wR=???????????????+_(Wp-.....`......~._ -?!~```  _         _.......`...    //
//    tlttlttttt>  .  ...    `_~` .tlttlttlttlttlttlttlttAM5(??=??=?==????==?=?=??????=????????=??==?=?==aQQQax=?????==?==???????uggaz=<wR?????????=???????+_dR-.`........~..~    ............` .  .~......`..    //
//    ttlttltlttl&.. .lllltOz-. _ .ztlttlt[email protected]Y"[email protected][email protected]==???=?????????<dR-......~.....` ~` .....~..__``  ~` ..~........    //
//    tlttlttltltttOttttttltttz  _ (ttlttlttlttltttlttOdMC??=?????=?=?=?????????=???1???=?=??=?????dMNMNNt    WNb???=??????=??=dN:   dMNMUHOvrOz??=????=??==z?+dN_...~..~.~..  ~          `    .~  ...~.~.....    //
//    ttltttltttlO~    `~???<<<` ~_ zttlttlttlttlttttQMB1??????=??????=?????????????=?????=??=????=zTMMMMr...-dMD????????????=?JMo..(HH91<bwrvrvz?=?=??????????1db_...~...~..  ~~~~~~~~~~~~~~.~~.  .~....~....    //
//    tlttlttltttt: _~~~._.... ..~_ jtlttlttlttltltwdM5????????????????=?==???????<dK??==?=??==???=???=1WHHmQH93?=??==??=?=??=??vWHHY^j??<<jkwvvvOz??=????=??=??1db_...~...~` ~___```````       `  ..~..~..~..    //
//    ttlttlttltltO. ~_   ```__~_`  zttltttlttlttOgMB?????=??=??=??==?==??=?=????<j9==?=?????????====?=11v``(z???=??????1?????=?=??1l`.z??+_/Wkvvrrz?==???????????Hb~...~.._  _        ..........-....~...~..~    //
//    tlttlttltlzzto. `  ++((......xttlttlttlttOgMBI??=?????==?????????=?=?=??=<+W6????=??=????????z=<??!````_<11zz?=??=?=???=?????1{``_?<11_.Hvrrvvz???==???1=?==?WR_...~.` _` ......~_`  `......~..~...~....    //
//    ttlttlttl~ . ``   .1tv<???1ztttlttlttlOQgM9!1?=?==?===?1??=????<?=??==?<jdU=?=??????=??????=?1+..```````` ..z?=??=???=???=jAz!`````.z>~ X0rvrvwz=??=???+??????dR_..._  .  ....~._ .-  .~~..~..~..~...~..    //
//    tlttlttttl.?1ll=z+(.  ..++-..?1tttOAQXMM6?-`.1=?????????????=????????v<JHI????=??==?==?????=?=???1-````.+1??dK????????=??=?dD1z.` J1=>~ dSrwrrrO??????????????:?N,._  _  ``       ~_   `_.~.....~...~..~    //
//    ttlttltltt> .l=!~~?!  ll=v<1dQWWHHHWUXZ1???-`.1????=?=????=?==?????<<(XSvrv??=?=?????????????=????=i `.=?????v9WQQQkWYWmgQW9???z-,=??<~.WXvrvvrrz?==???=??=??>`.zWm. ~_..........~~_...   ..~..~..~.....    //
//    tlttlttlttO..lz .zz+- 1=> ..qSrvrrrvvvOz??=?-`.1??=??=??=????=???<<(j9vrrvwz==?=????=??????=???????z{.v?????=??=?=??===?????????IJ=?<~_JFMkvvzrvw?=???=????<` .???OWHa._~.~~.~._~~___~~_  ...~.....~.~..    //
//    ttltttlttlto.1l- 1ttz.(l1 (tWkyvvvvvzvvvvI???<`.1?==?=?????=???<<(+M#vvvvvrvz???????????==?===?=????z1??????=?????=???????==????==?<~(dD.JNwwvrvvI=???=?<! ..=1????rrwVUk,     .~`    ~~  .~..~.~.....~.    //
//    tlttlttlttttz.?=i.1tt_ =l_.ttZWHmwvrvrvZ??=??=<` <??==?==??=?<<(+M6dNwrrrvrvrrOz=?+?=?=?=????=?==?=?=????????=????????=????=?=????>_(M^...?Nwrvvvw?<<!``..+????=??zvvvzzzH/.` .~`    .~`  .......~.~...~    //
//    ttlttlttltlttO-.<z-.`  zl> 1ttAXHH0rrrwI???????<``(???=????<<(g#6???dNmvvrrvrvvvvwzz=???=??=?=??=?????????=???=??=?=????=?==?=?=<+gM"......?Nc+<<>_..-+=??=??1zzzvrrvwvzwW}_      ...~`  ..~.~..~...~...    //
//    tlttlttltttlttlz..?1=lll=v  `(qSvzzzvvrvwwzzzv?=<.`_1???=<<(dBz??????zTM0QAwvvvvvvvvzOzzz????????=?=?=?????????????=?????????1ugM"~....`..`.(Mmrvvrz?>???1zz?zzvzvzrrvvwW$..~.`  ~~_`  ...~...~...~..~..    //
//    ttlttlttltttlttltO+. ???!   1lWkrvzzzzvvvvvrw1==?1-` ?<<((MB1???????<~...(""HNmmgAwwzvvvvrz????=????????=??==?=?==?=???1uajHM9=_.....`...`...-TNmwwzO=1zzvwAvvvrvdHWpWYY!....~      ....~...~..~...~..~.    //
//    tlttlttltltttltttttttz++(+t&.  ?WmmXwyzvvrrrwz?==??<. .gM8v???????<~..........._<?7T"HMMNmggggg&&zzzzzzzzzzzzz&&aggggHMB"~..........`..........-THkWVWwvvvwq9HWQW9!.......~............~..~.....~.......    //
//    ttlttlttttltttltltlttttttltttttttOVWHSzwzzvvzvzz<<(+MMBOtv??????<~.........................~_~<?77""""""""""""77<!_.............`..`...`..`..`...._?YHkQkWY!........~.~..~..~.~.~..~..~....~.~...~.~.~..    //
//    tlttlttlttltlttlttltltltttlttttttttdHmmwwZOI&++gWMB0ttttv?????<!........`...............~...................................`..`......`..`..................~..~.~...~..~..~...~..~..~..~...~..~..~...~.    //
//    ttlttlttlttlttlttttlttltlttltlltlttttOZUUU9UUZOtttttttlz????<~......`....`..`.`..`.......~..~..~..~..~..~.~.~......`..`.`..`.....`..`......`..`..`...........~..~..~.........~...........~....~.....~...    //
//    tlttlttlttlttlttlttttltttltttttltltlttlttttttttttttltt1???<!...`..`...............`.`......~......................`......`...`....`....`....`...`...`.`.......~...~..~.~.~.~..~..~.~.~.~..~..~..~..~..~.    //
//    ttlttlttlttltttltltlttlttlttltttttlttlttltltltlltlttl1??<!...........`..`..`....`....................................`........                                                                              //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SCE is ERC1155Creator {
    constructor() ERC1155Creator("SCE Pass Genesis", "SCE") {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC1155Creator is Proxy {

    constructor(string memory name, string memory symbol) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x6bf5ed59dE0E19999d264746843FF931c0133090;
        Address.functionDelegateCall(
            0x6bf5ed59dE0E19999d264746843FF931c0133090,
            abi.encodeWithSignature("initialize(string,string)", name, symbol)
        );
    }

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
     function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal override view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }    

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}