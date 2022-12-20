/// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Escrow  {
    //TODO add the auction struct
     struct Auction {
        uint id;
        uint minAmount;
        string tittle;
        string description;
        address  owner;
        bool active;
        address payable highestBidder;
        uint256  closingTime;

        } 
    //TODO add the escrow struct
     struct EscrowType {
        uint id;
        uint amount;
        address payable owner;
        address buyer;
        bool ownerApproved;
        bool buyerApproved;
        bool active;
        uint auctionId;
        uint closingTime;
        }
        
    Auction [] public auctions;
    EscrowType [] public escrows;
    uint public fee;
    event AuctionCreated(uint id, uint minAmount, string tittle, string description, address  owner, bool active, address payable highestBidder, uint256  closingTime);
    
    //event AuctionClosed(uint id, uint minAmount, string tittle, string description, address owner, bool active, address payable highestBidder, uint256  closingTime);

    constructor(uint _fee) {
        //TODO add the code to initialize the contract
         fee =  _fee;
        }

    function PublishAuction( string calldata tittle,string calldata description,uint minAmount) public 
    {
        //TODO add the code to publish a new auction
        Auction memory newAuction = Auction(auctions.length, minAmount, tittle, description, msg.sender, true, payable(address(0)), block.timestamp + 1 days);
        auctions.push(newAuction);
        emit AuctionCreated(newAuction.id, newAuction.minAmount, newAuction.tittle, newAuction.description, newAuction.owner, newAuction.active, newAuction.highestBidder, newAuction.closingTime);
          
    }
    function Close(uint id) public
    {
        //TODO add the code to close an auction
        Auction storage auction = auctions[id];
        require(auction.owner == msg.sender, "Only the owner can close the auction");
        auction.active = false;
        //TODO add the code to create new escrow
        EscrowType memory newEscrow = EscrowType(escrows.length, auction.minAmount, payable(auction.owner), auction.highestBidder, false, false, true, auction.id, block.timestamp + 1 days);
        escrows.push(newEscrow);

    }
    function Bid(uint id) public payable {
        //TODO add the code to bid on an auction
        Auction storage auction = auctions[id];
        require(auction.active == true, "The auction is not active");
        require(msg.value > auction.minAmount, "The amount is not enough");
        require(block.timestamp < auction.closingTime, "The auction is closed");
        //return the money to the previous highest bidder
        if(auction.highestBidder != address(0))
         payable(auction.highestBidder).transfer(auction.minAmount);
        //set the new highest bidder
        auction.minAmount = msg.value;
        auction.highestBidder = payable(msg.sender);

    }
    function GetAuctions() public view returns (Auction[] memory)
    {
        //TODO add the code to get all the auctions
        return auctions;
    }
    function GetAuction(uint id) public view returns (Auction memory)
    {
        //TODO add the code to get a specific auction
        return auctions[id];
    }
    function GetEscrows() public view returns (EscrowType[] memory)
    {
        //TODO add the code to get all the escrows
        return escrows;
    }
    function GetEscrow(uint id) public view returns (EscrowType memory)
    {
        //TODO add the code to get a specific escrow
        return escrows[id];
    }
    function Approve(uint id) public
    {
        //TODO add the code to approve an escrow
        EscrowType storage escrow = escrows[id];
        require(escrow.active == true, "The escrow is not active");
        require(block.timestamp < escrow.closingTime, "The escrow is closed");
         if(escrow.buyer == msg.sender)
        {
            escrow.buyerApproved = true;
        }
        if(escrow.owner == msg.sender)
        {
            escrow.ownerApproved = true;
        }
       
        if(escrow.ownerApproved == true && escrow.buyerApproved == true)
        {
            escrow.active = false;
            payable(escrow.owner).transfer(escrow.amount);
        }
    }


}