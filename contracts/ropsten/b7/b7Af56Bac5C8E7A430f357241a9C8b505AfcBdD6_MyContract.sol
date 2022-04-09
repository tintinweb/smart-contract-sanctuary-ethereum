/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract MyContract{

//private

string  _name;
uint _money;

constructor(string memory name, uint money ){
    
    _name = name;
    _money = money;
}

function getMoney() public view returns(uint money){
    return _money;
}



    
}