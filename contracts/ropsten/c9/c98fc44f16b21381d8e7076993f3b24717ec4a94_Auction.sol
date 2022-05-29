// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./Ownable.sol";

contract Auction is Ownable {

    IERC721 private nft_token;

    struct AuctionDetails {
        // Price (in token) at beginning of auction
        uint256 price;
        // Time (in seconds) when auction started
        uint256 startTime;
        // Time (in seconds) when auction ended
        uint256 endTime;
        // Address of highest bidder
        address highestBidder;
        // Total number of bids
        uint256 totalBids;
        // How many seconds auction will run
        uint256 auctionTime;
    }

    mapping(uint256 => AuctionDetails) private auction;

    event AuctionCreated(
        address indexed _seller,
        uint256 _tokenId,
        uint256 _price,
        uint256 _startTime,
        uint256 _endTime
    );
    event Bid(
        address indexed _bidder,
        uint256 indexed _tokenId,
        uint256 _price,
        uint256 _time
    );
    event AuctionClaimed(
        address indexed _buyer,
        uint256 _tokenId,
        uint256 _price,
        uint256 _time
    );
    event AuctionCancelled(
        address indexed _seller,
        uint256 _tokenId,
        uint256 _time
    );

    function initialize(address _nftToken)
        public
        virtual
        onlyOwner
        returns (bool)
    {
        require(_nftToken != address(0));
        nft_token = IERC721(_nftToken);
        return true;
    }

     function createAuction(
        uint256 _tokenId,
        uint256 _price,
        uint256 _startTime,
        uint256 _auctionTime
    ) public onlyOwner{
        require(
            nft_token.getApproved(_tokenId) == address(this),
            "Token not approved"
        );
        require(
            _price > 0,
            "Price must be greater than zero"
        );
        AuctionDetails memory auctionToken;
        auctionToken = AuctionDetails({
            price: _price,
            startTime: _startTime,
            endTime: _startTime + _auctionTime,
            highestBidder: address(0),
            totalBids: 0,
            auctionTime: _auctionTime
        });
        auction[_tokenId] = auctionToken;
        nft_token.transferFrom(msg.sender, address(this), _tokenId);
        emit AuctionCreated(msg.sender, _tokenId, _price, _startTime, _auctionTime);
    }

    function bid(uint256 _tokenId, uint256 _amount) public {      
        require(
            block.timestamp > auction[_tokenId].startTime,
            "Auction not started yet"
        );
        require(block.timestamp < auction[_tokenId].endTime, "Auction is over");       
        auction[_tokenId].highestBidder = msg.sender;
        auction[_tokenId].endTime = block.timestamp + auction[_tokenId].auctionTime;
        auction[_tokenId].totalBids++;
        emit Bid(msg.sender, _tokenId, _amount, block.timestamp);
    }

    function claim(uint256 _tokenId) payable public {
        require(
           auction[_tokenId].endTime < block.timestamp,
            "auction not compeleted yet"
        );
        require(
            auction[_tokenId].highestBidder == msg.sender || msg.sender == owner(),
            "You are not highest Bidder or owner"
        );
        if(msg.sender != owner()){
            require(msg.value >= auction[_tokenId].price, "Invalid Amount");
        }       
        nft_token.transferFrom(address(this), auction[_tokenId].highestBidder, _tokenId);
        payable(owner()).transfer(address(this).balance);

        emit AuctionClaimed(msg.sender, _tokenId, auction[_tokenId].price, block.timestamp);
        delete auction[_tokenId];
    }

     function cancelAuction(uint256 _tokenId) public {
        require(msg.sender == owner(), "You are not owner");
        nft_token.transferFrom(address(this), owner(), _tokenId);
        emit AuctionCancelled(msg.sender, _tokenId, block.timestamp);
        delete auction[_tokenId];
    }
}