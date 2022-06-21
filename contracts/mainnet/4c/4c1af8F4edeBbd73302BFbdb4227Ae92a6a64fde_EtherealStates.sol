//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

/// @title SignedAllowance
/// @author Simon Fremaux (@dievardump)
contract SignedAllowance {
    using ECDSA for bytes32;

    // list of already used allowances
    mapping(bytes32 => bool) public usedAllowances;

    // address used to sign the allowances
    address private _allowancesSigner;

    /// @notice Helper to know allowancesSigner address
    /// @return the allowance signer address
    function allowancesSigner() public view virtual returns (address) {
        return _allowancesSigner;
    }

    /// @notice Helper that creates the message that signer needs to sign to allow a mint
    ///         this is usually also used when creating the allowances, to ensure "message"
    ///         is the same
    /// @param account the account to allow
    /// @param nonce the nonce
    /// @return the message to sign
    function createMessage(address account, uint256 nonce)
        public
        view
        returns (bytes32)
    {
        return keccak256(abi.encode(account, nonce, address(this)));
    }

    /// @notice Helper that creates a list of messages that signer needs to sign to allow mintings
    /// @param accounts the accounts to allow
    /// @param nonces the corresponding nonces
    /// @return messages the messages to sign
    function createMessages(address[] memory accounts, uint256[] memory nonces)
        external
        view
        returns (bytes32[] memory messages)
    {
        require(accounts.length == nonces.length, '!LENGTH_MISMATCH!');
        messages = new bytes32[](accounts.length);
        for (uint256 i; i < accounts.length; i++) {
            messages[i] = createMessage(accounts[i], nonces[i]);
        }
    }

    /// @notice This function verifies that the current request is valid
    /// @dev It ensures that _allowancesSigner signed a message containing (account, nonce, address(this))
    ///      and that this message was not already used
    /// @param account the account the allowance is associated to
    /// @param nonce the nonce associated to this allowance
    /// @param signature the signature by the allowance signer wallet
    /// @return the message to mark as used
    function validateSignature(
        address account,
        uint256 nonce,
        bytes memory signature
    ) public view returns (bytes32) {
        return
            _validateSignature(account, nonce, signature, allowancesSigner());
    }

    /// @dev It ensures that signer signed a message containing (account, nonce, address(this))
    ///      and that this message was not already used
    /// @param account the account the allowance is associated to
    /// @param nonce the nonce associated to this allowance
    /// @param signature the signature by the allowance signer wallet
    /// @param signer the signer
    /// @return the message to mark as used
    function _validateSignature(
        address account,
        uint256 nonce,
        bytes memory signature,
        address signer
    ) internal view returns (bytes32) {
        bytes32 message = createMessage(account, nonce)
            .toEthSignedMessageHash();

        // verifies that the sha3(account, nonce, address(this)) has been signed by signer
        require(message.recover(signature) == signer, '!INVALID_SIGNATURE!');

        // verifies that the allowances was not already used
        require(usedAllowances[message] == false, '!ALREADY_USED!');

        return message;
    }

    /// @notice internal function that verifies an allowance and marks it as used
    ///         this function throws if signature is wrong or this nonce for this user has already been used
    /// @param account the account the allowance is associated to
    /// @param nonce the nonce
    /// @param signature the signature by the allowance wallet
    function _useAllowance(
        address account,
        uint256 nonce,
        bytes memory signature
    ) internal {
        bytes32 message = validateSignature(account, nonce, signature);
        usedAllowances[message] = true;
    }

    /// @notice Allows to change the allowance signer. This can be used to revoke any signed allowance not already used
    /// @param newSigner the new signer address
    function _setAllowancesSigner(address newSigner) internal {
        _allowancesSigner = newSigner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
pragma solidity ^0.8.12;

import {EtherealStatesMeta} from './EtherealStatesMeta.sol';

/// @title EtherealStates - https://etherealstates.art
/// @author Artist: GenuineHumanArt (https://twitter.com/GenuineHumanArt)
/// @author Developer: dievardump (https://twitter.com/dievardump, [email protected])
contract EtherealStates is EtherealStatesMeta {
    constructor(
        string memory contractURI_,
        address mintPasses,
        address newSigner,
        address dnaGenerator_,
        address metadataManager_,
        VRFConfig memory vrfConfig_
    )
        EtherealStatesMeta(
            contractURI_,
            mintPasses,
            newSigner,
            dnaGenerator_,
            metadataManager_,
            vrfConfig_
        )
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IERC721A, ERC721A, ERC721ABurnable} from 'erc721a/contracts/extensions/ERC721ABurnable.sol';

/// @title EtherealStatesCore
/// @author Artist: GenuineHumanArt (https://twitter.com/GenuineHumanArt)
/// @author Developer: dievardump (https://twitter.com/dievardump, [email protected])
/// @notice EtherealStates Core Logic
contract EtherealStatesCore is
    ERC721A('Ethereal States', 'ESTS'),
    ERC721ABurnable,
    Ownable
{
    error WithdrawError();

    /////////////////////////////////////////////////////////
    // Royalties                                           //
    /////////////////////////////////////////////////////////

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, IERC721A)
        returns (bool)
    {
        return
            interfaceId == this.royaltyInfo.selector ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Royalties - ERC2981
    /// @param tokenId the tokenId
    /// @param amount the amount it's sold for
    /// @return the recipient and amount to send to it
    function royaltyInfo(uint256 tokenId, uint256 amount)
        external
        view
        returns (address, uint256)
    {
        return (owner(), (amount * 5) / 100);
    }

    /////////////////////////////////////////////////////////
    // Gated Owner                                         //
    /////////////////////////////////////////////////////////

    /// @notice allows owner to withdraw funds from the contract
    function withdraw(address token) external onlyOwner {
        if (address(0) != token) {
            IERC20(token).transfer(
                msg.sender,
                IERC20(token).balanceOf(address(this))
            );
        } else {
            uint256 balance = address(this).balance;
            if (balance > 0) {
                //solhint-disable-next-line avoid-low-level-calls
                (bool success, ) = msg.sender.call{value: balance}('');
                if (!success) revert WithdrawError();
            }
        }
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/// @title EtherealStatesDNA
/// @author Artist: GenuineHumanArt (https://twitter.com/GenuineHumanArt)
/// @author Developer: dievardump (https://twitter.com/dievardump, [email protected])
/// @notice Generates DNA for EtherealStates NFTs
///         A big thank you to cxkoda (https://twitter.com/cxkoda) who helped me with the bit manipulation
///         & assembly and saved quite some gas.
contract EtherealStatesDNA {
    error WrongDistributionForLayer(uint256 layer, uint256 acc);

    function checkLayersValidity() public pure {
        unchecked {
            bytes memory layer;
            uint256 acc;
            uint256 i;
            for (uint256 j; j < 20; j++) {
                layer = getLayer(j);
                acc = 0;
                assembly {
                    for {
                        let current := add(layer, 0x20)
                        let length := mload(layer)
                    } lt(i, length) {
                        current := add(current, 2)
                        i := add(i, 2)
                    } {
                        acc := add(acc, sar(240, mload(current)))
                    }
                    i := 0
                }

                if (acc != 10000) {
                    revert WrongDistributionForLayer(j, acc);
                }
            }
        }
    }

    function generate(uint256 seed, bool includeHolderTraits)
        public
        pure
        returns (bytes32)
    {
        uint256 dna;
        uint256 random;

        unchecked {
            for (uint256 i; i < 20; i++) {
                // keccak the seed, very simple prng
                // we do it on each call, because even if Holders layer is not shown we want to be sure
                // the layers after stay the same with or without it
                seed = uint256(keccak256(abi.encode(seed)));

                // next random number
                random = seed % 10000;

                // push 8 null bits on the right side
                dna <<= 8;

                // done here and not in consumer, because getLayer(i) and pickOne are costly operations.
                // this way we save the gas when the trait is not included
                if (i != 12 || includeHolderTraits) {
                    // set the last 8 bits to the index of the asset in the layer
                    dna |= _pickOne(getLayer(i), random);
                }
            }

            // add 96 null bits right
            dna <<= 96;
        }
        return bytes32(dna);
    }

    function _pickOne(bytes memory layer, uint256 chance)
        public
        pure
        returns (uint256)
    {
        unchecked {
            uint256 i;
            assembly {
                for {
                    let current := add(layer, 0x20)
                    let acc
                } 1 {
                    // add 2 bytes to current position
                    current := add(current, 2)
                    i := add(i, 2)
                } {
                    // add the value of the 2 first bytes of current in acc
                    acc := add(acc, sar(240, mload(current)))
                    // if chance < acc
                    if lt(chance, acc) {
                        break
                    }
                }
                i := sar(1, i)
            }
            return i;
        }
    }

    // this is pretty dirty but this saves quite some gas
    // 1) putting the layers in storage would be very expensive when deploying & when reading storage
    // 2) using arrays of uint for that many assets (512), is too big for a contract
    // After tests, this seems to be a good working compromise
    function getLayer(uint256 which) public pure returns (bytes memory layer) {
        if (which == 0)
            layer = hex'01900190017c017c019001900006015e01900040017c00be0190000a0190015e017c017c0190015e001000680190017c0190017c00140020017c0087017c017c00df015e';
        else if (which == 1)
            layer = hex'012e0132007c00a0005e000a012c01e701e7000c000800b4006401e700a201e701e701e701e701bb01e701e7000e01e701b7000c01b701bb007c0130000e01e701e700a6';
        else if (which == 2)
            layer = hex'01b8019001b801b801a4011801cc01cc01cc0168001401cc01cc01b801cc01b801cc01b801b801b801b801cc01a401cc';
        else if (which == 3)
            layer = hex'004b003602080208020802080208004b00780208009102080110020802080208020801ae020801ae0208004f020802080208';
        else if (which == 4)
            layer = hex'007d004002080208020802080208004b020800a502080129020802080208020801c2020801c202080036020802080208';
        else if (which == 5)
            layer = hex'02260226021202120226021200d2012c022600aa02260096004002120212010400780212005602260212021202260226';
        else if (which == 6)
            layer = hex'01c201c200320064017201c201c20172001901c2017201720096017200960172003201c201c2017201c20064001901c2017201720064017201c201c2009601c2';
        else if (which == 7)
            layer = hex'00a01d4c005500780055009f00c700c7000700a000c700c7009f000500780055005500780005001e00c70078';
        else if (which == 8)
            layer = hex'01a901f401b301b301f401b301b301f401f4010e01f401f401b301f401b301f401a901f4005a01f40096001e01f401f4';
        else if (which == 9)
            layer = hex'020801b301b30208020801b300640208003c020800a001b301e501e501b30208015e020801b300c802080208015e0208';
        else if (which == 10)
            layer = hex'01e001fe019a019a01fe01e001fe01e0019a003201e001fe00960069004b01fe01fe01fe01fe01e001e001fe01fe019a';
        else if (which == 11)
            layer = hex'01f401f401f401f4012c01f40194019401e0001401e001f401f401e0000a019401e001e0019401f401f4019400fa01f4';
        else if (which == 12)
            layer = hex'0000032f032f032f032f032f032f01e00154032f01e00226032f032f032f';
        else if (which == 13)
            layer = hex'00780205020502050205008c01e002050205020501e0020500a000c001e001e00036020501e001e0020500fa02050205';
        else if (which == 14)
            layer = hex'020800be01e0020801e001fe01fe01e000fa003c01e0020800640208008c020801e00208020801e002080208020800a0';
        else if (which == 15)
            layer = hex'0194007801e0019401ea01ea01e00194000a019401ea01ea01ea01ea012c01e000fa01ea01ea01e001e001ea01ea0194';
        else if (which == 16)
            layer = hex'003201c2014301c201c2000a0143000f01c20143014301c200a000a00007005001c2003c00a001c2014301c201c201c201c201c201c201c2014301c201c200a0';
        else if (which == 17)
            layer = hex'00a00143005001a401a400f001a4006401a401a401a401a40143014301a4000a01a400f001a401a401a401a401a401a4014a01a400f000a0003c01430143002d';
        else if (which == 18)
            layer = hex'0143005001a401a401a4014301a40082002d01a4000a01a401a400f001a401a401a400a001a4004601a400a001a401430143014301a4017c00f001a4014a00f0';
        else if (which == 19)
            layer = hex'000a000a000a000a000a000a000a000a268e000a000a000a000a000a';
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {IERC721A, ERC721A} from 'erc721a/contracts/extensions/ERC721ABurnable.sol';

import {OwnableOperators} from '../utils/OwnableOperators.sol';

import {EtherealStatesMinter} from './EtherealStatesMinter.sol';
import {EtherealStatesVRF} from './EtherealStatesVRF.sol';
import {EtherealStatesDNA} from './EtherealStatesDNA.sol';

/// @title EtherealStatesMeta
/// @author Artist: GenuineHumanArt (https://twitter.com/GenuineHumanArt)
/// @author Developer: dievardump (https://twitter.com/dievardump, [email protected])
/// @notice EtherealStates Meta logic
contract EtherealStatesMeta is
    EtherealStatesMinter,
    EtherealStatesVRF,
    OwnableOperators
{
    error NotRevealed();
    error NonexistentToken();
    error WrongContext();
    error TooLate();

    /// @notice emitted whenever the DNA changes.
    event TokenDNAChanged(
        address operator,
        uint256 indexed tokenId,
        bytes32 oldDNA,
        bytes32 newDNA
    );

    /// @notice emitted whenever the random seed is set
    event RandomSeedSet(uint256 randomSeed);

    /// @notice ChainLink Random Seed
    uint256 public randomSeed;

    /// @notice DNA Generator contract
    address public dnaGenerator;

    /// @notice Metadata manager
    address public metadataManager;

    /// @notice this allows to save the DNA in the contract instead of having to generate
    ///         it every time we call tokenDNA()
    mapping(uint256 => bytes32) public revealedDNA;

    string public contractURI;

    /////////////////////////////////////////////////////////
    // Modifiers                                           //
    /////////////////////////////////////////////////////////

    // stops minting after reveal
    modifier onlyBeforeReveal() {
        if (requestId != 0) {
            revert TooLate();
        }
        _;
    }

    // allows some stuff only after reveal
    modifier onlyAfterReveal() {
        if (randomSeed == 0) {
            revert TooEarly();
        }
        _;
    }

    constructor(
        string memory contractURI_,
        address mintPasses,
        address newSigner,
        address dnaGenerator_,
        address metadataManager_,
        VRFConfig memory vrfConfig_
    )
        EtherealStatesMinter(mintPasses, newSigner)
        EtherealStatesVRF(vrfConfig_)
    {
        contractURI = contractURI_;
        dnaGenerator = dnaGenerator_;
        metadataManager = metadataManager_;
    }

    /////////////////////////////////////////////////////////
    // Getters                                             //
    /////////////////////////////////////////////////////////

    function tokenURI(uint256 tokenId)
        public
        view
        override(IERC721A, ERC721A)
        returns (string memory)
    {
        if (!_exists(tokenId)) {
            revert NonexistentToken();
        }

        return EtherealStatesMinter(metadataManager).tokenURI(tokenId);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    /// @notice Get the DNA for a givent tokenId
    /// @param tokenId the token id to get the DNA for
    /// @return dna the DNA
    function tokenDNA(uint256 tokenId)
        public
        view
        onlyAfterReveal
        returns (bytes32 dna)
    {
        if (!_exists(tokenId)) {
            revert NonexistentToken();
        }

        dna = revealedDNA[tokenId];

        if (dna == 0x0) {
            dna = _tokenDNA(tokenId);
        }
    }

    function tokensDNA(uint256 startId, uint256 howMany)
        public
        view
        returns (bytes32[] memory dnas)
    {
        bytes32 dna;
        dnas = new bytes32[](howMany);
        for (uint256 i; i < howMany; i++) {
            dna = revealedDNA[startId + i];
            if (dna == 0x0) {
                dna = _tokenDNA(startId + i);
            }
            dnas[i] = dna;
        }
    }

    /////////////////////////////////////////////////////////
    // Setters                                             //
    /////////////////////////////////////////////////////////

    /// @notice Allows to save the DNA of a tokenId so it doesn't need to be recomputed
    ///         after that
    /// @param tokenId the token id to reveal
    /// @return dna the DNA
    function revealDNA(uint256 tokenId)
        external
        onlyAfterReveal
        returns (bytes32 dna)
    {
        if (!_exists(tokenId)) {
            revert NonexistentToken();
        }

        dna = revealedDNA[tokenId];

        // only reveal if not already revealed
        if (dna == 0x0) {
            dna = _tokenDNA(tokenId);
            revealedDNA[tokenId] = dna;
            emit TokenDNAChanged(msg.sender, tokenId, 0x0, dna);
        }
    }

    /////////////////////////////////////////////////////////
    // Gated Operator                                      //
    /////////////////////////////////////////////////////////

    /// @notice Allows an Operator to update a token DNA
    /// @param tokenId the token id to update the DNA of
    /// @param newDNA the new DNA
    function updateTokenDNA(uint256 tokenId, bytes32 newDNA)
        external
        onlyOperator
    {
        if (!_exists(tokenId)) {
            revert NonexistentToken();
        }

        // the caller must be approved by the owner
        if (!isApprovedForAll(ownerOf(tokenId), msg.sender)) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        bytes32 dna = revealedDNA[tokenId];
        if (dna == 0x0) {
            revert NotRevealed();
        }

        revealedDNA[tokenId] = newDNA;
        emit TokenDNAChanged(msg.sender, tokenId, dna, newDNA);
    }

    /////////////////////////////////////////////////////////
    // Gated Owner                                         //
    /////////////////////////////////////////////////////////

    /// @notice Allows owner to update metadataManager
    /// @param newManager the new address of the metadata manager
    function setMetadataManager(address newManager) external onlyOwner {
        metadataManager = newManager;
    }

    /// @notice Allows owner to update dna generator
    /// @param newGenerator the new address of the dna generator
    function setDNAGenerator(address newGenerator) external onlyOwner {
        dnaGenerator = newGenerator;
    }

    /// @notice Allows to start the reveal process once everything is minted or time's up
    /// @dev this can only be used beforeReveal, so once the seed is set, this can't be called again
    ///      if the call, for any reason, fails,
    function startReveal() external onlyOwner {
        // only call if requestId is 0
        if (requestId != 0) {
            revert WrongContext();
        }
        currentTier = 0;
        _requestRandomWords();
    }

    /// @notice Allows to reset the requestId, if, for some reason, the ChainLink call does not work
    /// @dev this can only be used beforeReveal, so once the seed is set, this can't be called again
    function resetRequestId() external onlyOwner {
        if (requestId == 0 || randomSeed != 0) {
            revert WrongContext();
        }
        requestId = 0;
    }

    /// @notice Allows owner to update the VRFConfig if something is not right
    /// @dev this can only be used beforeReveal, so once the seed is set, this can't be called again
    function setVRFConfig(VRFConfig memory vrfConfig_)
        external
        onlyOwner
        onlyBeforeReveal
    {
        vrfConfig = vrfConfig_;
    }

    /////////////////////////////////////////////////////////
    // Internals                                           //
    /////////////////////////////////////////////////////////

    // called when ChainLink answers with the random number
    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory words
    ) internal override {
        randomSeed = words[0];
        emit RandomSeedSet(randomSeed);
    }

    function _tokenDNA(uint256 tokenId) internal view returns (bytes32) {
        return
            EtherealStatesDNA(dnaGenerator).generate(
                uint256(keccak256(abi.encode(randomSeed, tokenId))),
                hasHoldersTrait(tokenId)
            );
    }

    function _mintStates(
        address to,
        uint256 quantity,
        uint256 free,
        bool addHoldersTrait
    ) internal override onlyBeforeReveal {
        super._mintStates(to, quantity, free, addHoldersTrait);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {SignedAllowance} from '@0xdievardump/signed-allowances/contracts/SignedAllowance.sol';

import {PrimeList} from '../libraries/PrimeList.sol';

import {EtherealStatesCore} from './EtherealStatesCore.sol';

/// @title EtherealStatesMinter
/// @author Artist: GenuineHumanArt (https://twitter.com/GenuineHumanArt)
/// @author Developer: dievardump (https://twitter.com/dievardump, [email protected])
/// @notice EtherealStates Minter logic
contract EtherealStatesMinter is EtherealStatesCore, SignedAllowance {
    error LengthMismatch();
    error TooManyRequested();
    error UnknownItem();

    error WrongMintProcess();
    error TooEarly();

    error WrongValue();

    error OneMintCallPerBlockForContracts();

    /// @notice Emitted so we can know which tokens have the HoldersTrait and quickly generate after reveal
    /// @param startTokenId the starting id
    /// @param quantity the amount of ids
    event TokensWithHoldersTrait(uint256 startTokenId, uint256 quantity);

    uint256 public constant START_TOKEN_INDEX = 1;

    uint256 public constant MAX_SUPPLY = 7000;

    uint256 public constant MAX_PUBLIC = 6;

    uint256 public constant MAX_PER_LIST = 2;

    uint256 public constant MINT_BUNDLE = 5;

    uint256 public constant MINT_PRICE = 0.08 ether;

    address public immutable MINT_PASSES_HOLDER;

    uint256 public currentTier;

    uint256 public teamAllocation = 40;

    uint256 private _extraDataMint;

    /// @notice quantity minted for an address in the allow list + public mint
    mapping(address => uint256) public mintsCounter;

    /// @notice last tx.origin mint block when using contracts
    mapping(address => uint256) private _contractLastBlockMinted;

    /////////////////////////////////////////////////////////
    // Modifiers                                           //
    /////////////////////////////////////////////////////////

    modifier onlyMinimumTier(uint256 tier) {
        if (currentTier < tier) {
            revert TooEarly();
        }
        _;
    }

    // this modifier helps to protect against people using contracts to mint
    // a big amount of NFTs in one call
    // for people minting through contracts (custom or even Gnosis-Safe)
    // we impose a limit on tx.origin of one call per block
    // ensuring a loop can not be used, but still allowing contract minting.
    // This allows Gnosis & other contracts wallets users to still be able to mint
    // This is not the perfect solution, but it's a "not perfect but I'll take it" compromise
    modifier protectOrigin() {
        if (tx.origin != msg.sender) {
            if (block.number == _contractLastBlockMinted[tx.origin]) {
                revert OneMintCallPerBlockForContracts();
            }
            _contractLastBlockMinted[tx.origin] = block.number;
        }
        _;
    }

    constructor(address mintPasses, address newSigner) {
        MINT_PASSES_HOLDER = mintPasses;

        _setAllowancesSigner(newSigner);
    }

    /////////////////////////////////////////////////////////
    // Getters                                             //
    /////////////////////////////////////////////////////////

    function hasHoldersTrait(uint256 tokenId) public view returns (bool) {
        return _ownershipOf(tokenId).extraData == 1;
    }

    /////////////////////////////////////////////////////////
    // Minting                                             //
    /////////////////////////////////////////////////////////

    function mintPublic(uint256 quantity)
        external
        payable
        onlyMinimumTier(3)
        protectOrigin
    {
        uint256 alreadyMinted = mintsCounter[msg.sender];
        if (alreadyMinted + quantity > MAX_PUBLIC) {
            revert TooManyRequested();
        }
        mintsCounter[msg.sender] = alreadyMinted + quantity;

        _mintStates(msg.sender, quantity, 0, false);
    }

    function mintWithAllowlist(
        uint256 quantity,
        uint256 nonce,
        bytes memory signature
    ) external payable onlyMinimumTier(2) {
        // first validate signature
        validateSignature(msg.sender, nonce, signature);

        // then make sure the account doesn't try to mint more than MAX_PER_LIST
        uint256 alreadyMinted = mintsCounter[msg.sender];
        if (alreadyMinted + quantity > MAX_PER_LIST) {
            revert TooManyRequested();
        }

        // update minted
        mintsCounter[msg.sender] = alreadyMinted + quantity;

        _mintStates(msg.sender, quantity, 0, false);
    }

    function mintWithPasses(
        uint256[] memory ids,
        uint256[] memory amounts,
        bool addHoldersTrait
    ) external payable onlyMinimumTier(1) {
        // calculate how many to mint and how many are free
        uint256 free;
        uint256 quantity;
        uint256 length = ids.length;
        for (uint256 i; i < length; i++) {
            if (ids[i] == 1) {
                free += amounts[i];
            }
            quantity += amounts[i];
        }

        // we are not using safeMint so we can do that here.
        _mintStates(msg.sender, quantity, free, addHoldersTrait);

        // burn all the passes; will revert if someone tries to do weird stuff with
        // ids & amounts
        IERC1155Burnable(MINT_PASSES_HOLDER).burnBatch(
            msg.sender,
            ids,
            amounts
        );
    }

    /////////////////////////////////////////////////////////
    // Gated                                               //
    /////////////////////////////////////////////////////////

    /// @notice Allows owner to set current tier for the mint
    /// @notice (0 = no mint, 1 = holders, 2 = holders & allowlist, 3 = hholders & allowlist & public)
    /// @param newTier the new value for the current tier
    function setTier(uint256 newTier) external onlyOwner {
        currentTier = newTier;
    }

    /// @notice Allows owner to set the current signer for the allowlist
    /// @param newSigner the address of the new signer
    function setAllowancesSigner(address newSigner) external onlyOwner {
        _setAllowancesSigner(newSigner);
    }

    function teamMint(
        address[] calldata accounts,
        uint256[] calldata quantities
    ) external onlyOwner {
        uint256 length = accounts.length;

        if (accounts.length != quantities.length) {
            revert LengthMismatch();
        }

        uint256 _teamAllocation = teamAllocation;

        for (uint256 i; i < length; i++) {
            // will revert if too many requested
            _teamAllocation -= quantities[i];

            _mintStates(accounts[i], quantities[i], quantities[i], false);
        }

        teamAllocation = _teamAllocation;
    }

    /// @dev for tests; might forget to remove, so it's lock on testnets ids
    function testMints(
        address to,
        uint256 quantity,
        bool addHoldersTrait
    ) external onlyOwner {
        require(block.chainid == 4 || block.chainid == 31337, 'OnlyTests()');
        _mintStates(to, quantity, quantity, addHoldersTrait);
    }

    /////////////////////////////////////////////////////////
    // Internals                                           //
    /////////////////////////////////////////////////////////

    // start at START_TOKEN_INDEX
    function _startTokenId() internal pure override returns (uint256) {
        return START_TOKEN_INDEX;
    }

    function _mintStates(
        address to,
        uint256 quantity,
        uint256 free,
        bool addHoldersTrait
    ) internal virtual {
        // check that there is enough supply
        if (_totalMinted() + quantity > MAX_SUPPLY) {
            revert TooManyRequested();
        }

        // check we have the right amount of ethereum with the tx
        if (msg.value != (quantity - free) * MINT_PRICE) {
            revert WrongValue();
        }

        // there is supply, mint price is good, lfgo
        uint256 nextTokenId = _nextTokenId();

        if (addHoldersTrait) {
            _extraDataMint = 1;
        }

        // here we make bundles of MINT_BUNDLE in order to have a mint not too expensive, but also
        // not transfer too much the cost of minting to future Transfers, which is what ERC721A does.
        if (quantity > MINT_BUNDLE) {
            uint256 times = quantity / MINT_BUNDLE;
            for (uint256 i; i < times; i++) {
                _mint(to, MINT_BUNDLE);
            }

            if (quantity % MINT_BUNDLE != 0) {
                _mint(to, quantity % MINT_BUNDLE);
            }
        } else {
            _mint(to, quantity);
        }

        if (addHoldersTrait) {
            _extraDataMint = 0;
            emit TokensWithHoldersTrait(nextTokenId, quantity);
        }
    }

    /// @dev Used to set the "hasHoldersTrait" flag on a token at minting time
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual override returns (uint24) {
        // if minting, return the _extraDataMint value
        if (from == address(0)) {
            return uint24(_extraDataMint);
        }
        // else return the current value
        return previousExtraData;
    }
}

interface IERC1155Burnable {
    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {VRFCoordinatorV2Interface} from '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import {VRFConsumerBaseV2} from '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';

/// @title EtherealStatesVRF
/// @author Artist: GenuineHumanArt (https://twitter.com/GenuineHumanArt)
/// @author Developer: dievardump (https://twitter.com/dievardump, [email protected])
/// @notice EtherealStates VRF logic
contract EtherealStatesVRF is VRFConsumerBaseV2 {
    struct VRFConfig {
        bytes32 keyHash;
        address coordinator;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        uint16 requestConfirmations;
        uint32 numWords;
    }

    /// @notice ChainLink request id
    uint256 public requestId;

    /// @notice ChainLink config
    VRFConfig public vrfConfig;

    constructor(VRFConfig memory vrfConfig_)
        VRFConsumerBaseV2(vrfConfig_.coordinator)
    {
        vrfConfig = vrfConfig_;
    }

    /// @dev basic call using the vrfConfig
    function _requestRandomWords() internal virtual {
        VRFConfig memory vrfConfig_ = vrfConfig;
        // Will revert if subscription is not set and funded.
        requestId = VRFCoordinatorV2Interface(vrfConfig_.coordinator)
            .requestRandomWords(
                vrfConfig_.keyHash,
                vrfConfig_.subscriptionId,
                vrfConfig_.requestConfirmations,
                vrfConfig_.callbackGasLimit,
                vrfConfig_.numWords
            );
    }

    /// @dev needs to be overrode in the consumer contract
    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory
    ) internal virtual override {}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library PrimeList {
    // gets one of 100 primes in the list.
    function getPrime(uint256 index) internal pure returns (uint256) {
        return
            [
                2057982841,
                3869875883,
                8288889667,
                5583593761,
                6533057819,
                9823362113,
                7668713989,
                4895050343,
                8419848407,
                7466022211,
                3659662393,
                9344063951,
                9484074533,
                9033570737,
                4149710647,
                3236460443,
                7023522617,
                7557150893,
                4120054093,
                7478304191,
                1667055199,
                7911602089,
                2013632897,
                6708874279,
                1636635757,
                5424215549,
                7454377537,
                9920454443,
                8959001237,
                1389441451,
                3840126163,
                3722149259,
                8699921891,
                7956864961,
                5755991279,
                9422009873,
                7121899249,
                1221867313,
                2571008851,
                4216079773,
                5180142449,
                5884142287,
                8424633037,
                2855803127,
                9930029801,
                1655760173,
                8221814719,
                1703940299,
                9490790363,
                1988399783,
                7757984219,
                6607369759,
                1128581473,
                1641979019,
                2039141267,
                5684186393,
                6436080187,
                2420852747,
                4700296903,
                3632109049,
                6052282381,
                2222123201,
                2976802139,
                6211642961,
                7643093261,
                5019701891,
                4009686067,
                6030261227,
                8322941219,
                3113781061,
                5390087597,
                3036730759,
                2455383097,
                3754516219,
                1838205091,
                1769815771,
                1233893939,
                2023283659,
                2591069053,
                8297378923,
                7924516513,
                9132407111,
                1300651171,
                7470231641,
                2907967981,
                7991100277,
                9377211707,
                2131963397,
                5310841027,
                4630539619,
                3048557969,
                6376558717,
                2518366199,
                5481503539,
                8618038133,
                7908297451,
                1043354203,
                6745996333,
                3880507187,
                5311321111
            ][index % 100];
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title Operators
/// @author Simon Fremaux (@dievardump)
contract Operators {
    error NotAuthorized();
    error InvalidAddress(address invalid);

    mapping(address => bool) public operators;

    modifier onlyOperator() virtual {
        if (!isOperator(msg.sender)) revert NotAuthorized();
        _;
    }

    /// @notice tells if an account is an operator or not
    /// @param account the address to check
    function isOperator(address account) public view virtual returns (bool) {
        return operators[account];
    }

    /// @dev set operator state to `isOperator` for ops[]
    function _editOperators(address[] memory ops, bool isOperatorRole)
        internal
    {
        for (uint256 i; i < ops.length; i++) {
            if (ops[i] == address(0)) revert InvalidAddress(ops[i]);
            operators[ops[i]] = isOperatorRole;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';

import './Operators.sol';

/// @title OwnableOperators
/// @author Simon Fremaux (@dievardump)
contract OwnableOperators is Ownable, Operators {
    ////////////////////////////////////////////
    // Only Owner                             //
    ////////////////////////////////////////////

    /// @notice add new operators
    /// @param ops the list of operators to add
    function addOperators(address[] memory ops) external onlyOwner {
        _editOperators(ops, true);
    }

    /// @notice add a new operator
    /// @param operator the operator to add
    function addOperator(address operator) external onlyOwner {
        address[] memory ops = new address[](1);
        ops[0] = operator;
        _editOperators(ops, true);
    }

    /// @notice remove operators
    /// @param ops the list of operators to remove
    function removeOperators(address[] memory ops) external onlyOwner {
        _editOperators(ops, false);
    }

    /// @notice remove an operator
    /// @param operator the operator to remove
    function removeOperator(address operator) external onlyOwner {
        address[] memory ops = new address[](1);
        ops[0] = operator;
        _editOperators(ops, false);
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.1.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';

/**
 * @dev ERC721 token receiver interface.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard,
 * including the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at `_startTokenId()`
 * (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A {
    // Mask of an entry in packed address data.
    uint256 private constant BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with `_mintERC2309`.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to `_mintERC2309`
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The tokenId of the next token to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See `_packedOwnershipOf` implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    // - [232..255] `extraData`
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see `_totalMinted`.
     */
    function totalSupply() public view override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to `_startTokenId()`
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view returns (uint256) {
        return _burnCounter;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes of the XOR of
        // all function selectors in the interface. See: https://eips.ethereum.org/EIPS/eip-165
        // e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> BITPOS_NUMBER_MINTED) & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> BITPOS_NUMBER_BURNED) & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & BITMASK_AUX_COMPLEMENT) | (auxCasted << BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
                    uint256 packed = _packedOwnerships[curr];
                    // If not burned.
                    if (packed & BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an ownership that has an address and is not burned
                        // before an ownership that does not have an address and is not burned.
                        // Hence, curr will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed is zero.
                        while (packed == 0) {
                            packed = _packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> BITPOS_START_TIMESTAMP);
        ownership.burned = packed & BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> BITPOS_EXTRA_DATA);
    }

    /**
     * Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, BITMASK_ADDRESS)
            // `owner | (block.timestamp << BITPOS_START_TIMESTAMP) | flags`.
            result := or(owner, or(shl(BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << BITPOS_NEXT_INITIALIZED`.
            result := shl(BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSenderERC721A()) revert ApproveToCaller();

        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex && // If within bounds,
            _packedOwnerships[tokenId] & BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = _currentIndex;
                uint256 index = end - quantity;
                do {
                    if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (index < end);
                // Reentrancy protection.
                if (_currentIndex != end) revert();
            }
        }
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            uint256 tokenId = startTokenId;
            uint256 end = startTokenId + quantity;
            do {
                emit Transfer(address(0), to, tokenId++);
            } while (tokenId < end);

            _currentIndex = end;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * This function is intended for efficient minting only during contract creation.
     *
     * It emits only one {ConsecutiveTransfer} as defined in
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
     * instead of a sequence of {Transfer} event(s).
     *
     * Calling this function outside of contract creation WILL make your contract
     * non-compliant with the ERC721 standard.
     * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
     * {ConsecutiveTransfer} event is only permissible during contract creation.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function _mintERC2309(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > MAX_MINT_ERC2309_QUANTITY_LIMIT) revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(startTokenId, startTokenId + quantity - 1, address(0), to);

            _currentIndex = startTokenId + quantity;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        mapping(uint256 => address) storage tokenApprovalsPtr = _tokenApprovals;
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId]`.
        assembly {
            // Compute the slot.
            mstore(0x00, tokenId)
            mstore(0x20, tokenApprovalsPtr.slot)
            approvedAddressSlot := keccak256(0x00, 0x40)
            // Load the slot's value from storage.
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    /**
     * @dev Returns whether the `approvedAddress` is equals to `from` or `msgSender`.
     */
    function _isOwnerOrApproved(
        address approvedAddress,
        address from,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
            // Mask `from` to the lower 160 bits, in case the upper bits somehow aren't clean.
            from := and(from, BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, BITMASK_ADDRESS)
            // `msgSender == from || msgSender == approvedAddress`.
            result := or(eq(msgSender, from), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isOwnerOrApproved(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                to,
                BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isOwnerOrApproved(approvedAddress, from, _msgSenderERC721A()))
                if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (BITMASK_BURNED | BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
    }

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << BITPOS_EXTRA_DATA;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred.
     * This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred.
     * This includes minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function _toString(uint256 value) internal pure returns (string memory ptr) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.
            ptr := add(mload(0x40), 128)
            // Update the free memory pointer to allocate.
            mstore(0x40, ptr)

            // Cache the end of the memory to calculate the length later.
            let end := ptr

            // We write the string from the rightmost digit to the leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // Costs a bit more than early returning for the zero case,
            // but cheaper in terms of deployment and overall runtime costs.
            for {
                // Initialize and perform the first pass without check.
                let temp := value
                // Move the pointer 1 byte leftwards to point to an empty character slot.
                ptr := sub(ptr, 1)
                // Write the character to the pointer. 48 is the ASCII index of '0'.
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp {
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            } {
                // Body of the for loop.
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }

            let length := sub(end, ptr)
            // Move the pointer 32 bytes leftwards to make room for the length.
            ptr := sub(ptr, 32)
            // Store the length.
            mstore(ptr, length)
        }
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.1.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set through `_extraData`.
        uint24 extraData;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     *
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);

    // ==============================
    //            IERC165
    // ==============================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // ==============================
    //            IERC721
    // ==============================

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

    // ==============================
    //        IERC721Metadata
    // ==============================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // ==============================
    //            IERC2309
    // ==============================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId` (inclusive) is transferred from `from` to `to`,
     * as defined in the ERC2309 standard. See `_mintERC2309` for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.1.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721ABurnable.sol';
import '../ERC721A.sol';

/**
 * @title ERC721A Burnable Token
 * @dev ERC721A Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721ABurnable is ERC721A, IERC721ABurnable {
    /**
     * @dev Burns `tokenId`. See {ERC721A-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual override {
        _burn(tokenId, true);
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.1.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../IERC721A.sol';

/**
 * @dev Interface of an ERC721ABurnable compliant contract.
 */
interface IERC721ABurnable is IERC721A {
    /**
     * @dev Burns `tokenId`. See {ERC721A-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) external;
}