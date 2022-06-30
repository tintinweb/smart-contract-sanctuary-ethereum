// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

import "./interfaces/IRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    function trustedForwarder() public virtual view returns (address){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal virtual view returns (bytes calldata);

    function versionRecipient() external virtual view returns (string memory);
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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

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
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
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
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";
import "./library/math/Rebase.sol";
import "./library/math/PercentageMath.sol";
import "./library/configuration/PairConfiguration.sol";
import "./interfaces/IXVault.sol";
import "./interfaces/IXPair.sol";
import "./interfaces/IPriceOracleAggregator.sol";
import "./interfaces/IERC20Details.sol";

abstract contract XPairStorageV1 is IXPair, EIP712Upgradeable {
    // @dev name
    string public name = "xPair";

    /// @dev version
    string public version = "1";

    /// @dev pair interest accrue info
    PairAccrueInfo public pairAccrueInfo;

    /// @notice The pair collateral asset
    IERC20 public override collateral;

    /// @notice settlement general settlement data
    Settlement public settlementInfo;

    /// @notice total borrow
    /// elastic = Total token amount to be repayed by borrowers,
    /// base = Total parts of the debt held by borrowers
    Rebase public override totalBorrow;

    /// @notice total collateral
    uint256 public totalCollateral;

    /// @dev pair configuration data
    Config internal configuration;

    /// @notice configurator, allowed to perform admin functions
    address public configurator;

    /// @notice user collateral
    mapping(address => uint256) public override userCollateral;

    /// @notice user borrow share
    mapping(address => uint256) public override userBorrowShare;

    /// @dev user borrow allowances
    mapping(address => mapping(address => uint256)) public borrowAllowances;

    /// @notice user borrow allowance nonce
    mapping(address => uint256) public userBorrowAllowanceNonce;
}

