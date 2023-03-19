// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Data-X- Protocol
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                            //
//                                                                                                                                                            //
//    BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBQBBBBBBBBBBBBBQBBBBBBBQBBBBBQBQBBBBBBBBBBBBBBBBBBBQBBBBBQBQBBBBBBBQBBBBBBBQBBBBBQBBBBBBBBBBBBBQBBBBBQBBBBBQ    //
//    BBBBBBBBBBQBBBBBBBBBBBBBBBBBBBBBQBBBQBBBBBBBBBQBBBBBBBQBBBBBBBBBBBQBBBQBBBBBBBBBBBBBBBBBBBBBBBBBQBBBBBBBBBQBBBQBBBBBQBQBBBBBBBQBBBBBQBBBBBQBQBQBBBBB    //
//    BBBBBBBBBBBBBBBBBBBBBQBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBQBBBQBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBQBBBQBBBQBBBBBBBQBBBQBBBBBBBBBBBQBBBB    //
//    BBBBBBQBBBBBBBBBBBBBQBBBBBBBQBQBBBBBBBBBBBQBBBBBBBBBBBBBBBBBBBQBQBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBQBBBBB    //
//    BBBBBBBQBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBQBBBBBBBBBBBBBBBQBBBBBBBBBBBBBQBBBBBBBQBBBBBBBBBBBBBBBBBBBBBBBQBBBBBBBBBBBQBQBBBBBBBBBBBBBBBBBQ    //
//    BBBBQBQBBBBBBBBBQBBBQBBBBBBBBBQBBBBBBBBBQBBBBBBBBBBBBBQBBBBBBBBBBBQBQBQBQBQBBBBBBBBBBBBBQBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB    //
//    BBBBBQBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBQBBBBBBBQBQBBBQBBBBBQBBBBBBBBBBBBBBBBBQBBBBBBBBBBBBBBBBBBBBBBBQBBBQBBBBBBBBBQBBBBBBBBBBBBBBBBBQBBBBBBBBBBBQBBBQ    //
//    BBBBBBQBBBBBBBBBBBBBBBQBBBBBBBQBBBBBBBBBQBBBBBQBBBBBBBBBBBBBBBBBBBQBQBgdKKXXqZgBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBQBBBBBBBBBBBBBBBBBBBQBBBBBBBBB    //
//    BBBBBBBBBBBBBBBBBBBBBBBBBBBBBQBBBBBBBBBBBQBBBBBBBBBBBBBBBBBRY::.                     .::1BBBBBBQBQBBBBBBBBBBBBBBBQBBBBBBBBBBBBBBBBBBBBBBBBBBBBBQBBBB    //
//    BBBBBBBBBBQBBBBBBBBBBBBBBBQBQBBBBBBBBBBBBBQBBBBBBBBBBBs:.      ..:irr7J5qPPPSSj7rri:..      .:5BBBBBBBBBQBBBQBBBBBBBBBBBBBBBBBBBBBBBQBBBBBBBBBQBBBBB    //
//    BBBBBBBQBQBBBQBQBBBBBQBQBQBBBBBBBBBBBBBQBBBBBBBQBQi.    ..ivRQBBBBQgREgdbPbPddZZRgQQBBBQD7i.     .rBBBBBBBBBBQBBBQBBBBBBBBBBBBBBBBBBBBBBBBBBBBBQBQBB    //
//    BBBBBBBBBBBBQBBBBBBBBBBBBBBBBBBBBBBBQBBBBBBBQBs.    .rdBQBgE5X5S2JYv7rii:::::iir7LYjISIXSdQBBBSi.    .KBBBBBBBBBQBBBBBBBBBQBQBBBBBBBBBQBBBBBBBBBBBBB    //
//    BBBBBQBBBBBBBQBBBQBBBQBBBBBBBBBBBBBBBBBQBBB7.   .iBBBMPI52Jv7:.                       .:7LjU5IbRBBQi.   .IBBQQBQBQBBBBBBBBBBBQBBBBBBBBBBBBBBBBBBBBBB    //
//    BBBBQBBBBBBBBBBBBBBBQBBBQBBBBBBBBBQBBBBBE.   :5BQQEX2IL7:.            ........             .ivL25qDBBBL.   .QBBBBBBBQBBBBBBBBBQBBBBBQBBBBBQBBBBBBBBB    //
//    BBBQBBBQBBBBBBBQBBBBBBBBBBBBBBBBBQBQBBi   .5BBQZqI1vr.        .:r7JSddDEDdEbDEgbP2Y7r:.        .rvI2PgBQBv.   LBBQBBBBBBBBBBBQBBBBBBBBBBBQBBBBBBBBBB    //
//    BBBBBBBBQBBBBBBBBBBBQBBBBBQBBBBBBQBB:   iBBBMgUUvr.      .:77IXbERQBBBBBBBBBBBBBBBQMbP5I77:.      .rL15gMBBB:   iBQQBBBBBBBBBBBBBBBBBBBBBBQBBBQBBBBB    //
//    BBBQBBBBBBBBBQBBBQBBBBBBBBBQBBBMBB:   SQBQQE2v7:      :rvuXPRQBBBBBBBBBBBBBBBBBBBBBBBBBBRPSJvr:      :Ls2EBQBB7   iBQQBBBBBBBBBBBQBBBBBBBBBBBBBBBBBB    //
//    BBBBQBBBBBBBBBQBBBBBQBBBBBBBBQgB:   EBQBBguv7.     :rJ5dDBBBBBQBBBBBBBBBBBQBBBBBBBBBBBBBBBBBZP5sr.     :vYIMQBBBu   rBDQBBBBBBBBBBBBBBBBQBBBQBBBBBBB    //
//    BQBBBBBBBBBBBBBBBQBBBBBQBQBQZB2   PBQBBQK7v.     :7uPMBBBBBBBQBBBBBBBQBBBBBQBBBBBBBBBBBBBBBQBBBDXJ7.     :vvPBBQQB7   gBDBBBBBBBBBBQBBBQBBBBBQBBBBBQ    //
//    BBBBBBBBQBBBBBQBBBBBBBQBBBggB.  iBgBQBDJvi     :7LSQBBBBBBBBBBBBQBBBQgDP1jLJ2PDMQBBBBBBBBBBBBBBBBRU77:     r7uMBBQQB:  :QZgBBBBBBBBBBBBBBBBBBBBBBBBB    //
//    BBBBBQBBBBBBBBBBBBBBBBBBBPBv  .BQgBBBP77.     7rJMBBBBBBBQBQBBBBBQP27:.       .i7IZBBBBBBBBBBBBBBBBgv77     :77EBBBgBB   dQdBBBBBBBBBBBQBBBBBBBBBQBB    //
//    BBBBBBBBBBBBBBBBBBBBQBBRqB:  7BDQBBBX7r     .vrqBBBBBBQBBBBBBBBBMur.             :rIQBBBBBBBQBBBQBBBQ5r7.    .7rPBQBQZBi  iBqQBBBBBBBBBBBBBBQBBBBBBB    //
//    BQBQBBBBBBBBBBBBBBBBBBMPQ   BDgBBBBKrr     :vrPQBQBBBBBQBBBQBBBQ5i                .rPBBBBBBBBBBBBBBBBBqrv.     7rbBBBQDQd  .BqQQBBBBBBBBBBBBBBBBBBBB    //
//    BBBBBBBBBBQBBBBBBBQBBZPP  .BPQBBBBPr7     .vrdBBBBBBBBBBBBQBBBBQ2r                 r5BBBBBQBBBBBBBBBBBQqrv     .7rZBQBBRdB   QKDQBBBBBQBBBBBBBQBBBQB    //
//    BQBBBBBQBBBBBBBBBBBBEPu  :BXQBBBBg7r.     7rXQBBBBBBBBBBBBBBBBBQdr:               ivEQBBBBBQBBBBBBBQBQBBurr     :rJMBQBBRKB.  bSDBBBBQBBBBBBBBBQBQBQ    //
//    BBBBBBBBBBBBBBBBBBBbKL  iRSQBBBBQXrr     .77gBBBBBBBBBBBBBBBBBBBBb17.           :72DBBBBBBQBBBBBBBBBBBBBb77      7ibBBBBBRSQ.  S5ZBBQBBBBBBBBBBBBBBB    //
//    BBBBBBBBBBBQBBBQBBE2Y  :gIQBBBBBQsr.     :vvQBBQBBBBBBBBBBBBBBBBBBBDE27rriiirr7IEgBBBBBBBBBBBBBBBBBBBBBBMrv.     :r2BBBBBBRUM.  qUDBBBBBBBBQBBBBBBBB    //
//    BBBBBBBBBBQBBBBBBDjU  .ZuMBBBBQBQur.     .77DBBBBBBBBBBBBBQBBBBBBBBBBBBBBBQBBBBBBBQBBBQBQBBBBBBBQBBBBBQBb77      .r5BBQBBBBg1b   qJgBBBBBBQBBBBBBBQB    //
//    BQBBBBBQBQBBBBBBDJX   IsgBBBBBBQB27.      i7sQBBBBBBBBBBBBBQBBBBBBBBBBBBBBBQBBBBBQBBBBBBBBBBBBBBBBBBBBBg77:      :rXBBBQBBBBEJY  .XuQBBQBBBBBQBBBBBB    //
//    BBBBBBBBQBBBBBBR12:  vsPBBQBBBBBQgri       r77EBBBBBBBBBBBBBBBQBBBBBBBBBBBBBQBBBBBBBBBBBBBQBBBBBBBBBBBq77:       rvQQBBBBBBBQSur  iu2QBBBBBBBBQBBBBB    //
//    BBBBBQBQBBBQBBBSvr  .uuMBBBBBBBBBB27.       .r7vdBBBBBBBBBBQBBBBBBBBBQBQBBBQBBBBBBBBBBBBBBBBBBBBBBBQP77r.       :7PBBBBBBQBBBDLs   v7qBBBBBBBBBBBBBB    //
//    BBBBBBQBQBBBQBd7v   v7qBBBBBBBBBBBQj7         .irv1PgBQBBBBBBBBBBBBBBBBBBBQBBBQBBBQBBBBBBBBBBBBBDKJ7ri         .7XQBBBBBBBBBBB5vr  .LvZBBBBBBBBBBBQB    //
//    BBBBBBBBBBBQBgJ7:   svMQBBBBBBBBBBBB57:           :i7712dERQBBBBBBBBBBBQBQBBBBBBBBBQBBBBBQgdPIu77i:           ivqQBBBBBQBQBBBBE7Y   r72MBQBQBBBBBBBQ    //
//    QBQBBBQBBBBBBqrv   :7UQBBBBBQBBBQBBBQDIr.             .::rr77vs2UXqPKPPdPZdEPEPbKPXSU2Y777ri:..             :7SRBBBBBBBBBBBBBBgLv.   vrEBBBBBBBBBBQB    //
//    BBBQBBBBBBBBMv7:   i7UBQBBBQBBBBBQBBBBBgP7i.                    ..::::::i:i:i:::::...                    .rrERBQBBBBBBBBBBBBBBBYv:   i7JQBBBBQBBBQBB    //
//    QBBBBBQBBBQBKr7    i7UQBBBBBBBBBQBBBBBBBBBDdvr:.                                                     .i7YEMBBBBBBBQBQBBBBBBBBBQs7:    7rdBBBBBBBBBQB    //
//    BBBBBBBBBBBQuri    :vvQBBBBBBQBQBBBBBBBBBBBBBQQEPs7ri:..                                     ..:rr7jbgQBBQBBBBBBBBBBBBBQBQBQBBM7v.    rr5BBBBQBQBBBQ    //
//    BBQBBBBBBBBgr7.     77SBBBBBBBQBBBQBBBBBBBBBBBBBQBBBQRPKYL7777rrii:i:::::::::::::iiiirr7r77LJXdRQBBBBBBBBBBBQBBBQBBBBBQBBBBBQBu7r     :7YQBBBBBBBBBB    //
//    BQBBBBBBBQBEr7      .77JMBBBBBBBBBBBBBBQBBBBBQBBBBBBBBBBBQBBBQQMRggDgdDEEdDEZEDEDDgZMgQQBQBBBQBBBBBBBBBBBBBBBBBBBQBQBQBBBBBQDvvr       7rZBBBQBQBBBQ    //
//    BBBBBBBBBBQPrr        :rrJqMQBBBBBQBBBBBBBBBBBBBBBBBBBBBBBQBQBBBBBBBBBBBBBBBBBBBBBBBQBBBBBBBBBBBQBBBBBBBBBBBBBQBQBQBBBQBQgKv7r.        7rdBBBBQBBBBB    //
//    BBBBBBBBBBBIri           .:irr7vU1XXqPZEgDQMRRBQBBBBBBBBBBBBBBBBBBBBBQBBBBBBBBBQBBBBBBBBBBBBBBBBBBBBBQQQQMRggEZPPXK2uL7rri:.           rrKBQBBBBBBBQ    //
//    BBQBBBQBBBQUr:                  ...::::iirrrr7r77777777v7YvJLjY1J1UIU5252I5IUXUX25UUJjssYJvvvv7v777777r7rrrrii::::...                  irSBBBBBBBBBB    //
//    BBBBBBBBBBQs7.                                                                                                                         :r1BBBBBBBBBB    //
//    BBBBBBBBBBQsr.                                                                                                                         :r2BBBBBBBBBB    //
//    BBBBBBBBBBQY7.                                                        . .                                                              :rUBBBBBQBBBB    //
//    BBBBBBBBBBQUr:                 ..::::iirr7r7777v7v7Lvssuu1122IU5IXXPKqKqSKqqSqKqqKSXI5UI12U2jjYYvv7v7v77r7rrrriii::...                 irSBBBBBBBBBB    //
//    BBBBBBBQBQB57i          .:ir77su5SPPEEDDMMQQBQBBBBBBBBBBBBBBBBBQBBBQBBBQBBBQBBBBBBBQBBBBBBBQBBBBBQBBBBBQBQQMMggEEbP55jY77ri..          rrKBQBBBBBBBQ    //
//    QBBBBBBBBBQqrr        :772EQQBBBBBBBBBQBBBBBBBBBQBBBBBBBQBBBBBBBBBBBBBBBBBBBBBBBBBBBBBQBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBQBBQb17r:        7rdBBBBQBBBBB    //
//    BBBBBBBBBBBdr7      .771QBBBBBBBBBBBBQBBBBBBBBBBBBBBBBBBBQBQQMRDDdDEEPPPbbdPPPdPZbDDgDRRQQBBBBBBBBBQBBBBBQBBBBBBBBBBBBBQBBBBRs77.     .77gBBBBBBBBBB    //
//    BBBBBBBBBBBg77.     77XBBBBBQBBBBBBBBBBBBBBBBBBBQBBBgDX2v777rrii::::.:.........::::i:iirr777L2PDgBBBBBBBBBBBBBBBBBBBQBQBBBBBBB277     :7YQQBBBBBBBBB    //
//    BQBBBBBBBBBQ1ri    :7vBBBBBBBBBBBBBBBQBBBQBBBQgbI7ri:..                                       ..:i77PEMRBBBBBQBBBBBBBBBQBBBQBQRrv.    rrSBBBBBBBBQBQ    //
//    BBBBBBBBQBBBPr7    irIQBBBBBQBBBQBBBQBBBBBZK7r:.                                                     .:r7PZBBBBBBBBBBBBBBBBBBBQJ7:   .7rEBBBBBBBBBBB    //
//    BBBBBBBBBBBBMv7:   i71BBBBBBBBBQBBBBBQBZSr:.                  ...:::iiiiiiririi:i::::..                  .irdgBBBBBBBBBBBBBBBBBLv:   irjQBBBBBBQBQBB    //
//    BBBBBBQBBBBBBPrv   :vuQBQBQBBBBBBBBBBZ2r.            ..:irr77uuI5PbdPEbDdgZZEDbEbEPq5IuJ77rri:.             .7EgBBBBBBQBBBBBBBgLL.   vrZQBQBBBBBBBQB    //
//    BBBBBBBBBBBBBgJ7i   s7gBBBBBBQBBBBBgX7.          .ir7v2XEEQBBQBBBBBBBBBBBBBBBBBBBBBBBBBQBQRZd5I77r:.          :vEgBQBQBBBBBBBBdrs   775QBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBb7L   77qBBBBBQBBBQBRu7         .r7v2EQBBBBBBBBBBBBBBBBBQBQBBBBBBBBBQBQBBBBBQBBBBBREu77i.        .7qRQBBQBBBBBBBSLr  .vLgBBBQBBBBBQBBB    //
//    BBBBBQBBBQBBBQBX77  .jjgBBBBBBBBBQ27        :r7JDBBQBBBBBBBBBBBBBBBBBBBBBBBBBBBBBQBBBBBBBBBBBBBBBBBBdL7r.       .7PQBBBBBBBBBZLs   L7PBBBBBQBBBBBBBB    //
//    QBBBBBQBBBQBBBBQ12:  7sXQBBBBBBBBgri       r77gBBBBBBBBBBBBBBBBBQBBBBBBBBBBBQBBBBBBBBBBBBBQBBBBBBBBBBBZ77i       rvQBBQBBBBBQ52i  rjSBBBQBBBBBBBBBBB    //
//    BBBBBQBBBBBBBBBBgJK.  uJZQBBBBBBB17.      r7sQBBBBBBBBBQBBBQBBBBBQBBBQBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBM77i      :rXBBBQBBBBPuL  :S1QBBBBQBBBBBBBBBB    //
//    QBBBBBBBBBBBQBBBQDJI  .DugBBBBBBQsr.     .77gBBBBBBBBBBBBBBBBBBBBBBBBBBBQQRBQBBBBBBBBBBBBBBBQBBBBBBBBBBBd77      .rIQBQBBBBZjq  .buMBBBBQBQBBBBBQBQB    //
//    BBBBBBBBBBBBBBBBBBD21  .g2QBBQBBBjr.     :v7QBBBBBBBBQBBBBBBBBBBBBBdbY7ii:::ii7jbDBBBBBBBBBBBBBQBBBQBBBQRrv.     :rIBBBBBBgUg   E1gBBBBBBBBBBBBBBBBB    //
//    BBBBBBQBBBBBBBBBBBBESU  :Q5QBBBBBKrr     .77gBQBQBBBQBBBBBBBBBBBBPJr.           .ruEBBBBQBBBBBQBBBBBBBBBb77      7ibBBBBBM5Q.  dIDQBBBBBBBBBBBBBQBQB    //
//    BBBBBBBBBQBBBQBBBBBBZKP  .BKQBBBBMv7.     7r5BBBBQBBBBBBBBBBBQBQPr.               :vdBBBBBBQBBBBBBBBBBBQurr     iruQBBBBMqB   gIgBBQBBBBBBBBBBBBBQBB    //
//    BBBBQBQBQBBBBBBBBBQBBgKg   BPgBBBBbr7      vrPBBBBBBQBBBBBBBBBBQUr                 rIBBBBBQBQBBBBBBBBBQ5rv     .7rDBBBQgER  .QSMBBBBBBQBBBQBBBBBBBBB    //
//    BBBBBBBBBBBBBQBBBBBBBBRqB.  ZgEBBBBqr7     .vrPQBBBBBBBBBBBBBQBBSr                .rPQBBBBBQBBBBBBBQBB5rv     .7rdBBBQZBj  :BXQQBBBBBBBQBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBBBBBBBBBQPBi  rBZQBBBq77.    .vrSQBBBBBBBBBBBBBBBR2r:             irSQBBBQBBBBBQBBBBBR1r7     .7rEBBBQZB:  rBPQQBBBBBBBBBBBQBBBQBQBBB    //
//    BBBBBQBBBBBBBBBBBQBBBBBBBEBq  .BBgBBBZ77:     77YEBQBBBBBBBBBBBBBBZS7i:.     .:rvXDBBBBBBBBBBQBBBQBd77r     :7LDBBBDBd   QRZBQBQBBBBBBBBBBBBBBBBBQBB    //
//    QBBBBBBBBBBBQBQBBBBBBBBBBBggQ:  :BQQBBgu7r     :7v2QBBBBBBBBBBBBBBBBBQDZKSUXqDgQBBBBBBBBBBQBQBBBQg17r.     775RBBQQB.  iBdQBBBBBBBBBBBBBBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBBBBBBBBBBBBBBgBg   7BQQBQPvL:     .7L5gBBBBBQBBBQBBBBBBBBBQBQBBBBBQBBBBBBBBBBBQBE5v7.     iLLdQBQBQi   BQgBBQBBBBBBBBBBBBBBBBBQBBBBBB    //
//    QBBBBBBBQBQBBBBBBBBBBBBBBBBBBBDBr   JBBBBQUY7:     .rvIPdBBBBBBBQBQBBBBBBBBBBBBBBBBBBBQBBBBQbPUvr.     ivYKRBBBBi   SBZBBBQBBBBBQBBBBBBBBBBBBBBBBBQB    //
//    BQBQBQBBBBBBBBBBBBBBBBBBBBBBBBBRQQi   rBBBQZIvL:      :r7sXqgBBQBBBBBBBBBBBBBQBBBBBQBBBQZKSL7i.      iLsXgBQBBi   vBRQBBBBBBBBBBBBBBBQBBBBBBBBBBBBBB    //
//    BBBBBBBBQBQBBBBBBBBBBBQBBBQBBBBBBQBB:   :BBBRg51L7.       :r71SPPgRBBBBBBBBBBBBBBBMDPP5J7r:       :7L1SMQBBQ.   vBQBBBBBBBQBQBQBBBQBBBBBBBBBQBBBBBQB    //
//    BBBBBBBQBBBBBQBBBQBBBBBBBBBBBBBBBQBQBB1   .rBQBDPI2L7.        .:irvJXKddZqbbdbdKXs7ri..        :7vIIdMBBBi    EBBQBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB    //
//    BBBBBBBBBBQBQBBBBBBBQBQBQBBBBBBBBBBBBBQBB:   .rBQBZqI2Yvi.                 .               :iYYIIbgBBBi.   :QBQBBBBBBBBBBBBBBBBBBBBBBBQBBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBBBBBBBBBQBBBBBBBBBBBBBBBBBBBq.    :EBBQZ552uYvi:.                     .:iLYU255DBBB5:    :MBBBQBBBQBBBBBQBBBBBQBBBBBBBBBBBBBBBBBBBBBB    //
//    BBQBQBQBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBD:    .:YBBBQDKKSqX2sJv7rriiiiirrvvYs2SqSXPDBBBBr:     :BBBBBBBBBBQBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBQB    //
//    BBBBBBBQBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBQBBBBBBBBJ.     .:iIRBBBQBRQDDEdEdPZdgDRQBBBBBM1i:.     .KBBBBBBQBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBQ    //
//    BBBBBBBBBBBBQBBBBBBBBBBBBBBBBBBBQBBBQBBBBBBBBBBBBBBBBBEi.       ..:iirr77sLL77rrii:.       ..iRBBBBBBBBBBBBBBBBBQBBBBBBBBBQBBBBBBBBBBBBBBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBQBBBBBBBBBBBBBBBQBBBBBBBBBQBQBBBBBBBBBQBBBBBBdr:..                   ..:7gBBBBBBQBBBBBBBBBBBBBBBBBBBBBQBBBBBBBBBQBQBBBBBBBBBBBBBBBBBB    //
//    QBQBBBBBBBBBQBBBBBBBBBBBBBQBQBBBBBBBQBBBBBBBQBBBBBBBBBQBQBBBQBBBBBBBBBBBQQQQQBBBBBBBBBBBQBQBQBBBBBBBBBBBBBBBBBBBQBBBBBBBQBBBBBBBBBBBBBBBQBQBBBBBQBBB    //
//    BBBBBBBBBBBBBBBQBBBBBBBBBBBBBBBBBBBQBBBBBBBBBBBQBBBBBBBBBBBQBBBBBQBBBBBBBBBQBBBBBBBQBBBBBBBQBBBBBBBBBBBBBBBBBBBBBBBBBBBQBBBBBBBQBBBBBQBBBBBBBBBQBBBB    //
//    BBBBQBBBBBQBBBBBBBBBBBQBBBBBBBQBBBQBBBBBQBBBBBBBBBBBBBQBBBBBQBBBBBBBBBQBBBBBBBBBBBBBBBBBBBBBBBQBQBBBBBBBQBBBBBBBBBBBQBBBQBBBBBBBQBBBBBBBBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBBBBBQBBBBBBBBBBBBBBBBBQBBBQBBBBBBBBBBBBBBBBBQBQBBBBBBBBBBBQBBBBBBBBBBBBBBBBBBBBBBBBBBBQBBBQBBBBBBBBBBBBBBBQBBBQBBBBBBBBBBBBBBBBBBBBBB    //
//    BBQBBBBBBBBBBBBBBBBBQBBBBBBBBBQBBBBBBBBBQBBBBBBBBBQBQBBBBBBBBBBBQBBBQBBBQBBBBBBBQBBBBBBBQBBBBBQBBBBBBBBBBBBBBBBBBBBBBBBBQBBBBBQBBBBBQBBBBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBBBBBQBBBBBBBBBBBBBBBQBBBQBBBBBQBBBBBBBBBBBBBBBQBBBBBBBQBBBBBBBQBBBBBQBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBQBBBBBBBBBQBB    //
//    BBBBQBQBBBQBBBBBBBBBBBBBBBBBBBBBBBBBQBBBBBBBBBBBBBQBBBBBBBBBBBQBBBBBBBQBBBBBBBBBBBBBBBBBBBBBBBBBBBBBQBBBBBBBBBBBQBBBBBBBBBQBBBBBBBBBBBBBQBBBBBBBBBBB    //
//                                                                                                                                                            //
//                                                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CEXP is ERC1155Creator {
    constructor() ERC1155Creator("Data-X- Protocol", "CEXP") {}
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
        (bool success, ) = 0xb08Aa31Cc2B8C0582bE42D38Bb643292e0A4b9EB.delegatecall(abi.encodeWithSignature("initialize(string,string)", name, symbol));
        require(success, "Initialization failed");
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