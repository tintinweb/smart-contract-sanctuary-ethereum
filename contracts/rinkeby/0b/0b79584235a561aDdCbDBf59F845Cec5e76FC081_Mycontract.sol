/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
contract Mycontract{


string _name ;
uint _balance ; 

constructor(string memory name,uint balancee){
    require(balancee>=500,"balance equal 500");
    _name = name;
    _balance = balancee;
}

function getbalance() public view returns (uint balance){
    
    return _balance;
}
}