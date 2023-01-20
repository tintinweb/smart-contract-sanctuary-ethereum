/**
 *Submitted for verification at Etherscan.io on 2023-01-20
*/

// File: openzeppelin-solidity/contracts/utils/Strings.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
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

// File: openzeppelin-solidity/contracts/utils/cryptography/ECDSA.sol


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

// File: openzeppelin-solidity/contracts/utils/Context.sol


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

// File: contracts/SignatureBouncer.sol



pragma solidity ^0.8.0;

/**
 * @title SignatureBouncer
 * @author PhABC, Shrugs and aflesher
 * @dev SignatureBouncer allows users to submit a signature as a permission to
 * do an action.
 * If the signature is from one of the authorized signer addresses, the
 * signature is valid.
 * Note that SignatureBouncer offers no protection against replay attacks, users
 * must add this themselves!
 *
 * Signer addresses can be individual servers signing grants or different
 * users within a decentralized club that have permission to invite other
 * members. This technique is useful for whitelists and airdrops; instead of
 * putting all valid addresses on-chain, simply sign a grant of the form
 * keccak256(abi.encodePacked(`:contractAddress` + `:granteeAddress`)) using a
 * valid signer address.
 * Then restrict access to your crowdsale/whitelist/airdrop using the
 * `onlyValidSignature` modifier (or implement your own using _isValidSignature).
 * In addition to `onlyValidSignature`, `onlyValidSignatureAndMethod` and
 * `onlyValidSignatureAndData` can be used to restrict access to only a given
 * method or a given method with given parameters respectively.
 * See the tests in SignatureBouncer.test.js for specific usage examples.
 *
 * @notice A method that uses the `onlyValidSignatureAndData` modifier must make
 * the _signature parameter the "last" parameter. You cannot sign a message that
 * has its own signature in it so the last 128 bytes of msg.data (which
 * represents the length of the _signature data and the _signature data itself)
 * is ignored when validating. Also non fixed sized parameters make constructing
 * the data in the signature much more complex.
 * See https://ethereum.stackexchange.com/a/50616 for more details.
 */
contract SignatureBouncer is Context {
    using ECDSA for bytes32;

    // Function selectors are 4 bytes long, as documented in
    // https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector
    uint256 private constant _METHOD_ID_SIZE = 4;
    // Signature size is 65 bytes (tightly packed v + r + s), but gets padded to 96 bytes
    uint256 private constant _SIGNATURE_SIZE = 96;
    // Address with the signer role
    address public signer;

    /**
     * @dev Sets the value for {signer}.
     * This value is immutable: it can only be set once during construction.
     */
    constructor(address _signer) {
        signer = _signer;
    }

    /**
     * @dev Requires that a valid signature with a specified method and params of a signer was provided.
     */
    modifier onlyValidSignatureAndData(bytes memory signature) {
        // solhint-disable-next-line max-line-length
        require(_isValidSignatureAndData(_msgSender(), signature), "SignatureBouncer: invalid signature for caller and data");
        _;
    }

    /**
     * @dev is the signature of `this + account + methodId + params(s)` from a signer?
     * @notice the signature parameter of the method being validated must be the "last" parameter
     * @return bool
     */
    function _isValidSignatureAndData(address account, bytes memory signature) internal view returns (bool) {
        bytes memory msgData = _msgData();
        require(msgData.length > _SIGNATURE_SIZE, "SignatureBouncer: data is too short");

        bytes memory data = new bytes(msgData.length - _SIGNATURE_SIZE);
        for (uint256 i = 0; i < data.length; i++) {
            data[i] = msgData[i];
        }

        return _isValidDataHash(keccak256(abi.encodePacked(address(this), account, data)), signature);
    }

    /**
     * @dev Internal function to convert a hash to an eth signed message
     * and then recover the signature and check it against the signer role.
     * @return bool
     */
    function _isValidDataHash(bytes32 hash, bytes memory signature) internal view returns (bool) {
        address _signer = hash.toEthSignedMessageHash().recover(signature);

        return _signer != address(0) && isSigner(_signer);
    }

    /**
     * @dev Public function to check if given address has the signer role.
     * @return bool
     */
    function isSigner(address account) public view returns (bool) {
        return signer == account;
    }
}

// File: openzeppelin-solidity/contracts/access/Ownable.sol


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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// File: openzeppelin-solidity/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}

// File: openzeppelin-solidity/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// File: contracts/Controller.sol



pragma solidity ^0.8.0;

/**
 * @title Controller
 * @dev Contract used by controllers.
 */
