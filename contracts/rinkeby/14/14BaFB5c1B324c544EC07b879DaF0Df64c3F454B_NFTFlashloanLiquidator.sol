/**
 *Submitted for verification at Etherscan.io on 2022-09-06
*/

// Sources flattened with hardhat v2.9.9 https://hardhat.org

// File @openzeppelin/contracts/token/ERC721/[email protected]

// SPDX-License-Identifier: MIT
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


// File contracts/interfaces/IFlashLoanReceiver.sol

pragma solidity ^0.8.13;

interface IFlashLoanReceiver {
  function executeOperation(
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata premiums,
    address initiator,
    bytes calldata params
  ) external returns (bool);
}


// File contracts/interfaces/INonfungiblePositionManager.sol

pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Non-fungible token for positions
/// @notice Wraps Uniswap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManager {
  /// @notice Returns the position information associated with a given token ID.
  /// @dev Throws if the token ID is not valid.
  /// @param tokenId The ID of the token that represents the position
  /// @return nonce The nonce for permits
  /// @return operator The address that is approved for spending
  /// @return token0 The address of the token0 for a specific pool
  /// @return token1 The address of the token1 for a specific pool
  /// @return fee The fee associated with the pool
  /// @return tickLower The lower end of the tick range for the position
  /// @return tickUpper The higher end of the tick range for the position
  /// @return liquidity The liquidity of the position
  /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
  /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
  /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
  /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
  function positions(uint256 tokenId)
    external
    view
    returns (
      uint96 nonce,
      address operator,
      address token0,
      address token1,
      uint24 fee,
      int24 tickLower,
      int24 tickUpper,
      uint128 liquidity,
      uint256 feeGrowthInside0LastX128,
      uint256 feeGrowthInside1LastX128,
      uint128 tokensOwed0,
      uint128 tokensOwed1
    );

  struct DecreaseLiquidityParams {
    uint256 tokenId;
    uint128 liquidity;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
  }

  /// @notice Decreases the amount of liquidity in a position and accounts it to the position
  /// @param params tokenId The ID of the token for which liquidity is being decreased,
  /// amount The amount by which liquidity will be decreased,
  /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
  /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
  /// deadline The time by which the transaction must be included to effect the change
  /// @return amount0 The amount of token0 accounted to the position's tokens owed
  /// @return amount1 The amount of token1 accounted to the position's tokens owed
  function decreaseLiquidity(DecreaseLiquidityParams calldata params)
    external
    payable
    returns (uint256 amount0, uint256 amount1);

  struct CollectParams {
    uint256 tokenId;
    address recipient;
    uint128 amount0Max;
    uint128 amount1Max;
  }

  /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
  /// @param params tokenId The ID of the NFT for which tokens are being collected,
  /// recipient The account that should receive the tokens,
  /// amount0Max The maximum amount of token0 to collect,
  /// amount1Max The maximum amount of token1 to collect
  /// @return amount0 The amount of fees collected in token0
  /// @return amount1 The amount of fees collected in token1
  function collect(CollectParams calldata params)
    external
    payable
    returns (uint256 amount0, uint256 amount1);

  /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
  /// must be collected first.
  /// @param tokenId The ID of the token that is being burned
  function burn(uint256 tokenId) external payable;

  /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
  /// @dev The `msg.value` should not be trusted for any method callable from multicall.
  /// @param data The encoded function data for each of the calls to make to this contract
  /// @return results The results from each of the calls passed in via data
  function multicall(bytes[] calldata data)
    external
    payable
    returns (bytes[] memory results);
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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


// File contracts/lib/ConsiderationEnums.sol

pragma solidity ^0.8.7;

// prettier-ignore
enum OrderType {
    // 0: no partial fills, anyone can execute
    FULL_OPEN,

    // 1: partial fills supported, anyone can execute
    PARTIAL_OPEN,

    // 2: no partial fills, only offerer or zone can execute
    FULL_RESTRICTED,

    // 3: partial fills supported, only offerer or zone can execute
    PARTIAL_RESTRICTED
}

// prettier-ignore
enum BasicOrderType {
    // 0: no partial fills, anyone can execute
    ETH_TO_ERC721_FULL_OPEN,

    // 1: partial fills supported, anyone can execute
    ETH_TO_ERC721_PARTIAL_OPEN,

    // 2: no partial fills, only offerer or zone can execute
    ETH_TO_ERC721_FULL_RESTRICTED,

    // 3: partial fills supported, only offerer or zone can execute
    ETH_TO_ERC721_PARTIAL_RESTRICTED,

    // 4: no partial fills, anyone can execute
    ETH_TO_ERC1155_FULL_OPEN,

    // 5: partial fills supported, anyone can execute
    ETH_TO_ERC1155_PARTIAL_OPEN,

    // 6: no partial fills, only offerer or zone can execute
    ETH_TO_ERC1155_FULL_RESTRICTED,

    // 7: partial fills supported, only offerer or zone can execute
    ETH_TO_ERC1155_PARTIAL_RESTRICTED,

    // 8: no partial fills, anyone can execute
    ERC20_TO_ERC721_FULL_OPEN,

    // 9: partial fills supported, anyone can execute
    ERC20_TO_ERC721_PARTIAL_OPEN,

    // 10: no partial fills, only offerer or zone can execute
    ERC20_TO_ERC721_FULL_RESTRICTED,

    // 11: partial fills supported, only offerer or zone can execute
    ERC20_TO_ERC721_PARTIAL_RESTRICTED,

    // 12: no partial fills, anyone can execute
    ERC20_TO_ERC1155_FULL_OPEN,

    // 13: partial fills supported, anyone can execute
    ERC20_TO_ERC1155_PARTIAL_OPEN,

    // 14: no partial fills, only offerer or zone can execute
    ERC20_TO_ERC1155_FULL_RESTRICTED,

    // 15: partial fills supported, only offerer or zone can execute
    ERC20_TO_ERC1155_PARTIAL_RESTRICTED,

