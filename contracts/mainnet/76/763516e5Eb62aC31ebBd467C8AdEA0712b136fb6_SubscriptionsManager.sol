// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

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
pragma solidity ^0.8.9;

import '../../libraries/interfaces/ISubscriptions.sol';
import '../../libraries/interfaces/ISubscriptionsManager.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

/// @title Redlion Subscription Manager
/// @author Gui "Qruz" Rodrigues
/// @notice Management of payments and info of subcriptions
/// @dev Portal contract to all subscriptions tokens of REDLION
/*
  Each user is allowed to have a single subscription active,
  It is not possible to have a normal subscription and a super subscription simultaneously
  The following features are locked when the user is subscribed :
    - Transfer from (if subscription is SUPER)
      => The user is still allowed to burn their token
        Doing so will invalidate the subscription and every feature that comes the associated token
    - Transfer to 
    - Subscrption via contract
  Users still mainting 100% ownership of their tokens, they can sell them or give them
  but not hold multiple subscription tokens.

  
  Subscribed status : User is defined as subscribed whenever he holds a subscription token.
*/

contract SubscriptionsManager is
  Ownable,
  ReentrancyGuard,
  ISubscriptionsManager
{
  using Strings for uint256;
  using ECDSA for bytes32;

  mapping(SubType => uint256) PRICE;

  address SIGNER;

  address RED_ADDRESS;
  address GOLD_ADDRESS;

  /// @notice Construtor function defining basic parameters
  /// @dev subscription contract addresses can be null
  /// @param _red Super subscription contract address
  /// @param _gold Normal Subscroption contract address
  constructor(address _red, address _gold) {
    RED_ADDRESS = _red;
    GOLD_ADDRESS = _gold;
    setSubPrice(SubType.NORMAL, 99900);
    setSubPrice(SubType.SUPER, 299900);
  }

  /*///////////////////////////////////////////////////////////////
                             EVENTS
  ///////////////////////////////////////////////////////////////*/

  /// @notice Event emited when a user subscribes to a SuperSubscription
  /// @param to the subscriber address
  /// @param subType the type of subscription
  event Subscribe(address indexed to, SubType indexed subType);

  /*///////////////////////////////////////////////////////////////
                          SUBSCRIPTIONS
  ///////////////////////////////////////////////////////////////*/

  /// @notice Function subscribing the user depending on params
  /// @dev Internal function
  /// @param to target address
  /// @param subType Type of subscription
  function _subscribe(address to, SubType subType) internal {
    require(isSubscribed(to) == false, 'WALLET_ALREADY_SUBSCRIBED');
    if (subType == SubType.SUPER) {
      ISubscriptions(RED_ADDRESS).subscribe(to);
    } else if (subType == SubType.NORMAL) {
      ISubscriptions(GOLD_ADDRESS).subscribe(to);
    } else {
      revert('INVALID_SUB_TYPE');
    }

    emit Subscribe(to, subType);
  }

  /**
    This function was created with the intent of setting the price off chain.

    Although there's a PRICE mapping for each subscription type, these are only used as a signle source of truth
    that can be verified by the user. We're allowed to create discounts by changing the price in the signature.

    The price value in the signature should match the value of the transaction.

    Signature structure :
      - target address
      - contract address (in case we deploy a different subscription manager or use same signer in the future for different contract using the same logic)
      - Susbcription type (number id of enum)
      - Value (ethers price)
      - Timestamp of signature creation (seconds)

    @dev The signature contains data validating : price, valdiity (time) and contract address (contract) to avoid exploits
    @param subType the type of subscription
    @param timestamp the timestamp (seconds) when the signature was created
    @param signature the signature validating the subscription
     */

  function subscribe(
    SubType subType,
    uint256 timestamp,
    bytes memory signature
  ) public payable nonReentrant {
    require(block.timestamp < timestamp + 10 minutes, 'INVALID_TIMESTAMP');
    // Validate signature
    bytes32 inputHash = keccak256(
      abi.encodePacked(
        msg.sender,
        address(this),
        uint256(subType),
        msg.value,
        timestamp
      )
    );
    require(_validSignature(signature, inputHash), 'BAD_SIGNATURE');

    _subscribe(msg.sender, subType);
  }

  /*///////////////////////////////////////////////////////////////
                            SUB STATE
  ///////////////////////////////////////////////////////////////*/

  function isSubscribed(
    address target
  ) public view override(ISubscriptionsManager) returns (bool) {
    return
      ISubscriptions(RED_ADDRESS).isSubscribed(target) ||
      ISubscriptions(GOLD_ADDRESS).isSubscribed(target);
  }

  function whichType(address target) public view returns (SubType) {
    if (ISubscriptions(RED_ADDRESS).isSubscribed(target)) return SubType.SUPER;
    else if (ISubscriptions(GOLD_ADDRESS).isSubscribed(target))
      return SubType.NORMAL;
    return SubType.NONE;
  }

  function subscriptionInfo(
    address target
  ) public view override(ISubscriptionsManager) returns (SubInfo memory) {
    SubInfo memory info = SubInfo(false, SubType.NONE, 0, '');

    ISubscriptions superSubs = ISubscriptions(RED_ADDRESS);
    ISubscriptions normalSubs = ISubscriptions(GOLD_ADDRESS);

    if (normalSubs.isSubscribed(target)) {
      info.timestamp = normalSubs.when(target);
      info.subscribed = true;
      info.subType = SubType.NORMAL;
      info.subId = normalSubs.subscriptionId(target);
    } else if (superSubs.isSubscribed(target)) {
      info.timestamp = superSubs.when(target);
      info.subscribed = true;
      info.subType = SubType.SUPER;
      info.subId = superSubs.subscriptionId(target);
    }
    return info;
  }

  /*///////////////////////////////////////////////////////////////
                          OWNER FUNCTIONS
  ///////////////////////////////////////////////////////////////*/

  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  /// @notice Owner subscription function
  /// @dev Bypasses signature verification (owner only)
  /// @param to the target address
  /// @param subType the subscription type
  function ownerSubscribe(address to, SubType subType) public onlyOwner {
    _subscribe(to, subType);
  }

  /*///////////////////////////////////////////////////////////////
                              UTILITY
  ///////////////////////////////////////////////////////////////*/

  function _isValidSubType(SubType _subType) internal pure {
    require(
      _subType == SubType.NORMAL || _subType == SubType.SUPER,
      'INVALID_SUB_TYPE'
    );
  }

  /// @notice Sets the new signer address
  /// @dev this function is used when the current signer address has been compromised or access lost
  /// @param _address the new signer address
  function setSigner(address _address) public onlyOwner {
    SIGNER = _address;
  }

  /// @notice Set normal subscriptions contract address
  /// @param _contractAddress the new contract adddress
  function setSubscriptions(address _contractAddress) public onlyOwner {
    GOLD_ADDRESS = _contractAddress;
  }

  /// @notice Set super subscriptions contract address
  /// @param _contractAddress the new contract adddress
  function setSuperSubscriptions(address _contractAddress) public onlyOwner {
    RED_ADDRESS = _contractAddress;
  }

  /// @notice Set price for a specific subscription type
  /// @param _subType the subscription type
  /// @param _price the new price
  function setSubPrice(SubType _subType, uint256 _price) public onlyOwner {
    _isValidSubType(_subType);
    PRICE[_subType] = _price;
  }

  /// @notice Getter for a specific subscription type price
  /// @param _subType the subscription type id
  /// @return uint256 the subcription's price
  function getPrice(SubType _subType) external view returns (uint256) {
    _isValidSubType(_subType);
    return PRICE[_subType];
  }

  function _validSignature(
    bytes memory signature,
    bytes32 msgHash
  ) internal view returns (bool) {
    return msgHash.toEthSignedMessageHash().recover(signature) == SIGNER;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISubscriptions {

  function subscribe(address to) external;

  function isSubscribed(address target) external view returns (bool);

  function subscribers() external view returns (address[] memory);

  function subscriptionId(address target) external view returns (bytes memory);

  function when(address target) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISubscriptionsManager {
  enum SubType {
    NORMAL,
    SUPER,
    NONE
  }

  struct SubInfo {
    bool subscribed;
    SubType subType;
    uint256 timestamp;
    bytes subId;
  }

  function isSubscribed(address target) external view returns (bool);

  function subscriptionInfo(
    address target
  ) external view returns (SubInfo memory);
}