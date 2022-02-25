/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Payble1 {

    mapping(address => uint) public map;

    
    function deposit() public payable {
        map[msg.sender] += msg.value;
    }

    function redeem(uint amount) public {
        if (map[msg.sender] > amount) {
            payable(msg.sender).transfer(amount);
            map[msg.sender] -= amount;
        }
    }
}