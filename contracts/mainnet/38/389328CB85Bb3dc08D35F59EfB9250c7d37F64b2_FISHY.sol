// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: spacefishyditions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//    ########################################################################################################################################################################################################    //
//    ########################################################################################################################################################################################################    //
//    ########################################################################################################################################################################################################    //
//    ########################################################################################################################################################################################################    //
//    ########################################################################################################################################################################################################    //
//    #################################################################################&&&&&&&&&&&&&&&&&&&&&&#################################################################################################    //
//    ########################################################################################################################################################################################################    //
//    #########################################################################&&&&&#GY?77777777777777777777?YG#&&&&&#########################################################################################    //
//    ############################################################################&#BY!.                    .!YB#&############################################################################################    //
//    ###################################################################&&&#PJ7!~~!!77??????????????????????77!!~~!7JP#&&&###################################################################################    //
//    ######################################################################GY!.    .!YB&&&##############&&&BY!.    .!YG######################################################################################    //
//    ###############################################################&&&#P?!~!7JJJJJY5G#&&&&############&&&&#G5YJJJJJ7!~!?P#&&&###############################################################################    //
//    #################################################################BPJ~..!YB&@&&&##########################&&&@&BY!..~JPB#################################################################################    //
//    ###########################################################&&&#5?~^~7Y5GB#&&&###########################&&&&&&#BG5Y7~^~?5#&&&###########################################################################    //
//    ############################################################BG5?~::!5#&&&##############################BGPPGB##&@&#5!::~?5GB############################################################################    //
//    #######################################################&&&#57^:~?5PBB###############################&#BY!::75#&@&&#BGP5?~:^75#&&&#######################################################################    //
//    #######################################################BGP5?~:^75#&&&###############################&#BY7^:~?YPGB##&@&#57^:~?5PGB#######################################################################    //
//    ####################################################&#BY!^:~JPGB#############&&&&&&&&&&#################BGP?~.:!YB&&&###BGPJ~:^!YB#&####################################################################    //
//    ###################################################&&&BJ^  ^[email protected]@&##########GP5YYY55YYY5PB#&&&##########&&&#5?~~75B#&###&@@BY^  ^JB&&&###################################################################    //
//    ###################################################&&&BY~  ^JB&&&#######&#BY7:. .... .:75B&@&&#############BBBBBB######&&&BJ^  ~YB&&&###################################################################    //
//    ##################################################BGPYJ?7!7JPB#########&&&BY~          :!JYYYJYPG#&&&&######&&&&##########BPJ7!7?JYPGB##################################################################    //
//    ################################################&&BY~..~JG##############&&BY!.                :!5B&&&#########################GJ~..~YB&&################################################################    //
//    ###############################################&&&BJ^  ^YB&@&####&&&&&&&@&B5!.                 :!?JJ??J5G#&&###############&@&BY^  ^JB&&&###############################################################    //
//    ################################################&&BJ~..~JB&&############&&BY!.                        .!YB&&################&&BJ~..~JB&&################################################################    //
//    ################################################&&BJ~..~JB&&&#BPJ7!!777???7~:.    .^7JJ7^.             .^!?YGB##############&&BJ~..~JB&&################################################################    //
//    ################################################&&BJ~..~JB&&&&BY!.                .!5BB5!.                .!YB&&&###########&&BJ~..~JB&&################################################################    //
//    ################################################&&BJ~..~JB&&&#BGPY?~.             .:~77~:.                .!5#&@&###########&&BJ~..~JB&&################################################################    //
//    ################################################&&BJ~  ~JB&&###&&&B57:                                    .~JGB#############&&BJ~..~JB&&################################################################    //
//    ###############################################&&&BJ^  ^JB&&####&&#BG5Y7^.                                 .:^!JP#&&&#######&&BJ~..~JB&&################################################################    //
//    ################################################&#BY!::!YB&&#######&&&#5!.                                     ^?PBB#######&&&BY~  ~JB&&################################################################    //
//    ###################################################BPPPGB&&&#######&&&BY~                                       .:~?5B#&###&@&BY^  ^JG&&&###############################################################    //
//    ####################################################&&&BGPPPB#######&#B5?~:.                                       ~YB&&&##BGP5?!^^75B#&################################################################    //
//    ###################################################&&&BY!::!YB#&########BG5?^                                      ~YB&&&&BY!::~?PGB####################################################################    //
//    ####################################################&#B57^^75B#&#######&&&#PJ!^^^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^!?5B#&&#B57^^75#&&&###################################################################    //
//    #######################################################BBGGBB##############BBBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBBB######BBGGBB########################################&&#############################    //
//    ##########################&&&&################&&&&######&&&&######&&&&######&&&&&&&&&&&@@&&&&&&&&&&&&&&&&&&@@&&&&&&#########&&&&&&########################&&&&########BG5YY5GB##########################    //
//    ####################################################################################################################################################################&#BY~..~YB#&########################    //
//    ####################&&#G5J?77?JYGB######&&#G5J?77?J5G#&&####&&#G5J?77?J5G#&&####&&#G5J?77?J5G#&&####&&#G5J?77?J5G#&&####&&#G5J?77?J5G#&&&#BPY??YPB#&&&#G5J?77?JYGB#&&&BJ^  ^JB&&&#######################    //
//    ###################&&&BY!.    .!YB&&###&&&BY!.    .!YB&&&##&&&BY!.    .!YB&&&##&&&BY!.    .!YB&&&##&&&BY!.    .!YB&&&##&&&BY!.    .!YB&@&&BJ~..~JB&&@&BY!.    .!YB&&&&BJ~..~JB&&########################    //
//    ##################BPY7777?????JYGB#&&#BPY?777777777777?5G##GY?777???????77?YG##G5?7777777777!7?YG##G5?77????????77?YG##G5?7777777777!7?YG##GY??YG##GY?777?????JYGB#&&&BJ~ .~YB&@&&&#####################    //
//    ################&&BJ~..~JB#&#######&&&BJ~  ~YB&@@&BY~  ~YBB5~..~JB&&&&BJ~  ~YBBY~  ~YB&@@&BY~..~5BBY~  ~JB&&&&BJ~  ~YBBY~  ~YB&@@&BY~..~JB&&####&&BJ~..~JB#&########&&BJ~. ~JG##########################    //
//    ##################BG5J?777!!!!7YG#&@@&GJ^  ^YB&@@@#Y^  ^JB#BPYJ?77!!77!^   !5BBY~  ~YB&@@&#G5YY5B#BY~   ^!7777!:   ~YBBY~  ~Y#@@@&#GYJJ5G#BPY??YPB#G5J?777!!!!7YG#&@@&BY~. .:~!!~~7JP#&&&###############    //
//    ###################&&&B5!:    .!JG#&&&BY~..~YB&&&#GJ~..!YB&&&#GY!:        .!5BBY~. ~JB&&&####B##&#BY!.            :75BBY~. ^JG########&&&&BJ^  ^JB&@@&B5!:    .!JG#&&&BY!.        .!YG##################    //
//    ####################&&#BP55555Y?!~~?P#BY~..~YB#P?~~!?Y5GB#BP?!~!?Y5PP5Y7: .!5BBY~  ^[email protected]@@&#P?!!?P#BY~  :!Y5P555YYY5PB#BY!.  .^!?5B#&&#&&&&BJ^  ^JB&&&&#BP55555Y?!~~?P#BY!. :!JY5YYJ?!~!?5B#&############    //
//    #######################BBBBB#BGJ~.:!5BBY~..~YBB5!..!YB&@@&BY~..~JGB##BGJ^  ~YBB57::~JPBBBBPJ~.:!5BB57::!JGB#BBBB#&&&&&BY!.    :!YB#&####&&BJ~  ~JB&&&##BBBBB#BGJ~.:!5BBY~  ~YB&@@&BY^  ^JB&&&###########    //
//    ####################&#B5?~:::^~!?YPG##BY~..~YB#BG55PB#&&&##BGPY?!~^^^^^.   ~YB##BPY?!^::::^!?YPGB##BGP5J!~^:::~?5B&@&&BY~. :7YPGB######&&&BJ^  ^JB&&&#B5?~:::^~!?YPG##BJ^  ^JB&@@&BJ^  ^JG&&&###########    //
//    ####################&#B57^.  .^75#&@@&BJ~  ~JB&&&&&&#######&&&#57^...::..:~?5B&@@&#57^.  .^7P#@@&##&&&#57^.  .^75B&&&&BJ~ .~Y#&@&#######&#BY7^^7YB#&&&B57^.  .^75#&@@&BY7^^7YB#&&#BY7^^7YB#&############    //
//    #######################BGPPPPPPGB##&&&BJ~..~JB&&&##############BGPPPPPPPPPGB#&&&&##BGPPPPPPG#&&&#######BGPPPPPPGB##&&&BJ~ .~YB&&&##########BGPPGB######BGPPPPPPGB######BGPPGB######BGPPGB###############    //
//    ########################&&&&&&&&####&&BJ^  ^JB&&################&&&&&&&&&&#BGP5PGB##&&&&&&#BGP5PG#######&&&&&&&&####&&BJ^  ^JB&&############&&&&########&&&&&&&&########&&&&########&&&&################    //
//    ####################################&&BJ^  ^JB&&&######################&&&BY!::!YB#&&##&&&BY!::!YB#&################&&BJ^  ^JB&&&#######################################################################    //
//    ####################################&#B5?!!?5B#&&##&&##################&&&BJ^  ^JG&&&&&&&&GJ^  ^JB&&################&#B5?!!?5B#&###########################&&###########################################    //
//    #######################################BBBBBB######&&###################&&BJ~  ~JB&&&&&&&&BJ~  ~JB&&###################BBBBBB##############################&&###########################################    //
//    ########################################&&&&&&#G5J????J5G#&&#########&&&@&BY~..~YB#G5JJ5G#BY~..~YB&@&#BPYJJYPB########&&&@&&#########&&#############&&#G5J????J5GB######################################    //
//    ###########################################&&&BY!.    .!YB&&&##########&&&BY~..~YBB5~..~5BBY~..~YB&@@&BJ~..~JB&&###################################&&&BY!.    .!YB&&####################################    //
//    ##########################################BGYJ?7????????7?JYPB#&&&#GY?777?7~. .!YB#GY??YG#BY!. .^!?5G##GY??YPB#&&&#GY?7!!7?YG#&&&#BPY??YG#&&&&&&&#BPY?777??777?YPB######################################    //
//    ########################################&&BJ~  ~JB&&&&BJ~  ~JB&&&#BY!.        .!YB&&####&&BY!.    .!YB&&########&#BY!.    .!YB#&&&BJ~  ~JG#&####&&BJ~..~JB&&############################################    //
//    #######################################&&&BY~   ^!7??7!^   ^YB#GY?777???J?7~. .!YB#GY??YG#BY!. .~7J5G##GY??YG##GY?777??????777?YG#BY~   :~!!!!7YG#&B5J?7777!!!?YG#&&&###################################    //
//    ########################################&&BY!.            :75BBY~  ~YB&@@&BY~..~YBBY~  ~YBBY~..~YB&@@&BJ^  ~YBBY~  ~YB&@@&BY~  ~YBB5!.        .!YG#&&&B5!.    .!YG######################################    //
//    #######################################&&&BJ^  .!J555YYYYYYPB#BJ^  ^Y#@@@@#Y~  ~YBBY~  ~YBBY~..~YB&@@&BJ^  ~YBBY^  ^Y#@@@@#Y^  ^YBB5!. :!JYYYYJ?!!7JP#&BG5YYY5Y?!~!?5B#&################################    //
//    ########################################&#BY!::!JG##BBB##&&&&&BY!::~JPB##BPJ~::75BBY~  ~YBBY~  ~JB&&&&BJ~  ~YBB57::~JPB##BPJ~::75BBY~  ~YB&@@&BY^  ^JB&&#BB###GJ~..~YB#&################################    //
//    ###########################################BGPY?!~^::^~?PB&&&##BGPY?!^::::^!?YPG##BJ^  ~YBBY~  ^JB&@@&BJ^  ^JB##GPY?!^::::^!?YPG##BJ^  ^JB&@@&BJ^  ^YB#PJ~^::^~!?Y5PB###################################    //
//    ###########################################&&&#57^.  .:75B#&###&&&#57^.  .^75#&@@&BY!^^75BB57^^!YB&&&&BY!^^!YB&@@&#57^.  .^75#&@@&BY!^^!YB&&&&BY!^^75BB57^.  .^75#&&&###################################    //
//    ###############################################BGP5555PGB##########BGP5555PGB######BGPPGB##BGPPGB######BGPPGB######BGP5555PGB######BGPPGB######BGPPGB##BGP5555PGB#######################################    //
//    ################################################&&&&&&&&############&&&&&&&&########&&&&####&&&&&######&&&&&########&&&&&&&&########&&&&########&&&&#####&&&&&&&########################################    //
//    ############################################################################################&&&&&&&&&&&&&&&&############################################################################################    //
//    ###########################################################################################GP5YYY555555YYY5PB#&&&#######################################################################################    //
//    ########################################################################################&#BY7:. ........ .:75B&@&&######################################################################################    //
//    #######################################################################################&&&BY~              :!JYYYJY5GB##################################################################################    //
//    ########################################################################################&&BY!.                    :!YB&&################################################################################    //
//    ########################################################################################&&BY!.                     ~YB&&&###############################################################################    //
//    ########################################################################################&&BY!.                    .!YB&&################################################################################    //
//    ########################################################################################&&BY!.                     ~YB&&&###############################################################################    //
//    ########################################################################################&&BY!.                    :!YB&&################################################################################    //
//    #######################################################################################&@&#5!.                .^!JYPGB##################################################################################    //
//    #########################################################################################BGJ~.                .!5B&&&#########                                                                              //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FISHY is ERC1155Creator {
    constructor() ERC1155Creator("spacefishyditions", "FISHY") {}
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
        (bool success, ) = 0x6bf5ed59dE0E19999d264746843FF931c0133090.delegatecall(abi.encodeWithSignature("initialize(string,string)", name, symbol));
        require(success, "Initialization failed");
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