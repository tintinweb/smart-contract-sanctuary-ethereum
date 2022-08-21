// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Botanical Dreams
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//          .'.     .....   ;OKKK0OOO000x;'..  .....       .,. .......... .;kKKKK0000OOo. ......   ';.   ;kl.                     //
//          ...     .........lO0OOOkkkO00o,.........        .....  .......:kXKK0000O00x,     ..'..':c,,:odc.                      //
//         ....   ...  . ... .l00KKK0kxkK0l,..'.''..             . ......cOK0OOOOO0XKd'           .;:',,'.                        //
//          .''''...   ....   .o0KXNWNKOk0Ol'';;::'              .......cOKOkkkO0XXOl.             .,.                            //
//         ','..'...   ...     .c0XXXXXXKkxxl;,,c:.         ..    ..''.:kKK00KXNXOdl;.          .  ''                             //
//        ...  .,''.   ...      .;xKNNXK00xdxo;;:'..  ...   ..     .'',d0KKXXXX0xddl,..          .',.                             //
//        ..   ...... .'.         'cok0KK0kocl:;;.........          .,;xKK0KOkxdxko,.':c:,..   ...;.                              //
//         ...       .'.          .;lccloddo;,,,'.........          ..;dOxddddkOkd,...,lxOOxo:,.. ,,                              //
//                  .,.            .:dddxdooc,.'......'...           .,cllxO0KOxo,....',:lxOOOko,.;.                              //
//                 .,. ..            :xkkO0Okd;.....,,....     .     ..;ldk00xoc'..',,,;cloxOO00Ox:.                              //
//                .,.                 ;xOO0KKKO:....',... ..  ...   ...;lodol:,,,,,,;:cclx0XNWWWWN0o.                             //
//               .,.                   'dOO0KKKO:....'. .....,,..  ';..;cc:cc,..,clloxxddOKNNNNNNNNN0l.                           //
//               ''                     .oOOKKKXO;. .'. .....;...  .,..;;,:ccc:,,;cdxOKKOOkkkkOKXNNXXXk;.                         //
//              .,.             .....    .ck0KKKKk;... .''....  .......',..'oxooc;ccoxxkOOOOOkkO0KXNNXXKo.                        //
//             .,.                  .      :k0KKK0d'.. .:;;,.  ....    ....c0OdkxccoooxO000000KKK00KXXXXKx'                       //
//             ,'                   .       ;k0KKKOc,. 'cll;.  ..    .. ..'kXOxOOdldkxdkKNWWNKK0XNXXKKKXXKk,                      //
//            .,. .                 ..       ;k0000o'. ,ooc.         .. .'lXXOk0KkoxOOOOOKNWWWNX0KXWNNXKKKKO;                     //
//           .,. .         .       ..         :k00KO;..,oo,          .. .cONXOOXX0xx0O0K00KNWWWWWXXXNWNXKKKKk;                    //
//           ',.         ..        ..          cOO00d,.;ol.  ..      .. .oKXXO0NXXOx0K0KXK0KNWWWWWWNXXNWXKKKKk,                   //
//          .,.         .      .   ..          .l000Oc,;lc. ....     .  .dXXKOKWNN0xOK00XXKKKXWWWWWWNXKNWXKKKKx.                  //
//          ''.        .      .    ..           .x0O0o,,::. .',,.       .xNX0OXWWN0k0KK0KNXXXKXNWWWNNXKKXNXKKK0l.                 //
//         .,.       ..  ..  .   ....            :O0Ok:.... ....    .. .,kNX00XWWN0kKXXK0XNXXXKXNNNNNXXK0XXKKKKk'                 //
//         ''...... .........   .. ..            .d0OOo'...  ...    ..,';OXK00XWWN0OXNXXKKNXXXXXXNNNNXX000XXKKK0c                 //
//        .;. ....  ........  ...  ..             ;O00Ol....   .,... .',c0KKK0NWWNOOXNNXK0XNXXXXXXXXXXX000KXXK00d.                //
//        ',...... ........  ....  ...            .d0OOk:. .   .........dKKXK0NNNXkONNNXK0KXNNNXXKXXXXKKKKKKK000k'                //
//       .;'.....  .......  .....   ..             :OOOkl. ... ..    . 'kKXX00NNN0xONNNNXKKXNXXXXK0KKKKKKXXK00OOk;                //
//       .:....    ....... ....'.   ..    ..       'kK0kd'  ...   .   .:0XXX00XNXkx0XNNXXKKXXXXXK00KKKXKKXXK0OOOkc                //
//       ,:....     ..... .......   ..    .;.  .',,:kXXOd;. ..   ...  'xKXXXOOKXOxkKNNN00XKKXXXKK00KKKKKKKK0OkkOkl.               //
//      .c:...    ... ..........    .'  .  ';,,,..'cx0XKxc'..   ......lO0XXXkk0OxxOKNNXOOK0KXXKK000KKKKKK0OOkkkkko.               //
//      .l:..  .. ':. ..........    .'.    ..';.  lOdkKXkl;.        .,xO0KXKkxxddxOKNNXkOKKXXKKK00KKKKKKXKOOOkOkko.               //
//      .o:.  ....... ..........  .. ..     . .'.'kXkxO0xl,.   ..   .oOO0KXKkkxdxkO0XWKxOXKKK0K00KKKKK0KX00OOOOkkl.               //
//      .dc.  .........''.......  ...... .  . ...;0KkdxOxdl.  ..    c000KXNKO0OxkO000Xkd0XKK000000000O0KK00OOOOkxc.               //
//      .dl........   ...'...... ... .........   cKKkddkkOO:...   .;OKKXXNNKOK0kk00KKdcxXXK0O00O0OOOkkO0000OOOkxd:                //
//      .ox'...  ..   ...''.........  .....cl.  .dX0kxxkOKKd''.  ,cx0OKNNNN0OK0kk00kdoxxk0K0OOO0OOOkkOOOO0Okkkxdo,                //
//       :x;    ..........'''.......  .'..';;...,OXOO0OOKKX0:...'lkkxkXNNNX0OK0OdoclxOOOkxOOOOOO0KK00O00OOkkxdooc.                //
//       .o;  ........................';;;;;,,,,l0KO0KK0XXXKl. .;loox0XNNNXOO00OlcdkOOOkOkdkOkOKKK0Okk0OOkxxdolo,                 //
//        ;:........'''....''......',;;:cclc:;,,oK0O0XKKXNXXx...;cox0NNNNX0kkO0OddKOk0XKkxdxkkK000OkxkOkxxdooooc.                 //
//        .,........,,,,;;,',''''',;;,:oolooddc:xK0OKXXKXNXX0;.':xO0XXXXXK0kkOOOxdkxx0XXOdodxkOkO000xdxddoooodo;                  //
//         .'...''...,;:;,;,,,'',,,;:::cllllod:cOK00KXXXXNNXKl';o0KXKKXKKK0kxOOOkl:okO00koldxxddkOOkdoooddddddl.                  //
//          ,;''',..',,c:;,,,,,;::clcc::::cccc;lO000KXXXXNNXXx,:xKK00000KKOxxO0OOd::loxkdccoddooodoooddxxddddo,                   //
//          .oo;,,,',::cc:,',,,;;:lolc:;;;;;;:;o0000KXXXKXNXXk:ckOOOOkO00OOkkOO0Odc:coooc:lllooododxxxxxdddol,                    //
//           ;kxc;;;;::;::;;;;;;;;:clol:;,,,,,,d0O00KXXXKXXXX0llkkkkxkO0OkkkO00OOdc;;:c::clllllddxxxxdxxxdol;.                    //
//            ;OOo;;:clllcc:ccc:::::clllc;,''.,dOO0KKKXXKXXXXKdoxxxxkOOOOkkOO00OOd;',;;:ldddoodkxxxxxxkxdol,.                     //
//             'x0xc:ldddolcc:cccllccoodxl,''.;xOO0KKKKXKKXXXKkddxxxkkOOkkOOOO0Okd;,;,;oxxddddxxxxxkkkxdol,.                      //
//              .lk0xoloddlclloodddoooodkd;''.;xOO00000KKKXXKX0xxkkkO00OkO0OO00Oko,,;:lolodddxkkkkkkxdol:'                        //
//                'codooododxxxxkkOkkkdllc:;'.;xOOO00000KKKXKKKkkO00KK0OO0K0O0Okkl',collloooodkkOOkdolc;.                         //
//                 ..,:lodooodddxxxxkkxdl:::;';xOOO00000KK0KKKKOO0KKKK000K00OOOkd:,ccllccloodxxxdolcc:,.                          //
//                  ..';:clllcllclodddollccc:;:dOOO000000K00K0K0O0KXK00KK00OkOkxl;::::cclooooodooll:,.                            //
//                  ...,;:cccloodoooool:ccccc;:dkOkO00000K000000kO0KKK0000Okkkxo;::::cclldkO00Okdc'. .....                        //
//                 .....'cdxxolodxxdolc::cc::;;lkkkOO000000O0000OOO0KK0K0Okkkxo:;:;::ccd0XXKOxl;.      .,.                        //
//                 .... ..'ckOxdooolllccc:::;,,cxkxkkOOOOOOkO000OO00KK00OOkkxo;;;::::lx00kdc,..      .'cl:'..                     //
//                 .... ....:dkOOkxolccccc::;,';dkxxxkkkk0KOkOO0O00000OOkOkxl;;:::cldxxoc,.        ..,:::::::;;;'..               //
//               .';:;'...  .'cdkO000Okxdlc:;,',lxxxxxxdxO0OkkO000KKKOkkkOko::oodxkkxo:.           ....'.    ..',;;;'             //
//           .,lddlc::;;,.     .,cdkkkOOOkdl:;'':dxxxxddddkkkO00KKXKK0OkkOxlld0KK0Okl'.           .    ...        .':c;.          //
//         .:kkl'.      ..       .':lllc::cc::;''cxxkkddkkkO00KKXXNXXKK00OdldO000kxl,..           ..   ..            .:l,         //
//        'x0l.          .        ...,cool::;:::,;dkO0kOXNNXKXXXXNNXKKXXKOxk00OkxdkKKOo'          .. ..'.              ,o:.       //
//       :0O,  ..               ...   ..:loolc:::cokOK00KKKXNNOooxOKNNNNX00K0O0OkONWWWXo.         ..   ..               ,dc       //
//      cKk'   .,;.        .    .'.     ..,:loolcldkO0KKXNNNNKc''',dNNNNXXXKKXXkkXWWXK0k;  ..     ..    ..              .:x;      //
//     :KO,   .::.             ....      .,okO00kdk000KXXKKK0d:....:dddOKXK00OdokKKKK0xo;......   .'     .               'xd.     //
//    'kKc   .l:              .. ..      .o000XNXOkkkOKXx:oxdll:';:cldxOKOkoccoOKK0Okdoc........ ..'     ..              .xk'     //
//    l0d.  .ll.              .. .'      .lxkO0XNXOdlcldxoooldxooooddllxkl;:dxxkxkkxdl:'......... .'.   .'.     ',.      .xk.     //
//    k0c   .xc            .;clc::,..    .;oxxxkxkdl:cdlcc;;:lolloooolcldl:ll::llll:,...';:c:::,....    .,.     .;l,    .:0o.     //
//    OO;   'kd.        .:llc:;',;:;..    .;:clllc:,',cl:,;:;;:lxOOkdolc:,;,.,lo;,:;. ..''';:;,,;::,.  ....       'ol. .'xk,      //
//    Ok;  .,oO:.     .ldc.  ..    ';'. .  ..,,,;,;ldd:'.....,cd000Oxdlc;,;;;:d0Odl:....   .,.    .',,;:cllc,.     .od''dO:       //
//    ox:.',..cd:.   'oc.   ...     ;;....   ...'ckXKx:'....,c:clooolclxxdoccdOKKOdlc;. .   '.      .,:dl,;lxx:.    .dxxkc.       //
//    ,oc.;l;..'lc'.,l;.   .;;.   .':,..      ..'oO0Oxc..,;',,.';;,'';cdl:;';dkO0K000Oxl;. .,.  ...'',,:o'...;xl.    cKk;         //
//     ,c,;okxc'':llll;..  .:xc..,;:'          'oOOkd:,;:lllol;;ccc::c'  .....cxOOO0KKKK0dc::,,'.....od::'....:k:    cKk'         //
//      ':,':do'  .colllc:;,;ldoolc,........,:ldxl:'. .'','.:lodddxoccc'.;::.  .:dO0000000Okkxoc::::col,......,kc.  .xX0,         //
//       .;,.'cc...cl,.',;::::loodxdollllooool:;'.    ....'.',;cllll::c:;,'. ... ..;::cloooool:,,'''',ll'.  ..lx:...c0Kk,         //
//        .,,..,;'.co:.    .',,'...''''......  ....    ...,,,;clclooc;,,.....:l:'.......',..   ..,'...'colcclodol,.:k0Ol.         //
//        .,. ....':dl,...,:'.    .....    ............  .....;:::::,...''..;lool;;;....';,......;l;,;'':oxOkdc'..cO00x'          //
//         ,'  ....:lo;..,o:. ..........  .............. ... ..',,'.....;,'cooddxxddo,',,;;'....,ll:::;;ldkkx:. .dKKOx,           //
//         ,,    ..:loo;..:l,.  ....... ....................,:,.'.....,;;,ckOOkkOOkxOkl:::::::;;:,.....:dl:,..,oKNKOd,            //
//         .,.     .:ol,;::cc;....    ...','''''',,;,...',;lxko:;,,,::::;cdk0KKKKKKOO00kollll:'........d0dccoOXNKOkl.             //
//         .,.      .;;;lddo:;....  ...';;;;,,,:llldl,.':cldxkkkxollc:;,:dO0O0XXXXXXK00K0koooxko:;,,;:xXKdxKXK0Oxl'               //
//          .'.      .':oodddo:.   ..';:;,,;:loxkkOOkc'';:cclloolllc:,,,lk000OKXXXXKXXKKKKOkdxO0KKKKKXKOook0kxo:.                 //
//          .'.        'ldddddol,.  '::;;;codkOOOOO0Ox:',;;;;;::;:;,',;cxOKKK00KXXXXKKKKKKKOkkxdxO0Okxdloddlc,.                   //
//           .'         .;looolc;,':llccodkkOOOO0000Oxl,',,,;,,,,'..';:oOKKXXXK00XXXKKKKKK00OOko;;;;;;;,,'....                    //
//    .       ..          .';::;,lkkxddkOOOOOkO00000Oxl;,'',,,'''...;::okKXXXXXK00XXXK00K00OOOOd'            ..                   //
//    .       ...             .'o0KOkxkO00OkkOOOOO00Oxl,..''''...',:oc;cdO0KXXXXK00KXXK00000OOkkl.           ..                   //
//    ..       ..             .l0K0kkO00OkkkkO0000OOd:'.  .'''.','.:o:',cxOO00KKKK0OO0000OOOOOkkx;           ..                   //
//    ..       .'.           .o00OOOOOOkxxkOO00OOkd:..      .,,,,'.;c,''':okOO00000OOkxkkOOkkkOkkd;        .....                  //
//    ...       '.          .o00OOOkxxxxxkkkkkkxo;.          ',,;,';:,''..':oxxkOOOOOxdooddxxddxxxxl;..    .,:,.                  //
//    ...       .,.        .oOOkkxdddddxxxddoo:..            .,';:;:;,''.. ..;codxxxkkxxdddxkOkkkkkxxxoc;'.. 'c,     .            //
//    .... .',. .,'.',,..':dkxdolloooooolc:;,.      ..       .'',cc:;'.'..    .';codddddddooodxxxkkkkkkkkkxoc:cl'. .',',,'..      //
//     ....;ldOo,cocclxxodddollllcc;,'''''............   . ...''';;:;'''......   ..,:lloooooollloodddddxxxxxxxkkkdooolllc::,'.    //
//        .;..oOooo:;cooolllc:;'..            ....''.   ......',,,,::'''...........',;::::;,,';::;;,;;::ccclloodxkkOOxlc:,..'.    //
//         .. 'oolcccccc::;'..                 '..'..  .....  ';,,,:;'''.........,:;;;;;;'....'..      ...'',''::;cldxkdc,  ..    //
//         ...,::::c:;,...                        ........    ';;,,;;','..''....'::;,,,''..',,.................;'..':;:loo;.      //
//         ..;cllc:,..                            ....,'......';;;,;:;,,''','...,;;,'''''',;,''''...       .''';:,',,..';cdo'     //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BTNY is ERC721Creator {
    constructor() ERC721Creator("Botanical Dreams", "BTNY") {}
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