    // 16: no partial fills, anyone can execute
    ERC721_TO_ERC20_FULL_OPEN,

    // 17: partial fills supported, anyone can execute
    ERC721_TO_ERC20_PARTIAL_OPEN,

    // 18: no partial fills, only offerer or zone can execute
    ERC721_TO_ERC20_FULL_RESTRICTED,

    // 19: partial fills supported, only offerer or zone can execute
    ERC721_TO_ERC20_PARTIAL_RESTRICTED,

    // 20: no partial fills, anyone can execute
    ERC1155_TO_ERC20_FULL_OPEN,

    // 21: partial fills supported, anyone can execute
    ERC1155_TO_ERC20_PARTIAL_OPEN,

    // 22: no partial fills, only offerer or zone can execute
    ERC1155_TO_ERC20_FULL_RESTRICTED,

    // 23: partial fills supported, only offerer or zone can execute
    ERC1155_TO_ERC20_PARTIAL_RESTRICTED
}

// prettier-ignore
enum BasicOrderRouteType {
    // 0: provide Ether (or other native token) to receive offered ERC721 item.
    ETH_TO_ERC721,

    // 1: provide Ether (or other native token) to receive offered ERC1155 item.
    ETH_TO_ERC1155,

    // 2: provide ERC20 item to receive offered ERC721 item.
    ERC20_TO_ERC721,

    // 3: provide ERC20 item to receive offered ERC1155 item.
    ERC20_TO_ERC1155,

    // 4: provide ERC721 item to receive offered ERC20 item.
    ERC721_TO_ERC20,

    // 5: provide ERC1155 item to receive offered ERC20 item.
    ERC1155_TO_ERC20
}

// prettier-ignore
enum ItemType {
    // 0: ETH on mainnet, MATIC on polygon, etc.
    NATIVE,

    // 1: ERC20 items (ERC777 and ERC20 analogues could also technically work)
    ERC20,

    // 2: ERC721 items
    ERC721,

    // 3: ERC1155 items
    ERC1155,

    // 4: ERC721 items where a number of tokenIds are supported
    ERC721_WITH_CRITERIA,

    // 5: ERC1155 items where a number of ids are supported
    ERC1155_WITH_CRITERIA
}

// prettier-ignore
enum Side {
    // 0: Items that can be spent
    OFFER,

    // 1: Items that must be received
    CONSIDERATION
}


// File contracts/lib/ConsiderationStructs.sol

pragma solidity ^0.8.7;

// prettier-ignore

/**
 * @dev An order contains eleven components: an offerer, a zone (or account that
 *      can cancel the order or restrict who can fulfill the order depending on
 *      the type), the order type (specifying partial fill support as well as
 *      restricted order status), the start and end time, a hash that will be
 *      provided to the zone when validating restricted orders, a salt, a key
 *      corresponding to a given conduit, a counter, and an arbitrary number of
 *      offer items that can be spent along with consideration items that must
 *      be received by their respective recipient.
 */
struct OrderComponents {
    address offerer;
    address zone;
    OfferItem[] offer;
    ConsiderationItem[] consideration;
    OrderType orderType;
    uint256 startTime;
    uint256 endTime;
    bytes32 zoneHash;
    uint256 salt;
    bytes32 conduitKey;
    uint256 counter;
}

/**
 * @dev An offer item has five components: an item type (ETH or other native
 *      tokens, ERC20, ERC721, and ERC1155, as well as criteria-based ERC721 and
 *      ERC1155), a token address, a dual-purpose "identifierOrCriteria"
 *      component that will either represent a tokenId or a merkle root
 *      depending on the item type, and a start and end amount that support
 *      increasing or decreasing amounts over the duration of the respective
 *      order.
 */
struct OfferItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
}

/**
 * @dev A consideration item has the same five components as an offer item and
 *      an additional sixth component designating the required recipient of the
 *      item.
 */
struct ConsiderationItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
    address payable recipient;
}

/**
 * @dev For basic orders involving ETH / native / ERC20 <=> ERC721 / ERC1155
 *      matching, a group of six functions may be called that only requires a
 *      subset of the usual order arguments. Note the use of a "basicOrderType"
 *      enum; this represents both the usual order type as well as the "route"
 *      of the basic order (a simple derivation function for the basic order
 *      type is `basicOrderType = orderType + (4 * basicOrderRoute)`.)
 */
struct BasicOrderParameters {
    // calldata offset
    address considerationToken; // 0x24
    uint256 considerationIdentifier; // 0x44
    uint256 considerationAmount; // 0x64
    address payable offerer; // 0x84
    address zone; // 0xa4
    address offerToken; // 0xc4
    uint256 offerIdentifier; // 0xe4
    uint256 offerAmount; // 0x104
    BasicOrderType basicOrderType; // 0x124
    uint256 startTime; // 0x144
    uint256 endTime; // 0x164
    bytes32 zoneHash; // 0x184
    uint256 salt; // 0x1a4
    bytes32 offererConduitKey; // 0x1c4
    bytes32 fulfillerConduitKey; // 0x1e4
    uint256 totalOriginalAdditionalRecipients; // 0x204
    AdditionalRecipient[] additionalRecipients; // 0x224
    bytes signature; // 0x244
    // Total length, excluding dynamic array data: 0x264 (580)
}

/**
 * @dev Basic orders can supply any number of additional recipients, with the
 *      implied assumption that they are supplied from the offered ETH (or other
 *      native token) or ERC20 token for the order.
 */
struct AdditionalRecipient {
    uint256 amount;
    address payable recipient;
}

/**
 * @dev The full set of order components, with the exception of the counter,
 *      must be supplied when fulfilling more sophisticated orders or groups of
 *      orders. The total number of original consideration items must also be
 *      supplied, as the caller may specify additional consideration items.
 */
