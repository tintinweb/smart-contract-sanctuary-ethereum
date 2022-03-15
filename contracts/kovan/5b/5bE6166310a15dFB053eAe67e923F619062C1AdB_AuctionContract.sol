/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
pragma abicoder v2;

// authors: A. Froehlich, R. El-kurdi, P. Charreaux

contract AuctionContract {
    // NTF properties
    string public url = "https://nightlyside.github.io/";
    address public author = 0x384A42EA2B2046df609B9d72Bb377Ec37ed376F3;
    address private owner = author;
    
    // Tickets infos
    uint public soldTickets = 0;
    mapping (address => uint) public ticketsBalance;

    // Auction infos
    uint private roundNumber = 0;
    uint private reservePrice = 10; // the author should at least make 10 tickets
    bool private isAuctionRoundOpen = false;
    address[] private bidders;
    mapping(uint => mapping(address => uint)) private currentBids;
    address[] private ownersWhoIncreased;

    function buy(uint nbTickets) external payable {
        // check if the number of tickets matches the value in
        // the transaction
        require(msg.value == nbTickets * (3 gwei));
        // if so, increase the balance in tickets of the bidder
        ticketsBalance[msg.sender] += nbTickets;

        // increase the number of sold tickets
        soldTickets += nbTickets;
    }

    function sell(uint nbTickets) external {
        // checks if the bidder has enough tickets
        require(nbTickets <= ticketsBalance[msg.sender]);
        // if so, remove them from their balance
        ticketsBalance[msg.sender]-= nbTickets;
        // and transfer the money
        payable(msg.sender).transfer(nbTickets * (3 gwei));

        // decrease the number of sold tickets
        soldTickets -= nbTickets;
    }

    function getOwner() external view returns(address) {
        // return the owner
        return owner;
    }

    function giveForFree(address a) external {
        // first checks that the sender has the rights to change
        // ownership
        require(msg.sender == owner);
        // if so, change ownership
        owner = a;
    }

    function getBalance() external view returns(uint){
        return address(this).balance;
    }

    function newBid(uint nbTickets) external {
        // the bidder has to have enough tickets
        require(ticketsBalance[msg.sender] >= nbTickets);

        // open a new action round if no current auctions is opened
        if (!isAuctionRoundOpen) {
            isAuctionRoundOpen = true;
        }

        // register the bidder
        if (!member(msg.sender, bidders)) {
            bidders.push(msg.sender);
        }
        // change the bid for the current user
        currentBids[roundNumber][msg.sender] = nbTickets;
    }

    function getMaximalBid() external view returns(uint) {
        uint maxBid = 0;
        for (uint idx = 0; idx < bidders.length; idx++) {
            address bidder = bidders[idx];
            if (currentBids[roundNumber][bidder] > maxBid) {
                maxBid = currentBids[roundNumber][bidder];
            }
        }

        return maxBid;
    }

    function getMaximalBidder() external view returns(address) {
        uint maxBid = 0;
        address maxBidder = address(0);

        for (uint idx = 0; idx < bidders.length; idx++) {
            address bidder = bidders[idx];
            if (currentBids[roundNumber][bidder] > maxBid) {
                maxBid = currentBids[roundNumber][bidder];
                maxBidder = bidder;
            }
        }

        return maxBidder;
    }

    function getMinimalPrice() external view returns(uint) {
        return reservePrice;
    }

    function increaseMinimalPrice() external {
        // first checks that the sender has the rights to change
        // ownership
        require(msg.sender == owner);
        
        // if so, require that he didn't ever increased the price 
        // of the ntf
        require(!member(msg.sender, ownersWhoIncreased));
        
        // if everything is fine add the owner to the list
        // and increase the price
        ownersWhoIncreased.push(msg.sender);
        reservePrice += 10;
    }

    function closeAuction() external {
        // the auction round needs to be opened
        require(isAuctionRoundOpen);
        isAuctionRoundOpen = false;

        // get maximal valid bid (in case bidder sold tickets in the meantime)
        address maxBidder = address(0);
        uint maxBid = 0;
        while (true) {
            maxBid = this.getMaximalBid();
            maxBidder = this.getMaximalBidder();

            // if there is no valid candidate exit the loop
            if (maxBidder == address(0)) {
                break;
            } 

            // if the bidder has not enough tickets
            if (ticketsBalance[maxBidder] < maxBid) {
                // invalidate the bid
                currentBids[roundNumber][maxBidder] = 0;
                continue;
            } 
            // else the transaction can be made, we exit the loop
            break;
        }

        // transfer ownership if price is met and change the reserve price
        if (maxBid >= reservePrice) {
            // if the owner wasn't set during the round
            // then keep the ownership
            if (maxBidder != address(0)) {
                // pay the previous owner
                ticketsBalance[maxBidder] -= maxBid;
                ticketsBalance[owner] += maxBid;

                // change ownership
                owner = maxBidder;
                reservePrice = maxBid;
            }
        }

        // in any case reset the bids
        delete bidders; // reset the bidders array
        roundNumber++; // switch to the next round
    }

    function check() external view returns(bool, bool) {
        return (soldTickets * (3 gwei) <= this.getBalance(),
                soldTickets * (3 gwei) >= this.getBalance());
    }

    function member(address s, address[] memory tab) pure private returns(bool){
        uint length = tab.length;
        for (uint i=0; i < length; i++){
            if (tab[i] == s) return true;
        }
        return false;
    }
}