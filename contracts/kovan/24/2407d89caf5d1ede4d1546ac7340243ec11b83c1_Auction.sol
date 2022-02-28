/**
 *Submitted for verification at Etherscan.io on 2022-02-28
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

//pragma experimental SMTChecker;

contract Auction {
    string public url = ""; // public url containing url of the artwork
    address public author; // address of the creator of the contract
    uint256 public soldTickets; // amount of all sent tickets
    address private owner; // address of the owner of the contract
    uint256 private minimalPrice;
    bool private open = false;
    bool private increase = false; // ensure owner increases price only once
    address[] private players;
    mapping(address => bool) private playerExists; // remove duplicated users in players
    mapping(address => uint256) private userNbTickets; // Tickets bought buy users
    mapping(address => uint256) private userMaxBid;
    uint256 private maxBid;
    address private maxBidder;

    constructor(string memory _url) {
        url = _url;
        author = msg.sender;
        owner = msg.sender;
        minimalPrice = 10;
    }

    /*
    Buy allows user to buy tickets
    cost of a ticket is 3 gwei
    */
    function buy(uint256 nbTickets) external payable {
        // verify that the value is equal to nb_Tickets * (ticket price)
        require(msg.value == nbTickets * (3 gwei));
        userNbTickets[msg.sender] += nbTickets;
        soldTickets += nbTickets;
    }

    /*
    sell allows user to sell tickets
    */
    function sell(uint256 nbTickets) external payable {
        require(
            userNbTickets[msg.sender] - userMaxBid[msg.sender] >= nbTickets
        );
        uint256 _amount = nbTickets * (3 gwei); // get amount the user should recieve
        userNbTickets[msg.sender] -= nbTickets;
        soldTickets -= nbTickets;
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Withdraw failed.");
    }

    /*
    returns the address of the current owner
    */
    function getOwner() external view returns (address) {
        return owner;
    }

    /*
     * give for free the ownership of the contract to another
     */
    function giveForFree(address new_owner) external {
        require(msg.sender == owner && new_owner != owner);
        increase = false;
        owner = new_owner;
    }

    /*
    current balance of the contract
    */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /*
    make a bid with auction tickets
    If no current auction is opened,
    this opens a new auction round. A user can only bid tickets he owns.
    */
    function newBid(uint256 nbTickets) external {
        require(userNbTickets[msg.sender] >= nbTickets);
        open = true;

        if (nbTickets > maxBid) {
            maxBid = nbTickets;
            userMaxBid[msg.sender] = nbTickets;
            maxBidder = msg.sender;
            if(playerExists[msg.sender]== false){
                playerExists[msg.sender]= true;
                players.push(msg.sender);
            }
            
        }
    }

    /*
    returning the value of the current maximal bid (in tickets)
    */
    function getMaximalBid() external view returns (uint256) {
        return maxBid;
    }

    /*
    returning the address of the current maximal bidder
    */
    function getMaximalBidder() external view returns (address) {
        return maxBidder;
    }

    /*
    returning the value of the current minimal price (in tickets)
    */
    function getMinimalPrice() external view returns (uint256) {
        return minimalPrice;
    }

    /*
    increase with 10 tickets the minimal
    price. This can be done only once by each owner
    */
    function increaseMinimalPrice() external {
        require(increase == false);
        minimalPrice += 10;
        increase = true;
    }

    /*
    Stop current auction at any time.
    Any user can call the function.
    requires : bid >= minimal price
    closes the current auction round
    transfer ownership to the first user who made the maximal bid
    transfer maximal bid to old owner
    minimal price is set to maximal bid.
    all bids are cleared
    */
    function closeAuction() external {
        require(maxBid >= minimalPrice);
        open = false;
        userNbTickets[owner] += maxBid;
        userNbTickets[maxBidder] -= maxBid;

        for (uint256 i = 0; i < players.length; i++) {
            userMaxBid[players[i]] = 0;
            playerExists[players[i]]= false;
        }
        delete players;

        owner = maxBidder;
        maxBidder = 0x0000000000000000000000000000000000000000;
        minimalPrice = maxBid;
        maxBid = 0;
        increase = false;
    }

    function check() external view returns (bool, bool) {
        return (
            (soldTickets * (3 gwei) <= this.getBalance()),
            (soldTickets * (3 gwei) >= this.getBalance())
        );
    }

    function dev_getplayer() external view returns (address[] memory) {
        return (players);
    }

    function dev_getTickets() external view returns (uint256) {
        return userNbTickets[msg.sender] - userMaxBid[msg.sender];
    }
}