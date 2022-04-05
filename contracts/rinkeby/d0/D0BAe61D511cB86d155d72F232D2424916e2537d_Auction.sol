// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC721 {
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
}

contract Auction { 

    address payable public seller;

    bool public started;
    bool public ended;
    uint public endAt;

    IERC721 public nft;
    uint public nftId;

    uint public highestBid;
    address public highestBidder;
    mapping(address => uint) public bids;          // will be storing revious highest bids when new nid is made, user can withdraw old bid

    event Start();
    event End(address highestBidder, uint highestBid);
    event Bid(address indexed sender, uint amount);
    event Withdraw(address indexed bidder, uint amount);


    constructor () {
        seller = payable(msg.sender);
    }

    function start(IERC721 _nft, uint _nftId, uint startingBid) external {
        require(!started, "Already started !!");
        require(msg.sender == seller, " You did not start the auction.");
        
        highestBid = startingBid;

        nft = _nft;
        nftId = _nftId;
        nft.transferFrom(msg.sender, address(this), nftId);

        started = true;
        endAt = block.timestamp + 2 days;

        emit Start();
    }

    function bid() external payable {
        require(started, "Auction not started yet!");
        require(block.timestamp < endAt, "Auction already ended!");
        require(msg.value > highestBid);

        // for withdrawing bids 
        if (highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }
        highestBid = msg.value;
        highestBidder = msg.sender;

        emit Bid(highestBidder, highestBid);
    }

    function withdraw() external payable {
        uint bal = bids[msg.sender];
        bids[msg.sender] = 0;
        (bool sent, bytes memory data) = payable(msg.sender).call{value: bal}("");
        require(sent, "Could not withdraw!!");

        emit Withdraw(msg.sender, bal);
    } 

    function end() external { 
        require(started, "Auction not started yet !!");
        require(block.timestamp >= endAt, "Auction is still running.");
        require(!ended, "Auction already ended!");

        if (highestBidder != address(0)) {
            nft.transfer(highestBidder, nftId);
            (bool sent, bytes memory data) = payable(msg.sender).call{value: highestBid}("");
            require(sent, "Could not pay seller!!");
        }   else {
            nft.transfer(seller, nftId);
        }

        ended = true;
        emit End(highestBidder, highestBid);
    }

}