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

pragma solidity ^0.8.0;

/// @title: Puppets of Mayhem (Mayhem Drops)
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
//                                   ..',;;;;;,,'''........    ..                                                                      ..................     ....                                                                     ..,,'..,;,.......,,''.........';;'.                                            //
//                                             .....'',,;:::;:::;;;;;;;;;;,''''''.                                                      ...  ............     ....                                                                     ....'..',...'...':;,'..';:;,,,,..                                              //
//                                                      ....,:;,,',;::cllollllooc,'..                                                   . ........'......    .....                                                                          .....''.....','',;;;;,..                                                  //
//                                                     ....,:;..',;:,,::;;;:;:ll:;:cc;..                                               ..........'.......     ...                                                               .       .......'','....'''',;,...         ...                                         //
//                                                     .';:,........';::;'.';,,'..,;:cl:,..                                            ............ ......                                                                     ...';,'........';,.....'','..              ...                                         //
//                                                 ....''..                       ..'',;::;,.   ......                         ............................     ...                                                               ..',.   ...........'',;'                ...                                         //
//                                                ..;c,.                        .....     ..''.......                                                          ......                                                  .....        ..     ...........,;;'....             ..                                         //
//                                                .;l;.                   ....',,..         .;;...                                                             .........                                                             ..     ... ..........,;,'.   ...       .                                         //
//                                              .,oo;.         .....''''.'';::,..            .c;...                                                               .....                                                              ...   .,,.....,.   .:::::;;''''...     ..                                        //
//                                             .,;c;.   ....',:::lddodkxoolc;'.    ..        .:c.                                                                  ...  ..                                               .      ....    .. .:o:.  .'.  .,,...,:cccc:;,.     ...                                       //
//                                           .;;..,.  ..,:lxxxkOO0KK0KKKOxl,'cc:;:oxxo,.      'l;..                                                                                                                     ..  .    ....  ..;cok0kl,',::'.;lc'';::;,,,',;'..  ....                                       //
//                                          'cc;;;. ..;oxk0KKKKKK000K0KKKKOxkO00000KKKOo;'..  .lo'.  ....                                                           ..                                                       ..',;;,.;dkk0KXXXXXK0OkkxddO0Od:cc'..'.,::,.......        ..                             //
//                                        .:l:,',:cldkO0XXXKK0000OOOkddOXXXXKKKKK00KXXXXKOOxc;;co;.......                                                  ..... ..... ..                              . ..  ....  .     ...;oxxkdlldOKXXXXXNNNXX00OOxdxdx00kxkkxxkOOd:::;'.'.. ...''...                              //
//                                   ....,dxc,;coO00OO000OxxkOOO0KKXK000kkKXXXXXK0OkkO0000KKK0kkOdc'....                                         .         ..............  ..                            .................:dkOkk0OxOKKKKKK00KXXKKKK0OkkkdxO0OO0000OO0d::cllcloc;,;,'..                                //
//    .                         .;'. .;:oOK000KK0OkkkO00kxkO00KKK00KKK0xdOKKK00O0KKOOkkOOOO00K00KK0xc,...                                        ..   ...  ..............  ...                         .,;..... .'..;::;lk0K0Odx0KKKKK00OO0K00Okk0KOdoodkO0KK0OOOO0KKK0000OxOOd;...                                   //
//    ;'            ',.        ..coc;;oOKKKOOOkkO0XXXKK0Okkxdxk0K0xxddddxkxk0XKOO0KXKOkkxxxO000OOOOOOOx:...     .                                .    ... ...... ...........                           ,l,....':xOkkO0000OOOO0KKK000OOkkkkOOOOOxxk00OkooO0OO00000OOOO0KKK000koc;,,'.                                  //
//     ';.         .,'    ..,;::cllloxO000Okkxodk0KOO00OxodocoxdxOd;,'..;c:ldk0KOkk0K0OkxxxkkOOOOO00O00kc....  ..                   ... ..   ......... ........  .............                        .lc. ..;dO0KKK0OOOxxxxxxO00OOOkkO0K0kkkO0OkO00O00ddOOkddxxxddkkkOOkk00OkO00Ox:.   .,.                           //
//      .'.        .;c,.',lO0000OkxkO0OOO0K000K0OO0OkkxddxxdxkxxO0kc;;::clldxolclllk0000OkkOOkkO0OO00OkOOxc......              .        .... ....... .. . ....  .......  .....        ...             .do'.;cokOkxxkOOkkxdxkkO0OOxxxddxkxdl::ccdkkkkkkOdoxkkkxddddollkOOxxO0000OOOkoc,.  .,;.          .'.            //
//        .'.      .;xOOO0OOkkkkxxkK0kxxO000OOOOkdlcc:cddxkkxkkkxdllllddc:lxxdollc:dOxdxk0Okkkkkkkkkkkkkdoxo'...... .        .  ..... ........   ........  ..   .. ..  .. ..        ........  ..     .cxxxkOOOOOdloooolodc;:cddodddxdodl;,:;'.'lkxxkkOOOxolodddddddddddk0OxdxOkxddodOOo;,..,c.       .co,             //
//         .;;.      ;xk00OkOOkxdxkxolxOOOxlloooccll:cdoc;;clccll,'::;oxoc::cllloc:cooodxdxxoloxxxxdodkxlcdOl........         .................... ........... ......  .....        ........  ..    ,ldkxkO00OOxoll:'.:ol:;:clooooodddxxdlll,'cl:;,;;:okOdccllooccc:::cdkkkxxkOOxoxkkkOOkko;ll.     .xO,              //
//          'l:.   .cddoxOkxxxxdolllokkdllllooc::::lc;;:,'',,,,;:,....,lxxdol:;',;:;:;,;clooc;;:okxccclol:okko;,;;.....     ............................. ..'................              .  ..;:::lddodxxkOkdxdc,...:odxxdoccl:;:l;,:oodxo:::,,;c;..'ccccccllodolc:,':oxxxddxOOkxdocokOko':d;     cOc.              //
//          .co;..:dxdodxdodddxddkOOkxoc:cl;',,,;;,,c;.....'';c:::''..'',coddxxocc;,''''',,;;,'',cl:col::lk0KK0O0Ol.... ................................. .',...............    ..            'xOkxk00kkOkocodoxkc..''cxdc;,,::;,,;:;;;::ccloxkxlccc;::;;;;:;,;clc:cll;,;:lxxdoooxkkxo:;lxk:,ol.  .:x:.               //
//           'lddkxxkkxkkxxOOkkddkOxoc;,'',,','',:'.....'''''';;;:;,'.'''',;;::;;;:cc::,''..''''',:::clccokkxxdlx0Oc... .................................................. .                 .l0Okk0KKK0OOOkxxxxd:...,cl;,;:cl:,,''''''','.,clccclol:'.........';:,,;:c:,',lxkocodooxOxldOK0OOk; .lx:.                //
//           .okOxodOkxkOkdoodolclc;:ll;'...',,'......''.......'......''.''''',,'.....''''...''',,',.';;,,:c,;lxddkxoll'............. ..'................................   ....            .lO00KKKK0kc:::okkxl,''',:cc;;c:,'................,::coc.    ...... ...''',::;,;:okOkxo::lk0OOO0KKO:,o0l.                 //
//           ;xxooxxkkkdc,..,cddl'.,lc;;,'...''.',,..'........':::c:clccllolllxkxdol::;,'.......''...,,'.'';loclxkxooxkx:....................'............................ ......          .ckO0OO0Oxdoc;,;odcc,...'''''.... ...''.....',,,,;;:c:,;,'..........   .;::;''..,;lddodxkkO0KKOkO00kld0x,                  //
//          'd0o:okxkx;...'looddc';lc;,,''.....'','.':,..,;:::ccodc;::,''..'..,;;:cldkkxdol;''''.....','..':xO0OxkOkkkddxddol;............'''............................. .... ..   .'c:;:ldxkkolooddx:.;dko;'.............,::::;;;,',,,''';;:cc;;:::cc:,'....  ..'..,,'...,;;;:clokO0kxkkkkO0kkOx:'..      .        //
//      .,cdkOd,;xkkxc..;lddodkd;:oc;:c:,,'.. .......',:lol:,'....                  ...',:lolllc;,'''..''.'codxkkxxlldxxdodkOxl:,','...'.................,:cllccc:,'......  ........'lxkxdxxcll:;,':oddccdol;'..........,;:clc;'....            ......',,,:c;,..... ....,''...,:,..':oOOkkOOkOOkkkkOkxc'....clc'      //
//    ':dkOkxo:,lkOoc:lxkOOkxOKkllc,;clc;;;,'......,;ccc:'.                                .';llcc;;,'......;cclc:coc:odoloddxxdc;;'....  ..,'........;dk0KK00kkOkxdl;........... .:xl;cldxlcl:,',:c:;;:c:;::,........,::;'...                            .',,,'''.. .. .,,'..;oo;;;;lxOkddookOOkxxdxkOOkdc,::::.     //
//    dxkxl;..'lkO0kdk0Okkxxxdxkdc''::;,'...','.';cc:,..                                      ..,:::;,''... .';:;.'ldllollloddxdl;,'....'...,;,...'cdxOKKKKKKK00K0Okdo:......... .,ll:lxkdc::;;;,,,:;..;::c:,'......,;,..                                     ...'''...  .,;;,:lxxo;':xkocoddxddkkdxkkkO0Okoc:cc.     //
//    codol;..,ldxkkxdooddooddxOo'.';'.......,:clc,.                                              ..';:,''..  .,;,.,dxc:ll::lddolcc'..''..   ..'';ok0KKXK0KXXXK00KK0kkd,........ .:ddddodlco:.,oo;'''.;;:oc,.'.....'..                                          ...,:;,...',...':odl;colcllc::cllcodddxOOkkxddo'      //
//    ...:dxxoloxO0koccldxkxxkkko,.....  ..,colc,.                  ... ...... .                     .,;;;''....:l:;cdoc:ccccloooo,.',.        .cxkO0KKXXKKKKKK00KKK0OOxc'........cOklcoxxdo;.;lol;..,:::;;;,'...'.                                                .',;,..','..'.',;:ol;;,';col:;cllllodxxxkxo;.      //
//    '..,dxddolx000Odccldxxdoloc'.......'ldxc'.                ..,',c;',',:c,;;,'. ...                ..,::;''.',:c:loc::llddloxxl;.....      :xOKXXXXKKKK000KKKKKK0000Oo;'.  ...'lxxkK0Oxxxolodo;..:c:,:c;,....                    ............                    ..''...'...   .,ol::::lodolcoxxoloddxxxo;.       //
//    .  .':lodkkdlx0kc....''..,,.......,ooc;.                .';clclocclcodlloodl',:;'..                .':c:...,;:;;ol;;oololldkkd:.;o;,cc:,ckO0KKKKXKKKKKKKK0KK0000KKOkkkl,..,ldkkdoloodxdoolodc.';;,,:,....                .. ..,'';:',c;,,,;,'...                  .''..... ...':lloxxdooxO0kdooooodol;;'        //
//          .;ldl;:ldddc,..............,oc'.               .';cllodoooloooddodxkxlcodl,'....               .;:,'.';ccccl:,:lc:cloddxxookkO0OOO000KKKKKKKXKKKK0000K0000KK0OO00Oxx0KKK0Odoollllloolod:;;,,,,....             .....'';ll;:ddclolloolc;;,'..                  .','.......';cdkOkxxddxxoolc;:odolc'        //
//        ....':clc:'..',;;;,'...''...,l:.             ...'::coododxxxkkxxxxddkkkdool:;,...,'.              .',;'',:ll:cl;..,,,:okOO0KK00K00O00OOO00KKXXXKKKKK0Okk0KK00000KK0OkOkdodolcccllodoll:;ccc;,,,...             ..,,''.':llcllooooddoooxkoc:;;'...                 .,,... ....;lolcldxdolc:,'',:ccodo;.      //
//       .::'';loddl....';coo:',,;;'.':;.            .   ..;,;ldxOOO0KKKKKKKOxddddxxl:;....,;'..             ','''';lolccc;'...,lkOOOO00KKK00OkxkO0KKKKKKKKKK0OOOkkOOOO0KK0KKOocl;,;;;,,''..,::ccclo:,,,...           .....'..',;coddkOkOOO0Oxdoddoddlc;'''.    .            .,,..  ...',,,;;coollllc::c::cllol,.     //
//       ,oc:oxxddo:.'::clddc'.''';:;:,.           .......';:lxkOOOO00000KKK0Okdoodxxoc,...;c;....            ...',;lol:;:,..,;,:dkkkxkOO0KK00000000KK00OO00000000OkkkxOkk0Okdllodoc:::;''....,,;cxo:,'...           ..',,,,'';loxkO000000KK000Oxdolodolc:;...   ..           .''..  ....'''';olcllodl;;:clolllc'     //
//       ;odkOkxxo:''cdxxxxc'.....;c;..             ..'...;ldddxkkOOOOO000K0OOOkdccddol:;::;,;;'..            ....,cllc;'...;ll:;cloxkkkkdodxxO0000000000000000O00OkdolldxOx:;lxddl::c;...'.......;:;:,...           ...'','.,cdkOOO00OOO0000K000Okdloooll:','.  ..             ....... .':c;,;:cc:;;,,:;',cllc:,.    //
//       'lxkxllxxdooddolc:;,....;;:,.               ....;codddxkOOxddxO00OOkkOxoccolc:,,,;,,;'...            ....;cll;,,'',:::;;::cdxkxxxxxookOkkOO000KKKKK0OOOOOO0xlo:,:ol,,::cc;'.',,'...,,.....';;'...           ...'...'lxxxkkxl:;:::cdOO0000OOxolllll;'..                  ..'..   .:ooc:cc:,. ...'.';:clc,.    //
//       .',:cllollcll:,,'.'.. .';;,.                 ..':loodxkxc'.....,cxOkdddocclcc;...'...':;..           ..',,;c:'.'''...'',;codoooooooodkxdxOKKKKKKKK0OO0OOOO0kocc;';:'.;c:,'..,'..,codo:,','.::'...            ......;dxddd:.   .;. .;xO000Okkxoooll:'..                   .''.   .':ldl:ol,. .....':ll::.     //
//       .......'',,;;;,,'.... .,:c'              .. ...';coodxk:   ....  ,xdoooc;::c:;',;''..'...             ..',,,'.''.','',,,;cc:,,,:;';dxxxk0KKKKKK0KKKKK00OkOkxdl::'''..;:,'..,'..;xkc;c;';;..,;'...             .''.'ldxdo:     .:;. .lOOOOOOkkdooolc,'..                   .,'     .,:ddxkl'',,'',;lxxdc.     //
//      ....'';:ccccc;'.........,:;.             ......,,:oooodx:  .,:,.  .odlcc,';ccc:,;;'.....                .'',''''...'....';;..','',,;ldxkkO0KXKK000K000000Okkkkdc;'...'.....,:,..;xk:cxd:;,.','....             ...'':odol:.         .dkkkkOOkdollll:'....                  ';'.    .;lodxxkxoc::ccclodo;.     //
//      .';:cldkxolllc'.   ..,,'';;.                 ..'..:oolloo:. .....,oxoc::,.',::''..........             ..''''.',.......  ....... .,ldkkkO0K0OO00000OOO0O0000KK0xl;.........','...,ll:cc:,......''.             ....',collll,.     .,oxxxxkkxxdolllc;......                .','.    ..,:clxkkOOkl;ccclc'.      //
//    ..':cc:cc:,'..''.....''''.';;.                  ....';loooddo:,,;cdkxocc:;,'.',;,;;'.'......             ...''''... .',,'......   ..;oxkOO000OO0K000OO0O000000000Okd:...........................','.             ..''',:clllloolc::coxxdxxxxddoooolc;,'...                  .';'.      ..;looddkk:.';;;,..      //
//    .....','.........';,'',,..,:,                   . .''.';clooodddoollc:coo:,'',,'.,c;........             ..',;,'.. .';;::;,...  . .,oxkkkO0000O00K00O000OO0000OkOOOkl'. .  ...................';;,''.          ...'''',';cccclllllddodddxxdoooooool:;'...    .              ..,.        ..',,::;'.'cocccc'.     //
//    ...  .........,;cc:;,'....';'                      ..,;,';;,,;;;;;;:lool:,'';,';'...'...                 .',:c,'.. .,',:c:,'..   .;ldkOOO0OOOOO00O00000O000OO0KOkkOOx:....   ....''.''...',,,'',,..'..          ......'..';:llllllodddoooolloooll:;;'...                    .''.      ...,,.''. .:dddoollc'     //
//    ',..   ....';:cccc:c:'. ..,;,.                        ...;:;::,;cc:;,'..',,'''.,,.  ...                 ..',:lc,...,:;.';c;''.  .;dkO000OOOOOOO00000OkkO0000OOKK0kxxxd:..     .......'.';:::,..''.','..          .....'...',:cllllllllcc::cclol:,,'....                    ..''.     .,,.,c;. .;dxol:;;::l:.    //
//    ;;'..    .,;::clc::;'......,:.                     .  .   ...............'','......  ..                ...':lc;,.,:;;:,.....   .:dkO000OOOO000OO0OOOkkkO0000000000Oxxxdc;. ...........',c:,;:;..'.''''..            ....'.'..';c:;;:,';;,,;:,'''...',.                     ','.      ..,..':;;collcc,...'::.    //
//    :;'..'. .';:ccc;'....'......;,                       .. ...  ....................                    ....',cl;:l;,:;;c:,..    'lxkkO00OOOkO00OO0O000Oxdk000000OkkOkxkkxolc.......',,,,,::;;;:'.',....'..             ........''....'..',...,'  .'....                     .''.          ...,cdo,.....  .':;.    //
//    ;;......,:cccc;'.............,.                         ...       ....       .                       ....'',;,;:;;;......   .cxkkkOO0OkOOkkkkkOOO0OOOOOO0OOOOOOkkkkkOOkxoc:'. ....'...',;,,;;'.''........            .... ..'..  ............. ...                                                              //
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract POMMD is ERC1155Creator {
    constructor() ERC1155Creator() {}
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