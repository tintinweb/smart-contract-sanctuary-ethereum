/**
 *Submitted for verification at Etherscan.io on 2023-01-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;


contract whitelist {
     address owner;

     struct  white {
     string _type;
     string value;
     uint256 expired_date;
     }
    constructor() {
        owner = msg.sender;
    }

    mapping(bytes=> white) whites;

    function addWhitelist(string memory _type,string memory value,uint256  expired_date,bytes memory data) public isOwner{
        whites[data]= white(_type,value,expired_date);
    }

    function isWhite(bytes memory data) public view returns (bool){
      white storage w=  whites[data];
      uint256 old_time= w.expired_date; 
      uint256 new_time=block.timestamp;
      if(old_time>new_time){
          return true;
      }else{
          return false;
      }
     
    }
    modifier isOwner{
        require(msg.sender == owner, "You are not the owner");
        _;
    }


}