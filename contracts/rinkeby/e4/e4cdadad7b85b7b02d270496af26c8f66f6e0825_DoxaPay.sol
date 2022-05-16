/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

// File: @openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
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

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;



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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// File: CS_flat_flat.sol

/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

// File: all-code/doxa/SafeMath.sol



pragma solidity ^0.8.0;


library Strings {
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

// File: @openzeppelin/contracts/utils/cryptography/ECDSA.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;


/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
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
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
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

// File: @openzeppelin/contracts/utils/cryptography/draft-EIP712.sol


// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;


/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}




pragma solidity ^0.8.0;


contract whitelistChecker is EIP712 {

    string private constant SIGNING_DOMAIN = "Doxa_Pay";
    string private constant SIGNATURE_VERSION = "1";

     struct doxaPay {
        address buyerAddress;
        address sellerAddress;
        uint256  PaymentType;
        uint256 timestamp;
        bytes signature;
    }
    constructor() EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION){

    }

    function getSigner(doxaPay memory whitelist) public view returns(address){
        return _verify(whitelist);
    }

    /// @notice Returns a hash of the given whitelist, prepared using EIP712 typed data hashing rules.

function _hash(doxaPay memory whitelist) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
                keccak256("doxaPay(address buyerAddress,address sellerAddress,uint256 PaymentType,uint256 timestamp)"),
                whitelist.buyerAddress,
                whitelist.sellerAddress,
                whitelist.PaymentType,
                whitelist.timestamp
            )));
    }
    function _verify(doxaPay memory whitelist) internal view returns (address) {
        bytes32 digest = _hash(whitelist);
        return ECDSA.recover(digest, whitelist.signature);
    }

}
// File: all-code/doxa/doxa...doxa-pay.sol


pragma solidity ^0.8.0;





interface Wallet {
    function withdraw(address, string memory, uint) external;
    function walletBalanceOf(address) external view returns(uint);
    function getApproval(uint) external;
}

