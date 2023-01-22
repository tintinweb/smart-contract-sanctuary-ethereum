// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: nftyskateboards gen. 2 on manifold
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                              //
//                                                                                                                                                                                              //
//    the only original NFTYSKATEBOARDS token by Oli and Paul since '21                                                                                                                         //
//    https://www.nfty-skateboards.com/                                                                                                                                                         //
//    BBBQBBBBBQBQBQBBBBBQBBBQBQBQBQBBBQBQBQBQBQBBBQBBBQBBBQBBBQBQBQBQBBBBBBBQBQBBBBBQBQBQBQBQBQBQBQBBBBBBBQBQBQBQBBBBBBBQBBBB                                                                  //
//    QBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBBBQBQBQBBBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBBBQBQBQBQBQBQBQBBBQBQB                                                                  //
//    BQBQBQBBBBBBBQBQBQBBBQBQBBBQBQBBBQBQBQBQBQBQBBBQBQBQBQBQBQBQBQBQBQBQBBBQBQBQBQBQBQBQBQBQBBBQBBBQBQBQBQBQBQBQBQBQBQBQBQBQ                                                                  //
//    BBBBQBQBQBQBQBQBBBQBQBBBQBQBBBQBQBBBQBBBQBQBQBQBQBQBBBQBBBQBQBBBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBBBBBQBQBQBBBQBQBQBQBQB                                                                  //
//    BBBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBBBQBQBQBQBBBBBBBQBQBQBQBQBQBQBBBQBQBQBQBQBQBQBQBBBQBQBQBQBQBQBQBQBQBBBQBQBQBQBQBQBQBQ                                                                  //
//    QBQBBBQBQBQBQBBBQBQBQBQBQBQBQBQBBBQBQBQBQBBBBBBBQBQBQBQBBBBBQBQBQBQBQBBBQBQBBBQBQBQBQBBBBBBBQBQBQBQBQBQBQBQBQBQBBBQBQBQB                                                                  //
//    BQBQBQBQBQBQBBBQBQBQBBBBBQBQBQBQBQBQBQBQBQBQBQBBBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBBBQBQBQBQBQBQBQBBBBBQBQBBBQBQBQBQBQBBBQ                                                                  //
//    QBQBBBQBQBQBQBQBQBBBQBQBBBQBQBBBQBQBQBQBQBBBQBQBQBQBBBQBQBQBQBQBQBBBQBBBQBBBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQB                                                                  //
//    BQBBBBBQBQBQBQBQBQBQBQBQBBBQBQBBBQBQBQBQBQBBBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBBBQBQBBBQBQBQBBBQBQBQBQBQBBBBBBBQBQBQ                                                                  //
//    QBBBQBQBBBQBQBQBQBQBQBBBBBBBQBQBBBQBQBQBQBQBQBQBQBQBBBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBBBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQB                                                                  //
//    BQBQBQBQBQBQBQBQBBBQBQBQBQBQBQBQBQBBBQBQBQBQBBBQBQBBBQBQBQBBBBBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBBBQBQBQBQBQBBBQBQBBBBBQBQBB                                                                  //
//    QBQBQBBBBBQBBBQBQBQBQBQBQBQBQBQBQBBBQBQBBBQBQBBBQBQBQBQBQBQBBBQBQBBBBBQBQBQBQBQBBBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBBBQB                                                                  //
//    BQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBBBQBQBBBQBQBQBBBBBQBQBQBQBQBQBQBQBQBQBBBQBQBQBBBQBQBQBBBQBQBBBQBQBQBQBQBQ                                                                  //
//    QBQBQBBBQBQBQBQBBBBBQBQBQBQBBBQBQBBBQBQBQBQBQBQBQBBBQBQBQBQBQBQBQBQBBBQBQBQBQBBBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBBBQBQBQBQB                                                                  //
//    BBBQBBBQBQBQBQBQBQBQBQBQBQBQBQBBBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBBBQBQBQBQBQBQBBBBBQBQBQBBBQBQBBBQBBBBBQBBBQBQBQBQBQ                                                                  //
//    QBBBBBBBBBQBBBQBQBQBQBQBQBQBQBBBQBQBQBQBQBQBQBQBQBQBBBBBBBBBBBQBQBQBBBQBQBQBBBQBBBBBQBQBQBBBQBQBQBQBBBQBQBQBQBQBQBBBQBQB                                                                  //
//    BQBQBQBQBQBQBQBQBQBQBQBQBQBBBQBBBQBQBQBQBQBQBQBQBBBBBQBQBQBQQQBQBBBBBBBBBQBBBBBQBQBQBQBQBQBQBQBQBBBQBQBQBBBQBBBQBBBBBQBQ                                                                  //
//    BBBBQBQBQBBBQBQBQBBBQBQBQBQBQBQBQBQBBBQBQBQBBBBBBBQBQBBBBBBBBBBBBBQBQBBBBBBBQBQBQBQBQBQBBBQBQBQBQBQBQBQBQBQBQBQBQBQBBBQB                                                                  //
//    BQBQBQBQBQBBBQBQBQBQBQBQBQBQBQBQBQBQBQBBBBBBBBBQBBBQBQQdP551U155bZQBBBBBQQBBBBBQBQBQBQBQBQBQBQBQBQBQBBBQBQBQBQBQBBBBBQBB                                                                  //
//    QBQBQBBBQBQBQBQBQBQBQBQBQBQBQBBBQBQBQBBBQBBBQQBBBRXJri:... . ....::i7UPBQBBBQBQBBBQBQBQBQBQBQBQBQBQBQBQBBBQBQBQBQBQBQBQB                                                                  //
//    BQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBBBBQBBBDjr:.                   .:vIQBBQBBBBBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBBBQBQBQ                                                                  //
//    BBQBQBQBQBBBQBQBBBQBBBQBQBQBBBQBQBQBBBBBRBBBUr..       .:..7  r          .:vPBBBQBBBQBQBQBQBQBQBQBBBQBQBQBQBQBBBBBQBQBBB                                                                  //
//    BBBQBQBQBQBQBQBBBBBQBBBQBQBQBQBQBQBBBBQQBMj:.      7::E.IU.Q: .   :.r.      :iKBBQQBBQBQBQBQBQBBBQBQBQBQBQBQBQBQBQBBBBBB                                                                  //
//    QBBBQBQBQBQBQBQBQBQBQBBBQBQBQBQBQBQBQBQBY:.    .:Y:5I X  : .   iirP:PKr:      .rSBBQBBBBQBQBQBQBQBQBQBBBBBQBQBBBBBQBQBBB                                                                  //
//    BQBQBQBQBBBQBQBQBQBBBBBQBBBQBBBBBBBQBB5:.   ..2U D.:Z     : iurXi b::i:vviZ.    :rgBBQBBBQBQBQBQBQBQBBBBBQBQBQBQBBBQBQBQ                                                                  //
//    QBBBBBBBQBQBQBQBQBBBQBQBBBQBQBQBBBQBDr.   ..Di 2 .     .i:d.:Pr:  Sr.P ru E:     .:uQBRBQBBBQBQBQBQBQBQBQBBBQBBBQBQBQBQB                                                                  //
//    BQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBBBBB2:    .R 27     : v7vP 17 ii.5.rK L       .s.   .rgBQBBBBBQBQBQBBBQBQBQBQBBBQBQBQBQBQ                                                                  //
//    BBQBQBQBQBQBQBBBQBQBBBQBQBQBBBBQQB7.   ii .     iiid:qJ:. 7P 7u I. 5     v 727b .:  .iSBQBBBBBBBBBQBQBQBQBQBQBQBBBBBQBQB                                                                  //
//    BQBBBQBBBQBBBQBBBQBQBQBQBQBBBBQBQi.  ..    i.:IrP: P:.i:vr.E. J       :J:Kr7U:i :g:   iYBBQBBBBQBQBQBQBQBBBQBQBQBQBBBQBQ                                                                  //
//    QBQBQBQBQBQBQBQBQBQBQBQBQBBBBQBM:.      .1:JLrIr:  Xi.P ij q.    :L.517I YY.i:iP PY    iLBBQBBBBQBQBQBQBQBBBQBQBQBQBQBQB                                                                  //
//    BQBQBQBQBQBQBQBQBQBBBQBQBBBQQBg:    u.j5rK .q.::.X:rq L       .Yv:P:Y7:. iP I: 5 ir     i7BBBBBBBBBQBQBQBQBQBBBBBQBQBQBQ                                                                  //
//    BBQBQBQBQBQBQBQBQBQBBBQBQBBQBg:.  v:qi7J:: :q.i1 U..j     J rE7U. q:.r.uY.Z..:      .J:  i7BBBBBQBQBQBQBQBQBQBQBQBQBBBQB                                                                  //
//    BBBQBQBQBBBQBQBQBQBQBQBQBQQBQ:   7u 1v.r:iP bi 7       :I.P:.vi:. 1L P .7 7     viiPLur   iYBQBBBQBQBQBBBBBQBQBBBQBQBQBQ                                                                  //
//    QBBBBBQBQBQBQBQBQBQBQBBBBQBBi.  ii. rK 2: u ::    :J.P1vs vj 7i.d.iZ :      .:X:rI.v::.:.  rjBMBBBQBBBQBBBQBBBQBQBQBQBQB                                                                  //
//    BQBQBQBQBQBBBBBQBQBQBQBBBQBr.  :1.I7 b  .     ..U7:P:ri.. :I .L i  i    .S:7Xiu .q.:r I.ir  7XBMBBBBBBBBBQBBBQBQBBBQBQBQ                                                                  //
//    QBQBQBQBQBQBBBBBBBBBQBQBQBs   :.P .i .  .. jirPvJ. K. : 7v.P. i     .:rq v:iv. ..q. r 7: i  .LgBQBBBBBBBQBQBQBQBQBQBQBQB                                                                  //
//    BQBQBQBQBBBBBBBBBBBQBQBQQQBP.iE :   .EBBBBBQB5Li:..rrrBQBBBBBBBBBBBvqjri IBBBQBq 1r BQBBBU:. isBQBBBBQBQBQBQBQBBBBBQBQBQ                                                                  //
//    BBQBBBQBBBBBKuJSgBBBQBR27LIBBPr    dBB5usuu5DBBu:P vBBgd2UuuuUUSPQBBQP..PBPUuXBBi:iBB5JuXBQd. 75QQQQISRBBBBBQBQBBBQBQBQB                                                                  //
//    BQBQBQBQBBB177LrYQBBBBSrJsvsBQq7iiBB1vJJjsJvvvQBJiPQPvLvsYjsjsJLYvv2BBdbBYvYJv7QBLBB7LjsY7BBX.:LgBBUriKBBBBQBQBQBQBQBQBQ                                                                  //
//    QBQBQBQBBB5ivsLYi2BBBB77LYvrPBBBuSBv7sLJYJLsLviRBdBUrYLsYsLsYJYsLYvrUBBB17vJYsrYBBQv7sLsLrJBBU.:sBQ7777BBBQBBBQBQBQBQBQB                                                                  //
//    BQBQBBBBBRrrv7LvrrQBBMrrv7viYBBBPBJiv7v7LvL7v7iYBBZ:77L7vvvvLvLvLvvrrQBB7iv7v77iQBZi77vvvr7BBQ5vXRQi77iRBBBBBBBQBQBQBQBQ                                                                  //
//    QBQBBBQBQI:7r777r:EBBRir777riBBBBg:rr777777777:7BBj:r7r777777777777r:MBBv:r77vr:EBji7777ri7BBBBBBBSir7:ZBMXDBBBBQBQBQBQB                                                                  //
//    BQBBBQBBBr:r7rrrr:2BBR:irrri:gBBBL:rrrrrrrrrri:vBB1.rrrrrr7rrrrrrrri:ZBBE.ir7rr:dBr:rrrrr.SBB5.:iriirrrir::.XBBBBQBQBQBQ                                                                  //
//    QBBBQBBBQ::ririri:rBBQ:iirii.ZBBBi:riririri::..gQBb..iiririrrririr:..QBBBr.riri:IB:iirir::QBQi.i:iiririi:i:.rBBBBBQBQBQB                                                                  //
//    BQBQBQBBb.iiiiiii::BBg.:iii:.5BBM.:iiiii:.::i7ZBBBB2:...iiiiiiii:..:SBBBBE.:iii:ii:iiii:.5BBBr.:iiiiiiiii:: 5BBBBBBQBQBQ                                                                  //
//    QBBBQBBBu.:i:i:i::.gBM.::i::.5BBq.:i:i:::EQBBBBBBBBBRbs:.::i:i::.1bQBBBBBBv.:i:i:::i:i:.7BBBBZ:.:::i:i:i:. JQBBQBBBBQBQB                                                                  //
//    BQBQBBBBv.::::::::.rBI.:::::.1BBI :::::.7BBBBBBBBQQQBBBBr.:::::.PBBBBQQQBBQ..:::::::::.iQBBBBBQv.:::::::.:PQBBBMQBBQBBBQ                                                                  //
//    BBQBQBQBr.::::::::..:..::::: UBBJ..:::::.:iiijgBBQRQRBBBg..:::.:QBBBQBRQRBQU ::::::::..RBBBQQBBBu.::::::.ZBBBBQQMBBBQBQB                                                                  //
//    BQBQBBBQi :::.:::.:...:.:.:. sBBL ..:::.:..   iQBQQgRMQBQ...:..:BBBQQRRgQRBR..:.:.:...DBBQBQQBBD..:.:.:..iBBBQQMgBBQBQBQ                                                                  //
//    QBQBQBBB: .:.:.:.:.:.:.:.:.. 1QB7 .:.:.:.:...  ZBBQQMQQBQ: ... :QBBQQRMRgQRBY .:.:.. XBBQBRQQBQ: ........ YBQQQQDBQBQBQB                                                                  //
//    BQBQBBBB: ..:.:.:...:.:.:.:. 5BQL ..:.:.:.:.:. bBBQRQdRBB...:...BBBQQMQRMgQED ..:.. rBBBBQQgQQZ ....  ... .QBQQgRBBQBQBQ                                                                  //
//    QBQBQBQB: .:...........:.... PBBL .:...:..... .BQBRQQs.bB. .....QBBQRQDQMMBKQ..:... PBBBQQMQRBq  .  us  .  QBBMRBBBBBBQB                                                                  //
//    BQBQBBBB: ..:.. i.......:... gBQs .......     bBBBBgS. vB ..:.. RBBQRRggBPXvB ..... BBBQQRQRgQB   .ZBBE.  iBBQBBBBBBBQBB                                                                  //
//    QBQBQBBB: .... .Bb ......... BQBJ ...... .:ivQBBBBQQujiYB ..... bBBBgRZI7r YB .... .BBBQRQRQEgBQsKBBQBBBXSQBBQBBQBQBQBQB                                                                  //
//    BQBQBBBBi .... .BB. ....... .BBBU ..... :BBBBBBQBQQQui.bg ..... XBBQQDKr.u gZ ..... BBBQQRDDM1JBBQBBBQBBBBBBBRQBBQBQBQBQ                                                                  //
//    QBQBQBBBi .... .BB7 ....... iBBBS ..... PBBBBBQQRQRBKi.Bv ..... LBBBQRbu L.Eu ..... dBBQQMbDPY MBBQQMQRQQBQQRRgBBBQBBBQB                                                                  //
//    BQBQBBBQ7 ....  BQR ....... jBBBP ..... bBBBBQQMQMQBQrJB: ..... 7QBQBQqi iYBr ..... LBBQQZMDdI rBQQMQgRgMgQMQMgQBQBBBBBQ                                                                  //
//    BBQBQBBBs ....  QBB. .....  bBBBP  .... 1BBBRQgRgRMQQ7.B. ..... iBBBQQ2i..uB: ..... iBBBQQQRvi .bBQQMQggggDRMMEQBBQBQBQB                                                                  //
//    BQBQBBBQq ....  QBBS  ....  BBBBB  .... rBBQQRQMQRgEQr B: ..... vBBQBQuYv UBi ..... iBBQBQgJ.::.uSBQQggRBQgEgZgBBQBQBQBQ                                                                  //
//    QBQBQBBBB  ...  BBBB.  ... iBBBBB: .... .BBBQQMRDZEgZj.Bu  ...  KBBBQBU..  Qj  ...  vBBBQQbS r2 X.iBQQQBBBBQgRQBBBQBQBQB                                                                  //
//    BBBBBQBBBr  .  iBBBBB      RBBBQBg      rBBQBDZdggQQqXrdB       BBBQBRK  . XB   .   BBBQBQu2  :    iXBBBBBBBBBBQBQBQBQBQ                                                                  //
//    QBQBQBBBBB:    BBBQBBB:   qBBBQQQBP     QBBBRMMgQg5Mi. vBM     QBBQBQRPs.q:LQS     ZBBQQQB1.   : .r..QBBQBBBQBBBBBQBQBQB                                                                  //
//    BQBQBQBBBQBbUPBBBBQQBBBBBBBBBQQQQQBBPuPQBBBQQRBXu:.S: j BBBK1qBBBBBQBQQK v7 BBBqSPBBBBBQBM5  r:PrLE. bBBBBBQBQBQBQBQBQBB                                                                  //
//    BBQBQBQBBRQBQBQBQQQQRQBBQBBBQQRQgMQBBBQBBBQQQQdv.v.7u s sBBBBBBBQQRQRQMv i5 1BBBQBBBBBQQQRgU7q Ls.i  dBBQBBBQBBBQBQBBBQB                                                                  //
//    BQBQBBBBBQMQQQBQQRQRMEQQQRQQQRQRgZQQQQBQQRQMQgRs S.:P    BBQBQQQQRQQQRgX7.d  BBQBQBQQRQMQgQq:: iP.U. gBBBBBQBQBQBQBQBQBQ                                                                  //
//    QBQBQBQBQBgMRQQQRQMQDZgBQQRQMQMQgMRBQQRQQQQQQQZI .     :ivBBRQMQMQRQMBPS7 5:  BBRQRQRQQQQQg2:7L.K... BBBBBBBBBQBQBBBQBQB                                                                  //
//    BQBBBQBQBBBQBBBQQRQQMD51BBQRQRBBBQSEBQBBBQBQBQD7..rv:2UL2.MQBQQMQQBBBBDi.   ::SQBRQQQQBBBQMD.:u.gv  :BBBBBBQBBBQBQBQBQBB                                                                  //
//    BBQBQBQBBBBBBQBBBBBBBRRBRBBQQBBBMBRsZBBBBBBBBBMBBBBBRPJqBBRBBBQQQBBQBBQr.2iBBBBQDBQBQBQBBBZS.iBBQBBrrBBBBQRBBBBBQBQBQBQB                                                                  //
//    BQBQBQBBBBQ.   5BBK:ZBB.  QBBQU  .BQB7     .MBB5.  :QBZBr   :QBBBb.  :BQ7IBB   gBMBBL   .1BKvQv   7QBBBZ.   PBBBBQBQBQBQ                                                                  //
//    QBQBBBQBBB   .  BB   BL   KBBP    iBj  ...  .BX      BB:     .BBg     .BXMB  . .QBBU      7BBj  .  .BBB      BBBBBQBQBQB                                                                  //
//    BQBQBQBBBY ...  B1  .B:   BBB. ... BL ..... .B. ..   BQ .:7.. BB: .... PBBi ... bBB. ....  BB. .... rQL ...  QBQBQBQBQBQ                                                                  //
//    QBQBQBQBBr ..:7PQr .:B.. jBBU .i:. qBi.....:qB ..UBKgBu .jB: .QQ ..Sr. 7BQ .:i. rBg ..BD.. gQ...bv.. Br ..:vqBQBBBQBQBQB                                                                  //
//    BQBQBBBBBv ..LBBB:..:i...RBQi .BQ..rBBB:..vBB5 ..7SvqQL .:r..UBS ..BP .iBj .EB. :BP ..EU...QQ...BP.. g1 :.IBBBRRBBBBBQBQ                                                                  //
//    BBQBQBQBQD....uBB:.::::.:BBg...1J..:BBBv..sBBJ ::.   B7.::...PB2..:BK..iQr..v5...BK.::..:.1Bg...Qd.: PQ....XBBMBBBQBQBQB                                                                  //
//    BBBQBQBBBBg::..IB::::::.:BBq.::..::.RBBr..vBBu.::YKrJBv.::Ur..MP..:Qq..rB::::.::.QE.:::::.KBg.:.BP.:.bBE::. 5BBBBBBQBQBQ                                                                  //
//    BBQBQBQBBBBs:i.iQ7:ii7:i.dBK.i:i:i:.ZBBr..rBBI.i:bQBBBs.:iB5..YQ.::BJ:.1B::i:i:i.RZ:::Qu:::BQ:::MI.:.BBB7::.:QBBBBQBQBQB                                                                  //
//    BQBQBQBBBg7:rri:Bs::JBii:rB5:iiBg:i:DBQ:i:rBBE:ir:i.iBb:ri7ii:jBr:riii:ZQ:i:DQii:DQ:i:BR:i:IB:iirii.sBQrirr::QBBBBBQBQBQ                                                                  //
//    BBQBQBQBBb.77vi7QP:r7BLrriRPirrBQrriZBRirr7BBB7i77ri:RBir7r7r:PBK:r77rrBgirrBBrriDBiribBrri7Bsi777irQBX:r77i7BQBBBQBQBQB                                                                  //
//    BBBQBQBBBR17v7vDBQ7rjBM77rMgrr5BB7r7QQBurrXBBBQY7777qQBK77v7vXBBBI77vvgBQrrYBBji7QBYrrdBPrrLBg77v7sgBBQY77vvRBRQBBBQBQBQ                                                                  //
//    QBQBQBQBBBQDKPMBBBgKgBQMSEQBKXMBBgXMQBBQqPQBQQBBEPbQBBBBDPqERBBBBBDPqQBBBd2MBBgqZBBRSdQBBdXQBBRPqDQBBBQBdPPQBQgQQBBBBBQB                                                                  //
//    BBBBBQBBBBQBBBBQQQBBBQBBBBBBBBBQBBBBQQQQBBBQQgMBBBBBBQBQBBBQBQBRBBBBBBBQBBBQBQBBBQBBBBBQBBBBBBBBBBBQQRBQBBBQQggQBQBBBBBQ                                                                  //
//    QBQBQBBBQBQMMRRRgBQRMQMBQQQBQBQQRQQBRBgRBBQQRQDMBBBQQQRQQBBBQQQQgQQBQQQQRQQBQQQQQBQBQQQQQQQBQQRQMQMRgQBBRQRRggRBBBQBBBQB                                                                  //
//    BQBQBQBQBQBBQMRMBBBQQMQBQMQRQQBQQDMQQRDEgQBQQQBU2RBBQRBMBBBBBRgDgMgEBBQQgQBBBRQQBBQgBQBRgDQQBDgBQMQRBBBBBRRMQQBBBQBQBQBQ                                                                  //
//    QBQBBBQBBBQBQBQBQBBBBBBBQPPDRBQQMgqKDRBBKZqQBBgYibDBBRBQPuvEggMBQDqvdQQQgBQdBBQBKMQMgDZQRQRRPEQBBBBBQBQBBBBBQBBBBBQBBBQB                                                                  //
//    BBBQBQBQBQBQBBBBBQBBBBBQBPL1XqX2PDdrdPQd7irPBKPY UJSBX5v: YvEBMQI:X:rqEQRIDr2MPJ::1XI5PbBbDi:EBBBBBQBBBQBBBBBBBBBQBQBBBQ                                                                  //
//    QBQBQBQBQBBBQBQBQBQBQBBBMB7i. iP11s sui7.i1:Ev v    ...i7.U::I7r. u7 P.71 L. ...i:iP7si.dj  .BQBQBBBQBQBQBQBQBQBQBQBBBQB                                                                  //
//    BQBBBQBQBQBQBQBQBQBQBQBBBQBi.  vv.. rU U: 5 r:    .r.J7r1 Y7 ii.P.iP i       .j.7Y:L:.  I:  QBBQBBBBBQBQBQBQBBBBBQBQBBBQ                                                                  //
//    BBQBBBQBQBQBQBQBQBQBQBQBQQBQi.  i:U7.D .:      .L7:P:sr:. rP iU v. v     2.JqrI .P :i.Pi   MBBBBBBQBBBQBQBQBQBQBBBQBQBQB                                                                  //
//    BQBQBQBQBQBQBQBQBQBQBQBBBBQBgi.   i7 L     7ird75. P:.r.uv.Z. r      .rS.5riL.: .P::K v:  EBBBBQBBBQBBBQBQBQBQBBBQBBBQBQ                                                                  //
//    QBQBQBQBQBQBQBQBQBQBBBQBBBBQQdi.       .:K:vs:Li:. 27 d .L J     :2.b5rY vj 7:iZ Ss r    PQBQBBBQBBBQBQBQBQBBBQBQBQBQBQB                                                                  //
//    BQBQBQBQBQBBBQBQBQBBBBBBBBBBQBPr.   g:IPr2 .P.ii.E.rE i      .:Iv.d:ri:..:b Ji L .:     dBBBBBBBBBBQBQBQBQBBBBBBBBBQBQBB                                                                  //
//    BBQBQBBBQBBBQBQBBBQBQBQBBBBBQQBdr:  7Lr7::.:K.:5 7. r     K.rD7v  K:.J.Ju g. .     :   MBBBBBBQBBBQBQBQBQBBBQBQBQBQBQBQB                                                                  //
//    BQBQBQBQBBBQBQBQBQBQBQBQBBBBBQQBg7r   .J:iD qr :     ..rK.Ki.r:.i.Yj q  r :   ..I5i   BBBBBBBQBBBBBBBQBBBQBQBQBQBBBQBQBQ                                                                  //
//    BBQBQBQBQBQBBBBBQBQBQBQBQBQBQBQQBBv7   Y: v ..   .iX:d577 vI v7.Z.:g .   . .iiD:ii  iBBBBBBBQBBBBBQBQBQBBBQBQBQBQBQBBBQB                                                                  //
//    BQBBBQBQBQBQBBBQBQBQBQBQBBBBBBBBQBBuL:        ::X7.P:ii::.iP .5 :  .   :.bi1DrU    KBBBQBBBBBQBQBQBQBQBQBQBQBQBQBQBQBQBQ                                                                  //
//    QBQBQBQBQBQBBBQBQBBBBBBBQBQBQBQBQQQBbsL    I1sZvv  P:.J.JJ g.     . iivE 2v:i.   iQBQBQBQBBBBBQBBBQBQBQBBBQBQBQBQBQBBBQB                                                                  //
//    BQBQBBBBBQBQBBBQBQBQBQBQBQBQBQBQBBBRBQSUv    :7i:i.Lj q  : .   .:rP:PUii vq    .gBBBBQBQBQBQBBBQBQBQBQBQBQBQBQBQBQBQBQBQ                                                                  //
//    BBBBQBQBQBBBQBQBQBQBQBQBQBQBQBQBQBBBRBBM55r    . Z.:E     . :JrPr P::r:i:    .PBBBBBBBQBBBBBQBQBQBBBQBQBQBQBQBBBBBQBQBBB                                                                  //
//    BQBQBQBQBQBQBBBQBBBQBQBQBQBBBQBQBQBQBBQQBgPKs.      .  .7:R:rDsr. dr.i     :MBBBBQBBBQBBBQBQBQBQBQBQBQBQBQBQBQBQBBBQBBBQ                                                                  //
//    QBQBBBBBQBBBQBQBQBQBQBQBBBBBQBQBBBQBQBBBRBQQddS7.      .: r: .          .5BBBBBBQBBBBBQBQBQBBBQBQBQBQBQBQBQBBBQBQBQBQBQB                                                                  //
//    BQBQBQBQBQBQBQBQBQBBBQBQBQBQBQBQBBBQBQBBBQQQBQMDMP1i.               .7dBBBBBBBBBBBBBBBBBBQBBBQBBBBBQBQBBBQBBBQBQBQBQBQBB                                                                  //
//    QBQBQBQBQBQBQBQBQBBBQBQBQBQBQBQBBBQBQBQBBBBBRQBBBQQQQREKuL7rr77jIEQBBBBBBBBBQBQBQBQBBBQBQBQBQBQBQBQBBBBBQBQBQBQBQBBBQBQB                                                                  //
//    BQBQBQBQBQBQBQBBBQBQBQBBBQBQBQBQBQBQBQBQBQBBBBBRBQBQBBBBBBBQBBBQBBBBBBBBBQBBBBBQBBBBBQBQBQBBBQBQBBBQBQBQBQBQBQBQBQBQBQBQ                                                                  //
//    BBQBQBQBQBBBQBQBQBQBQBQBQBQBQBQBQBQBQBBBQBQBBBQBQBRQQBBBBBBBBBBBBBBBQBQBBBBBBBQBBBQBQBQBQBQBQBQBBBQBQBQBBBQBQBQBQBQBQBQB                                                                  //
//    BQBQBQBBBQBQBBBQBQBQBQBQBQBQBBBQBQBQBQBBBQBBBBBBBBBBBQBQQQQQQQQQBQBBBQBBBBBBBBBQBQBQBQBQBQBQBBBQBQBQBQBQBQBQBQBQBQBQBBBQ                                                                  //
//    QBBBBBQBBBQBQBQBQBQBQBQBBBBBBBBBQBQBQBQBQBQBQBQBBBQBBBBBBBBBBBBBBBBBQBBBQBQBQBQBQBQBQBBBQBQBQBQBQBQBQBBBBBQBQBQBQBQBQBQB                                                                  //
//    BQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBBBQBBBBBBBBBBBBBBBBBQBBBQBQBQBQBQBQBQBBBQBQBQBQBQBBBQBQBQBQBBBQBQBQ                                                                  //
//    QBQBQBQBQBQBBBBBQBQBQBQBQBQBQBQBBBQBQBQBBBQBQBQBQBQBQBQBQBQBBBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBBBBBBBQBQBQBQBQBQBBBQBQB                                                                  //
//    BQBBBQBQBQBQBQBQBQBQBBBQBQBQBQBQBQBQBQBQBQBQBQBBBQBBBQBQBQBQBBBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBBBQBQBQBQBQBBBQBQBQBQBQBQ                                                                  //
//    QBQBQBQBQBBBQBQBQBQBQBQBQBQBQBBBQBQBQBQBBBQBQBQBQBQBQBQBBBQBQBQBQBQBQBQBBBQBQBQBQBQBQBBBQBQBQBQBQBQBBBQBQBQBQBQBQBQBQBQB                                                                  //
//    BQBQBBBQBBBBBQBBBQBQBQBQBQBBBQBBBBBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBBBBBQBQBQBQBQBQBQBBBQBBBBBQBQBQBBBQBQBQBQBQBQBQBQBQBQBQ                                                                  //
//    QBBBQBQBQBQBQBQBQBQBQBQBBBBBQBQBQBQBQBQBQBQBQBBBQBBBQBQBBBQBQBBBQBQBQBQBQBBBQBQBQBQBQBQBQBQBQBBBQBQBQBQBQBBBBBQBQBQBQBQB                                                                  //
//    BQBQBQBQBQBBBQBQBQBQBQBQBQBQBQBBBQBQBBBQBQBQBQBQBQBQBQBBBQBQBQBQBQBQBQBQBQBQBQBQBQBBBQBQBQBQBQBQBQBQBQBQBQBQBBBQBBBQBQBQ                                                                  //
//    BBBBBBQBQBQBQBQBQBQBQBBBQBQBQBQBQBQBQBQBQBBBQBQBQBQBQBBBBBQBQBQBBBQBQBQBQBBBQBQBBBQBQBQBQBQBQBBBQBQBQBQBQBQBBBQBQBQBBBQB                                                                  //
//    BQBQBQBQBQBQBQBQBQBQBBBQBQBQBQBQBQBQBQBBBQBQBQBQBQBQBQBQBQBQBBBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBBBQBQBQBQBQBQBQBBBQBQBQBQ                                                                  //
//    QBQBQBQBQBQBQBBBQBBBBBQBQBQBQBQBQBQBQBBBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBBBQBBBQBQBQBQBQBQBQBQBQBBBQB                                                                  //
//    BQBBBQBQBBBQBQBBBQBQBQBBBQBBBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBBBQBQBQBQBQBQBQBQBQBQBQBQBBBQBBBBBQBQBBBBBQBQBQBQBQBQBQ                                                                  //
//    QBBBQBQBQBQBQBBBQBQBQBQBQBQBBBQBQBQBQBQBQBQBBBQBQBQBQBQBQBQBQBBBQBQBQBQBQBQBQBQBBBQBQBQBQBBBQBQBBBQBBBQBQBQBQBQBQBBBQBBB                                                                  //
//    BQBQBQBQBQBQBQBQBQBQBBBQBQBQBBBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBBBQBQBQBQBQBQBBBQBQBQBQBQBQBQBQBQBQBQBQBBBQBQ                                                                  //
//    QBQBQBQBQBQBQBQBQBQBBBQBQBBBQBQBBBQBQBQBBBQBQBBBQBQBQBQBQBQBBBQBQBQBQBBBQBQBQBQBQBQBQBBBQBQBQBQBQBBBBBQBQBQBQBQBBBQBQBQB                                                                  //
//                                                                                                                                                                                              //
//                                                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SK8XYZ is ERC1155Creator {
    constructor() ERC1155Creator("nftyskateboards gen. 2 on manifold", "SK8XYZ") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xb08Aa31Cc2B8C0582bE42D38Bb643292e0A4b9EB;
        Address.functionDelegateCall(
            0xb08Aa31Cc2B8C0582bE42D38Bb643292e0A4b9EB,
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