// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NERDCORE
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    &&&&&&&&&###########BBBBBBBBBGGGGGPPPPPP555P555P5555PPP5PPPP5P5PPPPPGGGGBBBBBBB############&&&&&&&&&    //
//    &&&&&&#########BBBBBBBBBGGGGPGPPPPPP555PPPB#GPPPPPPPPPPPPPPG#GP5PP5PPPGGPGGGBGBBBBB#########&&&&&&&&    //
//    &&&&#&###BBBBBBBBGGBGGGPPPPPGPP555Y555PB#&&BPP5P55PPPPP5P55PG&&#BGP55PPPGPGPGGBGBGBBBBBB######&&&&&&    //
//    &&&&######BBBBBBBGGGGGPP5PP5PP555Y5GB#&&##G55555PP5P5P555555G&B#&&&#GPPPPPPPGGGGBGBBBBBB#######&&&&&    //
//    &&&&&####BB#BBBGGGGGGGPGPPPP5P5PGB&&&####BBGP5PP5BBGPP55555GBGBB##&&&&#BGP5PGGGBGBBBBBBB#B####&&&#&&    //
//    &&&##########BBGGGGGGGGPPPPPPGB&&###B#BB5PJPGGGBJJ?YGBGGGPBBBBBGBBB###&&&#BGPGPGGGGGBBBBBB########&&    //
//    &&#####B#BBBBBGGGGGPPPPP5PPB#&&##BBB#P??JY??YYJYY!~~!YBG&&#BBBBBGBBBBB#B#&&&#BGGGGGGGBBBBBB#######&&    //
//    ########BBBBGGGGPPPPPPPPB#&&#BBBB#B#Y!?5B5!7!!7!~~~~~~!?B##&#######BBGBGBB##&&&#BGPGGGBBBBB######&&&    //
//    ######BBBBBGGGGGG5PPPB#&&#BBBBBB#GBY~YGPP?~~~~~~~~~?5~~~?YY5YYJYPB##BBB#BGBBB#&&&&#BGGGGGBBBBB######    //
//    ######BBBGBGGGGPPGB#&&#G#BB#BB#G?JJJ7!7777JJJ?~~~!7!!~~~~~~!~!~!!!JG&B#BBB#BBB#B####&##BGGGBBBBB####    //
//    ###BB#BBBGGGPGGB#&&&#B#BGBBBBB#??PPP555555#&@G7J5BBY7?7!7Y7~~~~~~!7!J7?GBB#BBBBBBBB#B&&&&#BBBBBB####    //
//    ###BBBBBGGGB#&&&&##GB#BB#GBBB#B!PGY555J????7?5&BB&@&PYJ7~!J!??7!!!7!~!~?#B#BBB#BBBBB#BB&#&&&##BBBB##    //
//    ##BBBBBB##&&#&BB#BB##G#BBB#BB##BPJPJ!~~~~~~~~~?&&&#7~~~~~7B775PP#PG#?7PG&B###BBBBBB#BB#BB##&&&&&####    //
//    ##BBB#&&&&B#BBG#B##BBBBB#GBBB#&B?G!~~~~~~~~~~~^P&&?^[email protected]!?5&####B#BBBBB##B##B#####&&&&#    //
//    &&#&&&&&##B#BBBBB#G#BB##GBBGB#&JPY^~~~~~~~~~~~~5##!~~~~~~~~~~~~?B&B7~~~5&B#B##BBBGB#BB##B#######&&&&    //
//    &&&####&#BBBBBBBG#BBB#BBBBG#B#&5JB!~~~~~~~~~~~7B5#Y^~~~~~~~~~~^?&B##P?!J&GGGBGGGGB#BBBBBBB#B########    //
//    &##########GBBGBBBGBBGBBGBBBB&#&Y5GJ7~~~~~~~!JPY~?#5!~~~~~~~~!J#5!7J5BBP&#BGPPPPPGGGGPGPGGGBBBB#####    //
//    ##&BB###BBBBBBB#GBBGBBBB#BGBB&#&GJ7J55YJ??JY5Y!~~~!YGP5J??JJ5GP?~~~~!YGBB&BGGGGGPPPPPPPGGGBBB#B#####    //
//    ###B&B##B##BB#BGBBG##GB#GB#BB&#&?~!~~755J??7~~~~~~~~~!?JYYYJ?!~~~~~~!?5PGB&BG#BGBBGPPPPGBBBBBB######    //
//    #######B#BBB#G#BBBBBB##B#BGBB&#P~~?~!YY~^~~^~~~~~~~~~~~^^~~~~!!!!~~~~!JPPG##BBBBGGBBGGBGGBBBBBBB####    //
//    ##B#B#BBBGBGBB#BGBBB#GBBGBBB#&#PJ~!?5Y??JYY55555PY77777?YPP555PPPP5YJ?7PPGB&BGGGGGGGGGPPPGGGGBBBBB##    //
//    &#########BB#B#B#BB#B##BBBBB#&#B?~7YYYGPB&#5JG#5?B&GPG&GJP5P?JYBBPJ???7YGGB&GGGGGGPPGPPPPGGPGGGBBB##    //
//    ##B######BBBBB#BBBBBBBBBBBB#G55Y5757~~~!JJ55YPP5!!#7^7#!JP5GY555JJ?!~~75#55GPYPGGPPPPPPPPPPPPGGGGBB#    //
//    ###BBB#BBBBBBBBB#BBBBBBBB###BJB5Y7Y7~~~~~~~7??77~~G!~7#!~!7!77!~~~~~~~?P55JPY^~5GPPPGGPPPPPGBB##BB##    //
//    ###B###BB#B#BB##BBB#BB#####[email protected]!7B?~~~~~~~~~~~~~7#BB#&?~~~~~~~~~~~~!75B!!B#!~~YGPPPGBGPPPPPGBBBBBB#    //
//    ##B#G5PGJPGPYPP?G#####Y77J7!?&@P~!G5^~~~~~~~~~~~!B#J?YBB!~~~~~~~~~~!7J&P~!#5^~~YPPPPGGGPPGGGGBBBB###    //
//    B#&G!!!~!!!~!~!~5#####G!!!~!7#B#!!5B?~~~~~~~~!7YBG!!~~?G#Y?!~~~~~~!!7P&J~?#!~~!JGBGGGGPPP55555555PPP    //
//    &#B#!!!!!!!!!!!~Y#&###&G~!~!7#JGBJB55J???JYYPP5YJ!!?~!J!555PGP5YJJ55B#B!YB?~~~YP##P#GGGG5!7~77!?!?77    //
//    ?PP#5!7!!!!~7~7~JYP#G&#BP~!!!BP~JG5P!!?????7!~~^~~~!~~!~~~~~!7JYYY5Y?P&GG?~~~7P##P&BGBGG5!7~!!!7!?7J    //
//    7!Y##G~!~~!~7~7~7~YBG&BG#J~~~J&!^~!?Y~~~~~~~~!7?JYYJYYJY55YJ7!!!!!7!?5J7~~~~~JY#GB#P##GBJ~7~7~!7!5B#    //
//    !!P&#&G!~!!~!~7~!!7GP&PGGP7!!~B5^~~~Y?~~~~~~~!JG#&BB#GGB#G5J77!!!777PJ~~~!~~775#GBYBBGGB??!!7~7!?#&#    //
//    7?##B#&P~~~~7~7!!7~GPB5Y5JY~!!?&J~~~!P???!~~~~~~!7???J??7!!7?7777??JP!~~~!~!?!P5GGYBGPGY77!!!!!7##B&    //
//    7!?G###&5~~~!!!!~7~5PPPJY7J~!!~JB?77???7JB5!~~~~~!~~~~!!!!!!777???JPJ~~~~~~!!7PJPYYG5G57J?!7777G#G&&    //
//    7?!7BG###7~~~!!7!!!YP55??!77!!!!!7!!~~JY!755J~~~~~~~~~~!7777???JYYPJ~~~~~~~!~?J?5J?5JGJ?Y!7?!!P#B#BP    //
//    !?!JBG&BBP^!~~~!!!~7J77!!!!!!Y!~~~~~~~~7!~^YG~~~~~~~~~~!!7??JJYYPP?~~~~~~~~!~77!?!7J?J!7?!77~Y#BB##B    //
//    !7!#GP&###?P7~~!~7!7?!7!!!!!~YJ~~~~~~~~~~~~JG~~~~~~~~~~~!7Y5PPGBG7!!!!!777!!~!~!7!J?7?!??!?7?#PB&G#&    //
//    GJ!GB&G#&G#BB~~!!!!~7~~!!~!!!PJ~P5YY!~~~~~~!#P!~~~~~~~~~!?PGGBBG5Y??77!777???7!!!!7~?7!?77?!PBB&BB&&    //
//    &B7?P&#&&#&##J~~~~!~!!~~~~~!7B!~Y&@@&P!~~~!YPBB7~~~~~~~~~?B#BPPP?PPP55YY5YY???????!!7!77!7!?GG&&&&&&    //
//    &#G!?PGBGBB#BB!~7!7!!!!!!~~~J#7~~?5B&&7~~~!#7!&Y~!~~~~!?5BGPPPP57PGPPGPPPGGGY?J5Y?7!?!777?!YYPGBG#B#    //
//    &#&5!?J55P5PGP5~!~7!!!~!~~~5YP~~~~~~JP!~~^5&YJGJ777YPGBBPY5PPPP5YGPPPPPPPGPJ!!!!JP7~!~!!!!7JJ5YGGBGB    //
//    &&##[email protected]?7YG?7!~~7YBPYJ7!7J5PPPBGGPPPPPPGPY!~77!!~?P~!~!!7!???JJ5PPP5    //
//    P####7~J7Y75?PJY~!!!~!~!~!P~?G~~~~!7?5J?Y?~^~~7YPPBP?!!!!?YPGGJ5GPPPGGGY7777?777?7P!~~!!!!?7??YJ5YYJ    //
//    G#&&&B!!!77?7777?~!!~!~!~7P~J5~~~~!!!~~~~~!J5B#GY7!7Y55YY5P5J75&#BBGPY?777?7???5?!P7~~!~!77!77J?J?Y?    //
//    #BB&&&P~!7777!7!7~!!~~~~~7G~57~~!!!!!~~~!?B#P5PP5PB5?77???JJP&@&&&#J!7?7?7?7??JB?!P?~~~~!!!!!7!!77?7    //
//    #B&&&&&J~7!77!7!7!!!~!~!~!??Y~~~!!!!!!~?G#P???JY5Y5PP55YY55YYYJPPY?7!777?77?77?B7!P?~~!~7!!7!7!777?7    //
//    #G&&&&&#7~7!7!7!!~~~~~~!~~!P!~~~!!7!!!?#P???777????7777!!?7777!!7!!7!777?77?77?#7!G?~~!~!!7!!7!?!?7J    //
//    [email protected]&&&&B!7~7~!!!!~~~~~~~~5?~~!!!77!!J#P?7777!777777?7!!!!77777!7777!77!777?7!?B!!B7~~~~!~!~!!!!7!J&    //
//    #&BB&#&&#P~!7!77!!~!~~~~~?P~~~!77?!!?#5!Y5YJ???YYJ?J?77???7?????????7!7777!77!?&?7G~~!!!7!7~7!!!!JG#    //
//    &#[email protected]#Y#&5#[email protected]&?5&#5J&B5YYY?B#G5GJJGP5?75BGP77!?!!!!JB!J5~~!~!!!!~7!7!7##&    //
//    B&#&#&B5&PP5~!!!!!~~~~~~~5Y~!!!!!!77B&#&[email protected]&&&#5JJJ75&@Y?#5BBJ&GJ#??BP?7JJ7!!YG~YJ~~!~!!!!~!!!7GG#&    //
//    ##B&#GBB#BPB?~7!!!~!~~~~!B7~~!!!!!!7#B#&J!GG&&&[email protected]#!!!!~!!5B!!JB!5?~!!~!!!!!?!7PB&BB    //
//    &#B&B5##5&#PB!!!~!~!~!~~5G~~!!!!!!!?&#GBGPBB&&#PP55YYGPYYJ?7JBBB??PGBGJ!!!5#7!!7!P!~~!!7!!!77~5BB&#B    //
//    ##@[email protected]#Y#PJP~!~!~~~~~7#[email protected]~!77777?JJY55PP55PPGBBBGPPGGG#BY777!5&Y~!!7G!~!!!7~!!!!7PG&G&#    //
//    ##&##[email protected]!!!!!!!!!!!!~!!~~!!!!!!!!!!77!!!!!~BB!~~5B~~!~!!77!?~5#B#BBG    //
//    B#&##YJGJY5Y#JP?~!!!!~PY~!77???JJJJP&57!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!77!!GY!7PPG~~!~!~7!!77G#PG5Y?    //
//    B#&GP??Y77PPPJJJ!!~!~7G~~~~~~~~~~~~!&YY?7!7777777!77!!7!!7!!!!!!!7!!!!!!!!7G!JG5YB!~!~7~7!!7JP5P?YYJ    //
//    &@#GPYYP55GJY!777!!!!PJ~~~~~~~~~~~~!&Y577777777!!!!!!!!!!!!!!!7!!7!!!!!!!!Y5777GPB!~!!!!7~?!J!???JJY    //
//    BBGP5YYJ??!7!7~7!!7!P?~~~~~~~~~~~~~!&JY7?JPGGGGGGGPGPPYJJ?!7!!7!!!!!!!!!!Y&?!77GPB!~!!~!!!7!7!??JYJY    //
//    5YYJJ??777!7~!~!!~!~BJ~~~~~~~~~~~~~!&P?YY5#&G#@#P&#5P&G!!!!!~!!!!!!~~!?JYB5777755#7~!!~!!7!7?7J?JYYY    //
//    PY5JJ???77!7!7!7!!!Y5G!~~~~~~~~~~~~!##[email protected]!77~!??755YGP55J?7!7JB&&@&Y??!!P5#7~!!~7!7!???JJYJ5Y    //
//    P55JYJ??77!7!!7!7!7G!B7~~~~~~~~~~~~!#@P!!!!~5&&@P5GGBBB#&###&@&&&#BP?PYJBYJJ?77BJ#?~!!!!!7!???JJ5YP5    //
//    GP55PYJY7J7?777!7~5J!G!~~~~~~~~~~~~!#&&P?5PYY55PGG5YJJJJJ?JYB&&&&&&#GG?Y#7!?77G55&?~!!!!777J7JJY55GP    //
//    #####PJJ?J7J7JY7YJP~?B~~~~~~~~~~~~~!#&&&BJJP##BBGP55JJJJ5GGGGBPPB&&&@#?5#[email protected]~!!7!?7???YJ5YPPG    //
//    &&####BPPGGBG##G&B!~7G~~~~~~~~~~~~~!#&&BG&GJ7??JJ??P&&BPJ7!!!!7J5BBB&&G5#JJG?J#[email protected]~!77!J7J?JYYP5G#&    //
//    ####BBGGGPGPPG&B&[email protected]&&&[email protected]#P?!!!!77?5B#&GY7!!77!!!J&@#[email protected]#Y!!7!Y?7YYPPGB#&&&    //
//    BGGP5YJJ??77!P&#&J~~5Y~~~~~~~~~~~~!BGP&&@B7YPB#G5Y7!!!!!?GB##GYY77YJ?BPPPYJPJYPJ5&J!77Y#PYGGBB#####&    //
//    BGGPP5YYJJ?75###&J~~G7~~~~~~~~~~~~J&P!5&&&B777????7!!!!!!!!7YPJPJ7J??P??BJ7B?7GPG5YG7J&&#PJJY5PPGGB#    //
//    BGGGGPP5YJ?P&#&#&5~7P~~~~~~~~~~~~7G&&#YP&&&[email protected]#Y5GYP#&##5Y55PGGGGB    //
//    BBBGGGPPYYG#&#&#&P~YJ~!~~~~~~~~~7P&@&&&5Y&&&B?!77777??J??JJ??YJJ5J757!?!!?~!?!7J7YJ75GY#&&#P5PPGGBBB    //
//    #BBBGGPP5#&&&#&B&B!5?!!!!!~~~~~7PG7YGB#&[email protected]&&&5JYJ!J5JJGJ?P?75?!Y7!?!~7!!7!!?!7?7?J?5#&&#&&#GPGGBBB#    //
//    ##BBBGGB#&&&&#&&&&JJY!!!!!!!~~?G&Y~~^~!?JYPBB#&B5JJY5JYPJJ5??J7!7!~7~~!~~!!!!!7777??P#&##&&&&BGBBB##    //
//    ###BBB#&&&#&&#&#B&&Y57!!!!!!7Y#&#BBB5Y7~~~~~!!7??JJJJ??777!!!!!7????JJJJJ?!77!?Y5PP5B&##&&&&&&#BB###    //
//    ######&&&##&##&&&&&&GPJJJJY5B##B#B##BG7~~~!!!7777777?77777!!777JPB#@&#&&#B?777?JP#&&#######&&&&#####    //
//    &&###&&&######BBBBBP5JY5PPPP#GGGBGBPJ!~!!~~~~~~~~~~~~~~~~~~~~!!~!7JPGGBBBBG???JJJYPB#######&&&&&###&    //
//    &&###&&&&###BGGGPP5YYJJ????5GGGGP5J!!!!!!!!!~!!!!!!!!!!!!!!!!!!!!!!!7?YPGB#P?JJJY55PGGB###&&&&&&##&&    //
//    &&&&######BBBGBGGGP55YYYJJPBGP5Y?7?!77!7!!!!!!!!!!!!!!!!!!!!!!777777?7??JYPB5Y5Y5PPPGGGBB####&##&&&&    //
//    &&&&&#####B#BBBGGGPPG5P55GG5YJJ?7?J???7?7!7!!7!!7!!!!!7!77!777?77???J???JJJY55PPPGGGBBBBB##B###&&&&&    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NC is ERC721Creator {
    constructor() ERC721Creator("NERDCORE", "NC") {}
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