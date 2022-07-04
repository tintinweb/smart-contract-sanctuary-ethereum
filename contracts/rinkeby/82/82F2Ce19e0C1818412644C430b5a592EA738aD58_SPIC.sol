/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

// Sources flattened with hardhat v2.9.9 https://hardhat.org

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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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


// File contracts/semaphore/base/SemaphoreConstants.sol


pragma solidity ^0.8.4;

uint256 constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;


// File @zk-kit/incremental-merkle-tree.sol/contracts/[email protected]


pragma solidity ^0.8.4;

library PoseidonT3 {
  function poseidon(uint256[2] memory) public pure returns (uint256) {}
}

library PoseidonT6 {
  function poseidon(uint256[5] memory) public pure returns (uint256) {}
}


// File @zk-kit/incremental-merkle-tree.sol/contracts/[email protected]


pragma solidity ^0.8.4;

// Each incremental tree has certain properties and data that will
// be used to add new leaves.
struct IncrementalTreeData {
  uint8 depth; // Depth of the tree (levels - 1).
  uint256 root; // Root hash of the tree.
  uint256 numberOfLeaves; // Number of leaves of the tree.
  mapping(uint256 => uint256) zeroes; // Zero hashes used for empty nodes (level -> zero hash).
  // The nodes of the subtrees used in the last addition of a leaf (level -> [left node, right node]).
  mapping(uint256 => uint256[2]) lastSubtrees; // Caching these values is essential to efficient appends.
}

/// @title Incremental binary Merkle tree.
/// @dev The incremental tree allows to calculate the root hash each time a leaf is added, ensuring
/// the integrity of the tree.
library IncrementalBinaryTree {
  uint8 internal constant MAX_DEPTH = 32;
  uint256 internal constant SNARK_SCALAR_FIELD =
    21888242871839275222246405745257275088548364400416034343698204186575808495617;

  /// @dev Initializes a tree.
  /// @param self: Tree data.
  /// @param depth: Depth of the tree.
  /// @param zero: Zero value to be used.
  function init(
    IncrementalTreeData storage self,
    uint8 depth,
    uint256 zero
  ) public {
    require(zero < SNARK_SCALAR_FIELD, "IncrementalBinaryTree: leaf must be < SNARK_SCALAR_FIELD");
    require(depth > 0 && depth <= MAX_DEPTH, "IncrementalBinaryTree: tree depth must be between 1 and 32");

    self.depth = depth;

    for (uint8 i = 0; i < depth; i++) {
      self.zeroes[i] = zero;
      zero = PoseidonT3.poseidon([zero, zero]);
    }

    self.root = zero;
  }

  /// @dev Inserts a leaf in the tree.
  /// @param self: Tree data.
  /// @param leaf: Leaf to be inserted.
  function insert(IncrementalTreeData storage self, uint256 leaf) public {
    require(leaf < SNARK_SCALAR_FIELD, "IncrementalBinaryTree: leaf must be < SNARK_SCALAR_FIELD");
    require(self.numberOfLeaves < 2**self.depth, "IncrementalBinaryTree: tree is full");

    uint256 index = self.numberOfLeaves;
    uint256 hash = leaf;

    for (uint8 i = 0; i < self.depth; i++) {
      if (index % 2 == 0) {
        self.lastSubtrees[i] = [hash, self.zeroes[i]];
      } else {
        self.lastSubtrees[i][1] = hash;
      }

      hash = PoseidonT3.poseidon(self.lastSubtrees[i]);
      index /= 2;
    }
    self.root = hash;
    self.numberOfLeaves += 1;
  }

  /// @dev Removes a leaf from the tree.
  /// @param self: Tree data.
  /// @param leaf: Leaf to be removed.
  /// @param proofSiblings: Array of the sibling nodes of the proof of membership.
  /// @param proofPathIndices: Path of the proof of membership.
  function remove(
    IncrementalTreeData storage self,
    uint256 leaf,
    uint256[] calldata proofSiblings,
    uint8[] calldata proofPathIndices
  ) public {
    require(verify(self, leaf, proofSiblings, proofPathIndices), "IncrementalBinaryTree: leaf is not part of the tree");

    uint256 hash = self.zeroes[0];

    for (uint8 i = 0; i < self.depth; i++) {
      if (proofPathIndices[i] == 0) {
        if (proofSiblings[i] == self.lastSubtrees[i][1]) {
          self.lastSubtrees[i][0] = hash;
        }

        hash = PoseidonT3.poseidon([hash, proofSiblings[i]]);
      } else {
        if (proofSiblings[i] == self.lastSubtrees[i][0]) {
          self.lastSubtrees[i][1] = hash;
        }

        hash = PoseidonT3.poseidon([proofSiblings[i], hash]);
      }
    }

    self.root = hash;
  }

  /// @dev Verify if the path is correct and the leaf is part of the tree.
  /// @param self: Tree data.
  /// @param leaf: Leaf to be removed.
  /// @param proofSiblings: Array of the sibling nodes of the proof of membership.
  /// @param proofPathIndices: Path of the proof of membership.
  /// @return True or false.
  function verify(
    IncrementalTreeData storage self,
    uint256 leaf,
    uint256[] calldata proofSiblings,
    uint8[] calldata proofPathIndices
  ) private view returns (bool) {
    require(leaf < SNARK_SCALAR_FIELD, "IncrementalBinaryTree: leaf must be < SNARK_SCALAR_FIELD");
    require(
      proofPathIndices.length == self.depth && proofSiblings.length == self.depth,
      "IncrementalBinaryTree: length of path is not correct"
    );

    uint256 hash = leaf;

    for (uint8 i = 0; i < self.depth; i++) {
      require(
        proofSiblings[i] < SNARK_SCALAR_FIELD,
        "IncrementalBinaryTree: sibling node must be < SNARK_SCALAR_FIELD"
      );

      if (proofPathIndices[i] == 0) {
        hash = PoseidonT3.poseidon([hash, proofSiblings[i]]);
      } else {
        hash = PoseidonT3.poseidon([proofSiblings[i], hash]);
      }
    }

    return hash == self.root;
  }
}


