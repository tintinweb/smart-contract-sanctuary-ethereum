/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC721 {
    function transferFrom(address, address, uint) external;
    function ownerOf(uint) external view returns (address);
}

interface Market {
    function getPrice(address, uint) external view returns (uint);
}

contract Auction {
    event Start(address indexed tokenAddr, uint indexed tokenId, uint startingBid, uint endAt);
    event End(address highestBidder, uint highestBid);
    event Bid(address indexed sender, uint amount);
    event Withdraw(address indexed bidder, uint amount);

    mapping(address =>mapping(uint => Bidding)) public biddings;

    uint public balances;

    struct Bidding {
        address seller;
        bool started;
        bool ended;
        uint endAt;
        ERC721 tokenAddr;
        uint tokenId;
        uint bidCount;
        mapping(uint => uint) highestBid;
        mapping(uint => address) highestBidder;
        mapping(address => uint) bids;
    }

    function start(address _tokenAddr, uint _tokenId, uint startingBid, uint dayAmount) external {
        Bidding storage _bid = biddings[_tokenAddr][_tokenId];
        _bid.tokenAddr = ERC721(_tokenAddr);
        _bid.seller = _bid.tokenAddr.ownerOf(_tokenId);
        _bid.ended = false;

        require(!_bid.started, "Already started!");
        require(msg.sender == _bid.seller, "You can not start the auction!");
        
        _bid.bidCount = 0;
        _bid.highestBid[_bid.bidCount] = startingBid;
        _bid.bidCount++;
        
        _bid.tokenId = _tokenId;
        _bid.tokenAddr.transferFrom(msg.sender, address(this), _bid.tokenId);

        _bid.started = true;
        _bid.endAt = block.timestamp + (dayAmount * 1 days);

        emit Start(_tokenAddr, _tokenId, startingBid, _bid.endAt);
    }

    function bid(address _tokenAddr, uint _tokenId) external payable {
        Bidding storage _bid = biddings[_tokenAddr][_tokenId];

        require(_bid.started, "Not started.");
        require(block.timestamp < _bid.endAt, "Ended!");
        require(msg.value > _bid.highestBid[_bid.bidCount], "Lower bid!");

        _bid.highestBid[_bid.bidCount] = msg.value;
        _bid.highestBidder[_bid.bidCount] = msg.sender;
        _bid.bids[_bid.highestBidder[_bid.bidCount]] = _bid.highestBid[_bid.bidCount];

        _bid.bidCount++;

        balances += msg.value;

        emit Bid(_bid.highestBidder[_bid.bidCount], _bid.highestBid[_bid.bidCount]);
    }

    function withdraw(address _tokenAddr, uint _tokenId) external payable {
        Bidding storage _bid = biddings[_tokenAddr][_tokenId];
        uint bal = _bid.bids[msg.sender];

        require(bal != 0 && bal <= balances, "Could not withdraw");

        if (msg.sender == _bid.highestBidder[_bid.bidCount]) {
            --_bid.bidCount;
            emit Bid(_bid.highestBidder[_bid.bidCount], _bid.highestBid[_bid.bidCount]);
        }

        _bid.bids[msg.sender] = 0;

        payable(msg.sender).transfer(bal);
        balances -= bal;

        emit Withdraw(msg.sender, bal);
    }

    function end(address _tokenAddr, uint _tokenId) external {
        Bidding storage _bid = biddings[_tokenAddr][_tokenId];

        require(_bid.started, "You need to start first!");
        require(block.timestamp >= _bid.endAt, "Auction is still ongoing!");
        require(!_bid.ended, "Auction already ended!");

        if (_bid.highestBidder[_bid.bidCount] != address(0)) {

            _bid.tokenAddr.transferFrom(address(this), _bid.highestBidder[_bid.bidCount], _bid.tokenId);

            payable(_bid.seller).transfer(_bid.highestBid[_bid.bidCount]);
            balances -= _bid.highestBid[_bid.bidCount];

            for (uint i = 0; i < _bid.bidCount; i++) {
                autoWithdraw(_tokenAddr, _tokenId, _bid.highestBidder[i]);
            }
        } else {
            _bid.tokenAddr.transferFrom(address(this), _bid.seller, _bid.tokenId);
        }

        _bid.ended = true;
        _bid.started = false;
        emit End(_bid.highestBidder[_bid.bidCount], _bid.highestBid[_bid.bidCount]);
    }

    function autoWithdraw(address tokenAddr_, uint tokenId_, address to) public payable {
        Bidding storage _bid = biddings[tokenAddr_][tokenId_];
        uint bal = _bid.bids[to];

        require(bal > 0 && bal <= balances, "Could not withdraw");

        _bid.bids[to] = 0;

        payable(to).transfer(bal);
        balances -= bal;

        emit Withdraw(to, bal);
    }

    function getPrice(address contractAddr, address tokenAddr, uint tokenId) public view returns(uint256 price) {
        return Market(contractAddr).getPrice(tokenAddr, tokenId);
    }
}