contract XPair is XPairStorageV1 {
    using SafeERC20 for IERC20;
    using RebaseLibrary for Rebase;
    using PercentageMath for uint256;
    using SafeCast for uint256;
    using PairConfiguration for Config;
    using Address for address;

    /// @dev delegate borrow message digest
    bytes32 internal constant _CREDIT_LINE_SIGNATURE_TYPE_HASH =
        keccak256("BorrowDelegate(bytes32 warning,address from,address to,uint amount,uint256 nonce)");

    /// @dev exchange rate precision
    uint256 private constant PRICE_RATE_PRECISION = 1e18;

    /// @dev liquidation close factor 50
    uint256 private constant CLOSE_FACTOR_PERCENT = 5000;

    /// @dev settlement activation delay
    uint256 private constant SETLLEMENT_ACTIVATION = 1 weeks;

    /// @notice where the tokens are stored
    IXVault public immutable vault;

    /// @notice protocol liquidation fee share percent
    uint256 public immutable protocolLiquidationFeeSharePercent;

    /// @notice address to withdraw fees to
    address public immutable feeVault;

    /// @notice borrow asset
    IERC20 public immutable override xasset;

    /// @notice The price oracle for the assets
    IPriceOracleAggregator public immutable override oracle;

    modifier whenNotPaused() {
        Config memory config = configuration;
        require(config.getSettlementMode() == false, "SETTLEMENT_MODE");
        require(config.isAllPaused() == false, "PAUSED");

        _;
    }

    modifier onlyConfigurator() {
        require(msg.sender == configurator, "O_G");
        _;
    }

    /// @notice constructor
    /// @param _vault vault
    /// @param _oracle price oracle aggregator
    /// @param _xasset xasset address
    /// @param _feeVault fee vault address
    /// @param _liquidationFeeSharePercent fee share of the liquidation feees
    constructor(
        IXVault _vault,
        IERC20 _xasset,
        IPriceOracleAggregator _oracle,
        address _feeVault,
        uint256 _liquidationFeeSharePercent
    ) {
        require(address(_vault) != address(0), "IV0");
        require(_feeVault != address(0), "IVWA");
        require(address(_xasset) != address(0), "IAC");
        require(address(_oracle) != address(0), "IV0");

        vault = _vault;
        feeVault = _feeVault;
        protocolLiquidationFeeSharePercent = _liquidationFeeSharePercent;
        xasset = _xasset;
        oracle = _oracle;
    }

    /// @inheritdoc IXPair
    function initialize(
        IERC20 _collateral,
        uint128 _decimals,
        uint128 _liquidationFeePercent,
        uint64 _interestPerSecond,
        uint128 _collateralFactorPercent,
        address _configurator,
        uint128 _borrowFeePercent
    ) external override initializer {
        __EIP712_init(name, version);

        collateral = _collateral;
        pairAccrueInfo.interestPerSecond = _interestPerSecond;

        Config memory data = configuration;
        data.setDecimals(_decimals);
        data.setCollateralFactorPercent(_collateralFactorPercent);
        data.setLiquidationFeePercent(_liquidationFeePercent);
        data.setBorrowFeePercent(_borrowFeePercent);

        // write configuration to storage
        configuration = data;
        configurator = _configurator;

        emit Initialized(address(this), address(xasset), address(_collateral), configurator);
    }

    /// @inheritdoc IXPair
    function depositCollateral(
        address _recipient,
        uint256 _share,
        bool _skim
    ) public override whenNotPaused {
        depositInternal(_recipient, _share, _skim);
    }

    function depositInternal(
        address _recipient,
        uint256 _share,
        bool _skim
    ) internal {
        userCollateral[_recipient] += _share;
        uint256 oldTotalCollateral = totalCollateral;
        totalCollateral += _share;

        address sender = msg.sender;
        IERC20 collateralAsset = collateral;

        if (_skim) {
            require(
                // not using totalCollateral because of extra SLOAD
                vault.balanceOf(collateralAsset, address(this)) >= (oldTotalCollateral + _share),
                "INVALID_DEPOSIT"
            );
        } else {
            vault.transfer(collateralAsset, sender, address(this), _share, 0);
        }

        emit Deposit(_skim ? address(vault) : _recipient, sender, _share);
    }

    /// @dev borrow
    /// @param _debtOwner address that holds the collateral
    /// @param _to addres to transfer the borrow amount to
    /// @param _amount amount of xasset to borrow
    function borrow(
        address _debtOwner,
        address _to,
        uint256 _amount
    ) public override whenNotPaused {
        require(_to != address(0), "LP_INVALID_RECIPIENT");
        address sender = msg.sender;
        accrueInterest();
        borrowInternal(sender, _debtOwner, _to, _amount);
        require(accountSolvent(sender, currentPriceExchangeRate()), "ACCOUNT_INSOLVENT");
    }

    /// @dev assumes accureInterest has been called
    function borrowInternal(
        address sender,
        address _debtOwner,
        address _to,
        uint256 _amountToBorrow
    ) internal returns (uint256 borrowShare) {
        (totalBorrow, borrowShare) = totalBorrow.add(_amountToBorrow, true);

        uint256 fee = borrowShare.percentMul(configuration.getBorrowFeePercent());

        if (_debtOwner != sender) {
            // will panic if no allowance
            borrowAllowances[_debtOwner][sender] -= _amountToBorrow;
        }

        userBorrowShare[_debtOwner] += (borrowShare + fee);
        pairAccrueInfo.fees += fee.toUint128();
        // transfer borrow asset to borrower
        vault.transfer(xasset, address(this), _to, 0, _amountToBorrow);

        emit Borrow(sender, _to, _amountToBorrow);
    }

    /// @notice Repay the borrow loan
    /// @param _beneficiary address to repay loan position
    /// @param _borrowShare The share amount of borrow asset to repay
    function repay(address _beneficiary, uint256 _borrowShare) public whenNotPaused {
        require(_beneficiary != address(0), "LP_INVALID_RECIPIENT");
        address sender = msg.sender;
        accrueInterest();
        repayInternal(sender, _beneficiary, _borrowShare);
    }

    /// @dev assumes accrueInterest has been called
    function repayInternal(
        address sender,
        address _beneficiary,
        uint256 _borrowShare
    ) internal returns (uint256 amount) {
        (totalBorrow, amount) = totalBorrow.sub(_borrowShare, true);
        // reverts if the user is overpaying
        userBorrowShare[_beneficiary] -= _borrowShare;
        vault.transfer(xasset, sender, address(this), 0, amount);

        emit Repay(sender, _beneficiary, amount);
    }

    /// @notice withdraw collateral
    /// @param _to address to send withdraw collateral to
    /// @param _share amount of collateral to withdraw
    function withdrawCollateral(address _to, uint256 _share) public whenNotPaused {
        address sender = msg.sender;
        accrueInterest();
        withdrawCollateralInternal(sender, _to, _share);
        require(accountSolvent(sender, currentPriceExchangeRate()), "ACCOUNT_INSOLVENT");
    }

    function withdrawCollateralInternal(
        address sender,
        address _to,
        uint256 _share
    ) internal {
        userCollateral[sender] -= _share;
        vault.transfer(collateral, address(this), _to, _share, 0);
        emit WithdrawCollateral(sender, _share);
    }

    /// @notice creditLine
    /// @param _from addres to create credit line
    /// @param _to address to delegate credit to
    /// @param _amount amount of credit to delegate
    function creditLine(
        address _from,
        address _to,
        uint256 _amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(_to != address(0), "INVALID_TO");

        if (v == 0 && r == 0 && s == 0) {
            // @TODO should this require a whitelist? no
            // because we want to support smart contract
            // wallets
            require(tx.origin != msg.sender && msg.sender.isContract() == true, "ONLY_CONTRACT");

            _from = msg.sender;
        } else {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    _domainSeparatorV4(),
                    keccak256(
                        abi.encode(
                            _CREDIT_LINE_SIGNATURE_TYPE_HASH,
                            keccak256(
                                "Allow a user to borrow on your behalf? read more here: https://docs.wuradao.com/developers/guides/credit-line"
                            ),
                            _from,
                            _to,
                            _amount,
                            userBorrowAllowanceNonce[_from]++
                        )
                    )
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);
            require(recoveredAddress == _from, "INVALID_SIGNATURE");
        }

        creditLineInternal(_from, _to, _amount);
    }

    function creditLineInternal(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        require(_to != address(0), "INVALID_TO");
        borrowAllowances[_from][_to] = _amount;
        emit Creditline(_from, _to, _amount, block.timestamp);
    }

    struct LiquidateLocalVars {
        uint256 totalBorrowedAmount;
        uint256 totalBorrowedShares;
        uint256 totalLiquidatedCollateralShares;
        uint256 totalLiquidationFee;
        uint256 exchangeRate;
    }

    /// @notice liquidate
    /// @param _borrowers address to liquidate
    /// @param _borrowShares borrow share to liquidate
    /// @param _to address to withdraw collateral
    function liquidate(
        address[] calldata _borrowers,
        uint256[] calldata _borrowShares,
        address _to
    ) external whenNotPaused {
        accrueInterest();

        LiquidateLocalVars memory vars;
        // fetch exchange rate
        vars.exchangeRate = currentPriceExchangeRate();
        IERC20 collateralAsset = collateral;

        uint256 userliquidationFeePercent = configuration.getLiquidationFeePercent();

        Rebase memory _totalBorrow = totalBorrow;

        for (uint256 i = 0; i < _borrowers.length; i++) {
            address borrower = _borrowers[i];
            require(borrower != msg.sender, "NOT_LIQUIDATE_SELF");

            if (accountSolvent(borrower, vars.exchangeRate)) {
                continue;
            }
            uint256 borrowShareToLiquidate;
            {
                // liquidate maximum of close factor percent
                uint256 maxBorrowShareToLiquidate = userBorrowShare[borrower].percentMul(CLOSE_FACTOR_PERCENT);
                borrowShareToLiquidate = (_borrowShares[i] <= maxBorrowShareToLiquidate ? _borrowShares[i] : maxBorrowShareToLiquidate);
                userBorrowShare[borrower] -= borrowShareToLiquidate;
            }
            uint256 borrowedAmount;
            uint256 collateralShare;
            uint256 liquidationFee;
            {
                borrowedAmount = _totalBorrow.toElastic(borrowShareToLiquidate, false);
                liquidationFee = borrowedAmount.percentMul(userliquidationFeePercent);
                uint256 collateralAmount = ((borrowedAmount + liquidationFee) * vars.exchangeRate) / PRICE_RATE_PRECISION;
                uint256 userCollateralBalance = userCollateral[borrower];
                collateralShare = vault.toShare(collateralAsset, collateralAmount, false);
                if (collateralShare > userCollateralBalance) {
                    userCollateral[borrower] = 0;
                } else {
                    userCollateral[borrower] = (userCollateralBalance - collateralShare);
                }
            }

            // calculate totals
            vars.totalBorrowedAmount += borrowedAmount;
            vars.totalBorrowedShares += borrowShareToLiquidate;
            vars.totalLiquidatedCollateralShares += collateralShare;
            vars.totalLiquidationFee += liquidationFee;

            emit Liquidate(borrower, collateralShare, borrowShareToLiquidate, liquidationFee, msg.sender);
        }

        require(vars.totalBorrowedShares != 0, "SOLVENT_USERS");

        _totalBorrow.elastic = _totalBorrow.elastic - vars.totalBorrowedAmount.toUint128();
        _totalBorrow.base = _totalBorrow.base - vars.totalBorrowedShares.toUint128();

        // Write to Storage
        totalBorrow = _totalBorrow;
        totalCollateral -= vars.totalLiquidatedCollateralShares;
        /// transfer the collateral to the user
        userCollateral[_to] += vars.totalLiquidatedCollateralShares;

        // take the protocol fee share of the total liquidation fees
        uint256 protocolLiquidationFees = vars.totalLiquidationFee.percentMul(protocolLiquidationFeeSharePercent);
        pairAccrueInfo.fees += protocolLiquidationFees.toUint128();

        // repay the loans
        vault.transfer(xasset, msg.sender, address(this), 0, vars.totalBorrowedAmount + protocolLiquidationFees);
    }

    /// @dev pause action in the pair
    /// @param _status true or false
    function setStatus(bool _status) external override onlyConfigurator {
        Config memory _config = configuration;
        _config.setAllActionPaused(_status);

        configuration = _config;

        emit SetStatus(_status);
    }

    int256 private constant USE_RETURN_INPUT = -2;

    uint8 private constant COLLATERAL_DEPOSIT = 1;
    uint8 private constant REPAY = 2;
    uint8 private constant BORROW = 3;
    uint8 private constant WITHDRAW_COLLATERAL = 4;

    uint8 private constant VAULT_DEPOSIT = 11;
    uint8 private constant VAULT_WITHDRAW = 12;
    uint8 private constant VAULT_TRANSFER = 13;
    uint8 private constant VAULT_APPROVE_CONTRACT = 14;

    uint8 private constant CALL = 20;

    struct AnvilStatus {
        bool hasAccruedInterest;
        bool requiresSolvencyCheck;
    }

    function anvil(uint8[] calldata actions, bytes[] calldata data) external whenNotPaused returns (uint256 value) {
        require(actions.length == data.length, "INV");
        address sender = msg.sender;

        AnvilStatus memory anvilStatus;

        for (uint8 i = 0; i < actions.length; i++) {
            uint8 action = actions[i];

            if (anvilStatus.hasAccruedInterest == false && action < 10) {
                accrueInterest();
                anvilStatus.hasAccruedInterest = true;
            }

            if (action == COLLATERAL_DEPOSIT) {
                (address receipient, int256 amount, bool skim) = abi.decode(data[i], (address, int256, bool));
                depositCollateral(receipient, select(amount, value), skim);
            } else if (action == REPAY) {
                (address beneficiary, int256 amount) = abi.decode(data[i], (address, int256));
                repayInternal(sender, beneficiary, select(amount, value));
            } else if (action == BORROW) {
                (address debtOwner, address to, int256 amount) = abi.decode(data[i], (address, address, int256));
                borrowInternal(sender, debtOwner, to, select(amount, value));
                anvilStatus.requiresSolvencyCheck = true;
            } else if (action == WITHDRAW_COLLATERAL) {
                (address to, int256 amount) = abi.decode(data[i], (address, int256));
                withdrawCollateralInternal(sender, to, select(amount, value));
                anvilStatus.requiresSolvencyCheck = true;
            } else if (action == VAULT_DEPOSIT) {
                (address token, address to, int256 amount) = abi.decode(data[i], (address, address, int256));
                (value, ) = vault.deposit(IERC20(token), sender, to, select(amount, value));
            } else if (action == VAULT_WITHDRAW) {
                (address token, address to, int256 amount) = abi.decode(data[i], (address, address, int256));
                value = vault.withdraw(IERC20(token), sender, to, select(amount, value));
            } else if (action == VAULT_TRANSFER) {
                (address token, address to, int256 amount) = abi.decode(data[i], (address, address, int256));
                vault.transfer(IERC20(token), sender, to, select(amount, value), 0);
            } else if (action == VAULT_APPROVE_CONTRACT) {
                (address _user, address _contract, bool _status, uint8 v, bytes32 r, bytes32 s) = abi.decode(
                    data[i],
                    (address, address, bool, uint8, bytes32, bytes32)
                );
                vault.approveContract(_user, _contract, _status, v, r, s);
            } else if (action == CALL) {
                // @TODO add call function
            }
        }

        if (anvilStatus.requiresSolvencyCheck) {
            require(accountSolvent(sender, currentPriceExchangeRate()), "ACCOUNT_INSOLVENT");
        }
    }

    /// @dev select Select which argument to pass
    function select(int256 paramInput, uint256 returnInput) internal pure returns (uint256 value) {
        value = paramInput >= 0 ? uint256(paramInput) : (paramInput == USE_RETURN_INPUT) ? returnInput : uint256(paramInput);
    }

    /// @notice Applies accrued interest to total borrows and fees
    /// @dev This calculates interest accrued from the last checkpointed block timestamp
    /// up to the current block timestamp and writes new checkpoint to storage.
    function accrueInterest() public {
        PairAccrueInfo memory accrueInfo = pairAccrueInfo;

        // Number of seconds passed since accrue was called
        uint256 elapsedSeconds = block.timestamp - accrueInfo.lastUpdateTimestamp;
        if (elapsedSeconds == 0) {
            return;
        }
        // update most recent timestamp
        accrueInfo.lastUpdateTimestamp = block.timestamp.toUint64();

        Rebase memory _totalBorrow = totalBorrow;
        if (_totalBorrow.base == 0) {
            pairAccrueInfo = accrueInfo;
            return;
        }

        uint128 interestAccrued = ((uint256(_totalBorrow.elastic) * accrueInfo.interestPerSecond * elapsedSeconds) / 1e18).toUint128();
        _totalBorrow.elastic = _totalBorrow.elastic + interestAccrued;
        accrueInfo.fees += interestAccrued;

        // Write to storage
        totalBorrow = _totalBorrow;
        pairAccrueInfo = accrueInfo;
    }

    /// @notice accountSolvent checks if an account is solvent
    /// @dev    accrueInterest must have already been called!
    /// @param _borrower address to check solvency status
    /// @param _exchangeRate price exchange rate
    function accountSolvent(address _borrower, uint256 _exchangeRate) public view returns (bool solvent) {
        uint256 borrowShare = userBorrowShare[_borrower];
        if (borrowShare == 0) return true;
        uint256 collateralShare = userCollateral[_borrower];
        if (collateralShare == 0) return false;
        Rebase memory _totalBorrow = totalBorrow;
        return
            vault.toUnderlying(
                collateral,
                uint256(collateralShare * PRICE_RATE_PRECISION).percentDiv(configuration.getCollateralFactorPercent())
            ) >= (borrowShare * _totalBorrow.elastic * _exchangeRate) / _totalBorrow.base;
    }

    /// @notice withdraw fees earned to the feeVault
    /// @dev this function can be called by anyone
    function withdrawFees() external {
        accrueInterest();
        uint256 feesEarned = pairAccrueInfo.fees;
        vault.transfer(xasset, address(this), feeVault, 0, feesEarned);
        pairAccrueInfo.fees = 0;

        emit WithdrawFees(feeVault, feesEarned);
    }

    /// @dev updateInterestRate
    /// @param newInterestRatePerSecond new interest rate
    function updateInterestRate(uint64 newInterestRatePerSecond) external override onlyConfigurator {
        accrueInterest();

        pairAccrueInfo.interestPerSecond = newInterestRatePerSecond;

        emit UpdatedInterestRate(newInterestRatePerSecond);
    }

    function currentPriceExchangeRate() internal view returns (uint256 exchangeRate) {
        IERC20[] memory tokens = new IERC20[](2);
        tokens[0] = xasset;
        tokens[1] = collateral;
        uint256[] memory assetPrices = oracle.getPriceInUSDMultiple(tokens);
        /// @TODO multiply by decimals
        exchangeRate = (assetPrices[0] * PRICE_RATE_PRECISION) / assetPrices[1];
    }

    /// @dev cancelShutDown cancel shutdown within activation period
    function cancelShutDown() external override onlyConfigurator {
        require(settlementInfo.timestamp > block.timestamp, "INVALID_CANCEL");

        Settlement memory info = settlementInfo;
        info.timestamp = 0;
        info.to = address(0);

        settlementInfo = info;
        Config memory _config = configuration;
        _config.setSettlementMode(false);

        configuration = _config;

        emit CancelShutDown(block.timestamp);
    }

    /// @notice shutdown
    /// @dev the _to address should be an address we can withdraw the xasset tokens from
    /// @param _to address to transfer received xasset to
    function shutdown(address _to) external override onlyConfigurator {
        uint64 shutDownTimestamp = (block.timestamp + SETLLEMENT_ACTIVATION).toUint64();

        settlementInfo.timestamp = shutDownTimestamp;
        settlementInfo.to = _to;

        Config memory _config = configuration;
        _config.setSettlementMode(true);

        configuration = _config;

        emit ShutDown(shutDownTimestamp, _to);
    }

    /// @notice claim collateral within the pair
    /// @param _to address to send the tokens to
    /// @param _amount amount of tokens to convert
    function settle(address _to, uint256 _amount) external override {
        Settlement memory info = settlementInfo;

        require(configuration.getSettlementMode() == true, "IN_SETTLE_MODE");
        require(info.timestamp != 0 && info.timestamp < block.timestamp, "INVALID_SETTLE");

        address sender = msg.sender;
        uint256 collateralToClaim = (_amount * currentPriceExchangeRate()) / PRICE_RATE_PRECISION;

        // transfer the xasset from user to settlement info to addres
        vault.transfer(xasset, sender, info.to, 0, _amount);

        // transfer collateral to the user
        vault.transfer(collateral, address(this), _to, 0, collateralToClaim);

        emit Settle(_to, _amount, collateralToClaim);
    }

    /// @dev settlement mode
    function settlementMode() external view returns (bool mode) {
        mode = configuration.getSettlementMode();
    }

    /// @dev status mode
    function status() external view override returns (bool mode) {
        mode = configuration.isAllPaused();
    }

    /// @dev getConfigurationData
    function getConfigurationData() external view override returns (uint256 data) {
        data = configuration.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IERC20Details {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
import "./IERC3156FlashBorrower.sol";

interface IERC3156FlashLender {
    /**
     * @dev The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IOracle {
    /// @notice Price update event
    /// @param asset the asset
    /// @param newPrice price of the asset
    event PriceUpdated(address asset, uint256 newPrice);

    /// @dev returns latest answer
    function latestAnswer() external view returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IOracle.sol";

interface IPriceOracleAggregator {
    event UpdateOracle(IERC20 token, IOracle oracle);

    function getPriceInUSD(IERC20 _token) external view returns (uint256);

    function getPriceInUSDMultiple(IERC20[] calldata _tokens) external view returns (uint256[] memory);

    function setOracleForAsset(IERC20[] calldata _asset, IOracle[] calldata _oracle) external;

    event OwnershipAccepted(address newOwner, uint256 timestamp);
    event TransferControl(address _newTeam, uint256 timestamp);
    event StableTokenAdded(IERC20 _token, uint256 timestamp);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IPriceOracleAggregator.sol";
import "./IXVault.sol";

interface IXPair {
    struct PairAccrueInfo {
        uint64 lastUpdateTimestamp;
        uint64 interestPerSecond;
        uint128 fees;
    }

    struct PairShutDown {
        bool shutdown;
        uint128 exchangeRate;
    }

    struct Settlement {
        uint64 timestamp;
        // address to
        address to;
    }

    enum PauseActions {
        Deposit,
        Borrow,
        Liquidate,
        Repay,
        All
    }

    /// @dev Emitted on initilaize
    /// @param pair address of the pair
    /// @param asset borrow asset
    /// @param collateralAsset collateral asset
    /// @param pauseGuardian user with ability to pause
    event Initialized(address indexed pair, address indexed asset, address indexed collateralAsset, address pauseGuardian);

    /// @dev Emitted on deposit
    /// @param user The user that made the deposit
    /// @param receipeint The user that receives the deposit
    /// @param amount The amount deposited
    event Deposit(address indexed user, address receipeint, uint256 amount);

    /// @dev Emitted on borrow
    /// @param borrower address of the borrrower
    /// @param receipeint The user address that receives the borrow amount
    /// @param amount amount being borrowed
    event Borrow(address indexed borrower, address receipeint, uint256 amount);

    /// @dev Emitted on repay
    /// @param repayer The user that's providing the funds
    /// @param beneficiary The user that's getting their debt reduced
    /// @param amount The amount being repaid
    event Repay(address indexed repayer, address beneficiary, uint256 amount);

    /// @dev Emitted on redeem
    /// @param account address amount being withdrawn to
    /// @param amount amount being withdrawn
    event WithdrawCollateral(address account, uint256 amount);

    /// @dev Emitted on withdrawFees
    event ReserveWithdraw(address user, uint256 shares);

    /// @dev Emitted on liquidation
    /// @param user The user that's getting liquidated
    /// @param collateralShare The collateral share transferred to the liquidator
    /// @param liquidator The liquidator
    event Liquidate(address indexed user, uint256 collateralShare, uint256 borrowShare, uint256 liquidationFee, address liquidator);

    /// @dev Emitted on flashLoan
    /// @param target The address of the flash loan receiver contract
    /// @param initiator The address initiating the flash loan
    /// @param asset The address of the asset being flash borrowed
    /// @param amount The amount flash borrowed
    /// @param premium The fee flash borrowed
    event FlashLoan(address indexed target, address indexed initiator, address indexed asset, uint256 amount, uint256 premium);

    /// @dev Emitted on interest accrued
    /// @param accrualBlockNumber block number
    /// @param borrowIndex borrow index
    /// @param totalBorrows total borrows
    /// @param totalReserves total reserves
    event InterestAccrued(
        address indexed pair,
        uint256 accrualBlockNumber,
        uint256 borrowIndex,
        uint256 totalBorrows,
        uint256 totalReserves
    );

    /// @dev Emitted on setStatus
    /// @param status status
    event SetStatus(bool status);

    /// @dev Emitted on settle
    /// @param amountOfTokensRedeem amount of borrow asset to redeem
    /// @param amountOfCollateral amount of collateral transferred
    event Settle(address to, uint256 amountOfTokensRedeem, uint256 amountOfCollateral);

    /// @dev Emitted on shutdown
    /// @param timestamp timestamp shutdown
    /// @param to address that holds funds
    event ShutDown(uint64 timestamp, address to);

    /// @dev Emitted on cancelShutDown
    event CancelShutDown(uint256 timestamp);

    /// @dev Emitted on updateInterestRate
    event UpdatedInterestRate(uint64 newInterestRatePerSecond);

    /// @dev Emitted on withdrawFees
    /// @param feeVault address of the fee vault
    /// @param share amount of fees withdrawn
    event WithdrawFees(address feeVault, uint256 share);

    /// @dev Emitted on creditline
    /// @param from address granting the credit line
    /// @param to address receiving the credit line
    /// @param amount amount of credit line to issue
    /// @param timestamp block timestamp of when the credit line was issued
    event Creditline(address from, address to, uint256 amount, uint256 timestamp);

    /// @notice Initialize
    /// @param _collateral pair collateral
    /// @param _decimals 18 - collateral decimals
    /// @param _liquidationFeePercent share of liquidation that we accrue
    /// @param _interestPerSecond interest per second
    /// @param _collateralFactorPercent pair collateral factor
    /// @param _configurator pair configurator
    /// @param _borrowFeePercent borrow fee
    function initialize(
        IERC20 _collateral,
        uint128 _decimals,
        uint128 _liquidationFeePercent,
        uint64 _interestPerSecond,
        uint128 _collateralFactorPercent,
        address _configurator,
        uint128 _borrowFeePercent
    ) external;

    /// @notice deposit allows a user to deposit underlying collateral from vault
    /// @param _recipient user address to credit the collateral amount
    /// @param _share is the amount of vault share being deposited
    /// @param _skim If true does only a balance check for deposit
    function depositCollateral(
        address _recipient,
        uint256 _share,
        bool _skim
    ) external;

    function xasset() external view returns (IERC20);

    function totalBorrow() external view returns (uint128 elastic, uint128 base);

    function collateral() external view returns (IERC20);

    function oracle() external view returns (IPriceOracleAggregator);

    /// @notice borrow a xasset
    /// @param _debtOwner address that holds the collateral
    /// @param _to address to transfer borrow tokens to
    /// @param _amount is the amount of the borrow asset the user wants to borrow
    function borrow(
        address _debtOwner,
        address _to,
        uint256 _amount
    ) external;

    function userCollateral(address _user) external view returns (uint256 collateralShare);

    /// @notice returns the user borrow share
    /// @param _user user address
    /// @dev To retrieve the actual user borrow amount convert to elastic
    function userBorrowShare(address _user) external view returns (uint256 borrowShare);

    function updateInterestRate(uint64 newInterestRatePerSecond) external;

    function cancelShutDown() external;

    function shutdown(address _to) external;

    function settle(address to, uint256 amount) external;

    function setStatus(bool) external;

    function status() external view returns (bool);

    function getConfigurationData() external view returns (uint256 data);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IERC3156FlashLender.sol";

interface IXVault is IERC3156FlashLender {
    // ************** //
    // *** EVENTS *** //
    // ************** //

    /// @notice Emitted on deposit
    /// @param token being deposited
    /// @param from address making the depsoit
    /// @param to address to credit the tokens being deposited
    /// @param amount being deposited
    /// @param shares the represent the amount deposited in the vault
    event Deposit(IERC20 indexed token, address indexed from, address indexed to, uint256 amount, uint256 shares);

    /// @notice Emitted on withdraw
    /// @param token being deposited
    /// @param from address making the depsoit
    /// @param to address to credit the tokens being withdrawn
    /// @param amount Amount of underlying being withdrawn
    /// @param shares the represent the amount withdraw from the vault
    event Withdraw(IERC20 indexed token, address indexed from, address indexed to, uint256 shares, uint256 amount);

    event Transfer(IERC20 indexed token, address indexed from, address indexed to, uint256 amount);

    event FlashLoan(address indexed borrower, IERC20 indexed token, uint256 amount, uint256 feeAmount, address indexed receiver);

    event TransferControl(address _newTeam, uint256 timestamp);

    event UpdateFlashLoanRate(uint256 newRate);

    event Approval(address indexed user, address indexed allowed, bool status);

    event OwnershipAccepted(address newOwner, uint256 timestamp);

    event RegisterProtocol(address sender);

    event AllowContract(address whitelist, bool status);

    event RescueFunds(IERC20 token, uint256 amount);

    // ************** //
    // *** FUNCTIONS *** //
    // ************** //

    function initialize(uint256 _flashLoanRate, address _owner) external;

    function approveContract(
        address _user,
        address _contract,
        bool _status,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function deposit(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _amount
    ) external returns (uint256, uint256);

    function withdraw(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _amount
    ) external returns (uint256);

    function balanceOf(IERC20, address) external view returns (uint256);

    function transfer(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _shares,
        uint256 _amount
    ) external;

    function toShare(
        IERC20 token,
        uint256 amount,
        bool ceil
    ) external view returns (uint256);

    function toUnderlying(IERC20 token, uint256 share) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

struct Config {
    // Pair Configuration data pack

    // 64 decimals
    // 16 collateral factor percent

    // 16 liquidation fee percent

    // 16 borrow fee percent

    // 1 bit all pause action
    // 1 bit settlement mode

    uint256 data;
}

library PairConfiguration {
    uint256 internal constant DECIMAL_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000000000;
    uint256 internal constant COLLATERAL_FACTOR_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF;
    uint256 internal constant LIQUIDATION_FEE_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFF;
    uint256 internal constant BORROW_FEE_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFF;
    uint256 internal constant ALL_PAUSE_ACTION_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    uint256 internal constant SETTLEMENT_MODE_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    uint256 internal constant COLLATERAL_FACTOR_POSITION = 64;
    uint256 internal constant LIQUIDATION_FEE_POSITION = 80;
    uint256 internal constant BORROW_FEE_POSITION = 96;
    uint256 internal constant ALL_PAUSE_ACTION_POSITION = 112;
    uint256 internal constant SETTLEMENT_MODE_POSITION = 113;

    uint256 internal constant MAX_UINT_64_VALUE = 1;
    uint256 internal constant MAX_UINT_16_VALUE = 65535;
    uint256 internal constant MAX_UINT_8_VALUE = 255;

    function setDecimals(Config memory _config, uint256 _decimals) internal pure {
        require(_decimals <= MAX_UINT_64_VALUE, "INVALID_DECIMALS");
        _config.data = (_config.data & DECIMAL_MASK) | _decimals;
    }

    function getDecimals(Config storage _config) internal view returns (uint256 decimals) {
        decimals = _config.data & ~DECIMAL_MASK;
    }

    function setCollateralFactorPercent(Config memory _config, uint256 _factor) internal pure {
        require(_factor < MAX_UINT_16_VALUE, "INVALID_VALUE");
        _config.data = (_config.data & COLLATERAL_FACTOR_MASK) | (_factor << COLLATERAL_FACTOR_POSITION);
    }

    function getCollateralFactorPercent_(Config memory _config) internal pure returns (uint256 collateralFactorPercent) {
        collateralFactorPercent = (_config.data & ~COLLATERAL_FACTOR_MASK) >> COLLATERAL_FACTOR_POSITION;
    }

    function getCollateralFactorPercent(Config storage _config) internal view returns (uint256 collateralFactorPercent) {
        collateralFactorPercent = (_config.data & ~COLLATERAL_FACTOR_MASK) >> COLLATERAL_FACTOR_POSITION;
    }

    function setLiquidationFeePercent(Config memory _config, uint256 _fee) internal pure {
        require(_fee < MAX_UINT_16_VALUE, "INVALID");
        _config.data = (_config.data & LIQUIDATION_FEE_MASK) | (_fee << LIQUIDATION_FEE_POSITION);
    }

    function getLiquidationFeePercent(Config memory _config) internal pure returns (uint256 liquidationFeePercent) {
        liquidationFeePercent = (_config.data & ~LIQUIDATION_FEE_MASK) >> LIQUIDATION_FEE_POSITION;
    }

    function setBorrowFeePercent(Config memory _config, uint256 _fee) internal pure {
        require(_fee < MAX_UINT_16_VALUE, "INVALID");
        _config.data = (_config.data & BORROW_FEE_MASK) | (_fee << BORROW_FEE_POSITION);
    }

    function getBorrowFeePercent(Config storage _config) internal view returns (uint256 fee) {
        fee = (_config.data & ~BORROW_FEE_MASK) >> BORROW_FEE_POSITION;
    }

    function getBorrowFeePercent_(Config memory _config) internal pure returns (uint256 fee) {
        fee = (_config.data & ~BORROW_FEE_MASK) >> BORROW_FEE_POSITION;
    }

    function setAllActionPaused(Config memory _config, bool status) internal pure {
        _config.data = (_config.data & ALL_PAUSE_ACTION_MASK) | (uint256(status ? 1 : 0) << ALL_PAUSE_ACTION_POSITION);
    }

    function isAllPaused(Config memory _config) internal pure returns (bool paused) {
        paused = (_config.data & ~ALL_PAUSE_ACTION_MASK) != 0;
    }

    function setSettlementMode(Config memory _config, bool status) internal pure {
        _config.data = (_config.data & SETTLEMENT_MODE_MASK) | (uint256(status ? 1 : 0) << SETTLEMENT_MODE_POSITION);
    }

    function getSettlementMode(Config memory _config) internal pure returns (bool paused) {
        paused = (_config.data & ~SETTLEMENT_MODE_MASK) != 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

library PercentageMath {
    uint256 internal constant PERCENT_PRECISION = 10_000;

    function percentMul(uint256 value, uint256 percentage) internal pure returns (uint256 result) {
        if (percentage != 0) {
            result = (value * percentage) / PERCENT_PRECISION;
        }
    }

    function percentDiv(uint256 value, uint256 percent) internal pure returns (uint256 result) {
        if (percent != 0) {
            result = (value * PERCENT_PRECISION) / percent;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

struct Rebase {
    uint128 elastic;
    uint128 base;
}

/// @notice A rebasing library using overflow-/underflow-safe math.
library RebaseLibrary {
    using SafeCast for uint256;

    /// elastic = Total token amount to be repayed by borrowers,
    /// base = Total parts of the debt held by borrowers
    /// @notice Calculates the base value in relationship to `elastic` and `total`.
    function toBase(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (uint256 base) {
        if (total.elastic == 0) {
            base = elastic;
        } else {
            base = (elastic * total.base) / total.elastic;
            if (roundUp && (base * total.elastic) / total.base < elastic) {
                base += 1;
            }
        }
    }

    /// @notice Calculates the elastic value in relationship to `base` and `total`.
    function toElastic(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (uint256 elastic) {
        if (total.base == 0) {
            elastic = base;
        } else {
            elastic = (base * total.elastic) / total.base;
            if (roundUp && (elastic * total.base) / total.elastic < base) {
                elastic += 1;
            }
        }
    }

    /// @notice Add `elastic` to `total` and doubles `total.base`.
    /// @return (Rebase) The new total.
    /// @return base in relationship to `elastic`.
    function add(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 base) {
        base = toBase(total, elastic, roundUp);
        total.elastic = total.elastic + elastic.toUint128();
        total.base = total.base + base.toUint128();
        return (total, base);
    }

    /// @notice Sub `base` from `total` and update `total.elastic`.
    /// @return (Rebase) The new total.
    /// @return elastic in relationship to `base`.
    function sub(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 elastic) {
        elastic = toElastic(total, base, roundUp);
        total.elastic = total.elastic - elastic.toUint128();
        total.base = total.base - base.toUint128();
        return (total, elastic);
    }

    /// @notice Add `elastic` and `base` to `total`.
    function add(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic = total.elastic + elastic.toUint128();
        total.base = total.base + base.toUint128();
        return total;
    }

    /// @notice Subtract `elastic` and `base` to `total`.
    function sub(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic = total.elastic - elastic.toUint128();
        total.base = total.base - base.toUint128();
        return total;
    }

    /// @notice Add `elastic` to `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function addElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic = total.elastic + elastic.toUint128();
    }

    /// @notice Subtract `elastic` from `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function subElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic = total.elastic - elastic.toUint128();
    }
}