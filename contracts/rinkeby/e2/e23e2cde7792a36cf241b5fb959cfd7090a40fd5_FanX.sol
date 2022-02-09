// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                 //
//    ,:::::::;;;;iiiiii;;;:::::;::,;;:::::::::::;:::;:::::,::::::::::::::::::::::::::;:::::::::::::,:::::::::::;::,:::::;::::::::::::::::::;,::::::::::;;:::::::::::::::::::::::;;::;::::::::::,:;:::::::::::::::::::::::::::::::::::::::::::::::::;;;;;;;::::    //
//    iiiiiiiiiiiiiiiiiiiiiiiii;;;i;;;ii;;iiii;;;i;;;i;i;;i;;iii;;;;i;;;;ii;;ii;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:;;;;;;;;;;;;;;;;;;;;;;:;;;;;;;;:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;::;;;;;;;;;;:;;;:;;;;;:;;;;;;:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;::;;::;;;;;;;;;ii11i;;;;;::;:::;;;;::::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:;;;::::;;i1ttttttttffffff1i;;;;;;;::::;::::::::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;i;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;i11iiiii1tttfLfffLLLGGLLLLffffttt1111i;;;;;;::::::::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;i1ttiii111ii1t11t1ii1tt1i1tt111ii11i;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;ii1tttttffffffLLLffLGLLLGGGGLLfffttttttfffft1ttt1ii1i;;::::;:::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;111iiiiiiiii11i111ii111i111111ii1i;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;ii1tttttffttttt1ttffftfLCGffLGLLLfffftfLffftftttfLLfttffft1i;;;:::::::::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;ii111tt11ttttffttftttfLLftttfttLGCGLLGf1tfLLGLftttt11tfLLfttfftffLLfti;;:::;:::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii;;iiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;i111111111tftttttfft11fLLftt1tffLfGGGGGGftfLLfLCGLLGGfftttfLLLfLLfffLLLGffftiiii;;:;;;:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii;;iiiiiii;;;;;;;;;;;;;;;;;;;;;;;;;;;;:;;;;;111i;ii111ffttfffLfttttffft111tLGGLffLLLfttfGGGGLGGLfLLLfffftttffLLfffLLLGGLfffft1i1i;;;:;;;:::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;ii11iiiii1111tffttttttLGLt1111111tfttffttfLf111tLGLGGLfLftttffffLLtttfGCCffffLLGGLLffLft111i;;::::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;;;;;;;;iii1t1ii1ttttt1tfffffft1tttttt111ttttft11t1i11tft111tGCLLftftfLtttfftttttttfLCGttfffffLLLLLLfttt1i;:::::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;;;;iiii1ttttfffffLffLfffft11111tLGf11ttttf1111tti1tff1iiifGCLLt1ttfLftf1ttLf111ttftttfLLftttffLLGLLffffti;;:;;::;;;;:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii;;iiiiiiii;;;;;;;;;;;;;;;;;;;;;;;ii11ttfffftfttfLfGLft1iiiii1fLfitftt1tt1tt1ttf11ttti;i1fLGLL1tft11t1111tf1i1111fLfLfGGLftf11ttfLLLLfffft1i;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii;;iiii;;;;;;;;;;;;;;;;;;;;;;;;;;i1tfttftttffftffLLLfttt11iii11ii1t1t1111111ttft11ii11i11tffL1itLG1iiii1111ii1tfLLGGGGLGLLLtttt111ttffLLLLftti;:::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii;;iii;;;;;;;;;;;;;;;;;;;;;;;;;;1tfttfffttfftttfffft11tt1ii1iiii1itt1iiii1fftftttf1ii1tt1fff1;itLL11i;ittfii;itfffLLLGLLGffffttttttffffLLfffft1iii;;;;;;::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii;;ii;;;;;i;;;;;;;;;;;;;;;;;;i1ttttfffttt11ttfftttti1t1iiiii;i11tt1;iii1fGftt11tt11i1t11tLt;;;1Lfi1fi:it1;i;i1tfttffGfLGLffftttLttttfftfffffLft1;::;::::;:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiiiiiiiii;;iii;;;;;;;;;;;;;;;;;;;;;;;;;;1tffttffttttt11ff11111i11ii;;::i1i1t1iiiiiftfft1ii111ttt1i1Lf;;;i1ttitfi;ii;;11i1tt11ttGfLGLftLtttftffftttfLLfffLLfti;;::::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;;;;;;;:;;::;;;:::ii11tii111111ii1:;11i;ii111iii;;,;1i;;ii;;;;it11t1i;i111tt1iif1;i;1iit1i111ii;;1tt111t1i11fffGLf1tttttt1t1t1i1fLf11tttft11i;;::::::::::::::;;;:::::;:::;;:::;;;;;;;;:;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiii;;;::::;::;;;;;ii;;;;;:;;;;;;;;::;;;:;;1tffftttttttii1i1ftt1iii1f1i;;:::;iiii;;;i;;11tii1i;;iii11i;1i;iii1i1t1i1ii;1ii1tt1i1t111tLftfffi11tftt;tii1;;i11ii;1i1ttt1i;::::,:::::::::::::::::;;:;;;::::;;::;;:;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;::;;i1tfftttttttii11i1tt1iii;itti;::::;;iiii1iiiiiii1;;i;;;i;;;;;;;;ii;ii;tf1;ii;ii;it11iii11111ft1ttfi1ttt1i1ttftt11tffftttftfft1i;::::::::::::::::::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;;;;;;itfLLLftffff111tt1tttiiiiii111;;:::iii;:;ii;iiii:::;i;;;;;:;;;;;;;;;i;;tf1iii;;;itfi;;;iiiiiit11tttii1t11ii11f11t11LLtffffffffft1i;::;:::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;;;;;itffLLffffff1ii1ttttt11ii1ii111;:;:;i;;:;;;::;;ii::;i;;;;i::;:;;;ii::;:;ii;ii;1i;;11i;:;;ii;i;11ii11;;;ii1i;iit11111tffffLfffffftt1i;:::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;;;;;;1tLLLLffffffft111111tt11ii1ii11;::;::;::;;::::;:;;::;i;:;i;::,:i;:ii:::;:ii;ii;1:;;iii;:;:;i:;;i1ii;i:;;;iii;;;11111t11tfffLftfffft1ii;::;:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;;;;;;itfLLLLLffftfft11iii1t1tt1;1iiiii;:;;::::,;:::::;;;;;:;;;;;;::;;;i::i::::i;;;:i1i;:;;i::;:::;::;;;;i;;;;;;;;i;;::1111t1t11tttfftttffft1i;;:::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;;;;i1tffLLLLGfttfft1111ii111tt;;iiiiii::;;::::,::;,,;;::;;::;:;ii;;;;;;,:;::,:i;:::;;ii::,::,,,:;:::;;::;::;i;;i;1i;::i1ii1ftt1ttfLftitffftt1i;;:::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;;;;itfLLLLfLfttttt1t111ii1t1t1;;;iiii;:;;;;::,:,,:,:;;::;::::::i;:;;;::,;;,:,:i:,::;:i;,,,:::,::::,:;;:::::;i1ii;;;;:;i1iiitt111tffft11tfLft1i;;::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;;;;itfLLLfffttttttttti11ii111t1;::;;i;;:iiii:::;:.,,:;::;::::,::;i:;;;:,,;;:,:;;:,::;;ii:,,,,,.::;:::::.:,::;i1i:::;:;iii1;i1t1i1ttfftt11tfftt1i;:;:::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;;;;itffffftfttftttt1t1111ii11tt1::;;;;;::ii;;:,,:,,,,,::,:,:,;,:,;i::::::;i;:,;;::,,,:;11:,,.,,.,,:;,,.,.,,:,;;i;:::;;;ii;1;;i1iii11tt111ttffft1t1;::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;;;itffttftttt1t1i1ttt1ii11i1111i:::;;;:::;i;:;,,,,,..,:;:,,:,:,,,:i:,:,,;::;:,;::;:,,;;ii:,,,,,...;i,,.,,..,,::;;::::i;;i:i;:;;;;i111tt1ttttfff11t1;;::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;;i1ttt1ttttt11111tftt1ii11ii11i;;:;;;;::::i;:;,,,,:,,:;;;,::,,,.,:;:,:,:i;,,;,::,::,,;iii,,:,::..,;i:,.,,,.,.,,:::,,,:::::;;:::;;1t11tft11tffttttt1i;::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;;;itt1tt1ttt1;;itttt1iii11i111i;;::;;;::::ii::,,.,;:,:;;:::;,,,,,:i:,,,:ii:,,:::;::,:;iii,,:::;..,;i:,,,,,,....,,,,,,,:::::;:::;;if1iitt111fftttttti;::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;;;;i11tttt11i;;1tttt11i11t1111i;;;::::::::;;:::,,:;:,,:;;::;,,::,:i;,,,:ii;:,:;:,::,:;ii;,,;:;:.,:;;:;;:,,,,,.,,,.,,,,:;;:::;::;i1t1i;111111fttttfti;::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;;;;i11tft11ii;i1ttt1ii111t11i1i;::;;,::::::i:::;,:i;:::;i::;:::::;ii;:,,ii;:,:;;:,:,,;1i;::i;:,,:::::ii::,::::;;;::,,,::;i;::::;i1t1i:i11ii1tttt111i;::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;;i111ttt1iiiii1ttt1i11tttt111i;::;:,::::;;;;::i::i;::;;;:;;:;;;::;ii;::;ii;,:;i;::::;ii;:,i;::,:::::iii;:::;;iii;:;::::;ii;;;:i;iiii:it1i11ttt1i1i;:::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;;;1111ttt111ii11ttt111tttttt111i::;;::::;;;:;;;;::i;;;;;;;;;;iii;;;iii;;iii;:;i1i;;;;i1ii::i;;::::::;iii;:::i;iii;;i;::;;i;;;:;i;;i;;:;1ii11tt1iiii;:::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;;;111tt11111ii111t11tttt1ttt1iii;;i;:;;;;;;;:;i;;;;;:;;;;;;;;iii;;;;;ii;;iii;iii;;;ii11ii;;iiii;::::i11i;;:;;;;;ii;ii:;iiiiii;;i;:::;:;iii11t11iii;;;::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;;;i111111111i11ttt1ttfftt111iii;;ii;;ii;ii;;;;;;;;;;:;iii;ii;;i;;;;;iiii;;;;iii;;;;;;iii;;;;iii;:;:;i111i;:::;;;11iii;i11iiii;;;;:,:;:;i;;111iiii;;;;::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;;i1111111111ttffttftfftt11ii;;;ii1ii;ii;i;;;;;i;;;;;iiii;;;;;;::;;;;;;;:,,:::,,:;;;;i;;;;;;iii;;;;;ii11ii;;;;iiii111i111111iii;;;:::::;;:iii;;;iii;;::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;iii1111i111tttfftfftttttt1i1;;ii11iiii;;;;;;;;;;;;;;;;;:::::::::::;;;;;::,,:,,,::;;;ii;;;;:;ii;;;;;;iiiiiii;iiiii1iiiii111111iiii;;;::;;::;;;;;iii;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;ii11i1iii1ttffttfffftttttt1ii111iii;;;;;;;;:::::::::::::::::::::::::::::,:::,,,:::::::::::;;;:::::;;;i;;;;iii;;;ii;iiiiiii11t111iii;:;;:::;;;i1ii;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;ii11111ii1tttttttffffttt1111111iii;;;;;;;:::::::::::::::::::::::::::,,,,,,,,,,,::::::::::::::::::::::;;:::;;;;;;;;;;iiiiiii11tttt1ii;;;::::::iiiii;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;i111111ii1ttttttftffftt111111iiiii;;;;;;;::::::::::::::::::::::::::::,,,,,::,:,::::::::::::::::::::::::::::::;;;;;;;;iiiiii111tft1t11ii;:;;:;i11i;;::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;i1tt11t1i1tftttfffffftt111111iiiiii;;;;;;;::::::::::::::::::::::::,,,,,,,,,,::,:::,::::::::::::::::::::::::::;;;;;;;;iiiiiiii1tfffftt1i;;;;ii111i;;;:::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;;1tt111111tttttffffttt111111iiiiiiii;;;;;;;;:::::::::::::::::::::,,,,,...,,,.,,:,,,,,:::::::::::::::::::::;;;;;;;;;iiiiii111111tfLfftt1;ii1iiii11i;;;:;:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;;ittt11111tttfftfffttt111111iiiiii;;;;;;;::::::::::::::::::,,,,,,,,..,,...,,.,,,,,,:::::::,,,,,,,::::::::::;;;;;;;;i;iiiii111111fLLffti;;ii;;i1111;::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;i1t111111ttftttttt1ttt11111iiiiiii111iii;;;::::::::::,,:::,,:,,::,,,:,,,,,,,,,,,,::::::::::::::::::::::;;;iii1iiiii;;iii1111111tfLLfti;;1i;i11111;:::;::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;iii11t111tffffttttttttt1111111111tttt111111111iii;;;;::::::;::,::,,,,:,,,:,,,,,,,,,,:::;;;;;;;iiiii111111ttttt111111iiiii1111111tLLfti:i1i;1tt11i;::::;;:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;:;ii111ttt1ttfffffftttttt1111ttttttttffttttfffLLLLLLLLLftt111iiii;;;;;::;:::;:;::;;;;;;;iii11tffLLLLLLLGGGLLLLLLLfffffttt1111ii1111tLLf1;;iiii1ttt11111;;:::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;1ffffftfffffffffffttttt11ttfffttttttttttttttfLLGGCGGGCGGLLfftt1111ii;ii;;;;;;;;;;;iii111ttfffLGGGGCCCCCCGGLLLLLLLLfffftt1tt111111i1fft;;;iii11111111ttti;:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;1Lfffffftffffffffffttttttttfftt1111111iiiiiii111ttfffLLLLLLLLfffftt11iii;;;;:;;;;ii11ttttffffLLLLLLLfffftt11111111tttt11111t111ii1i1tfi;;;;i11t1iii1tLGG1::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;tLGLfttttffffffttffttttttttttt11tt1111iiiiiiii111tttffffffffffffffttt1ii;;;;;;;;iii1ttfffLLLLLLGGLLLfffttt1111111111111111111111iiiitt1i;;;i111iii1tGCCG1:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;tLLLLfttttfffffffffttttttttttt1ttt111111iiiii11111ttfffLLLLLLLLLLLfft11i;;:::::;;i1tfLLGGGGGGGGGGLLLLLfffffttt11ttt1111111111111i111tt1i;;;i11111ttLGCGfi;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;1LLLLftttttfftfffffttttttttttttttttttttfffLLGGGCCC8CCCCCGGGGLLLLLLLfft1i;:::::::;;1fLGGGGGGGGGCCCCGGGGGGGGGGGGGGLLfffftttt111111i1i111iii;i111tfffttLGLfi:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;1fLLLft111tttttffffttttttttttttttffLGGGC8C8008C8000088CCCGGGGGLLLLffftti;::,,,,:;i1fLGGGGGGCCGGGGGC8GC000088CCGGGGGGLLfffttt111111i111ii;;i1tffft111fLft;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;;;;::itfftt1iii111111ttt11111111111tfLLGGGGGGLLGC8800008CGftfLGGGGLftttttttt1i;::,,,:;i1tfLLLLLGCCCGf1tGC8000088CGGCCCCGCCGLLft11iiiiii;ii1i;::iii1i;;;ii1tti:::::::::::::::::::::::::::;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiii;;;iii;;;;;;;;;;;;;;;;;;;;;itffft111111t11ttft1111111111ttfffffffffft1tLCCCCCGf1iitfffffft1111tttt1i;::::,:;;i1ttttttffLLft1itLGCCCCCGLttftfLLLLLLLft1111iiiii11t1ii1ttt1iiiiii1tti:;:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiii;;;iiiiiiiiiii;;;;;;;;;;;;;;1fftttfffLGLfttffft1t11111111ttttttttttt11i111ttt11iiiii1iiiiii11111tt1i;::::,::;i111ttt111111111i11ttfftt11tt1ttt111tt111iiiiiiii11t11tfLGCGGLfft11t1;:;:;;;;;;;;;;;;;;;;;;;;;;;;;:;;;;;;;;;;;;;;;;;;;;;;;;    //
//    iiiiiiiiiiiiiiiiii;;iiiiiiiiiii;;;;;;;;;;;;;;iffttffLLLLffffffft1111111iiiiii111i1111111111tt1111111iiiiiiii11111111i;;:::::;;i1111111t111111111111tt11i111t11iiiiiiiii;;iiiiii11tttfLGCCGGGLLfttt1;:;:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FanX is ERC1155Creator {
    constructor() ERC1155Creator() {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC1155Creator is Proxy {

    constructor() {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x442f2d12f32B96845844162e04bcb4261d589abf;
        Address.functionDelegateCall(
            0x442f2d12f32B96845844162e04bcb4261d589abf,
            abi.encodeWithSignature("initialize()")
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
// OpenZeppelin Contracts v4.4.1 (proxy/Proxy.sol)

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
     * This function does not return to its internall call site, it will return directly to the external caller.
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
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
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
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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