struct OrderParameters {
    address offerer; // 0x00
    address zone; // 0x20
    OfferItem[] offer; // 0x40
    ConsiderationItem[] consideration; // 0x60
    OrderType orderType; // 0x80
    uint256 startTime; // 0xa0
    uint256 endTime; // 0xc0
    bytes32 zoneHash; // 0xe0
    uint256 salt; // 0x100
    bytes32 conduitKey; // 0x120
    uint256 totalOriginalConsiderationItems; // 0x140
    // offer.length                          // 0x160
}

/**
 * @dev Orders require a signature in addition to the other order parameters.
 */
struct Order {
    OrderParameters parameters;
    bytes signature;
}

/**
 * @dev Advanced orders include a numerator (i.e. a fraction to attempt to fill)
 *      and a denominator (the total size of the order) in addition to the
 *      signature and other order parameters. It also supports an optional field
 *      for supplying extra data; this data will be included in a staticcall to
 *      `isValidOrderIncludingExtraData` on the zone for the order if the order
 *      type is restricted and the offerer or zone are not the caller.
 */
struct AdvancedOrder {
    OrderParameters parameters;
    uint120 numerator;
    uint120 denominator;
    bytes signature;
    bytes extraData;
}

/**
 * @dev A criteria resolver specifies an order, side (offer vs. consideration),
 *      and item index. It then provides a chosen identifier (i.e. tokenId)
 *      alongside a merkle proof demonstrating the identifier meets the required
 *      criteria.
 */
struct CriteriaResolver {
    uint256 orderIndex;
    Side side;
    uint256 index;
    uint256 identifier;
    bytes32[] criteriaProof;
}


// File contracts/interfaces/ConsiderationInterface.sol

pragma solidity ^0.8.7;

// prettier-ignore

/**
 * @title ConsiderationInterface
 * @author 0age
 * @custom:version 1.1
 * @notice Consideration is a generalized ETH/ERC20/ERC721/ERC1155 marketplace.
 *         It minimizes external calls to the greatest extent possible and
 *         provides lightweight methods for common routes as well as more
 *         flexible methods for composing advanced orders.
 *
 * @dev ConsiderationInterface contains all external function interfaces for
 *      Consideration.
 */
interface ConsiderationInterface {
  /**
   * @notice Fulfill an order offering an ERC721 token by supplying Ether (or
   *         the native token for the given chain) as consideration for the
   *         order. An arbitrary number of "additional recipients" may also be
   *         supplied which will each receive native tokens from the fulfiller
   *         as consideration.
   *
   * @param parameters Additional information on the fulfilled order. Note
   *                   that the offerer must first approve this contract (or
   *                   their preferred conduit if indicated by the order) for
   *                   their offered ERC721 token to be transferred.
   *
   * @return fulfilled A boolean indicating whether the order has been
   *                   successfully fulfilled.
   */
  function fulfillBasicOrder(BasicOrderParameters calldata parameters)
    external
    payable
    returns (bool fulfilled);

  /**
   * @notice Fill an order, fully or partially, with an arbitrary number of
   *         items for offer and consideration alongside criteria resolvers
   *         containing specific token identifiers and associated proofs.
   *
   * @param advancedOrder       The order to fulfill along with the fraction
   *                            of the order to attempt to fill. Note that
   *                            both the offerer and the fulfiller must first
   *                            approve this contract (or their preferred
   *                            conduit if indicated by the order) to transfer
   *                            any relevant tokens on their behalf and that
   *                            contracts must implement `onERC1155Received`
   *                            to receive ERC1155 tokens as consideration.
   *                            Also note that all offer and consideration
   *                            components must have no remainder after
   *                            multiplication of the respective amount with
   *                            the supplied fraction for the partial fill to
   *                            be considered valid.
   * @param criteriaResolvers   An array where each element contains a
   *                            reference to a specific offer or
   *                            consideration, a token identifier, and a proof
   *                            that the supplied token identifier is
   *                            contained in the merkle root held by the item
   *                            in question's criteria element. Note that an
   *                            empty criteria indicates that any
   *                            (transferable) token identifier on the token
   *                            in question is valid and that no associated
   *                            proof needs to be supplied.
   * @param fulfillerConduitKey A bytes32 value indicating what conduit, if
   *                            any, to source the fulfiller's token approvals
   *                            from. The zero hash signifies that no conduit
   *                            should be used, with direct approvals set on
   *                            Consideration.
   * @param recipient           The intended recipient for all received items,
   *                            with `address(0)` indicating that the caller
   *                            should receive the items.
   *
   * @return fulfilled A boolean indicating whether the order has been
   *                   successfully fulfilled.
   */
  function fulfillAdvancedOrder(
    AdvancedOrder calldata advancedOrder,
    CriteriaResolver[] calldata criteriaResolvers,
    bytes32 fulfillerConduitKey,
    address recipient
  ) external payable returns (bool fulfilled);
}


// File @openzeppelin/contracts/utils/introspection/[email protected]

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


// File @openzeppelin/contracts/token/ERC721/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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


// File contracts/lib/OrderTypes.sol

pragma solidity ^0.8.0;

/**
 * @title OrderTypes
 * @notice This library contains order types for the LooksRare exchange.
 */
library OrderTypes {
    // keccak256("MakerOrder(bool isOrderAsk,address signer,address collection,uint256 price,uint256 tokenId,uint256 amount,address strategy,address currency,uint256 nonce,uint256 startTime,uint256 endTime,uint256 minPercentageToAsk,bytes params)")
    bytes32 internal constant MAKER_ORDER_HASH = 0x40261ade532fa1d2c7293df30aaadb9b3c616fae525a0b56d3d411c841a85028;

    struct MakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address signer; // signer of the maker order
        address collection; // collection address
        uint256 price; // price (used as )
        uint256 tokenId; // id of the token
        uint256 amount; // amount of tokens to sell/purchase (must be 1 for ERC721, 1+ for ERC1155)
        address strategy; // strategy for trade execution (e.g., DutchAuction, StandardSaleForFixedPrice)
        address currency; // currency (e.g., WETH)
        uint256 nonce; // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
        uint256 startTime; // startTime in timestamp
        uint256 endTime; // endTime in timestamp
        uint256 minPercentageToAsk; // slippage protection (9000 --> 90% of the final price must return to ask)
        bytes params; // additional parameters
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s; // s: parameter
    }

    struct TakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address taker; // msg.sender
        uint256 price; // final price for the purchase
        uint256 tokenId;
        uint256 minPercentageToAsk; // // slippage protection (9000 --> 90% of the final price must return to ask)
        bytes params; // other params (e.g., tokenId)
    }

    function hash(MakerOrder memory makerOrder) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    MAKER_ORDER_HASH,
                    makerOrder.isOrderAsk,
                    makerOrder.signer,
                    makerOrder.collection,
                    makerOrder.price,
                    makerOrder.tokenId,
                    makerOrder.amount,
                    makerOrder.strategy,
                    makerOrder.currency,
                    makerOrder.nonce,
                    makerOrder.startTime,
                    makerOrder.endTime,
                    makerOrder.minPercentageToAsk,
                    keccak256(makerOrder.params)
                )
            );
    }
}


