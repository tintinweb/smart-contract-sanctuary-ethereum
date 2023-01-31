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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
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
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
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
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
error NotOwner();
error NewTicketTrackerDurationMustBeGreaterThanLastIndex();
error NewTicketsPerDayMustBeGreaterThanLastIndex();
error QueryForNonexistentToken();
error InvalidProof();

struct TicketRateTracker {
    uint128 stakingDurationBeforeLookingToNextRewardRate;
    uint128 ticketsPerDay;
}

contract PuffPuffPandasStaking is Ownable {
    IERC721Minimal private immutable PANDAS;    
    ITrippieLandMinimal public  trippieLand;
    struct Ownership {
        address owner;
        uint96 lastUpdatedTimestamp;
    }
    // uint public constant MAX_SUPPLY = 6666;
    mapping(uint => Ownership) public ownership;
    mapping(address => uint) public balanceOf;
    mapping(uint => uint) private ticketsCollected;
    bytes32 public traitMultiplierMerkleRoot;
    /*
    Leaves Are
    {uint256:tokenId,uint256:multiplier}
    */
    uint public trippieMultiplier = 2;

    TicketRateTracker[] public ticketRateTrackers;
constructor(address _pandas) {
        PANDAS = IERC721Minimal(_pandas);
        ticketRateTrackers.push(TicketRateTracker(0, 1)); //0 days
        ticketRateTrackers.push(TicketRateTracker(7 days, 2)); //7 days
        ticketRateTrackers.push(TicketRateTracker(21 days, 3)); //21 days
        ticketRateTrackers.push(TicketRateTracker(28 days, 4)); //28 days

        

    }

    function getAllTicketRateTrackers() external view returns (TicketRateTracker[] memory) {
        return ticketRateTrackers;
    }
    //TODO: Test This Function
    ///@dev multiplier is based on the token's traits
    function updateTicketsCollected(uint tokenId,bytes32 root, uint multiplier,bytes32[] calldata proof) internal {
        uint numTickets;
        Ownership memory _ownership = ownership[tokenId];
        uint96 lastUpdatedTimestamp = _ownership.lastUpdatedTimestamp;
        if(lastUpdatedTimestamp == 0) return;
        uint arrLength = ticketRateTrackers.length;
        uint durationStaked = block.timestamp - lastUpdatedTimestamp;
        if(!checkProof(tokenId,root,multiplier,proof)) revert InvalidProof();
       unchecked {
    //copilot stop here
    for(uint i; i<arrLength;++i){
        if(durationStaked > ticketRateTrackers[i].stakingDurationBeforeLookingToNextRewardRate){
            numTickets += ticketRateTrackers[i].ticketsPerDay * (durationStaked / 1 days);
            durationStaked -= ticketRateTrackers[i].stakingDurationBeforeLookingToNextRewardRate;
        } else {
            numTickets += ticketRateTrackers[i].ticketsPerDay * (durationStaked / 1 days);
            break;
        }

    }
       }
        ticketsCollected[tokenId] += numTickets;

    }

    function batchGetTotalTicketsEarned(uint[] calldata tokenIds,uint[] calldata discounts,bytes32[][] calldata proofs) external view returns(uint[] memory){
        uint[] memory arr = new uint[](tokenIds.length);
        for(uint i; i<tokenIds.length;++i){
            arr[i] = getTotalTicketsEarned(tokenIds[i],discounts[i],proofs[i]);
        }
        return arr;
    }

    //TODO: Test This Function
    function getTotalTicketsEarned (uint tokenId,uint discount,bytes32[] calldata proof) public view returns (uint) {
        uint collectedSinceLastUpdate = ticketsCollected[tokenId];
        uint numTicketsOwed;
        Ownership memory _ownership = ownership[tokenId];
        uint96 lastUpdatedTimestamp = _ownership.lastUpdatedTimestamp;
        if(lastUpdatedTimestamp == 0) return collectedSinceLastUpdate;
        uint arrLength = ticketRateTrackers.length;
        uint durationStaked = block.timestamp - lastUpdatedTimestamp;
        if(!checkProof(tokenId,traitMultiplierMerkleRoot,discount,proof)) revert InvalidProof();

        unchecked {
            for (uint i; i < arrLength; ++i) {
                if (durationStaked > ticketRateTrackers[i].stakingDurationBeforeLookingToNextRewardRate) {
                    numTicketsOwed += ticketRateTrackers[i].ticketsPerDay * (durationStaked / 1 days);
                    durationStaked -= ticketRateTrackers[i].stakingDurationBeforeLookingToNextRewardRate;
                } else {
                    numTicketsOwed += ticketRateTrackers[i].ticketsPerDay * (durationStaked / 1 days);
                    break;
                }
            }
        }
        return collectedSinceLastUpdate + numTicketsOwed;

    }

    function checkProof(uint tokenId,bytes32 root, uint multiplier,bytes32[] calldata proof) internal pure returns (bool) {
        return MerkleProof.verify(proof,root,keccak256(abi.encodePacked(tokenId,multiplier)));
    }
    
    function batchGetDailyRewardRate(uint[]calldata tokenIds,uint[] calldata multipliers,bytes32[][] calldata proofs) external view returns(uint[] memory){
        uint[] memory arr = new uint[](tokenIds.length);
        for(uint i; i<tokenIds.length;++i){
            arr[i] = getDailyRewardRate(tokenIds[i],multipliers[i],proofs[i]);
        }
        return arr;
    }
    function getDailyRewardRate(uint tokenId,uint multiplier,bytes32[] calldata proof) public view returns (uint) {
        if (tokenId < _startTokenId()) revert QueryForNonexistentToken();
        uint numTickets;
        Ownership memory _ownership = ownership[tokenId];
        uint96 lastUpdatedTimestamp = _ownership.lastUpdatedTimestamp;
        if(lastUpdatedTimestamp == 0) return 0;
        uint arrLength = ticketRateTrackers.length;
        uint durationStaked = block.timestamp - lastUpdatedTimestamp;
        if(!checkProof(tokenId,traitMultiplierMerkleRoot,multiplier,proof)) revert InvalidProof();

        unchecked {
            for (uint i; i < arrLength; ++i) {
                uint stakingDurationToBeat = ticketRateTrackers[i]
                    .stakingDurationBeforeLookingToNextRewardRate;
                if (i == arrLength - 1) {
                    if (durationStaked > stakingDurationToBeat)
                        numTickets = ticketRateTrackers[i].ticketsPerDay;
                    else {
                        numTickets = ticketRateTrackers[i - 1].ticketsPerDay;
                    }
                    break;
                }
                if (durationStaked > stakingDurationToBeat) continue;
                else {
                    numTickets = ticketRateTrackers[i - 1].ticketsPerDay;
                    break;
                }
            }
        }
        return numTickets;
    }

    function pushNewTicketRateTracker(
        uint128 stakingDurationBeforeLookingToNextRewardRate,
        uint128 ticketsPerDay
    ) external onlyOwner {
        //Make sure the new tracker is greater than the last tracker
        if (ticketRateTrackers.length == 0) {
            ticketRateTrackers.push(
                TicketRateTracker(
                    stakingDurationBeforeLookingToNextRewardRate,
                    ticketsPerDay
                )
            );
            return;
        }
        TicketRateTracker memory trackerAtLastIndex = ticketRateTrackers[
            ticketRateTrackers.length - 1
        ];
        if (
            stakingDurationBeforeLookingToNextRewardRate <
            trackerAtLastIndex.stakingDurationBeforeLookingToNextRewardRate
        ) revert NewTicketTrackerDurationMustBeGreaterThanLastIndex();
        if (ticketsPerDay < trackerAtLastIndex.ticketsPerDay)
            revert NewTicketsPerDayMustBeGreaterThanLastIndex();
        ticketRateTrackers.push(
            TicketRateTracker(
                stakingDurationBeforeLookingToNextRewardRate,
                ticketsPerDay
            )
        );
    }

    function modifyTicketTracker(
        uint128 stakingDurationBeforeLookingToNextRewardRate,
        uint128 ticketsPerDay,
        uint index
    ) external onlyOwner {
        uint len = ticketRateTrackers.length;
        if (index >= len) revert("Invalid Length");
        //Up To Owner Discretion to make sure the new tracker is greater than the last tracker
        ticketRateTrackers[index] = TicketRateTracker(
            stakingDurationBeforeLookingToNextRewardRate,
            ticketsPerDay
        );
    }

    function stakePanda(uint tokenId)  internal {
        if (msg.sender != PANDAS.ownerOf(tokenId)) revert NotOwner();
        ownership[tokenId].owner = msg.sender;
        ownership[tokenId].lastUpdatedTimestamp = uint96(block.timestamp);
        PANDAS.transferFrom(msg.sender, address(this), tokenId);
    }

    function unstakePanda(uint tokenId,bytes32 root,uint multiplier,bytes32[] calldata proof) internal {
        if (msg.sender != ownership[tokenId].owner) revert NotOwner();
        updateTicketsCollected(tokenId,root,multiplier,proof);
        delete ownership[tokenId].owner;
        delete ownership[tokenId].lastUpdatedTimestamp;
        PANDAS.transferFrom(address(this), msg.sender, tokenId);
    }

    function stakePandas(uint[] calldata tokenIds) external {
        for (uint i; i < tokenIds.length; ) {
            stakePanda(tokenIds[i]);
            unchecked {
                ++i;
            }
        }
        balanceOf[msg.sender] += tokenIds.length;
    }

    function unstakePandas(uint[] calldata tokenIds,uint[] calldata multipliers,bytes32[][] calldata proofs) external {
        bytes32 root = traitMultiplierMerkleRoot;
        for (uint i; i < tokenIds.length; ) {
            unstakePanda(tokenIds[i],root,multipliers[i],proofs[i]);
            unchecked {
                ++i;
            }
        }
        balanceOf[msg.sender] -= tokenIds.length;
    }

    function tokensOfOwner(
        address account
    ) external view returns (uint[] memory) {
        unchecked {
            uint tokenIdsIdx;
            uint tokenIdsLength = balanceOf[account];
            uint[] memory tokenIds = new uint256[](tokenIdsLength);
            for (uint i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                address _owner = ownership[i].owner;
                if (_owner != address(0)) {
                    if (account == _owner) {
                        tokenIds[tokenIdsIdx++] = i;
                    }
                }
            }
            return tokenIds;
        }
    }

    function getTicketRateTrackers()
        external
        view
        returns (TicketRateTracker[] memory)
    {
        return ticketRateTrackers;
    }

    function _startTokenId() internal pure returns (uint) {
        return 1;
    }
    function setTrippieMultiplier(uint _multiplier) external onlyOwner {
        trippieMultiplier = _multiplier;
    }
    function setTrippieLand (address _trippieLand) external onlyOwner {
        trippieLand = ITrippieLandMinimal(_trippieLand);
    }
    function setTraitMultiplierMerkleRoot(bytes32 _root) external onlyOwner {
        traitMultiplierMerkleRoot = _root;
    }
}

interface IERC721Minimal {
    function ownerOf(uint tokenId) external view returns (address);

    function transferFrom(address from, address to, uint tokenId) external;
}

interface ITrippieLandMinimal {
    function isMutant(uint tokenId) external view returns (bool);
}