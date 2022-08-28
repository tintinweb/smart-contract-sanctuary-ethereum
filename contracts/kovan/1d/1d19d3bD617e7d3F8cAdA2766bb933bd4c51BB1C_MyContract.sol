/**
 *Submitted for verification at Etherscan.io on 2022-08-28
*/

///SDPX-License-Identifier : MIT 
pragma solidity ^0.8.0;
contract MyContract{

//private 
string _name;
uint _temp;
uint _oxygen;
uint _pulse;



constructor(string memory name,uint temp ,uint oxygen, uint pulse){
    require(temp>0, "body temperature greater zero ");
    _name = name;
    _temp = temp;
    _oxygen = oxygen;
    _pulse = pulse;

}

}