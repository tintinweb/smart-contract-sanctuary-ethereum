/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

// SPDX-License-Identifier: UNLICENCE

pragma solidity ^0.8.15;

contract MyContract{
    uint256 public x = 1;
    string public sentence = 'Welcome';
    bool public clicked = false;

    function setX(uint256 _x) public {
        x = _x;
    }
    function setSentence(string memory _sentence) public{
        sentence = _sentence;
    }

    function click() public{
        if (clicked == false){
            clicked = true;}
        else if (clicked == true){
            clicked = false;}
    }
}