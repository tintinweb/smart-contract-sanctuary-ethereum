// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Unity Through Vandalism
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//    5PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPGGGGGGGGGGGGGGGGGBBBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG    //
//    55555PPPPP5555555555555555PPPPPPPPPPPPPPPPPPPPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG    //
//    5555555555555555555555555555555555555555555PPPPPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPPPPPPP    //
//    5555555555555555555YYYYYY5555YYYYYYY555555555PPPPPGGGGGGGPPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPPPPPPPPPPPP    //
//    55555555555555555555YYYYYYY5YYYYYYYYY5555555555PPPPPPGGGPPPGPGGGGGGGGGGBBGGGGGGGPPPPPPPPPPPPPPPPPPPP    //
//    555Y5YYY555555555555YYYYYYYYYYYYYYYYY5555555555555PPPPGGPPGPPPPPGGGGGGBGGGGGGGPPPPPPPPPPPPPPPPPPPPPP    //
//    YYYYYYYYYYYY555555555YYY555555YYYYYYYY555555555555PPPGGGGGGPPPPGGGGGBBBGGGGGGPPPPP555PPPPPPPPPPPPPPP    //
//    YYYYYYYYYYYY5P55555555Y5555555555555YYY55555555555PPGGGGGGGPPPGGBBBBBBGGGGGGPPPPP555PGPPPPPPPPPPPPPP    //
//    YYYYYYYYYYYYYPGPP55555555555555555555555555P5PPPPPPGGGBBGGGPGGBB###BBGGGGGGPGGPPPGGGGPPPPPPPPPPPPPPP    //
//    YYYYYYYYYYYYY5PGPP555555555P555555PPPPPPPPPPPGPGPGGBB##BGGGGBB####BBBGPPPGGGBGGGBBBGPP555PPPPPPPPPPP    //
//    YYYYYYYYYYYYYY5PPP5PPPPPPPPPPPPP55PPPGGGGGGGBBBGBBB#&##BGBBBB#####BBBGPPGGBBBBB#BBBGP5555PPPPPPPPPPP    //
//    YYYYYYYYYYYYYY5PBBGPPPPPPPPGGGGGP55PPPGGGBBBBGBGB######BB####&###BB#BGBB##########GPPPPPGGGGPPPPPPPP    //
//    YYYYYYYYYYYYYYY5G#&BPPPPPPGGGGGGGPPPPPPGBBBBBBBBGB#########&&&&#B##&###&#&&&&&&&##BBGGGGGPPPPPPPPPPP    //
//    YYYYYYYYYYYYYYYY5G#&&GPPPPGGGBBBBBBGGGPGBBBB#B###B#######&&&&&&##&&&&&&&&&&&&&&&###BBGBBGGGPPPPPPPPP    //
//    YYYYYYYYYYYYYYYYY5GB&&GGGGGGGBBB############&&&&&&&&@&&&&@@&&&&&&@&&@@&&&&&&&&##&###BBBGGPPPPPPPPPPP    //
//    YYYYYYYYYYYYYYYY55PBB##GGGGGGBB###&&&&&&&@@@@@@@&&&&&&####&&&&&&&&&&&&&&&&&&&&#&&&###BBGGPPPPPPPPPPP    //
//    YYYYYYYYYYYYYYYY5P5GBB##BBBBBB###&&&&&&@@@@@&&&&&&&&####GPPB##&&&##&BB#&&&&&&&&&&&&###BBBBGGPPPPPPP5    //
//    YYYYYYJJJJJJJJYYYPPPGGB###&###&&&&&&&&&@@&&&&&&&&&&&&&#B5Y5GB###BBBBB##&&&&&&&&&&&&#####BGPPPPPP5555    //
//    YYYYYJJJJJJJJJJYY55PGGB##&&&&&&&&@@&&@@@&#&&&&&&&&&&&&&BPBBPPGBG5YBBPP####&&&&&&&&&&###BGGPP55555555    //
//    YYYYYYJJJJJJJJJJY55PGB##&&&&&&@@@&&&@@@&&&&&&&&&#######BBB57!JGJ^~GBPJ5##B######&&&##BBGPP5555555555    //
//    YYYYYJJJJJJJJJYYY5PGB#&&&&&&@@@@&#&@@@&&&&&&&&###BBG#GGBBGJ^.~Y~ ^G5Y7^JBBBBB#########BGPP5555555555    //
//    YYYYJJJJJJYYYYY55PG##&&&&@@@&@&&&&@@@&&&&#&#&&&BGPPPGPYPPPYJ?7J~..5J7.  :JGBGYP##BB####BGP5555555555    //
//    YYYYJJJJJJJYYYY5PGB#&&&@@@@&&&&&&@@@@@&&&####&&BGPPJYPY5J!~?YJY?^.!!.     ^5BY^YG55BBB#BGP555YYYYYYY    //
//    YYYYYYJJJYYYY55PGB#&&@@@@&&&&&&&&@@&&@&&#BBB#&##BPPGPY??~~^~!~~!7~:^..     .YG~.!J7YPGBBGP5YYYYYYYYY    //
//    YYYYYYYYYYYYYY5PGB#&&@@@&&@@&&@@@@&&&&&&#BGGB&@@@@&BYYJJ!~!~^^^:^~:::.      :57  ~7!?YPGGP55YYYYYYYY    //
//    YYYYYY5P5YYY55PGB#&&&&&@&@@@&&@@@@&&&&&&##BBB#B&@@&BGP5YYJJ77!!~^^^::....    !~  :~:^!5PPPYYYYYYYYYY    //
//    YYYYYY5GG55YY5PGB##&&@@&@@&@@@@@@@@@&&&&&&#[email protected]@&BGGGGGGGGGGGGP5Y?!~^::....^:  ::.:^?5555JJYYYYYYY    //
//    YYYYYYY5PGP5555PGB#&&@@&&@&&&&@@&@@@@@@&&#BBGPPG&&&#BGP55555PPGGB####BPJ7^^:.:. ..:::^!JYYYJJJJJJYYY    //
//    YYYYYYYY5GBGP55PPB#&@@&&&&&&&&&&&&&@@@&###BGGPPG#B##BG5YJYYJJJYY5GB#####B5!^:...::::^~~7JJJJJJJJJJYY    //
//    YYYYYYYYYPG##BPPPB#&&@&&&&&&&&&&&&&&&&##BBBGGGGG#GG##BGPP55YJ?77?5G#####BGJ^. .::^^~!777JJJJJJJJJJJJ    //
//    YYYYYYYYY5PG##GPGB&&&&&&&#&&&&&&&&&&&##BBGGPPPGB&###&&##BGP5J7~:^?P#&&##BGY~^^^~?YPGBBGGPYJJJJJJJJJJ    //
//    YYYYYYYYYY55G##BB#&&&&&#&&&&&&&&&&&&##BGP5YJY5GB&@&&&&&&##BP5?!^^JGB&&&#BY?~~775B##BGP5JJJJJJJJJJJJJ    //
//    YYYYYYYYYY55PG#@&&&&#BGBB#&&&&&&&&&&##GY??777J5G#@&&&@@&&#BG5?7!7P##&&&#BY~.:^?B#BPY??Y5J?J?JJJJJJJJ    //
//    YYYYYYYYYYY55PB&@&#BPPGGGGB#&&&&&&&##B57!777?Y55G&&&@@@@&&&##BBBB###&###BP?^..7##B57~75PJ?????JJJJJJ    //
//    YYYYYYYYYYYY5PGB&&G5#&&###BB##&&&&&##57~7?JJYYYYP&##&&@@@@&@@@@@@&&#BB#BBP5?^.~P&#BP5PGP????????JJJJ    //
//    YYYYYYYYYYYY55PG#&5B&&&BB#&BB##&&&##G?!7?YY55YY5G#PGB#&&#######BBG5Y5GBGGP5??7^^Y##BBB#5J?????????JJ    //
//    YYYYYYYYYYYY555PG#5B&&GPPG#&###&&&##Y!7JY55PP55PBPYP5P#PPPYJJYJ7?J??YPGGGGG5YY7~!7G&&&B5J??????????J    //
//    YYYYYYYYYYYYY55PGBGP&PPBB#&&&######BYJJY5PPPPPPPB555Y5B?5J7:.:^^7~~7J5GGBGBBPPY!^:~5&BYJ???????????J    //
//    YYYYYYYYYYYY555PPBBPP5B&##&&#######GPPPPGGGGGGGBGPP5YPGYY?7^.  .^^~7?5GGBB#BBG57::.^Y5J????????????J    //
//    YYYYYYYYY5YYY555PGBB5P#&#GB&#PGBB#BGPPPGGGGGBBBBGGP55PY?!^::~7^:~^^!?YGGGGBGBBBPY7~~!!J???????JJJJJJ    //
//    YYYYYYYYY555Y5555PBBBPG###B#&#5GBBGPPGGGGGGBBBBBGGPP55J7!~^::~PJ^.:!7YGGGGB#&&&#GPY7^~?J????J5P555P5    //
//    YYYYYY5555PP55555PGB##GGBB#GPBBBBBP5PPPPGGGBBBBBGGPP5YJ?7!~^:~P?:.:??JBBBB##&&&#G57^^~??????J5GGGGBB    //
//    YYYYYYY5PPPGPPP55PPGB###BGGPG##BBGP55555PGGBBBBBGGPP5YYJ?7~^^!P~:::~^^75PGGGGBG57^^~!7?YJ???J5B#####    //
//    YYYYYY55PPGGGPPPPPPPGGB#&#GPGGB#BGPYJJJY5PGBBBBBGGPP5YYJJ?!~~JY^:::::^^~7JYJ?YJ7^~!!7?YGP??JPB#&&###    //
//    YYYYYYY55PPGGPPPPPPPGGBB#&&BGPPGBBPJ???Y5GGBBBBBGGPP55YYJJ?77?!~^^^^^^~~7??7~?77!~!7?JGGPY5GB##&&&&&    //
//    YYYYYYYY55PPGP55PPPPGGGBB#&#GPGBBBBJ???Y5GBBBBBBBGGPP55YYYJJJ?7777777??JPGBBPJ????7?JYYGGBB#####&&&&    //
//    YYYYYYYYY55PPPPYY5555PGGGB##B5PGGGBP???YPGGBBBBBBBGGPPP555YYYYYYYYPPGB&@@@@@&&##BGJJJJYGBBBBBB####BG    //
//    55YYYYYYYYY5PPPYJYYYY5PPGGBBB5YPPGBB57?J5GGBBBBBBBBGGGPPPPP55555PGB####BGPPGBB##&PJJJJ555PPPPBB#BPJJ    //
//    555YYYYYYYYY5P55YJJJJYY55PGBB5J5PGBBB5?J5GBB###BBBBBBGGGGGPPPP55555PPPPPY7^:^!77YY?J??JJ?JJYPBBGY???    //
//    5555YYYY55YYY55YYJJJJJJYY5PGGPJ5PGBB##BGGBBB#####BBBBBBBBGGGGPP5555PB####BG5J?7?J???7?YJJYJ5GGP5?777    //
//    55555YYYYYYYYYY5YJJJJ??JJYY5P5J5PGBB##&&##B#########BBBBBBBGGGPP5555PGB#&&@&&#BPJ????YY?77J5P5Y?7777    //
//    555555YYYYYYYYYYYY5BB5???JJJYYJ5PGBB###&&&&##############BBBBGGGPPPPPPGBBGGGGG5J?YY5P5J77?YYY?777777    //
//    555555YYYYYYYYJ5YY5GG5J??????JJ5GGBBB###&&&&&&&##############BBBGGPP55Y7~^^^^!??YYPP5?777JJJ?7!!!777    //
//    5555555YYYYYYYYYYY5PYJ?????JY5JPGBBBB#####&&&&&&&&&############BBGP5YJ?!!!!!~~7JYJJJ7!!77??7!!!!!777    //
//    5555555YYYYYYYYJYYG##Y????J5PPJPGBBBBBB######&&&&&&&&&&##########BBGP55YYY5YJ??Y?77!!!7777!!!!!!!777    //
//    55555555YYYYYYJJJY5JYJJYY5PPPPYPBBBBBBBB#######&&&&&&&&&&&####BBBB#BBBGGGGPPYJJ?77!!77!!!!!!!!!!!777    //
//    55555555YYYYYYJJJJJY5PGGBBGGGP5B##BBBBBBBBBB#####&&&&&&&&&####BBG5YJY555YYYYYJ??77777!!!!!!!!!!!!777    //
//    P555PBBP5YYYYYYJJ5G#####BBBBBGB####BBBBBBBBBBBBB###&&&&&&####BGPY???JJJJYYY55YJ??777777777!!!!!!7777    //
//    PPP5PPP55YYYYYYY5B##&########B#####BBBGGGGGBBBBBB#########BBGPYJ?JJYYY555PPP55YJJJ???777777777777777    //
//    PPP555555YYYYYYPB#&&&&##&&&&########BBGGGPPGGGGBBB#####BBGP5J?5GP5PPPPPPPPPP555YYYJ???77777777777777    //
//    PPP555555YYYYY5B##&&&&&&&&&&&#####BBBBGGP55PPGGGGBBBBBBG5YJ?75BBBBGGGGGGGGPPPP555YYJJJJ?????77777777    //
//    GGPP555555555PB#&&##&#&&&&&&######BBBBGP5Y5PPPPPGGBGGGPPYJ?7YBBBBBBBBBBBBGGGGPP5PP555YYYJJ???????777    //
//    BBPPPP55PPGBB###&&####&&&&&######BBBBBGP5YY555Y5PGGPPPPPYYJY##############BBBBBGGPPP555YYJJ???????77    //
//    #BBBBGGBBBBBB#########&&&&##BBBBBBBBBBGP5555YJJ755YYYYY5YY5B&&&&&&&&&&&&######BBBGGGGP5YYJJJJ???????    //
//    &&&&#B########&&&&###BB#&&##BBBBBBBBBBGGPP5YJ7!^YYJ?77?JJYG&@&&&&&&&&&&&&&######BBBGGP5YYJJJJJ??????    //
//    &#BB#########&&&&&&##BGGB###BBBBBBBBBBBBGP5YJ?~~??J?77?JJPB&@@@@@@&&&&&&&&&&#####BBGP55YYJJJJJJJ????    //
//    BBGPGB#&&&&&&##&&&&##BGPPGB#########BBBBGGP5Y!^[email protected]@@@@@@@&&&&&&&&&&####BBGP5555YJJJJJJJJJJ    //
//    GPGG#&&&&&&&&&#####&##BGPPPGB#########BBBG5YY?7JJY55PPPGBG#@@@@@@@@&&&&&&&&&&&###BBGGPPBBYJJJJJJJJJJ    //
//    GGBB#&&&&&&&&&#########BGPPPPG#########BGG55YYYY555PPPGBGB&@@@@&&@@&&&&&&&&&&&&##BGP555YYYYJJJJJJJJJ    //
//    BBB##&&&&&&&&&&#########BGPPPGGB########BGPPP55J555PPPGGGB&&&&&&&&&@&&&&&&&&&#BBGP5YYYYYYYYYYYYYYYYY    //
//    #####&&&&&&&&&&&&&###BBBBGGGGGGBB#######BGPPY5P555P5PPGGPG#&&&&&&&&&&&&&&&&#BGGGGPPP5555555YYYYYYYYY    //
//    ###&&&&&&&&&&&&&&@@&&&##BBGGGGGBBB######BBGPJGBG5JYYPGGGYPBBB&&&&&&&&&&&&&BBB#BBGGGGGGPPP555555YYYYY    //
//    &&&&####&&&&&&&&&&&@&&&@@&&##BBBBB###&####BBB##BP~75PGGP7YGGPB&&&&&&&&&&&#B###BBBGGGGGPPPPP555555555    //
//    &&###########&&&&&&&&&@@@@@@&&########&&&##BB#BGP?~YPGG5^?P5GB#&&&&&&&&&&######BBBGGGGGPPPPPP5555555    //
//    #################&&&&&&&&&&@@@@&&&&&&&&&&&&##BGPYJ7J5P5Y7?P5PBBB#&&&&&&&&&&&####BBBGGGGGGPPPP5555555    //
//    ##########BBB#######&&&&&&&&&&&&&&&&&&&&&&&&&#BGP5Y555P5555YYY5PGB#&&&&&&&&&&&###BBBGGGGGPPPPPPP5555    //
//    #########BBBBBBBB#####&&&&&&&&&&&@&&&&@@&&&&&&&##BGGP55PGPY!!!!!YPG#&&&&&##&&&####BBBBGGGGPPPPPPP555    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract UTV is ERC721Creator {
    constructor() ERC721Creator("Unity Through Vandalism", "UTV") {}
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