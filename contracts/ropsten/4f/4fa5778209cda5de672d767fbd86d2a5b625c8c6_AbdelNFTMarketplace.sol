/**
 *Submitted for verification at Etherscan.io on 2022-06-29
*/

// File: Abdel/interfaces/ILazyMinting.sol


pragma solidity ^0.8.3;

interface ILazyMinting {
    //@dev don't change the structure as it is being inherited in other contracts
    struct NFTVoucher {
        uint256 tokenId;
        uint256 amount;
        uint256 price;
        uint256 ts;
        string tokenURI;
        bytes signature;
    }

    function redeem(
        address minter,
        NFTVoucher calldata voucher
    ) external ;
}
// File: Abdel/interfaces/ITokenRoyaltyInfo.sol


pragma solidity ^0.8.0;

interface ITokenRoyaltyInfo {
    function royaltyInfo(uint256 tokenId, address seller, uint256 amount)
        external
        view
        returns (
            address[] memory receivers,
            uint256[] memory royalties,
            uint256 totalRoyalty
        );
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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;



/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;


/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


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

// File: Abdel/AbdelNFTMarketplace.sol

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;








contract AbdelNFTMarketplace is ERC1155Holder, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;

    enum SaleKind {
        FixedPrice,
        Auction
    }

    uint256 private _serviceFee;
    uint256 private _denominator = 10000;

    //min percent increment in next bid
    uint256 private _bidRate;
    uint256 private _totalServiceFeeAmount;
    //uint private _totalBidAmount;

    SaleKind public saleKind;

    Counters.Counter private _itemIds;

    event List(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed itemId,
        uint256 tokenId,
        uint256 basePrice,
        uint256 amount,
        uint256 listingDate,
        uint256 expirationDate
    );

    event Cancel(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed itemId,
        uint256 tokenId,
        uint256 amount
    );

    event Sold(
        uint256 indexed itemId,
        address indexed seller,
        address indexed buyer,
        address nftAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 nftNumber
    );

    event TransferredRoyaltyToTheCreator(
        address indexed creator,
        uint256 amount
    );

    event TransferredPaymentToTheSeller(
        address indexed seller,
        address indexed buyer,
        uint256 indexed itemId,
        uint256 amount
    );

    event ServiceFeeClaimed(address indexed account, uint256 amount);

    event ServiceFeeUpdated(
        address indexed owner,
        uint256 oldFee,
        uint256 newFee
    );

    event OfferRetracted(
        uint256 indexed itemId,
        uint256 indexed tokenId,
        address indexed bidder,
        address nftAddress,
        uint256 amount
    );

    event BidOffered(
        uint256 indexed itemId,
        uint256 indexed tokenId,
        address indexed bidder,
        address nftAddress,
        uint256 bidAmount
    );

    //event RoyaltyWithdrawn(uint256 amount, address indexed recipient);

    modifier itemExists(uint256 _id) {
        require(_id <= _itemIds.current(), "itemExists:Item Id out of bounds");
        require(marketItems[_id].basePrice > 0, "itemExists: Item not listed");
        _;
    }

    struct Item {
        uint256 tokenId;
        uint256 basePrice;
        uint256 itemsAvailable;
        uint256 listingTime;
        uint256 expirationTime;
        uint256 reservePrice;
        address nftAddress;
        address seller;
        bool lazyMint;
        SaleKind saleKind;
    }

    struct Bid {
        uint256 maxBid;
        address bidderAddress;
    }

    //itemId => Item
    mapping(uint256 => Item) public marketItems;
    //itemId => Bid
    mapping(uint256 => Bid) public itemBids;

    mapping(address => uint256) public userRoyalties;

    constructor(uint256 serviceFee_, uint256 bidRate_) {
        _serviceFee = serviceFee_;
        _bidRate = bidRate_;
    }

    // function getItem(uint256 _itemId)
    //     external
    //     view
    //     itemExists(_itemId)
    //     returns (Item memory)
    // {
    //     Item memory item_ = marketItems[_itemId];
    //     return item_;
    // }

