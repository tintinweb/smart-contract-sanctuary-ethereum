// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Rules of Parallels
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    !!!!!!!!?JYP#&&&&&&&##&&&&&&&&&&BY7~:.....................:^^::::~?????77??JYPGB&&&&#5?~:...........    //
//    !!!!!!7JJ5B&&&&&&&&&55B##&&&&&&&&&BPJ!^:....................:^^::~????????7?JY5G#&&&&&#P?~:.........    //
//    !!!!!?JYG#&&&&&&&&&&Y?7JPB##&&&&&&&&#B5?~::....................::~????????????JYP##&&&&&#GY!^:......    //
//    !!!7JJP#&&&&&&&&&&&#Y?~~!7YPB##&&&&&#&&#GY7^:....................:~7??JJJJJJ?????YPB#&&&&&&B57~:....    //
//    !!?JYB&&&&&&&&&&&&&#Y?~~~~!!?YGB#&&#BBB#&&#PJ!^:...................:^!?JJJJJ??77?77J5B##&&&&&#GJ~:..    //
//    ?JJP#&&&&&&&&&&&&###Y?~~~~~~~!!?5G#P5GGBB##&#B5?~::...................:~7JJJ?77777!!7?YPB#&&&&&#BY!^    //
//    Y5B&&&&&&&&&&&&&####5?~~~~~~~~~!!7YJJJY5GGBB##&#GY7^:....................^!??7!777!!!!77J5B#&&&##&BP    //
//    G&&&&&&&&#&&&&###BB#5?~~~~~!~~~!!!??7??JJYPGGBB#&&#GY!^:...................:^~~!7!!!!!!!!7?YG#&GGB#&    //
//    &&&&&&&#BG#&&###BP?!77~~~~~~~~~!!!JJ7777??JY5PGB####&BP?~:....................:^!!!!!!!!!!!77YPY5PGG    //
//    &&&&&#BBGG#&###GY7^...:^~~~~~~~~~!?????7777??JY5B#PPB#&#BY7^:...................:^~!!!!!!!!!77J!7?Y5    //
//    &&&&#BGGPP#&##P?!!^......:^~~~~~~!?????????777??5GY555PB#&#GJ~::...................:^~!!!!!!!7?^:^!7    //
//    &&#BGGPPPP#&GJ!!!!^.........:^^~~!?J??????????77?J7?JY555PB##B5?~:....................:~!!!!!7?::::^    //
//    #BGGPPPPPPGY7!!!!!^............:^~7??????????????7^~!7?JY55PGB##B57^:...................:^~!!7?:::::    //
//    BGGPPPP55J7!!!!!!!^...............:~7??????777???7::^^~!7?JY5PPG#&#GJ!^:...................:~!?:::::    //
//    GPPPP55J7!!!!!!!!!^..................:~7???!!!!!77:::::^^~!7JY5PG#B##BP?~:...................:~:::::    //
//    PPPP5Y7!!!!!!!!!!!^.....................:~!~~~~~!7::::::::^^~7?YPBPPPG##B57^:......................:    //
//    PP5Y?!!!!!!!!!!!!!~........................:^^~~!!:::::::::::^~!?P55PP5PB##GY!^:....................    //
//    P5J!~~~~~~~!!!!!!77~::........................::~!:::::::::::::^~?7?JY5P5PGB##GJ!^:.................    //
//    J7!~~~~~~~~!!!!7??77?7~^:........................:.:::::::::::::^7~~!7?J5PPPPG##BP?~::..............    //
//    !!~~~~~~~~~!!7?JYGBB##B5J!^:..........................::::::::::^7^::^~!7?J5PPGB#&#B5?~:............    //
//    ~~~~~!~~~~!7?JYG&&&&&&&&#BPJ7^:..........................:::::::^7^:::::^~!7?YPG#&&&&#B57^:.........    //
//    ~~~~~~~~!!?JYG#&&&&&&&&&&&&&BPY7~:..........................::::^7^::::::::^~!?YG#&&&&&&#GJ!^:......    //
//    ~~~~~~!!?JYP#&&&&&&&&&&&&&&&&&&#GY7~::.........................:^7^::::::::::^^!YPB##&&&&&&BP?~:....    //
//    ~~~~~!7?JP#&&&&&&&&&#PB###&&&&&&&&#G5?~^:........................^:::::::::::::^?7?YPB##&&&&&#BY7^:.    //
//    ~~~!7?J5B&&&&&&&&&&&BY?YPB###&&&&&&&&#B5?!^:........................:::::::::::^77!77?YPB##&&&&##GJ!    //
//    ~!7?J5B&&&&&&&&&&&&&BJ!~!7YPGB##&&&&B##&#BPJ!^:.........................:::::::^77!!!!77?YGB#&&GGB#B    //
//    7??YG&&&&&&&&&&&&&&&BJ!~~~!!7J5GB#&#PGGBB#&&#GY7~:........................:::::^77!!!!!!777J5GB5PPPG    //
//    JYG&&&&&&&&&&&&&&&##BY!~~~!!!!!7?5BPJJY5PGBB##&#G5?~^:.......................::^77!!!!!!!!!77?Y??Y5P    //
//    G#&&&&&&###&&&&&&###BY!~~~!!!~!!!!JY7???JJ5PGGB#&&#B5?!^:.......................~!!!!!!!!!!!!7J~~!7J    //
//    &&&&&&##BG#&&&&&#BB#BY!~~~!!!!!!!!?Y?7777??JJYPGB&##&#BPJ!^:......................:^~!!!!!!!!7J^:^^~    //
//    &####BBGGP#&&&##BBB#BY!~~~!!!!!!!!JY???77777??JJ5#GGBB#&&BPY7^:......................:^~!!!!!7J7~^^:    //
//    &&&&##BGPP#&&###BG57??!!~~!!!!!!!!JY????????777?JGYY5PGGB###BPJ!^:......................:^~!!7Y??7!~    //
//    ###&&&&&#B#####GY7~:..:^~!!!!!!!!!JYJJJ???????777Y???JJ5PGGB###BPY7^:......................:~!YJ????    //
//    GGGGB#&&&&&###P?!!~......::^~!!!!!JYJJJJ????????7Y?777???JY5GGB##&#GY7~:.....................:^!?JJJ    //
//    GPPGGGGBB#&&&&#B5J7:.........:^~~!JYJJJ??????????Y??77777???JY5PB#####GY?~:.....................:^!?    //
//    GGGGGGGGGPJJ5B#&&&BP?~::!~:......:~7?????????????Y?????77777???JYBBGGB###B5?~::....................:    //
//    GGGGGGG5?!~~~!7YP#&&&#GG&#PJ!:......:^~7?????????Y??????????777??P55PGGGBB##BP?!^:..................    //
//    GGGGG5?!~~~~~~~~!7?YP#&&&&&##GY7^:......:^!7?????Y??????????77777YJ??J5PGGGGB##BPJ!^:...............    //
//    BBGY7!~~~~~~~~~~~~~::J#&&&&&&&&#BGY^.......:^~7??YJ??JJJJJJ?????7JJ777??JYPGGGB#&&#PY7^:............    //
//    GY7~~~~~~~~~~~~~~~~:.:~YG&&&&&&&###G??!:.......:^77?JJJJJJJJJJ???JJ????77??J5PGB#&&&&#GY7~:.........    //
//    !~~~~~~~~~~~~~~~!!?!::..:!5B&&&&&&&&&&#GY!:.......:^~7JJJJJJJJJ??JJ??????????JJ5B&&&&&&&#G57~:......    //
//    ~~~~~~~~~~~~~~!7?????7!^::.:7G&&&&&&&&&&&#GJ~::^~!7JYYPGGGGGP5YYJJJ????JJJJJ????5GB##&&&&&&#B5?~:...    //
//    ~~~~~~~~~~~~!7JJYG#####G5J!^:^!?Y5B&&&&&&&&&#GG##&&&&&&&&&&&&&&##BG5YJJJJJJJ??77JJJ5GB##&&&&&&#B5?~:    //
//    ~~~~~~~~~~!?JYPB&&&&&&&&&&#G5?!^::^75B&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#BPYJJJJ?7!!J?777J5PBB##&&&BB#BP    //
//    ~~~~~~~!7?JYG#&&&&&&&&&&&&&&&&#GY7~::!G&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&B5J??7~!?7!!7777?YPGB##GPPGB    //
//    ~~~~~!7JJ5B&&&&&&&&&&B###&&&&&&&&&BPYG&&&&&&&&&&&&&#B#&&&&&&&&&&&&&&&&&&&&GY7~^~?7!!7777777?J5GYY5PP    //
//    ~~~!?JYPB&&&&&&&&&&&B55GBB###&&&&&&&&&&&&&&&&&&&#BB#&&&&&&&&&&&&&&&&&&&&&&&BJ~~~?7!!!!7777777?577?JY    //
//    !7?JYG#&&&&&&&&&&&&&BY77?J5PGB###&&&&&&&&&&&&&###&&&&&&&&&&&&&&&&&&&&&&&&&&&G~^~?7!!!!!!777777Y~~~!7    //
//    JJ5B&&&&&&&&&&&&&&&&BY!!!!!7?J5PGB#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&!.:^~!!!!!!!!7777Y~^^~~    //
//    G#&&&&&&&&&&&&&&&&&&BY!!!!!!!!!77JP#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&7....::~!!!!!!!7?Y~^~~~    //
//    &&&&&&&&##&&&&&&&##&BY!!!!!!!!!!!!YP#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#~........:^~!!77?Y~~~~~    //
//    &&&&&&###B#&&&&&###&BY!!!!!!!!!!!!YJY#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#J.............:~!7?!~~~~    //
//    &&&###BBBB#&&&&&###&BY7!!!!!!!!!!7YJ~?G&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&B?:................:^^~~~~    //
//    &##BBBBBBB#&&&&#####GY7!!!!!!!!!!7YJ~!!JG#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#5~....................:^^^~    //
//    #BBBBBBBBG#&&&##BGY7~~!7777!!!!!!7YJ~~~~!7YG#&&&&&&&&&&&&&&&&&&&&&&&&&&B?^:................::^^~~~!!    //
//    BBBBBBBGGG#&&#B5?7~.....:^!!777!!7YJ~~~~~~~~7?YPB##&&&&&&&&&&&&&##BBGGB#BG5?~::.........::^^~~~!!!!!    //
//    BBBBBBGGGG##GY7!!!~.........:^~!77YJ!!!~~~~~~~~~!Y77?JJYYYYYJJJJJPYJY5PPPGBBG5Y?~^:..:^^~~~!!!!!!!!!    //
//    BBBBGGGGP5Y?!!!~!!~.............::~!!!!!!!~~~~~~!J~~^^^^^^^^^^~~!J????JYYYY5PGGGPJ~^^~~!!!!!!!!!!!!!    //
//    BBGGGGPY?!~~~~~~!!~..................:^~!!!!!!~~!J~~~~^^^^^^^^^^~J!~!77?77?JYYJ7!~~~!!!!!!!!!!!!!!!!    //
//    BGGG5J7!~~~~~~~~~~~......................:^~!!!!!J~~~~^~~^^^^^^^~?!~~~~~~~!!~~~~~?7!!!!!!!!!!!!!!!!!    //
//    GPY7!~~~~~~!~~~~!!~...........................:^~7!!~~^~~~~^^^^~~?!~~~~~^^^~~!!!!J7!!!!!!!!!!!!!!!!!    //
//    ?!~~~~~~~~~~~~!!~~~...............................:^^~!!~~~~~~~~!?!~~^^~~!!!!!!!~J7!!!!!!!!!!!!!!!!!    //
//    ~~~~~~~~~~~~~~!!!!~....................................:^~!!!!~~~!~^~~!!!!!!!!!!~J7!!!!!!!!!!!!!!!!!    //
//    ~~~~~~~~~~~~~~!!7??~^::....................................:^~~^^~~!!!!!!!!!!!!!~J7!!!!!!!!!!!!!!!!!    //
//    ~~~~~~~~~~~~!7?JJY555Y7!~^::...............................:^^~~!!!!!!!!!!!!!!!!~?7!!!!!!!!!!!!!!!77    //
//    ~~~~~~~~~~!?JY5P#&&&&G5YJJ??7!^::.....................::^^~~!!!!!!!!!!!!!!!!!!!!~?7!!!!!!!!!!!77?JYY    //
//    ~~~~~~~!7JJ5G#&&&&&&&&&##BG5YYJJ?7!^:..............:^~!!!!!!!!!!!!!!!!!!!!!!!!!!~?7!!!!!!!!7?JYY5PG#    //
//    ~~~~!7?J5P#&&&&&&&&&&###&&&&&#BGP5YJ?7!~^::.....::~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!~?7!!!!7?JYY5PG#&&&&    //
//    ~!7?J5P#&&&&&&&&&&&&#GBBB####&&&&&#BP5YJJ?7!^::^~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!~?77?JYYY5GB#&&&&&&&    //
//    ?JYP#&&&&&&&&&&&&&&&BY?Y5PGBB#####BBBBBBPJ!~~~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!77J5YY5GB#&&&&&&&&&&#    //
//    GB&&&&&&&&&&&&&&&&&&BY7!77??Y5PPP55YYYY?!~~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!77?JYY5GB#&&&&&&&&&&&&&BG    //
//    &&&&&&####&&&&&&&&&&BY7!777777?????7~~~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!7?JYY5PB#&&&&&&&&&&&&&&&&&##    //
//    &&&##BBBBB&&&&&&&&&&BY7777777!!!~~~~~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!7?JYY5PB#&&&&&&&&&&&&&&&&&&&&&##    //
//    ##BBBBBB##&&&&&&&##&BY77777!~~~~~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!7?JJY5PG#&&&&&&&&&&&&&&&&&&&&&&&&&##    //
//    BBBBB#####&&&&&&###&B577!~~~~~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!7?JJY5PG#&&&&&&@&&&&&&&&&&&&&&&&&&&&&&##    //
//    BB########&&&&&####&GJ~~~~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!7??JY5PG#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&B#    //
//    #########&&&&&#####BJ!~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!7?JJY5GB#&&&&&&&&#BGGB&&&&&&&&&&&&&&&&&&&&&&#5P    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ROP is ERC721Creator {
    constructor() ERC721Creator("The Rules of Parallels", "ROP") {}
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