/**
 *Submitted for verification at Etherscan.io on 2022-03-27
*/

pragma solidity 0.8.13;//Solidity version

contract auctionContract {

//Declaration of variables
string constant public url="https://fr.m.wikipedia.org/wiki/Fichier:ETHEREUM-YOUTUBE-PROFILE-PIC.png"; //NFT
uint public soldTickets; // store the amount of all sent tickets
uint public minimalPrice=10; //initially, minimal price is fixed to 10 tickets
address public incMinimalPrice;//store the information that if the owner increase the minimal price once
address constant public addrAuthor=0xB3ec3A02356107Ac59b71021c85446b3b4732209; //Address of the author
address public addrOwner=msg.sender; //Address of the owner
bool public auctionOpened=false;//Know if auction is opened or not
uint public maximalBid=0;//Maximal bid
address public maximalBidder;//Address of the maximal bidder
mapping(address => uint) public currencyBalance;
address[] public owners;

//Buy a number of tickets
    function buy(uint nbTickets) external payable{
        require(msg.value == nbTickets * (3 gwei));
        currencyBalance[msg.sender]+= nbTickets;
        if (!member(msg.sender, owners)) {
            owners.push(msg.sender);
        }
    }

//Sell a number of tickets
    function sell(uint nbTickets) external payable {
        require(nbTickets<= currencyBalance[msg.sender]);
        currencyBalance[msg.sender]-= nbTickets;
        payable(msg.sender).transfer(nbTickets*(3 gwei));
        soldTickets=soldTickets-nbTickets;
    }
//Return the address of the current owner
    function getOwner() external view returns(address) {
        return addrOwner;
    }

//The owner can give the contract for free to another account
    function giveForFree(address a) external {
        require(msg.sender==addrOwner);
        addrOwner=a;
    }

//Return the current balance of the contract
    function getBalance() external view returns(uint) {
        return address(this).balance;
    }

//Make a new bid
    function newBid(uint nbTickets) external {
        require(nbTickets<=currencyBalance[msg.sender]);
        require(auctionOpened==false);
        maximalBid=maximalBid+nbTickets;
        auctionOpened=true;
    }

//Return the value of the current maximal bid in tickets
    function getMaximalBid() external view returns(uint) {
        return maximalBid;
    }

//Return the address of the current maximal bidder
    function getMaximalBidder() external view returns(address) {
        return maximalBidder;
    }

//Return the value of the current minimal price in tickets
    function getMinimalPrice() external view returns(uint) {
        return minimalPrice;
    }

//Permits to increase with 10 tickets the minimal price, can be done only once by each owner
    function increaseMinimalPrice() external {
        require(msg.sender==addrOwner);
        require(msg.sender!=incMinimalPrice);
        minimalPrice=minimalPrice+10;
        incMinimalPrice=msg.sender;
    }

//Close the auction
    function closeAUction() external {
        require(auctionOpened==true);
        require(maximalBid>=minimalPrice);
        currencyBalance[addrOwner]=currencyBalance[addrOwner]+maximalBid;
        addrOwner=maximalBidder;
        minimalPrice=maximalBid;
        maximalBid=0;
        maximalBidder=address(0);
        auctionOpened=false;
    }

//Must return the pair (true, true) to check
    function check() external view returns(bool,bool){
   return( (soldTickets*(3 gwei) <=  this.getBalance()),
           (soldTickets*(3 gwei) >=  this.getBalance()));
    }

    function member(address s, address[] memory tab) pure private returns(bool){
        uint length=tab.length;
        for(uint i=0;i<length;i++){
            if(tab[i]==s) return true;
        }
        return false;
    }
}