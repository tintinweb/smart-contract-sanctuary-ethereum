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

pragma solidity ^0.8.0;

/// @title: The Drowned World
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXXXXXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOxolcccccccccccccodkKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOdl:cccloxO0XNNWWWNNK0kxlcccccldxOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkocccclxOXWMMMMMMMMMMMMMMMMMMMMWX0kxolcccccldk0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOxoccccokKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0kdl::ccclok0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOdc::cldkKWMMMMMMMMMMWNKOkxolccOWMMMMMMMMMMMMMMMMMMMMMMMMWXKOxl::cclkXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOdl:;;cd0XKkolldKWWXKOkdl:,...';;:;:OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXOoc;cdKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXxc:;;okKWMW0c';o:'ckd,'',;co;  ,ONWMMMMMMMMMMMMMMMMMMMWXOxollodOXWMMMMMMMMMMWXx:,oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOc;co:,,,c0WMK; cNMWNWWKkk0XWMWl .kMMMMMMMMMMMMMMMMMMMNOo;.  .;cc;..:xXMMMMMMMMMMMNOc,oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx:;dKXl .ok,.kWX: cXMMMMMMMMMMMM0' :XMMMMMMMMMMMMMMMMMXx,. .;dONWMMNl   ;KMMMNOxKWMMMMWO:,oXMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMXd;:xNMMO. ;KM0',KMKo;;lONMMMMMMMMWo .kMMMMMMMMMMMMMMMMNx'  ,dKWMMMMMMMXd:cxNMNO;  ,0MMMMMMWk;;OWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMXo..dNMMMMo .kMMWc.xMMMNOo;;xNMMMMMMK, cNMMMMMMMMMMMMMMM0;  'xNMMNK0KNMMMMMMMMWO:. ,oONMMMN0KWMXc'oNMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMNx,,:'oWMMMWl :NMMWc.xMMMMMMX;.xMMMMMMd..OMMMMMMMMMMMMMMM0, .cXMMMM0:..'cONMMMWKc..;kNMMMMXd'..oNMNk,;OWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMM0:.lXWl.xWMMMx.cWMMX;.kM0xKXk:.;KMMMMMX: ;XMMMMMMMMMMMMMMMd  :XMMMMMMXc   .dWMXo. ,kNMMMWKo'    .;d0WXl,lKMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMNx,;OWMMX;;XMMMNc'kWNo.cNWx;cl:lkNMMMMMMNo.lNMMMMMMMMMMMMMMMk. '0WMMMN0o, .cxKWO, 'xNMMMNOc..cxOOOkl..cKW0:,dNMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMXl'dNMMMMMx'xMN0OKo:l:;l0XXK0OOOOOOOOOO0000O0XNWWMMMMMMMMMMMMWk, .cdoc'   ;OWMNo. cKMMMNx;.  :O0OOkkl. .kMMNk;;OWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMM0:,kWMMMMMMk.'lc;cxxdlclxkkOOOOxooolodxxxxxxxxxxkkkkkkkkOO0KXNWMNx:'..';cokNMMXc .oNMMNx'.''  ..'...',:o0WMMMMXl'dNMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWk,:0MMMMMMMNo. .:lloxOKKXWMMMMMMWWWNXWMMMMMMMMWNXNWWNXK0OOkkdxkkkxxkxxOXWMMMMMMK:,xNMMK; 'kNK, ;0KKKXNWMMMMMMMMMWx'cXMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMNd'oNMMMMXkoccclxOXWMMMMWWNXXK0OOkkkOOkkkkkOOO00KKXXNWWMMMMMMMXXMWNK0kxdolodk0KNWWNNMMMMXdoKMMX; cNMMMMMMMMMMMMMMMMWO,;KMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMXl'dWMMNOc:clxKWMMNK0kdoc:,'''''''',,;:::::::::cclccccc:::cloddxO0KNWMMMMW0OKOOxdkO00KNMMMMMMMMX; :XMMMWN0xdlccclc:kWM0,,0MMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMXc.xWWKd,;cl0WXOdl;'...';:lodkOOO000OOOOOOOO00000KKKKKK0Okxdolcc:;;;;;:cldxOKWWNWWWNKl:oodk0NWMMW0kXKxdlcc:clodxxddd0WMMK;,OWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMK:.oNO:..'''cKd...':odkOOkxolc:,'......        .......',,;:cloddxkO00Okxolc:;c0MMMMMMNk00oxxooodONMMWk,..;OWMMMMMMMMMMMMMMX:'kWMMMMMMMMMMM    //
//    MMMMMMMMMMMX: cKx. ,xc;o0k.,xOOko:,..                                          ..';cloxO00XWMMMMMO;;okKNMN0dodod0WWKklcoOWMMMMMMMMMMMMMXc'kMMMMMMMMMMM    //
//    MMMMMMMMMMWo '0x..dd;..,l' ,c,.                                                         ..',coxOX0l;,''';lx0NXo;cloONMNKXWMMMMMMMMMMMMMMX;,KMMMMMMMMMM    //
//    MMMMMMMMMMX; l0, .'. .cl.                                                                       .,:ok0Oxl;..';lkKKd;;dOXMMMMMMMMMMMMMMMMMx.oWMMMMMMMMM    //
//    MMMMMMMMMMO.'Oo...  .dx'                                  .',;:cllolllcc:;,,'...                     .;cdOOOd:'..;lclkc'lOWMMMMMMMMMMMMMMK;;XMMMMMMMMM    //
//    MMMMMMMMMMk.:0; .  .xl.                             .,cdkOXNWMMMMMMMMMMMMMWWWNX0Okdl:;'..                 .;lxOOd:'..:, .';dXMMMMMMMMMMMMWl.kMMMMMMMMM    //
//    MMMMMMMMMMx.:0,    ll                             .oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXOxl:'.               .,lk0kl'  ..  :dOWMMMMMMMMMMd.dMMMMMMMMM    //
//    MMMMMMMMMMO.'kc   .:. ...                       .oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKOxo:,.             .:dOkc.    'clOWMMMMMMMMd.dMMMMMMMMM    //
//    MMMMMMMMMMNo.:d.      .kd.                     .kWMMMMMMMMMMMMMWWNNNNWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMWKOdc,.           .;okd,  .c,'oKMMMMMMMd.dMMMMMMMMM    //
//    MMMMMMMMMMMNl.lo       ;c.                    .xWMMMMMMWNK000KKXKOkO0KKKKKXXXXXKKKKXXXWMMMMMMMMMMMMMMMMMWKx:.           .ckx, .'..'OWMMMMMo.xMMMMMMMMM    //
//    MMMMMMMMMMMMX;'kl       .:.                   cNMMMMNOk000KKNWMMMMMMMMMMMMMMMWWNXXKKK000O0KNMMMMMMMMMMMMMMMWXxc.          .:xl.    .kMMMMWc.OMMMMMMMMM    //
//    MMMMMMMMMMMMWc.xX;       ';,.                ;KMMMWk,.',,;:clox0NMMMMMMMMMMMMMMMMWNK0OOkoldO0O0NMMMMMMMMMMMMMMWKc  'l;      .oo.    lWMMMX:,KMMMMMMMMM    //
//    MMMMMMMMMMMMWc.ON:       'ol'               '0MMNO:.            .oXMMMMMMMMMMMWOc,.........':odxk0NMMMMMMMMMMMMMN: dMX;      ;l.    ;XMMMO.lWMMMMMMMMM    //
//    MMMMMMMMMMMMK,;XKc...                      'OMW0:    .oOOx;  ... .dWMMMMMMMMMMWk:,;okOKXX0Od:',ldxdxXMMMMMMMMMMMMk.cWMd.      ::.   ,KMMNc'OMMMMMMMMMM    //
//    MMMMMMMMMMMMx.cW0xc'. .'.                 .dWMK;    ;0WN0dc',dkOOOXMMMMMMMMMMMMMKl,l0WMMMMMMWKo..:xxdx0NMMMMMMMMMN:,KMK,      .cc.  ;XMMO.cWMMMMMMMMMM    //
//    MMMMMMMMMMMWc dMOxl;' :Kk;.               ;XMMNc   ,O0l;:cdOOkxxONMOlOWMMMMMMMW0::dKNMMMMWXWMMMK: .xNKxdkXMMMMMMMMd'kMWk.      .dd. lNMWl.kMMMMMMMMMMM    //
//    MMMMMMMMMMMN: dWkdl;' ,0MWd               dMNXX:   ;:.  .':loc:lONMK;.dWMMMMMMW0O0dc:ccc:,.,oONMNd':0WMXxlkWMMMMMMk.lWMWd      .kW00NMMK,:XMMMMMMMMMMM    //
//    MMMMMMMMMMMN:.dMxl:.. .kMMk.             ,KNodXc       ;OXXKOxo',OWMd ,KMMMMMMMMX; .d0Oxol'  .;kX0O0XWMMM0cdWMMMMMX;:NMM0'     ,KMMMWMMd.dMMMMMMMMMMMM    //
//    MMMMMMMMMMMN: dMO;.   cNMM0'             lNd:0Mk. .'. .c0k:;:lKXdOWWl .OMMMMMMMMNo:ONx,..lO:   ;0XWMMMMMMMk:OMMMMMWd;0MMWl     lWMMXXMK;,KMMMMMMMMMMMM    //
//    MMMMMMMMMMMWl cNX;   .OMMMK,            .kK:oWMx..dN0l:cxO0KXXWMMMWk. .OMMMMMMMMMMWMNOdood0OlccxXMMMMMMMMMNcoWMMMMM0:xMMMx.   .xMMWKKWo.xMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMk..kWo  .xWMMM0'            :Xx,kMMk. dMMMMMMMMMMMMMMMK;  lNMMMMMMMMMMMMMMMMMMMMMMMNNMMMMMMMMMMdcXMMMMMX;cNMMO.   '0MMNKNk.lNMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMNo.'00' :XMMMMx. ..         oMo,0MMx. lWMMMMMMMMMMMMMMk. cXMMMMMMMMMMMMMMMMMMMMMMMMXXMMMMMMMMMMdcXMMMMMWc.OMMO.   cNMMXXK;,KMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMNl..c. .xWMMNc .ol         dMo,0MMx. lWMMMMMMMMMMMMMX; '0MMMMMMMMMMMMMMMMMMMMMMMMMKxXWWMMMMMMMocXMMMMMMd.oWMd.  .xMMWKXd.dWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMNx,    cNMMK,.c0O.        dMo.xMMx. cWMMMMMMMMMMMWOc.  :KMMKxdoo0WMMMMMMMMMMMMMMMWOloONMMMMMNccNMMMMMM0';X0'   :XMMKxo';XMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMNx;  dMMMk.:NNl         :Nk.cXKc  :NMMMMMMMMMMMO,ox.  .kK:    lWXNMMMMMMMMMMMMMMWO,.:kKXXNk.cWMMMMMMNc.kl   .OMMNO; .OMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMN:.dMMMk.,K0'         .kNo;l,   lWMMMMMMMMMMMKcdXo,;cON0dlcoKXkKMMMMMMMMMMMMMMMMNkc:lo:dd.cWMMMMMXk:.cc  .xWMWXo. dWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMd.dMMMx.'0k.          cNWNNc  '0MMMMMMMMMMMMMWNWWWMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMNdxo cWMMMMMx.. .. .oWMWXx' ;KMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMx.oMMMk..Ok.          ,KMMMk. :NMMMMMMMMMMMMNOlok0KNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKdx: ,KMMXkOo      lNMMWk, .dWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMK,:NMMK,.d0'          ,KMMMK,.dWMMMMMMMMMMNx,    ..':ooddlcd0NMMMMMMMMMMMMMMMMMMMMMWxox. .xMMk...     lNMMMXl'..OMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWc.OMMWc lNc          .OMMMWc'0MMMMMMMMMMWo.  ,ldxxxdddlc:'..,dXMMMMMMMMMMMMMMMMMMM0:o:   dMNc      .oNMMW0lx0;'0MMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMd.dMMMk..Ox.         .dMMMMk,dWMMMMMMMMMO.  :00OOO0O00KXXX0c. ;0MMMMMMMMMMMMMMMMM0:lc.   oW0'     .kWMWXxcxN0':NMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMK,;XMMX: c0;          ;KMMMNl;KMMMMMMMMWl   ..       ....,:;.  ;XMMMMMMMMMMMMMMMNxl;     ,kc     ;0WMNKo:kWX:.kMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWo.xMMM0'.dx.          cXMMMXodNMMMMMMMNc                       dMMMMMMMMMMMMMMW0l.            .oNMWNOc:OWX:.dWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMM0,:XMMMk.'ko.          ,kNMMXooXMMMMMMMd.:kkd;.                :NMMMMMMMMMMMWO:.         .,'.;0WMW0d;.:xk;.cNMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWx.oWMMWO',kd.        .;.':cxO:cXMMMMMMx,dkc,.  .',.           lWMMMMMMMMMMKc..;.      .;ccoONMWXx:. .    ;KMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMNo.dWMMM0:'dd.       .od.   ckllolx0NMO.      .xNKl.  .;d:   .OMMMMMMMMMXd..;c'       .,:xNMMN0o'       ,0MMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMNc.dNMMMNd':d;       :KKo:c;;'    .,dd'.'.   .kKd;:xOKKx'  .xWMMMMMMMMK:.,ooll'     .cONMWN0o,       .lXMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMk..cXMMMW0:,oo.   .ckXMMMK,         .,.   .,kMMWWMMMNd.   lWMMMMMMMMKc,ldk0x'   .,dKWMWXOo,       ,oKWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWd.  ,OWMMMNkc:ol'  .;OMXXk.          ..  .dXWMMMWWXX0k:.';x0XWMMMMMMKc;o:;;.  'lONMMXOd:'      .;kNMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWx.    :xONMMMNOl:cc'  :l'';.          .;.  ..,:odkkkxl,......,OMMMMMWNo.:l..,oONMMWX0o'.      .cOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMM0' ,'.,,.,OMMMMMW0olc;,.                ..    .,oxxoll,        ,k0Oxl;...'cd0WMMMWXkl:'  .c, .o0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMNl.:kOx:okxk0XWMMMMNOdd:..                    ....                 ..;cd0NMMMNXKkxl,.    .Oo.dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMNO:'cxkxd:.,;ckNMMMMMWKkdl:.                                 .':lxOXWMMMMMXOo;. ':..:clood,'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWk,.,'..    .lxdkXWMMMMMNKOxoc;,'..             ....';:coxOKNMMMMWNNNKOo,..'cdOk;.,';cccd0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMNOoc:'.    .,. .cxkKWMMMMMMMMWNX0OkkxddddxxkOO0KXXNWMMMMWNWNXNNXkol;,;:oOKOo;.  .cONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0o;.  ..,cc,..':lxOKNWMMMMMMMMMMMMMMMMMMMMMMMMMNK0xolc,''..   .:xd:.     ;kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKko:;;.         ..,:cldxkOO0000000OOkxxxdxxc;,.                   .;oONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0xl:;'..                 ...   'okOkO0xd:.           .':lodxkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXKOxoc;'...              ,olcc;,'.         .;lx0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXK0Okxdolc;,'.........           .kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXKK0000000o.      ..;OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKdoodxO0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LSTGRL is ERC721Creator {
    constructor() ERC721Creator("The Drowned World", "LSTGRL") {}
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