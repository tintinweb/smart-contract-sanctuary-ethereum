// SPDX-License-Identifier: UNLICENCED

pragma solidity ^0.8.8;

import "./YetAnotherCoin.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @title A BSC-ETH blockchain bridge implementation for 
///        a sample ERC-20 token. 
/// @author Sfy Mantissa
contract Bridge {

  using Counters for Counters.Counter;
  using ECDSA for bytes32;

  /// @dev ERC-20 token interface used.
  IYetAnotherCoin public token;

  /// @dev Initiating the bridge transaction counter.
  Counters.Counter public nonce;

  /// @dev Used to prevent nonce collisions.
  mapping(uint256 => bool) public nonceIsUsed;

  /// @dev Triggers both upon `swap` and `redeem`.
  event SwapInitialized (
    address user,
    uint256 amount,
    uint256 nonce,
    bool isRedeem
  );

  /// @dev YAC token address may be different for BSC/ETH networks, so
  ///      it's set in the constructor.
  constructor(address _tokenAddress) {
    token = IYetAnotherCoin(_tokenAddress);
  }

  /// @notice Start the swap and burn `_amount` of YAC tokens from
  ///         the caller's address.
  /// @param _amount The quantity of tokens to be burned in the first network.
  function swap(uint256 _amount)
    external
  {
    token.burn(msg.sender, _amount);

    emit SwapInitialized(
      msg.sender,
      _amount,
      nonce.current(),
      false
    );

    nonce.increment();
  }

  /// @notice End the swap and mint `_amount` of YAC tokens to the caller 
  ///         address, verifying the request with `_signature` and `_nounce`.
  /// @dev ECDSA library is used to check whether the transaction was signed
  ///      by the caller.
  /// @param _signature Signed message hash.
  /// @param _amount The amount of YAC tokens to be transferred.
  /// @param _nonce Bridge operation counter value.
  function redeem(
    bytes calldata _signature,
    uint256 _amount,
    uint256 _nonce
  ) 
    external
  {

    require(
      nonceIsUsed[_nonce] == false, 
      "ERROR: Nonce was used previously."
    );

    nonceIsUsed[_nonce] = true;

    bytes32 signature = keccak256(
      abi.encodePacked(
        msg.sender,
        address(this),
        _amount,
        _nonce
      )
    );

    require(
      ECDSA.recover(
        signature.toEthSignedMessageHash(),
        _signature
    ) == msg.sender,
      "ERROR: Signature is invalid."
    );

    token.mint(msg.sender, _amount);

    emit SwapInitialized(
      msg.sender,
      _amount,
      _nonce,
      true
    );
  }

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.8;

/// @author Sfy Mantissa
/// @title  A simple ERC-20-compliant token I made to better understand the
///         ERC-20 standard.
interface IYetAnotherCoin {

  /// @notice Gets triggered upon any action where tokens are moved
  ///         between accounts: transfer(), transferFrom(), mint(), burn().
  event Transfer(
    address indexed seller,
    address indexed buyer,
    uint256 amount
  );

  /// @notice Gets triggeted upon a successful approve() call.
  event Approval(
    address indexed owner,
    address indexed delegate,
    uint256 amount
  );

  /// @notice Get token `balance` of the `account`.
  /// @param account Address of the account.
  function balanceOf(address account)
    external
    view
    returns (uint256);

  /// @notice Get the allowance provided by the account to delegate.
  /// @param account Address of the account.
  /// @param delegate Address of the delegate.
  function allowance(address account, address delegate)
    external
    view
    returns (uint256);

  /// @notice Get token's human-readable name.
  function name()
    external
    view
    returns (string memory);

  /// @notice Get token's acronym representation.
  function symbol()
    external
    view
    returns (string memory);

  /// @notice Get token's decimals for end-user representation.
  function decimals()
    external
    view
    returns (uint8);

  /// @notice Get token's total supply.
  function totalSupply()
    external
    view
    returns (uint256);

  /// @notice Allows to transfer a specified `amount` of tokens between
  ///         the caller and the `buyer`
  /// @param  buyer Address of the recepient.
  /// @param  amount Number of tokens to be transferred.
  /// @return Flag to tell whether the call succeeded.
  function transfer(address buyer, uint256 amount)
    external
    returns (bool);

  /// @notice Allows to transfer a specified `amount` of tokens on behalf
  ///         of `seller` by the delegate.
  /// @dev    Delegate must have enough allowance.
  /// @param  seller Address of the wallet to withdraw tokens from.
  /// @param  buyer Address of the recepient.
  /// @param  amount Number of tokens to be transferred.
  /// @return Flag to tell whether the call succeeded.
  function transferFrom(address seller, address buyer, uint256 amount)
    external
    returns (bool);

  /// @notice Allows the caller to delegate spending the specified `amount`
  ///         of tokens from caller's wallet by the `delegate`.
  /// @param  delegate Address of the delegate.
  /// @param  amount Number of tokens to be allowed for transfer.
  /// @return Flag to tell whether the call succeeded.
  function approve(address delegate, uint256 amount)
    external
    returns (bool);

  /// @notice Allows the caller to burn the specified `amount` of tokens
  ///         from the `account` and decrease the `totalSupply 
  ///         by the `amount`.
  /// @param  account Address of the burned account.
  /// @param  amount Number of tokens to be burned.
  function burn(address account, uint256 amount)
    external
    returns (bool);

  /// @notice Allows the caller to give the specified `amount` of tokens
  ///         to the `account` and increase `totalSupply` by the `amount`.
  /// @param  account Address of the recepient.
  /// @param  amount Number of tokens to be transferred.
  function mint(address account, uint256 amount)
    external
    returns (bool);

}

contract YetAnotherCoin is IYetAnotherCoin {

  mapping(address => uint256) public balanceOf;
  mapping(address => mapping(address => uint256)) public allowance;
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;

  constructor(
    string memory _name,
    string memory _symbol,
    uint8 _decimals,
    uint256 initialSupply
  )
  {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;  
    mint(msg.sender, initialSupply);
  }

  function transfer(address buyer, uint256 amount) 
    external
    returns (bool)
  {
    _transfer(msg.sender, buyer, amount);
    return true;
  }

  function transferFrom(address seller, address buyer, uint256 amount)
    external
    returns (bool)
  {
    _transfer(seller, buyer, amount);
    _spendAllowance(seller, msg.sender, amount);
    return true;
  }

  function approve(address delegate, uint256 amount)
    external
    returns (bool)
  {
    require(delegate != address(0), "Delegate must have a non-zero address!");

    allowance[msg.sender][delegate] = amount;

    emit Approval(msg.sender, delegate, amount);
    return true;
  }

  function burn(address account, uint256 amount)
    external
    returns (bool)
  {
    require(
      account != address(0),
      "Burner account must have a non-zero address!"
    );

    require(
      balanceOf[account] >= amount,
      "Burn amount must not exceed balance!"
    );
    
    unchecked {
      balanceOf[account] -= amount;
    }

    totalSupply -= amount;

    emit Transfer(account, address(0), amount);
    return true;
  }

  function mint(address account, uint256 amount)
    public
    returns (bool)
  {
    require(
      account != address(0),
      "Receiving account must have a non-zero address!"
    );

    totalSupply += amount;
    balanceOf[account] += amount;

    emit Transfer(address(0), account, amount);
    return true;
  }

  function _transfer(address seller, address buyer, uint256 amount)
    internal
  {
    require(seller != address(0), "Seller must have a non-zero address!");
    require(buyer != address(0), "Buyer must have a non-zero address!");
    require(
      balanceOf[seller] >= amount,
      "Seller does not have the specified amount!"
    );

    unchecked {
      balanceOf[seller] -= amount;
    }

    balanceOf[buyer] += amount;

    emit Transfer(seller, buyer, amount);
  }

  function _spendAllowance(address seller, address delegate, uint256 amount)
    internal
  {
    require(
      allowance[seller][delegate] >= amount,
      "Delegate does not have enough allowance!"
    );

    unchecked {
      allowance[seller][delegate] -= amount;
    }
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

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