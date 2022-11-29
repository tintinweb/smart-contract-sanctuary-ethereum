// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ISwapper.sol";

error NotListed(uint256 tokenId);
error AlreadyListed(uint256 tokenId);
error NotOwner();
error NotApprovedForMarketplace();
error LifetimeEnded();
error DurationMaximumExceeded();
error PriceMinimumNotMet();
error InvalidSignatureLength();
error InvalidSignature();
error CollectionNotAllowed();
error ArraysLengthNotMatching();
error AuctionNotEnded();
error NotForAuction();
error ArrayEmpty();

contract Marketplace is OwnableUpgradeable, PausableUpgradeable {
    struct Listing {
        uint256 price;
        address seller;
        uint256 endTime;
        uint256 creationTime;
    }

    struct Offer {
        uint256 price;
        address buyer;
        uint256 endTime;
    }

    struct Auction {
        uint256 minPrice;
        address seller;
        uint256 endTime;
        Offer highestOffer;
    }

    struct NFTtrade {
        address buyer;

        address[] collections;
        uint256[] tokenIds;

        uint256 tokenAmount;

        uint256 endTime;
    }

    mapping(address => bool) public allowedNFTs;                                // allowed NFTs collections to be sold in this marketplace
    uint256 public listingMaxDuration;
    uint256 public listingMinPrice;
    ISwapper public swapper;                                                    // swapper used for payment

    mapping(address => mapping(uint256 => bool)) public listed;                 // listed NFTs
    mapping(address => mapping(uint256 => Listing)) public listings;            // listings for each NFT

    mapping(address => mapping(uint256 => Offer[])) public offers;              //offers for each tokenId

    mapping(address => mapping(uint256 => bool)) public auctioned;               //nft for auction
    mapping(address => mapping(uint256 => Auction)) public auctions;             //auctions for each tokenId

    mapping(address => mapping(uint256 => NFTtrade[])) public trades;            //trades offers for each tokenId

    event ItemListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price,
        uint256 endTime
    );

    event ItemCanceled(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    event ItemBought(
        address indexed buyer, 
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    event NewOffer(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 offerId,
        uint256 price,
        uint256 endTime
    );

    event OfferCanceled(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 offerId
    );

    event OfferAccepted(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 offerId,
        uint256 price
    );

    event NewAuction(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 minPrice,
        uint256 endTime
    );

    event NewBid(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    event NewNFTTradeOffer(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 offerId,
        uint256 endTime
    );

    event NFTTradeOfferCanceled(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 offerId
    );

    event NFTTradeOfferAccepted(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 offerId
    );

    modifier onlyListed(address _nftAddress, uint256 _tokenId){
        if(!listed[_nftAddress][_tokenId]){
            revert NotListed(_tokenId);
        }
        _;
    }

    modifier onlyOwnerOfNFT(address _nftAddress, uint256 _tokenId){
        if(IERC721(_nftAddress).ownerOf(_tokenId) != tx.origin){
            revert NotOwner();
        }
        _;
    }

    modifier onlyOwnerOfListing(address _nftAddress, uint256 _tokenId){
        if(listings[_nftAddress][_tokenId].seller != tx.origin){
            revert NotOwner();
        }
        _;
    }

    modifier checkPrice(uint256 _price){
        if(_price < listingMinPrice){
            revert PriceMinimumNotMet();
        }
        _;
    }

    modifier checkDuration(uint256 _duration){
        if(_duration > listingMaxDuration){
            revert DurationMaximumExceeded();
        }
        _;
    }

    modifier onlyAuctioned(address _nftAddress, uint256 _tokenId){
        if(!auctioned[_nftAddress][_tokenId]){
            revert NotForAuction();
        }
        _;
    }

    modifier checkApprovedMarketplace(address _nftAddress, uint256 _tokenId){
        IERC721 nft = IERC721(_nftAddress);
        if (!nft.isApprovedForAll(msg.sender, address(this)) && nft.getApproved(_tokenId) != address(this)) {
            revert NotApprovedForMarketplace();
        }
        _;
    }

    modifier onlyAllowedNFT(address _nftAddress){
        if(!allowedNFTs[_nftAddress]){
            revert CollectionNotAllowed();
        }
        _;
    }

    /**
     * @notice Initialize the contract
     * @param _nftAddresses Array of NFT addresses
     * @param _swapperAddress Address of the swapper used for payment
     * @param _multisig Address of the multisig owning the contract
     * @dev equivalent to constructor but for proxied contracts
     */
    function initialize(address[] calldata _nftAddresses, address _swapperAddress, address _multisig) public initializer {
        __Ownable_init();
        __Pausable_init();

        for(uint256 i = 0; i < _nftAddresses.length;){
            allowedNFTs[_nftAddresses[i]] = true;

            unchecked {
                ++i;
            }
        }

        listingMaxDuration = 6 * 30 days;    // 6 months
        listingMinPrice = 0 ether;
        swapper = ISwapper(_swapperAddress);

        transferOwnership(_multisig);
    }

    /**
     * @notice Method for listing multiples NFTs
     * @param _nftAddress Address of the NFT
     * @param _tokensIds Tokens IDs of NFT
     * @param _prices sale price for each item
     * @param _numberOfSeconds duration of listings
     */
    function batchListItem(
        address _nftAddress,
        uint256[] calldata _tokensIds,
        uint256[] calldata _prices,
        uint256[] calldata _numberOfSeconds
    )
        external
    {
        if(_tokensIds.length != _prices.length || _numberOfSeconds.length != _tokensIds.length){
            revert ArraysLengthNotMatching();
        }

        for(uint256 i = 0; i < _tokensIds.length;){
            listItem(_nftAddress, _tokensIds[i], _prices[i], _numberOfSeconds[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Method for listing NFT
     * @param _nftAddress Address of the NFT
     * @param _tokenId Token ID of NFT
     * @param _price sale price for each item
     * @param _numberOfSeconds duration of listing
     * @dev Any call to this should be nonReentrant
     */
    function listItem(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _price,
        uint256 _numberOfSeconds
    )
        public
        onlyAllowedNFT(_nftAddress)
        onlyOwnerOfNFT(_nftAddress, _tokenId)
        checkPrice(_price)
        checkDuration(_numberOfSeconds)
        checkApprovedMarketplace(_nftAddress, _tokenId)
        whenNotPaused 
    {
        if(listed[_nftAddress][_tokenId]){
            revert AlreadyListed(_tokenId);
        }

        listings[_nftAddress][_tokenId] = Listing(_price, msg.sender, block.timestamp + _numberOfSeconds, block.timestamp);
        listed[_nftAddress][_tokenId] = true;

        emit ItemListed(msg.sender, _nftAddress, _tokenId, _price, block.timestamp + _numberOfSeconds);
    }

    /**
     * @notice edit listing price
     * @param _nftAddress Address of the NFT
     * @param _tokenId NFT token id
     * @param _newPrice new price
     * @param _newDuration new duration
     */
    function editListing(address _nftAddress, uint256 _tokenId, uint256 _newPrice, uint256 _newDuration) external  
        onlyListed(_nftAddress, _tokenId) 
        onlyOwnerOfListing(_nftAddress, _tokenId) 
        checkPrice(_newPrice)
        checkDuration(_newDuration)
        whenNotPaused 
    {
        listings[_nftAddress][_tokenId].price = _newPrice;
        listings[_nftAddress][_tokenId].endTime = block.timestamp + _newDuration;
        listings[_nftAddress][_tokenId].creationTime = block.timestamp;

        emit ItemListed(msg.sender, _nftAddress, _tokenId, _newPrice, block.timestamp + _newDuration);
    }

    /**
     * @notice Cancelling multiple listed NFT
     * @param _nftAddress Address of the NFT
     * @param _tokensIds NFT tokens ids
     */
    function batchCancelListing(address _nftAddress, uint256[] calldata _tokensIds) external {
        for(uint256 i = 0; i < _tokensIds.length;){
            cancelListing(_nftAddress, _tokensIds[i]);

            unchecked {
                ++i;
            }
        }
    }

     /**
     * @notice Cancelling a listed NFT
     * @param _nftAddress Address of the NFT
     * @param _tokenId NFT token id
     */
    function cancelListing(address _nftAddress, uint256 _tokenId) public 
        onlyListed(_nftAddress, _tokenId) 
        onlyOwnerOfListing(_nftAddress, _tokenId)
        whenNotPaused 
    {
        listed[_nftAddress][_tokenId] = false;
        delete listings[_nftAddress][_tokenId];

        emit ItemCanceled(msg.sender, _nftAddress, _tokenId);
    }

    /**
     * @notice Buying a listed NFT
     * @param _nftAddress Address of the NFT
     * @param _tokenId NFT token id
     * @param _token token to pay with
     * @dev The NFT is transferred to the buyer and the seller receives the price minus the royalties.
     * @dev The owner of an NFT could unapprove the marketplace, which would cause this function to fail
     */
    function buyListedItem(address _nftAddress, uint256 _tokenId, address _token) external {
        _buyListedItem(_nftAddress, _tokenId, listings[_nftAddress][_tokenId].price, _token);
    }

    /**
     * @notice Buying multiple listed NFT
     * @param _nftAddress Address of the NFT
     * @param _tokensIds NFT token id
     * @param _token token to pay with
     * @dev The NFT is transferred to the buyer and the seller receives the price minus the royalties.
     * @dev The owner of an NFT could unapprove the marketplace, which would cause this function to fail
     */
    function batchBuyListedItem(address _nftAddress, uint256[] calldata _tokensIds, address _token) external {
        for(uint256 i = 0; i < _tokensIds.length;){
            _buyListedItem(_nftAddress, _tokensIds[i], listings[_nftAddress][_tokensIds[i]].price, _token);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Buying a listed NFT
     * @param _nftAddress Address of the NFT
     * @param _tokenId NFT token id
     * @param _price price to buy the NFT
     * @param _signature signature of the seller (allowing to check if price have been lowered)
     * @param _token token to pay with
     * @dev The NFT is transferred to the buyer and the seller receives the price minus the royalties.
     * @dev The owner of an NFT could unapprove the marketplace, which would cause this function to fail
     */
    function buyListedItemWithLowerPrice(address _nftAddress, uint256 _tokenId, uint256 _price, uint256 _creationTime, bytes memory _signature, address _token) external {
        bytes32 ethSignedMessageHash = keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(listings[_nftAddress][_tokenId].seller, _nftAddress, _tokenId, _price, _creationTime)))
            );

        if(recoverSigner(ethSignedMessageHash, _signature) != listings[_nftAddress][_tokenId].seller || _creationTime != listings[_nftAddress][_tokenId].creationTime){
            revert InvalidSignature();
        }

        _buyListedItem(_nftAddress, _tokenId, _price, _token);
    }

    /**
     * @notice Buying multiple listed NFT
     * @param _nftAddress Address of the NFT
     * @param _tokensIds NFT token id
     * @param _prices price to buy the NFT
     * @param _creationTime listing creation time
     * @param _signature signature of the seller (allowing to check if price have been lowered)
     * @param _token token to pay with
     * @dev The NFT is transferred to the buyer and the seller receives the price minus the royalties.
     * @dev The owner of an NFT could unapprove the marketplace, which would cause this function to fail
     */
    function batchBuyListedItemWithLowerPrice(address _nftAddress, uint256[] calldata _tokensIds, 
        uint256[] calldata _prices, uint256[] calldata _creationTime, bytes[] calldata _signature, address _token) external 
    {
        if(_tokensIds.length != _prices.length || _creationTime.length != _tokensIds.length || _signature.length != _tokensIds.length){
            revert ArraysLengthNotMatching();
        }

        for(uint i = 0; i < _tokensIds.length;){
            bytes32 ethSignedMessageHash = keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", 
                keccak256(abi.encodePacked(listings[_nftAddress][_tokensIds[i]].seller, _nftAddress, _tokensIds[i], _prices[i], _creationTime[i])))
            );

            if(recoverSigner(ethSignedMessageHash, _signature[i]) != listings[_nftAddress][_tokensIds[i]].seller || _creationTime[i] != listings[_nftAddress][_tokensIds[i]].creationTime){
                revert InvalidSignature();
            }

            _buyListedItem(_nftAddress, _tokensIds[i], _prices[i], _token);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Buying a listed NFT
     * @param _nftAddress Address of the NFT
     * @param _tokenId NFT token id
     * @param _price price to buy the NFT
     * @param _token token used for payment
     * @dev The NFT is transferred to the buyer and the seller receives the price minus the royalties.
     * @dev The owner of an NFT could unapprove the marketplace, which would cause this function to fail
     * @dev Internal function: any external call should apply nonReentrant modifier
     */
    function _buyListedItem(address _nftAddress, uint256 _tokenId, uint256 _price, address _token) internal onlyListed(_nftAddress, _tokenId) whenNotPaused {
        Listing memory listedItem = listings[_nftAddress][_tokenId];

        if (block.timestamp > listedItem.endTime)
            revert LifetimeEnded();

        listed[_nftAddress][_tokenId] = false;
        delete listings[_nftAddress][_tokenId];
        
        if(_token == swapper.baseToken()){
            swapper.checkCanOffer(msg.sender, _price);
            swapper.executePayment(_price, msg.sender, listedItem.seller);
        }
        else{
            swapper.swapAndPay(_token, _price, msg.sender, listedItem.seller);
        }

        IERC721(_nftAddress).safeTransferFrom(listedItem.seller, msg.sender, _tokenId);

        emit ItemBought(msg.sender, _nftAddress, _tokenId, _price);
    }

    /**
     * @notice Method for placing a bid
     * @param _nftAddress Address of the NFT
     * @param _tokenId Token ID of NFT
     * @param _price bid price
     * @param _duration duration of bid (in seconds)
     * @dev bid value is extracted from the transaction value
     */
    function createOffer(address _nftAddress, uint256 _tokenId, uint256 _price, uint256 _duration) public 
        onlyAllowedNFT(_nftAddress)
        checkDuration(_duration)
        checkPrice(_price)
        whenNotPaused  
    {
        swapper.checkCanOffer(msg.sender, _price);
        
        Offer memory newOffer = Offer(_price, msg.sender, block.timestamp + _duration);
        offers[_nftAddress][_tokenId].push(newOffer);

        uint256 offerId = offers[_nftAddress][_tokenId].length - 1;

        emit NewOffer(msg.sender, _nftAddress, _tokenId, offerId, _price, block.timestamp + _duration);
    }

    /**
     * @notice Method for placing multiple offers
     * @param _nftAddress Address of the NFT
     * @param _tokensIds Token ID of NFT
     * @param _prices offers prices
     * @param _durations duration of bid (in seconds)
     */
    function batchCreateOffer(address _nftAddress, uint256[] calldata _tokensIds, uint256[] calldata _prices, uint256[] calldata _durations) external 
    {
        if(_tokensIds.length != _prices.length || _durations.length != _tokensIds.length){
            revert ArraysLengthNotMatching();
        }
        for(uint256 i = 0; i < _tokensIds.length;){
            createOffer(_nftAddress, _tokensIds[i], _prices[i], _durations[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Method for cancelling an offer
     * @param _nftAddress Address of the NFT
     * @param _tokenId Token ID of NFT
     * @param _offerIndex Offer index in the offers lists
     */
    function cancelOffer(address _nftAddress, uint256 _tokenId, uint256 _offerIndex) public 
        whenNotPaused 
    {
        if(offers[_nftAddress][_tokenId][_offerIndex].buyer != msg.sender){
            revert NotOwner();
        }

        offers[_nftAddress][_tokenId][_offerIndex] = offers[_nftAddress][_tokenId][offers[_nftAddress][_tokenId].length - 1];
        offers[_nftAddress][_tokenId].pop();

        emit OfferCanceled(msg.sender, _nftAddress, _tokenId, _offerIndex);
    }

    /**
     * @notice Method for cancelling multiple offers
     * @param _nftAddress Address of the NFT
     * @param _tokensIds Token ID of NFT
     * @param _offerIndexes Offer indexes in the offers lists
     */
    function batchCancelOffer(address _nftAddress, uint256[] calldata _tokensIds, uint256[] calldata _offerIndexes) external
    {
        if(_tokensIds.length != _offerIndexes.length){
            revert ArraysLengthNotMatching();
        }

        for(uint256 i = 0; i < _tokensIds.length;){
            cancelOffer(_nftAddress, _tokensIds[i], _offerIndexes[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Method for accepting a bid
     * @param _nftAddress Address of the NFT
     * @param _tokenId Token ID of NFT
     * @param _offerIndex index of the offer
     * @dev this ends the auction and deletes it
     */
    function acceptOffer(address _nftAddress, uint256 _tokenId, uint256 _offerIndex) external 
        onlyOwnerOfNFT(_nftAddress, _tokenId)
        checkApprovedMarketplace(_nftAddress, _tokenId)
        whenNotPaused 
    {
        if(offers[_nftAddress][_tokenId][_offerIndex].endTime < block.timestamp){
            revert LifetimeEnded();
        }

        address buyer = offers[_nftAddress][_tokenId][_offerIndex].buyer;
        uint256 price = offers[_nftAddress][_tokenId][_offerIndex].price;

        swapper.checkCanOffer(buyer, price);

        delete offers[_nftAddress][_tokenId];

        IERC721(_nftAddress).safeTransferFrom(msg.sender, buyer, _tokenId);

        swapper.executePayment(price, buyer, msg.sender);

        emit OfferAccepted(buyer, _nftAddress, _tokenId, _offerIndex, price);
    }

    /**
     * @notice create a new auction
     * @param _nftAddress Address of the NFT
     * @param _tokenId Token ID of NFT
     * @param _price minimum bid price
     * @param _duration duration of auction (in seconds)
     * @dev Can't be cancelled !
     */
    function createAuction(address _nftAddress, uint256 _tokenId, uint256 _price, uint256 _duration) external 
        onlyAllowedNFT(_nftAddress)
        onlyOwnerOfNFT(_nftAddress, _tokenId)
        checkDuration(_duration)
        checkApprovedMarketplace(_nftAddress, _tokenId)
        checkPrice(_price)
        whenNotPaused 
    {
        if(auctioned[_nftAddress][_tokenId]){
            revert AuctionNotEnded();
        }

        Auction memory newAuction = auctions[_nftAddress][_tokenId];
        newAuction.minPrice = _price;
        newAuction.seller = msg.sender;
        newAuction.endTime = block.timestamp + _duration;
        auctions[_nftAddress][_tokenId] = newAuction;
        auctioned[_nftAddress][_tokenId] = true;

        emit NewAuction(msg.sender, _nftAddress, _tokenId, _price, block.timestamp + _duration);
    }

    /**
     * @notice Method for placing a bid
     * @param _nftAddress Address of the NFT
     * @param _tokenId Token ID of NFT
     * @param _price bid price
     */
    function bid(address _nftAddress, uint256 _tokenId, uint256 _price) external 
        onlyAuctioned(_nftAddress, _tokenId)
        whenNotPaused 
    {
        Auction memory auction = auctions[_nftAddress][_tokenId];
        if(auction.endTime <= block.timestamp){
            revert LifetimeEnded();
        }

        if(auction.highestOffer.buyer != address(0)){
            if(_price <= auction.highestOffer.price){
                revert PriceMinimumNotMet();
            }
            
            swapper.releaseAuctionPaymentLoser(auction.highestOffer.price, auction.highestOffer.buyer);
        }
        else {
            if(_price < auction.minPrice){
                revert PriceMinimumNotMet();
            }

            auction.highestOffer.endTime = auction.endTime;
        }

        swapper.checkCanOffer(msg.sender, _price);
        swapper.holdAuctionPayment(_price, msg.sender);

        auctions[_nftAddress][_tokenId].highestOffer.buyer = msg.sender;
        auctions[_nftAddress][_tokenId].highestOffer.price = _price;

        emit NewBid(msg.sender, _nftAddress, _tokenId, _price);
    }
    
    /**
     * @notice Method for recovering the NFT when the auction is over
     * @param _nftAddress Address of the NFT
     * @param _tokenId Token ID of NFT
     * @dev this ends the auction and deletes it
     * @dev everyone can call this method
     */
    function recoverAuction(address _nftAddress, uint256 _tokenId) external 
        onlyAuctioned(_nftAddress, _tokenId)
        whenNotPaused 
    {
        Auction memory auction = auctions[_nftAddress][_tokenId];

        if(auction.endTime > block.timestamp){
            revert AuctionNotEnded();
        }

        if(auction.highestOffer.buyer != address(0)){
            IERC721(_nftAddress).safeTransferFrom(auction.seller, auction.highestOffer.buyer, _tokenId);
            swapper.releaseAuctionPaymentWinner(auction.highestOffer.price, auction.seller);        
        }

        auctioned[_nftAddress][_tokenId] = false;
        delete auctions[_nftAddress][_tokenId];
    }

    /**
     * @notice creates a new trade offer
     * @param _collection Address of the NFT
     * @param _tokenId Token ID of NFT
     * @param _proposedCollections proposed collections to trade from
     * @param _proposedTokensIds proposed token IDs to trade from
     * @param _tokenAmount proposed base token amount in addition to NFTs
     * @param _duration duration of the offer (in seconds)
     */
    function createTradeOffer(address _collection, uint256 _tokenId, address[] calldata _proposedCollections, uint256[] calldata _proposedTokensIds, 
        uint256 _tokenAmount, uint256 _duration) external whenNotPaused onlyAllowedNFT(_collection) checkDuration(_duration)
    {
        if(_proposedCollections.length != _proposedTokensIds.length){
            revert ArraysLengthNotMatching();
        }

        if(_proposedCollections.length == 0){
            revert ArrayEmpty();
        }

        uint256 endTime = block.timestamp + _duration;

        trades[_collection][_tokenId].push(NFTtrade(msg.sender, _proposedCollections, _proposedTokensIds, _tokenAmount, endTime));
        uint256 tradeIndex = trades[_collection][_tokenId].length - 1;
        
        emit NewNFTTradeOffer(msg.sender, _collection, _tokenId, tradeIndex, endTime);
    }

    /**
     * @notice Method for cancelling a trade offer
     * @param _collection Address of the NFT
     * @param _tokenId Token ID of NFT
     * @param _tradeOfferId Offer index in the nft trades offers lists
     */
    function cancelTradeOffer(address _collection, uint256 _tokenId, uint256 _tradeOfferId) external whenNotPaused {
        if(trades[_collection][_tokenId][_tradeOfferId].buyer != msg.sender){
            revert NotOwner();
        }

        trades[_collection][_tokenId][_tradeOfferId] = trades[_collection][_tokenId][trades[_collection][_tokenId].length - 1];
        trades[_collection][_tokenId].pop();

        emit NFTTradeOfferCanceled(msg.sender, _collection, _tokenId, _tradeOfferId);
    }

    /**
     * @notice Method for accepting a trade offer
     * @param _collection Address of the NFT
     * @param _tokenId Token ID of NFT
     * @param _tradeOfferId Offer index in the nft trades offers lists
     */
    function acceptTradeOffer(address _collection, uint256 _tokenId, uint256 _tradeOfferId) external whenNotPaused 
        onlyOwnerOfNFT(_collection, _tokenId) 
    {
        NFTtrade memory trade = trades[_collection][_tokenId][_tradeOfferId];

        if(trade.endTime <= block.timestamp){
            revert LifetimeEnded();                 //also reverts if there is no offer
        }

        for(uint256 i = 0; i < trade.collections.length; i++){
            IERC721(trade.collections[i]).safeTransferFrom(trade.buyer, msg.sender, trade.tokenIds[i]);
        }

        IERC721(_collection).safeTransferFrom(msg.sender, trade.buyer, _tokenId);

        if(trade.tokenAmount > 0){
            swapper.executePayment(trade.tokenAmount, trade.buyer, msg.sender);
        }

        trades[_collection][_tokenId][_tradeOfferId] = trades[_collection][_tokenId][trades[_collection][_tokenId].length - 1];
        trades[_collection][_tokenId].pop();

        emit NFTTradeOfferAccepted(msg.sender, _collection, _tokenId, _tradeOfferId);
    }

    /**
     * @notice Allows the owner to set the max duration for a listing
     * @param _listingMaxDuration The new max duration
     * @dev Can only be called by the owner
     */
    function setListingMaxDuration(uint256 _listingMaxDuration) external onlyOwner {
        listingMaxDuration = _listingMaxDuration;
    }

    /**
     * @notice Allows the owner to set the minimum price for a listing
     * @param _listingMinPrice The new min price
     * @dev Can only be called by the owner
     */
    function setListingMinPrice(uint256 _listingMinPrice) external onlyOwner {
        listingMinPrice = _listingMinPrice;
    }

    /**
     * @notice Allows owner to allow or disallow NFTs to be sold in this shop
     * @param _nftAddresses NFT addresses list
     * @param _allowed true to allow, false to disallow (for all address)
     * @dev Can only be called by the owner
     */
    function setAllowedNFTs(address[] calldata _nftAddresses, bool _allowed) external onlyOwner {
        for (uint256 i = 0; i < _nftAddresses.length;) {
            allowedNFTs[_nftAddresses[i]] = _allowed;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Allows pause of the contract
     * @dev Can only be called by the owner
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Allows unpause of the contract
     * @dev Can only be called by the owner
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Allows receiving ETH
     * @dev Called automatically
     */
    receive() external payable {
        payable(address(swapper)).transfer(msg.value);      
    }
    
    /**
     * @notice Allows owners to recover NFT sent to the contract by mistake
     * @param _token: NFT token address
     * @param _tokenId: tokenId
     * @dev Callable by owner
     */
    function recoverNonFungibleToken(address _token, uint256 _tokenId) external onlyOwner {
        IERC721(_token).transferFrom(address(this), address(msg.sender), _tokenId);
    }

    /**
     * @notice Allows owners to recover tokens sent to the contract by mistake
     * @param _token: token address
     * @dev Callable by owner
     */
    function recoverToken(address _token) external onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(balance != 0, "Operations: Cannot recover zero balance");

        IERC20(_token).transferFrom(address(this), address(msg.sender), balance);
    }

    /**
     * @notice Compute public key of signed message 
     * @param _hash: hash of the signed message
     * @param _signature: signature of _hash with the private key of the signer
     */
    function recoverSigner(bytes32 _hash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_hash, v, r, s);
    }

    /**
     * @notice Split signature into r, s and v variables
     * @param _sig: signature
     */
    function splitSignature(bytes memory _sig)
        public
        pure
        returns (bytes32 r, bytes32 s, uint8 v)
    {
        if(_sig.length != 65){
            revert InvalidSignatureLength();
        }

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(_sig, 32))
            // second 32 bytes
            s := mload(add(_sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(_sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    /**
     * @notice Compute active offers for an NFT
     * @param _nftAddress: NFT address
     * @param _tokenId: id of the NFT
     */
    function getOffers(address _nftAddress, uint256 _tokenId) external view returns (uint256[] memory, Offer[] memory) {
        uint256 offersNb = 0;
        for(uint256 i = 0; i < offers[_nftAddress][_tokenId].length; ++i){
            if(offers[_nftAddress][_tokenId][i].endTime >= block.timestamp){
                    ++offersNb;
            }
        }

        Offer[] memory offersActive = new Offer[](offersNb);
        uint256[] memory offersActiveIds = new uint256[](offersNb);
        uint256 index = 0;
        for(uint256 i = 0; i < offers[_nftAddress][_tokenId].length; ++i){
            if(offers[_nftAddress][_tokenId][i].endTime >= block.timestamp){
                offersActive[index] = offers[_nftAddress][_tokenId][i];
                offersActiveIds[index] = i;
                ++index;
            }
        }

        return (offersActiveIds, offersActive);
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ISwapper {
    function baseToken() external view returns (address);

    function executePayment(uint256 _amount, address _from, address _to) external;
    function holdAuctionPayment(uint256 _amount, address _from) external;
    function releaseAuctionPaymentLoser(uint256 _amount, address _to) external;
    function releaseAuctionPaymentWinner(uint256 _amount, address _to) external;
    function swapAndPay(address _tokenIn, uint256 _amountOut, address _from, address _to) external;
    function checkInputPrice(address _tokenIn, uint256 _amountOut) external returns (uint256);
    function checkCanOffer(address _buyer, uint256 _amount) external view;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.2) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.2) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
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