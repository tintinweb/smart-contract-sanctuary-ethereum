/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.12 <0.9.0;

// Clement LE GRUIEC - FIP3A - PNUM
// MAJ - FIP3A - PNUM
// IMT Atlantique - UE BlockChain

contract AuctionContract{

    // User Struct
    struct User {
        uint nbTickets;
        uint nbBid;
    }
 
    address public author = 0x6bF2eF0dd40A8c803cc00593765a8B0F7cF1Ed67; //Public address of the author
    address private owner = 0x6bF2eF0dd40A8c803cc00593765a8B0F7cF1Ed67; //Public address of the owner - default is the author
    address[] private lastOwners; // Previous owners
    address[] private runningBidders; // The bidders in the running auction
    mapping (address => bool) ownersBidUpdate; // To check if they already increase the minimal price
    mapping (address => User) users; // User Struct
    uint public soldTickets = 0; // Total tickets sold
    string public url = "https://cdn.guff.com/site_2/media/33000/32521/items/bdf67aafbc7a2429e3628148.jpg"; // URL of the ArtWork
    uint private minimalBid = 10; // at least 10 tickets when selling the ownership
    address private maxBidder; // address of the current maximal bidder
    uint private maxBid = 0; // value of the current maximal bid - Default is 0

    // Users of the contract can buy, so-called, auction tickets to participate to the auction using a payable
    // function buy(uint nbTickets). The cost of one ticket is exactly 3 Gwei
    function buy(uint _nbTickets) external payable {
        require(msg.value == _nbTickets * (3 gwei));
        users[msg.sender].nbTickets += _nbTickets;
        soldTickets += _nbTickets;
    }

    // Users can sell their tickets (if not bidden) and get their ether back 
    // using the sell(uint nbTickets) function
    function sell(uint _nbTickets) external {
        require(_nbTickets <= users[msg.sender].nbTickets);
        users[msg.sender].nbTickets -= _nbTickets;
        payable(msg.sender).transfer(_nbTickets*(3 gwei));
    }

    // An external function getOwner() returning the address of the current owner ;
    function getOwner() external view returns(address){
        return owner;
    }

    // he can give the contract as a gift to another account using the giveForFree(address a)
    // function. The effect of this function is to give for free the ownership of the contract to another account.
    function giveForFree(address _addr) external{
        require(msg.sender == owner);
        owner = _addr;
    }

    // An external function getBalance() returning the current balance of the contract ;
    function getBalance() external view returns(uint) {
        return address(this).balance;
    }

    // At any time, users can make a bid with auction tickets using the newBid(uint nbTickets) function.
    // If no current auction is opened, this opens a new auction round. A user can only bid tickets he owns.
    function newBid(uint _nbTickets) external {
        // If the user has enought tickets, if the number of bids is greater than the minimal, if the total user bid is greater than the last bid
        require(_nbTickets <= users[msg.sender].nbTickets && (maxBid+_nbTickets) >= minimalBid && (users[msg.sender].nbBid+_nbTickets) > maxBid);
        users[msg.sender].nbTickets -= _nbTickets;
        users[msg.sender].nbBid += _nbTickets;
        maxBidder = msg.sender;
        maxBid = users[msg.sender].nbBid;
        
        uint nbBidder = runningBidders.length;
        bool exist = false;
        for(uint i=0; i<nbBidder; i++){
            if(maxBidder == runningBidders[i]){
               exist = true;
               break; 
            }
        }
        if(!exist){
            runningBidders.push(maxBidder);
        }
        
    }

    //An external function getMyBidBalance() returning the value of the user bid(s) ;
    function getMyBidsBalance() external view returns(uint){
        return users[msg.sender].nbBid;
    }
    

    //An external function getMyTicketBalance() returning the value of the user ticket(s) ;
    function getMyTicketsBalance() external view returns(uint){
        return users[msg.sender].nbTickets;
    }


    //An external function getMaximalBid() returning the value of the current maximal bid (in tickets) ;
    function getMaximalBid() external view returns(uint){
        return maxBid;
    }

    // A external function getMaximalBidder() returning the address of the current maximal bidder ;
    function getMaximalBidder() external view returns(address){
        return maxBidder;
    }

    // A external function getMinimalPrice() returning the value of the current minimal price (in tickets) ;
    function getMinimalPrice() external view returns(uint){
        return minimalBid;
    }

    // The owner of the contract has two privileges. First, he can increase the minimal price with 10 tickets by
    // calling the increaseMinimalPrice(). The owner can only do this once during all contract lifetime.
    function increaseMinimalPrice() external {
        require(ownersBidUpdate[msg.sender] == false && msg.sender == owner);
        minimalBid += 10;
        ownersBidUpdate[msg.sender]=true;
    }

    // Any user can stop the current auction process by calling the closeAuction() function. If the maximal
    // bid is greater or equal to a given minimal price (i.e. reserve price) then the effect of closeAuction()
    // is to close the current auction round, to transfer ownership of the contract to the (first) user who has
    // made the maximal bid, and to transfer the maximal bid to the old owner of the contract. The minimal
    // price is set to the maximal bid. Besides, all bids are cleared.
    function closeAuction() external{
        // Bid is at least the minimal price. Second part is to block the auction in case of cheating
        require(maxBid >= minimalBid && users[maxBidder].nbBid-maxBid == 0);
        users[owner].nbTickets += maxBid;
        users[maxBidder].nbBid -= maxBid;
        owner = maxBidder;
        lastOwners.push(maxBidder);
        maxBid = 0;
        maxBidder = 0x0000000000000000000000000000000000000000;
        
        uint nbBidder = runningBidders.length;
        for(uint i=0; i<nbBidder; i++){
            users[runningBidders[i]].nbTickets += users[runningBidders[i]].nbBid;
            users[runningBidders[i]].nbBid = 0;
        }
        runningBidders = new address[](0);
        
        
    }

    function check() external view returns(bool,bool) {
        return( (soldTickets*(3 gwei) <= this.getBalance()),
                (soldTickets*(3 gwei) >= this.getBalance()));
    }
}