// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Challe PFP from ESCA-NFT
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                               //
//                                                                                                                                                                                                               //
//                                                                                                                                                                                                               //
//                                                                                                                                                                                                               //
//                                                                                                                                                                                                               //
//       `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `   .............    `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `       //
//                                                                                ...(gQWgmmmmmgmmmHHHHmggmgmggmHma+...                                                                                    `     //
//                                                                         ..(gHgmmHYY""<<__::<<~~`` ````````` ~?7"TUHmmgHmJ..                                                                          `        //
//      ` `  ` `  ` `  ` `  ` `  ` `  ` `  ` `  ` `  ` `  ` `  ` `  ` ..ggmmWY"^`  ..(<<<<_-                            -?"UHggHa..   ``` ``  ` `  ` `  ` `  ` `  ` `  ` `  ` `  ` `  ` `  ` `  ` `  `           //
//                                                            ...(jgmgHY"^    ..J==<<<::;::::;::;;:;;:;:::::::::::;:;:::::::::?7UHgmHaJ<;;;;;;;;;;<--..                                                  `  `    //
//                                                       `..(+jdgmHY=     .(zlv11??>??>????????????????????????????????????<?!` _?<zTWmmHmx=======1+++;;;-.                                                      //
//      `  `  ` `  ` `  ` `  ` `  ` `  ` `  ` `  ` `  `..;j&WmHY^     ..zlz1??>??><<<?!~```  ...........  `_~?<<<?>?>??>?` .(;;;;_. ?<?vTHmmmxl=========1+<;<.  `  ` `  ` `  ` `  ` `  ` `  ` `  ` ` `  `        //
//                                                   .(jgmmB"`     .Jlz11??<<!~` ...((+??1zz&&++++WHHHHHHqmgHmaJ... _?<`.<;<!`.. !1lz-._<?1TWmmmxl=l=l======+<;_.                                          `     //
//        `  `    `    `    `    `    `    `    `  .(gmmB=      .Jtv1?<?~ ...(HgHheAXVVVVVVVfVfVVVVVVVVVVfVVfffHHHHmHm+,(lz.(UWffe, ?1ll<.???+VWmHmzl=l=l=====1<;<.    `    `    `    `    `    `      `         //
//      `       `    `    `    `    `    `    `   (Wm#"     `.Jtv1<!` .(+1u&wXffffffVVVVVVVVVVVVVVVVVVVVVVVfffffffffVWMN 1ll _<?TWffk-.?Wg,.>???zTHmHx===l=l====1<;_      `    `    `    `    `    `      `      //
//                                             .(gHY!      .zlv!` .(?zudfffVVfVfffffVVVVVVVVVVVVVVVVVVVVVVVVffVfffVffVHgh zl>.WAJ_<7Uff;,gg,.?>?????WmHsl===l==l==+;<.                               `           //
//        `  `   `  `  `   `  `  `   `  `  ` .dm#=       .lv! ..?1uwuXVVVfVffVfffVVVVVVVVVVVVVVVVVVVVVVVVVVVfffVfVVVVVfHg[.ll-,WWpk&-?Wf;,gm,.?>?>????WmHe=========1<;.  `  `   `  `  `   `  `  `      `   `     //
//      `     `                            .dmB^   `      `.-?zzuuuXXVVVVfVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVfWgH,?lli..74WWWwkX,(mg,.?>?>?>??zWmHs=l=l==l=1<;_                          `      `       //
//                `     `   `     `   `  .dmB^       `     jzuuuuuXVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVffWHY` ?1llz-.?TWWH=.Jgm <<?>??>??>?WmHx========<;-    `   `     `   `       `  `          //
//         `         `         `       .Jg#^            `  ,uuuuuXVVVVVVVVVVVVVVVVVVVfVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV=`.(<1+. ?1lll<. .dmgY^..(. ?<?>?????Hmkz=l==l==<;_          `         `                  //
//                                    .mH=                 ,ZuuuXVfVVVVVUUTTC11??+HHHHHHHHHmggmHkkkWfVVVVVVVVVVVVVVY= .(;;;!?lll1.._?zlllv= .(zz1llz-._?>>???TmHs=======<;_                                      //
//                                  .WmY                  .ZuuuXVVWUT1?<<<<<<><~:~::~::~::~(<<_(?7TUWHgHkkWVVVVVVV'.:;;;!`.Ja,.?1llz-. `  .;;<!.J._?zlli. ?<???Hmkz======+;_                                     //
//                                 JgB'                 ` duuV777?<<<:::~::(;<:~:~:~:~:~:~::~~<;_::~<<<(?TWHgHkWVk ;;;`.JZXHHqqh..?1lll<  ;;_ [email protected]?1lli.(>??UmHx=l====+;<                                    //
//                               .Wm=                  `.wV^      _::~:~:~+<:~~~~~~_~~~~~~~~~~~_<<_~~~~<;_:~:?TUHH;.z+< XZZZZZWHmmH&._zl1 _:;-,[email protected]?ll-.>>?dmms==l===z;<                                   //
//                              .gH^                ` .(V^        .<:~~~~<<~~~~~~~~~.~~.~..~.~~.~~>_~~~~_<<__~~:?uS 1ll-,ZZZZZZZZWHmm[.lll (;;_,XWyVyHHHs,(mg+ <???Hmk======z;<.                                 //
//                             Jgf`    `.        `  .JC<`         (>~~~~(<~~.~~~~.~~~.~~.~~.~~.~~~_<<~~.~~_<<_~~.ju}.llz.jkXZZZZZZZXHm,(ll> <:;.([email protected],(ggL <?>?HmR======1;<.                                //
//                           .dgY      Jt>_.......d0z<!.        .(<~~~~(<~.~~..~.~.~~.~~~~~~.~~.~~.~<<~~.~~~_;<~~_wX.(lll TWpWXZZZZZUmH.(ll: [email protected],(ggh <??1HgR==l===1;;.                               //
//                          .Wm%     .lv! (+wuZuVC<<` (<~.    .(><~~..(<_~~.~~~.~~~.~~.~..~~.~~.~~~.~<<~~.~~~~<+--(Xo lll-.++ZWpWXZZZWmN.1ll- 1lz.(TyVVyVWHgo,Hgh.<>??HmR======1<;.                              //
//                         .Wm%     .lv!.J+uuuXm+~``.<!~~~<<<<<<~~.~~(;~~.~~.~~~.~~.~~.~~~_(((JJJggQkWmmmHHHHBBBBYYWM;-llli..74ppWZyZZWmb 1ll. 1lll<..7WVyWHg\,gm] (???Hmy=l====1<;-                             //
//                        .Wm%     (v!.+mHUuXXHY``` .`` .~~~~~~~~.~~_><~~~.~~.~~((JJ&gkmHHBYY""=<<~...~~_......._~_(uz,.1llldmJ.?TZZZZ0"..llz`(,.?1llli..?4V!.ggB!(`(>?JmHy==l====<;-                            //
//                        dm%     <<(WHWuuuXgY```` .``` ~.~.~.~~.~~.(<~~((J&QHHHYY"=<~..............~.._~_.~.~...._:(Ozw-._<dggmHa,_7=.JgmH? [email protected]?1lllz-.dggY.dY (>??dmH~.<<><+.<;_                           //
//                       JmP     [email protected]!`  -`._``.~~~.~~.~.~((JQWmHY"=<_.........~.~.~.~.~.~..~..~._:_.~.~~.~._~_(7wzz&[email protected]@Na._?zlll7^.f`.+??>??WmR_+==z,W,<;_                          //
//                      [email protected]    .zz ?gkuXWH=```.~~._ ..~.~~~(JJgmHY"TI......~.~.~~.~.~..~...~..~..~..~..~._:[email protected]@m,.``.J= (??>?>?>?mHxlllll.4;<!!                         //
//                     .mH!    zv?<..4mgY `` .~~(;~~~_(JgHHY"7~..._<:.~.~...~....~..~...~..~...~..~..~...._:_..~..~...~.....~?TZXX+..-..WfffpfffpbkbkkkHMHMkHg% +?>??>???-wmKl=l=z~T'J?????i                     //
//                     dm%    xv?><!.JH^``` ~~._+iJgmHY=!......~.._:_..~.~..~.~...~..~..~..~.~..~..~..~..~._~.~..~.~.~.~.~.....~<?77!vgkpfffpfffpkkkbkkkbkbkWg] O?>?>?>???jmm/???~+`(~Jz?<_.W,                   //
//                    .gK    Jz??<`.VY ``` ~(JgHHY=!...~..~.~.~.~._:~....~.~...~.~..~..~..~...~..~._-~..~...__..~...~...~.~~.~..~~....?gkpfpfffpWbbbbkkbkbkkkg]`lO?>??>>?>?WmP!!!! (~(llz?<_.H     `             //
//                   .Hm>   ,l1>! .W^```..dHY"!+>..~.~..~..~.....~_:..~.~...~..~..~..~..~..~..~..~._<..~..~..~...~...~......~...~~_.~..vgkffffffWbkkkkkbkkbkbgD`1lO?>???>?<,mH<<<?i <.<l=z?~d^                   //
//                   ,mP   .tz?!.Jf!..dHY"~...(?_.~...~..~..~.~.~.:~..~..~..~.~...~...~..~..~..~..~.1<..~..~..~~..~..~.~.~...~..._~..~..4gWffpfpWUYWHHHWkkkkkgF`<1lO+<<??<.?mmZlli.i ?-....J!.                   //
//                   Wm\   tv<`.XWdHBYv`` ..~_?:`..~..~..~..~..~..:~.~...~...~..~..~..~...~..~..~...(<..~...~`__<..~..~..~~.~.~....~..~._Y?ffVC<<++zUUUWHHgHHg] :<<!..+gQ&, 4mRlll>,F ......~;.       `          //
//                  .mH   (v?:`WY"~,??:`` ...(< `~..~..~..~..~...~:~..~.~..~...~..~..~..~..~..~..~.._1<_.~...``__1-.~...~..._ `.~..~..~.._:?C<+rrrrrrrrrrrrWHgL _! JH9UvzXHgXgKl=<[email protected] (!....?>_;.                 //
//                  dmF  .l1?><` .+<(?~``.~.(?!`` ..~..~..~..~..~.:~~..~..~.~.~..~..~..~..~..~..~..~.(?-` ``````_(?-`_.~..._ ``` ~..~..~..(:jrrrrrrrrrrrrrrwyXHH,`JHXvvvvvwUgmK...< (~Jlll=i.a.;-                //
//                .;Wm\  (<!` .(?<``(<``..._+>````_~..~..~..~..~..:~..~..~...~..~..~..~..~..~..~..~..(?< `````.`..(?< ```.````````_..~.._(<zrrrrrrrrrrrrrrrdZyZWHhgHvvvvvvwZHmH.((+.<.1llll=~d'.(((((.           //
//               .;jmm`  +++?<<~`` .<<```~._~ ````._.~..~..~..~..._:_..~..~....~..~..~..~..~..-.~.`_.(??<`` .-.`` .(?1.````..-.~_.  ..~.(<wrrrrrrrrrZ<<<THgHkkyZyHgHyzvvwwZXgmH====1.+.1==z~d^,!.(-..<.          //
//             `.;+dmH  .!??+-.-_--(+>```._:~``````` ..~..~..~._.._:._..~.._. `_.~..~.._``` .~<.``` .(?~?<` ...~...~<??<.``..~..~...~..(:zrrrrrrrrZ>:<~~~~:(THHWZyWggHkkkQH#TmH=====1.?<<<<?^.!,lz?<~.4[         //
//             .;+=dmK  l1-. _????jgz>``.-:~```.`````` `_..~.._<.~(?_` _.~-_````````````````_~?.````.(?__1< .~..~..._?<<?- _..~..~..~._:+rrrrrrrrZ:<```__~~~~~7gkyZWH/7"gP`..mH====lv_J<<<<+.__(llz?<`(%         //
//            (;+==dmb .l??>?>+(-`dHz>`` _~``` ...   ````````.?~._??>``` .(<```````````````` _?_````.(?<._11-.~..~...(?-_<?-.~...~...~_:zrrrrrrrO<<````` ((_:~~?HHyZHN `4b``,mK?===v_<.=llz.X,.<.<<<!(%          //
//           (;+===dgb (v?>?????:.mHI<``-~`` ........~._..``.?!..(?<1 ``` _?-``.` .   ..``.``.<< .-..(?~..~<?<_..~.~..<<.._<?<_.~..~..(:rrrrrrrrC:_``` ..(???<:~/gHyUg[`JH.dgm] ===`<.llllll.4,.?????^.          //
//          (;+====dmb +z?>?>>?>_.gHr:`.:` -~.~.~.~...~..~ (<~.._?>_?_````_<1.`` .~.....~.- ` (?_....(?~~._._<?<_.~.~._?<...~<1+-~..~.(<rrrrrrrr>:_`` ...(????<:~JgkyWH ,mY'Xmb <==-~-?l=llv(H~=====lz;<         //
//         (;+=====dgK tz??>??>>`,gf$:_:~....~.~.~.~.~..~-+<_..~(<_.<1.``` _1<`` ..~.~..~....`_?<.~.~(?_..` _.~<<1-_.~.(?_~...._<?-_..(<rrrrrrrr<:_ `..`.~.(???<~(HHZWg;`` .mgM .===-_-_???_V~z====l==z;<        //
//        .;+===l==dgH l??>??>?<`dHfk::~..~.........~..~(?<...~(?~~._1>`` ~._?_`-~..~.~..~..._.<<..~.(<.._```` `__<<?+(-?>.~. ~.~_<11-(:Orrrrrrr>:~:---+:...???<~~dHyyg#YYBHmMNa. ?1=i.<<<<~.==========z;_       //
//        :<=======zmg<l??>?>??:`WHVf:~...~.~~.~.~..~.(+<~...~(?>..~.(?- ...._:_ .~....~..~~.~.(?_...+<~._```````.  ._~?<>```.(,...._<1+zrrrrrrrI;:~_???1...???=:~JgyZmD```dm% ?YMm, ?===l=======l======<;.      //
//       (;+==l==l==Wm]l???>?>>: gHf:~..~.....~..~.~(+<~...~.(?>.~_ ~.(?-~.~.~_:...~.~..~...~..~1<~._?>.~``. .(JZ""<!``````.dHH]` _~..~WHrrrrrrrZmb~~<?????????<~~JgyymD` .mH     (TN, ?===========l====z;<      //
//       ;;=========dmKl?>?????: gD+~..~.~.~....~_(?<~..~..~(?>~._`` ..<?-.~..~~:_..~..~..~...~.(?<.(?<._`.(7^``..JgWHHHHHHHbbWb``` `..JgkrrrrrrrXg+~~<???????<<~:dHyym]``dm%       (WN,.1=====l=====l===;;      //
//       ;<==l==l===vmmZ??>>?>?:.8?!..~...~.~~_(+<<_~..~..~(?!.._```` _.(?-....~~:_...~..~..~..~.<1_(<.~_-=``.JHHWfffffffffWbbbHHa,```~.WHrrrrrrrrWH/~~~<???<<~~:(gHZWg\`.mH         <dN, 1=l=====l======<;.     //
//       ;<======l===WmKz??>?>!`,?!.~..~.._((?<<~...(_.~._(<~.~_...--...~(?<~.~..~:_.~..~..~..~.._11?:._```.XHffffWWWHHHHWWbbbbbbkHh,` .(HHrrrrrrrrWHx~~:~~~:~~:(HHyyWK` Xm%        `<_?N, 1==========l==<;_     //
//       ;<===l======vmm2>??>! (<~_--((+?<<<~.....~(?_..(?<~.__7!````-??T1-<1-.~.._:_..~..~..~..~.(?<.~_`.dHkbWWHHHUZuuuuuUWHHWbbbbkHh._.(HHrrrrrrrrdHNJ~:~~:~(JgHZZWg% (mH....      <:<dN..==l==l==l====<;`     //
//       ;;1======l===WmR?>??..<<&&z>~``` ....~..~.(<.-(<<HmaJ.+kHHHHHHma...?1+_.~._:_..~..~..~..~.(?-..`[email protected]=?uuuuuuuuuuuXWJUHbbbbkH,_.JHHwrrrrrrrrVHgma+&dmHWyZXgF`[email protected]<Mb 1==========l=;:      //
//       (;+===l====l=vHm2?>?>--`WK?_```` ..~..~...+<(<<..JHbbbpWfffWbbbbbHH&-<?<_..~~(-.~..~..~....(=-~_WkHHS `.XXVXZZXuXZuuuW/_THbbbbHHJ?>4HmrrrrrrrrrrrXUWyZZyZWgF`[email protected]@[email protected]@@@@@MMMN .=lv?!!~~??1v;!      //
//        :;1====l=====dmH+????<`d3>`````..~..~.~._?<<.~_`.HbWfffpWWWWWWkbbbkHh_<?+-.._11-.~..~..~.~.(?-.W#1WuuVOdOdX7TyydkXuuXh..(gbbbbH6<..JgHyrrrrrrrrrrwyZyyXWH=`[email protected]@@ND;<[email protected];;[email protected]@MN (! .JNMMMNa, _`      //
//        .;<===========WmR?>?>?.,?:``<```..~....~_?>..``.HHfffWHYTdWUZXUWHHHbHb` ?<1-_.(?1-_...~..~..(?-<.(WVOlOSOy{``jkwkttwZW<..mkbW9<?~~.JgWHNmyrrrrrrrdZyXWmY``[email protected]@MM<;[email protected]>;[email protected]@@MN  .M"`     ?TM,       //
//         (;+=l==l==l==vHmR?>?? .?``.=_`. ..~.~...?>._`.HHffWHY_(f``(ZuuZuuUHWm|``` ?<1(?>?1+-_..~..~.(?<.(Stltwk?Wl .d$zklttZX:` mbH$-?>..~dgfWMHHgNmmQQQkHHY= ``[email protected]@[email protected][email protected]@gMN.MF         (?M[      //
//          ~;+==========vHmy?><`(<``.1>```_~..~..~<<~.`dHffWH^.(Wl..JXXXVWXuXW,.`````` ?<!`` ?<11+((---(?<(kltv;Xc?TUV3;dC?OltW``.H#^_+<.~._WHWMNNQNMkHHgY! `` ``[email protected]@HM$<[email protected]@@[email protected]@MNM3         .<:MF      //
//           ~;+==l==l====vHms?<`(>``~(?_`` ..~..~.(<.~.mbbbq:..JSuVXOX77WyXOOXk__``.````````````` __~!!~_``4yv<<?U+<<<<J3;;+ld%``X3._(<_..~([email protected]@MMHkHH^``` `` .Wm%[email protected]@[email protected]+;7Y>;[email protected]@HNM^          (<jM%      //
//            _;<=====l====vHms:`<>` _+?1.`` ..~...(?_.,HbbWP...d0OOkwW `,kd0tld) ````````````.```````````` .W{..(~__.._.~;;+wf``` ._(<[email protected]@MNMHgHJgWHHHma.mH^[email protected]@[email protected]@@@@MM^          __+MD       //
//             _;<======l===vHmn`(>` (1Xs?-`` ..~.~(?<(dHbbWD.._zZttXZ4k+X3d0ttw$```.`.`.`.``.``.```````````` T+(_........;+d=````-_+<_.~..([email protected]"!``` ` (mHNx     _7""HMMMNNNNMNMNF         .(jd#'        //
//               ;<1l==?_....,Wmh(?.(1WkVkz<.``_.~._?dHkbbbkH_``,ktlzS+;;;<Z;;1w$``````````.`````.``.``.`.`````.TA------(JdY~.``..(?<.~..~([email protected]#HP``` ```.dm9<<TN,           (:+<<<dNM,    ...gM#"           //
//                ;<1=>.!.....XHmHx+<`?gHVys?-.` ..~?>_7UHWbHL```jZ>_(?><~<<<;<d\```.``.``````.````.``.```.``.```` _~<<!_......._(?!...~_([email protected]=_H]`` `  .mH= <:(dN           :<_<:(Nt (T"""""!               //
//                 ;;>.!.l=lll.4ZHm2`...WNkfWA&&..`.<>._``_"Wmo```1..(_......(jf`````.```.`.-.``````````````.```......` .......-+<~.-(([email protected]@MM=:(?m,`` .dmf` .<<(d#          .<<(<jM^ +1+((-_~`               //
//                  <_(-?ll=l=>.P.Hmh+<-`?NNMMMMMN1(+<(,````````` `(4+_.....-J=```.`````````_!``.`.``.``.````````.... ........(???<ugx([email protected]<~_<?UHJJg#^ .(<(jd#`       ` .~<:<jM^.=====<:!                 //
//                   <-?i(111>.>.!.Tqmn. [email protected]@MNR._.(H-``.```````  .7UrOZY"!```.``.``.``.````.````.````.`.``.``.............._([email protected]&++J+-(+gmMMNmNNNN#!           _:[email protected]`.=====<;!                  //
//                    <_-<<<<?! !.llvWmH,,NNWNM#MMNMMMMNN(..`..............````.``````.`````.``````````.`````.````.........._(dMMffWkkMMMM5<_;?MN.` `(mmY7777TUUUWNF        .(<<<?T5.(=====<;!                   //
//                     `.?<<<1- <.<[email protected]@MN|`.ND7TMm..-`...........`.````.`````.`````.``.`.``.```.````.````.......(NMffffpWkkH# .(<(<<(NF..mmY`     (<(_<NF        v.dMWgJ,_?1==z<;!                    //
//                     ,!,1lli(i <[email protected],MF   ?Mb..............````.``.``.``.`.`` .````````````.````.``````.`..NpfffWkkHM#^  ;~_(<jMmmHY`       <~_(jN]      -(~(#jv+-?Ba-?1;;`                     //
//                    .!.<>1lll,h -!!!!! ;([email protected]@@MNN]   :M#..............``.``````.````````?Wn-``.``.`.````.```````````..MNpWWHNM"`   .(<_;(NMH"         .~<:;(N\.z<<1+J>_dCI-(JMo?He_1~                      //
//                     <._<?1l!J%.<?<<<?- <. 4MkWHMNNNNb.  ~dMa-...........``````.``````.``.``` U%`.``.```.`````.``.``.. (&NNMNM#"`      .<:((N9^.........  _<:(_JN_l_.._=I~(@?<d1d#~<<db.1                      //
//                      1.._~~,^.!.lllli(i.> .MNMY""""""HMNxdNMNm,.....`.````.``.``.``.`````.``````````````.`.````.` .(gNNN#^            .+MMH""""""""""""""WMR_<dMM1i--J=z_?Nx-M#[email protected]!(/                      //
//                        ```~..; =lllll>(] .M"          _?TMNb(TMNJ,..`````.````````````.````.``.``.``.``````.. .(+HHHMMY!            .(#=                  -N(+M5..+====lv.(@zg+(jM5_(?`                       //
//                            ;<.<.1l=l<[email protected] .M^            _:~TNp:~7MNMm.,. .``.``.``.``.```.``````.`````... .((dgHHHQMM"              .M=                .l. J#(z<~_<====l>_J5jM37"=_(!                          //
//                             :<.1.....Y .N$          ....JJJJNmJJJMNMMMMNa+..-....`.``.```.`..`.....-((gWgHHHWVWMNMHr              (@  .   .          [email protected]:~ [email protected](z_.._l=l=!(M3+MNJ,.+!                            //
//                              :!......  d#          MMMMMMMMMMMMMMMMMMMMMNNNNMNNMNggg+JJJJJ+&gQkHgmHHHHWVVVVWNM#=dyZr            .d#  `.    .   .   [email protected]:~~.M>(mz++<<<+:([email protected](`                            //
//                               .!.....} NF         .NNV77TTTT4ppppppppppppppppWHHMMMMMMMMNNNNNNNmmQkkWVffWNM#"   jyZr          .Z1M'                d#:~:(NF+<<_((Jgg+-..?"Hg#.-<`                             //
//                              .!.?1llz. Mb         _7Y6<::~:~<XZZZuuuZZuZZXXUUUUWWWWppppppppppHHMYYYYYWHHH5.     (yZr       .(=! (N....        .....MC~:([email protected]+~(gB1((x+><M.(i_?~(!                               //
//                              (- <?1ll:,,Mh.       _~~::~(XZZZZZZuZZuZZZuZZuZZuZZZuZZuZXv++77UWWWZ<;;;;;+?(<     JyZ[     .Z=    d#[email protected]:(+M8_1_?mj<(#dh~+#.+==z11.                               //
//                               _- <<?:,%. TNa.       .MNZZZuZZuZuZZZuuZZuZZZuZuZuZuZZuZZk&++++dZ7T>:;;;++&z/!    dyZ}  .J=~      M]    `~??????!~` NNMM5<:([email protected]:...1-                              //
//                                _<<<<<!,=1. ?HNMmg,.  (NNuZZuZZuZZuZZuZZZuZZZuZuZZZuuZZZZuZZZuZk<::;:::jWWMb.NMMakyZ+J7!         .4NMMNNmmmmmNNNMNNMNr<(<<_jMo-Jh(JJjgdD_z1i-_(z!                              //
//                                                                                                                                                                                                               //
//                                                                                                                                                                                                               //
//                                                                                                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ChalleESCA is ERC721Creator {
    constructor() ERC721Creator("Challe PFP from ESCA-NFT", "ChalleESCA") {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC721Creator is Proxy {
    
    constructor(string memory name, string memory symbol) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xEB067AfFd7390f833eec76BF0C523Cf074a7713C;
        Address.functionDelegateCall(
            0xEB067AfFd7390f833eec76BF0C523Cf074a7713C,
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