/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/interfaces/IERC2981.sol


// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165Checker.sol


// OpenZeppelin Contracts (last updated v4.7.2) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;


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
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
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
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
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

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
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
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @isaacfrank/contracts/utils/GetStuck.sol



pragma solidity ^0.8.0;



contract GetStuck is Ownable {
    /// @notice Get stuck tokens in the contract
    /// @dev Function can be overriden
    /// @param token The address of the token stuck in the contract
    /// @param receiver The address of who would receive the stuck token
    function getStuckToken(IERC20 token, address receiver)
        public
        virtual
        onlyOwner
    {
        uint256 amount = token.balanceOf(address(this));
        token.transfer(receiver, amount);
    }

    /// @notice Get stuck eth in the contract
    /// @dev Function can be overriden
    /// @param receiver The address of who would receive the stuck eth
    function getStuckETH(address receiver) public virtual onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = payable(receiver).call{value: amount}("");

        require(success, "transfer failed");
    }
}

// File: ArtreusMarketplace.sol


pragma solidity ^0.8.0;







/// @title NFT Marketplace for Artreus Protocol
/// @author Isaac Frank
contract ArtreusMarketplace is Ownable, GetStuck {
    using Counters for Counters.Counter;
    using ERC165Checker for address;

    // ======================================================
    // STRUCTS
    // ======================================================
    struct Item {
        address collection;
        uint256 tokenId;
        uint256 marketplaceId;
        //===>
        address seller;
        address owner;
        uint256 price;
        bool sold;
        //===>
        address oldOwner;
        address oldSeller;
        uint256 oldPrice;
        //==>
        bool isResell;
        bool isBanned;
        bool soldFirstTime;
        //==>
        uint256 royaltyAmount;
        address royaltyRecipient;
    }

    struct Collection {
        bool isListed;
    }

    // ======================================================
    // STATE VARIABLES
    // ======================================================
    Counters.Counter private itemId;
    Counters.Counter private itemsSold;

    mapping(address => uint256[]) private allCollectionsTokenId;
    mapping(address => mapping(uint256 => Item))
        private collectionItemByTokenId;
    mapping(address => Collection) private isListed;
    address[] private collections;
    mapping(uint256 => Item) private itemById;

    address public feeAccount; // the account that recieves fees
    uint256 public feePercent; // the fee percentage on sales 1: 100, 50: 5000, 100: 10000
    uint256 public precision = 10000;
    bytes4 public constant _INTERFACE_ID_ROYALTIES_EIP2981 =
        type(IERC2981).interfaceId;

    // ======================================================
    // EVENTS
    // ======================================================
    event ItemListed(
        address indexed collection,
        uint256 indexed tokenId,
        uint256 marketplaceId,
        address indexed seller,
        address owner,
        uint256 price,
        address oldOwner,
        address oldSeller,
        uint256 oldPrice,
        bool isResell,
        bool soldFirstTime,
        uint256 royaltyAmount,
        address royaltyRecipient
    );

    event ItemSold(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed buyer,
        uint256 price,
        uint256 royaltyAmount,
        address royaltyRecipient
    );

    event CancelledListing(address indexed collection, uint256 indexed tokenId);

    event UpdatedItemPrice(
        address indexed collection,
        uint256 indexed tokenId,
        uint256 oldPrice,
        uint256 newPrice
    );

    event UpdatedBanItem(
        address indexed collection,
        uint256 indexed tokenId,
        bool indexed value
    );

    event UpdatedFeeAccount(
        address indexed oldAccount,
        address indexed newAccount
    );

    event UpdatedFeePercent(uint256 indexed oldFee, uint256 indexed newFee);

    // ======================================================
    // CONSTRUCTOR
    // ======================================================
    constructor(address _feeAccount, uint256 _feePercent) {
        feeAccount = _feeAccount;
        feePercent = _feePercent;
    }

    // ======================================================
    // MODIFIERS
    // ======================================================
    modifier onlyItemOwner(
        address collection,
        uint256 tokenId,
        address user
    ) {
        require(
            IERC721(collection).ownerOf(tokenId) == user,
            "Sender does not own the item"
        );
        _;
    }

    modifier hasTransferApproval(
        address collection,
        uint256 tokenId,
        address user
    ) {
        require(
            IERC721(collection).isApprovedForAll(user, address(this)) ||
                IERC721(collection).getApproved(tokenId) == address(this),
            "Market is not approved"
        );
        _;
    }

    modifier itemExists(address collection, uint256 tokenId) {
        require(
            collectionItemByTokenId[collection][tokenId].marketplaceId != 0,
            "Could not find item"
        );
        _;
    }

    modifier isForSale(address collection, uint256 tokenId) {
        require(
            collectionItemByTokenId[collection][tokenId].owner == address(0),
            "Item is not for sale"
        );
        _;
    }

    modifier itemExistsById(uint256 id) {
        require(itemById[id].marketplaceId != 0, "Could not find item");
        _;
    }

    modifier isForSaleById(uint256 id) {
        require(itemById[id].owner == address(0), "Item is not for sale");
        _;
    }

    modifier isNotForSale(address collection, uint256 tokenId) {
        bool firstTime = collectionItemByTokenId[collection][tokenId]
            .marketplaceId == 0;
        if (!firstTime) {
            require(
                collectionItemByTokenId[collection][tokenId].owner !=
                    address(0),
                "Item is for sale"
            );
        }
        _;
    }

    // ======================================================
    // PRIVATE METHODS
    // ======================================================
    function takeMarketFee(uint256 price) private returns (uint256 _fee) {
        _fee = (price * feePercent) / precision;
        (bool success, ) = feeAccount.call{value: _fee}("");
        require(success, "Taking Market Fee Failed");
    }

    function takeRoyaltyFee(
        address nft,
        uint256 tokenId,
        uint256 price
    ) private returns (uint256 _fee, address _recipient) {
        (_recipient, _fee) = royaltyInfo(nft, tokenId, price);
        (bool success, ) = _recipient.call{value: _fee}("");
        require(success, "Taking Royalty Fee Failed");
    }

    function royaltyInfo(
        address nft,
        uint256 tokenId,
        uint256 price
    ) private view returns (address recipient, uint256 amount) {
        if (nft.supportsInterface(_INTERFACE_ID_ROYALTIES_EIP2981)) {
            (recipient, amount) = IERC2981(nft).royaltyInfo(tokenId, price);
        }
    }

    function _buyNFT(Item memory item) private {
        address customer = msg.sender;
        uint256 value = msg.value;
        uint256 price = item.price;

        require(value >= price, "Not enough funds sent");
        require(customer != item.seller, "Can't buy your own item");

        uint256 rem = value - price;
        if (rem > 0) customer.call{value: rem}("");

        uint256 marketCharge = takeMarketFee(price);
        (uint256 royaltyCharge, address royaltyReceiver) = takeRoyaltyFee(
            item.collection,
            item.tokenId,
            price
        );

        uint256 toReceive = price - (marketCharge + royaltyCharge);
        (bool success, ) = item.seller.call{value: toReceive}("");
        require(success, "Failed to pay seller");

        IERC721(item.collection).transferFrom(
            address(this),
            customer,
            item.tokenId
        );

        item.owner = customer;
        item.sold = true;

        itemById[item.marketplaceId] = item;
        collectionItemByTokenId[item.collection][item.tokenId] = item;

        itemsSold.increment();

        emit ItemSold(
            item.collection,
            item.tokenId,
            customer,
            price,
            royaltyCharge,
            royaltyReceiver
        );
    }

    function _cancelSale(Item memory item) private {
        address customer = msg.sender;

        require(customer == item.seller, "Can't cancel others listing");

        IERC721(item.collection).transferFrom(
            address(this),
            customer,
            item.tokenId
        );

        item.owner = customer;
        item.seller = item.oldSeller;
        item.price = 0;
        item.sold = true;

        itemsSold.increment();

        emit CancelledListing(item.collection, item.tokenId);

        itemById[item.marketplaceId] = item;
        collectionItemByTokenId[item.collection][item.tokenId] = item;
    }

    function _updateItemPrice(Item memory item, uint256 newPrice) private {
        require(msg.sender == item.seller, "Can't update others listing");

        uint256 oldPrice = item.price;
        item.price = newPrice;

        itemById[item.marketplaceId] = item;
        collectionItemByTokenId[item.collection][item.tokenId] = item;

        emit UpdatedItemPrice(
            item.collection,
            item.tokenId,
            oldPrice,
            newPrice
        );
    }

    function _listPartTwo(
        Item memory item,
        address collection,
        uint256 tokenId
    ) private {
        if (!isListed[collection].isListed) {
            isListed[collection] = Collection(true);
            collections.push(collection);
        }

        if (
            collectionItemByTokenId[collection][tokenId].collection ==
            address(0)
        ) {
            allCollectionsTokenId[collection].push(tokenId);
        }

        collectionItemByTokenId[collection][tokenId] = item;
        itemById[item.marketplaceId] = item;

        (address royaltyRecipient, uint256 royaltyAmount) = royaltyInfo(
            item.collection,
            item.tokenId,
            item.price
        );

        emit ItemListed(
            item.collection,
            item.tokenId,
            item.marketplaceId,
            item.seller,
            item.owner,
            item.price,
            item.oldOwner,
            item.oldSeller,
            item.oldPrice,
            item.isResell,
            item.soldFirstTime,
            royaltyAmount,
            royaltyRecipient
        );
    }

    function _filterItems(address collection, bool onsale)
        private
        view
        returns (Item[] memory)
    {
        uint256[] memory ids = allCollectionsTokenId[collection];
        uint256 itemCount;
        uint256 index;

        for (uint256 i = 0; i < ids.length; i++) {
            if (
                (collectionItemByTokenId[collection][ids[i]].owner ==
                    address(0)) == onsale
            ) {
                itemCount += 1;
            }
        }
        Item[] memory items = new Item[](itemCount);
        for (uint256 i = 0; i < ids.length; i++) {
            if (
                (collectionItemByTokenId[collection][ids[i]].owner ==
                    address(0)) == onsale
            ) {
                items[index] = collectionItemByTokenId[collection][ids[i]];
                index += 1;
            }
        }

        return items;
    }

    // ======================================================
    // PUBLIC / EXTERNAL METHODS
    // ======================================================
    function listNFT(
        address collection,
        uint256 tokenId,
        uint256 price
    )
        external
        onlyItemOwner(collection, tokenId, msg.sender)
        hasTransferApproval(collection, tokenId, msg.sender)
        isNotForSale(collection, tokenId)
        returns (bool)
    {
        IERC721(collection).transferFrom(msg.sender, address(this), tokenId);

        Item memory item = collectionItemByTokenId[collection][tokenId];
        // First time
        if (item.marketplaceId == 0) {
            itemId.increment();
            uint256 id = itemId.current();

            item.collection = collection;
            item.tokenId = tokenId;
            item.marketplaceId = id;

            item.seller = msg.sender;
            item.price = price;
        }
        // Relisting
        else {
            // Prev Values
            address oldOwner = item.owner;
            address oldSeller = item.seller;
            uint256 oldPrice = item.price;

            // Current values
            item.owner = address(0);
            item.seller = oldOwner;
            item.price = price;
            item.sold = false;
            item.isResell = false;

            //Start to save old value
            item.oldOwner = oldOwner;
            item.oldSeller = oldSeller;
            item.oldPrice = oldPrice;
            itemsSold.decrement();
        }
        // Escape Stack too Deep error
        _listPartTwo(item, collection, tokenId);

        return true;
    }

    function buyNFT(address collection, uint256 tokenId)
        external
        payable
        itemExists(collection, tokenId)
        isForSale(collection, tokenId)
    {
        Item memory item = collectionItemByTokenId[collection][tokenId];
        _buyNFT(item);
    }

    function buyNFT(uint256 id)
        external
        payable
        itemExistsById(id)
        isForSaleById(id)
    {
        Item memory item = itemById[id];
        _buyNFT(item);
    }

    function cancelSale(address collection, uint256 tokenId)
        external
        itemExists(collection, tokenId)
        isForSale(collection, tokenId)
    {
        Item memory item = collectionItemByTokenId[collection][tokenId];
        _cancelSale(item);
    }

    function cancelSale(uint256 id)
        external
        itemExistsById(id)
        isForSaleById(id)
    {
        Item memory item = itemById[id];
        _cancelSale(item);
    }

    function updateItemPrice(
        address collection,
        uint256 tokenId,
        uint256 newPrice
    ) external itemExists(collection, tokenId) isForSale(collection, tokenId) {
        Item memory item = collectionItemByTokenId[collection][tokenId];
        _updateItemPrice(item, newPrice);
    }

    function updateItemPrice(uint256 id, uint256 newPrice)
        external
        itemExistsById(id)
        isForSaleById(id)
    {
        Item memory item = itemById[id];
        _updateItemPrice(item, newPrice);
    }

    // ======================================================
    // OWNABLE METHODS
    // ======================================================
    function updateFeeAccount(address newAccount) external onlyOwner {
        emit UpdatedFeeAccount(feeAccount, newAccount);
        feeAccount = newAccount;
    }

    function setFeePercent(uint256 _feePercent) public onlyOwner {
        require(_feePercent > 0, "Fee percent must be at least 1");
        require(
            _feePercent <= precision,
            "Fee percent must be less than precision"
        );
        emit UpdatedFeePercent(feePercent, _feePercent);
        feePercent = _feePercent;
    }

    // ======================================================
    // VIEW METHODS
    // ======================================================

    function fetchSingleItem(address collection, uint256 tokenId)
        external
        view
        returns (Item memory item)
    {
        item = collectionItemByTokenId[collection][tokenId];
    }

    function fetchSingleItem(uint256 id)
        external
        view
        returns (Item memory item)
    {
        item = itemById[id];
    }

    function getMyItemCreated() public view returns (Item[] memory) {
        uint256 total = itemId.current();
        uint256 itemCount;
        uint256 index;

        for (uint256 i = 0; i < total; i++) {
            if (itemById[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }

        Item[] memory items = new Item[](itemCount);
        for (uint256 i = 0; i < total; i++) {
            if (itemById[i + 1].seller == msg.sender) {
                items[index] = itemById[i + 1];
                index += 1;
            }
        }
        return items;
    }

    function getMyNFTPurchased() public view returns (Item[] memory) {
        uint256 total = itemId.current();
        uint256 itemCount;
        uint256 index;

        for (uint256 i = 0; i < total; i++) {
            if (itemById[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        Item[] memory items = new Item[](itemCount);
        for (uint256 i = 0; i < total; i++) {
            if (itemById[i + 1].owner == msg.sender) {
                items[index] = itemById[i + 1];
                index += 1;
            }
        }
        return items;
    }

    function getAllUnsoldItems() public view returns (Item[] memory) {
        uint256 total = itemId.current();
        uint256 itemCount = total - itemsSold.current();
        uint256 index;

        Item[] memory items = new Item[](itemCount);
        for (uint256 i = 0; i < total; i++) {
            if (itemById[i + 1].owner == address(0)) {
                items[index] = itemById[i + 1];
                index += 1;
            }
        }
        return items;
    }

    function getMyResellItems() public view returns (Item[] memory) {
        uint256 total = itemId.current();
        uint256 itemCount;
        uint256 index;

        for (uint256 i = 0; i < total; i++) {
            if (
                (itemById[i + 1].seller == msg.sender) &&
                (itemById[i + 1].sold == false)
            ) {
                itemCount += 1;
            }
        }

        Item[] memory items = new Item[](itemCount);
        for (uint256 i = 0; i < total; i++) {
            if (
                itemById[i + 1].seller == msg.sender &&
                itemById[i + 1].sold == false
            ) {
                items[index] = itemById[i + 1];
                index += 1;
            }
        }
        return items;
    }

    function getCollectionActive(address collection)
        external
        view
        returns (Item[] memory items)
    {
        items = _filterItems(collection, true);
    }

    function getCollectionDorm(address collection)
        external
        view
        returns (Item[] memory items)
    {
        items = _filterItems(collection, false);
    }

    function getCollectionTokenIds(address collection)
        external
        view
        returns (uint256[] memory ids)
    {
        ids = allCollectionsTokenId[collection];
    }

    function getCollectionItemByTokenId(address collection, uint256 tokenId)
        external
        view
        returns (Item memory item)
    {
        item = collectionItemByTokenId[collection][tokenId];
    }

    function getAllCollections()
        external
        view
        returns (address[] memory collecs)
    {
        collecs = collections;
    }

    function collectionIsListed(address collection)
        external
        view
        returns (bool listed)
    {
        listed = isListed[collection].isListed;
    }
}