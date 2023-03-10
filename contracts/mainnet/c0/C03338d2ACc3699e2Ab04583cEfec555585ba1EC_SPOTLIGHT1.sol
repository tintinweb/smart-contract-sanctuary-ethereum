// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Spotlight #1: LETHAL
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMNkolool;xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMO;lXWMNo;OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMXl:KMMMKccXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMM0:oNMMMk;dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWx;kWMMNo;kNNNNNNNNXXXXXXKKKKKKKKK0000000OOOOOOkkkkxxxkOKNWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWOolc,:KMMMKc;cc:::::::;;;;;;;;,,,,,,,,,'''''''''''''''.''',:ldxOKNMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWx'''''oNMMWO;';;;;;::::::::cccccccclllllllooooooooddddddc,:oc,'';kWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMO,''lo;xWMMNd,dKXXXXXXXXNNNNNNNNNNNNWWWWWWWWWWWWWWWWWWWWO,oNNo'',kMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMM0:''l0l:0MMMKccKWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW0;cXXl'';0MMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMXc'':K0:lNMMMO;dNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWK::KKc''cKMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMNo'';OWx;xWMMWd;OWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWXc;00;''lXMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWd'',kWXl:0MMMKccKWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWXl;Ok,''oNMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMk,''dNW0:lNMMMO;oNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNo,kx,',xWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMXo,''l0K0l,xWMMNd;x00000000000000KKKKKKKKKKKKKKKKKXXXXXXKo,do'',xWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMNk:'',;clllc,:0MMMKc;x0OOOOOkkkkkxxxxxxxddo:;::::::::::::::,';;,'';oKWMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMW0l,'',:llllllc,lXMMMO;dNWWWWWWWWWWWWWWWWWWNd,;cllllllcccccc;',;;;;,'';dKWMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMXd;'',:cllllllll:,xWMMWd;kWWWWWWWWWWWWWWWWWKl,:lllllllllllll:,;clc:;;,''';xXMMMMMMMM    //
//    MMMMMMMMMMMMMMNk:''';clllllllllc;,:0MMMXccKWWWWWWWWWWWWWWW0c,:lllllllllllll:,;cllllc;;;,''':kNMMMMMM    //
//    MMMMMMMMMMMMW0l,'',:lllllllllc;;dk:lXMMMO;oNWWWWWWWWWWWWNk;;cllllllllllllc;,::cllllllc;;;,'',cONMMMM    //
//    MMMMMMMMMMMXd;'',:clllllllllc;cONWx;xWMMNd;kWWWWWWWWWWWNd;;cllllllllllllc;,xXOl:cllllllc;;;,'',lOWMM    //
//    MMMMMMMMMNk:''';cllllllllll:;dXWWWXo:0MMMKccKWWWWWWWWWXo,:lllllllllllllc,;xNWWNkc:cllllll:;;,,'',l0W    //
//    MMMMMMMW0l,'',:llllllllllc;cONWWWWW0:ckOkd:oXWWWWWWWW0c,:lllllllllllllc,;kNWWWWWXxc:cllllll:;;,,'',d    //
//    MMMMMMXd;'',:clllllllllc;;oXWWWWWWWW0xdodxONWWWWWWWWO:,clllllllllllllc,:OWWWWWWWWWKd::llccc::,,,''';    //
//    MMMMNk:''';cllllllllllc;cONWWWWWWWWWWWWWWWWWWWWWWNKx;;clllllllllllll:,:0WWWWWWWWX0ko::cccc:;,,''''';    //
//    MMW0l,'',:lllllllllll;;oXWWWWWWWWWWWWWWWWWWWWWWWXo;,;clllllllllllll:,cKWWWWWX0kol::clllcc:;;,;::,'';    //
//    MXd;'',:cllllllllllc;:ONWWWWWWWWWWWWWWWWWWWWWWWKc,,:llllllllllllll:,lKWWX0kdl::clllc:;;;;';ccllc;'';    //
//    O:''';clllllllllll:;oKWWWWWWWWWWWWWWWWWWWWWWWWO:,:lllllllllllllll;,o00xol::clllc:;;;cok0d,:llllc;'';    //
//    ;''',:::ccccllllc;:kNWWWWWWWWWWWWWWWWWWWWWWWNx;;cllllllllllllllc;';ll::clllc:;;;cdkKNWWWk,:llllc;'';    //
//    ,'',;;;;;;;;;;;;',lkO0KKXNNWWWWWWWWWWWWWWWWXo,;cllllllllllllllc;,;:clllc:;;:ldkKNWWWWWWWk,:llllc;'';    //
//    ;'';llllllcccc:::;;;;;;::clloddxkO0KXXNNWWKl,:lllllllllllllllc;,:llc:;;:ldOKNWWWWWWWWWWWk,:llllc;'';    //
//    ;'';lllllllllllllllllllcccc:::;;;;;:::cllo:',::cccccllllllllc,,;:;,,;':0WWWWWWWWWWWWWWWWk,:llllc;'';    //
//    :'';cllccllcccllllllllllllllllllllllcccc::::;;;;;;;;;;;;;;:;,',,;;:cc,cKWWWWWWWWWWWWWWWWk,:llllc;'';    //
//    :'',cll:xNXKd:llccddoocclllccclllllllllllllllllllccccc::::;,,:cclllll,cXWWWWWWWWWWWWWWWWk,:llllc;'';    //
//    c'',cll:xWMMOcclccOWWNOccccxkxxoclllcccccclllllllllllllllll::llllllll,cXWWWWWWWWWWWWWWWWk,:llllc;'';    //
//    l'',cll:xWMMOccllclKMMWk::kWMMWkckNXK0OOkxoccllccccccclllll::llllllll,cXWWWWWWWWWWWWWWWWk,:llllc;'';    //
//    l'',cll:dWMMOcclll:oXMMNdxWMMM0::0MMMMMMMMNOlccck000Oo:llll;:llllllll,cXWWWWWWWWWWWWWWWWk,:llllc;'';    //
//    o'',:ll:dNMM0ccllll:xNMMWWMMMKl:cOMMMXOOXMMMKo;c0MMMMOcclll;:llllllll,cXWWWWWWWWWWWWWWWWk,:lllll;'';    //
//    d'',:ll:dNMM0ccllllcckWMMMMMXocccOMMMk;;lKMMMO;cKMMMMO:clll;:llllllll,cXWWWWWWWWWWWWWWWWk,:lllll;'';    //
//    x''':ll:oNMM0c:cccllcc0MMMMNd:lccOMMMKxdkXMMM0::KMMMMO:clll;:llllllll,cXWWWWWWWWWWWWWWWWk,:lllll;'';    //
//    x,'':ll:oXMMWKOkxxdoc;dNMMWx:llccOMMMMMMMMMMNx;c0MMMMO:clll;:llllllll,cXWWWWWWWWWWWWWWWWk,:lllll;'',    //
//    k,'':ll:lXMMMMMMMMMXo,oXMMNd:llccOMMMMWMMMMNx::c0MMMMO:clll;:llllllll,cXWWWWWWWWWWWWWWWWk,:lllll;'',    //
//    O,'';llccoxkk00KXNWNd,oXMMNd:llc:OMMMKodKMMWkc:c0MMMMO:clll;:llllllll,cXWWWWWWWWWWWWWWWWk,:llccc;'';    //
//    O;'';lllllc::codddooc:cx0KKo:llccOMMMOc;oXMMWk;c0MMMMO:clll;:llllllll,cXWWWWWWWWWWWWWWWWx,,:c:;c;'',    //
//    0;'';clllclxKNWMWNKkoc:ccclccccc:o0KXkcc:dNMMNo:0MMMMO:cllc;;llllllll,cXWWWWWWWWWWWWXOxdoox0Nx;:;'',    //
//    0;'';cllcoKMMMMMMMMMWOlclllccxkxdc:clcclc:oO0KOoOWMMMO:cllc;;llllllll,cXWWWWWWWNKOxdodk0NMMMMk;c;'',    //
//    K:'';clcc0MMMWKkkOXN0dcclll:kWMMWOcclll:lxdol:ccldddxo:lllc;:llllllll,cKWWWNKkdoddkKNMMMMMMMMk;c;'',    //
//    Kc'',cl:oXMMMOc:ccllccllll:oXMMMMNd:lll:kMMWNd:lllllccllllc;;llllllll,c00kdodxOXWMMMMMMMMMMMMk;c;'',    //
//    Xc'',cl:lXMMWx:llllllllllcc0MMMMMMKlcll:kMMMWx:lllllllllllc;;llllllc:,;ldxOXWMMMMMMMMMMMMMMMMk;c;'',    //
//    Xl'',clccOMMM0lclllccllll:xWMMWWMMWk:ll:kMMMWx:lllllllllllc;;llc:::cok0NWMMMMMMMMMMMMMMMMMMMMk;:;'',    //
//    No'',cllcl0MMWKdlclddcclclKMMMOdXMMXo:l:xMMMWx:lllllllllllc;;ll;ckKNMMMMMMMMMMMMMMMMMMMMMMMMMk;c;'',    //
//    No'',:lllclOWMMWNKXWW0o::OMMMMKOXMMMOcc:xWMMWx:lllllllllllc;;lc;dWMMMMMMMMMMMMMMMMMMMMMMMMMMMk;c;'',    //
//    Wd''':llllccd0NMMMMMMMXldNMMMMMMMMMMNd::xWMMWx:lllllllllllc,;lc;dWMMMMMMMMMMMMMMMMMMMMMMMMMMMk;c;'',    //
//    Wx''':llllllccoxO000OxccKMMMNOOKXNMMMKl,xWMMWx:cccllllllllc,;lc;dWMMMMMMMMMMMMMMMMMMMMMMMMMMMk;c;'',    //
//    Mx,'';lllllllllcccccccccdxkko::ccoKMMWk;xWMMMXOkxxddolccclc,;lc;dWMMMMMMMMMMMMMMMMMMMMMMMMMMMk;c;'',    //
//    Mk,'',;;;;;:cccllllllllllccccllllcokO0OcdWMMMMMMMMMWNX0o:lc,;lc;dWMMMMMMMMMMMMMMMMMMMMMMMMMMMk;c;'',    //
//    MO,''o00kxdol::;;;;::cclllllllllllcccccccdxxk0KXNWMMMMWd:lc,;lc;dWMMMMMMMMMMMMMMMMMMMMMMMMMMMk;c:'',    //
//    MO;''oNWWWWWWXK0Okdolc:;;;;::cccllllllllllccccclooddxkkl:lc,;lc;dWMMMMMMMMMMMMMMMMMMMMMMMMMMMk;c:'',    //
//    MO;''oNWWWWWWWWWWWWWWNXK0kxdol::;;;;::ccllllllllllllccccllc,;lc;dWMMMMMMMMMMMMMMMMMMMMMMMMMMMk;c:'',    //
//    M0:''lXXO0WWWNWWWWWWWWWWWWWWWWXK0Okdolc:;;;;;:ccclllllllllc,;lc;dWMMMMMMMMMMMMMMMMMMMMMMMMMMMk;c:'',    //
//    MK:''cX0:oNW0oloxKKKNWWWWWWWWWWWWWWWWWNXK0kxdolc:;;;;;::cc:,;lc;dWMMMMMMMMMMMMMMMMMMMMMMMWKOdc;c;'',    //
//    MKc''cK0:oNMO;:odOl;0W0dOWNKKNWWWWWWWWWWWWWWWWWXK00Oxdolc:;';lc;dWMMMMMMMMMMMMMMMMMMMWKkdc:::cll;'',    //
//    MXl'':K0:oNMO;;lOKc'dKo'o0l;;ckNKx0WNXNWWWWWWWWWWWWWWWWWNXx;;lc;dWMMMMMMMMMMMMMMMWKkdooxl,:lllll;'',    //
//    MNl'':00:ckKO;:dO0c.:o;'cc;x0d:dk,;0OcOWNkONWNXNWWWWWWWWWW0;,lc;dWMMMMMMMMMMMWKkdddxOXWWk,:lllll;'',    //
//    MNo'';0Xdc:ld:;ldx:;:',,::cKMNo:o;'ld:xWO,;OWx:ckXWXOOKXNW0;,ll;dWMMMMMMMWKkdddxOXWWWWWWk,:lllll;'',    //
//    MWo'';OWWNXXX0kddxoxd,lccd:lOO:cd:cc;;kNo,,oNd;l:oKk:,:cOWO;,lc;dWMMMWKkdodxOXWWWWWWWWWWk,:lllll;'',    //
//    MWd'',kWWWWWWWWWWWNNX0K0kX0l:;cOk;xk,,kO;:::0x:Ok:cl:cxkXWO;,lc;dNKkdc:dOXWWWWWWWWWWWWWWk,:lllll;'',    //
//    MWx'',cxO0KNWWWWWWWWWWWWWWWNXKNWKx0Xo;xo,;;,dd:kd;:l:,:dXMO;,lc;:l:::,cXWWWWWWWWWWWWWWWWk,:lllll;'',    //
//    MMk,'',;;;:clodkOKXNWWWWWWWWWWWWWWWWNKK0OK0odd;,;o0k:cxOXWO;,ll::clll,cXWWWWWWWWWWWWWWWWk,:lllll;'',    //
//    MMk,'';lllcc::;;;;:codxk0KNWWWWWWWWWWWWWWWWNNX0OKNWKo::cOWO,,clllllll,cXWWWWWWWWWWWWWWWWk,:lllll:'''    //
//    MMO,'';lllllllllllcc::;;;:clodkOKXNWWWWWWWWWWWWWWWWWWNXKXWO,,clllllll,cXWWWWWWWWWWWWWWWWk,:lllll:'''    //
//    MMO;'';llllllllllllllllllccc:;;;;:cldxk0KXNWWWWWWWWWWWWWWWk,,clllllll,cXWWWWWWWWWWWWWWWWk,:lllll:'''    //
//    MM0;'';clllllllllllllllllllllllllcc::;;;::lodxO0XNWWWWWWWWk,,clllllll,cXWWWWWWWWWWWWWWWWk,:lllll:'''    //
//    MM0:'';clllllllllldxxxddddddddxxxxdllllllcc:;;;;:clloxk0KXx,,clllllll,cXWWWWWWWWWWWWWWWWk,:lllll:'''    //
//    MMKc'',cllllllldkxdoodddddddddddooodxxdlllllllllccc::;;;;:;',clllllll,cXWWWWWWWWWWWWWWWWk,:lllll:'''    //
//    MMXc'',clllloxkdloxkOkkxxddoodxxxxdooodxkdlllllllllllllllc;',clllllll,cXWWWWWWWWWWWWWWWWk,:lllll:'''    //
//    MMXl'',cllldOdcoOOkkkO00K0Okolddxxkkkxdlodkxolllllllllllll:',clllllll,cXWWWWWWWWWWWWWWWWk,:lllll:'''    //
//    MMNo'',cllxOll00dd0NWWWWWWWWXOXWWWNK0OOkxoldkxolllllllllll:',clllllll,cXWWWWWWWWWWWWWWWWk,:lllll:'''    //
//    MMWd'',:lxOcoKxcxNWWWWWWWWWWXxOWWWWWWWN0kkkocdOxllllllllll:',clllllll,cXWWWWWWWWWWWWWWWWk,:lllll;'''    //
//    MMWd'',:dOllKx,oNWWWWWWNNWWWNddNWWWWWWWWN0xxkocxkollllllll:',clllllll,cXWWWWWWWWWWWWWWWWk,:llc:;,'''    //
//    MMWx''':Ox:OO;:OXXWWWWWKdkNWWdc0WWWNNWWWWWNkokxcoOOxllllll:',clllllll,cXWWWWWWWWWWWWWWWWk,;:;,''':ok    //
//    MMMk,''lOllKoc0WX0OOKWWWOlxNWx,xWWKoxNWWWWWWOcoOlcdOklllll:',clllllll,cXWWWWWWWWWWWWWWN0l'''',:dOXWM    //
//    MMMk,'';c;lxckWWWWXOddxKNX0XWk,cKWxcOWWWWWNX0x:lOd;ckkllll;',clllllll,cXWWWWWWWWWWWXOd:,'',cd0NMMMMM    //
//    MMMKo:;'''',,coxO0XWN0dclx0NWO;,kWXXWNX0kddk0NKolOKdckklll;',clllllll,cXWWWWWWWWXko:,'';lx0WMMMMMMMM    //
//    MMMMWNKOxdl:;'''',:loxOko:;cdd;'l00kdc::okXWWWWNxokOocOxll;',clllllll,cXWWWWNKkl;''';lkKWMMMMMMMMMMM    //
//    MMMMMMMMMMWNKOxdl:;'''',::,''';cc;,',cxKNWWWWWWWNx:xOcoOoc;',clllllll,cXWN0xl;'',:okXWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWNKOxdl:;''''',cc,'ckXWX00KNWWWWWX0xOx:kkc;',clllllll,:xdc,'',:dOXWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWNKOxdl:,'''',:col::ckNWWWWWWOkOcdOl;',clllllc:,'''',cd0NMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOxdl:;'''',;coxO0XWM0x0olOo;',cllc:;,''';lx0NMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOxdl:;'''',:loccdccOd;',::;,''';lkKWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNK0xdl:;'''''',::,'''''':okXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOkxdl:;''''',:dOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0xl;,:xXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SPOTLIGHT1 is ERC1155Creator {
    constructor() ERC1155Creator("Spotlight #1: LETHAL", "SPOTLIGHT1") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x6bf5ed59dE0E19999d264746843FF931c0133090;
        (bool success, ) = 0x6bf5ed59dE0E19999d264746843FF931c0133090.delegatecall(abi.encodeWithSignature("initialize(string,string)", name, symbol));
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