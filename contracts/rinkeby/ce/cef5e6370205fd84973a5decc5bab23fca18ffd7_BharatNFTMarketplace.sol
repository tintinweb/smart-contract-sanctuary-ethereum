/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

/**
 *Submitted for verification at Etherscan.io on 2022-07-22
*/

// SPDX-License-Identifier: MIT
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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
}


// File: @openzeppelin/contracts/utils/Counters.sol

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: contracts/BMark.sol
//@author Priyanshu Jain


pragma solidity ^0.8.0;


interface BharatNFT721{
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns(address receiver, uint256 royaltyAmount);
    function ownerOf(uint256 tokenId) external view returns (address);
    function getApproved(uint256 tokenId) external view returns (address);
    function totalSupply() external view returns(uint256);
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external ;
}
  
interface BharatNFT1155 {
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns(address receiver, uint256 royaltyAmount);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function ownerOf(uint256 tokenId) external view  returns (address);
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}


contract BharatNFTMarketplace is Ownable, ReentrancyGuard, IERC721Receiver {

    using Counters for Counters.Counter;      


    Counters.Counter public _listingIds1155;


    Counters.Counter public _itemIds721;

    Counters.Counter public _itemsSold721;

    Counters.Counter public _itemsCancelled721;
                                            

    uint8 public commission = 2;
    

    mapping(uint128 => Listing1155) public idToListing1155;

    mapping(uint128 => tokenDetails721) public tokenToAuction721;

    mapping(uint128 => Offer) public offerToToken721;

    mapping(uint128 => mapping(address => uint128)) public bids721;

    mapping(uint128 => MarketItem721) public idToMarketItem721;


    BharatNFT721 private BERC721;   

    BharatNFT1155 private BERC1155;

    IERC20 private BERC20;


    enum MarketItemStatus721 {
        Active,
        Sold,
        Cancelled
    }                                         


    constructor(address _erc721, address _erc1155, address _erc20) {
    
        BERC721 = BharatNFT721(_erc721);
        BERC1155 = BharatNFT1155(_erc1155);
        BERC20 = IERC20(_erc20);
    }


    struct tokenDetails721 {
        address seller;
        uint128 price;
        uint128 duration;
        uint128 maxBid;
        address maxBidUser;
        bool isActive;
        uint128[] bidAmounts;
        address[] users;
    }


    struct MarketItem721 {
        uint128 itemId;
        uint128 tokenId;
        address payable seller;
        address payable owner;
        uint128 price;
        MarketItemStatus721 status;
    }


    struct Listing1155 {
        address seller;
        address[] buyer;
        uint128 tokenId;
        uint128 amount;
        uint128 price;
        uint128 tokensAvailable;
        bool privateListing;
        bool completed;
        uint listingId;
    }


    struct Offer {
        address offerer;
        address owner;
        uint128 price;
        bool isCompleted;
    }

    event TokenListed721(
        uint256 itemId
    );


    event TokenListed1155(                                                         
        address indexed seller, 
        uint128 indexed tokenId, 
        uint128 amount, 
        uint128 pricePerToken, 
        address[] privateBuyer, 
        bool privateSale, 
        uint indexed listingId
    );


    event TokenSold1155(
        address seller, 
        address buyer, 
        uint128 tokenId, 
        uint128 amount, 
        uint128 pricePerToken, 
        bool privateSale
    );


    event ListingDeleted1155(
        uint indexed listingId
    );


    function getRoyalties721(uint256 tokenId, uint256 price)
        private
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        (receiver, royaltyAmount) = BERC721.royaltyInfo(tokenId, price);
        if (receiver == address(0) || royaltyAmount == 0) {
            return (address(0), 0);
        }
        return (receiver, royaltyAmount);
    }


    function getRoyalties1155(uint256 tokenId, uint256 price)
        private
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        (receiver, royaltyAmount) = BERC1155.royaltyInfo(tokenId, price);
        if (receiver == address(0) || royaltyAmount == 0) {
            return (address(0), 0);
        }
        return (receiver, royaltyAmount);
    }



