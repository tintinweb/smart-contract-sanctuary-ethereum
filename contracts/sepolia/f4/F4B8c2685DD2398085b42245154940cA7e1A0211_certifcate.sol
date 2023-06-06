/**
 *Submitted for verification at Etherscan.io on 2023-06-05
*/

//SPDX-License-Identifier: MIT 
pragma solidity 0.8.17;

contract certifcate{

    
    address public owner;
   

    modifier checkLevel(uint8 _level) {
        require(_level<=3,
        "you input the wrong level");
       
        _;
        
    }
    modifier onlyOwner{
        require(owner == msg.sender,
        "you are not the owner");
        _;
    }
    struct Holder {
        string name;
        uint8 level ;
        
    }
    mapping (address => Holder) Holders;
    address[] public holderAcct;

    // event holdInfo(string name,
    //  uint8 level);



   function setHolders(address _address,string memory _name,uint8 _level)checkLevel(_level) onlyOwner public {
      Holders[_address].name = _name;
      Holders[_address].level = _level;
      holderAcct.push(_address);
    //   emit holdInfo(_name,_level);

    }
    function getHolders()external view returns(address[] memory){
        return holderAcct;
    }
   
    function getHolder(address _address)external view returns(string memory,uint8){
        return(Holders[_address].name, Holders[_address].level);
    }

    function countHolders()external view returns(uint){
        return holderAcct.length;
    }
    //incase the holders violate the rule we can delete his certificate to takes membership from him/her

    function deleteHolder(address _address) onlyOwner public{
        delete Holders[_address];
    } 


}