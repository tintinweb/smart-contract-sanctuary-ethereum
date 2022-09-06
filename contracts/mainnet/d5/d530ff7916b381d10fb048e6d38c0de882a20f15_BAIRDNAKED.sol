// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Baird vs Baird
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#PP&@@@@@@@@B&&BBG5Y5&@#G&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&[email protected]@@@@@@@@@5!^~~:. .!Y55PPBBB&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&##@@@@@@@&[email protected]&5~^JGY!^.:~~??~:^:~77Y#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@&#&@@@&#@@@&B??55YY^^5&#?:...^7~.:~^.~..:~7YB&@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&@@@&GJ5J!:~^:JGJ:^::^::...^!:~:.::  :75&@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#BB#B&#P??7: :!7~^:^~~^..^::::^:.... ....?&@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@&[email protected]&@@@@&@&GJ?!7J!#&#5J^?Y?:^ ::~?^...^^^.:^.::       :[email protected]@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@&&@@&55G5JJ?7:[email protected]@&YJ&@?   .. ::  .:...:: ..         .?&@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@#B&&@PPB#G???YJY#BY5G&#JP7.    ^:^...  :..:. ..   .. .    :[email protected]@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@&#&#&@#G#&&@@&@@@&@&Y#J75#G!^.   ~B#P5?^  :. .: ::    ....     [email protected]@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@BG&B&&B&@@@@@@&YJ5!7J7. ~7:    ~5&@BYJ.     . .:.  ..    .     7&@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@&#&&5?YG#&&&@@@@#5: .^5#5: .:   :?YG#5!^^... . :.:  .. .... .    :^[email protected]@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@&##Y^^7JB&&@@@&@@G^.J#@G: .5J. .?5#@@B?~.    ...         .        [email protected]@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@&GG57!~!~JB&@BYJY##[email protected]@P. ^B&J. ::7GG^.            ..              :[email protected]@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@&BGPJ7J?!~!~7B&&&?   ~!: !&@#~ 7&@P:    7B~                              ?&@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@&J^^^75GGB&&@@@@&PYJP#B! !&@&[email protected]@G^    J&Y.             .:^!!^          :[email protected]@@@@@@@@@@    //
//    @@@@@@@@@@@@@@#!  !G&@@@@@@@@@@@@@@@@B!?&@@&&##@&J:   :P&J.   ^7^7P5YY5B##YP#P!.   ..   7#@@@@@@@@@@    //
//    @@@@@@@@@@@@@@P:^Y#@@@@@@@&&@@&##&@@@@@&@@@@##@&&B5?~. ^B#~ ^Y5G#@@@@@@#Y7.75J!.        .J&@@@@@@@@@    //
//    @@@@@@@@@@@@@[email protected]@@&#BG57^:^:....!P#@@@@@@&GYPG^.   [email protected]@@@@@&GY!~:.     ..     [email protected]@@@@@@@@@    //
//    @@@@@@@@@@@@&J~J&@&5^.:.     .:::::.!#@@@@P^.?#@B?: :..:: .7#@@@&BBY~...          ..  .::7#@@@@@@@@@    //
//    @@@@@@@@@@@@BJY&&P7:^75BBGPB#&@&B#&&&@@@B57^J&@@@#!.~.   ~?5&@###GGPJ7!~^^:...   ...   !?Y&@@@@@@@@@    //
//    @@@@@@@@@@@&5J5?~7PG#@@@@@&G5JJJP&@@@@&#B5J5&@@@##G~     .^^^[email protected]@@@@@##BGBGBB#BY7^.    :^[email protected]@@@@@@@@    //
//    @@@@@@@@@@@BJY55B&@@GJYJ?7~^^[email protected]@&B5!^!P#&@@@&GGY~          .~?PPBGJ~.   :^^~~7#G^     [email protected]@@@@@@@@    //
//    @@@@@@@@@@&J:^5&@&#G5YJJPG#@@@@&&#?!?7:  :[email protected]@@@#B!.             .:~~!~^:^:. ... ^?!.     ?&@@@@@@@@    //
//    @@@@@@@@@#5~:!YBPP##Y7!?P##[email protected]&5!7?5&@@@@&#J^.        ..      ...:^^::J5J^        .?&@@@@@@@@    //
//    @@@@@@@@#?!^^!5&@@@&BG?Y?J!!JJB&@@@@BB#@@&@&@@@@Y:.    :.    .~^.           ..     .:..  :#@@@@@@@@@    //
//    @@@@@@@@##GGBGB&@@@@@@&#BPJYG#&@@@@BY^7GBY~::7J7~. .          :&B!                  .:::  [email protected]@@@@@@@@    //
//    @@@@@@@@G&@5J##[email protected]@@@@@[email protected]@@@@@@P   .?JJY^?&B?:..            [email protected]@P:              :!^::. [email protected]@@@@@@@@    //
//    @@@@@@@@@&@P~PGJG&BBG#[email protected]@@@@@@B  ^P&@&#[email protected]@@@&#?  .^7JYJ!. ^@@@@B~            ..:: :::[email protected]@@@@@@@@    //
//    @@@@@@@@@@@Y7Y!^~?~~~YJYP#&@@@@@@@@J~&@@@@&&@@@@@@?  !GBG#@G. ^[email protected]@@@&?.            ..:^~~^[email protected]@@@@@@@@    //
//    @@@@@@@&&55P7~^:^..~Y55G&@@@@@@@@@@@@@GJ?JB&@@@@B~7^     .^   [email protected]@@#5?:         ....:^^~?P&@@@@@@@    //
//    @@@@@@[email protected]@@@@@@@@5~:[email protected]@5YY5:        .    [email protected]@@@&P^         .  [email protected]@@@@@@@@@    //
//    @@@@@@#B&GYJP##@&##&&B5^  ?&@@@@@@@B555PJ5&B?7JGY!!JP!.^.       :Y&@@@&J:    .:. ..  ...^[email protected]@@@@@@@@@    //
//    @@@@@@&[email protected]@@@@@@#7.  [email protected]@@@@@@@&&@&&#GB?~:[email protected]@@@@@B5BP!.       ?&@@@&7     :.     . .^[email protected]@@@@@@@@@    //
//    @@@@@@[email protected]@@&@@@@B5~   ?&@@@@@@@@@@@@@J:7: J##@@@@BY~7J~::~~7:  [email protected]@@@&!           ...^[email protected]@@@@@@@@@    //
//    @@@@@@&5!?YJ5GB&@@@&G^  ~#@@@@@@@@@@@@@#?.  :Y???7JJ~.  ~: :5J7:.  ^JP#@@B~.         ....J#@@@@@@@@@    //
//    @@@@@@@@@BYJYB&@@@@&P!.^J#@@@&@@&#BGB&&#GJ7J55YJ7!!!7!~!^.   .:      .^[email protected]@@5      ...   . ^&@@@@@@@@    //
//    @@@@@[email protected]&B#&&GB&@@@@[email protected]@@@@P55P:~!J&@@@@@@&###&#P55P&&&G!^   ...   .:[email protected]@#.      :.. .:[email protected]@@@@@@@@    //
//    @@@@@[email protected]#[email protected]&#&&G&@@@B. :&@@@@@Y755^7#@@&BP&5~.   :.    .^[email protected]^   .     ^@@@~     . . ....#@@@@@@@@@    //
//    @@@@@PB&@@@@[email protected]&&@@@@P: ~#&@@@G&@BP#@@@#!  ^                 !JG!..      .P&@#~.        . [email protected]@@@@@@@@    //
//    @@@@@@#Y#@@@@@@@@#&@&Y. !#@@@@@#J5#@B7::^??YY?!7?JY7~~~~?J??J7^J#P.   :. .?&&G~       . :5G&@@@@@@@@    //
//    @@@@@@@&&@@@@@@@@&@@@P. ^&@@@@@5:7YPYJP&@@@@@@@@@@#@@@@@@@@@@@@@@@7  .PJ  ~#@G:    .::. [email protected]@@@@@@@@    //
//    @@@@@@@@&@@@@@@@@@@@@G. [email protected]@@@@? ^#@@@@@@@@@@@@@@@PP#@@@@@@@@@@@@@B:  7#J.!7G?!   ..::7::~&@@@@@@@@@    //
//    @@@@@@@@@##@@@@@@@@@@J   !&@@@B. [email protected]@@@@@@@@@@@@@@&BP#@@@@@@@@@@@@@7   5B..P&~. ..  : ::G#@@@@@@@@@@    //
//    @@@@@@@@@@#[email protected]@@@@@@#Y?. [email protected]@&P!  !#@@@@@BGGBBG5GG&@B5&@@#[email protected]@@@@@&?  ^JB~7&G^..     .!Y&@@@@@@@@@@@    //
//    @@@@@@@@@@@@@#B#&@@&#5:  5&@@@!. ~&@@@@@@&&###GJPG5Y5J5BB5J#@@@@@@J   [email protected]~?:.^..  ~^~&@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@#PG#&@&J ^?B#&@G!^5&@@@@@&GGGBGG575G5?GGY#[email protected]@@@@#Y:  ^PBJ:. ..:^:^?J7?&@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@&P&&@@P~^^?!#@#G~:J&@@@@@@@@@&[email protected]@@@@@#?   .:J&G!.  ..:^^^[email protected]@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@&#@@@&##[email protected]@@#[email protected]@@@@@@@@BGBBP55G5YY#@@@@@@@5     .?G#5..  .^[email protected]@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@&J~ [email protected]@@@@?: ^&&P&@@@@BP&&GG#@&?J#@@@@@@@B:      [email protected]~   ^[email protected]&@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@BJ^ :: [email protected]@@@@@@@&@@@#5#@@@@@@@#:      [email protected]@P. .:5JG#@B&@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@&#&[email protected]@@@@&G?:   [email protected]@@@@@@@@@@@@@@@@@@@P.       :[email protected]@#~ ~P7??#[email protected]@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@#@&&@#Y&G&@@@@&##!?^   [email protected]@@@@@@@@@@@@@@@@@5         ^JG&B!~~PJ^[email protected]@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@&@@#GB^~5#@@@@@#[email protected]! [email protected]@@@@@@@@@@@@@@@#:       [email protected]~!BG#&5&[email protected]@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@G5G&[email protected]@@@@@@&GG?7&@@7.!PG&@@@&##@&@B&#7  .  .  ~BP55! .:G&@&[email protected]@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@#?JGY?&&&5  ..^^^~..?7PYP.   .     !&GJP^ :.:[email protected]@[email protected]@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@G&@@@@@[email protected]@@@@@@P^[email protected]@@BY!7.:^JGP!?P!^  .^~.    .#@#&7: :!..~G&#&@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@#GB#[email protected]@@@@@@&?!P&@@@@@@&B#&@@@GJ!^^ .:::   .:[email protected]@&#J.:..:Y7Y&@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@BG#[email protected]@@@@@@@&&&@@@#&@##@&##5YBP7 .....      [email protected]@&B57:[email protected]@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@&B#@&&&&@@@@@@@&@B&@###P!^:~5G5.:~^...  ^[email protected]~!.?57Y5B#@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@&#&B##Y^7&@@@@@@@@@@@@@@&B77~!?!^!:.    :[email protected]@GJ:^7J7:?YGG&@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@&P?Y?J&G#@@@@@@@@@##@@@BJYY?J??~.    7&@@G: 77 .?GBB#@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@G7Y55&YG&#&#GGGGG#&&&&PJ5!~7Y7:^:.^^JGB&G?~~: .JPY#&@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@##GPBJ5#&#57!G#PBBGGGJJ~!5#J5????~:!G?P#J: :7YJP&@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BP##5B#G#G?P5JB#GYYBY?:~#@GPYJ^...:^7BBJ:~!YB&@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@#&&@&[email protected]@#P^  ^!~~^YJ^^^77P&@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&@@@@@#[email protected]&@@#&#YJ:.~J&&@#P7^755!7YY7^?5#@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@#[email protected]@@@@@@@@&&Y.7#@@#G&#[email protected]&#@##@#P&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@&@&&@@@@@@[email protected]@@@@@@@@&&#@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@&@@@@@&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BAIRDNAKED is ERC721Creator {
    constructor() ERC721Creator("Baird vs Baird", "BAIRDNAKED") {}
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