// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JPEG da Vinci Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    ^^~!7!^^^!7!77???77?JY?777!~~J5Y?77?YG##P??J?????777??7!75~::::~##BG&GG&B~!7~~!!^^^~!7????J??7~!!?7!    //
//    ^^^:~!!!~!!!!!77?7!7!7???J?~!!7?YYJ?JJY&#5JJJJ5?77??J?7!^5G?~~^[email protected]@J##BBJ:!!!!!!!!7??JJJJ?7!!~~~~7YJ    //
//    77!^^[email protected]@[email protected]&GP77!~!!!!777?777??7~~~!J?77?Y    //
//    7???7!~^^J55PJ?7777!!^^!!77~!7!!777JYJ77YG&[email protected]@#5JJ???!~~!~~!~~!77!!777?YYY?7    //
//    ?YY5PY7!~!7?JJJ!~~~!!~~!~!7!^~!77?YYJ??!!7GB7!7~!777JYYYYYJJYY5G55#[email protected]?J??7!!~~!!?J!!??7!??~~JP?    //
//    YYGGYJ?7!!77YBGYY?!77!7!?J?!~J?!7!~~7?YJ7^7#G~!?!~!7?JYJJ?JJJYYY5G#G&&5Y7?7?JJ???7777????77???7!~!?G    //
//    PB##GPPY!???~Y&#[email protected]!J!~~!~!?Y???7?????J##&5Y57!!?7??7JJJ???7!~^^~~^^^~7!Y    //
//    5B&&&#&GJPPP5PGGGY~J57~7J?JY755J??JYPYJ??JY5#&5J!~!~~~~7??JJ?77?J5&BBYPG?77??7!~!777???7!!!!~~^^^~!!    //
//    ?P&&&B&[email protected]#5Y~~^!77!~7??77J55G&GPBBY?J5Y?7?7??7!!???7!~7?!~7!~!~    //
//    ##@&&&@PJJ5Y7G&##PY??J?77?????JYJJJJPGPYBG5?J5&#BY7!!77JP55J??YY5B&G#&J?Y5J!?JJYJJJ77!!!7!!!!~^^^~!!    //
//    BB#&B#&&#BYPB&BBGYJJ?7???J??7??5Y?5Y5PPG##GYJ5P&P5YYYJJYP5PY????P#&BP7?PPJ7!7JY?JJJ?????!!!^~^~:.^^~    //
//    777?JBPJY#BB&&G5JY5YJY??Y5YY7!7??JJYYJ??5G#&&BPBBG5GP5YJY5YJJ5PG#@#J!YPY??77JJ?7JJJJJJJ?77!~77~~~~~7    //
//    !YY7?PGPP#&##BP5GPPJ???YPP5Y??PJJJ??????5PPB&@@&&@BP#GG5YG#&@@&#@@PYGJ~~!!~!7??5GYJ????77777???????J    //
//    !!!!!7YBGJ777?YPP5J77?5BG5YY7~5J7?JYYYY?7??77?YP&#&#BG5J?Y5GP5GG&###7~!77?!7??Y5YJJ????7?7?77???J?7?    //
//    !!!!777!~~~~~~^!?JJ7?JY55?7!!7JY??7JJJ!!7????J55Y55Y?!!!!!~^^!JBBY7!!!7JJ?!777JJY??77!!!!7?~~~7??7!!    //
//    J???J77!!!7J555J?!7????J?JJJ7?5YJ5???7?JYP##G5J57YY7?JYYYY5PP5?????JJY5Y7JYY5PPPB5J55JJJYJ7?JJJJ????    //
//    GGGY5Y!7J5G##GPPGGY?55G&JPYYBBPGGP5JJYYBBPG5YPGGPY?5555PPGGGGPP?J5GGPPGPJ5PGBBBGGGY###BBG#YPGG55J5GG    //
//    #BGP5JYG#@&[email protected]@@@&BGP5G5PP&&&BG#G55Y#BBB&#BPPGPYJ55###BGB5GB#BB#BBB5B#&#BBBPP##GG5B&&    //
//    &&@&BY5&@@&#G5#Y5Y7J55YGGG#G5Y5B&&B5JJYY?#&&&##B5PPG&@@&@@#GBP5Y#&&@@&#PP###B&&&&GP&&@@&BB#B#@&#5GGG    //
//    @&@@GJP&@@&&BP&#[email protected]#[email protected]@&#BBBG55&&&&&@@@#[email protected]&&@@&GB&&&B&&@#PPGGB&[email protected]@@@&P?7?7    //
//    @@@#[email protected]@@@@@####&&P&#?JY5P##BJY5P&@&&@G&&&#5YJJG5Y#@&&#&@&GY?J5G&@@@&BYYPBBG##&G?5&BGG57?J?J??JY55P    //
//    &@#?75&@@@&&&@@@&##[email protected]&&&JJJYG&@&G7!~~^^^^[email protected]@@&BY7~^~^!YY5BB55PGGPY!!~~~^^~!J5?777777!!5G##    //
//    [email protected]!~~^^~!7?Y5JJ#&&@&BG#5YYYPBB!^!!~!77?7??!^[email protected]?7!~~~~!~~~^~7GBPY?::^^!777!~^^^^75PYY55JJY55    //
//    JYBY7~!!~~^[email protected]@@@BGG5GP55P?7JJ?JYY5GG5YYJJYGPPPJ??JYYYJJ77!~~7!!7?777YYJ7!~^~~!Y5PB#BY77~:    //
//    PY5^~?JY5PPPYYJY????!!5&@@@BP5JP555?!?JJYYYPGB&&#YP5?75GGP5GP##BBGYYY?!P&#GJ!~^::^:.::::.:^!7JPB?~!?    //
//    BJ77JY5GB##BP5Y5YYJJ?!7##GPJ77!~^^::^::^^~^~~!7?J7YJ7!75PG#@@@@@@@&BB57YJ~^::::^::..^!!~~::^^^~!7JYY    //
//    #5?Y55PPGGGP5YY5YYJ?77~7~^::^[email protected]@&@@@@@@@@@@&Y~^!~^~!!~~^~!~77~7~~~!~!~^!J5    //
//    #P?J5PPGGGGPPPPPPGGPYJ!!7?????JJJ???J5J?JJ??J???J???7?!7Y#@@@@@@@@@@&J777?YPPGP5Y?7YY5?7!!77~777!!~7    //
//    BBJYY5GB#&@@@@&&&@@@&YJ?7?YJ?YJJJ????JJJJJJYYYYYY5YYJJ?777Y#@@@@@@@#Y7?JJPG#GGBPYY?JYY????~77~7~7!~^    //
//    5J55Y5PB#BB#&@#[email protected]@@@@&G?JYY5G#G5PGYYYY55Y5###G5555J???!    //
//    &Y?Y55PGGGP5G#PJ?JJ~!?77Y5Y55Y??JJYY??7J5GGGGGBBBB#[email protected]@&&&YJYJ?PGPPP55555PGGBBGP5J?7?PBP??7    //
//    Y?77PPB#&&&##&&BBP!J57J5JP55YY55YY5J7JYY5GB#######BGGPPP55J7?J#@&&#J5G5YYP5P555GGB##BP555YJY??!?&Y~P    //
//    5YJJ?YB&@@@@&&@@&5!7~~J5?JY5PPPGPPPGB#BP5PPGBBBBBG55YYYYYYPGBG5&@@BJP5P55GG5PPPPPPPP5PY55GPGGGPY5J~?    //
//    G55J7PB&@@@@&###[email protected]@GJGYG5B&&P555P5555P5555J???!!!J?!^    //
//    GGB5JPB&@@@@@@#YJJ!!7YG&#555PPPG###BGBGGG5555YJJYJJYJJ5#[email protected]@BJPPGGP&&P5PPGGGGBGGGGP5P555YY5J?!    //
//    #BPPGGP#&&&##GJYJJGBBB#&BY55PGB#&&&#B###&&&&&&##PJJYYJ5#[email protected]@&JP#GB&&@GPGGGGBB#######BB#&##GGBY    //
//    GBGGP##&@&###?5PP#@@@@&&@5YPPPG##@@@@@&&#BPPGB#@@#[email protected]&G7YGBGB##BGPGGB##&@@@@@@@@@@&&@@&#    //
//    JY?7Y#&&@@&##PP##&&&@@@@@&P555GB####&##BGBP5PBB&@&GB5?JYPGGGPYJ&&#77J5GGB#&@#BBB#&&&@@&@@&&@@@#BBBPY    //
//    YJ?!7B&&@@@@@@B##G#&#&&@&B5JY5PB#BGPBB##&@@&##B#&&#GGYJJ5GGP55GBP7!7?YP##&@@&&&&&&&&&&&&##BGB#&&#BGY    //
//    [email protected]&@@&&@&PYP5PBGBG#&PJY5PGGGBGGPP55PGP5PG#&#&&&#G5Y?GBGPBY^~!7?JJYB#&@@@@@@&@@@@@@&&&&&#B#BB#G5    //
//    PP55PB&&@@&G?!^^!Y5BGGB#&B55PPGGGB#BB####BGP##&&&@&&&#B5JB&Y?7^^!!!??JYB&&@&&&&&&&@@@@@@@@@@@@@@@@&&    //
//    YY55GB#@B57^~!7!~!?JGB#&&&&G5PGPG#######GGG5G&#&&&@&##BG5#&?^~7?JJYJYPB&&&&###&&&&@@@@@@@@@@@@&###G5    //
//    ??JJYPP?^:^!7???7YPG#BB&##@#5PB####&&&##BBGGG##&&&&&&&#B##Y!?J5PGPGGB#&&@&B###&&&&&&@@@@@@@&##B5??!~    //
//    7!!777~777???JJ?JGPPB#B##&&&P5B#BB###&&&&##BBB&@@@@@@#PYGP??G###&&&@@@@@@&BBB###&&###BGGB##BG5J7!~~~    //
//    ??7!!~7????7?PBPGBGG##BB&@&&&GPGBBBGPBB####&&&&&&@&#[email protected]@@@@@@@@@@@&###&##B##PJ?7!!7JYYYY?7~~!    //
//    YJ77~~7!777JY55YPPP#BGG#@&@&&&BGGPPP5GGBGPGPGB&&&@&##[email protected]@@@@@@@@@@@@&B##B###BYJJ??7!!7??5GP5JY    //
//    ??J5Y?!7JJ?YP5Y55GBB##&&&&@@&&&&#BBBGPBBBGBGGBB##&&[email protected]@@@@@@@@@@@&##B####&B5PGBPY???7J5BBPY7    //
//    JY5GGJ?555GBBGGG#&&B&@@&@&&&&&&&@&&&&#&&&&&&&&&##BBBGY7:!5BGYG&@@@@@@@@@@@&##&##&&G5G##B###P5YPGBYY7    //
//    GBB##J?YGPG##&@@&##&&&&&#&&##&&&&&&@&&@@@&#&@@@@@&GP5J!^[email protected]@@@@@@@@@&&##&&#&&@GP#&&&&&#GGJ5GPYJ5    //
//    B##&&P?JB#&&B#@&##&&#&#BB##B#&&&#&#&#&@&&&##&&&&#GGPJJ?!!J?7!7JB&&&&&BGGP555PPPGBGPB#@@@@@&PGYP&BPPB    //
//    &#BGGPJ5B#BP#&&&&###BBBBBB#######&########&#B##BBBGBBG5?77!!!~^^JPBBBPP5Y??JJJJYYYJYB&@@@@&PJ7J&@@PG    //
//    GG##[email protected]&&&&##&###BBGBBGBB#&B########BGGGGBG#G5GBJ?J?7JJ7^:^^[email protected]@@PP    //
//    &&&@GJJ?JPBB#&##&##&#&##&&&BBPGB####B#BBBGGGBGGGGGYYYJJJ??7~~7?~^^^:7GG#BGGPYYYYJYJJJYJ5GB###B#@@@&&    //
//    PP5GG?^!?PGGGGG#B##&&&&&@@&BBGGBGGGGBBBGGGBBGBPBG?5PJ?7?J5Y!!!77~~~^:?&#&###BB#P5GGGBBGBB###PG&&@@&@    //
//    !?YJ555?7Y5PGPGB#B###&&&@@&&&#B#BBBGGGPPGB&&&BPJ5JY?7??J5Y?7YJ?77~~^::[email protected]@@@@&&&#&#B&&@&&#&#GB&@@@@&@    //
//    YJ?7?Y!^!J5GGGBBBBBB#&&@@@@@@&&#&&#BB#BBB#&#BPPJ5Y555JJJ?7JYJJ!7?!^!!:[email protected]@@@@@#@@@@@@@@@@#&@#[email protected]@@@@#&    //
//    !!?!7?!!!JP#&@&&#BBB##&&@&&@@@@@@@@&&&&&&&@@[email protected]@@@@@@@@@@@@@@@@@@@@#B#@&&B#    //
//    7!!~!!~:^?YG&&#BPGBB#B#&@&@@@@@@@@@&@@&&@@@@#[email protected]@@@@@@@@@@@@@@@@@@@&#BGGB#BGB    //
//    !~!!7~::~75GGGBBBBBBB##&&&@@@@@@@@@@@@@@@@@&B#BG#G5G#GGGB5J!7!Y5?Y?YP&@@@@@@@@@@@@@@@@@@&#GP5PPG#BG5    //
//    ~!!~^^~^^JPBB#B#&&@####&##@@@@@@@@@@@@@@@@@@@BG#[email protected]@&@@@@@@@@@@@@@@&&#BG#BBBBG#BP5    //
//    [email protected]@@@@&#&#B#####&@&&@@&&###&&&#B&#BPG#BG&&#GY5GGP55GBYY5BGBBBGB&@@@@@@@@&&&BGBB#&&@&&&#G5    //
//    !!7^~7?!77:^[email protected]@&&&B##B####BBBGB#&#BPBGB&BGGBB#&#BBBBGG&&#@#PPPPP55?YYGJ5JY#@@##@@@&&&&&BBB&@@&BBPBGP    //
//    Y7!:^!7!!?!!7G&&&&#B#BBBBBGBBPGGGGGGBG5G5P55BGPBBPGBGB&B5G#GG5PBGG5YY!!~?5P#&[email protected]@@@@&&&&&@&#BB5?JY    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract JDV is ERC1155Creator {
    constructor() ERC1155Creator("JPEG da Vinci Editions", "JDV") {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC1155Creator is Proxy {

    constructor(string memory name, string memory symbol) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x6bf5ed59dE0E19999d264746843FF931c0133090;
        Address.functionDelegateCall(
            0x6bf5ed59dE0E19999d264746843FF931c0133090,
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