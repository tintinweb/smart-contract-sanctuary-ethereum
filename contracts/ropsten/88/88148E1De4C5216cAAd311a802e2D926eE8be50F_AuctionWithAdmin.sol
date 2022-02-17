// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./Ownable.sol";

contract AuctionWithAdmin is Ownable {
	
	// The NFT token we are selling
	IERC721 private nft_token;
	
	// beneficiary Address
	address beneficiary;
	
	// Represents an auction on an NFT
	struct AuctionDetails{
	    // Price (in wei) at beginning of auction
	    uint price;
	    // Time (in seconds) when auction started
	    uint startTime;
	    // Time (in seconds) when auction ended
	    uint endTime;
	    // Address of highest bidder
	    address highestBidder;
	    // Highest bid amount
	    uint highestBid;
	    // Total number of bids
	    uint totalBids;
	}

	// Represents an offer on an NFT
	struct OfferDetails{
	    // Price (in wei) at beginning of auction
	    uint price;
	    // Address of offerer
	    address offerer;
	    // Offer accepted
	    bool accepted;
	}
	
	// Mapping token ID to their corresponding auction.
	mapping (uint => AuctionDetails) private auction;
	// Mapping token ID to their corresponding offer.
	mapping (uint => OfferDetails) private offer;
	// Mapping from addresss to token ID for claim.
	mapping (address => mapping (uint => uint)) private pending_claim;
	// Mapping from token ID to token price
	mapping (uint => uint) private token_price;
	// Mapping from token ID to token seller
    mapping (uint => address) private token_seller;
    
    uint sell_token_fee;
    uint auction_token_fee;
    
    event Sell (address indexed _seller, uint _tokenId, uint _price, uint _time);   
	event SellCancelled (address indexed _seller, uint _tokenId, uint _time);
    event Buy (address indexed _buyer,  uint _tokenId, address _seller, uint _price, uint _time);
	
    event AuctionCreated (address indexed _seller, uint _tokenId, uint _price, uint _startTime, uint _endTime);
	event Bid (address indexed _bidder, uint _tokenId, uint _price, uint _time);	
    event AuctionCancelled (address indexed _seller, uint _tokenId, uint _time);

	event OfferMaked (address indexed _offerer, uint _tokenId, uint _price, uint _time);
	event OfferReceived (address indexed _buyer,  uint _tokenId, address _seller, uint _price, uint _time);
        
	/// @dev Initialize the nft token contract address.
	function initialize(address _nftToken) public onlyOwner virtual returns(bool){
	    require(_nftToken != address(0));
	    nft_token = IERC721(_nftToken);
	    return true;
	}
	
	/// @dev Returns the nft token contract address.
	function getNFTToken() public view returns(IERC721){
	    return nft_token;
	}
	
	/// @dev Set the beneficiary address.
	/// @param _owner - beneficiary addess.
	function setBeneficiary(address _owner) public onlyOwner {
	    beneficiary = _owner;
	}
	
	/// @dev Contract owner set the token fee percent which is for sell.
	/// @param _tokenFee - Token fee.
	function setTokenFeePercentForSell(uint _tokenFee) public onlyOwner {
	     sell_token_fee = _tokenFee;
	}
	
	/// @dev Contract owner set the token fee percent which is for auction.
	/// @param _tokenFee - Token fee.
	function setTokenFeePercentForAuction(uint _tokenFee) public onlyOwner {
	     auction_token_fee = _tokenFee;
	}
	
	/// @dev Creates and begins a new auction.
    /// @param _tokenId - ID of token to auction, sender must be owner.
    /// @param _price - Price of token (in wei) at beginning of auction.
    /// @param _startTime - Start time of auction.
    /// @param _endTime - End time of auction.
	function createAuction(uint _tokenId, uint _price, uint _startTime, uint _endTime) public {
	    require(msg.sender == nft_token.ownerOf(_tokenId), "You are not owner");
	    require(nft_token.getApproved(_tokenId) == address(this), "Token not approved");
	    require(_startTime < _endTime && _endTime > block.timestamp, "Check Time");
	    AuctionDetails memory auctionToken;
	    auctionToken = AuctionDetails({
	        price         : _price,
	        startTime     : _startTime,
	        endTime       : _endTime,
	        highestBidder : address(0),
    		highestBid    : 0,
    		totalBids     : 0
	    });
	    token_seller[_tokenId] = msg.sender;
	    auction[_tokenId] = auctionToken;
	    nft_token.transferFrom(msg.sender, address(this), _tokenId);
	    emit AuctionCreated(msg.sender, _tokenId, _price, _startTime, _endTime);
	}
	
	/// @dev Bids on an open auction.
	/// @param _tokenId - ID of token to bid on.
	function bid(uint _tokenId) public payable{
	    require(block.timestamp > auction[_tokenId].startTime, "Auction not started yet");
	    require(block.timestamp < auction[_tokenId].endTime, "Auction is over");
	    // The first bid, ensure it's >= the reserve price.
        require(msg.value >= auction[_tokenId].price, "Bid must be at least the reserve price");
        // Bid must be greater than last bid.
	    require(msg.value > auction[_tokenId].highestBid, "Bid amount too low");
	    pending_claim[msg.sender][_tokenId] += msg.value;
	    auction[_tokenId].highestBidder = msg.sender;
	    auction[_tokenId].highestBid = pending_claim[msg.sender][_tokenId];
	    auction[_tokenId].totalBids++;
	    emit Bid(msg.sender, _tokenId, msg.value, block.timestamp);
	}

	/// @dev Offer on an sell.
	/// @param _tokenId - ID of token to offer on.
	function makeOffer(uint _tokenId) public payable{
		require(token_seller[_tokenId]!= address(0) && token_price[_tokenId] > 0, "Token not for sell");
        // Offer must be greater than last offer.
	    require(msg.value > offer[_tokenId].price, "Offer amount less then already offerred");
	    pending_claim[msg.sender][_tokenId] += msg.value;
	    offer[_tokenId].offerer = msg.sender;
	    offer[_tokenId].price = pending_claim[msg.sender][_tokenId];
	    emit OfferMaked(msg.sender, _tokenId, msg.value, block.timestamp);
	}

	/// @dev Receive offer from open sell.
	/// Transfer NFT ownership to offerer address.
	/// @param _tokenId - ID of NFT on offer.
	function reciveOffer(uint _tokenId) public {
		require(msg.sender == token_seller[_tokenId], "You are not owner");
	     nft_token.transferFrom(address(this), offer[_tokenId].offerer, _tokenId);
		 payable(beneficiary).transfer(offer[_tokenId].price * sell_token_fee / 100);
	     payable(token_seller[_tokenId]).transfer(offer[_tokenId].price * (100 - sell_token_fee) / 100);
		 delete token_seller[_tokenId];
	     delete token_price[_tokenId];
		 delete offer[_tokenId];
	     emit OfferReceived(offer[_tokenId].offerer, _tokenId, msg.sender, offer[_tokenId].price, block.timestamp);
    }
	
	/// @dev Create claim after auction ends.
	/// Transfer NFT to auction winner address.
	/// @param _tokenId - ID of NFT.
	function claim(uint _tokenId) public {
	    require(block.timestamp > auction[_tokenId].endTime, "Auction not ended yet");
	    require(auction[_tokenId].highestBidder == msg.sender, "Not a winner");
    	nft_token.transferFrom(address(this), msg.sender, _tokenId);
	}
	
	/// @dev Seller and Bidders (not win in auction) Withdraw their funds.
	/// @param _tokenId - ID of NFT.
	function withdraw(uint _tokenId) public {
	    require(block.timestamp > auction[_tokenId].endTime, "Auction not ended yet");
	    if(msg.sender == token_seller[_tokenId]){
	        payable(beneficiary).transfer(auction[_tokenId].highestBid * auction_token_fee / 100);
	        payable(msg.sender).transfer(auction[_tokenId].highestBid * (100 - auction_token_fee) / 100);
	        pending_claim[auction[_tokenId].highestBidder][_tokenId] = 0;
	    }
	    else{
	        payable(msg.sender).transfer(pending_claim[msg.sender][_tokenId]);
    		pending_claim[msg.sender][_tokenId] = 0;
	    }
	}
	
	/// @dev Returns auction info for an NFT on auction.
    /// @param _tokenId - ID of NFT on auction.
	function getAuction(uint _tokenId) public view virtual returns(AuctionDetails memory){
	    return auction[_tokenId];
	}

	/// @dev Returns auction info for an NFT on auction.
    /// @param _tokenId - ID of NFT on auction.
	function getPending_claim(address _user, uint _tokenId) public view virtual returns(uint){
	    return pending_claim[_user][_tokenId];
	}
	
	/// @dev Returns sell NFT token price.
	/// @param _tokenId - ID of NFT.
	function getSellTokenPrice(uint _tokenId) public view returns(uint){
	    return token_price[_tokenId];
	}
	
	/// @dev Buy from open sell.
	/// Transfer NFT ownership to buyer address.
	/// @param _tokenId - ID of NFT on buy.
	function buy(uint _tokenId) public payable  {
		require(token_seller[_tokenId]!= address(0) && token_price[_tokenId] > 0, "Token not for sell");
	     require(msg.value >= token_price[_tokenId], "Your amount is less");
	     nft_token.transferFrom(address(this), msg.sender, _tokenId);
	     payable(beneficiary).transfer(msg.value * sell_token_fee / 100);
	     payable(token_seller[_tokenId]).transfer(msg.value * (100 - sell_token_fee) / 100);
		 delete token_seller[_tokenId];
	     delete token_price[_tokenId];
	     emit Buy(msg.sender, _tokenId, token_seller[_tokenId], msg.value, block.timestamp);
    }
        
	/// @dev Creates a new sell.
	/// Transfer NFT ownership to this contract.
	/// @param _tokenId - ID of NFT on sell.
	/// @param _price   - Seller set the price (in eth) of token.
	function sell(uint _tokenId, uint _price) public {
	     require(msg.sender == nft_token.ownerOf(_tokenId), "You are not owner");
	     require(nft_token.getApproved(_tokenId) == address(this), "Token not approved");
	     token_price[_tokenId] = _price;
		 token_seller[_tokenId] = msg.sender;
         nft_token.transferFrom(msg.sender, address(this), _tokenId);
	     emit Sell(msg.sender, _tokenId, _price, block.timestamp);
	}   
	
	/// @dev Removes token from the list of open sell.
	/// Returns the NFT to original owner.
	/// @param _tokenId - ID of NFT on sell.
	function cancelSell(uint _tokenId) public {
	     require(msg.sender == token_seller[_tokenId], "You are not owner");
	     nft_token.transferFrom(address(this), msg.sender, _tokenId);
	     delete token_seller[_tokenId];
	     delete token_price[_tokenId];
	     emit SellCancelled(msg.sender, _tokenId, block.timestamp);
	}
	
	/// @dev Removes an auction from the list of open auctions.
	/// Returns the NFT to original owner.
	/// @param _tokenId - ID of NFT on auction.
	function cancelAuction(uint _tokenId) public {
	    require(msg.sender == token_seller[_tokenId], "You are not owner");
	    require(auction[_tokenId].endTime > block.timestamp, "Can't cancel this auction");
	    nft_token.transferFrom(address(this), msg.sender, _tokenId);
	    delete auction[_tokenId];
	    delete token_seller[_tokenId];
	    emit AuctionCancelled(msg.sender, _tokenId, block.timestamp);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}