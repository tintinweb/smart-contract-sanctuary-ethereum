/**
 *Submitted for verification at Etherscan.io on 2022-05-29
*/

// File: codeapachi.sol


pragma solidity ^0.8.7;

// Lottery Contract 


contract lottery {
  
    //Golbal veriables 
     address public manger ;  
     address payable[] public Lotterybuyers ;  
     

     
    constructor(){
                  manger=0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    }
    //receive payable function for deposits 
    receive() payable external{
           require(msg.value >= 1 ether,'Not Minimum Value');
           require(msg.sender!= manger , 'Manger cant buy Tick');
           Lotterybuyers.push(payable(msg.sender));
    }
    // showing balance
    function getblance() view public returns(uint){
        require(msg.sender==manger,'Not manger');
        return address(this).balance;
    }
    // genreating Random Winner
    function random() public view returns(uint){
       return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,Lotterybuyers.length)));
    }
    //Return Lotterybuyers All
    function TotalNumberOfBuyer() public view returns(uint){
        return Lotterybuyers.length;
    }
    // Winner selecting 
    function Winer() public {
        require(msg.sender==manger);
        require(Lotterybuyers.length>=3);
        address payable Winner ;
        uint r = random();
        uint index = r % Lotterybuyers.length;
        Winner = Lotterybuyers[index];
        Winner.transfer(getblance());
    }
    // Transfer to Winner and clear 
    function ReloadLottery() public {
        require(msg.sender==manger);
        Lotterybuyers=new address payable[](0);
    }

    
}