// File contracts/interfaces/ILooksRareExchange.sol

pragma solidity ^0.8.0;

interface ILooksRareExchange {
  function matchBidWithTakerAsk(
    OrderTypes.TakerOrder calldata takerAsk,
    OrderTypes.MakerOrder calldata makerBid
  ) external;
}


// File contracts/interfaces/ICryptoPunksMarket.sol

pragma solidity ^0.8.13;

interface ICryptoPunksMarket {
  function punkIndexToAddress(uint256 punkIndex)
    external
    view
    returns (address);

  function balanceOf(address user) external view returns (uint256);

  function transferPunk(address to, uint256 punkIndex) external;

  function withdraw() external;

  function acceptBidForPunk(uint256 punkIndex, uint256 minPrice) external;
}


// File contracts/interfaces/IUniswapV2Router01.sol


pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
  function factory() external pure returns (address);

  function WETH() external pure returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETHWithPermit(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountToken, uint256 amountETH);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
}


// File contracts/interfaces/IUniswapV2Router02.sol


pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}


// File contracts/interfaces/IWrappedPunks.sol

pragma solidity ^0.8.13;

/**
 * @dev Interface for a permittable ERC721 contract
 * See https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC72 allowance (see {IERC721-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC721-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IWrappedPunks is IERC721 {
  function punkContract() external view returns (address);

  function mint(uint256 punkIndex) external;

  function burn(uint256 punkIndex) external;

  function registerProxy() external;

  function proxyInfo(address user) external view returns (address proxy);
}


// File contracts/lib/DataTypes.sol

pragma solidity ^0.8.13;

/**
 * @title DataTypes
 * @notice This library contains Data types for the paraspace market.
 */
library DataTypes {
  struct Credit {
    address token;
    uint256 amount;
    bytes orderId;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }
}


// File contracts/interfaces/IPool.sol

pragma solidity ^0.8.13;

/**
 * @title IPool
 *
 * @notice Defines the basic interface for an Paraspace Pool.
 **/
interface IPool {
  /**
   * @notice Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receiveOToken True if the liquidators wants to receive the collateral xTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveOToken
  ) external;

  function liquidationERC721(
    address collateralAsset,
    address liquidationAsset,
    address user,
    uint256 collateralTokenId,
    uint256 liquidationAmount,
    bool receiveNToken
  ) external;

  function acceptBidWithCredit(
    bytes32 marketplaceId,
    bytes calldata data,
    DataTypes.Credit calldata credit,
    address onBehalfOf,
    uint16 referralCode
  ) external;
}


// File contracts/interfaces/IWETH.sol

pragma solidity ^0.8.13;

interface IWETH {
  function deposit() external payable;

  function transfer(address to, uint256 value) external returns (bool);

  function withdraw(uint256) external;
}


// File contracts/lib/AdaptorDataTypes.sol

pragma solidity ^0.8.13;



enum MarketType {
  SEAPORT_BASIC,
  SEAPORT_COLLECTION,
  LOOKSRARE,
  PARASPACE,
  CRYPTOPUNKS,
  UNIV3POS
}

struct LiquidateCallParams {
  address collateralAsset;
  uint256 tokenId;
  address debtAsset;
  address user;
  uint256 debtToCover;
}

struct FlashLoanParams {
  uint8 mode;
  address flashLoanAsset;
  address[] flashLoanToDebtSwapPath;
  address[] offerToflashLoanSwapPath;
}

struct SeaportBasicLiquidateERC721Params {
  BasicOrderParameters order;
  address market; // seaport
  address nftApprover; // conduit
  LiquidateCallParams liquidateParams;
  FlashLoanParams flashLoanParams;
}

struct AdvancedOrderParameters {
  AdvancedOrder advancedOrder;
  CriteriaResolver[] criteriaResolvers;
  bytes32 fulfillerConduitKey;
  address recipient;
}

struct SeaportAdvancedLiquidateERC721Params {
  AdvancedOrderParameters order;
  address market; // seaport
  address nftApprover; // conduit
  LiquidateCallParams liquidateParams;
  FlashLoanParams flashLoanParams;
}

struct LooksRareLiquidateERC721Params {
  OrderTypes.TakerOrder takerAsk;
  OrderTypes.MakerOrder makerBid;
  address market; // looksRareExchange
  address nftApprover; // transferManagerERC721
  LiquidateCallParams liquidateParams;
  FlashLoanParams flashLoanParams;
}

struct AcceptBidWithCreditParams {
  bytes32 marketplaceId;
  bytes data;
  DataTypes.Credit credit;
  address onBehalfOf;
  uint16 referralCode;
}

struct ParaspaceLiquidateERC721Params {
  AcceptBidWithCreditParams acceptBidInfo;
  address nftApprover; // paraspace seaport or conduit address
  LiquidateCallParams liquidateParams;
  FlashLoanParams flashLoanParams;
}

struct CryptoPunksBid {
  uint256 punkIndex;
  address punkContract;
  address offerToken; // WETH
  uint256 amount; // value
}

// sell cryptopunks on CryptoPunksMarket contract
struct LiquidateCryptoPunksParams {
  CryptoPunksBid bid;
  LiquidateCallParams liquidateParams;
  FlashLoanParams flashLoanParams;
}

struct UniV3POSInfo {
  uint256 tokenId;
  address posManager;
  address offerToken;
}

// removeLiquidity and collect fees
struct LiquidateUniV3POSParams {
  UniV3POSInfo info;
  LiquidateCallParams liquidateParams;
  FlashLoanParams flashLoanParams;
}


// File contracts/nftSellAdaptors/MarketAdaptor.sol

pragma solidity ^0.8.13;











library MarketAdaptor {
  using SafeERC20 for IERC20;

  /**
   * @dev using seaport fulfillBasicOrder function to fulfill bid
   * @param _seaport    seaport address : opensea seaport or paraspace seaport
   * @param _conduit    fulfiller conduit address
   */
  function fulfillBasicOrder(
    BasicOrderParameters memory parameters,
    address _seaport,
    address _conduit
  ) external returns (bool fulfilled) {
    IERC721(parameters.considerationToken).setApprovalForAll(_conduit, true);
    return ConsiderationInterface(_seaport).fulfillBasicOrder(parameters);
  }

