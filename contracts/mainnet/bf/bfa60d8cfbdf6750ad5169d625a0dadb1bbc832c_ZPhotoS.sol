// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Photos Sold
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//    [email protected]@@@@@@@@@@@@@@@@@&[email protected]@&[email protected]@&[email protected]@@@@@@@@@@@@@@@@@#YG5P5PPP5    //
//    [email protected]@@@@@@@@@@@@@@@@@[email protected]@&[email protected]@[email protected]@@@@@@@@@@@@@@@@&5P55P#BPYP    //
//    &[email protected]@@@@@@@@@@@@@@@@G?GJ7?5!?Y5!&@&[email protected]@P!PJ??57?5P?&@@@@@@@@@@@@@@@@@PYGYY55JPP5    //
//    @&B#BB##BB###@@@@@@@@@@@@@@@@@&#&BB#&BBB#[email protected]@@##BBB&#BB#B&@@#B#GBB#BBB##@@@@@@@@@@@@@@@@@&P#GGG#GGG#G    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    [email protected]@G5G5YGP55B5&@@@@@@@@@@@@@@@@[email protected]@YY5??P?7?P7#@&JPY??PJJYPY&@@@@@@@@@@@@@@@@PGGPP#[email protected]@    //
//    [email protected]&[email protected]@@@@@@@@@@@@@@@G~57!7J!7Y^[email protected]@7!J7~J!!7J:#@#^[email protected]@@@@@@@@@@@@@@@[email protected]@    //
//    5Y&@#[email protected]@@@@@@@@@@@@@@&[email protected]@J??!YG57!Y!&@[email protected]@@@@@@@@@@@@@@@[email protected]@G    //
//    [email protected]@[email protected]@@@@@@@@@@@@@@@!?J7^[email protected]@?~J!^[email protected]@5^Y!~?!!?Y~#@@@@@@@@@@@@@@@[email protected]@G?    //
//    [email protected]&JGYJ5PJYGY#@@@@@@@@@@@@@@@[email protected]@[email protected]@[email protected]@@@@@@@@@@@@@@@[email protected]&YP    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@&@    //
//    [email protected]@GGG5PBP5BP&@@@@@@@@@@@@@@&[email protected]@[email protected]@5G5Y5GYYG5&@@@@@@@@@@@@@@@G#GG#BBB##@@####    //
//    Y!?57#@[email protected]@@@@@@@@@@@@@&~?7^!7^7J:&@5^J~:?^[email protected]&^?7~!!^!J^&@@@@@@@@@@@@@@[email protected]&!Y!^    //
//    [email protected]@[email protected]@@@@@@@@@@@@@@??~~YP7^?~#@[email protected]&~J^[email protected]@@@@@@@@@@@@@@?J!?5P?7Y7&@Y7!7?    //
//    [email protected]!Y?!Y!!J^[email protected]@@@@@@@@@@@@@J~7~~?~!J:[email protected]^?!~J~!?^[email protected]#:[email protected]@@@@@@@@@@@@@B^[email protected]!Y77P    //
//    [email protected]@[email protected]@@@@@@@@@@@@@BJ57?57?5?#@[email protected]#[email protected]@@@@@@@@@@@@@57J!7J~757&@YJJ!?J    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&@@#&##&#    //
//    #GB#[email protected]@GBP5BP5GP#@@@@@@@@@@@@@@PG5YG5YPP#@&PG55G55GP&@#[email protected]@@@@@@@@@@@@@&BBBB#BB##@@#&##&&#    //
//    5?!J^!Y7&@?77^!!^[email protected]@@@@@@@@@@@@@~?!^7^~?^[email protected]^J~:?:~J:[email protected]~?~^7:[email protected]@@@@@@@@@@@@@J!?^!7^[email protected]&!5!~J!7    //
//    [email protected][email protected]@@@@@@@@@@@@@7?^[email protected]^7^?P?^?~#@J!~~YY~^[email protected]@@@@@@@@@@@@@~7^7Y7^7^[email protected]!77YY!!    //
//    [email protected]@~?!~J!!J^#@@@@@@@@@@@@@[email protected]:?~^?~~?:&@[email protected]@@@@@@@@@@@@B^[email protected]@!?!75J~?    //
//    Y5J7577Y?#@[email protected]@@@@@@@@@@@@[email protected]#?5775775?&@[email protected]@@@@@@@@@@@@[email protected]!7J^?J    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&@@@&&#&&##&    //
//    @[email protected]&[email protected]@@@@@@@@@@@@#[email protected]&[email protected]@PG55G55GP&@@@@@@@@@@@@@GBPGBGG#[email protected]@B#BB#B##&    //
//    @YJJ!J~7Y!&@!J!~?^[email protected]@@@@@@@@@@@@B^?~^!^[email protected]#^?~^7:[email protected]@~?!^?^~?^&@@@@@@@@@@@@#[email protected]#!Y!!J!J?P    //
//    @[email protected]~7PJ~?~#@@@@@@@@@@@@#~7^?5!^[email protected]#~7^?57:[email protected]&~7^?P7^[email protected]@@@@@@@@@@@@[email protected]!!75Y!?7#    //
//    @#[email protected]~7~7!~?^[email protected]@@@@@@@@@@@#:7~^7^[email protected]&:7~^7^[email protected]&^?~^7^[email protected]@@@@@@@@@@@@Y~7^7!!7^[email protected][email protected]    //
//    @@[email protected]#[email protected]@@@@@@@@@@@&J5??5[email protected]&[email protected]&[email protected]@@@@@@@@@@@@[email protected]@[email protected]    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    [email protected]@@[email protected]@@@@@@@@@@@@[email protected]&[email protected]&[email protected]@@@@@@@@@@@@[email protected]#[email protected]@    //
//    [email protected]!J7?!~?^#@~7~^?^[email protected]@@@@@@@@@@@@~7~^[email protected]&^?~^7^[email protected]^7~~7^[email protected]@@@@@@@@@@@&^?~^7^[email protected]!7^[email protected]@    //
//    [email protected]&[email protected]~7P?^[email protected]@@@@@@@@@@@@77^7BJ^[email protected]&~7^?P7^[email protected]~!^[email protected]@@@@@@@@@@@#~7^[email protected][email protected]#    //
//    7&@[email protected][email protected]@@@@@@@@@@@@7?!^7^[email protected]&^?~^7^[email protected]^?~~!^[email protected]@@@@@@@@@@@G^[email protected][email protected]    //
//    G&@BBPGB5PP#@#[email protected]@@@@@@@@@@@@[email protected]@[email protected]&[email protected]@@@@@@@@@@@#Y5J55YP5&@[email protected]    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    P&@[email protected]#[email protected]@@@@@@@@@@@@[email protected]&[email protected]#PPYP5JP5#@@@@@@@@@@@@[email protected]&Y5?Y5YPY#@G    //
//    5#@[email protected]#5P5P55GY&@@@@@@@@@@@@[email protected]&[email protected]#5P5P55P5#@@@@@@@@@@@@[email protected]&YP55P5G5#@5    //
//    #@@&&&&&&#&&@&###&&B##@@@@@@@@@@@@@&BB#&#B#[email protected]@&#&&&###&@&###&&B##&@@@@@@@@@@@@&###&#B#[email protected]@###&&#&#&@#    //
//    B&@#[email protected]&#B#B#G#[email protected]@@@@@@@@@@@@#BBPBGG#[email protected]&[email protected]&#BBG#G#G&@@@@@@@@@@@@&B#G#B##[email protected]@BBBG#G#G&@&    //
//    &@@&&&&&&#&&@@@&@&@&&&@@@@@@@@@@@@@@&&#&&&&&@@#B#B&B###@@&#&&&#&&@@@@@@@@@@@@@@&&&&&&&&@@&&##&#&#@@&    //
//    #@@&&#&&#&&&@&&&&&&#&&@@@@@@@@@@@@@&&&&&&&&&@@&@&&@&&@@@@&&&&&&&&@@@@@@@@@@@@@@@&&@@&@@@@@@&@@&&@@@@    //
//    ?&@[email protected][email protected]@@@@@@@@@@@@[email protected]&[email protected][email protected]@@@@@@@@@@@[email protected]@[email protected]    //
//    [email protected]&[email protected][email protected]@@@@@@@@@@@@[email protected]#^[email protected][email protected]@@@@@@@@@@@P!7!YJ7J!&@[email protected]    //
//    [email protected]!J!??~7^#@[email protected]@@@@@@@@@@@@~7^!Y!^[email protected]#^7^[email protected][email protected]@@@@@@@@@@@G~7!YY!?!#@[email protected]    //
//    [email protected]!J7!Y7&@[email protected]@@@@@@@@@@@&!J~^?^[email protected]#~J~~7^[email protected]!J~!!^[email protected]@@@@@@@@@@@[email protected][email protected]#    //
//    @@@@@@@@@@@@@@@&&@&&&&@@@@@@@@@@@@@&&##&####@@##B#&###&@&########&@@@@@@@@@@@@@####&##&@@&&#&&&&&&@@    //
//    @@GBPGBPGB#@&GBGBBGBB&@@@@@@@@@@@@@##B##BB#&@&##B#####&@&##B##B##&@@@@@@@@@@@@@####&###&@&##B##B#[email protected]@    //
//    @&[email protected]!?^7!!J~#@@@@@@@@@@@@B~J~~7^[email protected]~J^~7^[email protected]~J~~7^[email protected]@@@@@@@@@@@@[email protected]#[email protected]    //
//    @[email protected]~7PJ!?~&@@@@@@@@@@@@[email protected]^!^[email protected]^[email protected]@@@@@@@@@@@@[email protected]&[email protected]    //
//    @Y??!J~~7~&@[email protected]@@@@@@@@@@@@[email protected]^[email protected]^[email protected]@@@@@@@@@@@@J777Y?7J!#@[email protected]    //
//    @[email protected]&[email protected]@@@@@@@@@@@@[email protected][email protected]#[email protected]@@@@@@@@@@@@[email protected]&    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&@@@@&&&@@&&@@@@&&&&@&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    [email protected]@PG5YG55GP&@@@@@@@@@@@@@BBGPBGGBG&@#BBGBBGGB#@@BBGB#GG#[email protected]@@@@@@@@@@@@@B#[email protected]@BBGPBPPBG    //
//    [email protected]&~J7^[email protected]@@@@@@@@@@@@@~?!:7^~J^[email protected]!?^!!^[email protected]#~Y!^?^!Y!&@@@@@@@@@@@@@7J7~J~7Y!#@J?J!J7?57    //
//    [email protected][email protected]@@@@@@@@@@@@&~?^75?^7^[email protected][email protected]&~?^?P?~J!#@@@@@@@@@@@@@[email protected]?Y    //
//    577?:~?^&@!?7^[email protected]@@@@@@@@@@@@B:?~~J~~?:#@[email protected]&^[email protected]@@@@@@@@@@@@[email protected]@7J?7Y??5    //
//    [email protected]&JPJ?5??PJ&@@@@@@@@@@@@@G7Y!!J~7Y!&@[email protected]&[email protected]@@@@@@@@@@@@&JP??5??5J&@P55J55Y5    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    [email protected]@5GYYG5YGP#@@@@@@@@@@@@@@[email protected]@[email protected]@[email protected]@@@@@@@@@@@@@&[email protected]@BGGPGBP    //
//    [email protected]!J!~J!!J^#@@@@@@@@@@@@@@!J7^!~^[email protected]@!?7^[email protected]@7??~!7^[email protected]@@@@@@@@@@@@@#[email protected]??Y?    //
//    [email protected]@[email protected]@@@@@@@@@@@@@&~?^[email protected]@[email protected]@J?77YP?!J7&@@@@@@@@@@@@@@[email protected]@YY?JGB    //
//    [email protected]~J7!?^~?:[email protected]@@@@@@@@@@@@@G^[email protected]@^?!!??!~?^&@[email protected]@@@@@@@@@@@@@[email protected]#7YJ?5    //
//    [email protected]@[email protected]@@@@@@@@@@@@@@[email protected]&!Y7~??~7Y!&@[email protected]@@@@@@@@@@@@@&[email protected]@PP5J5    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&@&&&&@@@&&&&&&&&&&@@&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    5GP&@&PBPPBBGG#[email protected]@@@@@@@@@@@@@@@#&B#####&#@@&#&##&###&#@@&#&##&##B&#@@@@@@@@@@@@@@@@#&#B####&[email protected]@&B#B    //
//    [email protected]@[email protected]@@@@@@@@@@@@@@#7P?!J?7JP7&@G~57~J7!?Y!&@B!5J7Y?!?57#@@@@@@@@@@@@@@@[email protected]@5PP    //
//    PY&@BJ5?5GPJJ57&@@@@@@@@@@@@@@@P?Y?JPY?75!&@G~J7?5Y?7Y!#@#[email protected]@@@@@@@@@@@@@@#JPJYGGPYP5&@#5G    //
//    ?#@#[email protected]@@@@@@@@@@@@@@@[email protected]@[email protected]&[email protected]@@@@@@@@@@@@@@@[email protected]@BJ    //
//    [email protected]@[email protected]@@@@@@@@@@@@@@@&[email protected]@[email protected]@[email protected]@@@@@@@@@@@@@@@&[email protected]@G    //
//    @@@&@&&&&&&&&&@@@@@@@@@@@@@@@@&B&BB##BB###@@#B#GB#BGG#B&@@###BB#BBB#[email protected]@@@@@@@@@@@@@@@@&&&##&&&&&&@@@    //
//    @&&&&&@@&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    #YG5JJPYYPG5&@@@@@@@@@@@@@@@@#JGJ7?P?JJP?#@@[email protected]@[email protected]@@@@@@@@@@@@@@@@#[email protected]    //
//    [email protected]@@@@@@@@@@@@@@@@575??7Y7JYY!&@&[email protected]@G7PYJJPJYYPJ&@@@@@@@@@@@@@@@@@PPBPPBGGGBGG    //
//    #BB#&&[email protected]@@@@@@@@@@@@@@@@@GGG5G##[email protected]@&5BPPB&#[email protected]@#5B5PB&#PPBP&@@@@@@@@@@@@@@@@@&B#BB#@&BB#B    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ZPhotoS is ERC721Creator {
    constructor() ERC721Creator("Photos Sold", "ZPhotoS") {}
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