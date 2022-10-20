/**
 *Submitted for verification at Etherscan.io on 2022-10-20
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @openzeppelin/contracts/utils/cryptography/MerkleProof.sol


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

// File: erc721a/contracts/IERC721A.sol


// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
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
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
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

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

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

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


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

// File: contracts/2_Owner.sol


pragma solidity ^0.8.14;






interface IX2 {
    function mintByOperator(address _addressBuyer, uint _quantity) external ;
    function ownerOf(uint tokenId) external view returns (address owner);
    function totalSupply() external view returns (uint);
    function revealActive() external returns(bool);
}

interface IX1 {
    function mintBySaleContract(address _addressBuyer, uint _quantity) external ;
    function ownerOf(uint tokenId) external view returns (address owner);
    function totalSupply() external view returns (uint);
    function MAX_SUPPLY() external returns (uint);
    function unstakeNFT(uint[] memory tokenId, address _to) external;
    function isStaked(uint) external returns(bool);
}

  library StructLib {
    struct Parent {
        uint tokenId1;
        uint tokenId2;
    }
}


contract OperatorContract is Ownable, ReentrancyGuard {

    event X1Staked(address owner, uint256 tokenId, uint256 timeframe);
    event X1Unstaked(address owner, uint256 tokenId, uint256 timeframe);
    event X2Staked(address owner, uint256 tokenId, uint256 timeframe);
    event X2Unstaked(address owner, uint256 tokenId, uint256 timeframe);
    event Merged(address owner, uint256 tokenId1, uint tokenId2, uint createdTokenId, uint256 timeframe);

    mapping(uint => address) public X1Depositaries;
    mapping(uint => address) public X2Depositaries;
    mapping(address => uint[]) public tokenIdOldStaking;

     // mapping to check if given id is revealed
    mapping(uint => bool) public isRevealed;
    // mapping to get the chosen parentID to attribute revealed metadata
    mapping(uint => uint) public chosenMainTokenId;

    mapping(uint => StructLib.Parent) public parents;

    address public X1Address;
    address public X2Address;

    address burnAddress = 0x000000000000000000000000000000000000dEaD;

    // activation
    bool public isStakingActive;
    bool public isMergeActive;
    uint public freeMintLimit;

    // free mint root
    bytes32 public freeMintRoot;

    // free mint supply
    uint public maxSupplyFreeMint = 1500;
    uint public countMintedByFreeMint;

    // Mapping to follow the freemint used
   mapping(address => uint) public freeMintsUsed;

    modifier stakingIsActive() {
        require(isStakingActive, "Contract is not active");
        _;
    }

     modifier mergeCheck(uint256 _tokenId1,uint256 _tokenId2) {
        require(isMergeActive, "Contract is not active");
        require(IERC721A(X1Address).ownerOf(_tokenId1) == msg.sender, "You must own the NFT.");
        require(IERC721A(X1Address).ownerOf(_tokenId2) == msg.sender, "You must own the NFT.");
        _;
    }

    modifier freeMintCheck(uint _quantity, uint count, bytes32[] calldata proof){
        require(block.timestamp < freeMintLimit, "Free mint is over");
        require(MerkleProof.verify(proof, freeMintRoot, keccak256(abi.encode(msg.sender, count))), "!proof");
        require(countMintedByFreeMint + _quantity <= maxSupplyFreeMint , 'Max supply freemint reached');
        require(freeMintsUsed[msg.sender] + _quantity <= count, 'Not allowed to freemint this quantity');
        countMintedByFreeMint += _quantity;
        freeMintsUsed[msg.sender] += _quantity;
        _;
    }

    constructor(address oxyaAddress_, address X2Address_) {
        X1Address = oxyaAddress_;
        X2Address = X2Address_;
    }

  
      /**
     * @dev Merge 2 tokens in the X1 contract to get 1 X2 token
     * @param _tokenId1 ids of token X1
     * @param _tokenId2 ids of token X2
     */
    function Merge(uint _tokenId1,uint _tokenId2) public mergeCheck(_tokenId1, _tokenId2)  {
        IERC721A(X1Address).transferFrom(msg.sender, burnAddress, _tokenId1);
        IERC721A(X1Address).transferFrom(msg.sender, burnAddress, _tokenId2);

        uint totalSupply = IX2(X2Address).totalSupply();
        IX2(X2Address).mintByOperator(msg.sender, 1);
         parents[totalSupply] = StructLib.Parent(
                _tokenId1,
                _tokenId2
            );
        emit Merged(msg.sender, _tokenId1, _tokenId2, totalSupply, block.timestamp);
    }

    /**
     * @dev Merge 2 tokens in the X1 contract to get 1 X2 token and stake it in present operator contrat
     * @param _tokenId1 ids of token X1
     * @param _tokenId2 ids of token X2
     */
    function MergeAndStake(uint256 _tokenId1, uint256 _tokenId2) public  mergeCheck(_tokenId1, _tokenId2) {
        IERC721A(X1Address).transferFrom(msg.sender, burnAddress, _tokenId1);
        IERC721A(X1Address).transferFrom(msg.sender, burnAddress, _tokenId2);
        
        uint totalSupply = IX2(X2Address).totalSupply();
        IX2(X2Address).mintByOperator(address(this), 1);
         parents[totalSupply] = StructLib.Parent(
                _tokenId1,
                _tokenId2
            );
        emit Merged(msg.sender, _tokenId1, _tokenId2, totalSupply, block.timestamp);

        stakeFreeMintX2NFT(totalSupply, msg.sender);
    }

    
      /**
     * @dev  Function to mint freeMints X1
     * @param _quantity quantity of token X1 to mint
     * @param count maximum of authorized mint for the msg.sender
     * @param proof merkle proof
     */
    function freeMintX1(uint _quantity, uint count, bytes32[] calldata proof) external freeMintCheck(_quantity, count, proof) {

        IX1(X1Address).mintBySaleContract(msg.sender, _quantity);  
    }

   /**
     * @dev  Function to mint and stake freeMints X1
     * @param _quantity quantity of token X1 to mint
     * @param count maximum of authorized mint for the msg.sender
     * @param proof merkle proof
     */
    function freeMintX1Stake(uint _quantity, uint count, bytes32[] calldata proof) external freeMintCheck(_quantity, count, proof) {

        uint totalSupply = IX1(X1Address).totalSupply();
        IX1(X1Address).mintBySaleContract(address(this), _quantity);  

        for(uint i=0; i<_quantity; i++){
            stakeFreeMintX1NFT(totalSupply + i, msg.sender);
        }
    }

      /**
     * @dev  Function to mint X1 and merge into X2
     * @param _quantity quantity of token X1 to mint
     * @param count maximum of authorized mint for the msg.sender
     * @param proof merkle proof
     */
    function freeMintX2( uint _quantity, uint count, bytes32[] calldata proof) external freeMintCheck(_quantity, count, proof) {
        require(_quantity % 2 == 0 && _quantity != 0 , "quantity should be a modulo 2");
        uint allowableMints = _quantity/2;

        for(uint i; i < allowableMints; i++ ){
             uint totalSupplyX1 = IX1(X1Address).totalSupply();
            uint totalSupplyX2 = IX2(X2Address).totalSupply();
            IX1(X1Address).mintBySaleContract(burnAddress, 2);  
            IX2(X2Address).mintByOperator(msg.sender, 1);
            parents[totalSupplyX2] = StructLib.Parent(
                    totalSupplyX1 ,
                    totalSupplyX1 +  1
                );
            emit Merged(msg.sender, totalSupplyX1 , totalSupplyX1 + 1, totalSupplyX2 , block.timestamp);
        }
    }

      /**
     * @dev  Function to mint X1 and merge and stake into X2
     * @param _quantity quantity of token X1 to mint
     * @param count maximum of authorized mint for the msg.sender
     * @param proof merkle proof
     */
    function freeMintX2Stake(uint _quantity, uint count, bytes32[] calldata proof) external  freeMintCheck(_quantity, count, proof){
        require(_quantity % 2 == 0 && _quantity != 0 , "quantity should be a modulo 2");
        uint allowableMints = _quantity/2;

        for(uint i; i < allowableMints; i++ ){
            uint totalSupplyX1 = IX1(X1Address).totalSupply();
            uint totalSupplyX2 = IX2(X2Address).totalSupply();
            IX1(X1Address).mintBySaleContract(burnAddress, 2);  

            IX2(X2Address).mintByOperator(address(this), 1);
            parents[totalSupplyX2] = StructLib.Parent(
                    totalSupplyX1,
                    totalSupplyX1 + 1
                );
            emit Merged(msg.sender, totalSupplyX1, totalSupplyX1 + 1, totalSupplyX2, block.timestamp);

            stakeFreeMintX2NFT(totalSupplyX2, msg.sender);
        }
    }

    //STAKING X2 NFT
    /**
     * @dev stake tokens X2  in the contract
     * @param _tokenId ids of token
     * @param _to address of staker
     */
    function stakeX2NFT(uint256 _tokenId, address _to) internal  {
        require(IX2(X2Address).ownerOf(_tokenId) == _to, "not owner");
        require(X2Depositaries[_tokenId] == address(0), "Already staked");
           
        IERC721A(X2Address).transferFrom(_to, address(this), _tokenId); 
        X2Depositaries[_tokenId] = _to;
        
        emit X2Staked(_to, _tokenId, block.timestamp);
    }

    /**
     * @dev stake tokens X2 in the contract, called by freeMint function
     * @param _tokenId ids of token
     * @param _to address of staker
     */
    function stakeFreeMintX2NFT(uint256 _tokenId, address _to) internal  {
        require(X2Depositaries[_tokenId] == address(0), "Already staked");

        X2Depositaries[_tokenId] = _to;
        
        emit X2Staked(_to, _tokenId, block.timestamp);
    }

     /**
     * @dev stake multiple tokens X2 in the contract
     * @param _tokenIds ids of tokens
     */
    function batchStakeX2NFT(uint256[] memory _tokenIds) public stakingIsActive {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            stakeX2NFT(_tokenIds[i], msg.sender);
        }
    }

    /**
     * @dev unstake token X2 out of the contract
     * @param _tokenId tokenId of token to unstake
      * @param _to address of unstaker
     */
    function unstakeX2NFT(uint256 _tokenId, address _to) internal {
        require(X2Depositaries[_tokenId] == _to, "not owner");
        
        IERC721A(X2Address).transferFrom(address(this), _to, _tokenId); 
        X2Depositaries[_tokenId] = address(0);

        emit X2Unstaked(_to, _tokenId, block.timestamp);
    }

     /**
     * @dev unstake multiple token X2 out of the contract
     * @param _tokenIds tokenId of token to unstake
     */
    function batchUnstakeX2NFT(uint256[] memory _tokenIds) public stakingIsActive {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            unstakeX2NFT(_tokenIds[i], msg.sender);
        }
    }

    // STAKING X1 NFT
    /**
     * @dev stake tokens X1  in the contract
     * @param _tokenId ids of token
     * @param _to address of staker
     */
    function stakeX1NFT(uint256 _tokenId, address _to) internal  {
        require(IX1(X1Address).ownerOf(_tokenId) == _to, "not owner");
        require(X1Depositaries[_tokenId] == address(0), "Already staked");
           
        IERC721A(X1Address).transferFrom(_to, address(this), _tokenId); 
        X1Depositaries[_tokenId] = _to;
        
        emit X1Staked(_to, _tokenId, block.timestamp);
    }

    /**
     * @dev stake tokens X1  in the contract, callable by freeMint
     * @param _tokenId ids of token
     * @param _to address of staker
     */
    function stakeFreeMintX1NFT(uint256 _tokenId, address _to) internal  {
        require(X1Depositaries[_tokenId] == address(0), "Already staked");

        X1Depositaries[_tokenId] = _to;
        
        emit X1Staked(_to, _tokenId, block.timestamp);
    }

     /**
     * @dev stake multiple tokens X1  in the contract
     * @param _tokenIds ids of token
     */
    function batchStakeX1NFT(uint256[] memory _tokenIds) public stakingIsActive {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            stakeX1NFT(_tokenIds[i], msg.sender);
        }
    }

    // UNSTAKE X1 NFT
      /**
     * @dev unstake token X1 out of the contract
     * @param _tokenId tokenId of token to unstake
      * @param _to address of unstaker
     */
    function unstakeX1NFT(uint256 _tokenId, address _to) internal {
        require(X1Depositaries[_tokenId] == _to, "not owner");
        
        IERC721A(X1Address).transferFrom(address(this), _to, _tokenId); 

        X1Depositaries[_tokenId] = address(0);

        emit X1Unstaked(_to, _tokenId, block.timestamp);
    }

     /**
     * @dev unstake token X1 out of the contract, also check the staking in previous contract
     * @param _tokenIds tokenIds of token to unstake
     */
    function batchUnstakeX1NFT(uint256[] memory _tokenIds) public stakingIsActive {
      
       for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 value = _tokenIds[i];
            bool isStakedInX1 = IX1(X1Address).isStaked(_tokenIds[i]);

            if(isStakedInX1 == true){
                tokenIdOldStaking[msg.sender].push(value);
            } else {
                unstakeX1NFT(_tokenIds[i], msg.sender);
            }
        }
       
        if(tokenIdOldStaking[msg.sender].length > 0){
            IX1(X1Address).unstakeNFT(tokenIdOldStaking[msg.sender], msg.sender);
                delete tokenIdOldStaking[msg.sender];
         }
    }

      /**
     * @dev reveal selected NFT with the parent choice for the metadata
     * @param _tokenId id of token to reveal
     * @param parentChoice id of token Parent for metadata attribution
     */
    function revealNFT(uint _tokenId, uint parentChoice ) public  {
        uint idParent1 = parents[_tokenId].tokenId1;
        uint idParent2 =parents[_tokenId].tokenId2;
        require(IX2(X2Address).revealActive() == true, "reveal not active yet");
        require(X2Depositaries[_tokenId] == msg.sender || IX2(X2Address).ownerOf(_tokenId) == msg.sender , "not owner");
        require(isRevealed[_tokenId] == false, "already Revealed");
        require(parentChoice == idParent1 || parentChoice == idParent2, "wrong choice" );
        chosenMainTokenId[_tokenId] = parentChoice;
        isRevealed[_tokenId] = true;
    }

    /**
     * @dev necessary to transfer tokens
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * @dev necessary to calculate proof
     * @param _root root for free mint
     */
    function setFreeMintMerkleRoot(bytes32 _root) public onlyOwner {
        freeMintRoot = _root;
    }

    /**
     * @dev timestamp to activate freeMint
     * @param timestamp timestamp limit for freemint
     */
    function setFreeMintLimit(uint timestamp) external onlyOwner {
        freeMintLimit = timestamp;
    }

     function setIsMergeActive() external onlyOwner {
        isMergeActive = !isMergeActive;
    }

    function setIsStakingActive() external onlyOwner {
        isStakingActive = !isStakingActive;
    }

     /*
     * FreeMint supply
     * function to change FreeMintSupply
     */
    function setFreeMintSupply(uint _newFreeMintSupply) external onlyOwner {
        require(_newFreeMintSupply > countMintedByFreeMint, "supply minimum reached");
        require(_newFreeMintSupply <= IX1(X1Address).MAX_SUPPLY() - IX1(X1Address).totalSupply(), "Max supply reached");
        maxSupplyFreeMint = _newFreeMintSupply;
    }

    // MIGRATION ONLY.
    function setX1Contract(address X1Contract) public onlyOwner {
        X1Address = X1Contract;
    }

      function setX2Contract(address X2Contract) public onlyOwner {
        X2Address = X2Contract;
    }

}