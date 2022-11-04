// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) external;

    function transferFrom(
        address,
        address,
        uint
    ) external;
}

contract NTSAuction {
    event Start();
    
    event Withdraw(address indexed bidder, uint amount);

    //define our bidding structure2
    struct BidStr {
            uint BidValue;
            string imageId;
            string name;
        }

    BidStr public highestBid;

    event End(address winner, BidStr highestBid);
    event Bid(address indexed sender, BidStr highestBid);
    IERC721 public nft;
    uint public nftId;

    
    uint public minIncrement = 100000000000000000; //0.1 eth in wei
    address public highestBidder;
    //uint public highestBid;

    address payable public seller;
    uint public endAt;
    bool public started;
    bool public ended;

    
    
    mapping(address => uint) public bids;

    constructor(
        address _nft,
        uint _nftId,
        uint _startingBid,
        string memory _startingId,
        string memory _startingName
    ) {
        nft = IERC721(_nft);
        nftId = _nftId;

        seller = payable(msg.sender);
        highestBid = BidStr(_startingBid, _startingId,_startingName);
    }

    //transfer the nft from the seller, and then start the auction immediately
    function start() external {
        require(!started, "started");
        require(msg.sender == seller, "not seller");

        nft.transferFrom(msg.sender, address(nft), nftId);
        started = true;
        endAt = block.timestamp + 3 days;
        emit Start();
    }

    function bid(
                string memory _imageID,
                string memory _imageName) external payable {
        require(started, "Auction not started yet");
        require(block.timestamp < endAt, "Auction is already over");
        require(msg.value > highestBid.BidValue + minIncrement, "You must bid at least 0.1 eth higher than the previous bid");

        //ensure bidder is not
        if (highestBidder != address(0)) {
            bids[highestBidder] += highestBid.BidValue;
        }

        highestBidder = msg.sender;
        highestBid = BidStr(msg.value, _imageID,_imageName);

        emit Bid(msg.sender, highestBid);
    }

    function gethighestBid() public view returns (BidStr memory) {
        return highestBid;
    }

    function getHighestBidder() public view returns (address) {
        return highestBidder;
    }

    function withdraw() external {
        uint bal = bids[msg.sender];
        bids[msg.sender] = 0;
        payable(msg.sender).transfer(bal);

        emit Withdraw(msg.sender, bal);
    }

    function end() external {
        require(started, "not started");
        require(block.timestamp >= endAt, "not ended");
        require(!ended, "ended");

        ended = true;
        if (highestBidder != address(0)) {
            nft.safeTransferFrom(address(this), highestBidder, nftId);
            seller.transfer(highestBid.BidValue);
        } else {
            nft.safeTransferFrom(address(this), seller, nftId);
        }

        emit End(highestBidder, highestBid);
    }
}