// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Provenance
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    //
//    Honestly guys, I've had enough of this crap. Where’s the transparency from the team I mean the floor is dropping and not a single word. Just rug me already. I can’t stand losing my money any longer. If this persists I will take legal action. Id like to inform you that my dad is a lawyer, and a good one at that. Top 10 in the country. You don’t want trouble devs. The SEC is already  taking a peek at this project. I can stop this as long as devs do something    //
//    --------------                                                                                                                                                                                                                                                                                                                                                                                                                                                                  //
//    Reacting to messages with a clown (🤡), a skull (💀), or a nerd face (🤓) isn't funny. It's not cool, it's not interesting, it's annoying.                                                                                                                                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    //
//    These 3 emojis in particular aren't funny, they're RUDE. We as staff work hard to keep this place safe, and to have you all constantly react to our messages with mean emojis makes me FURIOUS.                                                                                                                                                                                                                                                                                 //
//    STOP reacting to our messages with rude emojis. They do NOTHING but make you look really, really stupid.                                                                                                                                                                                                                                                                                                                                                                        //
//    It shows you have no rebuttals to our arguments, so you have to use juvenile tactics paramount to terrorism in order to stop us from being able to speak our truth.                                                                                                                                                                                                                                                                                                             //
//    FROM NOW ON, IF YOU REACT WITH ANY MEAN EMOJIS, I AM WRITING YOUR NAME DOWN.                                                                                                                                                                                                                                                                                                                                                                                                    //
//    IF YOU ARE A SERIAL REACTOR, YOUR USERNAME IS GOING TO A GOOGLE DOC. AT THE END OF THE MONTH, I WILL TAKE THIS DOC TO THE APPROPIATE AUTHORITIES FOR THEM TO INVESTIGATE AND ARREST YOU.                                                                                                                                                                                                                                                                                        //
//    --------------                                                                                                                                                                                                                                                                                                                                                                                                                                                                  //
//    This has been quite hectic for the past 24 hours, trying to run a project and blow up way out of proportion. None of us has ever had any web3 experience in terms of running a project and therefore it's quite hard to get used to new circumstances.                                                                                                                                                                                                                          //
//    --------------                                                                                                                                                                                                                                                                                                                                                                                                                                                                  //
//    Can I just say we are glad to everybody who didn’t meant because the price was too high but now we have to listen to you cry when all we want to do is just say goodbye but yeah you are sticking around like a bad smell and we don’t know why                                                                                                                                                                                                                                 //
//    --------------                                                                                                                                                                                                                                                                                                                                                                                                                                                                  //
//    hi. i dont wanna sound like a fudder its just i want to ask how the floor is so cheap compared where it was. i didnt really follow the project but i was following the minting process and i remember how hyped it was. now that the floor is not that high I'm thinking about buying in. Ofc I will do my own research but I would like to hear some feedback how things are and how the floor turned this low.                                                                //
//    --------------                                                                                                                                                                                                                                                                                                                                                                                                                                                                  //
//    You belittle my success and achievement over the past two years, scratch that my entire life, and then tell me to stop talking about it with you or anyone else???  My OWN family can’t handle who I am, let alone the degens on social media. -Anon                                                                                                                                                                                                                            //
//    --------------                                                                                                                                                                                                                                                                                                                                                                                                                                                                  //
//    Thanks to the team for making sure the ones with BOTS steal my transaction!! How come I got the message “Transaction complete”, party confetti, view on OS and seconds later it said transaction failed?! Can you please explain that to me??? I was so excited, ready to view it and nothing! What a disappointment!! I posted the screenshots on my Twitter                                                                                                                   //
//    --------------                                                                                                                                                                                                                                                                                                                                                                                                                                                                  //
//    I am not yet sure of how my account was compromised. I have two prevailing theories, both are, to my mind, highly unlikely. One is an insider at Twitter being involved; this was my immediate reaction, and while still possible, I don’t consider it an especially high likelihood. The other is a phishing attack on me where I gave access to an attacker to the extent that they could bypass my Google Authenticator 2FA. -Zeneca                                         //
//    --------------                                                                                                                                                                                                                                                                                                                                                                                                                                                                  //
//    I’ve decided to make a pivotal investment towards my future. I’m ready to be the change throughout multimedia, entertainment, and Web3. BUT I promise it’s not for the profit. This is about securing a feeling of ownership, that what we build together will also define my legacy. -Anon                                                                                                                                                                                     //
//    --------------                                                                                                                                                                                                                                                                                                                                                                                                                                                                  //
//    Hey mate, i just searched your ERC20 address on etherscan, I saw your trading history and was wondering if you are trying to be the first on-chain clown or something                                                                                                                                                                                                                                                                                                           //
//    --------------                                                                                                                                                                                                                                                                                                                                                                                                                                                                  //
//    This Moonbirds CC0 announcement has single-handedly ruined my life. I had just negotiated a deal for $1 million, and now the deal is canceled and my wife has left me. I expect compensation                                                                                                                                                                                                                                                                                    //
//    --------------                                                                                                                                                                                                                                                                                                                                                                                                                                                                  //
//    If everyone had to package up and ship 📦 every Doodle or Cryptodickbutt they sold, then NFTs would never last. The incredible ease & blockchain verification makes the MP work                                                                                                                                                                                                                                                                                                 //
//    --------------                                                                                                                                                                                                                                                                                                                                                                                                                                                                  //
//    Actually not even joking when I say I probably have a similar picture in a similarly dumb shirt with a similar stature at that point in my life. I, however, grew up to be a desk jockey just like you'd expect that kid to                                                                                                                                                                                                                                                     //
//    --------------                                                                                                                                                                                                                                                                                                                                                                                                                                                                  //
//    Honestly guys, I've had enough of this crap. Where’s the transparency from the team I mean the floor is dropping and not a single word. Just rug me already. I can’t stand losing my money any longer. If this persists I will take legal action. Id like to inform you that my dad is a lawyer, and a good one at that. Top 10 in the country. You don’t want trouble devs. The SEC is already  taking a peek at this project. I can stop this as long as devs do something    //
//    --------------                                                                                                                                                                                                                                                                                                                                                                                                                                                                  //
//    If you are rocking a PFP under $100k plz don’t @ me or share your opinion on my wall.  I don’t care what you have to say. Reality is you need to Work harder, move out of your moms basement, stack eth/sol, buy a few real PFP then share your opinion.                                                                                                                                                                                                                        //
//    --------------                                                                                                                                                                                                                                                                                                                                                                                                                                                                  //
//    gm you stupid fucks pls quit crypto for good                                                                                                                                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Final is ERC721Creator {
    constructor() ERC721Creator("Provenance", "Final") {}
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