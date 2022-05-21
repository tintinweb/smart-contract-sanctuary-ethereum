//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import "./Interfaces.sol";


abstract contract Ownable {
    address public owner;
    constructor() {owner = msg.sender;}
    modifier onlyOwner {require(owner == msg.sender, "Not Owner!");
        _;}
    function transferOwnership(address new_) external onlyOwner {owner = new_;}
}

interface IOwnable {
    function owner() external view returns (address);
}

contract PawShop is Ownable {

    // Events

    event WLVendingItemAdded(address indexed operator_, WLVendingItem item_);
    event WLVendingItemModified(address indexed operator_, WLVendingItem before_, WLVendingItem after_);
    event WLVendingItemRemoved(address indexed operator_, WLVendingItem item_);
    event WLVendingItemPurchased(address indexed purchaser_, uint256 index_, WLVendingItem object_);


    IERC20 paw;
    IERC1155 tracker;
    IKumaVerse  kumaContract;

    constructor(address _pawContract, address _trackerContract, address _kumaverseContract) {
        paw = IERC20(_pawContract);
        tracker = IERC1155(_trackerContract);
        kumaContract = IKumaVerse(_kumaverseContract);
    }

    // holdersType -> 0 : anyone with paw, 1 : genesis and tracker holders, 2: tracker holders only
    // category -> 0 : WL spot, 1 : NFT
    struct WLVendingItem {
        string title;
        string imageUri;
        string projectUri;
        string description;

        uint32 amountAvailable;
        uint32 amountPurchased;

        uint32 startTime;
        uint32 endTime;

        uint256 price;

        uint128 holdersType;
        uint128 category;
    }

    modifier onlyAdmin() {
        require(shopAdmin[msg.sender], "You are not admin");
        _;
    }

    mapping(address => bool) public shopAdmin;
    // Database of Vending Items for each ERC20
    WLVendingItem[] public WLVendingItemsDb;

    // Database of Vending Items Purchasers for each ERC20
    mapping(uint256 => address[]) public contractToWLPurchasers;
    mapping(uint256 => mapping(address => bool)) public contractToWLPurchased;

    function setPermission(address _toUpdate, bool _isAdmin) external onlyOwner() {
        shopAdmin[_toUpdate] = _isAdmin;
    }

    function addItem(WLVendingItem memory WLVendingItem_) external onlyAdmin() {
        require(bytes(WLVendingItem_.title).length > 0,
            "You must specify a Title!");
        require(uint256(WLVendingItem_.endTime) > block.timestamp,
            "Already expired timestamp!");
        require(WLVendingItem_.endTime > WLVendingItem_.startTime,
            "endTime > startTime!");

        // Make sure that amountPurchased on adding is always 0
        WLVendingItem_.amountPurchased = 0;

        // Push the item to the database array
        WLVendingItemsDb.push(WLVendingItem_);

        emit WLVendingItemAdded(msg.sender, WLVendingItem_);
    }

    function editItem(uint256 index_, WLVendingItem memory WLVendingItem_) external onlyAdmin() {
        WLVendingItem memory _item = WLVendingItemsDb[index_];

        require(bytes(_item.title).length > 0,
            "This WLVendingItem does not exist!");
        require(bytes(WLVendingItem_.title).length > 0,
            "Title must not be empty!");

        require(WLVendingItem_.amountAvailable >= _item.amountPurchased,
            "Amount Available must be >= Amount Purchased!");

        WLVendingItemsDb[index_] = WLVendingItem_;

        emit WLVendingItemModified(msg.sender, _item, WLVendingItem_);
    }

    function deleteMostRecentWLVendingItem() external onlyAdmin() {
        uint256 _lastIndex = WLVendingItemsDb.length - 1;

        WLVendingItem memory _item = WLVendingItemsDb[_lastIndex];

        require(_item.amountPurchased == 0,
            "Cannot delete item with already bought goods!");

        WLVendingItemsDb.pop();
        emit WLVendingItemRemoved(msg.sender, _item);
    }
    //
    //    // Core Function of WL Vending (User) - ok
    //    // ~0xInuarashi @ 2022-04-08
    //    // As of Martian Market V2 this uses PriceController and TokenController values.
    //    // We wrap it all in a WLVendingObject item which aggregates WLVendingItem data
    function buyItem(uint256 index_) external {

        // Load the WLVendingObject to Memory
        WLVendingItem memory _object = getWLVendingObject(index_);

        // Check the necessary requirements to purchase
        require(bytes(_object.title).length > 0,
            "This WLVendingObject does not exist!");
        require(_object.amountAvailable > _object.amountPurchased,
            "No more WL remaining!");
        require(_object.startTime <= block.timestamp,
            "Not started yet!");
        require(_object.endTime >= block.timestamp,
            "Past deadline!");
        require(!contractToWLPurchased[index_][msg.sender],
            "Already purchased!");
        require(_object.price != 0,
            "Item does not have a set price!");
        require(paw.balanceOf(msg.sender) >= _object.price,
            "Not enough tokens!");
        require(canBuy(msg.sender, _object.holdersType), "You can't buy this");
        // Pay for the WL
        paw .transferFrom(msg.sender, address(this), _object.price);

        // Add the address into the WL List
        contractToWLPurchased[index_][msg.sender] = true;
        contractToWLPurchasers[index_].push(msg.sender);

        // Increment Amount Purchased
        WLVendingItemsDb[index_].amountPurchased++;

        emit WLVendingItemPurchased(msg.sender, index_, _object);
    }

    function canBuy(address _buyer, uint256 _holdersType) internal returns (bool) {

        if (_holdersType == 0) {
            return true;
        } else if (_holdersType == 1) {
            uint256 kumaBalance = kumaContract.balanceOf(_buyer);
            if (kumaBalance > 0) {
                return true;
            }
        } else if (_holdersType == 2) {
            uint256 trackerBalance = tracker.balanceOf(_buyer, 1);
            if (trackerBalance > 0) {
                return true;
            }
        }
        return false;
    }

    function getWLPurchasersOf(uint256 index_) public view
    returns (address[] memory) {
        return contractToWLPurchasers[index_];
    }

    function getWLVendingItemsLength() public view
    returns (uint256) {
        return WLVendingItemsDb.length;
    }

    function getWLVendingItemsAll() public view
    returns (WLVendingItem[] memory) {
        return WLVendingItemsDb;
    }

    function raw_getWLVendingItemsPaginated(uint256 start_,
        uint256 end_) public view returns (WLVendingItem[] memory) {
        uint256 _arrayLength = end_ - start_ + 1;
        WLVendingItem[] memory _items = new WLVendingItem[](_arrayLength);
        uint256 _index;

        for (uint256 i = 0; i < _arrayLength; i++) {
            _items[_index++] = WLVendingItemsDb[start_ + i];
        }

        return _items;
    }

    // Generally, this is the go-to read function for front-end interfaces.
    function getWLVendingObject(uint256 index_) public
    view returns (WLVendingItem memory) {
        WLVendingItem memory _item = WLVendingItemsDb[index_];
        return _item;
    }

    function getWLVendingObjectsPaginated(uint256 start_,
        uint256 end_) public view returns (WLVendingItem[] memory) {
        uint256 _arrayLength = end_ - start_ + 1;
        WLVendingItem[] memory _objects = new WLVendingItem[](_arrayLength);
        uint256 _index;

        for (uint256 i = 0; i < _arrayLength; i++) {

            uint256 _itemIndex = start_ + i;

            WLVendingItem memory _item = WLVendingItemsDb[_itemIndex];

            _objects[_index++] = _item;
        }

        return _objects;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

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

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';

interface IPaw is IERC20 {
    function updateReward(address _address) external;
}

interface IKumaVerse is IERC721 {

}

interface IKumaTracker is IERC1155 {}

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}