/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

contract ANFT {
    mapping(address => uint256) public ticketsBalance;
    uint256 public soldTickets = 0;
    string public constant URL =
        "https://i.pinimg.com/originals/12/56/00/1256000a71e6e0fbcd09c8505529889f.jpg";
    address public author = msg.sender;
    address private owner = author;

    uint256 public minimalPrice = 0;
    bool private increase = false;

    bool private is_auctioned = false;
    uint256 private max_bid = 0;
    address private max_bidder = address(0);

    function buy(uint256 nbTickets) external payable {
        require(msg.value == nbTickets * (3 gwei));
        ticketsBalance[msg.sender] += nbTickets;
        soldTickets += nbTickets;
    }

    function sell(uint256 nbTickets) external payable {
        require(msg.sender != max_bidder);
        require(nbTickets <= ticketsBalance[msg.sender]);
        ticketsBalance[msg.sender] -= nbTickets;
        soldTickets -= nbTickets;
        (bool success, ) = payable(msg.sender).call{value: nbTickets * (3 gwei)}("");
        require(success, "Transfer failed.");
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function getMaximalBid() external view returns (uint256) {
        return max_bid;
    }

    function getMaximalBidder() external view returns (address) {
        return max_bidder;
    }

    function getMinimalPrice() external view returns (uint256) {
        return minimalPrice;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function newBid(uint256 nbTickets) external {
        require(nbTickets > 1);
        require(ticketsBalance[msg.sender] >= nbTickets);
        require(nbTickets > max_bid);
        if (is_auctioned == false) {
            max_bid = minimalPrice;
            is_auctioned = true;
        }
        max_bid = nbTickets;
        max_bidder = msg.sender;
    }

    function closeAuction() external {
        require(max_bid >= minimalPrice);
        ticketsBalance[owner] += max_bid;
        ticketsBalance[max_bidder] -= max_bid;
        minimalPrice = max_bid;
        owner = max_bidder;
        is_auctioned = true;
        max_bid = 0;
        max_bidder = address(0);
    }

    function giveForFree(address a) external {
        require(msg.sender == owner);
        owner = a;
    }

    function increaseMinalPrice() external {
        require(msg.sender == owner);
        require(increase == false);
        minimalPrice += 10;
        increase = true;
    }

    function check() external view returns (bool, bool) {
        return (
            (soldTickets * (3 gwei) <= this.getBalance()),
            (soldTickets * (3 gwei) >= this.getBalance())
        );
    }
}