// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kye Honoraries
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNX0kdoc:;'...             .cddoolloo:,;codk0KNWMMMMMMMMMMMMMMMMMMMMMMWWWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOxoc;'............             .oOKKKKKx' ......';:ldOKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0xo:'. ................               'lxO0d' .............';cdOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0xdoodl,.  ................                  ... ................  'lodOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkdoodk0KKx;.  ................                     .................  ;kOdolox0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxolok0KKKKKKk;.  ................                    ..................  ;OKKK0kolod0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd::ok0KKKKKKKKKOc.   ...............                   ...................  :OKKKKKK0OdllxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMNkc.  .;ok0KKKKKKKK0o'.  ................                 ...................  .l0KKKKKKKKK0kolokXMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWKxlc'      .,lx0KKKKKKk:.   ...............                 ...................  .dKKKKKKKKKKKKK0x:,oKWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWKdlokx;.        .':ok0KK0d,.  ...............                 ...................  :OKKKKKKKKKKKOxl,. ..c0WMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMW0oldO0k:.  ..         .,cokOo'   .............                  ..................  .d0KKKKKKKOxl;.       ..:OWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWKdcdOKKOc.  ......          .',..   ............   ..              ................  .l0KKK0kdl;..             .c0WMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMXxcoOKKK0o'.  .........                   .......   .;:;,'.....      ...............  .:xxoc;'.           ...     ..oKMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWOllk0KKKKk;.  ..............                        .;:c::;;,,,'....   ............     ..             .:ldkkkdl,. ...,xNMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMKocx0KKKKK0o'.  ...............            ......      ...............                                  'xKKKKKKKK0d' ....c0WMMMMMMMMMMMM    //
//    MMMMMMMMMMMWOclOKKKKKKKOc.  ................             ........                                           ...      :0KKKKKKKKKKx. ....'xNMMMMMMMMMMM    //
//    MMMMMMMMMMNd:d0KKKKKKKKk:.  ................              .:ccc,.                     .....          .........       ;OKKKKKKKKKKO; ......lXMMMMMMMMMM    //
//    MMMMMMMMMKlck0KKKKKKKKKk;.  ................                .,;. .....        ..,;::clllol;.   ..............        .o0KKKKKKKKKO; .......:0MMMMMMMMM    //
//    MMMMMMMM0clOKKKKKKKKKKKk;.  ................                    ......   ..,;lxO0KK0KKKKKOc.  ...............         .d0KKKKKKKKx' ........,OWMMMMMMM    //
//    MMMMMMMO,':ccccclllloodl'.  ................                   ...    .,cdkO0KKKKKKKKKKKKx,.  ...............          .:k0KKKKK0l. .........'kWMMMMMM    //
//    MMMMMWO'                            ........                       .,lxO0KKKKKKKKKKKKKKK0d'.  ...............            .;ok000x' ...........'kWMMMMM    //
//    MMMMM0,............                                             .,lxO0KKKKKKKKKKKKKKKKKK0o'.  ...............               ..',. .............'kWMMMM    //
//    MMMMK;.................   .'',,'.                             .;oxOOOOOOOO000000KKKKKKKK0o'.  ...............                     ..............,OMMMM    //
//    MMMXc...............     ;x00000Ox:. ......                   ..............'',,;;:clodxkl'.  ................                   ................;KMMM    //
//    MMWo..............      ,kKKKKKKKKKx, .....        ......                               ..     ...............                   .................lNMM    //
//    MMO'............        c0KKKKK0kxoc'    ...',;:lloddo;.   ....................                       .........                  ..................xWM    //
//    MX:............         c00koc;'.....,:codxkO000KKK0x;.  ....................    'codddoc,.  ..             ....                 ..................;KM    //
//    Wx............          .,'....,:ldxO00KKKKKKKKKKK0x;.  .................       ;kKKKKKKK0d,.........    ..                      ...................oW    //
//    X:............          ..,coxk00KKKKKKKKKKKKKKKKKk;.  ................        .dKKKKKKKKKKk, .......... .;c:,..                            ......  ,0    //
//    x.............      ..;ldk00KKKKKKKKKKKKKKKKKKKKKOc.  ................         .xKKKKKKKKKK0c ..........  'x0Oxoc;..                                .d    //
//    c...........      'cdk0KKKKKKKKKKKKKKKKKKKKKKKKK0d'.  ...............          .oKKKKKKKKKKO: ...........  :OKKKK0kdc,.   ........     ...           ;    //
//    '..........       .oOKKKKKKKKKKKKKKKKKKKKKKKKKKKO:.  ................           ,kKKKKKKKKKd. ............ .d0KKKKKKK0ko:'.   .    .;oxkkkdl;. ....  .    //
//    ..............      ,d0KKKKKKKKKKKKKKKKKKKKKKKKKx,.  ...............             ,k0KKKKKKk, .............  :OKKKKKKKKKK0Odc'.     c0KKKKKKK0x, ......    //
//     .............       .;d0KKKKKKKKKKKKKKKKKKKKKK0o'.  ...............              .lk0KKKk, ..............  ,kKKKKKKKKKKKKK0Odc'. .:k0KKKKKKKKk' ....     //
//     .............         .,d0KKKKKKKKKKKKKKKKKKKK0l.   ...............                .;lol' ...............  .dKKKKKKKKKKKKKKKK0Od:...;dOKKKKKK0; .....    //
//     .............            ,oOKKKKKKKKKKKKKKKKKK0l.   ...............                      ................  .o0KKKKKKKKKKKKKKKKKK0xl,..'lk0KKKk, .....    //
//     ..............             .cx0KKKKKKKKKKKKKKK0l.   ................                    .................  .o0KKKKKKKKKKKKKKKKKKKKKOo'  .ck00l. .....    //
//     ..............               .;oO0KKKKKKKKKKKK0o'.  ................                   ..................  .d0KKKKKKKKKKKKKKKKKKKK0kc. ...':c. ......    //
//     .............                   .:dOKKKKKKKKKKKx;.  ................                  ...................  'xKKKKKKKKKKKKKKKKKK0Oo;.  .'cxd'  .......    //
//      ............    .                 .:dO0KKKKKKKOc.   ...............                  ...................  ;kKKKKKKKKKKKKKKKKOd:.      .:l:. ........    //
//         ........   .;;,'....              .;ok0KKKKKx,.  ...............                 ...................  .l0KKKKKKKKKKKK0Od:.              ........     //
//                   .;cc::;;,''....            .':ok0K0o'.  ..............                  ..................  'xKKKKKKKKKKOxl;.                .........     //
//    .              ...............                .':od:.   .............                  .................  .l0KKKKK0Oxl:'.                  ...........    //
//    '                                                 ...    ...........   .'....          ................  .:OK0Oxoc,.                      ...........,    //
//    l......                         .....                          ....   .;c:::;,'......   ..............   'cc:,..                         ............c    //
//    O'..............                                                      .,;;;;;;,,'.....   ......                                          ............k    //
//    Nc................                            ......         .......                                                 'ldxxdl;.            ..........:X    //
//    Mk'...............               ....  ................     ,;,'........                 .................          :OKKKKKK0Ol. ...          ......kW    //
//    MNl................         .';coo:.  ...............      .x0Okxdolc::;.                 .',,;::cloddxkkkdl:'.    .o00KKKKKKK0o. ......         ..cNM    //
//    MMK;...............    ..;coxO0K0o'  ...............       .oKKKKKKKK000l. ............   ;xOOO00KKKKKKKKKKK0Oxoc,...';ok0KKKKKk' .........  ...  ,0MM    //
//    MMWk...........    ..;ldk0KKKKKKk;.  ...............        ,kKKKKKKKKKKl. .............  .o0KKKKKKKKKKKKKKKKKKK00kdc.  .,cdOKKd. .........  .lo,'xWMM    //
//    MMMWd......     .,cdk0KKKKKKKKK0o'  ...............          ,x0KKKKKKK0: ...............  ,kKKKKKKKKKKKKKKKKKKKKKKKx,  ..,;ckk, ........... .cx:dNMMM    //
//    MMMMNl.     ..;oxOKKKKKKKKKKKKKOc.  ...............           .ck0KKKK0d. ................ .l0KKKKKKKKKKKKKKKKKKKKOo. ..,d00Ox, ............  ';lXMMMM    //
//    MMMMMXc  ..:ok0KKKKKKKKKKKKKKKKk:.  ...............             .,ldkkx, .................  ,kKKKKKKKKKKKKKKKKKK0d,   .:k0K0o. .............  .cXMMMMM    //
//    MMMMMMXc.ck0KKKKKKKKKKKKKKKKKKKk;.  ...............                 ...  .................  .o0KKKKKKKKKKKKKKK0x:.     'ldd;. ..............  :KMMMMMM    //
//    MMMMMMMXo:kKKKKKKKKKKKKKKKKKKKKk:.  ................                    ................... .cOKKKKKKKKKKKKK0x:.            .................cXMMMMMMM    //
//    MMMMMMMMNd:x0KKKKKKKKKKKKKKKKKKOc.  ................                    ...................  ;OKKKKKKKKKKK0d;.             .................lXMMMMMMMM    //
//    MMMMMMMMMNx:o0KKKKKKKKKKKKKKKKK0l.   ................                  ....................  ;kKKKKKKKK0Oo,.             ..................dNMMMMMMMMM    //
//    MMMMMMMMMMWOclkKKKKKKKKKKKKKKKKKx,.  .................                 ....................  ;OKKKKKK0x:.               .................,OWMMMMMMMMMM    //
//    MMMMMMMMMMMMXo:d0KKKKKKKKKKKKKKKOc.   ................                 ....................  cOKKK0xl'.                .................lKMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWkclk0KKKKKKKKKKKKKKx;.  .................                 ..................  .o00xc,.                   ...............,kWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMXdcoOKKKKKKKKKKKKK0o'.  ................                 ..................  'c:'.                     ...............oXMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMW0lcd0KKKKKKKKKKKKOl'.  ................                  ..............               .,'.           .............c0WMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWOl:cdkO0KKKKKKKKOl'.   ..............    .              .........                  .;c::;'...       ..........:OWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMNk:...,:ldxO00KK0o,.   ............    ':;,,'''......                             .',;;;;,,'....   ........:kNMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMNOc.  ....';:clol,.   ...........   .:c::;;,'.....          ......',;;'.             ..........   .....cONMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWKo,............                  .......                  .,:ldk000l.                           .,o0WMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMXkc'..................                                  .ckKKKK0o. .......         ..........:kXMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKx:,,;cc:;,'''......                                   .:okkl. ..............   .::,..':xKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxolldkOkkxxddoo:.             ......                  ..  ................  ;olclxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkdolodO0KKKKx,.  ................                     ................. .:okXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkdolldkOx;.  ................                    ...............';lxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOxdol,.   ...............                   ...........';ldOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0xoc:,...............                 .....',:cox0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0xoc,...                       ..,:ox0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Kye is ERC721Creator {
    constructor() ERC721Creator("Kye Honoraries", "Kye") {}
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