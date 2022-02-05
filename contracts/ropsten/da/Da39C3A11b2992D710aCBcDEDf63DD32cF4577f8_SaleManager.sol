/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

// Sources flattened with hardhat v2.6.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/utils/cryptography/[email protected]
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

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


// File @openzeppelin/contracts/utils/[email protected]
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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


// File @openzeppelin/contracts/interfaces/[email protected]
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}


// File @openzeppelin/contracts/utils/cryptography/[email protected]
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;



/**
 * @dev Signature verification helper: Provide a single mechanism to verify both private-key (EOA) ECDSA signature and
 * ERC1271 contract signatures. Using this instead of ECDSA.recover in your contract will make them compatible with
 * smart contract wallets such as Argent and Gnosis.
 *
 * Note: unlike ECDSA signatures, contract signature's are revocable, and the outcome of this function can thus change
 * through time. It could return true at block N and false at block N+1 (or the opposite).
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271.isValidSignature.selector);
    }
}


// File contracts/AccessOracle.sol

pragma solidity >=0.8.0 <0.9.0;

contract AccessOracle {
  bytes32 private constant DOMAIN_TYPE_HASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"
    );
  bytes32 private constant DOMAIN_NAME = keccak256("TokensoftAccessOracle");
  bytes32 private constant DOMAIN_VERSION = keccak256("1");
  bytes32 private constant PERMIT_TYPEHASH = keccak256("Allow(address user,uint256 saleId)");
  bytes4 public constant MAGIC_VALUE = bytes4(keccak256("isAllowed(address,uint256,bytes)"));
  bytes32 public immutable DOMAIN_SEPARATOR;
  address public immutable signer;

  constructor(address _signer, address _saleManager) {
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        DOMAIN_TYPE_HASH,
        DOMAIN_NAME,
        DOMAIN_VERSION,
        block.chainid,
        address(this),
        keccak256(abi.encode(_saleManager))
      )
    );
    signer = _signer;
  }

  function isAllowed(
      address user,
      uint256 saleId,
      bytes calldata signature
  ) external view returns (bytes4) {
    bytes32 digest = keccak256(
        abi.encodePacked(
            '\x19\x01',
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(PERMIT_TYPEHASH, user, saleId))
        )
    );

    if (SignatureChecker.isValidSignatureNow(signer, digest, signature)) {
      return MAGIC_VALUE;
    }
    return 0;
  }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]
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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;


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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/[email protected]
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


// File @openzeppelin/contracts/token/ERC20/[email protected]
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;



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


// File @openzeppelin/contracts/security/[email protected]
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}


// File contracts/SaleManager.sol

pragma solidity >=0.8.0 <0.9.0;




struct Sale {
  address accessOracle;  // the address validating sale participants
  address seller; // the address that will receive sale proceeds
  address payToken;  // the ERC-20 token the owner will receive. Price is denominated in this asset.
  uint8 buyTokenDecimals; // the number of decimals in the token being bought (which may not exist yet)
  uint256 price; // number of payToken (integer) per buyToken (decimal)
  uint256 saleBuyLimit;  // max tokens that can be bought in total
  uint256 userBuyLimit;  // max tokens that each user can buy
  uint startTime; // the time at which the sale starts
  uint endTime; // the time at which the sale will end, regardless of tokens raised
  bool enabled; // the seller must enable the sale
  uint256 totalBought;
  mapping(address => uint256) bought;
}

contract SaleManager is ReentrancyGuard {
  using SafeERC20 for ERC20;
  uint256 public saleCount = 0;

  bytes4 private constant ACCESS_ORACLE_MAGIC_VALUE = 0x19a05a7e;

  event UpdateStatus(uint256 indexed saleId, bool enabled, uint startTime, uint endTime);
  event Buy(uint256 indexed saleId, address indexed buyer, uint256 value, bytes proof);

  mapping (uint256 => Sale) public sales;

  modifier validSale (uint256 saleId) {
    require(
      saleId < saleCount,
      "invalid sale: check saleCount"
    );
    _;
  }

  modifier isSeller(uint256 saleId) {
    require(
      sales[saleId].seller == msg.sender,
      "must be seller"
    );
    _;
  }

  modifier requireOpen(uint256 saleId) {
    require(sales[saleId].enabled, "sale not enabled");
    require(block.timestamp > sales[saleId].startTime, "sale not started yet");
    require(block.timestamp < sales[saleId].endTime, "sale ended");
    require(sales[saleId].totalBought < sales[saleId].saleBuyLimit, "sale over");
    _;
  }

  constructor() {
  }

  function isContract(address _address) private view returns (bool){
    uint32 size;
    assembly {
      size := extcodesize(_address)
    }
    return (size > 0);
  }

  // Accessor functions
  function getAccessOracle(uint256 saleId) public validSale(saleId) view returns(address) {
    return(sales[saleId].accessOracle);
  }

  function getSeller(uint256 saleId) public validSale(saleId) view returns(address) {
    return(sales[saleId].seller);
  }

  function getPayToken(uint256 saleId) public validSale(saleId) view returns(address) {
    return(sales[saleId].payToken);
  }

  function getBuyTokenDecimals(uint256 saleId) public validSale(saleId) view returns(uint8) {
    return sales[saleId].buyTokenDecimals;
  }

  function getPrice(uint256 saleId) public validSale(saleId) view returns(uint256) {
    return(sales[saleId].price);
  }

  function getSaleBuyLimit(uint256 saleId) public validSale(saleId) view returns(uint256) {
    return(sales[saleId].saleBuyLimit);
  }

  function getUserBuyLimit(uint256 saleId) public validSale(saleId) view returns(uint256) {
    return(sales[saleId].userBuyLimit);
  }

  function getStartTime(uint256 saleId) public validSale(saleId) view returns(uint) {
    return(sales[saleId].startTime);
  }

  function getEndTime(uint256 saleId) public validSale(saleId) view returns(uint) {
    return(sales[saleId].endTime);
  }

  function getEnabled(uint256 saleId) public validSale(saleId) view returns(bool) {
    return(sales[saleId].enabled);
  }

  function totalBought(uint256 saleId) public validSale(saleId) view returns(uint256) {
    return (sales[saleId].totalBought);
  }

  function bought(
      uint256 saleId,
      address userAddress
    ) public validSale(saleId) view returns(uint256) {
    // returns the number of tokens purchased by this address
    return(sales[saleId].bought[userAddress]);
  }

  function isOpen(uint256 saleId) public validSale(saleId) view returns(bool) {
    return(
      sales[saleId].enabled
      && block.timestamp > sales[saleId].startTime
      && block.timestamp < sales[saleId].endTime
      && sales[saleId].totalBought < sales[saleId].saleBuyLimit
    );
  }

  // sale setup and config
  function newSale(
    address accessOracle,
    address seller,
    address payToken,
    uint8 buyTokenDecimals,
    uint256 price,
    uint256 saleBuyLimit,
    uint256 userBuyLimit,
    uint startTime,
    uint endTime
  ) public returns(uint256) {
    Sale storage s = sales[saleCount];
    // TODO: check for transferFrom method
    require(isContract(payToken), "must pay with ERC-20");
    require(startTime <= 4102444800, "max: 4102444800 (Jan 1 2100)");
    require(endTime <= 4102444800, "max: 4102444800 (Jan 1 2100)");
    require(endTime > block.timestamp, "sale must end in future");

    s.accessOracle = accessOracle;
    s.seller = seller;
    s.payToken = payToken;
    s.buyTokenDecimals = buyTokenDecimals;
    s.price = price;
    s.saleBuyLimit = saleBuyLimit * 10 ** buyTokenDecimals;
    s.userBuyLimit = userBuyLimit * 10 ** buyTokenDecimals;
    s.startTime = startTime;
    s.endTime = endTime;

    return saleCount++;
  }

  function enable(uint256 saleId) public validSale(saleId) isSeller(saleId) {
    // verify everything works before opening the sale
    require(!sales[saleId].enabled, "sale already enabled");
    sales[saleId].enabled = true;
    emit UpdateStatus(saleId, true, sales[saleId].startTime, sales[saleId].endTime);
  }

  function setStart(uint256 saleId, uint startTime) public validSale(saleId) isSeller(saleId) returns(uint){
    // seller can update start time until the sale starts
    require(block.timestamp < sales[saleId].endTime, "disabled after sale closes");
    require(startTime < sales[saleId].endTime, "sale start must precede end");
    sales[saleId].startTime = startTime;
    emit UpdateStatus(saleId, sales[saleId].enabled, startTime, sales[saleId].endTime);
    return startTime;
  }

  function setEnd(uint256 saleId, uint endTime) public validSale(saleId) isSeller(saleId) returns(uint){
    // seller can update end time until the sale ends
    require(block.timestamp < sales[saleId].endTime, "disabled after sale closes");
    sales[saleId].endTime = endTime;
    emit UpdateStatus(saleId, sales[saleId].enabled, sales[saleId].startTime, endTime);
    return endTime;
  }

  // sale participation
  function buy(
    uint256 saleId,
    uint256 quantity,
    bytes calldata proof
  ) public  validSale(saleId) requireOpen(saleId) nonReentrant returns(bool) {
    require(
      quantity + sales[saleId].bought[msg.sender] <= sales[saleId].userBuyLimit,
      "purchase exceeds your limit"
    );

    require(
      quantity + sales[saleId].totalBought <= sales[saleId].saleBuyLimit,
      "purchase exceeds sale limit"
    );

    // If the access oracle is provided the sale is private
    if (sales[saleId].accessOracle != address(0)) {
      AccessOracle accessOracle = AccessOracle(sales[saleId].accessOracle);

      require(
        accessOracle.isAllowed(
          msg.sender,
          saleId,
          proof
        ) == ACCESS_ORACLE_MAGIC_VALUE,
        "not authorized"
      );
    }

    // the number of tokens the user is spending to make this purchase
    ERC20 payToken = ERC20(sales[saleId].payToken);
    uint256 spendQuantity = quantity * sales[saleId].price / (10 ** sales[saleId].buyTokenDecimals);
    require(payToken.allowance(msg.sender, address(this)) >= spendQuantity, "allowance too low");

    // move the funds
    payToken.safeTransferFrom(msg.sender, sales[saleId].seller, spendQuantity);

    // effects after interaction: we need a reentrancy guard
    sales[saleId].bought[msg.sender] += quantity;
    sales[saleId].totalBought += quantity;

    emit Buy(saleId, msg.sender, quantity, proof);

    return true;
  }
}


// File contracts/Claims.sol

pragma solidity >=0.8.0 <0.9.0;



contract Claims {
  // TOKENS CANNOT BE WITHDRAWN FROM THIS CLAIMS CONTRACT EXCEPT IN THESE CASES:
  // * ERC-20 Token
  // * Sale closed
  // * Claims opened
  // * The message sender calling claim() participated in the sale and their claim was not voided
  using SafeERC20 for ERC20;

  event Open(address indexed buyToken, uint256 total);
  event Void(address indexed claimant);
  event Claim(address indexed claimant, uint256 amount);
  event Close();

  SaleManager public immutable saleManager;
  uint256 public immutable saleId;
  ERC20 public buyToken;
  bool public opened;
  uint256 voided;
  uint256 remaining;
  mapping(address => bool) claimed;

  constructor(address _saleManager,uint256 _saleId) {
    saleManager = SaleManager(_saleManager);
    saleId = _saleId;
  }

  modifier isSeller {
    require(
      saleManager.getSeller(saleId) == msg.sender,
      "can only be called by the seller"
    );
    _;
  }

  modifier saleClosed {
    require(
      !saleManager.isOpen(saleId),
      "sale must be closed first"
    );
    _;
  }

  modifier claimsOpened {
    require(
      opened,
      "claims must be opened first"
    );
    _;
  }

  function getRemainingClaim(address claimant) public view returns (uint256) {
    if (claimed[claimant]) {
      return 0;
    }
    return saleManager.bought(saleId, claimant);
  }

  function getRemainingClaims() public claimsOpened view returns (uint256) {
    return remaining;
  }

  function getTokenBalance() public claimsOpened view returns (uint256) {
    return buyToken.balanceOf(address(this));
  }

  function void(address claimant) public isSeller saleClosed returns (uint256) {
    // prevent this claimant from receiving any tokens
    require(!opened, "claims already opened");
    uint256 bought = getRemainingClaim(claimant);
    claimed[claimant] = true;
    voided += bought;
    emit Void(claimant);
    return bought;
  }

  function open(address _buyToken) public isSeller saleClosed {
    // checks
    require(!opened, "claims already opened");
    buyToken = ERC20(_buyToken);
    require(
      buyToken.decimals() == saleManager.getBuyTokenDecimals(saleId),
      "decimals must match"
    );
    uint256 _remaining = saleManager.totalBought(saleId) - voided;
    require(buyToken.allowance(msg.sender, address(this)) >= _remaining, "claims contract allowance too low");

    // effects
    remaining = _remaining;
    opened = true;
    emit Open(_buyToken, remaining);

    // interactions
    buyToken.safeTransferFrom(msg.sender, address(this), remaining);
  }

  function claim() public saleClosed claimsOpened returns (uint256) {
    // checks
    require(!claimed[msg.sender], "claim already fulfilled or void");
    uint256 quantity = getRemainingClaim(msg.sender);
    require(quantity > 0, "this address cannot claim any tokens");

    // effects
    claimed[msg.sender] = true;
    emit Claim(msg.sender, quantity);
    remaining -= quantity;
    if (remaining == 0) {
      emit Close();
    }

    // interactions
    buyToken.safeTransfer(msg.sender, quantity);

    return quantity;
  }
}


// File contracts/USDC.sol

// From: https://github.com/ethereum/ethereum-org/blob/master/solidity/token-erc20.sol

interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external;
}

contract USDC {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This generates a public event on the blockchain that will notify clients
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    // This notifies clients about the amount minted
    event Mint(address indexed to, uint256 value);

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol,
        uint8 _decimals
    ) {
        decimals = _decimals;
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != address(0x0));
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    // TODO fix this mint function with permissions
    function mint(address to, uint256 _value) public returns (bool success) {
        balanceOf[to] += _value;  // Add to balance
        totalSupply += _value;    // Add to total supply
        emit Mint(to, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
}


// File contracts/Chute.sol

// // contracts/Chute.sol
// // pragma solidity ^0.6.6;

// // OpenZeppelin
// // TODO fix this import
// // import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// // import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

// // Uniswap
// import '@uniswap/lib/contracts/libraries/TransferHelper.sol';
// import '@uniswap/v2-periphery/contracts/interfaces/IERC20.sol';

// // SubChutes
// import './subchutes/ChuteEthToToken.sol';
// import './subchutes/ChuteTokenToToken.sol';
// import './subchutes/ChuteTokenToEth.sol';


// // contract Chute is Initializable, OwnableUpgradeable, ChuteEthToToken, ChuteTokenToToken, ChuteTokenToEth {
// contract Chute is ChuteEthToToken, ChuteTokenToToken, ChuteTokenToEth {
//     using SafeMath for uint256;

//     address private _uniswapFactoryAddress;
//     address private _uniswapRouterAddress;
//     address private _wethAddress;

//     address payable private _cfoAddress;
//     uint256 private _feeTenthsOfAPercent;

//     function initialize(address factoryAddress, address routerAddress, address wethTokenAddress) public initializer {
//         __Ownable_init();
//         setCfoAddress(payable( getOwnerAddress()));
//         setFeeTenthsOfAPercent(0);

//         setUniswapFactoryAddress(factoryAddress);
//         setUniswapRouterAddress(routerAddress);
//         setWethAddress(wethTokenAddress);
//     }

//     function sweepTokenToCfo(address tokenAddress) public {
//         require(tokenAddress != address(0), "Chute: zero address is not a sweepable token.");
//         require(_cfoAddress != address(0), "Chute: CFO is set to the zero address.");
//         IERC20 token = IERC20(address(tokenAddress));
//         TransferHelper.safeTransfer(tokenAddress, _cfoAddress, token.balanceOf(address(this)));
//     }

//     function sweepEthToCfo() public {
//         require(_cfoAddress != address(0), "Chute: CFO is set to the zero address.");
//         TransferHelper.safeTransferETH(_cfoAddress, address(this).balance);
//     }


//     // cfoAddress getter/setter
//     function getCfoAddress() external override view returns (address payable) {
//         return _cfoAddress;
//     }

//     function setCfoAddress(address payable newAddress) public onlyOwner {
//         require(newAddress != address(0), "Chute: cannot set CFO to the zero address.");
//         emit CfoChange(_cfoAddress, newAddress);
//         _cfoAddress = newAddress;
//     }

//     // wethAddress getter/setter
//     function getWethAddress() external override view returns (address) {
//         return _wethAddress;
//     }

//     function setWethAddress(address newAddress) public onlyOwner {
//         require(newAddress != address(0), "Chute: cannot set WETH to the zero address.");
//         emit WethAddressChange(_uniswapFactoryAddress, newAddress);
//         _wethAddress = newAddress;
//     }

//     // uniswapFactoryAddress getter/setter
//     function getUniswapFactoryAddress() public override view returns (address) {
//         return _uniswapFactoryAddress;
//     }

//     function setUniswapFactoryAddress(address newAddress) public onlyOwner {
//         require(newAddress != address(0), "Chute: cannot set Uniswap Factory to the zero address.");
//         emit UniswapFactoryAddressChange(_uniswapFactoryAddress, newAddress);
//         _uniswapFactoryAddress = newAddress;
//     }

//     // uniswapRouterAddress getter/setter
//     function getUniswapRouterAddress() external override view returns (address) {
//         return _uniswapRouterAddress;
//     }

//     function setUniswapRouterAddress(address newAddress) public onlyOwner {
//         require(newAddress != address(0), "Chute: cannot set Uniswap Router to the zero address.");
//         emit UniswapRouterAddressChange(_uniswapRouterAddress, newAddress);
//         _uniswapRouterAddress = newAddress;
//     }

//     // feeTenthsOfAPercent getter/setter
//     function getFeeTenthsOfAPercent() external override view returns (uint256) {
//         return _feeTenthsOfAPercent;
//     }

//     function setFeeTenthsOfAPercent(uint256 newFee) public onlyOwner {
//         require(newFee <= 10, "Chute: cannot set a fee of more than 1%.");
//         emit FeeUpdated(_feeTenthsOfAPercent, newFee);
//         _feeTenthsOfAPercent = newFee;
//     }

//     // owner getter (a foolish consistency...)
//     function getOwnerAddress() public view returns (address) {
//         return owner();
//     }

//     receive() external payable {}

//     event CfoChange(address oldAddress, address newAddress);
//     event FeeUpdated(uint256 oldFee, uint256 newFee);
//     event UniswapFactoryAddressChange(address oldAddress, address newAddress);
//     event UniswapRouterAddressChange(address oldAddress, address newAddress);
//     event WethAddressChange(address oldAddress, address newAddress);
// }


// File contracts/NewToken.sol

// From: https://github.com/ethereum/ethereum-org/blob/master/solidity/token-erc20.sol

// interface tokenRecipient {
//     function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external;
// }

contract NewToken {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This generates a public event on the blockchain that will notify clients
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    // This notifies clients about the amount minted
    event Mint(address indexed to, uint256 value);

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol,
        uint8 _decimals
    ) {
        decimals = _decimals;
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != address(0x0));
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    // TODO fix this mint function with permissions
    function mint(address to, uint256 _value) public returns (bool success) {
        balanceOf[to] += _value;  // Add to balance
        totalSupply += _value;    // Add to total supply
        emit Mint(to, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
}


// File contracts/subchutes/ChuteEthToToken.sol

// // contracts/subchutes/ChuteEthToToken.sol
// pragma solidity ^0.6.6;

// // OpenZeppelin
// import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

// // Uniswap
// import '@uniswap/lib/contracts/libraries/TransferHelper.sol';
// import '@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol';
// import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
// import '@uniswap/v2-periphery/contracts/interfaces/IERC20.sol';
// import '@uniswap/v2-periphery/contracts/interfaces/IWETH.sol';

// import './SubChute.sol';


// abstract contract ChuteEthToToken is SubChute {
//     using SafeMath for uint256;

//     function getQuoteForEthToToken(
//         address outputToken,
//         uint256 amountToBeReceived,
//         uint256 slippageTenthsOfAPercent
//     ) public view returns (uint256 amount) {
//         require(outputToken != address(0), "Chute: set a valid output token.");
//         require(amountToBeReceived > 0, "Chute: specify a valid amount to be received.");

//         (uint256 reserveIn, uint256 reserveOut) = UniswapV2Library.getReserves(this.getUniswapFactoryAddress(), this.getWethAddress(), outputToken);
//         uint256 minimumSendAmount = UniswapV2Library.getAmountIn(amountToBeReceived, reserveIn, reserveOut);

//         uint256 amountToSend = this.getFeeTenthsOfAPercent().add(1000).add(slippageTenthsOfAPercent).mul(minimumSendAmount) / 1000;

//         return amountToSend;
//     }

//     function sendEthToToken(
//         address outputToken,
//         uint256 amountToBeReceived,
//         address recipient
//     ) public payable {
//         require(msg.value > 0, "Chute: must send non-zero amount of ETH.");
//         require(outputToken != address(0), "Chute: set a valid output token.");
//         require(amountToBeReceived > 0, "Chute: specify a valid amount to be received.");
//         require(recipient != address(0), "Chute: cannot set recipient to the zero address.");

//         uint256 contractStartingEth = address(this).balance.sub(msg.value);

//         address[] memory path = new address[](2);
//         path[0] = this.getWethAddress();
//         path[1] = outputToken;

//         IUniswapV2Router02 router = IUniswapV2Router02(address(this.getUniswapRouterAddress()));

//         router.swapETHForExactTokens{value: msg.value}(
//             amountToBeReceived,
//             path,
//             recipient,
//             now
//         );

//         uint256 fee = this.getFeeTenthsOfAPercent().mul(amountToBeReceived) / 1000;

//         if (fee > 0) {
//             router.swapETHForExactTokens{value: address(this).balance.sub(contractStartingEth)}(
//                 fee,
//                 path,
//                 this.getCfoAddress(),
//                 now
//             );
//         }

//         uint256 amountToReturn = address(this).balance.sub(contractStartingEth);
//         TransferHelper.safeTransferETH(msg.sender, amountToReturn);

//         emit SendEthToToken(msg.value.sub(amountToReturn), outputToken, amountToBeReceived, fee);
//     }

//     event SendEthToToken(uint256 amountSpent, address outputToken, uint256 outputAmount, uint256 fee);
// }


// File contracts/subchutes/ChuteTokenToEth.sol

// // contracts/subchutes/ChuteEthToToken.sol
// // pragma solidity ^0.6.6;

// // OpenZeppelin
// // TODO fix this import
// // import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// // Uniswap
// import '@uniswap/lib/contracts/libraries/TransferHelper.sol';
// // import '@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol';
// import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
// import '@uniswap/v2-periphery/contracts/interfaces/IERC20.sol';
// import '@uniswap/v2-periphery/contracts/interfaces/IWETH.sol';

// import './SubChute.sol';


// abstract contract ChuteTokenToEth is SubChute {
//     using SafeMath for uint256;

//     function getQuoteForTokenToEth(
//         address inputToken,
//         uint256 amountToBeReceived,
//         uint256 slippageTenthsOfAPercent
//     ) public view returns (uint256 amount) {
//         require(inputToken != address(0), "Chute: set a valid input token.");
//         require(amountToBeReceived > 0, "Chute: specify a valid amount to be received.");

//         // TODO fix this
//         // (uint256 reserveIn, uint256 reserveOut) = UniswapV2Library.getReserves(this.getUniswapFactoryAddress(), inputToken, this.getWethAddress());
//         // uint256 minimumSendAmount = UniswapV2Library.getAmountIn(amountToBeReceived, reserveIn, reserveOut);

//         // uint256 amountToSend = this.getFeeTenthsOfAPercent().add(1000).add(slippageTenthsOfAPercent).mul(minimumSendAmount) / 1000;

//         // return amountToSend;
//         return 0;
//     }

//     function sendTokenToEth(
//         address inputToken,
//         uint256 maxAmountToSend,
//         uint256 amountToBeReceived,
//         address recipient
//     ) public {
//         require(inputToken != address(0), "Chute: set a valid input token.");
//         require(maxAmountToSend > 0, "Chute: specify a valid amount to send.");
//         require(amountToBeReceived > 0, "Chute: specify a valid amount to be received.");
//         require(recipient != address(0), "Chute: cannot set recipient to the zero address.");

//         uint256 contractStartingBalance = IERC20(inputToken).balanceOf(address(this));

//         TransferHelper.safeApprove(inputToken, address(this.getUniswapRouterAddress()), maxAmountToSend);
//         TransferHelper.safeTransferFrom(inputToken, msg.sender, address(this), maxAmountToSend);

//         address[] memory path = new address[](2);
//         path[0] = inputToken;
//         path[1] = this.getWethAddress();

//         IUniswapV2Router02 router = IUniswapV2Router02(address(this.getUniswapRouterAddress()));

//         router.swapTokensForExactETH(
//             amountToBeReceived,
//             maxAmountToSend,
//             path,
//             recipient,
//             block.timestamp
//         );

//         uint256 fee = this.getFeeTenthsOfAPercent().mul(amountToBeReceived) / 1000;

//         if (fee > 0) {
//             router.swapTokensForExactETH(
//                 fee,
//                 maxAmountToSend,
//                 path,
//                 this.getCfoAddress(),
//                 block.timestamp
//             );
//         }

//         uint256 amountToReturn = IERC20(inputToken).balanceOf(address(this)).sub(contractStartingBalance);

//         TransferHelper.safeTransfer(inputToken, msg.sender, amountToReturn);

//         emit SendTokenToEth(inputToken, maxAmountToSend.sub(amountToReturn), amountToBeReceived, fee);
//     }

//     event SendTokenToEth(address inputToken, uint256 amountSpent, uint256 outputAmount, uint256 fee);
// }


// File contracts/subchutes/ChuteTokenToToken.sol

// // contracts/subchutes/ChuteTokenToToken.sol
// pragma solidity ^0.6.6;

// // OpenZeppelin
// import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

// // Uniswap
// import '@uniswap/lib/contracts/libraries/TransferHelper.sol';
// import '@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol';
// import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
// import '@uniswap/v2-periphery/contracts/interfaces/IERC20.sol';

// import './SubChute.sol';


// abstract contract ChuteTokenToToken is SubChute {
//     using SafeMath for uint256;

//     function getQuoteForTokenToToken(
//         address inputToken,
//         address outputToken,
//         uint256 amountToBeReceived,
//         uint256 slippageTenthsOfAPercent
//     ) public view returns (uint256 amount) {
//         require(inputToken != address(0), "Chute: set a valid input token.");
//         require(outputToken != address(0), "Chute: set a valid output token.");
//         require(amountToBeReceived > 0, "Chute: specify a valid amount to be received.");

//         (uint256 reserveIn, uint256 reserveOut) = UniswapV2Library.getReserves(this.getUniswapFactoryAddress(), inputToken, outputToken);
//         uint256 minimumSendAmount = UniswapV2Library.getAmountIn(amountToBeReceived, reserveIn, reserveOut);

//         uint256 amountToSend = this.getFeeTenthsOfAPercent().add(1000).add(slippageTenthsOfAPercent).mul(minimumSendAmount) / 1000;

//         return amountToSend;
//     }

//     function sendTokenToToken(
//         address inputToken,
//         uint256 maxAmountToSend,
//         address outputToken,
//         uint256 amountToBeReceived,
//         address recipient
//     ) public {
//         require(inputToken != address(0), "Chute: set a valid input token.");
//         require(maxAmountToSend > 0, "Chute: specify a valid amount to send.");
//         require(outputToken != address(0), "Chute: set a valid output token.");
//         require(amountToBeReceived > 0, "Chute: specify a valid amount to be received.");
//         require(recipient != address(0), "Chute: cannot set recipient to the zero address.");

//         uint256 contractStartingBalance = IERC20(inputToken).balanceOf(address(this));

//         TransferHelper.safeTransferFrom(inputToken, msg.sender, address(this), maxAmountToSend);
//         TransferHelper.safeApprove(inputToken, address(this.getUniswapRouterAddress()), maxAmountToSend);

//         address[] memory path = new address[](2);
//         path[0] = inputToken;
//         path[1] = outputToken;

//         IUniswapV2Router02 router = IUniswapV2Router02(address(this.getUniswapRouterAddress()));

//         router.swapTokensForExactTokens(
//             amountToBeReceived,
//             maxAmountToSend,
//             path,
//             recipient,
//             now
//         );

//         uint256 fee = this.getFeeTenthsOfAPercent().mul(amountToBeReceived) / 1000;

//         if (fee > 0) {
//             router.swapTokensForExactTokens(
//                 fee,
//                 maxAmountToSend,
//                 path,
//                 this.getCfoAddress(),
//                 now
//             );
//         }

//         uint256 amountToReturn = IERC20(inputToken).balanceOf(address(this)).sub(contractStartingBalance);

//         TransferHelper.safeTransfer(inputToken, msg.sender, amountToReturn);

//         emit SendTokenToToken(inputToken, maxAmountToSend.sub(amountToReturn), outputToken, amountToBeReceived, fee);
//     }

//     event SendTokenToToken(address inputToken, uint256 amountSpent, address outputToken, uint256 outputAmount, uint256 fee);
// }


// File contracts/subchutes/SubChute.sol

// contracts/subchutes/SubChute.sol
// pragma solidity ^0.6.6;


// interface SubChute {
//     function getCfoAddress() external view returns (address payable);
//     function getFeeTenthsOfAPercent() external view returns (uint256);
//     function getUniswapFactoryAddress() external view returns (address);
//     function getUniswapRouterAddress() external view returns (address);
//     function getWethAddress() external view returns (address);
// }