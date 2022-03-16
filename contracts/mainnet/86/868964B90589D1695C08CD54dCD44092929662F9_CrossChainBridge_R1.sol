// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./libraries/ProofParser.sol";
import "./interfaces/ICrossChainBridge.sol";
import "./SimpleTokenProxy.sol";
import "./InternetBondProxy.sol";

contract BridgeRouter {

    function peggedTokenAddress(address bridge, address fromToken) public pure returns (address) {
        return SimpleTokenProxyUtils.simpleTokenProxyAddress(bridge, bytes32(bytes20(fromToken)));
    }

    function peggedBondAddress(address bridge, address fromToken) public pure returns (address) {
        return InternetBondProxyUtils.internetBondProxyAddress(bridge, bytes32(bytes20(fromToken)));
    }

    function factoryPeggedToken(address fromToken, address toToken, ICrossChainBridge.Metadata memory metaData, address bridge) public returns (IERC20Mintable) {
        /* we must use delegate call because we need to deploy new contract from bridge contract to have valid address */
        address targetToken = SimpleTokenProxyUtils.deploySimpleTokenProxy(bridge, bytes32(bytes20(fromToken)), metaData);
        require(targetToken == toToken, "bad chain");
        /* to token is our new pegged token */
        return IERC20Mintable(toToken);
    }

    function factoryPeggedBond(address fromToken, address toToken, ICrossChainBridge.Metadata memory metaData, address bridge, address feed) public returns (IERC20Mintable) {
        /* we must use delegate call because we need to deploy new contract from bridge contract to have valid address */
        address targetToken = InternetBondProxyUtils.deployInternetBondProxy(bridge, bytes32(bytes20(fromToken)), metaData, feed);
        require(targetToken == toToken, "bad chain");
        /* to token is our new pegged token */
        return IERC20Mintable(toToken);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "./interfaces/IERC20.sol";
import "./interfaces/IInternetBondRatioFeed.sol";
import "./SimpleToken.sol";
import "./libraries/Utils.sol";

contract InternetBond is SimpleToken, IERC20InternetBond {

    IInternetBondRatioFeed public ratioFeed;
    bool internal _rebasing;

    function ratio() public view override returns (uint256) {
        return ratioFeed.getRatioFor(_originAddress);
    }

    function isRebasing() public view override returns (bool) {
        return _rebasing;
    }

    function totalSupply() public view override returns (uint256) {
        return _sharesToBonds(super.totalSupply());
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _sharesToBonds(super.balanceOf(account));
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 shares = _bondsToShares(amount);
        _transfer(_msgSender(), recipient, shares, false);
        emit Transfer(_msgSender(), recipient, _sharesToBonds(shares));
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _sharesToBonds(super.allowance(owner, spender));
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        uint256 shares = _bondsToShares(amount);
        _approve(_msgSender(), spender, shares, false);
        emit Approval(_msgSender(), spender, allowance(_msgSender(), spender));
        return true;
    }

    function increaseAllowance(address spender, uint256 amount) public override returns (bool) {
        uint256 shares = _bondsToShares(amount);
        _increaseAllowance(_msgSender(), spender, shares, false);
        emit Approval(_msgSender(), spender, allowance(_msgSender(), spender));
        return true;
    }

    function decreaseAllowance(address spender, uint256 amount) public override returns (bool) {
        uint256 shares = _bondsToShares(amount);
        _decreaseAllowance(_msgSender(), spender, shares, false);
        emit Approval(_msgSender(), spender, allowance(_msgSender(), spender));
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 shares = _bondsToShares(amount);
        _transfer(sender, recipient, shares, false);
        emit Transfer(sender, recipient, _sharesToBonds(shares));
        _decreaseAllowance(sender, _msgSender(), shares, false);
        emit Approval(sender, _msgSender(), allowance(sender, _msgSender()));
        return true;
    }

    // NB: mint accepts amount in shares
    function mint(address account, uint256 shares) public onlyOwner override {
        require(account != address(0));
        _totalSupply += shares;
        _balances[account] += shares;
        emit Transfer(address(0), account, _sharesToBonds(shares));
    }

    // NB: burn accepts amount in shares
    function burn(address account, uint256 shares) public onlyOwner override {
        require(account != address(0));
        _balances[account] -= shares;
        _totalSupply -= shares;
        emit Transfer(account, address(0), _sharesToBonds(shares));
    }

    function _sharesToBonds(uint256 amount) internal view returns (uint256) {
        if (_rebasing) {
            uint256 currentRatio = ratio();
            require(currentRatio > 0, "ratio not available");
            return Utils.multiplyAndDivideCeil(amount, 10 ** decimals(), currentRatio);
        } else {
            return amount;
        }
    }

    function _bondsToShares(uint256 amount) internal view returns (uint256) {
        if (_rebasing) {
            uint256 currentRatio = ratio();
            require(currentRatio > 0, "ratio not available");
            return Utils.multiplyAndDivideFloor(amount, currentRatio, 10 ** decimals());
        } else {
            return amount;
        }
    }

    function initAndObtainOwnership(bytes32 symbol, bytes32 name, uint256 originChain, address originAddress, address ratioFeedAddress, bool rebasing) external emptyOwner {
        super.initAndObtainOwnership(symbol, name, originChain, originAddress);
        require(ratioFeedAddress != address(0x0), "no ratio feed");
        ratioFeed = IInternetBondRatioFeed(ratioFeedAddress);
        _rebasing = rebasing;
    }
}

contract InternetBondFactory {
    address private _template;
    constructor() {
        _template = InternetBondFactoryUtils.deployInternetBondTemplate(this);
    }

    function getImplementation() public view returns (address) {
        return _template;
    }
}

library InternetBondFactoryUtils {

    bytes32 constant internal INTERNET_BOND_TEMPLATE_SALT = keccak256("InternetBondTemplateV1");

    bytes constant internal INTERNET_BOND_TEMPLATE_BYTECODE = hex"608060405234801561001057600080fd5b506110c0806100206000396000f3fe608060405234801561001057600080fd5b506004361061012c5760003560e01c806371ca337d116100ad5780639dc29fac116100715780639dc29fac1461026b578063a457c2d71461027e578063a9059cbb14610291578063dd62ed3e146102a4578063df1f29ee146102b757600080fd5b806371ca337d1461020a5780638da5cb5b146102125780638e29ebb51461023d57806394bfed881461025057806395d89b411461026357600080fd5b8063313ce567116100f4578063313ce567146101b057806339509351146101bf57806340c10f19146101d25780635dfba115146101e557806370a08231146101f757600080fd5b806306fdde0314610131578063095ea7b31461014f57806318160ddd1461017257806323b872dd14610188578063265535671461019b575b600080fd5b6101396102da565b6040516101469190610e14565b60405180910390f35b61016261015d366004610d2a565b6102ec565b6040519015158152602001610146565b61017a610348565b604051908152602001610146565b610162610196366004610cee565b61035b565b6101ae6101a9366004610d93565b610400565b005b60405160128152602001610146565b6101626101cd366004610d2a565b61049e565b6101ae6101e0366004610d2a565b6104b9565b600854600160a01b900460ff16610162565b61017a610205366004610ca0565b610560565b61017a610582565b600254610225906001600160a01b031681565b6040516001600160a01b039091168152602001610146565b600854610225906001600160a01b031681565b6101ae61025e366004610d54565b610606565b610139610657565b6101ae610279366004610d2a565b610664565b61016261028c366004610d2a565b6106f9565b61016261029f366004610d2a565b610714565b61017a6102b2366004610cbb565b610752565b600654600754604080519283526001600160a01b03909116602083015201610146565b60606102e760015461078a565b905090565b6000806102f883610860565b905061030733858360006108e6565b6001600160a01b0384163360008051602061106b83398151915261032b8288610752565b60405190815260200160405180910390a360019150505b92915050565b60006102e761035660055490565b61097c565b60008061036783610860565b905061037685858360006109f9565b836001600160a01b0316856001600160a01b031660008051602061104b8339815191526103a28461097c565b60405190815260200160405180910390a36103c08533836000610ab2565b336001600160a01b03861660008051602061106b8339815191526103e48884610752565b60405190815260200160405180910390a3506001949350505050565b6002546001600160a01b03161561041657600080fd5b61042286868686610606565b6001600160a01b03821661046d5760405162461bcd60e51b815260206004820152600d60248201526c1b9bc81c985d1a5bc819995959609a1b60448201526064015b60405180910390fd5b60088054911515600160a01b026001600160a81b03199092166001600160a01b039093169290921717905550505050565b6000806104aa83610860565b90506103073385836000610b5f565b6002546001600160a01b031633146104d057600080fd5b6001600160a01b0382166104e357600080fd5b80600560008282546104f59190610e69565b90915550506001600160a01b03821660009081526003602052604081208054839290610522908490610e69565b90915550506001600160a01b038216600060008051602061104b83398151915261054b8461097c565b60405190815260200160405180910390a35050565b6001600160a01b0381166000908152600360205260408120546103429061097c565b60085460075460405163a1f1d48d60e01b81526001600160a01b039182166004820152600092919091169063a1f1d48d9060240160206040518083038186803b1580156105ce57600080fd5b505afa1580156105e2573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906102e79190610dfb565b6002546001600160a01b03161561061c57600080fd5b60028054336001600160a01b031991821617909155600094909455600192909255600655600780549092166001600160a01b03909116179055565b60606102e760005461078a565b6002546001600160a01b0316331461067b57600080fd5b6001600160a01b03821661068e57600080fd5b6001600160a01b038216600090815260036020526040812080548392906106b6908490610fc7565b9250508190555080600560008282546106cf9190610fc7565b90915550600090506001600160a01b03831660008051602061104b83398151915261054b8461097c565b60008061070583610860565b90506103073385836000610ab2565b60008061072083610860565b905061072f33858360006109f9565b6001600160a01b0384163360008051602061104b83398151915261032b8461097c565b6001600160a01b0380831660009081526004602090815260408083209385168352929052908120546107839061097c565b9392505050565b6060816107a557505060408051600081526020810190915290565b600060105b60ff8116156107fc57836107be8284610e81565b60ff16602081106107d1576107d161101e565b1a60f81b6001600160f81b031916156107f1576107ee8183610e81565b91505b60011c607f166107aa565b50600061080a826001610e81565b60ff1667ffffffffffffffff81111561082557610825611034565b6040519080825280601f01601f19166020018201604052801561084f576020820181803683370190505b506020810194909452509192915050565b600854600090600160a01b900460ff16156108dd57600061087f610582565b9050600081116108c75760405162461bcd60e51b8152602060048201526013602482015272726174696f206e6f7420617661696c61626c6560681b6044820152606401610464565b61078383826108d86012600a610efd565b610bbc565b5090565b919050565b6001600160a01b0384166108f957600080fd5b6001600160a01b03831661090c57600080fd5b6001600160a01b038085166000908152600460209081526040808320938716835292905220829055801561097657826001600160a01b0316846001600160a01b031660008051602061106b8339815191528460405161096d91815260200190565b60405180910390a35b50505050565b600854600090600160a01b900460ff16156108dd57600061099b610582565b9050600081116109e35760405162461bcd60e51b8152602060048201526013602482015272726174696f206e6f7420617661696c61626c6560681b6044820152606401610464565b610783836109f36012600a610efd565b83610c01565b6001600160a01b038416610a0c57600080fd5b6001600160a01b038316610a1f57600080fd5b6001600160a01b03841660009081526003602052604081208054849290610a47908490610fc7565b90915550506001600160a01b03831660009081526003602052604081208054849290610a74908490610e69565b9091555050801561097657826001600160a01b0316846001600160a01b031660008051602061104b8339815191528460405161096d91815260200190565b6001600160a01b038416610ac557600080fd5b6001600160a01b038316610ad857600080fd5b6001600160a01b03808516600090815260046020908152604080832093871683529290529081208054849290610b0f908490610fc7565b90915550508015610976576001600160a01b0384811660008181526004602090815260408083209488168084529482529182902054915191825260008051602061106b833981519152910161096d565b6001600160a01b038416610b7257600080fd5b6001600160a01b038316610b8557600080fd5b6001600160a01b03808516600090815260046020908152604080832093871683529290529081208054849290610b0f908490610e69565b6000610bf9610bd4610bce8487610ea6565b85610c3e565b8385610be08289610fde565b610bea9190610fa8565b610bf49190610ea6565b610c71565b949350505050565b6000610bf9610c13610bce8487610ea6565b83610c1f600182610fc7565b86610c2a878a610fde565b610c349190610fa8565b610bea9190610e69565b600082610c4d57506000610342565b82820282848281610c6057610c60611008565b041461078357600019915050610342565b60008282018381101561078357600019915050610342565b80356001600160a01b03811681146108e157600080fd5b600060208284031215610cb257600080fd5b61078382610c89565b60008060408385031215610cce57600080fd5b610cd783610c89565b9150610ce560208401610c89565b90509250929050565b600080600060608486031215610d0357600080fd5b610d0c84610c89565b9250610d1a60208501610c89565b9150604084013590509250925092565b60008060408385031215610d3d57600080fd5b610d4683610c89565b946020939093013593505050565b60008060008060808587031215610d6a57600080fd5b843593506020850135925060408501359150610d8860608601610c89565b905092959194509250565b60008060008060008060c08789031215610dac57600080fd5b863595506020870135945060408701359350610dca60608801610c89565b9250610dd860808801610c89565b915060a08701358015158114610ded57600080fd5b809150509295509295509295565b600060208284031215610e0d57600080fd5b5051919050565b600060208083528351808285015260005b81811015610e4157858101830151858201604001528201610e25565b81811115610e53576000604083870101525b50601f01601f1916929092016040019392505050565b60008219821115610e7c57610e7c610ff2565b500190565b600060ff821660ff84168060ff03821115610e9e57610e9e610ff2565b019392505050565b600082610eb557610eb5611008565b500490565b600181815b80851115610ef5578160001904821115610edb57610edb610ff2565b80851615610ee857918102915b93841c9390800290610ebf565b509250929050565b600061078360ff841683600082610f1657506001610342565b81610f2357506000610342565b8160018114610f395760028114610f4357610f5f565b6001915050610342565b60ff841115610f5457610f54610ff2565b50506001821b610342565b5060208310610133831016604e8410600b8410161715610f82575081810a610342565b610f8c8383610eba565b8060001904821115610fa057610fa0610ff2565b029392505050565b6000816000190483118215151615610fc257610fc2610ff2565b500290565b600082821015610fd957610fd9610ff2565b500390565b600082610fed57610fed611008565b500690565b634e487b7160e01b600052601160045260246000fd5b634e487b7160e01b600052601260045260246000fd5b634e487b7160e01b600052603260045260246000fd5b634e487b7160e01b600052604160045260246000fdfeddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925a26469706673582212202704c0c85a7ffefb8570f6c29df5c6522044694561363ba9c4f84b992471d3fb64736f6c63430008060033";

    bytes32 constant internal INTERNET_BOND_TEMPLATE_HASH = keccak256(INTERNET_BOND_TEMPLATE_BYTECODE);

    function deployInternetBondTemplate(InternetBondFactory templateFactory) internal returns (address) {
        /* we can use any deterministic salt here, since we don't care about it */
        bytes32 salt = INTERNET_BOND_TEMPLATE_SALT;
        /* concat bytecode with constructor */
        bytes memory bytecode = INTERNET_BOND_TEMPLATE_BYTECODE;
        /* deploy contract and store result in result variable */
        address result;
        assembly {
            result := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(result != address(0x00), "deploy failed");
        /* check that generated contract address is correct */
        require(result == internetBondTemplateAddress(templateFactory), "address mismatched");
        return result;
    }

    function internetBondTemplateAddress(InternetBondFactory templateFactory) internal pure returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(uint8(0xff), address(templateFactory), INTERNET_BOND_TEMPLATE_SALT, INTERNET_BOND_TEMPLATE_HASH));
        return address(bytes20(hash << 96));
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "./interfaces/ICrossChainBridge.sol";

contract InternetBondProxy {

    bytes32 private constant BEACON_SLOT = bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1);

    fallback() external {
        address bridge;
        bytes32 slot = BEACON_SLOT;
        assembly {
            bridge := sload(slot)
        }
        address impl = ICrossChainBridge(bridge).getBondImplementation();
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {revert(0, returndatasize())}
            default {return (0, returndatasize())}
        }
    }

    function setBeacon(address newBeacon) external {
        address beacon;
        bytes32 slot = BEACON_SLOT;
        assembly {
            beacon := sload(slot)
        }
        require(beacon == address(0x00));
        assembly {
            sstore(slot, newBeacon)
        }
    }
}

library InternetBondProxyUtils {

    bytes constant internal INTERNET_BOND_PROXY_BYTECODE = hex"608060405234801561001057600080fd5b50610215806100206000396000f3fe608060405234801561001057600080fd5b506004361061002b5760003560e01c8063d42afb56146100fd575b60008061005960017fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d516101a2565b60001b9050805491506000826001600160a01b0316631626425c6040518163ffffffff1660e01b8152600401602060405180830381600087803b15801561009f57600080fd5b505af11580156100b3573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906100d79190610185565b90503660008037600080366000845af43d6000803e8080156100f8573d6000f35b3d6000fd5b61011061010b366004610161565b610112565b005b60008061014060017fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d516101a2565b8054925090506001600160a01b0382161561015a57600080fd5b9190915550565b60006020828403121561017357600080fd5b813561017e816101c7565b9392505050565b60006020828403121561019757600080fd5b815161017e816101c7565b6000828210156101c257634e487b7160e01b600052601160045260246000fd5b500390565b6001600160a01b03811681146101dc57600080fd5b5056fea2646970667358221220d283edebb1e56b63c1cf809c7a7219bbf056c367c289dabb51fdba5f71cdf44c64736f6c63430008060033";

    bytes32 constant internal INTERNET_BOND_PROXY_HASH = keccak256(INTERNET_BOND_PROXY_BYTECODE);

    bytes4 constant internal SET_META_DATA_SIG = bytes4(keccak256("initAndObtainOwnership(bytes32,bytes32,uint256,address,address,bool)"));
    bytes4 constant internal SET_BEACON_SIG = bytes4(keccak256("setBeacon(address)"));

    function deployInternetBondProxy(address bridge, bytes32 salt, ICrossChainBridge.Metadata memory metaData, address ratioFeed) internal returns (address) {
        /* lets concat bytecode with constructor parameters */
        bytes memory bytecode = INTERNET_BOND_PROXY_BYTECODE;
        /* deploy new contract and store contract address in result variable */
        address result;
        assembly {
            result := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(result != address(0x00), "deploy failed");
        /* setup impl */
        (bool success, bytes memory returnValue) = result.call(abi.encodePacked(SET_BEACON_SIG, abi.encode(bridge)));
        require(success, string(abi.encodePacked("setBeacon failed: ", returnValue)));
        /* setup meta data */
        bytes memory inputData = new bytes(0xc4);
        bool isRebasing = metaData.bondMetadata[1] == bytes1(0x01);
        bytes4 selector = SET_META_DATA_SIG;
        assembly {
            mstore(add(inputData, 0x20), selector)
            mstore(add(inputData, 0x24), mload(metaData))
            mstore(add(inputData, 0x44), mload(add(metaData, 0x20)))
            mstore(add(inputData, 0x64), mload(add(metaData, 0x40)))
            mstore(add(inputData, 0x84), mload(add(metaData, 0x60)))
            mstore(add(inputData, 0xa4), ratioFeed)
            mstore(add(inputData, 0xc4), isRebasing)
        }
        (success, returnValue) = result.call(inputData);
        require(success, string(abi.encodePacked("set metadata failed: ", returnValue)));
        /* return generated contract address */
        return result;
    }

    function internetBondProxyAddress(address deployer, bytes32 salt) internal pure returns (address) {
        bytes32 bytecodeHash = keccak256(INTERNET_BOND_PROXY_BYTECODE);
        bytes32 hash = keccak256(abi.encodePacked(uint8(0xff), address(deployer), salt, bytecodeHash));
        return address(bytes20(hash << 96));
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IInternetBondRatioFeed.sol";

contract InternetBondRatioFeed is OwnableUpgradeable, IInternetBondRatioFeed {

    event OperatorAdded(address operator);
    event OperatorRemoved(address operator);

    mapping(address => bool) _isOperator;
    mapping(address => uint256) private _ratios;

    function initialize(address operator) public initializer {
        __Ownable_init();
        _isOperator[operator] = true;
    }

    function updateRatioBatch(address[] calldata addresses, uint256[] calldata ratios) public override onlyOperator {
        require(addresses.length == ratios.length, "corrupted ratio data");
        for (uint256 i = 0; i < addresses.length; i++) {
            _ratios[addresses[i]] = ratios[i];
        }
    }

    function getRatioFor(address token) public view override returns (uint256) {
        return _ratios[token];
    }

    function addOperator(address operator) public onlyOwner {
        require(operator != address(0x0), "operator must be non-zero");
        require(!_isOperator[operator], "already operator");
        _isOperator[operator] = true;
        emit OperatorAdded(operator);
    }

    function removeOperator(address operator) public onlyOwner {
        require(_isOperator[operator], "not an operator");
        delete _isOperator[operator];
        emit OperatorRemoved(operator);
    }

    modifier onlyOperator() {
        require(msg.sender == owner() || _isOperator[msg.sender], "Operator: not allowed");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IERC20.sol";

contract SimpleToken is Context, IERC20, IERC20Mintable, IERC20Pegged {

    // pre-defined state
    bytes32 internal _symbol; // 0
    bytes32 internal _name; // 1
    address public owner; // 2

    // internal state
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal _totalSupply;
    uint256 internal _originChain;
    address internal _originAddress;

    function name() public view returns (string memory) {
        return bytes32ToString(_name);
    }

    function symbol() public view returns (string memory) {
        return bytes32ToString(_symbol);
    }

    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        if (_bytes32 == 0) {
            return new string(0);
        }
        uint8 cntNonZero = 0;
        for (uint8 i = 16; i > 0; i >>= 1) {
            if (_bytes32[cntNonZero + i] != 0) cntNonZero += i;
        }
        string memory result = new string(cntNonZero + 1);
        assembly {
            mstore(add(result, 0x20), _bytes32)
        }
        return result;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount, true);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount, true);
        return true;
    }

    function increaseAllowance(address spender, uint256 amount) public virtual returns (bool) {
        _increaseAllowance(_msgSender(), spender, amount, true);
        return true;
    }

    function decreaseAllowance(address spender, uint256 amount) public virtual returns (bool) {
        _decreaseAllowance(_msgSender(), spender, amount, true);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount, true);
        _decreaseAllowance(sender, _msgSender(), amount, true);
        return true;
    }

    function _increaseAllowance(address owner, address spender, uint256 amount, bool emitEvent) internal {
        require(owner != address(0));
        require(spender != address(0));
        _allowances[owner][spender] += amount;
        if (emitEvent) {
            emit Approval(owner, spender, _allowances[owner][spender]);
        }
    }

    function _decreaseAllowance(address owner, address spender, uint256 amount, bool emitEvent) internal {
        require(owner != address(0));
        require(spender != address(0));
        _allowances[owner][spender] -= amount;
        if (emitEvent) {
            emit Approval(owner, spender, _allowances[owner][spender]);
        }
    }

    function _approve(address owner, address spender, uint256 amount, bool emitEvent) internal {
        require(owner != address(0));
        require(spender != address(0));
        _allowances[owner][spender] = amount;
        if (emitEvent) {
            emit Approval(owner, spender, amount);
        }
    }

    function _transfer(address sender, address recipient, uint256 amount, bool emitEvent) internal {
        require(sender != address(0));
        require(recipient != address(0));
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        if (emitEvent) {
            emit Transfer(sender, recipient, amount);
        }
    }

    function mint(address account, uint256 amount) public onlyOwner virtual override {
        require(account != address(0));
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function burn(address account, uint256 amount) public onlyOwner virtual override {
        require(account != address(0));
        _balances[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    modifier emptyOwner() {
        require(owner == address(0x00));
        _;
    }

    function initAndObtainOwnership(bytes32 symbol, bytes32 name, uint256 originChain, address originAddress) public emptyOwner {
        owner = msg.sender;
        _symbol = symbol;
        _name = name;
        _originChain = originChain;
        _originAddress = originAddress;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function getOrigin() public view override returns (uint256, address) {
        return (_originChain, _originAddress);
    }
}

contract SimpleTokenFactory {
    address private _template;
    constructor() {
        _template = SimpleTokenFactoryUtils.deploySimpleTokenTemplate(this);
    }

    function getImplementation() public view returns (address) {
        return _template;
    }
}

library SimpleTokenFactoryUtils {

    bytes32 constant internal SIMPLE_TOKEN_TEMPLATE_SALT = keccak256("SimpleTokenTemplateV1");

    bytes constant internal SIMPLE_TOKEN_TEMPLATE_BYTECODE = hex"608060405234801561001057600080fd5b50610a7f806100206000396000f3fe608060405234801561001057600080fd5b50600436106101005760003560e01c80638da5cb5b11610097578063a457c2d711610066578063a457c2d714610224578063a9059cbb14610237578063dd62ed3e1461024a578063df1f29ee1461028357600080fd5b80638da5cb5b146101cb57806394bfed88146101f657806395d89b41146102095780639dc29fac1461021157600080fd5b8063313ce567116100d3578063313ce5671461016b578063395093511461017a57806340c10f191461018d57806370a08231146101a257600080fd5b806306fdde0314610105578063095ea7b31461012357806318160ddd1461014657806323b872dd14610158575b600080fd5b61010d6102a6565b60405161011a919061095e565b60405180910390f35b6101366101313660046108f5565b6102b8565b604051901515815260200161011a565b6005545b60405190815260200161011a565b6101366101663660046108b9565b6102d0565b6040516012815260200161011a565b6101366101883660046108f5565b6102f6565b6101a061019b3660046108f5565b610305565b005b61014a6101b0366004610864565b6001600160a01b031660009081526003602052604090205490565b6002546101de906001600160a01b031681565b6040516001600160a01b03909116815260200161011a565b6101a061020436600461091f565b6103b9565b61010d61040a565b6101a061021f3660046108f5565b610417565b6101366102323660046108f5565b6104c5565b6101366102453660046108f5565b6104d4565b61014a610258366004610886565b6001600160a01b03918216600090815260046020908152604080832093909416825291909152205490565b600654600754604080519283526001600160a01b0390911660208301520161011a565b60606102b36001546104e3565b905090565b60006102c733848460016105b9565b50600192915050565b60006102df8484846001610661565b6102ec843384600161072c565b5060019392505050565b60006102c733848460016107eb565b6002546001600160a01b0316331461031c57600080fd5b6001600160a01b03821661032f57600080fd5b806005600082825461034191906109b3565b90915550506001600160a01b0382166000908152600360205260408120805483929061036e9084906109b3565b90915550506040518181526001600160a01b038316906000907fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef906020015b60405180910390a35050565b6002546001600160a01b0316156103cf57600080fd5b60028054336001600160a01b031991821617909155600094909455600192909255600655600780549092166001600160a01b03909116179055565b60606102b36000546104e3565b6002546001600160a01b0316331461042e57600080fd5b6001600160a01b03821661044157600080fd5b6001600160a01b038216600090815260036020526040812080548392906104699084906109f0565b92505081905550806005600082825461048291906109f0565b90915550506040518181526000906001600160a01b038416907fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef906020016103ad565b60006102c7338484600161072c565b60006102c73384846001610661565b6060816104fe57505060408051600081526020810190915290565b600060105b60ff811615610555578361051782846109cb565b60ff166020811061052a5761052a610a1d565b1a60f81b6001600160f81b0319161561054a5761054781836109cb565b91505b60011c607f16610503565b5060006105638260016109cb565b60ff1667ffffffffffffffff81111561057e5761057e610a33565b6040519080825280601f01601f1916602001820160405280156105a8576020820181803683370190505b506020810194909452509192915050565b6001600160a01b0384166105cc57600080fd5b6001600160a01b0383166105df57600080fd5b6001600160a01b038085166000908152600460209081526040808320938716835292905220829055801561065b57826001600160a01b0316846001600160a01b03167f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b9258460405161065291815260200190565b60405180910390a35b50505050565b6001600160a01b03841661067457600080fd5b6001600160a01b03831661068757600080fd5b6001600160a01b038416600090815260036020526040812080548492906106af9084906109f0565b90915550506001600160a01b038316600090815260036020526040812080548492906106dc9084906109b3565b9091555050801561065b57826001600160a01b0316846001600160a01b03167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef8460405161065291815260200190565b6001600160a01b03841661073f57600080fd5b6001600160a01b03831661075257600080fd5b6001600160a01b038085166000908152600460209081526040808320938716835292905290812080548492906107899084906109f0565b9091555050801561065b576001600160a01b038481166000818152600460209081526040808320948816808452948252918290205491519182527f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b9259101610652565b6001600160a01b0384166107fe57600080fd5b6001600160a01b03831661081157600080fd5b6001600160a01b038085166000908152600460209081526040808320938716835292905290812080548492906107899084906109b3565b80356001600160a01b038116811461085f57600080fd5b919050565b60006020828403121561087657600080fd5b61087f82610848565b9392505050565b6000806040838503121561089957600080fd5b6108a283610848565b91506108b060208401610848565b90509250929050565b6000806000606084860312156108ce57600080fd5b6108d784610848565b92506108e560208501610848565b9150604084013590509250925092565b6000806040838503121561090857600080fd5b61091183610848565b946020939093013593505050565b6000806000806080858703121561093557600080fd5b84359350602085013592506040850135915061095360608601610848565b905092959194509250565b600060208083528351808285015260005b8181101561098b5785810183015185820160400152820161096f565b8181111561099d576000604083870101525b50601f01601f1916929092016040019392505050565b600082198211156109c6576109c6610a07565b500190565b600060ff821660ff84168060ff038211156109e8576109e8610a07565b019392505050565b600082821015610a0257610a02610a07565b500390565b634e487b7160e01b600052601160045260246000fd5b634e487b7160e01b600052603260045260246000fd5b634e487b7160e01b600052604160045260246000fdfea2646970667358221220fe9609dd4d099f8ee61d515b2ebf66a53d24e78cf669be48b69b627acefde71564736f6c63430008060033";

    bytes32 constant internal SIMPLE_TOKEN_TEMPLATE_HASH = keccak256(SIMPLE_TOKEN_TEMPLATE_BYTECODE);

    bytes4 constant internal SET_META_DATA_SIG = bytes4(keccak256("obtainOwnership(bytes32,bytes32)"));

    function deploySimpleTokenTemplate(SimpleTokenFactory templateFactory) internal returns (address) {
        /* we can use any deterministic salt here, since we don't care about it */
        bytes32 salt = SIMPLE_TOKEN_TEMPLATE_SALT;
        /* concat bytecode with constructor */
        bytes memory bytecode = SIMPLE_TOKEN_TEMPLATE_BYTECODE;
        /* deploy contract and store result in result variable */
        address result;
        assembly {
            result := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(result != address(0x00), "deploy failed");
        /* check that generated contract address is correct */
        require(result == simpleTokenTemplateAddress(templateFactory), "address mismatched");
        return result;
    }

    function simpleTokenTemplateAddress(SimpleTokenFactory templateFactory) internal pure returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(uint8(0xff), address(templateFactory), SIMPLE_TOKEN_TEMPLATE_SALT, SIMPLE_TOKEN_TEMPLATE_HASH));
        return address(bytes20(hash << 96));
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "./interfaces/ICrossChainBridge.sol";

contract SimpleTokenProxy {

    bytes32 private constant BEACON_SLOT = bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1);

    fallback() external {
        address bridge;
        bytes32 slot = BEACON_SLOT;
        assembly {
            bridge := sload(slot)
        }
        address impl = ICrossChainBridge(bridge).getTokenImplementation();
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {revert(0, returndatasize())}
            default {return (0, returndatasize())}
        }
    }

    function setBeacon(address newBeacon) external {
        address beacon;
        bytes32 slot = BEACON_SLOT;
        assembly {
            beacon := sload(slot)
        }
        require(beacon == address(0x00));
        assembly {
            sstore(slot, newBeacon)
        }
    }
}

library SimpleTokenProxyUtils {

    bytes constant internal SIMPLE_TOKEN_PROXY_BYTECODE = hex"608060405234801561001057600080fd5b50610215806100206000396000f3fe608060405234801561001057600080fd5b506004361061002b5760003560e01c8063d42afb56146100fd575b60008061005960017fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d516101a2565b60001b9050805491506000826001600160a01b031663709bc7f36040518163ffffffff1660e01b8152600401602060405180830381600087803b15801561009f57600080fd5b505af11580156100b3573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906100d79190610185565b90503660008037600080366000845af43d6000803e8080156100f8573d6000f35b3d6000fd5b61011061010b366004610161565b610112565b005b60008061014060017fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d516101a2565b8054925090506001600160a01b0382161561015a57600080fd5b9190915550565b60006020828403121561017357600080fd5b813561017e816101c7565b9392505050565b60006020828403121561019757600080fd5b815161017e816101c7565b6000828210156101c257634e487b7160e01b600052601160045260246000fd5b500390565b6001600160a01b03811681146101dc57600080fd5b5056fea2646970667358221220e6ae4b3dc2474e43ff609e19eb520ce54b6f38170a43a6f96541360be5efc2b464736f6c63430008060033";

    bytes32 constant internal SIMPLE_TOKEN_PROXY_HASH = keccak256(SIMPLE_TOKEN_PROXY_BYTECODE);

    bytes4 constant internal SET_META_DATA_SIG = bytes4(keccak256("initAndObtainOwnership(bytes32,bytes32,uint256,address)"));
    bytes4 constant internal SET_BEACON_SIG = bytes4(keccak256("setBeacon(address)"));

    function deploySimpleTokenProxy(address bridge, bytes32 salt, ICrossChainBridge.Metadata memory metaData) internal returns (address) {
        /* lets concat bytecode with constructor parameters */
        bytes memory bytecode = SIMPLE_TOKEN_PROXY_BYTECODE;
        /* deploy new contract and store contract address in result variable */
        address result;
        assembly {
            result := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(result != address(0x00), "deploy failed");
        /* setup impl */
        (bool success,) = result.call(abi.encodePacked(SET_BEACON_SIG, abi.encode(bridge)));
        require(success, "setBeacon failed");
        /* setup meta data */
        (success,) = result.call(abi.encodePacked(SET_META_DATA_SIG, abi.encode(metaData)));
        require(success, "set metadata failed");
        /* return generated contract address */
        return result;
    }

    function simpleTokenProxyAddress(address deployer, bytes32 salt) internal pure returns (address) {
        bytes32 bytecodeHash = keccak256(SIMPLE_TOKEN_PROXY_BYTECODE);
        bytes32 hash = keccak256(abi.encodePacked(uint8(0xff), address(deployer), salt, bytecodeHash));
        return address(bytes20(hash << 96));
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "../interfaces/IERC20.sol";

interface ICrossChainBridge {

    event ContractAllowed(address contractAddress, uint256 toChain);
    event ContractDisallowed(address contractAddress, uint256 toChain);
    event ConsensusChanged(address consensusAddress);
    event TokenImplementationChanged(address consensusAddress);
    event BondImplementationChanged(address consensusAddress);

    struct Metadata {
        bytes32 symbol;
        bytes32 name;
        uint256 originChain;
        address originAddress;
        bytes32 bondMetadata; // encoded metadata version, bond type
    }

    event DepositLocked(
        uint256 chainId,
        address indexed fromAddress,
        address indexed toAddress,
        address fromToken,
        address toToken,
        uint256 totalAmount,
        Metadata metadata
    );
    event DepositBurned(
        uint256 chainId,
        address indexed fromAddress,
        address indexed toAddress,
        address fromToken,
        address toToken,
        uint256 totalAmount,
        Metadata metadata,
        address originToken
    );

    event WithdrawMinted(
        bytes32 receiptHash,
        address indexed fromAddress,
        address indexed toAddress,
        address fromToken,
        address toToken,
        uint256 totalAmount
    );
    event WithdrawUnlocked(
        bytes32 receiptHash,
        address indexed fromAddress,
        address indexed toAddress,
        address fromToken,
        address toToken,
        uint256 totalAmount
    );

    enum InternetBondType {
        NOT_BOND,
        REBASING_BOND,
        NONREBASING_BOND
    }

    function isPeggedToken(address toToken) external returns (bool);

    function deposit(uint256 toChain, address toAddress) payable external;

    function deposit(address fromToken, uint256 toChain, address toAddress, uint256 amount) external;

    function withdraw(bytes calldata encodedProof, bytes calldata rawReceipt, bytes calldata receiptRootSignature) external;

    function factoryPeggedToken(uint256 fromChain, Metadata calldata metaData) external;

    function factoryPeggedBond(uint256 fromChain, Metadata calldata metaData) external;

    function getTokenImplementation() external returns (address);

    function getBondImplementation() external returns (address);

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Mintable {

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}

interface IERC20Pegged {

    function getOrigin() external view returns (uint256, address);
}

interface IERC20Extra {

    function name() external returns (string memory);

    function decimals() external returns (uint8);

    function symbol() external returns (string memory);
}

interface IERC20InternetBond {

    function ratio() external view returns (uint256);

    function isRebasing() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

interface IInternetBondRatioFeed {

    function updateRatioBatch(address[] calldata addresses, uint256[] calldata ratios) external;

    function getRatioFor(address) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.6;

library CallDataRLPReader {
    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START = 0xb8;
    uint8 constant LIST_SHORT_START = 0xc0;
    uint8 constant LIST_LONG_START = 0xf8;
    uint8 constant WORD_SIZE = 32;

    function beginIteration(uint256 listOffset) internal pure returns (uint256 iter) {
        return listOffset + _payloadOffset(listOffset);
    }

    function next(uint256 iter) internal pure returns (uint256 nextIter) {
        return iter + itemLength(iter);
    }

    function payloadLen(uint256 ptr, uint256 len) internal pure returns (uint256) {
        return len - _payloadOffset(ptr);
    }

    function toAddress(uint256 ptr) internal pure returns (address) {
        return address(uint160(toUint(ptr, 21)));
    }

    function toUint(uint256 ptr, uint256 len) internal pure returns (uint256) {
        require(len > 0 && len <= 33);
        uint256 offset = _payloadOffset(ptr);
        uint256 numLen = len - offset;

        uint256 result;
        assembly {
            result := calldataload(add(ptr, offset))
            // cut off redundant bytes
            result := shr(mul(8, sub(32, numLen)), result)
        }
        return result;
    }

    function toUintStrict(uint256 ptr) internal pure returns (uint256) {
        // one byte prefix
        uint256 result;
        assembly {
            result := calldataload(add(ptr, 1))
        }
        return result;
    }

    function rawDataPtr(uint256 ptr) internal pure returns (uint256) {
        return ptr + _payloadOffset(ptr);
    }

    // @return entire rlp item byte length
    function itemLength(uint callDataPtr) internal pure returns (uint256) {
        uint256 itemLen;
        uint256 byte0;
        assembly {
            byte0 := byte(0, calldataload(callDataPtr))
        }

        if (byte0 < STRING_SHORT_START)
            itemLen = 1;
        else if (byte0 < STRING_LONG_START)
            itemLen = byte0 - STRING_SHORT_START + 1;
        else if (byte0 < LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
                callDataPtr := add(callDataPtr, 1) // skip over the first byte

                /* 32 byte word size */
                let dataLen := shr(mul(8, sub(32, byteLen)), calldataload(callDataPtr))
                itemLen := add(dataLen, add(byteLen, 1))
            }
        }
        else if (byte0 < LIST_LONG_START) {
            itemLen = byte0 - LIST_SHORT_START + 1;
        }
        else {
            assembly {
                let byteLen := sub(byte0, 0xf7)
                callDataPtr := add(callDataPtr, 1)

                let dataLen := shr(mul(8, sub(32, byteLen)), calldataload(callDataPtr))
                itemLen := add(dataLen, add(byteLen, 1))
            }
        }

        return itemLen;
    }

    // @return number of bytes until the data
    function _payloadOffset(uint256 callDataPtr) private pure returns (uint256) {
        uint256 byte0;
        assembly {
            byte0 := byte(0, calldataload(callDataPtr))
        }

        if (byte0 < STRING_SHORT_START)
            return 0;
        else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START))
            return 1;
        else if (byte0 < LIST_SHORT_START)
            return byte0 - (STRING_LONG_START - 1) + 1;
        else
            return byte0 - (LIST_LONG_START - 1) + 1;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "./CallDataRLPReader.sol";
import "./Utils.sol";
import "../interfaces/ICrossChainBridge.sol";

library EthereumVerifier {

    bytes32 constant TOPIC_PEG_IN_LOCKED = keccak256("DepositLocked(uint256,address,address,address,address,uint256,(bytes32,bytes32,uint256,address,bytes32))");
    bytes32 constant TOPIC_PEG_IN_BURNED = keccak256("DepositBurned(uint256,address,address,address,address,uint256,(bytes32,bytes32,uint256,address,bytes32),address)");

    enum PegInType {
        None,
        Lock,
        Burn
    }

    struct State {
        bytes32 receiptHash;
        address contractAddress;
        uint256 chainId;
        address fromAddress;
        address payable toAddress;
        address fromToken;
        address toToken;
        uint256 totalAmount;
        // metadata fields (we can't use Metadata struct here because of Solidity struct memory layout)
        bytes32 symbol;
        bytes32 name;
        uint256 originChain;
        address originAddress;
        bytes32 bondMetadata;
        address originToken;
    }

    function getMetadata(State memory state) internal pure returns (ICrossChainBridge.Metadata memory) {
        ICrossChainBridge.Metadata memory metadata;
        assembly {
            metadata := add(state, 0x100)
        }
        return metadata;
    }

    function parseTransactionReceipt(uint256 receiptOffset) internal view returns (State memory, PegInType pegInType) {
        State memory state;
        /* parse peg-in data from logs */
        uint256 iter = CallDataRLPReader.beginIteration(receiptOffset + 0x20);
        {
            /* postStateOrStatus - we must ensure that tx is not reverted */
            uint256 statusOffset = iter;
            iter = CallDataRLPReader.next(iter);
            require(CallDataRLPReader.payloadLen(statusOffset, iter - statusOffset) == 1, "tx is reverted");
        }
        /* skip cumulativeGasUsed */
        iter = CallDataRLPReader.next(iter);
        /* logs - we need to find our logs */
        uint256 logs = iter;
        iter = CallDataRLPReader.next(iter);
        uint256 logsIter = CallDataRLPReader.beginIteration(logs);
        for (; logsIter < iter;) {
            uint256 log = logsIter;
            logsIter = CallDataRLPReader.next(logsIter);
            /* make sure there is only one peg-in event in logs */
            PegInType logType = _decodeReceiptLogs(state, log);
            if (logType != PegInType.None) {
                require(pegInType == PegInType.None, "multiple logs");
                pegInType = logType;
            }
        }
        /* don't allow to process if peg-in type is unknown */
        require(pegInType != PegInType.None, "missing logs");
        return (state, pegInType);
    }

    function _decodeReceiptLogs(
        State memory state,
        uint256 log
    ) internal view returns (PegInType pegInType) {
        uint256 logIter = CallDataRLPReader.beginIteration(log);
        address contractAddress;
        {
            /* parse smart contract address */
            uint256 addressOffset = logIter;
            logIter = CallDataRLPReader.next(logIter);
            contractAddress = CallDataRLPReader.toAddress(addressOffset);
        }
        /* topics */
        bytes32 mainTopic;
        address fromAddress;
        address toAddress;
        {
            uint256 topicsIter = logIter;
            logIter = CallDataRLPReader.next(logIter);
            // Must be 3 topics RLP encoded: event signature, fromAddress, toAddress
            // Each topic RLP encoded is 33 bytes (0xa0[32 bytes data])
            // Total payload: 99 bytes. Since it's list with total size bigger than 55 bytes we need 2 bytes prefix (0xf863)
            // So total size of RLP encoded topics array must be 101
            if (CallDataRLPReader.itemLength(topicsIter) != 101) {
                return PegInType.None;
            }
            topicsIter = CallDataRLPReader.beginIteration(topicsIter);
            mainTopic = bytes32(CallDataRLPReader.toUintStrict(topicsIter));
            topicsIter = CallDataRLPReader.next(topicsIter);
            fromAddress = address(bytes20(uint160(CallDataRLPReader.toUintStrict(topicsIter))));
            topicsIter = CallDataRLPReader.next(topicsIter);
            toAddress = address(bytes20(uint160(CallDataRLPReader.toUintStrict(topicsIter))));
            topicsIter = CallDataRLPReader.next(topicsIter);
            require(topicsIter == logIter); // safety check that iteration is finished
        }

        uint256 ptr = CallDataRLPReader.rawDataPtr(logIter);
        logIter = CallDataRLPReader.next(logIter);
        uint256 len = logIter - ptr;
        {
            // parse logs based on topic type and check that event data has correct length
            uint256 expectedLen;
            if (mainTopic == TOPIC_PEG_IN_LOCKED) {
                expectedLen = 0x120;
                pegInType = PegInType.Lock;
            } else if (mainTopic == TOPIC_PEG_IN_BURNED) {
                expectedLen = 0x140;
                pegInType = PegInType.Burn;
            } else {
                return PegInType.None;
            }
            if (len != expectedLen) {
                return PegInType.None;
            }
        }
        {
            // read chain id separately and verify that contract that emitted event is relevant
            uint256 chainId;
            assembly {
                chainId := calldataload(ptr)
            }
            if (chainId != Utils.currentChain()) return PegInType.None;
            // All checks are passed after this point, no errors allowed and we can modify state
            state.chainId = chainId;
            ptr += 0x20;
            len -= 0x20;
        }

        {
            uint256 structOffset;
            assembly {
                // skip 5 fields: receiptHash, contractAddress, chainId, fromAddress, toAddress
                structOffset := add(state, 0xa0)
                calldatacopy(structOffset, ptr, len)
            }
        }
        state.contractAddress = contractAddress;
        state.fromAddress = fromAddress;
        state.toAddress = payable(toAddress);
        return pegInType;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "./CallDataRLPReader.sol";
import "./Utils.sol";

library ProofParser {

    // Proof is message format signed by the protocol. It contains somewhat redundant information, so only part
    // of the proof could be passed into the contract and other part can be inferred from transaction receipt
    struct Proof {
        uint256 chainId;
        uint256 status;
        bytes32 transactionHash;
        uint256 blockNumber;
        bytes32 blockHash;
        uint256 transactionIndex;
        bytes32 receiptHash;
        uint256 transferAmount;
    }

    function parseProof(uint256 proofOffset) internal pure returns (Proof memory) {
        Proof memory proof;
        uint256 dataOffset = proofOffset + 0x20;
        assembly {
            calldatacopy(proof, dataOffset, 0x20) // 1 field (chainId)
            dataOffset := add(dataOffset, 0x20)
            calldatacopy(add(proof, 0x40), dataOffset, 0x80) // 4 fields * 0x20 = 0x80
            dataOffset := add(dataOffset, 0x80)
            calldatacopy(add(proof, 0xe0), dataOffset, 0x20) // transferAmount
        }
        return proof;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "../SimpleToken.sol";

library Utils {

    function currentChain() internal view returns (uint256) {
        uint256 chain;
        assembly {
            chain := chainid()
        }
        return chain;
    }

    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }

    function saturatingMultiply(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            if (a == 0) return 0;
            uint256 c = a * b;
            if (c / a != b) return type(uint256).max;
            return c;
        }
    }

    function saturatingAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return type(uint256).max;
            return c;
        }
    }

    // Preconditions:
    //  1. a may be arbitrary (up to 2 ** 256 - 1)
    //  2. b * c < 2 ** 256
    // Returned value: min(floor((a * b) / c), 2 ** 256 - 1)
    function multiplyAndDivideFloor(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {
        return saturatingAdd(
            saturatingMultiply(a / c, b),
            ((a % c) * b) / c // can't fail because of assumption 2.
        );
    }

    // Preconditions:
    //  1. a may be arbitrary (up to 2 ** 256 - 1)
    //  2. b * c < 2 ** 256
    // Returned value: min(ceil((a * b) / c), 2 ** 256 - 1)
    function multiplyAndDivideCeil(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {
        return saturatingAdd(
            saturatingMultiply(a / c, b),
            ((a % c) * b + (c - 1)) / c // can't fail because of assumption 2.
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import "../interfaces/ICrossChainBridge.sol";
import "../interfaces/IERC20.sol";
import "../libraries/EthereumVerifier.sol";
import "../libraries/ProofParser.sol";
import "../libraries/Utils.sol";
import "../SimpleToken.sol";
import "../InternetBond.sol";
import "../InternetBondRatioFeed.sol";
import "../BridgeRouter.sol";

contract CrossChainBridge_R1 is PausableUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable, ICrossChainBridge {

    mapping(uint256 => address) private _bridgeAddressByChainId;
    address private _consensusAddress;
    mapping(bytes32 => bool) private _usedProofs;
    address private _tokenImplementation;
    mapping(address => address) private _peggedTokenOrigin;
    Metadata _nativeTokenMetadata;
    address private _bondImplementation;
    IInternetBondRatioFeed private _internetBondRatioFeed;
    BridgeRouter private _bridgeRouter;

    function initialize(
        address consensusAddress,
        SimpleTokenFactory tokenFactory,
        InternetBondFactory bondFactory,
        string memory nativeTokenSymbol,
        string memory nativeTokenName,
        InternetBondRatioFeed bondFeed,
        BridgeRouter router
    ) public initializer {
        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();
        __CrossChainBridge_init(consensusAddress, tokenFactory, bondFactory, nativeTokenSymbol, nativeTokenName, bondFeed, router);
    }

    function getTokenImplementation() public view override returns (address) {
        return _tokenImplementation;
    }

    function setTokenFactory(SimpleTokenFactory factory) public onlyOwner {
        _tokenImplementation = factory.getImplementation();
        require(_tokenImplementation != address(0x0));
        emit TokenImplementationChanged(_tokenImplementation);
    }

    function getBondImplementation() public view override returns (address) {
        return _bondImplementation;
    }

    function setBondFactory(InternetBondFactory factory) public onlyOwner {
        _bondImplementation = factory.getImplementation();
        require(_bondImplementation != address(0x0));
        emit BondImplementationChanged(_tokenImplementation);
    }

    function getNativeAddress() public view returns (address) {
        return _nativeTokenMetadata.originAddress;
    }

    function getOrigin(address token) internal view returns (uint256, address) {
        if (token == _nativeTokenMetadata.originAddress) {
            return (0, address(0x0));
        }
        try IERC20Pegged(token).getOrigin() returns (uint256 chain, address origin) {
            return (chain, origin);
        } catch {}
        return (0, address(0x0));
    }

    function __CrossChainBridge_init(
        address consensusAddress,
        SimpleTokenFactory tokenFactory,
        InternetBondFactory bondFactory,
        string memory nativeTokenSymbol,
        string memory nativeTokenName,
        InternetBondRatioFeed bondFeed,
        BridgeRouter router
    ) internal {
        _consensusAddress = consensusAddress;
        _tokenImplementation = tokenFactory.getImplementation();
        _bondImplementation = bondFactory.getImplementation();
        _nativeTokenMetadata = Metadata(
            Utils.stringToBytes32(nativeTokenSymbol),
            Utils.stringToBytes32(nativeTokenName),
            Utils.currentChain(),
            // generate unique address that will not collide with any contract address
            address(bytes20(keccak256(abi.encodePacked("CrossChainBridge:", nativeTokenSymbol)))),
            0x0
        );
        _internetBondRatioFeed = bondFeed;
        _bridgeRouter = router;
    }

    // HELPER FUNCTIONS

    function isPeggedToken(address toToken) public view override returns (bool) {
        return _peggedTokenOrigin[toToken] != address(0x00);
    }

    function getRatio(address token) public view returns (uint256) {
        return _internetBondRatioFeed.getRatioFor(token);
    }

    function getBondType(address token) public view returns (InternetBondType) {
        try IERC20InternetBond(token).isRebasing() returns (bool isRebasing) {
            if (isRebasing) return InternetBondType.REBASING_BOND;
            else return InternetBondType.NONREBASING_BOND;
        } catch {
        }
        return InternetBondType.NOT_BOND;
    }

    function getNativeRatio(address token) public view returns (uint256) {
        try IERC20InternetBond(token).ratio() returns (uint256 ratio) {
            return ratio;
        } catch {
        }
        return 0;
    }

    function createBondMetadata(uint8 version, InternetBondType bondType) internal pure returns (bytes32) {
        bytes32 result = 0x0;
        result |= bytes32(bytes1(version));
        result |= bytes32(bytes1(uint8(bondType))) >> 8;
        return result;
    }

    // DEPOSIT FUNCTIONS

    function deposit(uint256 toChain, address toAddress) public payable nonReentrant whenNotPaused override {
        _depositNative(toChain, toAddress, msg.value);
    }

    function deposit(address fromToken, uint256 toChain, address toAddress, uint256 amount) public nonReentrant whenNotPaused override {
        (uint256 chain, address origin) = getOrigin(fromToken);
        if (chain != 0) {
            /* if we have pegged contract then its pegged token */
            _depositPegged(fromToken, toChain, toAddress, amount, chain, origin);
        } else {
            /* otherwise its erc20 token, since we can't detect is it erc20 token it can only return insufficient balance in case of any errors */
            _depositErc20(fromToken, toChain, toAddress, amount);
        }
    }

    function _depositNative(uint256 toChain, address toAddress, uint256 totalAmount) internal {
        /* sender is our from address because he is locking funds */
        address fromAddress = address(msg.sender);
        /* lets determine target bridge contract */
        address toBridge = _bridgeAddressByChainId[toChain];
        require(toBridge != address(0x00), "bad chain");
        /* we need to calculate peg token contract address with meta data */
        address toToken = _bridgeRouter.peggedTokenAddress(address(toBridge), _nativeTokenMetadata.originAddress);
        /* emit event with all these params */
        emit DepositLocked(
            toChain,
            fromAddress, // who send these funds
            toAddress, // who can claim these funds in "toChain" network
            _nativeTokenMetadata.originAddress, // this is our current native token (e.g. ETH, MATIC, BNB, etc)
            toToken, // this is an address of our target pegged token
            totalAmount, // how much funds was locked in this contract
            _nativeTokenMetadata // meta information about
        );
    }

    function _depositPegged(address fromToken, uint256 toChain, address toAddress, uint256 totalAmount, uint256 chain, address origin) internal {
        /* sender is our from address because he is locking funds */
        address fromAddress = address(msg.sender);
        /* check allowance and transfer tokens */
        require(IERC20Upgradeable(fromToken).balanceOf(fromAddress) >= totalAmount, "insufficient balance");
        InternetBondType bondType = getBondType(fromToken);
        uint256 amt;
        if (bondType == InternetBondType.REBASING_BOND) {
            amt = _peggedAmountToShares(totalAmount, getRatio(origin));
        } else {
            amt = totalAmount;
        }
        address toToken;
        if (bondType == InternetBondType.NOT_BOND) {
            toToken = _peggedDestinationErc20Token(fromToken, origin, toChain, chain);
        } else {
            toToken = _peggedDestinationErc20Bond(fromToken, origin, toChain, chain);
        }
        IERC20Mintable(fromToken).burn(fromAddress, amt);
        Metadata memory metaData = Metadata(
            Utils.stringToBytes32(IERC20Extra(fromToken).symbol()),
            Utils.stringToBytes32(IERC20Extra(fromToken).name()),
            chain,
            origin,
            createBondMetadata(0, bondType)
        );
        /* emit event with all these params */
        emit DepositBurned(
            toChain,
            fromAddress, // who send these funds
            toAddress, // who can claim these funds in "toChain" network
            fromToken, // this is our current native token (can be ETH, CLV, DOT, BNB or something else)
            toToken, // this is an address of our target pegged token
            amt, // how much funds was locked in this contract
            metaData,
            origin
        );
    }

    function _peggedAmountToShares(uint256 amount, uint256 ratio) internal pure returns (uint256) {
        require(ratio > 0, "zero ratio");
        return Utils.multiplyAndDivideFloor(amount, ratio, 1e18);
    }

    function _nativeAmountToShares(uint256 amount, uint256 ratio, uint8 decimals) internal pure returns (uint256) {
        require(ratio > 0, "zero ratio");
        return Utils.multiplyAndDivideFloor(amount, ratio, 10 ** decimals);
    }

    function _depositErc20(address fromToken, uint256 toChain, address toAddress, uint256 totalAmount) internal {
        /* sender is our from address because he is locking funds */
        address fromAddress = address(msg.sender);
        InternetBondType bondType = getBondType(fromToken);
        /* check allowance and transfer tokens */
        {
            uint256 balanceBefore = IERC20(fromToken).balanceOf(address(this));
            uint256 allowance = IERC20(fromToken).allowance(fromAddress, address(this));
            require(totalAmount <= allowance, "insufficient allowance");
            require(IERC20(fromToken).transferFrom(fromAddress, address(this), totalAmount), "can't transfer");
            uint256 balanceAfter = IERC20(fromToken).balanceOf(address(this));
            if (bondType != InternetBondType.REBASING_BOND) {
                // Assert that enough coins were transferred to bridge
                require(balanceAfter >= balanceBefore + totalAmount, "incorrect behaviour");
            } else {
                // For rebasing internet bonds we can't assert that exactly totalAmount will be transferred
                require(balanceAfter >= balanceBefore, "incorrect behaviour");
            }
        }
        /* lets determine target bridge contract */
        address toBridge = _bridgeAddressByChainId[toChain];
        require(toBridge != address(0x00), "bad chain");
        /* lets pack ERC20 token meta data and scale amount to 18 decimals */
        uint256 chain = Utils.currentChain();
        uint256 amt;
        if (bondType != InternetBondType.REBASING_BOND) {
            amt = _amountErc20Token(fromToken, totalAmount);
        } else {
            amt = _amountErc20Bond(fromToken, totalAmount, getNativeRatio(fromToken));
        }
        address toToken;
        if (bondType == InternetBondType.NOT_BOND) {
            toToken = _bridgeRouter.peggedTokenAddress(address(toBridge), fromToken);
        } else {
            toToken = _bridgeRouter.peggedBondAddress(address(toBridge), fromToken);
        }
        Metadata memory metaData = Metadata(
            Utils.stringToBytes32(IERC20Extra(fromToken).symbol()),
            Utils.stringToBytes32(IERC20Extra(fromToken).name()),
            chain,
            fromToken,
            createBondMetadata(0, bondType)
        );
        /* emit event with all these params */
        emit DepositLocked(
            toChain,
            fromAddress, // who send these funds
            toAddress, // who can claim these funds in "toChain" network
            fromToken, // this is our current native token (can be ETH, CLV, DOT, BNB or something else)
            toToken, // this is an address of our target pegged token
            amt, // how much funds was locked in this contract
            metaData // meta information about
        );
    }

    function _peggedDestinationErc20Token(address fromToken, address origin, uint256 toChain, uint originChain) internal view returns (address) {
        /* lets determine target bridge contract */
        address toBridge = _bridgeAddressByChainId[toChain];
        require(toBridge != address(0x00), "bad chain");
        require(_peggedTokenOrigin[fromToken] == origin, "non-pegged contract not supported");
        if (toChain == originChain) {
            return _peggedTokenOrigin[fromToken];
        } else {
            return _bridgeRouter.peggedTokenAddress(address(toBridge), origin);
        }
    }

    function _peggedDestinationErc20Bond(address fromToken, address origin, uint256 toChain, uint originChain) internal view returns (address) {
        /* lets determine target bridge contract */
        address toBridge = _bridgeAddressByChainId[toChain];
        require(toBridge != address(0x00), "bad chain");
        require(_peggedTokenOrigin[fromToken] == origin, "non-pegged contract not supported");
        if (toChain == originChain) {
            return _peggedTokenOrigin[fromToken];
        } else {
            return _bridgeRouter.peggedBondAddress(address(toBridge), origin);
        }
    }

    function _amountErc20Token(address fromToken, uint256 totalAmount) internal returns (uint256) {
        /* lets pack ERC20 token meta data and scale amount to 18 decimals */
        require(IERC20Extra(fromToken).decimals() <= 18, "decimals overflow");
        totalAmount *= (10 ** (18 - IERC20Extra(fromToken).decimals()));
        return totalAmount;
    }

    function _amountErc20Bond(address fromToken, uint256 totalAmount, uint256 nativeRatio) internal returns (uint256) {
        /* lets pack ERC20 token meta data and scale amount to 18 decimals */
        uint8 decimals = IERC20Extra(fromToken).decimals();
        require(decimals <= 18, "decimals overflow");
        uint256 totalShares = _nativeAmountToShares(totalAmount, nativeRatio, decimals);
        totalShares *= (10 ** (18 - decimals));
        return totalShares;
    }

    function _currentChainNativeMetaData() internal view returns (Metadata memory) {
        return _nativeTokenMetadata;
    }

    // WITHDRAWAL FUNCTIONS

    function withdraw(
        bytes calldata /* encodedProof */,
        bytes calldata rawReceipt,
        bytes memory proofSignature
    ) external nonReentrant whenNotPaused override {
        uint256 proofOffset;
        uint256 receiptOffset;
        assembly {
            proofOffset := add(0x4, calldataload(4))
            receiptOffset := add(0x4, calldataload(36))
        }
        /* we must parse and verify that tx and receipt matches */
        (EthereumVerifier.State memory state, EthereumVerifier.PegInType pegInType) = EthereumVerifier.parseTransactionReceipt(receiptOffset);
        require(state.chainId == Utils.currentChain(), "receipt points to another chain");
        ProofParser.Proof memory proof = ProofParser.parseProof(proofOffset);
        require(_bridgeAddressByChainId[proof.chainId] == state.contractAddress, "crosschain event from not allowed contract");
        state.receiptHash = keccak256(rawReceipt);
        proof.status = 0x01; // execution must be successful
        proof.receiptHash = state.receiptHash; // ensure that rawReceipt is preimage of receiptHash
        bytes32 hash;
        assembly {
            hash := keccak256(proof, 0x100)
        }
        // we can trust receipt only if proof is signed by consensus
        require(ECDSAUpgradeable.recover(hash, proofSignature) == _consensusAddress, "bad signature");
        // withdraw funds to recipient
        _withdraw(state, pegInType, hash);
    }

    function _withdraw(EthereumVerifier.State memory state, EthereumVerifier.PegInType pegInType, bytes32 proofHash) internal {
        /* make sure these proofs wasn't used before */
        require(!_usedProofs[proofHash], "proof already used");
        _usedProofs[proofHash] = true;
        if (state.toToken == _nativeTokenMetadata.originAddress) {
            _withdrawNative(state);
        } else if (pegInType == EthereumVerifier.PegInType.Lock) {
            _withdrawPegged(state, state.fromToken);
        } else if (state.toToken != state.originToken) {
            // origin token is not deployed by our bridge so collision is not possible
            _withdrawPegged(state, state.originToken);
        } else {
            _withdrawErc20(state);
        }
    }

    function _withdrawNative(EthereumVerifier.State memory state) internal {
        state.toAddress.transfer(state.totalAmount);
        emit WithdrawUnlocked(
            state.receiptHash,
            state.fromAddress,
            state.toAddress,
            state.fromToken,
            state.toToken,
            state.totalAmount
        );
    }

    function _withdrawPegged(EthereumVerifier.State memory state, address origin) internal {
        /* create pegged token if it doesn't exist */
        Metadata memory metadata = EthereumVerifier.getMetadata(state);
        InternetBondType bondType = InternetBondType(uint8(metadata.bondMetadata[1]));
        if (bondType == InternetBondType.NOT_BOND) {
            _factoryPeggedToken(state.toToken, metadata);
        } else {
            _factoryPeggedBond(state.toToken, metadata);
        }
        /* mint tokens (NB: mint for bonds accepts amount in shares) */
        IERC20Mintable(state.toToken).mint(state.toAddress, state.totalAmount);
        /* emit peg-out event (its just informative event) */
        emit WithdrawMinted(
            state.receiptHash,
            state.fromAddress,
            state.toAddress,
            state.fromToken,
            state.toToken,
            state.totalAmount
        );
    }

    function _withdrawErc20(EthereumVerifier.State memory state) internal {
        Metadata memory metadata = EthereumVerifier.getMetadata(state);
        InternetBondType bondType = InternetBondType(uint8(metadata.bondMetadata[1]));
        /* we need to rescale this amount */
        uint8 decimals = IERC20Extra(state.toToken).decimals();
        require(decimals <= 18, "decimals overflow");
        uint256 scaledAmount = state.totalAmount / (10 ** (18 - decimals));
        if (bondType == InternetBondType.REBASING_BOND) {
            scaledAmount = Utils.multiplyAndDivideCeil(scaledAmount, 10 ** decimals, getNativeRatio(state.toToken));
        }
        /* transfer tokens and make sure behaviour is correct (just in case) */
        uint256 balanceBefore = IERC20(state.toToken).balanceOf(state.toAddress);
        require(IERC20Upgradeable(state.toToken).transfer(state.toAddress, scaledAmount), "can't transfer");
        uint256 balanceAfter = IERC20(state.toToken).balanceOf(state.toAddress);
        require(balanceBefore <= balanceAfter, "incorrect behaviour");
        /* emit peg-out event (its just informative event) */
        emit WithdrawUnlocked(
            state.receiptHash,
            state.fromAddress,
            state.toAddress,
            state.fromToken,
            state.toToken,
            state.totalAmount
        );
    }

    // OWNER MAINTENANCE FUNCTIONS (owner functions will be reduced in future releases)

    function factoryPeggedToken(uint256 fromChain, Metadata calldata metaData) external onlyOwner override {
        // make sure this chain is supported
        require(_bridgeAddressByChainId[fromChain] != address(0x00), "bad contract");
        // calc target token
        address toToken = _bridgeRouter.peggedTokenAddress(address(this), metaData.originAddress);
        require(_peggedTokenOrigin[toToken] == address(0x00), "already exists");
        // deploy new token (its just a warmup operation)
        _factoryPeggedToken(toToken, metaData);
    }

    function _factoryPeggedToken(address toToken, Metadata memory metaData) internal returns (IERC20Mintable) {
        address fromToken = metaData.originAddress;
        /* if pegged token exist we can just return its address */
        if (_peggedTokenOrigin[toToken] != address(0x00)) {
            return IERC20Mintable(toToken);
        }
        /* we must use delegate call because we need to deploy new contract from bridge contract to have valid address */
        (bool success, bytes memory returnValue) = address(_bridgeRouter).delegatecall(
            abi.encodeWithSignature("factoryPeggedToken(address,address,(bytes32,bytes32,uint256,address,bytes32),address)", fromToken, toToken, metaData, address(this))
        );
        if (!success) {
            // preserving error message
            uint256 returnLength = returnValue.length;
            assembly {
                revert(add(returnValue, 0x20), returnLength)
            }
        }
        /* now we can mark this token as pegged */
        _peggedTokenOrigin[toToken] = fromToken;
        /* to token is our new pegged token */
        return IERC20Mintable(toToken);
    }

    function factoryPeggedBond(uint256 fromChain, Metadata calldata metaData) external onlyOwner override {
        // make sure this chain is supported
        require(_bridgeAddressByChainId[fromChain] != address(0x00), "bad contract");
        // calc target token
        address toToken = _bridgeRouter.peggedBondAddress(address(this), metaData.originAddress);
        require(_peggedTokenOrigin[toToken] == address(0x00), "already exists");
        // deploy new token (its just a warmup operation)
        _factoryPeggedBond(toToken, metaData);
    }

    function _factoryPeggedBond(address toToken, Metadata memory metaData) internal returns (IERC20Mintable) {
        address fromToken = metaData.originAddress;
        if (_peggedTokenOrigin[toToken] != address(0x00)) {
            return IERC20Mintable(toToken);
        }
        /* we must use delegate call because we need to deploy new contract from bridge contract to have valid address */
        (bool success, bytes memory returnValue) = address(_bridgeRouter).delegatecall(
            abi.encodeWithSignature("factoryPeggedBond(address,address,(bytes32,bytes32,uint256,address,bytes32),address,address)", fromToken, toToken, metaData, address(this), address(_internetBondRatioFeed))
        );
        if (!success) {
            // preserving error message
            uint256 returnLength = returnValue.length;
            assembly {
                revert(add(returnValue, 0x20), returnLength)
            }
        }
        /* now we can mark this token as pegged */
        _peggedTokenOrigin[toToken] = fromToken;
        /* to token is our new pegged token */
        return IERC20Mintable(toToken);
    }

    function addAllowedContract(address allowedContract, uint256 toChain) public onlyOwner {
        require(_bridgeAddressByChainId[toChain] == address(0x00), "already allowed");
        require(toChain > 0, "chain id must be positive");
        _bridgeAddressByChainId[toChain] = allowedContract;
        emit ContractAllowed(allowedContract, toChain);
    }

    function removeAllowedContract(uint256 toChain) public onlyOwner {
        require(_bridgeAddressByChainId[toChain] != address(0x00), "already disallowed");
        require(toChain > 0, "chain id must be positive");
        address wasContract = _bridgeAddressByChainId[toChain];
        delete _bridgeAddressByChainId[toChain];
        emit ContractDisallowed(wasContract, toChain);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function changeConsensus(address consensus) public onlyOwner {
        require(consensus != address(0x0), "zero address disallowed");
        _consensusAddress = consensus;
        emit ConsensusChanged(_consensusAddress);
    }

    function changeRouter(address router) public onlyOwner {
        require(router != address(0x0), "zero address disallowed");
        _bridgeRouter = BridgeRouter(router);
        // We don't have special event for router change since it's very special technical contract
        // In future changing router will be disallowed
    }
}