contract DoxaPay is OwnableUpgradeable,whitelistChecker{
   

    IERC20Upgradeable  public token;
    address adminAddress;

    IERC20Upgradeable  public usdt;
    address public signer;
    mapping(address=>mapping(uint=>bool)) public usedNonce;

    Wallet wallet;
    address walletAddress;

    struct PaymentInfo {
        uint txId;
        string paymentType;
        string mailID;
        uint timestamp;
        bool isPaidOut;
        string eventId;
        uint amount;
        string payer;
    }


    mapping(address => PaymentInfo[]) public PaymentRecords;
    mapping(string => address) public eventHostRecords;


    event Received(address indexed sender, uint indexed amount);
    event DoxaPayment(address indexed sender, PaymentInfo info);
    event ETHPayment(address indexed sender, PaymentInfo info);
    event AppWalletPayment(address indexed sender, PaymentInfo info);
    event Refund(address indexed account, PaymentInfo info);
    event USDTPayment(address indexed sender, PaymentInfo info);

    
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }


    function initialize(address admin, address _token, address _usdt, address _wallet) external initializer{
           token = IERC20Upgradeable(_token);
        usdt = IERC20Upgradeable(_usdt);
        adminAddress = admin;
        walletAddress = _wallet;
        wallet = Wallet(walletAddress);
        __Ownable_init();
        signer=msg.sender;
    }

    function setSigner(address _signer) external onlyOwner{
        signer=_signer;
    }
    /////////////////////////////////////
        //   Doxa payment     //
    ////////////////////////////////////

    function payDoxa( uint amount,string memory id, string memory eventId, string memory payer) public {
        require(token.balanceOf(address(msg.sender)) >=amount,"Insufficient token balance");
        PaymentInfo memory info;
        info.txId = totalNoOfPayments(msg.sender) + 1;
        info.paymentType = "DOXA";
        info.timestamp = block.timestamp;
        info.amount = amount;
        info.mailID = id;
        info.eventId = eventId;
        info.payer = payer;

        PaymentRecords[msg.sender].push(info);

        if(keccak256(bytes(payer)) == keccak256(bytes("host"))) {
            eventHostRecords[eventId] = msg.sender;
            token.transferFrom(msg.sender, adminAddress, amount);
        } else {
            uint fee = (amount *(10))/(100);
            address host = eventHostRecords[eventId];
            require(host != address(0), "Invalid event ID or event not created!");
            token.transferFrom(msg.sender, address(this), amount - (fee));
            token.transferFrom(msg.sender, adminAddress, fee);
        }

        emit DoxaPayment(msg.sender, info);
    }

    function totalNoOfPayments(address account) public view returns(uint) {
        return PaymentRecords[account].length;
    }

    /////////////////////////////////////
        //   ETH Payment     //
    ////////////////////////////////////

    function payETH(string memory id, string memory eventId, string memory payer) public payable {
        uint amount = msg.value;

        PaymentInfo memory info;
        info.txId = totalNoOfPayments(msg.sender) + 1;
        info.paymentType = "ETH";
        info.timestamp = block.timestamp;
        info.amount = amount;
        info.mailID = id;
        info.eventId = eventId;
        info.payer = payer;

        PaymentRecords[msg.sender].push(info);

        if(keccak256(bytes(payer)) == keccak256(bytes("host"))) {
            eventHostRecords[eventId] = msg.sender;
            payable(adminAddress).transfer(amount);
        } else {
              uint fee = (amount *(10))/(100);
            address host = eventHostRecords[eventId];
            require(host != address(0), "Invalid event ID or event not created!");
            payable(adminAddress).transfer(fee); 
            payable(address(this)).transfer(amount - (fee));        
        }

        emit ETHPayment(msg.sender, info);
    }

    /////////////////////////////////////
        //   App Wallet Payment     //
    ////////////////////////////////////

    function payUsingAppWallet(uint amount, string memory id, string memory eventId, string memory payer) public {
        require(walletBalanceOf(address(msg.sender)) >= amount,"Insufficient wallet token balance");

        PaymentInfo memory info;
        info.txId = totalNoOfPayments(msg.sender) + 1;
        info.paymentType = "APP";
        info.timestamp = block.timestamp;
        info.amount = amount;
        info.mailID = id;
        info.eventId = eventId;
        info.payer = payer;

        PaymentRecords[msg.sender].push(info);

        wallet.getApproval(amount);
        wallet.withdraw(msg.sender, id,amount);

        if(keccak256(bytes(payer)) == keccak256(bytes("host"))) {
            eventHostRecords[eventId] = msg.sender;
            token.transferFrom(walletAddress, adminAddress,amount);
        } else {
             uint fee = (amount *(10))/(100);
            address host = eventHostRecords[eventId];
            require(host != address(0), "Invalid event ID or event not created!");
            token.transferFrom(walletAddress, address(this),amount - (fee));
            token.transferFrom(walletAddress, adminAddress, fee);
        }

        emit AppWalletPayment(msg.sender, info);
    }

    function setTokenAddress(address _addr) public onlyOwner {
        token = IERC20Upgradeable(address(_addr));
    }

    function setUsdtAddress(address _addr) public onlyOwner {
        usdt = IERC20Upgradeable(address(_addr));
    }


    function walletBalanceOf(address _addr) public view returns(uint) {
        return wallet.walletBalanceOf(_addr);
    }

    function setWalletInstance(address _addr) public onlyOwner {
        wallet = Wallet(_addr);
    }

    function claimEventAmount(uint txID,doxaPay memory _payment) public {
        require(!usedNonce[msg.sender][_payment.timestamp],"used Nonce");
        require(getSigner(_payment)==signer,"!signer");

        require(keccak256(bytes(PaymentRecords[msg.sender][txID - 1].payer)) == keccak256(bytes("host")));
        require(PaymentRecords[msg.sender][txID - 1].isPaidOut == false);
         usedNonce[msg.sender][_payment.timestamp]=true;

        PaymentRecords[msg.sender][txID - 1].isPaidOut = true;
        PaymentInfo memory info = PaymentRecords[msg.sender][txID - 1];

        uint amount = (info.amount) - ((info.amount)/(10));

        if(keccak256(bytes(info.paymentType)) == keccak256(bytes("ETH"))) {
            payable(msg.sender).transfer(amount);
        } else {
            token.transfer(msg.sender, amount);
        }
    }

    function contractETHBalance() public view returns(uint) {
        return address(this).balance;
    }



    function payUSDT(uint amount, string memory id, string memory eventId, string memory payer) public {
        amount = amount /(10 ** 12);
        require(usdt.balanceOf(address(msg.sender)) >= amount,"Insufficient token balance");

        PaymentInfo memory info;
        info.txId = totalNoOfPayments(msg.sender) + 1;
        info.paymentType = "USDT";
        info.timestamp = block.timestamp;
        info.amount = amount;
        info.mailID = id;
        info.eventId = eventId;
        info.payer = payer;

        PaymentRecords[msg.sender].push(info);

        if(keccak256(bytes(payer)) == keccak256(bytes("host"))) {
            eventHostRecords[eventId] = msg.sender;
            usdt.transferFrom(msg.sender, adminAddress, amount);
        } else {
            uint fee = (amount/(10))/(100);
            address host = eventHostRecords[eventId];
            require(host != address(0), "Invalid event ID or event not created!");
            usdt.transferFrom(msg.sender, address(this), amount - (fee));
            usdt.transferFrom(msg.sender, adminAddress, fee);
        }

        emit USDTPayment(msg.sender, info);
    }








    //////////////////.......................Escrow payment..........................///////////////

    event DoxaEscrowPayment(address indexed sender, string userId, EscrowInfo escrow);
    event ETHEscrowPayment(address indexed sender, string userId, EscrowInfo escrow);
    event AppWalletEscrowPayment(address indexed sender, string userId, EscrowInfo escrow);
    event Refund(address indexed account, string userId, EscrowInfo escrow);
    event USDTEscrowPayment(address indexed sender, string userId, EscrowInfo escrow);
    event EscrowPaymentRelease(EscrowInfo escrow, string userId);

    struct EscrowInfo {
        string id;
        address buyer;
        address seller;
        uint paymentType;
        uint amount;
        bool isDisputed;
        bool isReleased;
    }

    mapping(string => EscrowInfo) public EscrowRecords;

    modifier notDisputed(string memory id) {
        require(!EscrowRecords[id].isDisputed, "Escrow in dispute state!");
        _;
    }

    function escrowPayETH(string memory id,doxaPay memory _payment, string memory userId) public payable {
        escrowPayment(id,userId,msg.value,_payment);
    }

    function escrowPayment(string memory _id, string memory userId, uint256 _amount , doxaPay memory _escrow) public {
        require(!usedNonce[msg.sender][_escrow.timestamp],"Nonce : Invalid Nonce");
        require (getSigner(_escrow) == signer,'!Signer');
        usedNonce[msg.sender][_escrow.timestamp] = true;
        require(_amount > 0, "Amount should be greated than 0");
        require(!isExist(_id), "Escrow for the given ID already exist");
        EscrowInfo memory escrow;

        escrow.id = _id;
        escrow.buyer = _escrow.buyerAddress;
        escrow.seller = _escrow.sellerAddress;
        escrow.paymentType = _escrow.PaymentType;
        escrow.isReleased = false;
        escrow.amount = _amount;

        EscrowRecords[_id] = escrow;

        if(_escrow.PaymentType == 0) {
            emit ETHEscrowPayment(msg.sender,userId, escrow);
            return;
        }

        if(_escrow.PaymentType == 1) {
            require(token.balanceOf(_escrow.buyerAddress) > _amount, "Insufficient Balance");
            token.transferFrom(_escrow.buyerAddress, address(this), _amount);
            emit DoxaEscrowPayment(_escrow.buyerAddress, userId, escrow);
            return;
        }

        if(_escrow.PaymentType == 2) {
            wallet.getApproval(_amount);
            wallet.withdraw(_escrow.buyerAddress, _id, _amount);
            token.transferFrom(walletAddress, address(this), _amount);
            emit AppWalletEscrowPayment(_escrow.buyerAddress, userId, escrow);
            return;
        }

        if(_escrow.PaymentType == 3) {
            require(usdt.balanceOf(_escrow.buyerAddress) > _amount, "Insufficient Balance");
            usdt.transferFrom(_escrow.buyerAddress, address(this), _amount);
            emit USDTEscrowPayment(_escrow.buyerAddress,userId, escrow);
            return;
        }

        return;
    }


    function releaseEscrowPayment(string memory id, uint releaseTo, string memory userId) public {
        EscrowInfo memory escrow = EscrowRecords[id];
        require(!escrow.isReleased, "Escrow amount already released!");
        if(msg.sender != adminAddress) {
            require(msg.sender == escrow.buyer, "Only buyer can release payment");
        }
        EscrowRecords[id].isReleased = true;

        uint paymentType = escrow.paymentType;
        address activeAddress;
        if(releaseTo == 1) {
            activeAddress = escrow.buyer;
        } else {
            activeAddress = escrow.seller;
        }

        require(msg.sender != activeAddress, "Operation not allowed");

        uint feeAmount = ((escrow.amount)*2)/(100);
        uint feeDeductedAmount = (escrow.amount)-(feeAmount);
        if(paymentType == 0) {
            payable(activeAddress).transfer(feeDeductedAmount);
            payable(adminAddress).transfer(feeAmount);
            emit EscrowPaymentRelease(escrow, userId);
            return;
        }

        if(paymentType == 1 || paymentType == 2) {
            token.transfer(activeAddress, feeDeductedAmount);
            token.transfer(adminAddress, feeAmount);
            emit EscrowPaymentRelease(escrow, userId);
            return;
        }

        if(paymentType == 3) {
            usdt.transfer(activeAddress, feeDeductedAmount);
            usdt.transfer(adminAddress, feeAmount);
            emit EscrowPaymentRelease(escrow, userId);
            return;
        }

    }

    function isExist(string memory id) public view returns(bool) {
        return EscrowRecords[id].amount > 0;
    }

    // function raiseDispute(string memory id) public {
    //     EscrowInfo memory escrow = EscrowRecords[id];
    //     require(isExist(id), "The escorw with the given is doesn't exist");
    //     require(!escrow.isReleased, "Payment already released");
    //     require(msg.sender == escrow.buyer || msg.sender == escrow.seller, "Not a seller or buyer");
    //     EscrowRecords[id].isDisputed = true;
    // }

    function releaseDisputePayment(string memory id, uint releaseTo, string memory userId) public onlyOwner {
        //require(EscrowRecords[id].isDisputed, "Escrow not in disputed state");
        // EscrowRecords[id].isDisputed = false;
        releaseEscrowPayment(id, releaseTo, userId);
    }


}