    function getItemCount() external view returns (uint256) {
        return _itemIds.current();
    }

    function setServiceFee(uint256 _newFee) external onlyOwner {
        uint256 _oldFee = _serviceFee;
        _serviceFee = _newFee;
        emit ServiceFeeUpdated(_msgSender(), _oldFee, _newFee);
    }

    function listItem(
        uint256 _tokenId,
        uint256 _basePrice,
        uint256 _nftAmount,
        uint256 _listingTime,
        uint256 _expirationTime,
        uint256 _reservePrice,
        address _nftAddress,
        bool _lazyMint,
        SaleKind _saleKind
    ) external nonReentrant {
        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        require(
            _expirationTime > _listingTime,
            "listItem: Expiration date invalid"
        );

        require(_basePrice > 0, "listItem: Price cannot be zero");

        if (_saleKind == SaleKind.Auction && _reservePrice != 0) {
            require(
                _reservePrice > _basePrice,
                "listItem: Reserve price is lower than base price"
            );
        }

        IERC1155 nft = IERC1155(_nftAddress);
        require(
            nft.isApprovedForAll(_msgSender(), address(this)),
            "listItem: NFT not approved for marketplace"
        );

        marketItems[itemId] = Item(
            _tokenId,
            _basePrice,
            _nftAmount,
            _listingTime,
            _expirationTime,
            _reservePrice,
            _nftAddress,
            _msgSender(),
            _lazyMint,
            _saleKind
        );

        if (_lazyMint) {
            emit List(
                _msgSender(),
                _nftAddress,
                itemId,
                _tokenId,
                _basePrice,
                _nftAmount,
                _listingTime,
                _expirationTime
            );
        } else {
            nft.safeTransferFrom(
                _msgSender(),
                address(this),
                _tokenId,
                _nftAmount,
                ""
            );
        }

        emit List(
            _msgSender(),
            _nftAddress,
            itemId,
            _tokenId,
            _basePrice,
            _nftAmount,
            _listingTime,
            _expirationTime
        );
    }

    //function lazyListItem(address nftAddres) external nonReentrant {}

    function cancelListing(uint256 _itemId) external itemExists(_itemId) {
        Item memory item_ = marketItems[_itemId];
        IERC1155 nft = IERC1155(item_.nftAddress);

        require(
            item_.seller == _msgSender(),
            "cancelListing: Unauthorized access"
        );

        if (itemBids[_itemId].maxBid > 0) {
            _refund(itemBids[_itemId].maxBid, itemBids[_itemId].bidderAddress);
        }

        uint256 id = item_.tokenId;
        uint256 amount = item_.itemsAvailable;
        bool islazyMint = item_.lazyMint;

        delete (marketItems[_itemId]);
        delete (itemBids[_itemId]);

        if (!islazyMint) {
            nft.safeTransferFrom(address(this), _msgSender(), id, amount, "");
        }

        emit Cancel(_msgSender(), item_.nftAddress, _itemId, id, amount);
    }

    function makeBid(uint256 _itemId)
        external
        payable
        itemExists(_itemId)
        nonReentrant
    {
        Item memory item_ = marketItems[_itemId];
        uint256 _oldBid = itemBids[_itemId].maxBid;
        uint256 _bidAmount = msg.value;

        require(
            item_.saleKind == SaleKind.Auction,
            "makeBid: Not listed for English Auction"
        );
        require(
            item_.expirationTime > block.timestamp,
            "makeBid: Sale expired"
        );

        if (_oldBid == 0) {
            require(
                _bidAmount >= item_.basePrice,
                "makeBid: Bid lower than base price"
            );
        } else {
            require(
                _bidAmount >= (_oldBid * _bidRate) / _denominator,
                "makeBid: New bid supposed to be at least 5 percent higher than last"
            );
            _refund(_oldBid, itemBids[_itemId].bidderAddress);
        }

        itemBids[_itemId].maxBid = _bidAmount;
        itemBids[_itemId].bidderAddress = _msgSender();

        emit BidOffered(
            _itemId,
            item_.tokenId,
            _msgSender(),
            item_.nftAddress,
            _bidAmount
        );
    }

