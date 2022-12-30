// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Off Grid
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
//    .:...:::::.::::.:.. ........   . . . .         ...  .. ...            %    S @[email protected]@[email protected]   S           ..::;:;;tSt%;;;:.:::;;;t;;;;;;;%%%S%%%%t%%%%%%%%t8:8:8:8:[email protected];@8888888%[email protected]@[email protected]@@8888%;;::::::::::::::;;;;;t;t;t:::;;t;;:::;;t;;;;;;:;::.:::    //
//    ..:....::.:.:.:... . .... .     .  .    8:@.  .. .                  S S S X [email protected]@[email protected]@@[email protected]@@8 S          S .:;;t%t%%X%SSS%;;::::;;%t%;t;;[email protected]@[email protected]@88 %8t8t8;[email protected]@:8;[email protected]@@8 88888888:[email protected] 8S8S8 [email protected]@[email protected] @[email protected]@@[email protected];;;;;;;::::::::::t;tttt%t%X::;tt%ttt;;t;t%ttttttt;::;;;    //
//    ::.:.:....:.:.:.... ..:. .  .8.8;   .  .:..8.  ..                %    %   X @XXX888888X % 8  X            :;tttt%%S;tSX%%.;:.:t%tt;tt8;[email protected]%[email protected]%8;@ 888 8;8888888888tS [email protected]:[email protected] @8888888888;@888.X888888SX888:X8 888888 @888X88S888S8%888888;;tt;;;;;;;;;;;;;t%%%%t%%%t;;t%%%%%St;t%t%%%%tttt;;;;;t    //
//    :::::..:.:.:.:.:   8X;....8:..:;888t .8t    8%..                    S  S   @ [email protected] ; SX: X         8   .;;%;t%Xt%[email protected];t;:SS:8888;88888X8t8S8;888t88888 @[email protected]:%[email protected]%SX888 8.88 [email protected] X888 [email protected]@ @8:X888888 [email protected];[email protected] @888888888 8Xtttt;;;;;;::;;:;;tt%%%%S%S;t;%%Xt%%ttt;ttt%%%X;%t%;:;;:    //
//    ..::::.....8%:.88tX :.....:  .88 %; .:;  8t.;..  .    8;         S   S  S  @X [email protected]@888S.;S @  @X     X  @  .:::;;%[email protected]%X%S;t 8t8.8.888 8ttS888S888t%[email protected]:8888X88888t8:[email protected]%8 8;88888 @[email protected] @[email protected]@ [email protected];8X%ttt;;;;;:;;:;;;;tt%S;%t;tttt%ttt%%%;t;tttSt%;t%%;;;;;;    //
//    ..::..:.8t t;.S ;.: ...88; 88S;t..  ... :;   . .. .  .:            S  S     8 8888X X:t;8 8 X X   S  X   .   ..:;%%X%S%XtS;88888888888Xt8tS888.t;8%;[email protected]:[email protected]:888;@8:X:[email protected]@t8:X8;@88888888 [email protected]@[email protected];;;;;;:;;;;t;%tttttttXt;;ttSt%%%%t;;ttttt%%%%tt;ttt    //
//    :.:.:8% ;:.....    @[email protected]:;.8:;  .X:88            .  ..   .   @.         X  [email protected]@88X S S 8 8X X X    X @   .    .;;%%%tS%X%%:8 : 888 888;;888%t888 St;8:88 88:[email protected]@[email protected]@[email protected]@[email protected] 8888888 [email protected]%@88;[email protected]@[email protected]@XSttt;t;;;;:;;;;;;t%%tt%%St%t;;%%;%%%S;;;;ttt%%%S;%%tttt;    //
//    :.:.S.:::...S; S:X8 .:;. 8 . .88 .:;    8% 8t . ... . .  .  .     S  X     X:[email protected] S.88 8 @ S     X  X  .    ..:;t;;t;[email protected]:.8.;88888t888888:8 t%8 8:X:X8X.t8888S88t%.8;S888 8%8;@[email protected];X888 [email protected]@[email protected]@[email protected]@:;t;;;;;;;;;;:;;;t%t%S%;tX;;;t%%%%t;t;::;tt%%tt%t%tt%t:    //
//    :..;;:..8t.8 t:...8t 8: 8: .8;:t% 8t  .:t .:     . .      .         S S S  S 8 @888X:X:88 8 X    X. XX 8.   S...::;;:;:SSS8t88S:;:888:8:888%8;:88t:;.8.8:8888X8%88;[email protected]@[email protected];X [email protected];@888%S8;@8888X8%8X88888;8 [email protected]@[email protected];t;tt;;t;;;::;;;;%t%%ttt%%t;t%tS;t;;:;::;ttSt%tt%tttttt    //
//    :.....88;; t .S88;: 8 %8 .8S..  8::  S:     @:@:  .  . . .   8:   X   % % S 8;[email protected] @.8 8 8X @ X. S. 88     . ..:..:t;tSXS;%:8:t88:8.  88.888%8;8;[email protected]@ 88 [email protected]@88.8.X8 @[email protected]@888X88 888 8X [email protected] [email protected]@88;tt;;;;;;;;;;::;;t%%tt%%t%t;ttttt;::::::;tt;tt%%St%%%tt    //
//    :....%.;:.:.%8%   8;8; t:8 . S8t  8; :  X.X:. :X.. .         .     S X  S%% S%S8S888 8 8 8 X X S S.S X 8  X:%: ....:;%tXXX%%%;;88 ..8888 [email protected]%tt888S8.8.8%8:X88888;88 @8.X;[email protected];8888888X8888%X888;888888888 8 [email protected]@@8888888888S8;@8888;tt;;;;;:;;;::;;t%%%%%;tX;;tt%;t;:::::;;ttt%%Stt%Sttt;    //
//    :...::. .. .t; t 8  : 8:;;.8: 8;t::8;   :.: S. [email protected]:  8t 8; @. X   S  S X %%@[email protected] 8 8 @ @  X.% [email protected] 8 X:    .   :;t%tXXXtSt8.;88888;:X% 888:%88888 ;8;88888S888:@8:X88888:S88 @ @888 88888X8 8X888;[email protected]@ [email protected];t;;;;;::;::;tStt%t%ttt;;tt%%;;;:::;;;;t%Stt%%%%t%%;    //
//    ....:..   %;.t.8;8.888t.:. .%8 t:88 t X:S.  .X:  @:.: .:  :    S  S   S% @@XXX8 8 [email protected]@ X S @ S  S 8:8 8: X @ %:.   .:;tSSX%XSSt888.:888: %t8 :S88%8.:[email protected];@8 8 @888888888.8;@8888 8 8%X88:[email protected];8:%[email protected]@88:[email protected]@[email protected]@ [email protected];;;;;;:::::t;t%t%ttt%@:;tt%%tt:::;;t;t%t%%%%t%%%%%;    //
//    .....:  t..; S8  :8t .;8.88; 8:88:;t S; .X:S;.S.  @:  X:  X       % @  [email protected]@@@[email protected]@[email protected] S  S   X. 8t8.8t8: X:S.      .;;%t%S%Xt;:88888.:888t;%8888888888S.8t88X88t888 @88888 @[email protected]@[email protected] [email protected]@8t888888888888888888 888%[email protected] 88:88.t;;;;;;;;;:;:;;t%t%%%S;;t;;St%ttt;t;;;;ttt%%tS;%%Sttt    //
//    .:.....      %tt8.8:88; 8 t .:::;t.8.888;. .S: @ 8%S. .X.  @. X X %  X [email protected]@[email protected]@SS @X8S S  X  .S;.t.8t  8: S.%. tt8;.:;%%tS;%%tt;%;t%888%88%8:[email protected];.t88t8X8S88t8 X [email protected] [email protected] 88888X888:[email protected]:X8888888S888 [email protected];;;;;;;;;;;::::tttSttt;%%;;;t%%tt%%%;tt;;;t%%ttSt%t%S:    //
//    :....  t.t.%;  .. .8tt8.8.888;8t 8.:.8 % 8%  X: [email protected]:@:  @: .     S X % S [email protected]@88X [email protected] S  %  S...% 8;.8:8%t S 8t  :;;:.;;t%ttt%t%tS88XXS%8:8888.;:8 .8%8;S88S888%[email protected]:X8;8.8:X88S888 8X8 [email protected]@[email protected] [email protected];[email protected] 8888:;t;;;;;::;::;:;tt;tt%tXt;t;t%%t%%tttt%ttttt%%ttt%Stt;    //
//    :....... ..: % 8:8; 88;888; .:;t..888t888S 8%.X 8t 8;X.  @:@.8: X S % XSS [email protected]    S     88:8; 8.8 8; . 8;8:....;;;t:;%[email protected]%8t888t88.88888%[email protected] 8 [email protected]@888:@[email protected] @[email protected]@888;[email protected]@88 [email protected]@:;;;;;;;;::::;;;;t%Xttt%%;;t%%tt%%%%%t;;;;t%ttSt%S;ttt    //
//    ::..... %: %;... .8.8t8. 8:8;t.8.:.;.t.8t  ;    :8: 8;@.8t . [email protected]  X S S XSXXXSXSS [email protected] X  S   ;.t..8:8t88t;8:.:..8t.:  ;;:;;t%SSS%[email protected]%%88888888;[email protected]@@@888 8:X8 @8 [email protected] [email protected]@888S 8 8888:X888 [email protected]%88%@[email protected];:;;;;;;;;;;;;;:;tt%;tttX;;;t%ttS%tt%tt;;;;;tt%tttt;ttt    //
//    ::......: ..8;tt  88;.88;:.:88: t.888:8% 8;% [email protected];.8: 8:@;[email protected]; X 8 S SX @XXXS @SX 88 8 S  S  %: :8.8888888.8;:8;..  ..8St:;:888%S%@%[email protected]:888;[email protected]@888%[email protected] [email protected]@@ [email protected] @888 [email protected]@[email protected] [email protected]@8888888888:88Xt:;;;;;;;;;;:::::tttt%Stttttt%X;tt%%;tt;;;;;;ttt%ttt%t;    //
//    ::.......%..;  %.8..;8::888;.t;t .    .8t: S8;  S: 8.X 8: 8; @.SS 8 % XS%SXSSX @SX [email protected] S  S . .:.88%%;.8.8t8;t:8;:888;;:88888%88X%XSXX%tS88t8.88 8 S %[email protected]:X;8:[email protected]@88 8S8X88 888 @888888 88888S888888;@8. [email protected] 8X88:[email protected] @888888888888888X888X%tt;;:;;:;;:;;;::;tt%S;tX;;;t%tt%%tttt;;;;;;t%%t%%ttttt    //
//    :.:....88.t.t.88 . 8S: . 8t:8.;8.8.t;8;. t.%;tS.S @[email protected] 8:[email protected]:X.%@S S%%%SSSSS 8XS [email protected] 8X X S  %:  888X.;88888888;.:.8888. 88..8t%%[email protected]%[email protected]%t8;[email protected] 8888.888888 888X8S888888X888888 8 @8 [email protected] @S8888%..888 8888888 8888 8888888888888888888888t888%;;;;;;;;;:;;;:::;;ttttt%t;;tS;%tttttt;;;;;;;t%%%ttt%%;    //
//    :.....8;   8.:: ; .: ;88t.: ;8; ; t: . ; 8t t: X:[email protected] @ [email protected] S @S%S%%XXX%S @ 88 [email protected] S S  . .: t ;8888888 8;88:8%.t.8:[email protected]@[email protected]%%8;8t8t8t88;8888:8:8 888X88 8 [email protected]@88888888888888888 [email protected]:S888888 8 [email protected]@88X888888888888888X88%88;;t;tt;;;:;;;::::;;t%t%tX;;;%t;t%%%t%t;;;;;;tt%t%tSt;t;    //
//    ::..:    S:. t.t.8t t:.t;tt8;.;8 t;ttt t:.8; 8% 8tS:S 8 8;@ 8 8%8%[email protected] 8 8 [email protected] @X S S. 8t:8:8:88%8888::.:8:.  88888t;;[email protected]%[email protected]@@@8;;S888X;[email protected]:@[email protected] [email protected]@[email protected] 8 @88888888 8%[email protected]@88X88X8888888 @888 @[email protected]@[email protected] [email protected]@t;tt;;;t:;;;::;:::;tt%tt%t;ttt%%%t%%;;;;;;;:;t%ttt;%ttt    //
//    ::......:;...88t:;  t t %: .;;  t;;;%%%;; .%::%::S.S @ 8 8 8 8 [email protected]@8X8X [email protected] 8 8 8SXXS%@@ S 8%S8:: 888.8888S 8888::888:.88:88ttS8t%[email protected]@:8t888;:.888 ;@8 88 8 [email protected]@[email protected]@X8888%[email protected]@8888888 @[email protected]@[email protected]%.SS%%;t;t;;;;:;;:::::;ttt%%X;;tt%t%tttt%;;;;;tt;ttttttttt;    //
//    :::.: . ..%88;;. 8%.. .%:t t %t tt t % S %  8t 8t S.X X @[email protected]@[email protected]@@@ 8.8.8 8S X @[email protected] :.. 8;8:8.:.8888888;:;.8;8888;..888;:tXXSSX8;8t88.8t8;8:S.8t88t88.88 [email protected]@[email protected]@ X88S888888 8X8;[email protected]@[email protected]@ 888888888888888S8 88X8;;t;;;;;::;:::::::;ttStt%t;tt%t:;;;;;;;::;%t;ttt%%%tt%;    //
//    ..:....88%  ...8;t  %8t:.   %.% %.8:t%X S % :t:.8: X X @%[email protected]@@88888 8 @;8. 8 8 8 X @XX%.  :.;:8. 8 88..8888 888888t88888:88888%@S%%%8888.:;888t8..:888..88 [email protected]@888S8X8%[email protected] X88X8XS8888 8 @[email protected]@88 [email protected]@[email protected]%t%;ttt:;;:::;:;:::;%S;S;X:;;%;:;;;;;:::::;;;;ttt%%tt%t;    //
//    .:....% ;.. .88;. 8:   ..%:   S:%: 8. S X % t S..% S X X%@[email protected]@@[email protected] %@;@t8.8 8 88 S 8 X S 8%:.8;8.888t.8.8 :88888%;;:88;88888.8S8X%%888.;@;X 8.8 @[email protected]%88 888888888888888 8X88 @[email protected] 88888 [email protected]@[email protected]@[email protected] @XStttt;;;;:;;;;;::::;;;tttt;t;S;;t;;;;;:::;:;;;;t%%%tt%tt    //
//    .....::.:..88%;...  ;....: 8t .S:8t.tt 8. X %  S. S. X X%[email protected]@[email protected]@[email protected]@. 8;8:8:[email protected] S 8 @..:. 888::.8;.888.88t88;;8888.8 :888:@ :%%t88888::8 .:888S8S [email protected]%8;88 [email protected]@8S88888 [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@S8XSt%%%t%;;;;;;;::::;ttt%S%ttttt;;t;t;;;::::::;t%t%%t%tt;    //
//    .:   .....8tt...88.88. .  :; %. .: % t% 8. @ t  S. S S S [email protected]@88 X;X88; 8:  @ X X% 8 @ 8.::.: 8 8::88.8;888888888; 88%:[email protected];88888:8 8 [email protected] St888:8.%88.t88;888S8S8 8%@8888 [email protected]@[email protected]%888888888 [email protected]@[email protected]@8 [email protected]@t%%SttStXtt;;:;;:;;;t%tXtt;;%tt;;;;;;::::::;:;tt%tttttt    //
//    ...   .8.;t:.. 8;..::;8%.     S.8; % t @: 8: t   %  S X X [email protected]@[email protected];888 @ 8  X @ S SXS%.; 8:8t.:888.8:.8:88 8;88;8888.%8888S888t8.88.  . : 8:@S8.t88 S88888888S8 @[email protected]@[email protected] [email protected]@[email protected] 88S88888888888888888S8888%St%t%%%S%tSttt;::;;;;;tttt;;;tttt;;;;;:::::::;;t%ttttS;t    //
//    .:.  8t...:.  8::.  .;. .  %: ..:t. S t @.. @ tt  %.  X XSS%%[email protected]@@@[email protected]:8 8:X @  X S X X 8:8888:8.8:888.8:..888X;:;:88tX8 ;@8 888:[email protected]@888%.888%8;8%8t8 ;@[email protected] [email protected] @ [email protected] [email protected] [email protected] [email protected]%St%S%%%StS;;t;:;;:;;;;t%t;;t;ttt;ttt;;;:::::;;t%%%ttttt    //
//    ..  :t. ....8 ;: ..88: ....:  X:  S: %    @  %     %  X  S S @ @[email protected]@8 S8 8:X X X S S% S.88 .:8::.8888;88888Xt.:.:.88t.8.888X.8X888%888888;.888 88;8.888:888888;8 888%[email protected]@ 888X8X88888X8S8888 @[email protected]@[email protected]@@t%t;tStttt;;;;:S:;;;;;;;;;;;;;;;;;ttt;;;:.::;;%%tt%;tt;    //
//    . . .....8: t....%8%.. ..8%  .: 8t % t% @   @  t %  S  @ S 8SSS @[email protected]@88 X8.8 @  X X % S.  888888 88888%[email protected]:8: 888;.88  8888t8888%88 [email protected];[email protected] :@%[email protected]@ [email protected]@[email protected] [email protected]@[email protected] 888888%[email protected]@[email protected]@8t%t;;ttt;t;;;;;:;t;:;;;;;;;:;;;;;;;tt;;:::::;:;t%%t;t;;;    //
//    . ...88t.:;.. t8;..:. . 8;: S: .:  t;  X: @.  %   %  X S % S X%S%%X8888888 8 @ S S S  888% 8.8;888:888888X;.S8 :88;[email protected];:888.88.8 [email protected];@[email protected] 888.88XS8888888888 [email protected]%[email protected] 8X 88 [email protected] [email protected]@[email protected]%%tt;ttt;t;t;;;;;;:::;;;;t;::;::;;;;;t;::::::::;tt%S;;;;t    //
//    .  .S.;.::. 8:   ...:..t . ..%. t t  S   X.  S  t  S  S S @ 8 St%[email protected]@ 8 X X X X:. .8:88888888888888.8:88888:.888:88 @ 888 [email protected] S8X%88X8%8:8.88X88%[email protected]@[email protected]@[email protected] 8S8 8 8%[email protected] [email protected]@8t%ttttt%;;;t;;;;;;;::;::;:::;:::::::;:;:;;:::.:::;ttttt:;;:    //
//    .  .:......::. 88. ..:.:   %:.%.  ; S. @         %  S % X S tSt%%[email protected] X%SS S t;88;8%:8:88.888;888888t888S 8.888.8888888  t:;; 888 [email protected] 8888X888S88 8S8 8S8 888X88 88888%[email protected]@[email protected];tt;t;;;:;;;:::;;::;;;;:::;;::;;t;;;:::::::;t%tt;tt;;    //
//         ..:.:..:t8;  .8t:... .. t:t t        X   %   S  S % @ %ttt%t%[email protected]@88888X S X  S...8;.8;;8888:.888:88 8.8888888;8:[email protected];8.:@;8 X88:X88.8.:%[email protected]@888:[email protected]@[email protected] 8S8XX8 [email protected] [email protected]@[email protected]%ttt;t;t%;;;;;:;;;:;t::;;::;;::::;;;;;::::::::;ttt%S;t%t    //
//    .. 8t ..:..8t    88t:.... S:t:  t %  @.     S  t   S %  X S t8.8 8%[email protected]@888888 XS X %88888; 8t; 8888;8;8888.8.888888888 888888888..:8tS;8.888:[email protected]:[email protected]@[email protected]@888%88 [email protected] 8888 8 8 8X8%88888888%S8888 [email protected]@@t88%t%%;tt;t;;;;;;;;:;:;;:;;;;;;::::;:::;::;:::::::;%tt%ttSSt    //
//    : :;..8;:.; . 88  .;.....8  . %  ;   .  @       % t % X  8    8t8 8S%%[email protected]@888X @S %:.t8.:8:88888S. : 888 ;888;8:[email protected]%88888:[email protected]%88X888;8:88:%:[email protected] 8 8%X888 88S8 [email protected] [email protected] 8 8%[email protected]@ 8 8 [email protected]@[email protected]@88S;tt;;t;t;t;;;;:;;;;;;;;;;;:;:;;;:;::;;;;::::::;ttt%%%X:;    //
//    :... 8:.:::..8; ; :...8t     %:; ; X      X  @     % S X 8 t 8%.8;8%%%%[email protected]@88:8 8 X  t  :;.:8::.t.8 8888: 88;88888888.8888;8;t.X%[email protected] [email protected];@@;X88S8S8X8 8S8S8 @%8X88888888 888X888X888888888 8 [email protected]%@888888888888X8X88%;t;;t;;;;:;;;;;;;:;:;;;;;::;;;::::;;;t;;;:;;:;ttt%%t;;:    //
//    :...8.::::.88;.t:... 8::  ....  t    X  @       @  % S X 8   :888;8X8%%%[email protected]@8 [email protected] S% t;:;:888 88 .:..888t;8.888888:888888%S8X8.88888.8X 88Xt8S8888888 [email protected] [email protected]@[email protected] [email protected]@8%[email protected]@%8 8 8 8 @88 [email protected]:[email protected]%;;;;;;;;;;;;:;;;:;;;:;::::;;:;:::::;;;:::;::;;tt%t%;:;    //
//    :.:  .::.: .;. .88 t8:;.... %:    t           8:  X  S S  X. ..% 8;8 XS%[email protected]%SS S% t;88888t.8:888888:[email protected];.8888888t8.SS;8888888t8S88t8888SS888 88;88888.%88X88888888888888888S8 8 8 8 88888%8888 8 [email protected] 8 [email protected]@%X;tt;;;;;;;;;;;;;;;::::::;::;::::;::;::::::::;;;ttttt;;:    //
//    :.:..:..:.... 8t;: .  .... 8 ;     t  %  S S       @ S  8  t 8:;8 8 8 S%%[email protected]@ @SSS X%%t.8;8;8888.8%:.:: 88.888888888;. 88X:%8t88 ..X% 8%[email protected]%8X888888888;@[email protected];888t%;[email protected] @88888 8 8 8 8 [email protected]@[email protected]@[email protected];;;;;;;;;;;;:;;;:::;:;;:::::;;:::;:::;;:::::;t%ttttt::    //
//    :.::...:....8t:. . t: .8t: ; .  S:  %         @ @   X X  @   : 8:8.%t%t%[email protected]@S X%  888t888.88:8t.8888888888.X888S88888 88888%8;8888%.8 8t8X88%[email protected]%X88 8;@[email protected] 888X 8S8 8S8S8888888888%8 8888S8888888888888 @@[email protected]:888;;t;t;;::;;:;;;::;:;;;;:;;::;:;:::;:::;:::::::;;tt%%t;::    //
//    :...8t:.:.88;... 88. 8S: .:.  S;:      t % @     @ 8   8   t :   :8 tt%%SSS XSX8XXS 8 8:8;88:.8S 8S88.8; 8888888 88S 888888;[email protected]%888888888%88;@8:[email protected]@ @888 @[email protected] 8888888X8 8 @ 8 [email protected]@[email protected] 88888888888888888888XS [email protected]%tt;;;;;:;::;;;;;:;::::::::::::::::;::;::::.::;t%%;t;;;:    //
//    :.:X ....;.;:  8;:: t. ......::  S:%.S  t    @. S S X @. X. ;:8:8: 8.;t%S8SS @X8XXS  %::;; 8.8888%88:[email protected] 888888X. St888888S:[email protected] 8 88 %[email protected];88888;[email protected]%88 @8.S8888:8;@88888S8 @[email protected] 8 8%@ 8SXSS888S888888888 8 [email protected]@88888888;88S8%;t;t;;;t;:;:;:;;:;:::;::;;;::;:;;::;::::::::::;ttt%;:::    //
//    :::t..8t::.. 88;.      .... .   .:    S  % 8.      S S. X. ; ..  8:.8.8 8%8%[email protected]% 8:8.88. 8 :8;:8 888888:88 %8:t8 .X8:SX:[email protected] [email protected];S8%[email protected]%X%888;S88:88;8888%888:S%[email protected] 8 8 8 @88X888888S8888888888 888%@88888888888S [email protected]@St;t;;;;;;::;;::;;:;::::;::::::::::;::::::::::::;ttttt;:.    //
//    ::::: ;:....;:   S8% t;...88t..S;  8t . t     X S % %  S  t ; 8:8t;.8:8;[email protected]% 888.8;8.8888:8t.88888.88 8S%88%;:8:8;%888;S8:X.8t;8 8%[email protected]@888%@88;8;%888 8.88 888888888888 @[email protected] [email protected] @[email protected]@888%S%%t;tt;;;:;:::::;;;:::;;:;:::::::;;::::;;::::::::;;;tt;:::    //
//    :::::::.:..... 88 % .....8t% .:: .:;  %  t  8    S  % S  t  ;.:..8;:888 [email protected]@88:.t8:8888%:;8.8;88.8888.88 88.:888;@S888 88;8% 888t:8:[email protected] 8888;@S88t8X8;;[email protected]@8 [email protected]@@888888 [email protected] 8X88888888 88 @[email protected]%[email protected]@[email protected] [email protected];t;;;;;;;;::;:::;:::;::;::::::;;::;;::::.::;;;;;;:::    //
//    :::::::.:.8t. 8: :    ..:t: .  .S;       t   X 8   X S X  ;  ;:8; 8;8:88 8S8%8%[email protected] 8.8t 8;8: 8888888888 8888;X8:[email protected]@88:S8:S8X88X8 % 888SXS88888;[email protected]@ 8;[email protected]@@8888888 [email protected] 888S888888888888888 [email protected]@8888888888888X [email protected]@SSS;;tt;;                                                     //
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract OGITL1155 is ERC1155Creator {
    constructor() ERC1155Creator("Off Grid", "OGITL1155") {}
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