// File contracts/semaphore/base/SemaphoreGroups.sol


pragma solidity ^0.8.4;


/// @title Semaphore groups contract.
/// @dev The following code allows you to create groups, add and remove members.
/// You can use getters to obtain informations about groups (root, depth, number of leaves).
abstract contract SemaphoreGroups {
    using IncrementalBinaryTree for IncrementalTreeData;

    /// @dev Gets a group id and returns the group/tree data.
    mapping(uint256 => IncrementalTreeData) public groups;
    mapping(uint256 => IncrementalTreeData) public votersGroup;

    mapping(uint256 => bool) internal icValidity;
    mapping(uint256 => bool) internal vcValidity;

    /// @dev Creates a new group by initializing the associated tree.
    /// @param groupId: Id of the group.
    /// @param depth: Depth of the tree.
    /// @param zeroValue: Zero value of the tree.
    function _createGroup(
        uint256 groupId,
        uint8 depth,
        uint256 zeroValue
    ) internal virtual {
        require(
            groupId < SNARK_SCALAR_FIELD,
            "SemaphoreGroups: group id must be < SNARK_SCALAR_FIELD"
        );
        require(
            getDepth(groupId) == 0,
            "SemaphoreGroups: group already exists"
        );
        groups[groupId].init(depth, zeroValue);

        votersGroup[groupId].init(depth, zeroValue);
    }

    /// @dev Adds an identity commitment to an existing group.
    /// @param groupId: Id of the group.
    /// @param identityCommitment: New identity commitment.
    function _addMember(uint256 groupId, uint256 identityCommitment)
        internal
        virtual
    {
        require(
            getDepth(groupId) != 0,
            "SemaphoreGroups: group does not exist"
        );
        require(
            !icValidity[identityCommitment],
            "SemaphoreGroups: identity already exists"
        );

        groups[groupId].insert(identityCommitment);

        icValidity[identityCommitment] = true;

    }

    /// @dev Adds an identity commitment to an existing group.
    /// @param groupId: Id of the group.
    /// @param externalNullifier: New external nullifier of vote.
    function _addVote(uint256 groupId, uint256 externalNullifier)
        internal
        virtual
    {
        require(
            getDepth(groupId) != 0,
            "SemaphoreGroups: group does not exist"
        );
        require(
            !vcValidity[externalNullifier],
            "SemaphoreGroups: vote already exists"
        );
        votersGroup[groupId].insert(externalNullifier);

        vcValidity[externalNullifier] = true;

    }

    /// @dev See {ISemaphoreGroups-getRoot}.
    function getRoot(uint256 groupId)
        public
        view
        returns (uint256, uint256)
    {
        return (groups[groupId].root, votersGroup[groupId].root);
    }

    /// @dev See {ISemaphoreGroups-getDepth}.
    function getDepth(uint256 groupId)
        public
        view
        returns (uint8)
    {
        //Depth of both mapping will be same
        return groups[groupId].depth;
    }

    /// @dev See {ISemaphoreGroups-getNumberOfLeaves}.
    function getNumberOfLeaves(uint256 groupId)
        public
        view
        returns (uint256)
    {
        //no of leaves of both mapping will be same
        return groups[groupId].numberOfLeaves;
    }
}


