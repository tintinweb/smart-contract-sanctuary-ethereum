// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 4 FISHES
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                //
//    s+"""""+++""""""2Ov"+++++++"[email protected]>>|||||||||||||||>>>>>>>>>>>>>>>>>>>||||||||||||||>>>>"""""""""""++++++++"""">>>""""""""""""""""""""+++++++++""""">>>+>>>>>>>>""">|||+nqq$$$$qqqq$qqqq$q$$qqqqq$$$$$$q$qqqqqqq$qqqqqqq$bCCCCCCCCCCCCCCCSCSSSwqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq$$$$$$$$qqqqqqqqqqqqqqqqqqqqqqq00000000000ppp0pp0000    //
//    v+>||>""""""">>>8P"""+++++"""kQb">>>>>>>>||||||||||||>>>|||||||||||||||||||||||||>""""""""""""""""""""""""""""""""""""++""""""""""""+++++""""""""""""ii>>>>>>>||||___"nqqd$$$$qqq$$q$$qq$$qqqq$$$$q$$$qq$q$qqqqqqqqqq$nnnnnnnnnnnnnnnnnnnnnnnSqqqqqqqqqq$qqqqqqqqqqqqqqqqqqqqqqqqqqqqqq$$qqqqqqqq$qqqqqqqqqqqqqqqqq000000p0000ppp0pp0p00    //
//    z+>||"+++"++++""gA""+++++++++PMa}i?7vcllllc1?i+++++""""""""">>|>>>"""""""""+++tsvlzzzzllcv17sj?tiii}}}iitt?s7vclzz2222zl1?i}++++++++++++++++i?vlzzzzzzyvr?i+++""">>||"n$q$$$$$qqqq$$$$$qqqqqqq$q$$$$$$$qqq$$qqqqqqq$qnaaaaxaaxaaaaaaaaaaaaaaaaC$qq$$qqqqqqqq$qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq$$qqqqqqqqqq000000pppp0pppppppp0    //
//    z+>>"+vllvvvcvvvGGllv77771vc8MG]aInCS88www8SCnxezzlvjt}++++++++++++}}it?s1lz3unC8w999w88SSCCCnnnIIufxxxxxxxuInnCbwdd$d98CnIae2zlllcvcclzz2eaInS8dd$d99kbSCnnfy2lv?}++tC$$$$$$qqq$$$$$$$$$$$$$$$$$$$qq$$$q$$$q$$$$q$$822z22222222222222222zz22zxqq$$$$$$$$$$$$$$q$qqqqq$qqqq$qqqqqqqqqqqqqqqqqqqqqqqqq$$qqqqqqqqqqqqd9q000000000ppppppppp    //
//    l+>>"[email protected]&pd$$$$q$$$$$$$$$d98SCnnua322zzzzzz222e3afInCS89$$$$$$$$$$$$$$$$$$$$$$dddddddd$$$$$$$$$$$$$$$$$9w8SSCCCCSS88w9$$$qqq$d9wwh9wd$q$d8SCnuxun9$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$Cllllllllllllllzllllzlzlllyqq$$$$$$$$$$$$q$$q$$q$$$$$$$$qqq$qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq$$qqq0000000000pppppp    //
//    c+>>"t][email protected][email protected]$$$$$$$$$$$$$$$$q$$$$$$$d9ww888wwww99d$$$$$$$q$q$$$$$$$$$$$$$$$$$$$$$$$$$$q$qq$qqqqqq$qqqqqqqqqqqq$dd9w888bbbSCCnIfayeeu5553axInbdq$$$$$$$$qqq000qq$$q$$qqqq$$$$$$$$$$$$$$$$$$$$$$$$$dzllllllllllllllllllllllllI$q$$$$$$$$$$$$$$$$$$$$qqqqqqqqqq$$$$$qq$qqqqqqqqq$$$$$qq$qqqqqqqqqqqqqqqqqqqqq00000pppppp    //
//    1">>"teC$qqq$PgqqC08++l8qqUPAqqq$$$$$$$$$$$$$$$$$$$$$$qq$$$qqq$qqq$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$q$q$qq$qqqq$98SCnnIuxay3e2222222zzzzllllll2Illllllllz2Ib$q$q0pFgAAgggAAAAggggUUFkhp0qq$$$$$$$$qq$$$$$$qq$qnllllllllllllllllllllllle9$q$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$qqqqqqqqqqqqqqqqqqqqq$q000pppp0    //
//    s">""teC$$qq$pPgqdI2z2nqqqqqPP0qqq$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$q$$$qqq$q$q$qq$dwbCnIxy2zzzzlllllllllllllllzzzz225ey]u$Ifxaaye2llzICC0UAAg0CnuxxfInCS$0pAAAAAAAPAAAAAgFh0qq$$$$$$$qq$qqnzllllllllllllllllllll39$q$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$qqqq$$qqqqqqqqqqqqqqqq0000000    //
//    t">""jaS$q$q$$qUAUqq$$qqqqq$0Amgqq$$q$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$qqq$qqqqd8SCnua2zzlllllllllllzz2222e3yaaxxuInnIIIIIIIn0nnIIIIIInaab9qgPA0naaxInnnnnnnnnnnwAAAAAAAAAAAAAAPPAghq$$$$$$$$$$qSylllllllllllllllll2n$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$qqq$$qqq$$$$q$$qqq$$$qqqqqqqqqqqqqqqqq000000    //
//    i">"+cnwqqqq$$$qqgPhq$$qCxu8q0Pmp$qqq$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$q$$qq$8SCIaezzlllllllllllz2e]axInIIuaye2zzzllccvv1111111CnvcllzaIInS9d0APhu]Innnnn$hUp9nnnnnn0AAAAAAAAAAAAAAAAAAA0qqq$$$$$$$$$Cxzlllllzlllzlzyn$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$q$$$$$$$$$$qqq$qqqqqqqqqqqqqqqqq000000    //
//    }>>"}2C$$$q$q$$qqq0Ag$qf+""inqAXA$qqqq$$$$$$$$$$$$$$$$$$$q$qqqq$$qqqqq$$q$$$qq$$$$$$qqq$q$q$dbCna2zllllllllllzz2e]auIIx]2zzc1s?tj7vcllzzz225e3y]aaa0uaye2z5InS9dqAApeInnnnnAWDDDDDWFnnnnSPAAAAAAAAAAAAAAAAAAA0q$$$$$$$$qq$q$CnuaeeeyxICdqq$qq$$$$$$$$$$$$$$$$q$q$$$$$$$$$qq$$$$$$$$$$$$$$$qqCev+""||_|>"}c3S$$qqqq$qq$qqqqqq$qq$qq00000q    //
//    +>|"}eS$$$$$$$$qqqqqP$qz""""2qAXgqq$qq$$$$$$$$$$$$$$$$$$$q$qqq$qq0pgAPGOmmmOOOOOOOOmXXXXOAdI3zllllllllz2yaxInIIxezlvst?7clz2yauIIIIInnIIIIIIIIIIIIn0IIIIIIIICd99UPZnnnnnnCmDDDDDDDDDPnnnnAAAAAAAAAAAAAAAAAAAAA0$$$$$$$$$$$$$q$$$$q$$$$q$$$$$q$$$$$$$$$$$$$$$$$$$q$$qq$$$$$$$$$$$$$$$$$$$qSv^ ~1n$hgAPAg0Is' '}xqq$$$$qq$q$q$$$qqqqq000qq    //
//    +|||+zC$$$q$qqqqq0AAhqqw3cv39hPm0qq$qq$$$$$$$$$$$$$$$$qqqqq0hAPGOGOOOGGPPPAAggUUUFUgAg0wIezlllllllz2aInIIIx[email protected]DDDDDDDDDGnnnnAAAAAAAAAAAAAAAAAAAAAg$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$q$$$Salt+>_;;_>"}veC$$$$$$$$$$$$$$x~`1PBHHHHHHHHHHHHRP2,`+C$$$$$q$$$$$$$$$$qqqqqqq    //
//    +|__>ta8$qqq$0AAgF0$qqqqqqq0gPOg$$q$qq$$$$$$$$$$$$$$q$qq0FPGOGPPPPAgUZhhhhhhhhhhhhh0Su5zlllllllzexIIIu3zcstj[email protected]DDDDDDDXwnnnnUAAAAAAAAAAAAAAAAAAAAA0$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$Is|`  ~+l]uIazj"` `"x$$8Iy22eaC$x,^[email protected]&&&@DBHHWi ^I$q$$$$$$$$$$$$$qqqqqqq    //
//    "|__|"1I8$$qAPhwnnCqqqqqqhAPOP0$$$$$$$$$$$$$$$$$$$$$$q0AmOPPPPAAUhphhhhhhhhhhhhhh0nyzlllllllz5xIII]zcjtvz2auIInInIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIw0nInIIIICd99ddd0FF0bnnnnSAOWWXGhnnnnnnkAAAAAAAAAAAAAAAAAAAAAkq$$$$$$$$$$$$$$$$$q$$$$$$$$$$$$$$$$$qn>` "[email protected]~`+",`;>>_``;''mHHHBDWmOGPPPGOOOmMHHQv 'I$qq$$$$$$$$$$$qqqqqqq    //
//    "|__|>+cI8$APq8zcclnqqq0APOP0qqq$$$$$$$$$$$$$$qqqqq$0PWWmOPPAkp0pphkUgAAghhhhhpqCazlllllll2aIII]z7trl2aIIIIIIIIIIIIIIIIIIIIIIIIInIIIIIIIIIIIIIIIIII0nInIIIIn8d9d99dd$0kZhp$CnnnnnnnnnnnnnhAAAAAAAAAAAAAAAAAAAAAAqq$$$$$$$$$$$$$$$$$$$$q$$$$$$q$$$$$Ct``[email protected]&`;uGDHHHHDPn8mHHR&mOPAgAAPPOOOOOOMHHRt |S$$$$$$$$$$$$$$qqqqqq    //
//    "|___|"[email protected]$nxxffufffffufIC90pAhdn3zlllllll2uIIu2vtsz3IIIIIIIIIIIIIIIIIIIIIIIIIIIInnIIIIIIIIIIIIIIIIII80IIInIIInC89d9d99ddddq0hhSnnnnnnnnnnnpAAAAAAAAAAAAAAAAAAAAAAg0$$$$$$$$$$$$$$$$$$$$$$$$$$$$qqq$z' [email protected]@&&@&&@[email protected]` l$$$$$$$$$$$$qqqqqqqq    //
//    "||__|>"?yS$AAp9CC9qqqhPm0q$qqqq$$$$$$$$$$$$$$qq$pOP0n27i++++?affufffffffufSnezlllllll2fIIuzrtv2uIIIIIIIIIIIIIIInnnIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII0IIIIIIIIInnnnCCCS9dddd9gUnnnnnnnnnnn0AAAAAAAAAAAAAAAAAAAAAAAAAUp0q$$$$$$$$$$$$$qq$$qq$$$$$$S+ `2DHB&[email protected]@[email protected]| }$$$$$$$$$$$$$qq$qq$q    //
//    "||___>"+zC$q0AAUqqqqqhPmgqqq$qq$$$$$$$$$$q$$$qqAGwfxv"""""""+]ffffffffufuu]zlllllllzxIII21tv5IIIIIIIIIIIIIIIn$UAPPAh8IIIIIIIIIIIIIIIIIIIIIIIIIIIInn0nInIIIIIIIIIIIInCwd$0pppSnnnnnnnnnnn9PAAAAAAAAAAAAAAAAAAAAAAAAAAAAgh0qq$$$$$$$$$$$$q$$$$$qS" `0HHQmPAPAAOmmOOPAPOOOPGMBXGPmPPAPWmmGOOGAAAUhAPOPPGOOOOAgFBHHH+ "$q$$$$$$$$$$$$qqqqqq    //
//    +|____>"+lnd$$qqkAZqqqqAPOA$$qqq$$$$$$$$$$qqqqqAAnxfa}""""""}zffffffffuff3zlllllllleIIIavtr2IIIIIIIIIIIIIIIIngPPAAUZFAhnIIIIIIIIIIIIIIIIIIIIIIIIIIII0IIIIIIIIIIInInC9d90p$CnnnnnnnnnnnnnnnpAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgpq$$$$$$$$$$$$$$$q$d}  qHHHmPPPhPXPAAAPOOGAPAPM&PPGmGPmWGgOpPOGFAFZAPAAAAAAAAAOPAPHHHR> +$$$$$$$$$$$$$$qqqqqq    //
//    +|___|>"}znd$qqq$$pA0qq0APOAqqq$$$$$$$$$$qq$$qAPSufffazllclzaffffffffuuuzlllllllllaIII2jtlfnIIIIIIIIIIIIIInnUPAAUhhhhhgACIIIIIIIIIIIIIIIIIIIIIIIIInn0nIIIIIIIIIIIIC99dqgCnnnnnnnnnnnnnnnnnn0AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAg0q$$$$$$$$$$$$$$q2` vBHHMPPPpAPPGOOGAgGOmUAM&POP&PXPWOAP0POOUP0gAAkPOOPghAOAgGhOHHHF  z$$$$$$$$$$$$$$qqqqqq    //
//    }|___|>[email protected]@Gg0CufffffffffffffunfzlllllllllxInIltjeIIIIIIIIIIIIIIIIIIqPAAUhhhhhhhUAnInIIIIIIIIIIIIIIIIIIIIIIn80IIIIIIIIIIIIInS9990pp0$CnnnnnnnnnnnnnnnnSq0phhkZFUAAAAAAAAAAAAAAAAAAAAAAAU0$$$$$$$$$$$$q$" `AHHH&AXphmWOOPAPOPhOP0GW&PPPWXmXXPgUGOOFPhpPgpOGg$}` `+0hAABHH&; "dq$$$$$$$$$$$$qqqqq$q    //
//    +|___|>+znd$q$$qq$q0P$qqq0PPO0qq$$$$$$$$$q$qApffnqAGW&Uffffffffffffu9ulllllllllzxIIna11eIIIIIIIIIIIIIIIIIII0PAPghhhhhhhhAhIIIIIIIIIIIIIIIIIIIIIIIII90IIIIIIIIIIIInnnnnCSw9$0hk9nnnnnnnnnnnnnnnnnnnnnnnnnCd0AAAAAAAAAAAAAAAAAAAAA0q$$$$$$$$$$q8^ ~WHHHXPACA&[email protected]@[email protected]&OAgGOOOGUGqGPAhOkA0+   ;nPgRHHQs -I$q$$$$$$$$$$$$qqqqqqq    //
//    "|____>?ab$qqqqqqqUPhq$$$qgPXgqq$$$$$$$$$qqkAgPgwIffuIufffffffffffuqulcllllllllaIIIIIIIIIIIIIIIIIIIIIIIIIInnAPAAAFhhhhhhZAnIIIIIIIIIIIIIIIIIIIIIIIIC0nIIIIIIIIIIIIIIIIIn89dd90ACnnnnnnnnnnnnnnnnnnnnIa22eaInwAAAAAAAAAAAAAAAAAAAA0$$$$$$$$$$q8^ ~&HHBXPAbPPv`  ,nhnAPA&[email protected]@D&OOOOAUgwPPAUPggPhasvSUPRHHRz `zq$$$$$$$$$$$$$$qqqqqq$    //
//    "|____>[email protected]&mpuffffffffffffIqalvlllllllleInIIIIIIIIIIIIIIIIIIIIIIIIIIInqAPAAAkhhhhhP$IIIIIIIIIIIIIIIIIIIIIIIIn0nInIIIIIIIIIIIIIInb99$phhdnnnnnnnnnnnnnnnnnnnnul11111czunhAAAAAAAAAAAAAAAAAAAq$$q$$$$$$$$+ `AHHH&AGn0W7    lCgGpXWOGP&DDMMDBHHMXOOAZPqAGgPAAhqbS$$AWBHHWi ,z$$$q$$$$$$$$$$$$qqqqqq$    //
//    ">|___>+zCdqq$0PZ8uaI$$$$$hPm0qqqq$q$$$$$qAwffffI80Sfffffffffffuu0al7llllllllzaIIIez2IIIIIIIIIIIIIIIIIIIIIIInIn9gPAAkhhhhApInIIIIIIIIIIIIIIIIIIIIIIIFCIIIIIIIIIIIIIIIInw99kZnnnnnnnnnnnnnnnnnnnnnnny11111117cnnhAAAAAAAAAAAAAAAAAApq$$$$$$$$qq3` 1BHHRPPUnkG9u228PPhO&mmXWWQHHHHHHHHBD&XgPP0pPAPPU$qqA&BHHBq' |u$q$$$$$0q$$$$$$$$qqqqqqq    //
//    ">|||||"sx8q$qPpSzvccn$$$qkPPqqqqqqqqq$qqUUPXPAh0nffufffffffffffqIl7vllllllllllzIIvtvfIIIIIIIIIIIIIIIIIIIIIIIIIInAAAghhhhUgInIIIIIIIIIIIIIIIIIIIIIIIPAIIIIIIIIIIIIIIIIInC8qhhqnnnnnnnnnnnnnnnnnnnnnn211111111InCAAAAAAAAAAAAAAAAAAgq$$$$$$$$$q$?  [email protected]$0pAAAAX&[email protected]@XmP000qqA&RHHHBP+ ,18$$q$$$$qA0$$$$$$$$qqqqq$$    //
//    ">||>>>"}2C$qpPqxcvccIq$$qAOkq$q$$$$$$$qqAnn0APmXgufuffffffffffS$lvslllllllllllzIIIfIIIIIIIIIIIIIIIIIIIInnIIIIInqPAAUhhhhhAIIIIIIIIIIIIIIIIIIIIIIIIIO&wIIIIIIIIIIIIIIIIInCdd$hknnnnnnnnnnnnnnnnnnnnnnazv111vznnn9AAAAAAAAAAAAAAAAAA0$$$$$$Cn$$$8i  [email protected]&&&@WWX&BBMHQRHQBHRBHHHHHHBRBHHHHHHHQZ} `+n$$$$$$$$pA0$$$$$$$$$q$qqqq$    //
//    ">|>"">"+znd$qP0xvccl8$$$kOPqq$q$$$$qq$qkAOPAAFnffffffffffffffIp2l?llllzlllzyInnCCnnIIIIIIIIIIIIIIIIIIIIIC0hkFgAPPAUhhhhhhPIIIIIIIIIIIIIIIIIIIIIIII0WWXCIIIIIIIIIIIIIIIC8999qZpnnnnnnnnnnnnnnnnnnnnnnnnIaaxInnnnnhAAAAAAAAAAAAAAAAApq$$$$S>'u$qq$z' \[email protected]&&@@HMHDRHDBHDRBBHBHHHHHHHHMA8I1' \tn$$$$$$$$$$qgU$$q$$$$$$qqqq$qq    //
//    ">|>>>>"}zC$q$hPqnxIbq$qhGP0q$qq$$$$qqqqAn0gAPPCfuffffffffffff0Clj7llllllzfSSbSSCCSSnIIIIIIIIIIIIIIIIIIIIFPPAAPAAgZhhhhhhhPIIIIIIIIIIIIIIIIIIIIIIIw&Ap&mnIIIIIIIIIIIIInwdd9h0Snnnnnnnnnnnnnnnnnnnnnnnnnnnnnx2xnnnSAAAAAAAAAAAAAAAAAk$$$$$$w8$$q$$$Sl_   [email protected]@[email protected]&BMHMHBMHQQBRHRBHBHHHHHH0+` \vaw$qq$$$$$$$$$qUA$$qq$$$$qqq$$qqq    //
//    ">||||>"sxb$qqqpPp$$$qqUOAq$$$qq$$$$q$qAG0wCCnuffuffffffffffffplctlllllllxbSSSnnnnnCSnII[email protected]PnnInIIIIIIIIIInS99hwnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn21lInnnhAAAAAAAAAAAAAAAAU$$$$$Cl8$$$$qqn+`[email protected]@&&@&&@[email protected] `u$q$$$$$$$$$$$$qZA0$q$$$$$q$$qqq$$    //
//    ">||_|"teC$$qqqqqAA00gPP0qqqqq$$$$$$qqhAhPOmXXkufffffffffffxf0xl?rllzllllnSSSnnnnnnnCbnIIIIIIIIIIIIIIIIIInbAPAAAhhhhhhhhhUP000000000$CnIIIIIIIIIInW0uphPMhIInIIIIIIIIIIIISd9qpCnnnnnnnnnnnnnnnnnnnnnnnnnnnnIl1ennnqPAAAAAAAAAAAAAAAgq$$$$d9$$$$qC+`'[email protected]@@&@[email protected]@@@@[email protected]\ 1$$$q$$$$$$$$$$$$0h$qq$$$$$$qqqqq$    //
//    +>|||>+znd$$$$$qq$pAPA0$$qq$$$$$$$$$qqPCfffffffffffffffffffuuZlltllllllllISSCnnnnnnnnCCIIIIIIIIIIIIIIICFAPPPAAAkhhhhZAAUp0$CnnnnnnnC80ppSInIIIIIICWCIphAMAIIIIIIIIIIIIIInwdddhCnnnnnnnnnnnnnnnnnnnnnnnnnnnnn51lInnSAAAAAAAAAAAAAAAAAq$$$$nCqq$$n_ "[email protected]&W&[email protected]@MQRA` z$$$$$$$$$$$$$$q$$q$$$$$$$$$qqqqq$    //
//    }">||"1Iwqq$$$$qqq$$q$$$qqq$$$$$$$$$qkguxfffffffffffffffffff9dl1tllllllll2bbCnnnnnnnnCCIIIIIIIIIIIIInIgAAAPAAUhhhUAgp$nnnnnIx32zlllzzyI8gZCIIIIIInWP3ChOM$IIInIIIIIIIIIIC9ddp9nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnf11ynnCAAAAAAAAAAAAAAAAA0$$$$$$$$$b> "&[email protected]@MRM&[email protected]&M1 |8q$$q$$$$$$$$$$qqggAF$$$$$q$q$$qq$    //
//    s"||>+2C$qq$$$$$qqq00q00qq$$$$$$$$$$qPbufxexfffffffffffffuffqel?slllllllllIbCnnnnnnn[email protected]WOWMPInIIIIIIIIIIIInS9d9pnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnv1znnngAAAAAAAAAAAAAAAA0$qq$$$$$$t '[email protected]&@RW&O&@Wdz+}t]naszgWBHHHHHHHMHDHDHHMHQHBMW&DBw `5qq$$$$$$$$$$$$$$qgUAh$$q$$q$qq$$$q    //
//    j"||"ru8$$$$$$$$$$$0gAA0qq$$$$$$$$q$0Auxxi"zfffffffffffffffn8llt1lllllllll2SCnnnnnnnnnCnIIIIIIIInn8pgAPPPAghFAFwnnnnnx2lvlz]unnnnnnnI5clIZAgnnIInIISAGGhnnIIInIIIIIIIIInS9d9pnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnl1lInnFAAAAAAAAAAAAAAAA0$q$$$$$$a` [email protected]&WDMWOX&X2"}ii+"++zBHHHHHHBBHBRBQHDBHBRHHRDMHHF` v$$$$$$$$$$$$$qq$$$$$$$qq$$$qqqqq$$q    //
//    t>||"ln$$$$$$$$q$$qqq0qqq$q$$$$$qq$qAhffz"sxfufffffffffffufbnllivllzlllllllnSnnnnnnnnnCnIIIIIIIInhPPAAAAAUZAg8nnnnnIzvlexnnnnnnnnnnnnnIIn0APSInIIIIIIIIIIIInIIIIIIIIIIIn89d9kCnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnz1vfnnpAAAAAAAAAAAAAAAA0$q$$$$$$" "[email protected]_~~~~;_"""fAPZayOHDDMBHHHHHHHM&&&&DHh,`r$$$$$$$$$$$$$$qAPUhhhhhAPq$q$$qq$q$$    //
//    }>_|"lC$$$$$$$$$$$$qqgg0qq$$$$$qqqqqPCff?"zffufffffffffffuugullclzlllllllllnCnnnnnnnnnCnIIIIIIInkPAAAUhhhUAqnnnnnnnnfxnnnnnnnnnnnnnnnnnnnqAPdIIIIIIIIIIIIIIIIIIIIIIIIIIIS9d9ZCnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnz11ann0PAAAAAAAAAAAAAAA0$$$$$$$f` [email protected]~~~~~~~~~~_>"""">[email protected]``l$qq$$$$$$$$$$$$$$0FFFFFUg0$$$q$qq$$$$    //
//    }>_|"cn$$$$$$$$$q$$$pgkPq$q$$$$$qqqqAffa++yfffffffffffffffnAyll7tclllllllleSnnnnnnnnnnCIIIIIIII0PAAAkhhhgASnnu2llz]nnnnnnnnnnnnnnnnnnnnnn$AP$nIIIIIIIIIIIIIIIIIIIIIIIIIIC9d9ZCnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn2173nn9PAAAAAAAAAAAAAAA0$$$$$$q7 `[email protected]@&&P"~~~~~~~~~;;~~~;>[email protected]&&@DBBC \y$q$$$q$$q$$$$$$$$q$$$$$$$$$$$$$$qq$$$$    //
//    i>|_>sIw$$q$$$$$q$$$0ggpqqq$$$$$qq$Zgff2+iffffffffffffffffwAxll+"jlllllllyCCnnnnnnnnnnnIIIIIIIwPPPAUhhhgACnnev1111lnnnnnnnnnnnnnnnnnnnnnnqAPdIIIIIIIIIIIIIIIIIIIIIIIIIIICdd9ZCnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn5115nnCAAAAAAAAAAAAAAAA0$q$$$$q" [email protected]&W0;~~~~~~~~~~~~~~>[email protected] _$0000phhhhkkkZkhhp00q$$$$$$qqq$$$qqqqq$q    //
//    t"|_>}5C$$q$$$$$$$q$qqq$$$q$$$$q$q$Ppffl"sffffffffffffffffqg0ylllllllll2nSnnnnnnnnnnnnnIIIIIIIgPAAAhhhhPwnn3v11111znnnnnnnnnnnnnnnnnnnnnn$AP9IIIIIIIIIIIIIIIIIIIIIIIIIInC9ddhCnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnne112nnngAAAAAAAAAAAAAAA0$qq$$q$_ [email protected]@XS~~~~~~~~~~~~~~;_+z0PPPRHHHBX0MBBHHWz\`znnnnIuuuuIInnCb8$q00phZh0q$$$$$qqqqqqq$    //
//    }"|||"vu8$$$$$$qqqqq000pqqq$$$$$$qqPCfxs"lfffffffffffffffu0g9qCxe52eaICCnnnnnnnnnnnnnnnIIIIIICPPAAZhhhUknnnz11111zInnnnnnnnnnnnnnnnnnnnnnqAP8nIIIIIIIIInIIIIInIIIIInCSw0AGPAA8nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn]11znnnhAAAAAAAAAAAAAAAq$qq$qq8\ [email protected]@&Xd~~~~~~~~~~~~_i]C8UA}|"[email protected]@2>}OMBHHHB} cnzclllzzzzllv1rannaeannC$hZ0$$$$qqqq$q$    //
//    +">||"t2Cd$$$$$qqqqqAUUAqqq$$$$qqqqAuf3+"2fffffffffffffffIpg$CSCCCCCnnnnnnnnnnnnnnnnnnnIIIIIISPAPAhhhhA0nnnev11v2nnnnnnnnnnnnnnnnnnnnnnnn0APSIIIIIIInnnCCCnn8pFgAPPOXXXXXXXWO$nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnna17znnn0PAAAAAAAAAAAAAgq$$$$qqd; [email protected]@&WP>|++}}>~~~_yAq]2el+~_~|vPC;+tUPXBHBn _unnnnnnnnnnnnnnInxvt?t1zInn$g0$$$qqqqqq$    //
//    +>>||"+lI8$$$$$qq$qqAggA0q$$$$$$qqpAffz""afffffffffffffffIhU$CCSnnnnnnnnnnnnnnnnnnnnnnnIIIIIIbPAAghhhhUUnnnna22xnnnnnnnnnnnnnnnnnnnnnnnnn0APnaaxfufuxaye2zllCXXW&@@@MMMMMMDDWqnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnuv1lInndPAAAAAAAAAAAAAgq$$$$qqq> [email protected]@@@IC9S90p2~~;+>~~|clxC}~;}P2>+vWmXBWt :annnnnnnnnnnnnnnnnctt??ttcnnn0U$$q$q$$qq$    //
//    +>>||>"jeC$$$$$qq$$qAhkAh$$$$$$$q$AUff2++xffffffffffffffunFUdCCCSnnnnnnnnnnnnnnnnnnnnnnIIIIII8PAPUhhhhhP8nnnn[email protected]qnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnl1vxnnCAAAAAAAAAAAAAAUq$$$$$$$i [email protected]@h;;~~~~~~_|~~~"8WCz"~~~"Ac"[email protected]"  }nnnnnnnnnnnnnnnnnnvt??tt??ennCA0qqqq$$q$$    //
//    +>>|>>"}zn9$$$$$qqq$q$qqq$q$$$$$q$P$fffxxufffffffffffffffwgkSCCCCCnnnnnnnnnnnnnnnnnnnnIIIIInI9PAAUhhhhhUAqnnn[email protected]0nnnnnnnnnnnnnnnnnnnnn                                                                                                                                         //
//                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PADEDO is ERC721Creator {
    constructor() ERC721Creator("4 FISHES", "PADEDO") {}
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