// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Naked Galina
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    ####&###############################################################################################    //
//    ############################################BBB#####################################################    //
//    ######################################GGB####BP5G##P5B###B##########################################    //
//    #######################################PJ?J5GB#G?7PBPJYPB#5B#BP#BP5JJ5B##BB#########################    //
//    #####################################G5???!^~!7?JJJ?YPJ7JP5?GY5Y7!^JGPY??YG#######B#################    //
//    ####################################Y~~~7~~~~!~~~!!J?JJYJ???!5J~!~!?7~!?JYY5PP5JYYPB################    //
//    ###################################57?75?^~~~~~^Y7~!JJ??J??777J7!~~~~~~~~^~!!!~~JPBB################    //
//    ###################################57^?J^7J~~~~!5!!7PJ?J?77?????7!!~~~^~~~~~~~~~~!!7?7YYYG##########    //
//    #################################BY??!57?YJ^~!^?Y^?JP7JJJ??7777?J777!!~~~~~!~!!~~~~7?5GGB###########    //
//    ################################5!7J??B5~Y?~Y7^JJ??!P~?55J7777!!YJ!??PY7~~~Y!!J!~!!!???5G###########    //
//    ###B##########################P7!JJ?!YBJ!J?Y7~~75Y~~5?JJ???77?77!5?!757Y?!!Y!!7J~7Y??7???JG#########    //
//    ##BBB#######################B5JPG?~!~Y???YPY^~~~P?^~YP7?PJ??JJ?!!7P7YY!!5!7J~~~Y!?J~^^~JYGPG########    //
//    ###BB##########################P!~^~~~~!??#J~!7~Y!YY75?GY??J^:J7!!5YP?77?YJ7~~~JJ5!~~!~J7?##########    //
//    ####B#######################BG?!?7^^^^~~~!PJ?55~~?PY~!J?7!5^..^G7!55Y?5?7GY!77~JG7!!?P!!Y?5G########    //
//    ############################GP5Y7!7~~~~~?!~!YJ~Y^J??7~5:JJ!::::GJ!75GJBJ75?777!YY~~!?5Y75?#GB#######    //
//    ############################BY~^~Y?!!7Y!55~~Y?.7JJJ.Y!5 J5 ::::B?~YJPP!57!G7!7!J7?7!~YYPY^Y##B######    //
//    ##########################G?~~7~^5!^~5!7?J?~Y7.:~YP ~5J ~G..:.7B7Y7?B^~57YP!~!777!JJ?7?GJ~~P########    //
//    ########################B57?YJ!~^Y7^J?^!Y.Y!?? ..:Y7.^Y. !^. ^B5J^~P~ Y5?~Y~7G?JJ!7?7?7?YY5~P#######    //
//    ########################GGG5!~~~~J?!5~~~Y~.Y757?YPPPYYY?7!!~^JY~..^..!?^.!J7?5JJ5!!~~!!7?P#J!#######    //
//    ########################BY~~~~~~~7YY?~~~!Y.~PGBB^!#PG#5PPG5YY555YJ?!!!: ^5?!.57!57~!J~!!!?B#JB######    //
//    #######################P!~?7~~?!~!GP~~~~~7Y.5GBGJY###BGG~BP5YPJ?#5BBG5P?!:: ?Y~!7P7?Y^?5!!P#BB######    //
//    ######################5~?BJ!~Y?~!~B??~~~~^755BBG5J?Y5GBBJBG?~G?7####G7YPP?^!P!777YY7577JP!!B#B######    //
//    #####################B?P#P~~~5!~~!?!5~J?~!~JGGBPYJJ7!~~?GP7 ^PBGGGGBBG7GGPPP?7Y7!!5JP!~~5BYY########    //
//    #####################BB#B7~!75~~!~~75^YPJ~!~PJ5GGY?775P5?^...Y5~7J5B#BP#BG57JP?!!!?P5~7!^P##########    //
//    ########################Y~7!JY~?5~!YJ~JYJJ~~5^.^!7?JJ?!:.....:Y5~~!?JYG#GJ7J5!~!77!5P~7P77B#########    //
//    #######################P~??^Y?!PY^?5!~?5~5~!5....:.... ........JY5GBB#BG!^!J!!!!777??!~P#!G#########    //
//    ######################PY5J~!5??Y?7Y7!~YY^5?Y~...::::^::.........:^~!7?7: ?J~~!!J77?7~!7Y#PG#########    //
//    ######################BY!~7J?!~5JJ7~~!P7!55^.:..::::~^J?..^~.:.......^:.J?~7J775Y??!7?~7############    //
//    ###################&#57~~~5!~~JJ!5J~7Y7!JP:.:....:::^:.:..!7^^.......^:7Y7J55!7?P?!!!?J?P###########    //
//    ###################GYY5J!~57!!!~Y#7JY~~~75 ....:.:!!~~^^:::....::....::YJJ!5Y??JP~!!77?GPB##########    //
//    #################BGG##5!!!P!!!!YYP?5~7?~757.....~?J7!~^~^^^!:..::::.:.~GJ~?P7!~?G777??!!P###########    //
//    #################B##GY??~JY~~~7P~5P?~7GJ??~?:...?7777!!!!~~~?.::..:.:7?G7JY!~!~JP77?7Y~!!P##########    //
//    ##################B?~J5Y?P?777!5?7GP!~!5?Y!:?~ .:?!~77!!77?Y?.:...:!57!?YJ!77!~Y5!57~YY77Y####B#####    //
//    ################B5YYJGJ75J777?YJYY5BY??7Y^~..?!..:~!!!~~^~!?^...:!!?P77YYJ5J77!P?Y577!57~J##########    //
//    #################BY!:5?55777777J5Y???7PYJJ .  !?^:::^^~~^^:J:.:!7^^5JYYPYJ5Y??!5J5!~~~!P~J##########    //
//    ################G!. !Y?G??77!!JJ7YY!!!Y7Y5:.: .:7!~:::.:..!5!~~::!JGY75G??G?77?JBJ7!7!?#5Y##########    //
//    ###############Y. ..J7PJ5P777!?PYJGJ??Y5PP5JYJ5!7?JJYY?777PY^^~!!!Y5!~Y?!P??J77!?!BY??P##B#B########    //
//    ##############P!??^.JJPJ5P???7!YY?G?7?GG5YPP5YG55G?7?JPBG5G5.~GY5BG7!J?!JY7P?!~!~~G5!~Y#B###########    //
//    #############PYYYP!7Y55PJJ!7?7!JP7JG?J#5PY7~55PP5G. .7J5J?P5?!GYP7P75G7YYJP7~?~!!!JYJ77G####B#######    //
//    ##########&BPYYY!JJ5JJJJY!~~55~J5!55YY5P5PY!J!GBYGJJY5B7^^7JGGYP~ J5#Y7?JY7JP7!!!!!J?75YG###########    //
//    ###########GY555?J?PY7775!!?5YJ5J!5YG?^5!?PPP5GBJ55?7?B?!~.JBYG5 ..?BJ?5J?55??77YJJ7P^Y#BB##########    //
//    ###########5Y777!^:~??7?5!!PJ?GP77JG7:P#Y~:7Y5JGYGJ .:7JBY!B5PPPY~.:P7JG!JJ~^^~^Y?Y?G!:B############    //
//    ##########?J:. .....:P7J5!5Y7?YJ7775:^PBYPJ?55JG555YY5555BPYGJ.5GP5P57Y?JJ~!7JP~5~?JP^:B#####B######    //
//    #########P...:......JY!75YG???7JJ777Y^YBY55P5P55G5P7JG?77YYJYJ?YJ7?7^7YJ5~^JJ7PYY~~5~ ~###BB########    //
//    #########!......::.75?Y7YPY7777P?Y!^57.~.:~^:!:.~:^..^..::~^:......!J7!JG?YJ!7P7!7!P: ^B###B########    //
//    ########5..::....:?5?!5??YY???7Y~^Y~JJ..::.......::::....::^^^:..:Y?~!7?YYP!~?Y?7~JJ..^B####B#######    //
//    ########!...:....:^:. ?JJ!^5?7~5!.!YY^::::.::.::...::....::::^^^.?Y!J57755JY???PJY?.. 7####B#B######    //
//    #######B^ .......::...?YJ:.57!?5::^Y~:::.:.::.:..::..:::.:..:::^^?YJ?J!!JP~75!~Y57:...P#######BBB###    //
//    #######B:......:.:::..??5.:Y~!5^.:::::::.:.::::..:...:..::.:.:::^:P?J?!!~!~Y~.J75..::7#B#####BB#####    //
//    #######G...:::::::::.~7 Y!!J^J7..:::::::.::::.:.....::.:..::..:.::^!~J!~!5!Y: 7^^:...Y##############    //
//    #######Y ........:..^?..:^7?~5:..::::::.::.:::::.::.:.::..::..::::::.!57JJ?7? .?^.:.^B##############    //
//    #######!...........:J:.::.:J!Y!:^^::::::::::.:.:.::.::::...:..:...:..:PYJ 77J?:.J:..5#B#############    //
//    ######B:...::::::..J^......~??G7~!7^:::..:::......:.::...::::...:^~~~~5Y7::..~!.:Y 7################    //
//    ######G:..:::.::::^?......~?:?5P?^^Y^:....::.....::..:....::::.:?~^~~YY?7:^:.... J!B################    //
//    ####B#B:.:::::::::~7...::.7!:JJYJ^~J::.:...::.:. J^? ......:...77:?5YP^:?!.^^... ?B#########B#######    //
//    ####B#B:.::::::::::J:.:...:~~~~~!!7^::::::::::: ~? ?^ .........^?^^!!~^^J^:^^:.. 5##################    //
//    ####BBB^::::::::::.^?:.:....:::^^::^^:.:::::::.^?..:J:.....:....^!~~~~!!: ::^::.7BB#################    //
//    ######B^.::::::::::.^J:.:.......::::^^::..:..:!!..:.:?^.....:......:::.....::::?B###################    //
//    #######!.::::::::::..YJ~:..:::.::::::^^:..:^!7^......:!!:...:................~5#B###################    //
//    #######J:.::::::::::.J~^!~:.::..::::::^~~!!^:.......:..^!!:.............. .!5B####################B#    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NAKEDG is ERC721Creator {
    constructor() ERC721Creator("Naked Galina", "NAKEDG") {}
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