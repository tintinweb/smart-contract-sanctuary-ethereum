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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████▀▀╙╙╙└     ,▄▓██████████
// █████████████████████████████████████████▀▀▀▀▀╙╙'   ¡╟▓      ,,,▄▓▓█████████████
// ████████████████████████▀▀╙╙╙╙╙▀▀█████▒         ,▄▄▓██▌    ⁿ▀▀▀▀▀▀██████████████
// ██████████████████▀╙              ╚███     ▓▓▓████████          ╓▓██████████████
// ██████████████████,     ╔▓▓▓██▒    ╟█          ,╟▓███▌    ╔▄▄▓██████████████████
// ███████████████████ε    ▓█████╩    ╠⌐    ≡▄▄▄▓███████╬   ╔██████████████████████
// ██████████████████▌    ╟████▀`    ▄▌   «▓██▀▀▀▀▀╙╙╠╠╣▒  ╔███████████████████████
// ██████████████████    ║███╨     ╔██╬          ,╔▓████▓▒▄████████████████████████
// █████████████████▓   ╔█▀`    ,▄████▌ ,,,╓▄▄▓▓███████████████████████████████████
// █████████████████▌,;φ╙   ,╔▓████████▓███████████████████████████████████████████
// ██████████████████▓▒╓▄▄▓████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀

/**
 * @author emrecolako.eth
 * @title SecretSanta for DEF DAO!
 */

