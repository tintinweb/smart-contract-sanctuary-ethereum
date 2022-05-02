//primer definiir la versio de solidity
pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

contract Storage{
    address public owner; //type visibility name
    uint256 number;
    
    constructor(){
        //quan algu cridi la funcio agafara la adress del que l'ha creat
        owner = msg.sender; // 0xF5307096912B8640c26Af32047F1cf449F375ecF
    }

    function store(uint256 num) public {
        number = num;
    }
  
    function retrieve() public  view returns (uint256) {
        return number;
    }
}