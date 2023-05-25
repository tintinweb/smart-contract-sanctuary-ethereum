// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Ownable} from "openzeppelin/access/Ownable.sol";
import {MerkleProofLib} from "solmate/utils/MerkleProofLib.sol";

contract GasRewardsDistributor is Ownable {
    receive() external payable {}

    mapping(bytes32 root => uint16 round) public rootsToRounds;
    mapping(uint16 round => uint64 endTime) public roundEndTimes;
    mapping(bytes32 packedRecipientAndRound => bool used) public claimedRewards;

    event Claimed(address recipient, uint16 round, uint256 amount);

    error RoundNotOpen();
    error AlreadyClaimed();
    error InvalidProof();
    error TransferFailed();
    error NotEnoughEtherInContract();
    error InvalidRoundId();

    constructor() {
        if (msg.sender != tx.origin) {
            transferOwnership(tx.origin);
        }
    }

    function _packRecipientAndRound(address _address, uint16 _round) internal pure returns (bytes32) {
        return (bytes32(uint256(uint160(_address))) << 96) | bytes32(uint256(_round));
    }

    function claim(bytes32 merkleRoot, uint256 amount, bytes32[] calldata proof) public payable {
        if (amount > address(this).balance) revert NotEnoughEtherInContract();

        // Look up the round for the given merkle root, verify that it's open
        uint16 round = rootsToRounds[merkleRoot];
        if (round == 0) revert InvalidRoundId();
        if (block.timestamp > roundEndTimes[round]) revert RoundNotOpen();

        // Verify that the user hasn't already claimed for this round
        bytes32 packedRecipientAndRound = _packRecipientAndRound(msg.sender, round);
        if (claimedRewards[packedRecipientAndRound]) revert AlreadyClaimed();

        // Validate merkle proof
        if (!MerkleProofLib.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender, amount, round)))) {
            revert InvalidProof();
        }

        // Perform all state changes before sending Ether
        claimedRewards[packedRecipientAndRound] = true;
        emit Claimed(msg.sender, round, amount);

        (bool success,) = payable(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed();
    }

    function setRoundEndTime(uint16 round, uint32 endTime) public onlyOwner {
        // Round can't be 0 because that's how we check for round existence
        if (round == 0) revert InvalidRoundId();
        roundEndTimes[round] = endTime;
    }

    function setRoundMerkleRoot(uint16 round, bytes32 merkleRoot) public onlyOwner {
        // We don't check if the round is 0, because that's how we delete a merkle root
        rootsToRounds[merkleRoot] = round;
    }

    function withdraw(uint256 amount) public onlyOwner {
        (bool success,) = payable(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed();
    }
}

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
pragma solidity >=0.8.0;

/// @notice Gas optimized merkle proof verification library.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/MerkleProofLib.sol)
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/utils/MerkleProofLib.sol)
library MerkleProofLib {
    function verify(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool isValid) {
        assembly {
            if proof.length {
                // Left shifting by 5 is like multiplying by 32.
                let end := add(proof.offset, shl(5, proof.length))

                // Initialize offset to the offset of the proof in calldata.
                let offset := proof.offset

                // Iterate over proof elements to compute root hash.
                // prettier-ignore
                for {} 1 {} {
                    // Slot where the leaf should be put in scratch space. If
                    // leaf > calldataload(offset): slot 32, otherwise: slot 0.
                    let leafSlot := shl(5, gt(leaf, calldataload(offset)))

                    // Store elements to hash contiguously in scratch space.
                    // The xor puts calldataload(offset) in whichever slot leaf
                    // is not occupying, so 0 if leafSlot is 32, and 32 otherwise.
                    mstore(leafSlot, leaf)
                    mstore(xor(leafSlot, 32), calldataload(offset))

                    // Reuse leaf to store the hash to reduce stack operations.
                    leaf := keccak256(0, 64) // Hash both slots of scratch space.

                    offset := add(offset, 32) // Shift 1 word per cycle.

                    // prettier-ignore
                    if iszero(lt(offset, end)) { break }
                }
            }

            isValid := eq(leaf, root) // The proof is valid if the roots match.
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