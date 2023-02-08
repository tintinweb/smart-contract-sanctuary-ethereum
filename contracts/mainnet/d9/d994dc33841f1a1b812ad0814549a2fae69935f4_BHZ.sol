// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BeatHeadz Checks
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0OkkxdoollccccccccccccclloodxkkO0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0kdol:;,'........'',,,;;;,,,,,,'........',:coxO0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0dc'...';:lodkOO0KXXNNWWWWWWWWWWWNNXXKK0Ox:  ',...':dOKKKKKKKKKKKKKKKKKklo0K0KKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0o'..:dOKNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWk' .xNKOdc..'o0KKKKKKKKKKKKKKx' .xKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKc  .;:;;:cokXWWWWWWWWWWWWWWWWWWWWWWWWWWWWNd.   dWWWWWXo..:OKKKKKKKKKKKKd.  .xKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKko:.           'xNWWWWWWWWWWWWWWWWWWWWWWWWWXl..:. oWWWWWWWx. ;dOKKKKKKKK0l... .xKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKOo;.               .xWWWWWWWNNXXXKKKKKKKKKXXN0:  lk, oWWWWWWW0,   'ckKKKKKO:..dc 'kKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKkc.                 .,dkdlc:;,'''...........'''. ,:;;. cKNWWWWWx.     .:kKKk, .,c' ;OKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKk,                   .....',::ccccccc:::::ccc:.  'kK0c. ..';coo:.        .od. ,xdc. c0KKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKl              ,odoooodxxxdolc;,''............ .::;co; .ldl:,'..          ...,,cxl..dKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKc             ,OKKKKOdl;'.......''',,,,,,,,'  ,kK0ko;.  .;cokO0d.          'x0kl:. ,OKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKK:.,; .c.      ;00xc,.....',;;;;;;;;;;;;;;;. ..;OKKKKo. ......'cc.         .l0KKKd..oKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKK0llKO,oXk'     .:'...',;;;;;;;;;;;;;;;:;;'..,xx:;codo. .;;:;,'..         'oo:;coo' :0KKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKK0:.;kX0l.       ..';;;;;;;;;;;;;;;;;;;;,.  'kKK0kol;. .,;;;;;;;;,..     'kKK0kd:. 'xKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKK0:.:kK0o'.     .,::;;;;;;;;;;;;;;;;;,.. .co;;d0KKK0c..,:;;;;:;;;;:,.  ;c;;okOOkc..dKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKOclKO,lXO'     .;;;;;;;;;;;;;:;;;;,..  .lKK0o;:loo;..,;;;;;;;;;;,..  ,OK0dc:c:. .o0KKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKK0O, ,, .:.      .;;;;;;;;;;;;,,;,'. .cc,.cKKKK0xo;. .,;;;;;;;;;'...;o,'kKKKKKk:..dKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKK0kdc;'..  .....      .;;;;;;;;;;;;,......cK0Oo,:dO0K0o. .;;;;;;;;,'....oKKkc;cdO0x,  :k0KKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKK0xc,..,coxo':0KKK0Oko:'  .,;;;;;;;;;;:,. 'o,;OKKKOoc::;'..';;;;;;;;;,. 'l,;OKKKko:,'.    .,:d0KKKKKKKKKKKKK    //
//    KKKKKKKKKKKOl,..:x0NWWXc;KWWWWWWWWWXkc...;:;;;;;;;;;' .ox:;lxOKKKk;  .,:;;;;;;;;;;. .xk:;lxO0Oo. .'. .;c'.'cx0KKKKKKKKKK    //
//    KKKKKKKKKOl..,xXWWNxo0o,OWWWWWWWWWWWWNO; .,;;;;;;;;;;. .oOxc;;:l:. .,;;;;;;;;;;;;;'  'okdc;,'.  .,:;. .xXOc..;x0KKKKKKKK    //
//    KKKKKKKKx,.,xNWWWWx,,,'xWWWWWWWWWWWWWWWK; .''';;;;;;;'   .,;;'     .',;;;;;;;;;;;:'    ..''...',....,' .xWWKl..lOKKKKKKK    //
//    KKKKKKKx'.cXWWWWWO,oXkkNWWWWWWWWWWWWWWWWk. ''..';;;;;,. .::,'.     .......',,;;;;:' ...  .',;;::;'.  .  .xWWNk'.:OKKKKKK    //
//    KKKKKKO, :XWWWWWK;cXWWWWWWWWWWWWWWWWWWWWX; .;.  .,;;:;. .c;..     .,loc;,.......... .od,. .,;;;;;;'.     .kWWWO'.l0KKKKK    //
//    KKKKKKl 'OWWWWWWKkXWWWWWWWWWXKXWWWWWWWWWWx. ,,    .,;;.        ..,:lxkOOkkdoc'       .;:,.  .....,;'.     'OWWWo.'kKKKKK    //
//    KKKKKk' lWWWWWWWWWWWWWWWWNk:...;kNWWWWWWWNc .,. ', .',.  ..,;:ldxkkkkkkkkkkOd,.                   .'.     .,0WW0, cKKKKK    //
//    KKKKKo..kWWW0o:;:dKWWWWWNo.     .oNWWWWWWWx. .. ..     .:dxkOOkkkkkOOOkkkkkkxollccc::::;;,,''....'..     .occ0WNl ,OKKKK    //
//    KKKK0: ;KMWx.     .kWWWW0'       'OWWWWWWWO.    .,:c,  ,dddooollcc::;:okkkkkkx;';:;;;::;;:::::::lxkc.    .xW00WMk..dKKKK    //
//    KKKKO, cNM0,       ,0WWW0'       '0WWWWWWWx. ;l:;;;;;..,;:;.     'll'.ckkkkkkk,.oOkxxxl.   .:o:.'xOd.    .dWWWWW0' lKKKK    //
//    KKKKO, lNW0'       .OWWWWd.     .dNWWWWWWO,  :kk;.ckkOOO0KKd;...,xKx.,xOkkkkkOd''xKKKKKo,,;l00:.lkOx'    .dWWWWW0'.oKKKK    //
//    KK0K0; ;XMNo       :XWWWWNOl,',lONWWWNKkc.   cOkd,'o0KKKKKKKKOkO00o',xkkkkkkkkkd;'cx0KKKKKK0d;'lkkOx'    .kWWWWNo.'kKKKK    //
//    KKKKKx..cKWNx;. .'oXXdlxXWWWNNNWXo:;,'.     .oOkkxc,,cdO0KKKKK0xl;,cxkkkkkkxxxxkko:,;;:c:::;;cdkkkOd.    '0WXKk:..dKKKKK    //
//    KKKKKKx,..:ox00O0NWWd.  ,0WWWWWWK,          'dOkkkkxo:;;;:::::;;;lxkkoc;;,,,,;,,,;lxdllcccldkkkkkkOo.    cOc'..'ckKKKKKK    //
//    KKKKKKK0xl:. ;KWWWWW0ddxOXWWWWWWWx.         :kkkkkkkkkkkxdodddxkOkkl'',;:ccloxdlc;.,dkkOkkkkkkkkkkk:    .xc 'dk0KKKKKKKK    //
//    KKKKKKKKKKKx. oWWWWWWWWWWWKx0WWWWNc        'dOkkkkkkkkkkkkkkkkkkkOo..ldl::lool;;ll..dOkkkkkkkkkkkOd.    ok'.oK0KKKKKKKKK    //
//    KKKKKKKKKKK0; :XWx:kWWWWWWo ,KWWWWx.      .lkkkkkkkx::xOkkkkkkkkkkd,.,:;,:oddol;'',okkkkkxdxkkkkkx;    cXd..xKKKKKKKKKKK    //
//    KKKKKKKKKKKKl ,0Wl ,KWWWWWk..xWWWW0'     .lkkkkxdkk:..ckkkkkkkkkkkkxl:;;cxkkkkkdodkkkkkkl,,lkkkkk:.  .oXNl ,OKKKKKKKKKKK    //
//    KKKKKKKKKKKKd..kMx..OWWWWWX: cNWWWO'    'okkkkko,;:.;'.okkkkkkkkkkkkkkkOOkkkkkkxxxkkkOk:.:kOkkkk:. .:OWM0, c0KKKKKKKKKKK    //
//    KKKKKKKKKKKKk, cXO' dWWWWWWd..kX0x, ..;lxOkkkkkko:,';;,';xOkkkkkxdoodkkkkkkkl;;;;,,cc:,,lkkkkkx;..cdlcoo,.;kKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKx'.,;. ,x0KKOx;  .....:dkkkkkkkkkkkxdkkkkko,,:lol:;;;;;,,lxkkd;'cxkko....:xkkkkko'  ....,,,:oOKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKOoc:::'..'...,coo:..;xkkkkkkkd:;ol,:xkkkkkko:;;;:oxkOkxl;;;;,:dkkkkk:..:kkkkkxc..;lloxO0KKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKK0kxdxkO0KKK0x,..:dkkkxldx:..'dkkkkkkkkOOkkkOkkkkkkkxxxkkkkkkkOd,;xkkkxl..'d0KKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0d,..;okx:,;',c;cxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxc'..lOKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKK0kdc;;x0d;..'co,.',okkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkko;..,oOKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKK0xc,. .  :0K0kl,.  ,oodkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxo:..  .:x0KKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKK0kc'...',;. .xKKKK0xc,..';cokkkkkkkkkkkkkkkkkkkkkkkkOOkxo:,.  .''.. .'lkKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKK0x;. .';;;;:,. ,OKKKKKK0ko;. ,xkkkkkkkkkkkkkkkkkkkkdoc:;'....  .;;::;,'. .:kKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKO:. .,;;;:;;;;,. ,kKKKKKKKKo..lkkkkkkkkkkkkkkkkkkkkx,  .;coxo' .,;;;;;;;;,. .lOKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKx' .,;::;;;;;;;;,. .ckKKK0KO, .:lodxxkkkkkkkOOkkkkkkxc. c00x:. .;;::;;;;;;:;'. ,kKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKx' .;;;;:;;;;;;;;:;'...,ldO0o.     ....'',,,,,,,,,,'......;,. .,;;;;;;;;;:;;;;,. 'kKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKO, .;;;,,,;;;;:;;;;:;;,.....'.        ';  ,clcccccclll' .:. .',;;;;;;;;;;;;,,;;:,. ;0KKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKo. ''..  .,;;;;;,;:;;;;;;;,'.         cc  .:odxxxxkkkd.  'c'.;;;;;;;,;;;;:'   ..'. .dKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKK0:   .'c:. ';;,.. .,;;;;;,'...        .l,    .,kXXXNNWk.   :l.'::;:,. .',;:. .:c.    cKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKK0:  ,d0Kx. .,. ..  ';,'....''.      ..'dc...   .oXWWWNl .,;,.  .',;'  ....,. .kKOo'  c0KKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKxco0KKKO,   .;xx' .. .,lxOKd.      :, ',,;;co;  ;OWWK, .l;    .. .. ,kd,.   ;0KKKOocxKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKd'.;x0K0:   ,x0KKKKl       :;      c0:   .oXx.  'o'   ;o'   l0K0d,.,xKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKOk0KKKKk;.cOKKKKK0:       ;;'xl. .okl'..  :c..,;'    .xO:.:OKKKK0kOKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0O0KKKKKK0;       ;:.'.,;...',;,,,;lc,.       cK0O0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKO,       ,:   ..          ,:.        ;0KKKKKKKKKKKK0KKKKKKKKKKKKKKKKKKKKKKKKKK    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BHZ is ERC721Creator {
    constructor() ERC721Creator("BeatHeadz Checks", "BHZ") {}
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