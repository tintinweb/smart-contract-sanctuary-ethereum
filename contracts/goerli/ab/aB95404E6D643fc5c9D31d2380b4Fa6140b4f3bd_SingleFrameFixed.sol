// Market contract
// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISingleNFT {
	function initialize(address creator, address _adminAddress) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function onAuctionApprove(address auctionAddress) external;
	function addItem(string memory _tokenURI, uint256 royalty, address sender, uint256 lazyTokenId, address marketAddress) external returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function creatorOf(uint256 _tokenId) external view returns (address);
	function royalties(uint256 _tokenId) external view returns (uint256);
}

contract SingleFrameFixed is Ownable, ERC721Holder {
    using SafeMath for uint256;

	uint256 constant public PERCENTS_DIVIDER = 100;
    uint256 constant public MIN_BID_INCREMENT_PERCENT = 3; // 3%
	uint256 public feeAdmin = 2; //2%
	address public adminAddress = 0xbA7f642d9c08047b847feb11f2a8Bb437d20B29B;//MultiVac
	//address public adminAddress = 0xbF1bAa92f99E33870f06D6D57d9AeFcadaf05763;//BSC
    address public serverAddress = 0x842C0236236BbDaC052CC2FCC943C6cb9A0e167a;

	uint256 public totalEarnedCoin = 0;
	uint256 public totalEarnedToken = 0;
	uint256 public totalSwapped; /* Total swap count */

    /* Pairs to swap NFT _id => price */
	struct Pair {
		uint256 pairId;
		address collection;
		uint256 tokenId;
		address creator;
		address owner;
		address tokenAdr;
		uint256 price;
        uint256 creatorFee;
        bool bValid;		
	}

    struct Offer {
        uint256 offerId;
        address collection;
        uint256 tokenId;
        uint256 lazyTokenId;
        address creator;
        address owner;
        address tokenAdr;
        uint256 offerPrice;
        uint256 offerAmount;
        bool active;
    }

    // AuctionBid struct to hold bidder and amount
    struct AuctionBid {
        address from;
        uint256 bidPrice;
    }

    // Auction struct which holds all the required info
    struct Auction {
        uint256 auctionId;
        address collectionId;
        uint256 tokenId;
        uint256 startTime;
        uint256 endTime;
        address tokenAdr;
		uint256 startPrice;
        address creator;
        address owner;
        bool active;       
    }

    struct LazyBid {
        uint256 lazyTokenId;
        string  tokenURI;
        uint256 royalty;
        address collectionId;
        address tokenAdr;
        uint256 startPrice;
        uint256 startTime;
        uint256 endTime;
        address sender;
        uint256 amount;
    }

    //Offer
    struct  LazyItem {
        string tokenURI;
        uint256 royalty;
        uint256 lazyTokenId;
        address collection;
    }

	address[] public collections;
	// collection address => creator address

    mapping(uint256 => Pair) public pairs;
    // token id => Offer[] mapping
    mapping(address => mapping(uint256 => Offer[])) public offers;
	uint256 public currentPairId = 0;

    // Array with all auctions
    Auction[] public auctions;
    
    // Mapping from auction index to user bids
    mapping (uint256 => AuctionBid[]) public auctionBids;
    
    // Mapping from owner to a list of owned auctions
    mapping (address => uint256[]) public ownedAuctions;
	
	/** Events */
    event SingleItemListed(uint256 pairId, Pair pair);
	event SingleItemDelisted(address collection, uint256 tokenId, uint256 pairId);
    event SingleSwapped(address buyer, uint256 lazyTokenId, Pair pair);
    event SingleLazySwapped(uint256 tokenId);
    event SingleOfferCreated(Offer offer);
    event SingleOffersCreated(Offer[] offers);
    event SingleOfferCancelled(address collection, uint256 tokenId, uint256 offerId);
    event SingleOfferAccepted(address sender, address collection, uint256 tokenId, uint256 lazyTokenId, uint256 offerId);
    event SingleLazyOfferAccepted(uint256 tokenId);
    
    event AuctionBidSuccess(address _from, Auction auction, uint256 price, uint256 _bidIndex);
    // AuctionCreated is fired when an auction is created
    event AuctionCreated(Auction auction);
    // AuctionCanceled is fired when an auction is canceled
    event AuctionCanceled(Auction auction);
    // AuctionFinalized is fired when an auction is finalized
    event AuctionFinalized(address buyer, uint256 price, Auction auction);
    event SingleLazyBidded(uint256 tokenId);

	constructor () {
	}
	
	function setFee(uint256 _feeAdmin, address _adminAddress, address _serverAddress) external onlyOwner {		
        feeAdmin = _feeAdmin;
		adminAddress = _adminAddress;
        serverAddress = _serverAddress;
    }

    function singleList(address _collection, uint256 _tokenId, address _tokenAdr, uint256 _price, uint256 pairId) OnlyItemOwner(_collection,_tokenId) public {
		onSingleList(_collection, _tokenId, _tokenAdr, _price, msg.sender, pairId);
    }

	function onSingleList(address _collection, uint256 _tokenId, address _tokenAdr, uint256 _price, address sender, uint256 _pairId) internal returns (uint256) {
		require(_price > 0, "invalid price");	
		ISingleNFT nft = ISingleNFT(_collection);        
        //nft.safeTransferFrom(sender, address(this), _tokenId);

		currentPairId = currentPairId.add(1);
		pairs[currentPairId].pairId = currentPairId;
		pairs[currentPairId].collection = _collection;
		pairs[currentPairId].tokenId = _tokenId;
		pairs[currentPairId].creator = nft.creatorOf(_tokenId);
        pairs[currentPairId].owner = sender;
		pairs[currentPairId].tokenAdr = _tokenAdr;		
		pairs[currentPairId].price = _price;	
        pairs[currentPairId].creatorFee = nft.royalties(_tokenId);
		pairs[currentPairId].bValid = true;	

        emit SingleItemListed(_pairId, pairs[currentPairId]);

		return currentPairId;
	}

    function singleDelist(uint256 _id) external {        
        require(pairs[_id].bValid, "not exist");
        require(msg.sender == pairs[_id].owner || msg.sender == owner(), "Error, you are not the owner");        
        //ISingleNFT(pairs[_id].collection).safeTransferFrom(address(this), pairs[_id].owner, pairs[_id].tokenId);        
        pairs[_id].bValid = false;
        emit SingleItemDelisted(pairs[_id].collection, pairs[_id].tokenId, _id);        
    }

	function singleBuy(uint256 _id, uint256 lazyTokenId) public payable {
		singleBuy(_id, lazyTokenId, msg.sender);
	}

    function singleBuy(uint256 _id, uint256 lazyTokenId, address sender) internal {
		require(_id <= currentPairId && pairs[_id].pairId == _id, "Could not find item");
        require(pairs[_id].bValid, "Invalid Pair Id");
		require(pairs[_id].owner != sender, "Owner can not buy");
        require(pairs[_id].price <= msg.value, "Invalid NFT Price");

		Pair memory pair = pairs[_id];
		uint256 totalAmount = pair.price;
		uint256 feeAmount = totalAmount.mul(feeAdmin).div(PERCENTS_DIVIDER);
		uint256 createrAmount = totalAmount.mul(pair.creatorFee).div(PERCENTS_DIVIDER);
		uint256 ownerAmount = totalAmount.sub(feeAmount).sub(createrAmount);

		if (pairs[_id].tokenAdr == address(0x0)) {
            require(msg.value >= totalAmount, "too small amount");

			if (feeAmount > 0)payable(adminAddress).transfer(feeAmount);
			if (createrAmount > 0)payable(pair.creator).transfer(createrAmount);
			payable(pair.owner).transfer(ownerAmount);
			totalEarnedCoin = totalEarnedCoin + feeAmount;
        } else {
            IERC20 governanceToken = IERC20(pairs[_id].tokenAdr);

			require(governanceToken.transferFrom(sender, address(this), totalAmount), "insufficient token balance");
			
			// transfer governance token to feeAddress
			if (feeAmount > 0)require(governanceToken.transfer(adminAddress, feeAmount));			
			// transfer governance token to creator
			if (createrAmount > 0)require(governanceToken.transfer(pair.creator, createrAmount));			
			// transfer governance token to owner
			require(governanceToken.transfer(pair.owner, ownerAmount));
			totalEarnedToken = totalEarnedToken + feeAmount;
		
        }
		
		// transfer NFT token to buyer
		//ISingleNFT(pairs[_id].collection).safeTransferFrom(address(this), msg.sender, pair.tokenId);
		ISingleNFT(pairs[_id].collection).safeTransferFrom(pair.owner, sender, pair.tokenId);
		
		pairs[_id].bValid = false;		
		totalSwapped = totalSwapped.add(1);
        emit SingleSwapped(sender, lazyTokenId, pair);		
    }

	function lazySingleBuy(uint256 lazyTokenId, string memory _tokenURI, uint256 royalty, address _collection, address _tokenAdr, uint256 _price, address sender, uint256 pairId) external payable{
		ISingleNFT nft = ISingleNFT(_collection);
		uint256 tokenId = nft.addItem(_tokenURI, royalty, sender, lazyTokenId, address(this));
		uint256 _id = onSingleList(_collection, tokenId, _tokenAdr, _price, sender, pairId);
		singleBuy(_id, lazyTokenId, msg.sender);
        emit SingleLazySwapped(tokenId);
	}

    function onMakeOffer(address _collectionId, uint256 _tokenId, address tokenAdr, uint256 _offerPrice ) external{
        require(tokenAdr != address(0x0), "Offer should be with wrapping token");
        ISingleNFT nft = ISingleNFT(_collectionId);
        uint256 offerId = offers[_collectionId][_tokenId].length;
        Offer memory newOffer;
        newOffer.offerId = offerId;
        newOffer.collection = _collectionId;
        newOffer.tokenId = _tokenId;
        newOffer.lazyTokenId = 0;
        newOffer.creator = nft.creatorOf(_tokenId);
        newOffer.owner = msg.sender;
        newOffer.tokenAdr = tokenAdr;
        newOffer.offerPrice = _offerPrice;
        newOffer.offerAmount = 1;
        newOffer.active = true;
        offers[_collectionId][_tokenId].push(newOffer);
        emit SingleOfferCreated(newOffer);
    }

    function onCancelOffer(address _collectionId, uint256 _tokenId, uint256 _offerId ) external{
        require(_offerId <= offers[_collectionId][_tokenId].length && offers[_collectionId][_tokenId][_offerId].offerId == _offerId, "Could not find offer");
        Offer memory offer = offers[_collectionId][_tokenId][_offerId];
        require(offer.active, "Not Exist");
        require(offer.owner == msg.sender, "Only Offer Maker can cancel.");
        offer.active = false;
        emit SingleOfferCancelled(_collectionId, _tokenId, _offerId);
    }

    function onAcceptOffer(address _collectionId, uint256 _tokenId, uint256 _lazyTokenId, uint256 _offerId, uint256 _pairId, uint256 _auctionId) public {
        require(_offerId <= offers[_collectionId][_tokenId].length && offers[_collectionId][_tokenId][_offerId].offerId == _offerId, "Could not find offer");
        Offer memory offer = offers[_collectionId][_tokenId][_offerId];
        require(offer.active, "Not Exist");
        ISingleNFT nft = ISingleNFT(offer.collection);
        address owner = nft.ownerOf(offer.tokenId);
        require(owner == msg.sender, "Only owner can accept the item.");
        require(offer.tokenAdr != address(0x0), "Offer should be with wrapping token");

        uint256 feeAmount = offer.offerPrice.mul(feeAdmin).div(PERCENTS_DIVIDER);
		uint256 createrAmount = offer.offerPrice.mul(nft.royalties(_tokenId)).div(PERCENTS_DIVIDER);
		uint256 ownerAmount = offer.offerPrice.sub(feeAmount).sub(createrAmount);

        IERC20 governanceToken = IERC20(offer.tokenAdr);
        require(governanceToken.balanceOf(offer.owner) >= offer.offerPrice, "The buyer's balance is insufficient.");
        // transfer governance token to feeAddress
        if (feeAmount > 0)require(governanceToken.transferFrom(offer.owner, address(this), feeAmount));			
        // transfer governance token to creator
        if (createrAmount > 0)require(governanceToken.transferFrom(offer.owner, offer.creator, createrAmount));			
        // transfer governance token to owner
        require(governanceToken.transferFrom(offer.owner, owner, ownerAmount));

        nft.safeTransferFrom(msg.sender, offer.owner, offer.tokenId);
        if(_pairId >= 0 && _pairId < 1e8){
            Pair storage pair = pairs[_pairId];
            if (pair.bValid){
                pair.bValid = false;
                emit SingleItemDelisted(offer.collection, offer.tokenId, _pairId);
            }
        }

        if (_auctionId >= 0 && _auctionId < 1e8){
            Auction storage auction = auctions[_auctionId];
            if (auction.active){
                auction.active = false;
                emit AuctionCanceled(auctions[_auctionId]);
            }
        }
        offer.active = false;
        offer.lazyTokenId = _lazyTokenId;
        offers[_collectionId][_tokenId][_offerId] = offer;
        emit SingleOfferAccepted(msg.sender, offer.collection, offer.tokenId, _lazyTokenId, _offerId);
    }

    function onLazyAcceptOffer(LazyItem memory lazyItem, Offer[] memory _offers, uint256 _offerId) external returns (uint256){
        ISingleNFT nft = ISingleNFT(lazyItem.collection);
        uint256 tokenId = nft.addItem(lazyItem.tokenURI, lazyItem.royalty, msg.sender, lazyItem.lazyTokenId, address(this));
        for (uint256 i = 0 ; i < _offers.length ; i++){
            _offers[i].tokenId = tokenId;
            offers[lazyItem.collection][tokenId].push(_offers[i]);
        }
        emit SingleOffersCreated(offers[lazyItem.collection][tokenId]);
        onAcceptOffer(lazyItem.collection, tokenId, lazyItem.lazyTokenId, _offerId, 1e8, 1e8);
        emit SingleLazyOfferAccepted(tokenId);
        return tokenId;
    }

	function withdrawCoin() public onlyOwner {
		uint balance = address(this).balance;
		require(balance > 0, "insufficient balance");
		payable(msg.sender).transfer(balance);
	}
	function withdrawToken(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
		uint balance = token.balanceOf(address(this));
		require(balance > 0, "insufficient balance");
		require(token.transfer(msg.sender, balance));			
	}

	modifier OnlyItemOwner(address tokenAddress, uint256 tokenId){
        ISingleNFT tokenContract = ISingleNFT(tokenAddress);
        require(tokenContract.ownerOf(tokenId) == msg.sender);
        _;
    }

    modifier ItemExists(uint256 id){
        require(id <= currentPairId && pairs[id].pairId == id, "Could not find item");
        _;
    }


    /*
     * @dev Creates an auction with the given informatin
     * @param _tokenRepositoryAddress address of the TokenRepository contract
     * @param _tokenId uint256 of the deed registered in DeedRepository
     * @param _startPrice uint256 starting price of the auction
     * @return bool whether the auction is created
     */
    function createAuction(address _collectionId, uint256 _tokenId, address _tokenAdr, uint256 _startPrice, uint256 _startTime, uint256 _endTime) 
        onlyTokenOwner(_collectionId, _tokenId) public 
    {   
        onCreateAuction(_collectionId, _tokenId, _tokenAdr, _startPrice, _startTime, _endTime, msg.sender);      
    }

    function onCreateAuction(address _collectionId, uint256 _tokenId, address _tokenAdr, uint256 _startPrice, uint256 _startTime, uint256 _endTime, address sender) internal returns(uint256) {
        require(block.timestamp < _endTime, "end timestamp have to be bigger than current time");
        
        ISingleNFT nft = ISingleNFT(_collectionId); 

        uint256 auctionId = auctions.length;
        Auction memory newAuction;
        newAuction.auctionId = auctionId;
        newAuction.collectionId = _collectionId;
        newAuction.tokenId = _tokenId;
        newAuction.startPrice = _startPrice;
        newAuction.tokenAdr = _tokenAdr;
        newAuction.startTime = _startTime;
        newAuction.endTime = _endTime;
        newAuction.owner = sender;
        newAuction.creator = nft.creatorOf(_tokenId);
        newAuction.active = true;
        
        auctions.push(newAuction);    
        ownedAuctions[sender].push(auctionId);
        
        //nft.safeTransferFrom(msg.sender, address(this), _tokenId);    
        nft.onAuctionApprove(address(this));
        emit AuctionCreated(newAuction);
        return auctionId;
    }
    
    /**
     * @dev Finalized an ended auction
     * @dev The auction should be ended, and there should be at least one bid
     * @dev On success Deed is transfered to bidder and auction owner gets the amount
     * @param _auctionId uint256 ID of the created auction
     */
    function finalizeAuction(uint256 _auctionId) public {
        Auction memory myAuction = auctions[_auctionId];
        uint256 bidsLength = auctionBids[_auctionId].length;
        require(msg.sender == myAuction.owner || msg.sender == owner() || msg.sender == serverAddress, "only auction owner can finalize");
        
        // if there are no bids cancel
        if(bidsLength == 0) {
            //ISingleNFT(myAuction.collectionId).safeTransferFrom(address(this), myAuction.owner, myAuction.tokenId);
            auctions[_auctionId].active = false;           
            emit AuctionCanceled(auctions[_auctionId]);
        }else{
            // 2. the money goes to the auction owner
            AuctionBid memory lastBid = auctionBids[_auctionId][bidsLength - 1];

            address _creator = ISingleNFT(myAuction.collectionId).creatorOf(myAuction.tokenId);
            uint256 royalty = ISingleNFT(myAuction.collectionId).royalties(myAuction.tokenId);

            // % commission cut
            uint256 _feeValue = lastBid.bidPrice.mul(feeAdmin).div(PERCENTS_DIVIDER);
            uint256 _creatorValue = lastBid.bidPrice.mul(royalty).div(PERCENTS_DIVIDER);
            uint256 _sellerValue = lastBid.bidPrice.sub(_feeValue).sub(_creatorValue);
            
            if (myAuction.tokenAdr == address(0x0)) {
                
                payable(myAuction.owner).transfer(_sellerValue);
                payable(adminAddress).transfer(_feeValue);
                payable(_creator).transfer(_creatorValue);
                totalEarnedCoin = totalEarnedCoin + _feeValue;
            } else {
                IERC20 governanceToken = IERC20(myAuction.tokenAdr);

                require(governanceToken.transfer(myAuction.owner, _sellerValue), "transfer to seller failed");
                if(_feeValue > 0) require(governanceToken.transfer(adminAddress, _feeValue));
                if(_creatorValue > 0) require(governanceToken.transfer(_creator, _creatorValue));
                totalEarnedToken = totalEarnedToken + _feeValue;
            }
            
            // approve and transfer from this contract to the bid winner 
            //ISingleNFT(myAuction.collectionId).safeTransferFrom(address(this), lastBid.from, myAuction.tokenId);		
            ISingleNFT(myAuction.collectionId).safeTransferFrom(myAuction.owner, lastBid.from, myAuction.tokenId);		
            auctions[_auctionId].active = false;

            emit AuctionFinalized(lastBid.from,lastBid.bidPrice,myAuction);
        }
    }
    
    /**
     * @dev Bidder sends bid on an auction
     * @dev Auction should be active and not ended
     * @dev Refund previous bidder if a new bid is valid and placed.
     * @param _auctionId uint256 ID of the created auction
     */

    function bidOnAuction(uint256 _auctionId, uint256 amount) external payable {
        onBidOnAuction(_auctionId, amount);
    }

    function onBidOnAuction(uint256 _auctionId, uint256 amount) internal {
        // owner can't bid on their auctions
        require(_auctionId <= auctions.length && auctions[_auctionId].auctionId == _auctionId, "Could not find item");
        Auction memory myAuction = auctions[_auctionId];
        require(myAuction.owner != msg.sender, "owner can not bid");
        require(myAuction.active, "not exist");

        // if auction is expired
        require(block.timestamp < myAuction.endTime, "auction is over");
        require(block.timestamp >= myAuction.startTime, "auction is not started");

        uint256 bidsLength = auctionBids[_auctionId].length;
        uint256 tempAmount = myAuction.startPrice;
        AuctionBid memory lastBid;

        // there are previous bids
        if( bidsLength > 0 ) {
            lastBid = auctionBids[_auctionId][bidsLength - 1];
            tempAmount = lastBid.bidPrice.mul(PERCENTS_DIVIDER + MIN_BID_INCREMENT_PERCENT).div(PERCENTS_DIVIDER);
        }

        if (myAuction.tokenAdr == address(0x0)) {
            require(msg.value >= tempAmount, "too small amount");
            require(msg.value >= amount, "too small balance");
            if( bidsLength > 0 )payable(lastBid.from).transfer(lastBid.bidPrice);
        } else {
            // check if amount is greater than previous amount  
            require(amount >= tempAmount, "too small amount");
            IERC20 governanceToken = IERC20(myAuction.tokenAdr);
            require(governanceToken.transferFrom(msg.sender, address(this), amount), "transfer to contract failed");
            if( bidsLength > 0 )require(governanceToken.transfer(lastBid.from, lastBid.bidPrice), "refund to last bidder failed");
        }
        // insert bid 
        AuctionBid memory newBid;
        newBid.from = msg.sender;
        newBid.bidPrice = amount;
        auctionBids[_auctionId].push(newBid);
        emit AuctionBidSuccess(msg.sender, myAuction, newBid.bidPrice, bidsLength);
    }

    function lazySingleBid(LazyBid memory lazyBid) external payable{
        ISingleNFT nft = ISingleNFT(lazyBid.collectionId);
		uint256 tokenId = nft.addItem(lazyBid.tokenURI, lazyBid.royalty, lazyBid.sender, lazyBid.lazyTokenId, address(this));
		uint256 auctionId = onCreateAuction(lazyBid.collectionId, tokenId, lazyBid.tokenAdr, lazyBid.startPrice, lazyBid.startTime, lazyBid.endTime, lazyBid.sender);
        onBidOnAuction(auctionId , lazyBid.amount);
        emit SingleLazyBidded(tokenId);
    }

    modifier AuctionExists(uint256 auctionId){
        require(auctionId <= auctions.length && auctions[auctionId].auctionId == auctionId, "Could not find item");
        _;
    }


    /**
     * @dev Gets the length of auctions
     * @return uint256 representing the auction count
     */
    function getAuctionsLength() public view returns(uint) {
        return auctions.length;
    }
    
    /**
     * @dev Gets the bid counts of a given auction
     * @param _auctionId uint256 ID of the auction
     */
    function getBidsAmount(uint256 _auctionId) public view returns(uint) {
        return auctionBids[_auctionId].length;
    } 
    
    /**
     * @dev Gets an array of owned auctions
     * @param _owner address of the auction owner
     */
    function getOwnedAuctions(address _owner) public view returns(uint[] memory) {
        uint[] memory ownedAllAuctions = ownedAuctions[_owner];
        return ownedAllAuctions;
    }
    
    /**
     * @dev Gets an array of owned auctions
     * @param _auctionId uint256 of the auction owner
     * @return amount uint256, address of last bidder
     */
    function getCurrentBids(uint256 _auctionId) public view returns(uint256, address) {
        uint256 bidsLength = auctionBids[_auctionId].length;
        // if there are bids refund the last bid
        if (bidsLength >= 0) {
            AuctionBid memory lastBid = auctionBids[_auctionId][bidsLength - 1];
            return (lastBid.bidPrice, lastBid.from);
        }    
        return (0, address(0));
    }
    
    /**
     * @dev Gets the total number of auctions owned by an address
     * @param _owner address of the owner
     * @return uint256 total number of auctions
     */
    function getAuctionsAmount(address _owner) public view returns(uint) {
        return ownedAuctions[_owner].length;
    }

    modifier onlyAuctionOwner(uint256 _auctionId) {
        require(auctions[_auctionId].owner == msg.sender);
        _;
    }

    modifier onlyTokenOwner(address _collectionId, uint256 _tokenId) {
        address tokenOwner = IERC721(_collectionId).ownerOf(_tokenId);
        require(tokenOwner == msg.sender);
        _;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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