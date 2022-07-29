/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract DepoSafe {
    mapping(address => uint256) balances;

    receive() external payable {}

    function deposit() public payable {
        require(msg.value > 0, "Invalid Amount");
        balances[msg.sender] += msg.value;
    }

    function checkBalance() public view returns (uint256) {
        return balances[msg.sender];
    }

    function withdraw() public {
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal Failed");
    }
}