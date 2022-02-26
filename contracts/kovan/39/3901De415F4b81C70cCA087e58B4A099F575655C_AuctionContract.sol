/**
 *Submitted for verification at Etherscan.io on 2022-02-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
pragma abicoder v2;

contract AuctionContract{
    address author = msg.sender;
    address owner = msg.sender;
    bool auction = false;
    uint soldTickets=0;
    uint minPrice= 10;//en nb de Tickets
    uint MaxBid=0;
    uint Pressed=0;
    address MaxBidder;

    string URL="https://imgur.com/98n1HQK";
    mapping (address => uint) public currencyBalance;
    mapping (address => bool) public alreadyIncrease;


    //Demande 3 Gwei par tickets et prends en paramétre le nombre de Tickets a acheter
    function buy(uint nbTickets) external payable{    
        require(msg.value == nbTickets * (3 gwei));
        currencyBalance[msg.sender]+= nbTickets;
        soldTickets+=nbTickets;
    }

    //Vends ces tickets pour 3Gwei
    function sell(uint nbTickets) external {
        require(nbTickets>0);
        require(address(this).balance>=nbTickets*(3 gwei));
        require(nbTickets<= currencyBalance[msg.sender]);
        currencyBalance[msg.sender]-= nbTickets;
        soldTickets-= nbTickets;
        payable(msg.sender).transfer(nbTickets*(3 gwei));
    }

    //retourne le owner
    function getOwner() external view returns(address){
        return owner;
    }
    //le owner peut donner a qui il veut 
    function giveForFree(address a) external{
        require(owner == msg.sender);
        owner = a;
    }
    //Retourne la valeut totale du contrat
    function getBalance() external view returns(uint){
        return address(this).balance;
    }
    //retourne l'addresse de la plus grosse mise
    function getMaximalBidder() external view returns(address){
        return MaxBidder;
    }
    //retourne la valeur de la plus grosse muse
    function getMaximalBid() external view returns(uint){
        return MaxBid;
    }
    //retourne le prix minimal en tickets
    function getMinimalPrice() external view returns(uint){
        return minPrice;
    }
    //propose une nouvelle enchere et valide si supérieur a l'ancienne
    function newBid(uint nbTickets) external{
        require(currencyBalance[msg.sender]>= nbTickets);
        require(currencyBalance[msg.sender]> MaxBid);
         if(!auction) {
            MaxBidder=msg.sender;
            auction=true;
        }
        else{   
           currencyBalance[MaxBidder]+=MaxBid;
        }
        currencyBalance[msg.sender]-=nbTickets;
        MaxBid=nbTickets;
        MaxBidder=msg.sender;
        
    }
    //aumente de 10 ticket le prix mnimum pour finir les enchere
    //rendre l'augment unique par owner
    function increaseMinimalPrice() external{
        require(msg.sender==owner);
        if(!alreadyIncrease[msg.sender]){
            minPrice+=10;
            alreadyIncrease[msg.sender]=true;
        }
    }

    function closeAuction() external{
        require(MaxBid>= minPrice);
        require(auction);
        currencyBalance[owner]+=MaxBid;
        owner=MaxBidder;

        MaxBidder=0x0000000000000000000000000000000000000000;
        minPrice=MaxBid;
        MaxBid=0;
        auction=false;
    }

    function check() external view returns(bool,bool){
        return((soldTickets*(3 gwei) <= this.getBalance()),(soldTickets*(3 gwei) >= this.getBalance()));
    }
    
    //Utilité ?
    function pressMePlease() external{
        Pressed+=1;
    }
    function howManyTimePress() external view returns(uint){
        return Pressed;
    }
    function isItEnoughtPress() external view returns(bool){
        return (Pressed > minPrice*2);
    }

}