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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

interface IRaffleChef {
    event RaffleCreated(uint256 indexed raffleId);
    event RaffleCommitted(uint256 indexed raffleId);

    error RaffleNotRolled(uint256 raffleId);
    error InvalidCommitment(
        uint256 raffleId,
        bytes32 merkleRoot,
        uint256 nParticipants,
        uint256 nWinners,
        uint256 randomness,
        string provenance
    );
    error Unauthorised(address unauthorisedUser);
    error StartingRaffleIdTooLow(uint256 raffleId);
    error InvalidProof(bytes32 leaf, bytes32[] proof);

    /// @dev Descriptive state of a raffle based on its variables that are set/unset
    enum RaffleState {
        /// @dev Default state
        Unknown,
        /// @dev Done
        Committed
    }

    /// @notice Structure of every raffle; presence of certain elements indicate the raffle state
    struct Raffle {
        bytes32 participantsMerkleRoot;
        uint256 nParticipants;
        uint256 nWinners;
        uint256 randomSeed;
        address owner;
        string provenance;
    }

    /// @notice Publish a commitment (the merkle root of the finalised participants list, and
    ///     the number of winners to draw, and the random seed). Only call this function once
    ///     the random seed and list of raffle participants has finished being collected.
    /// @param participantsMerkleRoot Merkle root constructed from finalised participants list
    /// @param nWinners Number of winners to draw
    /// @param provenance IPFS CID of this raffle's provenance including full participants list
    /// @param randomness Random seed for the raffle
    /// @return Raffle ID that can be used to lookup the raffle results, when
    ///     the raffle is finalised.
    function commit(
        bytes32 participantsMerkleRoot,
        uint256 nParticipants,
        uint256 nWinners,
        string calldata provenance,
        uint256 randomness
    ) external returns (uint256);

    /// @notice Verify that an account is in the winners list for a specific raffle
    ///     using a merkle proof and the raffle's previous public commitments. This is
    ///     a view-only function that does not record if a winner has already claimed
    ///     their win; that is left up to the caller to handle.
    /// @param raffleId ID of the raffle to check against
    /// @param leafHash Hash of the leaf value that represents the participant
    /// @param proof Merkle subproof (hashes)
    /// @param originalIndex Original leaf index in merkle tree, part of merkle proof
    /// @return isWinner true if claiming account is indeed a winner
    /// @return permutedIndex winning (shuffled) index
    function verifyRaffleWinner(
        uint256 raffleId,
        bytes32 leafHash,
        bytes32[] calldata proof,
        uint256 originalIndex
    ) external view returns (bool isWinner, uint256 permutedIndex);

    /// @notice Get an existing raffle
    /// @param raffleId ID of raffle to get
    /// @return raffle data, if it exists
    function getRaffle(uint256 raffleId) external view returns (Raffle memory);

    /// @notice Get the current state of raffle, given a `raffleId`
    /// @param raffleId ID of raffle to get
    /// @return See {RaffleState} enum
    function getRaffleState(
        uint256 raffleId
    ) external view returns (RaffleState);
}

// SPDX-License-Identifier: MIT
/**
    The MIT License (MIT)

    Copyright (c) 2018 SmartContract ChainLink, Ltd.

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
*/

pragma solidity ^0.8;

