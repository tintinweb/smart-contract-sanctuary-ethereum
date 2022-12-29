// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Samanta
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    !!!!!77!!!!7!!!!!!!!!!!!!!!!!!7~~~^~^^^^^^^^!~^^^^^::::::^::^~^^^^^^^^^^^^^^^^^^^^:^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~~^^~^^~~~!^::::^^:^^::.    //
//    !!!!!!!!!!!!77!!!!!!!!!!!!!!!!?~~~~^^~^^^~~~!~~~~~~~^^:^^^^~!~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~~^:::^~~!^~~^^^^:::::::::.    //
//    77!77!!!!!!!!7!!!!!!!!!!!!7!~!!77!!!!7!~~!~~^^^^~^^^^~~^^^::^~!~^^^^^^^^^^^^^^^^^^^~7?7!^^^^^^^^^^^^^^^^^^^^^^^^^^^^~^~^^::~^:::::^^^:^^^^:::::^^^^^:.    //
//    7777777!!!!!!!!!!!!!!!!!!!7!~~!!!!77777~!!~!^^^^^^^^^:^:::::::^!~~~^^^^^^^^^^^^^^75PGJ!??7~^^^^^^^^:^^^^^^^^^^^~^~~~~^^:^^^^::^::^^^^^^^^^^~~^^^:^:::.    //
//    777777777!!!!7!!!!!!77!!!?!!~~!77!!~~~!~!~^~~^^^^^^^^^:^^::::::::^~!^^^^^^^^^~^~JGGGGP?!!7??!~^:^^^^^^^^^^^^^^^~~~~^^^^^^^^^^^^^^^^~^~^^^^^^^^^^:::^:.    //
//    777777777!!777!!!!!!!!!!!?!~~!!~~!~^^^^^^^~!~!~~~^~~^^~~^^^::::::^^~^^^^^^^^^~7PGGGB5Y5YJ7~~!77~^^^^^^^^^^^^^^^~^^^^^^^:^^~~~~~~~~~~~~~~~^^~^^^^^^^^^.    //
//    !77777777777!!!!!!777!!7777!!7~^^^^^^^^^^~!~^~~~!^^~~^^^^^^^^:::^~~^^^^^^^^^!YGBGGGGJJJ7??7~^^^~!~^^^^^^~~~^~~~~~~~^^^:~~^^^:^~^~^^^^^^^~^~^^~~^^^^~^:    //
//    !!7777!!!77!!7777!!!7!!?!~~~~!!~^^^^^^^^~~~^^^^^~~~~^^^~^^^^^^^^!~^^^^^^^^~YGBGGGGG5~~!!^^^^:::::~7~^^~^~^^^~^~~^~^~^^^^^:::::^^^::::^^^:^^~^^^^^^^^^:    //
//    !77!!!!!!!!7!!!!7!!!!!~~!!!~~~~~^^~^^^~^^^^^^^^^^^^^^^^^^^^~~~~^~~~^~^^^^~5GGGGGGGBY!^^^::::::::::^~~^^^^^^^^^^::::^::^::::::::::::::^^^^^^^:::::^^~^:    //
//    !77!!!7!!!!!!~~~~~~~~~~~~~~~~~!~~~~~~!~^^^^^^^^^^^^^^^^^^^~~^^^^^^^^^~!~!YGGGGGGB#P?!~^:::::::::::::~~^~~~^^^^^~~^^~~~~~~~~^^:::::::::^^^^^^^~~^~~^^::    //
//    77777!!!!!!!~~~~~~~~~~~~~~~~~~~!!!^^~~~~!!~~~^^^^^^^^~~~~~~^^^^^^^^^^^~!7GGGPP5GPPPPY7!^::::::::::::^7~~~!~~~!!!!~~~~~~~~^~~^^^^:^^^^^~^^^^^^^^^~^^^:.    //
//    !!!7!!!!!!!!~~~~~~~~~~~~~~~~~~!!~~~^~~~~~~~~~^^^~~~~~~^~^^^^~7!~~~^^^^~~JGP5JJY7?5PGGGP5J?~^^^::::::^!~~~~^^~~~~^~^~~^^^~~~^~^^^~~^^^~^^^^^~^^^^~^::::    //
//    7!!77!!!!!!!!~!!~~~~~~~!!77!!!!!~!~~~~~~^^^^^^^^^^^^^~~^~^^!5BP!!5PJ!~755?JYJ?Y?J5PPGGGGBBP!^~^::::::^^^~~~~~^^^^~^^^^^^^~~~~^^^^^^~~~~^^^~~~^^::::::.    //
//    !!!!!77!7?7!!7!77!!!77!!!!7!!!!7!!!!!!!~~!!^^^^^^^^^^^^^^^7GBBBG7?YYY5GBG!~!7????J55PPPGGGBG?~^::::::::::^^^^~~~~!~~!!~~!~^^^!!~^~~^~^^^::^^::::::::::    //
//    !!!!!!!7!!!7!!7!!!!!!!!!!!!!!!!!!!!!!!7!!!~~^^^^^^~!~^^^~JGPPBBBP7~!^~?PG5?~^?JY?J5YYYY55PPGGPJ!^^:::::::::::^7~^~~^~~~~~^~^~~^^^~^^^^:::^:::::::::^::    //
//    !!!!!!!!7!!!!!!!!!!!!!!7!!7!!!!!!~!!~~!!!~~~~^^~~~!~~~~7P#GY5GBGG57~^^^!??JJ777J??JJ?7????J55PGGY?~^:::::::::^~~~^~~~~~~^^^^^^:~~~~^~~~~~^^^^^:^^^^^::    //
//    77!!!!!7!!7!!!!!7!!!!!!!!!!!!!!!!!!~~!~~!!~~~~~~~~~~~?PB##B?7J555YYJ!^^^^~~^^~~!?7777!!7!!77?JJY5GG7^::::::::::^~^::^^^~^~~~!!~~::::::::~^~^^^^^^^^^::    //
//    77!77!77!!!!!~~!7!!!!!!!7~~~~~~~^~~~~~~~^~~~~!~~~!~75BBB##BG?!!7?77!!^^^:^^^^^~^7!!77!!~~~~^~~!??Y55!:::::::::::^~:::^^~7YYJ7~^:::::::::^^~~^^^^^^^^::    //
//    777!7!7!!!!~!!!!!!!7!!~!~~~~~~~~~~~^^~~~~!!^^~~^~!JGBBBGGBB#GY!~~~^^^^^^~~^^^~~~~~~~!~~^^^^^~~~~77^^~^~^^::::::::^~!?JY5PPGGGPY7^:::::^^^^^^~~^^^~^^^:    //
//    777!77!77!!7!!!!7!!!!!~~!~~~~~~~~~~~!~~!~^~^^^^^7PBGGGGGBG5YY55Y?7^^^^^^^^^^^^^^^^^^^^~~~^~~^^^^~^^^:^^^^~^^^::::^~~?YJYYYYYYY5PY~:::^~:::::::::::::::    //
//    !777777!7!!!!!!!!!!~!!!7!~77!~~!~~~~~^^~~~~~^~!5GPPPPGB##P???JYJJYJ7^^^^^^^^^^^^^^^^~!~^^^~^:::::::::::::^^~^^~^::::^~7!!!!!7??YYY~:^:::::::::::::::::    //
//    7777!!777!!!!!!!!!!!!7!!!!!!!~~~~~~~~~~~~~~~!YB#YYPGB####B7~~!7777?J!~^^^^^^^^^^~~~~~^^^^^::::::::::::::^^^^::^^^::::^~~~~~~~~7?7J~::::::^:::::::::^::    //
//    777777!!!!77!!!!!!!!!!!!!!~!!!!~~~~!7!~~~~7YGB#BBPJYGBGGBBP7~^^~^^^~!7!~~~^^^^^~~~~~^^^:^^^::::::^^^^^^~^^^^^~^^^~~~~^^^^^^^^^~~~~~^~~^^^:::^^^~^:^~^:    //
//    77!!!!!!!!!!!!!!!!!!!!~!!!!~~~~!~~7GB7!7J5GGGGGPGP5Y5GPPPBPGJ~^^^^~?PP?77!~^^^^!^^^^~^^^^^^^^^^~~~^^~^^~~^^^^^^^^^~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^::    //
//    !!!7!!!!!!!!!!!!!!!~!!~~!!!!!!!~!YB##BJ!!7YPPPP5YYJ?JY5GGB577~~~^~5###5!!!7?77!!~^~~~~~~7~~~~~~~~~~^^^^~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^:^^::    //
//    !!!77!!!!!!!!!!!!!!!!!!!!!!!!~~7P#####G?77?JY5J??J???YPP55PJ!~~~~Y#####G?!~J?7??!~~^^~~~~^^^^~~^^~~~~~^~~~~~~^~^^^^^^^^^^^^^^^^^^^^^^^^^^^^:^^::^:::::    //
//    7!!!777!!!!!!!!!!!!!!!!!!!!!!!YBBGB####J7777?YYYYYY5555JJYJ??7~~J#####B##5?J5?7!!!!!!!~^^~~~~~~~~~~~~~~JPPJ!~~~~~^^~~^^~^^^^^^^^^~~~~~^^^^^^^^^^^^:^::    //
//    7777!!!!!!!!!!!!!!!!!!!!!!!!7PBBBBB#BB#BP?!7~!?JJJJYYYJ?777!7!!?BB#B#B####BY?JJJ?!77?YJ~^^^~~~~~~~~~~?G####BPY?!~~~~~~~~~~~~~~~!?J7???7!~^^^^~^^^^^:::    //
//    77!!7!!!!!!!!!!!!!!!!!!!!!7YGBBBGGGGPB#B##5YJ77?J?JJ?77??7!!!!?B#BBBBB###B##Y77???77JP5Y?!~~~~~~~~~!YBBBB##B##P?77!~~~~~~^~~7J5GBG~~~~!7?7~~~~^^^^^^::    //
//    77!777!!!!7!!!!!!!!!!!!?Y5PGGGGP5PPPBBBGG##BJJ7?????J7!!!!!!~?GBBB#BBBBBB####GY?7JY55Y77?JJ?7!~~~7YGBGGBBBGGBB#GY7?5Y?!!7?5GGBBBBG!!?7!!~!??!~^^^^^:::    //
//    77!7!!!!!!!!!!!!!!!7?Y5GPPPPPG55PPGBGGGBBB#B5JY?7?JYYJ!~~~~!JGGGBBGGBBBBB#B####BPJ7!777777!7?Y55PGGGGPPPPPP5PGP5PPY5PPPGGGGGPGGBPJ7?YJJY?!~!7J?!~^^^^:    //
//    77777777!!!!JPY??J5PPP555YYPYJY5P555PGBBBBGGBBYJJJ77?J7~^~?PGGPGBGPGGBPBBBB#######G?!!!777!7YPP55Y5YYYYJJY5PGGY!7?JJYY55PP5PPP5YJ?7?5PGY!7!!~~~7?J?7~:    //
//    777777777??5GGG5PPYYJJ?J?JY??YYYYJJ5PBBGPPPGPPJ?J????7?JYPGPPGGBGPGPPPGGPBBBB######PJ777??!7JJJJ?????77J5GB5JYPJ!!7?JYYJYP5PP5?7JYJ5GGYY5?!!!~~~~~7?!:    //
//    777????YP55YYJYYJ?777777!77?Y?????J5GG5PGB5J?YJ????JJJJY55555PG55PP5PG5PGBBBBBB##B#BY??YJ7777777!7!!7?JJJ5G55J77Y?!!JJ?5P55YYPGY7?YPGGYYPG5?7!!~^^^^^:    //
//    ??7??J???777!777!!!!!!!777?7!!!777?YYY5GPYJ?YJ77JJJ?777JYYY5PYYYJYY5P55GBGBBGBBB#B##B?JP?77!!!~~~7!!!7?JJJJJJYYY5?!~~~!?77??JY555J?J5G5Y55PGY?7!~:^^^:    //
//    777777!!!!!!!!!!!!!!!!!!!~~~~~~~~!7??777?!~7?J?JJ7!!!!7???JYJ???JJYYYYPBP5PGGBBBBBB#BGB5!!!!~~~^^~^~~~!777777?JJYYYJJ?!~~^^~!!~!7?7?JYY5P55PP5J?!~^^::    //
//    7777777!!7!!!!!!!!~~~~~~~~~~~~~~!!!!!!!!~~7J?77!!!!!!!!!!77!77777???J55YYY5PGGGGPPBGGGGP?~~~~~~~~!~~~~~~~~~^^~~~~~!!7777!~!!~~^^^~~~~!!77!7?7!!7?7~^^:    //
//    777!!!!!!!!!!!!!!!~~~~~~~~~~!!~~!~~~~~!!!!!~~~!!~~~~!7!~!!~^^~~~!7??J???JJPPPPYJJY55555P5Y!~~~~~~!~~~~~!!~!!!~~~~~~~~~~~~^~~^^^^^^^^^~~~~^~^^^^^^^^:::    //
//    77777??77??7777777!!~~~~~~~!!!!!!~~!!~~~~~^^^^^~~~~~~~^~~~~~~~~~!!!!!!!7?JJJ?7777??????777!~~~~~~~~~~~~~~~~~~~~~^^~~~~~~~~~~~~~~~~~~~~~^^^^^^^~~^~~^^:    //
//    777777777777!!!!~~~~~~~~~!!!!~~!!~^~~~^~!!~~~~~~~^^^^^^^^^^^^^^~~~^~~~~!7!!!~~!!~~~~~~^^^^^~~~~~~~~^^^^^^^^^^^^^^^^^^^~~~~~~~~~~!7!~~~~~~~^^^^^^^^^^^:    //
//    77777??7777!!!!!!!~~~!7JG57!~^^^^^~!!~~7!!!!!7777~~~~~!~~~^~~~^^^^~~~~~~~~!!~!~~~~~!77!!7?5PY7!~^^^^^::^^!?5?7~^::::^^^:^^^^^~~~^^^^^^^^^^^^^^^^^^~^^:    //
//    77777???77777!!!~!!?5GB##G?7777!!~~~~~~~~~~~~~~~~~~!!~~~~~!???7!!!~~~~!!?Y!~~!7?!?5PBGGGG#B#PYYYY?7!~!7JPB##Y?JY7~^^:::::^~~^^~~^~~^~^^^^^^^^^^^^^^^::    //
//    !!!!777??YPGP555PGB####BG5?77!!!777!7J7!7!!777!!777?7!~!77J5555Y?77?Y5PPGPG5JYPP5BBBGGBBB#B##5JYYP555GGGGBB#55?7JYYJ?!~^~~^:::::::^^^^^^^^^~!7?^::::::    //
//    7?7?YYP55P55Y5G######BBBYJ?77777!?JJYY???J77??77??777777??????Y5PPPGGPPPPPGPGP5YYGBBBBGGBBBBBBP5Y5PGPBGPBBGBPJ5Y7~!7??J7~~!~^^~~^^^^~!!!7JYPGBB5?!~^::    //
//    ?5555YJ?JJJYGB#BBBGGPPPP??JJJ777?J55J???77!~~!777777!??!77??Y555555555PGGGGGGBB5J5PGGPPPGGGGBBBBPPPPGBBPBBGPBPJJ5Y7~^^?JYYJ?77!!77?J5PGGBBGBPGGGGP55J^    //
//    ?YJJ?777?5GBGGBBGP555YYJYG5J??Y5GGGY????????7!!!!?7!77!7JY5P5YJJJJJJY5PPGGGGGPGB5?JY555555PPGGGP5555PPGPGBG5GGPJ7?YY7~^~!!7?JY5PPPGPPP5YPP5555Y5YYYYJ^    //
//    7J?7?J5GGPP5PPPPYJJ???YG##?7YPPGBGJ!!7?7????J?!~^^~~!!?JJJJJ7??7??JYY55YYPPPPGPP55J?JJJJJ5Y5PPPYY5P5P5PP5P555GG5J7!7?J7!^^^^~!7JYYYYJJJJYJ?JJ???JJ7!~^    //
//    7JJ5PP5YJYYY5YJ?7777YG###B77YPPGPYY7~~~!!7!!!??7~^^^^~~~!!7YGJ??JJJJJJ?JJYJY55Y5YY5Y?777JJ?JYYYYJYJJJJJJYJYYJ5P5YJ?!~~!!7!~^^^^~!7JJY?77!!!!!!!!!!!~^:    //
//    ?YYJ??J??????7777?YG##BB#GJ!?Y55JJYYJ!^^^^^^~~!?7!~~^^^^~7PB#P?J?77777777?J?JJ?JJJJYYJ?7!!7????YJ??????7??7?J7?JJ??J7~^^^~~^^^^^^^^^!JJJ?!~^^^^^^:::::    //
//    7777777777!!!7?YPGGB#GGGGYYJ??JJJ?J?Y??~^^^^^^^~~^^~~!!!YBBG55J7J7~~~~~~~~~~~7??77??7????~~~!7?7?!~~~!!777!!!!!777~!7!~~^:::::^^:::::^~!??JJ?!~^^:::::    //
//    !!!!!!!!!!!?YPGPPGPGP5GPY???JJJ?777?!!!!!7Y?!~~~^^^^~?YGGPPGP?7!!!7!~^^^^^^^^~!!~~~~~~!!!7~^^~~!~~^^::^^^~~~^^^^^~^:^^^:^^:::::::::::::^^^~~!77777!~^:    //
//    !!!!!!!?J55P5YYYYPGPY55Y!!!7!!7!!7!!!7J5GB#B?7!!!J555PGGY5P555~~^^^^~~~^^^~~~~~~^^:^^^^^^^~^^^^^~^::::::::^^::::::^:::::::::::::^^^:::::::::::^^^^^^^:    //
//    !!77JY55YJJJJ??JY5YJJJ?!!!~~~!~~~~!?YG######P77!?55Y5YYYJYYJJ?~^^^^^^^^!!~^^^^:^~!~^~~^^~~~^^^^^^^^^^:::::::::::::::::::::::::::::::::::::::::::::::::    //
//    7JYYJ?77777777??77!!!!~~~~~~~~~!?5GB#B#####B577!!?JYJ???7??7?~^^^^^^^~~!~^^^^::^~!~~^^~7^^^~7~~~!!~~~~^^^:::::::::::::::::::^~^~!^^^::::::::::::::::::    //
//    7777!!!!!!!!!!!!!!!!!!!!!777J5PBBBBB#BBBBG5?~~^^^^~!?7!!^^^^^~~~7~~~~~^~~~^:::::::^^^:^~:::~~^::^^^~~^~^^^^^^^^::^^::::::::^~:::~^^^^^::::::::::::::::    //
//    !!!!!!!!!!!!77!!!!!!!7JY5GBGBBGGGGGPPPBGY7!~~!!~~^^^^^^^^^^^^~7~~~^^~~~~~!^^:::::^~~^^::::::::::::::^^^!~~~^^^~!~^^^^^^^^~^^^::^^:::~~^~~^^^::^^^^::::    //
//    !!!!!!!!7!7!7~~!7?J5PPP5YYYYY5YYYJJY5GP?!!~~7!!~~~^^^^^^^^^^~!!^^^^~^^^!!J5Y~~~^::^^^~~^^^^:::::::^^^:^~:~~^::^^^^^^::::^^^^:::::::^^^::~!~~~!!~~~~~^:    //
//    77777!77!!!7JJY555YJ???777777??7777?J?~~~^^~~^^^^~!^^~~~!^^!!^^^^^^~~7JPGBBG7~77!~^^::^^::^^:::::^^^^^:::::^~~^^^^~::::::^^^:::^^^^^^^^:~!!~~~^^~^^^^:    //
//    7!!!!!77JJJJ?7777!!!!!~~~!~!~!!~~~!!!~~~~~^~~~~^^^^^^^^^^^^^^~~~!YJYGBPYPPP?77^^!77!~~~^^:::::::::::::^^^^^^^^^^^~~^::::::::::^^^^^^^:^^^^^!~^^^^^^^^:    //
//    777?777!!!!~~~~~~~~~~~~~~~~~~~~~!~^~~~~^^^~^~~~^^~~~^^~!!~!!~!?YPYJGPJ7??77~!!7^^^^!~~?777~~^~~^^^^^~^^^^^^^^^^^^^~~^^^^^^^^^~~^~~^^^~~^^~~~^^^^^^^^^:    //
//    7777!!!~~~~~~~~~~~~~!!!7??7~!77!!!~777!!7!!!!7!!!7?7777?777!!?PY7~7J!~!~~~^~!^^^^^^^^^^^^!?!^~77~~^^^^^^^^^^^^^^^^^^^^^^^^~~~~~~~~~~~~~~^^^^^^^^^^^^^:    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TQH is ERC721Creator {
    constructor() ERC721Creator("Samanta", "TQH") {}
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