// File contracts/semaphore/interfaces/IVerifier.sol


pragma solidity ^0.8.4;

/// @title Verifier interface.
/// @dev Interface of Verifier contract.
interface IVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[3] memory input
    ) external returns(bool);
}


// File contracts/semaphore/interfaces/IVerifierIC.sol


pragma solidity ^0.8.4;

/// @title Verifier interface.
/// @dev Interface of Verifier contract.
interface IVerifierIC {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input
    ) external returns (bool);
}


// File contracts/semaphore/extensions/SemaphoreVoting.sol


pragma solidity ^0.8.4;



contract SemaphoreVoting is SemaphoreGroups {

    address public VERIFIER_IDENTITY;

    address public VERIFIER_VOTE;

    uint256 internal ZERO_VALUE = 21663839004416932945382355908790599225266501822907911457504978515578255421292;

    struct Poll {
        uint256 matchAmount;
        uint256 startEpoch;
        uint256 endEpoch;
        uint256 voterIncentive;
        address coordinator;
        address erc20Address;
        address erc721Address;
        uint8 votesIndex;
        uint8 voterIndex;
    }

    mapping(uint256 => Poll) public polls;

    function createPoll(
        uint256 pollId,
        address coordinator,
        uint256 matchAmountPoll,
        uint256 startEpochTime,
        uint256 endEpochTime,
        uint256 voterIncentive,
        address erc20Address,
        address erc721Address,
        uint8 depth
    ) internal {    


        _createGroup(pollId, depth, ZERO_VALUE); //both of the trees are initialized

        Poll memory poll;

        poll.coordinator = coordinator;

        poll.matchAmount = matchAmountPoll;

        poll.startEpoch = startEpochTime;

        poll.endEpoch = endEpochTime;

        poll.erc20Address = erc20Address;
        
        poll.erc721Address = erc721Address;

        poll.voterIncentive = voterIncentive;

        polls[pollId] = poll;
    }

    function castVote(
        uint256 mRootIc,
        uint256 votingCommitment,
        uint256 _pollId,
        uint256[8] calldata proofIc
    ) internal {

        _addVote(_pollId, votingCommitment);


        bool v = _verifyProofIC(mRootIc, proofIc);

        require(v, "NOT VERIFIED");
    }

    function _verifyProofIC(uint256 mRootIc, uint256[8] calldata proofIc)
        internal
        returns (bool r)
    {   

        r = IVerifierIC(VERIFIER_IDENTITY).verifyProof(
            [proofIc[0], proofIc[1]],
            [[proofIc[2], proofIc[3]], [proofIc[4], proofIc[5]]],
            [proofIc[6], proofIc[7]],
            [mRootIc]
        );
    }

    function _verifyProofVC(
        uint256 votingCommitment,
        uint256 mRootVc,
        uint256 pollId,
        address pkContributor,
        uint256[8] calldata proofVc
    ) internal returns (bool r) {
        require(
            vcValidity[votingCommitment],
            "Voting and identity commitment does not exist"
        );

        r = IVerifier(VERIFIER_VOTE).verifyProof(
            [proofVc[0], proofVc[1]],
            [[proofVc[2], proofVc[3]], [proofVc[4], proofVc[5]]],
            [proofVc[6], proofVc[7]],
            [pollId, uint256(uint160(address(pkContributor))),mRootVc] //to make array unified
        );
    }
}


