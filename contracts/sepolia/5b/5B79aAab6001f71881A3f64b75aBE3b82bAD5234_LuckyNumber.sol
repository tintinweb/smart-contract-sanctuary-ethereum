/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;


contract LuckyNumber {




    uint256 private _randomFromUser= 9999;

     address private _owner;


     mapping(string => uint) private _records;

    constructor(){
         _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "LuckyNumber: Only owner can call this function" );
        _;
    }


    function gen_luckNum(string memory random_str1,string memory random_str2,string memory ticket) public  onlyOwner   returns (bool) {
   
  
    uint ret= uint(keccak256(abi.encodePacked(random_str1, block.timestamp,_randomFromUser, blockhash(block.number),random_str2)));
        ret *=ret ;
        _records[ticket] = ret;
       

        return true;
    } 


    //everyone can check the luck number record
    function check_record(string memory ticket) public  view  returns (uint) {
    
        return _records[ticket];
    } 

    //any one can increase random seek to make sure the result can not be control by owner
    function increase() public     returns (bool) {
        _randomFromUser++;
        return true;
    }
    
   
  
   

}