    function buyItem(
        uint256 _itemId,
        uint256 _nftAmount,
        ILazyMinting.NFTVoucher calldata voucher
    ) public payable itemExists(_itemId) nonReentrant {
        Item memory item_ = marketItems[_itemId];

        require(
            item_.saleKind == SaleKind.FixedPrice,
            "buyItem: Not on fixed price sale"
        );

        require(
            item_.expirationTime > block.timestamp &&
                item_.listingTime < block.timestamp,
            "buyItem: Not on active sale"
        );
        require(
            item_.itemsAvailable >= _nftAmount,
            "buyItem: Not enough tokens on sale"
        );

        if (!item_.lazyMint) {
            uint256 _totalPrice = item_.basePrice * _nftAmount;
            require(msg.value >= _totalPrice, "buyItem: Price not met");
            _purchase(_itemId, _totalPrice, _nftAmount, _msgSender());
        } else {
            uint256 _totalPrice = item_.basePrice;
            require(msg.value >= _totalPrice, "buyItem: Price not met");
            _purchaseWithLazyMinting(
                _itemId,
                _totalPrice,
                _msgSender(),
                voucher
            );
        }
    }

    function claimNFT(uint256 _itemId, ILazyMinting.NFTVoucher calldata voucher)
        external
        itemExists(_itemId)
    {
        Item memory item_ = marketItems[_itemId];
        uint256 price = itemBids[_itemId].maxBid;
        uint256 _nftAmount = item_.itemsAvailable;

        require(
            block.timestamp > item_.expirationTime,
            "claimNFT: Auction process ongoing"
        );
        require(
            _msgSender() == itemBids[_itemId].bidderAddress,
            "claimNFT: Unauthorized access"
        );

        if (item_.reservePrice != 0) {
            if (itemBids[_itemId].maxBid < item_.reservePrice) {
                _refund(itemBids[_itemId].maxBid, _msgSender());
                revert("claimNFT: Reserve price not met");
            }
        }

        if (item_.lazyMint) {
            _purchaseWithLazyMinting(_itemId, price, _msgSender(), voucher);
        } else {
            _purchase(_itemId, price, _nftAmount, _msgSender());
        }
    }

    function acceptOffer(
        uint256 _itemId,
        ILazyMinting.NFTVoucher calldata voucher
    ) external itemExists(_itemId) {
        Item memory item_ = marketItems[_itemId];
        uint256 price = itemBids[_itemId].maxBid;

        require(
            _msgSender() == item_.seller,
            "acceptOffer: Unauthorized access"
        );
        require(price > 0, "acceptOffer: No offers to accept");

        uint256 _nftAmount = item_.itemsAvailable;

        if (item_.lazyMint) {
            _purchaseWithLazyMinting(
                _itemId,
                price,
                itemBids[_itemId].bidderAddress,
                voucher
            );
        } else {
            _purchase(
                _itemId,
                price,
                _nftAmount,
                itemBids[_itemId].bidderAddress
            );
        }
    }

    function retractOffer(uint256 _itemId) external itemExists(_itemId) {
        Item memory item_ = marketItems[_itemId];

        require(
            _msgSender() == itemBids[_itemId].bidderAddress,
            "retractOffer: Unauthorized access"
        );
        require(
            block.timestamp > item_.expirationTime,
            "retractOffer: Auction ongoing, cannot retract bid"
        );

        uint256 amount = itemBids[_itemId].maxBid;

        delete (itemBids[_itemId]);
        payable(_msgSender()).transfer(amount);

        emit OfferRetracted(
            _itemId,
            item_.tokenId,
            _msgSender(),
            item_.nftAddress,
            amount
        );
    }