//-----------------------------------------------------------------------------ERC721(Offer)--------------------------------------------------------------------------------//



    function makeOffer(uint128 _tokenId, uint128 offer) external nonReentrant {

        require(_tokenId <= BERC721.totalSupply(),"Token ID does not exist");
        require(BERC20.allowance(msg.sender, address(this)) >= offer, "Bharat token not approved");
        require(offerToToken721[_tokenId].price <= offer, "Need a better offer");


        Offer memory _offer = Offer({

            offerer: msg.sender,
            owner: BERC721.ownerOf(_tokenId),
            price: offer,
            isCompleted: false
        });

        offerToToken721[_tokenId] = _offer;

    }


    function acceptOffer(uint128 _tokenId) external nonReentrant {

        require(BERC721.ownerOf(_tokenId) == msg.sender, "Only the owner is allowed to accept offer");
        
        Offer memory offer = offerToToken721[_tokenId];

        require(!offer.isCompleted, "Already completed");
        require(msg.sender == offer.owner, "Caller is not the seller");
        require(BERC20.allowance(offer.offerer, address(this)) >= offer.price, "Bharat token not approved");

        offer.isCompleted = true;

        (address royaltyReceiver, uint256 royaltyAmount) = getRoyalties721(
            _tokenId,
            offer.price
        );

            BERC20.transferFrom(offer.offerer, offer.owner,  ((offer.price - royaltyAmount)*(100 - commission))/100);

            BERC20.transferFrom(offer.offerer, address(this),  ((offer.price - royaltyAmount)*(commission))/100);

            BERC20.transferFrom(offer.offerer, royaltyReceiver, royaltyAmount);


            BERC721.safeTransferFrom(
                offer.owner,
                offer.offerer,
                _tokenId
            );
        
    }


    function rejectOffer(uint128 _tokenId) external nonReentrant {
        
        Offer memory offer = offerToToken721[_tokenId];

        require(msg.sender == offer.owner || msg.sender == offer.offerer , "You can't reject this offer");
        require(!offer.isCompleted, "Offer already accepted or rejected or deleted");

        offer.isCompleted = true;
    }


    function fetchBestOffer(uint128 _tokenId) public view returns (Offer memory) {
        Offer memory offer = offerToToken721[_tokenId];
        return offer;
    }

//-----------------------------------------------------------------------------ERC721--------------------------------------------------------------------------------//
    function createMarketItem721(uint128 tokenId, uint128 price)
        external 
        nonReentrant
    {

        require(
            BERC721.ownerOf(tokenId) == msg.sender,
            "Sender does not own the item"
        );
        require(price > 0,
            "Price must be at least 1 wei"
        );
        require(
            BERC721.getApproved(tokenId) == address(this),
            "Market is not approved"
        );

        BERC721.transferFrom(msg.sender, address(this), tokenId);

        _itemIds721.increment();

        uint256 itemId = _itemIds721.current();

        idToMarketItem721[uint128(itemId)] = MarketItem721(
            uint128(itemId),
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            MarketItemStatus721.Active
        );

        emit TokenListed721(itemId);

    }


    function createMarketSale721(uint128 itemId)
        external
        payable
        nonReentrant
    {
        require(itemId <= _itemIds721.current() && itemId > 0, "Could not find item");

        MarketItem721 storage idToMarketItem_ = idToMarketItem721[itemId];
        uint256 tokenId = idToMarketItem_.tokenId;

        require(
            idToMarketItem_.status == MarketItemStatus721.Active,
            "Listing Not Active"
        );
        require(msg.sender != idToMarketItem_.seller, "Seller can't be buyer");
        require(
            msg.value == idToMarketItem_.price,
            "Please submit the asking price in order to complete the purchase"
        );

        (address royaltyReceiver, uint256 royaltyAmount) = getRoyalties721(
            tokenId,
            msg.value
        );

        (bool success, ) = idToMarketItem_.seller.call{value: ((idToMarketItem_.price - royaltyAmount)*(100 - commission))/100}("");
            require(success,"Unable to transfer funds to seller");

        (bool success0, ) = royaltyReceiver.call{value: royaltyAmount}("");
            require(success0,"Unable to transfer funds to royalty reciever");    
        
        BERC721.transferFrom(address(this), msg.sender, tokenId);
        
        idToMarketItem_.owner = payable(msg.sender);
        idToMarketItem_.status = MarketItemStatus721.Sold;
        _itemsSold721.increment();
      
    }


    function cancelMarketItem721(uint128 itemId)
        external
        nonReentrant
    {
        require(itemId <= _itemIds721.current() && itemId > 0, "Could not find item");

        MarketItem721 storage idToMarketItem_ = idToMarketItem721[itemId];

        require(msg.sender == idToMarketItem_.seller, "Only Seller can Cancel");
        require(
            idToMarketItem_.status == MarketItemStatus721.Active,
            "Item must be active"
        );

        idToMarketItem_.status = MarketItemStatus721.Cancelled;
        _itemsCancelled721.increment();
        
        BERC721.transferFrom(address(this), msg.sender, idToMarketItem_.tokenId);

    }


    function fetchMarketItems721(uint128 _tokenId) public view returns (MarketItem721 memory) {
        MarketItem721 memory item = idToMarketItem721[_tokenId];
        return item;
    }

    

