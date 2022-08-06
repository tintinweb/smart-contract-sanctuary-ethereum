// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: enne
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                    //
//                                                                                                                                                                                                    //
//    ttttt1ttttttttttttttttttf11111111;1i1:111i;;:i1:iiGGGGGGGCGCCCCLGGGCCCCCCCfftfffLfGGCGfCCCGt1iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii11ttffffffttttttfGCCGLff111ttiGLL    //
//    t1ttt1tttt1tttttttttttttf:1111i1111iLGi111111111,1LGGGGGGGGG8CCGLGCCGCL8CCffffLffGLCCGGGCCtt1iiiiii11iiiiiiiiiii;iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii;;;ifC8CCCCGGLLLffffttttt111111111GGGG    //
//    11ttttttttttttttttttttttt;;;111111L:ffLCt11111111tLiffttftfff1f;ffLftfftCCLLfffffCGCGCGfCtt11111iiiiiiiiiiiiiiiiifittffff;;tfffffttt1:if1ffLLLLt1iiii1111fLGGGGGGGGGGLGLLLLffffffttttttLGGGL    //
//    tttt11tttt1tttttttttttttt11111ii11i:Git;i11111111tCfttttttfLtCff;ffffttfffffftftftttt1tffft1i111i11111111i11i1i1CG:fffftff1tfLLf1iffffifLfffLfff1fifffLfLLGGCCCCCGGGGGGGGGGLLLLLfLfffftLLLLL    //
//    tttttttt1tttttttttttttttfi11i1ii111i1i11111i11111tCfifttttfGtf1Gf1fffftCffffffffff1tifffffffffLtttttfffftLfffffftifftfffff1ffLLfffffffifLfffffftLLLLffffLLLGCCCCCCCCCCCCCCCCCGGGGGLLLLLLGLLG    //
//    1tttttttttt1ttttttt1ttttf1i:11ii1111GL1t1111111i1t8LttittttfLGiffttLfff8ffttffffffLffiffffffiLLftffffffftftLfffffffftffffLfCfLttfffffffff1fffftfGifftfffffLCCCCCCCCCCCCCCCCCCCCGGGGGGLLLLLLG    //
//    tt1tttttttttttttt1tt1t1tfiii1i1i11f1L1Cf,1i.1:;;:;0fffttttfttfLfL1tfLfLCf1fttftfffLLGG1LfffffffttffffftfGGfftffffff,;ffffLf1CLfiLLfLfft1tifLfffffLffLt1fffLGCCCCCCCCCCCCCCCCCCCCCGGGGGGGLLLG    //
//    tttttttt1t11ttt1ttttttt1t11ii111ii11G1ii1.111, 1:,8tttttttttftttffffLffGfff1Lfffffftfff1ffffffLtffffffffL1LLftffffftfffffffLCLLLffffffttLffLffffffifLfftfffLCC8CCC8CCCCCCCCCCCCGCCGGGGGGGGLL    //
//    1t11tttttttttt11tttttttti,, iiii11:,C.;1;1:1i,.:,18tftffttttfCGfffffftffftffffffftffffff1ffffffGti,tfffffGftffiffffftftfffLLtGLCfffff1LtGffiffLLLLGfLCtffft18C8C8CCCCCC8CCC8C8CC8CCCCGCt1fLL    //
//    tt1ttt1ttttt11tttt1ttttt1i:1i11i1LC ,,CL;1:1i..;i:81ttitttttGtLtf1iff;;iLfff1tfttftLfffffffffftCffffffffff1fffftfffftffffffLCGCGftf11;f;LLf1ffffffCff11ffffftCGGGGGGGGGGGGGGGGGGGGGGGC1GLLLL    //
//    tt1tttttttttttttttttttt11,:i11LG,. CG,,.LGi1i;1..10fttfttttitfGtfLtiLt;,GfftiffttftGLfftfffft:fGfff;fffftLffffffffft;tfffftff8fttttiG,1iLLftffffffLfffLi,t1L,GGGCGGGGGGGGGGGGGGGGGGGGGLLLLLL    //
//    ttttttttttttftttttfttttt1.:1fi.. :L .,Cf .;G11;i1:0tfi:ftftf1;i,tf1f1t,1CtfttttffLtLttL1:tLif;tLfftLfffffLL1LtifLf:f;ttfff;ff;tLt11i1iiG,LLfffffftt,i:;tf;fitCGGGGGGGGGGGGGGGGGGGGGGGGGLLLLL    //
//    tttttfffffffffLfffffffffiGG ,....;::G.G:..,. CL1i.8ttt;ttfffCG.G;:tttt:t8ffttffff1fttfff11fff;,Gff1ffffGffG1LGi1fL;;1ffffffL81C8ttt;f:,1iffLfLffLC8,GtLftiiffLGGGGLffLLLLLLLLLLLLLGGGGGLLLLL    //
//    tttttfffffLLLLLLLLLLLLff;1;1G,..  G.G:f ....CG111;8tt1ittfCi.,...G:ffftf8fftftfffft;t,t,tiL::t:,tfffffft;f8,GffLf,t,:ttttfCC:t.,:8Cffi1L1LLtLfLCf,,Ci,tGf;Lft;GGGffffLLLLLLLLLLLLGGGGGGLLLLL    //
//    tttttffffLLLLLLLLLLLLLLL;,1.i1L; .. .  . fG11111118ft:tL8..,:C,1  GGffff8tff1ffftfCi.Lfftt1;L.,:Gtifffffff8ifLLf;;f:,ft1CL,,,G.1,,,:8Cff;;LfGC.,:,8.:1t,.CGLfLLfftffffLLLLLLLLLLGGGGGGLGLLLL    //
//    1ttttfffffLLLLLLLLLLLLLL111ii11iGL.... CL1111111118LfGt.,.t:, 81i0f:,fGLCff;,ttfL,,8f..GGfiff1:,8ffftfff8t,,88;:fL;.1fCG...G.,L ,.;,,.18C:LG::,,,:1iCiG.,,.:CLffffffffLLLLLLLLLLLGGGGGGLLLLL    //
//    tttttfffLLLLLLLLLLLLLLfL1111,i1i1iLCfL1111111111118LfCG....,C 8.1:,,, GLGff:fLG .:fG,.t..:Cftff;CffttfC:,,CG.,;Cfi:;fCCi,..,.8:;CL,:,,CCLifffGG ,,.8ttG,,,.1CLLfftfffLfLGLLLLLLLGGLGGGGGLLLL    //
//    tttttfffLLLLLLLLLLGLLLLf111i.i111111111111111111118LfftLG;if1;88...:8CtfLt1LC ,,::, C..:G...8GftGfftC.,::L..;G;  8GfttftC8.tft:1tti.CCtffffffttGGf.,,,,,,LCLffLfffffffffGLLLLLLLLLLLLGGGLLLL    //
//    tttttfffLLLLLLLLLLLLLLffi11iii1111tGLL1111111111118ftttt1tGL.....,,CfftfLftGL.,,,,G C,Cf...,.GCftGC.,,,.,.;C:G....,:Cft:tffCL.,.  8Ctfffffiffff1ffLC;.,CGLffffLfffffffffGLLLLLLLLLLGGGGGGLLL    //
//    tttttffffLLLLLLLLLLLLLL:11i111,fLL....LG1.111111110Lfttt1ftfGC..GCffffftfLffiGC:,i1iG8;fC.1GCffffL8C..,,.0:C:L...,fGfftfttfffCGiCCftffffff1LffffiffffGGffffffffLffffffLfLLLLfLLLLLLLGGGGLLLL    //
//    tttttfffLLLLLLLLLLLLLLL11i1iiGG.G Cf  . LCf1,111118LttttftttttCCtftfftftfGf1ttitCL......LGGftttfffttLGC.....,...LGLffLft;ffffftfttffttfffftLftffffff1,G;iftffffLfLLfffffLGLLLLLLLLLGGGGGLLLL    //
//    tttttfffLLLLLLLLLLLLLLLtii:L1..,fLCL:G ... CG1,i110Gtttftttt1,tf.;tffftttCfttf1fftLC,.GGLffffffffCfffifGCt.,,.CGfffffLttf:1ttff8CGtttfffff1fftff,fffCf.:Ctf1iffffLLLLffffGLLffLLLLLGGGGGGLLL    //
//    1ttttfffLLLLLLLLLLLLLLL1GL.....1GfGGCG C.... GC.118t;t1t:ttfGC ,C8ftt:fttCfftttifftttCftfffffftffCfffffttfCC8Gfffffffftttft,LCC., GCf:itttfffLiffiGf...,,.Ct1fiiLfLLfffffLLLLfLLLLLLGGGGLGLL    //
//    ttttffffLLLLLLLLLLLLLLL.i,iL, .,G.C G 18.  iCf.1;10i1ff11LG;,..,,,GtL1ft,8ttftttttt:,L..1fttftfftCffff;tffttttffffffffitft1GCf CG ..GGCttff;L1ffCt..Gf:,C. .CGtfG;LLLLfffLLLLfLLLLLLLGGLGGLL    //
//    ttttfffLLLLLLLLLLLLLLLL ,:.,.CfL  Cit iCGCC1,1iii;8t1t1G0.,:LC; C:t:CCfftCt11fL,ftfG1,;Cfft1tttffLfffttt.ffC8GffttftffLftCC .GLGC,C.,.,,8G.fLfCL,,,,C.CiG.G.,.1LiffLLffLLfLLLLfLLLLLGGGGGGGL    //
//    tttffffLLLLLLLLLLLLLLLfii  ;ii;GG ..   GL1i1:i1ti10LfL1:...,Lfi C L,,,.GLCift1tffG:.,.,..GCf1t,ftffffiLtiCi...,Ct,ti.tfCG ..,iGGC:G,C,..,;CG;CGC,,..f,C.8LC ..,iCGfLfLLfffLLLLfLLLLLLGGGGGLL    //
//    1ttfffLLLLLLLLLLLLLLLLfi:. ;, t;1LC tfi111111111:iCL1CG,,.,;GL;iGL:,,:LGfff1tfiG.,C:C,,G  .CGt1t;1f;tffCiG.G:   L8Ct1fti8C; ..C G.G,G...8Gf1;L:t;LG.C.LCLLCG:iGLtG;fLLLfLfLLLLffLLLLLGLLGGLL    //
//    ttttfffLLLLLLLLLLLLLLLL;,.i;i11,111ti1111111111.110i..fiGt.C GGGCLGi.Gtf1GftGC .,,f1C iGiC,,.fC1..ffGG.,,88Cf;8  ..iGLf,1,.GC: :C:.,tfCCt.fftLiL1.iCGi.....1GGff1ffLLLLLfLLLLLffLLLLLLLLLGLL    //
//    ttttfffLLLLLLLLLLLLLLLt :1ii111iiiiLtii11111i111110L1if1,1CL  ..,..GGft1tLLfL:...,t1C LLGt...,;CLtCG....,fGC8CC:G...,.Ci.:it;fC1 ,..88ttt1ftt1t;f1:.t1CC.;CGffffffLLLLLLLffLLLLffLLLLLGGGGGG    //
//    tttffffLfLLLLLLLLLLLLLfi1i1111i1LG;. GGiii1111i111Ct;,ftf:ttCC.,.8GttftttLG,.tCG.,G.G;G;LLG LGG:f1C1GG..,ifLiGiiG:,.fGif.,f:;;f1C8LCfttfttffL,fLft1i:itffGfttfffffL1GLLLLffLLLLLfLLLGLLLLGGL    //
//    tttfffLLLLLLLLLLLLLLLft111i111GC ,.,...GGi1111111181ftt1,ttt;tGGCftttftttfLtf,ttLC., ..., LGftt;ttG.L,C8 t,iLC .8GfGLtit;:,t1tittt1ttttttttLt,1LffffttttLGfttftffffLLLLLLfffLLLLfLLLLLLLGGGL    //
//    tttffLLLLLLLLLLLLLLLLL11111tGi. G .C...Ct;Gt1111118L:fttttttttttftttfLtttfGt;.;f.:LG:.. GLttttttffL.1,.fLGf... .GCLttttfiftttttffGCCLtftffftfiGfftfttffG:,iGffttfftLfLLLLLffLLLLffLLLLLLGGGG    //
//    tttffLLLLLLLLLLLLLLLLL11iCG ...,G:tG1:tC....GLt1110LtttttttttGCiG1tttLtttt8f,1ttfttitCGGftttttttft;,,f;..t;GG fGGftttttfiftttffGG1.,,CC1tttfftiLffttfL;,,,,..CLtfftffGLLLLffLLLLffLLLLLLGLGG    //
//    tttffffLLLLLLLLLLLLLLL1:f;,....GGLfGt:fG,...1Lf1it8Ltttttt1GC....GGttLttttCf,1tttttttttttttttttttitff;f;1ttftLGfttttfftffttftGGf.,: .  fCGttf1:ffffGi,,L:fC;;C1fGttfLLLLLLfffLLLLfLLLLLLLLLG    //
//    ttffffLLLLLLLLLLLLLLLL1:..tG:.. f GCLLGGi GGi111118Lftt1tGG.Gi.GG..fLGfttt8ftttttfttLGCLtftfftttfttftttffftttLCffftttttffttLCL. Gt8G:.... 8CLtiCfLL,,,.GGiGL,G:,.,CfftGGLLLffLLGLffLLLLLGGGG    //
//    ttffffLLLLLLLLLLLLLLLG1;11.11Gt G ...:: CL11i111118LttfLi,,;G;L;  .. ;GGtt8fftttttfGt,..1CLfttttfttGfffftftGC .CCtftftffftCL....CGCt,C1G  ,.i8GGGG:,,.;LL C1,Li... CCLLLLLLfffLLGLfLLLLLGGGG    //
//    ttffLLLLLLLLLLLLLLLLLL;1i1;1i;;LL ..,,Gf1111i;i1118GLL,,.. :GtGC.G8, , .CG8tfttftCi:,.1 .,.CGttttttCttfftG8.,,..,;CLfftff,CG  .,8G.f18 G ..CGt1,ftfGC..,G.G,,Gf, CGtfLLLLLLLfffGGLffLLLLLGLL    //
//    tfffLLLLLLLLLLLLLLLLLG.111ii 1i iGG1L11.i1111111118Lt1G8 .,1G: C CC,.:tGffCtftLG;..8G8C.,,...CGftttGfftGC.,G  G   C.CGtft;ttLL1..G.L,18C,fCfttt,tfttffCL ....  GGttttffLGLLLfffLGLLfLLLLLGLG    //
//    tffffLLLLLLLLLLLLLLLfL tii1i.111;:i11111,,.ii1..118LtftfGC..G;:;,fG ,CLtttGtLC;,,, CGGCi8.G....CGttLtGG... G1GCGLGC,, CGtf1:tt.8G,..,.,;CGtfttt1fLfttt;tGC ..GLf1fftttfLGLLLLffLLLLfLLLLLLLL    //
//    fffLfLLLLLLLLLLLLLLLLt:i1i;i:i1.i1LC11111,tiiii;1t8LftfittLG: ..,,.CGfttttftLC1,.,;GC.8;8 C.,..fCLtLGL...,,CCGCCLLGL,.,,C1t1.fit.GCG.,f1ttttttt1i1ft,::it;fLLfttt;;:ttffGGGLLLLfLGLffLLLGLLG    //
//    tfLfLLLLLLLLLLLLLLLLLt1:ii.1i .;LG .tffi1;;ii. 1;;8L,t1ttfftLCf,.8Lt1tffttft.ftGC ,,C G .;C  LGffttf1LGC.,:;8,C1LCCC,.CCtf;ttt,11titGGttt,i;ttt,:ftttf;,1i1t,ttttt:t:fffLGLLLfffLGGffLLLLLLL    //
//    fffLLLLLLLLLLLLLLLLLL11ii1i,itLi .....:LG...;,i1i1CGfii:1t;1t;fGCtttf;f;tttf1tt:fGC..,... .GGftttttt:tt,GCG C....C: CGtttt;fLf11f,t:fGttf1,1:f1fififtttt11fGtLt, 1:1:fiLfGLLLLffLLGLffLLLLLL    //
//    tffLfLLLLLLLLLLLLLLLL1ii1  GG ,,,.:., iG CC:i.:ii:8L11ttt,;ttitt:1ttftitf1tGtfttt:tLC1.,.CGttttttttt1tf1,ftGC ,,, GGttttttt11.1,LL1GL.CGttfft,f.tfLfiti1fGt,.. Cft1t..fLfLLLLLfffLGLffLLLLLL    //
//    fffLLLLLLLLLLLLLLLLLL1iiiGC ..  .t    tC.. GG1i1,18L1it1fttf:fGLGC .f1.,,itCittff:tffiGGLfttti:tttt;11tffffttGCtCLttt:tttftitftftGG;..,.iCC..f.:fifftf LG .,  . i;Gftt1f1GGLLLfffLGLffLLLLLL    //
//    ffffLLLLLLLLLLLLLLLLf1tGL.... ,...ft1LGC..,.,GC11:8Ltt;f11tLG1....fCttt1,1fC,ftttttf:1t:tttt1ftf1tf;f,tffttfftf;ttttft1tttft1:1fGf, f,:;;GfCG:t.t;fftLC.,11i;:,GfG..GG :LtLLLLLfffLGLftLLLGL    //
//    fffLLLLLLLLLLLLLLLLLG11i1Lt...G,G;LLLfLL..1Lf1i1118Lfttt.LG;.:. ... CGffttf0fLt1,tf,i1LGG.iitttt1ft:L:tt1ft.Lf;LLitLtttt1:fttfGL..,...tLG1G,.,GCftGGG ..,,.ttLLL1G...,;GGLGGLLLfffLGGfffGLLL    //
//    ffLLLLLLLLLLLLLLLLLLL1i1.11GG GiG;..:GLGLG,iii11118Gtt1fL.,LLLL   GC,,tGC i0tfft1,ttLG ..fGLtf;..ffi1ttftift1CC .iGt,;,. LftGG .,.,ifGG.GiL . ,.G8fCGG.,.iG;LtfCiC:...CGtLLGLLLLffLLGfffLLLG    //
//    ffLLLLLLLLLLLLLLLLLLLi11iiii;GG   ..  LG..iiii11itCLtGL...,   iff1fC,,,:.GC8ttt..fCC ,..,,,.GGtt.ttiitti;;tGG .....,fLt1,,ff1LG ..,L,GftLtG,. GLLt:fftGL: L;G...,CG.GL1ttffLGLLLLfLGGLffLLLL    //
//    ffLLLLLLLLLLLLLLLLLLfii111iiii.GG . CL,i1iiiiiiiit8GfGC....GGCGfCiLG:,:,GLt8ttftCC.  .;....8L CGt.ft:1tttLG.;,. ,::.G GLt,1L1ifCC..L;L  ;1GGLGGtft:GffttfLL ...., GL1ttttffGLLLLfffLGGfffLLL    //
//    ffLLLLLLLLLLLLLLLLfL111i:.:i1,1;iCGGii.;;iiiiiii1f8LfttGG,.Cf1LLG..G:.CCtttGffLC ..;it8....LG...CG.1tftLC;,,  i:..  G . CC;1i1tttLGf,,,.. ;GL,ttttfG11ittttLL, .iLLift1tttfLGGGLCCC88GLffLLG    //
//    fLLLLLLLLLLLLLLLLLLLt111iiiiii,;1;.iiii1i1.iiiii1f8LtttttCGG:. ....CfCfftttLLG.,..,.. .:8,CtG....;GLfGG1..,,:,, C;G1G:...,LCtt1t1ftiCC;..CC11ftttti;tffttttt1LGGGtttt1t;ttft00008CC888LffLLL    //
//    fLLLLLLLLLLLLLLLLLLL1111iiii1i;i:GLLiiiiiiii1iiiiL0CfttttttLLL....:GLt1tt1ttftGG1. :C.C.G.L1G..:GGtttGLGC ,.tL,GfGGGCf.,iGLtftt,ttititGGGtt:.,ftttt:tfftttttt,ttttttttttttfL800008CC88GLftLL    //
//    fLLLLLLLLLLLLLLLLLLL1111iiii1i;Lf...GLt1iiii1ii1;18GttttttttttLCtGGttt,:t11tLtttfL8,C.G ...GG,GGittttLtttCGtiCGG...GGG:GCtttf1ttttttitt;tt1t111iittiCtftttttftGLLfttttttttt1t00088CG88CLffLL    //
//    fLLLLLLLLLLLLLLLLLLL111111iiLL;...... LLt11iiiiiiL8Lttttttttf:;tL1tttfLt1t1fGttttttGG...,.,.GGtfttttfLtttttLLL.,..,..LCittttG1tttttt,ttGGGG1tt1tt1tf;fftttttLG:..,GGttttttttf00088CCC88GLLfL    //
//    LLLLLLLLLLLLLLLLLLLL1111iiGG    .;ftG:  iLfiiiiiif8Lttttttt11ttLGttt1tft1t1tLtt;ittttGG1..LL1itfi1tttf;;itttttLG ,.8Lt:11fttfttttttt1LL .. GG11ttttt;tLttttGf......:GGftttttL800088CC88CLffL    //
//    LLLLLLLLLLLLLLLLLLLG111iGG . .  f .:G.G1..,LLii11f011ttttttt1LG1.GGttLtttt1tCtttttttttttGLittttff:tttfttttttttttGLLitttti1;tfttt111Gf,.. ,:.:CGfttfttLfttLG... ;. f....GLtttLt00088CCC8CLfff    //
//    LLLLLLLLLLLLLLLLLLLL1iGL ... :11f  ;G  . ...1ff1it0L1ttttttLL;....,LLGtttttt8ftttttttt,1tftttttttttttfLtttttttt,fttttttttttttf1ttLL;  . , ;G . iGGtttttGL...,:fC;iLtLL...fGLtf00088CCG88Cfff    //
//    LLLLLLLLLLLLLLLLLLLG11tLL .  G1.GfG. LL ,.1G1ii1,f8Ltt1t1LG; 1C,  tG,CL1tttt8fttttttt11LLLLtttttttttffCtttttttfffGLGtttttttttf1tLL.  .,LL;iG1ti.,.GGL:G;,....   i,CLf,...,:LGGC00088CC88CLff    //
//    LLLLLLLLLLLLLLLLLLLt1111;LC. G,,GfL..Lf tLiii1: 1L8L111LG:.t1fL1 GL. ,;GGt1t8ttttttttfGi.. ff1111t1ttf8ftttttttLG ..GGtttttttLGL ....  ..t L.G  ..:LL1LLG;.. L L,G..;G.. CGtttt80008CCC8CGff    //
//    LLLLLLLLLLLLLLLLLLL11111i1;GC . .  .  tLiiiiiiii1L8LtGG,..... ;  GL .....CGf8ttttttfLL  .... GLt1tttff8ttttttLG. ,. . GG1ttttG1tLG .,iG G;L,.G;. GL11iG1tfLL G1LLGG1tf.GGfttttt008808CC888Lf    //
//    LLLLLLLLLLLLLLLLLLLi:..i1i1i;GG ..  fLi,iiiiiiii1L8LGG ....L .G;GGLC;...,LLt8tttttCC    iLGGi, GGLtttf8ttttGL . . GLLt:.GGftttt1ttGG: L;G.Li1CLLGGttt1;tttt1LG, ,..,.1fGt1tttfGf00088CGC88Gf    //
//    LLLLLLLLLLLLLLLLLLf,;1;.iiiiii;GG.fG;:;t:1iiiiiiiL8f11GG; .GL.L1G..L:, CG11tCtttLC.....t.  L.Cf..iGL1LfttfG:.. .::. G ff..iLLtLittttfGL ,,, .iLLttttt1ifffttttfLf.. LLt:t;ttttLt000088CC88CL    //
//    LLLLLLLLLLLLLLLLLLL,1,1i1;,iiiii;C.iiii.;iiiiiiiiL8f1tt1GL1GG 8tG.,C;LLtttt1GfGC ....ttLf. G .. ...;GGffCt..,.:1LG. L, ......GL1t1tttttGG.,,Cff;ttttttiftttttttttLLffttttiittttf800888CCC88G    //
//    LLLLLLLLLLLLLLLLLLLi111iiiiiiiiiii.1iiiiiiiiiiiiiG0Li1ttttLLf...  ..LGttttt1LfLGf... L:LLf;..L. . GG1,tGLC... GG:LGG. C1. .GLLt:t,.ttt1t1GGLGt1.1ftttt11tttttttttttt;ttttttttttff00088CCC88G    //
//    LLLLLLLLLLLLLLLLLLL1111iii1iiiiiii:1iiiiiiii1iiiiL8L1;iit1ttfLf..,LGi1fLttt1ffttfLG  L:iGGt  G; GLtttttLttGG:.iG L:C..tf fGGtttt1ttttttttt1.tt111ttttttittttt1ttttttt1ttt1ttttf1i00088CCC88C    //
//    LLLLLLLLLLLLLLLLLLL11111i;iiiiiiii111i;.ii1iii:;iG8Lttt11tt1t11ffL1111i1ttttfLtttttLL:  . ... LLLttttttG:1ttGGf . . ,. ,GGtt1tf11tttttttttttt1111tt11t1ifttt;fttttttt;t1t:t1tt:1LL0088CCCC88    //
//    LLLLLLLLLLLLLLLLLLfi11i1,i111i1i;Gi;L; ,i1i:1i:iiL8ft11111111111t1ttttffttt1tLti1ttt1GL,..  1GG1;ttttt1Lt:11tttGC .,, GLt;t1tttG1tt1ttttttt1.1t1;ttttt1.ffttfttttt1tt11tti:tf1,i: 80088CCC88    //
//    LLLLLLLLLLLLLLLLLLf111i1i1iiii1i1i1:Gi.i i1i,.,;;f8t11111111111111;1ttfttttitG,i1i;1tt1fGi LGtt1f;tttttL,ftt1ttttGG:CGftt,tttttf11f;ttt11tt1fft.;:tttiti1fttfttttGGtLfGtttt1,ftt;:C0008CGCC8    //
//    LLLLLLLLLLLLLLLLLLi,:;1:i1111L1t11tfiiii ,;ii .:;L8f11111111111111:ttt1ttttttGtttttttttttfGittttt111ttttfttttttttttLL1ttttt1tttftttLtttttLttL,t1 11tt,;..tf1tttt1GL1tLiG1tt:ti.:tfi8000CGCC8    //
//    LLLGLLLLLLLLLLLLLL11111111iii11G11tL;1i.;t.1;i., fCtt111,1111t1111i1t:i1tti: Ltttttttttttt1tftttt1ttttttLttttttttttt1;ttttt1tttt;11tttttLGtfGtLttt:.ftt. Lt:1,tttCLGtC1i111ti,,t. .00008CGC8    //
//    LLLLLLLLLLLLLLLLLLt1t1;;ii111i1tLtt1L;,;i..i ..,:1Cttt11t11tttttGtLttttti,;1tCttttttttttttt1:ttt1ttt1tt:Gtttffttttt11tttttt1t1t:11tttt1ttG1tG:L11t11 .,f.1t1i1t11tfttGfG;;t1:1t;:tfL0008CCGC    //
//    LLLLLLLLLLLLLLLLLLt11ii:1iiii1111;;,.,1i1.1 :1i1;GLf111:ttt1tLLfGfffttftt.;,.0ttttt1ttttttt1it1tit1t111tL1tttttttt1111,11t,tt1:tf1titt111GtLLfGGt.t:. t..;L1ttttttttttttt::.t1t1if1;0000C8CC    //
//    LLLLLLLLLLLLLLLLLL1111;,1111i111111i; :.1:1i;,: .GCt11tttttttftf;G.1.1L,ti1.iGtttt;tttttttttt1tit.ttt1..;ttt,ttttti1ttttti;.t1tt;11,ttttttt1t1, .11t.f.1t,f1t;ttt1tttt1ttti.t11tttt1C00088CC    //
//    LLLLLLLLLLLLLLLLLL11ii1:111ii1111111,1 1i;;i11.:1fCt1;,t1ttttLGGt1ftf;fftii1,Gfttt;tttttttGtGf1tt1;11it ,i1fittttfft1LLG111t.ttit1:1ttt11ttttt1t.1 1.t1;;:ff,11tttttttt1ttt111tttttft000888G    //
//    LLLLLLLLLLLLLLLLLL111.1,i1i;1111111i, i11111ii11:GGt11:;1ttttt1111t11.ff11,,1Gtttt1tttttfLGt,1tii,it t.:fGfft1t1ttL;ffLLt11;ft.f;f;tt1tf:ftttttt.;;ttiff118f;1;fttttttttt1tttttt1ttLf000888C    //
//    LLLLLLLLLLLLLLLLLft11:1:1111i11111111i11111iii111LGt11;;tttttt111111tt,fit1;t1t1t1tttttttLftfLL;,t;1i1.:fLf,t.1tt1Gft1G;i1ttt,,t G;t.tt.tttttttti.tttttttt1fttt,ttttttttttt1tt1t1ttLtG00088C    //
//    LLLLLLLLLLLLLLGLGf11111,i11111111111111111i11111iLCtt1;1tttttt11111ti:LttttttLft,ftttttt1tff:tt.ittf;fti:Gft:111tttt1tC1.:t1:1;i;fiftt1ftttttttttttttttttt:Ltt1f1ttttt1t1tttttt111ttLt000888    //
//    LLLLLLLLLLLLLLLLLfttit1:t11t1111111111111111i1111GCttt;ti1111tt1111tt1tttttttLftt;ittttttttt1tt:;.f;1t:i1Ctitt1111111111t...iit11ft1tifttttt11tttttttttttt18fi;1;ttt1ttttttt1tttttttLf000008    //
//    LLLLLLLLLLLLLLLLLfttifii1tttttttt1t1t1111111i11itCCtt1i1;tt11t11111ttt1ftttttfftti1tttttttttttti1.111,.1iCfifi11111111111t1.t1;;ift11;t1ttttttttttttttttttiGfttttttttttttt11ttttttttftfGGCGG    //
//    LLLLLLLLLLLLLLGLLftt;1ttittttttttttttt1111111111tCGftt;t111ttt111111t                                                                                                                           //
//                                                                                                                                                                                                    //
//                                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract abc is ERC721Creator {
    constructor() ERC721Creator("enne", "abc") {}
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