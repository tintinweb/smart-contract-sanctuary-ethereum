// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Concentric Mechanisms
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                     //
//                                                                                                                                                                                                     //
//                                                                                                                                                                                                     //
//    C━┪┙┩┘┫┖┪┕┨──┧┧└└└└└└└└└┧┧──┨┕┕┪┖┫┘┩┙━C O NC E N T RR II  CCCCCCC   II R  T N E C NO C━┪┙┩┘┫┫┖┪┕┕┨┨───────────┨┨┕┕┪┖┖┫┘┘┩┙┪━━C OO N  CC   EEEEEEEE   CC  N OO C━━┪┙┩┘┫┫┖┪┕┕┨──┧┧┧└└└└└└└└┧┧┧─    //
//    C━┪┙┘┫┖┪┪┕┨──┧┧└└└└└└└└└┧┧──┨┕┪┖┫┘┩┙┪━C ON C E N T R  I   CCCCCCC   I  R T N E C N O C━┪┙┩┘┫┖┪┪┕┨┨───┧┧┧┧┧────┨┨┕┕┪┖┖┫┘┩┙┪┪━C O  N  C  EEE         EE  CC NN O CC━┪┙┩┘┫┫┖┪┕┕┨───┧┧┧└└└└└└┧┧┧─    //
//    C━┙┩┘┫┖┪┕┕┨─┧┧└└└└└└└└└└┧┧─┨┨┕┪┖┫┘┩┙┪━CO N C  N T  R II  CCCCCCCC  II RR T N E C N  C━┪┙┩┘┫┖┖┪┕┨┨───┧┧┧┧┧┧┧───┨┨┕┪┪┖┫┘┘┩┙┪━C O  N CC EE  NNNNNNNNNN   EE CC N O  C━┪┙┩┘┫┫┖┪┕┕┨┨──┧┧┧┧└└┧┧┧┧──    //
//    ━┪┙┩┘┫┖┪┕┨┨─┧┧└└└└└└└└└└┧┧─┨┨┕┪┖┫┘┩┙┪C O NC E N T RR II  CCCCCCCC  II R  T N E  N O C━┪┙┩┘┫┖┪┕┕┨┨──┧┧┧┧┧┧┧┧───┨┕┕┪┖┖┫┘┩┙┪━C  O N C  E  NN     T     NN  E  C N OO C━┪┙┩┘┫┫┖┪┕┕┨┨──┧┧┧┧┧┧┧┧┧──    //
//    ━┪┙┩┘┫┖┪┕┨──┧┧└└└└└└└└└┧┧──┨┕┪┪┖┫┘┙┪━C ON C E N T R  I   CCCCCCC   I  R T N E C N O ━┪┙┩┘┫┖┖┪┕┨┨──┧┧┧┧┧┧┧┧┧──┨┨┕┕┪┖┫┘┘┩┙┪━C O N C EE NN  TTTT   TTTT  NN EE C N  O C━┪┙┩┘┫┖┖┪┕┕┨┨───┧┧┧┧┧┧───    //
//    ━┪┙┩┫┖┖┪┕┨──┧┧└└└└└└└└└┧┧──┨┕┪┖┫┘┩┙┪━C  N C E  TT R II  CCCCCCCC  II  R T N E C NO C━┪┙┩┘┫┖┪┕┕┨───┧┧┧┧┧┧┧┧┧──┨┨┕┪┪┖┫┘┩┙┪━C O N C EE N  TT    RRRR   TT  N  E C N OO C━┪┙┩┘┫┖┖┪┕┕┨┨────┧┧┧────    //
//    ━┪┩┘┫┖┪┕┕┨──┧┧└└└└└└└└└┧┧─┨┨┕┪┖┫┘┩┙┪━ O N CE N T RR II  CCCCCCCC  II RR T N E CN O C━┪┙┘┘┫┖┪┕┨┨──┧┧┧┧┧┧┧┧┧┧──┨┨┕┪┖┫┫┘┩┙┪━C O N C E N  T  RRRR   RRRR  TT NN E C N O C━┪┙┩┩┘┫┖┪┪┕┕┨┨─────────┨    //
//    ━┙┩┘┫┖┪┕┨┨─┧┧└└└└└└└└└└┧┧─┨┨┕┪┖┫┘┩┙┪C O N  E N T R  II  CCCCCCCC  II R  T N  C N O ━┪┙┩┘┫┖┪┪┕┨┨──┧┧┧┧└┧┧┧┧┧──┨┕┕┪┖┫┘┩┙┪━C O N C E N  T  RR         RRR TT N  E C N O C━┪┙┩┘┫┫┖┪┪┕┨┨┨────────┨    //
//    ┪┙┩┘┫┖┪┕┨┨─┧┧└└└└└└└└└└┧┧─┨┕┕┪┖┫┘┩┙━C O  C E N T R  I   CCCCCCCC  II R T N E C N OC━┪┙┩┘┫┖┪┕┕┨──┧┧┧┧└└└┧┧┧──┨┨┕┪┪┖┫┘┩┙┪━C O NC E  N T  RR  IIIIIII   RR TT N E C N O C━┪┙┩┩┘┫┖┖┪┕┕┨┨┨──────┨┨    //
//    ┪┙┩┘┫┖┪┕┨──┧┧└└└└└└└└└┧┧──┨┕┕┪┖┫┘┩┪━C ON C E N T R  I  CCCCCCCC   I  R T N E C NO C━┪┙┩┘┫┖┪┕┕┨──┧┧┧┧└└┧┧┧┧──┨┨┕┪┖┖┫┘┩┙┪━ O N C E N TT RR  IIIIIIIII   R  T NN E C N O C━┪┙┩┘┫┖┖┪┪┕┕┨┨┨────┨┨┨    //
//    ┪┙┩┘┫┖┪┕┨──┧┧└└└└└└└└└┧┧──┨┕┪┖┖┫┩┙┪━C ON C E N T R II  CCCCCCCC  II  R T N E C  O C━┪┙┩┘┫┖┪┕┨┨──┧┧┧┧└└┧┧┧┧──┨┨┕┪┖┫┫┘┩┪━C O N C E N T  R  IIII   IIII  RR T  N E C N O C━┪┙┩┘┫┫┖┪┪┕┕┨┨┨┨┨─┨┨┨┨    //
//    ┪┙┩┘┫┖┪┕┨──┧┧└└└└└└└└└┧┧──┨┕┪┖┫┘┩┙┪━C  N C E  TT R II  CCCCCCCC  II RR T N E CN O C━┪┙┩┘┫┖┪┕┨┨──┧┧┧┧└└┧┧┧┧──┨┕┕┪┖┫┘┩┙┪━C O N C E N T  R  IIII   IIII  RR T  N E C N O C━┪┙┩┘┫┫┖┪┪┕┕┨┨┨┨┨┨┨┨┨┨    //
//    ┪┙┩┘┖┖┪┕┨──┧┧└└└└└└└└└┧┧──┨┕┪┖┫┘┩┙┪━CO N C EN T  R II  CCCCCCCC  II RR T N E CN O C━┪┩┘┫┫┖┪┕┨┨──┧┧┧┧┧┧┧┧┧┧──┨┕┕┪┖┫┘┩┙┪━C O N C E N T  R   IIIIIIIII   R  T N EE C N O C━┪┙┩┘┫┫┖┪┪┕┕┨┨┨┨┨┨┨┨┨┨    //
//    ┪┙┩┫┖┪┪┕┨──┧┧└└└└└└└└└┧┧──┨┕┪┖┫┘┩┙┪━CO N C  N T  R II  CCCCCCCC  II RR T N E  N O C━┪┩┘┫┫┖┪┕┨┨──┧┧┧┧┧┧┧┧┧───┨┕┕┪┖┫┘┩┙┪━C O N C E N TT RR  IIIIIIII   R  T  N E C N O C━┪┙┩┩┘┫┖┖┪┕┕┕┨┨┨┨┨┨┨┨┨┨    //
//    ┪┙┘┫┖┪┪┕┨──┧┧└└└└└└└└└┧┧─┨┨┕┪┖┫┘┩┙┪━CO N C  N T  R II  CCCCCCC   II R  T N E  N O C━┪┙┘┘┫┖┪┕┨┨──┧┧┧┧┧┧┧┧┧──┨┨┕┕┪┖┫┘┩┙┪━C O N C E N  T  RR          RR  TT N E CC N O C━┪┙┩┘┫┫┖┪┪┕┕┨┨┨┨┨┨┨┨┨┨┨    //
//    ┪┩┘┫┖┪┕┕┨──┧┧└└└└└└└└└┧┧─┨┨┕┪┖┫┘┩┙┪━CO N C  N T  R II   CCCCCC   II R  T N E  N O C━┪┙┩┘┫┖┪┕┕┨───┧┧┧┧┧┧┧┧──┨┨┕┕┪┖┫┘┩┙┪━C O N C EE N TT  RRR     RRRR  T  N E  C N O C━┪┙┩┘┘┫┖┖┪┕┕┨┨┨┨────┨┨┨┨    //
//    ┪┩┘┫┖┪┕┕┨──┧┧└└└└└└└└└┧┧─┨┨┕┪┖┫┘┩┙┪━CO N C  N TT R II   CCCCCC   II R  T N E  N O C━┪┙┩┘┫┖┪┕┕┨┨──┧┧┧┧┧┧┧───┨┨┕┪┪┖┫┘┩┩┙┪━C O N C E NN  TT   RRRRRR   TT NN E CC N O C━┪┙┩┩┘┫┖┖┪┕┕┨┨┨┨─────┨┨┨┨    //
//    ┪┩┘┫┖┪┪┕┨──┧┧└└└└└└└└└┧┧─┨┨┕┪┖┫┘┩┙┪━CO N C EN TT R  I   CCCCCC   I  R  T N E CN O C━┪┙┩┘┫┖┪┪┕┨┨───┧┧┧┧┧┧───┨┨┕┪┪┖┫┘┘┩┙┪━C O N C  E NN  TTT      TTT  NN  E C  N O C━┪┙┩┩┘┫┖┖┪┕┕┨┨┨────────┨┨┨    //
//    ┪┩┘┫┖┪┪┕┨──┧┧└└└└└└└└┧┧┧─┨┨┕┪┖┫┘┩┙┪━CO N C E N T R  II   CCCC   II  R  T N E C  O C━┪┙┩┘┫┖┖┪┕┕┨┨────┧┧────┨┨┨┕┪┪┖┫┘┘┩┙┪━C O  N C  E  NN    TTTT    NN  E  C N OO C━┪┙┩┘┘┫┖┖┪┕┕┨┨┨─────────┨┨┕    //
//    ┪┙┘┫┖┪┪┕┨──┧┧└└└└└└└└┧┧┧─┨┨┕┪┖┫┘┩┙┪━CO N C E N T R  II    CCC   II  R  T N E C N  C━┪┙┩┘┘┫┖┪┪┕┨┨┨─────────┨┨┕┕┪┪┖┫┫┘┩┙┪━━C O N  C  EE  NNNNN NNNNN  EE  C NN O C━━┪┙┩┘┫┫┖┪┪┕┕┨┨────┧┧┧────┨┨┕    //
//    ┪┙┩┫┖┖┪┕┨──┧┧└└└└└└└└┧┧┧─┨┨┕┪┖┫┘┩┙┪━C  N C E N T RR II          II  R  T N E C N O C━┪┙┩┘┫┖┖┪┕┕┨┨┨───────┨┨┨┕┕┪┪┖┫┫┘┩┙┪┪━C OO N  CC EEE          EE  CC  N OO C━┪┙┙┩┘┫┖┖┪┕┕┨┨───┧┧┧┧┧┧┧───┨┨┕    //
//    ┪┙┩┘┫┖┪┕┨──┧┧┧└└└└└└└┧┧──┨┨┕┪┖┫┘┩┙┪━C ON C E N T  R  II         II  R  T N E C N O C━┪┙┩┘┫┫┖┪┪┕┕┨┨┨┨┨──┨┨┨┨┕┕┕┪┖┖┫┫┘┩┙┙┪━CC O  N  CC   EEEEEEEEE   CC NN OO C━━┪┙┩┘┘┫┖┪┪┕┕┨┨──┧┧┧┧┧┧┧┧┧───┨┨┕    //
//    ┪┙┩┘┫┖┪┕┨┨─┧┧┧└└└└└└└┧┧──┨┨┕┪┖┫┘┩┙┪━C O  C E N TT R  III       III  R  T N E C N O C━┪┙┙┩┘┫┖┖┪┪┕┕┕┨┨┨┨┨┨┨┨┕┕┕┪┪┖┖┫┫┘┩┙┙┪━━C  O  NN  CCC       CCCC  NN OO CC━┪┙┩┩┘┫┖┖┪┕┕┨┨──┧┧┧┧┧└└┧┧┧┧┧──┨┨┕    //
//    ┪┙┩┘┫┖┪┕┨┨──┧┧└└└└└└└┧┧──┨┨┕┪┖┫┘┩┙┪━C O N  E NN T RR  II       III  R  T N E C  N O C━┪┙┩┘┘┫┖┖┪┪┕┕┕┕┕┨┨┨┕┕┕┕┪┪┪┖┖┫┘┘┩┙┙┪━━CC OO  NN    CCCCCC    NN  OO CC━┪┪┙┩┘┘┫┖┪┪┕┕┨───┧┧┧└└└└└└┧┧┧───┨┕┕    //
//    ┪┙┩┘┫┖┪┕┕┨──┧┧┧└└└└└┧┧┧──┨┨┕┪┖┫┘┩┙┪━C O N C E N T  R  IIII    III  RR  T N  E C N O C━┪┙┙┩┘┘┫┖┖┪┪┪┕┕┕┕┕┕┕┕┪┪┪┪┖┖┫┫┘┘┩┙┙┪┪━CC  OO  NNNN       NNN   OO CC━┪┪┙┩┩┘┫┖┖┪┕┕┨┨──┧┧┧└└└└└└└└┧┧┧──┨┨┕┪    //
//    ┪┙┩┘┫┖┪┪┕┨──┧┧┧└└└└└┧┧┧──┨┨┕┪┖┫┫┘┩┙━C O N C E N TT RR  IIIIIIIIII  RR  T N  E C N O CC━┪┙┩┩┘┘┫┖┖┖┪┪┪┪┪┪┪┪┪┪┪┖┖┖┫┫┘┘┩┩┙┙┪┪━CC  OOO   NNNNNNNNN   OO  CC━━┪┙┙┩┘┘┫┖┪┪┕┕┨──┧┧┧└└└└└└└└└└┧┧┧──┨┕┕┪    //
//    ┪┙┩┘┫┖┖┪┕┨┨──┧┧┧┧└└┧┧┧┧──┨┨┕┪┖┫┫┘┩┙┪━CO N C E NN T  RR  IIIIIIII   RR TT NN E C NN O C━┪┪┙┩┩┘┘┫┫┖┖┖┖┪┪┪┪┪┖┖┖┖┫┫┫┘┘┩┩┙┙┪┪━━CC   OOO           OOO  CC━━┪┪┙┩┩┘┫┫┖┪┪┕┨┨──┧┧┧└└└└└└└└└└└┧┧──┨┨┕┪┖    //
//    ━┪┙┩┘┫┖┪┕┨┨──┧┧┧┧┧┧┧┧┧┧──┨┨┕┪┖┖┫┘┩┙┪━C O N C E N TT RR    IIIII   RRR TT NN E CC N O  C━┪┪┙┩┩┘┘┫┫┫┫┖┖┖┖┖┖┖┖┫┫┫┘┘┘┩┩┙┙┙┪┪━━CC   OOOO       OOOO   CC━━┪┙┙┩┘┘┫┖┖┪┪┕┨┨──┧┧┧└└└└└└└└└└└┧┧┧─┨┨┕┪┪┖    //
//    ━┪┙┩┘┫┖┪┕┕┨┨──┧┧┧┧┧┧┧┧───┨┨┕┪┖┖┫┘┩┙┪━C O N C E NN T  RRR          RR  TT NN E  C N  O CC━┪┪┙┙┩┩┘┘┘┫┫┫┫┫┫┫┫┫┘┘┘┘┩┩┩┙┙┪┪┪━━CCC   OOOOO   OOOOOO  CCC━━┪┙┙┩┘┘┫┫┖┪┪┕┨┨──┧┧┧└└└└└└└└└└└┧┧┧─┨┨┕┪┪┖┫    //
//    ━┪┙┩┘┫┖┪┪┕┨┨───┧┧┧┧┧┧┧───┨┕┕┪┖┖┫┘┩┙┪━C O N C EE N  T  RRR        RRR  TT NN E  C NN O  C━━┪┪┙┙┩┩┩┘┘┘┘┘┘┘┘┘┘┘┩┩┩┩┙┙┙┪┪━━━CCC   OOOOOO  OOOOOO   CC━━┪┙┙┩┩┘┫┫┖┖┪┕┕┨┨──┧┧┧└└└└└└└└└└┧┧──┨┨┕┪┪┖┫┘    //
//    ━┪┙┩┘┫┫┖┪┕┕┨┨───┧┧┧┧┧───┨┨┕┕┪┖┖┫┘┩┙┪━C O  N C E NN TT   RRRRRRRRRRR  TT  NN EE C  N  O  C━━┪┪┪┙┙┙┩┩┩┩┩┩┩┩┩┩┩┙┙┙┙┪┪┪━━━CCC   OOOOO      OOOO   CC━━┪┪┙┙┩┘┘┫┫┖┪┪┕┕┨┨──┧┧┧└└└└└└└└┧┧┧──┨┨┕┪┪┖┫┘┩    //
//    C━┪┙┩┘┫┖┪┪┕┨┨┨────┧─────┨┨┕┕┪┖┖┫┘┩┙┪┪━C O N C EE NN TT   RRRRRRRR   TTT  N  EE CC NN OO  CC━━┪┪┪┙┙┙┙┙┙┙┙┙┙┙┙┪┪┪┪━━━CCC   OOOO           OOOO  CC━━┪┪┙┙┩┘┘┫┫┖┪┪┕┕┨┨───┧┧┧┧┧└┧┧┧┧┧───┨┨┕┪┪┖┫┘┩┙    //
//    C━┪┙┩┘┫┖┖┪┕┕┨┨─────────┨┨┨┕┕┪┖┖┫┘┩┙┙┪━C O N  C E  NN TTT           TTT  NN  E  CC NN  OO  CC━━━┪┪┪┪┪┪┪┪┪┪┪┪┪━━━━CCC   OOOO     NNNNNN     OOO  CC━━┪┙┙┩┩┘┫┫┖┖┪┕┕┨┨┨───┧┧┧┧┧┧┧┧───┨┨┕┕┪┖┖┫┘┩┙┪    //
//    C━┪┙┩┘┘┫┖┪┪┕┕┨┨┨──────┨┨┨┕┕┪┪┖┖┫┘┩┩┙┪━C OO N C  E  NN  TTT       TTTT  NNN EE  CC  N  OOO  CCC━━━━━━━━━━━━━CCCC    OOO    NNNNNNNNNNNNNN   OOO  CC━┪┪┙┙┩┘┘┫┫┖┪┪┕┕┕┨┨──────────┨┨┨┕┕┪┪┖┫┘┘┩┙┪━    //
//     C━┪┙┩┘┫┖┖┪┪┕┕┨┨┨┨───┨┨┨┨┕┕┪┪┖┖┫┘┩┩┙┪━CC O N  C EE  NN   TTTTTTTTTT   NNN  EE  CC  NN  OOO   CCCCCCCCCCCCCC    OOO    NNN              NNNN  OO  CC━┪┪┙┩┩┘┘┫┫┖┖┪┪┕┕┕┨┨┨┨┨┨┨┨┨┨┕┕┕┪┪┖┫┫┘┩┙┙┪━C    //
//     C━┪┙┩┘┘┫┖┖┪┪┕┕┨┨┨┨┨┨┨┨┨┕┕┕┪┪┖┫┫┘┩┩┙┪━━C O  N CC EE  NNN             NNN  EE  CCC  NN   OOO               OOOO    NNN    CCCCCCCCCCCCCC   NNN  O  CC━┪┪┙┙┩┘┘┫┫┖┖┪┪┪┕┕┕┕┕┕┕┕┕┕┕┪┪┪┖┖┫┘┘┩┙┪━━C     //
//     C━┪┙┙┩┘┫┫┖┪┪┪┕┕┕┨┨┨┨┨┨┕┕┕┪┪┖┖┫┫┘┩┩┙┪━━C OO NN CC EE   NNNN      NNNNN   EE   CC   NN   OOOOO        OOOOO    NNN   CCCC      EEEE     CCC  NN  OO  C━━┪┪┙┩┩┘┘┫┫┖┖┖┪┪┪┪┪┪┪┪┪┪┪┖┖┫┫┘┘┩┙┙┪━C OO    //
//      C━┪┙┩┩┘┫┫┖┪┪┪┕┕┕┕┕┕┕┕┕┕┪┪┪┖┖┫┫┘┩┩┙┪┪━C  O  N  CC  EE    NNNNNNNNN    EEE   CC   NNN    OOOOOOOOOOOOO    NNN   CCC    EEEE         EEEE  CCC  N  OO CC━━┪┙┙┩┩┘┘┫┫┫┖┖┖┖┖┖┖┖┖┖┫┫┫┘┘┩┩┙┪━━C O N    //
//    O C━┪┙┙┩┘┘┫┖┖┖┪┪┪┕┕┕┕┕┕┪┪┪┪┖┖┫┫┘┘┩┩┙┪┪━CC OO NN  CC  EEE            EEEE   CCC   NNNN     OOOOOOOO     NNN   CCC   EEE    NNNNNNNNNNN   EEE  CC  N  O  CC━┪┪┙┙┩┩┩┘┘┘┫┫┫┫┫┫┫┫┘┘┘┩┩┙┙┪┪━C  O N     //
//    O CC━┪┙┩┩┘┘┫┫┖┖┪┪┪┪┪┪┪┪┪┪┪┖┖┖┫┫┘┘┩┙┙┪┪━CC OO  NN  CC   EEEEEEEEEEEEEE    CCC    NNNN       OO       NNNN   CC   EE   NNNN             NNN  EE  CC NN  O  CC━━┪┪┙┙┩┩┩┩┘┘┘┘┘┘┩┩┩┩┙┙┪┪━CC OO N C    //
//                                                                                                                                                                                                     //
//                                                                                                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CNMCH is ERC721Creator {
    constructor() ERC721Creator("Concentric Mechanisms", "CNMCH") {}
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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