  /**
   * @dev using seaport fulfillAdvancedOrder function to fulfill collection bid
   * @param _seaport    seaport address : opensea seaport or paraspace seaport
   * @param _conduit    fulfiller conduit address
   */
  function fulfillAdvancedOrder(
    AdvancedOrderParameters memory parameters,
    address _seaport,
    address _conduit
  ) external returns (bool fulfilled) {
    address considerationToken = parameters
      .advancedOrder
      .parameters
      .consideration[0]
      .token;
    IERC721(considerationToken).setApprovalForAll(_conduit, true);

    if (parameters.advancedOrder.parameters.consideration.length > 1) {
      address offerToken = parameters.advancedOrder.parameters.offer[0].token;
      uint256 offerAmount = parameters
        .advancedOrder
        .parameters
        .offer[0]
        .startAmount;
      _safeApprove(offerToken, _conduit, offerAmount);
    }

    return
      ConsiderationInterface(_seaport).fulfillAdvancedOrder(
        parameters.advancedOrder,
        parameters.criteriaResolvers,
        parameters.fulfillerConduitKey,
        parameters.recipient
      );
  }

  /**
   * @dev using looksrare matchBidWithTakerAsk function to fulfill standard or collection bid
   * @param takerAsk    accept bid info
   * @param makerBid    bid order
   * @param _looksRareExchange    looksRareExchange address
   * @param _transferManager    nft approve
   */
  function matchBidWithTakerAsk(
    OrderTypes.TakerOrder memory takerAsk,
    OrderTypes.MakerOrder memory makerBid,
    address _looksRareExchange,
    address _transferManager
  ) external {
    IERC721(makerBid.collection).setApprovalForAll(_transferManager, true);

    ILooksRareExchange(_looksRareExchange).matchBidWithTakerAsk(
      takerAsk,
      makerBid
    );
  }

  /**
   * @dev using function `pool.acceptBidWithCredit` to sell nft on paraspace marketplace
   * @param params    params of `pool.acceptBidWithCredit`
   * @param nft       nft collection address
   * @param approver  paraspace seaport or conduit address
   */
  function acceptBidWithCredit(
    AcceptBidWithCreditParams memory params,
    address pool,
    address nft,
    address approver
  ) external {
    IERC721(nft).setApprovalForAll(approver, true);

    IPool(pool).acceptBidWithCredit(
      params.marketplaceId,
      params.data,
      params.credit,
      params.onBehalfOf,
      params.referralCode
    );
  }

  /**
   * @dev using CryptoPunksMarket acceptBidForPunk function to fulfill punk bid
   * @param _wpunk  wpunk address
   * @param bid     bid information
   */
  function acceptBidForPunk(address _wpunk, CryptoPunksBid memory bid)
    external
  {
    IWrappedPunks(_wpunk).burn(bid.punkIndex);

    ICryptoPunksMarket punk = ICryptoPunksMarket(bid.punkContract);
    punk.acceptBidForPunk(bid.punkIndex, bid.amount);
    punk.withdraw();

    uint256 bal = address(this).balance;
    IWETH(bid.offerToken).deposit{ value: bal }();
  }

  /**
   * @dev remove UNIV3POS liquidity and collect fees to get some token0 and token1
   * @param params UNIV3POS Information
   * @param router uniswapv2 router
   */
  function uniV3RemoveLiquidityAndCollection(
    UniV3POSInfo memory params,
    IUniswapV2Router02 router
  ) external {
    INonfungiblePositionManager posManager = INonfungiblePositionManager(
      params.posManager
    );
    uint256 tokenId = params.tokenId;
    address weth = params.offerToken;
    (
      ,
      ,
      address token0,
      address token1,
      ,
      ,
      ,
      uint128 liquidity,
      ,
      ,
      ,

    ) = posManager.positions(tokenId);

    bytes[] memory data = new bytes[](3);

    data[0] = abi.encodeWithSelector(
      posManager.decreaseLiquidity.selector,
      INonfungiblePositionManager.DecreaseLiquidityParams({
        tokenId: tokenId,
        liquidity: liquidity,
        amount0Min: 0,
        amount1Min: 0,
        deadline: block.timestamp
      })
    );

    data[1] = abi.encodeWithSelector(
      posManager.collect.selector,
      INonfungiblePositionManager.CollectParams({
        tokenId: tokenId,
        recipient: address(this),
        amount0Max: type(uint128).max,
        amount1Max: type(uint128).max
      })
    );

    data[2] = abi.encodeWithSelector(posManager.burn.selector, tokenId);

    posManager.multicall(data);

    if (weth != token0) {
      address[] memory path = new address[](2);
      path[0] = token0;
      path[1] = weth;

      uint256 bal = IERC20(token0).balanceOf(address(this));
      _safeApprove(token0, address(router), bal);

      router.swapExactTokensForTokens(
        bal,
        0,
        path,
        address(this),
        block.timestamp
      );
    }
    if (weth != token1) {
      address[] memory path = new address[](2);
      path[0] = token1;
      path[1] = weth;

      uint256 bal = IERC20(token1).balanceOf(address(this));
      _safeApprove(token1, address(router), bal);

      router.swapExactTokensForTokens(
        bal,
        0,
        path,
        address(this),
        block.timestamp
      );
    }
  }

