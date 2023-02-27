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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
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

// SPDX-License-Identifier: None
pragma solidity 0.8.17;

interface IMarketplaceNonCustodial {
    enum NFTStandard {
        E721,
        E1155
    }

    struct Order {
        uint256 orderId;
        address nftAddress;
        NFTStandard standard;
        uint256 tokenId;
        uint256 quantity;
        uint256 pricePerItem;
        address payable seller;
    }

    struct Buyer {
        address buyer;
        uint256 quantityBought;
        uint256 buyPricePerItem;
    }

    // Errors
    error InvalidNFTStandard(address nftAddress);
    error ItemsNotApprovedForListing();
    error InvalidOrderIdInput(uint256 orderId);
    error OrderClosed(uint256 orderId);
    error InvalidCaller(address expected, address caller);
    error InactiveOrder(uint256 orderId);
    error NotEnoughItemsOwnedByCaller(address nftAddress, uint256 tokenId);
    error ZeroPricePerItemInput(uint256 input);
    error InvalidQuantityInput(uint256 input);
    error ItemAlreadyOwned(address nftAddress, uint256 tokenId);
    error ModifyListingFailed(uint256 newPriceInput, uint256 qtyToAdd);

    // Events
    event ItemsListed(
        uint256 indexed orderIdAssigned,
        address indexed nftAddress,
        NFTStandard standard,
        uint256 indexed tokenId,
        uint256 quantity,
        uint256 pricePerItem,
        address seller
    );

    event ItemsBought(
        uint256 indexed orderId,
        address indexed nftAddress,
        NFTStandard standard,
        uint256 indexed tokenId,
        uint256 buyQty,
        uint256 soldFor,
        address buyer
    );

    event ItemsModified(
        uint256 indexed orderId,
        address indexed nftAddress,
        NFTStandard standard,
        uint256 indexed tokenId,
        uint256 newPricePerItem,
        uint256 qtyToAdd
    );

    event ItemsCancel(
        uint256 indexed orderId,
        address indexed nftAddress,
        NFTStandard standard,
        uint256 indexed tokenId,
        address unlistedBy
    );

    // Functions
    function withdrawFunds() external;

    function listItem(
        address _nftAddress,
        NFTStandard _standard,
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _pricePerItem
    ) external;

    function modifyListing(
        uint256 _orderId,
        uint256 _newPricePerItem,
        uint256 _qtyToAdd
    ) external;

    function cancelListing(uint256 _orderId) external;

    function buyItem(uint256 _orderId, uint256 _qtyToBuy) external payable;

    function isOrderActive(uint256 _orderId) external view returns (bool);

    function isERC721(address nftAddress) external view returns (bool output);

    function isERC1155(address nftAddress) external view returns (bool output);

    function isOrderClosed(uint256 _orderId) external view returns (bool sold);
}

// SPDX-License-Identifier: None
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "./IMarketplaceNonCustodial.sol";

