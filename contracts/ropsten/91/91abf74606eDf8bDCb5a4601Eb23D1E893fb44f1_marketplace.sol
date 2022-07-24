/**
 *Submitted for verification at Etherscan.io on 2022-07-22
*/

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

// File: contracts/new_updated_contract.sol




pragma solidity ^0.8.10;




contract marketplace is ReentrancyGuard, ERC1155Holder

{
    address payable public immutable feeAccount;
    uint immutable feesPercent;
    uint private auctionItem;
    uint private itemCount;

    //structure for listing data
    struct Item{
        uint itemId;
        IERC1155 nft;
        uint tokenId;
        uint qunatity;
        uint price;
        address payable Seller;
        uint timestamp;
        // uint end_date;
        bool sold;
        bool archieved;
    }

    //structure for the auction data 
    struct Auction{
        uint itemId;
        IERC1155 nft;
        uint tokenId;
        uint qunatity;
        uint min_price;
        address payable Seller;
        uint timestamp;
        uint end_date;
        bool sold;
        bool archieved;
    }
    

    //structure for the Bids data
    struct Bids {
        uint bidPrice;
        address payable Bidder;
    }

    
    mapping(uint=>Item) public items;

    mapping(uint=>Bids) public bids;
    
    mapping(uint=>Auction) public auctionSale;

    mapping(uint=>Bids) public AuctionBids;

    // event saleListing(address indexed id, address indexed seller, IERC1155 indexed nft, uint saleAmount, uint tokenID, uint end_date);
    // event auctionListing(address indexed id, address indexed seller, IERC1155 indexed nft, uint saleAmount, uint tokenID, uint end_date);
    // event salePurchase(uint indexed id, address indexed seller, address indexed buyer, uint amount, uint timestamp);
    // event sellerApproval(uint indexed id, address indexed seller, address indexed Bidder, uint bid);
    // event auctionApproval(uint indexed id,address indexed seller, address indexed bidder, uint bid);
    // event saleBid(uint indexed id, address indexed bidder, uint bid);
    // event auctionBids(uint indexed id, address indexed bidder, uint bid);


    constructor(uint _feesPercent){
        feeAccount = payable(msg.sender);
        feesPercent = _feesPercent;
    }

    function ListForSale(IERC1155 _nft, uint _tokenId, uint _price, uint _amount, bytes calldata _bytes) external nonReentrant {
        require(_price>0, "Price must be greater then zero");
        itemCount ++;

        bool approved = _nft.isApprovedForAll(msg.sender, address(this));
        if(!approved){
            revert("please approve the marketplace contract to interact");
        }
        _nft.safeTransferFrom(msg.sender,address(this), _tokenId, _amount, _bytes);
        items[itemCount]= Item(itemCount,_nft,_tokenId,_amount, _price,payable(msg.sender),block.timestamp, false, false);

        bids[itemCount] = Bids(0, payable(msg.sender));
        
    }

    function PurchaseItem(uint _itemId) external payable nonReentrant{
        Bids storage bid = bids[_itemId];
        uint _totalPrice = getTotalPrice(_itemId);
        Item storage item = items[_itemId];
        require(_itemId>0 && _itemId<=itemCount,"item doesnot exist");
        require(msg.value >=_totalPrice, "Not enough amount to cover ur value");
        require(!item.sold,"item already sold");
        // require(item.end_date > block.timestamp, "Sale Over");
        require(!item.archieved,"item revoke");

        item.Seller.transfer(_totalPrice);
        feeAccount.transfer(item.price - _totalPrice);
        item.sold = true;
        item.nft.safeTransferFrom(address(this),msg.sender, item.tokenId, item.qunatity,"");
        if(bid.bidPrice > 0){
            bid.Bidder.transfer(bid.bidPrice);
        }
    }

    function SaleBidding(uint _itemId) external payable nonReentrant
    {
        Bids storage bid = bids[_itemId];
        Item storage item = items[_itemId];
        uint _totalPrice = getTotalPrice(_itemId);

        // require(item.end_date > block.timestamp, "Sale Over");
        require(msg.value>bid.bidPrice,"Bidding value must be greater than the last bid");
        require(_itemId>0 && _itemId<=itemCount,"item doesnot exist");
        require(!item.sold,"item already sold");
        require(!item.archieved,"item revoke");

        
        if(msg.value == item.price){
            require(msg.value >=_totalPrice,"Not enough Value");
            item.Seller.transfer(_totalPrice);
            feeAccount.transfer(item.price-_totalPrice);
            item.sold = true;
            item.nft.safeTransferFrom(address(this),msg.sender,
            item.tokenId, item.qunatity,"");
        }
        bid.Bidder.transfer(bid.bidPrice);
        bid.bidPrice  = msg.value;
        bid.Bidder =payable(msg.sender);
    }


    function SaleAcceptBid(uint _itemId) external payable nonReentrant{
        Bids storage bid = bids[_itemId];
        Item storage item = items[_itemId];
        uint _totalPrice = getTotalPrice(_itemId);
        require(item.Seller == msg.sender, "exception throw" );
        require(_itemId>0 && _itemId<=itemCount,"item doesnot exist");
        require(!item.sold,"item already sold");
        require(!item.archieved,"item revoke");

        require(bid.bidPrice != 0, "No bids has been made");
        // require(item.end_date > block.timestamp, "Sale Over");
        item.Seller.transfer(bid.bidPrice*(100 - feesPercent)/100);
        feeAccount.transfer(bid.bidPrice - (bid.bidPrice*(100 - feesPercent)/100));
        item.sold = true;
        item.nft.safeTransferFrom(address(this),bid.Bidder,
        item.tokenId, item.qunatity,"");
    }

    function RevertSale(uint _itemId) external payable nonReentrant {
        Item storage item = items[_itemId];
        Bids storage bid = bids[_itemId];
        require(item.Seller == msg.sender, "exception throw" );
        require(item.archieved, "item is already reverted");
        item.archieved = true;
        if(bid.bidPrice> 0){
            bid.Bidder.transfer(bid.bidPrice);
        }
        item.nft.safeTransferFrom(address(this),msg.sender,
            item.tokenId, item.qunatity,"");
    }

    



    

    




    function CreateAuction(IERC1155 _nft, uint _tokenId, uint _amount, uint _minPrice, uint _endDate, bytes calldata _bytes) external nonReentrant returns(uint){
        require(_minPrice>0, "Price must be greater then zero");
        auctionItem++;

        bool approved = _nft.isApprovedForAll(msg.sender, address(this));
        if(!approved){
            revert("please approve the marketplace contract to interact");
        }
        _nft.safeTransferFrom(msg.sender,address(this), _tokenId, _amount, _bytes);
        auctionSale[auctionItem]= Auction(auctionItem ,_nft,_tokenId,_amount, _minPrice, payable(msg.sender), block.timestamp, _endDate, false, false);
        AuctionBids[auctionItem] = Bids(0, payable(msg.sender));
        return auctionItem;
    }


    function AuctionBid(uint _auctionId) external payable nonReentrant {
        Bids storage bid = AuctionBids[_auctionId];
        Auction storage auction = auctionSale[_auctionId];
        require(auction.end_date > block.timestamp, "Sale Over");
        require(!auction.sold,"item sold");
        require(!auction.archieved,"item revoke");


        require(msg.value>bid.bidPrice && msg.value > auction.min_price,"Bidding value must be greater than the last bid");
        require(_auctionId>0 && _auctionId<=auctionItem,"item doesnot exist");
        bid.Bidder.transfer(bid.bidPrice);
        bid.bidPrice  = msg.value;
        bid.Bidder =payable(msg.sender);
    }




    function AuctionDisbursal(uint _auctionId) external payable nonReentrant{
        Bids storage bid = AuctionBids[_auctionId];
        Auction storage auction = auctionSale[_auctionId];
        require(block.timestamp > auction.end_date, "Please let the auction end");
        require(!auction.archieved, "Item is revoked from the auction");
        uint _totalPrice = getTotalPrice(bid.bidPrice);
        auction.nft.safeTransferFrom(address(this),bid.Bidder, auction.tokenId, auction.qunatity,"");
        auction.Seller.transfer(bid.bidPrice);
        auction.sold = true;
    }

    function RevertAuction(uint _itemId) external payable nonReentrant {
        Auction storage item = auctionSale[_itemId];
        Bids storage bid = AuctionBids[_itemId];
        require(item.Seller == msg.sender, "exception throw" );
        require(item.archieved, "item is already reverted");

        item.archieved = false;
        if(bid.bidPrice> 0){
            bid.Bidder.transfer(bid.bidPrice);

        }
        item.nft.safeTransferFrom(address(this),msg.sender,
            item.tokenId, item.qunatity,"");
    }




    function getTotalPrice(uint _itemId) private returns(uint){
    return (items[_itemId].price*(100 - feesPercent)/100);
    }


    function GetAuctionCount() public view returns(uint) {
        return auctionItem;
    }

    function GetSalesCount() public view returns(uint){
        return itemCount;
    }
}