//------------------------------------------------------------------721 Auction-------------------------------------------------------------------------//



    function createTokenAuction721(
        uint128 _tokenId,
        uint128 _price,  // In wei and in bharat token
        uint128 _duration
    ) external {

        require(msg.sender != address(0), "Invalid Address");
        require(msg.sender == BERC721.ownerOf(_tokenId), "Not the owner of tokenId");
        require(_price > 0, "Price should be more than 0");
        require(_duration > 0, "Invalid duration value");

        tokenDetails721 memory _auction = tokenDetails721({
            seller: msg.sender,
            price: uint128(_price),
            duration: _duration,
            maxBid: 0,
            maxBidUser: address(0),
            isActive: true,
            bidAmounts: new uint128[](0),
            users: new address[](0)
        });

        BERC721.safeTransferFrom(msg.sender, address(this), _tokenId);
        tokenToAuction721[_tokenId] = _auction;
    }


    function bid721(uint128 _tokenId, uint128 _amount) external nonReentrant {

        tokenDetails721 storage auction = tokenToAuction721[_tokenId];

        require(_amount >= auction.price, "Bid less than price");
        require(BERC20.allowance(msg.sender, address(this)) >= _amount, "Bharat token not approved");
        require(auction.isActive, "auction not active");
        require(auction.duration > block.timestamp, "Deadline already passed");

        bids721[_tokenId][msg.sender] = _amount;

        if (auction.bidAmounts.length == 0) {
            auction.maxBid = _amount;
            auction.maxBidUser = msg.sender;
        } else {
            uint256 lastIndex = auction.bidAmounts.length - 1;
            require(auction.bidAmounts[lastIndex] < _amount, "Current max bid is higher than your bid");
            auction.maxBid = _amount;
            auction.maxBidUser = msg.sender;
        }

        auction.users.push(msg.sender);
        auction.bidAmounts.push(_amount);
    }


    function executeSale721(uint128 _tokenId) external nonReentrant {

        tokenDetails721 storage auction = tokenToAuction721[_tokenId];

        require(auction.maxBidUser == msg.sender || msg.sender == auction.seller, "You can't buy");
        require(auction.duration <= block.timestamp, "Deadline did not pass yet");
        require(auction.isActive, "auction not active");

        if (msg.sender == auction.seller && auction.bidAmounts.length == 0) {

            auction.isActive = false;

            BERC721.safeTransferFrom(
                address(this),
                auction.seller,
                _tokenId
            );

        } else {

        require(BERC20.allowance(auction.maxBidUser, address(this)) >= auction.maxBid, "Bharat token not approved");

        auction.isActive = false;

        (address royaltyReceiver, uint256 royaltyAmount) = getRoyalties721(
            _tokenId,
            auction.maxBid
        );

            BERC20.transferFrom(auction.maxBidUser, auction.seller,  ((auction.maxBid - royaltyAmount)*(100 - commission))/100);

            BERC20.transferFrom(auction.maxBidUser, address(this),  ((auction.maxBid - royaltyAmount)*(commission))/100);

            BERC20.transferFrom(auction.maxBidUser, royaltyReceiver, royaltyAmount);


            BERC721.safeTransferFrom(
                address(this),
                auction.maxBidUser,
                _tokenId
            );
        }
    }
    

    function cancelAuction721(uint128 _tokenId) external nonReentrant {

        tokenDetails721 storage auction = tokenToAuction721[_tokenId];
        
        require(auction.seller == msg.sender, "Not seller");
        require(auction.isActive, "auction not active");
        
        auction.isActive = false;

        BERC721.safeTransferFrom(address(this), auction.seller, _tokenId);
    }


    function getTokenAuctionDetails721(uint128 _tokenId) public view returns (tokenDetails721 memory) {
        tokenDetails721 memory auction = tokenToAuction721[_tokenId];
        return auction;
    }


    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    )external override pure returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    receive() external payable {}


