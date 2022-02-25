/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Auction {

    string public urlArtwork = "https://www.dictionary.com/e/wp-content/uploads/2018/03/This-is-Fine-300x300.jpg";
    address public author = 0x12e3c582A413136569d4C51a8Cc0165685950Bd8;
    address private owner = author;
    uint soldTickets = 0;
    uint maxBid = 0;
    address maxBidder = owner;
    bool isOpen = false;
    bool priceHasIncreased = false;
    uint minimalPrice = 10;

    mapping (address => uint) private balances;
    
    function buy(uint nbTickets) external payable{
        require(msg.value == nbTickets * (3 gwei));
        balances[msg.sender] += nbTickets;
        soldTickets += nbTickets;
    }

     function sell(uint nbTickets) external{
        if (msg.sender == maxBidder)
            require( nbTickets<= (balances[msg.sender] - maxBid));
        else
            require( nbTickets<= balances[msg.sender]);
        balances[msg.sender] -= nbTickets;
        soldTickets -= nbTickets;
        msg.sender.call{value: nbTickets*(3 gwei)}("");
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function giveForFree(address a) external {
        require(msg.sender ==  owner);
        owner = a;
    }

    function getBalance() external view returns (uint) {
        return soldTickets * (3 gwei);
    }

    function newBid(uint nbTickets) external {
        require(nbTickets > maxBid);
        isOpen = true;
        maxBid = nbTickets;
        maxBidder = msg.sender;
    }

    function getMaximalBid() external view returns (uint) {
        return maxBid;
    }

    function getMaximalBidder() external view returns (address) {
        return maxBidder;
    }

    function getMinimalPrice() external view returns (uint) {
        return minimalPrice;
    }

    function increaseMinimalPrice() external {
        require(msg.sender == owner);
        require(!priceHasIncreased);
        minimalPrice += 10;
        priceHasIncreased = true;
    }

    function closeAuction() external {
        require (maxBid >= minimalPrice);
        isOpen = false;
        balances[maxBidder] -= maxBid;
        balances[owner] += maxBid;
        owner = maxBidder;
        priceHasIncreased = false;
        minimalPrice = maxBid;
    }

    function check() external view returns(bool,bool){
        return( (soldTickets*(3 gwei) <= this.getBalance()), (soldTickets*(3 gwei) >= this.getBalance()));
    }
}