/**
 *Submitted for verification at Etherscan.io on 2022-11-02
*/

// SPDX-License-Identifier: GPL-3.0


pragma solidity >=0.3.0 <0.9.0;

contract CastCrowdfunding {

    //Variable
    //address payable ownerAddress;
    address  owner;   
    string public name;
    //uint private   donation;
    uint public  balance;
    //string message = "Thank you for your cooperation";
  
  
      //Eventos
    event SetInt(uint set);
    event SetString(string set);
    
    //Mofdificadores
   modifier onlyOwner{
        require(msg.sender == owner);
        _; 
    }
    //Constructores
    function CastCrowdfunding() payable public{
        owner = msg.sender;

    }    



    function Donation(string memory _name, uint _donation) payable public {
        require(msg.value == _donation); 
        name = _name;      
        owner.transfer(address(this).balance);
        balance = balance + _donation;
    }

     function getBalance() view public returns(uint){
        
        return address(this).balance;
    }

     function Owners() view public returns(address){        
        return owner;
    }

 

}