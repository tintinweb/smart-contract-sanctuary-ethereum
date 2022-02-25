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

    function redeem() public {
        if (map[msg.sender] > 0) {
            payable(msg.sender).transfer(map[msg.sender]);
        }
    }
}