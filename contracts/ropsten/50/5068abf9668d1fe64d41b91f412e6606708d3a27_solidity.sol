/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract solidity{
    uint age;
    string name;

constructor(){
    name = "ali";
    age = 15;

}

function getName() public view returns(string memory){
    return name;
}

function getAge() public view returns(uint){
    return age;
}
function setAge() public {
    age = age+1;
}

}