    function withdrawServiceFee(address account, uint256 amount)
        external
        onlyOwner
    {
        require(
            _totalServiceFeeAmount >= amount,
            "withdrawServiceFee: Not sufficient funds"
        );
        _totalServiceFeeAmount -= amount;

        payable(account).transfer(amount);

        emit ServiceFeeClaimed(account, amount);
    }

    function withdrawRoyalty() external nonReentrant {
        uint256 amount = userRoyalties[_msgSender()];
        userRoyalties[_msgSender()] = 0;
        payable(_msgSender()).transfer(amount);
        emit TransferredRoyaltyToTheCreator(_msgSender(), amount);
    }

    function _purchaseWithLazyMinting(
        uint256 _itemId,
        uint256 _totalPrice,
        address _buyer,
        ILazyMinting.NFTVoucher calldata voucher
    ) internal {
        Item memory item_ = marketItems[_itemId];

        uint256 serviceFee_ = _getServiceFee(_totalPrice);
        _totalServiceFeeAmount += serviceFee_;
        uint256 payment = _totalPrice - serviceFee_;

        ILazyMinting(item_.nftAddress).redeem(_buyer, voucher);

        payable(item_.seller).transfer(payment);

        if (msg.value > _totalPrice) {
            _refund(msg.value - _totalPrice, _buyer);
        }
        delete (marketItems[_itemId]);
        delete (itemBids[_itemId]);
    }

    function _purchase(
        uint256 _itemId,
        uint256 _totalPrice,
        uint256 _nftAmount,
        address _buyer
    ) internal nonReentrant {
        Item memory item_ = marketItems[_itemId];

        (
            address[] memory _creators,
            uint256[] memory _royalties,
            uint256 _totalRoyalty
        ) = _getRoyalty(
                item_.nftAddress,
                item_.seller,
                item_.tokenId,
                _totalPrice
            );

        require(
            _creators.length == _royalties.length,
            "_purchase: creators and royaty count mismatch"
        );

        uint256 serviceFee_ = _getServiceFee(_totalPrice);
        uint256 payment = _totalPrice - _totalRoyalty - serviceFee_;

        item_.itemsAvailable -= _nftAmount;

        _totalServiceFeeAmount += serviceFee_;

        //Transferring payment to the seller
        payable(item_.seller).transfer(payment);
        emit TransferredPaymentToTheSeller(
            item_.seller,
            _buyer,
            _itemId,
            payment
        );

        //Transferring royalties to the recipients
        for (uint256 i = 0; i < _creators.length; i += 1) {
            userRoyalties[_creators[i]] += _royalties[i];
        }

        //Transferring the NFTs
        IERC1155(item_.nftAddress).safeTransferFrom(
            address(this),
            _buyer,
            item_.tokenId,
            _nftAmount,
            ""
        );

        emit Sold(
            _itemId,
            item_.seller,
            _buyer,
            item_.nftAddress,
            item_.tokenId,
            _totalPrice,
            _nftAmount
        );

        if (item_.itemsAvailable == 0) {
            delete (marketItems[_itemId]);
            delete (itemBids[_itemId]);
        }

        if (msg.value > _totalPrice) {
            _refund(msg.value - _totalPrice, _buyer);
        }
    }

    function _refund(uint256 amount, address receiver) internal {
        payable(receiver).transfer(amount);
    }

    function _getRoyalty(
        address _nftAddress,
        address _seller,
        uint256 _tokenId,
        uint256 _amount
    )
        internal
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256
        )
    {
        try
            ITokenRoyaltyInfo(_nftAddress).royaltyInfo(_tokenId, _seller, _amount)
        returns (
            address[] memory creators,
            uint256[] memory royalties,
            uint256 totalRoyalty
        ) {
            return (creators, royalties, totalRoyalty);
        } catch {
            address[] memory nullAddress;
            uint256[] memory nullValues;
            return (nullAddress, nullValues, 0);
        }
    }

    function _getServiceFee(uint256 _amount) internal view returns (uint256) {
        return (_amount * _serviceFee) / _denominator;
    }
}