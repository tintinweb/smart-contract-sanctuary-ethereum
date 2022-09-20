/**
 *Submitted for verification at Etherscan.io on 2022-09-20
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract a {

uint256 one;    
string two;

    constructor(uint256 val, string memory sval) {
        one = val;
        two = sval;
    }


event eventB(address indexed thisaddress, string b);

function setone (uint256 val) external {

one = val;

}

function getone (uint256 getval) external view returns (uint256)   {

return one;

}

function fire() public {

emit eventB(msg.sender, "fired now");


}

}