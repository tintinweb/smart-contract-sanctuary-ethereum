// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Shamanz DA Refunds
/// @author @KfishNFT
contract ShamanzRefund is Ownable, ReentrancyGuard {
    /// @notice Merkle Root used to verify if an address is part of the refund one list
    bytes32 public merkleRootOne;
    /// @notice Merkle Root used to verify if an address is part of the refund Two list
    bytes32 public merkleRootTwo;
    /// @notice Merkle Root used to verify if an address is part of the refund Three list
    bytes32 public merkleRootThree;
    /// @notice Used to keep track of addresses that have been refunded
    mapping(address => bool) public daRefunded;
    mapping(address => bool) public wlRefunded;
    mapping(address => bool) public alRefunded;
    /// @notice Toggleable flag for refund state
    bool public isRefundActive;
    /// @notice Wich refund phase are we in?
    bool public da = true;
    bool public wl = false;
    bool public al = false;
    /// @notice Refund amount for people who minted one Shamanz in DA
    uint256 public refundOneAmount = 0.35 ether;
    /// @notice Refund amount for people who minted two Shamanz in DA
    uint256 public refundTwoAmount = 0.7 ether;
    /// @notice Refund amount for people who minted three Shamanz in DA
    uint256 public refundThreeAmount = 1.05 ether;

    /// @notice Contract constructor
    /// @dev The merkle root can be added later if required
    /// @notice Emit event once ETH is received
    /// @param sender The sender of ETH
    /// @param value The amount of ETH
    event Received(address indexed sender, uint256 value);

    /// @notice Emit event once ETH is refunded
    /// @param sender The address being refunded
    /// @param value The amount of ETH
    event Refunded(address indexed sender, uint256 value);

    /// @notice Allow contract to receive eth
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /// @dev requires a valid merkleRoot to function
    /// @param _merkleProof the proof sent by an refundable user
    function refund(bytes32[] calldata _merkleProof, uint256 _toRefund) external nonReentrant {
        require(isRefundActive, "Refunding is not active yet");
        if (da) require(!daRefunded[msg.sender], "Already refunded");
        if (wl) require(!wlRefunded[msg.sender], "Already refunded");
        if (al) require(!alRefunded[msg.sender], "Already refunded");

        uint256 toPay = refundOneAmount;

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (_toRefund == 1) require(MerkleProof.verify(_merkleProof, merkleRootOne, leaf), "not refundable");

        if (_toRefund == 2) {
            require(MerkleProof.verify(_merkleProof, merkleRootTwo, leaf), "not refundable");
            toPay = refundTwoAmount;
        }

        if (_toRefund == 3) {
            require(MerkleProof.verify(_merkleProof, merkleRootThree, leaf), "not refundable");
            toPay = refundThreeAmount;
        }

        if (da) daRefunded[msg.sender] = true;
        if (wl) wlRefunded[msg.sender] = true;
        if (al) alRefunded[msg.sender] = true;

        if(toPay > 0) {
            (bool os, ) = payable(msg.sender).call{value: toPay}("");
            require(os);
            emit Refunded(msg.sender, toPay);
        }
    }

    /// @notice Function that sets refunding active or inactive
    /// @dev only callable from the contract owner
    function toggleIsRefundActive() external onlyOwner {
        isRefundActive = !isRefundActive;
    }

    /// @notice Set refund amounts for people who minted Shamanz in DA
    /// @param refundOneAmount_ Refund amount for people who minted one Shamanz in DA
    /// @param refundTwoAmount_ Refund amount for people who minted two Shamanz in DA
    /// @param refundThreeAmount_ Refund amount for people who minted three Shamanz in DA
    function setRefundAmounts(
        uint256 refundOneAmount_,
        uint256 refundTwoAmount_,
        uint256 refundThreeAmount_
    ) external onlyOwner {
        refundOneAmount = refundOneAmount_;
        refundTwoAmount = refundTwoAmount_;
        refundThreeAmount = refundThreeAmount_;
    }

    /// @notice Sets the merkle root for refunds verification
    /// @dev only callable from the contract owner
    /// @param merkleRootOne_ used to verify the refund list of one mint
    /// @param merkleRootTwo_ used to verify the refund list of two mints
    /// @param merkleRootThree_ used to verify the refund list of three mints
    function setMerkleRoots(
        bytes32 merkleRootOne_,
        bytes32 merkleRootTwo_,
        bytes32 merkleRootThree_
    ) external onlyOwner {
        merkleRootOne = merkleRootOne_;
        merkleRootTwo = merkleRootTwo_;
        merkleRootThree = merkleRootThree_;
    }

    /// @notice Sets refund phase DA
    /// @dev only callable from the contract owner
    /// @param _activate active phase
    function setDa(bool _activate) external onlyOwner {
        da = _activate;
    }

    /// @notice Sets refund phase WL
    /// @dev only callable from the contract owner
    /// @param _activate active phase
    function setWl(bool _activate) external onlyOwner {
        wl = _activate;
    }

    /// @notice Sets refund phase AL
    /// @dev only callable from the contract owner
    /// @param _activate active phase
    function setAl(bool _activate) external onlyOwner {
        al = _activate;
    }

    /// @notice Withdraw function in case anyone sends ETH to contract by mistake
    /// @dev only callable from the contract owner
    function withdraw() external payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
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