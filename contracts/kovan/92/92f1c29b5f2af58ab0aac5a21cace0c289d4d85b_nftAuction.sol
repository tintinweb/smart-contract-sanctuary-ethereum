/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.8.12;

// Exploitez une faiblesse du contrat permettant Ã  un 
// compte de retirer plus d'Ã©ther que le montant envoyÃ©.

contract nftAuction{
    address author = msg.sender;
    address owner = msg.sender;
    address[] ownerHasIncresedPrice;
    string public url = "https://i.kym-cdn.com/entries/icons/mobile/000/028/526/honklhonk.jpg";
    uint public soldTickets;
    uint minimalPrice = 10;

    mapping (address => uint) public tiquetBalance;
    mapping (address => uint) public biddedTiquets;
    mapping (address => string) identity;
    address[] public bidders;
    
    function getBalance() external view returns(uint){
        return address(this).balance;
    }
    
    function buy(uint nbTiquets) external payable{
        require(msg.value == nbTiquets * (3 gwei));
        tiquetBalance[msg.sender]+= nbTiquets;
        soldTickets+= nbTiquets;
    }

    function newBid(uint nbTickets) external {
        require(nbTickets<= tiquetBalance[msg.sender]);
        if (!member(msg.sender, bidders)) {
            bidders.push(msg.sender);
        }
        tiquetBalance[msg.sender]-= nbTickets;
        biddedTiquets[msg.sender]+= nbTickets;
    }

    function closeAuction() public {
        require(getMaximalBid() >= getMinimalPrice());

        minimalPrice = getMaximalBid();

        tiquetBalance[owner]+=biddedTiquets[getMaximalBidder()];
        owner = getMaximalBidder();
        biddedTiquets[getMaximalBidder()] = 0;

        uint length= bidders.length;
        for (uint i=0; i<length; i++){
            if (biddedTiquets[bidders[i]]>0)  {
                tiquetBalance[bidders[i]] += biddedTiquets[bidders[i]];
                biddedTiquets[bidders[i]]=0;
            }
        }
        
    }

    function getOwner() external view returns(address) {
        return owner;
    }

    function giveForFree(address a) external {
        require(msg.sender==owner);
        owner=a;
    }


    function getMinimalPrice() public view returns(uint) {
        return minimalPrice;
    }

    function getMaximalBidder() public view returns(address) {
        uint length= bidders.length;
        address maxBidder;
        uint maxBid=0;
        for (uint i=0; i<length; i++){
            if (biddedTiquets[bidders[i]]>maxBid)  {
                maxBid = biddedTiquets[bidders[i]];
                maxBidder = bidders[i];
            }
        }
        return maxBidder;
    }


    function getMaximalBid() public view returns(uint) {
        return biddedTiquets[getMaximalBidder()];
    }

    function increaseMinimalPrice() external {
        require(msg.sender==owner && !member(msg.sender, ownerHasIncresedPrice));
        minimalPrice+=10;
        ownerHasIncresedPrice.push(msg.sender);
    }

    function check() external view returns(bool,bool){
        return( (soldTickets*(3 gwei) <= this.getBalance()), (soldTickets*(3 gwei) >= this.getBalance()));
    }


    function sellTiquet(uint nbTiquets) external{
        require(nbTiquets<= tiquetBalance[msg.sender]);
        tiquetBalance[msg.sender]-= nbTiquets;
        payable(msg.sender).transfer(nbTiquets*(3 gwei));
        soldTickets-= nbTiquets;

    }

    function member(address s, address[] memory tab) pure private returns(bool){
        uint length= tab.length;
        for (uint i=0;i<length;i++){
            if (tab[i]==s) return true;
        }
        return false;
    }

}