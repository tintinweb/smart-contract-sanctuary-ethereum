// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
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
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";

contract PhysicalRedeemable is Ownable {
    // External addresses
    IERC1155 public parallelAuxiliaryItem =
        IERC1155(0x38398a2d7A4278b8d83967E0D235164335A0394A);
    address public routerContractAddress =
        0x38398a2d7A4278b8d83967E0D235164335A0394A;

    address public pullParallelAuxiliaryItemFromAddress = address(0);
    uint256[] public physicalItemTokenIds = [4, 5, 6, 7, 8]; // hoodie sizes

    mapping(address => mapping(uint256 => uint256)) public physicalItemsClaimed;

    bool public disabled;

    event Redeemed(
        address account,
        uint256[] physicalItemTokenIds,
        uint256[] physicalItemsToRedeems,
        uint256 parallelTransactionId
    );
    event Collected(
        address owner,
        uint256[] PhysicalItemTokenId,
        uint256[] requestedPhysicalItemsCount,
        uint256 parallelTransactionId
    );

    bytes32 public merkleRoot;

    constructor() {}

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPullParallelAuxiliaryItemFromAddress(address _address)
        public
        onlyOwner
    {
        pullParallelAuxiliaryItemFromAddress = _address;
    }

    function setParallelAuxiliaryItem(IERC1155 _address) public onlyOwner {
        parallelAuxiliaryItem = _address;
    }

    function setRouterContractAddress(address _newAddr) public onlyOwner {
        routerContractAddress = _newAddr;
    }

    function collect(
        address account,
        uint256 maxAccountAmount,
        bytes32[] calldata merkleProof,
        uint256[] calldata requestedTokenIndexes,
        uint256[] calldata requestedTokenAmounts,
        uint256 parallelTransactionId
    ) external {
        require(disabled == false, "disabled");

        // Verify the merkle proof.
        bytes32 leaf = keccak256(
            abi.encodePacked(account, physicalItemTokenIds, maxAccountAmount)
        );

        require(
            MerkleProof.verify(merkleProof, merkleRoot, leaf),
            "invalid proof"
        );

        // Make sure the request is legitimate
        uint256[] memory tokenIdsToTransfer = verifyClaimRequest(
            account,
            maxAccountAmount,
            requestedTokenIndexes,
            requestedTokenAmounts
        );

        // send nft
        parallelAuxiliaryItem.safeBatchTransferFrom(
            pullParallelAuxiliaryItemFromAddress,
            account,
            tokenIdsToTransfer,
            requestedTokenAmounts,
            bytes("")
        );
        // emit collected event
        emit Collected(
            account,
            tokenIdsToTransfer,
            requestedTokenAmounts,
            parallelTransactionId
        );
    }

    /**
     * @dev using token indexes as input ensures requestedTokenIds is a subset of physicalItemTokenIds (IndexOutOfBounds).
     * @param requestedTokenIndexes - the requested token indexes (of tokens within physicalItemTokenIds&)
     * @return batchTokenIds - the array of tokenIds to be transferred to the claiming user
     */
    function verifyClaimRequest(
        address account,
        uint256 maxAccountAmount,
        uint256[] calldata requestedTokenIndexes,
        uint256[] calldata requestedAmounts
    ) internal returns (uint256[] memory) {
        uint256[] memory tokenIdsToTransfer = new uint256[](
            requestedTokenIndexes.length
        );
        uint256 i;
        uint256 requestedTokenIndex;
        for (i = 0; i < requestedTokenIndexes.length; i++) {
            requestedTokenIndex = requestedTokenIndexes[i];

            // [requested + claimedToDate] MUST BE <= [totalMerkleTreeAmount] for each of the tokens requested in the claim
            require(
                requestedAmounts[i] +
                    physicalItemsClaimed[account][requestedTokenIndex] <=
                    maxAccountAmount,
                "cannot claim more than account total"
            );

            // update the global mapping of all completed claims
            physicalItemsClaimed[account][
                requestedTokenIndex
            ] += requestedAmounts[i];

            tokenIdsToTransfer[i] = physicalItemTokenIds[requestedTokenIndex];
        }
        return tokenIdsToTransfer;
    }

    function getAccountClaims(
        address account,
        uint256[] calldata requestedTokenIndexes
    ) external view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](requestedTokenIndexes.length);
        uint256 i;
        for (i = 0; i < requestedTokenIndexes.length; i++) {
            amounts[i] = physicalItemsClaimed[account][
                requestedTokenIndexes[i]
            ];
        }
        return amounts;
    }

    function handleReceive(
        address _userAddress,
        address, /*_receiverAddress*/
        uint256, /*_type*/
        uint256, /*_id*/
        uint256, /*_ethValue*/
        uint256, /*_primeValue*/
        uint256[] memory _physicalIds,
        uint256[] memory _physicalQuantities,
        bytes memory _data
    ) external onlyParallelAuxiliaryItemsRouter {
        // emit redeemed event
        emit Redeemed(
            _userAddress,
            _physicalIds,
            _physicalQuantities,
            abi.decode(_data, (uint256))
        );
    }

    modifier onlyParallelAuxiliaryItemsRouter() {
        require(
            msg.sender == routerContractAddress,
            "only callable by PAI router"
        );
        _;
    }
}