// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Elizabeth Colomba
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#####B#########BB#@@@[email protected]@@##BB#######&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@&&&&&&&&&###############B#B#BB##B##BBBBBB##GJ7JB#BBBBBBB#B###################&&&&#&&&&&&&&&@@@    //
//    @@@@@@BBBB##B&##GP#GGBBGBGBBGBBGBGGBGBBGBGBBGBBGY?PB57YGBBGBGBBGBBGBBBBBB##BBBGGGGGGGBBBBBGBBBB##@@@    //
//    @@@@@@[email protected]#BBBBGBGGGBBGGBPGGBBGBBGBGGBGGBBB57Y##B#BJ?5GGBPGBBBGBBBBBBB#######&###&########B#&#@@@    //
//    @@@@@@[email protected]#B#@@GG#@&GB#BGG&BB&&GGB##G&G??G##BBB#&PJG##BBBBBB###&&&G5J?5&57^^[email protected]!~~~!!7?G##@@@    //
//    @@@@@&####GGB###B#@@@&GPPGGG&#B#GGPP&BGBBGGY75##BBB#BBB#######BB&[email protected]@J:  [email protected]!  7#@&~^ ^?7!^Y&#&@@    //
//    @@@@@###Y#B##BB#&&#G#BGBG5BBBG#@&#BBBGPPGPJJB##BBBB#BB#BBPY?!^.~#5^. :[email protected]^  [email protected]!. 7#@#~^ [email protected]@#PP&B&@@    //
//    @@@@@##B5BG##B&&&PGGGGB&#B#PGBG##B##GBBGGBBBBB###[email protected]@5~. .^!?J#P~.  :PY^  [email protected] 7#@#~^ ~55GBG##&@@    //
//    @@@@@#BBGB#@#GG5J77JY5PB#&&BPGB####BBBB#####G5?!^.  ?&@G~. ?&@@@@P~.   :7~  [email protected] 7#@#~^ .. ?BGBB&@@    //
//    @@@@@#BB#G5?!^..^^:  . :!YB#&&#####B#&B5J!J&7^  ~?YPG&@G~. 7#G&@@G~.^7  ..  [email protected] 7#@#~^ 7BBGBGBB&@@    //
//    @@@@@#&GJ!:.  75B&&BJ^^   .7G#&[email protected]#.  [email protected]?! [email protected]@@@@@G~. ..^[email protected]@G~.:BY     [email protected] !#@#~^ 7&@#BGBB&@@    //
//    @@@@@@Y!~    YG#@@@@@P:!.   :PB?:  7&@&:  [email protected]?! .J55&@@@G^: ^YP#@@G~ :[email protected] [email protected] !#@&~^ !PBBPB#B&@@    //
//    @@@@@5~!    [email protected]@@@@@@J.!    :G7~  ?&@&:  [email protected]!  . ?#@@@G^: [email protected]@@&@G! ^[email protected]@B^  [email protected]^  [email protected]::     .G&B&@@    //
//    @@@@&^?     [email protected]@@@@@@@#.~:    ?Y~  ?&@&:  [email protected]!  JB#&@@@G^: 7G5J~GG~ :P&@@&! Y&[email protected]&BGPP5YJJB#B&@@    //
//    @@@@B:?    [email protected]@@@@@@@&::~    ~5~. ?&@&:  [email protected]! [email protected]@@B&@G^:     ^BG?YPB&@@@&PG&&&&&&#####&&&&BBBBB&@@    //
//    @@@@&:?.    [email protected]@@@@@@@#.^^    ??~. ?&@&:  [email protected]!  ?J!:!#@Y:~7J5GB&&&&&&#####B##BBBBBBBBBBBBBBBBB#BB#@@    //
//    @@@@@Y:7    [email protected]@@@@&@J.!    :5?~. 7#@G. .J&?~   .:~J#@##&&&&&###B##############&B##BB##B#B#BG#BB#@@    //
//    @@@@@@Y^!.   5G#@BJ?!~...   :YBB~^ .~!.  7P&77J5GB#&&&####BBBB#BB##B#B#BBBB#&#BB&####B#B###&BGGBB#@@    //
//    @@@@@#&G7~^.  ?5B#GP!.^^:  [email protected]@GJ!^.  ^JB#P#@@&###BBBBB######B#B#B###&&&&#B#&G?YGGPG5GBPPGPGGGBB#@@    //
//    @@@@@#B##GY7!^. :~^.   :!~^. .!YG#BGP5PBGJ^JP&#B####&&&@@@@@#&&@@@@@@@@@@@&BGB#BJ?GB#&B#GJP#BGGBB#@@    //
//    @@@@@#BBGB#BBGY7!~!!7J5GGY7!^:.  .^~~~^::~YG&#&&@@@@@@@@@#5YJYB&@@@@@@@@@@@@#BG##P?YB#PGBP&GGGGBB#@@    //
//    @@@@@#BBGB#BBB&&########B##G5J?77!!7!!7YPB&@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@#GB##Y75P5#5G#BGGBB#@@    //
//    @@@@@#BBGB&#BBBBBBBBBB##&&@@@&&#BBBB###&@@@@@@@@@@@@@@@5Y7:.!P5#BB&@@@@@@@@@@@@&BGB#BJJB&GPGGGGBB#@@    //
//    @@@@@#BBGBBPPGJJB#BGB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BP?.:.. :[email protected]@@@@@@@@@@@@@#BG##P7JGP5BGGBB#@@    //
//    @@@@@#BBGBGPY7Y##BG#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#B5.:^:  ?G#@@@@@@@@@@@@@#[email protected]@#GB##Y?5GGGGBB#@@    //
//    @@@@@#BBGBP?JB#BGB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@P~~^!J&@@@@@@@@@@@@@#[email protected]@@&BGB#G??PBGBB#@@    //
//    @@@@@#BBGY?P##GB#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#P5PY?!JP&@@@&BGGBGPG?!PYP#@@@#GG##57YGBB#@@    //
//    @@@@@#B5?Y##BG#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@J7?7::JP7:^:..~7JJ5^  :^^.^~7PB5&@@@&BGB#BJ?PB&@@    //
//    @@@@@B??G#BGB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@7:..  ?Y5~^ .!^     :.  ?G5GPB&&[email protected]@@@@&BGB#P?J#@@    //
//    @@@@P75##BB#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?:7 : ~#G7..!!:   :. .^ ~5&&&#[email protected]&&@@@@@@@#GB##[email protected]    //
//    @@@@57P##BB#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@P!:J~ :.!7^:^~:..  !^::.:[email protected]?#@@@@@@@@@@#BB##[email protected]    //
//    @@@@@B??G#BGB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&7. ~B^  ^?^..    .^!PG?!:^!5&@@[email protected]@@@@@@@@&BGB#P?J#@@    //
//    @@@@@#B5?Y##BG#@@@@@@@@@@@@@@@@@@@@&&#B#BBB#G7.:[email protected]#577!..^!?YPG#&@@&[email protected]@@@[email protected]@@@@@@&#GB#BJ?PB&@@    //
//    @@@@@#BBGJ?P##GB&@@@@@@@@@@@@@@#57?!^^^~:.:!.:[email protected]@@&#&BY5B&&&#[email protected]@@@@#[email protected]@@@[email protected]@@@@@#GG##57YGBB#@@    //
//    @@@@@#BBGBP?JB#BGB&@@@@@@@@GY7~^:.^5J7!7?J5&##@@@&PJ?GP5GP5555JP&&BBGGGB#&&57YJ#@@@@&BGB#G??PBGBB#@@    //
//    @@@@@#BBGBBPY75##BG#@@@@@&P??7Y7^~~:      .:~7YPY^.^?5~ ^?J??JPPJ7!~~^7G#&&&&&&&&@&BGB##Y?5GGGGBB#@@    //
//    @@@@@#BBGBB5PGJ?G&#GB&@@@@B#&##BB7  ..  .          ...J^ .  ..J######[email protected]@@@@@@@@@#BB##P7JGP5BGGBB#@@    //
//    @@@@@#BBGBBGPG&G?JB#BGB&@@&@@@@#7   ^? !57  .      ^7 JP .    [email protected]@@@@@[email protected]@@@@@@@&BGB#BJJB&PPGGGGBB#@@    //
//    @@@@@#BBGGB#GP#55J75##BG#@&@@@5:    .! PY#P~~57:  [email protected]# .  ^[email protected]@@@@@[email protected]@@@@@@#GB##Y7YP5#5G#BGGBB#@@    //
//    @@@@@#BBGBGG&PBGG#BJ?G#BGB#@#!    .  . [email protected]#@@PJB#P?P&@@#P ^?G#[email protected]@@@@@#[email protected]@@@@#BG##P?YB#PGBP&GGGGBB#@@    //
//    @@@@@#BBGBBBPJG#B&BGP7Y##BGJ.         .:[email protected]@@@&[email protected]@@@@@@B:^[email protected]@@@@@#[email protected]@@&BGB#BJ?GB#&B#GJP#BGGBB#@@    //
//    @@@@@#BBGBGPGPPBP5GPGGY?GY:           .^[email protected]@@@@@&@@@@@@@@#??J5G#@@@@@@#[email protected]@#GB##5?YGGPG5GBPPGPGGGBB#@@    //
//    @@@@@#BBGBBG5G&P#PG5BGB5!^    .J.    ^.? [email protected]@@[email protected]@@@@@#G&BGB&G??GBGB5GP#5&G5GGGGBB#@@    //
//    @@@@@#BBGBPPPP####GGBG?: 7?^..55     Y!P:[email protected]@@##&&&&&###BBBBBBG#@@@@@@#PBB##Y7YGPPGGGG####P5PPBGBB#@@    //
//    @@@@@#BBGBG#G#BBP&GB?:  .!##[email protected]~     G##[email protected]@@@@@@@@@@@@@@@@@@@@@@@@#BB##P?JG#GB#&G#P&PBB#GBGGGBB#@@    //
//    @@@@@#BBGB##5#BP##J: .!J5B#G5JJ:     [email protected]@? [email protected]@@#BBBBBBB########&@@@&BBB&BJ?PG#[email protected]&PB#@BP##5#BGGBB&@@    //
//    @@@@@#BBGBB#P#[email protected]@#GPPP5Y7~^.  [email protected]@P [email protected]@@[email protected]&#BB##Y75PGPPG#@@&B#&GBG5#P#BGGBB&@@    //
//    @@@@@#BBGBPB&@?^.~?~  G#B#[email protected]@#[email protected]@@@@@@@@@@@@@@@@@&&#BB#&G?J5GPGGBBB#&BGB&#[email protected]#GPBGBB&@@    //
//    @@@@@#BBPPJ?Y!.   .^^7GBBB&&###BG5~.:!#&&@@@@@@@@@@@@@@@@@@@@&BBB&BJ?5BBB##&&BBBGPGPPPB&#B&PPBGB#&@@    //
//    @@@@@#BBY:. .:::[email protected]&&###&&##BBBY   :##BB#@@@@@@@@@@@@@@@@@#BB##57JGGGBB&&&&###&&#B&#B##BG5GGGBB&@@    //
//    @@@@@#BBGGPG55PY&BGGBPG#BB#BG5B#B~...^YB&#BB&@@@@@@@@@@@@@&BB#&G?YGGGGB#G5GB#BBBGGBGG&#P&#B#BGGBB&@@    //
//    @@@@@#BBGB#@BB&P#BPGGGGGGB#BPPB&Y^~~?~ ~P##BB#&@@@@@@@@@&#BB##Y?5GB&&&B&BPG##BPGGGGGPB#P#[email protected]&@@    //
//    @@@@@##BYBB##B#&#PPPGGB&#B#PGBG#^   ^Y:7??G&#BB#@@@@@@@#BB##P7?PGBB&####GBGP#B&&BGGPPP###B##BP5##&@@    //
//    @@@@@###5#BB#BB#&&#G#BGBG5BG#G&5   !YJYGG57JB#BBB&@@@&BB#&B?7PGPPGBBB#&@#GBGBPGBGB#G#&&#B##BBG5&B&@@    //
//    @@@@@&####GGB###B#@@@&GPPGGG#Y~~~:~GY5GBBBGY75##BB#&BBB##Y?YGBBBGB#PPBG#BB&[email protected]@@@#B###BGG&###&@@    //
//    @@@@@@[email protected]#B#@@GG#@&GG7^^~7?P&@BGB##G&G??G##BBB##P?JB&G#BBGG&&GB#GGB#BG&@#[email protected]@BB#[email protected]#@@@    //
//    @@@@@@[email protected]#BBBGBGGBGGBGBY7Y##B#[email protected]#@@@    //
//    @@@@@@BBBB##B&##PY#GGBBGBGBBGBBGBGGBGBBGBGBBGBBGY?PB57YGBBGBBGBGBBGBGGBGBBGBGGBGBBGG#5BB##B##BBB#@@@    //
//    @@@@@@&&&&&&&&&#########################B##B#####GJ7JB###########B######################&&&&&&&&&@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BB##B###@@@[email protected]@@###B###[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Queenie is ERC721Creator {
    constructor() ERC721Creator("Elizabeth Colomba", "Queenie") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x80d39537860Dc3677E9345706697bf4dF6527f72;
        Address.functionDelegateCall(
            0x80d39537860Dc3677E9345706697bf4dF6527f72,
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