// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC721Creator is Proxy {
    
    constructor(string memory name, string memory symbol) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x03F18a996cD7cB84303054a409F9a6a345C816ff;
        Address.functionDelegateCall(
            0x03F18a996cD7cB84303054a409F9a6a345C816ff,
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

/// @title: VERT's CURATED CREATIONS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd.                                                                             .dNMMMMMMMMMWMMNOkd:cxOKNKd;,:loxko:,codOKXXKOOkddkO00kxo,;x0d:;o0OookkddONMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO'              .'.                                                            .dNMMMMMMMMMMMWKkKNklxOOOko:;ckxxkxldOddOK0OOx;..,oxkO0K0lck0kOkk0xloxxdld0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;             ,OXOo,.                                                         .dNMMMMMMMMMMWXOONWXkxkOXOl:;:lclkkkX0kKX00Od:..':oddkO0Oo::lkKkd00dkOxoc;lKMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl.           ,OWWWWKc.                                    ..,;,.              .dNMMMMMMMMWMN0kXWMW0kOOOKOoccoollldxllkOkkxolc:dkk0KOk0kl:lodkOooooO0Oxc'.oXMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk.          .oXWWWWO;                               ..;coxOKNNXk;.            .oNMMMMMMMWWWKk0WWWMWOkKOkxddxko;;oOxox00OOkxxxoOXOOXNX0o:lkOxk0OdoxKK00kc..:odk0KXNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0;         .okOKXNK:                          ..,:ok0XNWMMMMMMMWKo.           .oNMMMMMMWWWXOONWWMMMXkOXOl:coo;',o0Oxkk0KOk0OkxOWN0kOOooOXK0OdoollONX0Oxl...'....',;codkO0KXNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl.       .oXNK0Ok:.                      .':ox0XWWMMMMMMMMMMMMWWNOc.         .oNMMMMWMMWNOkKWWWWWMWKk0Xx,;dxdxxxx:,lO0kkK0xOOkXWXd:;ck0KKK0Oxc',lxOkxxo'.;xo.         ...';;codxO0XNNWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk.       :KWWWW0:                    ..:oOXWWMMMMMWMMMMMMMMMMWWWMWXk;.       .oNWMMMMMMWKk0NMMWMMMWW0kKO;:dxOXxdkxc:llokOodOxdkxocccokKKK0kxdl;:dxddxxo,.,kN0c.                 ...';:codkO0XNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO'      'OWWWWNx.                 .'cxKNWMWWMMMMMMMMMMMMMMMMWWWMWWWWXx,.     .oNWMMMMMMXkONMMMMMMMMMNOOxclolkOdoKW0oldk0kodxc:dOkxOXOk000O000xkdok00xol;':xXWXx;.                         ...';:loxk0KXNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0,     .oNMWWWk,                .ckXWWMWWMMMMMMMMMMMMMMMMMMMMMWWMMMWWWKd,.   .oNWMMMMMW0kKWMWMMMMWMMMXkl;cdolxOx0N0ooKKd::d0Ox00kKXKOlcx0NWXkxOxoON0kkoc:cld0XNKx,                                  ...,;codxOXWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0,     ,0WMWWKc.             .,dKNWMMWMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMWMMWKd'  .oNWMMMWWKk0NWMWWMMMWWMWWKc.;x00OxdO0kkddOxoxOOOoldk0O0KkdxOXXxox0XOkOk00dodxkxkOO00Ol.                                       .'lOWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0,     lNWWMNx.            .,dKWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMN0l..lXMWMMWNOONWWMWMWMMMWWWWKd,,dO00d:coxOkxkkOXXOo,,oOKNWNOk0Odc:d0KKklck0xoodxkxOXX0OOOo'                                   .'cxKNWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;    .xWMWMK:            'dKWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOldXMMMWW0kXWWMMMMMMMMMWXOO0xodxxkx:,lxO0klcokkOkodOOO0KKkkK0olkKK0kc:xOxllloododO0Okxdl,.                               .;oOXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:    'OWWWWk'          .c0WMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0OXWMMWXk0NWWMMMMMMWWXOOKNWXOOXKkolox00ko,.:xO0klcdkkxdoc:oOX0kO0OxoOWNOkOkkkOkokOOkkkdl,                            .:d0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:    ;0WWWXo.         ,kXWMMMMMMMMMMMWMMMMWMMWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMW0kXWWWNOONWMMWWWWWWKOOKNWWWWKk0Xkxkl:x0K0o:okKNXxdOkO00kocd00kdcoOkONN0xdoodoxkdkKXXKOOO:.                       .,lkKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc    ;0WWWK:        .:0WWMMMMMMMMMMMMWWWWWWNNXKXXNNWMMWWWMMMMMMMMMMMMMMMMMMW0kXMWN0kKWMWWWWWNKOOKNWWWWWWN0oldk00xkNW0xxkOOKXOONXOdlkOxOKOddo:;cdxkooxdO0k0NOOXK0O0Xk.                     .;oOXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc    ,ONWW0;       .lKWWMMMMMMMMMMWWWWWNK0O0000000000XWWMWWMMMMMMMMMMMMMMMMWOkXWXOk0WMWWMWNKOOKWWWWWWNNK0Ol;o0XWXk00k0OOKXOkkOK0OOOko;:oxOOkl;oOOxoxxoxOoxKxoxOKNWK:                  .':x0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc    .,lOXx'      .oXWWWMMMMMMMMMMWWNK0O0KNWWWWWWWNX0OOKNWWMMMMMMMMMMMMMMMMW0kXNOxkXWMWWN0OOKNMMWNNX0OO0XNXkxOO0KOxxOXKk0NXkc:ldkkdl;.;kXNNOkdkWW0x0Odxkc:c;;xNWWNd.               .,lkKWMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl.      .''.     .oXWMWWMMMMMMMMMMWXOOKNWMMMMMMMMMMWWNKOOKNMMMMMMMMMMMMMMMMW0kKKkx0WWWNKO0KWMWNX0O00KXWMMWWKk0NKOd;;d0OoxOkdlcokkkOOdlxOOK0k0xd0OddkdokOllxOkkNMM0;             .:oOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl.               :KWMMMMMMMMMMMMMMWXXNWWMMMMMMMMMMMWWWWNKO0NWMMMMMMMMMMMMMMNOk0OOXNWX0O0XNNX00O0KXWWWWNNXXXKxok0Oxc:oxkddxkOOxcckXKOkxOKxccx0dlkxo0KkOKOodNWKk0WNo.         ..:d0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl.              ,OWMMMWWMMMMMMMMMMMWWWWWMMMMMMMMMMWWWWWWWNXNWMMMMMMMMMMMMMWW0xxOKNX0O0KXKOOO0KXXXKK00OOO000KKxxKNKk0XX0o:cdxkxxkkxdxxodkxlokXXkkOONKddkOxOWMNOONO,       .,lkKNWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl.             .xNMMMMMMMMMMMMMMMMWWMWWWWWMMMMMMMMMWWWWMMWWMMMMMMMMMMMMMMMMW0ooOOOkkkkxkkkOO00000KKKXNNNWMMWWXk0N0kXX0xodkkxxocxOocxOdk0kKXOOKOdx0XklkXNkONMW0O0l.    .;okXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMWMWWXl.             :KMMMMMMMMMMMMMMMMMWWWWWWWWWWWMMMWMMMMMWMMMMMMMMMMMMMMMMMMMMWO;,clooddxk00KKXNWWWWMMMMMMWMMMWWW0kOkkkoldkO00OxcoxkOkkkddx0WWNKkdcoOOxxXMNkOWWMXkl. .':d0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNK0O0Oo.            .xNMMMMMMMMMMMMMMMMMWWNWWWMWKOXWMMWNNMMMMMMMMMMMMMMMMMMMMMMMMWk'.:xOOO000000000000KKKKKKXXXXXXXXKkc:;,:oxkOO0KOdOK0Oxo:';xKKKKKk:.;dkddO0OddO00Ol''lkKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNKOOKXNW0:            ;0MMMMMMMMMMMMMMMMMMMN0KNWNXOdOXXXXO0WMMWWMMMMMMMMMMMMMMMMMMMWk'.;xOKNNNXXXXKKKKKKKKKKKK00000OO0Oo'.:dxkOO00OOxok0000Oo..ck0KK00doOKOdd0K0xdOKOd::xXWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMWXOOXWWWWWNl.          .lXMMMMMMMMMMMMMMMMMMWNKkkkkddllodxxdkXNWMMMMMMMMMMMMMMMMMMMMWWO,.':lokKNMMMMMMMMMMMMMMMMMMWWWWWNOc''lKWWWWWWWW0kKWWWWXd::dO0KNWNkONMXkONWWKk00Oxx0OONMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXk0NWMWWMMWk'          .xWMMMMMMMMMMMMMMMMMMWN0dlc;,''',;cldkOOKNWNWMMMMMMMMMMMMMMMMWW0c;:cloodOXNWWMMWWMMMWMMMMMWMMWWKkdlolcdKNMMMWMW0kXWWWXOxdxkKXOOK0kKWMXk0WWNOoxKKOONXOONMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNOONWWWMMWWNK:          'OMMMMMMMMMMMMWWMWNNNKko:,.       .,cok0Okk0NMWMMMMMMMMMMMMMMMW0doolldkxdxOKNWWWWWMMMMMWMMWWWN0kkxxkkkxk0NMMMMW0kNWWXOkkO0OONWXOooKWWKkKNXOdo0W0kXWMXkONWMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0kXWMMWWMN0OOl.         ,0MMMMMMMMMMMMWWMWX0koc;.           ':oOKOxKWWWMMMMMMMMMMMMMMMW0xxxdddxOOkkkOKNWWWMMMMMMWWWWXOkKOkOxO0kOOOXWMMW0ONMNOOK0OXKkKWWKxxk0XOx0OO00k0KkKWWWWKdkNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOONWWWWWKO0XN0:         ;0MMMMMMMMMMMMMMWWWXkl;.   ...      .,cdKN0OXWWMMMMMMMMMMMMMMMW0xOOk0kkkk0OkOOk0NMWWMMWMMWNKk0X0doc,cddOKOOXWMW0ONNOkXXOkXNOOXWOkXNKxlckKNWXkOOkNMWX0OdoKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXk0WWWMMXkONMMWx.        ;0MMWMMMMMMMMMMWWWWKdc,  .c0Kx,      .coONXO0NMMMMMMMMMMMMMMMWW0kKOOX0kOOOKKOOOOO0NMWWMMWXOO0Kkc;loodocckX0kKWNkONOkXWXkONWXk0XkOWNKkxxOKNMNkdkKNKOOKX0xKMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkKMMMMMKkKWMMWXc        'OWWWMMMMMMMMMMMWWN0dc'  ,0WMXo.     .:lxXWKOXMMWMMWMMMMMMMMMMW0kKKkkKOk0OOKN0kO0OO0XWWWKkxO0Oo::xkkKkc;ck0Ok0NOO0kXWWKkKWWNOkOk0KO0XWWKOOKKolkOk0KNWWKkKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKk0WMWWWKkKWMMWNd.       .lXMWWMMMMMMMMMMMWXOko'  'kNWXl.     .;cxXWXOKWMMMMMMMMMMMMMMMW0xKXkd0XOOXOkKNX0O0K0k0KxodOKXOod0OooOOkolk0OxdkxdxKWMWKkXMMWXxcokk0XXXNXK0ko,,d0XNWMWWKkKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXk0WMMMMXkKWWMWXkl.       .xNWWWWMMMMMMMWMWXOOd,.  ,dkl.      .:lxXWN00NMMMMMMMMMMMMMMMW0kXW0dkNXkOXKk0WWXOOKXOl,ck00klcxOx;'lO0kclOKOo;':OXKX0dlk0OOOo,cxOOOOOO0Oxl'.'d00KXXWWKkKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNO0WMMMMNKXWWMWKO0l.       .dNWWWWMMMMMWMMWKO0k:.             'ok0NWN0OXMMMMWMMMMMMMMMMN0kKWKkkKWKk0NKk0NWNKO0XOlldOK0dlkKk:,lOKk:lkOko,.;x0KK0dcx0XXKd:kNNNWNXKkdoc;;:oKKK0OO0xdKMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOkNWMMWWWMMMMWXOK0;       ,xXWWWWMMMMMWWMWKO0Ol,.           .:kKNWMW0OXMMMMMMMMMMMMMMMW0xKWNXOONW0kKWXk0NMWXOOKKkxkO00dldkxxOkxolx0OxooodOONWXkxk0NWXxoONWNXKkdok0dcxxdkKWWNKkloKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWXk0WWMMMMMMMMMW0ONk'     :OWWWMMMMMMMMMMMWXOKKxl,.         .;clxKWWWKOXMMMMMMMMMMMMMMMN0kKMMW0kXWNOOXWXOONWMWKOO0Ok00Od,;xkk0d::oOKOk0XxONOkK0kKKkOKOkOxk0OkxxOXNklxX0kkkKX0OkxONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0kXWMMMMMMMMMMNOKNx.  .:0WMWWMMMMMMMMMMMWXOKN0dc:'.......;ccloONWWW0OXMWMMMMMMMMMMMMMN0kKWWMXk0WWXOOXWXO0NWWWN0kOOO0NKo:cc:loldKXOOKWXk0WNKkdxKWXOxdkOooOkk0XWW0do0N0k0Ood0NKkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXk0WWMWMMMMMMMWKOXXo. ;OWWMMMMMMMMMMWWMWMNO0WNOdlc:::::ccccldOXWWWN00NMWMMMMMMMMMMMMMW0kKWWMW0kNWWXk0WWXkONWWMWN0kxk0X0xxooOOOK0kONWWKk0WX0kolxO0kc,cdolx0XWWWKxdkXWXk0KloKN0OXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0kKWWMMMMMMMMWWK0KO:,xNMMMMMMMMMMMMWWMWWN0ONWN0xolllllllldkKNWWWMXOKWWMMMMMMMMMMMMMMW0kKWMMMKkKWWWKkKWWXkONWMMMWXOxdOKOkk0KkOOOKWMWN0odOO0KXKOOKKxdkklcd0KNNKkkk0WWWOxOkkkOk0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0kXWMMMWMMWWMWWNK0ddXWWMMMMMMMMMMMMMMMMWXOKWWWNK0kxxxkOKXNWWWWWWKONMMMMMMMMMMMMMMMMW0kKWMMMNOONMWN0kXMWXOONMMMWWNKxoxkdxkxxk0XWNK0OdcokO000KKOkxdxOKXkx00OxodxxKWMWKxoON0odXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWW0kKWMMMMMMMMWMWWW0kKWWMMMMMMMMMMMMMWMMMWKOKNWWWWWNNNWWWMWWMMMWKOKWMMMMMMMMMMMMMMMMW0kKWMMMWKkKWWMNOONMWXOONMMMMMWXOoc:cllx0K00O0KXOkXNNXKK00Oo,,xNWW0xXWXkxxodO0KXNx:x0doONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0OKNMMMMWMMMMWWWXk0NMMMMMMMMMMMMMWMMMMWWKO0XWWWWMWWMMMMMWMMWKOKWWMMMMMMMMMMMMMMMMW0kKWMMMMXk0NMMWXkOWWWXOONMMWWMWWKd,..lkO0KXNWMNOONMWWWMWKOkdclx0WXk0XOOK0kXXKK0Ol;oddONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKO0XWWMWWMMMMMMNOkNMMMMMMMMMMMMMMMMMMMWWX00KXNWWWWMMMWWWXK00XWWMMMMMMMMMMMMMMMMMW0kKMMMMMWOOXWMWWKkKWMMXkONWMWMWWMXo';kKNWMMMMMNOOWMMWNXOOKX0kkdlxKkkkkKKk0NWWNKkoldkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0O0NWWMWWWMMWWKkKWMMMMMMMMMMMMMMMMMMMWWWNK0000KKKKKKK00KXWWWWMMMMMMMMMMMMMMMMMW0kKMMMMMMKxKWMWMW0kKMMWXOONMMWWMN0dlk00OKNWWWWNkOWWNKOOKNWN0kXNOoddcoKNOkXNK0O0KklxXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0OOKNWWMMMMMNOONMMMMMMMMMMMMMMMMMMMMMWWMWNXXKKKKXXNNWMMMMMMMMMMMMMMMMMMMMMMMW0kKMMMMMMNOONMMWMWOkXWMMXOOXWMWXOOkkXWNK0OOKNWNkONKO0XNWWWN0kKWWKxl;l0KkxOkxO000kOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNK00000KKKKKkdKWMMMMMMMMMMMMMMMMMMMMMMWWWWWWWMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMW0xKMMMMMWWKkKWMWWMNkONMMWXOONWKkOX0kXWWWWNX0O0OookkOKKKKKK0xlx000xcldolcldkO0KXNNWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWNXXXXKK0kkXMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMWMMMWWW0kXMMWMMMMXkONMMMMWKk0WMMWXOkOkOXXkx0KK00000Odc',oO000KKKXXOd0WWXOOXWXO0XNWMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXO0NMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWMMMMMMMMMMMMMMMMMMMWWMWWWWWNOxKMWWMMWWW0kKWMMWWW0kKWWWW0c:dOOkodOKKKKKK0OkxodkOXWMMMMMW0xKMW0kXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXO0NMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWMMMMMMMMMMMMMMMMMMMWWWWNK0OddKMWWMMWWWXk0WMMMMWN0OXWW0olokKWXk0WWMMWX0O0XKk0N0O0NWMMMW0xKW0kKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                   //
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract VRT777 is ERC721Creator {
    constructor() ERC721Creator("VERT's CURATED CREATIONS", "VRT777") {}
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