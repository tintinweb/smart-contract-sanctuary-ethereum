// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Shiba Sequoia Forest Foundry
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                     //
//                                                                                                                                     //
//    Result                                                                                                                           //
//    &&&&&&&&########BBGGGGGGPPPPPPPPPP5555555PPGB#&&&&&&&##########P&@&#&&&&##########################BBBBBBBBBBBBBBBBBB####&&&&&    //
//    &&&&&&&&########BBGGGGGPPPPPPPPPPP5555YY55PPGB&&&&&&&##########P&@&#&&&&###BGB##################BBBBBBBBBBBBBBGGBBBB####&&&&&    //
//    &&&&&&&&########BBGGGGGPPP555555555YYYYYYY55GBB#BBBB#GPBP5G####P!!JJ?7755JYGY?5G#############BBBBBBGGBBBGBBBBBBBBBBB###&&&&&&    //
//    &&&&&&&&&########BGGGGGPPP55555Y555YYYYYJJYY55YYYY?7J7?J?!^Y###!...^~:.:!7!77!^YBPGGPGGPPBBBBBBBBBGGGGGGGGBBBBBBBBB####&&&&&&    //
//    &&&&&&&&#########BGGGGGPPP555YYYYYYYYYJJJYYYYJJP?~!7~~7?7!?77J5~..:^~7!^!?!:^~^?~!!~.:!7:~BBB##BBBGGGGGGGGGBBBBBBBB####&&&&&&    //
//    &&&&&&&&#########BBGGGGPPP55YYYYYYYJJYYY55YYJJYJ!!77?Y7!7~~~^~^^^!?!!5JJ7YYYJ?!~.....:^!?5#BBGYBP5GBGGGGGGGGGBBBBBB####&&&&&&    //
//    &&&&&&&&&########BBGGGPPP555YYYYJJJJYJ?JJ?J7?^~:^!^:^!!~!PGJYY7?7YP5YJJJ?77YBB5P?!?!.  :!J5!7^~55??5PGGGGGGGGGGGGBB###&&&&&&&    //
//    &&&&&&&&&########BBGGGPPP55YYYYYJJJJJJ???!?7!:  ~7J?5GBJ7#BGPYJY7~~~~~^:~:.!B###BGY~.::??7^.:^~?YY?5GGGBGGGGGGGBBBB###&&&&&&&    //
//    &&&&&&&&&########BBGGGPPP55YYYYYYYYJJJJ??777!^^?B&&&&&&G!!^^^~^^^!~^~!YJYPY5555GBP!!:7J7:7YPY:^YG5P5PPYPGBBGBGBBBBB###&&&&&&&    //
//    &&&&&&&&#########BBGGGPPP55YYYJYJYJY?JJ5~^^~~7JJG&######G7 .^G#[email protected]~: ..7~~~!?YBBBB^~JJ7!7JJ7^~!:~YJYJ~?JPBBBBBB####&&&&&&&&    //
//    &&&&&&&&&########BBGGPPPP5YYYJJJ??7!^!?7^~!^!??JP&#######B?^.^PP?5G!~5~.?5?7PY7YGPP7.?PY~~!~^:^.  .!!!P5JJGBBBBBB####&&&@&&&&    //
//    &&&&&&&&&&#######BBGGPPP55YYY555555J?~?7J!7?7!JJY#&&&&&&&##?^:~?~7BG!.:.::::^^^:....:?GGGGBBPJY7~7JJGGGGBBGGBBBBB###&&&&@&&&&    //
//    &&&&&&&&&&#######BBGGPPPPPP5YPG5YY5Y55Y55YJ??^?Y5GG5JJYPGJ?^ .^:JPB7~!JP5~~!~7?!:::^77YYPPPPGBBGPPPPGGGPPPGGGGGBB###&&&&@&&&&    //
//    &&&&&&&&&&&#######BBGPGP55P5PPP55J7YJ!7!~^.:77J777!!~!:^~^^:::::~^^^~?5Y7?YJJGP555P5JYBG7!7~!75PYJJ55PGPPGGGGGGBBB##&&&@@&&&&    //
//    &&&&&&&&&&&&######BBGPPPYYYJ?7??77777J??~:.~?JY!~~::~?!JY?77!7!7??YYJJYJ777Y5PY5PGGGGGBG?~7J7?7?!!!??!5PPGGPPPGGB##&&&&@@&&&&    //
//    &&&&&&&&&&&&&#####BB55PY5J?^~???7!77JJJ??7!~~!!~!!77~^!?YY57YJYY5555YYP5J~.^PPPP5YYY?J?!JYP5JY5P55PPPPPGG57???Y5PG&&&&@@@&&&&    //
//    &&&&&&&&&&&&&#####BBPYYJ?JY?JJJJJJJJJJJ?????7?J?JYG#P^^JBG#GGJ?7Y5##5YYJ57!7Y55GP555~::.:^:.!Y55Y?!~777??7!!?J?YG5G&&&@@@&&&&    //
//    &&&&&&&&&&&&&&#####BBGPP55YYJJ?JJJJJJJJJ????????JY77?!!YPY5YYJ!YYYBGYJ?55YJPG5YG55PGPPJ?J7~: .^7?~!:~7J?7!75PPBB###&&@@@@&&&&    //
//    &&&&&&&&&&&&&&&###BBPYJ7~!!:^^^~JJYYYYYYYJJJJJJ?7?7^!YYY55JJYYGGJYP&5GPGBG5PJ^^:^^7?5J:::^:.    :^7JPY~!?JJ55PB##&&&&@@@@&&&&    //
//    &&&&&&&&&&&&&&&&BYJJ7~^:^7?!~!JJYYJY5JY555YYJ?!:.^~^~7JPGGB5P##BJ5P&G##BBGGJ^:!Y5J7^:^~~. ~!:.^~~YP55J^???JPP55G#&&&@@@@@&&&&    //
//    &&&&&&&&&&&&&&&GPYP?7!^^7?!::.:!JY?YYJJ5Y?7J!^^~~!77~^~!YGB###&PYPG&B##BPY!::YBGBBBBPPGG^ :J:^7777~~JJ7GBGYJYG5PGB#B&@@@@&&&&    //
//    &&&&&&&&&&&&&&&GYYYJ~::~^~7~:^!!!?7~!^^^!JY?~^!?77Y5PP7:.:^!?5GY5GB#5Y7!~!^.^PGBBBBBBBBBP7J7YPPPP5Y5PP5GP77~JY??YP5PB#&@@&&&&    //
//    &&&&&&&&&&&&&&&B5G?JYJYGGPPP555555J~. :^~~~~~J5Y???7!YBY~?J!~7?!YP!~!JJ5PGPYPGBBBBBBBBBBBBGG7?YPPPPPPPPPJ7^:!7??J5JYBB#&@&&&&    //
//    &&&&&&&&&&&&&&&&##BP###BBGPP55555Y!~JYJYY~7~?JYJ7?77!?B&#&&&#Y?JY775#&&&#BBBBBBBBBB####BBBBB5^~PGPPPPPY:.:~^:JJYP&&&&&&@@&&&&    //
//    &&&&&&&&&&&&&BPGJY5PB###BBGPPPP55J^!JYYYJ7!!?YJ7!!7!!~7Y!JJY#&[email protected]#&&&###BB###############BJ~75PPY!7~..7~77J5JP&@@@@@@@&&&&    //
//    &&&&&&&&&&&GG5555YY5BBGPPPPPPP55J~!~^!~^!7!7?Y?7JYJJ?!77??Y5P&#JY5&@#&&&&#####BG########BBBPPPY?5G5^^?Y77J?Y?YJ5B&@@@@@@@&&&&    //
//    &&&&&&&&&BGBGGGGB55PPY?Y?775GP55Y?!. ~?~~~7YJYJJ?7~~~?JJ!J?5B&B5PG#@&&&&&&##PPJ75P55BG5JYYJ?Y5PGBG5J5YYGPGBG?5B5PBP&@@@@@&&&&    //
//    &&&&@@@@&#GPPGB#BP5PGP5J7?7J5PPP5J~:^77?YY55JJ?!:  .!5P##BB#&&G!JYGP&&&&&&&PJYYPG55P5Y5PP#GGGGPPPGPPPYPBG??7^~JY?P5B&@@@@&&&&    //
//    &&&&@@@@@&GBBBGPP5BGYGGG5!PBBPJ5J!^.. .??J?77!!7!~!JYJJGB&@&&&&7!?P!P&&&&&&#B#####GB###&#&&##BBB5JY5PPPGG!.~?7BP?5GB#&@@@&&&&    //
//    &&&&@@@&##B#[email protected]&#&#GG5J?5Y7J5!!^.^??7JJ?5PP5PGGGPPPGB&@&&&@5^J7!?#&&&&&&&&&&&&&&&&&#GGGPPGGGP555GBPGBBB7^7??J5PYG5P&@&&&&    //
//    &&&&@@@&B##BGBB#B&@@@@BPPPPPJ?55JGG5YPYPYYYPBGPPGP5555B&@@@@@&@B^. .:Y&&&&&&&&&&&&&&&&Y5GG5GBBB#BGP#&#GB###YPPJB#G&&@&@@@&&&&    //
//    &&&&@@@@@@@&&&@@@@@@@@&&&&&&BBBBPGBBBG5GGGPGGPPP55YYY5B&@@@@@@@&G?   ^G&&&&&&&&&&&&&&&5G##&&&#B##BB##BB####&&&#&&&&@@@@@@&&&&    //
//    &&&&@@@@@@@@@@@@@@@@@@@@@&@@&&&####BBBBBBGGPPPPPP55555G&@@@@@@@@B&~:~?B&@@&&&&&&&&&&&&@&&@&&##############&&&&&@@@@@@@@@@&&&&    //
//    &&&&@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&######BBGGBGGGPP555P&@@@@@@@&Y7~!PB#&@@@@@@@@@@@@@@@@@@@&&###########&&&&&&@@@@@@@@@@@&&&&    //
//    &&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&####BBBBGGPPP#@@@@@#~...7YBB&@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@&&&&    //
//    &&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&###B####BGGB&&&&&Y    ~Y#&&&&&#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@&&&&    //
//    &&&&@@@@@@@@@@&&&&&&&&&&&&&&&&#############BBBBBBBBBBBBBBBBGBP^:..?5P#BB#B#############&##&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@&&&&    //
//    &&&&@@@@@@@&&&&&&&&&&&&&&&###&&&&#########BBBBBBBBBBBBGGBGGGG?^?JPB#GPB##BBB##############&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@&&&&    //
//    &&&&@@@@@@@&&&&&&&&&&&&&&&#&&&&&&&&#######BB#BBBB#BGGGP5P5JJJ~JB##G#G5P5YP5##BG########&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@&&&&    //
//    &&&&@@@@&&&&&&&&&&&&&&&&&&&&#&&&&&########BBBB#BBGGGPPGG##J~:?GB#&&GBGJJY55GB#B#&&########&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&#####&&&&#&&&&&#######BBGBGPGBBBBB#GY?J7G#GJG&BPYG#&&#5B&&&#######B#&#&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&#&&&&&&&&&&#########BBBBGBG5GGBPY?5###P5PG#&#P5&&&&&#5##BG&#########&##&&&&&&&&&&&&&&&&&&&&@@@@@@@&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#############BGBBBBBPG5YGB#####&GJ55PYY#&&&&&&&BBBG###B##########&&&&&&&&&&&&&&&&&&&&&@@@@@&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&#########&#####BBBBBB##BBBJ#&&&&&&&&&BB&&Y^B&&########GPBGBBBBB######&&&&&&&&&&&&&&&&&&&&&@@@@@&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&#&&&&&####&&&##BBBBBBBBPGGG#&####&&&#5PG#&G?JGGPPPPPP5GGPP#&##BB#B#####&&&&&&&&&&&&&&&&&&&&&@@@@&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&#&&&&&&#&&&#&&##GGGBB#&#5&&&###BGPGB#57##GG##BB##&&&#B####BGB##B########&&&&&&&&&&&&&&&&&&&&&@@@@&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&##&&#####BBGB###BBGB#BBBBPYGGGPPP5G#&@@@@@@&&&G5#&&&&&##B##B##B##B###&&&&&&&&&&&&&&&&&&&&&@@&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&#&&##&&&&&#BB#BPGGBBBG###Y#&&&&&&&&#GB&&&&&###&PBGGBBBBBBB#B####B#B#&&&&&&&&&&&&&&&&&&&&@@@@&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&####BBB###BB####P####&&&&&&#YBB#####BGB##BGBBPPBB##BGBB#######&&&&&&&&&&&&&&&&&@&@@&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&############BBBBBBG&#GBB#BB###PG#&BGBB##GG#BGB#GBBGGGBBBBB########&&&&&&&&&&&&&&&&&&&&@&&&&    //
//    &&&&&&@&&&&&&&&&&&&&&&&&&&&&&&&#######BBBBBBBBBBB#BP#BBBBB#BBBBB5#BGG#GGBB##B##B##BGGBB#BBBBBB#######&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&&&@&&&&&&&&&&&&&&&&&&&&&&&&&&######BBBBBBBBB#BBG#BBBB#BBBBGBBBGGGBGBB#BBB######B#BBBBBBBBBBB######&&&&&&&&&&&&&&&&&&&@@&&&&    //
//    &&&&@@@@@@&&&&&&&&&&&&&&&&&&&#####BBBBBBBBBBBBBBB##BB##BBBGBPBG##BGGBBBBBBBBBB#BB#B##BBBB##BB####&#&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&&&@@@@@@@@@@&&&&&&&&&&&&&&&#######BBBBBBBBBBBBBBBBBB##BBBBBB#GBGBGGGGBBBBBBBBBBBBBBBBBBB#BBB###&&#&&&&&&&&&                    //
//                                                                                                                                     //
//                                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SSFF is ERC721Creator {
    constructor() ERC721Creator("Shiba Sequoia Forest Foundry", "SSFF") {}
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