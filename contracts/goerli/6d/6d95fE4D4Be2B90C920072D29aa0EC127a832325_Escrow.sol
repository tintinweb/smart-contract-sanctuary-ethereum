/**
 *Submitted for verification at Etherscan.io on 2023-02-10
*/

// File: @openzeppelin/contracts/utils/cryptography/MerkleProof.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/utils/Counters.sol


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

// File: contracts/projects.sol


pragma solidity ^0.8.0;





interface NFT {
    function tokenPrice() external returns (uint256);

    function artist() external returns (address);
}

interface Token {
    function advisory() external returns (address);

    function platform() external returns (address);
}

error ProjectFailed();
error ProjectSuccessfullyFunded();

error ProjectHasEnded();
error ProjectStillFunding();

error NFTTaken();
error NFTPending();
error InvalidProof();
error NotOwner();

contract Escrow is Ownable {
    using Counters for Counters.Counter;

    event DurationChanged(uint256 projectId, uint256 newDeadline);
    event ProjectCreated(
        address indexed projectOwner,
        // Capstone
        uint256 soft,
        uint256 medium,
        uint256 hard,
        // Distribution in bps
        uint256 artist,
        uint256 project,
        uint256 advisory,
        uint256 platform
    );
    event Deposit(
        address indexed payee,
        uint256 projectId,
        address nftContract,
        bytes32 tokenUri,
        uint256 price
    );
    event CapstoneReached(uint256 indexed projectId, uint8 status);
    event NftMinted(
        address indexed minter,
        uint256 projectId,
        address nftContract,
        bytes32 tokenUri
    );
    event Withdraw(
        address indexed withdrawer,
        uint256 projectId,
        uint256 amount
    );
    event FundClaimed(
        address indexed claimer,
        uint256 projectId,
        uint256 amount
    );

    struct Project {
        //Cap
        // uint256 soft;
        // uint256 medium;
        // uint256 hard;
        uint256 finalCap;
        //Fee
        uint256 artist;
        uint256 project;
        uint256 advisory;
        uint256 platform;
        //Info
        uint256 totalDeposit;
        uint256 deadline;
        bytes32 projectRoot;
        uint8 status;
        address owner;
    }

    Counters.Counter private projectIds;
    mapping(uint256 => Project) private projects;
    // USed to track if NFT has been picked
    bytes32 public globalNftRoot;

    address public talax;

    constructor(address _talax) {
        talax = _talax;
    }

    /* ------------------------------------------ Functions ----------------------------------------- */
    function createProject(
        address _owner,
        uint256 _soft,
        uint256 _medium,
        uint256 _hard,
        uint256 _artist,
        uint256 _project,
        uint256 _advisory,
        uint256 _platform,
        uint256 _duration
    ) external onlyOwner {
        projectIds.increment();
        projects[projectIds.current()] = Project({
            owner: _owner,
            // soft: _soft,
            // medium: _medium,
            // hard: _hard,
            finalCap: 0,
            artist: _artist,
            project: _project,
            advisory: _advisory,
            platform: _platform,
            totalDeposit: 0,
            status: 0,
            deadline: block.timestamp + _duration,
            projectRoot: ""
        });

        emit ProjectCreated(
            _owner,
            _soft,
            _medium,
            _hard,
            _artist,
            _project,
            _advisory,
            _platform
        );
    }

    // Need to be called every time a project change status
    function updateProjectRoot(
        uint256 _projectId,
        bytes32 _root,
        bytes32 _globalNftRoot
    ) public onlyOwner {
        projects[_projectId].projectRoot = _root;
        globalNftRoot = _globalNftRoot;
    }

    // Only called by owner, owner handle the gas fee
    function deposit(
        uint256 _projectId,
        address _nftContract,
        address _depositor,
        bytes32 _tokenUri,
        uint8 _status
    ) public onlyOwner {
        Project storage project = projects[_projectId];
        if (project.status == 3) revert ProjectSuccessfullyFunded();
        if (project.deadline <= block.timestamp) revert ProjectHasEnded();

        uint256 tokenPrice = NFT(_nftContract).tokenPrice();
        project.totalDeposit += tokenPrice;

        if (project.status < _status) {
            project.status = _status;
            project.finalCap = project.totalDeposit;
            emit CapstoneReached(_projectId, project.status);
        }

        IERC20(talax).transferFrom(_depositor, address(this), tokenPrice);
        emit Deposit(
            _depositor,
            _projectId,
            _nftContract,
            _tokenUri,
            tokenPrice
        );
    }

    function withdraw(
        bytes32[] memory _proof,
        uint256 _projectId,
        uint256 _amount
    ) public {
        Project memory project = projects[_projectId];
        if (project.deadline > block.timestamp) revert ProjectStillFunding();

        // Merkle Proof to check user is a depositor
        bytes32 leaf = _generateLeaf(abi.encode(_projectId, msg.sender));
        if (!MerkleProof.verify(_proof, project.projectRoot, leaf)) {
            revert InvalidProof();
        }

        IERC20(talax).transfer(msg.sender, _amount);
    }

    function mintNft(
        bytes32[] memory _proof,
        uint256 _projectId,
        address _nftContract,
        bytes32 _tokenUri
    ) public isRunning(_projectId) returns (bool) {
        Project memory project = projects[_projectId];
        // Merkle Proof to check user has already been picked this NFT
        bytes32 leaf = _generateLeaf(
            abi.encode(_projectId, _nftContract, _tokenUri, msg.sender)
        );
        if (!MerkleProof.verify(_proof, project.projectRoot, leaf)) {
            revert InvalidProof();
        }

        // Distribute Talax
        _distribute(
            project.artist,
            project.advisory,
            project.platform,
            _nftContract,
            NFT(_nftContract).tokenPrice()
        );

        emit NftMinted(msg.sender, _projectId, _nftContract, _tokenUri);
        return true;
    }

    function claimFunding(uint256 _projectId) public isRunning(_projectId) {
        if (msg.sender != projects[_projectId].owner) revert NotOwner();
        Project memory project = projects[_projectId];
        if (project.status == 0) revert ProjectFailed();

        uint256 amount = (project.project * project.finalCap) / 10_000;

        IERC20(talax).transfer(msg.sender, amount);

        emit FundClaimed(msg.sender, _projectId, amount);
    }

    function terminateProject(
        uint256 _projectId
    ) external onlyOwner isRunning(_projectId) {
        Project storage project = projects[_projectId];
        if (project.status > 0) revert ProjectSuccessfullyFunded();

        delete project.projectRoot;
    }

    function changeDuration(
        uint256 _projectId,
        uint256 _additionalTime
    ) external onlyOwner {
        if (projects[_projectId].deadline <= block.timestamp) {
            revert ProjectHasEnded();
        }
        projects[_projectId].deadline += _additionalTime;

        emit DurationChanged(_projectId, projects[_projectId].deadline);
    }

    function getProject(
        uint256 _projectId
    ) external view returns (Project memory) {
        return projects[_projectId];
    }

    /* ------------------------------------- Internal Functions ------------------------------------- */

    function _distribute(
        uint256 _artistFee,
        uint256 _advisoryFee,
        uint256 _platformFee,
        address _nftContract,
        uint256 _tokenPrice
    ) internal {
        address artist = NFT(_nftContract).artist();
        address advisory = Token(talax).advisory();
        address platform = Token(talax).platform();

        IERC20(talax).transfer(artist, (_artistFee * _tokenPrice) / 10_000);
        IERC20(talax).transfer(advisory, (_advisoryFee * _tokenPrice) / 10_000);
        IERC20(talax).transfer(platform, (_platformFee * _tokenPrice) / 10_000);
    }

    function _generateLeaf(
        bytes memory _encoded
    ) internal pure returns (bytes32) {
        return keccak256(bytes.concat(keccak256(_encoded)));
    }

    /* ------------------------------------------ Modifiers ----------------------------------------- */

    function _isRunning(uint256 _projectId) internal view {
        if (projects[_projectId].deadline >= block.timestamp) {
            revert ProjectStillFunding();
        }
    }

    modifier isRunning(uint256 _projectId) {
        _isRunning(_projectId);
        _;
    }
}