//-----------------------------------------------------------------------------ERC1155--------------------------------------------------------------------------------//


    function listToken1155(uint128 tokenId, uint128 amount, uint128 price, address[] memory privateBuyer) public nonReentrant returns(uint256) {
        require(amount > 0, "Amount must be greater than 0!");
        require(BERC1155.balanceOf(msg.sender, tokenId) >= amount, "Caller must own given token!");
        require(BERC1155.isApprovedForAll(msg.sender, address(this)), "Contract must be approved!");

        bool privateListing = privateBuyer.length>0;
        _listingIds1155.increment();
        uint256 listingId = _listingIds1155.current();
        idToListing1155[uint128(listingId)] = Listing1155(msg.sender, privateBuyer, tokenId, amount, price, amount, privateListing, false, _listingIds1155.current());


        emit TokenListed1155(msg.sender, tokenId, amount, price, privateBuyer, privateListing, _listingIds1155.current());

        return _listingIds1155.current();
    }


    function purchaseToken1155(uint128 listingId, uint128 amount) public payable nonReentrant {
        
        if(idToListing1155[listingId].privateListing == true) {
            bool whitelisted = false;
            for(uint i=0; i<idToListing1155[listingId].buyer.length; i++){
                if(idToListing1155[listingId].buyer[i] == msg.sender) {
                    whitelisted = true;
                }
            }
            require(whitelisted == true, "Sale is private!");
        }

        require(msg.sender != idToListing1155[listingId].seller, "Can't buy your own tokens!");
        require(msg.value >= idToListing1155[listingId].price * amount, "Insufficient funds!");
        require(BERC1155.balanceOf(idToListing1155[listingId].seller, idToListing1155[listingId].tokenId) >= amount, "Seller doesn't have enough tokens!");
        require(idToListing1155[listingId].completed == false, "Listing not available anymore!");
        require(idToListing1155[listingId].tokensAvailable >= amount, "Not enough tokens left!");

        idToListing1155[listingId].tokensAvailable -= amount;
    
        if(idToListing1155[listingId].privateListing == false){

            idToListing1155[listingId].buyer.push(msg.sender);
        }

        if(idToListing1155[listingId].tokensAvailable == 0) {

            idToListing1155[listingId].completed = true;
        }


        (address royaltyReceiver, uint256 royaltyAmount) = getRoyalties1155(
            idToListing1155[listingId].tokenId,
            idToListing1155[listingId].price
        );


        BERC1155.safeTransferFrom(idToListing1155[listingId].seller, msg.sender, idToListing1155[listingId].tokenId, amount, "");


        (bool success, ) = idToListing1155[listingId].seller.call{value: ((idToListing1155[listingId].price - royaltyAmount)*amount*(100 - commission))/100}("");
            require(success, "Unable to transfer funds to seller");

        (bool success0, ) = royaltyReceiver.call{value: royaltyAmount*amount}("");
            require(success0, "Unable to transfer funds to royalty reciever");    


        emit TokenSold1155(
            idToListing1155[listingId].seller,
            msg.sender,
            idToListing1155[listingId].tokenId,
            amount,
            idToListing1155[listingId].price,
            idToListing1155[listingId].privateListing
        );
 
    }


    function deleteListing1155(uint128 _listingId) external nonReentrant{
        require(msg.sender == idToListing1155[_listingId].seller, "Not caller's listing!");
        require(idToListing1155[_listingId].completed == false, "Listing not available!");
        
        idToListing1155[_listingId].completed = true;

        emit ListingDeleted1155(_listingId);
    }


    function viewListing1155(uint128 _listId) public view returns(Listing1155 memory) {
        Listing1155 memory listing = idToListing1155[_listId];
        return listing;
    }
    

//----------------------------------------------------------------------OnlyOwner-------------------------------------------------------------------------------------//


    function withdraw(uint128 _amount) public payable onlyOwner {
        require (_amount < address(this).balance, "Try a smaller amount");
	    (bool success, ) = payable(msg.sender).call{value: _amount}("");
		require(success, "Unable to transfer funds");
	}

    function withdrawToken(uint128 _amount) public onlyOwner {
        require (BERC20.balanceOf(address(this)) > _amount, "Try a smaller amount");
        BERC20.transfer(msg.sender, _amount);
    }


    function setCommission(uint8 _newRate) external onlyOwner {
        commission = _newRate;
    }


}