// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ITrinviNFT.sol";
// import "hardhat/console.sol";

contract Sale is Ownable {

  // =============================================================
  //                            EVENTS
  // =============================================================
  event BatchSet(Batch);

  // =============================================================
  //                            ERRORS
  // =============================================================
  error BatchShouldStartAfterLastBatch();
  error BatchStartMustBeInFuture();
  error BatchEndMustBeAfterStart();
  error LastBatchDoesNotEnd();
  error BatchNotFound();
  error BatchNotYetStarted();
  error BatchHasPassed();
  error InsufficientValueForMint();
  error NotRegisteredInCurrentBatch();
  error MintQtyExceedsMaxSale();
  error MintQtyExceedsMaxSalePerAccount();
  error MustEndInTheFuture();
  error BatchAlreadyHasEndDate();
  error AirdropStartMustBeInFuture();
  error AirdropNotFound();
  error NotRegisteredInAirdrop();
  error MintQtyExceedsMaxQty();
  error MintQtyExceedsMaxQtyPerAccount();
  error AirdropNotYetStarted();
  error AirdropHasPassed();


  // =============================================================
  //                            STRUCTS
  // =============================================================
  struct BatchParam {
    string name;
    uint256 start;
    uint256 end; // set end to 0 if no end
    uint price;
    uint maxSale; // Set to 0 if no max
    uint maxSalePerAccount; // Set to 0 if no max
    bool mustRegister;
  }

  struct Batch {
    uint idx;
    string name;
    uint256 start;
    uint256 end; // set end to 0 if no end
    uint price;
    uint maxSale; // Set to 0 if no max
    uint maxSalePerAccount; // Set to 0 if no max
    uint qtySold; // track the number of qty sold
    bytes32 whitelistMerkleRoot; //
    bool mustRegister;
  }

  struct BatchClaim {
    uint batchIdx;
    address claimer;
    uint qtyClaimed;
  }

  /// Airdrops does not have have to start and end in sequences like Batch do
  struct AirdropParam {
    string name;
    uint256 start;
    uint256 end; // set end to 0 if no end
    uint maxClaim;
    uint maxClaimPerAccount;
  }

  struct Airdrop {
    uint idx;
    string name;
    uint256 start;
    uint256 end; // set end to 0 if no end
    uint maxClaim;
    uint maxClaimPerAccount;
    uint qtyClaimed;
    bytes32 whitelistMerkleRoot;
  }

  struct AirdropClaim {
    uint airdropIdx;
    address claimer;
    uint qtyClaimed;
  }

  // =============================================================
  //                            STORAGE
  // =============================================================
  address public _nftAddress;
  uint public _lastBatchIdx;
  uint public _lastAirdropIdx;

  // =============================================================
  //                            MAPPINGS
  // =============================================================
  // id => Batch
  mapping (uint => Batch) public _batches;
  mapping (uint => Airdrop) public _airdrops;
  mapping (uint => mapping(address => BatchClaim)) public _batchClaims;
  mapping (uint => mapping(address => AirdropClaim)) public _airdropClaims;


  // =============================================================
  //                            MODIFIERS
  // =============================================================
  modifier mustSendSufficientValue(uint qty, uint batchIdx) {
    Batch memory currBatch = _batches[batchIdx];
    if (msg.value < (currBatch.price * qty)) {
      revert InsufficientValueForMint();
    }
    _;
  }

  modifier followsBatchRules(uint batchIdx, uint mintQty, bytes32[] calldata merkleProof) {
    Batch memory currBatch = _batches[batchIdx];
    if (currBatch.idx == 0) {
      revert BatchNotFound();
    }
    BatchClaim memory batchClaim = _batchClaims[batchIdx][msg.sender];
    if (!hasStarted(currBatch.start)) {
      revert BatchNotYetStarted();
    }
    if (hasPassed(currBatch.end)) {
      revert BatchHasPassed();
    }
    if (currBatch.mustRegister && !_isInWhitelist(msg.sender, currBatch.whitelistMerkleRoot, merkleProof)) {
      revert NotRegisteredInCurrentBatch();
    }
    if (!doesNotExceedMaxQty(mintQty, currBatch.maxSale, currBatch.qtySold)) {
      revert MintQtyExceedsMaxSale();
    }
    if (!isAllowedToMintQty(mintQty, currBatch.maxSalePerAccount, batchClaim.qtyClaimed)) {
      revert MintQtyExceedsMaxSalePerAccount();
    }
    _;
  }

  function hasStarted(uint start) internal view returns (bool) {
    if (start > 0 && block.timestamp < start) {
      return false;
    }
    return true;
  }

  function hasPassed(uint end) internal view returns (bool) {
    if (end > 0 && block.timestamp > end) {
      return true;
    }
    return false;
  }

  function _isInWhitelist(address msgSender, bytes32 whitelistMerkleRoot, bytes32[] calldata merkleProof_) internal pure returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(msgSender));
    bool isValidProof = MerkleProof.verify(merkleProof_, whitelistMerkleRoot, leaf);
    return isValidProof;
  }

  function isAllowedToMintQty(uint qty, uint maxQtyPerAccount, uint qtyMinted) internal pure returns (bool) {
    if (maxQtyPerAccount == 0) {
      return true;
    }
    uint allowedMintQty = maxQtyPerAccount - qtyMinted;
    if (qty > allowedMintQty) {
      return false;
    }
    return true;
  }

  function doesNotExceedMaxQty(uint qty, uint maxQty, uint qtyMinted) internal pure returns (bool) {
    if (maxQty == 0) {
      return true;
    }
    uint qtyRemaining = maxQty - qtyMinted;
    if (qty > qtyRemaining) {
      return false;
    }
    return true;
  }

  modifier followsAirdropRules(uint airdropIdx, uint mintQty, bytes32[] calldata merkleProof) {
    Airdrop memory airdrop = _airdrops[airdropIdx];
    AirdropClaim memory airdropClaim = _airdropClaims[airdropIdx][msg.sender];
    if (!hasStarted(airdrop.start)) {
      revert AirdropNotYetStarted();
    }
    if (hasPassed(airdrop.end)) {
      revert AirdropHasPassed();
    }
    if (!_isInWhitelist(msg.sender, airdrop.whitelistMerkleRoot, merkleProof)) {
      revert NotRegisteredInAirdrop();
    }
    if (!doesNotExceedMaxQty(mintQty, airdrop.maxClaim, airdrop.qtyClaimed)) {
      revert MintQtyExceedsMaxQty();
    }
    if (!isAllowedToMintQty(mintQty, airdrop.maxClaimPerAccount, airdropClaim.qtyClaimed)) {
      revert MintQtyExceedsMaxQtyPerAccount();
    }
    _;
  }

  constructor(address nftAddress) {
    _nftAddress = nftAddress;
  }

  function mintTo(address to, uint qty, uint batchIdx, bytes32[] calldata merkleProof) external payable
    mustSendSufficientValue(qty, batchIdx)
    followsBatchRules(batchIdx, qty, merkleProof)
  {
    ITrinviNFT(_nftAddress).mintTo(to, qty);
    recordBatchActivity(msg.sender, batchIdx, qty);
  }

  function claimAirdrop(address to, uint qty, uint airdropIdx, bytes32[] calldata merkleProof)
    external
    followsAirdropRules(airdropIdx, qty, merkleProof)
  {
    ITrinviNFT(_nftAddress).mintTo(to, qty);
    recordAirdropActivity(msg.sender, airdropIdx, qty);
  }

  function batches(uint index) public view returns (Batch memory) {
    return _batches[index];
  }

  function currentBatch() public view returns (Batch memory batch_) {
    for (uint i = _lastBatchIdx; i > 0; i--) {
      Batch memory batch = _batches[i];
      if (block.timestamp >= batch.start && batch.end == 0) {
        return batch;
      }
      if (block.timestamp >= batch.start && block.timestamp < batch.end) {
        return batch;
      }
    }
  }

  function addBatches(BatchParam[] calldata batches_) external onlyOwner {
    for (uint i = 0; i < batches_.length; i++) {
      addBatch(batches_[i]);
    }
  }

  function addBatch(BatchParam calldata batchParam) internal {
    validateBatchParam(batchParam);

    _lastBatchIdx++;

    Batch memory batch = Batch({
      idx: _lastBatchIdx,
      name: batchParam.name,
      start: batchParam.start,
      end: batchParam.end, // set end to 0 if no end
      price: batchParam.price,
      maxSale: batchParam.maxSale, // Set to 0 if no max
      maxSalePerAccount: batchParam.maxSalePerAccount, // Set to 0 if no max
      mustRegister: batchParam.mustRegister,
      whitelistMerkleRoot: bytes32(0),
      qtySold: 0 // track the number of qty sold
    });
    _batches[_lastBatchIdx] = batch;
  }

  function setLastBatchEnd(uint batchEnd_) external onlyOwner {
    Batch memory batch = _batches[_lastBatchIdx];
    if (batch.end > 0) {
      revert BatchAlreadyHasEndDate();
    }
    if (batchEnd_ < batch.start) {
      revert BatchEndMustBeAfterStart();
    }
    batch.end = batchEnd_;
    _batches[_lastBatchIdx] = batch;
  }

  function validateBatchParam(BatchParam memory batch) internal view {
    if (batch.start < block.timestamp) {
      revert BatchStartMustBeInFuture();
    }
    if (batch.end > 0 && batch.start > batch.end) {
      revert BatchEndMustBeAfterStart();
    }
    if (_lastBatchIdx > 0) {
      Batch memory lastBatch = _batches[_lastBatchIdx];
      if (lastBatch.end == 0) {
        revert LastBatchDoesNotEnd();
      }
      if (batch.start <= lastBatch.end) {
        revert BatchShouldStartAfterLastBatch();
      }
    }
  }

  function registerAddressesToBatch(bytes32 whitelistMerkleRoot, uint batchIdx) external onlyOwner {
    Batch memory batch = _batches[batchIdx];
    if (batch.idx == 0) {
      revert BatchNotFound();
    }
    batch.whitelistMerkleRoot = whitelistMerkleRoot;
    _batches[batchIdx] = batch;
  }

  function isInBatchWhitelist(address address_, uint batchIdx, bytes32[] calldata merkleProof) external view returns (bool) {
    Batch memory batch = _batches[batchIdx];
    if (batch.idx == 0) {
      revert BatchNotFound();
    }
    return _isInWhitelist(address_, batch.whitelistMerkleRoot, merkleProof);
  }

  function isInAirdropWhitelist(address address_, uint airdropIdx, bytes32[] calldata merkleProof) external view returns (bool) {
    Airdrop memory airdrop = _airdrops[airdropIdx];
    if (airdrop.idx == 0) {
      revert AirdropNotFound();
    }
    return _isInWhitelist(address_, airdrop.whitelistMerkleRoot, merkleProof);
  }

  function recordBatchActivity(address msgSender, uint batchIdx, uint mintQty) internal returns (BatchClaim memory claim) {
    claim = _batchClaims[batchIdx][msgSender];
    if (claim.claimer == address(0)) {
      claim.batchIdx = batchIdx;
      claim.claimer = msgSender;
    }
    claim.qtyClaimed = claim.qtyClaimed + mintQty;
    _batchClaims[batchIdx][msgSender] = claim;

    Batch memory batch = _batches[batchIdx];
    batch.qtySold += mintQty;
    _batches[batchIdx] = batch;

    return claim;
  }
  
  function recordAirdropActivity(address msgSender, uint airdropIdx, uint mintQty) internal returns (AirdropClaim memory claim) {
    claim = _airdropClaims[airdropIdx][msgSender];
    if (claim.claimer == address(0)) {
      claim.airdropIdx = airdropIdx;
      claim.claimer = msgSender;
    }
    claim.qtyClaimed += mintQty;
    _airdropClaims[airdropIdx][msgSender] = claim;

    Airdrop memory airdrop = _airdrops[airdropIdx];
    airdrop.qtyClaimed += mintQty;
    _airdrops[airdropIdx] = airdrop;

    return claim;
  }

  function addAirdrops(AirdropParam[] calldata airdrops_) external onlyOwner {
    for (uint i = 0; i < airdrops_.length; i++) {
      addAirdrop(airdrops_[i]);
    }
  }

  function addAirdrop(AirdropParam calldata airdropParam) internal {
    validateAirdropParam(airdropParam);

    _lastAirdropIdx++;

    Airdrop memory airdrop = Airdrop({
      idx: _lastAirdropIdx,
      name: airdropParam.name,
      start: airdropParam.start,
      end: airdropParam.end, // set end to 0 if no end
      maxClaim: airdropParam.maxClaim, // Set to 0 if no max
      maxClaimPerAccount: airdropParam.maxClaimPerAccount, // Set to 0 if no max
      whitelistMerkleRoot: bytes32(0),
      qtyClaimed: 0 // track the number of qty sold
    });
    _airdrops[_lastAirdropIdx] = airdrop;
  }

  function setAirdropEnd(uint airdropIdx, uint end) external onlyOwner {
    Airdrop memory airdrop = _airdrops[airdropIdx];
    if (airdrop.idx == 0) {
      revert AirdropNotFound();
    }
    if (block.timestamp > end) {
      revert MustEndInTheFuture();
    }
    airdrop.end = end;
    _airdrops[airdropIdx] = airdrop;
  }

  function validateAirdropParam(AirdropParam memory airdrop) internal view {
    if (airdrop.start < block.timestamp) {
      revert AirdropStartMustBeInFuture();
    }
  }

  function registerAddressesToAirdrop(bytes32 whitelistMerkleRoot, uint airdropIdx) external onlyOwner {
    Airdrop memory airdrop = _airdrops[airdropIdx];
    if (airdrop.idx == 0) {
      revert AirdropNotFound();
    }
    airdrop.whitelistMerkleRoot = whitelistMerkleRoot;
    _airdrops[airdropIdx] = airdrop;
  }

  /**
    * Withdraw all contract's balance to specified address
    */
  function withdraw(address to) public onlyOwner {
    address payable receiver = payable(to);
    receiver.transfer(address(this).balance);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface ITrinviNFT {

  // Modifiers:
  // - OnlySaleContract
  // - IsInitialized
  function mintTo(address to, uint qty) external;

  // Modifiers:
  // OnlyOwner
  //
  // After called successfully, `isInitialized()` should return true
  function initialize(address saleContract) external;

  function saleContractAddress() external view returns (address);

  // Returns true after `setSaleContract()` is called
  function isInitialized() external view returns (bool);

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
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
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
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
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
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
     * @dev Calldata version of {processMultiProof}
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