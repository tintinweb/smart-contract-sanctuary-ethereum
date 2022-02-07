// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JakNFT Mints
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                    //
//               ╙╬▓╦_   . ╔_- ▒▄╙╙╦╠K╬╬#╬╬╠╬╠╬▄¢╩╚║╩╙╬╬╠╬╠▒╠╩╩╚Ü░░û▒╠╠Ü_╩_╠╬Ö▓▓╣╬╬╫╩╬╩╙` ,▓╬▓╣╣▓▓╣╬╣╣▒▓╬╬╣╣▓╣╩▓╬╬╩╬╚╬_U⌂²  .  `_╓``                 ___  _=     ╒▄»»╠░Ü╙Ü=`╙╙`É░Ü░»▒╚╠╚╩╠Ü╩╬Ü▒░]]ÜÜ╙` ,@╠╩`          //
//                 ╙╚╣█▄, .[_"╬╠╬▒▒╬╬▒╙╠╬Ö╬╬D║░`╙φ▓j▓Ü╬╬╬▒╙╚▒╬▒░╩``╠╩_[░╦``_▒▒╬╫╬Å╩``   µ▓█▓╣╬▓▓▓▓▓╢▓▓║╣╬╠╬R╣░_╬,╦,▄░░░▄╦φ╬▄▌'   _-               ,     =`  `    ╔_Ñ=\░░__,. `_YÜ_=░▒``` ûYÜ»∩` `»H ,╔╣╩╙             //
//                    ╙╬▓▒▄`[R{]Ü╚ÜÜÜ╠╚Ü╚É╚░░░▒mφ╙╬░╠╩╠╬Ü╠`░»,╙»»»░¥  _'`╔▄╣╬╬╙▀  ╓   ╓▓╣╣▓▓║╣╬▓█╬▓Γ╙╬╬╬╠K╬╝;[▒▓╬╩Ü░░╩`JÅ▀^   ╓=`       | _     _+__   __²       [ h-∩ _``»_|░::`»`╚╙___ __!=`Ü```▒╔╬╩`               //
//        .__           ╙╙╬█▒░Ü▒░UÉ_==Ü;^µ▒¼ì╠╬╒_[╩╩╔0░╠░Ü]`╙╙» P=`    ╔▒╬╬╜,   `  ,▄=╬╬╬╬▓Ñ╣▓▓▓▓╬║▓▓╩▓`Ö`_╔#╩╬╩ÑU░#▀`,    ,≤^    ^  __   Γ '   =_   û░__,╔R=     ² `_  _`],._░_`░` ,  ╙╚»` |╩░_╔╗╬╙                  //
//         ,_   ``=┐,__    ╚╚▓▒▒╩l_!`╚|ÜYµ »»`,R`ÜÜÜÖ░_╠.U ░'`[H`   ,╔╣╬╩╙` ²   ;╔║▓Ü'╓╝╬╩ ║▓▓╣▓▓▓╩╠╩Ü▓^ ▄╝╙]╙░░░Ü╠▓╩`   ▄R`      ╓▄`└   ,▒▒U    _r `Ü╩╙` . !      `'``_!, .`_      _       _╔╣╬╩^                    //
//        _|»     `    _`  {;╠║Ü╙Ü;``_╘`»!h░Ü╙░▒╚,╠░╔Ä, `⌐'__``  __╔╢╠╩╙  ╓▒▄▄_║╬▒╬╙║HJ╙^ ╬▒█╬╩^╙`╔▓Å` ╓█`,A`░░╔Üφ╩   ╓φ╩╠H`      -     _╚╩╙`       `  [⌠ ^`_         '╙Ü`_u²`Y        ≈  _╔╣╩╙`≡`` ``#     ._        //
//        '`   _ _       ».. └▄╠░╬Ü»U_¥`-`,`╙`_▒▒▒_=U_.»`.``  - ╔╬╣╬╩ ╓▓▓▓▓▓▓H  ║█` ╠╬  ╓╝╬▀ »░╓╔╬╬` ╓█╙   [_,╚╬^   ▄▓╣╜╙               __╓╓÷          r╙-  '           ╚``∩           _╔╔░Ü___╔ - `»ñ._   ∩_`╦ w=    //
//               ` _:      = `╠Ü║╝Ä╣╩╩≈ =` ╙,j╠░Ö░Ü=░ ;ù__».'_j╬╠╠╜  ,╬║╫╬╠▓╣  ╔█Ñ :╩` ╔ __ ╗R`╬╩╩ ,▓╙   ¡_»`[^   ╓#╩`  _            _▄⌐╙╙`  _ ____╔▓▓@▓▓▓▓▓╣▓▄╓,╔╦Kφ╗  ,_           ,jÜ╩╙       ^»╙.═`    m ²_».     //
//          `,__   `     `   -_+▒╙╬▒▄φ_ ` ⌐_╙φ╬╠╠Üm╙░²_D=`_;╬╠╬Ü^_.▄▄╬▌╣▒║Ü╜╙ ▄█╠  __ á ▓█ [╩`'`  ▄█`  #_/_.^   ╓Å``              ╓φ▀ _,╔╦╦╦╦╬╠∩»_╠╬╠╠╬╬╬╬╠╬╙``  `¡╠╬R=≈╘R╬⌐ ²%≈≈.,▄╣╩╩`            '         Ü- ì    //
//           |```∩      ∩ .__ ╙╬╩H║╬╠╬╬▓ `'φ╬⌐ `.\_j'╙╚)_╔║╣╣╩ _;╔╣▓╝╬H╚╠▒( H╔█░  ╔▓▌▓ ║█Ñ,Ü`   ╓█▀  ,╙ ' ╙   ,R`             ,▄▒╣╬@H`░▒▒░╓_╠░╠Ü▄▄╬╠Å╩╩╩╩╩╙╙`^`    Γ ¬╔^╚≡░ _   ╓@Ü╚╙                 '╙   ╔`Γ_╘≈U    //
//               `        ,_   ░▄╠▒╬╢▒▓╬▒R▒╠░▒▄▄R '╓Γ ∩▓╙╠╠▓▓▓j╬Ö╣╬╣╬╬ ║█`_ ▐█ Ü Γ░╠║▌ ╩╩ ╬`   ╓█`  ,╙  /    ∩  _-        _╔▄██╬╠╬╬╬╬╬╬╠╬╠╙╩╩╩╙╚``   »»-░∩_ _=⌐   _`░╙`  `^^»,▄▓╠╩`                        '`=▒░░÷    //
//                  ____  _ =;║⌐╚╠`╙≡╙░=Ü▒Ñ░╙╚╩▒▒▒▄ |▄╣╬╢╬▓▓▓╬Ü╠▀╠╬╣█▌ ╚░░ ╓║Ñ`__`»▐╬ ▐Ü`║Ü   ╔█   _`  É   ,``          ╓▓▓██╬╬╬╠╬╩╩╩╙╙╙` ` ``_____        [Ü__;;_=^    `   ╠╠Ü╙  `                             ╙-    //
//        _ ╔≈!m  _÷Åⁿ^` - _⌐╙▄`»[╦╔'``╠Üh.`+#Ä╙╚╠╬╬╠╠╩Ñ║╣╣▓▓▒▒Ü╣╣╣╣╬H [╙░_╠▌ .╬H ▐▓▌ |_ Ü   ╔█ '    ,╜    `          ╔╣██╩╚╬╩╙╙`_,▄▄≡≈^,▄#Æ▀▀▀▀╙^^""""`^" ¬    ^           ╚`  ` `                        ▄▄▄#▓▓▓    //
//        ]Ü╙░╙▒▒▒░¼≡⌂ "╔m╓∩╔░≡=m{▒Ü_``-`.²²=`,╙▒╠╬╠╬▒╦_╙╝█╣▓╣▒▒╫▓╬▓▓▒ ╠╠_╗Ü  [Ü  ║█  |⌐▐`  Φ█ ╔  , ;           _,- ╔╣██╩╩` _▄▄██▀^`               `                        _       _.   H      ___╓▄╗▒▌   ╝╩╙╙`_╔    //
//        |░╦Ü▒_` ╙H,»KR]ÜHH╬▒▒╠╣W╬░²░» _╔╔U░,╠╬╠╩╩`╙╠╬▒▓░_▄╠╫█▒╠█╠╬▓▒ Ü╠╗▒»   `  █▌  [ ╚` ╠█`      ╣   _▌     ,  ╓╣║▓╩=R` ;╙``__                                          ' !≈   \      ▄╓▄φR▒_╠╬╩╩╩╙╙`   _▄╦RÜ``    //
//        ╦▒▒╚░░∩_¼░Ü»` /=░▒`ÜÜ░░╠Ü╠▒╠░▒╦╦░▒║╬╬╩` $_ ¡╚╚╠▓▓╣▓▓█╠Ü╠╬╬╬▒║ ║▓▌ ``    ▓▌  ╚_░  ░╙    [_║▌   ║▒╗▄m-⌠` ' »╩╩╙`_  _▄φ╗H  ,▄▄▄@K¥R╙╙╚KR╩D╚▓▓▒▓▓▄▄▄▄__                '  `  ,▄▒▓²╠▒╠   ```     ╗▄mÜ ```        //
//        ▒╠╬▒░░░`_!`'░╔▒░ÑU=░¼=Ü_```!╙╚╠Ü╬╬╠╬╠▒▓╦▄▄╦_╔╣▓▀╠╣▓█▌▓▒▓╝▓╬▒▓ ▐╣⌐ ╕   ∩╒╣_  `|`_'`    ,ÜÄ█Ñ ,╫╩╙`  = ,  -;===¬_╔φ╗'     `` ▄╓          __________``"^ⁿ≈._         ╦U╓▄▄^╙Ö╚^"  R╜  `  _,╔@░```  `   ,▄▒▓    //
//        Ü╠╠Ä╝▒▄φ»|H`)]µ▒Pµ÷P╙╚░_╔=_ »╗╬╬╩^¡[╩╩╚╚╣╬╣▓▓█▓▀╙█▓╬██╠ⁿ▓█╬╣█ ║▓ »║` ▐` ╣▓▒_ ║▌`     ▄Ü``╓Γ `  ,=`  » `` ╓╗▒╓φ▓╣▓▀╗φ█▓▓▄╙``    _╓-=²```                         ` ``````        ╓__╠RR````     _ ╔▒╣╩╠Ñ╙    //
//        ╬R▒▒░_╙╚U░░=}░╠:╙U ░]▒]▒__╔╬╣╬╩`    _. '╦_█▓Ö█╣▓▌'╣▒║█  ║█╙╣███▌H '⌐  █ `║▓Ü `      ╬`  P    »`      , ^╙╙  ▄▓█████╝▀╙█▓_,_»=-. __                                         ,▄▄▄╩ÜÜ╙`        ╓r   ╙╙^        //
//        ▒╠Üù░Ü²░U░░.`:░▒▒╬▒╙╙²Ü`»▒╬╬Ñ` '`  _  ╓,▄╣▓█▓█╣▓█  ▀▓█  '▀▀║█╣█⌐!   _ ╠  ,╩       ,   /`   »         '   ╓╦▓╬▓▒╠▀▓▓▓▓▒▄╙▓█╗  _ ``    `∩==___                              ` ║▓▓▓▒`     __▄▓K╩╙              //
//        ╬╠░╚░░``_]░╚╚Ü▒]==▒╦¼░░▒▒╙╙ j▒@▄»╔_)=»Ü▒║╣▓╣▒██╣╩▒  ║█▒  `0▓█╣█     ΓH   :           `              _╔▓▒╠▓▓▓╗▓╬║▀██╬█▓▓▓╣█╬mn∩ R#█   '       `                            __║▓╬╝╠▒▄_╓▄▓╝╩╠ ` ┌  ,_          //
//        ╬╬╠▒░░=`÷``__=░_╔╚╚╠╠▒╠░ÜH '_╠╬╦K░¼φ░µ╠▓▓╣╬╣▓███▄Φ█▄▐█▒▒   ╚███▒  _                             _, `╙▒▄▓╣▄▄▄▄▄╠╙██▄`║╣╣▌²╣▓▄=` , __                                        ` ╚╬_,╠╬╬╬Ü╦▒╠╣H     ╠║▓▓█▓▄▄    //
//        ╬╠▒╠░░`=Ü░▒░░Ü╚¼╬Ü╠╬╬╙╙╠╬╬▓▒@▒▄ÄÜ▒░╠▒▒╬▓╠╬╣╬╙████¼ ╙╦╬Ü╚▒_  ║█╙╙  :      ! ,  _  `             φ╬H,▓▓▓███╣▓▓▓█▓▓██▓█▓╣██`║╙╓▄▓╣▓╦▄▄ _  _     _                             _╓▄╣╬╩╙`╙╝▓▒╠░░H  ! K╣╣╬╬╬╬╬╬    //
//        ▒╬╚Ü░░»░░]╠Ü╙░░▒▒╠╩`. __ ╒`╠Ñ╠▒▓D╬╩╠╠╬╠╠╠╬╬H╔║█▀Ü^╓_ ║▓  ╚╦_ ╙⌐`  '_        `             _. :║╣▓▓╣▓╣▓▒▓╝╣Ü║╬▀▓╬╢▓Å█▓███w▓▓█▓██▓▓▓█  `                    _        ___╓_▄φ▓╠█Ñ``-    ╙╝▒▒╔╗╣╦  ╚╣╣╬╬╣╬╣╬    //
//        ╩╬Ü░ÜÜ,`╔]╬_░▒╠╠╩Ü» ╙_╙`_ ╙w╙╠╬╚▒▓╬╬╬╗╚▒╬╢╠▒▒║█_`% `%_╬▒  ╙╠╩║▓_     `                    ╔  ²╬╬╣╬╠╩╣╣▓▓▓▓▒╠╠▓▓║▓▓█╣▓▓█▓▓Ñ▓█▓▓▓█▓▓╬__ » »-.__      _          ≈_    ╓φ@▒║╬▒_ »░ _.  `  `╚╬φ░╚▒▄▄╣╬╣▓╣╣╢╬    //
//        ╬╬ÜÜ_²░░Ü░µ▒╚╬░Ü`   :  Ä _¼▄``j╬H╠╙╚╣▓█`╠╠╫╬╣╣██▄    `╙╣,▒ Ä╙_ _    _ `                '`²Ü▒Ü╠╣╬╬╬╩╠▓║╬▓▓█▓█▓▓█╝╬▓▓▓███▓█║█▓║║╬▓▓▓▒█   _    `  ``   ` _       [∩`╗▄  ╙╓▓╬╝▓╬▄    _╔     _ ╙╠▓╬╚▓▓╣╣╬╣╫█╣    //
//        Ü╠╬╠ÜÜ░`╠╬╬Ü╩Y1H»   :╚╚⌐'╠H__^Ü ╦`░╔.║█▓Ö╚▓║█▒▓█▒▒╓_    ,▓█     ╙▀_       __    `    ` ,   _ ``╚╠╠▓▓▓██▓███▓▓▓▓▓▓▓╩▓█╫▓▓▌▓╣█▓█▓╣╣██╣╜H `^_____  `==╔▄,_       [Ü░░_╦╓_ ╙▄²╩██▓▄   ╙#-   `   ╙╠ ╙╠╣╬╬▓╬╣╬    //
//        ▒▒░░▒;R╠╬▌╚,⌐l_` _`╔`  ;.`╙_Ü`U:░|╙░_ ╚██▌╚╠║╬▓╣█▒`╙\╓▄▓▓╩^     '       _        . _`  ``    ,`___`▀█╬╬║██▓▓██╣╬╬║█▓█▓▓█▓█╣╣▓██▓▓╫╣Ü` -²=╙╙╩╝╝╝D▓▓▄▄╓╙▀█▄▄, ._  '╙=Ü░╤   ╙▄ ╬█▓▄_,_ P╦    `  `   ╔╙╝╫╣╣║    //
//        ╠╬╩▒╬╬╠Ü╠Ü╠- _`"╚` ¬ '`╚K|~╚=_░∩`= ░╙`╚╙╚╬╬╬╙║▒╙██▄╔▓▓╩` '`   _   _⌐  _   ._-          "      `  ^╠H╙█▓█▓▓╙██▓█╣╫▓╢║▓▓█╣▓▓▀▓▓█▓╣▒║▒»`;╦╓..____   , ```╙`╙╩Å▓█▄▒╦_`╚K=░▒_  `▀╬Ñ▀▌`▀▄```-`  ╘»-`   ╙╠▒░╚╣╬    //
//        "W╬D▓^╠▓Ü ¼_ ╔⌐     - r  -⌐_≈╠=░»_µ  _j▓▒▄╣██▄ `▄╣██╙            ,   _   ,░` '_ _   .   __   `_ -»,╓φ╣╬R█▓█╠Ö╩╝▓▒║█║█▓╦▓█▒▓██▓╬▓╬╣▓╒▓▓▓▓Ü▓`û`_░-`__╓_,___    `╙▀▓▌_`╬▒░░░   ,╓ ╙W  '    _         `'╠▓╦╙    //
//        ╠_╬Ü╙` ²ÜÜ░_╓░H         _;-.=╚▀`╔_»_»╙`` `▓╙╙╠███╩`         _▄<^/   ___           ^  _»    '_  ΦÑ╙`)▒▐▓▓╬█╣█▓▓╬╣█╝╣╣╬║█▓▌▌╣█╣█║█▒█▓ ` ^ ```"`^╙^╚Æ≡╦_'Ü-_        ╙║▓▄╠╝╣▒░_  '▒H'W "H   `  `    `    `╙╬    //
//        ▒╬ÜÑ``╙_░╦░Ä` ÷r Ç__     ╙..PÜ╔φ`  _╠╗╦╦╦Å{▄▓██`         ,╗Ö▄▄m░___²__▓╩╙▀▀▓_  ,_       _^`- ;╬▒H╠_╠▒▓█║Ö╙█╬▀╣║╬▓╬╠╬▓▓▓█▓▓████╫█▒║▒        =╔╦╦▄,___``   `        `╙╩╚Å╣▒▀╚_  '█╔▄▓_     . __  _            //
//        ╣╬▄░░_,▒K╩░╔▒ _  ^ `╗⌐R  ,⌐ !╙`╚`╦░Ü░░Ü╠║▓██▀          _▄▄▓█▀╙` ` »`█▓███▄,≡▒▒▄_`_ _   ≈ .   ]Ü╠_▒▓▓╙╣╬▓██▓█▓║██╫╬╙╠║▓▓█▓█╣▓██▓╬▒╣╣█⌐        ╙╙╚Ü╠╣╬▒▄  -▄_          `╙U`PW╣▄  `╙▄ ╚    `         `         //
//        ╝╬╩╩╬░╚░▒╠Ñ_  `_  _`²          ,╬Ü░░░▒▄▓█╩Ü`     '   _╗╩╠╙`      ╓▓█████████Ü_╙__    ` ,-  ``╔`[Ü╣╬║⌐╔▓█████`╙╬║╝╩▓█▓███▓▓▓╬▓▓▓╬╠╬▒▒===≡=╦╓,__   ``╚╚Ö▒▒╓ `╙█▄_         `   ╙▒▓_╙)_ Φ__¼  ` _ '÷`           //
//         ┌╔_ K^,░`╚`'`_                ╬░Ñ▒▄▓██▀`╙` ` '`  __-D╩``  _  _▄█▓████████╫╬Ü ,╣▌ _     `-τ |. ╬╬║╬▓█╬╝╙╬██ÑK▐▌▓█▄║║▓▒╬▓▓█╣▓█▓▓╬╠█▀Γ  v_   _ `╙²=╦╓_```╠╬▓▄_ `╙█▄`_         _ ╚▌╙█╙_ ▓Φ╣█▒K╗_ ,_  _         //
//         \[╓   .` « ¥                 ╠▒╔▓██╩╙    _-P`  .    `     ,▄▓████████▒╠╬╙` ,▄▓▀` - ``   '╓KÆ`╠▒R╬╚▓▓█░╔Æ╙_▒▒╠Ü▓╣╬▓▓▓▒╠╬▓╬█▓╬█╬R╠╩      `  ╙█▄_    `╙╙:,░╠Ñ▒▒▄_ `▀╦``,_²  _╔»_²▓_╙█╙_ ▒╬╙╚╠Ö{P╙─╚▀▀%▄.__    //
//          ╓_         ░L               ╣▓██Ü`  ,,_!` _»_    ▄^ ;K-%╩╝▀▀^`T^╙╚ »  ░__▄╝╬╩ `;==  _   ╠╩ ▒╣╬▒╠▓██╣╠╫,µ╠╬▓╣╬█▓▓██▓▓█▓▓▓╣█║▓▓╚╫▌ _ _     ` `╙%_       `╙╚Ü╬╬R╦▄  `¥__ _ ╚φ▄__`▀  ▌╬_``_'  `  _=⌐          //
//          ⌐╒≈  ╓   `      ,╔     |_▄▓██╩╙`_.∩░-``  _`j    ` ``  !`     0^░░▒░░╬╚R╙╙╙ ╚   . _      ` ╓╔╬Ü¼╫█▓▓█▒▓▓█▓▓_║Ü▓╬▓║╬Ñ╣╬╣╬▓▓▒╩╣▓▒▓╩▀`≈ _         ╙▓▄_       `╚╩░Ñ╬▒▄_  ╙╦'▄µ╠╬╬░_▄_ ║_╙▄_     ` `,≈          //
//           `   ╦╦_  __    .     ╓φ▓█Ñ╚^_-H_ » " __   ╠ -   :  ,-`_  .Ä'`÷[=``    _    .` .   ,▄'  _▄╣╬▒▒║▓▓█▓║▓█▓▓╣█╔║▓╣╬╣▓▒╠Ü╙║╬╣▓▒▓▓▓█▓  _ `'`._ _-    `╙Æ▄          `╙╚╬▒▒▄  `.j╣▒╠╠▓╬▓▄ ╙▄╚▄░,.   ,` ._         //
//        `     r `^          _╓φ▓█▀╙`_╔⌐ ,∩` `   `   j╓╩ `            ``              ▄╕,`___╔Ä - _╠╬╬╠╬║╢▓▓║█▓▓╠▓▓▀║╩║╬║█▓▓▒█▒▓▒╣██▒╙╬▓█▓▓⌐    `╙╔▄_╙ H╓   ╚╙╚▄           ╙╩╝╠▓_  ` `╠╬╬╬╬█  ▒_║▌    ¬   _`         //
//                    _    _▒▓▓▓█▀╙_╔R`_╔Å╙_.⌐_╓^ _  ╓▒Ü`              ,   .         _    _▄▄Å`-_;µ[╠Ü▒╬╬╢█▓╬▒▓█▓▓█Ü╔╩Ü║▒╣██▓╬▓╣╣╗▓▓Üj╩Ñ`╠╠▀▌_ ▀▄_  ╙Ü▓_╒___    `Φ▄            ╙║▒▄  `  `╠║╫▓╗φ║▓╔║▄ ` .`   - `       //
//            __ _    '` ,▓▓▓▓╬╩`╓Æ╙_╔H`_÷` .░, {∩` 1╠Ü                É _     ,»░-_   =_▄R╙   `,»░╙ É╙╣╣▓███╣▓█▓█Ñ╠║▓▓╣╣╣▓╣▓▓▒▓█╣▓▓╠▄▄█╓.╙ φ∩: '²w_  ╙╝▓▄▒∩╔.,   `Φ_            ▓╬▓   :,∩╚║▓▓▓▓█╬╚▒H  »_ `   .  _    //
//             `        Æ▓╬╣╩╜,▄╜ ╓▓╜    . »` .` _▄╬▓╩        _      __   _=  ` `    _»Ü`` = _≡░Ü≡-,j≈▄╣▓██╣Ñ▓█▓▓█w╩╣╬▓╬╙▓▓▓B║╬▓╣█▓╣▓╬╬╬φ,░µ      !╠_   ╙╩║▄╩▒▄` _  `W_      _   ║█╬█_  `_╔R╙╝╣▓╣█▓▓▒    `  `   ._    //
//                    _▓█╩^_▄▀^_▄``   . _-`,²   ª╙▒╩`_    `      _   │        .-_ ` ` `= __=$ ╦╓╙_ ┌║▓▓▓╬▓Ñ╬╣╣╬█▓▒|╔╬╬█▓╠╣▓╣█╣╣▓▓▓╝╣▓█╬╣█▒╩m        ╙▓_   `╫█▄▓▓_     ╙╦   `≈     ╙▒╙█╦  ╙``Ü╬╠▓▓▓╬▓D`    .           //
//                    ╫▓▌_ `,≤^   _▄  +^  `    _φ/^,' _╔       _        _ _▄ -_     ` ]▒▄▒,_`_`²╓▄╔|╣╬╬╬╙▀▓╬╣█▓▓▌╫▒╣▒╣██║▓█▓╬╬█▓▓█Ü╙╬╬╠╬╬║▓▄⌐_        ╙█    ╙╣█▓╫▄   _  '    `     `_╒ \    »░╠╩█╬▓██H                //
//               _╒╦  ╣██▄▄███████████████▀▓^ ▓▒╬▄▄▓████████████▓#===     _ ┌   ``,,▓▓█╬╩╙_µ╬R╓▓█Ñ╓╬▌╔█╠╬░▓╣█▓▓█╣▒▓█▓╣██▓▓╣██╣╣▓▓▒`¥╬╠▒` ╚╩█░╔▓▒_      `▀▄   ╘║██╬▓   %_      !▓     ╙  ;_ ╚ `²║▓█╣▓▓` ⌐`_φ_          //
//         .   __     `║██████████████████` ▄╠╬╠╬╚╠╝╜`╠`,»░╩╙▄╬╩╙ `   _   ` __,▄▓██▀╙╚Ü^╔^R▒▄▓▓╬╬#Ü╬╣╣Ü╬█╫▓▓▓▓██▓╫╝╬╬▓█╣▓▓╣██▌▓▓▓▌|▒╙╙██▄  ╙▓▄╙Ü`_       ╙█   `¼╙██▓▄  '╔      ╙ ╕  ` _,▐▄▄ `░_ ╚▓█▓⌐ _   `_          //
//              `      ╙█▓██████████╬▀Ü=` '╠╬R╣╬╣▒__ ╙░∩``,▓█Ñ╙_   '▐H▄▄,▒╔▓███▀▒╚ÜÜ=╔╦╠H╓▓██╬╣╬╬╬▒║╬╫║Ñ╔█▓▓▓▓╬╠▓█║▒Ü▓▒▓▓▓╫▓▓█▓█▒R▒║▄'`╫╣█▄  ╙U_KH_        ╙▄   Y,╠██▓   Φ_     ░`▒▄    ,Ü░_'░░Ü`║█▓H       h         //
//            _╔╓╓   ╓__╙███████▀``▄▄▓▄▄|▓╣█▀▀██▀╠╬╬╬▓▌╓,╣█` _` ▄▄▓▓▓▓████▀╠Ü#▓╬Ñ¥╠╦▒[▒▓██╩╠╬K░Ñ▒╬╬▓▓▓Ü╓╣█╣███╙╣▓▌╠╬▓█▓▓▓╬╣▒╣▓▌╣█╣█▓▌_  `╚██_  ╚█_▒K_        V   `╚'╠██_  Φ╕     ╠»`╠▄ `_^╓`▒[░_ '▓█▓▒∩m≡_ ▄▄,_       //
//           ╠╬╠▒Ü▄'╔▒░R ║█▓▌ ,<   ╚█▓▓█▓▓▓▓█▓╬╣███╠░,╓╦╣█▄,▄__|`╙╙^╠Γ`╠▒_ ^]╔Ü_j╦▒▓▓▓▓▀╠╣▒╠]║╣▓╬╩╬╬ÖK'║▓▓▓██▓╦╬▓Ñ;╩╫▓██╩¼╣▓▓█▓█╣▌╙╠║▓█_   ╙█▌_ `▀▒φR_        `     `╬║█▄         ╚``╙`≈ ``╠Ü▒░░ Y╙⌐║█    [║▓▒▒_      //
//        `_ `.Ü__░=╬╩Ñ _ ╙████▓▄_    ╣▓▄▒╠╬▒╠▓▓▓╬╬╙^╙` `╙╠╬▓Ñ `╙__ ▒╔░Γ__  ,]▓▓▓▓█╬░╠╬╬╠╙»Ö╠▓Ñ╬╬K╩╩Ü[▓▓╣██▓║█║▓█▒Ü╔▓▓▓╠Ñ▓,╣▓Ü▓╬╬▓▓█╙█▓█▄▄  »╙▀▄╔╬╙╬╠╔▄_             `╬╠║█▄ `_     ╙_`╦_'_ û▓K░░░   |█     ╣╣╬╬H_     //
//        ⌐_. `      _  _ _╙`╠░ ░╙▀▀╗▄▄╠╬╬▓█╬▓▓╬╬╬▓██Kφ▄,»╙█▄▄,`^ ╔▓╬Ü▄▄▄▄▓███╬╣╩` ╠╩▒╠`⌂_╔▒╬▓╣╬▒╩╬▄▄█╣▓▓▓█▒╬╫╫█Ñ▓▓█▓▓Ñ▓,╠╣██╣╣▓▀╙╚╩  ╙▀███_   `╩░Ñ╩╣▓▒\              ╙╬╢╬██_ ╦     ╙_`░_╫▒╦Ü░ÜÜ░ »╦R    _ `╙╙╙       //
//        -φ   `^   ⌂`╔╩╩_  [Ü, `░-_ `╙╚╬╬▓╣╬▒▒Ü╚▀╬`ÖÜ║╬▓╗ |_║█__ ╙╙Ü╬╩▀▀╠▒╝╙^`_╔▒╠Ü╠╠▒╠▒╬╬╬╚╠╬╬Ü▄▓▓╣▓▓██▓░▒▓Ñ█▓▄╣▓╣▓╩║█╝╠▓█▓╩╬╙▒   »_  `▀███▄   `Ü╠▒║██,              '║╬╬╠█▄`_     ╙▒░`Ü`╠╣▒░_`╔ »`  _,` ` .        //
//        _.^`   ²H_`¬``    ╫∩▄  ▓█▓▄▄_ ╠╚╩░╚╚╬╝▓▒` ¬    │▐█▓█▓█╬_ ª^╙╩╚Ü¼_,ª╙╙╠╩╠▒╩╠▒╠╬@╬Ñ╠╬╩╠▓▓██▓╬▌║█▓╬╬█▓▓╣██▓╬▌╠▒╬║▓▓█╝╬╣╬╠╣█  ¡  ╕  `╚███▄   ╙╬Ü╠╣█▒_              ╚╬╬▓`█▄N     ╙▒▒_╦ ╚╬▒Ü »∩!» '░▒H`   _       //
//          ```  _ `        ╣ Ü≈ '╣█╬╙╝█▓░╗▄_[▒╚Ñ_ ``▄,▄ ▐▓╠╬████▓▒H╔_╓,▄,╓,▒≥Ü║▒╩_]╠╣╬╠╬╬╬╬▒╫╣█▓▓▓Ñ╠▒╣█╫▓██▀Ü▓█▓Ñ╬█▓▒▓██╫▌  ║▓╬╬╣▓_ `  ╙▄  `╚╣██▄  '╠Ü░╣█▒_`             ╚╠╠▓ ╙█▓  _  ╙╬▒∩╦`╙╬_   _.` =╬▒╦  _=       //
//           `__._          ▓ ║██▄ ╙║█▄╠██▒╩█▓▒ ▄"¬K▄╙▀██▒_╬╠╬╣╬╫╬▀██▄░║░░╬╠▒╗Ü╠▒▓╫R╬╫╣╬╠▒╠║▓▓▓╢█▒╠▄█▓▓█▌╠▌║▓█Ü╬█K╫╣╣██╝▀╔▒█   `╚╬╬█▄     ▓_  ╙╬╙██_  ╙╬▒╙█▌ ╙_    _     . ╙╬╬▓  ╙█▄`   ╙╬▓░╕[╙╬`  ²w »_║║▓¬          //
//         .       ╓╔╔▄__   ║H-█████▄`╫╬▓╩▀╬▒╚╩██▄▄ ``  ╙███▓▒╬╣╠█▌  ╙▀██▓▒╠╠╢╬╬╬^_╔▒╠╬╬╣▓▓▓╣▓╣Ö╠▓█▓█╩╠▓,Ñ╔║█Ü╣▀{▓▓█▓╣╩ UÑ╠╬▓_   '╣╬╬▒     ▀▄   ╙_╙█▌_ `║▒╙██▄╙╕   ²≡     U_`╬╬▄  ╙█▄_-_ '╬╬▒_╠╩_    » ¬╠╬█           //
//          _` `_-/[email protected]` `_   [█╔██▓╬▀███╬╠▒▓╬╠Φ+ ██≈╔╦`▄▄▄ ╙███▓█▓╬╬▓▄_^  .╚╣╬╬╩╬╬▒╬╬▒╬╬╬╣▓▓▓╣╬╣▓▓╬▌▄▓▓█¼▌|▓▓█║Ñ▐▓╣█▓▓   ╙╙▀░╣█▌    ╚╬╣▓_    ╠▄   '_'╚█▄  ╚╬░║█▄╙╦   ╚░_   '╣▄ █▓█  ╙╬█_║  ╙╬╬▒`,╩.» `,▄_╚▓▓φ _        //
//          '»`   `=░`_²┌    ╙▓██╬▌ H R███▓╬▓╬ÅD▄║█╬_ ╚▀▀███▄╠╙█████╬▀████▄▄▒▓▒╬▓╣╬║╣R▒╠╬╣╬Ö║▓▓▓║▓╩╠█╬▒▌╔▓╣╣▓▌║▓▓╬▓▀   _  ▄ ▀█╬█▄   ╙▓╬█▄    ╬φ      ╙██_ ']Ü╚██╙▒   ╙░╓   ╙╣▓ ╣██  ║▓█▄▒_ `╬╬H   ²   `` ╠╬╬░╙╙▒,_    //
//                  `         ╣██▓H║▌╠ ▐▒╠╬╣▓▓▒▄`╩╚▀█▄▄H╚░╠ÜÜ╙██▄╚╠╙▀██▄╠╚╣╠╠███╬╠╢╬║╣Ü╠▓╠╬╣█▓╠╝▓``╠█╦╩¼╣▓█▓▒╣╫▓╬█Ñ_   `\  ¼_ ╚╚█▄    ╣▓█╦    ╫█      ╚║█▄ ╙⌠H`║█╠▓_  ╚░▄   ╚▓█▄╫▓█ '█▓█║▓  ╙░▒          ║╬╠░]``;_    //
//             `             ⁿ▓▓▓╬]╣▒Ñ▄H▓▒╣▓Ü╙╝╣████▄╣╬╣▓╬╠╦φ╩ ╬██╩╚m¡╠███▒║╣╣╣╬▓╬╬╬╬╬╣╬╬╬▓▓╣╩Ñ▓Ñ[▓█╬Ñ▄▓█╬║`╬██║█`▐m▒▄   `  ▐▓_`▀█▌_   ╚╬╬▄    ╣▓       ╙██  ╠`»╚█▓╬▄  `║▓_  ╙██▒║╣█ ║▓╣╣╬▌  ]╚           ╣▓▓╣▓▒Ü_    //
//        _     n  __,,_╓:_, ╓▓▓█Γ╬▓╬▄█`╬▓▓ÜÜ╔█`╠╬╬╠╙▀▓╬╣╣▒ÜÜ░_,╙██^_▓▒╠╚███╬╬▓▓╬╠╣▓▓╩Ü░║▓╣╩░D║Ñ▄▓█╬Ñ║██▓█¼▓▓║█╩Γ`.'█▓▒      ╙█▄ ╙█▌_   ╙╬▓█_  ╙╬H ╔    `╚█▓▄ ▐▒░╙█▓╠▄   ║█▄  ╙█▓▒║▓█ ╚╬▓▓╩W  │_          ║███▓Ñ╓@    //
//        ▄╕φm)▒╬Ü╦Hm0RK╩` ⌐ ╣▓╬▌▐╣╬╣╣▒H╬╣▌╣▓▓▓╬╣╬▓╣╣╢▓╬╬╣╬╬≡KH╬`╚██▄▒▓▒▓▄╚█▓▓╠╬╠▓╣╩╬▒╣╬╩╚∩h╬║¼▓Ñ╣╫█║╬▓██▄▓█▓╬▓▓`  ``^ ^    ` ╙▒█▄ ║▌_   `╬║█_  ╙`='H   ' ╬╬██ ║Ü░░║█▒▓   ║▓▄  ╙█╩▓║█▒║╣╬▒▓▒_ |____       ╙╚Ü╙.≈`╠    //
//        ╠╚/╚╚░»░[╠░)`.`` _║▓▓▓HÖ╬╣▓╣▒▐╣╣█╣╬▓╬╠╬╠╬▌`╙╬║▓╬╣╬╝░╖`░_╙▀██╬║╬╬╬▒║█▓╬▓█▒╬╬▒╩Ü_▄]╩╗▓▓▓██Ñ▄▓▓▓█╬███▓╠╙╙▓▄      _╦  _  ╙█▓▄ ╙_\    ║╬Ü   ┌,╔ `    ║╬╙██_╠╙Ü░╙█▒▒   ╚▓█  `Ü╚R╬╬▒╬╙▒▒║╬ '░_-»»│    -- ``T»`╙    //
//        Ü░╝░▒░Ñ╬Ü|⌐╙¬`* .╗█▓╣▓▒║╩║╣╬`▓╬▓╬▓╣╬▒║▓╬╫█_`  `╙▓║▄_▒/_`░╬╠╠██▓▓▓▓╬▓██▒╠╬╩╬╠╬░▄╔╩▄╣╣█╬Å [║█▓███▓▓╩╚█▄_ ╙█_    `╠▓_    ╙▌\╦_`.╔    ╙U▓   Ü╠H      HÜΓ██_Ü!░░Γ█▒░_  ╚▓█_  Ü║╣╬Ö░▒▓╠░╚╠ ╠;^░»=» _   `` P1^╓    //
//        ╔╠▒HΩ]/▒=╓»_.`" ╩║█▓▓▒▓H▒╬╣▒║╬╬▓╬▓▓╬╓╣▓╬╬║╬▒╦ ▓▓╬▓▒▓▄,φ»_╬▓╬╢╣███▓██╩ÜT╚╩╦▄▒╠▓P▐╣▒╩╩X╙-▄║╣▓█▓███╬░  ╙█▄  └╕   \[▓█_    '.▄╔_ ╙H    ║▓⌐  ╙╬▓ `     ║█▄║█▄_÷]│`╚▓▓▄  ╚▓█_  ╫▓▒╬╚╬Ü`╚▒╙¼|;░░==░``     _=░╓╫    //
//        ▓╠╠H^╠Ñ⌂Ö▒`ûÜ=|Å▓╫████Ö╓▄▓█⌐█▓▓╣Ñ██ ▐▓╬╠╬╬╬╣▒╣╣▓╣╣▓▓╣▒]▓▒╝╬╠╣╬╬╣▓██╙░╙╙╠╣║Ü▒Ñ╓▓╬▓▓__ ▄╬╣█║█▓▓╬█▓Ñ    `▀█▄  \_  `██▒     ╚▓█╬m ╙▒_   ╚`  ▐╣_        █▓▄║█▄»,░░░Ü█╩▄  ╙▓▒▄  ╠Ñ╬H╔_U╦░»╠░`Ü_==Ü»`     j╠φ╙!    //
//        `╠╬╢≡▒▒▒▒j░▀▒ ╙Ü▒╠████║▓▓█║██▓▓▌▐█▌_╚`_╠▓╬╩║╣╬╣▓▓╬╣▓╫╬╬╠╠▓╣╩╙Ö║▓█╬Ö`╔▄▓╩Ü) ╚▓▓╬▓█▓▓█▓╬▓▓▓╬██▓╬╣╣█▄     `▀█_  _  '║▀`_   (╣▒╚Ü▄ `╠_      _╙` `   _  `█╠▄╚█m╚╠Ü»░╔▓▓▄  ╚▓Ü_  Ö╙╙Ñ= _╚[»!=»░)░_     ╓_╓▄`^╙    //
//        ▒╣╣Ñ_╠╠╠░ÖÜ»^H_╓`Ö███Ñ███╗██▒███║██▓▓▓▓██╬▒║╬╣╬▓▓█╣╬▓R▓▓▓▄R╩[▓█Ü░╙Ü╗╬╙╒╦¥╩▄██▄╝Ñ▓▓█▓▓▓▓▓▓▓▄ ` `╙█▓▄'_    `█▄  ⁿ    `'    '╬RÜ░\  ╬      ░(     ▐▌j  '╠║▄╙█▒ '»»Γ║╣█▌  ╫▒Ü\ ╙_╚;-H_|_=∩Ü░░_'P__   ² ╠░▓▒_    //
//        ▒║╬╬Ü╙ÜuÜ=`┘ =` ` █╣█║███╫█▀║██▓████████▓█▓╬╬╣▓▀╠║▓╬▓██╬╚  ╓▓╩╢H▄▓R^`T  ▄▓▓╠▓█_ ║╬▓▓█▓▓▌╙▀▓▓ ` `╙█▓▌ ╦     ╙█   .  \▓█_  ]╙▒░_╩╚  ║_    `y⌐ _  ╚█ ▄_  Ü╣▒╙█  |░░╙███▌  Ü╙²\ ╚░.[ ,)-»`»░╩-_ `     `"╩╩╣╬    //
//        ╙╙`^`` `         _▐█▒╬╣╚╣▓█¥███▓██▓▓▓▓█▓██╬▓▓╠╬╬╩Ü▓█▀`▒▒^"▐▓╬▒╬╬╬╬R▒,_j╬▓╬╣╬▒╬█▄╙█▓██▓▓█▓_``¼▄   ╙╫██ ¼▄     ▀_  \  ╚╣▓╦ [▌║Ü╬░_╠  ╣_   ║▌H__  ▐▌▄██_  _╬_╙▌ /╠░Ü║▓███ `_░-H_╔=P_░ÜU░∩»░_░`»_._             //
//           _   _ ,       _  ╚`   ╬`▐▀╙╠║╬╬▒^_╚╠╬╬╫╬╬╬╣╩Ü╬██▒▓▌║▒╓▓▓▓╬╬╠╣╬M.Ü╔▓▓╬_`║▓╩║▓█▓╣▓▓▓▓██▓▓_  ╚▌   `╚██ ▀      ╙▄  `_ ╚╠╬▓_ÜÜ╙Ü░╠║▓  Ü_   ╠|║__`╠╔█▓██▄ ╠»╠ ║_`▐▒░░██▓██_    ` _-._╙░¡```Ü-  ``» _           //
//                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                    //
//    JAKNFT MINTS                                                                                                                                                                                                    //
//                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract JakNFT is ERC1155Creator {
    constructor() ERC1155Creator() {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC1155Creator is Proxy {

    constructor() {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x142FD5b9d67721EfDA3A5E2E9be47A96c9B724A4;
        Address.functionDelegateCall(
            0x142FD5b9d67721EfDA3A5E2E9be47A96c9B724A4,
            abi.encodeWithSignature("initialize()")
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
// OpenZeppelin Contracts v4.4.1 (proxy/Proxy.sol)

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
     * This function does not return to its internall call site, it will return directly to the external caller.
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
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
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
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

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
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}