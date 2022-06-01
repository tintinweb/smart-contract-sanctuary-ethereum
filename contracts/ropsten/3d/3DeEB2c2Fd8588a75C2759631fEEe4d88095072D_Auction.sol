// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC721.sol";
import "./Ownable.sol";

contract Auction is Ownable {

    IERC20 private token;

    struct AuctionDetails {
        // Auction Id
        uint256 id;
        // Price (in token) at beginning of auction
        uint256 price;
        // Time (in seconds) when auction started
        uint256 startTime;
        // Time (in seconds) when auction ended
        uint256 endTime;
        // Address of highest bidder
        address highestBidder;
        // Highest bid amount
        uint256 highestBid;
        // Total number of bids
        uint256 totalBids;
        // Amount of tokens
        uint256 amountOrTokenId;
        // TokenAddress
        address token;
    }

    // How many seconds auction will run
    uint256 auctionTime = 90;

    uint256 public currentAuctionId = 0;

    // Mapping from auctionid to auction struct
    mapping(uint256 => AuctionDetails) public auction;

    // Mapping from addresss to token ID for claim.
    mapping(address => mapping(uint256 => uint256)) public pending_claim_auction;

    event AuctionCreated(
        address indexed _seller,
        uint256 _amountOrTokenId,
        uint256 _price,
        uint256 _startTime,
        uint256 _endTime,
        address _tokenAddress
    );
    event Bid(
        address indexed _bidder,
        uint256 indexed _auctionId,
        uint256 _price,
        uint256 _time
    );
    event AuctionClaimed(
        address indexed _buyer,
        uint256 _auctionId,
        uint256 _price,
        uint256 _time
    );
    event AuctionCancelled(
        address indexed _seller,
        uint256 _auctionId,
        uint256 _time
    );

    function initialize(address _token)
        public
        virtual
        onlyOwner
        returns (bool)
    {
        require(_token != address(0));
        token = IERC20(_token);
        return true;
    }

     function createAuction(
        uint256 _amountOrTokenId,
        uint256 _price,
        uint256 _startTime,
        uint256 _endTime,
        address _token,
        uint256 _type
    ) public onlyOwner{
        require(
            _price > 0,
            "Price must be greater than zero"
        );
        if(_type == 0){
            require(
                IERC20(_token).allowance(msg.sender, address(this)) >= _amountOrTokenId,
                "Tokens not approved"
            );
            IERC20(_token).transferFrom(msg.sender, address(this), _amountOrTokenId);           
        }else{
            require(
                IERC721(_token).getApproved(_amountOrTokenId) == address(this),
                "Token not approved"
            );
            IERC721(_token).transferFrom(msg.sender, address(this), _amountOrTokenId);
        }       
        currentAuctionId++;
        AuctionDetails memory auctionToken;
        auctionToken = AuctionDetails({
            id : currentAuctionId,
            price: _price,
            startTime: _startTime,
            endTime: _endTime,
            highestBidder: address(0),
            highestBid  : 0,
            totalBids: 0,
            amountOrTokenId : _amountOrTokenId,
            token : _token
        });
        auction[currentAuctionId] = auctionToken;
        emit AuctionCreated(msg.sender, _amountOrTokenId, _price, _startTime, _endTime, _token);
    }

    function bid(uint256 _auctionId, uint256 _amount) public {      
        require(
            block.timestamp > auction[_auctionId].startTime,
            "Auction not started yet"
        );
        require(block.timestamp < auction[_auctionId].endTime, "Auction is over");  
        // require((auction[_auctionId].endTime - auction[_auctionId].startTime) <= auctionTime, "You can bid in only 90 seconds");
        if(_amount < pending_claim_auction[msg.sender][_auctionId]){
            _amount = pending_claim_auction[msg.sender][_auctionId];
        }     
        require(
            _amount >= auction[_auctionId].price,
            "Bid must be at least the reserve price"
        );
        // Bid must be greater than last bid.
        require(_amount > auction[_auctionId].highestBid, "Bid amount too low");
        token.transfer(address(this), _amount - pending_claim_auction[msg.sender][_auctionId]);
        pending_claim_auction[msg.sender][_auctionId] = _amount;
        auction[_auctionId].highestBidder = msg.sender;
        auction[_auctionId].startTime = block.timestamp;
        auction[_auctionId].endTime = block.timestamp + auctionTime;
        auction[_auctionId].totalBids++;
        emit Bid(msg.sender, _auctionId, _amount, block.timestamp);
    }

    function claim(uint256 _auctionId, uint256 _type) public {
        require(
           auction[_auctionId].endTime < block.timestamp,
            "auction not compeleted yet"
        );
        require(
            auction[_auctionId].highestBidder == msg.sender || msg.sender == owner(),
            "You are not highest Bidder or owner"
        ); 
        if(_type == 0){
            IERC20(auction[_auctionId].token).transfer(auction[_auctionId].highestBidder, auction[_auctionId].amountOrTokenId);
        }else{
            IERC721(auction[_auctionId].token).transferFrom(address(this), auction[_auctionId].highestBidder, auction[_auctionId].amountOrTokenId);
        }
        token.transfer(owner(), auction[_auctionId].highestBid);  
            
        pending_claim_auction[auction[_auctionId].highestBidder][_auctionId] = 0;

        emit AuctionClaimed(msg.sender, _auctionId, auction[_auctionId].amountOrTokenId, block.timestamp);
        // delete auction[_auctionId];
    }

    function auctionPendingClaim(uint256 _auctionId) public {
        require(auction[_auctionId].highestBidder != msg.sender && auction[_auctionId].endTime < block.timestamp, "Your auction is running");
        require(pending_claim_auction[msg.sender][_auctionId] != 0, "You are not a bidder or already claimed");
        token.transfer(msg.sender, pending_claim_auction[msg.sender][_auctionId]);
        emit AuctionClaimed(msg.sender, _auctionId, pending_claim_auction[msg.sender][_auctionId], block.timestamp);
        pending_claim_auction[msg.sender][_auctionId] = 0;
    }

     function cancelAuction(uint256 _auctionId, uint256 _type) public {
        require(msg.sender == owner(), "You are not owner");
        if(_type == 0){
            IERC20(auction[_auctionId].token).transfer(owner(), auction[_auctionId].amountOrTokenId);
        }else{
            IERC721(auction[_auctionId].token).transferFrom(address(this), owner(), auction[_auctionId].amountOrTokenId);
        }
        emit AuctionCancelled(msg.sender, _auctionId, block.timestamp);
        delete auction[_auctionId];
    }
}