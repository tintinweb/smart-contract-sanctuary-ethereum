/**
 *Submitted for verification at Etherscan.io on 2023-02-16
*/

/* This is the smart contract for the Tender DApp. It consists of two contracts - 
   tender, and tenderFactory - which is used to declare instances of the 'tender'
   contract.
*/
pragma solidity ^0.4.17;

contract tenderFactory {
    address[] public deployedTenders;
    // deployedTenders stores the addresses of the deployed tenders
    function createTender(string description) public {
      address newTender = new Tender(description, msg.sender);
      deployedTenders.push(newTender);
    }
    /* createTender is used to deploy a new instance of the 'tender' contract - 
       it accepts the requirements of the tender as argument and deploys an
       instance with the msg.sender as manager
    */  

    function getDeployedTenders() public view returns(address[]){
        return deployedTenders;
    }
    /* getDeployedTenders is a function that returns the array of deployed tenders' 
       addresses.
    */
}

contract Tender{
    bool public complete;
    string public data;
    address public manager;
    /* manager => address of the manager/creator of the tender
       data => requirements of the tender 
       complete => status of whether the tender has BEEN AWARDED
    */
    struct Bid {
        address  bidder;
        uint bidAmount;
        string bid;
    }
    /* struct Bid is a type to hold the details of a bid made - containing
       the address of the bidder, the amount that the bid is made at, and the
       proposal of the bidder (bid).
    */
    struct hiddenBid {
        uint ID;
        uint bidAmount;
        string bid;
    }
    /* struct hiddenBid contains the bidAmount and bid members, but does not contain the 
       address of the bidder, to ensure that the awarding of a tender is an unbiased process
    */
    Bid[] private bids;
    hiddenBid[] public hiddenBids;
    Bid public winner;
    uint public winIndex;
    /* 1.bids consists of all the bids and is made private to ensure no bias.
       2.hiddenBids is the array of structures that contain bids without their addresses, for 
         the purpose of the govt choosing a bid
       3.winner consists of the address of the winning bidder and winIndex contains the index
    */
    modifier restricted()
    {
        require(msg.sender==manager);
        _;
    }
    // This modifier is used to check if the sender of the function call is the manager.
    constructor(string description, address creator) public
    {
        manager = creator;
        data = description;
    }
    // Constructor function of the tender contract.

    function getBidSummary(uint index) public view returns (address, uint, string) {
        return (
            bids[index].bidder,
            bids[index].bidAmount,
            bids[index].bid
        );
    }
    /* This function returns the details of the bidder, bidAmount and bid(proposal)
       only after the tender has been awarded, to ensure transparency in the system.
    */
    

    function makeBid(uint bidAmount, string desc) public
    {  require(!(msg.sender==manager));
       require(!complete);
        Bid memory newBid = Bid({
            bidder : msg.sender,
            bidAmount : bidAmount,
            bid : desc
        });
        bids.push(newBid);
        hiddenBid memory newhiddenBid = hiddenBid({
            ID : bids.length,
            bidAmount : bidAmount,
            bid : desc
        });
        hiddenBids.push(newhiddenBid);
    }

    /* This function is used to let a bidder make a bid, it creates a temporary instance
       of Bid and hiddenBid and initialised them and pushes them into the respective arrays.
    */
    
    function finalizeBid(uint index) public  {
        require(!complete);
        require(msg.sender==manager);
        winner = bids[index];
        winIndex = index;
        // winner.bidder.transfer(winner.bidAmount);
        msg.sender.transfer(address(this).balance);
        complete = true;   
    }

    /* finalizeBid is used to award the bid by passing an argument of the index of the bid,
       It is a payable function, the sender of the call passes some ether to the contract
       the bidAmount is sent to the chosen bidder, and the balance is sent back to the 
       manager of the tender.
    */

    function getSummary() public view returns (address, string, uint) {
        return(manager,
        data,
        bids.length);
    }
    function getBidCount() public view returns (uint) {
        return bids.length;
    }
    
    function verify() public view  {
      require(msg.sender==manager);
    }

    function verifyManager() public view returns (bool) {
        return(manager==msg.sender);
    }
    
    function status() public view returns(bool)
    {
        return complete;
    }


}