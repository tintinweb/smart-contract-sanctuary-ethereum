/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.8.7;
pragma abicoder v2;


contract AuctionContract{

    address public author = msg.sender; 
    address private owner = msg.sender; 
    string public  URL = "http://.."; 
    uint private soldTickets = 0;  
    uint private price = 10;

    uint private bestMaxBid = 0;
    address private bestMaxBidder;

    //Variable pour savoir si l'enchere est en cours ou non 
    bool private InProgress = false;

    //Nombre de tickets qu'à l'utilisateur 
    mapping (address => uint) private HaveTickets;

    mapping (address => uint) private AuctionTickets;
    address[] private AddAuctionTickets; 

    mapping (address => uint) private user_price;
    address[] private user_increasePrice; 
    
    function buy(uint _nbTickets) external payable {
        require(msg.value == _nbTickets * (3 gwei));
        soldTickets+=_nbTickets;
        HaveTickets[msg.sender]+= _nbTickets;
    }

    function sell(uint _nbTickets) external {
        require(_nbTickets<= HaveTickets[msg.sender]);
        HaveTickets[msg.sender]-=_nbTickets;
        soldTickets-=_nbTickets; 
        payable (msg.sender).transfer(_nbTickets*(3 gwei));
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function clearAuction () private {
        bestMaxBid = 0;
        bestMaxBidder = address(0);
        for (uint i = 0; i < AddAuctionTickets.length; i++) {
            AuctionTickets[AddAuctionTickets[i]] = 0;
        }
        delete AddAuctionTickets;
    }

    function giveForFree(address _a) external {
        require(msg.sender == owner && _a != address(0)); 
        if (InProgress) {
            InProgress = false;
            clearAuction();
        }
        owner = _a; 
    }

    function getBalance() external view returns (uint){
        return address(this).balance;
    }

    //Fonction qui verifie si l'user est dans une liste ou non
    function check_user_list(address _user, address[] memory _tab) private pure returns (bool)
    {
        for (uint i = 0; i < _tab.length; i++){
            if(_tab[i] == _user)
            {
                return true;
            }
        }
        return false; 
    }

    function newBid( uint _nbTickets) external {
        //On enleve les tickets que l'user a déjà encheris 
        require(HaveTickets[msg.sender] - AuctionTickets[msg.sender] >= _nbTickets);
        AuctionTickets[msg.sender] += _nbTickets;
        if(!InProgress)
        {
            InProgress = true; 
            bestMaxBid = _nbTickets;
            bestMaxBidder = msg.sender;
          
        }else{
            if(bestMaxBid < AuctionTickets[msg.sender])
            {
                bestMaxBid = AuctionTickets[msg.sender];
                bestMaxBidder = msg.sender; 
            }
        }
        if(!check_user_list(msg.sender, AddAuctionTickets)){
            AddAuctionTickets.push(msg.sender);
        }
       
    }

    function getMaximalBid() external view  returns (uint){
        require(InProgress);
        return bestMaxBid;
    }

    function getMaximalBidder() external view  returns (address){
        require(InProgress);
        return bestMaxBidder;
    }

    function getMinimalPrice() external view  returns (uint){
        return price; 

    }

    function increaseMinimalPrice() external{
        require(msg.sender == owner); 
        if (!check_user_list(owner, user_increasePrice))
        {
            user_increasePrice.push(msg.sender);
            price +=10;
        }
    }

    function closeAuction() external{
      require(bestMaxBid >= price && InProgress);
      //On donne l'argent à l'ancien owner
      HaveTickets[owner] += bestMaxBid;
      //On change le owner
      owner = bestMaxBidder;
      //On retire l'argent au nouveau owner 
      HaveTickets[owner]-= bestMaxBid; 
      price = bestMaxBid; 
      clearAuction();
    }

    function check() external view returns(bool,bool){
        return( (soldTickets*(3 gwei) <= this.getBalance()), (soldTickets*(3 gwei) >= this.getBalance()));
    }   
}