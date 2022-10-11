// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: padedonism 3.0
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                //
//    nxnSUPZdqAOPAgppAhgAPggGGgAP0Zh0SC8Cclllz2222e3eeyaaaaaaaaaauuuISSnnnnCnC$CS8bSSSSTb8T888SCCSSCCCCnnnC8TCnIu222zzzzzz22zz2522e5eeeyyyaa333eenT5y222vsrs1vv1?}ttsi+}i7t}?r?tj}?}itistttt?}}t?i}}}}}}}}}iiii}iiiiizi++++i?sss?ttitttczzttttztiit?stiiis7rcz2cst1zclzcvlcsrccc1clz52z5xe2zzi+++++++++++7zezvv1?tti}}+}}+++}}+ii}ijclclc1t+>    //
//    IuaCnSnnxnS0AAPAAqSnCbnqgSnwpq0$h0$Snnx3axx3eauxauIIIuuIInnnCCnn$qSSCS8880SSbSCCSqq$TwwwwbbCCCCCnCCCCCCCCIIIa2z2z2zzlllllzzlzzzzzzzCezaCzzxxxuz2zlcs?s7cccccsr?si}itst}rsstsistj1vvcvvv1?t?siiiiiiiitttjsrss71rszqnt7es71vv17c5v7c8pSxl1lCIvzn$8Calzz2CTp0CzxIAA8Inlcz52z2eayz2axu3z??1l1?tt???tttslaezzv?j7rssnAz?t??tt?s71r1clzzlct+++    //
//    I3xn2vanIaznhgggTa2zcccv"""?z33nnCCxzxnvcclllzeee5e3ya]xuuInnnnn$dnnnCCCnwnnnnnnCTSSCCSCSCCnuuuuxxnnnnnyee5a2axa32e2llcvcvxmdllc11v2vv1l7sv?lzsncvvvvv1vvcccvcj7i+it7?tr7stsivzl2az2zz5cj?jsttttjs1vvvccclzzzzcc2U8ss7ezvvv1171vaC$0ApnxnSICan00qd0Swbg0wCnnqw$qUG0xCn23a]anIayl?tjce51"?rrrrr7r+|++zy2c_t~}lcvlz1rr7ssrvvczzzye2zlti7++    //
//    CIII8a2uCnnC$0TIIuIu5zlz}+anezynxz2Caz?}iit2aIInxye53y]axunIuxxxbbuunnnuISIIuuIIIIIInnnnInxyzzlccl2xIIyzzzz2]n8Cx2]nxlcvvcyPCzzlcrszrrrlrrc7z2vyvccclccvccccll7s?tjs7ssr1s??jvllz2zzzlll7t???srvclzzzzlccc2e2zzz32enzv2zvvv11171vex]zc7zqnnxCnu00$Cun$0$p00T8u5z]nzl3aaxnCnt+zvcye]]yzllv7777777}_tc"+l""2~rllcvss1ccc1cc2uIux2zcvv+?i"}    //
//    Cd8CCnzvzeIbTI3llebnaazc]C22nx23xzcIziti?2333nzlCee55yxxaIIuuuun00CCCnCCCqCCCnnCCSCnnCCnIx3eee2zzzexnIxxaaannna5eyIq0Czvvcc3lllllrr2lvrlssc122vacccccvvvcccllc1sssr1ssr77sjtj7v1s7771vcvvvrczlclllllcccclllzzclllctt?}lelvvvenc1r77zl777zaz2zaCSdxlcz2laC5nalz2u]2]IuInnIzlzz2yazllcvvc11r7777771s"|?j""l+>lclllll2zz5z23Innx2lc1ss+"i+>    //
//    bCSnz+"">^^"zuelzI21uIn3z]a]a]2zzznn5e22avzuCa|+n2ey5euIunIuuIIC00CCCCSCCqCCCCCT8CnIxIInx223a]ae23aunnnnnnnCwn5aCn8h0wIcvvl5lcvccrrz1lzzrrc122vacvvvvvvvvvvccv11771vv1s?si}+}trtt?s71vccl225zzzzccccvvvcclccclll?\srsv|t2cv12av7r111771llzc7715nezl3zzlav2alezyxynnn8wCIzanu2e2z225xanCellzlvjczljlv""++}+zlzcz2]eezzzltccz22zcvsj?t+"""    //
//    x]2zs}+++>_|_\\_>|>+"eua5zclcv7+`|a7lzCevnSuyvzxexuIx3uIIIIIInnC00CCCCCCn$CCCCbTbnnuxxxxIae25222zzz2xnCnnnnSTCn8hUp0$Izvvcv5cvvlvr1yzzyxlzzv227xzzzzccvvvvvcvr?ttttt+">~\'~\'+s??sssrr1vv23a2zzzlvvvvvvvccccclzzzi+t+jz+]nnnAPqIx2ccc222]sjsl1v3zlcczlcllnz5uenyInnCdnuanI2c?_"claCl2v52_"+e+"'lc|}lvcczezz2z5nSuu]ezc+ca3zzlcv7s?i++>>"    //
//    z?s??tt+}}jclc"^^\,'+7nnzs?s1st}^'iz5znvjczyaelvlannIxaxxuInnnbSp0CCbCCCC$nCCnnnnIxae]xxnnae2zlzz2e22a]yauxxzen$0$I2zvvvvvv5ccv1vczIxuz2lzzle2s2vczzzzllcjr1s7s}++">""++"_^'-}}}}}}}[email protected]@RBHHHHHHHBD&mg8]t}clCzllccllInv7czcIeeezuandn5nCazjj2zr?+j+^}>___^^"|"~__\ic1vccccclzenn2zIz2z12zlcvrs??t}+++>>"    //
//    z]zs1lzlzz2222zi""~'_vz++++}t+++"""|~^>czzlsivz2ennayyCnaxIInnCSp0SS8CSSS0CSbnnCCCnIxaxnSCnIua]y]yy]aaa22z32?+t1r17vclzzzz2IaI3czz2x]2lz1vlv3avz??r11vz2zcccr}++}++irvvv}|^'|+""""[email protected]&P82ce7tttt?1v???t?lzzsvcz]n]TU$2t}nxazarc2Ie2In2za8Ia25Izcsrs17711vluuzlcezclrvvs71cv?i++""""_"    //
//    caxCCInI]zlvr}}++}+t1"}|___>>_^^^~^`   \}it]3cttluI1i7Cx5auIIInC00nCCnnnndnnnnnnnnnIxxxInnCCCnIIxxuaa]5zlzzzv?v]xez23eeauazIz$Uxaxeaczaa17l12572sssstt??+"iclvs?i}tsllc7i>~'+}~|""""""+}tvvjitsr717jti}iveC$$GMBHHHHHHHHHHHHHHHHHHHHHHHHHHHDkxsiiijt}+}vv1v1itttt?rlz0mOz+?azz1z2aC0wwCIlclz22zzlc1sss}}t}j112l?ttzcss??j1171cs}++"""">"    //
//    cnAUqnnnesi}ti}++?cIA$C}^\\'`    ,_~\'^>">"x222zII+_ca7z]aInnnnC00CSSCSSS0b8CnInnCnnnnnCSSnIxe]aaInnxyzlzcvlccz25zz2zlzzzzz3czxxxy2]vzllssl12ztz}}}+}i}++++}tiittircc?+">~:-z2i>+?tit?jvl2zc1ssvcv?t}+?2nbqPDHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHRP2s}^|_\\?jssczjjtsvc11c22s}i}strcen$nC0Znnbncl0Tnczlv2ezct}izzeci+izccc17czzc1rcssst+++++    //
//    Cph00Tnu27i+++++la0mmWBBO1_\`    ,_|>">||,-\"+"23""axsc5aunnunnCp0CSbCSSC0CCnIIInnInnnnSdq$8uax]xInxazz1?+itjs1vzzzzczll2Spg0pCyunxn2}+c}}7illt2sii?sst}t++++"""""""|>>">_,+xzz++ti}}[email protected]&mPPmmWMBHHHHHHHHHHHHDg+"77\\isssjvzzzv1vzz2ezttittttvzzzaCq0$T0ucvqIqvcze2e]xIccIaIlttszcllclzzc11cvvv1vc17?i    //
//    bhhpqnnCCx1tiir3p0n"\:vOHM+~\```,\^~_""|"___""lI++c2zz2auxnCdInC00CCSC8TTpdTSCnnnnnCCCCS8bdqC22eaxxu222l"""][email protected]&RPgA&pc5n2azctr}slszzt2sssssss}+">>""""+++"""""_|~3acct>}sjs1lzlzynn3z1++++tCkdgQHHHHHHHHHHRWpxzjt+_^_>"}a0mQHHHHHHHHHHHP+^\\\+vc1sssssi?tjccls+ccztttczz5uS8C0p$uz1xd0ae52znnnCn]2zzc11v2lccllcvccccccvtscv17r    //
//    S0U0undwTS2cvi?zSke~\'+0HB}`,,,-'~~^\___>+"||"ta2zllz2xnSIanwaax$qInSSq$wp8CIuuuuIS8$T888$00C23aaxy2lczc"_|[email protected]?sljzl}zt?jsssss?+""""+++++||"++"+"uzclc"+clz22zzzzaaezi"""+ahUABHHHHHHHHHMAar>~\'-,'~|^,`,\"3PMBHHHHHHHHH&z\\~_>+?t}+""""+tssc7izla5zzaInuxaaT8x2lvjyTqna5z1eq8xIxz1vccvll1vvll1vcvvlcvvvvs?vvr    //
//    0p0CInw$$S2lvv}"cSAGAhXBRn,````>np$+'\^_"}i+++++i?tv2yxbCInwnuIu$qInCCdTTp8bCnnunT$qq$$qqq$Cyzzaxx3c?tl?+>"ts1}}?nAAhpZ83cv2rl5zvv12vsict?ctzl}ziitttssst+++++"">"++}ii+}""7v7vr+"}clexez5222zs""""zpggBHHHHHHHHROe+~''\^^\:,-'~||_\,'|zPMHHHHHHHHHDu}sijznpgOW&@[email protected]@WOPPAAApwCana]ynCnx$3uxaezICn5cclrtvrvzzllz17r1sti+++}}}t1v1    //
//    q$qTwnunCazzzeul+cSPmGOPv\`````+0Zn_`,-^+|"+++++"+jclz8nanTnIuuubdInnnCCSpSCCCnxn8dwT8CCCnnae2exIxyj"}?">|++r+}itlayzz]nCezz}lzcz0r2ctil??ctzztzttttttttt+++++|""i+""""++"||izzc7""tvleaaeeIu2t++++CApDHHHHHHHHMwa|,'\`,,-''\^~||_~^\,`'"[email protected]}tt++it+"""""|_>}vcc1si}}i}}+"""++++++    //
//    nS8nuuInIzlz55]l+velznu2Cnl1i}+"+>\:```'+__|_||>"7lllzxnnCIuIInnqqInnnCnSpb8bCCInCq$$qw8CnnIIInnCCucsc}+"}7sl1vzzaylvc55uai1+js+rI+1"tc2ssls25r2tttttt??i}}}++>_+">>>>"">""|"ce2zz++1lexe22zcv1?sszgAPHHHHHHHHDP7"`,'`:^~^^^\\\\^^"~,,``,[email protected]+>__^'~|""+++"|"+cvs?t+t??i}t?t}++">|||||    //
//    5nCnnSIazccleanztcuIIeuzc33s"|||"~\'``,:++>_~_||>+1zzz2225e3axnnqqnnIunnn0CCCnnnSbbb8w$TCInnIIIInnnx22v+"?tczccczIlizpztca7c"?i"+v"r"i7ztsls25r5s7c1jjlSzvs}+"~->__>>>""|_>""+ze5zs"iz2lvclz7tjtsj2PGQHHHHHHHBPklt ,``\\^^^_\\^',_+_ ````\+cWHHHHHHHHHHHHHHHHHHHHHHHHHHHHHBA0ntizpDHHHHHHHBMWPw"^,,\_|>"+++szxbqpdwIcj7vv77st}+"">||____    //
//    2anC$0I2u33CCn2j2nn]znnlticls}++~`:'`,,-"~"+++>|"+tc2ee22yaaxunnqqxaxunnC0nCCCTw88CCSbCnaIInnCCCnCCCIxc">tlazzc7tnpPmXwlxP5c>}i"+7>vl1tc}}v}zziztrc7}}t2+++"""^\"^_>">>"""+i+>+1jjr+"tsit}?c2zvs?+zPXHHHHHHHHW0$av`^\^|"tt}++"+}"">_^\\_|>|"nHHHHHHHHHHHHHHHHHHHHHHHHHHHHMe"">"|',|GHHHHHHHHB&mG0y}_>>"}rzChUAAh8IC8Suz1tt}+"""""|____~^    //
//    xInCnSn3v}+ivlxS2eIIT2xs7?+zc>_~"pOXe---",-^~>+i+""+?vze2lxqqqI2nnz2xn8CC0CCCbw8SCnIuxxIICnnIn$$ww$Tnzi">sln]xac}[email protected]?lvc++?+lziz}+"__|>c""_^~|'_~^\^|"+++++ii+"s2lcc?+?s7?titcvi+>[email protected]+t7r1aBHHHHHHHHHHHHHHHHHHHHHHHHHHH]\"_~^'--,}BHHHHHBP?"ckW&Pz2I0gggUh00p0n5zct+"++"""">"""">""">>    //
//    xnnnn5exaelvaaInCSnzxl2cver2]+}"_XBBC~,,>,:':^>"">>>>+?cll2C$balunz2]nwnn0bCnSSSCSCIuuInnnnnnCb8Tw$Calt+"s+eiv2ztlv2z][email protected]>______v""|~__,>_>>_"+}+""+t}+">i]auIjic1t+++++">>"wRHHHHHHHHmTpCbTq00qqqp$T8T$0w0ZCS00Cj"+c0BHHHHHHHHHHHHHHHHHHHHHHHHHHHC">|`,''\^zBHHHH&a'`^"vuZXOPAgh00q8Iy2zc}+""++++"""""""""++++++    //
//    n0Cnb3zz22e22I8SaI$uu1z?+i+""^\:_WBBn___"-:\\>>>>>>>>"+?vczeSx2cunzzzxnnn0dTCnnCnnCnnnnCx5z5l22ayuzzzzt}+c"l>"+}"7>isct+5xz0APACn00m&XAPPmXOmU2l_|_~~|>v">|_|_'>_>"+}+}+"""""""|\"vzzl>t?+""+++"||>[email protected][email protected]~_',''[email protected]?35zz2IbunCCnnIcrs?r1t""}t}++++++}}}?711??r+    //
//    Cp00qC2vcvjstv23xIIeyxn1r}"">|\,_WBBC~\^t_^|_>"""""""""+?lzv>}11aa11leaaxTIuxxuuInnIIuxxxelzrsl2ze1vvls++s"1>""}>1">[email protected]@[email protected]]s>_>"v|"|_|||+">>"+">|_______||^"+++>\""""+++"|>|_sMHHHHHHHH&[email protected]28mBHHHWxi+jvljs11c7vllvccs?j?7jtjrst+t?jsvz21ivclzzzzzc}    //
//    C0UAAknt"+}}+++"+jzclCpnzzl1i+__"WBBC_}"""+"_>"+++"""""+j1v+ >11ax11c2aaabunnCCnuuIIIIxa2zlzvtcllls}}c+""+it?++++"r"~vi"c2lI>"}"}z+v+2$PmMM0$$nh0gPgC2tc">">|\|_||_|"||>"">>>">|>~\>"""\_">>"++"""|~_SBHHHHHHHHHHHHHHHHMGg0wq0q0gPX&@[email protected]@&WBHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHD0s""""11rrvirzlllc1vsj1ttttt?s1s?7c7l2evtllllz22vs+    //
//    C0pAAgCz+"""++_"sv2cacj+++++++^:_WBBn^"' ^>"""z8qTv""+}t71c+ >11ax?}}l222bIIInnnIInnnnIueezcvivslsv++?j+">+}+i>||>_+"+}"rCl3sv+>j2"j+"|t++z2TgpUnunqgAPAnz+|_'|~~~_>""""""">>|___|^~"""_,>_~||>"|__^^[email protected]P&@@@MBHHHHHHBm2>>ts>>"_^\++?sjscvvcv7tttttj7111r7s1zxz7zzl1l5x2i++    //
//    aCwhg0Izi++"|+vveCpCyeycvt+"|\,,_WBBb|+' >+|"+2bwSv"+tttr1l} "11x5""+1lllnaxxuxaaxInxexna2zvv?+1i?1i"+7+}"'tt++|>""_"c+|zu3l\"+|+s_l+>_}>"+|7ccpPmGg0CCAPDR&P$xc"_||>>"""">||>_~|>>\_">_:,,,,:~|_^^^^^_nRHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHRmhuzz3x]ay2a0nzln0AmRHDq}+">""|'\|~:>++}}tj?7rrst?tt?1svcc1?1z2c125c1zx3zlt+"    //
//    nCCd0Cn3?"_|+5CIbnnczzIx5e2ci>~-_WBB8"?' >+"+"+szq2}t?ss71c+ "r1az""+vcccI2aax3e3]uneennxzlv"+_++}+r""}c}+_"+j+}""++"}c++uva>++~"t~i|"+t~|+>11|s|}x0PGPAPR&[email protected]+"">>>>|_^___\:\^^'`,:''\^^^^^^^^~z&HHHHHHHHmCPRHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHBX055z22zzcvrc1tzIzji+11aUCv?+>>"|,__,^>"++s1crrvcc17v7svrtrcvsvzz?c3z1c2xljl32}}    //
//    nqd$$8C2t++tcnATnCqxIeycv?t++"_|+&BB8>}\ "+>++++CBA}tc77rjt+ "ttzl""+vv1vIe]ay25exnn323a2ucs>_"_++}+1j}i1t+">"7}it"+"vi}z2ea"}}~"t~i|""+^_+"cv>s____|"[email protected]>>>_^~_~^',,,,``-,,:\^^^^^^^^^+WHHHHHDn|^\"eUWHHHHHHHHHHHHHHHHHHHHHHHHHHHHHRZzv11v17jt+"|',``^t+"+j+22+_|__^^:|_,|"""+tvi7l1rs7cll17s17s?t1zzrzelszae712ev++i    //
//    q088nunxj">i2xnnSSqxe3nnCCx1+|^>+&BRS>t\ "[email protected]}}" "+zAA8++17ssx232e2yxxIuxe5zzzztt">t"+t+7sc+}sc?}">"liti"t+>+l"c_}i_"?^s}~~}_|i"1s~i\\\\~^_t|>""tznqgPmQG0q0PDBMkl|\_|\'',`,',`,`,-\^^^^^^^^\:[email protected]'\\:'^>XHHHHHHHHHHHHHHHHHHHHHHHHHHHHHWqdTbn27_,```````'>+"+">~v+|,,\^_~\_++"""s"}srcrcllllccc7j?}}z]11521vaxvjzyc+++}+    //
//    8000q$CCc+>tzzezleqnb]3z3aes"_,,>lzv}>s>'+}"""+}1ul7XBhlq0v+ ""bHH&t+17ssuz5ee]xxaaxxuazzlcl+}+>i++r}j?c+"+7?+""|i1}+vt|"+}l^++~"t^}>+"j">}"j}-+,-''''\}___~~~_||>+z?~]CzCpOMBWbs^':,,````````,:'\\\^^^^\,I+`sev3+'\,'~_|gHHHHHHHHHHHHHHHHHHHHHHHHHHHHHRXUp0n2v+""_'`,```,^"t"""+|^',:'^>"+++++++"+i1ccczzzzzlzc7}}zascezslu5rc5z}""++}"    //
//    b$TCCTnI2v?lczelr2nzzCnxczl}"|^\_"}+"+++s"_|++"++zt?XBhzMRe" ">[email protected]+v1rcnzzz3xa3e35ynCa2vssr"+}"+}"}++tcs++}vs++""}i1i|+s?v^+}^"?_i~|}c|_+~++,+,v"''''+\^^^^^^^____+"I]\'--++zCh82",,```,````,,--:'\\\'-,1nzIh0h}'\_"""[email protected]]cs+">^\^'-,``,'>>^\____||>>"+ii+''"++++++7cvcccz2z221t2ajzev7eul1za1+++++"+"    //
//    nnnbqquc?s2yyan2zaSz2I$S2zv"~""""+?}++++7"_>"++""1}rXBgzMRz> ">[email protected]?+v1v2Czzz5e2zclvlz2zcssj+?+"t""+>>+"tjc">+s7vi++|+"_+v}v|i+\"?^}>+"}'-"\}}'},|^''''+\"0}\\y+''\\>'"",,,,>,-,,-_"^'`,,,`````,,,-,,-,-\[email protected]"[email protected]+">_~\\^^'''```,_^\^">__|^^^\>+++^^|>""">|"}tt?svllzs?3er227lxevcez}""++++""|    //
//    c3Cd0$]1+ccv1cIaxudxbqnyzli+_|"+}tc}icz1zs}t87+t+"++28lcMRl> >|[email protected]?+v1vzSy2zee2zlvvvcvs?jii">+1"+"^"+~+"+i?}>_"jsi?i1"\+l+c+1ltvv\1+^\+\|ciz?\l\>_':''+''}~\\+\,,,,|,"",,,,"--,,,,,,-,,,,````,,,,,,,,,\[email protected]`''^>',,CHHHHBGq0AqZcnxgxz"^'\_:\',``````,`,-\\'''\^|+"|+++++++++++""+sv1cccc?1azr5zr2xl1zes+""""""++"_    //
//    c3II2lrvclv+"ra2z2qCn5xzl+"+++|>+}cea+"',,,}Ca"+}+"+}z"tMRc| >_THHMi"sttvn]2zlzzc7ssrcs}++}"|_|"j"|+__+~""++i1i"_~>|"i>\"stj+1zlel\?}1tl++zlI1^y^"_'|Ae",,+',,+',,,,|,""``,,",,,,-'''',`,,`````````,,,,[email protected]"lpxxuu1tPDxzpz+mHHHHd\`^~^|_\,"MHHHHPTSAPA5C8hhsv\,\_'_\-,```````,-:,,,-\|_^\,^|>++++++++++++j7vlvilxcvazv]5vl]1"">>>>>||""__    //
//    exCn]l+t?s?}?czlICdc1jzj""++"+++++l8_,,,,,,2caj+++">>s~}MRv| |^8HHM+|t++?aclllccvl25a2v?+++"|\^~^++^">\>>_""++"svt++|>_-"v"v+}c2az+2lzzyit2lnIvC_"_',\""``"-`,+\,^,,>,"",,,,+:,'':'\-,``,,```````````,,vWi"i0CClz}[email protected]}rnnPHHHHA+++"~\_\'zBHHHHPnpUwpa8CAO2">^,:```````````,,````,``````,^>++""""""""++++}??tzxrlacv3ll]2+|_____""_>"___    //
//    InInxu2zzvs}i1xzzlus+"j}"">+""++st2urv1v",,2+1x"">__"7_+MR1_ |\bHHM+_}++ie}tjrj?7l22yl?c?++"||~\^'\""~"|\"""|++}i""++"~->i1s+}lxue2n3x2at?2zn8x$~"~:,'">``",``+\"p|,>,"",```",,,,---,:,`',````````````,:Tgt}[email protected]+?1vlIRHHHBAv+"_,\\yMHHHHXwuAOGp00CpOAe""\``````````````````````,,,,:\^^_"">>>"""">"""t52jze7zec5Iv">>|||>">"|_>~~_    //
//    xnIIxC2i7vcsjnn?|+c"}|l+~~"}i++}}is+"++3?,|a++x}__~~~|~}MR1_ |\bHHM+~}""+2i}}ii+icllzlr?++++|\^^-,,,^""_|>~^"||__|>_,|^,>t"z+}zIu3lzc2yncv3zn8ub~"_','"">"+,``+'`>'`>`"",,,,"```````````````````````````,v0p0exdAPAc"tcjzlzkBHHHHRP0C$AMHHHHHWww5IppTd0I0UAq+zl+\````,````` ``````'``````,-:'_|""""++">>""?az1az12zcun+|||||>>""""|_>_~_    //
//    2aa]ana""}}++"v7lzu+++yt\|^_"_>+"+?c">?a,,lc++yz\\\\_\\+MR1~ _'SHHM+\+"""z++++++tlc1cvjlz+++|\''\',,',,|_~^~~"\'~^'',|^,|+"z?t?v23ae3unq32xznTIn~"_-`'"+""s,``"-`|,`|`">````"``````````````````````````````+lcnInz+t"r1vzz2cImBHHHHHHHHHHHBQm$n$ewPSnxxCnUC8c>\,```  `,````````,``_,````,\~~__||""">+"||"lxv2e1z2v2uc5xC]>|>>>>>"||>^^^|    //
//    lezz2e2s"+""""1-:iC?"\cj"\>|\_>_+"sj+"a",-a+++x+''\:\\\+MRv~ _,SHHD+\+"""z}+ii}}icvr1v1lej+">^\':-\\',,,,\__~|>\~~\,,|~,|j"rv1vzaIS0hUgpaeuzC8In'>^,`,>>""1,``",`_,`>`">````>``````````````````````````````+t~s|py|?++}?sc7clv2$PWBHHHBBMXmPGgz5uIPAApzxZSng$+^,```````````,`,+^'\>\`` ```,'^~>"}"|>>>_zTquuzrzcc]zl2200c\\''\^^\\^|^^^_    //
//    tvc]n5ls||>~\>1',"e"s+5+~"_^_'||~"i}"+5,,^a+++u^'\\'\\\+MBv_ ~,SHHD+\+"++ztis?tt}1tts7cll++"_\\_'',,--',,,``,^"_|~-,,|^,|ct1zzzz2yn8ZUk0aan2CCau-|'``,>>|+t```",`|,`>`>>````>`````` ```````````````````````,+"y\">>+i""++ccvccllzzzx0mPAwqpGSl1zeCqhXm2a$wx$C+j"+~\',``,``-',`,`,',,\""">|~\'>"">^>>"+}Ienhp0Izeec2z1lc|\\\\\\''''_^\^~_    //
//    ?3Iljccv"_\``^i'->z,\|nA+'_,'_\^+e?t}?",,>a++i3\\\\\\\\+MBc_ ~,SHHD+\+>>>zlvs?t?ii}isvvt+"""_:,'\:-,,``,,,,,,`~,,,,,,|~,:_|"?zenCCSdh02l"+q8x222,>\``,>""++```>,`|,`>`>|` ` >        `` ```````` ````````` ``,dl",'~}||"+l2z1rv1ti2nUpnxn5yAc}sz22ewSn0gpAp0hz?">7j^\\'-,```````,``'~\|"+trvvvzcvt+++?ac2ycel5Ilz2s1s>^\':,,,`,,:|>>>"""    //
//    zxe1z3zc}"\`,_s`-"2\\+y+,,,,,',,2",,,,,,,c3++2z\'\^\':\+MBc|-":bHHD+'+||_2z1s1}+ii}}rvi"""""|'-,``,,,,```,-''`_^-,,,,>"|"+""tclIbTwq08"__}Cny2eazz"\,-|">"?```|``_,`>`>|````"``         ```````` ``` `      ``nWOpl^+|>|"}[email protected]&hwz?+2v"">|\,``````````,``````,,:\\\\_"ve1elczr2zv2c7l"``````     `,\^^^^~~    //
//    zInez2zc+\``,^s,`_z"s|l"````,,`,x}z12lliznl++x|'-''''-^+MBc_i_,bHHD+'+|__2l?}}++++t}tlz"""""_-,````````-,,,,,`^_,`,``>jtl2ea2llzeIxxnwnnnCnI32x8nuzzzc+>>"?```_``_``>`>|   `"`````  ``` ``````  ```````````````"0n>|+"|""}"++cSAUUSIx3zcvila"2l}lzz2aeAXA&WmGTAAC}ln3vi}^````^ti``,```````````````1Cz12cls1z1zl7zt\`````` `````'>+?vvr?+    //
//    aCC]xI2?|^-,\|s,,"Tv"_c>````````t2c2+v\++?ccs5---,,,,,:+MR?`>``CHHD"-+___ci+++"""+tsla2|__|_\``````  ` `,,-'\-^_,,,,,,\~|>"?j1lllz2eaa1172nx2z5Innct?}~""+}```_``_``>`>>````"````````````````````````````````````'\zn++>t++50PA$wgIay2visj"si"xu}}rzzlmA8AA00p8hZ""">+"|t?__1CCnz]uvtcv2i5?ltc+rswp]zzcSC2vvl1ls~,`\^^~>+"^>>__+i7lzccvs    //
//    3CCeuIzi"|~~\_"'sgb+}|z",````````+n+v~+jc"v+qc'-,,,,,,,"MRi`|``CHHQ"`"^\\1"""">"+"_"?j>\^^~^:`````````````,-\~~>\\\\\\\'\\^"iczzzzz23]vccyuvv1stvcc2zzzIzcnayezt7z}+1+vs"|_'"````````````````````````````````````'``]0uuC8A0Cx]i>8gxz?}t+cc}z]zCI+"[email protected]+^\\'^>v5x1',\+|,-"clev?cs    //
//    yCnunu1svi__\"az7vC++_z+\,```````,t3c72szlt+r+',,------"MR}`\``CHHQ","~\~c>""">|||~~~|_\^^^^:`````````````,''\'>^^^^^^~^^^^~+cczuInnCn5eanuccv11zz3b2zaSzzqCndxzInl2lveccj?+>`````````` ```````````                                                                                                                                         //
//                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PADEDO is ERC721Creator {
    constructor() ERC721Creator("padedonism 3.0", "PADEDO") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x03F18a996cD7cB84303054a409F9a6a345C816ff;
        Address.functionDelegateCall(
            0x03F18a996cD7cB84303054a409F9a6a345C816ff,
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