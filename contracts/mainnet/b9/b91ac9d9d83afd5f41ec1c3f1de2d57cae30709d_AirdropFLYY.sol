/**
 *Submitted for verification at Etherscan.io on 2022-11-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

interface ITokenVestingFLYY {
    function createVestingSchedule(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 _slicePeriodSeconds,
        uint256 _amount
    ) external;
}

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
    function processProof(bytes32[] memory proof, bytes32 leaf)
        internal
        pure
        returns (bytes32)
    {
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
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf)
        internal
        pure
        returns (bytes32)
    {
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
        require(
            leavesLen + proof.length - 1 == totalHashes,
            "MerkleProof: invalid multiproof"
        );

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
            bytes32 a = leafPos < leavesLen
                ? leaves[leafPos++]
                : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++]
                : proof[proofPos++];
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
        require(
            leavesLen + proof.length - 1 == totalHashes,
            "MerkleProof: invalid multiproof"
        );

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
            bytes32 a = leafPos < leavesLen
                ? leaves[leafPos++]
                : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++]
                : proof[proofPos++];
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

    function _efficientHash(bytes32 a, bytes32 b)
        private
        pure
        returns (bytes32 value)
    {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

contract AirdropFLYY is Ownable, ReentrancyGuard {
    IERC20 public tokenContractAddress =
        IERC20(0xd324Ba09f83A109da048001bBFb0E84C9733150E);
    uint8 private constant _tokenDecimals = 18;

    ITokenVestingFLYY public vestingContractAddress =
        ITokenVestingFLYY(0xE7FafeBd53Def137595aB6B7697D76F49b2073f6);
    uint8 private _unlockedPercentageTGE = 10;
    uint256 private _vestingStart = block.timestamp;
    uint256 private _vestingCliff = 7889229;
    uint256 private _vestingDuration = 31556916;
    uint256 private _vestingSlicePeriodSeconds = 2629743;

    mapping(address => uint256) private _claimCountOfAddress;
    mapping(address => bool) private _isIncludedInWhitelist;
    uint256 public claimStartTime = 0;
    uint256 public allowedClaimCount = 1;

    uint256 private _pot1TokenRewards = 280 * 10**_tokenDecimals;
    uint256 private _pot2TokenRewards = 400 * 10**_tokenDecimals;
    uint256 private _pot3TokenRewards = 800 * 10**_tokenDecimals;
    uint256 private _pot4TokenRewards = 1600 * 10**_tokenDecimals;
    uint256 private _pot5TokenRewards = 5000 * 10**_tokenDecimals;

    uint256 private _pot1ClaimPeriod = 432000;
    uint256 private _pot2ClaimPeriod = 432000;
    uint256 private _pot3ClaimPeriod = 432000;
    uint256 private _pot4ClaimPeriod = 432000;
    uint256 private _pot5ClaimPeriod = 432000;

    bytes32 private _pot1MerkleRoot =
        0x9e2da8fcfdeea62af574de239954c0cf222f9dc76dba04a7e06c2f8fb17c0b40;
    bytes32 private _pot2MerkleRoot =
        0x92dcb97174a8c866dffcd14f0475875607af2e53c7dd39d7d27b3798d0bc39fa;
    bytes32 private _pot3MerkleRoot =
        0x3591bdbf8aed7630feac83518dabedd3f8a2e4ed1c35b6d41771e1c9bc1921bb;
    bytes32 private _pot4MerkleRoot =
        0x6206998bd052af2f895dc0993862ad352b48946ec6ab364ef2965962f6742e12;
    bytes32 private _pot5MerkleRoot =
        0xd847f59f45dfa4e75a3694e6e8229c6a2e3e9142fb6a1fcb14fe8608989d7150;

    event WinnerTokensClaimed(address, uint256);

    constructor() {}

    function getAllPotsMerkleRoot()
        external
        view
        returns (
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32
        )
    {
        return (
            _pot1MerkleRoot,
            _pot2MerkleRoot,
            _pot3MerkleRoot,
            _pot4MerkleRoot,
            _pot5MerkleRoot
        );
    }

    function getAllPotsTokenRewards()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            _pot1TokenRewards,
            _pot2TokenRewards,
            _pot3TokenRewards,
            _pot4TokenRewards,
            _pot5TokenRewards
        );
    }

    function getAllPotsClaimPeriods()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            _pot1ClaimPeriod,
            _pot2ClaimPeriod,
            _pot3ClaimPeriod,
            _pot4ClaimPeriod,
            _pot5ClaimPeriod
        );
    }

    function getVestingSchedule()
        external
        view
        returns (
            uint8,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            _unlockedPercentageTGE,
            _vestingStart,
            _vestingCliff,
            _vestingDuration,
            _vestingSlicePeriodSeconds
        );
    }

    function changePotMerkleRoot(uint8 potNumber, bytes32 merkleRoot_)
        external
        onlyOwner
        returns (bool)
    {
        require(
            potNumber > 0 && potNumber < 6,
            "AirdropFLYY: pot number must be between 1 to 5"
        );
        if (potNumber == 1) {
            _pot1MerkleRoot = merkleRoot_;
        } else if (potNumber == 2) {
            _pot2MerkleRoot = merkleRoot_;
        } else if (potNumber == 3) {
            _pot3MerkleRoot = merkleRoot_;
        } else if (potNumber == 4) {
            _pot4MerkleRoot = merkleRoot_;
        } else {
            _pot5MerkleRoot = merkleRoot_;
        }

        return true;
    }

    function changePotTokenRewardsAndClaimPeriod(
        uint8 potNumber,
        uint256 newTokenRewards,
        uint256 newClaimPeriod
    ) external onlyOwner returns (bool) {
        require(
            potNumber > 0 && potNumber < 6,
            "AirdropFLYY: pot number must be between 1 to 5"
        );
        if (potNumber == 1) {
            _pot1TokenRewards = newTokenRewards;
            _pot1ClaimPeriod = newClaimPeriod;
        } else if (potNumber == 2) {
            _pot2TokenRewards = newTokenRewards;
            _pot2ClaimPeriod = newClaimPeriod;
        } else if (potNumber == 3) {
            _pot3TokenRewards = newTokenRewards;
            _pot3ClaimPeriod = newClaimPeriod;
        } else if (potNumber == 4) {
            _pot4TokenRewards = newTokenRewards;
            _pot4ClaimPeriod = newClaimPeriod;
        } else {
            _pot5TokenRewards = newTokenRewards;
            _pot5ClaimPeriod = newClaimPeriod;
        }

        return true;
    }

    function changeAllowedClaimCount(uint256 allowedClaimCount_)
        external
        onlyOwner
        returns (bool)
    {
        allowedClaimCount = allowedClaimCount_;

        return true;
    }

    function changeClaimAndVestingStartTime(
        uint256 claimStartTime_,
        uint256 vestingStart_
    ) external onlyOwner returns (bool) {
        claimStartTime = claimStartTime_;
        _vestingStart = vestingStart_;

        return true;
    }

    function changeVestingContractAddress(address newContractAddress)
        external
        onlyOwner
        returns (bool)
    {
        vestingContractAddress = ITokenVestingFLYY(newContractAddress);

        return true;
    }

    function changeTokenContractAddress(address newContractAddress)
        external
        onlyOwner
        returns (bool)
    {
        tokenContractAddress = IERC20(newContractAddress);

        return true;
    }

    function changeVestingSchedule(
        uint8 unlockedPercentageTGE_,
        uint256 vestingStart_,
        uint256 vestingCliff_,
        uint256 vestingDuration_,
        uint256 vestingSlicePeriodSeconds_
    ) external onlyOwner returns (bool) {
        require(
            unlockedPercentageTGE_ <= 100,
            "AirdropFLYY: unlocked TGE percentage must not be greater than 100"
        );

        _unlockedPercentageTGE = unlockedPercentageTGE_;
        _vestingStart = vestingStart_;
        _vestingCliff = vestingCliff_;
        _vestingDuration = vestingDuration_;
        _vestingSlicePeriodSeconds = vestingSlicePeriodSeconds_;

        return true;
    }

    function isWhitelisted(
        address account,
        bytes32[] memory proof,
        bytes32 root
    ) public pure returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(account));

        return MerkleProof.verify(proof, root, leaf);
    }

    function claimToken(
        bytes32[] memory pot1MerkleProof_,
        bytes32[] memory pot2MerkleProof_,
        bytes32[] memory pot3MerkleProof_,
        bytes32[] memory pot4MerkleProof_,
        bytes32[] memory pot5MerkleProof_
    ) external nonReentrant returns (bool) {
        uint8 potNumber = 0;
        if (isWhitelisted(_msgSender(), pot1MerkleProof_, _pot1MerkleRoot)) {
            potNumber = 1;
        } else if (
            isWhitelisted(_msgSender(), pot2MerkleProof_, _pot2MerkleRoot)
        ) {
            potNumber = 2;
        } else if (
            isWhitelisted(_msgSender(), pot3MerkleProof_, _pot3MerkleRoot)
        ) {
            potNumber = 3;
        } else if (
            isWhitelisted(_msgSender(), pot4MerkleProof_, _pot4MerkleRoot)
        ) {
            potNumber = 4;
        } else if (
            isWhitelisted(_msgSender(), pot5MerkleProof_, _pot5MerkleRoot)
        ) {
            potNumber = 5;
        } else {
            revert("AirdropFLYY: calling account address is not whitelisted");
        }
        _claimToken(potNumber);

        return true;
    }

    function _claimToken(uint8 potNumber) private {
        address beneficiary = _msgSender();
        uint256 claimableRewards;
        uint256 potClaimPeriod;

        if (potNumber == 1) {
            claimableRewards = _pot1TokenRewards;
            potClaimPeriod = _pot1ClaimPeriod;
        } else if (potNumber == 2) {
            claimableRewards = _pot2TokenRewards;
            potClaimPeriod = _pot2ClaimPeriod;
        } else if (potNumber == 3) {
            claimableRewards = _pot3TokenRewards;
            potClaimPeriod = _pot3ClaimPeriod;
        } else if (potNumber == 4) {
            claimableRewards = _pot4TokenRewards;
            potClaimPeriod = _pot4ClaimPeriod;
        } else {
            claimableRewards = _pot5TokenRewards;
            potClaimPeriod = _pot5ClaimPeriod;
        }

        require(
            _claimCountOfAddress[beneficiary] < allowedClaimCount,
            "AirdropFLYY: allowed claim count limit exceeded"
        );
        require(
            (claimStartTime + potClaimPeriod) > block.timestamp,
            "AirdropFLYY: claim period already passed"
        );
        require(
            getContractTokenBalance() >= claimableRewards,
            "AirdropFLYY: claimable rewards exceed contract token balance"
        );

        uint256 unlockedShareTGE = (claimableRewards * _unlockedPercentageTGE) /
            100;
        uint256 vestingShare = claimableRewards - unlockedShareTGE;

        if (unlockedShareTGE > 0) {
            require(
                tokenContractAddress.transfer(beneficiary, unlockedShareTGE),
                "AirdropFLYY: token FLYY transfer to winner not succeeded"
            );
        }
        if (vestingShare > 0) {
            _sendToVesting(beneficiary, vestingShare);
        }

        _claimCountOfAddress[beneficiary]++;

        emit WinnerTokensClaimed(beneficiary, claimableRewards);
    }

    function _sendToVesting(address beneficiary, uint256 amount) private {
        if (_vestingCliff == 1 && _vestingDuration == 1) {
            require(
                tokenContractAddress.transfer(beneficiary, amount),
                "AirdropFLYY: token FLYY transfer to winner not succeeded"
            );
        } else {
            require(
                tokenContractAddress.approve(
                    address(vestingContractAddress),
                    amount
                ),
                "AirdropFLYY: token FLYY approve to vesting contract not succeeded"
            );
            vestingContractAddress.createVestingSchedule(
                beneficiary,
                _vestingStart,
                _vestingCliff,
                _vestingDuration,
                _vestingSlicePeriodSeconds,
                amount
            );
        }
    }

    function getContractTokenBalance() public view returns (uint256) {
        return tokenContractAddress.balanceOf(address(this));
    }

    function withdrawContractTokenBalance(uint256 amount) external onlyOwner {
        require(
            getContractTokenBalance() >= amount,
            "TokenVestingFLYY: withdrawable funds exceed contract token balance"
        );
        require(
            tokenContractAddress.transfer(owner(), amount),
            "AirdropFLYY: token FLYY transfer to winner not succeeded"
        );
    }

    function getCurrentTime() external view returns (uint256) {
        return block.timestamp;
    }
}