// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Indi Art 2023
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    NMMMMMWNWx'..''..;0MMWWKO000XK:..xWNNo..xMMMMMMMMMMMMWNK0c.. 'OWNXXXx..:XWWMWNK:    :KWWMWd..,dk00XMMMMMMMMMMWWXKd..cXkl    //
//    WMMMWMWNNd'...'..;0MMWWK0KOkKK:..xWNKl..dWMMMMMMMMMMMWX0O:.. 'OWNNNXx..:XWWMWN0:    :KWWMNo..'okO0XMMMMMMMMMMWWK0o. :KOl    //
//    NWWMWWWXNx'......;0MMWN0OK0k0K:..dWNKl..dWMMMMMMMMMMMWX0k:.. 'OWWNXNk' ;KWWMMWK:  . :KWWMNo. 'okO0KMMMMMMMMMMWN0Ol. :0Ol    //
//    XWWMWMWXNk'......,OMMWNOOXKk0K:..dWNKl..dWMMMMMMMMMMWWKOxl:,'c0NXKKKd. :KWWWWMK:. . :KWWMNo. 'oxO0KWMMMMMMMMMNXOdc. ;OOc    //
//    XWWMWWNNWx'......;0MMWN0OXKk00:..xWXKl..dWMMMMMMWNXXXXKKK000KKXXXXXXOc'lXWWWWWK:... ;KNWMNo. 'oxO0KWMMMMMMMMWKOxo;. ;0Oc    //
//    XWWMWWNNWx'......,OMWNN0OXXO00:..xWX0l..dWMMMMWX00Odlok0K000KK00KXXNNX00XNNWWWK;....:KNWMNo. 'oxO0KWMMMMMMMMWKOxl;. ;00l    //
//    XWNMWWWNWx'......,OMWNNK0NKkOO:..dWXKl..dWMMWNX0d;,;ldxocloxkO00XKKXXNNNXKXNWWX:....:KNWMWo..'lxO00WMMMMMMMMWKOxl;. ;00c    //
//    NWWMMMWWWk,......,OMWWWK0XKkkk:..oNNKl..dWMWXX0: .,okO0OkOOdc:,',,';lkXXNNNWWWXc....:KXNMWo..'lxO00WMMMMMMMMWKOdl:. ;0Kc    //
//    WMMMWWWWM0;......,OMWWWK0NKkkO:..oNNKl..oNWNXKc   .:dOkkOd;.        .'cOXNWWWWK:....;KXXMWo...lxO00WMMMMMMMMWKOxl:. ;0Kc    //
//    WMMWWMWWW0;......,OMWWWKKNXOO0c..oWNKl..oWMWW0' ..;lkx:,'.  ....    .'.,kXXNWWXc....;KXNMWd...ldO00WMMMMMMMMMX0ko:. ;0Kl    //
//    WMMWWMMWW0:......;0MWWWXKNX000c..dWNKo..oWMMMXd,..,;;;,...;;:oOkc'..'ll;dXNNWWXc....;0XXMWd...ldkO0NMMMMMMMMMX0xl;. 'k0l    //
//    WMMMMMMWW0,......;0MWWWXKXK000l.'xNXKd,,xNNNNXOdc,;:,....':clkXKc,lkKXX0x0NWWNXc... ;KXXMNd. .ldkOONMMMMMMMMMX0xc;. 'x0l    //
//    WMMMMMMWWO,......,OMWWWXOOxdddc:ldkxolcclddc;'.;l;','. ...'lddoc,:0WMN0xxxdONWXl... ;KXXMNo...cdkOONMMMMMMMMMXOd:,. 'x0c    //
//    WMMMMMMWWO;......;0MWWXOdo:'..............    .,c;;l;;dOk;,odl;,'lKX0OdllxdONMNl. . ,0XNMXo...cdkOONMMMMMMMMMX0xc,. 'k0:    //
//    WMMMMMMWMO,......;OWWXkll;.     ..'....        ';';c,;dxkocdxoodlloddxo,'o0NWMNo. . ,OKXMNo...cdkOONMMMMMMMMMN0xc;. 'k0c    //
//    NWWMWWWNWO,......,OWXkdd;      .';;;,'..      .,..''',;:oollolc:,',:c:;':ONWMWNo. . ,OXNMWd. .cdkOONMMMMMMMMMNKkl:. 'O0c    //
//    000KK0OOOd,......,kXkdkl..    .,::;;;..       .,..'',;,,,,:dOxc;,;dkkxkk0NXNWWNo. . 'OXNMWx...cdxkONMMMMMMMMMNKOl;. ,OKc    //
//    c;:cc:::::,......'ll:dd;cl,...colc:::,....  .'c;,;:ccccclx0XXx'..,okKXXXNNKKWMNo. . 'kXNMWx...coxkONMMMMMMMMMNKOl;. ,0Kc    //
//    ..................,.:xcoOko,,:lllc;::..',;;lx0KdloooldOXWWMWWd..oXNNNWWMWNKKWMNo. . 'OXNMWx'..cokOONMMMMMMMMMNKOo;. ,0Kc    //
//    lllllllllc,......,odOdd0xkOdoolldl'....,:okOXNN0ocldKWMMMWWWNO,.xNNKXWMMMWXXWMNo... 'OXXWWx...cokOkXMMMMMMMMMNKko:. 'k0l    //
//    NNNNNNNNN0:......cKXOx0Xdloc:;:d0d'. ..,:cx0XKOkdooOMMMMMMMNX0c.;0W00NMMMMNNWWNd... 'OXXWMk. .coxOOXMMMMMMMMMNKxlc. 'x0l    //
//    OOOOOOOO0x;......:0OoxK0;.....,kXk,.   .,:dKXkddddxKMMMWNNNXXO;.:0KoxNWMMMWNWMWd....'kKXWMk' .cdxOOXMMMMMMMMMNKkl:. 'k0l    //
//    xxkkkkkkkd;......l0dlxKx. .   ;0XO:.    .,x0K0d:;dKXXXNXXKookl..c0xckXWMMMWWWWNo....'kKXWMO'..cdxOOXMMMMMMMMMNKkl:. 'k0l    //
//    xkkkkkkkkd;......lx:cxKd...  .dNKc.     .;xKKOx::xklcxOKXd,ckc..dOcckXMMMMWWWMXc... 'kKKWMO'..:dxkOXMMMMMMMMMN0ko:. 'kKl    //
//    xkkkkkkkkx;......ol;lxKk'....:KMXl,;,'..;dKNK0d:lc'..'l0O,'ok: .xk:l0WMMMMWNWWXc....'k0KWMO'..:oxOOXMMMMMMMMMN0kd:. 'xKo    //
//    xkkkkkkkkx:.....'ddoOk0k;''.,kWMMXO0Odox0NNKO0xxxollcoOXd..:l' ,kx:oXMMMMWXNWWXc....'k0KWMO'..cdxOkXMMMMMMMMMWK0xc. .xKo    //
//    kkkkkkkkkx;.....;kkoclOk,..;dXWWWNNNNNNWWWKkxxxkOk0WWMXKo..'.  ,kkckWMMMMNKXWMXl....'k0KWMO'..cdxkkXMMMMMMMMMWXKkl. .dKo    //
//    kxkkkkxxkd;.....l0x,.,o, .;lkNNNWWWWWWMMMNkox0XXKKNMMMXkc...   .d0OKWMMMMWKXWMXl... 'x0KWMk'..cdxkkKMMMMMMMMMWXKkl. .dKo    //
//    kxxxxxxxkd;....;kO; .;c. . .;dOXWMMMMMMMXxcldKWMMMMMMMNxll,    .:kKNMMMMMMNNWMXl... 'x0KWMO'..:dxkkKMMMMMMMMMWXKOl' .xKo    //
//    kxxxxxxxkd;....l0l. .lx,...   .,oKWMMWWWKooONWWWMMMMMMWOoc.     'oKWMMMMMWXXWMXl....'x0KWMO,..:dkOkKMMMMMMMMMWXKOo' .xKl    //
//    xxxxkkxxkx;...'dk.  .;kklcc:.    .ckKNNNN00NMWWWWWMMMMMXl.     .cOWMMMMMMMXXWMXl... .xO0WMO'..cxkOkKMMMMMMMMMWNX0d' .xKl    //
//    xxxxkkkkkx:...,ko.   .'d0K0Oxd:'.   ':oddx0K0KXXKNMMMMMWx'.    .:OMMMMMMMMNNWMNo... .dO0WMO'..cxkOkKMMMMMMMMMWNNKx, .kXl    //
//    xxxxkkkkkx:...;kl.      .ck00Okxdl;'.. .';clclx0XWN00WMMNOo,...,dXMMMMMMMMWNWMNo... .dO0WMO,..cxk0OKMMMMMMMMMWNNXO; .kXl    //
//    xkxxkkkkkx:...;xl...     ..:xO0Okdolcc;'. ..;ccldk0xd0KXNNNOdloKWMMMMMMMMMWWWMNo... .xO0WMO,..cxk0OXMMMMMMMMMMWNX0: .kNk    //
//    kkxxkkkkkx:...,xd,;;,'...  ...,okkxdoddl:'.......cOk:,..'',:lloxKWMMMWMMMMWWWMNo.....x00WM0,..:xk00XMMMMMMMMMMMWNXkcoKWW    //
//    kxxxkkkkkx:...'l0kdxkc...   .   .....,,;;;;:;.';';xl.    .      .c0WMMMMMMWWWMWo.....x00WM0,..:xO00XMMMMMMMMMMMWNXXNNNXK    //
//    kkxxkkkkkx:....'dKkdl' ......             ....,c,;xx;.....        .:dOXWMMWWWMWd.....x00WMO,..ckOKKNMMMMMWWWWWWNXK0koc;,    //
//    kxxkkkkkkkc...'.,x0c. .......                  . .';::.               .;xXWWWMWd.....xKKWMO,..lO0XNWMWWNXKOkdolc:'......    //
//    xkkkkkkkkkc..','.lKKd;.    ...                       ..       ..         ;KWWMWd.....kXXWM0;.'o0KKKOkdoc;,..........,,''    //
//    xkkkkkkkOk:..','.;xXNk:,.     ....   .  ...  ..         ',.   ';,.     ...oWMMWd.....kXNWWKdccclc;'....'','..',;:clddxxd    //
//    xkkkkkkkOk:...,'.;okKNOdl;,'';codxdc,'',;lol:cdo;.  .. .o0Oc;,..;,....;c;.cNMMWx.....kKxoc;'.......;:::clccodxkkkkkkkOKO    //
//    kkkkkkkkOx:...'.,do;oKNX0OkkkxocxXX0kxxkO0XWNXXNNOl,,clcdXWWN0o::;'..'....lNMMWd....'do,..........:o:..;ok0d:;,..'.,ldkx    //
//    kkkkkkkkkxc...'.,kd,,;lkKXNWWNXKXNWNXXKKK0kkkOkdlldl;cx:cXMMMWNX0x,  ...coxNMMNd'...'dkdc'.........'....;odl:,,,,'.,;,;:    //
//    kkkkkkkkkkc...'..ckx:'..,:lxOKKXXXNNNNXKXKKKXNXd. ...:xxkNMMMMMWW0c.  .'lkONMMWx'...'x0xc...................',;;,....'',    //
//    kkkkkkkkkkc'..'...lO0kxoc:,,,;cclllllodk0XNWMMWKc.';.'odlOMMMMMWW0:',..,;lkXMMWk'...'k0xc..;:,''....'..'''.....''...';;,    //
//    kkkkkkkkkkc'.''..'cxkO0K00OOkkkOOOOOO0KKKXNWWWNXk,.......lXWMNK0Xx. ....'o0KWMWk,....xOxc'';cxOOkocll:,.......''''...,,,    //
//    kkkkkkkkOkl'..'...cdxkkOOOO0OOkkkxkOOOKWN0000OOKKc   ..  .kNMN0O0c       ,xKWMMO,....oOdc';lxKWMMWWNNX0kxolc:;,'.....,,,    //
//    kkkkkkkkkkl'..'...cddxddxxxkkxxxxdxkkx0WXOkOOOkOKo.   ..  cXWWKO0:       .xXWMM0,....oOxolONWMMMMMMMMMMMWWNNX0Oxdool:::,    //
//    kkkkkkkkkkc...'...cddddddddddddddddxxx0WXOkkOOOOKO, .,;,. .kNWN0O:  ..   'kXWMWKl;,'.oOxxoodxkO0KXNWMMMMMMMMWNNXKXXK0Okx    //
//    kkkkkkkkOkc...'...cdddddddddddddoodxxxKNN0kkkOkO0Kx'.:c:,..oKNWNKl  .'.  'kXWMWNXK0kx0KKOlclccccllodxkOKNWMMMMMMMMMWNXXX    //
//    kkkkkkkkOkc...'...cdddddddddddddoodxkKNNWNX0kOkOOKKx,';::' ;kKWWNk..',.  ,ONMMWWWWWWNWNNKdclccclllccccccoxxkkOKXNNWWMMMM    //
//    oooooooooc,...'...cdddddddddddddoodxONMNNMMXOkkkkk00d,':c,..ckWWW0:.',.  'OWMWKOO000KKKXXdclcclllccccccccccccclloddkkOKX    //
//    '''''''''.....'...cdddddddooddddoddxONMWWMMN0kkxxxx00x:,:;. .lXNNXd,',.  ,ONMW0xdxxxxxkXKoccccllllcccccccccccccccccccclo    //
//    ccclllllc:'...'...:doodddooooooooodxkKMMMMNKOkkxxddxO0x:;:'  'kK0X0c.'.. ,ONMW0xxkkxxxkXKo:cccllllcccccccccccccccccccccc    //
//    0OO000000d,...'...cdddddoooddddddddxdONMMN0kxxxxddddxO0x:;,. .lKO0Xk,... 'OWMW0xxxxxxkOKKo:ccccllllllccccccccccccccccccc    //
//    xxxxxxxkOxc,..,...o0kddddddddddddddolo0MMN0O0KXXK0kxxxOKx:'...,k00XXd,,' .kWMW0ddxxxkkk00l;ccccllllllllcllcccccllllclcll    //
//    xxxxkkkkO00kddkkkOKX0xddddoooooooooox0NMMMWWWWNNNNXOkkkOKOc''..l0KKN0c,, .xWMMKxdddxxkk00o:cccllllllllllllllllllllllllll    //
//    xxxxkkkOKNWWWWWNXK0OkxddoooooooooooxKNNKXWNXNWMMWWNXK0OO0K0l,,';xKKNXo,'. lNMMXkdddxxkk00dccclllllllllllllllllllllllllll    //
//    xxxxkkkOKWMWX0OxxdddoooooooooooodkOXWNx,xN0kkOKXNWWNXXKK0O0Odc;,cOXNNk;'. :XMMW0dddxxkO0Olclllllllllllllllllllllllllllll    //
//    kkkOOO0KXWMWKkdooooooooooooodkOKNWMMW0,,0NXK00OkOO0KXNWWNK000k:,cxOXWO,.. .OMMMKxddxkkO00oclllllllllllllllllllllllllllll    //
//    NWWWWWWMMMWN0xdooooddoldkO0KNWMWWWMMXl.dWMMMMWWNXXKK0KKXXNWNNXOlcccxKk,.'. lWMMNOdxxkkO00dllllllllllllllllllllllllllllll    //
//    MMMMMMWNX0OxddooodddoxOKNNNNNNNXXNNXd.;XMMMMNK0000KXXXXXKKKXXNNKxl',lc..:. ,KMMMKxdxxkkOkolllllcclllllllllllllllllllllll    //
//    MWXK0kxdollooooodddkXWNXXXXXXXKKXXKk,'OMMMMW0dooooodxxkOOOOOO0NN0d, .lcco; .dNMMNOdxxkkkxollllllccllllllllllllllllllllll    //
//    kxooooooooooooooddlkNX0OOkkkkkOXWW0c'xWMMMMXkooooooodddddxxl;cOX0dlc':O0Ox;.;ONMMXkdxxkkxollllllclllllllllllllllllllllll    //
//    ddxddddooooloooodxldKkllllloood0WNo.oWMMMMMXxoooooooodddddxdldKKocldl':k0ko'.dKNMWKkxxkkxollllllllllllllllllllllllllllll    //
//    xxdddooooooooooodxoxOxlllooooodONO;lXMMMMMMNOdoooooooodddxkkO00Odc..;,.,dkxc.l0KWMWKkxkkxlclllllllllllllllllllllllllllll    //
//    ooooooooooooooooodddoolllooooodkKooXMMMMMMMWNKOxddoooooddxkOO00Okkd;',..;dkx;c0KNMMWKOkkxlclllllllllllllllllllllllllllll    //
//    oooooooooooolllooooolllllooooodOOdOMMWNNWMMMMWNXKOkxdooodddxxkkOOOOOxdllc:xOoxKK0XWMNKkkxoclllllllllllllllllllllllllllll    //
//    oooooolloolllllllllllllloooooodxx0NWX0OKWMMMMMMMWWNXKOxddddddddxxkOOOO000lckdlOKkxOXWNKOkoclllllllllllllllllllllllllllll    //
//    olllllllllllllllllllllloooooodd;'dK0OOKNWWMMMMMMMMMMMWNX0OkxxxdddxxkOkkkOx:ox:lKKxlxKWWXOo:lllllllllllllllllllllllllllll    //
//    llllllllcllcclllllllllloooooddl'.;dKKXNNXKXNWMMMMMMMMMMMWWNNXXKOkxxkkkOkkd;;l;lO0kolodKNKdllllllllllllllllllllllllllllll    //
//    llllllllllcccllllllllloooooodxOkxkKXKOxxkkO0KKXWWWWMMMMMMMMMMMMWNXK0OOOOkkl,''o0dcdkkkKWNkllllllllllllllllllllloolllllll    //
//    llllllllllccllllllllooooooodddxkkOOkxddddddxkOOKKXXXNWWMMMMMMMMMMMMWNXXK0Oklckkkx;;ldONWWkllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllloooooodddddddddddddddddddddxxkO0KXXXNWWMMMMMMMMMMMMWWWNK0K0Oxc;,'c0WNdclllllllllllllllllllllllllllll    //
//    oooooooooooloolllloooooooodddddddddddddddddddooddddxkO00KXNWWMMWMMMMMMMMMMMWWXKKKkdoxKWMNd:llllllllllllllllllllllllllllc    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract IA23 is ERC721Creator {
    constructor() ERC721Creator("Indi Art 2023", "IA23") {}
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