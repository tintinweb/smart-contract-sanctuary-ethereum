// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Proof of Fren
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
//    ,lxKWMMMMMMMMMMMMW0xc,.                        .,:lxOXWMMMMMMMMMWX0koc,.. .,lxKNMMMMMMMMMMMMW0xc,.                        .,:lxOXWMMMMMMMMMWX0koc;.   .,lxKNMMMMMMMMMMMMW0xc,.                        .,:lxOXWMMMMMMMMMWX0koc,.  .,lxKWMMMMMMMMMMMMW0xc,.                        .,:lxOXWMMMMMMMMMWX0koc;..     //
//        .,lxKNMMMMMMMMMMMMNKxc,.              .':lxOKWMMMMMMMMMWX0koc;..           .,cxKNMMMMMMMMMMMMW0xc,.              .,:lxOKWMMMMMMMMMWN0koc;..            .,cxKNMMMMMMMMMMMMN0xc,.              .':lxOKNMMMMMMMMMWN0koc;..           .,cx0NMMMMMMMMMMMMWKxc,.              .,:lxOXWMMMMMMMMMWN0koc;..          //
//            .,cx0NMMMMMMMMMMMMWKxl,.    .,:ldOKNWMMMMMMMMWN0kdc;..                     .,cx0NMMMMMMMMMMMMWKxl,.    .':ldOKNWMMMMMMMMWN0kdc;'.                      .,cx0NMMMMMMMMMMMMWKxl,.    .':ldOKNWMMMMMMMMWN0koc;'.                     .,cx0NMMMMMMMMMMMMWKxl,.    .':ldOKNMMMMMMMMMWN0koc;..                //
//                .,cx0NMMMMMMMMMMMMWKxodOKNMMMMMMMMMWNKkdc;'.           ..,::'.             .,cd0NMMMMMMMMMMMMWKxodOKNMMMMMMMMMWNKkdc;'.           ..,c:'.              .,cd0NMMMMMMMMMMMMWKxodOKNMMMMMMMMMWNKkdc;'.           ..,::'.             .,cd0NMMMMMMMMMMMMWKxodOKNMMMMMMMMMWNKkdc;'.           ..,::'.    //
//    :'.             .'cd0NMMMMMMMMMMMMMMMMMMMWNKkdc;'.           ..,cox0XWMWNOd:'.             .'cd0NMMMMMMMMMMMMMMMMMMMWNKkdl;'.           ..,cox0XWMMNOdl:'.             .'cd0NMMMMMMMMMMMMMMMMMMMWNKkdc;'.           ..,cox0XWMWNOd:'.             .'cd0NMMMMMMMMMMMMMMMMMMMWNKkdc;'.           ..,cox0XWMWNO    //
//    MN0dc'.             .'cd0NWMMMMMMMMWNKOdl;'.            .,:ox0XWMMMMMMMMMMMMN0dc'.             .':d0NWMMMMMMMMWNKOdl;'.            .,:ox0XWMMMMMMMMMMMMMN0dc'.             .'cd0NMMMMMMMMMWNKkdl;'.            .,:ox0XWMMMMMMMMMMMMN0dc'.             .'cdONWMMMMMMMMWNKOdl;'.           ..,:ox0XWMMMMMMMMMM    //
//    MMMMWN0dc,.             .':dOXNKOdl;'.            .,:lxOXWMMMMMMMMMMMMMMMMMMMMMMN0dc'.             .':dOXNKOdl;'.            .,:oxOXWMMMMMMMMMMMMMMMMMMMMMMWN0dc'.             .':dOXNKOdl;'.            .,:ox0XWMMMMMMMMMMMMMMMMMMMMMMN0dc,.             .':dOXNKOdl;'.            .,:ox0XWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMN0xc,.             ..'.            .,:lxOXWMMMMMMMMMWX0koc:lxKWMMMMMMMMMMMMN0xc,.             ..'.            .,:lxOXWMMMMMMMMMWX0koc:lxKWMMMMMMMMMMMMMN0xc,.             ..'.            .,:lxOXWMMMMMMMMMWX0koc:lxKWMMMMMMMMMMMMN0xc,.              .'.            .,:lxOXWMMMMMMMMMWX0koc:lxKWMM    //
//    NMMMMMMMMMMMMN0xc,.                   .,:lxOKWMMMMMMMMMWX0koc;..      .,lxKNMMMMMMMMMMMMN0xc,.                   .,:lxOXWMMMMMMMMMWX0koc;..      .,lxKXWMMMMMMMMMMMMN0xc,.                   .,:lxOXWMMMMMMMMMWX0koc;..      .,lxKWMMMMMMMMMMMMN0xc,.                   .,:lxOXWMMMMMMMMMWX0koc;..      .,lx    //
//    ,cx0NMMMMMMMMMMMMWKxl,.         .':lxOKNMMMMMMMMMWN0koc;..                .,cx0NMMMMMMMMMMMMWKxl,.         .':ldOKNMMMMMMMMMWN0koc;..                ..,cx0NMMMMMMMMMMMMWKxl,.         .':ldOKWMMMMMMMMMWN0koc;'.                .,cx0NMMMMMMMMMMMMWKxl,.         .':lxOKNMMMMMMMMMWN0koc;..                    //
//       .,cx0NMMMMMMMMMMMMWKxl,.':ldOKNMMMMMMMMMWNKkdc;'.           .              .,cx0NMMMMMMMMMMMMWKxl,.':ldOKNMMMMMMMMMWNKkdc;'.           .               .,cx0NMMMMMMMMMMMMWKxl,.';ldOKNMMMMMMMMMWN0kdc;'.           .              .,cx0NMMMMMMMMMMMMWKxl,.':ldOKNMMMMMMMMMWNKkdc;'.           .              //
//           .'cd0NMMMMMMMMMMMMWXNMMMMMMMMMWNKkdc;'.           ..,cok0Od:'.             .'cd0NMMMMMMMMMMMMWXNWMMMMMMMMWNKkdc;'.           ..,cok0Od:'.              .'cd0NMMMMMMMMMMMMWXNMMMMMMMMMWNKkdc;'.           ..,cox0Od:'.             .'cd0NMMMMMMMMMMMMWXNMMMMMMMMMWNKkdc;'.           ..,cox0Od:'.         //
//               .'cd0NMMMMMMMMMMMMMMMNKkdl;'.           ..,:ox0XWMMMMMMMNOdc'.             .'cd0NMMMMMMMMMMMMMMWNKkdl;'.           ..,:ox0XWMMMMMMWN0d:'.              .'cd0NMMMMMMMMMMMMMMWNKkdl;'.           ..,cox0XWMMMMMMWNOdc'.             .'cd0NMMMMMMMMMMMMMMWNKkdl;'.           ..,:ox0XWMMMMMMWNOdc'.     //
//    '.             .':dONWMMMWNKOdl;'.            .,:ox0XWMMMMMMMMMMMMMMMMMN0dc'.             .':dONWMMMWNKOdl;'.            .,:oxOXWMMMMMMMMMMMMMMMMMN0dc;'.             .'cdONWMMMMNKOdl;'.            .,:oxOXWMMMMMMMMMMMMMMMMMN0dc'.             .'cdONWMMMMNKOdl;'.           ..,:ox0XWMMMMMMMMMMMMMMMMMN0d    //
//    N0xc,.             .':odl:'.            .,:lxOXWMMMMMMMMMWX0OKWMMMMMMMMMMMMN0xc,.             .':odl;'.            .,:lxOXWMMMMMMMMMWX0OKWMMMMMMMMMMMMMN0xc,.             .':odl;'.            .,:oxOXWMMMMMMMMMWX0OKWMMMMMMMMMMMMN0dc,.             .':odl:'.            .,:lxOXWMMMMMMMMMWX0OKWMMMMMMMMMMM    //
//    MMMMN0xc,.                        .,:lxOXWMMMMMMMMMWX0koc,.. .,lxKNMMMMMMMMMMMMN0xc,.                        .,:lxOXWMMMMMMMMMWX0koc;.. .,lxKWMMMMMMMMMMMMMN0xc,.                        .,:lxOKWMMMMMMMMMWX0koc;.. .,lxKWMMMMMMMMMMMMN0xc,.                        .,:lxOXWMMMMMMMMMWX0koc,.. .,lxKWMMMMMMM    //
//    MMMMMMMMNKxc,.              .':ldOKWMMMMMMMMMWN0koc;..           .,cx0NMMMMMMMMMMMMNKxc,.              .':lxOKWMMMMMMMMMWX0koc;..           .,cx0NMMMMMMMMMMMMMNKxc,.              .,:lxOKWMMMMMMMMMWX0koc;..           .,lx0NMMMMMMMMMMMMNKxc,.              .':lxOKWMMMMMMMMMWN0koc;..           .,cxKNMMM    //
//    MMMMMMMMMMMMWKxl,.    .':ldOKNWMMMMMMMMWN0koc;'.                     .,cx0NMMMMMMMMMMMMWKxl,.    .':lxOKNMMMMMMMMMWN0kdc;..                     .,cx0NMMMMMMMMMMMMMWKxl,.    .':ldOKNMMMMMMMMMWN0kdc;'.                     .,cx0NMMMMMMMMMMMMWKxl,.    .':ldOKNMMMMMMMMMWN0kdc;'.                     .,cx0    //
//    cd0NMMMMMMMMMMMMWKxodOKNMMMMMMMMMWNKkdc;'.           ..,::'.             .,cd0NMMMMMMMMMMMMWKxodOKNWMMMMMMMMWNKkdc;'.           ..,c:'.             .,;cd0NMMMMMMMMMMMMWKxodOKNMMMMMMMMMWNKkdc;'.           ..,::'.             .'cx0NMMMMMMMMMMMMWKxodOKNWMMMMMMMMWN0kdc;'.           ..,c:'.             .    //
//      .'cd0NMMMMMMMMMMMMMMMMMMMWNKkdl;'.           ..,cox0XWMMNOd:'.             .'cd0NMMMMMMMMMMMMMMMMMMMWNKkdc;'.           ..,cox0XWMMN0d:'.              .'cd0NMMMMMMMMMMMMMMMMMMMWNKkdc;'.           ..,cox0XWMMNOd:'.             .'cd0NMMMMMMMMMMMMMMMMMMMWNKkdc;'.           ..,cox0XWMMNOdc'.              //
//          .':d0NWMMMMMMMMWNKkdl;'.           ..,:ox0XWMMMMMMMMMMMWN0dc'.             .':d0NMMMMMMMMMWNKOdl;'.           ..,:ox0XWMMMMMMMMMMMMN0dc'.              .':d0NWMMMMMMMMWNKOdl;'.            .,:ox0XWMMMMMMMMMMMWN0dc'.             .':d0NMMMMMMMMMMNKkdl;'.            .,:ox0XWMMMMMMMMMMMMN0dc'.          //
//              .':dOXNKOdl;'.            .,:ox0XWMMMMMMMMMMMMMMMMMMMMMMN0dc,.             .':dOXNKOdl;'.            .,:lx0XWMMMMMMMMMMMMMMMMMMMMMMN0dc,.              .':dOXNKOdl;'.            .,:lx0XWMMMMMMMMMMMMMMMMMMMMMMN0dc'.             .':dOXNKOdl:'.            .,:lxOXWMMMMMMMMMMMMMMMMMMMMMMN0dc'.      //
//    .             ..'.            .,:lxOXWMMMMMMMMMWX0koc:lxKWMMMMMMMMMMMMN0xc,.             .''.            .,:lxOXWMMMMMMMMMWX0koc:lxKWMMMMMMMMMMMMN0xc,..             ..'.            .,:lxOXWMMMMMMMMMWX0koc:lxKWMMMMMMMMMMMMN0xc,.              .'.            .,:lxOXWMMMMMMMMMWX0koc:lxKWMMMMMMMMMMMMN0xc    //
//    0xc,.                   .,:lxOKWMMMMMMMMMWX0koc;..      .,lxKNMMMMMMMMMMMMN0xc,.                   .':lxOKWMMMMMMMMMWX0koc;..      .,cxKNMMMMMMMMMMMMNX0xc,.                   .,:lxOKNWMMMMMMMMWX0koc;..      .,lxKNMMMMMMMMMMMMN0xc,.                   .':lxOKWMMMMMMMMMWX0koc;..      .,cxKNMMMMMMMMMMMM    //
//    MMMW0xl,.         .,:ldOKNMMMMMMMMMWN0koc;..                .,cx0NMMMMMMMMMMMMWKxl,.         .':ldOKNMMMMMMMMMWN0koc;..                .,cx0NMMMMMMMMMMMMMWKxl,.         .':ldOKNMMMMMMMMMWN0kdc;'.                .,cx0NMMMMMMMMMMMMNKxl,.         .':ldOKNMMMMMMMMMWN0kdc;..                .,cx0NMMMMMMMM    //
//    MMMMMMMWKxl,.':ldOKNMMMMMMMMMWNKkdc;'.           .              .,cx0NMMMMMMMMMMMMWKxl,.':ldOKNWMMMMMMMMWNKkdc;'.           .              .,cx0NMMMMMMMMMMMMMWKxl,.':ldOKNMMMMMMMMMWNKkdc;'.           .              .,cx0NMMMMMMMMMMMMWKxl,.':ldOKNMMMMMMMMMWNKkdc;'.           .              .,cx0NMMMM    //
//    MMMMMMMMMMMWXNMMMMMMMMMWNKkdc;'.           ..,cox0Od:'.             .'cd0NMMMMMMMMMMMMWXNWMMMMMMMMWNKkdc;'.           ..,cok0Od:'.             .'cd0NMMMMMMMMMMMMMWXNMMMMMMMMMWNKkdc;'.           ..,cox0Od:'.             .'cd0NMMMMMMMMMMMMWXNMMMMMMMMMWNKkdc;'.           ..,cok0Od:'.             .'cd0N    //
//    d0NMMMMMMMMMMMMMMWNKkdl;'.           ..,:ox0XWMMMMMMMN0dc'.             .'cd0NMMMMMMMMMMMMMMMNKOdc;'.           ..,:ox0XWMMMMMMWN0dc'.             .'cld0NMMMMMMMMMMMMMMWNKkdl;'.           ..,:ox0XWMMMMMMMN0dc'.             .'cd0NWMMMMMMMMMMMMMMNKkdl;'.           ..,:ox0XWMMMMMMMN0dc'.             .'    //
//     .':dONWMMMWNKOdl;'.            .,:ox0XWMMMMMMMMMMMMMMMMMN0dc'.             .':dONWMMMMNKOdl;'.            .,:ox0XWMMMMMMMMMMMMMMMMMN0dc'.              .':dONMMMMMNKOdl;'.           ..,:ox0XWMMMMMMMMMMMMMMMMMN0dc'.             .':dONMMMMWNKOdl;'.            .,:oxOXWMMMMMMMMMMMMMMMMMN0dc'.               //
//         .':odl;'.            .,:lxOXWMMMMMMMMMWX0OKWMMMMMMMMMMMMN0dc,.             .':odl;'.            .,:lxOXWMMMMMMMMMWX0OKWMMMMMMMMMMMMN0dc,.              .':odl:'.            .,:lxOXWMMMMMMMMMWX0OKWMMMMMMMMMMMMN0xc,.             .':odl:'.            .,:lxOXWMMMMMMMMMWX0OKWMMMMMMMMMMMMN0xc,.           //
//                        .,:lxOKNMMMMMMMMMWX0koc;.. .,lxKWMMMMMMMMMMMMN0xc,.                        .,:lxOKWMMMMMMMMMWX0koc;.. .,cxKNMMMMMMMMMMMMN0xc,.                         .,:lxOKNMMMMMMMMMWX0koc,.. .,lxKNMMMMMMMMMMMMN0xc,.                        .,:lxOXWMMMMMMMMMWX0koc,.. .,lxKNMMMMMMMMMMMMN0xc,.       //
//                  .':lxOKNMMMMMMMMMWN0koc;..           .,cx0NMMMMMMMMMMMMNKxl,.              .':lxOKNMMMMMMMMMWN0koc;..           .,cx0NMMMMMMMMMMMMNKxl,.               .':lxOKWMMMMMMMMMWX0kdc;..           .,cx0NMMMMMMMMMMMMNKxl,.              .':lxOKNMMMMMMMMMWN0koc;..           .,cx0NMMMMMMMMMMMMNKxc,    //
//    xl,.    .':ldOKNMMMMMMMMMWN0kdc;'.                     .,cx0NMMMMMMMMMMMMWKxl,.    .':ldOKNMMMMMMMMMWN0kdc;'.                     .,cx0NMMMMMMMMMMMMWKOxl,.    .':ldOKNMMMMMMMMMWN0kdc;'.                     .,cx0NMMMMMMMMMMMMWKxl,.    .':ldOKNMMMMMMMMMWN0kdc;'.                     .,cx0NMMMMMMMMMMMMW    //
//    MMWKxodOKNMMMMMMMMMWNKkdc;'.           ..,::'.             .,cd0NMMMMMMMMMMMMWKxodOKNMMMMMMMMMWNKkdc;'.           ..,c:'.             .,cd0NMMMMMMMMMMMMMWKxodOKNMMMMMMMMMWNKkdc;'.           ..,::'.             .,cd0NMMMMMMMMMMMMWKxodOKNMMMMMMMMMWNKkdc;'.           ..,c:'.             .,cd0NMMMMMMMMM    //
//    MMMMMMMMMMMMMWNKkdl;'.           ..,cox0XWMWNOd:'.             .'cd0NMMMMMMMMMMMMMMMMMMMWNKkdc;'.           ..,:ox0XWMMN0d:'.             .'cd0NMMMMMMMMMMMMMMMMMMMMWNKkdc;'.           ..,cox0XWMMNOdc'.             .'cd0NMMMMMMMMMMMMMMMMMMMWNKkdl;'.           ..,cox0XWMMNOdc'.             .'cd0NMMMMM    //
//    MMMMMMMMNKOdl;'.           ..,:ox0XWMMMMMMMMMMMMN0dc'.             .':dONMMMMMMMMMWNKOdl;'.            .,:ox0XWMMMMMMMMMMMMN0dc'.             .':dONMMMMMMMMMMWNKOdl;'.            .,:ox0XWMMMMMMMMMMMMN0dc'.             .'cd0NMMMMMMMMMWNKOdl;'.            .,:ox0XWMMMMMMMMMMMMN0dc'.             .':d0NW    //
//    OXNKOdl:'.            .,:lxOXWMMMMMMMMMMMMMMMMMMMMMMN0dc,.             .':dOXNKOdl;'.            .,:lxOXWMMMMMMMMMMMMMMMMMMMMMMN0xc'.             .':dxOXNKOdl:'.            .,:lxOXWMMMMMMMMMMMMMMMMMMMMMMN0dc,.             .':dOXNKOdl;'.            .,:lxOXWMMMMMMMMMMMMMMMMMMMMMMN0dc,.             .':    //
//     .'.            .,:lxOXWMMMMMMMMMWX0koc:lxKWMMMMMMMMMMMMN0xc,.             .''.            .,:lxOXWMMMMMMMMMWX0koc:lxKWMMMMMMMMMMMMN0xc,.               .'.            .,:lxOXWMMMMMMMMMWX0koc:lxKWMMMMMMMMMMMMN0xc,.             ..'.            .,:lxOXWMMMMMMMMMWX0koc:lxKNMMMMMMMMMMMMN0xc,.                //
//              .,:lxOKNMMMMMMMMMWX0koc;..      .,cxKNMMMMMMMMMMMMN0xc,.                   .,:lxOKWMMMMMMMMMWX0koc;..      .,lx0NMMMMMMMMMMMMN0xc,.                    .,:lxOKWMMMMMMMMMWX0koc;..      .,cxKNMMMMMMMMMMMMN0xc,.                   .,:lxOXWMMMMMMMMMWN0koc;..      .,cxKNMMMMMMMMMMMMN0xc,.            //
//        .':ldOKNMMMMMMMMMWN0kdc;..                .,cx0NMMMMMMMMMMMMWKxl,.         .':ldOKNMMMMMMMMMWN0koc;..                .,cx0NMMMMMMMMMMMMWKxl,.          .':ldOKNMMMMMMMMMWN0koc;..                .,cx0NMMMMMMMMMMMMWKxl,.         .':lxOKNMMMMMMMMMWN0koc;..                .,cx0NMMMMMMMMMMMMWKxl,.        //
//    :ldOKNMMMMMMMMMWNKkdc;'.           ..             .,cx0NMMMMMMMMMMMMWKxl,.':ldOKNWMMMMMMMMWNKkdc;'.           .              .,cx0NMMMMMMMMMMMMWKxl,.';:ldOKNWMMMMMMMMWNKkdc;'.           .              .'cx0NMMMMMMMMMMMMWKxl,.';ldOKNMMMMMMMMMWNKkdc;'.           .              .,cx0NMMMMMMMMMMMMWKxl,.    //
//    MMMMMMMMMWNKkdc;'.           ..,cox0Od:'.             .'cd0NMMMMMMMMMMMMWXNWMMMMMMMMWNKkdc;'.           ..,cok0Od:'.             .'cd0NMMMMMMMMMMMMWXNWMMMMMMMMMWNKkdc;'.           ..,cox0Od:'.             .'cd0NMMMMMMMMMMMMWXNMMMMMMMMMWNKkdc;'.           ..,cox0Od:'.             .'cd0NMMMMMMMMMMMMWX    //
//    MMMWNKOdl;'.           ..,:ox0XWMMMMMMMN0dc'.             .'cd0NWMMMMMMMMMMMMMWNKkdl;'.           ..,:ox0XWMMMMMMWN0dc'.             .'cdONMMMMMMMMMMMMMMMWNKkdl;'.            .,:ox0XWMMMMMMMN0dc'.             .'cdONMMMMMMMMMMMMMMWNKkdl;'.           ..,:ox0XWMMMMMMMN0dc'.             .'cd0NWMMMMMMMMM    //
//    Odl;'.            .,:oxOXWMMMMMMMMMMMMMMMMMN0dc'.             .':dONWMMMWNKOdl;'.            .,:ox0XWMMMMMMMMMMMMMMMMMN0dc,.             .':dONWMMMMNK0Odl;'.            .,:ox0XWMMMMMMMMMMMMMMMMMN0dc'.             .':dONWMMMMNKOdl;'.            .,:oxOXWMMMMMMMMMMMMMMMMMN0dc,.             .':dONWMMMMN    //
//                .,:lxOXWMMMMMMMMMWX0OKWMMMMMMMMMMMMN0xc,.             .':odl:'.            .,:lxOXWMMMMMMMMMWX0OKWMMMMMMMMMMMMN0xc,.             .':odl:'..            .,:lxOXWMMMMMMMMMWX0OKWMMMMMMMMMMMMN0xc,.             .':odl:'.            .,:lxOXWMMMMMMMMMWX0OKWMMMMMMMMMMMMN0xc,.             .':odl:'    //
//          .,:lxOKWMMMMMMMMMWX0koc;.. .,lxKNMMMMMMMMMMMMN0xc,.                        .,:lxOXWMMMMMMMMMWX0koc;.. .,lxKNMMMMMMMMMMMMN0xc,.                         .,:lxOKWMMMMMMMMMWX0koc;.. .,lxKNMMMMMMMMMMMMN0xc,.                        .':lxOKNMMMMMMMMMWX0koc,.. .,lxKWMMMMMMMMMMMMN0xc,.                     //
//    .':lxOKNMMMMMMMMMWX0koc;..           .,cx0NMMMMMMMMMMMMWKxl,.              .':lxOKNMMMMMMMMMWN0koc;..           .,cxKNMMMMMMMMMMMMNKxc,.              ..':lxOKNMMMMMMMMMWN0koc;..           .,cx0NMMMMMMMMMMMMNKxc,.              .,:lxOKNMMMMMMMMMWN0koc;..           .,cx0NMMMMMMMMMMMMWKxl,.                 //
//    KNMMMMMMMMMWN0kdc;..                     .,cx0NMMMMMMMMMMMMWKxl,.    .';ldOKNMMMMMMMMMWN0koc;'.                     .,cx0NMMMMMMMMMMMMWKxl,.    .':ldO0KNMMMMMMMMMWN0kdc;'.                     .,cd0NMMMMMMMMMMMMWKxl,.    .':ldOKNMMMMMMMMMWN0kdc;'.                     .,cx0NMMMMMMMMMMMMWKxl,.    .':ld    //
//    MMMMMWNKkdc;'.           ..,::'.             .'cd0NMMMMMMMMMMMMWKxodOKNWMMMMMMMMWNKkdc;'.           ..,::'.             .'cd0NMMMMMMMMMMMMWKxodOKNMMMMMMMMMMWNKkdc;'.           ..,::'.             .,cd0NMMMMMMMMMMMMWKxodOKNWMMMMMMMMWNKkdc;'.           ..,::'.             .,cd0NMMMMMMMMMMMMWKxodOKNMMM    //
//    NKkdl;'.           ..,:ox0XWMMNOdc'.             .'cd0NMMMMMMMMMMMMMMMMMMMWNKkdl;'.           ..,:ox0XWMMNOdc'.             .'cd0NMMMMMMMMMMMMMMMMMMMWWNKOdc;'.           ..,:ox0XWMWN0dc'.             .'cd0NMMMMMMMMMMMMMMMMMMMWNKOdl;'.           ..,:ox0                                                    //
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DDM is ERC1155Creator {
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x142FD5b9d67721EfDA3A5E2E9be47A96c9B724A4;
        Address.functionDelegateCall(
            0x142FD5b9d67721EfDA3A5E2E9be47A96c9B724A4,
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