  /**
   * @dev safeApprove to 0 and then safeApprove to `_amount`
   *
   * IMPORTANT: This logic is required for compatibility for USDT or other
   * token with this kind of compatibility issue. It's not needed for most
   * other tokens.
   */
  function _safeApprove(
    address _token,
    address _spender,
    uint256 _amount
  ) internal {
    IERC20(_token).safeApprove(_spender, 0);
    IERC20(_token).safeApprove(_spender, _amount);
  }
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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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


// File contracts/interfaces/IFlashLoanPool.sol

pragma solidity ^0.8.13;

interface IFlashLoanPool {
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata modes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;

}


// File contracts/LiquidatorConfig.sol

pragma solidity ^0.8.13;



/**
 * @dev Use LiquidatorConfig to store config for Liquidator Contracts,
 * including addresses of contract dependencies and executor white list.
 */
contract LiquidatorConfig is Ownable {
  mapping(address => bool) _executorWhitelist;
  IPool public _pool;
  IFlashLoanPool public _flashLoanPool;
  IUniswapV2Router02 public _uniswapV2Router;

  /**
   * @dev Add `users` as white listed executors
   */
  function addExecutors(address[] memory users) public onlyOwner {
    for (uint256 i = 0; i < users.length; i++) {
      _executorWhitelist[users[i]] = true;
    }
  }

  /**
   * @dev Remove `users` from white listed executors.
   * It's a no-op if input is not in the white list.
   */
  function removeExecutors(address[] memory users) public onlyOwner {
    for (uint256 i = 0; i < users.length; i++) {
      _executorWhitelist[users[i]] = false;
    }
  }

  /**
   * @dev Check `addr` whether it is a white listed executor or not.
   */
  function isExecutor(address addr) public view returns (bool) {
    return _executorWhitelist[addr];
  }

  function setPool(IPool pool) public onlyOwner {
    _pool = pool;
  }

  function setFlashLoanPool(IFlashLoanPool flashLoanPool) public onlyOwner {
    _flashLoanPool = flashLoanPool;
  }

  function setUniswapV2Router(IUniswapV2Router02 uniswapV2Router)
    public
    onlyOwner
  {
    _uniswapV2Router = uniswapV2Router;
  }
}


// File contracts/LiquidatorBase.sol

pragma solidity ^0.8.13;




/**
 * @dev Base class for Liquidator Contracts.
 * An immutable address of `LiquidatorConfig` is managed.
 * Withdraw ERC20 or ERC721 functions are provided here.
 */
abstract contract LiquidatorBase is Ownable {
  using SafeERC20 for IERC20;

  LiquidatorConfig public immutable CONFIG;

  constructor(LiquidatorConfig config) {
    CONFIG = config;
  }

  modifier onlyExecutor() {
    require(
      msg.sender == owner() || CONFIG.isExecutor(msg.sender),
      "Caller must be owner or executor"
    );
    _;
  }

  function withdrawERC20(
    address _token,
    address _account,
    uint256 _amount
  ) public onlyOwner {
    IERC20 token = IERC20(_token);
    if (_amount > token.balanceOf(address(this))) {
      _amount = token.balanceOf(address(this));
    }
    token.safeTransfer(_account, _amount);
  }

  function withdrawERC721(
    address _token,
    address _account,
    uint256 _tokenId
  ) public onlyOwner {
    IERC721 token = IERC721(_token);
    token.safeTransferFrom(address(this), _account, _tokenId);
  }
}


// File contracts/NFTFlashloanLiquidator.sol

pragma solidity ^0.8.13;







contract NFTFlashloanLiquidator is
  LiquidatorBase,
  IFlashLoanReceiver,
  IERC721Receiver,
  IERC1271
{
  using SafeERC20 for IERC20;

  event LiquidateERC721(
    MarketType indexed marketType,
    address indexed collection,
    uint256 indexed id
  );

  constructor(LiquidatorConfig config) LiquidatorBase(config) {}

  /**
   * @dev the only one external funtion of liquidate NFT with flashloan
   */
  function liquidateERC721(
    bytes calldata _fullParamsBytes,
    bytes calldata _liquidateParamsBytes,
    bytes calldata _flashLoanParamsBytes
  ) external onlyExecutor {
    (
      LiquidateCallParams memory liquidateParams,
      FlashLoanParams memory flashLoanParams
    ) = _decodeLiquidateAndFlashloanParams(
        _liquidateParamsBytes,
        _flashLoanParamsBytes
      );

    _flashLoanAndExecute(liquidateParams, flashLoanParams, _fullParamsBytes);

    MarketType marketType = MarketType(uint8(_getParamType(_fullParamsBytes)));
    emit LiquidateERC721(
      marketType,
      liquidateParams.collateralAsset,
      liquidateParams.tokenId
    );
  }

  /**
   * @dev build params of flashloan and call flashloanPool.flashloan
   */
  function _flashLoanAndExecute(
    LiquidateCallParams memory _liquidateParams,
    FlashLoanParams memory _flashLoanParams,
    bytes memory _paramsBytes
  ) internal {
    // the various assets to be flashed
    address[] memory assets = new address[](1);
    assets[0] = _flashLoanParams.flashLoanAsset;

    // the amount to be flashed for each asset
    uint256[] memory amounts = new uint256[](1);

    if (_flashLoanParams.mode == 0) {
      amounts[0] = _liquidateParams.debtToCover;
    } else {
      uint256[] memory _amounts = CONFIG._uniswapV2Router().getAmountsIn(
        _liquidateParams.debtToCover,
        _flashLoanParams.flashLoanToDebtSwapPath
      );
      amounts[0] = _amounts[0];
    }

    // 0 = no debt, 1 = stable, 2 = variable
    uint256[] memory modes = new uint256[](1);
    modes[0] = 0;

    // 1. lend money
    // 2. call callback
    // 3. repay money
    CONFIG._flashLoanPool().flashLoan(
      address(this), // receiver address
      assets,
      amounts,
      modes,
      address(this), // onBehalfOf
      _paramsBytes,
      0 // referralCode
    );
  }

  /**
   * @dev Flash loan callback, execute remaining logic for liquidateERC721
   */
  function executeOperation(
    address[] calldata,
    uint256[] calldata amounts,
    uint256[] calldata premiums,
    address,
    bytes calldata params_
  ) external override returns (bool) {
    MarketType marketType = MarketType(uint8(_getParamType(params_)));

    if (marketType == MarketType.SEAPORT_BASIC) {
      _executeOperationForSeaportBasic(params_, amounts, premiums);
    } else if (marketType == MarketType.SEAPORT_COLLECTION) {
      _executeOperationForSeaportAdvanced(params_, amounts, premiums);
    } else if (marketType == MarketType.LOOKSRARE) {
      _executeOperationForLooksRare(params_, amounts, premiums);
    } else if (marketType == MarketType.PARASPACE) {
      _executeOperationForParaspace(params_, amounts, premiums);
    } else if (marketType == MarketType.CRYPTOPUNKS) {
      _executeOperationForCryptoPunks(params_, amounts, premiums);
    } else if (marketType == MarketType.UNIV3POS) {
      _executeOperationForUniV3POS(params_, amounts, premiums);
    }

    return true;
  }

  /**
   * @dev flashloan callback for SeaportBasic type
   */
  function _executeOperationForSeaportBasic(
    bytes memory _paramsBytes,
    uint256[] memory _amounts,
    uint256[] memory _premiums
  ) internal {
    (, SeaportBasicLiquidateERC721Params memory params) = abi.decode(
      _paramsBytes,
      (uint256, SeaportBasicLiquidateERC721Params)
    );

    _beforeSellNFT(params.liquidateParams, params.flashLoanParams, _amounts);

    MarketAdaptor.fulfillBasicOrder(
      params.order,
      params.market,
      params.nftApprover
    );

    _afterSellNFT(
      params.liquidateParams,
      params.flashLoanParams,
      _amounts,
      _premiums,
      params.order.offerToken
    );
  }

  /**
   * @dev flashloan callback for SeaportAdvanced type
   */
  function _executeOperationForSeaportAdvanced(
    bytes memory _paramsBytes,
    uint256[] memory _amounts,
    uint256[] memory _premiums
  ) internal {
    (, SeaportAdvancedLiquidateERC721Params memory params) = abi.decode(
      _paramsBytes,
      (uint256, SeaportAdvancedLiquidateERC721Params)
    );

    _beforeSellNFT(params.liquidateParams, params.flashLoanParams, _amounts);

    MarketAdaptor.fulfillAdvancedOrder(
      params.order,
      params.market,
      params.nftApprover
    );

    address offerToken = params.order.advancedOrder.parameters.offer[0].token;
    _afterSellNFT(
      params.liquidateParams,
      params.flashLoanParams,
      _amounts,
      _premiums,
      offerToken
    );
  }

  /**
   * @dev flashloan callback for looksrare type
   */
  function _executeOperationForLooksRare(
    bytes memory _paramsBytes,
    uint256[] memory _amounts,
    uint256[] memory _premiums
  ) internal {
    (, LooksRareLiquidateERC721Params memory params) = abi.decode(
      _paramsBytes,
      (uint256, LooksRareLiquidateERC721Params)
    );
    _beforeSellNFT(params.liquidateParams, params.flashLoanParams, _amounts);

    MarketAdaptor.matchBidWithTakerAsk(
      params.takerAsk,
      params.makerBid,
      params.market,
      params.nftApprover
    );

    _afterSellNFT(
      params.liquidateParams,
      params.flashLoanParams,
      _amounts,
      _premiums,
      address(params.makerBid.currency)
    );
  }

  /**
   * @dev flashloan callback for paraspace type
   */
  function _executeOperationForParaspace(
    bytes memory _paramsBytes,
    uint256[] memory _amounts,
    uint256[] memory _premiums
  ) internal {
    (, ParaspaceLiquidateERC721Params memory params) = abi.decode(
      _paramsBytes,
      (uint256, ParaspaceLiquidateERC721Params)
    );
    _beforeSellNFT(params.liquidateParams, params.flashLoanParams, _amounts);

    MarketAdaptor.acceptBidWithCredit(
      params.acceptBidInfo,
      address(CONFIG._pool()),
      params.liquidateParams.collateralAsset,
      params.nftApprover
    );

    _afterSellNFT(
      params.liquidateParams,
      params.flashLoanParams,
      _amounts,
      _premiums,
      address(params.acceptBidInfo.credit.token)
    );
  }

  /**
   * @dev flashloan callback for cryptopunks type
   */
  function _executeOperationForCryptoPunks(
    bytes memory _paramsBytes,
    uint256[] memory _amounts,
    uint256[] memory _premiums
  ) internal {
    (, LiquidateCryptoPunksParams memory params) = abi.decode(
      _paramsBytes,
      (uint256, LiquidateCryptoPunksParams)
    );
    _beforeSellNFT(params.liquidateParams, params.flashLoanParams, _amounts);

    MarketAdaptor.acceptBidForPunk(
      params.liquidateParams.collateralAsset,
      params.bid
    );

    _afterSellNFT(
      params.liquidateParams,
      params.flashLoanParams,
      _amounts,
      _premiums,
      address(params.bid.offerToken)
    );
  }

  /**
   * @dev flashloan callback for UNIV3POS type
   */
  function _executeOperationForUniV3POS(
    bytes memory _paramsBytes,
    uint256[] memory _amounts,
    uint256[] memory _premiums
  ) internal {
    (, LiquidateUniV3POSParams memory params) = abi.decode(
      _paramsBytes,
      (uint256, LiquidateUniV3POSParams)
    );
    _beforeSellNFT(params.liquidateParams, params.flashLoanParams, _amounts);

    MarketAdaptor.uniV3RemoveLiquidityAndCollection(
      params.info,
      CONFIG._uniswapV2Router()
    );

    _afterSellNFT(
      params.liquidateParams,
      params.flashLoanParams,
      _amounts,
      _premiums,
      address(params.info.offerToken)
    );
  }

  /**
   * @dev 1. swap flashloan asset to user debt asset
   *      2. execute liquidate NFT
   */
  function _beforeSellNFT(
    LiquidateCallParams memory _liquidateParams,
    FlashLoanParams memory _flashLoanParams,
    uint256[] memory amounts
  ) internal {
    if (_flashLoanParams.mode != 0) {
      _safeApprove(
        _flashLoanParams.flashLoanAsset,
        address(CONFIG._uniswapV2Router()),
        amounts[0]
      );

      CONFIG._uniswapV2Router().swapTokensForExactTokens(
        _liquidateParams.debtToCover,
        amounts[0],
        _flashLoanParams.flashLoanToDebtSwapPath,
        address(this),
        block.timestamp
      );
    }

    // liquidate ERC20
    _safeApprove(
      _liquidateParams.debtAsset,
      address(CONFIG._pool()),
      _liquidateParams.debtToCover
    );

    CONFIG._pool().liquidationERC721(
      _liquidateParams.collateralAsset,
      _liquidateParams.debtAsset,
      _liquidateParams.user,
      _liquidateParams.tokenId,
      _liquidateParams.debtToCover,
      false
    );
  }

  /**
   * @dev 1. swap offer token to flashloan asset
   *      2. transfer remaining fund (profits) to owner
   *      3. approve flashloan amount plus fee to flashloanPool
   */
  function _afterSellNFT(
    LiquidateCallParams memory _liquidateParams,
    FlashLoanParams memory _flashLoanParams,
    uint256[] memory amounts,
    uint256[] memory premiums,
    address _offerToken
  ) internal {
    uint256 amountOwing = amounts[0] + premiums[0];
    uint256 transferToOwner;

    if (_offerToken != _flashLoanParams.flashLoanAsset) {
      _safeApprove(
        _offerToken,
        address(CONFIG._uniswapV2Router()),
        IERC20(_offerToken).balanceOf(address(this))
      );

      uint256 amountNeeded = amountOwing -
        IERC20(_flashLoanParams.flashLoanAsset).balanceOf(address(this));

      CONFIG._uniswapV2Router().swapTokensForExactTokens(
        amountNeeded,
        IERC20(_offerToken).balanceOf(address(this)),
        _flashLoanParams.offerToflashLoanSwapPath,
        address(this),
        block.timestamp
      );

      transferToOwner = IERC20(_offerToken).balanceOf(address(this));
    } else {
      uint256 offerTokenBal = IERC20(_offerToken).balanceOf(address(this));
      require(offerTokenBal >= amountOwing, "can't repay flashloan");
      transferToOwner = offerTokenBal - amountOwing;
    }

    IERC20(_offerToken).safeTransfer(owner(), transferToOwner);

    if (_flashLoanParams.mode != 0) {
      IERC20(_liquidateParams.debtAsset).safeTransfer(
        owner(),
        IERC20(_liquidateParams.debtAsset).balanceOf(address(this))
      );
    }

    // Approve the LendingPool contract allowance to *pull* the owed amount
    _safeApprove(
      _flashLoanParams.flashLoanAsset,
      address(CONFIG._flashLoanPool()),
      amountOwing
    );
  }

  /**
   * @dev decode liquidateParams and flashLoanParams from their paramsBytes
   */
  function _decodeLiquidateAndFlashloanParams(
    bytes memory _liquidateParamsBytes,
    bytes memory _flashLoanParamsBytes
  ) internal pure returns (LiquidateCallParams memory, FlashLoanParams memory) {
    LiquidateCallParams memory _liquidateParams = abi.decode(
      _liquidateParamsBytes,
      (LiquidateCallParams)
    );
    FlashLoanParams memory _flashLoanParams = abi.decode(
      _flashLoanParamsBytes,
      (FlashLoanParams)
    );
    return (_liquidateParams, _flashLoanParams);
  }

  /**
   * @dev Parsing out MarketType from different types of _paramBytes
   */
  function _getParamType(bytes calldata _paramBytes)
    internal
    pure
    returns (uint256)
  {
    bytes memory typeBytes = _paramBytes[0:32];
    return abi.decode(typeBytes, (uint256));
  }

  /**
   * @dev safeApprove to 0 and then safeApprove to `_amount`
   *
   * IMPORTANT: This logic is required for compatibility for USDT or other
   * token with this kind of compatibility issue. It's not needed for most
   * other tokens.
   */
  function _safeApprove(
    address _token,
    address _spender,
    uint256 _amount
  ) internal {
    IERC20(_token).safeApprove(_spender, 0);
    IERC20(_token).safeApprove(_spender, _amount);
  }

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
    address,
    address,
    uint256,
    bytes memory
  ) external virtual override returns (bytes4) {
    return this.onERC721Received.selector;
  }

  /**
   * @dev Should return whether the signature provided is valid for the provided data
   * @param hash      Hash of the data to be signed
   * @param signature Signature byte array associated with _data
   */
  function isValidSignature(bytes32 hash, bytes memory signature)
    external
    view
    returns (bytes4 magicValue)
  {
    address signer = ECDSA.recover(hash, signature);
    require(CONFIG.isExecutor(signer), "Signer invalid");
    // 0x1626ba7e is the interfaceId for signature contracts (see IERC1271)
    return 0x1626ba7e;
  }

  receive() external payable {}
}