// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The TwilightZone
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    JJ??????77777!!!!!~~~~~~~~!!!777?????JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJ?????????????77777!!!!!!~~~~~~~!!!!!!77777???????JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ????????77    //
//    ??????????JJJJJ?JJ?????????????????7777777!!!!!!!~~~~~~~~~~~~~~~~~~!!!!!!!!~~~~~~~~~~~~~~~~~~~~~~~~!    //
//    !!!7777777777??????????????J?JJJ?????????????????????????777777777777777777777777777777777??????????    //
//    ~~~!!!!!!!!!!!!!!777777777777???????????????JJJJJ?J?J????JJ?J?????????????????????????????JJJJJJJJJJ    //
//    ^^^^^^^^^~~~~~~~~~~!!!!!!!!!!!!!!77777777777777???????????????????????J?JJJ?????????????????????????    //
//    ~~~~~~~~~~~~~~~^^^^^^^^^~~~~~~~~~~!!!!!!!!!!!!!!!!!!!~~~~~~~~!!!!!77777777777777777777777777777!77!!    //
//    ~~^^^~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^~~~!!!!!~~~~~^^^^~~~~!!!!!!!!!!!!!!!!!!!!!!!!!!!!~~~~~~~~    //
//    !!!!!~~~~~~~~~~^^^^^^^^~~~~~~~~~~~~~~~~~~!!?JJJJYYYYYYYJJ?7??JJJYYYJJJ?77!~~^^^^^^^^^^^^^^^^^~~~~~~~    //
//    ?????7777777!!!!!!!!~~~~~~~~~~~^^^^^^~~7?JYYYYYYYYYYYJJJY5PGB########BGP5YJ?7~~~~~~~~~~~~~~~~~~~~~~~    //
//    ????????????????????7777777!!!!!!~~~!77??JJJYYYYYYJJY5GB#&&@&&&&&&&&&&&&##BG5J7!~~~~^^^^^^^^^^^^^^^^    //
//    !!!!!!!!!!77777??????????????????7?J7!77??JJJJYYJJYPB&@@@&&&&&##BBBGGGGGGGGGGG5J7^^^~~~~~~!!!!!!!!!!    //
//    JJJJJ?????77777!!!!!!!!!!77777???YJ~!!77????JJYYYG#&@@&&&&&#BGPP5555YYYYYYYYYYYYY?!^^!??????????????    //
//    JJJJJJJJJJJJJJJJJJJJJ??????77777Y7~~~~!!777?JJY5#@@@&&&&#BGP5YYJJ???77777777??????7!~:~???????777777    //
//    ??????????????????????????JJJJJ5!^~~~~~~~!7??YG&@@&&&&#GP5YJJ??77!!!!~~~~~~~~!!!!!!!!~:^!7!!!!777777    //
//    [email protected]@&@&&BGP5YJ?77!!~^~^^^^^^:^:::^^~~~~~~~~^^?JJJJJJJJJJ    //
//    ??????????????????777777777?Y55JYYY7!!~^~!J5B&&&&&#G5YYJ?7!777???JJ???J?77~~~^::^^^~^^~~::7????77777    //
//    77777777!7777!!!!!7!!!!!!!JP?!!!!!JG7!!!!?5B&&&&#GP5YYYYY55PPGGGGGGGGPP5P5YYY?7~^::^^^^^^:^7???77777    //
//    !!!~~~!!!!!~~~!!77!~~~!!7Y5!!!!75B#@BJ77!PP&&##BPPPPPGBBBBGGGGGGGGGGGGGGP55Y555YJ7^^^^^^^^:~77777777    //
//    7!~~!!77!~~~!7777~~~!!JGB&BBB###@@#[email protected]&?!YPB##BGGBBB#####B5J7777JY5PBGGPGPP55YP5YJJ?7~^^^^^^:~!~!7777    //
//    [email protected]@@@@@@@@&#[email protected]#?7GPBGBBB########BY~::::~?YGGGGGPPPP5YY5YYY????7~^^^^:^7!~~!7!    //
//    [email protected]@@@@@@@@#[email protected]#7?PPGGB#########BB5?777JYPGBBGGP5555YJ5P5JJJ????J!^^^^^!7!~~~7    //
//    [email protected]@@@@@@@@&[email protected]!JP5G#&##########BBGGPGGBBBBGG5Y5P5YJ555YJJ?77?JJY!^^^:!!7!~~!    //
//    [email protected]@@@@@@@@#[email protected]!?P5#&#BB#BBBB##########BBBGP5555YYY55YYJJ??JJJYYYJ~^^:!7!7~~~    //
//    [email protected]@@@@@@@@#[email protected]#&BBBBBGGGB###BBBBBGPGP555P555555YJ?77??JY5555Y!~^:77!7!~~    //
//    77?7!~~!!7??!7~^~!!77!?J5#5555P&&[email protected]!5Y##BBBBBGPPPPGGGPPPPPPPP55PPPPPP55YJJJJYY5PGGGP57~^:77!77~~    //
//    7?77!~~!!??7!7~^~!!?7!!^~PY77!~?B&&&&Y77?PP#BBGGGGPPP555555PPPP5PPPGGGGPPPPGPPPPGGGGBBBBG7^^^?7!77~~    //
//    7?77!~!!!???!7~~~!!?7!!~~!P5777!!?5#?77?!55B#GGBGGGPP5555P5PPP555PGGGGGBBGPPGGBGGBB####B5!^^~?7777~~    //
//    7?77!~!!!???77~~~!!?7!!~~!!YG5JJJYPJ!!777!P5##BBBBBBBBGGPPPPPPPGGGGGGGBGPP5GBBGYYPB###B5?~^^??7777~~    //
//    7?77!~~!!7??77!~~!!77!!~~!77?PJ???!~~!!7777PP########BGGPPPPPGBBBBBGPGBBGPPGBBP??J5GBB5?!~^!J7777!~~    //
//    7??77~~!!7??77!~~!!!?7!!~~!77JP~~~^::~!777!7PG#&###BB####BBB#G55Y555Y5GB##BB#BG5YJ5PBBY7!~!??!777~~^    //
//    ???77!~!!!??777~~!!!7?7!!!~!77Y5~^^^~~!!7777!YGB#&&&###BGGBB#GGGGPPPY?777YPB&&&#BGGGBBY7!!??7!77!~^~    //
//    ???77!~~!!7??77!~~!!!7?7!!!~~!!JP?!!J5J?777?7!75GB&@@&###&&&&&&@&&BGP5Y?!!!7YG&&#####5?77??!!777~~~!    //
//    ???7!7!~!!7??7!7!~!!!77??7!!!~~~?GY?7?5PPYJ?777!?YPG#&@@@@@&@@@@@&#&&&#BGPP55PB&&&#GY?7??7!!7?7~^~!!    //
//    J???77!~~!!7??7!!!~~!!77???7!!!~~!YPY???J5GG5J?7!!7J5PG#&@@@@@@@@@@@@@@@@@&&&&&#B5J????7!!77?!^^~!!~    //
//    J???7!7!~!!!????7!!!!!!!77????7!!~~7BBY????J5PGP5J7!!7?Y5PGBB#&&&@@@@@@&&&#BGPYJ?????7!!7??!~^~!7!!7    //
//    7??J?7!7!~~!!7????77!!!!!!777????7JP55GGPJ???7?JY5PP5J?777?JJYY5555PPP55YJJY7J?7??77!77?7!~^~!!!!7??    //
//    77?JJ?77!!!~~!!7?????77!!!!!!777YBGY???J5GBPJ?777777?JYYYYJJJ???????J?JJJJ?~~GY77!77?77~^~~!!!!77???    //
//    !77??JJ?77!!!~~~!77?????77!!!~~5B5YYJ?77!!?G&GP5J?77777!!777?JJJJJJ?JYJ~^^~7J57Y7?77~~~~~!!!!7?????7    //
//    ~~!77??JJ?77!!!!~~!!77?????7!7PBP55Y?!~~~^^~YBYYPGGP5J?77!!!?JJ!!!~~!J?!?J?!5!.JY~^~~!!!!!77???77!!7    //
//    !!~~!!7??JJJ?77!!!~~~!!77???JB5????J55?!?!:::YGY77?JYPPGGP55555YYYYYYJ?7!!7JG:.J7??!!!!777??77!!777!    //
//    7!!!!~~!7??JJJ?7777!!~~~!!77B5???77!^~YP?JJ:::GJ5~!!!!!!!!~!7!!!~~^^:^.7JJJJY..Y~:Y?77???77!!777!!!!    //
//    J?77!!!~~!77?JJJ?77777!!~~~Y#J?????!^^:~PYYY:^JY?~^^^^^^^::^^^!!!77!:P~^~~^?Y.:?~!^P??777!77!!!!!!!!    //
//    JJJ??7!!!!~!7??JJJ??7777!~JGJYYJ7!?YJ~!~^GYG?~7P~^::::::::^~~5#5555BJJY7777?~:::?!.!5!!777!~~!!!!!!!    //
//    ?JJJJ??7!!!~~!7?JJJJJ?777PPJ??7??!^^?P757!#[email protected]?~~~JG:^~!!~~^^::Y^7:7Y!!!!!!!!!!!777    //
//    ???JJJJ?7!!!!!!7JJJJJJJJBPYY?77!~~~^:~PJP!BP57JJ5#[email protected]?~!~JB:?5?JPPPGJ:5JJ:.Y7!!!!!!!777!!7    //
//    7??JYJJ??7!!!!!!?JJJJJJBG?JYP5Y7^:^77:~GY!#G????GB^^^^^^^?#[email protected]!!!YP:5G5YGYJ5#7&P::.~Y!!!!777!!7777    //
//    77??JJJ???!!!!!!7JJJ??PB???77?JP57::?J.JJYG?????BG~JJJJJ7!#7!5GYYYYY!^Y#PYPPP5B&P::~!?P!777!!7777!~~    //
//    77??JYJJ??7!!!!!7JJJ?Y&5J??77!~:~JY~.??75P??????BG!J????!7#7!5B^!J~B7^JBG?JYYYGY^?Y7~^5?!77777!~~~~~    //
//    777?JYJJ??7!!!!!7JJJ?#G5PP5Y7~^~~:^??:5Y#J??????BG^^^^^^^7#7!5&^!Y^#7~!?JP&B##??G57!77?P77!!~~~~~!!7    //
//    ?77??YJJ??7!!!!!7JJJY&P555PPY?7!!77!?YBBYY55YJ??BG^~~~~~~!#7!5&~!Y^#7~~~~7PPPGG&PYJ?7!~JY~~~!!!!777?    //
//    ?77??YYJ??7!!!!!7YYJP#YYJJ??7!~^..:~?#@#GP5Y55?7BG^~~~~~^~B7!5&~!Y^#?~~~7?PGP&#J7!~~~~~~JJ!77777????    //
//    ?77??YJJ??7!!!!!7YYJPB????JJJJ??7^[email protected]????7775#[email protected]~~Y^#?~~~!JJYY&P555YJJ???YB7????77!~~    //
//    ?77??YJJ??7!!!!!7YJJP#PPPPP5YYJ?7!!~^?&[email protected]~~Y~#?^^^^?JJJ##J?7!~^^:::5J!!!~~~~~~    //
//    ?77??YJJ??7!!!!!7YYJY&5J??JY55YJ?7!!!BP??????777!~~~^^^^[email protected]!~7^#?^^^^:~?PG#555J777!~:J7~~~~~~!!!    //
//    ?77??YJJ??7!!!!!7JYJJBJYPGGGP5J?7!!~!G5??????777!!~^^^^^[email protected]!^?5&7:^^:^JGYJ&GP5Y?7!!7YB7!!!777???    //
//    ?77??YJJ???!!!!!7?JYYG#G5YJ??7!!^^:.~#J??????777!!~~~~~~~~~~~?#B7JJ&7:^:::YP7?#P55YJ?!^.:GJ??JJJJJJJ    //
//    ?77?JYYJ???7!!!!!7???5B???JY5PP555YJ7GY5P5YYJ?7!!!~~~~~~~~~~~G#&!:[email protected]:::::BJ?7BBPPPPPGGY^GJJJ????777    //
//    ??7?JYYJJ???7!!!!!!!77G5JGG555555YYJ5BJJY5PGGGGPP5YJJJ?????~!BG&[email protected]!???Y&J??J&BJ?JYGG#B57777!!!!!~    //
//    ????JYYYJJ????77!!!!!!7G&5?PGPY?~^!G#YJJJJJ??????JJJYYYYYYJ~~JG#G55G~!YJJ?#5YYP#7^^^^[email protected]#Y!!~~~~~~~~!    //
//    77??JJYYYYYJJJJ????77777PPP&Y??7~:::GP5PPPPPPPP5J7!~~~^^^^^~~~~!!!J7^^::..5BYPB?!~:::?G!~~!!!!!!!777    //
//    !!777??JJJJJJYYYYYYJYJJJJYYB5???!^^:7#PPPP55YYJJJ5PY!~~~~~~~~~~~~JP~^^^:::^PBBJG?P?..5?!777777????77    //
//    7777777777777777777????????YBJ???~~Y:G5JJ??JJY55J7!JP5!!J!!7~~~7PP!~~^^:::::5P755PY.7P???77777777777    //
//    ????????????77777777777777775GJ???!5Y7GJ???77!!!7J5J!YB??5?Y!JPGJ!!77?????77?BY?PG~?5777777777??????    //
//    JJJJJJJJJJJJJJ???????????????YG5JJ??PPBPYJ?7!!!~~^^75YJ#JPPGPPYJY555J?7~^^::.?BPP?5577??????JJJJJJ??    //
//    YYYYYJJJJJJJJJJJJJJJJJJJJ?????JP#PPP5PY5PPPP5J?!~~^^^?5BBG&&PPP5Y?7!!~~~^^::::GG55J??JJJJJ??JJJJJJYY    //
//    JJJJJJJJJJYYYYYYYYYYYYYYYYYYYJJB5??JJJ??77777JY5Y?~^^!?P&B&B5J?7777!!!!~^^:::.~GJ??JJJJJJJYYYYYYYYYY    //
//    !!77777??????????JJJJJJJJYYYYYP#PP5Y55555Y7~~~^~7YP?^!BGPP#JJ???777!!!!~~^^:::.!PJYYYYYYYYYYJJJJJJ??    //
//    :::::^^^^^^^^~~~!!7777????????BYJY5GGGPPYJ7~^^^^^^~Y55PYYPBPJ???7777!!~~~^^^^^~^YPYYJJJJ???????JJJJJ    //
//    777!!!!!!~~~~^^^::::^^^~~~~!~JG??????JJY5PP5J7~^:^7?GY???JBB?JY??77777?JJJJ??7!!YP?????JJJJJJJJJJJJ?    //
//    ??????????????7777!!~~~^^^^::YGPYJ????77!!!7?Y55Y7YP!!!!!!75PGJ??JY555J?7!~~^::.^GJJJJJJJJJJ?????77!    //
//    55YYYYYYYYYJJJJJJJ???????777JG?J5P5YJ?77!!~~~~~~?G7:::::::::?BJ5GP5J77!!!~~~^^^::YJ?????7777!!~~^^::    //
//    PPPPPPPPPPP5555555YYYYJJJJJJGY?J55PPPY?7!!~~~~~Y57!7!!!!!!!7!J#BY???77??JJYYJJJ??PJ~~~~^^^^::^^^~~!!    //
//    PPPPPPPPPPPPPPPPPPPPPP55555P#JJ??JYYY5555YJ?77PP?JJJJJJJJJJJJ?5BJJY5PP5YJ?7!~^:..?7:^^^~~~!!77777???    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPBB?5PYJ???7777777!~G5555555555555555GBGP5J?77!!~~~^::.?J777777?????JJJYYY    //
//    PPPPPPPPPPPPPPPPPPPPPPPPGGPBB??J5PGP5YJ?7!!!?PBPPPPPPPPPPPPPPPPP#BP555Y?7!!~~^^:.75JJJJJJYYYY5555PPP    //
//    5555555555PPPPPPPPPPPPPPPPPGB??????JY5PPPPP5?JGPPPPPPPPPPPPPPPPPP#GP555J?7!~~^::.!G555555PPPPPPPPPPP    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TTZ is ERC1155Creator {
    constructor() ERC1155Creator("The TwilightZone", "TTZ") {}
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