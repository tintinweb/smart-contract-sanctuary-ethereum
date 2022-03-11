// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Collection.sol";
import "./Ownable.sol";


contract SecondaryMarketplace is Ownable{

    collectionNFT public token;

    struct OfferStruct {
        address offerer;
        uint256 price;
        uint256 amount;
        bool isAccepted;
    }

    struct SellStruct {
        uint256 price;
        address seller;
        uint256 amount;
        uint256 offerNo;
    }
 
    struct AuctionDetails {     
        uint256 price;    
        uint256 startTime;    
        uint256 endTime;       
        address highestBidder;      
        uint256 highestBid;
        uint256 totalBids;
        uint256 amount;
        address owner;
    }

    uint256 private tokenSellId = 0;

    uint256 private tokenAuctionId = 0;

    // Store all active sell offers  and maps them to their respective token ids
    mapping(uint256 => mapping(uint256 => OfferStruct)) public activeOffers;
   
    mapping (uint256 => SellStruct) public saleDetails;

    // Mapping token ID to their corresponding auction.
    mapping(uint256 => AuctionDetails) private auction;

    mapping (uint256 => uint256) public auctionIdTotokenId;

    mapping (uint256 => uint256) public sellIdTotokenId;

    mapping (uint256 => uint256[]) private tokenIdToSellId;
    mapping (uint256 => uint256[]) private tokenIdToAuctionId;

    mapping (address => mapping (uint256 => uint256)) public countToken;

    event NewOffer(uint256 indexed sellId, uint256 indexed tokenId, address indexed offerer, uint256 amount, uint256 price, uint256 _time);
    event OfferAccepted(uint256 indexed sellId, uint256 indexed tokenId, uint256 indexed offerNo, uint256 _time);
    event OfferReceived(uint256 indexed tokenId, uint256 indexed sellId, address indexed buyer, uint256 _amount, uint256 price, uint256 _time);

    event Sell (address indexed _seller, uint256 _tokenId, uint256 _amount, uint256 token_sell_id, uint256 _price, uint256 _time);   
    event Purchased(uint256 indexed tokenId, uint256 pricePaid, address indexed buyer, uint256 time);

    event AuctionCreated(address indexed seller, uint256 tokenId, uint256 price, uint256 startTime, uint256 endTime, uint256 amount);
    event Bid(address indexed bidder, uint256 auctionId, uint256 tokenId, uint256 price, uint256 amount, uint256 time);

    event AuctionClaimed(address indexed buyer, uint256 auctionId, uint256 price, uint256 time);
    event SellCancelled (address indexed seller, uint256 sellId, uint256 tokenId, uint256 time);
    event AuctionCancelled (address indexed owner, uint256 auctionId, uint256 tokenId, uint256 time);

    function initialize(address _token) public onlyOwner{
        require(_token != address(0), "Invalid Address");
        token = collectionNFT(_token);
    }

    function createOffer (uint256 _sellId, uint256 _price , uint256 _amount) public 
    {  
        require(saleDetails[_sellId].seller != address(0) && saleDetails[_sellId].price > 0 ,"Token not for sell");
        require(_price <= saleDetails[_sellId].price * _amount, "Your price is not less");     
        require(saleDetails[_sellId].amount >= _amount, "Your amount is greater than selling amount"); 
        saleDetails[_sellId].offerNo++;
        activeOffers[_sellId][saleDetails[_sellId].offerNo] = OfferStruct({offerer : msg.sender, price : _price, amount: _amount, isAccepted: false});
        emit NewOffer(_sellId, sellIdTotokenId[_sellId], msg.sender, _amount, _price, block.timestamp);
    }

    function acceptOffer (uint256 _sellId, uint256 _offerNo) public {
        require(saleDetails[_sellId].seller == msg.sender, "You are not owner");
        activeOffers[_sellId][_offerNo].isAccepted = true;
        emit OfferAccepted(_sellId, sellIdTotokenId[_sellId], _offerNo, block.timestamp);
    }

    function offerRecieve (uint256 _sellId, uint256 _offerNo) public payable {      
        require(activeOffers[_sellId][_offerNo].isAccepted, "Offer is not accepted");
        require(msg.sender == activeOffers[_sellId][_offerNo].offerer,"You are not offerer");
        require(msg.value >= activeOffers[_sellId][_offerNo].price * activeOffers[_sellId][_offerNo].amount,"Not enough ETH to buy");

        token.safeTransferFrom(saleDetails[_sellId].seller, msg.sender, sellIdTotokenId[_sellId], activeOffers[_sellId][_offerNo].amount, "");
        payable(saleDetails[_sellId].seller).transfer(msg.value);
        countToken[saleDetails[_sellId].seller][sellIdTotokenId[_sellId]] -= activeOffers[_sellId][_offerNo].amount;        
        emit OfferReceived(sellIdTotokenId[_sellId], _sellId, msg.sender, activeOffers[_sellId][_offerNo].amount, msg.value, block.timestamp);
        for(uint256 i = 0; i < tokenIdToSellId[sellIdTotokenId[_sellId]].length; i++){
            if(tokenIdToSellId[sellIdTotokenId[_sellId]][i] == _sellId){
                tokenIdToSellId[sellIdTotokenId[_sellId]][i] = tokenIdToSellId[sellIdTotokenId[_sellId]][tokenIdToSellId[sellIdTotokenId[_sellId]].length - 1];
                delete tokenIdToSellId[sellIdTotokenId[_sellId]][tokenIdToSellId[sellIdTotokenId[_sellId]].length - 1];
                tokenIdToSellId[sellIdTotokenId[_sellId]].pop();
            }   
        }
               
        if(saleDetails[_sellId].amount == activeOffers[_sellId][_offerNo].amount){
            delete sellIdTotokenId[_sellId];
            delete saleDetails[_sellId];  
        }else{
            saleDetails[_sellId].amount -= activeOffers[_sellId][_offerNo].amount;
        }
        delete activeOffers[_sellId][_offerNo];
        
    } 

    function sell (uint256 _tokenId, uint256 _price, uint256 _amount) public {
        require(token.balanceOf(msg.sender, _tokenId) >= _amount, "You are not owner");
        require(token.isApprovedForAll(msg.sender, address(this)), "Token not approved");
        require(token.balanceOf(msg.sender, _tokenId) > countToken[msg.sender][_tokenId] + _amount, "Token Already in sale");
        require(_price > 0,"Price must be greater than zero");
        tokenSellId++;
        SellStruct memory sellToken;
	    sellToken = SellStruct({
	        price  : _price,
            seller : msg.sender,
            amount : _amount,
            offerNo : 0
	    });
        saleDetails[tokenSellId] = sellToken;
        sellIdTotokenId[tokenSellId] = _tokenId;
        tokenIdToSellId[_tokenId].push(tokenSellId);
        countToken[msg.sender][_tokenId] += _amount;
        emit Sell(msg.sender, _tokenId, _amount, tokenSellId, _price, block.timestamp);
    }

    function buy (uint256 _sellId , uint256 _amount) public payable {         
        require(saleDetails[_sellId].seller != address(0) && saleDetails[_sellId].price > 0 ,"Token not for sell");
        require(msg.value >= saleDetails[_sellId].price * _amount, "Not Enough Amount");	
        require(saleDetails[_sellId].amount >= _amount, "Your amount is greater than selling amount");
	    token.safeTransferFrom(saleDetails[_sellId].seller, msg.sender, sellIdTotokenId[_sellId], _amount, "");
	    payable(saleDetails[_sellId].seller).transfer(msg.value);
        countToken[saleDetails[_sellId].seller][sellIdTotokenId[_sellId]] -= _amount;
        emit Purchased(sellIdTotokenId[_sellId], msg.value, msg.sender, block.timestamp);

        for(uint256 i = 0; i < tokenIdToSellId[sellIdTotokenId[_sellId]].length; i++){
            if(tokenIdToSellId[sellIdTotokenId[_sellId]][i] == _sellId){
                tokenIdToSellId[sellIdTotokenId[_sellId]][i] = tokenIdToSellId[sellIdTotokenId[_sellId]][tokenIdToSellId[sellIdTotokenId[_sellId]].length - 1];
                delete tokenIdToSellId[sellIdTotokenId[_sellId]][tokenIdToSellId[sellIdTotokenId[_sellId]].length - 1];
                tokenIdToSellId[sellIdTotokenId[_sellId]].pop();
            }              
        }

        if(saleDetails[_sellId].amount == _amount){
            delete sellIdTotokenId[_sellId];
            delete saleDetails[_sellId];  
        }else{
            saleDetails[_sellId].amount -= _amount;
        }
               
    }

    function createAuction(
        uint256 _tokenId,
        uint256 _price,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _amount
    ) public {
        require(token.balanceOf(msg.sender, _tokenId) >= _amount, "You are not owner");
        require(token.isApprovedForAll(msg.sender, address(this)), "Token not approved");
        require(token.balanceOf(msg.sender, _tokenId) > countToken[msg.sender][_tokenId] + _amount, "Token already in sale");
        require(_startTime < _endTime && _endTime > block.timestamp,"Check Time");
        require(_price > 0,"Price must be greater than zero");
        tokenAuctionId++;
        AuctionDetails memory auctionToken;
        auctionToken = AuctionDetails({
            price: _price,
            startTime: _startTime,
            endTime: _endTime,
            highestBidder: address(0),
            highestBid: 0,
            totalBids: 0,
            amount :_amount,
            owner : msg.sender
        });
        auction[tokenAuctionId] = auctionToken;
        auctionIdTotokenId[tokenAuctionId] = _tokenId;
        tokenIdToAuctionId[_tokenId].push(tokenAuctionId);
        countToken[msg.sender][_tokenId] += _amount;
        emit AuctionCreated(msg.sender, _tokenId, _price, _startTime, _endTime, _amount);
    }

    function bid(uint256 _auctionId, uint256 _price, uint256 _amount) public {
        require(
            block.timestamp > auction[_auctionId].startTime,
            "Auction not started yet"
        );
        require(block.timestamp < auction[_auctionId].endTime, "Auction is over");
        // The first bid, ensure it's >= the reserve price.
        require(
            _price >= auction[_auctionId].price * _amount,
            "Bid must be at least the reserve price"
        );
        // Bid must be greater than last bid.
        require(_price > auction[_auctionId].highestBid, "Bid amount too low");
        auction[_auctionId].highestBidder = msg.sender;
        auction[_auctionId].highestBid = _price;
        auction[_auctionId].totalBids++;
        emit Bid(msg.sender, _auctionId, auctionIdTotokenId[_auctionId], _price, _amount, block.timestamp);
    }

    function auctionClaim(uint256 _auctionId) public payable {     
        require(block.timestamp > auction[_auctionId].endTime, "Auction not ended yet");
        require(msg.value >= auction[_auctionId].highestBid, "Less Amount");
        require(auction[_auctionId].highestBidder == msg.sender, "You are not winner");

        token.safeTransferFrom(auction[_auctionId].owner, msg.sender, auctionIdTotokenId[_auctionId], auction[_auctionId].amount, "");
        countToken[auction[_auctionId].owner][auctionIdTotokenId[_auctionId]] -= auction[_auctionId].amount;
	    payable(auction[_auctionId].owner).transfer(auction[_auctionId].highestBid);     

        emit AuctionClaimed(msg.sender, _auctionId, auction[_auctionId].highestBid, block.timestamp);

        for(uint256 i = 0; i < tokenIdToAuctionId[auctionIdTotokenId[_auctionId]].length; i++){
            if(tokenIdToAuctionId[auctionIdTotokenId[_auctionId]][i] == _auctionId){
                tokenIdToAuctionId[auctionIdTotokenId[_auctionId]][i] = tokenIdToAuctionId[auctionIdTotokenId[_auctionId]][tokenIdToAuctionId[auctionIdTotokenId[_auctionId]].length - 1];
                delete tokenIdToAuctionId[auctionIdTotokenId[_auctionId]][tokenIdToAuctionId[auctionIdTotokenId[_auctionId]].length - 1];
                tokenIdToAuctionId[auctionIdTotokenId[_auctionId]].pop();
            }   
        }          

        delete auction[_auctionId];  
        delete auctionIdTotokenId[_auctionId];              
    }

    function getTokenIdToSellId(uint256 _tokenId) public view returns (uint256[] memory) {
        return tokenIdToSellId[_tokenId];
    }

    function getTokenIdToAuctionId(uint256 _tokenId) public view returns (uint256[] memory) {
        return tokenIdToAuctionId[_tokenId];
    }
    
    function cancelSell(uint256 _sellId) public {
        require(msg.sender == saleDetails[_sellId].seller,"You are not owner");
        require(saleDetails[_sellId].price > 0, "Can't cancel the sell");
        countToken[saleDetails[_sellId].seller][sellIdTotokenId[_sellId]] -= saleDetails[_sellId].amount; 
        tokenSellId--;
        emit SellCancelled (msg.sender, _sellId, sellIdTotokenId[_sellId], block.timestamp);
        for(uint256 i = 0; i < tokenIdToSellId[sellIdTotokenId[_sellId]].length; i++){
            if(tokenIdToSellId[sellIdTotokenId[_sellId]][i] == _sellId){
                tokenIdToSellId[sellIdTotokenId[_sellId]][i] = tokenIdToSellId[sellIdTotokenId[_sellId]][tokenIdToSellId[sellIdTotokenId[_sellId]].length - 1];
                delete tokenIdToSellId[sellIdTotokenId[_sellId]][tokenIdToSellId[sellIdTotokenId[_sellId]].length - 1];
                tokenIdToSellId[sellIdTotokenId[_sellId]].pop();
            }              
        }

        delete sellIdTotokenId[_sellId];
        delete saleDetails[_sellId]; 
    }

    function cancelAuction(uint256 _auctionId) public {
        require(msg.sender == auction[_auctionId].owner,"You are not owner");
        require(auction[_auctionId].price > 0, "Can't cancel the auction");
        countToken[auction[_auctionId].owner][auctionIdTotokenId[_auctionId]] -= auction[_auctionId].amount; 
        tokenAuctionId--;
        emit AuctionCancelled (msg.sender, _auctionId, auctionIdTotokenId[_auctionId], block.timestamp);
        for(uint256 i = 0; i < tokenIdToAuctionId[auctionIdTotokenId[_auctionId]].length; i++){
            if(tokenIdToAuctionId[auctionIdTotokenId[_auctionId]][i] == _auctionId){
                tokenIdToAuctionId[auctionIdTotokenId[_auctionId]][i] = tokenIdToAuctionId[auctionIdTotokenId[_auctionId]][tokenIdToAuctionId[auctionIdTotokenId[_auctionId]].length - 1];
                delete tokenIdToAuctionId[auctionIdTotokenId[_auctionId]][tokenIdToAuctionId[auctionIdTotokenId[_auctionId]].length - 1];
                tokenIdToAuctionId[auctionIdTotokenId[_auctionId]].pop();
            }   
        }   
        delete auction[_auctionId];  
        delete auctionIdTotokenId[_auctionId];     
    } 
}