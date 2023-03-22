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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./IGnGOffering.sol";

contract GnGOffering is IGnGOffering, Ownable, Pausable {
    mapping(address => bool) public supportedERC721Collections;
    mapping(address => bool) public supportedERC1155Collections;

    uint256 public maxAmountPerTx = 15;
    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD;

    constructor(address[] memory _supportedERC721Collections, address[] memory _supportedERC1155Collections) {
        _addERC721Collections(_supportedERC721Collections);
        _addERC1155Collections(_supportedERC1155Collections);
    }

    /**
     * @dev Offer the NFTs in supported ERC721 & ERC1155 collections to burn.
     * @dev The collections need to be approved by the owner first.
     * @dev `collections`, `tokenIds` and `amounts` should be in same length.
     * @param collections The list of contract addresses to offer
     * @param tokenIds The list of tokenIds for each collections to offer
     * @param amounts The list of amounts for each token to offer
     */
    function offer(
        address[] calldata collections,
        uint256[][] calldata tokenIds,
        uint256[][] calldata amounts
    ) external whenNotPaused {
        if (collections.length != tokenIds.length) revert InvalidInput("Invalid tokenIds length.");
        if (collections.length != amounts.length) revert InvalidInput("Invalid amounts length.");

        uint256 totalAmount = 0;
        uint256 maxAmount = maxAmountPerTx;

        for (uint256 i = 0; i < collections.length; ) {
            address collection = collections[i];
            uint256[] memory tokenIdList = tokenIds[i];
            uint256[] memory amountList = amounts[i];

            if (supportedERC721Collections[collection]) {
                totalAmount += tokenIdList.length;
                if (totalAmount > maxAmount) revert InvalidInput("Invalid amounts total.");

                _burnERC721(msg.sender, collection, tokenIdList);
            } else if (supportedERC1155Collections[collection]) {
                for (uint256 j = 0; j < amountList.length; ) {
                    totalAmount += amountList[j];
                    if (totalAmount > maxAmount) revert InvalidInput("Invalid amounts total.");

                    unchecked {
                        j++;
                    }
                }
                _burnERC1155(msg.sender, collection, tokenIdList, amountList);
            } else {
                revert InvalidInput("Unsupported collection.");
            }

            unchecked {
                i++;
            }
        }

        if (totalAmount == 0) revert InvalidInput("Total amount cannot be zero.");

        emit AmountOffered(msg.sender, totalAmount);
    }

    /**
     * @dev Transfer user's ERC721 tokens from `from` to burn address
     * @dev This is an internal function can only be called from this contract
     * @param from address representing the owner of the given NFTs
     * @param collection address representing the contract of the given NFTs
     * @param tokenIds The list of ids of the token to be transferred
     */
    function _burnERC721(
        address from,
        address collection,
        uint256[] memory tokenIds
    ) internal {
        for (uint256 i = 0; i < tokenIds.length; ) {
            IERC721(collection).safeTransferFrom(from, burnAddress, tokenIds[i]);
            unchecked {
                i++;
            }
        }
        emit ERC721Offered(from, collection, tokenIds);
    }

    /**
     * @dev Transfer user's ERC1155 tokens from `from` to burn address
     * @dev This is an internal function can only be called from this contract
     * @param from address representing the owner of the given NFTs
     * @param collection address representing the contract of the given NFTs
     * @param tokenIds The list of ids of the token to be transferred
     * @param amounts The list of amounts of the token to be transferred
     */
    function _burnERC1155(
        address from,
        address collection,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) internal {
        IERC1155(collection).safeBatchTransferFrom(from, burnAddress, tokenIds, amounts, "");
        emit ERC1155Offered(from, collection, tokenIds, amounts);
    }

    /**
     * @dev Add `collections` to supported ERC721 whitelist
     * @dev This is an internal function can only be called from this contract
     * @param collections The list of addresses representing NFT collections to add
     */
    function _addERC721Collections(address[] memory collections) internal {
        for (uint256 i = 0; i < collections.length; ) {
            supportedERC721Collections[collections[i]] = true;
            unchecked {
                i++;
            }
        }
        emit CollectionsAdded(msg.sender, TokenType.ERC721, collections);
    }

    /**
     * @dev Add `collections` to supported ERC1155 whitelist
     * @dev This is an internal function can only be called from this contract
     * @param collections The list of addresses representing NFT collections to add
     */
    function _addERC1155Collections(address[] memory collections) internal {
        for (uint256 i = 0; i < collections.length; ) {
            supportedERC1155Collections[collections[i]] = true;
            unchecked {
                i++;
            }
        }
        emit CollectionsAdded(msg.sender, TokenType.ERC1155, collections);
    }

    /**
     * @dev Add `collections` to supported ERC721 whitelist
     * @dev This function can only be called from contract owner
     * @param collections The list of addresses representing NFT collections to add
     */
    function addERC721Collections(address[] memory collections) external onlyOwner {
        _addERC721Collections(collections);
    }

    /**
     * @dev Add `collections` to supported ERC1155 whitelist
     * @dev This function can only be called from contract owner
     * @param collections The list of addresses representing NFT collections to add
     */
    function addERC1155Collections(address[] memory collections) external onlyOwner {
        _addERC1155Collections(collections);
    }

    /**
     * @dev Remove `collections` from supported ERC721 whitelist
     * @dev This function can only be called from contract owner
     * @param collections The list of addresses representing NFT collections to remove
     */
    function removeERC721Collections(address[] memory collections) external onlyOwner {
        for (uint256 i = 0; i < collections.length; ) {
            delete supportedERC721Collections[collections[i]];
            unchecked {
                i++;
            }
        }
        emit CollectionsRemoved(msg.sender, TokenType.ERC721, collections);
    }

    /**
     * @dev Remove `collections` from supported ERC1155 whitelist
     * @dev This function can only be called from contract owner
     * @param collections The list of addresses representing NFT collections to remove
     */
    function removeERC1155Collections(address[] memory collections) external onlyOwner {
        for (uint256 i = 0; i < collections.length; ) {
            delete supportedERC1155Collections[collections[i]];
            unchecked {
                i++;
            }
        }
        emit CollectionsRemoved(msg.sender, TokenType.ERC1155, collections);
    }

    /**
     * @dev Update maximum amount per transaction
     * @dev This function can only be called from contract owner
     * @param amount The amount to be updated
     */
    function setMaxAmountPerTx(uint256 amount) external onlyOwner {
        maxAmountPerTx = amount;
        emit MaxAmountUpdated(msg.sender, amount);
    }

    /**
     * @dev Pause the contract
     * @dev This function can only be called from contract owner
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the contract
     * @dev This function can only be called from contract owner
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IGnGOffering {
    /**
     * @dev Supported token types that can be offered.
     */
    enum TokenType {
        ERC721,
        ERC1155
    }

    /**
     * @dev Error with `errMsg` message for input validation.
     */
    error InvalidInput(string errMsg);

    /**
     * @dev Emitted when supported ERC721 tokens transferred from `sender` to burn address.
     */
    event ERC721Offered(address indexed sender, address indexed collection, uint256[] tokenIds);

    /**
     * @dev Emitted when supported ERC1155 tokens transferred from `sender` to burn address.
     */
    event ERC1155Offered(address indexed sender, address indexed collection, uint256[] tokenIds, uint256[] amounts);

    /**
     * @dev Emitted when supported tokens transferred from `sender` to burn address.
     */
    event AmountOffered(address indexed sender, uint256 totalAmount);

    /**
     * @dev Emitted when supported collections added by `operator`
     */
    event CollectionsAdded(address indexed operator, TokenType tokenType, address[] collections);

    /**
     * @dev Emitted when supported collections removed by `operator`
     */
    event CollectionsRemoved(address indexed operator, TokenType tokenType, address[] collections);

    /**
     * @dev Emitted when max amount per transaction updated by `operator`
     */
    event MaxAmountUpdated(address indexed operator, uint256 amount);

    /**
     * @dev Check if `collection` is a supported ERC721 collection.
     * @return Boolean result.
     */
    function supportedERC721Collections(address collection) external returns (bool);

    /**
     * @dev Check if `collection` is a supported ERC1155 collection.
     * @return Boolean result.
     */
    function supportedERC1155Collections(address collection) external returns (bool);

    /**
     * @dev Offer the NFTs in supported ERC721 & ERC1155 collections to burn.
     * @dev The collections need to be approved by the owner first.
     * @dev `collections`, `tokenIds` and `amounts` should be in same length.
     * @param collections The list of contract addresses to offer
     * @param tokenIds The list of tokenIds for each collections to offer
     * @param amounts The list of amounts for each token to offer
     */
    function offer(
        address[] calldata collections,
        uint256[][] calldata tokenIds,
        uint256[][] calldata amounts
    ) external;
}