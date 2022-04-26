// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Over the Clouds
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
//                     ....                                                    ....                               ........ ....                                ...                            //
//                  .',cdOK0d;                                            .   .dN0,                            .cdl'..:dOx.:XXl                               .xNO'                           //
//                .c:.   .cOWWk'                                         'o'   dM0'                           :KNd.     ,;.;XWc                               .xMO.                           //
//                l0,      .oNM0'.;c;.    ',. .,'.''.  'c:;,..,,.      .lK0:.  dMK;..',.     .,,'.''.        :XM0'         ;XWl   .'::;.   'c:.   .:c,   .,;'.'kMO.  .,'.''..                 //
//               .OX;        lNWl.oWX:    ;;:k0l..:00c.lWM0:..cKl      .xM0,   dMK:...dKo. .o0k,...dKx'     .kMMx.         ;XWl .c;':kNXx' cWN:   ;KMd..dKKc..'OMO..oXO,..lOk'                //
//               '0Wd.       .kMo .kMO.  .'cXWd   ;KMk.cWWl    ..      .xM0'   dM0'   ,KWl.xMK,   .xWNc     .kMMd          ;XWc.x0'   cXM0':NN:   ,KMo'kMWl   .xMO.,KMNx;. ';.                //
//               .dMNd.       oX;  ,KWd..'.dMN: 'lxdc. cWN:            .xM0'   dM0'   '0Md:XMk..';oxl,       oWMk.         ;XWc,KWl    :XNccNN:   ,KMo:XMN:   .xMO. 'lkXNKko,                 //
//                .kWWO;     .ol    cNNc'. cNNo,;....  cWN:             dM0'   dM0'   '0Md'OMO;;:,....       .xWN:         ;XWc.kMXl.  .k0,;XNc   ,KMo'OMWo   .xMO..;...;oKWNo                //
//                 .cONNOl;,','     .xMXc  .lK0;.,dKO' lWNc             :XX: ..xMK,   ,KMx.,OXd. .lOXc        .:kOc.  .;oc.:NWl .xXNk:.,l, .lKk.  :XMd.'xNXo. .kM0';00o,..oNK:                //
//                    ':clc,.        'll,    .;,';;;,  ,ll'              .:;...;lc.   .cl;. .,;'',:;;.           ';'.';;;. 'll,   .:cc;.     .;,..'cl;   .;c;..:lc. ..','';,.                 //
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
//                                                                    ..                                                                                                                      //
//                                                                   .xd.                           .l'                                                                                       //
//                                                                   .kx.'c,;o,  .    .;;.;c;l;   ..,x;,o'.;, ;d,.,,..,l;                                                                     //
//                                                                   .kx..xKldO,..     :c':0ooO, .. ;KccK; c0,lK, .cx, c0l                                                                    //
//                                                                   .kd..kK,.xO'     ;0o.,0l.xOc,  ;KccK; cK;l0'  'Ok'.lc                                                                    //
//                                                                    ;;.,:'  .;.     .:,.'c, .ll'  .l''l. 'l',c.   .::..                                                                     //
//                                                                         .c;.                                                                                                               //
//                                                                          ..                                                                                                                //
//                                                                                                                                                                                            //
//                                                                                                            ',                                                                              //
//                                                                                                      .,:lodO0x:''cdxxoccdxoldl.         .;:,'::'...                                        //
//                                                                                                 ':loooOWWOkKNNX0XNKOdcxXK0XXKk;.    .:oxkO0KNWWX0Okoc:,.             ..                    //
//                                                                                               .dOKWWKOXXOKWMWX0O0x;.',cOXWNKkxOd.  .dNXXKKNWKOO00kd0NK0Od'       .'cxkddxx;                //
//                                                                                             .ckX0XWNKNXkxk0KXKOkdc...,ckKKXKO0XkccdOXNNMMMWKl'';c:ck00K0xl,.    ;kOOkdoxO0d.               //
//                                                                                             l0KKXKdc;:c,',,,;;'.....,odlxO0KXWMWWWNKkdxO000d;,;;..,lldXN0kOxddld0kd0K00OkO0o.              //
//                                                                                           .dXNNN0l;,,;;;;;;;;,'....,lkkOXOokXXXOxO0x;'.',,;;,..   ..,cONWNkkNMMMWxoKx;;,;ldkk;             //
//                                                                                           .kKkkkdodxOKK0Okxkdc:'':ccdKWWWXxdOKXd;xK0OxdlcxOko.    ..':odKKOKWMWWN00Xkc,':d0WWNOoooxkkOd    //
//                                                                                     .cxdlclKX0kxOXX000OOKXWMWXKkdk0KNX0XNK0XWWWKOKkllkKkkKkoc.      ....lkkXMMMMXkKWNKxlodOKXXWMNKKNNNN    //
//                                                                                    ,kK0KKXNWMMWKKXd'':odkKWKOXWWXXWWXNWWXxoOXN0oc;....',;;..         ...'ccxNMMWNWWKxdkddkx0WWWMNKOKWMN    //
//                                                                                   :OOdollONWWNKdc;..;xOOxdoox0WNXNNKkk0KXkccodo:..    .....         ......,OWWNWWMWXdldxkO0XKXWWWNWNXKO    //
//                                                                                 .oK0d::;oXMWX0Od,.,;..... .oXXKdlooc;;,;cc;,,,'.....  .....        ......;dXN0kOXX0xc;;ldOkxkKKOOOkxool    //
//                                                                                 :0KNk;..cKMWkll:..:;...    cxc;;;:::clll:;'..... ..           .;;..;,..'xNMWNKOOOo;'',,,:odd0XXXNNXOoll    //
//                                                                              .;:kNNKl'.'xNNXko,      .     ....',;:cldl;'.....    ...:oodolooddodkOxoc.,OWN0Okddko;,;;:lxxdkKWWWWNWNOdo    //
//                                                                          ..'oXWMMWKl'''cKXkOx:,.           ..........''...        .:0KKXK0000KNWNWMNOxx0NNklxkOXWN0Okc.':odxkOOdllkNWK0    //
//                                                                      'ldOKKKXMMMWWO;';;lXNk:'.........         ........          .;0WK0KXKK0xkKWMMN00XWWWWXXWWMMWNXX0c:o;:llll:'',:okXW    //
//                                                                    'oKXXNNNXNWWKOXkcc:;dXKk:','......           .             .,lkNMMMMMMWNNWMMMWNKdlkKKXWMWXNWKkxxolkKx;:c;,'......,lO    //
//                                                                 .;x00xlcldx0NMNO0Kxd:. :Kkl:,'''..                           'lKMMWXKKNWNkokKOkXWXkooxkkO0OxdxOxc,''';c;,,,'... .'..,cx    //
//                                                                .dX0xxkc,lxO0NMWWNKkxllokNXd:'..'..                         .lKWNK0Oxl:lkx;':l;:kN0o::;,,,'.,,,,;'.....',,''.,coldX0k0NW    //
//                                                                ,0KOX0dxKXKNWMMMMMWNNXXKWMXd:,','.                          .:xkl:::;..',,..''..;lc,'''.   .................,kNNNXWMMMMW    //
//                                                             .':kNX00dlOOldXMNKKKXNWMWXOKWXd:,,';,                            .........................     ...            .'x0xOKXXXXX0    //
//                                                       ...;o0KXWN0dkK0O0kxKWMKl;,;cdOKNKkOkc,...dXd.                                 ..................                   ,x0KXdcccxx:,,    //
//                                                   .ldx0XNXXKKXK0KXWMWNWMMMW0o:'.....,:::;;;,;cdXXd.                                 .......... .......                  'OWMMWOc,:xd'..    //
//                                               .;:l0KO0NWNXOldkdxkXWWWWWWWN0xlc;'.......'',,:OWWNx'.                                               ..                 ,odOXNNWWOod:....     //
//                                             .:OXKK00OXXkkKd,:d0XNWWXXKOKWKxdl:cc::c,....'',dNMXxc,.........                                                         'OKxddkKXK0d;......    //
//                                             cOxoclldKWN0K0c'oKX0dxOkkxdkXKklccOX0KXOkkxxdolOWW0l:,.......                                                           ,kd;'.:kXKkdl,..,lk    //
//                .;,.                      .,dK0kxddd0WMK00d:lO0kdlodoodx0NWNKNWN0kKWMMMMMMMWWWWN0x:'.....                                                             'dOx:c0WNx:::,;dko    //
//      .colokkkkOkdc'...;c.             'cd0WMWWMWXk0NNWWNNOxxkOolodddk0NMMWWMMMNOONWX00NMMMWNNNWNk:'......                                                            .oK0k0XKkc'.;lc;,'    //
//    .;kWMMWNWWXx,..coo0Xk;            ,OK0XWKkOOxk0XXO0NNNKx:ckxloOXNWMMMMXXXX0xONWXkookKK0OO0OOxl;,,......                                                            .:;:c:::'.',,,,,;    //
//    ONMMWKOKWWKo.  .':O0c.            :OxdOKKxoocdXN0xxOkKWKOOXOlcd0NMMMMWKkxxoON0doccccllcc:clllll:;,'....                                                              ........''',;;;    //
//    MMMW0ldXWXKkdc',dXNo.            .lKXXNNNXXKOxOOdod0NNWWWMW0dokXNNXNWXOOOxoxOo;,,;;;;;:cccccc:,........                                                             ..........',,,,,    //
//    NX0x:,lXMWWWMNXKKOc.           'd0XK00000000XNXKK00XNK0OOOO0KOkOKKKXNXK0Okdooc;,,,,,,;;;;'...                                                                       ...........,,;;:    //
//    0dc'.;xNWWNNNKd;.            .lKKkO0K0kxdlclokXNKO0XOxdodkKWWWMMMMWNNWWNKkdolc;;,'','..                                                                              ...........',;;    //
//    ;;;'.,kNNKOkd;               .kNK00kxooddl;;lkXNKO0OdxkOXWW0xOOxdddcokkOXXKklc;,:x0KOo:cloxddo;...                                                                    . ........',,,    //
//    ';;..'dXNXOl;.                c0ko;',;:cc:;:lONWMMWKKNMWOxKk;:c:;;;'.',,l0KdccokKNX00NMMNXXXKOOk0XOdc'                                                     ..       ..  ........,:cc    //
//    ..',:loONWk'                .cOKkxc,;:cllolldxKWMMMMWXXKl','.''........,:dxodOXWKdlokXX0ddk0Oxoclx0KKk:.                                               .   ..  . ....,'.......'oKXNN    //
//     ..'lkOOxl.               .xXWMMWKxddddxddkXWMMMMMMWKkokx;... ':coxkxl;::codKWWXx;';xk:,'',,'.....'cdkkc,.                                                   ..,cdkOKNXOkxo::ckNMMMM    //
//      ..,clc,.                .cKWWWX0OOOOOOkONMMMMWXXKkl:;co:,'.lKNN0xk0OO0K0O0NWN0dc:c:,'''.......  ....'cxl.                                        .;,';c;:odkKNMMMMWWNNWWWWWMMMMMNX    //
//      ..'',,'.                 lNWWNK0KXXX0OKWMWWKxoccclkOO0XKK0KX0dc;..';o0NWWMWKOkddoolccol:::,..   ........                                        .xWNNWMWWMMMMMMMWK000XNNWMMMMMWXkx    //
//       ...'..            .:odoldKWMWNNMMMMWWMMMWXo,;:;:ONWMWNXKNMNKOx:...,lx0KXNXKXXNNNNNNWWX00XXOko'                                             .cdkKWMMWMMMMMMWXKKK0kO0XWWWMMWWXKKkdd    //
//       ..';;.        .':dKWWMMMWWWXkokNMMMWWNNWXd:dO00KNNNWMWWMMMWWMWXkc:odkO0KKKNMMMMMWX00NNOx0NWNNkc;;'.                                   ...':OWMMWWNXX0KXXK00OOOddkO0OOO00OOOkxxkkO    //
//    ....':dOk;.  .,ck0XWMWXNMMWWN0xlcxXXNXOkddKOlxK0KKXXXWWWWWWMNKKNWWWNNWWWWWWMMMWNNWNX0kxKXKO00K0O0XNWXOd,  'odoc.                         :ddkXWMMWKOkxkxxxkxxxkKXOx0XNKOxddxxkkxxKNW    //
//    .. .;OWWWX0dlOXNNNXNWWWWWWMMWN0xllOKkdc::lkxdKXkOKX0XWXKNNX0kdook0KNWMMWNNMMMMWXK00K0kxkkddoolcclooooodd, 'oxoo:.                       .lxd0WMMMW0xxxxkxxxkOO0XWWXKXNNKOxk0XXKKKXNN    //
//       .;xKNWWMWWWNXNK0XNNWWNWMWNKklcldOko:;:o0NWWNKNMMMMNkxO0xoolc:cloxKWWNNWMMMWWN0OOkxooxxdolc;,,,,''.....  ......                    .,:oONWMMMMMMNXXXKXXKKXWNNNNNX0KXK0kkOKXK000KK0    //
//        .,dXWKKWWWNKXNXXK0KNMWK0Okko::::lO0kOXN0ONMMMMWNXkollolcllc:clloox0NWWMMNK0kool:;,;cc::::;'......''.........                   'dKNWMMMMMMWWMMMMMMMWNNNNMMMN0OO0KKKKXNNNNXK0000O    //
//        ..:dxdkO0XK0XWWNWWWWWWNKK0OO0xccOWMMW0xolx0NWN0kdl:,;;,,,;;;:cclclok0KK0koc;'......''','........';,............            .cclOWWWMMMMMMWXXNNNWWWWWNNWWMMNKOkkO000KNWNXXKOkkkkk    //
//        ....';ccoxxO0KXNNNWMMMNNWWNK0XNNWMWKOdllooxkkdlc::;,,,''',;;;;:::::cloddl:,''...................................          .lKXNWMWMMMMMWNKKXXXKXNWWWWNNWMMWKOkkkO00O00KXX0xdxxdx    //
//        ......',;cloxOKXK0XWMMWXNNXOk0XKKKKklcccdxdddl:;,,,,,''',;;;;;,;;;;;;::c:;;,,'''''''............................           .lOXXXNWWMWXKKKKXXNNNWWNXKKNWMWN0OOOkkxddxO0KK0xolooo    //
//        .......'''':kKNKOk0NWNXNWWNKKK0kxoolcc::oolodc,'''',,''',,,,,,'',,,,,,,,,;;;,''''''''''..........'''..........            .,dOOO0XNNNX0OOOOOKNNWWX00KXNWWX0kkkxddddx0KKK0kdoooll    //
//       ...,;::,''::l0NNXOOXNXK0KXNNXXXKOdlc;;,,'....'......'''''''''''''''''''''',;,''''''''''''.''....'''''.......               .o00kxOXNXKK0OkkkO0KKKKKKNWWNXXKOkdooooodkKK0kxdooolcc    //
//    .  ...'ckkkkxx0KKXXX0KXKOxxxxkO0000xl:;,,''...................''''''''.......'',,,''''''''''''''''''''........                ,oxOkxkkkkOOkkkkkO0OkOkkk0KKK0Ok                          //
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract OVTC is ERC721Creator {
    constructor() ERC721Creator("Over the Clouds", "OVTC") {}
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/Proxy.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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