contract SecretSanta is ERC721Holder {
    /// @notice Individual NFT details + Index
    struct Vault {
        address erc721Address;
        uint256 erc721TokenId;
        uint256 erc721Index;
    }

    /// @notice Gift address & tokenId
    struct Gift {
        address erc721Address;
        uint256 erc721TokenId;
    }

    /*//////////////////////////////////////////////////////////////
                          ERRORS
    //////////////////////////////////////////////////////////////*/
    /// @notice If user has already collected
    error AlreadyCollected();
    /// @notice If collection period is not active
    error CollectionPeriodIsNotActive();
    /// @notice Throws error if depositWindow is closed
    error DepositWindowClosed();
    /// @notice If user has already deposited
    error GiftAlreadyDeposited();
    /// @notice User isn't allowed
    error MerkleProofInvalid();
    /// @notice If user hasn't made any deposits
    error No_Deposits();
    /// @notice No Gifts available
    error No_Gifts_Available();
    /// @notice If user is not the token owner
    error NotTokenOwner();
    /// @notice If user is not the owner of the contract
    error NotOwner();
    /// @notice Throws error if address = 0
    error ZeroAddress();

    uint256 public reclaimTimestamp;
    uint256 private _offSet;
    address public ownerAddress;
    bool public collectionOpen = false;

    bytes32 public merkleRoot;

    Gift[] public gifts;

    mapping(address => Vault) public Depositors;
    mapping(address => Gift) public collectedGifts;
    mapping(address => uint256) public DepositCount;
    mapping(address => bool) public depositedGifts;

    // Events
    event AllowlistUpdated(bytes32 merkleRoot);
    event GiftCollected(
        address erc721Address,
        address senderAddress,
        uint256 erc721TokenId
    );

    event GiftDeposited(
        address erc721Address,
        address senderAddress,
        uint256 erc721TokenId
    );

    /*//////////////////////////////////////////////////////////////
                          MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier nonZeroAddress(address _nftaddress) {
        if (_nftaddress == address(0)) revert ZeroAddress();
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != ownerAddress) revert NotOwner();
        _;
    }

    modifier onlyOwnerOf(address _nftaddress, uint256 _tokenId) {
        if (
            msg.sender != IERC721(_nftaddress).ownerOf(_tokenId) &&
            msg.sender != IERC721(_nftaddress).getApproved(_tokenId)
        ) revert NotTokenOwner();
        _;
    }

    // @notice Requires a valid merkle proof for the specified merkle root.
    modifier onlyIfValidMerkleProof(bytes32 root, bytes32[] calldata proof) {
        if (
            !MerkleProof.verify(
                proof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            )
        ) {
            revert MerkleProofInvalid();
        }
        _;
    }

    modifier CollectionPeriodActive() {
        if (!collectionOpen) revert CollectionPeriodIsNotActive();
        _;
    }

    modifier DepositWindowActive() {
        if (collectionOpen) revert DepositWindowClosed();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                          CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(uint256 _reclaimTimestamp, bytes32 _merkleRoot) {
        reclaimTimestamp = _reclaimTimestamp;
        ownerAddress = msg.sender;
        merkleRoot = _merkleRoot;
    }

    /*//////////////////////////////////////////////////////////////
                          SANTA FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Allows users to deposit gifts
    function deposit(
        address _nftaddress,
        uint256 _tokenId,
        bytes32[] calldata proof
    )
        public
        nonZeroAddress(_nftaddress)
        onlyOwnerOf(_nftaddress, _tokenId)
        onlyIfValidMerkleProof(merkleRoot, proof)
        DepositWindowActive
    {
        // Check if the user has already deposited a gift
        if (depositedGifts[msg.sender]) {
            revert GiftAlreadyDeposited();
        }

        IERC721(_nftaddress).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId
        );

        gifts.push(Gift(_nftaddress, _tokenId));

        DepositCount[msg.sender]++;
        Depositors[msg.sender] = Vault(_nftaddress, _tokenId, gifts.length);

        // Mark the user as having deposited a gift
        depositedGifts[msg.sender] = true;
        emit GiftDeposited(_nftaddress, msg.sender, _tokenId);
    }

    function toggleCollection() public onlyOwner {
        collectionOpen = !collectionOpen;
    }

    /// @notice Allows depositors to collect gifts
    function collect() public CollectionPeriodActive {
        if (!depositedGifts[msg.sender]) {
            revert No_Deposits();
        }

        if (collectedGifts[msg.sender].erc721Address != address(0))
            revert AlreadyCollected();

        uint256 giftIdx;

        if (gifts.length == 0) {
            revert No_Gifts_Available();
        } else if (gifts.length == 1) {
            giftIdx = 0;
        } else if (gifts.length == 2) {
            giftIdx = (_offSet % 2 == 0) ? 0 : 1;
        } else {
            uint256 randomNumber = _randomNumber();
            giftIdx = ((randomNumber % gifts.length) + _offSet) % gifts.length;
        }

        Gift memory gift = gifts[giftIdx];

        emit GiftCollected(gift.erc721Address, msg.sender, gift.erc721TokenId);

        IERC721(gift.erc721Address).safeTransferFrom(
            address(this),
            msg.sender,
            gift.erc721TokenId
        );

        _offSet = _offSet + 1;
    }

    /*//////////////////////////////////////////////////////////////
                          ALLOWLIST FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // @notice Allows users to check if their wallet has been allowlisted
    function allowListed(address _wallet, bytes32[] calldata _proof)
        public
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                _proof,
                merkleRoot,
                keccak256(abi.encodePacked(_wallet))
            );
    }

    // @notice Updates merkleRoot of allowlist
    function updateAllowList(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
        emit AllowlistUpdated(merkleRoot);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL + ADMIN
    //////////////////////////////////////////////////////////////*/

    /// @notice Random number generator
    function _randomNumber() internal view returns (uint256) {
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty,
                    block.timestamp,
                    gifts.length,
                    block.number,
                    blockhash(block.number - 1),
                    msg.sender,
                    tx.gasprice
                )
            )
        );
        return randomNumber;
    }

    /// @notice Emergency function to withdraw certain NFT
    function adminWithdraw(
        address _nftaddress,
        uint256 _tokenId,
        address recipient
    ) external onlyOwner {
        IERC721(_nftaddress).transferFrom(address(this), recipient, _tokenId);
    }

    ///@notice function that allows the contract owner to reclaim uncollected gifts
    function reclaimGifts(address _transferAddress) public onlyOwner {
        // Check if the reclaim timestamp has passed
        if (block.timestamp < reclaimTimestamp) {
            // Reclaim timestamp has not passed, do nothing
            return;
        }

        // Loop through all gifts and check if they have been collected
        for (uint256 i = 0; i < gifts.length; i++) {
            Gift memory gift = gifts[i];
            if (gift.erc721Address == address(0)) continue;

            // Check if the gift has been collected
            if (
                IERC721(gift.erc721Address).ownerOf(gift.erc721TokenId) !=
                address(this)
            ) {
                // Gift has been collected, do nothing
                continue;
            }

            // Gift has not been collected, reclaim it
            if (_transferAddress == address(0)) {
                // Transfer the gift back to the original depositor
                IERC721(gift.erc721Address).safeTransferFrom(
                    ownerAddress,
                    IERC721(gift.erc721Address).ownerOf(gift.erc721TokenId),
                    gift.erc721TokenId
                );
            } else {
                // Transfer the gift to the specified address
                IERC721(gift.erc721Address).safeTransferFrom(
                    ownerAddress,
                    _transferAddress,
                    gift.erc721TokenId
                );
            }
        }
    }
}