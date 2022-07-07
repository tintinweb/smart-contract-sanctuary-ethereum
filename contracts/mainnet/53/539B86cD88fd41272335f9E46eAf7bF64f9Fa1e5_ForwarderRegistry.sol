/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

// Sources flattened with hardhat v2.9.9 https://hardhat.org

// File contracts/metatx/interfaces/IForwarderRegistry.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title Universal Meta-Transactions Forwarder Registry.
/// @dev Derived from https://github.com/wighawag/universal-forwarder (MIT licence)
interface IForwarderRegistry {
    /// @notice Checks whether an account is as a meta-transaction forwarder for a signer account.
    /// @param forwarder The signer account.
    /// @param forwarder The forwarder account.
    /// @return isForwarder True if `forwarder` is a meta-transaction forwarder for `signer`, false otherwise.
    function isForwarderFor(address signer, address forwarder) external view returns (bool isForwarder);
}


// File contracts/metatx/interfaces/IERC2771.sol
pragma solidity ^0.8.8;

/// @title Secure Protocol for Native Meta Transactions.
/// @dev See https://eips.ethereum.org/EIPS/eip-2771
interface IERC2771 {
    /// @notice Checks whether a forwarder is trusted.
    /// @param forwarder The forwarder to check.
    /// @return isTrusted True if `forwarder` is trusted, false if not.
    function isTrustedForwarder(address forwarder) external view returns (bool isTrusted);
}


// File contracts/cryptography/interfaces/IERC1271.sol
pragma solidity ^0.8.8;

/// @title Standard Signature Validation Method for Contracts.
/// @dev See https://eips.ethereum.org/EIPS/eip-1271
/// @dev Note: This interface uses the initial version of ERC1271, which was later updated to use the same function signature as ERC1654.
interface IERC1271 {
    /// @notice Returns whether the signature is valid for the data.
    /// @param data The signed data.
    /// @param signature The signature for `data`.
    /// @return magicValue `0x20c13b0b` if the signature is valid, else any other value.
    function isValidSignature(bytes calldata data, bytes memory signature) external view returns (bytes4 magicValue);
}


// File contracts/cryptography/interfaces/IERC1654.sol
pragma solidity ^0.8.8;

/// @title Dapp-wallet authentication process with contract wallets support.
/// @dev See https://eips.ethereum.org/EIPS/eip-1271
/// @dev This interface is used in the final version of ERC1271.
interface IERC1654 {
    /// Returns whether the signature is valid for the data hash.
    /// @param hash The hash of the signed data.
    /// @param signature The signature for `hash`.
    /// @return magicValue `0x1626ba7e` if the signature is valid, else any other value.
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}


// File contracts/metatx/libraries/ERC2771Data.sol
pragma solidity ^0.8.8;

/// @dev Derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT licence)
/// @dev See https://eips.ethereum.org/EIPS/eip-2771
library ERC2771Data {
    /// @notice Returns the sender address appended at the end of the calldata, as specified in ERC2771.
    function msgSender() internal pure returns (address sender) {
        assembly {
            sender := shr(96, calldataload(sub(calldatasize(), 20)))
        }
    }

    /// @notice Returns the calldata omitting the appended sender address, as specified in ERC2771.
    function msgData() internal pure returns (bytes calldata data) {
        return msg.data[:msg.data.length - 20];
    }
}


// File @openzeppelin/contracts/utils/[email protected]
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


// File @openzeppelin/contracts/utils/[email protected]
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}


// File @openzeppelin/contracts/utils/cryptography/[email protected]
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

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
            /// @solidity memory-safe-assembly
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
            /// @solidity memory-safe-assembly
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


// File contracts/metatx/ForwarderRegistry.sol
pragma solidity 0.8.15;







