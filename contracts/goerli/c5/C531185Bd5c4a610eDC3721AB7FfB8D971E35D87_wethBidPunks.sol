// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface IWETH9 {
  function approve(address guy, uint wad) external;
  function deposit() external payable;
  function withdraw(uint wad) external;
  function transferFrom(address src, address dst, uint wad) external;
}
interface ICryptoPunk {
  function balanceOf(address owner) external returns (uint256 count);
  function punkIndexToAddress(uint256 punkIndex) external returns (address);
  function punksOfferedForSale(uint256 punkIndex) external returns (bool, uint256, address, uint256, address);
  function buyPunk(uint punkIndex) external payable;
  function transferPunk(address to, uint punkIndex) external;
  function withdraw() external;
}

error InvalidBid();
error InvalidFilter();
error InvalidSignature();
error SignatureExpired();
error Unauthorized();

contract wethBidPunks is Ownable {
  using MerkleProof for bytes32[];

  IWETH9 public immutable _wethContract;
  ICryptoPunk public immutable _punkContract;

  uint constant chainId = 1;

  enum BidStatus{ ONGOING, CANCELED, EXECUTED }
  struct Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
  }
  struct Bid {
    uint256 cancelNonce;
    uint256 bidNonce;
    uint256 deadline;
    uint256 amount;
    address bidder;
    bool collectionWide;
    bytes32 merkleTree;
    bytes32[] merkleProof;
  }

  mapping(address => uint) public cancelNonces;
  mapping(address => mapping (uint => BidStatus)) public bids;

  event BidAccepted(address indexed bidder, address indexed accepter, uint punkId, uint amount, uint8 v, bytes32 r, bytes32 s);
  event BidCanceled(address indexed bidder, uint bidNonce);
  event AllBidsCanceled(address indexed bidder, uint cancelNonce);

  constructor(address weth9Address, address cryptoPunkAddress){
    _wethContract = IWETH9(weth9Address);
    _punkContract = ICryptoPunk(cryptoPunkAddress);
  }

  /**
   * @dev Cancel a bid after authorizing it off-chain. Can only be called by the bid creator
   */
  function cancelBid(
    Bid memory bid
  ) external {
    if (block.timestamp > bid.deadline) revert SignatureExpired();
    if (msg.sender != bid.bidder) revert Unauthorized();
    if (bids[msg.sender][bid.bidNonce] != BidStatus.ONGOING) revert InvalidBid();

    bids[bid.bidder][bid.bidNonce] = BidStatus.CANCELED;
    emit BidCanceled(bid.bidder, bid.bidNonce);
  }

  /**
   * @dev Cancel all off-chain bids of the msg.sender. No deadlines or signatures are checked.
   */
  function cancelAllBids() external {
    emit AllBidsCanceled(msg.sender, cancelNonces[msg.sender]);
    cancelNonces[msg.sender]++;
  }

  function checkSignature(Signature memory sig, bytes32 hash, address bidder) pure internal returns (address) {
    address signer = ecrecover(hash, sig.v, sig.r, sig.s);
    if (signer != bidder || signer == address(0)) revert InvalidSignature();

    return signer;
  }

  function buildIntermediateSignatureHashes(
    uint cancelNonce, uint bidNonce, address bidder, uint amount,
    bool collectionWide, bytes32 merkle, uint256 deadline
  ) view internal returns (bytes32 domainHash, bytes32 structHash) {
    bytes32 eip712DomainHash = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes("ForeverMarket")),
        keccak256(bytes("1")),
        chainId,
        address(this)
      )
    );
    bytes32 hashStruct = keccak256(
      abi.encode(
        keccak256("Bid(uint cancelNonce,uint bidNonce,address bidder,uint amount,bool collectionWide,bytes32 merkleTree,uint deadline)"),
        cancelNonce,
        bidNonce,
        bidder,
        amount,
        collectionWide,
        merkle,
        deadline
      )
    );

    return (eip712DomainHash, hashStruct);
  }

  function stringToUint(string memory s) public pure returns (uint) {
    bytes memory b = bytes(s);
    uint result = 0;
    for (uint256 i = 0; i < b.length; i++) {
      uint256 c = uint256(uint8(b[i]));
      if (c >= 48 && c <= 57) {
        result = result * 10 + (c - 48);
      }
    }
    return result;
  }

  // Need this empty function declaration to accept the ETH when unwrapping WETH
  // see https://ethereum.stackexchange.com/questions/83929/while-testing-wrap-unwrap-of-eth-to-weth-on-kovan-however-the-wrap-function-i
  fallback() external payable {}
  receive() external payable {}

  function acceptBid(
    Signature calldata sig,
    Bid calldata bid,
    string calldata punkIdToSell
  ) external payable {
    if (block.timestamp > bid.deadline) revert SignatureExpired();
    if (bid.cancelNonce < cancelNonces[bid.bidder]) revert InvalidBid();

    (bytes32 eip712DomainHash, bytes32 hashStruct) = buildIntermediateSignatureHashes(
      bid.cancelNonce, bid.bidNonce, bid.bidder, bid.amount, bid.collectionWide, bid.merkleTree, bid.deadline
    );
    bytes32 hash = keccak256(abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct));
    if (bids[bid.bidder][bid.bidNonce] != BidStatus.ONGOING) revert InvalidBid();

    checkSignature(sig, hash, bid.bidder);
    // uint256 commission = collectionCommission;
    if (!bid.collectionWide) {
      if (!bid.merkleProof.verify(bid.merkleTree, keccak256(bytes(punkIdToSell)))) revert InvalidFilter();
      // commission = traitCommission;
    }

    // set bid executed before sending punk and ETH to prevent re-entrancy attacks
    bids[bid.bidder][bid.bidNonce] = BidStatus.EXECUTED;

    // transfer WETH from bidder to SC 
    _wethContract.transferFrom(bid.bidder, address(this), bid.amount);

    // unwrap WETH (without commission) to ETH
    _wethContract.withdraw(bid.amount);

    uint punkId = stringToUint(punkIdToSell);
    // SC can now buy the punk
    _punkContract.buyPunk{value: (bid.amount)}(punkId);

    // SC can transfer the punk to the bidder
    _punkContract.transferPunk(bid.bidder, punkId);

    emit BidAccepted(bid.bidder, msg.sender, punkId, bid.amount, sig.v, sig.r, sig.s);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/MerkleProof.sol)

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
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
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
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
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
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            unchecked {
                return hashes[totalHashes - 1];
            }
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
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
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
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            unchecked {
                return hashes[totalHashes - 1];
            }
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