contract Controller is Ownable, Pausable, SignatureBouncer {
    using Address for address;

    mapping(bytes => bool) private signatures;

    /**
     * @dev Requires that a valid `signature` and `timestamp` were provided.
     */
    modifier onlyValidSignatureAndTimestamp(bytes calldata signature, uint256 timestamp) {
        require(!paused(), "Controller: signatures usage is paused");
        require(!wasSignatureUsed(signature), "Controller: signature was already used");
        require(_isValidSignatureAndData(_msgSender(), signature), "Controller: invalid signature for caller and data");
        require(timestamp > block.timestamp - 1 hours, "Controller: outdated timestamp");
        require(timestamp < block.timestamp + 1 hours, "Controller: premature timestamp");
        _;
    }

    /**
     * @dev Sets the `signer` address.
     */
    constructor(address signer) SignatureBouncer(signer) {
        require(signer != address(0), "Controller: signer must be a valid address");
        require(!signer.isContract(), "Controller: signer cannot be a contract");
    }

    /**
     * @dev Marks `signature` as used.
     */
    function _markSignatureAsUsed(bytes calldata signature) internal {
        signatures[signature] = true;
    }

    /**
     * @dev Marks signatures usage as disabled.
     */
    function pauseSignatures() onlyOwner external {
        _pause();
    }

    /**
     * @dev Marks signatures usage as enabled.
     */
    function unpauseSignatures() onlyOwner external {
        _unpause();
    }

    /**
     * @dev Returns true it the `signature` was already used.
     */
    function wasSignatureUsed(bytes calldata signature) public view returns (bool) {
        return signatures[signature];
    }
}

// File: contracts/Controllable.sol



pragma solidity ^0.8.0;

/**
 * @title Controllable
 * @dev Contract used for handling controllers.
 */
contract Controllable is Ownable {
    using Address for address;

    address public controller;

    event ControllerChanged(address indexed controller);

    /**
     * @dev Throws if called by any account other than the controller.
     */
    modifier onlyController() {
        require(_msgSender() == controller, "Controllable: caller is not the controller");
        _;
    }

    /**
     * @dev Sets address of the controller to `newController`.
     */
    function setController(address newController) external onlyOwner {
        require(newController != controller, "Controllable: new value is the same");
        require(newController != address(0), "Controllable: controller must be a valid address");
        require(newController.isContract(), "Controllable: controller must be a contract");

        controller = newController;

        emit ControllerChanged(controller);
    }
}

// File: openzeppelin-solidity/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: openzeppelin-solidity/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: openzeppelin-solidity/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: openzeppelin-solidity/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File: openzeppelin-solidity/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: openzeppelin-solidity/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: contracts/TreasurerWallet.sol



pragma solidity ^0.8.0;

/**
 * @title TreasurerWallet
 * @dev Contract that keeps tokens.
 */
