// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: P Badge
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        //
//    [size=9px][font=monospace][color=#7f7f7f]_[/color][color=#7f7f7f]__________________________[/color][color=#7b7b7b]_[/color][color=#6e6e6e],[/color][color=#5e5e5e]▄[/color][color=#4e4e4f]▄[/color][color=#3f3f40]▄[/color][color=#333234]▓[/color][color=#29282a]█[/color][color=#1f1f21]█[/color][color=#171719]█[/color][color=#111113]█[/color][color=#0d0d0f]█[/color][color=#090a0c]█[/color][color=#070709]████[/color][color=#101012]█[/color][color=#161617]█[/color][color=#1d1d1f]█[/color][color=#262527]█[/color][color=#303031]█[/color][color=#3c3c3d]▓[/color][color=#4b4b4c]▄[/color][color=#59595a]▄[/color][color=#696a6a],[/color][color=#797879]_[/color][color=#7f7f7f]_[/color][color=#7f7f7f]__________________________[/color]                                                                                             //
//    [color=#7f7f7f]______________________[/color][color=#757576]_[/color][color=#5c5c5c]▄[/color][color=#434344]▄[/color][color=#2a2a2b]█[/color][color=#131315]█[/color][color=#08080a]█[/color][color=#070709]█████████████████████████[/color][color=#0f0f11]█[/color][color=#242426]█[/color][color=#3d3d3e]▓[/color][color=#575758]▄[/color][color=#717171],[/color][color=#7f7f7f]_[/color][color=#7f7f7f]_____________________[/color]                                                                                                                                                                                                                                                                                                                                                                                                           //
//    [color=#7f7f7f]__________________[/color][color=#787878]_[/color][color=#565757]▄[/color][color=#343435]▓[/color][color=#141416]█[/color][color=#070809]█[/color][color=#070709]███████████████████████████████████[/color][color=#101012]█[/color][color=#2c2c2e]▓[/color][color=#4f4f50]▄[/color][color=#727272]_[/color][color=#7f7f7f]_[/color][color=#7f7f7f]_________________[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                         //
//    [color=#7f7f7f]_______________[/color][color=#757575],[/color][color=#4a4a4b]▄[/color][color=#201f21]█[/color][color=#09090b]█[/color][color=#070709]███████████████████████████████████████████[/color][color=#171719]█[/color][color=#414042]▄[/color][color=#6d6d6d],[/color][color=#7f7f7f]_[/color][color=#7f7f7f]______________[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       //
//    [color=#7f7f7f]____________ [/color][color=#5a595a]▄[/color][color=#252526]█[/color][color=#08080a]█[/color][color=#070709]██████████████████████[/color][color=#202021]█[/color][color=#5a5a5b]╙[/color][color=#787878]_[/color][color=#707070],_[/color][color=#595959]╙[/color][color=#141416]█[/color][color=#070709]█[/color][color=#070709]███████████████████[/color][color=#1b1b1d]█[/color][color=#4d4d4e]▄[/color][color=#797979]_[/color][color=#7f7f7f]_[/color][color=#7f7f7f]___________[/color]                                                                                                                                                                                                                                                                                                                                      //
//    [color=#7f7f7f]__________[/color][color=#7a7a7a]_[/color][color=#444445]▄[/color][color=#101012]█[/color][color=#070709]█[/color][color=#070709]███████████████████████[/color][color=#474747]▀ [/color][color=#5b5b5b]╔[/color][color=#111113]█[/color][color=#070709]█[/color][color=#1d1d1f]█[/color][color=#7b7b7b]_[/color][color=#737373]_[/color][color=#0d0d0f]█[/color][color=#070709]█[/color][color=#070709]████████████████████[/color][color=#0b0b0d]█[/color][color=#363637]▓[/color][color=#727272]_[/color][color=#7f7f7f]_[/color][color=#7f7f7f]_________[/color]                                                                                                                                                                                                                                                                 //
//    [color=#7f7f7f]________ [/color][color=#474748]▄[/color][color=#0f0f11]█[/color][color=#070709]█[/color][color=#070709]████████████████████████[/color][color=#444445]▌[/color][color=#7f7f7f]_[/color][color=#555556]▐[/color][color=#08080a]█[/color][color=#070709]███[/color][color=#4f4f50]▌[/color][color=#7f7f7f]_[/color][color=#39393a]╟[/color][color=#070709]█[/color][color=#070709]███████████████████████[/color][color=#373738]▓[/color][color=#767676]_[/color][color=#7f7f7f]_[/color][color=#7f7f7f]_______[/color]                                                                                                                                                                                                                                                                                                               //
//    [color=#7f7f7f]______ [/color][color=#5c5c5d]▄[/color][color=#151517]█[/color][color=#070709]█[/color][color=#070709]█████████████████████████[/color][color=#1b1b1d]█ [/color][color=#727272]][/color][color=#0c0c0e]█[/color][color=#070709]█[/color][color=#070709]███[/color][color=#353637]▌[/color][color=#7f7f7f]_[/color][color=#505051]╟[/color][color=#070709]█[/color][color=#070709]████████████████████████[/color][color=#0d0d0f]█[/color][color=#4b4b4c]▄[/color][color=#7e7e7e]_[/color][color=#7f7f7f]______[/color]                                                                                                                                                                                                                                                                                                               //
//    [color=#7f7f7f]_____[/color][color=#7b7b7b]_[/color][color=#323234]▓[/color][color=#08070a]█[/color][color=#070709]███████████████████████████[/color][color=#545454]▒[/color][color=#7f7f7f]_[/color][color=#373738]╫[/color][color=#070809]█[/color][color=#080809]████[/color][color=#303032]▌[/color][color=#6a6a6a],[/color][color=#424243]╟[/color][color=#070709]█[/color][color=#070709]██████████████████████████[/color][color=#222224]█[/color][color=#727272]_[/color][color=#7f7f7f]_[/color][color=#7f7f7f]____[/color]                                                                                                                                                                                                                                                                                                               //
//    [color=#7f7f7f]____[/color][color=#717171],[/color][color=#19181a]█[/color][color=#070709]█[/color][color=#070709]████████████████████████[/color][color=#18181a]█[/color][color=#2c2c2d]▀[/color][color=#3e3e40]▀[/color][color=#4e4f4f]╙  [/color][color=#6d6d6d],[/color][color=#676868],[/color][color=#666667],,,,, [/color][color=#636363]└[/color][color=#565657]╙[/color][color=#464647]╙[/color][color=#333334]▀[/color][color=#1c1c1e]█[/color][color=#0a0a0c]█[/color][color=#070709]███████████████████████[/color][color=#0e0e10]█[/color][color=#606060]p[/color][color=#7f7f7f]_[/color][color=#7f7f7f]___[/color]                                                                                                                                                                                                                   //
//    [color=#7f7f7f]___[/color][color=#6c6c6c],[/color][color=#101012]█[/color][color=#070709]█[/color][color=#070709]████████████████████[/color][color=#0b0b0d]█[/color][color=#282829]▀[/color][color=#494a4a]▀[/color][color=#686868]'[/color][color=#6c6c6c],[/color][color=#545455]▄[/color][color=#3f3e3f]▄[/color][color=#2b2b2c]█[/color][color=#1c1c1e]█ [/color][color=#7b7b7b]_[/color][color=#101012]█[/color][color=#070709]█[/color][color=#070709]██████[/color][color=#0c0b0d]█[/color][color=#141416]█[/color][color=#252526]█[/color][color=#3c3c3d]▓[/color][color=#575758]▄ [/color][color=#646465]└[/color][color=#404041]▀[/color][color=#18181a]█[/color][color=#070809]█[/color][color=#070709]█████████████████████[/color][color=#575758]▄[/color][color=#7f7f7f]_[/color][color=#7f7f7f]__[/color]                           //
//    [color=#7f7f7f]__[/color][color=#717171],[/color][color=#101012]█[/color][color=#070709]█[/color][color=#070709]███████████████████[/color][color=#29292a]▀[/color][color=#5a5a5b]╙[/color][color=#727272],[/color][color=#4f4f50]▄[/color][color=#2a2a2b]█[/color][color=#0d0e0f]█[/color][color=#070709]█[/color][color=#070709]███[/color][color=#151517]█ [/color][color=#7f7f7f]_[/color][color=#666666]└[/color][color=#626262]└[/color][color=#585859]╙[/color][color=#3f3f40]▀[/color][color=#151516]█[/color][color=#070709]█[/color][color=#070709]████████[/color][color=#151517]█[/color][color=#3e3e3f]▌[/color][color=#6c6c6c],[/color][color=#686868]└[/color][color=#2d2d2f]▀[/color][color=#08080a]█[/color][color=#070709]████████████████████[/color][color=#5f5f5f]╕[/color][color=#7f7f7f]_[/color][color=#7f7f7f]_[/color]    //
//    [color=#7f7f7f]_ [/color][color=#19191b]█[/color][color=#070709]█[/color][color=#070709]██████████████████[/color][color=#2f2f31]▀ [/color][color=#646464]╓[/color][color=#28282a]█[/color][color=#09090b]█[/color][color=#070709]██████[/color][color=#3b3b3c]▌ [/color][color=#59595a]▄[/color][color=#7f7f7f]_[/color][color=#5d5d5e]╙[/color][color=#0b0b0d]█[/color][color=#151617]█[/color][color=#454546]▄[/color][color=#7c7c7c]_[/color][color=#39393b]╟[/color][color=#070709]█[/color][color=#070709]██████████[/color][color=#29292a]█  [/color][color=#1c1c1e]█[/color][color=#070709]█[/color][color=#070709]██████████████████[/color][color=#0c0c0e]█[/color][color=#707070]_[/color][color=#7f7f7f]_[/color]                                                                                                                       //
//    [color=#7f7f7f]_[/color][color=#3f3f40]╫[/color][color=#070709]█[/color][color=#070709]█████████████████[/color][color=#101012]█[/color][color=#606060]└[/color][color=#727272],[/color][color=#282829]█[/color][color=#070809]█[/color][color=#070709]████████[/color][color=#6f6e6f]_[/color][color=#6e6e6e]j[/color][color=#09090b]█[/color][color=#3c3c3d]▌[/color][color=#787878]_ [/color][color=#434344]╙[/color][color=#09090b]█[/color][color=#717171]_[/color][color=#6f6f6f]][/color][color=#070709]█[/color][color=#070709]████████████[/color][color=#4d4d4e]▄[/color][color=#7d7e7e]_[/color][color=#373738]╟[/color][color=#070709]█[/color][color=#070709]██████████████████[/color][color=#252527]█[/color][color=#7f7f7f]_[/color]                                                                                                //
//    [color=#767676]_[/color][color=#0c0c0e]█[/color][color=#070709]█[/color][color=#070709]████████████████[/color][color=#0f0f11]█ [/color][color=#686869]╒█[/color][color=#070709]█[/color][color=#070709]█████████[/color][color=#272729]█[/color][color=#767676]_[/color][color=#5a5a5a]╙[/color][color=#2d2d2e]▀[/color][color=#19191b]█[/color][color=#272728]█[/color][color=#3c3c3d]▀[/color][color=#5e5e5f]`[/color][color=#747474],[/color][color=#232324]█[/color][color=#070709]█[/color][color=#070709]█████████████[/color][color=#464647]▌[/color][color=#7f7f7f]_[/color][color=#303031]╟[/color][color=#070709]█[/color][color=#070709]██████████████████[/color][color=#626262]µ[/color]                                                                                                                                              //
//    [color=#4c4c4d]╟[/color][color=#070709]█[/color][color=#070709]█████████████████[/color][color=#59595a]⌐[/color][color=#787878]_[/color][color=#111213]█[/color][color=#070709]█[/color][color=#070709]████████████[/color][color=#262628]█[/color][color=#3f3f40]▄[/color][color=#4b4b4c]▄[/color][color=#4b4b4c]▄[/color][color=#3f3f40]▄[/color][color=#242426]█[/color][color=#09090b]█[/color][color=#070709]████████████████[/color][color=#686868]⌐[/color][color=#767676]_[/color][color=#0c0c0e]█[/color][color=#070709]█[/color][color=#070709]█████████████████[/color][color=#2b2b2d]▌[/color]                                                                                                                                                                                                                                          //
//    [color=#232324]█[/color][color=#070709]█[/color][color=#070709]████████████████[/color][color=#161618]█ [/color][color=#454546]╟[/color][color=#070709]█[/color][color=#070709]█████████████████████████[/color][color=#0f0f10]█[/color][color=#151517]███[/color][color=#070709]█[/color][color=#070709]██████[/color][color=#363637]▌[/color][color=#7f7f7f]_[/color][color=#29292a]╫[/color][color=#070709]█[/color][color=#070709]█████████████████[/color][color=#121214]█[/color]                                                                                                                                                                                                                                                                                                                                                             //
//    [color=#0c0c0e]█[/color][color=#070709]█[/color][color=#070709]████████████████[/color][color=#262628]▌[/color][color=#7f7f7f]_[/color][color=#2d2d2e]╫[/color][color=#070709]█[/color][color=#070709]███████████████████[/color][color=#121214]█[/color][color=#2f2f30]▀[/color][color=#434344]▀[/color][color=#3f3e40]▄[/color][color=#323234]▓[/color][color=#222224]█[/color][color=#0f0f11]█[/color][color=#08080a]█[/color][color=#070709]█████████[/color][color=#2b2b2d]▌[/color][color=#7f7f7f]_[/color][color=#313132]╟[/color][color=#070709]█[/color][color=#070709]██████████████████[/color]                                                                                                                                                                                                                                          //
//    [color=#08080a]██████████████████[/color][color=#1e1d1f]█[/color][color=#7f7f7f]_[/color][color=#3f3f40]╟[/color][color=#070709]█[/color][color=#070709]█████[/color][color=#0c0c0e]█[/color][color=#131315]█[/color][color=#1a191b]█[/color][color=#202122]█[/color][color=#282729]█[/color][color=#2c2c2e]▓[/color][color=#323234]▓[/color][color=#39393b]▓[/color][color=#424243]▄[/color][color=#4b4b4c]▄[/color][color=#525253]▄[/color][color=#565656]╙╙  Q[/color][color=#242425]█[/color][color=#171719]█[/color][color=#0f0f11]█[/color][color=#09090b]█[/color][color=#070709]███████████[/color][color=#4f4f50]▌ [/color][color=#19191b]█[/color][color=#070709]█[/color][color=#070709]██████████████████[/color]                                                                                                                       //
//    [color=#171718]███████████████████[/color][color=#6c6c6d]⌐ [/color][color=#0b0b0d]█[/color][color=#070709]█[/color][color=#070709]██████████[/color][color=#0b0b0d]█[/color][color=#101012]█[/color][color=#111113]██[/color][color=#171719]█[/color][color=#1f1f21]█[/color][color=#2f2f31]▓[/color][color=#434344]▄[/color][color=#202021]█[/color][color=#08080a]█[/color][color=#070709]████████[/color][color=#111213]█[/color][color=#3a3b3c]▀[/color][color=#5c5c5d]└ [/color][color=#707070]_[/color][color=#626162]└[/color][color=#39393a]▀[/color][color=#2c2c2d]█[/color][color=#707070]_[/color][color=#6a6a6a]_[/color][color=#18181a]█[/color][color=#070709]█[/color][color=#070709]████████████████[/color][color=#0d0d0f]█[/color]                                                                                                //
//    [color=#373738]╟[/color][color=#070709]█[/color][color=#070709]█████████████████[/color][color=#1b1b1d]█[/color][color=#7b7b7b]_[/color][color=#545455]╙[/color][color=#09090b]█[/color][color=#070709]██████████████████████████[/color][color=#111113]█[/color][color=#525253]╨[/color][color=#7e7e7e]_[/color][color=#7f7f7f]______[/color][color=#575757]▐[/color][color=#0d0d0f]█  [/color][color=#0b0a0c]█[/color][color=#070709]████████████████[/color][color=#1b1b1c]█[/color]                                                                                                                                                                                                                                                                                                                                                             //
//    [color=#676767]└[/color][color=#08080a]█[/color][color=#070709]██████████████████[/color][color=#202022]█[/color][color=#797979]_[/color][color=#5e5e5f]╙[/color][color=#0c0c0e]█[/color][color=#29292a]▀[/color][color=#505050]╙[/color][color=#5f5f5f]└[/color][color=#5f5f5f]└[/color][color=#555555]╙[/color][color=#414142]▀[/color][color=#242426]▀[/color][color=#0a0a0c]█[/color][color=#070709]████████████████[/color][color=#2c2c2e]▌ [/color][color=#7f7f7f]_[/color][color=#7f7f7f]______ [/color][color=#444445]║[/color][color=#0e0e10]█ [/color][color=#717071],[/color][color=#0a0a0c]█[/color][color=#070709]████████████████[/color][color=#474747]▌[/color]                                                                                                                                                                     //
//    [color=#7e7e7e]_[/color][color=#1f1f20]█[/color][color=#070709]█[/color][color=#070709]█████████████████[/color][color=#1c1c1e]█ [/color][color=#4a4a4b]╟[/color][color=#474748]▌[/color][color=#7f7f7f]_[/color][color=#7f7f7f]______ [/color][color=#5f5f5f]└[/color][color=#303031]▀[/color][color=#0a0a0c]█[/color][color=#070709]████████████[/color][color=#383839]▌ [/color][color=#7f7f7f]_[/color][color=#7f7f7f]____ [/color][color=#767676],[/color][color=#515152]▄[/color][color=#252526]█[/color][color=#353536]▀ [/color][color=#646465]╓[/color][color=#151517]█[/color][color=#070709]█[/color][color=#070709]███████████████[/color][color=#0f0f11]█[/color]                                                                                                                                                                      //
//    [color=#7f7f7f]_[/color][color=#696969]└[/color][color=#0a0a0c]█[/color][color=#070709]█████████████████[/color][color=#2e2e30]▌[/color][color=#7f7f7f]_╫[/color][color=#383739]▌__________ [/color][color=#3f3f40]╙[/color][color=#0a0a0c]█[/color][color=#070709]█████████[/color][color=#0f0f11]█ [/color][color=#7f7f7f]_[/color][color=#7d7d7d]_[/color][color=#757575],[/color][color=#616262]╓[/color][color=#4e4e4f]▄[/color][color=#424243]▓[/color][color=#3b3b3c]▀▀[/color][color=#646464]└ [/color][color=#535354]▄[/color][color=#202021]█[/color][color=#07080a]█[/color][color=#070709]█████████████████[/color][color=#4d4d4e]▌[/color][color=#7f7f7f]_[/color]                                                                                                                                                                     //
//    [color=#7f7f7f]__[/color][color=#484849]╙[/color][color=#070709]█[/color][color=#070709]█████████████████[/color][color=#525252]▄[/color][color=#797979]_[/color][color=#3d3e3f]▀[/color][color=#2a2a2c]█[/color][color=#4a4b4b]▄[/color][color=#666667],[/color][color=#787878]_[/color][color=#7d7d7d]_[/color][color=#7f7f7f]_______[/color][color=#696969]└[/color][color=#0b0b0d]█[/color][color=#070709]█[/color][color=#070709]████████[/color][color=#212123]█[/color][color=#1f1e20]█[/color][color=#2e2e30]▓[/color][color=#464647]▄[/color][color=#606061]╓ [/color][color=#777778]_[/color][color=#767676]_[/color][color=#727272],[/color][color=#7f7f7f]_[/color][color=#6d6d6d]][/color][                                                                                                                                            //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NTP is ERC1155Creator {
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