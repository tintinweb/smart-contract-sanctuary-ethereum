/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

// SPDX-License-Identifier: MIT
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



    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);
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

// File: contracts/AuctionAndBid.sol


pragma solidity ^0.8.8;





interface IAsixNFT {
    enum TYPE {
        Listener,
        Promotor
    }
    struct ITEM {
        uint256 id;
        address owner;
        TYPE _type;
        bool onSell;
		string url;
		string name;
		uint256 price;
		string others;

    }
    

   
   function mintItem(string memory _name, uint256 _price, TYPE itemType, string memory _url, string memory _others) external;
   function getItemDetails(uint _itemId) external view returns(ITEM memory);
   function getItemPrice(uint256 _itemId) external view returns(uint256);
   function totalItemsMinted () external view returns (uint);
   function getUserInventory(address _user) external view returns (ITEM[] memory);
   function changeOwner(address _newOwner, uint _itemId) external;
   function changeState(uint _itemId) external;
   function changeBuyAndSellAddress(address _buyAndSellAddress) external;
   function getType(uint _choice) external view returns(TYPE);
}


contract AuctionAndBids is ReentrancyGuard {
    // --------------- Var --------------
    using Counters for Counters.Counter;
    Counters.Counter private auctionId;
    mapping(uint256 => Auction) private IdToAuction;
    mapping(address => mapping(uint=>uint)) private BidersBalances; // balance of each bidder
    address public platFormAddress;
    IAsixNFT getItem;
    IERC20 public paymentToken;

    address private getItemsAddress;

    struct Auction {
        uint256 id;
        bool start;
        bool end;
        uint256 endAt;
        address[] bidders;
        address highestBidder;
        uint256 highestBid;
        address seller;
        uint256 itemId;
    }

    constructor(address _getItemAddress, address _paymentAddress) {
        getItem = IAsixNFT(_getItemAddress);
        platFormAddress = address(0);
        getItemsAddress = _getItemAddress;
        paymentToken = IERC20(_paymentAddress);
        
    }

    

    // create an Auction
    // our contract can recieve ERC1155 tokens
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function createAuction(
        uint256 _itemId,
        uint256 _timesInHour
        
    ) external {
        
        auctionId.increment();
        uint256 currentBidId = auctionId.current();
        IdToAuction[currentBidId].id = currentBidId;
        IdToAuction[currentBidId].start = true;
        IdToAuction[currentBidId].end = false;
        IdToAuction[currentBidId].endAt = block.timestamp + _timesInHour * 1 hours;
        IdToAuction[currentBidId].bidders.push(msg.sender);
        IdToAuction[currentBidId].highestBidder = msg.sender;
        IdToAuction[currentBidId].highestBid = getItem.getItemPrice(_itemId);
        IdToAuction[currentBidId].seller = msg.sender;
        IdToAuction[currentBidId].itemId = _itemId;
        getItem.changeOwner(address(this), _itemId);
        getItem.changeState(_itemId);
        IERC1155(getItemsAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _itemId,
            1,
            ""
        );
        
    }

    // Enter to the auction (bid)
    function bid(uint256 _auctionId, uint256 _bidAmount) external nonReentrant {
        
        uint totalBid = _bidAmount + BidersBalances[msg.sender][_auctionId];
        uint256 highest_bid = IdToAuction[_auctionId].highestBid;
        bool isStarted = IdToAuction[_auctionId].start;
        bool isEnded = IdToAuction[_auctionId].end;
        uint256 endAt = IdToAuction[_auctionId].endAt;
        require(totalBid > highest_bid, "value < H.B");
        require(isStarted, "!started");
        require(isEnded == false, "ended");
        require(block.timestamp < endAt, "time out");
        bool res = paymentToken.increaseAllowance(address(this), _bidAmount); 
        require(res, "failed");
        BidersBalances[msg.sender][_auctionId] += _bidAmount;
        // uint256 itemId = IdToAuction[_auctionId].itemId;
        IdToAuction[_auctionId].highestBid = totalBid;
        IdToAuction[_auctionId].highestBidder = msg.sender;
        IdToAuction[_auctionId].bidders.push(msg.sender);
        
    }

    // end the auction everyone can call this function require timeend

    function endAuction(uint256 _auctionId) external nonReentrant {
        uint256 endTime = IdToAuction[_auctionId].endAt;
        bool isStarted = IdToAuction[_auctionId].start;
        bool isEnded = IdToAuction[_auctionId].end;
        require(block.timestamp >= endTime, "not yet");
        require(isStarted == true, "not started");
        require(isEnded == false, "ended");
        address highestBidder = IdToAuction[_auctionId].highestBidder;
        BidersBalances[highestBidder][_auctionId] = 0;
        uint256 highest_bid = IdToAuction[_auctionId].highestBid;

        address seller_addr = IdToAuction[_auctionId].seller;

        bool res = paymentToken.transferFrom(highestBidder, address(this), highest_bid); // staking token transfer POOL.
        require(res, "Please try again.");
        res = paymentToken.transfer(seller_addr, highest_bid);
        require(res, "Please try again.");


        uint256 itemId = IdToAuction[_auctionId].itemId;
        IdToAuction[_auctionId].end = true;
        IdToAuction[_auctionId].start = false;
        getItem.changeOwner(address(this), itemId);
        getItem.changeState(itemId);
        IERC1155(getItemsAddress).safeTransferFrom(
            address(this),
            highestBidder,
            itemId,
            1,
            ""
        );
       
    }

    // Cancel Auction


    function cancelAuction(uint256 _auctionId) external {
        bool isStarted = IdToAuction[_auctionId].start;
        bool isEnded = IdToAuction[_auctionId].end;
        address seller = IdToAuction[_auctionId].seller;
        address highest_bidder = IdToAuction[_auctionId].highestBidder;
        require(highest_bidder == seller ,"you can't cancel");// there's already auction
        require(msg.sender == seller, "you can't");
        require(isStarted == true, "ended");
        require(isEnded == false, "ended");
        uint256 itemId = IdToAuction[_auctionId].itemId;
        IdToAuction[_auctionId].end = true;
        IdToAuction[_auctionId].start = false;
        getItem.changeOwner(address(this), itemId);
        getItem.changeState(itemId);
        IERC1155(getItemsAddress).safeTransferFrom(
            address(this),
            msg.sender,
            itemId,
            1,
            ""
        );

        
    }

    // withdraw bids but the highest bidder can't

    function withdrawBids(uint256 _auctionId) external nonReentrant {
        address highestBidder = IdToAuction[_auctionId].highestBidder;
        require(highestBidder != msg.sender,"you're H.B");
        uint256 allowedwithraw = 0;
        if (msg.sender != highestBidder) {
            allowedwithraw = BidersBalances[msg.sender][_auctionId];
            BidersBalances[msg.sender][_auctionId] = 0;
        }

        
        bool res = paymentToken.decreaseAllowance(address(this), allowedwithraw); 
        require(res, "failed");
        
    }

    // Get Auction Details

    function getAuctionDetails(uint256 _auctionId)
        external
        view
        returns (Auction memory)
    {
        return (IdToAuction[_auctionId]);
    }



    function getTotalAuction() external view returns(Auction[] memory){
        uint totalAuctions = auctionId.current();
        Auction[] memory auctions = new Auction[](totalAuctions);

        uint currentIndex = 0;
        for(uint i =1;i<=totalAuctions;i++){
            Auction storage currentAuction = IdToAuction[i];
            auctions[currentIndex] = currentAuction;
            currentIndex += 1;    
        }
        return auctions;
    }

    
    function isUserBidder(address _user) external view returns(bool){
        uint totalCreated = auctionId.current();
        for(uint i =1;i<=totalCreated;i++){
            Auction memory auc = IdToAuction[i];
            for(uint j=0;j<auc.bidders.length;j++){
                if(_user == auc.bidders[j]){
                    return true;
                }
            }
        }
        return false;
    }

 


// FIX BALANCE

    function getBalanceOf(address _bidder,uint _auctionId) external view returns(uint){
        return BidersBalances[_bidder][_auctionId];
    }

    function totalAuctionsCreated() external view returns(uint){
        return auctionId.current();
    }
}