// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Editions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    ;S8.   [email protected]%S8;t:;@:;;[email protected];  ttXS;;;:.:::.:.:.::::::::::tSS;:%;::::::::::;;::::..::.:.. %%...... . . ..: [email protected];Xt.  %8:8:    //
//    [email protected]:8t: 8S%8%[email protected]%.;; [email protected]%%; :t8%S:..........::.:.:.:.:t%@%;;:.::::::::.:........... ..::;......::t;:tX8 %X8S8XXSXt @88    //
//    88.8.S;8; 8; 88SXXSX8..;:%;:  ;St::@..:.::....:.:.::::::.::;::.:::.::::........:;. ... .....;;.%[email protected]%%:SS:   ;%:;@[email protected]@.8    //
//    @88t:@[email protected];%[email protected] %8 8t ;t% : [email protected]:S .:.:..:.:.:.....:.:..::....::.:.::.:.:....::: ... ;tttS88.%.;;%%@. 88t%:8X ;@.t:%@    //
//    t.  [email protected] [email protected]@@[email protected] %SX%: t: :.:tXXt..:......:.:..::..:.:.::..:::::. :...:[email protected]@@[email protected] %X ;t;;[email protected];S:.8 8X.    //
//    @S.:SX%:XS ..:8 [email protected]:  @ @[email protected] .X;::X%XS8..::......................:.::::..:..:. @[email protected]@@X%:.;t%  .   :: 88X .;S. 8    //
//    :  8:@[email protected] X t8: [email protected] t;:  888S;  @ X.; t @@Xtt.::::::.::::.::.::...;;;::...::....... [email protected]%[email protected]%t.: %t; S%   88.X .%8;8.8     //
//    S8XX :.  @S%  888 XSX%[email protected] 8 .X8.S [email protected];S;[email protected]@[email protected]@[email protected]%S%;.;X888 8:;8.::.:;::....            .:t    //
//    S:%8;t8X [email protected] 888 .8X:[email protected]%t%@[email protected]%S88S%S:.: ;[email protected]%;@X8%ttXS 8:;8  8;[email protected] 8 ::8 88::;@ 8 ::.8    //
//    . %:[email protected] @8  @S   %88X: 8%8::.8;@;[email protected]@[email protected]@@S ;%8%[email protected]@@t888tt%[email protected]; 8 .88:; @.8  8. 8%;. S;%8.:;; @    //
//    S88888  tXX;;tt;;t;;:@:.;% ;t8%[email protected];8 [email protected]@X888XX8 t8888:[email protected]: 8:8X 8tX;8888S8;8;. 888 8.; 8;88 .% @;%.888 t:.X  %@[email protected] 8    //
//    : 8 @8S::;t%;::::;S8%8.8:. XS8%8%@%[email protected] @@S; ;;;;;8tSt8: @ [email protected]@8X88S. S8888888 %8 [email protected]:@X8.;;.%S  8    //
//     [email protected]:8:@SSS.SSXt8S888Xt%tXS8. [email protected]%[email protected] .88XtX [email protected]   8%S;t%t [email protected];   8t: [email protected]%.; 8S88 :8tt88%S:.8 .8    //
//      8X8 S%.88%;;8tS8tt%SS8X.S XXX8X8S8:;t;88X;[email protected]:[email protected]@S8 @S   :8.: ..88. @@88888 .;SSS X  8%t 8XS X.:[email protected]:t:t:t8 [email protected]    //
//    X  X8 X [email protected]:X%St%S%[email protected]%8XS8%X%8 8X8S [email protected]@[email protected]  88888 X888 S8 88;XXt88:.: @.8tXttSX88S:.;tX %%t;% 8 8X    //
//    [email protected] @@.X8S8t8;[email protected]%@S;;8:88t;@%XSS :S88;[email protected]@88S88X 8888t;8: [email protected]: :;.88S [email protected] 8 888.8 8Xt888 ;;S% ;;8; :% @[email protected] ;8 S8 8    //
//    : 8 :[email protected]%8X8S .8  8 X88%tt;8SS X8%Xt8:. S88;%88:8t [email protected]:8 %%.88888:t88%t 8::@ ;X8t8%8   8888 ;@.%t%S     .%[email protected] 8.%8%    //
//    %t8   X S8SS88.  X  8888 88 8X;S;t;8%[email protected]@[email protected];;.;.8; 88:%S8888;;  XS88X8X;@8 [email protected]@ S :X8 .8 %.8S SSS; 8 @SS @[email protected]  8X8%     //
//     X    8:@[email protected] 888   X  8% 8888;[email protected] S.;;%@8S8888.88 8%8. 8%t8;  S8:88  88:8. X8 88888XS8888%:8 [email protected]:%X      @ 8  8 8 ::    //
//     8X: 8Xt;[email protected] 88%;8  8 8888 8:% t8.:S88888;.8t888 t;t888888 t XX8 :8:8 ;;:tXS%%[email protected]%88%.  8t8 ttX [email protected]     X .:8..8.S    //
//        8;;;@[email protected] 88888 [email protected]  t 88S 8:SX8 [email protected]%88888:[email protected]%@   tX8t8S888:8t8tt8888t888888tS8:X8:; @ 8  : : 8   88.;8::8:;8     //
//    8 X8 X.:[email protected] 8 8888%SX88 ;;[email protected]%SSX.t%X8S 8:SX8S      8t88%8S.  .S8888%88t8S8t 8S8X888888%8 88S8tt  8: [email protected] 88.;t8t8.8 8S    //
//    @  [email protected]@8t8:[email protected] X ;[email protected] 88;X8;t8ttXX   S XX%S;SS88SS8::tt;[email protected]% 8%tt8;[email protected]@tS8;88X8.t:X888%@ 8888%%%8;t8:8.8S    //
//     [email protected]:[email protected] @  SSS   %8S8S::[email protected]:X888 8X%  X8X .888:8:%;;tt%[email protected]% S88S88%[email protected]@[email protected] 888888;[email protected]%@88t8 88X%SX8%S8;8;8S.    //
//    ;;.S8;t.t;:8t; 8  [email protected] [email protected] ;[email protected] 8 [email protected] S%88S.t8t8S;.;;@@[email protected];;88%8%8%[email protected]@8888X88:88%%88S8X%.:%:8SS8XXX8t8.S8:[email protected]    //
//     X8S8%%%.  X8X8 [email protected]@88; %8X8  888 [email protected] 88888 [email protected]@t.t: tt;%[email protected]@8t%S:[email protected];;[email protected]%[email protected];%8%8%8888%8 X;[email protected]@88SXX%8:[email protected]    //
//     88%.8.X: [email protected]@XSS88S%t88%[email protected]:8;8  [email protected];:;;:. ..;@ Xt;:.. ;tt%X8Xt;t;[email protected]%[email protected]::@X8S8.%8XtS8    //
//    [email protected];[email protected]:[email protected]@[email protected]%[email protected]%[email protected]%888SS%X  SSX;X:: S %S: [email protected]:. :%tttt%%[email protected];@8%8S;X8%%8:[email protected]@@8;%8    //
//    [email protected]@[email protected]@[email protected]%XSX88S8%[email protected] [email protected];% [email protected]%XSX8 88S88888%% 8SX8S%%8; 8.:.88S   @%%S%[email protected]%8S8;; 8:[email protected]:8X. ;8;[email protected]% 8    //
//    8 ;:@[email protected] S ;[email protected]@88t%S8X8%%X%8 S;8 88888S88;[email protected]    XX;@;%%[email protected]%8t8888%888 X  ;X%%tS8S8888%:t8S8%[email protected] 8S::S8%8%8%8 %    //
//    @ 8::8:. @[email protected];%8S%8t8%;;:t;X888 8%8XX X SStSXXS8%S888%%S.88:[email protected]:8 8  ::@t%%[email protected]:.; .8t8.%8SX%[email protected]@[email protected]@:@t8XXtS.:88X;    //
//     t8:8t8 8 @888X88;.%8 8S;t%S%SX;8%8t8 [email protected]@S88X8%t :[email protected] [email protected]%88 8 : %8X%@8 ;;.;:@[email protected]@@;X%:.;:S.XX:8St%;88%;8;%    //
//    [email protected] 8tX;X%S%S8888%[email protected]@[email protected]:@8;8 %:8tX%@;888;@@@SS%tS:;[email protected] [email protected]@[email protected]@;tS tt:[email protected] .8X;tSXXX    //
//    ;%S:;@8:tt% S%.888:[email protected] [email protected]%%@[email protected]%SX8%t. [email protected]%;XXt.;:;@88888 8SS%%SSSS;;S .8;8 ::  ;8;:.8XXS8  @:.t8t88X;[email protected] ..S8    //
//    :@ttX:[email protected]%;S8X;@SX8888888X8%[email protected]%X8X 8.8:X;t:8; ;[email protected]%[email protected] 88 88Xt;;[email protected]  8 ;;: .8;88S;t @@@% ;.8S:  Xt ;; %XX; :88    //
//    %@8:  ;:t8%S8%tS8X8%@[email protected]@8.SXtSX8XXS::[email protected];888Xt X88;[email protected]@ 88  .8 88t8     8X   8 8:[email protected]:[email protected]@8X8X 8    //
//    S%@@8%t%;S88X.8  [email protected]; %@tS%@;%%[email protected] [email protected]@[email protected] %X8 8 t;.t888 8  8 @  8 888   8.8 88. .:.%%%%%S:%t;.8 ;SX8XStXttXX.:;8    //
//    S;8: ;@8;[email protected];88%@@8X8%88XX.SS%S88X88.%X 8. @[email protected] 888t88t   ::88     888   X  8 8   8 [email protected]@[email protected]@@%.%S%%%:      S:SS     //
//    [email protected];8:X8;%Xt;.;88% :@[email protected]@[email protected]@@ :@@.8;8 S8   @ @8X 88 88 8S888    88      [email protected] 88 ;8S;;.:t;:....:;;;t;tt;::: tX:t;     //
//    8X88S8:8X8X888 .tS88 %;%. [email protected]:[email protected]; [email protected]@t S  ;:  8 :88  S888X @[email protected] [email protected]%8 .: . .:::;t%ttt;t;;;;;;:SX.;S%    //
//    [email protected]:88.888 8t888%[email protected]:@:S 8.8S; SX::tt      8 8    ; SX  S %            8 8 8 ;8:..;;;;;;:[email protected]:88X;;;;;:;  t;. @    //
//    88X.%[email protected]%8 XtXX8888X;StX.S;[email protected]   8  @: X88X   @88  SX8X88 S8 ::         .8   t8 X%:.t;t.88SSXX:8;S;S;;;:;:[email protected]    //
//    8X8S @t8X%X.::[email protected]@t;[email protected]@t8 S8S8.:[email protected]%8:%[email protected];8S88888 8  :     .;8..   [email protected]:%t:%%88. 88t @t8tt;;t  %%S%:    //
//    888 88888 [email protected]@8%[email protected]:8X.8%@%;X 8. S.;[email protected] @X:[email protected]@%[email protected]@@@%[email protected] ;   .. ..8.:  8S %%[email protected]@ 8SX%t;t:%%SX8X    //
//    @  X:  @ @888XS S  :S8888 8  8X .t.Xt;.  % [email protected]@@8 : .;;;.;;:; t 888 t: tX8S:Xt SSX ;88%888S%..;SS88    //
//    ;8 ;t    8 X88888 X; t8 [email protected]   8SX:%t%t.t :::@ [email protected]@@:  88 : 8.t   t 88 S8; %@%%S 8888S;88:%8t%;8tX%8S    //
//    .;t: SX     @XX8 ;888:.8 [email protected] ;Xt%%%.:[email protected]@[email protected]@[email protected]@     t     @ %888%  :%X888  88 8SX;888SS8S;8%Xt.%    //
//    St% .%%        88 @[email protected]    ;%t.:: %[email protected]@[email protected]@[email protected]@[email protected]@S8 X  88 @88 8 @%  [email protected];[email protected]:t S888 8 8t:8888%%SSS%8X    //
//    8%: :  :    8 [email protected] 88S @  8 X8 8.  :.. ;X888888X8;[email protected]@88X8;@888888S8  S8888:88;88%:%888%888S888S 8 888X %;[email protected]@    //
//    .S%. 88  X  X88888  888      8  [email protected]  X%;t.;@[email protected]@[email protected]%8 [email protected];[email protected]@@[email protected] [email protected];S :tX8 X88 [email protected]%88;% [email protected]     //
//    . 8 888  @ @S%X 8SX .88%%8S 888  S   S tt. @[email protected]@[email protected]@[email protected]@[email protected]@88X8t88888888X8 8%8%@8;%S%[email protected] 8XSX8X8.SXS8%t% @[email protected]    //
//    :8%8% 88  @ S 88888888 888888888888%  8  @ @@@888888%X888X8t8888888888t  t;S:88888X888:88:;X 8.X8;8X 8X8SS88 ;X888SX:@:S    //
//    SS;% @88  S8 88888888888%[email protected]@[email protected]@[email protected];[email protected] [email protected]; :8888X%;[email protected]%[email protected];S;X8t    //
//    t8t% [email protected] 8S%[email protected] 888888888X8 [email protected]@@@8%[email protected];t88.S [email protected]@@  888;[email protected]%[email protected] S    //
//    :XS    88  [email protected]%88S8888888888% [email protected] 8%[email protected]@[email protected];88S%888888%X8 [email protected]     8S8X;t:%@888%:.88 ::%[email protected]@;    //
//    88SS :8X;  S 8 [email protected]%@88S888888888 88888 @[email protected]@@@[email protected]@@@[email protected];[email protected] 8 8   :8;.8.888:@:@[email protected]@[email protected];%%8 t    //
//     t 88 888 S%%S8X88 X [email protected]@X888888888S:88  [email protected]%@[email protected]@ 8. 8    @8% [email protected]@888888888888%8S:XS    //
//    @tS88 . [email protected]@:SSSS %[email protected] [email protected];8 88. 8888%[email protected] @8 XS%8 S::88888   ;S88X   88;%[email protected]@@[email protected]@[email protected]@.:    //
//    ;@XX8  [email protected]%[email protected]%S;[email protected]@t8S8888 8%;8t888%[email protected] S:S;X.:[email protected]   X ;S @  %[email protected]@[email protected]@[email protected]%    //
//    X88   [email protected]@X:8 [email protected]%%8;@8888888%@SS  ;888S88888%@ .%8%@  @;  8 %88  8 S8 8    8:[email protected]@[email protected]@[email protected]    //
//    %8X   8: 8S8X 88888%888S%8%8S8X88 88XS [email protected]@8 X%8  888 [email protected] 8X     8 S%8 [email protected];[email protected];t:8888S88888 ;[email protected]    //
//    ;    .8 .8 8S 88 [email protected]@XS888888888 [email protected]@8;[email protected]@@t.888.8.8S;888%[email protected]@% % :t8888 [email protected] 8X   8;[email protected]  X [email protected]%    //
//    ;X    [email protected]@SSX888X SSS [email protected]@.. X:X%88X8X;8X ;888888888X888X88X8%8.;.8888X;[email protected]@[email protected]@ 888 @;8S:[email protected]    //
//    X  8  88:X8 :%X888XXS;.%[email protected]@@8tS8%[email protected];S%[email protected]@[email protected]@88Xt8888XX8SX888888%[email protected]:[email protected];8   @ 88S88    //
//    8St  ;S88888 %  @[email protected]@[email protected]%888t %[email protected]@88%@@S88X8 8%tX8%[email protected]%[email protected] St 8;@[email protected] 8%%@ X8 88X8X88888S8888X     //
//    8t @S8%.8t ..%[email protected]@;;8;[email protected]@8  @%88S:@[email protected]%@@[email protected]%;8 S8888  8X888%[email protected]@%[email protected] tS88.X;@:@; .S88SS 8S888XXS..8X    //
//    S%   8:[email protected]%[email protected]%@@[email protected]@@[email protected] @ ;SX8; S88 8XSX8 8;[email protected]@X%XX%S%[email protected]@[email protected] ;XS;t888 @ .;t [email protected] 8S.8S888X%@[email protected] S @X    //
//    %% @ @8%[email protected]@[email protected]:%%:[email protected]@[email protected]%88X%8;XX @8 :S8;@[email protected]@X%[email protected]@[email protected]@S :St %@[email protected]%@:[email protected]@8%[email protected]@:8X%    //
//    tt%. 8SX  .S8;[email protected]@X;[email protected]%@S8 : 8; %:%% :[email protected];t%8;S% .S8%8 :@@[email protected]@t;; @:@;[email protected]@[email protected]:@    //
//    .:[email protected]@S :%%.;: % ;X88;X8; %tS: ;[email protected]%:@[email protected] [email protected]% t [email protected]@S88888888% 8:88S:S%[email protected]@[email protected] ;[email protected]     //
//    t8888;S%[email protected]%t;t;%X8:[email protected]  @@8S88S  @8 %X  S8 8;8 X %8%[email protected]@[email protected]@[email protected]  88X8:[email protected] :[email protected]@@%[email protected]@[email protected]    //
//    t8.:@[email protected]@8:888S;;t:@@@[email protected]%88 [email protected] 8  8X.8t8 8 [email protected]@[email protected]@ 8t%@:X8X%[email protected]@[email protected]:[email protected]    //
//    . 8S8S8X8X;8X8%t;tt8 @ 888S8 88888888888S  @8  88. 8:S  @@[email protected]:.;[email protected]@[email protected]@[email protected]@S8S8888S    //
//     8%[email protected]@8%@ % X;t;S %@  8.888888 [email protected]:. [email protected] X ..X ;888 @[email protected]@[email protected]@[email protected]%[email protected] @@ S    //
//    :S8tX88S8t8XX88S;;St8S%8 [email protected] :t;;.::...:;%@ @8S8SX:;[email protected]%@[email protected]@ .8 8:8888 [email protected]@[email protected]@[email protected]%%XS8 88    //
//    : [email protected]%[email protected]%;888::;t88X:t... .;::...;::..:::%[email protected] :[email protected];8888S%X8XX88 8  8X88%888%[email protected]@[email protected]@88888888SS88X 8    //
//    8:[email protected]@888ttX%X;8;[email protected]   .   .  . ...;:....::%XXX S S;X8 8%[email protected]@[email protected]%:88 888 @8t [email protected]%S88888;8%[email protected] 8    //
//    :: t8X8%X;t%;XSS8Xtt:.   .  . . .....: .:;:%X%   8 ;@@ [email protected]%[email protected] @ .8888888% @8;%@@@[email protected]@[email protected] 8tX;[email protected]    //
//      .;8%[email protected];%8tX8%8;S8%%S%t%;t;;t;tt%S%%%%tt;:8;8X; 88 : ;;[email protected]@:8XX8; 888 [email protected]%[email protected]  %% [email protected]@@@[email protected];8S    //
//     ;%@[email protected]@[email protected]@8t:t%%%%%%%%%%t%t%t%%%%%St888;  [email protected]:t8 %;[email protected]@88888%@S8% . @8X8888 888%88t888%888X88%[email protected]% 8:8     //
//     :8 S;.SttX8% [email protected]%[email protected]@%%%%%%%tt%ttt%%%%%%StXt %88 8;St ;%[email protected]@[email protected]@[email protected]:888 [email protected]%[email protected]@[email protected]  X:     //
//    .:tS % ; 8S:%[email protected];S; 8t;tt%t;t;t;ttS%SSt88;888%[email protected]@@@[email protected]@%[email protected]@[email protected]   8 88.888S8S88 :[email protected]% 8 88S 88S:8    //
//    [email protected] [email protected]% .;%[email protected] 8t :X%tt;;;t;;ttX%XS8 .tSXSX S%@ [email protected]%@[email protected]%  888:8%88 88 888 @88X%8%8S8:@888SS 8S88t    //
//    [email protected]% .%X8S88S ...X%t88S88  t 888X%;;ttt%[email protected] :  tX8%; [email protected]@@[email protected]@[email protected]@%[email protected]@[email protected] ;@[email protected]@888X8:8    //
//    XS; X; 88X [email protected]:888X88S [email protected]@88.%XS%:t%[email protected]@8 SX : : %@  t%t tS [email protected]@@:[email protected]@  :;X8 8t88.S8888 [email protected] 8 [email protected] ;  S8 8S88     //
//     XXS%88 8S8 8:;.;:;t;:t;[email protected]@St8X88  @;%SXX8 t8.8:%:.; X88S 8%.XS888 88XS. .%8: % 8 8888:[email protected];X8.S [email protected]%    //
//    [email protected]  ..;8 8 @ SX:@SS%%%ttt%@X%; 8S :.St%[email protected] @t8%XX 8.;[email protected]@@t.:@:: X:[email protected];  tS.. .Xt.%XX 88 88888X 88S [email protected] 8888 t%.    //
//    ;t;XS   [email protected]@%S%;%[email protected]@%@888%@@@@[email protected] S%8SX % @ t8X:88;S   t  8.S8.S %S: :[email protected]%8;;@888 [email protected] 888 8 X%X    //
//    :@[email protected];[email protected]  ::: .::.   ;:..:;%[email protected]% S:8%888%.S SS%X:@@8%@8 8 88tX;SttX.8:8 888 [email protected];@%StX%8SSX  [email protected]    //
//    ;;[email protected]:. S%t%  ;[email protected];;[email protected]@8t;;[email protected] 8:@@ % . @ @ 88:[email protected] ;S8%%%@t%8888t8888    8 S;[email protected]@@@@@[email protected]@%SSS8S:S    //
//    t8:[email protected]:;S ;%S8  . :[email protected]@8S%:  SS X8  [email protected]@8X 8%;8%@ 888XX;@St.XS S ; @S:8  %:8t;:888%:888%8X8S St8t:88S:[email protected]%[email protected]@:88S    //
//    [email protected]@    8S;8X8%[email protected]@S8X8.tX8%[email protected]@@;[email protected] @t8S88XX:88  [email protected];  8 8 [email protected];t 8X Xt88 %t8tX8S%:S8 % [email protected]%[email protected]:[email protected]@  [email protected]    //
//    8t:: XX.%8X;[email protected];@X%@[email protected]@SXXt:S88 %:;8:;[email protected] @%8:[email protected]  ;  . t8X8%.:tS t888X %8%tX8.  :%[email protected]%8;%8St8S8  [email protected]@:[email protected]     //
//    [email protected];S%@[email protected]@:;SS. .XS88:[email protected]@  %X:t%St:XS  X    % @:.:%888%.tX: .8X.8:[email protected]%[email protected];88S SSS8 . ; tX%[email protected]: .:@ X     //
//    %[email protected]%: @;88%.X 88t ;;t8 [email protected] @8X 8X8 @X:t  @ 8 SS;@[email protected] t:@@t ;S%t%S8S .t8X 88;S [email protected] ;@[email protected];  :8;:;%8;St88 ;.; @[email protected];tSS        //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FEMALE is ERC721Creator {
    constructor() ERC721Creator("Editions", "FEMALE") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xe4E4003afE3765Aca8149a82fc064C0b125B9e5a;
        Address.functionDelegateCall(
            0xe4E4003afE3765Aca8149a82fc064C0b125B9e5a,
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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