/// @title Universal Meta-Transactions Forwarder Registry.
/// @notice Users can allow specific forwarders to forward meta-transactions on their behalf.
/// @dev Derived from https://github.com/wighawag/universal-forwarder (MIT licence)
contract ForwarderRegistry is IForwarderRegistry, IERC2771 {
    using Address for address;
    using ECDSA for bytes32;

    enum SignatureType {
        DIRECT,
        EIP1654,
        EIP1271
    }

    struct Forwarder {
        uint248 nonce;
        bool approved;
    }

    bytes4 internal constant ERC1271_MAGICVALUE = 0x20c13b0b;
    bytes4 internal constant ERC1654_MAGICVALUE = 0x1626ba7e;

    bytes32 internal constant EIP712DOMAIN_NAME = keccak256("ForwarderRegistry");
    bytes32 internal constant APPROVAL_TYPEHASH = keccak256("ApproveForwarder(address forwarder,bool approved,uint256 nonce)");

    mapping(address => mapping(address => Forwarder)) internal _forwarders;

    uint256 private immutable _deploymentChainId;
    bytes32 private immutable _deploymentDomainSeparator;

    /// @notice Emitted when a forwarder is approved or disapproved.
    /// @param signer The account for which `forwarder` is approved or disapproved.
    /// @param forwarder The account approved or disapproved as forwarder.
    /// @param approved True for an approval, false for a disapproval.
    /// @param nonce The `signer`'s account nonce before the approval change.
    event ForwarderApproved(address indexed signer, address indexed forwarder, bool approved, uint256 nonce);

    constructor() {
        uint256 chainId;
        //solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
        _deploymentChainId = chainId;
        _deploymentDomainSeparator = _calculateDomainSeparator(chainId);
    }

    /// @notice Approves or disapproves a forwarder for the sender.
    /// @param forwarder The address of the forwarder to change the approval of.
    /// @param approved Whether to approve or disapprove (if previously approved) the forwarder.
    function approveForwarder(address forwarder, bool approved) external {
        address signer = msg.sender;
        Forwarder storage forwarderData = _forwarders[signer][forwarder];
        _approveForwarder(forwarderData, signer, forwarder, approved, forwarderData.nonce);
    }

    /// @notice Approves or disapproves a forwarder using EIP-2771 (msg.sender is the forwarder and the approval signer is appended to the calldata).
    /// @param approved Whether to approve or disapprove (if previously approved) the forwarder.
    /// @param signature Signature by signer for approving forwarder.
    /// @param signatureType The signature type.
    function approveForwarder(
        bool approved,
        bytes calldata signature,
        SignatureType signatureType
    ) external {
        address signer = ERC2771Data.msgSender();
        address forwarder = msg.sender;

        Forwarder storage forwarderData = _forwarders[signer][forwarder];
        uint256 nonce = uint256(forwarderData.nonce);

        _requireValidSignature(signer, forwarder, approved, nonce, signature, signatureType);
        _approveForwarder(forwarderData, signer, forwarder, approved, nonce);
    }

    /// @notice Forwards the meta-transaction (assuming the caller has been approved by the signer as a forwarder).
    /// @param target The destination of the call (that will receive the meta-transaction).
    /// @param data The content of the call (the signer address will be appended to it according to EIP-2771).
    function forward(address target, bytes calldata data) external payable {
        address signer = ERC2771Data.msgSender();
        require(_forwarders[signer][msg.sender].approved, "NOT_AUTHORIZED_FORWARDER");
        target.functionCallWithValue(abi.encodePacked(data, signer), msg.value);
    }

    /// @notice Approves the forwarder and forwards the meta-transaction.
    /// @param signature Signature by the signer for approving the forwarder.
    /// @param target The destination of the call (that will receive the meta-transaction).
    /// @param data The content of the call (the signer address will be appended to it according to EIP-2771).
    function approveAndForward(
        bytes calldata signature,
        SignatureType signatureType,
        address target,
        bytes calldata data
    ) external payable {
        address signer = ERC2771Data.msgSender();
        address forwarder = msg.sender;

        Forwarder storage forwarderData = _forwarders[signer][forwarder];
        uint256 nonce = uint256(forwarderData.nonce);

        _requireValidSignature(signer, forwarder, true, nonce, signature, signatureType);
        _approveForwarder(forwarderData, signer, forwarder, true, nonce);

        target.functionCallWithValue(abi.encodePacked(data, signer), msg.value);
    }

    /// @notice Checks the signed approval (but does not record it) and forwards the meta-transaction.
    /// @param signature Signature by the signer for approving the forwarder.
    /// @param target The destination of the call (that will receive the meta-transaction).
    /// @param data The content of the call (the signer address will be appended to it according to EIP-2771).
    function checkApprovalAndForward(
        bytes calldata signature,
        SignatureType signatureType,
        address target,
        bytes calldata data
    ) external payable {
        address signer = ERC2771Data.msgSender();
        address forwarder = msg.sender;
        _requireValidSignature(signer, forwarder, true, uint256(_forwarders[signer][forwarder].nonce), signature, signatureType);
        target.functionCallWithValue(abi.encodePacked(data, signer), msg.value);
    }

    /// @notice Gets the ERC1271 DOMAIN_SEPARATOR.
    /// @return domainSeparator The ERC1271 domain separator.
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32 domainSeparator) {
        return _DOMAIN_SEPARATOR();
    }

    /// @notice Gets the current nonce for the signer/forwarder pair.
    /// @param signer The signer account.
    /// @param forwarder The forwarder account.
    /// @return nonce The current nonce for the `signer`/`forwarder` pair.
    function getNonce(address signer, address forwarder) external view returns (uint256 nonce) {
        return uint256(_forwarders[signer][forwarder].nonce);
    }

    /// @inheritdoc IForwarderRegistry
    function isForwarderFor(address signer, address forwarder) external view override returns (bool) {
        return forwarder == address(this) || _forwarders[signer][forwarder].approved;
    }

    /// @inheritdoc IERC2771
    function isTrustedForwarder(address) external pure override returns (bool) {
        return true;
    }

    function _requireValidSignature(
        address signer,
        address forwarder,
        bool approved,
        uint256 nonce,
        bytes memory signature,
        SignatureType signatureType
    ) internal view {
        bytes memory data = abi.encodePacked("\x19\x01", _DOMAIN_SEPARATOR(), keccak256(abi.encode(APPROVAL_TYPEHASH, forwarder, approved, nonce)));
        if (signatureType == SignatureType.EIP1271) {
            require(IERC1271(signer).isValidSignature(data, signature) == ERC1271_MAGICVALUE, "SIGNATURE_1271_INVALID");
        } else if (signatureType == SignatureType.EIP1654) {
            require(IERC1654(signer).isValidSignature(keccak256(data), signature) == ERC1654_MAGICVALUE, "SIGNATURE_1654_INVALID");
        } else {
            address actualSigner = keccak256(data).recover(signature);
            require(signer == actualSigner, "SIGNATURE_WRONG_SIGNER");
        }
    }

    function _approveForwarder(
        Forwarder storage forwarderData,
        address signer,
        address forwarder,
        bool approved,
        uint256 nonce
    ) internal {
        forwarderData.approved = approved;
        unchecked {
            forwarderData.nonce = uint248(nonce + 1);
        }
        emit ForwarderApproved(signer, forwarder, approved, nonce);
    }

    // solhint-disable-next-line func-name-mixedcase
    function _DOMAIN_SEPARATOR() private view returns (bytes32) {
        uint256 chainId;
        //solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }

        // in case a fork happens, to support the chain that had to change its chainId, we compue the domain operator
        return chainId == _deploymentChainId ? _deploymentDomainSeparator : _calculateDomainSeparator(chainId);
    }

    function _calculateDomainSeparator(uint256 chainId) private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)"),
                    EIP712DOMAIN_NAME,
                    chainId,
                    address(this)
                )
            );
    }
}