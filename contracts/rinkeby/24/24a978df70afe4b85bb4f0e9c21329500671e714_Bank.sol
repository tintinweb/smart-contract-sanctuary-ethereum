/**
 *Submitted for verification at Etherscan.io on 2022-08-06
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract Bank {

    mapping (address => uint) public balanceOf;
    uint goal = 100;

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
    }

    function withdraw(uint m) public {
        require(balanceOf[msg.sender] >= goal, "Error!");
        payable(msg.sender).transfer(m);
        balanceOf[msg.sender] -= m;
    }

}