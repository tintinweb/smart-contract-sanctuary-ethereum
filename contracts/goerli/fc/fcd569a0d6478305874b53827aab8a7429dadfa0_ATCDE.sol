// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Above the Clouds by Daria Elshiner
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    ART-BY-DARIA-ELSHINER-JJJJJJJJJJJJJ???77!!^:^^^^^^^~!~!7!!~!!~~^^^:...^~~~~!?!~~~~~!!!!!!!777777777??????JJJJJJJYYYYYYYYYYYYYYYYYYYYYYYYYYYYY55YYYYYYY    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ????77!^:^^^^^^^^~~!!!~~!!~^^^^:..:^~~~!!!~~~~~!!!!!!!77777777??????JJJJJJJJYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ????7!^::^^^^^^^~~~!~~~!~^^^^:...:~~~~77~~~~~!!!!!!!77777777??????JJJJJJJJJYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY    //
//    JJJJJJJJJJJJJJJJJJJJJ???????????????77!~^:^^^^^^^~^~!~~~~~^^^^:..:^~~~!7!~~~~!!!!!!!77777777??????JJJJJJJJJYYYYYYYYYYYYYYYYYYYYYYYYYYYYYJJYYYYYYYYYYYY    //
//    JJJJJJJJJJJ?????????????????77777777!!~^:::^^^^^~^~!~~~~~^^^::..:^~~~77~~~~~~!!!!!!7777777??????JJJJJJJJJJJYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY    //
//    JJJJJJ??????????????????7777!!!77??????77!!~~^^~^~~~~~~^^^^:...^~~~!7!~~~~~!!!!!!7777777??????JJJJJJJJJJJJJJYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY    //
//    JJJJ??????????????????77!!7?J5PGBBBBBBGGPPYJ?7!~~~~~~~^^^::..:^~~~7!~~~~~~!!!!!777777??????JJJJJJJJJJJJJJJJJJYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY    //
//    JJ???????????????????!!7J5GB#######BBBBGGGPP5YJ?7!~~^^^^:...^^~~!!~~~~~~!!!!!777777??????JJJJJJJJJJJJJJJJJJJJYJJJJJYYYYJJJJJYYYYYYYYYYYYYYYYYYYYYYYYYY    //
//    ??????????????????7!!?5B###&&&&&&&&&###BBBGPP5YJ?77!~^::..:^~~!!~~~~~~!!!!!!77777????????JJJJJJJJJJJJJJJJJJJJJJJJJJYYJJJJJYJJJJJJYYYYYYYYYYYYYYYYYYYJJ    //
//    ????????????????77!?P#&&&&&&&&&&&&&&######BBGP5YJ?777!:..:^^~!!~~~~~~!!!!!777777?????JJJJJJJJJJJJJJJJJJJJJJJJJJJJYYJYYYJJYYYYYYYJYYYYYYYYYYYYYJJJ?7!^^    //
//    7????????????777!75B&&&&&&&&&&&&&&&#######BBBGGP5J?777!^^^~!!~^~~~~~!!!!!77777?????JJJJJJJJJJJJJJJJJJJJJYYJJJJYYJJJJJJJJYYJJYYYYJYYYYYYYYJJJ?7~^:.....    //
//    ^7????????????77!Y#&&&&&&&#############BBBBBBBBBBGY?7777!~!~^~~~~~~!!!7777777?????JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJYYJJYYYJYYYYYYJ??7~^:......::^^    //
//    ^^??????77????7!JG55PPGGPPP5555PPGGGGGGGGGGGBBBBBBBPJ77!?!^^~~~~~~!~!7Y?777??????JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJYYYYYYJJ?!~^:......::^^~~~!!    //
//    ~^~??777777?777!Y5JJ5PGGGGB#BGPG55GPP55555PPGGBBBBB#GJ7!!?~^~~~~~!!7?J?777???????????JJ??JJJJJJJJJJ??JJJJJJJJJJJJJJJJJJJJJJJ?7!~::......::^^~~!!!77??J    //
//    ~~:!7777777777!?Y55PG##&##B55PGPGGGGPYY5555PGGGGGGB##BJ!!?!^~~~!!!!!!!777????????????????????????????????????????????JJ?7!~:......::^^^~~!!!77??JJJYYY    //
//    !~^:!7777777!J555YG&&&#GGBBPGB&#&&PBP55JPGGPGBGBGJPGB#G?!?~~~~~!!!!!!777?????????????????????????????????????????7777!^:.....::^^~~~!!777??JJJYYYYYYYY    //
//    7!~^^!77!!!!!GBYYYP#&#GPGBBB#&&&&BG5?PB5P#BBBBB#P5GP5P5~~~^~~~~~~~~!777?????????????????????????????????????77!~^::::^^:::^^~~~!!77??JJJJYYYYYYJJYYYYY    //
//    !!!~^^!!!!!!!5PJY555#GGB####&&&&B5J?Y5BG##&##&##BBPPPY?^^~~7?!!~~!!777777??????????????77!!77777777???77!!~^:.....::^^~~~!!77???JJJJJJJJYJJYJJYYJ?JYYY    //
//    !!!~^^~!!!~~~7PY55YJJY5GB####&#GY77?Y5PBB&&#######GG5?~^~7JYJ7!!!!77777777777777777777777!777777777!~^^:.....::^^~~~!!77??JJJJJJJJJJJJJJJJJJYYYYYJJYJJ    //
//    ~~~~~~^~~~!JYY5YYYJJ?!!7JY5GBGYJ7!7?JY5P###&&#####BP5BY7JJ?77!~!!!!!7777777777777777777777777!!~~^:.....::^^~~!!777???JJJJJJJJJJJJJJJJJJJJJJJJJJJJJ???    //
//    JJJ??77!?Y#&@&5YYYYJJ??YPB#B57!77!7??JJ55G##BBBGGPYJPGJ??7!777~!!!!7777777777777777777!!!!~^:::::.::^^~~~!!777???????JJJJJJJJJJJJJJJJJJJ??????77777777    //
//    JJJJJJPB#@&&&&B555YYYYGBG5J777???JJYYPGGGB###BGP5Y?J57!!77777?!~!!!!!!!!!!777777!!!!~~^::....::^~~!!!!777??????????JJ7?JJJJ??????????77777777777777777    //
//    !!!!!5&&##&@&&&G5555Y5BGJ55YJ???JYPP55GPPBGGB#BGGP5J7!7777????7~!!!7!!!!!!!!!!!~~^:....::^^~~!!!!777777????????????????????77777?7!77!!!!777777????JJY    //
//    77!J#&[email protected]&&#P5555YPB5GPBY7777J55PGGGGB#BBPP5GGPJ!77777777??!~!!!!!!!!!!~^:....::^^~~!!!77777?JJJJ?77?77777777777!?JJ?JJYY?!!!7????JJJJJJ?JJJYY555Y    //
//    GY?B&[email protected]&&#G55555G?Y?JYYJJJJY?JY5PGB#BGJ?5GG5777?777?????!~!!!!~~^::...::^~~~!!77777777?J?JJ????J77??777777777?YYJ7?JJ5GP5YJ????77!~!?JJ??7JP5PJ    //
//    &&#&&&[email protected]@&&B5PPPY!5J????Y5PPPPGBGPPGG55PGGGG5J?777??????7~~^:...::^^~~!!!77777777!777!7777??J????!????JJ?77J?JJJYJJJJYPBGPYJ7!!!!75PBBYJ77?YG5?    //
//    &&&&&&&&GJ7?!~J#@&&#P5PY!YYJJ?77?JJYYY5GGGGYJBBBBB#&#B5Y?7?777?7~^::^^~!!!!!!!!!77!777!7PBBP7^:^7???JJYY7!?7~~~!77?55!~7JY55GBBG5Y557!!?YY55J7!!7?YY5J    //
//    &&&&&&&&&&P?77~!P&@&&BGP7!?????77??JJJ5PGPJ!5#####BB####GY???JJJ!~~!!!!~!7777777!!!~~~~JBBGPJ~7?JYYYY55PY!?J7!???J5Y7^:^!7??YGBBPJJ5J!!7!!!!!!!77?Y5P5    //
//    &&&&&&&&&&&PJ???~7P&&&&#GJ777????7?JJ?JYJ??G##&&###BB&&##B5JJYYY7~^?P55?~JPPPGYPY77~~~~~!777?75PYJYYY555P?!?5J???7YYY7~7Y57^7?JGPY?YJ!!!!7?JJJJ???Y55Y    //
//    &&&&&&&&&&&&#P7??5G&&&&&&&B5JJJ?J??YJ??JY5B#&&&&###BB&&#BBGYYYY5?~^7GGGBY~5BGBY55777!!!~^^~Y#GYGYJYYY555P5!?P5??7!?PY7~7!~^!??YGPJY5Y?!7JY55555Y??J??J    //
//    &&&&&&&&&&&&&&PP&@&&&&&&&&@@&#BBPGPPBGB#####&&&&#######BBGG55555J~^!5GBBB7!GGG5Y577??7!!^^?G##5G5JYYY55555775P5JJ??YJ!!?7!~~7?GB5J5PPP?7?P&#BG5??JJJYY    //
//    &&&&&&&&&&&&&&@&&&&&&&&&&&&&&&&&&&&&&&&##&&&&&######BBBBBBBBBBGG5!^~?JYY5?~Y55Y??!!YJ???7J&&&&YJ?JYYYY5555J75GBY????5YJY5?~7JYGG555PPPY?7JGBBB#GYYGB##    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#B###&######BBB##BGPY77!!!!!!!77?!7?7PPPGB##&&&GYY5YYYY5PPP5JYPP?!!?Y5Y?Y5YYYJJJPBBGPPPPYJ?7YGBB#G?Y55PP    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#B#&&&&&&##########BBBGPPPJ!!!!!JJPPJ5PB&&&&&&&&GYYYYYYYYY?77!!!!7J5PP5JJ5?7?77YY##GPPPPPYJ?7YG#G?Y5PYJY    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#&&&&##########&####BB#BG5J!^^~~J55Y5P#&&&&&&&#JJJJ??7!^^^~!?Y55YJJ?J???7!!~JY?YGBBGP555YY?Y##?7YYY??5    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#&&&&##########&&####B###BBG5?!~!!!!?G#&&&&&&&&J77!~^^^^!?JYYYYJ7!!77!!!!!77!!!!7?JYY5PGP5Y5#G!!7?J5BB    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&###########&&&&&###B#######G!^~!!JG#&&&&&&&#J!~^^^!7JYYJ??Y55J7!~~~!!!!!!!!!!!!~~~!?PG55555!7???J5P    //
//    &&&#B&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&############&&&&&###B#&######G!!JJJY5PGGBBBY!!!!777?JJJJJJY5PGPY!~~~~!77??7~~~~!!7?7!?PPJ7??!7YJ??JJ    //
//    &&&[email protected]&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#&#############&&&&&&###B#&&###&&J!??7?????????JYYY?JYYJ555P555GBPY!~^^^^~!?JY?^^^~!JGP~!7Y?7!7!!??!!7J    //
//    &&&?~PB&&@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#############&&&&&&&&####&&&&&&#J77777??JJJJJJJJJJ?YYJGGPPPPPPGB5!~~!!7?J5PPGB7^~!?5B#?^~7J??7~!?J77!!    //
//    &&&B775G5Y5GY?B&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#&&&&&&&##&&&&&&&&&&&###&&&&&&&B?7??JYYYYYYYJ?JYJJY55Y5B5555PPPBP7J5YJ???JPPGBP?JJY5PBB!^~7?J7~!?Y????    //
//    &&&@PY&&Y7?&[email protected]&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#&&&&&##&&&&&&&&&&##&&&&&&&#BY!!!7????JJ?7??JYYYYJJ75JJY5YYPGGGGBPJ?JYJPPGBBYYYY5PBB7^^~7Y?!!J5????    //
//    &&&&5~?J?~~?5J!5&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&##&&&&&&&&&###&&&&&&###BY!!!!77777777??J?7777!YY?JPGPPPPBBGGGPPGGGPGGBBBB#BBPGY~~~!?J??YY?JY5    //
//    &&&&?^^^^^~5&GJJ&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&###&&&&&&####B5!!777777777???!!77777Y?JPBBPY5G#GGGGGGB5Y5PPB##GGP5YY?77777JY5PGGGP    //
//    &&&&B7~!~~^~7?7!JB&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&###&&&&&#######P7!77777????JJ777???!YJ?7??7?Y5GBGGGBBGYY5GB##G55J??JJY55YYYYYYYYYY    //
//    &&&&&&GJ?JJ7??JJJ5&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&##&&&&&&&&&###&####&&&&&&########G77777?????JJ?77???7?PY?!!!J5P5B#BGGGPYJY5G#BYJ5GB#&BY???7777777!7    //
//    &&&&&&&#J!!7!!!~?#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#####&&&&&&#########&&&&&&&########G?777????JJJ?777???7PPGGGP5PBGBBBBBBBBB5YJJ7~5&@@@G7!777?JYY?!~!!    //
//    &&&&&&&&&GYJJJJ5#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&###&&#############&&&&&&&&&##&#####G?7???JJJJYJ77Y555YPGPGGG55GBBBBBGGP5J7!!~~~B&@@B?7?JY5GPJ!~~!7?    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&###&&&&###########&&&&&&&&&&#&&&&&##G????JJJYYY?7B&&#BGPPPPGGB##[email protected]&&BPY55PGGJ!~~~!7J5    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&##&&&&&&########&&&&&&&&&&&&&&&&&&&&&BY?JJJYYY5?7J5G####&&##&&&###G5J7!!~~~!7J#@@@&#####G?!~~!!7JPG    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&###&&&&##########&&&&&&&&&&&&&&&&&&&&&&#5JJYYYY5J??7?YYPGBB#&&&&&&&&###BBGGGG5YJ5G#&@&&#BJ!!!!7?JPPJ    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&########&&&&&&&&&&&&&&&&&&&&&&&&&#PYYY555Y????JYY5Y55PPGB#&#B&&&&&&&&&#BGGPPPPPPG5?777??YPPJJ    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&###########&&&&&&&&&&&&&&&&&&&&&&&&&&&&#G555P5J???JYY5YYYY5555PPPB##&&&&&&&&&&##BBGGGP55YYJYPPJJ5    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ATCDE is ERC721Creator {
    constructor() ERC721Creator("Above the Clouds by Daria Elshiner", "ATCDE") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x03F18a996cD7cB84303054a409F9a6a345C816ff;
        Address.functionDelegateCall(
            0x03F18a996cD7cB84303054a409F9a6a345C816ff,
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