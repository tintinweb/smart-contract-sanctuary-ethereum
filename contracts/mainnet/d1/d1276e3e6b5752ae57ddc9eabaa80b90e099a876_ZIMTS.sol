// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Zimmits
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJYYYYYJJJJJ?77!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!777????JJJJJ?    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJYYYYYJJJJ??77!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!777???7    //
//    JJJJJJJJJJJJJJJJJJJJJJJJYYYYYJJJ??77!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!777    //
//    JJJJJJJJJJJJJJJJJJJJJJJJYYYYYJ?777!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    JJJJJJJJJJJJJJJJJJJJJJJJYYYYJ77!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    JJJJJJJJJJJJJJJJJJJJJJJJYYYJ77!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJYJ?!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    JJJJJJJJJJJJJJJJJJJJJJJJ?JJ7!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    JJJJJJJJJJJJJJJJJJJJJJJ?7??!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    JJJJJJJJJJJJJJJJJJJJJ?7!!7?!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!7!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    JJJJJJJJJJJJJJJJJJJ?7!!!!7?!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!77777??77777777777777777777!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    JJJJJJJJJJJJJJJJJ??!!!!!!7?!!!!!!!!!!!!!!!!!!!!!!!!!!!!7777!!777777???????JJJ?????777777777777777!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    JJJJJJJJJJJJJJJJ?7!!!!!!!7?!!!!!!!!!!!!!!!!!!!!!!!!777777777777???JJJJJJJJJJJJJJJJ??77777?????77777!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    JJJJJJJJJJJJJJ??7!!!!!!!!7J7!!!!!!!!!!!!!!!!!!!!7777777777777???JJJJJJJJYY555PPPPGGPPPPPPPGGPPP555YJJ??77!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    JJJJJJJJJJJJ??7!!!!!!!!!!7J?!!!!!!!!!!!!!!!!!777777777777777???JYY5PPGGGGGPPPPPP555555555555555PPPPPPPPPP55YJ?77!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    JJJJJJJJJJJ?7!!!!!!!!!!!!7J?!!!!!!!!!!!!!!!!!77777777777777J5PGGGGPPP55555555555555555555555555555555555555PPPPP5Y?7!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    JJJJJJJJJ?77!!!!!!!!!!!!!7JJ7!!!!!!!!!!!!!!!!!777777777JYPGGGPP5YYJJ???777??JJYY555555555555555555555555555555555PPG?!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    JJJJJJJJ?7!!!!!!!!!!!!!!!7JJJ7!!!!!!!!!!!!!!!!77777?YPGGGP5YJ?7!!~~~~~~~~~~~~~~!?Y555555555555555555555555555555555BJ!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    JJJJJJ?7!!!!!!!!!!!!!!!!!!?JJ?!!!!!!!!!!!!!!!!77?YPGGP5YJ?!!~~~~~~~~~~~~~~~~~~~~~J55YYY5P55555555555555555555555555BJ!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    JJJJJ?7!!!!!!!!!!!!!!!!!!!?JYJ7!!!!!!!!!!!!!!7JPBGP5YJ7!~~~~~~~~~~~~~~~~!!~~~~~~!J?7?YPPPP5555555555555555555555555BY!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    JJJ??7!!!!!!!!!!!!!!!!!!!7?JYJ77!!!!!!!!!!!7YGBP5YJ7!~~~~~~~~~~!~~~~!!!~~~~~~~!!!?JY5YJJJ5P555555555555555555555555G5!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    JJ?7!!!!!!!!!!!!!!!!!!!!!7?JYJ?7!!!!!!!!!7YBGP5Y?!~~~~~~~~~~~~~~~~!!!~~~~~~~7JJY55YJJJJJJJYGP5555555555555555555555G5!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    J?7!!!!!!!!!!!!!!!!!!!!!7?JJJJ?7!!!!!!!7YBBP5J7~~~~~~~~~!7!~~~~~!!~~~~~~~~!?JJ7~~?JJJJJJJJJYGP555555555555555555555G5!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    ?7!!!!!!!!!!!!!!!!!!!!!!7JJJJ??7!!!!!!?GBP5J7~~~~~~~~~!?7!7~~~~~~~~~~~~~7??7~.   .!JJJJJJJJJYGP55555555555555555555GY!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!!7?JJ????77!!!75#G5J7~~~~~~~~!7?7!~7!!~!~~~~~~~~!?7~:       .~JJJJJJJJJYGP5555555555555555555GJ!!!77??JJYY5Y!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!77JJ??7777777?P#PY7~~~~~~~~!7?7~~~77777!~~!~~!77~:       .^.  ~?JJJJJJJJYG5555555555555555555PYY55YYJJ??Y55P?!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!77?J??7777777?GB5J!~~~~~~~!?7!~~~~!7?77!!!!!77~:      .^!JPGJ   ^?JJJJJJJJ5G5555555555555555Y?7777777?JJJJP5PJ!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!777J?77777777?GBY7~~~~~~~~!?!7?7!~~!7777!!77!:.   .:~7Y5GGBBBB~   ~JJJJJJJJJGP55555555555555Y777???77!!~~~!P55Y!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!777?J?777777??G#PYJ7!~~~~~~?~!Y5555!7!7!77!^.  .:~?YPPPPPPGGGBBP.   ~JJJJJJYYP5Y5555555555555J!!!~~~~~~~~~~~PP55!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!7777??7777?5YJYPGGGGPYJ!~~~~!~?555P57777!^.    ~5GGBG5G#&&B5PGGB#J   .?YYYYJ?7!~75555555555555?~~~~~~~~~~~~~~5P5P7!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!777??777?P!. .^7JY5GGPY?~~~~~J555PJ7?!.       [email protected]@@@G5GGBBB!^!7??7!~~~~~!J5555555555555?~~~~~~~~~~~~~~JG5P7!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!777??777P!     .~?JJYGG5?~~~~?55557!!!         [email protected]@@&PPGGPY?!!~~~~~~~~7JY55555555555555?~~~~~~~~~~~~~~?B5P?!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!777?777?G.       :7JJYP#GJ!~~7555Y~~~7^         .JBGG5Y#&#B5?7!~~~~~~~~!7?JYYY555555555555555?~~~~~~~~~~~~~~!G5PJ!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!7?777?G.        :JPB##&GY!~~J555?~~~?^         .JBG5YJ?!~~~~~~~!!7?YYYYJ?7!!7Y5555555555555?~~~~~~~~~~~~~~~J5P5!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!777?777?G:     .~?5G#####&BY!~!Y55Y~~~~?~    .:^~!7?!~~~~~~~!7?JYYYJ?7!!~~~~~~75GGBBGP55555557~~~~~~~~~~~~~~~755P!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!77?7777P~    7PGGGGGB####&BJ~~7Y5Y~~~~~?7^~!!!!!~~~~~!!7?JYYJJ7!!~~~!!!!!!~75GB##BBG5P5555557~~~~~~~~~~~~~~~!Y5P7!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!77??777J5.   ^5GGGGGGBB###&G?~~7YY~~~!777!!~!!!!77?JYYYJ?77!!!!!!!!!!!!!~^!YGGGG#Y?YYY7Y555Y!~~~~~~~~~~~~~~~!Y5P?!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!77?7777P!    :5GGGP5G#&####Y~~!?Y~~~~~~~!!!7?JYYJJ?7!777!!!!!!!!!!~~~~!!~^^^!7~~~7?7J!7555Y~~~~~~~~~~~~~~~~?5PP7!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!77??777?P^    :YGG55&@@&##&P77?YGJ!7?JJ~~~!5Y7!!~~!!!!~!!!!!~~~~~!~~~~!7?Y5GGPJ~!JGP7^?P55J~~~~~~~~~~!!!777YPGJ!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!7!77??7!7J5:    .YGP5P&@@&PYJJ?YB#BP555Y7~~!5Y!~~!7!~~~!~!?7!!!!!~!~~~7?P#&@@@@&5Y5PPP?JG55J~~~~~~~~!77?JY5PPPY!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!7777??77!7JY:    .JGP5P&@&PYPY?!7JJ7!!!!!~~~Y57~~7!!7!~!7P##BGPJ?!~~!?JB&BBPG&@#P555PPP?555?~~~~~!7JY5PP5YJ?7!!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!77777???7!7?Y^    .?GG5P&@@&#P7~~~~~~~~~~~~~7PY~!7!7!~~~!#@@@@@&GY!!7J#@PJBP5#G555555YGY555?!7JY555YJ?7!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!77!!!7???77!7Y7.    [email protected]@@@[email protected]@@@@@&[email protected]@&&&&&P7Y55P55??GPPPG5YJ?7!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!77??77!7JJ!.   [email protected]@#7~~~~~~~~~~~~~~~YPJ~!!!!~~~~~!YB&&@@BJ7!7PB###BPY7J5PP555Y&#PBY!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!77???7!!7JJ7^. ~PPB&#[email protected]&BY?7!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!77??77777?JJ?7Y[email protected]@G7J7!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!77??77777777??[email protected]&J7J!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!777??777777777775Y~~7?~~~!!~!~~~~~~!Y!~~~~~~~~~~~~~~~~~!?GGJ7!7?!!!!?5PPP55#@B7J?!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!77??77777777777YY~~??~~~!!~!~~~~~~~~~~~~~~~~~~~~~~~~~~!!77!!777!77?5PP55P&@PJ?!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!777?77777[email protected]@BGPY!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!7??7777777777YY~~J?~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!7?JYJ7!!!777GPPP5#@@###G7!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!7?7?77777777Y5!~!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!PP?7!!!!!?JJJG#[email protected]@&BBBP!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!![email protected]@#555#@@###B5!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!![email protected]&[email protected]@@#BBBJ!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!7!7777777?YGYJ???77!!~~~~~!~~~~~~~~~~~~~~~!7!!!~~~~~~~~?&@BP#@@@###B?!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!![email protected]&#@@@&GGGP7!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!![email protected]@@@@@B?7777!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!![email protected]@&&##G7777777!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!777??????????JJJJJJJJ?77!!!!77?77!~~~~~~~~J##BPPPBG7777777!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!77777777777????JJJJJJJYYYJJ?7777?J?77!~~7P??G#&@@G7777777!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!77777?????????J??JJJYYYYY5P??J?77!Y#@@@&&P77!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!![email protected]@#BGPGP!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!![email protected]#Y!?PGBG!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!7!777777777777777777777JJ?JPY?PPY7?G##BG!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!77777!!!777777777?JP&@GY777JGP5G#B7!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!777!!!!!7777777775YYP?7???5YB#BB7!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!7?7!!77!!!!    //
//    77!777!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!777777P5JY??J?YGPGB##?!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!?Y777?!!!!!    //
//    777777!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!7777#&Y?JJYJ55JYG##J!!!!!!!!!!!!!!!!!!!!!!!!!!!!7J?77?777?????    //
//    777777777!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!JPYJJJ?JYJJ?JYB#P!!!!!!!!!!!!!!!!!!!!!!!!!!!!!7777777777?77    //
//    7777777777!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!7PY??????PYJ??J5#B7!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!777??7!7?7!    //
//    7777777777!!7!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!J&BJ??????YJ7??YB#J!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!77?    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ZIMTS is ERC721Creator {
    constructor() ERC721Creator("Zimmits", "ZIMTS") {}
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