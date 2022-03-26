// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Auction {
    string public currentLot;
    uint public bidPrice;
    address public bidAddress;
    address public sellerAddr;
    address public owner;

    constructor(){
        owner = msg.sender;
    }

    modifier isBidable {
        require(bidPrice != 0, "The auction has not yet begun!");
        require(msg.value > bidPrice, "Current bid price should be greater than last bid price!");
        _;
    }

    modifier isSeller {
        require(sellerAddr == msg.sender, "Permission denied! You are not the lot seller.");
        _;
    }

    modifier isOwner {
        require(owner == msg.sender, "Permission denied! You are not an owner.");
        _;
    }

    modifier isBeginable{
        require(bidPrice == 0 && bytes(currentLot).length == 0 && sellerAddr == address(0), "Auction is active!");
        _;
    }

    receive() external payable{}
    
    function makeBid() isBidable external payable {
        if (bidAddress != address(0)){
            payable(bidAddress).transfer(bidPrice);
        }
        bidPrice = msg.value;
        bidAddress = msg.sender;
    }

    function stopAuction() isSeller external {
        payable(sellerAddr).transfer(address(this).balance);

        currentLot = "";
        bidPrice = 0;
        bidAddress = address(0);
        sellerAddr = address(0);
    }

    function beginAuction(string memory _currentLot, uint _startPrice, address _sellerAddr) isOwner isBeginable external payable{
        owner = msg.sender;
        currentLot = _currentLot;
        bidPrice = _startPrice;
        sellerAddr = _sellerAddr;
    }
}