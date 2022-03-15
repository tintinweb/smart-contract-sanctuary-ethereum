/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.6 <0.8.0;
pragma abicoder v2;

contract Auction {

    uint256 MAX_INT = 115792089237316195423570985008687907853269984665640564039457584007910;

    string public url= "https://media-exp1.licdn.com/dms/image/C4E03AQHzHKQ7e1TR7w/profile-displayphoto-shrink_400_400/0/1597227011285?e=1652313600&v=beta&t=P4ArJltA8l866VPf5wLrBcw7Au9uY9ODrZ0cDONbUD4";

    mapping (address => uint) public currencyBalance;
    mapping (address => uint) public bidBalance;
    mapping (address => uint) public bidChanged;
    address[] public owners;

    address public owner = 0xd5dbe0e636545F7FFea2C684e3c0cEf345d13389;
    address public author = 0xd5dbe0e636545F7FFea2C684e3c0cEf345d13389;
    address private bidder;

    uint bid = 0;
    uint startBid = 10;
    uint soldTickets = 0;

    bool auctionPending = false;

    function check() external view returns(bool,bool){
        return( (soldTickets*(3 gwei) <= address(this).balance), (soldTickets*(3 gwei) >= address(this).balance));
    }

    function buy(uint nbTickets) external payable{
        require(nbTickets < MAX_INT);
        require(msg.value == nbTickets * (3 gwei));
        currencyBalance[msg.sender]+= nbTickets;
        soldTickets+=nbTickets;
        if (!member(msg.sender, owners)) {
            owners.push(msg.sender);
        }
    }
    
    function sell(uint nbTickets) external{
        require(nbTickets<= currencyBalance[msg.sender]);
        require(nbTickets < MAX_INT);
        currencyBalance[msg.sender]-= nbTickets;
        msg.sender.transfer(nbTickets*(3 gwei));
        soldTickets-=nbTickets;
    }

    function newBid(uint nbTickets) external payable returns(uint){
        require(nbTickets <= currencyBalance[msg.sender]);
        if(!auctionPending) {
            bid = startBid-1;
            auctionPending = true;
        }

        currencyBalance[msg.sender]-= nbTickets;
        bidBalance[msg.sender]+= nbTickets;


        if(bidBalance[msg.sender]>bid)
        {
            bidder = msg.sender;
            bid = bidBalance[msg.sender];
        }

        return bidBalance[msg.sender];

    }

    function closeAuction() external payable returns(address){
        require(auctionPending);
        if(bid >= startBid) {
            currencyBalance[owner]+= bid;
            bidBalance[bidder]-=bid;
            owner = bidder;
            startBid = bid;

            uint length = owners.length;
            for(uint i; i<length;i++) {
                currencyBalance[owners[i]]+=bidBalance[owners[i]];
                bidBalance[owners[i]]=0;
            }

            auctionPending=false;

            return owner;
        }
    }

    function increaseMinimalPrice() external payable returns(uint){
        require(bidChanged[msg.sender]==0);
        require(msg.sender==owner);
        bidChanged[msg.sender]=1;
        startBid+=10;
        return startBid;
    }

    function giveForFree(address a) external payable returns(address){
        require(msg.sender==owner);
        owner = a;
        return owner;
    }

    function getBalance() external view returns(uint){
        return address(this).balance;
    }

    function getMaximalBid() external view returns(uint){
        return bid;
    }

    function getMaximalBidder() external view returns(address){
        return bidder;
    }

    function getMinimalPrice() external view returns(uint){
        return startBid;
    }

    function member(address s, address[] memory tab) pure private returns(bool){
        uint length= tab.length;
        for (uint i=0;i<length;i++){
            if (tab[i]==s) return true;
        }
        return false;
    }
}