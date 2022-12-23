// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RandomMarketPlace is Ownable {
    mapping(address => bool) controllers;
    address public token;
    address public vault;
    uint256 public totalItems = 0;
    bool public isPaused = false;
    mapping(uint256 => Item) public items;
    uint256[] public deletedIds;
    mapping(address => mapping(uint256 => NftItem)) public nftItems;
    NftItem[] public nftItemsArray;

    struct CollectionForSell {
        address collection;
        uint256[] nftIds;
    }

    struct NftItem {
        address seller;
        uint256 price;
        uint256 tokenId;
        address tokenCollection;
        bool isForSale;
    }

    struct Item {
        uint256 id;
        string name;
        uint256 price;
        address owner;
        bool purchased;
        string mongoId;
        bool exists;
    }

    event ItemBought(
        uint256 id,
        string name,
        uint256 price,
        address owner,
        bool purchased
    );

    event NftBought(
        address seller,
        uint256 price,
        uint256 tokenId,
        address tokenCollection,
        bool isForSale
    );

    modifier onlyItemOwner(uint256 _id) {
        require(items[_id].owner == msg.sender, "You are not the owner");
        _;
    }

    modifier onlyController() {
        require(controllers[msg.sender], "You are not a controller");
        _;
    }

    modifier itemAlreadyPurchased(uint256 _id) {
        require(items[_id].purchased == false, "Item already purchased");
        _;
    }
    modifier allArraysAreSameLength(
        string[] memory _names,
        uint256[] memory _prices,
        string[] memory __mongoIds
    ) {
        require(
            _names.length == _prices.length &&
                _prices.length == __mongoIds.length,
            "Arrays are not the same length"
        );
        _;
    }

    modifier enoughMoneyToBuy(uint256 _id) {
        require(
            IERC20(token).balanceOf(msg.sender) >= items[_id].price,
            "You don't have enough money"
        );
        _;
    }

    modifier deleteNftItemsLengthCompliant(
        uint256[] memory _tokenIds,
        address[] memory _tokenCollections
    ) {
        require(
            _tokenIds.length == _tokenCollections.length,
            "Arrays are not the same length"
        );
        _;
    }

    modifier buyNftCompliant(
        uint256 _tokenId,
        address _tokenCollection,
        uint256 _price
    ) {
        NftItem memory _item = nftItems[_tokenCollection][_tokenId];
        require(_item.isForSale == true, "Item is not for sale");
        require(_item.price == _price, "Price is not correct");
        require(
            IERC721(_tokenCollection).ownerOf(_tokenId) == _item.seller,
            "Seller is not the owner"
        );
        require(
            IERC20(token).balanceOf(msg.sender) >= _item.price,
            "You don't have enough money"
        );
        require(
            IERC721(_tokenCollection).isApprovedForAll(
                _item.seller,
                address(this)
            ),
            "The Owner of this nft is no longer approved for this contract"
        );
        _;
    }

    modifier addNftItemsCompliant(
        uint256[] memory _prices,
        uint256[] memory _tokenIds,
        address[] memory _tokenCollections
    ) {
        require(
            _tokenCollections.length == _tokenIds.length &&
                _tokenIds.length == _prices.length,
            "Arrays are not the same length"
        );
        for (uint256 i = 0; i < _tokenCollections.length; i++) {
            require(
                IERC721(_tokenCollections[i]).isApprovedForAll(
                    msg.sender,
                    address(this)
                ),
                "You need to approve this contract before you sell your NFTs"
            );
            require(
                IERC721(_tokenCollections[i]).ownerOf(_tokenIds[i]) ==
                    msg.sender,
                "You are not the owner of this NFT"
            );
        }
        _;
    }

    modifier notPaused() {
        require(isPaused == false, "Contract is paused");
        _;
    }

    constructor(address _token) {
        token = _token;
    }

    function createItem(
        string memory _name,
        uint256 _price,
        string memory mongoId,
        address _seller
    ) public onlyController {
        uint256 id = totalItems;
        _seller == address(0) ? _seller = msg.sender : _seller = _seller;
        if (deletedIds.length > 0) {
            id = deletedIds[deletedIds.length - 1];
            deletedIds.pop();
        } else {
            id = totalItems;
            totalItems++;
        }
        items[id] = Item(id, _name, _price, _seller, false, mongoId, true);
    }

    function buyItem(uint256 _id)
        public
        itemAlreadyPurchased(_id)
        enoughMoneyToBuy(_id)
        notPaused
    {
        Item memory _item = items[_id];
        IERC20(token).transferFrom(msg.sender, _item.owner, _item.price);
        items[_id].owner = msg.sender;
        items[_id].purchased = true;
        emit ItemBought(_item.id, _item.name, _item.price, msg.sender, true);
    }

    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }

    function createManyItems(
        string[] memory _names,
        uint256[] memory _prices,
        string[] memory _mongoIds,
        address _seller
    ) public allArraysAreSameLength(_names, _prices, _mongoIds) onlyController {
        for (uint256 i = 0; i < _names.length; i++) {
            createItem(_names[i], _prices[i], _mongoIds[i], _seller);
        }
    }

    function addNftItems(
        uint256[] memory _prices,
        uint256[] memory _tokenIds,
        address[] memory _tokenCollections
    )
        public
        onlyController
        addNftItemsCompliant(_prices, _tokenIds, _tokenCollections)
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            NftItem memory _item = NftItem(
                msg.sender,
                _prices[i],
                _tokenIds[i],
                _tokenCollections[i],
                true
            );
            nftItems[_tokenCollections[i]][_tokenIds[i]] = _item;
            _addNftItemToArray(_item);
        }
    }

    function buyNftItem(
        uint256 _tokenId,
        address _tokenCollection,
        uint256 _price
    ) public notPaused buyNftCompliant(_tokenId, _tokenCollection, _price) {
        NftItem memory _item = nftItems[_tokenCollection][_tokenId];
        IERC20(token).transferFrom(msg.sender, _item.seller, _price);
        IERC721(_tokenCollection).transferFrom(
            _item.seller,
            msg.sender,
            _tokenId
        );
        _removeNftItemFromArray(_item);
        delete nftItems[_tokenCollection][_tokenId];
        emit NftBought(_item.seller, _price, _tokenId, _tokenCollection, false);
    }

    function deleteNftItems(
        uint256[] memory _tokenIds,
        address[] memory _tokenCollections
    )
        public
        deleteNftItemsLengthCompliant(_tokenIds, _tokenCollections)
        onlyController
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _removeNftItemFromArray(
                nftItems[_tokenCollections[i]][_tokenIds[i]]
            );
            delete nftItems[_tokenCollections[i]][_tokenIds[i]];
        }
    }

    function getNftItemsForSell()
        public
        view
        returns (NftItem[] memory _items)
    {
        return nftItemsArray;
    }

    function getItems() public view returns (Item[] memory) {
        Item[] memory _items = new Item[](totalItems);
        uint256 counter = 0;
        for (uint256 i = 0; i < totalItems; i++) {
            if (items[i].exists) {
                _items[counter] = items[i];
                counter++;
            }
        }
        return _items;
    }

    function getItemsForSaleIds() public view returns (uint256[] memory) {
        uint256[] memory _itemsForSellIds = new uint256[](totalItems);
        uint256 counter = 0;
        for (uint256 i = 0; i < totalItems; i++) {
            if (items[i].purchased == false) {
                _itemsForSellIds[counter] = items[i].id;
                counter += 1;
            }
        }
        return _itemsForSellIds;
    }

    function _addNftItemToArray(NftItem memory _item) internal {
        for (uint256 i = 0; i < nftItemsArray.length; i++) {
            if (
                nftItemsArray[i].tokenId == _item.tokenId &&
                nftItemsArray[i].tokenCollection == _item.tokenCollection
            ) {
                return;
            }
        }
        nftItemsArray.push(_item);
    }

    function _removeNftItemFromArray(NftItem memory _item) internal {
        for (uint256 i = 0; i < nftItemsArray.length; i++) {
            if (
                nftItemsArray[i].tokenId == _item.tokenId &&
                nftItemsArray[i].tokenCollection == _item.tokenCollection
            ) {
                delete nftItemsArray[i];
                nftItemsArray[i] = nftItemsArray[nftItemsArray.length - 1];
                nftItemsArray.pop();
                return;
            }
        }
    }

    function getSoldItems() public view returns (Item[] memory) {
        Item[] memory _soldItems = new Item[](totalItems);
        uint256 counter = 0;
        for (uint256 i = 0; i < totalItems; i++) {
            if (items[i].purchased == true) {
                _soldItems[counter] = items[i];
                counter += 1;
            }
        }
        return _soldItems;
    }

    function paused() public view returns (bool) {
        return isPaused;
    }

    function getSomeLove() public pure returns (string memory) {
        return "Love you <3 <3 <3";
    }

    function getSoldItemsIds() public view returns (uint256[] memory) {
        uint256[] memory _soldItemsIds = new uint256[](totalItems);
        uint256 counter = 0;
        for (uint256 i = 0; i < totalItems; i++) {
            if (items[i].purchased == true) {
                _soldItemsIds[counter] = items[i].id;
                counter += 1;
            }
        }
        return _soldItemsIds;
    }

    function getItem(uint256 _id) public view returns (Item memory) {
        return items[_id];
    }

    function getBalance() public view returns (uint256) {
        return IERC20(token).balanceOf(msg.sender);
    }

    function deleteItem(uint256 _id) public onlyController {
        require(items[_id].purchased == false, "Item is already purchased");
        require(items[_id].exists == true, "Item does not exist");
        deletedIds.push(_id);
        delete items[_id];
    }

    function deleteManyItems(uint256[] memory _ids) public onlyController {
        for (uint256 i = 0; i < _ids.length; i++) {
            deleteItem(_ids[i]);
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