contract TreasurerWallet is Controllable, ERC165, IERC721Receiver, IERC1155Receiver {
    using Address for address;

    bool public isLocked = false;

    event MigrationStarted();
    event ERC721Received(address indexed token, uint256 indexed identifier);
    event ERC1155Received(address indexed token, uint256 indexed identifier, uint256 indexed amount);
    event ERC1155BatchReceived(address indexed token, uint256[] indexed identifiers, uint256[] indexed amounts);
    event ERC721Withdrawal(address indexed token, uint256 indexed identifier, address indexed beneficiary);
    event ERC1155Withdrawal(address indexed token, uint256 indexed identifier, uint256 indexed amount, address beneficiary);
    event ERC1155BatchWithdrawal(address indexed token, uint256[] indexed identifiers, uint256[] indexed amounts, address beneficiary);

    /**
     * @dev Throws if called after the contract was locked.
     */
    modifier onlyUnlocked() {
        require(controller != address(0), "TreasurerWallet: controller was not set yet");
        require(!isLocked, "TreasurerWallet: wallet is already locked");
        _;
    }

    /**
     * @dev Starts tokens migration.
     */
    function startMigration() external onlyUnlocked onlyOwner {
        require(!isLocked, "TreasurerWallet: migration has already started");

        isLocked = true;

        emit MigrationStarted();
    }

    /**
     * @dev Allows to migrate ERC721 tokens to new wallet address by the owner.
     */
    function migrateERC721(address[] calldata tokens, uint256[] calldata identifiers, address wallet) external onlyOwner {
        require(isLocked, "TreasurerWallet: migration has not started yet");
        require(wallet.isContract(), "TreasurerWallet: new wallet must be a contract");
        require(tokens.length == identifiers.length, "TreasurerWallet: length of tokens and identifiers must be the same");

        for (uint256 i = 0; i < tokens.length; ++i) {
            IERC721(tokens[i]).safeTransferFrom(address(this), wallet, identifiers[i], "");
        }
    }

    /**
     * @dev Allows to migrate ERC1155 tokens to new wallet address by the owner.
     */
    function migrateERC1155(address[] calldata tokens, uint256[] calldata identifiers, uint256[] calldata amounts, address wallet) external onlyOwner {
        require(isLocked, "TreasurerWallet: migration has not started yet");
        require(wallet.isContract(), "TreasurerWallet: new wallet must be a contract");
        require(tokens.length == identifiers.length, "TreasurerWallet: length of tokens and identifiers must be the same");
        require(identifiers.length == amounts.length, "TreasurerWallet: length of identifiers and amounts must be the same");

        for (uint256 i = 0; i < tokens.length; ++i) {
            require(amounts[i] > 0, "TreasurerWallet: amount must be greater than zero");

            IERC1155(tokens[i]).safeTransferFrom(address(this), wallet, identifiers[i], amounts[i], "");
        }
    }

    /**
     * @dev Allows to withdraw ERC721 token by the controller.
     */
    function withdrawERC721(address token, uint256 identifier, address beneficiary) external onlyUnlocked onlyController {
        require(beneficiary != address(0), "TreasurerWallet: withdrawal to the zero address");

        IERC721(token).safeTransferFrom(address(this), beneficiary, identifier, "");

        emit ERC721Withdrawal(token, identifier, beneficiary);
    }

    /**
     * @dev Allows to withdraw ERC1155 token by the controller.
     */
    function withdrawERC1155(address token, uint256 identifier, uint256 amount, address beneficiary) external onlyUnlocked onlyController {
        require(beneficiary != address(0), "TreasurerWallet: withdrawal to the zero address");
        require(amount > 0, "TreasurerWallet: amount must be greater than zero");

        IERC1155(token).safeTransferFrom(address(this), beneficiary, identifier, amount, "");

        emit ERC1155Withdrawal(token, identifier, amount, beneficiary);
    }

    /**
     * @dev Allows to withdraw multiple ERC1155 tokens by the controller.
     */
    function withdrawERC1155Batch(address token, uint256[] calldata identifiers, uint256[] calldata amounts, address beneficiary) external onlyUnlocked onlyController {
        require(beneficiary != address(0), "TreasurerWallet: withdrawal to the zero address");
        require(identifiers.length > 0, "TreasurerWallet: at least one identifier is requiredt");
        require(identifiers.length == amounts.length, "TreasurerWallet: length of identifiers and amounts must be the same");

        IERC1155(token).safeBatchTransferFrom(address(this), beneficiary, identifiers, amounts, "");

        emit ERC1155BatchWithdrawal(token, identifiers, amounts, beneficiary);
    }

    /**
     * @dev Emits event when ERC721 tokens are received.
     */
    function onERC721Received(address, address, uint256 identifier, bytes calldata) external override returns (bytes4) {
        if (isLocked) {
            return "";
        }

        emit ERC721Received(_msgSender(), identifier);

        return this.onERC721Received.selector;
    }

    /**
     * @dev Emits event when ERC1155 tokens are received.
     */
    function onERC1155Received(address, address, uint256 identifier, uint256 amount, bytes calldata) external override returns (bytes4) {
        if (isLocked) {
            return "";
        }

        emit ERC1155Received(_msgSender(), identifier, amount);

        return this.onERC1155Received.selector;
    }

    /**
     * @dev Emits event when ERC1155 tokens are received.
     */
    function onERC1155BatchReceived(address, address, uint256[] calldata identifiers, uint256[] calldata amounts, bytes calldata) external override returns (bytes4) {
        if (isLocked) {
            return "";
        }

        emit ERC1155BatchReceived(_msgSender(), identifiers, amounts);

        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev Returns true if `interfaceId` is supported.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721Receiver).interfaceId || interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// File: contracts/TreasurerController.sol



pragma solidity ^0.8.0;

/**
 * @title TreasurerController
 * @dev Contract that manages tokens.
 */
contract TreasurerController is Controller {
    using Address for address;

    address private _wallet;

    event ERC721Withdrawal(address indexed token, uint256 Identifier, address indexed beneficiary, bytes signature);
    event ERC115Withdrawal(address indexed token, uint256 Identifier, uint256 indexed amount, address indexed beneficiary, bytes signature);
    event ERC1155BatchWithdrawal(address indexed token, uint256[] indexed Identifiers, address indexed beneficiary, bytes signature);
    event MixedBatchWithdrawalMixedBatch(address[] indexed tokens, uint256[] indexed identifiers, uint16[] indexed standards, address beneficiary, bytes signature);

    /**
     * @dev Sets wallet and signer addresses.
     */
    constructor(address wallet, address signer) Controller(signer) {
        require(wallet != address(0), "TreasurerController: wallet must be a valid address");
        require(wallet.isContract(), "TreasurerController: wallet must be a contract");

        _wallet = wallet;
    }

    /**
     * @dev Allows to withdraw ERC721 token by the bearer of valid signature.
     */
    function withdrawERC721(address token, uint256 identifier, address beneficiary, uint256 timestamp, bytes calldata signature) external onlyValidSignatureAndTimestamp(signature, timestamp) {
        require(beneficiary != address(0), "TreasurerController: withdrawal to the zero address");

        _markSignatureAsUsed(signature);

        TreasurerWallet(_wallet).withdrawERC721(token, identifier, beneficiary);

        emit ERC721Withdrawal(token, identifier, beneficiary, signature);
    }

    /**
     * @dev Allows to withdraw ERC1155 token by the bearer of valid signature.
     */
    function withdrawERC1155(address token, uint256 identifier, uint256 amount, address beneficiary, uint256 timestamp, bytes calldata signature) external onlyValidSignatureAndTimestamp(signature, timestamp) {
        require(beneficiary != address(0), "TreasurerController: withdrawal to the zero address");
        require(amount > 0, "TreasurerController: amount must be greater than zero");

        _markSignatureAsUsed(signature);

        TreasurerWallet(_wallet).withdrawERC1155(token, identifier, amount, beneficiary);

        emit ERC115Withdrawal(token, identifier, amount, beneficiary, signature);
    }

    /**
     * @dev Allows to withdraw multiple ERC1155 tokens by the bearer of valid signature.
     */
    function withdrawERC1155Batch(address token, uint256[] calldata identifiers, uint256[] calldata amounts, address beneficiary, uint256 timestamp, bytes calldata signature) external onlyValidSignatureAndTimestamp(signature, timestamp) {
        require(beneficiary != address(0), "TreasurerController: withdrawal to the zero address");
        require(identifiers.length > 0, "TreasurerController: at least one identifier is required");
        require(identifiers.length == amounts.length, "TreasurerController: length of identifiers and amounts must be the same");

        _markSignatureAsUsed(signature);

        for (uint256 i = 0; i < identifiers.length; ++i) {
            require(amounts[i] > 0, "TreasurerController: amount must be greater than zero");
        }

        TreasurerWallet(_wallet).withdrawERC1155Batch(token, identifiers, amounts, beneficiary);

        emit ERC1155BatchWithdrawal(token, identifiers, beneficiary, signature);
    }

    /**
     * @dev Allows to withdraw multiple tokens by the bearer of valid `signature`.
     */
    function withdrawMixedBatch(address[] memory tokens, uint256[] memory identifiers, uint256[] calldata amounts, uint16[] calldata standards, address beneficiary, uint256 timestamp, bytes calldata signature) external onlyValidSignatureAndTimestamp(signature, timestamp) {
        require(beneficiary != address(0), "TreasurerController: withdrawal to the zero address");
        require(tokens.length > 1, "TreasurerController: at least two tokens are required");
        require(tokens.length == identifiers.length, "TreasurerController: list lengths must match");
        require(tokens.length == amounts.length, "TreasurerController: list lengths must match");
        require(tokens.length == standards.length, "TreasurerController: list lengths must match");

        _markSignatureAsUsed(signature);

        for (uint256 i = 0; i < tokens.length; ++i) {
            require(standards[i] == 721 || standards[i] == 1155, "TreasurerController: invalid standard");

            if (standards[i] == 721) {
                TreasurerWallet(_wallet).withdrawERC721(tokens[i], identifiers[i], beneficiary);
            } else if (standards[i] == 1155) {
                require(amounts[i] > 0, "TreasurerController: amount must be greater than zero");

                TreasurerWallet(_wallet).withdrawERC1155(tokens[i], identifiers[i], amounts[i], beneficiary);
            }
        }

        emit MixedBatchWithdrawalMixedBatch(tokens, identifiers, standards, beneficiary, signature);
    }
}