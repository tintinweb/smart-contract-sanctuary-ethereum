// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: egg
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                                               //
//                                                                                                                                                                                                                                                                                                                                                                                               //
//    [email protected]@[email protected]@@@[email protected]@[email protected]@[email protected]@@@[email protected]@[email protected]@[email protected]@@@[email protected]@[email protected]@[email protected]@@@000000000000fLLftL,,.fGCCfGttfLtt1tfLffffffffffffLGLGGCGf1111111LGLffGC8800L888800000808C00C008Lf111111iL1;;i11tf111111111111111i111tttGLtttttfLLGG00000008CC88C    //
//    [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@0000000ffGGLfLi.itttLCfttGfLttttGLfttfffffffffGLffCGGGGt1111111CCLtG000088f00808088G88GC8CC8888ff1;i1111t111111t1111111111tt11tttftttGLfftttfLC00000000888C888    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected],,t1tftLttt1tftttttfLffffftffftfLfffCLGGGGf1ii1111GCGtt1tfG8CCGLfCLtGfL;[email protected]@[email protected]    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@000000ffCfffLLLfLfi1tftffLftttLtfftfffffffffffffCGLLLG8LCGGGGiLf;;i11CGLfLtt118if;tLGGt.,[email protected]@000000CGG88    //
//    @@@@@@@@[email protected]@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@[email protected]@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@0000008ffCffffGLGGGLLi;tf11tLf1ttLfffffLLLfffffffffGfLG8LCGLCGGGLit;;;;LLLGGLGGGLt111;8LLGf:;t81GLL8L00008ffttftttf11tttttffffffttfLffffffGCCCGCCCCCCC8000000ffLfft111i    //
//    @@@@@@@@[email protected]@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@0000LfGffffffGLGGGGGfi,1tt1LttttLfffffGLCCC8fffffGCCCCLCCCCLC8GGG1f;;;;Lt111tLGGGC:1L1iiiLffLLt.CCC8C08888LLt1fffLfffffLLLLLLLfLLLLLLffff8CCCCCGCffttt11111ii1tt1111111    //
//    @@@@@@@@[email protected]@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@00000[email protected][email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@0000000fLfffffffLGLGC80Gii;1ttLffttLfffffC0888808LfLGCCCCCCCC8CLGCGGGLt1tt;ttLGLf1ttGCG8fttt1iiiffLi8CC8C8888GLLLLLLGLLLLGLLGGGGLGGGGGLLLLLG888CCCLLfLttttt11;;i;i;11111111    //
//    @@@@@@@@@@[email protected]@[email protected]@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@0000L[email protected][email protected]@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]GGGGGCLLLftttGGGGGGLt1LLfttttttttft8C8888888CGLGGGCGLLLGGGGGCGGC88CCGGGLL80088CC0LtLfffGGGGLttt;:;i11111111    //
//    @@@@@@@@@@@[email protected]@@[email protected]@@@@@@@@@@@@@@@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@0000Gf11fLffffffLL0000000LLttLtfLC888G80000888LLGGCCLtG,fC8C8808GLGLCLLLLLffLGGGGGGGGGGL111ftttttttttC88800G8088CCGGGC888000888888C:CCC808008888GCLLCLLLLff11fGtti;11i11111    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@[email protected]@@@[email protected]@[email protected]@@@@[email protected]@[email protected]@[email protected]@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected],,GL8888000GLLGGLLLffGGGGGGGGGGGGGGGf1tfttttttttffL8000G00000088C8C0CGC8888CiG8008888888C8GGCGGLLfffff1iCt1i1i11tttt    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]888CGL8CLLLLGGGGLtGGGfCCLL001fftttC8LftfffL8008800008C8CCC8888GGGGGGCC800888888C8CCCCLf:fftLLf1tff1i111tttf    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@0000008GGGCCCCCCCC,:CCCCC0000GGGLG00880000LLCGGGCCCCLGCLLLL::888C88CCCCfi;ifLi1LCf1fCi:::8800fLtt00000fffffffCCC0800000000CCGLLftfLLCCCC008888CLLGLLGGCG11fGLf1tft1t1ttffff    //
//    @@@@@@@@[email protected]@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected];C11GGGfGCtC88001CC88CCGLLLLftti,:tGGCGGGC88LLGtttf8CCCLLLLLLLLLLLG0000ftt1111i1iiiii18CGCCC80080CCLGCCLLLLLLffGfttt1tfLLLL    //
//    @@@@@@@@[email protected]@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@88LLC88C00GCfLLLL888880L88CCCGLGLC8GGC880CCGCC88CGffffLLLCCC8808CCGGGGGGt888ftCCCCGGCCCCC888CCGfftffGGG8fGCGGGGLtt11tLf,1,f;i;iiiiii111880008GC0888CCCGGGLLLLGfftttttLLGGCL    //
//    @@@@@@@@@@@[email protected]@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@08CLL008C00LLGLLGC88C8808CGGCLfGC8GGLLG888LG888ff1GGffLLLGG8G88CCGfGGGGGGLLLCCCC888CCGCCCC8CCCCCCC8Ltff1GGLLtt1itiiiiiiiffGLf1ii111111tG000000000C88CGLLGGGLffffffttLCLLff0    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@00000000000CG000C0000888CCCGf1tLCGGGGG88CG8800G0GfftfLfGGGGGGCCGLii1GfLGfLGGCC8CCCC88888888C88C88C88tLLLLfG8C:;,[email protected]    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected];.:;;i111ttG888C8088888C8CLLCC888LLLLt1i1i1G88Ct11L111111LGC:[email protected]@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@0000:[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]:111tGG;i. ::;;;i11tGGLGGGL8CLC888000titiiffGGGL8CCC888fttGLtttffCC;[email protected]@@@@@@@    //
//    @@@@@@@@@@@@[email protected]@@@@@@@@@@0000:[email protected]@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@000000008000808888GC88808CCLGLLLC00808000CCC8C0Gtt;t1:::iG;:::::::::;ii1fC8CCC;t1f1fC00CLLLGLG[email protected][email protected]@@@@@@    //
//    @@@@@@@@@@@@[email protected]@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@008800080880800008808LLLC008000t0C8C888Gt111;iit11;;:::,,:::;;;ii1fL8;1:,ttf;ttC00GGGC888[email protected][email protected]@@@@@@    //
//    @@@@@@@@@@@@[email protected]@@@@@@@@@@@[email protected]@@@@[email protected]@@@@@@@@@[email protected]@@@@@@[email protected]@[email protected]@@@@@@@@[email protected]@@[email protected]@@@@@@[email protected]@@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@@@@@@@@[email protected]@[email protected]@@[email protected]@@@[email protected]@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@00000880CLG8800000080CLfLL880080088GC8CGft1tttt1t;;111;:;:;;1;iii1ttL88CGGf1ftffL100[email protected][email protected]@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@00           @i  [email protected]@@@@f  [email protected]@          ;[email protected]@@0          ,[email protected]@   @@@@         @@[email protected]        ,@[email protected]           00f        ,@,           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@000800888ffLG08008008LLfffC88088CC8888LLt111ttii11;11i;;;;;iiiitttL88GL11fC80ffL1G088880,0000000000000000000008888GGG80C1t88CGC88000000000000000000G000000000000000    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@   [email protected]@@@i  [email protected]@@@@f  [email protected]@   @@@@[email protected]@@@@@@0   @@[email protected] [email protected]@   @@    @@[email protected],C000    @@@@@ [email protected]   @@@@@@@00.  [email protected]@@@008  :@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@[email protected]@000C88C00ffLG0G00000GGffff8000000888LLff11iiiii111ii111iii11111G8C80[email protected][email protected]@@@@@@@@[email protected]@@[email protected]@[email protected]@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@00   [email protected]@@@i           [email protected]@         @@@@@@0         [email protected]@0   @@   @00      80   000      [email protected] [email protected]@         ,[email protected]@@8  :@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@[email protected][email protected][email protected]@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@00   [email protected]@@@i  [email protected]@@@@f  [email protected]@   @@@@@@[email protected]@@0   @00000   @0   00   [email protected]@000  [email protected] [email protected] [email protected]   @[email protected]@@@@[email protected]@[email protected]@@@C   [email protected]@@8  :@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@[email protected];;:111tfCLttC888CCCC8LLLL8800C8GC0,[email protected]@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@00   [email protected]@@i  [email protected]@@@@f  [email protected] [email protected]@@@            00   @[email protected] [email protected]           00           0           [email protected]  ,[email protected]@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@0000C0008088C880fCCGLLLLG1GLLLGCC08C8GL:,fG888CGLiiiiiiiiii11111:iii:t11fGG[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@0    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@0000000C00008:i8GGGLLLG1GLLLLf8800t.CLGCitG808Gf1i11i1i11111i;tCL1itt111;L111tt1tf88CCC888;[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@0    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@0008088C0C.8C.0GGGGGCGLLLLG88LL.GLGCCC.fGC8GGf111CfLt111GLfi1itttt:L1ttttfLtt1t1t;iLG8CG::.  [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@[email protected]@@[email protected]@[email protected]@[email protected]@@@[email protected]@[email protected]@[email protected]@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@00000080G0C0G.88G08008800CLLLC8888,,LGGG,fGG888GC8800tfLCtttttftt11111ttfLLG8G1t1;t1tt10CCC:[email protected]@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@0    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@08::::::::::00::,000L:::::::::000:::[email protected]@@0,::0L::::::::::,[email protected]:::::::::000:::[email protected]@@@0i::000000:::001:::::::::,[email protected]@@@@   00.   [email protected]@;  [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@08880LGLGG800C;G888008008808GG801G8G;..LCCC00ttL00CC001fGG1ttt1t;;itffGLC808Lttf1;[email protected]@@@@@@[email protected]@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@[email protected]@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@08::i000000000::,00:::C00000t0000:::000000,::000000::;[email protected]:::00000,:000:::[email protected]@@0i::[email protected]:::001::800000:::[email protected]@   @C.     C00;  [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@0C80LG1LfL8800088000080088888C8008G888880LtGfLtLC00C08CLLCLf111;[email protected]@@@@@@@[email protected]@@@@@@@@@@@@[email protected]@[email protected]@@@@@@@@@@@[email protected]@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@08:::::::::000::,0C::i000::::::00::::::::::::[email protected]@@00::;[email protected]@@@0:::00000000000:::[email protected]@@0i::800000:::001:::::::::[email protected] [email protected]  0G   0;  [email protected]@@@@@[email protected]@@@@@@@@@@@@@@@@@@@00GLGL800GC880000GGCGLGGGLfLfLGGC888880C818CC0CG0888G8CCG8GG1ttfLLLG80000Cf110008f1tCCCCL880CGft1ii,,i;[email protected]@@@[email protected]@[email protected]@@@@@@@@@@@[email protected]@@@@@@@@@@@@[email protected]@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@08::i000000000::,00:::[email protected]::00:::000000,::[email protected]@@00::;[email protected]@@0i:::000001t000:::00000000::,00000::,001::[email protected];::[email protected]@   @@.  [email protected] [email protected]@@@@@[email protected]@@@@@@@@@@@@@@@@@@@000tfCGCC0CCC8008GCGGG08CGLLGGGCCCCCC88001Lt;t;Ltf8CCCGGGG8ftftfLL;1LfG8LCCfG888C1tCCC88GGCCLG08ttt:[email protected]@@[email protected]@@@@@@@@@@@@[email protected]@[email protected]@@@@@@@@@@@[email protected]@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@08::[email protected]@@@@@00::,000i:::::::::L00:::[email protected]@@0,::[email protected]@@00::;[email protected]@@@000:::::::::800:::::::::100:::::::::0001::::::::::,[email protected] [email protected]  @[email protected]@0L   [email protected]@[email protected]@@@@@@@@@@@@@@@@@@@@0000fCCCCC8CCC800CCC8CLL,,,,:GC00CCCC8Cf00L[email protected]@[email protected]@@@@@@@@@@@@@[email protected]@[email protected]@@@@@@@@@@@@[email protected]@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@[email protected]@[email protected]@[email protected]@@@@[email protected]@@@@[email protected]@@@@@[email protected]@@[email protected]@[email protected]@@[email protected]@[email protected]@@@[email protected]@@@@@@@@@@@@@@@@[email protected]@@@[email protected]@@@@@@@@@@@@@@@@@@@@@[email protected],,,11:,,,t80CCLGCGG88G[email protected][email protected]@[email protected]@@@@@@@@@@@@@[email protected]@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@[email protected],:;11111t,,100GGGCCCCC[email protected][email protected]@@@@@@@@@@@[email protected]@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@[email protected]@@@[email protected]@[email protected]@@@@[email protected]@@@@@@@@[email protected]@@[email protected]@[email protected]@[email protected]@@[email protected]@[email protected]@@@[email protected]@@[email protected]@@[email protected]@@@[email protected]@@[email protected]@[email protected]@@[email protected]@[email protected]@@@[email protected]@[email protected]@@@@0008088GGC88CC808C88:,1i1111iii,,t00GGC88888[email protected]@@@@@@@@@@@@@[email protected]@[email protected]@@@@@@@@@@@@@@@@@@@@0000000,[email protected]@@@@@@@@@    //
//    @@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@0           @i  [email protected]@@@@f  [email protected]@          :@@@@0    [email protected] [email protected]          ti           @[email protected]    :@00   [email protected]@0   [email protected]          :0t          [email protected]@i          [email protected] [email protected]@@@[email protected];,1i111i111t,18008CCCGCC0CGLCGC00C8CGGG1111111111titff11tLCGfL,;[email protected]@@@@@@@@@@@@@@@[email protected]@[email protected]@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@    //
//    @@@@@@@@@@@@@[email protected]@[email protected]@@@@@@@@@[email protected]@@@@@[email protected]@00   [email protected]@@@i  [email protected]@@@@f  [email protected]@   [email protected]@@@@@@0      @00     [email protected]   @[email protected]@[email protected]@@0   [email protected]@[email protected]   8  :[email protected]   C000   [email protected]   @@[email protected]@@t  [email protected]@00   [email protected] [email protected]@[email protected]@@   [email protected]@@[email protected]@@@@[email protected]@@000fCCC8C8CC888tf,1ii111i11,,t808CC8G[email protected]@@@@@@@@@@@@@@@@[email protected]@@@@[email protected]@[email protected],[email protected]@@@@@@@@@@@    //
//    @@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@[email protected]@@@@@@@@00   [email protected]@@@i           [email protected]@         @@@@@@0   @;     @;  [email protected] [email protected]@@@0   [email protected]@@@   @08  [email protected]@@   00   [email protected]@@         000t           [email protected]        :@0         [email protected]@[email protected]@@@[email protected],:ii1i11.,,:80CCC8CG[email protected]@@@@@@@@@@@@@@[email protected]@[email protected]@@@@@                                           //
//                                                                                                                                                                                                                                                                                                                                                                                               //
//                                                                                                                                                                                                                                                                                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract egg is ERC721Creator {
    constructor() ERC721Creator("egg", "egg") {}
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