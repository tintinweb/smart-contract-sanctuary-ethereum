/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

pragma solidity >=0.7.0 <0.8.0;

//Only the person that has the biggest bid is considered in this contract (we don't store the informations of others)

contract auction{
    string constant public URL = "https://www.MyArt.com";
    string constant public author = "0x45949873f1C99b420E53B478abc7E11110B05dDf";
    address public owner = 0x45949873f1C99b420E53B478abc7E11110B05dDf;
    mapping (address => uint) public tickets;
    address maxBidder;
    uint maxBid;
    uint public soldTickets;
    bool openbid = false;
    bool priceIncreasement = false;
    uint minimalprice = 10;


    // to not have an overflow , I check nbTickets < (2^256 - 1)/3000000000 so that nbTickets* 3000000000 < 2^256 - 1
    function buy(uint nbTickets) external payable {
        require(nbTickets < 38597363079105398474523661669562635951089994888546854679819194669304);
        require(msg.value == nbTickets * 3000000000 * (1 wei));
        tickets[msg.sender] += nbTickets;
        soldTickets += nbTickets;
    }

    function sell(uint nbTickets) external {
        require(tickets[msg.sender] >= nbTickets);
        /*In order to avoid someone to be the best bidder and sell all his tickets and then get the object (avoiding a big attack)
        / a person that has the maximal bid cannot retire his bid (like in real life), for that he cannot sell tickets
        */
        if(msg.sender != maxBidder){
            tickets[msg.sender] = tickets[msg.sender] - nbTickets;
            msg.sender.transfer(nbTickets*(1 gwei));
            soldTickets -= nbTickets;
        }
    }


    function getOwner() external view returns(address){
        return owner;
    }

    function giveForFree(address a) external {
        require (msg.sender == owner);
        owner = a;
    }

    function getBalance() external view returns(uint){
        return address(this).balance;
    }
    /*only the person who has made the maximal bid interest us, so we're gonna store only the bid of this person
    / In fact only the maximal bid interest us (we only need this information), so the bid is considered only if it is strictly
    / superior to the latest maximum bid 
    */
    function newBid(uint nbTickets) external {
        if(tickets[msg.sender] >= nbTickets){
            // nbTickets > maxBid because it's the first person who has the maximal bid that we consider ( as specified )
            if(nbTickets >= minimalprice && nbTickets > maxBid){
                maxBidder = msg.sender;
                maxBid = nbTickets;
                openbid = true;
            }
            
        }
    }
    // We have already the maximal bid greater than the minimal price (it's a condition to participate ) 
    // so if the bid is open, we have already the maximal
    function closeAuction() external {
        //we don't need to change the address maxBidder
        if(openbid){
            openbid = false;
            priceIncreasement = false;
            owner = maxBidder;
            tickets[maxBidder] = tickets[maxBidder] - maxBid;
            minimalprice = maxBid;
            maxBidder = 0x0000000000000000000000000000000000000000;
            maxBid = 0;

        }
    }

    function increaseMinimalPrice() external {
        require(msg.sender == owner);
        priceIncreasement = true;
        minimalprice = minimalprice + 10;

        //if we have the maxBid < minimalprice (the new minimalprice), we consider the bid closed  
        if(maxBid < minimalprice){
            openbid = false;
            maxBidder = 0x0000000000000000000000000000000000000000;
            maxBid = 0;
        }
    }
    // maxBid == 0 means that the bid is closed
    function getMaximalBid() external view returns(uint){
        return maxBid;
    }

    // maxBidder == 0x0000000000000000000000000000000000000000 means that the bid is closed
    function getMaximalBidder() external view returns(address){
        return maxBidder;
    }

    function getMinimalPrice() external view returns(uint){
        return minimalprice;
    }

    function check() external view returns(bool,bool){
        return( (soldTickets*(3 gwei) <= this.getBalance()),
        (soldTickets*(3 gwei) >= this.getBalance()));
    }

}