contract MarketplaceNonCustodial is
    Ownable,
    ReentrancyGuard,
    IMarketplaceNonCustodial
{
    using ERC165Checker for address;
    bytes4 public constant IID_IERC721 = type(IERC721).interfaceId;
    bytes4 public constant IID_IERC1155 = type(IERC1155).interfaceId;
    address payable public adminAddress;
    uint256 public percentFeesAdmin = 4; //4%
    uint256 public orderCtr;

    // listings orderId => Order
    mapping(uint256 => Order) public listings;

    // OrderId => Buyer[]
    mapping(uint256 => Buyer[]) public listingBuyers;

    // keeps a check whether user has listed a particular NFT previously or not
    // user addr => nft addr => token id => bool
    mapping(address => mapping(address => mapping(uint256 => bool)))
        public userListedNFTBefore;

    modifier onlyAdmin() {
        if (msg.sender != adminAddress) {
            revert InvalidCaller(adminAddress, msg.sender);
        }
        _;
    }

    constructor() {
        orderCtr = 0;
        adminAddress = payable(msg.sender);
    }

    // admin only functions
    function withdrawFunds() external override onlyAdmin {
        payable(msg.sender).transfer(address(this).balance);
    }

    function listItem(
        address _nftAddress,
        NFTStandard _standard,
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _pricePerItem
    ) external override {
        // token quantity token owner owns
        uint256 ownerHas = 1; //1 for 721
        if (_standard == NFTStandard.E721) {
            if (!isERC721(_nftAddress)) {
                revert InvalidNFTStandard(_nftAddress);
            }
            if (_quantity != 1) {
                revert InvalidQuantityInput(_quantity);
            }
            IERC721 _nft = IERC721(_nftAddress);
            // ownership check
            if (_nft.ownerOf(_tokenId) != msg.sender) {
                revert NotEnoughItemsOwnedByCaller(_nftAddress, _tokenId);
            }
            // approval check
            if (_nft.getApproved(_tokenId) != address(this)) {
                revert ItemsNotApprovedForListing();
            }
        } else {
            if (!isERC1155(_nftAddress)) {
                revert InvalidNFTStandard(_nftAddress);
            }
            IERC1155 _nft = IERC1155(_nftAddress);
            ownerHas = _nft.balanceOf(msg.sender, _tokenId);
            // ownership check
            if (ownerHas < _quantity) {
                revert NotEnoughItemsOwnedByCaller(_nftAddress, _tokenId);
            }
            // approval check
            if (!_nft.isApprovedForAll(msg.sender, address(this))) {
                revert ItemsNotApprovedForListing();
            }
        }

        if (_pricePerItem == 0) {
            revert ZeroPricePerItemInput(_pricePerItem);
        }
        // condition to prevent double listing
        require(
            userListedNFTBefore[msg.sender][_nftAddress][_tokenId] == false,
            "MarketplaceNonCustodial: This NFT already listed by you. Modify the old listing!"
        );
        _createNewOrder(
            _nftAddress,
            _standard,
            _tokenId,
            _quantity,
            _pricePerItem,
            payable(msg.sender)
        );
    }

    function modifyListing(
        uint256 _orderId,
        uint256 _newPricePerItem, // 0, if you don't want to change current lising price per token
        uint256 _qtyToAdd // 0 if you don't want to add any more tokens to the listing
    ) external override {
        if (_orderId > orderCtr) {
            revert InvalidOrderIdInput(_orderId);
        }
        if (isOrderClosed(_orderId)) {
            revert OrderClosed(_orderId);
        }
        Order memory _order = listings[_orderId];
        if (_order.seller != msg.sender) {
            revert InvalidCaller(_order.seller, msg.sender);
        }
        if (!isOrderActive(_orderId)) {
            revert InactiveOrder(_orderId);
        }
        uint256 ownerHas = 1; // for 721
        if (_order.standard == NFTStandard.E1155) {
            IERC1155 _nft = IERC1155(_order.nftAddress);
            ownerHas = _nft.balanceOf(msg.sender, _order.tokenId);
        }
        // the transaction should change at least one thing - either increae the qty listed or change the price per token
        if (_newPricePerItem == 0) {
            if (_qtyToAdd != 0) {
                // condition to prevent double listing
                require(
                    _order.quantity + _qtyToAdd <= ownerHas,
                    "MarketplaceNonCustodial: Can't increase token quantity any more!"
                );
                listings[_orderId].quantity += _qtyToAdd;
            } else {
                revert ModifyListingFailed(_newPricePerItem, _qtyToAdd);
            }
        } else {
            if (_qtyToAdd != 0) {
                // condition to prevent double listing
                require(
                    _order.quantity + _qtyToAdd <= ownerHas,
                    "MarketplaceNonCustodial: Can't increase token quantity any more!"
                );
                listings[_orderId].quantity += _qtyToAdd;
            }
            // price will be changed in both cases
            _updateOrderPrice(_orderId, _newPricePerItem);
        }
        emit ItemsModified(
            _orderId,
            _order.nftAddress,
            _order.standard,
            _order.tokenId,
            _newPricePerItem,
            _qtyToAdd
        );
    }

    // cancel listing would mean cancelling all the listed items
    function cancelListing(uint256 _orderId) external override {
        if (_orderId > orderCtr) {
            revert InvalidOrderIdInput(_orderId);
        }
        if (isOrderClosed(_orderId)) {
            revert OrderClosed(_orderId);
        }
        Order memory _order = listings[_orderId];
        if (_order.seller != msg.sender) {
            revert InvalidCaller(_order.seller, msg.sender);
        }
        userListedNFTBefore[msg.sender][_order.nftAddress][
            _order.tokenId
        ] = false;
        listings[_orderId].quantity = 0;
        emit ItemsCancel(
            _orderId,
            _order.nftAddress,
            _order.standard,
            _order.tokenId,
            msg.sender
        );
    }

    function buyItem(uint256 _orderId, uint256 _qtyToBuy)
        external
        payable
        override
        nonReentrant
    {
        if (_orderId > orderCtr) {
            revert InvalidOrderIdInput(_orderId);
        }
        if (isOrderClosed(_orderId)) {
            revert OrderClosed(_orderId);
        }
        if (!isOrderActive(_orderId)) {
            revert InactiveOrder(_orderId);
        }
        Order memory _order = listings[_orderId];
        if (_order.seller == msg.sender) {
            revert ItemAlreadyOwned(_order.nftAddress, _order.tokenId);
        }
        // valid qty checks
        if (_qtyToBuy == 0 || _qtyToBuy > _order.quantity) {
            revert InvalidQuantityInput(_qtyToBuy);
        }
        require(
            msg.value == _order.pricePerItem * _qtyToBuy,
            "MarketplaceNonCustodial: Price not met!"
        );
        _splitFunds(msg.value, _order.seller);

        uint256 _newQty = _order.quantity - _qtyToBuy;
        if (_order.standard == NFTStandard.E721) {
            IERC721 _nft = IERC721(_order.nftAddress);
            _nft.safeTransferFrom(_order.seller, msg.sender, _order.tokenId);
            userListedNFTBefore[_order.seller][_order.nftAddress][
                _order.tokenId
            ] = false;
        } else {
            IERC1155 _nft = IERC1155(_order.nftAddress);
            _nft.safeTransferFrom(
                _order.seller,
                msg.sender,
                _order.tokenId,
                _qtyToBuy,
                ""
            );
            if (_newQty == 0) {
                userListedNFTBefore[_order.seller][_order.nftAddress][
                    _order.tokenId
                ] = false;
            }
        }
        _addBuyerToOrder(_orderId, msg.sender, _qtyToBuy, _order.pricePerItem);
        listings[_orderId].quantity = _newQty;
        emit ItemsBought(
            _orderId,
            _order.nftAddress,
            _order.standard,
            _order.tokenId,
            _qtyToBuy,
            msg.value,
            msg.sender
        );
    }

    function isOrderActive(uint256 _orderId)
        public
        view
        override
        returns (bool)
    {
        if (_orderId > orderCtr) {
            return false;
        }
        if (isOrderClosed(_orderId) == true) {
            return false;
        }
        Order memory _order = listings[_orderId];
        if (_order.standard == NFTStandard.E721) {
            IERC721 _nft = IERC721(_order.nftAddress);
            //note don't need to make sure if owner is right because with any transfer approval will be cleared
            try _nft.getApproved(_order.tokenId) returns (
                address _approvedAddress
            ) {
                return _approvedAddress == address(this);
            } catch {
                // for non existent tokens
                return false;
            }
        } else {
            IERC1155 _nft = IERC1155(_order.nftAddress);
            // check ownership and approval
            if (
                (_nft.balanceOf(_order.seller, _order.tokenId) >=
                    _order.quantity) &&
                (_nft.isApprovedForAll(_order.seller, address(this)))
            ) {
                return true;
            } else {
                return false;
            }
        }
    }

    function isERC721(address nftAddress)
        public
        view
        override
        returns (bool output)
    {
        output = nftAddress.supportsInterface(IID_IERC721);
    }

    function isERC1155(address nftAddress)
        public
        view
        override
        returns (bool output)
    {
        output = nftAddress.supportsInterface(IID_IERC1155);
    }

    function isOrderClosed(uint256 _orderId) public view returns (bool) {
        return (listings[_orderId].quantity == 0);
    }

    function _createNewOrder(
        address _nftAddress,
        NFTStandard _standard,
        uint256 _tokenId,
        uint256 _qty,
        uint256 _pricePerItem,
        address payable _seller
    ) internal {
        orderCtr++;

        listings[orderCtr].orderId = orderCtr;
        listings[orderCtr].nftAddress = _nftAddress;
        listings[orderCtr].standard = _standard;
        listings[orderCtr].tokenId = _tokenId;
        listings[orderCtr].quantity = _qty;
        listings[orderCtr].pricePerItem = _pricePerItem;
        listings[orderCtr].seller = _seller;
        userListedNFTBefore[_seller][_nftAddress][_tokenId] = true;
        emit ItemsListed(
            orderCtr,
            _nftAddress,
            _standard,
            _tokenId,
            _qty,
            _pricePerItem,
            _seller
        );
    }

    function _updateOrderPrice(uint256 _orderId, uint256 _newPricePerItem)
        internal
    {
        listings[_orderId].pricePerItem = _newPricePerItem;
    }

    function _splitFunds(uint256 _totalValue, address payable _seller)
        internal
    {
        uint256 valueToSeller = (_totalValue * (100 - percentFeesAdmin)) / 100;
        payable(_seller).transfer(valueToSeller);
    }

    function _addBuyerToOrder(
        uint256 _orderId,
        address _buyer,
        uint256 _qtyBought,
        uint256 _buyPrice
    ) internal {
        listingBuyers[_orderId].push(Buyer(_buyer, _qtyBought, _buyPrice));
    }

    receive() external payable {}
}