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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
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
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";
import { IERC721 } from "openzeppelin-contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "openzeppelin-contracts/token/ERC1155/IERC1155.sol";
import { IERC721Receiver } from "openzeppelin-contracts/token/ERC721/IERC721Receiver.sol";
import { IERC1155Receiver } from "openzeppelin-contracts/token/ERC1155/IERC1155Receiver.sol";

enum State{ UNOPENED, SUBMISSION, GIFTING, CLOSED }

struct Gift {
  uint256 nextTouch;
  uint256 poolIndex;
  uint256 stolenCount;
  uint256 tokenId;
  address tokenContract;
}

/// @notice An implmentation of an NFT Secret Santa experiment.
/// @author JingleBeanz (github.com/heyskylark/jingle-beanz/jingle-contract/src/JingleBeanz.sol)
contract JingleBeanz is Ownable {
  /*//////////////////////////////////////////////
                      ERRORS
  //////////////////////////////////////////////*/

  error WrongState(State _currentState, State _requiredState);

  error AlreadySubmitted();

  error InvalidGift();

  error Unauthorized();

  error AlreadyHaveGift();

  error AlreadyOwnedGift();

  error GiftCooldownNotComplete();

  error GiftDoesNotExist();

  error MaxGiftSteals();

  error NoGiftOwner();

  error ZeroAddress();

  error OwnerWithdrawLocked();

  /*//////////////////////////////////////////////
                      EVENTS
  //////////////////////////////////////////////*/

  event Submitted(
    address indexed _from,
    uint256 indexed giftId,
    address tokenContract,
    uint256 tokenId
  );

  event Gifted(address indexed _to, uint256 indexed giftId);

  event Stolen(address indexed _from, address indexed _to, uint256 indexed giftId);

  event Withdraw(address indexed _to, uint256 indexed giftId);

  event StateChange(State indexed _state);

  /*//////////////////////////////////////////////
                      MODIFIERS
  //////////////////////////////////////////////*/

  /// @notice only allows submitted senders to make calls
  modifier onlySubmitted() {
    if (_giftGiver[msg.sender] == 0) revert Unauthorized();
    _;
  }

  /// @notice only allows a call to be made when the contract is set to a specific state
  modifier onlyWhenState(State _state) {
    if (_state != state) revert WrongState(state, _state);
    _;
  }

  /*//////////////////////////////////////////////
              JINGLE METADATA STORAGE
  //////////////////////////////////////////////*/

  State public state;

  uint256 public giftId;
  
  uint256 public poolSize;

  bytes32 public userMerkleRoot;

  bytes32 public giftMerkleRoot;

  uint256 private seed;

  uint256 private withdrawReleaseDate;

  uint256 constant public STEAL_COOLDOWN = 6 hours;

  /// @dev lockout so owner can withdraw and raffle off stray gifts that were never picked up (5 day game + 14 day lockout)
  uint256 constant public OWNER_WITHDRAW_LOCKOUT = 19 days;

  /*//////////////////////////////////////////////
                    GIFT STORAGE
  //////////////////////////////////////////////*/

  /// @notice a mapping to keep track of all unclaimed gifts in a pool
  /// @dev cheaper to swap gift IDs outside of the pool size than whole gift struct
  /// @dev due to being unsure of the final array size until after submissions are closed I figuered mapping would be more efficient
  mapping(uint256 => uint256) internal _giftPool;

  /// @notice a mapping of gift IDs to gift
  mapping(uint256 => Gift) internal _gift;

  function gift(uint256 _giftId) public view returns (Gift memory returnGift) {
    returnGift = _gift[_giftId];
    if (returnGift.tokenContract == address(0)) revert GiftDoesNotExist();
  }

  /// @notice a mapping of gift giver address to gift ID
  mapping(address => uint256) internal _giftGiver;

  function giftGiver(address _giver) public view returns (uint256) {
    if (_giver == address(0)) {
      revert ZeroAddress();
    }

    return _giftGiver[_giver];
  }

  /// @notice given a gift ID returns current owner of claimed gift
  mapping(uint256 => address) internal _ownerOf;

  function ownerOf(uint256 _giftId) public view returns (address giftOwner) {
    if ((giftOwner = _ownerOf[_giftId]) == address(0)) revert NoGiftOwner();
  }

  /// @notice returns the gift ID the address owns
  mapping(address => uint256) internal _ownsGift;

  function ownsGift(address _owner) public view returns (uint256) {
    if (_owner == address(0)) {
      revert ZeroAddress();
    }

    return _ownsGift[_owner];
  }

  /// @notice a mapping to check if a user has been in contact with a gift before
  mapping(address => mapping(uint256 => bool)) internal _touchedGift;

  function touchedGift(address _user, uint256 _giftId) public view returns (bool) {
    if (_user == address(0)) {
      revert ZeroAddress();
    }

    return _touchedGift[_user][_giftId];
  }

  /*//////////////////////////////////////////////
                    CONSTRUCTOR
  //////////////////////////////////////////////*/

  constructor(bytes32 _userMerkleRoot, bytes32 _giftMerkleRoot) {
    state = State.UNOPENED;
    userMerkleRoot = _userMerkleRoot;
    giftMerkleRoot = _giftMerkleRoot;

    withdrawReleaseDate = block.timestamp + OWNER_WITHDRAW_LOCKOUT;
  }

  /*//////////////////////////////////////////////
                    JINGLE LOGIC
  //////////////////////////////////////////////*/

  /// @notice used for a caller to submit a gift and participate in the Secret Santa. The submitting user can only submit once.
  /// @param _tokenId the ID of the gifted token
  /// @param _tokenContract the contract address for the token contract
  /// @param _userMerkleProof merkle proof to check if caller is whitelisted
  /// @param _giftMerkleProof merkle proof of the submitted token gift address
  function submitGift(
    uint256 _tokenId,
    address _tokenContract,
    bytes32[] calldata _userMerkleProof,
    bytes32[] calldata _giftMerkleProof
  ) public onlyWhenState(State.SUBMISSION) {
    if (!isUserWhiteListed(msg.sender, _userMerkleProof)) revert Unauthorized();
    if (!isTokenApproved(_tokenContract, _giftMerkleProof)) revert InvalidGift();
    if (_giftGiver[msg.sender] != 0) revert AlreadySubmitted();

    // Would be insane if 2^256 - 1 gifts were gifted
    unchecked {
      giftId++;
      poolSize++;
    }

    Gift memory newGift = Gift({
      nextTouch: 0,
      poolIndex: poolSize,
      stolenCount: 0,
      tokenId: _tokenId,
      tokenContract: _tokenContract
    });

    _giftGiver[msg.sender] = giftId;
    _gift[giftId] = newGift;
    _giftPool[poolSize] = giftId;

    if (isERC721(_tokenContract)) {
      IERC721(_tokenContract).safeTransferFrom(msg.sender, address(this), _tokenId);
    } else {
      IERC1155(_tokenContract).safeTransferFrom(msg.sender, address(this), _tokenId, 1, "");
    }

    emit Submitted(msg.sender, giftId, _tokenContract, _tokenId);
  }

  /// @notice if the caller does not already have a gift, this function will give them a gift randomly from the gift pool
  function getRandomGift() public onlySubmitted onlyWhenState(State.GIFTING) returns (uint256) {    
    return internalGetRandomGift();
  }

  function internalGetRandomGift() internal returns (uint256) {
    if (_ownsGift[msg.sender] != 0) revert AlreadyHaveGift();

    uint256 randomPoolIndex = getRandomPoolIndex();
    uint256 id = _giftPool[randomPoolIndex];

    /// @dev swaps the claimed gift with the last valid gift in the pool then shrinks the pool size
    if (randomPoolIndex < poolSize) {
      _giftPool[randomPoolIndex] = _giftPool[poolSize--];
    } else {
      unchecked {
        poolSize--;
      }
    }

    _gift[id].nextTouch = block.timestamp + STEAL_COOLDOWN;
    _ownerOf[id] = msg.sender;
    _ownsGift[msg.sender] = id;
    _touchedGift[msg.sender][id] = true;

    emit Gifted(msg.sender, id);

    return id;
  }

  /// @notice if the caller does not have a gift, this allows the caller to steal a gift from another user
  /// @param _giftId the ID of the gift the caller wants to steal
  function stealGift(uint256 _giftId) public onlySubmitted onlyWhenState(State.GIFTING) {
    if (_ownsGift[msg.sender] != 0) revert AlreadyHaveGift();
    /// @dev caller can't steal a gift they already owned
    if (_touchedGift[msg.sender][_giftId]) revert AlreadyOwnedGift();

    address prevOwner = _ownerOf[_giftId];

    /// @dev can't steal a gift from nobody
    if (prevOwner == address(0)) revert NoGiftOwner();

    Gift storage stolenGift = _gift[_giftId];
    /// @dev only 1 steal every 6 hours
    if (block.timestamp < stolenGift.nextTouch) revert GiftCooldownNotComplete();
    /// @dev max steals for a gift is 2
    if (stolenGift.stolenCount == 2) revert MaxGiftSteals();

    stolenGift.nextTouch = block.timestamp + STEAL_COOLDOWN;
    unchecked {
      stolenGift.stolenCount++;
    }

    _ownerOf[_giftId] = msg.sender;
    _ownsGift[msg.sender] = _giftId;
    _ownsGift[prevOwner] = 0;
    _touchedGift[msg.sender][_giftId] = true;

    emit Stolen(prevOwner, msg.sender, _giftId);
  }

  /// @notice allows the caller to transfer out their gifted token after the games have ended
  function withdrawGift() public onlySubmitted onlyWhenState(State.CLOSED) returns (uint256) {
    /// @dev If no gift in possesion, grab random gift from pool
    uint256 id = _ownsGift[msg.sender];
    if (id == 0) {
      id = internalGetRandomGift();
    }

    /// @dev prevent re-entry to take multiple ERC-1155
    delete _giftGiver[msg.sender];

    Gift memory withdrawnGift = _gift[id];
    uint256 withdrawnGiftId = withdrawnGift.tokenId;
    address contractAddress = withdrawnGift.tokenContract;
    giftTransfer(contractAddress, withdrawnGiftId);

    emit Withdraw(msg.sender, id);

    return id;
  }

  /// @notice allows the caller to withdraw their gift while submissions are still open
  function withdrawFromGame() public onlySubmitted onlyWhenState(State.SUBMISSION) {
    uint256 id = _giftGiver[msg.sender];
    Gift memory withdrawnGift = _gift[id];
    uint256 withdrawnGiftPoolIndex = withdrawnGift.poolIndex;

    /// @dev swap only necessary when in the middle of the pool
    if (withdrawnGiftPoolIndex < poolSize) {
      uint256 endOfPoolGiftId = _giftPool[poolSize--];
      Gift storage endOfPoolGift = _gift[endOfPoolGiftId];
      endOfPoolGift.poolIndex = withdrawnGiftPoolIndex;

      /// @dev swaps the withdrawn gift with the last valid gift in the pool then shrinks the pool size
      /// @dev no need to delete the gift outside of the poolSize after the decrement since it'll be ignored or replaced during next gift submit
      _giftPool[withdrawnGiftPoolIndex] = endOfPoolGiftId;
    } else {
      /// @dev should never be able to underflow since more gifts can't be withdrawn than submitted
      unchecked {
        poolSize--;
      }
    }

    delete _giftGiver[msg.sender];
    delete _gift[id];

    address withdrawnGiftContract = withdrawnGift.tokenContract;
    uint256 withdrawnGiftTokenId = withdrawnGift.tokenId;
    giftTransfer(withdrawnGiftContract, withdrawnGiftTokenId);

    emit Withdraw(msg.sender, id);
  }

  /*//////////////////////////////////////////////
                    OWNER LOGIC
  //////////////////////////////////////////////*/

  function changeGameState(uint8 _state) public onlyOwner {
    state = State(_state);

    emit StateChange(state);
  }

  function updateUserMerkleRoot(bytes32 _userMerkleRoot) public onlyOwner {
    userMerkleRoot = _userMerkleRoot;
  }

  function updateGiftMerkleRoot(bytes32 _giftMerkleRoot) public onlyOwner {
    giftMerkleRoot = _giftMerkleRoot;
  }

  /// @notice owner can withdraw gifts after withdraw lockout period (2 weeks) to raffle off
  function withdrawGift(uint256 _giftId) public onlyOwner {
    if (block.timestamp < withdrawReleaseDate) revert OwnerWithdrawLocked();

    Gift memory withdrawnGift = _gift[_giftId];
    if (withdrawnGift.tokenContract == address(0)) revert GiftDoesNotExist();

    address withdrawnGiftContract = withdrawnGift.tokenContract;
    uint256 withdrawnGiftTokenId = withdrawnGift.tokenId;
    giftTransfer(withdrawnGiftContract, withdrawnGiftTokenId);

    emit Withdraw(msg.sender, _giftId);
  }

  /*//////////////////////////////////////////////
            PRIVATE/INTERNAL JINGLE LOGIC
  //////////////////////////////////////////////*/

  function giftTransfer(address withdrawnGiftContract, uint256 withdrawnGiftTokenId) private {
    if (isERC721(withdrawnGiftContract)) {
      IERC721(withdrawnGiftContract).safeTransferFrom(address(this), msg.sender, withdrawnGiftTokenId);
    } else {
      IERC1155(withdrawnGiftContract).safeTransferFrom(address(this), msg.sender, withdrawnGiftTokenId, 1, "");
    }
  }

  /// @notice check if the given user is whitelisted to join the game
  function isUserWhiteListed(
    address _user,
    bytes32[] calldata _merkleProof
  ) internal view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(_user));
    return MerkleProof.verify(_merkleProof, userMerkleRoot, leaf);
  }

  /// @notice checks if the given token contract address exists in the merkle tree
  function isTokenApproved(
    address _tokenAddress,
    bytes32[] calldata _merkleProof
  ) internal view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(_tokenAddress));
    return MerkleProof.verify(_merkleProof, giftMerkleRoot, leaf);
  }

  /// @notice a psuedo random function to pick a gift randomly from the pool (Thanks Valhalla for the seed idea)
  function getRandomPoolIndex() internal returns (uint256) {
    return (uint256(keccak256(
      abi.encodePacked(
        block.timestamp,
        block.difficulty,
        ++seed
      )
    )) % poolSize) + 1;
  }

  /// @notice used to determine if the given contract is ERC-721
  function isERC721(address _contract) internal view returns (bool) {
    // Check if the contract implements the ERC721 interface
    return IERC721(_contract).supportsInterface(type(IERC721).interfaceId);
  }

  /*//////////////////////////////////////////////
                ON RECIEVE LOGIC
  //////////////////////////////////////////////*/

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) public pure returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
  }

  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes calldata
  ) public pure returns(bytes4) {
    return IERC1155Receiver.onERC1155Received.selector;
  }
}