// File contracts/interfaces/ISPIC.sol


pragma solidity ^0.8.4;

interface ISPIC {

    function createCircle(
        uint256 _id,
        uint256 _matchAmount,
        uint256 voterIncentive,
        address erc20Address,
        address erc721Address,
        uint256 _endEpoch
    ) external;

    function addContributors(uint256 _id, address[] calldata _addresses)
        external;

    function becomeVoter(
        uint256 _id,
        uint256 identityCommitment,
        uint256 _tokenId
    ) external;

    function castVoteExternal(
        address pk,
        uint256 mRootIc,
        uint256 votingCommitment,
        uint256 _pollId,
        uint256[8] calldata proofIc
    ) external;

    function withdrawNFT(
        uint256 votingCommitment,
        uint256 mRootVc,
        uint256 pollId,
        address pkContributor,
        uint256[8] calldata proofVc
    ) external;

    function receiveCompensation(uint256 pollId) external;
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


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
}


// File contracts/interfaces/IERC721Transfer.sol


pragma solidity ^0.8.4;

interface IERC721Transfer is IERC721 {

   function transfer(address to, uint256 id) external;
}


// File contracts/SPIC.sol


pragma solidity ^0.8.0;





contract SPIC is SemaphoreVoting, ISPIC {
    address public RELAYER;

    mapping(uint256 => mapping(address => Contributor)) public contributors;
    mapping(address => uint256) public nftToAddress;

    struct Contributor {
        uint8 voteCount;
        bool status;
    }

    event ContributorAdded(address _contributor, uint256 _id);

    event CompensationReceived(
        address _contributor,
        uint256 _id,
        uint256 _amount
    );

    event NFTWithdrawn(address user, uint256 nftId);

    event VoteCasted(
        uint256 pollId,
        uint256 votingCommitment,
        address pkContributor,
        uint8 index
    );

    event VoterAdded(
        address user,
        uint256 id,
        uint256 identityCommitment,
        uint256 _tokenId,
        uint8 index
    );

    event CircleCreated(
        uint256 _id,
        uint256 _matchAmount,
        uint256 _startEpoch,
        uint256 _endEpoch,
        uint256 voterIncentive,
        address erc20Address,
        address erc721Addres
    );

    constructor(
        address _relayer,
        address _verifierIC,
        address _verifierVC
    ) public {

        RELAYER = _relayer;
        VERIFIER_IDENTITY = _verifierIC;
        VERIFIER_VOTE = _verifierVC;

    }

    function createCircle(
        uint256 _id,
        uint256 _matchAmount,
        uint256 voterIncentive,
        address erc20Address,
        address erc721Address,
        uint256 _endEpoch
    ) external override {
        require(polls[_id].coordinator == address(0), "Organization was already created");
        require(_endEpoch > block.timestamp, "Invalid EPOCH value");

        createPoll(
            _id,
            msg.sender,
            _matchAmount,
            block.timestamp,
            _endEpoch,
            voterIncentive,
            erc20Address,
            erc721Address,
            3
        );

        IERC20(erc20Address).transferFrom(msg.sender, address(this), _matchAmount);

        emit CircleCreated(_id, _matchAmount, block.timestamp, _endEpoch, voterIncentive, erc20Address, erc721Address);
    }

    function addContributors(uint256 _id, address[] calldata _addresses)
        external
        override
    {
        require(polls[_id].coordinator == msg.sender);
        require(polls[_id].endEpoch > block.timestamp);
        for (uint8 i = 0; i < _addresses.length; i++) {
            contributors[_id][_addresses[i]].status = true;

            emit ContributorAdded(_addresses[i], _id);
        }
    }

    function becomeVoter(
        uint256 _id,
        uint256 identityCommitment,
        uint256 _tokenId
    ) external override {

        require(!contributors[_id][msg.sender].status, "Contributor can't become voters");

        require(polls[_id].endEpoch > block.timestamp, "EPOCH ENDED");

        address nftAddress = polls[_id].erc721Address;

        IERC721Transfer(nftAddress).transferFrom(
            msg.sender,
            address(this),
            _tokenId
        );
        _addMember(_id, identityCommitment);

        nftToAddress[msg.sender] = _tokenId;

        emit VoterAdded(
            msg.sender,
            _id,
            identityCommitment,
            _tokenId,
            polls[_id].voterIndex
        );

        polls[_id].voterIndex = polls[_id].voterIndex +1;
    }

    function castVoteExternal(
        address pk,
        uint256 mRootIc,
        uint256 votingCommitment,
        uint256 _pollId,
        uint256[8] calldata proofIc
    ) external override {
        require(polls[_pollId].endEpoch > block.timestamp, "EPOCH ENDED");
        require(contributors[_pollId][pk].status, "NOT CONTRIBUTOR");
        require(msg.sender == RELAYER, "NOT RELAYER");

        contributors[_pollId][pk].voteCount++;

        castVote(mRootIc, votingCommitment, _pollId, proofIc);

        emit VoteCasted(_pollId, votingCommitment, pk, polls[_pollId].votesIndex);

        polls[_pollId].votesIndex = polls[_pollId].votesIndex +1;
    }

    function withdrawNFT(
        uint256 votingCommitment,
        uint256 mRootVc,
        uint256 pollId,
        address pkContributor,
        uint256[8] calldata proofVc
    ) external override {
        require(polls[pollId].endEpoch < block.timestamp, "EPOCH NOT ENDED");
        address nftAddress = polls[pollId].erc721Address;
        address erc20Address = polls[pollId].erc20Address;
        uint256 nftId = nftToAddress[msg.sender];
        
        _verifyProofVC(
            votingCommitment,
            mRootVc,
            pollId,
            pkContributor,
            proofVc
        );

        address user = msg.sender;

        uint256 reward = (polls[pollId].matchAmount * polls[pollId].voterIncentive) /
            (polls[pollId].votesIndex * 1000);
       
        IERC20(erc20Address).transfer(user, reward);
        IERC721Transfer(nftAddress).transfer(user, nftId);

        emit NFTWithdrawn(user, nftId);
    }

    function receiveCompensation(uint256 pollId) external override {
        require(contributors[pollId][msg.sender].status);
        require(polls[pollId].endEpoch < block.timestamp);

        address erc20Address = polls[pollId].erc20Address;

        uint256 afterAmount = polls[pollId].matchAmount -
            ((polls[pollId].matchAmount * polls[pollId].voterIncentive) / 1000);

        uint256 perUserVote = afterAmount /
            polls[pollId].votesIndex;

        uint256 reward = perUserVote *
            contributors[pollId][msg.sender].voteCount;

        IERC20(erc20Address).transfer(msg.sender, reward);

        emit CompensationReceived(msg.sender, pollId, reward);
    }
}