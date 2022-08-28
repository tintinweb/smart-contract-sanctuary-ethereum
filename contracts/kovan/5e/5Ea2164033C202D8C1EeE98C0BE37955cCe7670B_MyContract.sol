/**
 *Submitted for verification at Etherscan.io on 2022-08-28
*/

///SDPX-License-Identifier : MIT 

pragma solidity ^0.8.0;
contract MyContract{


string _name;
uint _temp;



constructor(string memory name,uint temp){
    require(temp>0, "body temperature greater zero ");
    _name = name;
    _temp = temp;

}
function getTemp() public view returns (uint temp){
    return _temp;
}

}