abstract contract TypeAndVersion {
    function typeAndVersion() external pure virtual returns (string memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {TypeAndVersion} from "./interfaces/TypeAndVersion.sol";
import {IRaffleChef} from "./interfaces/IRaffleChef.sol";
import {FeistelShuffle} from "./vendor/FeistelShuffle.sol";
import {Withdrawable} from "./vendor/Withdrawable.sol";

/// @title RaffleChef
/// @author kevincharm
/// @notice RaffleChef is the master of raffles. He can make raffles and he is a fair guy.
///     RaffleChef does NOT record whether a winner has claimed their win; this is upto an
///     external raffle consumer to handle. Take care not to double-spend a raffle, unless
///     that is your intent.
contract RaffleChef is IRaffleChef, TypeAndVersion, Ownable, Withdrawable {
    /// @notice ID of next created raffle
    uint256 public nextRaffleId;

    /// @dev Mapping of raffleId => Raffle data
    mapping(uint256 => Raffle) private raffles;

    /// @dev RESERVED
    uint256[48] private __RaffleChef_gap;

    constructor(uint256 startingRaffleId) Ownable() {
        if (startingRaffleId == 0) {
            revert StartingRaffleIdTooLow(startingRaffleId);
        }
        nextRaffleId = startingRaffleId;
    }

    /// @notice See {TypeAndVersion-typeAndVersion}
    function typeAndVersion() external pure override returns (string memory) {
        return "RaffleChef 1.0.0";
    }

    function _authoriseWithdrawal() internal virtual override onlyOwner {}

    /// @notice Get an existing raffle
    /// @param raffleId ID of raffle to get
    /// @return raffle data, if it exists
    function getRaffle(uint256 raffleId) public view returns (Raffle memory) {
        return raffles[raffleId];
    }

    /// @notice Get the current state of raffle, given a `raffleId`
    /// @param raffleId ID of raffle to get
    /// @return See {IRaffleChef-RaffleState} enum
    function getRaffleState(
        uint256 raffleId
    ) public view returns (RaffleState) {
        Raffle memory raffle = getRaffle(raffleId);
        if (
            raffle.participantsMerkleRoot != bytes32(0) &&
            raffle.nWinners > 0 &&
            raffle.randomSeed != 0 &&
            bytes(raffle.provenance).length > 0
        ) {
            return RaffleState.Committed;
        } else {
            return RaffleState.Unknown;
        }
    }

    /// @notice See {IRaffleChef-commit}
    function commit(
        bytes32 participantsMerkleRoot,
        uint256 nParticipants,
        uint256 nWinners,
        string calldata provenance,
        uint256 randomness
    ) external returns (uint256) {
        uint256 raffleId = nextRaffleId;
        nextRaffleId += 1;

        // NB: Validity of provenance is not actually checked
        if (
            participantsMerkleRoot == 0 ||
            nParticipants == 0 ||
            nWinners > nParticipants ||
            randomness == 0 ||
            bytes(provenance).length == 0
        ) {
            revert InvalidCommitment(
                raffleId,
                participantsMerkleRoot,
                nParticipants,
                nWinners,
                randomness,
                provenance
            );
        }

        Raffle memory raffle = Raffle({
            participantsMerkleRoot: participantsMerkleRoot,
            nParticipants: nParticipants,
            nWinners: nWinners,
            randomSeed: randomness,
            owner: msg.sender,
            provenance: provenance
        });
        raffles[raffleId] = raffle;

        emit RaffleCommitted(raffleId);

        return raffleId;
    }

    /// @notice See {IRaffleChef-verifyRaffleWinner}
    function verifyRaffleWinner(
        uint256 raffleId,
        bytes32 leafHash,
        bytes32[] calldata proof,
        uint256 merkleIndex
    ) external view returns (bool isWinner, uint256 permutedIndex) {
        Raffle memory raffle = raffles[raffleId];
        if (raffle.randomSeed == 0) {
            revert RaffleNotRolled(raffleId);
        }

        // Verify that the merkle proof is correct.
        // This proves that `account` is a member of the participants list,
        // at the given `index` (as derived from the merkle proof's path indices).
        bool isValidProof = verifyMerkleProof(
            raffle.participantsMerkleRoot,
            leafHash,
            proof,
            merkleIndex
        );
        if (!isValidProof) {
            revert InvalidProof(leafHash, proof);
        }

        // Compute the shuffled index using the random seed using a stateless shuffle
        // that bijectively maps P -> P' where P is the participants list, and P' is
        // a permutation of P.
        permutedIndex = FeistelShuffle.getPermutedIndex(
            merkleIndex,
            raffle.nParticipants,
            raffle.randomSeed,
            4
        );

        // A winner is defined as any account having an original index that maps to a
        // shuffled index that is less than the total number of winners.
        isWinner = permutedIndex < raffle.nWinners;

        return (isWinner, permutedIndex);
    }

    /// @notice Verify a merkle proof given a merkle root.
    /// @param merkleRoot Root of the merkle tree to verify against
    /// @param leafHash Hash of leaf element
    /// @param proof Hashes of leaf siblings required to construct the root
    /// @param index leaf index in merkle tree
    /// @return isValid true if proof is valid for supplied leaf
    function verifyMerkleProof(
        bytes32 merkleRoot,
        bytes32 leafHash,
        bytes32[] calldata proof,
        uint256 index
    ) internal pure returns (bool isValid) {
        bytes32 computedHash = leafHash;
        for (uint256 i = 0; i < proof.length; ++i) {
            computedHash = hashMerklePair(
                computedHash,
                proof[i],
                (index >> i) & 1 == 1
            );
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == merkleRoot;
    }

    /// @notice Hash a merkle pair -> keccak256(left,right)
    /// @param a left value
    /// @param b right value
    /// @param reverse if true, reverses the order of left and right
    /// @return h Hash of merkle pair, constructing a parent node
    function hashMerklePair(
        bytes32 a,
        bytes32 b,
        bool reverse
    ) internal pure returns (bytes32 h) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Use scratch space [0, 0x40)
            // h <- keccak256(reverse ? b : a, reverse ? a : b)
            let rev := and(reverse, 0x1)
            mstore(mul(rev, 0x20), a)
            mstore(mul(iszero(rev), 0x20), b)
            h := keccak256(0, 0x40)
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8;

// solhint-disable no-inline-assembly, no-empty-blocks

/// @title FeistelShuffle
/// @author kevincharm
/// @notice Implementation of a Feistel shuffle, adapted from vbuterin's python implementation [1].
///     [1]: https://github.com/ethereum/research/blob/master/shuffling/feistel_shuffle.py
library FeistelShuffle {
    /// @notice Compute the bijective mapping of `x` using a Feistel shuffle
    /// @param x index of element in the list
    /// @param modulus cardinality of list
    /// @param seed random seed to (re-)produce the mapping
    /// @param rounds number of Feistel rounds
    /// @return resulting shuffled/permuted index
    function getPermutedIndex(
        uint256 x,
        uint256 modulus,
        uint256 seed,
        uint256 rounds
    ) internal pure returns (uint256) {
        modulus ** (rounds - 1); // lazy checked exponentiation
        assembly {
            // Assert some preconditions
            // (x < modulus): index to be permuted must lie within the domain of [0, modulus)
            let xGteModulus := gt(x, sub(modulus, 1))
            // (modulus != 0): domain must be non-zero (value of 1 also doesn't really make sense)
            let modulusZero := iszero(modulus)
            if or(xGteModulus, modulusZero) {
                revert(0, 0)
            }

            // Calculate sqrt(s) using Babylonian method
            function sqrt(s) -> z {
                switch gt(s, 3)
                // if (s > 3)
                case 1 {
                    z := s
                    let r := add(div(s, 2), 1)

                    for {

                    } lt(r, z) {

                    } {
                        z := r
                        r := div(add(div(s, r), r), 2)
                    }
                }
                default {
                    if iszero(iszero(s)) {
                        // else if (s != 0)
                        z := 1
                    }
                }
            }

            // nps <- nextPerfectSquare(modulus)
            let sqrtN := sqrt(modulus)
            let nps
            switch eq(exp(sqrtN, 2), modulus)
            case 1 {
                nps := modulus
            }
            default {
                let sqrtN1 := add(sqrtN, 1)
                // pre-check for square overflow
                if gt(sqrtN1, sub(exp(2, 128), 1)) {
                    // overflow
                    revert(0, 0)
                }
                nps := exp(sqrtN1, 2)
            }
            // h <- sqrt(nps)
            let h := sqrt(nps)
            // Perform Feistel rounds until result is in the correct domain
            // i.e. Loop until x < modulus
            for {

            } 1 {

            } {
                let L := div(x, h)
                let R := mod(x, h)
                // Loop for desired number of rounds
                for {
                    let r := 0
                } lt(r, rounds) {
                    r := add(r, 1)
                } {
                    // Load R and seed for next keccak256 round into scratch space
                    mstore(0, R)
                    mstore(0x20, seed)
                    // roundHash <- (keccak256(R,seed) / (modulus**r)) % modulus
                    let roundHash := mod(
                        div(keccak256(0, 0x40), exp(modulus, r)),
                        modulus
                    )
                    let newR := mod(add(L, roundHash), h)
                    L := R
                    R := newR
                }
                x := add(mul(L, h), R)
                if lt(x, modulus) {
                    break
                }
            }
        }
        return x;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/// @title Withdrawable
/// @author kevincharm
abstract contract Withdrawable {
    function _authoriseWithdrawal() internal virtual;

    function withdrawETH(uint256 amount) external {
        _authoriseWithdrawal();
        payable(msg.sender).transfer(amount);
    }

    function withdrawERC20(address token, address to, uint256 amount) external {
        _authoriseWithdrawal();
        IERC20(token).transfer(to, amount);
    }

    function withdrawERC721(
        address token,
        address to,
        uint256 tokenId
    ) external {
        _authoriseWithdrawal();
        IERC721(token).safeTransferFrom(address(this), to, tokenId);
    }

    function withdrawERC1155(
        address token,
        address to,
        uint256 tokenId,
        uint256 amount
    ) external {
        _authoriseWithdrawal();
        IERC1155(token).safeTransferFrom(
            address(this),
            to,
            tokenId,
            amount,
            bytes("")
        );
    }
}