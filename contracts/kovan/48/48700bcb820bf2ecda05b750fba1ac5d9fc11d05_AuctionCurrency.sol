/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

pragma solidity >=0.7.0 <0.8.0;

contract AuctionCurrency{
     string public url = "https://ae01.alicdn.com/kf/H3aa2daece560427da6d4f847519a16b5Z/Peinture-l-huile-de-femme-sur-toile-noir-et-chair-Art-africain-affiches-et-imprim-s.jpg_Q90.jpg_.webp";
     address public author = address(this);
     address   payable owner =  msg.sender;
     mapping (address => uint)  currencyBalance;
     mapping (address => uint)  offres;
     uint public soldTickets = 0;
     address[]  paticipant;
     uint cpt = 0;
     uint minimalPrice = 10;

     function buy(uint nbticket) external payable{
        require(msg.value == nbticket * (3 gwei));
        currencyBalance[msg.sender]+= nbticket;
    
    }

    function sell(uint nbticket) external{
        require(nbticket <= currencyBalance[msg.sender]);
        currencyBalance[msg.sender]-= nbticket;
        msg.sender.transfer(nbticket*(3 gwei));
    }

    function getOwner() external view returns(address){
        return owner;
    }

    function giveForFree(address a) external{
        require(msg.sender == owner);
         owner = payable(a);
    }

    function getBalance() external view returns(uint){
        return address(this).balance;
    }
    
    function newBid(uint nbTickets) external{
        require(nbTickets <= currencyBalance[msg.sender]);
         if (!member(msg.sender, paticipant)) {
            paticipant.push(msg.sender);
        }

        if(soldTickets == 0){
          offres[msg.sender] = nbTickets;
          soldTickets = nbTickets;
        }
        else{
            soldTickets = soldTickets + nbTickets;
            offres[msg.sender] = nbTickets;

        }
    }


     function getMaximalBid() external view  returns(uint){
        uint length = paticipant.length;
        uint max = minimalPrice;
        for (uint i=0; i<length; i++){
            if(offres[paticipant[i]] > max){
               max = offres[paticipant[i]];
            }
        }
        return max;
    }

    function getMaximalBidder() external view returns(address){
        uint length = paticipant.length;
        uint max = this.getMaximalBid();
        address win = address(this);
        for (uint i=0; i<length; i++){
            if(offres[paticipant[i]] ==  max){
              win =  paticipant[i];
            }
        }
        return win;
    }

    function getMinimalPrice() external view returns(uint){
        uint length = paticipant.length;
        uint min = minimalPrice;
        for (uint i=0; i<length; i++){
            if(offres[paticipant[i]] < min){
               min = offres[paticipant[i]];
            }
        }
        return min;
    }

    function member(address s, address[] memory tab) pure private returns(bool){
        uint length = tab.length;
        for (uint i=0;i<length;i++){
            if (tab[i]==s) return true;
        }
        return false;
    }
    
    function increaseMinimalPrice() external  returns(uint){
        require(cpt == 0);
        cpt = 1;
        minimalPrice = minimalPrice + 10;
        return minimalPrice;
    }

    function closeAuction() external {
        address winner = this.getMaximalBidder();
        uint max = this.getMaximalBid();
        owner.transfer(max*(3 gwei));
        currencyBalance[winner]-= max;
        owner = payable(winner);
        uint length = paticipant.length;
        for (uint i=1; i<length; i++){
           delete offres[paticipant[i]];  
        }
        delete paticipant;
        //soldTickets = 0;
        cpt = 0;
        minimalPrice = max;

    }


    function check() external view returns(bool,bool){
        return( (soldTickets*(3 gwei) <= this.getBalance()),
        (soldTickets*(3 gwei) >= this.getBalance()));
    }






    
}