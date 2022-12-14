// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC721Creator is Proxy {
    
    constructor(string memory name, string memory symbol) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x2d3fC875de7Fe7Da43AD0afa0E7023c9B91D06b1;
        Address.functionDelegateCall(
            0x2d3fC875de7Fe7Da43AD0afa0E7023c9B91D06b1,
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

pragma solidity ^0.8.0;

/// @title: Demics
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                                                           //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWWWWWWWWWMMMMMMMMMMMMMWWWWWWWWWMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWWWMWWWWWWWWWWWWWN0xdooodk00OkkkkOKNWWWWWWWWWWWWWWWNNWWWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWNXXXNWWWWWWWWWWWWWWWWWN0c.       ...    ..l0WWWWWWWWWWWWKo;;;coxOKNWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWNX0OOOkxo:'.',coxOXNWWWWWWWWWNN0;                   cKWWWWWWWWWN0;       ..;lxOKXXNNNNWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWMMWMMMMMMWWWWWWNO:...             .'cONNNNNNNNNXo.                   :KNNNNWNNNN0;             ..',,,,;lkXWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWNXKXWWWWWWWWWWWWNx.                    ,ONNNNNNNXO,                    :KNNNNNNNNXl                       .dNWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWNKkl;..'oKWWWWWWWWWNK;                      cKXXXXXOl.                     ;0NNNNNNNN0;                        lXWWWWWWWWWWWWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWNNKkddo:.      .oXWWWWWWNNN0,                      .dXXXXO;                      .lKXXXNNXNXx.                       .kNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWNNNNXOl.             ;0NNNNNNNNNKc                       ;OKKKo.                       ;0XXXXXXXKc                        :KNNNNWWWWWWWNXKK0OOOOOKXNWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWNX00O0000Oxl;.               .xXNNNNNNNXXd.                      .dKK0c                        .dXXXXXXXKc                        cKXNNNNNNNXOo;'....   ..,colc::o0WWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWKx:'........                    ;0NNNNNNXXXO,                      .l00k,                         cKXXXXXXXOo,.                    .oKXXNNNNXx;.                    ;0NWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWNk,                               .dXXXXNXXXXKc                       ,k0x'                         :0XXXXXXXXKKx,                   ;OXXXXXX0c.                       :ONNNWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWNk'                                 ,kXXXXXXXXKd.                      .o0d.                         :0XXXXXXXXXKx.              ...'lOXXXXXXO;                          .ckKNNWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWNd.                                 .oXXXXXXXXKd.                       ;o;                          c0XXXXXXXXXKl              'dO00KXXXXXXO;                              'l0NWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWNN0;                                  :0XXXXXXXKl                                    ..              .oKXXXXXXXXXO;             .o0KKKXXXXXX0c                                 ,kNWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMWWMMMWWWWWWWNNNNO;                                 ;OXXXXXXX0;                                   .ol.             .xXXXXXXXXXXk'             ;OKKKXXXXXXKo.                                  :KNWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWWWWWWWNNNNNXx.                               'xXXXXXXXX0:               .;.                 'xo.             ,OXXXXXXXXXKd.            .o0KKXXXXXXXk'                                   ;0NNNWWWWWWWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWNNNNNWWWNNWWWWNNNNNNXXKl.                       ..',;;lOXXXXXXXXXKc               .l:                 ,xl.             c0XXXXXXXXX0:             'kKKXXXXXXXO;                                   .oXNNNNWWWWWWWWWWWWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWWWWWWWWWNKOkdc;';clol::lxk0XNNNNXXXX0c.                  .;ldkO0KKKXXXXXXXXXXXKo.              .ld'                ,xl.            .oKXXXXXXXXXx.             c0KXXXXXXXKl.              .....                c0XXNNNNNNNXOdlc::cox0XNWWWWWWWWWWWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWWWWWWWNXOo;..               .:kKXXXXXXK0c.                ;xO000KKKKXXXXXXNNXXXXXO:              .dkc.               ,xx'            'kXXXXXXXXXKl             .dKKXXXXXXKo.              ,okkkd,              ;OXXXXNNNXOl'.        .,:ldxk0XNWWWWWWWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWWWWWWWWNKx;.                     .;x0XXXXKKO:               .o00000KK0kddddkKXNNXXXXX0d,            'xOx'               :kx,            ,OXXXXXXXXX0:             ,OKXXXXXX0l.              :kOO0OOx;            .lKXXXXXX0l.                  .'o0NWWWWWWWMMMMMMMMMMM    //
//    MMMMMMMMMMWWWWWWWNNXk;                           ,o0KKKKKOl.              'oxdlc::,.    .oXNNNXXXXXKO;           .lOOc.             ,xOd.            ,OXXXXXXXXX0:             lKXXXXXXKo.              ;k000000d'            .dKKXXXXO:                       .lONWWWWWWWMMMMMMMMM    //
//    MMMMMMMMWWWWWWNNXKOo.                              ,xKKKKK0l.               .            ,0NNNXXXXXXO;            ;kOx'            ,xO0d.            .xXXXXXXXXXKl            .xKKXXXXXk,              .d000000x'             :OKKKK0d'                          .c0NWWWWWWMMMMMMMM    //
//    MMMMMMMWWWWWXOl;,..                                 .dKKKKKO:                            .xXNNXXXXXXO,            'x0Ol.          .d000k;.           .oKXXXXXXXX0c            ;OKKXXXXKl.              :OKKKKK0:            .cOKKKOo,                              ,kNNWWWWWMMMMMMM    //
//    MMMMMMWWWWWKl.                                       'xKKKKKk;                            lKNNNNXXXX0:            ,k00k;          ,k0000o;.           :0XXXXXXXKl.           .lKKKKKKKd.              .dKKKKKKKo.         .;x0KKkc.                                 ;0NNWWWWWMMMMMM    //
//    MMMMMWWWWWNd.                                         ;kKKKKKk,                           ;0NNNXXXXX0:            'x000kc.        ,k0000Ox;           'kXXXXXXKx.            'kKKKKKOc.               ;OKKXXXXXKkl;'....,cx0KKKO:                                   .dXNWWWWWMMMMMM    //
//    MMMMWWWWWWNk'                                          :OKKKK0o.                        .,xXNNNNNXXXKo.           .o0000k;        ,kK00K0Oc           .dKXKKXK0:             c0KKKK0c.               .dKXXXXXXXXXXXKK000KXXXXKK0;                                    cXNNWWWWWMMMMM    //
//    MMMMWWWWWNNXl                                           cOKKKKx.                 .:oxxxxk0XNNNNNNXXXXx.           'x0000x'        :0KKKK00d.           c0KKKKKx.            'xKKKKKO,               .o0XXXXXNNNNNNNNNXXXXXXXXXXO;                                    cKNNWWWWWMMMMM    //
//    MMMMWWWWWNNNO:.                      .....              .o0KKKO;                ;k0KKKXXXXXXNNNNXXXXXO,          ,x00000o.        :0KKKKKK0o.          ;OKK00k;            .l0KKKKK0:              ,xKXXXXNNNNNNNNNNNNNNNXXXXXKl.                .                  .dXNNWWWWWMMMMM    //
//    MMMMMWWWWNNNNKd,                   .:dxkkxl'             'xKKKKx,               :O0KKKKXXXXXXNNNXXXXXKo.         ,k0KKK0o.        :0KKKKKKXKx:'.       ,Okc,..             'kKKKKKKKo.           .lOKXXXNNNNNNNWWWWWNNNNNNXXXKd.              .:oddl'              .lKNNNWWWWWMMMMM    //
//    MMMMMWWWWWNNNXX0o'                  :kOOO0Okl'            ;OKKKKkc'..           .o0KKKKXXXXXKOxddOKXXXO;          ,xKKKKx'       .oKXXXXXXXXXK0d.      ck;                 .,lkKKKKk,           'd0KXXXXNNNNWWWWWWWWWWNNNNNXXO,             .cxOOOkd,             .lKXNNNWWWWWMMMMM    //
//    MMMMMWWWWWWNNNXXKkc.                 ,oO00000kc.           cOKKKK00Oo.           'd0KKKXXKOo,.   .l0XXKl.         .l0KKKKx'      ;0XXXXXXXXXXXX0;     'xd.                    c0KKO;           .l0KKXXXNNNNNWWWWWWWWWWWWNNNNXx.            'dOOOko,.             'dKXXNNNWWWWMMMMMM    //
//    MMMMMMWWWWWWNNNXXXKOo,                .;dO0000Oc           .oKKKKKKK0d.           .;cdxdl;.       .dKXKx.         'xKXXXXKd.    .xXXXXNNNNNXXXXO'     ;kl                    .xKKKx.           .dKKKXXXXXKXNWWWWWWWWWWWWNNNNXx.           ,x000k:.             .:OKXXNNNWWWWWMMMMMM    //
//    MMMMMMMWWWWWWNNNNXXXK0d;.               .:x0000Oc.          ;OKKKKKKK0l.                           ,kKXO;         :0XXXXXXKx,. .oKNNNNNNNNNNNNNKx:.  .d0:                   .o0KKKk'           .o0KKKKkc,.,cd0NWWWWWWWWWNNNNXO,          .l0000x.             .c0XXXNNNWWWWWMMMMMMM    //
//    MMMMMMMMMWWWWWNNNNXXXXK0kl,               .oO000k;          .xKKXKKKKKx'                           .oKX0c      .,o0XXXXXXNNNKOO0XNNNNNNNNWNNNNNNNXOolxKKc                   :0KKKK0:            ;x0Od;.      'kNWWWWWWWNNNNNXKd.          'lk00Oc.            :OXXXNNNWWWWWMMMMMMMM    //
//    MMMMMMMMMMWWWWWWNNNNXXXXKK0o.              .ck000d.         .lKXXXXXXK0o.                          .dXXX0o:,,:okKXNNNNNNNNNNNNNNWWWWWWWWWWWWWWNNNNNNXXXXOl,.            ..,o0XXXXKKd.            ...         .kNNNNNWWNNNNNXXXKl.           'o00Oo;;,.       ;OXXNNNNWWWWWMMMMMMMMM    //
//    MMMMMMMMMMMMWWWWWWNNNNXXXXKKk,               :k00k,          :0XXXXXXXXKkl,                       .l0XXXXXXXXXNNNNNNNNNNNNWWWWWWWWWWWWWWWWWWWWWWWNNNNNNXXXK0xddolcclodxxk0KXXXXXXXXO:                       .oXNNXK0KXNNNNNXXXX0l.           .o0KKKK0kl,..':xKXNNNNNWWWWWMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWWWWWWNNNNXXXXKO:.              ;k0Oc          .xXXXXXXXXXXXx.                  .,:lkKXXXNNNNNNNNNNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNNNNXXXXXXXXXXXXXXXXXXXXXXXXXX0l.                    .l0XOl'...,coxddOKXKKO,            'kKKKKKXXK00KXNNNNNNWWWWWWMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWWWWWWNNNNXXXX0l.              ,dOk;          ;OXXXXXXXXXX0:                .lOKXXXXXNNNNNNNNWWWWWWWWWWWWWWWWWWWWMMMMMMMMMMMMMWWWWWWWWWNNNNNNNNNNXXNNNNNNNNNNNNNNNXXXX0d;.               .ckKKd'           'kKKKO;            .l0KXXXXXXXNNNNNNNWWWWWWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWWWWWWNNNNXXXKk;              .cd;          .oKXXXXNXXXXXk,              ;xKXXXXNNNNNNWWWWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWNNNNNNNNNNNNNNNNNNNNNNNNNXXXKd.             ,xKXOc.           .:OKK0d.             .dXXXXNNNNNNNWWWWWWWWWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWWWWWNNNNXXXX0l.                           ;0XXNNNNNNNXX0o;'..';cooooox0XXXNNNNNNWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNNNXXKl.  .,;::,..,oOKXXx'           .l0KKOl.              'kXXXNNNNNWWWWWWWWWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWWWWWWNNNNXXXKd'                         .oKXNNNNNNNNNNNXXK00KKXXXXXXXXXNNNNNWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNNNXXOxkOKXXXK00KXXXXXKkc.         c0K0x;               'xXXNNNNNWWWWWWWWWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWWWWWWNNNXXXK0o'                      ,xKXNNNNNNNNNNNNNNNNXXXXXXXNNNNNNNWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWMMMMMMMMWWWWWWWWWNNNNNNNXXXXXXXXXXXXXXXX0:         'll;.              .cOXXNNNNWWWWWWWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWWWWWNNNXXXXKk;                    .xXXXNNNNWWWWWWWNNNNNNNNNNNNNNNNWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWNNNNNNNNNNNNNNNNXXXXXK:                          .:kKXXNNNNWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWNNNXXXKO;                   ;OXXNNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWNNNNNNNNNNNNXXXd.                       .;xKXXXNNNNWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWNNNNXXXk;                  ;0XNNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWWWNNNNNNXKd'                     ,dKXXXNNNNWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWNNNNXXXk;                .oKXNNNWWWWWWMMMMMMMWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWNNNNXX0d;.                'o0XXXXNNNNWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWNNNXXXOl.             .oKXNNNNWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWNNNNXXKkl;..   ..,,,,:lx0XXXNNNNNWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWNNNNXXKkl,..'..     .dKXNNNNWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWNNNNNXXXK0kddxk0KKKKXXXXXNNNNNWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWNNNNXXXK0000x:,';lOXNNNNWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWNNNNNNXXXXXXXXXXXXXNNNNNNNWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWNNNNNXXXXXXXKKXXNNNNNWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWNNNNNNNNNNNNNNNNNNNNWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWNNNNNNNNNNNNNNNNNWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWNNNNNNNNNNNWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWNNNNNNNNWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWMMMMMMMWWWWWWWWWWWWWWWWMMMMMMMMMMMMM                                                                                                                                                                                       //
//                                                                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract mvzi is ERC721Creator {
    constructor() ERC721Creator("Demics", "mvzi") {}
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