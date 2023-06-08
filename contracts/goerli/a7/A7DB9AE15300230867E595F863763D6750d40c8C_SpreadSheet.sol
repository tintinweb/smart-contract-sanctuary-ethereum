// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { Ownable } from "@openzeppelin/access/Ownable.sol";
import { Pausable } from "@openzeppelin/security/Pausable.sol";
import { IERC721 } from "@openzeppelin/token/ERC721/IERC721.sol";
import { MerkleProof } from "@openzeppelin/utils/cryptography/MerkleProof.sol";

/**
 *
 *     _____                          _ _____ _               _
 *    /  ___|                        | /  ___| |             | |
 *    \ `--. _ __  _ __ ___  __ _  __| \ `--.| |__   ___  ___| |_
 *     `--. \ '_ \| '__/ _ \/ _` |/ _` |`--. \ '_ \ / _ \/ _ \ __|
 *    /\__/ / |_) | | |  __/ (_| | (_| /\__/ / | | |  __/  __/ |_
 *    \____/| .__/|_|  \___|\__,_|\__,_\____/|_| |_|\___|\___|\__|
 *          | |
 *          |_|
 */

/// @title SpreadSheet
/// @notice Handles the claim and distribution of SHEETs.
contract SpreadSheet is Ownable, Pausable {
    /*//////////////////////////////////////////////////////////////////////////
                                       ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when the number of SHEETs an allocatee is trying to claim exceeds their allocation.
    ///
    /// @param allocatee The account that is trying to claim SHEETs.
    /// @param allocation The total number of SHEETs allocated to the allocatee.
    /// @param totalClaimedAfter The total number of SHEETs the allocatee is trying to have after claiming.
    error SpreadSheet__AllocationExceeded(address allocatee, uint256 allocation, uint256 totalClaimedAfter);

    /// @notice Thrown when the provided transition Merkle proof is invalid.
    ///
    /// @param sheetId The ID of the SHEET linked with the provided proof.
    /// @param botsId The ID of the BOT linked with the provided proof.
    error SpreadSheet__InvalidTransitionProof(uint256 sheetId, uint256 botsId);

    /// @notice Thrown when the provided allocation Merkle proof is invalid.
    ///
    /// @param allocatee The allocatee account linked with the provided proof.
    /// @param allocation The allocation amount linked with the provided proof.
    error SpreadSheet__InvalidAllocationProof(address allocatee, uint256 allocation);

    /// @notice Thrown when the provided allocation reserve Merkle proof is invalid.
    ///
    /// @param sheetId The ID of the SHEET linked with the provided proof.
    error SpreadSheet__InvalidAllocationReserveProof(uint256 sheetId);

    /// @notice Thrown when the provided arrays are not the same length.
    error SpreadSheet__MismatchedArrays();

    /// @notice Thrown when the caller is trying to claim 0 SHEETs.
    error SpreadSheet__ZeroClaim();

    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when claiming SHEETs in exchange for burning BOTS.
    /// @param claimer The account that claimed the SHEETs.
    /// @param sheetIds The IDs of the SHEETs that were claimed.
    /// @param botsIds The IDs of the BOTS that were burned.
    event ClaimSheetsViaTransition(address indexed claimer, uint256[] sheetIds, uint256[] botsIds);

    /// @notice Emitted when claiming SHEETs that were allocated to the caller account.
    /// @param claimer The account that claimed the SHEETs.
    /// @param sheetIds The IDs of the SHEETs that were claimed.
    /// @param allocation The total number of SHEETs allocated to the caller.
    event ClaimSheetsViaAllocation(address indexed claimer, uint256[] sheetIds, uint256 allocation);

    /// @notice Emitted when the owner withdraws SHEETs from the contract.
    /// @param recipient The account that received the SHEETs.
    /// @param sheetIds The IDs of the SHEETs that were withdrawn.
    event AdminWithdraw(address indexed recipient, uint256[] sheetIds);

    /// @notice Emitted when the owner pauses the claim process.
    event PauseClaims();

    /// @notice Emitted when the owner unpauses the claim process.
    event UnpauseClaims();

    /// @notice Emitted when the transition Merkle root is set.
    /// @param newTransitionMerkleRoot The new transition Merkle root.
    event SetTransitionMerkleRoot(bytes32 newTransitionMerkleRoot);

    /// @notice Emitted when the allocation Merkle root is set.
    /// @param newAllocationMerkleRoot The new allocation Merkle root.
    event SetAllocationMerkleRoot(bytes32 newAllocationMerkleRoot);

    /// @notice Emitted when the allocation reserve Merkle root is set.
    /// @param newAllocationReserveMerkleRoot The new allocation reserve Merkle root.
    event SetAllocationReserveMerkleRoot(bytes32 newAllocationReserveMerkleRoot);

    /*//////////////////////////////////////////////////////////////////////////
                                   PUBLIC STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice The Sheetheads NFT contract whose tokens are to be distributed.
    IERC721 public immutable sheetNFT;

    /// @notice The Pawn Bots NFT contract whose tokens are to be burned.
    IERC721 public immutable botsNFT;

    /// @notice The Merkle root of the BOTS -> SHEET transition Merkle tree.
    bytes32 public transitionMerkleRoot;

    /// @notice The Merkle root of the SHEET allocation Merkle tree.
    bytes32 public allocationMerkleRoot;

    /// @notice The Merkle root of the SHEET allocation reserve Merkle tree.
    bytes32 public allocationReserveMerkleRoot;

    /// @notice The total number of SHEETs claimed by an allocatee.
    mapping(address => uint256) public totalClaimed;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @param _sheetNFT The Sheetheads NFT contract whose tokens are to be distributed.
    /// @param _botsNFT The Pawn Bots NFT contract whose tokens are to be burned.
    constructor(IERC721 _sheetNFT, IERC721 _botsNFT) {
        sheetNFT = _sheetNFT;
        botsNFT = _botsNFT;
    }

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Claim SHEETs in exchange for burning BOTS.
    ///
    /// @dev Emits a {ClaimSheetsViaTransition} event.
    ///
    /// Requirements:
    /// - All provided arrays must be the same length.
    /// - The number of SHEETs to claim must be greater than 0.
    /// - Each provided transition Merkle proof must be valid.
    /// - The caller must own all of the BOTS IDs to burn.
    ///
    /// @param sheetIdsToClaim The IDs of the SHEETs to claim.
    /// @param botsIdsToBurn The IDs of the BOTS to burn.
    /// @param transitionProofs The Merkle proofs for verifying transition claims.
    function claimSheetsViaTransition(
        uint256[] calldata sheetIdsToClaim,
        uint256[] calldata botsIdsToBurn,
        bytes32[][] calldata transitionProofs
    )
        external
        whenNotPaused
    {
        if (sheetIdsToClaim.length != botsIdsToBurn.length || sheetIdsToClaim.length != transitionProofs.length) {
            revert SpreadSheet__MismatchedArrays();
        }
        if (sheetIdsToClaim.length == 0) {
            revert SpreadSheet__ZeroClaim();
        }
        for (uint256 i = 0; i < sheetIdsToClaim.length; i++) {
            if (
                !MerkleProof.verify({
                    proof: transitionProofs[i],
                    root: transitionMerkleRoot,
                    leaf: keccak256(abi.encodePacked(botsIdsToBurn[i], sheetIdsToClaim[i]))
                })
            ) {
                revert SpreadSheet__InvalidTransitionProof({ sheetId: sheetIdsToClaim[i], botsId: botsIdsToBurn[i] });
            }
            botsNFT.transferFrom({ from: msg.sender, to: address(0xdead), tokenId: botsIdsToBurn[i] });
            sheetNFT.transferFrom({ from: address(this), to: msg.sender, tokenId: sheetIdsToClaim[i] });
        }
        emit ClaimSheetsViaTransition({ claimer: msg.sender, sheetIds: sheetIdsToClaim, botsIds: botsIdsToBurn });
    }

    /// @notice Claim SHEETs that were allocated to the caller account.
    ///
    /// @dev Emits a {ClaimSheetsViaAllocation} event.
    ///
    /// Requirements:
    /// - All provided arrays must be the same length.
    /// - The number of SHEETs to claim must be greater than 0.
    /// - The provided allocation Merkle proof must be valid.
    /// - The number of SHEETs to claim must not exceed the number of SHEETs allocated to the caller account.
    /// - Each provided allocation reserve Merkle proof must be valid.
    ///
    /// @param sheetIdsToClaim The IDs of the SHEETs to claim.
    /// @param allocation The total number of SHEETs allocated to the caller.
    /// @param allocationProof The Merkle proof for verifying the allocation claim.
    /// @param allocationReserveProofs The Merkle proofs for verifying allocation reserve claims.
    function claimSheetsViaAllocation(
        uint256[] calldata sheetIdsToClaim,
        uint256 allocation,
        bytes32[] calldata allocationProof,
        bytes32[][] calldata allocationReserveProofs
    )
        external
        whenNotPaused
    {
        if (sheetIdsToClaim.length != allocationReserveProofs.length) {
            revert SpreadSheet__MismatchedArrays();
        }
        if (sheetIdsToClaim.length == 0) {
            revert SpreadSheet__ZeroClaim();
        }
        if (
            !MerkleProof.verify({
                proof: allocationProof,
                root: allocationMerkleRoot,
                leaf: keccak256(abi.encodePacked(msg.sender, allocation))
            })
        ) {
            revert SpreadSheet__InvalidAllocationProof({ allocatee: msg.sender, allocation: allocation });
        }
        uint256 totalClaimedAfter = sheetIdsToClaim.length + totalClaimed[msg.sender];
        if (totalClaimedAfter > allocation) {
            revert SpreadSheet__AllocationExceeded({
                allocatee: msg.sender,
                allocation: allocation,
                totalClaimedAfter: totalClaimedAfter
            });
        }
        totalClaimed[msg.sender] = totalClaimedAfter;
        for (uint256 i = 0; i < sheetIdsToClaim.length; i++) {
            if (
                !MerkleProof.verify({
                    proof: allocationReserveProofs[i],
                    root: allocationReserveMerkleRoot,
                    leaf: keccak256(abi.encodePacked(sheetIdsToClaim[i]))
                })
            ) {
                revert SpreadSheet__InvalidAllocationReserveProof(sheetIdsToClaim[i]);
            }
            sheetNFT.transferFrom({ from: address(this), to: msg.sender, tokenId: sheetIdsToClaim[i] });
        }
        emit ClaimSheetsViaAllocation({ claimer: msg.sender, sheetIds: sheetIdsToClaim, allocation: allocation });
    }

    /// @notice Withdraw SHEETs from the contract.
    ///
    /// @dev Emits a {AdminWithdraw} event.
    ///
    /// Requirements:
    /// - The caller must be the owner.
    ///
    /// @param recipient The address to withdraw to.
    /// @param sheetIds The IDs of the SHEETs to withdraw.
    function adminWithdraw(address recipient, uint256[] calldata sheetIds) external onlyOwner whenPaused {
        for (uint256 i = 0; i < sheetIds.length; i++) {
            sheetNFT.transferFrom({ from: address(this), to: recipient, tokenId: sheetIds[i] });
        }
        emit AdminWithdraw({ recipient: recipient, sheetIds: sheetIds });
    }

    /// @notice Pause the claim process.
    ///
    /// @dev Emits a {PauseClaims} event.
    ///
    /// Requirements:
    /// - The caller must be the owner.
    ///
    function pauseClaims() external onlyOwner {
        _pause();
        emit PauseClaims();
    }

    /// @notice Unpause the claim process.
    ///
    /// @dev Emits an {UnpauseClaims} event.
    ///
    /// Requirements:
    /// - The caller must be the owner.
    ///
    function unpauseClaims() external onlyOwner {
        _unpause();
        emit UnpauseClaims();
    }

    /// @notice Set the Merkle root of the BOTS -> SHEET transition Merkle tree.
    ///
    /// @dev Emits a {SetTransitionMerkleRoot} event.
    ///
    /// Requirements:
    /// - The caller must be the owner.
    ///
    /// @param newTransitionMerkleRoot The new transition Merkle root.
    function setTransitionMerkleRoot(bytes32 newTransitionMerkleRoot) external onlyOwner {
        transitionMerkleRoot = newTransitionMerkleRoot;
        emit SetTransitionMerkleRoot(newTransitionMerkleRoot);
    }

    /// @notice Set the Merkle root of the SHEET allocation Merkle tree.
    ///
    /// @dev Emits a {SetAllocationMerkleRoot} event.
    ///
    /// Requirements:
    /// - The caller must be the owner.
    ///
    /// @param newAllocationMerkleRoot The new allocation Merkle root.
    function setAllocationMerkleRoot(bytes32 newAllocationMerkleRoot) external onlyOwner {
        allocationMerkleRoot = newAllocationMerkleRoot;
        emit SetAllocationMerkleRoot(newAllocationMerkleRoot);
    }

    /// @notice Set the Merkle root of the SHEET allocation reserve Merkle tree.
    ///
    /// @dev Emits a {SetAllocationReserveMerkleRoot} event.
    ///
    /// Requirements:
    /// - The caller must be the owner.
    ///
    /// @param newAllocationReserveMerkleRoot The new allocation reserve Merkle root.
    function setAllocationReserveMerkleRoot(bytes32 newAllocationReserveMerkleRoot) external onlyOwner {
        allocationReserveMerkleRoot = newAllocationReserveMerkleRoot;
        emit SetAllocationReserveMerkleRoot(newAllocationReserveMerkleRoot);
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

// SPDX-License-Identifier: MIT
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