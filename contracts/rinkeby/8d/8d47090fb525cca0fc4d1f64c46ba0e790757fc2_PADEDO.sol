// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MICRONS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!it!!!!!!!}!!!!!!!!!!!!!!!!!!!!!!t+!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!++}}+t+!!!!!!>|____|!!!!!!!!!!!!!!!+i!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!vL+!!    //
//    !!Ic!!!!!!!!!!!!!!!!!!+!!!!!!ceC8?!!!!!vq}!!!!rclz?!!!!!!!!+sn]A0z!!!!1CCc!!!!!!!!!iz+!!!!!!!!!!!!!">>"!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!z]+!!!!!!!!!!!!!!++}}}++++}t+!!!|\,-'^;;^,,"!!!!!!!!!!}lv1?!!!!!!!!!!!!!!!!"^-':_!!+v+!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!tt!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!+vt!!j]!!!    //
//    !!!uP0i!!x2!!!!!!!!!!!lz+!!!tzCnn2n?!!!llx+!1znC8I2ulr!}+!e$InUpk8?lCi]PPPCznnr!!!!1t!!!!!!!!!>~'::'''':-:\;>!!!!!!!!!!!!!!!!!!!!!!!!!!>|>!!!!!!2BH8!!!!!!!++}}}}}++++}}}}+!!!!>-`;"!|_^^^,,"!!!!!!!!!}2+!!!!!!!!!!!!!!!!!!!_`|!_,\>!+!!!!>|;^|!!!!!!!!>|"!!!|'->!!!!!!1s!!!!!!!!!!!!!!!!+1llllllcllzs!!!!!!!!!!!!!!!!!c7!!!!1&HBn!i?+!!    //
//    !!!qWPj!!!!!!!!!!!!!!!!!!}z}eCICPUgIc+!]Ivanzr8Z0pnay0IaxzI0dnCnzzCn0d00SCCZG$zzaS+!!!!!!!!!"\`^>!!>>>>!!"|~`\!!!!!!!!!!!!!_:''|!!!!!>`,\`\!!!!!!1l+!++}}}}+++++}}+}++!!!!!!!!"`-""~,'~;;;|"!!!!!!!!!!+et!!!!!!!!!!!!!!!!!!!"^`^"!;::-'':':'~;`-!!!!!!!_``,'` `^"!!!!!+t!!!!!!!!!!!!!!!+zz7+1llllzz}!ni!!!!!!!!!!!!!!!!i}!!!!+qPAv!!!!!!    //
//    !!!!!!!!!!!2C!!!!!!!!!!!!ixCn00dnnx12nCnxen2zlz2Cp0whnnCnqu0USS0eaarzS]rs}aZSlltvc!!!!!!!!!|`'"!_,:'''':::\\`'!!!!!!!!!!!!!`^!|,,|!!!^`"!\,!!!!!+}}}}++++}}}}}++!!!!!!!!!!!!!!~`>!^`>!!!!">|>"!!!!!!!!!rx!!!!!!!!!!!!!!!!!!!!!>\,'|>"!!!!">|_\`\!!!!!!!!!|^\;>!!!!!!!!l]!!!!!!!!!!!!!!+aj+zz7+!!v2v+z2!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!a2!!!!!!!!!!!!!!!!!!!}lcs}+!!!!!n8vlz}nae100C2Sl1+vaCC0n$Px0dICxr!!!+v+!!!!!!!!!!!!!!`\!>-`|!!!!!!!>__>!!!!!!!!!!!!!!~`\"!;`'>!,'!"`'!+i}++++}}}?c71}!!!!!!!!!!!!!!!!!!!\`"!\`>"_'--'':,:>!!!!!clc+!!!!!!!!!+?}!!!!!!!!!!!"_\:,''''-'\~_>!!!!!!}st!+!!!!!!!!!!!?z2l!!!!!!!!!!!!!ec"x1!!szzr+le1!!!!!!!!!!!!!sel7z+!!!!!++!!!!!!!!!    //
//    !!!!!"|~^_>!!!!!!!!!vx1+!!!!!!!lc!!!!!+x2tllvvzeIeuz+!!!vcjj}jnzlzz+!!!!y?!!!!!!!!!!!!!!!!!~,:,\"!!!!!!!!!!!!!!!!!!!!!!!!!!!>\`;!"\`,`>!;`|+?!+}+}+!!vrzltas1s+!!!!!!!!!!!!!!!>`\!"'`,\|!">>!",,!!!!!2!!!!!!!!!!!szzn!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!+z}az3z!!!!!!!!!!jzv2+!!!!!!!!!!!!zz"2zllv}vzz?!!!!!!!!!!!!+!tnzl!xl?!!!!!+!!!++!!!!    //
//    !!!|:,';_\,,>!!!!!!!}z!!!!!!!!!!!!!!!!!!z!!!!+laSIzs!!!v!!!!+vv!!!!!!!!+z+!!!!!!!!1lv!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!>-,_!>|""^`_!i}!s+!!!!zz!!!?}++}zi!!!!!!!!!!!!!!!|`->!>"!"^,:_!>`\!!!!!lz!!!!!!!!+?z2jyi!!!!!!!!!!!!!!!!!!!!!!!!!!!!!izz7etln+!!!!!!!!!+l1z1+!!!!!!!!!!!+3z11cllzj!!!!!!!!!!!+s?z22l3nnv!!2z!!!!!lb!!!!!!!    //
//    !!!`'!"_;"!\`|!!!!!!}2i!!!!!!!!!!!!!+sj!t!!!!!!1z7!!!!+3!!!!2l!!!!!!!!slclcccccclzr}I1!!!!!!!!jvsclj1}+svll7t!?7vs1}+}}cv1sst}!!|-,''','>!+?++t!!+?tczsrt?r+}izl!!!!!!!!!!!!!!!!"\`_!!"!!!>_\`\"!!!!+zl!!!!!!s2cxz2?+27tt}!!!!!!!!!!!!!!!!?lv!!!!!!z!!!z!+1cl!!!!!!!!}cvzcv!!!!!!!!!!!!!+??}!!!!!!!!!!!!!!!3c1vvvazncxuCIl!!!!!!+!!+!!!!    //
//    !!!_:'-\,,"!-,!!!!!+dS0+!!!!!!!!!!tzz7e2!!!!!!!!?a+!!!!!!!!!!!!!!!!!tec}?vcccccvrczlj!!!!!!!!i|`>';tizz`|\'jlc'||itzj-|`"1e^|!l!!!"||>!!!+t++?++x]rzv+lzt?r!zxzI?!!!!!!!!!!!!!!!!| _!_`,'''\_"!!!!+zzt!!!!!!1zc7esj1vz12jvc!!!!!!!!!!!!!t1vee!!!!!+e!}2xl+cz3+!!!!!!!?zvz12!!!!!!!!!!!!!!!!!!!!!!!!!!}zyaz2enav2sIunaInn?!!!!!!++++?+!!!    //
//    !!!!!!!!_ |!;`"!!!!lPIq+!!!!!!!!!z2+jzz+!!!!xt!!!!!!!!!!+j!!!!!!!!!+u}}actiiiiii?i!!!!!!!!!!t; _li `t"}\}! |s|:+|`tl__+- }s_+!e!!!!!!!+}i}!+t+!!zstt1S1!+j+!!ezz3!!!!!!!!!!!!!!!!_ |!;`>!!!!!!!!!!et!!!!!!!!?xal22zazzll!!l!!!!!!!!!!!!!cvvtl"t+!!lelyzznaz2Cl!!!!!!!ixeul2!!!!!!!!!!!!!!!!+titi!+s1lIz222]2cu]Cunaezazl2xIa}!!!!!!?n?!!    //
//    !!|~^~_>:`"!'`!!!!!zAh0t!!!!!!!!c]"zz!!!!lllnl!!!!!!!!!!vw+!!!!!!!!el!x?!!!!!!!!!!!!!!!!!!!!?+,    |>\',!>'\''!+!!!!}7vi__!"!11!!!+}}}+++}}+!+7vs!!!!xi!ss1!!evjcl?j!!!!!!++!!!!!>`^!|`;!!!!!!!!!!e!!!!!!!!!?tr1itc21czzv1c+!!!!!!!!!!!ililc>,,c!!+?ttit?itt1+!!!!!!!7zeexCezlz2c!!!!!!!!!!l7!!+jt!lczee32v1vvzz22?cc771rsr+!!!!!!++!!!!    //
//    >,,;_;\-->!_`_!!!!!?00hlce+!!!!!va"z2!!+yt+1+z2"!!!!!!!!!!!!!!!!!!!z2zz!!!!!!!!!!!iz1!!!!!!!!cczl2vl1zxv?sszn1sicvld7j+t}iI++!!!+i}++}}}+!!!!vlr!!!!!n?!!sc+!il!!!+jz+!!!!++!!!!!!',!!:,!!!!!!!!!!]t!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!+va7c';"l+!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!}}!!+!!!!!    //
//    \`"!!!!!!!\`_!!!!!!!aqnlL2+!!!!!!el!l2vez+CC+?x"!!!!!!!!!!!!!!!!!!!!++!!!!!!!!!!!+QHBb!!!!!!!!!!vu+!!!ei!!!r]+!!!!tl+!!!!+c!!!!!ti}}}+!!!!!!!!cv!!!!!n}!!1c+!!ssci!!+z!!++!!!!!!!!|`_!|`;!!!!!!!izl!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!iyzzz2v+lhUz!!!!!!!!++}it??svvvclzzzzzzz22ee2?!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!++!!!!!!!!    //
//    >,,^_|_;"!\`>!!!!!!!70l!lxy]z}!!!!c2v+jl+}c+7yt!!!!!!i+}si+ily222zc}!!!!!!!!!!!!!!AmPz!!!!!!!!!!!!!!!!!!!!!+!!!!!!!!!!!!!!!!!!!!!+!++!!!!!!!!}z!!!!!iC}!!!!!!!!!zClz+iz!++!!++!!!!!\`>!:`!!!!!!!z+!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!+22sittitzzr!!!vxyaaaayyy2zzzzlllllllcv11sti2d?!!!!!!!!!!!!!!!!tssjt+!!!!!!!!!!!!!!!!!!!!!!!!ay!!!!    //
//    !!>;\\\`:!!,,!!!!!!!il+!!?Iy?!!!!!!!sll2t}ylv!!!!!!+7>:_>>>>+y222z2x1!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!eC!!!!!!!!!c0b0j!!!!++!!!++!!!!!!1zxIr!!!!}8j!!!!!!!1nppnn?!?2iit?1t!!!!!"\,:,_!!!!!!!21!!!!!+}}+i}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!+Ca!++}i??s1vvvlzzzzzzz22eeea3Iy+!!!!!!!!!!!!!!!rz++tjsl!!!!!!!!!!!!+it?t1!!!!+i+!!!!    //
//    !!!!!!!_`_!_`|!!!!!!!!!!!!!!!!">>!!!!!!vy!x?!!!!!!!1;+sjr!>>>n2zzzz2xv!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!?a}!!!!!!!!IP!pw!!!!!!!!!!!+++!!z0y2pa!!!!+Ci!!!!!!xpphgI!!!szj!!!!11!!!!!!!!!!!!!!!!!+z!!!i}+++}i}!!!!!i+_v+t+t!!!!!!!!!!!!!!!!!!!!!!!!!!jaaax]yy2zzzllllcv111111sti}++!!!!!!!!!!!!!!!!!7r2++1}v!!!!!!!!!}clscvs!jl!!!rj!!!!!    //
//    !!!!!!!!,,!"`'!!!!!!!!!!!!|^:,,-,`_!!!!!a+?x+!!!!!!t'}rtl+>>>ezzzzzzzaz?!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!jl'a+!!!!!!!}Gs]G!!!!!!!+lczb8xv+I00pgx!!!!tnt!!!!!!lCIz?!!!l1!!!!!!+as+!!!!!!!!!!!!!!}z1!!t}!i}+!!!!!!c"s!`},+;!c!!!!!!!!!!!!!+s72zzlj!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!+}!cs7iZuczzl!!!!!!!!+c+zrt+ezcz}!!!!!!!!!    //
//    !!!!lar!_`\~`\!!!!!!!"|\,,,\|"!!>`-!!!!!+ycut!!!!!!j\>"!">>>>z2zz2z22z2xa]2zc+!!!!!!+t?+!!?+!!!!!!!!!!!!!u+`nz!!!!!!!!An+Gl!!!!!!2Sveq0Ak0q8dZ0z!!!!in+!!!!ts7c!!!!!!ixcvst!!zuzc!!!!!!!!!!!!!!a+!!!?++?!!!!!!+tv},,"1>|}vs+icz]j!!!!!!laiiI2zs2z}?!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!lzlz!12zzz7z2s!!!!!!+ztyczaqj!!!!!!!!!!!!!    //
//    !!tk$aX1!>;;|!!!!"|\,,-^|"!"|\-,,\"!!!!!!!}+!}st+">?\|>>>>>>>}l2e23322zzzz22ext!!!!!t`;y?vxl!!!!!!!!!!!!!l`+?i!!!!!!!!SZ!Pu!!!!!!?SA$n0PZ00p$eti!!!!lC!!!!i3t!ti?sttr?lzi]ats!l!!!!!!!!!!!!!!!!x!!++s+!?!!!!!?v!t!+1!lcce2e2nSCCr!!!!!!zi12xI]t72z2at!!!!!!!!!!!!!!!!!!!!!!vt!!!!!!!!!!!!!!!!c2cCInx71cIzzye!!!!!turCyInxl!!!!!+?}!!!!!!    //
//    !?PesAn!!!"|;^\,,,-^|!!"_\,,,^|"!!!!!!!!!!!!vr>`   +|_>>>>>>>>>>>>!j3ezzz22zz2ui!!!+" :2!!!!!!!!!!!!!!!!!v!zc!!!!!!!!!00!P]!!!!!!!80g0n0kAn2!!zztiiiIx!!!!!+3?t+!!!}7?cz2ez2wqSti+++!!!!!!!!!!!zti}+++}i!!!!!}zlzzzzzzzzv}11cv}!!!!!!!!z!zIIIIz2annxz!!!!!!!!!!!!!!!zI7s?}eea!!!!!!!!!!!!!++cyuanIxvln$$Ixni!!!!!+2nzj?+!!!!!!+x1ac!!!!!    //
//    !AxtOl!"\`,\_|>"!!"|^,,,^|"!!!!!!!!!!!!!!!!7l_     \};>>>>>+++>>>>!}+23zz2zz222n}"!+\ 'c!!!!!!!!!!!!!!!!!2c!z?!!!!!jn0$+SA+!!!!!!!!uA00qzvelza1+z2s++vst?7se3?czvlzj?j}+!1vv727ijlcl3zzlz!!!!!c2s!+t+!!!!!!zj!!+lt!+l1!!!sr!!1v!!!!!!!!+ssr+!i???}t?!!!!!!!!!!!!!!!i?ltzz++aIyt+!!!!!!!!!!llvv}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!sx"zz!!!!!    //
//    lG+$0!|`,>!"|~\',,,:^>!!!!!!!!!!!!!!!!!}1lvx+,      }|>>>>>+ !++++s^  se2zezazzev     \z!!!!!!!!!!+!!!!!!!!!!!!!!!uPzvn0C+!!!!!jlzzznnnaczsttzl?+!stjtt?vc2y7+i!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!2s+t!t+!!!!!!!++!!+ci!+ri!!!lz!!tt!!!!!!!!!!!!!!!!!!!!!|\!!!!!!!!!!!i+lj2"71vsai!+c!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!i!!!!!!!!!!su"2c!!!!!    //
//    Cg!Aa|`'"!_`,^_|>"!!!!!!!!!!!!!!!!!!+v+iy}+3+,      |+!"___'          `|>!>`>""">`^^\_}c!!!!!!!!!+1+!!!!!!!!!!}l+!jLSbz+!!!!!!!!!!!!!!!>____|>>"!"""!!!!!!!!!!!!!!!!!!!">>|__;_>!!!!!!!!!!!!!et+t!?+!!!!!!!!!!!!!!vIe+!!st!!!!!!!!!!!++!!!!!!!!!!!;~+e!_;!!!!!!!!?"sleellcz}__+j!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!cIx+!!!!!!!!!jx"zl!!!!!    //
//    p0!Pl`,"!_`\!!!!!!!!!!!!!!!!!!+ttt+}}>|>z+1av,                                  "tj??t!!!!!!!!!!!!!!!!!!!!!!!!}z}!!!!!!!!!!!!!!!!!!!>','\^\\\'''\'---:'''''''''''''''::\''\\^^\`^!!!!!!!!!!!!z3+?!+t!!!!!!!!!!!!!IBHHA!!++!!!t}!!iz!!y2!7zvi!!!!!!""!_|!!!!!!!!!!!!+?+!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!jzv1l?z7lllz?!!!!!+u!vx"!!!!    //
//    kS!O? _!"`,!!!!!!!!!!!!!!!!!lIC3|_||!!|~7!ic2vs+t?t}ttti+!!!>!!|`   |v+vi1zzzzzz2!!!!!!!!!!!+l3Od+!!ebUv!!vlnAa!!!!!!!!!!!!!!!!!!!"'`_!"_;;;__|>>"""""""""""""""""""""">>|__;;^`^!!!!!!!!!!!vz+!t}!?+!!!!!!!!!!!!cPWmx+l+!!!llzcvr}1l|!xl]2z!!!!!!!!!|>!!!!!!!!!!!!!!!!!!!!!!!!!!!sjj}!a2xt!!!!!!!!!!!!!!!tvvzel+}+!se1nC+!!!!"x7+I+!!!!    //
//    P]iG_`"!| ^!!!!!!!!!!!!!!!!!$Cay++++t^` ,?tsll7t222zzzzzllcxIcez7++j32i]22zjttt}+>|>||||||>>}nCi!tstIx;+"!8A02nalllllvjjjj}!!!!!!!|`^>^`'~~^^\\\''\\\':-,,,,,,,,,,,,:\':'\\^;__>!!!!!!!!!!!!z+!!!i}t+!!!!!!!!!!!!!!!!!+7+!!!ct}1t"^+s|>c!+zv!!!!!!!!!!!!!!!ivz}!!!!!!!!!!!!!!!!!!+x?rls2!lz!!!!!!!!!!!!!!!lzet+!zll!+zveC?!!!!!l2"xs!!!!    //
//    Pe2m`-!!\`>!!!!!!!!!!!!vv|_|"_,``` ```     ```  ,>_ `` ``  !Icc17vvc+!!tlv1?+_`          ,t+++ii+i}?tiiiit1crt?111111rjjsll!!!!!!!!|\'\>!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!le!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!zjxzca1}lvvsjell!!!!!!!!!!!!tvzzy72!!!!!!!!!!!!!!!!!!!e+!!srrl}!!!!!!!!!!!!+iln+1jz7?!2CSCss+!!!!!!?x"z2!!!!    //
//    Pl2O ~!!,`!!!}zl+}ii}+sI1                    -\\\^~\\\\\_;_??!!!!!!!!!!!!!!+z}>           7!!+!!!!!!!!!!!!!>;\'':,\"!!!!!!!!!!!!!!t??t!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!zz+!!!!!!!tcllttjj!!!!!!!!!!!!!cn0pq}iz+\vIt}w$wqnl!!!!!!!!cne21?23+!+2c!!!!!!!!!!!!!!!s2lzl!!!!!!!!!!!!!!!!!!!z!!!zxvue]zlluus!!!!!+I+sx"!!!    //
//    P72A |!"`'!!!+7i!!!!!!!1s!!!!!!!!+>-  '}++iits???t}+++++!!!!!!!!!!!!!!!!!!!!}lv+!_\\,````:t!!!!">>>|___|_^,,^|>!!|`^!!!!!!!+tt?1vzzl2al!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!+!!!!+!!!!!!!!!!zl!!!!!!vjee2x27sI!!!!+!!!!!!!!!+jjs+tll}lz?tsjjj+!!!!!!!!!2dlsae2e2z2cvri!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!svtieecc!++!!!!!!!!!!!Ij+u!!!!    //
//    O7ap`>!| ^!!!!!!!!!!!!!!!!!!!!!!!!!?+;?+!!!!!!!z1!!+}}}+!!!!}1c!!!!!!!!!!!!!!!!!+?ts?}+++t+!!>:,'''\\\\\\;>!>^':::\"!!!!!vvlvvvii+!1aSz!!!!!!!!!!+cvvlccllzllczlcllczlczzllz]zllclvvlvzCl!!z3!!!!!?v!cljz2nc?v!!tC?!ijt!!!!!!!!!!!++?j?++}tii+!!!!!!!!eC21i}zu2cvz2uC3t}i}!!!!!!!!!!!!!!+}t!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!ec!u+!!!    //
//    O7Id`!!; |!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!}i+++i+!!!!zl!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!|`\__^^^^^^\'','_!!!!+}+v7svr!!!!l+rlzl?t2sty?!!!!!!lvcl+"""""""""""""""""""""""!!""""e2zn]++3i!!!!!+lzvt?yl2xcilzzc!!!!!}7i?tv7vt7i+!!!!!!!!!!!lc!!!!!+tsvs}irt!!!!!!!isssj}!!!!!!!!!!!+?t+!ccs7?t111111stt1j+!!!!!!!!!tsc3sjjz!!!zz>nj!!!    //
//    O1Iw:!!\`>!!!!!!tvvs+!!!!!!!!!!!!!!!!vSCv!!+1+!+?++i}+!!!!!!nn!!!!!!!!!!!!!!!+++++++!!!!!!!!!!>;^~;______|>!!!!!+v7+!2llccvzzzIzl+}sr?+7z3+!!!!!!!!!tzv1llv!""""""""""""""z]lznalen8c31!!ze!!!!!szlx2!!zClza2vxn8z!!!!!!!!!!!!!!!+jc2+!!!!!!!+?t}tti}+}tttt}+?111111117s1cr?vzv}t1+!tv!``_!}+!!!!!!!!!!!!!!s1t!!!!!!ltirz1ezl21!le!ec!!!    //
//    O7nw\!!,`!!!!}zzc??szz?!!clclzj!!!!!!GHHP!!izt!?++t+!!!!!!}ca1!!!!!!!!!!!+}}}}++++}}}+!!!!!!!!!!!!!!!!!!!!!!!!!!v1tc7iitlztll+izllv?sc2vi!!!!+a1!!!!!!!!!!rzl1jv?lay?""}zlae2+tA0pUnx!!!!2l!!1yIalj21cvs0c!e2tunnnc!!!!!!!!!!!!!zlvlc!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!vq1v!|'\"!!!!!!!!!!!!!!!!!!!jc!!!!+ex2l+7CeeCz!1a"zz!!!    //
//    O7x0`,,`_!!!2z}tzzlzl+lzz?+l7+lei!!!!?nns!!!!!i}!?+!!!!!!zye22l!!!!!!!+}i}+!!++++++!+t+!!!!!!tzlj!!!!!!!!!!!!!!!!!!}c1j72t!!l]2uICnI1t!!!!i+!!+!!!!!!!!!!!!!!vxpAAUqe"+n}!!!nznA0g1n2!!!1z!!tIb8C3212eazcvcS?!rnInn+!!!!!!!!!!!!11+lv!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!c2l!!!!!!!+vz!>>!!!!!!!!!+sjvv1??!!!!!!sl!!ca]v?xezeznc!!sn"lz!!!    //
//    P72P">>!!!!!lzzl+!!!?zlvlzz?cej+x7!!!!!!!!!!!!j++?!!!!!}nelayl$+!!!!!+t+!!+i}}+++}}!!i}!!!!!jzl!zslazt!!!!!!!!!!!!tz++stcl"!svitiisi!+7+!!lv!!!!!!!!!!!!!!!!!!!2x+zzl"zC!!!!Czq8gny2!!}3s!!!!}svc1+!!!+tt??}!!!}i!!!!!!!!!!!!tvjsi!vzl1!!!!!!!!!!!!!!!!!!!!!!!!!!!!+11?s7ay?!!!!!!c7!\"!!!!!!!!7ct+++!!tl+!!!!!z}!+vsanxzczv!!!!jn"c2!!!    //
//    Pc2X!!!!!!!!!!!!!!!!!!+t}!!!!+llz+!!!!!!!!!ze+?!}t!!!!!lpzluezh?!!!!+t+!+i}+!!!!+i+!+t}!!!!!le2t3zz+!1!!!!!!+Iz!!!+v"^'\"+!!lv!!!?nc!+z?!!+t?s?jjt+!!!!!!!!!!!lI+vxz}!u2!?2lIaA0ha!!!!2y!!!!!!!!!!!!!!!!!!!!++!!!!!!!!!!!!!!szc!!ticnzvei!!!!!!!!!!!!!!!!!!!!!!!!!tzz1?cvzCxlv+!!!2!!\!!!!!!!!!c++!!!!!!+z!!!!!tl!!!!czxxecl!!!!7x"zz!!!    //
//    Pz2X!!!!!!!!i1t!!!!i7t!!!!!jvlc+!!!!!!!!!!!!"+?!ii!!!!!zCyzI3zh!!!!!+t+!}i+!!!!}t+!+i}!!!!!+c2c2+re!!l!!1l+!!++!!"^,:_|\`|!!!!!!!!!!+it++!!!|___|!+ir+!!!!!!!!in3}ln+"a!!cee!SggI!!!!!cx!!!+tt7zz+!!!!!!!!!!+!!!!!!!!!!!!!}cescezyeI0CabIci!!!!!!!!!!+I2!!!!!!!!!!}clCxunxeecc}!!!2!!'"!!!!!!!!z++!!!!!!!l!!!!!!z!!!!!!!!!!!!!!!2l!x?!!!    //
//    Pz2X!!!!!!icc+!!!!!!!!!!!!!!!!+!!!!1+!!!!!!!!!?++?+!!!!+xzzIeze!!!!!}t+!}i+++}i++!+t}!!!!++ls1ctc?t!jc!!sc!!!!!!_`'>!|\,->!!!!!!!}i+!|__|>!!!!!!!!"_>7r!!!!!!!!yIxe]""n!!!!I7AAS+!!!!!ll!!v3a223za!!+++!!+++!!!++!!!!!!!+ISnnaazczclc1cclc1!!!!!!!!!!zCq+!!!!!!!!!!!!srsj++!!!!!!!lt!\;!!!!!!!!l}+!!!!!!?c!!!!!!2!!!!!!!!!!!!!+ze!le+!!!    //
//    Pz2X!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!+ll+!!!!!!!+?++?+!!!!lzlI2at!!!!!+?+!++}+++!!+i}+!!!!+ccz!?i+l1ezcs!xj!!!!!!;`_!>-,_"!!!!!!}vc!|>"!!!!!!!!!+j?+!!"!s1!!!!!!!I0S0OGWDP000APG0+!!!!ie1!!!scz!s3n8?!!!!!!!!!++!!!!!!!!!!!i}!!!!!!!!!++!!!!!!!!!!!!!!!r21!!!!!!!!!!!!!!!!!!!!!!!!!jzl!"'|!!!!!!!c+}!!!!!tc!!!!!!!l?!!!!!!!!+}7zz1+z2+t}!!    //
//    Pl2&cs!!!!!">_|"!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!+?++?!!!!laauyS!!!!!!!+i}+++++}ii++!!!!!!vi2jtyav}C0]z!!t!!!!!!^`|!|`\"!!!!!!!jr|}z!!!!!!!!!il2axuac!!!!z!!!!!!!cg0Sna2ct++++++!!!!!!ll!!!7zly}envnv!!!!!!!!!!!!!!!!!!!!!!!!r0CCCCC8Snq0+!!!!!!!!!!!!!7uCz!!!!!!!!!!!!!!}i!!!!!!!1c}]}!"|!!!!!!!l+++!!+vr!!!!!!!!vs!!!!!!12lcs+szzt!!!!!!    //
//    P72G!!!|\--'^_^`_!!!!!!!!!!!!!!!!!!!!!!!!cz+!!!!+?++?+!!!jcnx1!!!!!!!!!!+++++!!!!!!!!!!tv!!++c3sz0Ayc!!!">|_\,'"!;`_!!!!!!!}tl+>!zl?i!!!+le3zzzzzzye!!!ctij!!!!!!!!!!!!!!!!!!!!!!!!!!2+!!c2e?r2axu2?!!!!!!!!!+?clvlt!!!!!!!lhSCCCCCCC$a!!!!!!!!!!!!!lnIuqs!!!!!!!!!!!!!??!!!!!!!1|+jzs!!_>!!!!!zl+++sj!!!!!!!!!!vs!!!!!!?zcllc}!!!!!!!!!    //
//    O13P!|,-_"!>_^-,|!!!!!+sj}!!!!!!!}j+!!!!!!}}!!!!!+t}i+!!!!l2ni!!!!!!!!!!!!!!!!!!!!!!!!+ejt+exizzj+22v!",-''\_>!|,,|!!!!!!!tt_!v|!zl"+v+ce2zzzzz2ayeucc?+>|>c!!!!!!!!!!!!!!!!!!!!!!!!?2+!!!!!!!!!!!!!!!!!!!!+lluz1sInl!!!!!!!}rsss1lz32i!!!!!!!!!!!!}Cny2wj!!!!!!!!!!!!!!!!!!!!!!1,!!v22}!!!!!!!?zs11+!!!!!!!!!!!vs!!!!!!!!!!!!!!!!|:>!!!    //
//    O1aA;`_!>\,:^_>!!!?1c2y3eyec?sc2eee]2cs!!!!!!!s!!!!!!!!!!!Ixav!!!!!!!!!!!!!!!!!!!!!!!!!t?jsszzzl!!aa1!>`_|__~',,_"!!!!!!+iyt}i!"!+j?}2n2zzzzzz2]}!!!!ltz!!_ttt+!!!!!!!!!!!!!!!!!!!!zl!!!!!!!!!!!!!!!!!!!!!!zcasz}l3et!!!!!!CAnnnnnnu3SO+!!!!!!!!!!!lCauuC+!!!!!!!+?+!!!!!!!!!!!!v`!!!t+zvl71v1crIv?+s?1?1s1t7scv2s!!!!!!!!!>,~!_\!!+}!!!    //
//    O7Ip`;!>`\"!!!!!slzz2ezzlzannuuCa]e2l2zl!!!!!!vz+!!!!!!!!!!">!!!!!!+}ttttttt+!!!!!!!!!!!!!!!v?!1s1i!!!!_\'\^_|"!!!!!!!!v++2""!!!!!!!!inzzzzzzzzyaav!!z7c!!|+_'_t!!!!!!0Ai!!!!!!!!!!a+!!!!!!!!!!!!!!!!!!!!zxvllzl]2IxUv!!!!!z0L8LLLSCCS2!!!!!!!!!!!!2Iannu+++itti1ls2+!!!!!!!!!!!v`!!!!!!tt}}!i}!2}tl7+vz??7li!++cz+__!si>+i!|"!++!!++!!!    //
//    G?Cw`"!',"!!!!!vlzzz2l22xx2lr+vn3e3zz2zl!!!!!!!++!!!!>`\!!!|\!!!!+vt+++iti++tjt+!!!!!!!!!!!!!!!!!!!!!!!!!+++!+}t?jji^:;s>!ei+!!!!!!!!!s71?1eyzzzznztjl1ai}+r`  1!!!!!!rl!!!!!!!!!!!zt!!!!!!!!!!!!!!                                                                                                                                         //
//                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PADEDO is ERC721Creator {
    constructor() ERC721Creator("MICRONS", "PADEDO") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x80d39537860Dc3677E9345706697bf4dF6527f72;
        Address.functionDelegateCall(
            0x80d39537860Dc3677E9345706697bf4dF6527f72,
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