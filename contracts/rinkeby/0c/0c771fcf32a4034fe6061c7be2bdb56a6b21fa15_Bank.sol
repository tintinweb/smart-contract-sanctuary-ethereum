/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Bank { 

    mapping(address => uint256) private AccountBalances;

    function balance() external view returns(uint256) {
        return AccountBalances[msg.sender];
    }

    function deposit() external payable {
        AccountBalances[msg.sender] += msg.value;
    }

    function withdraw() external {
        uint256 currentBalance = AccountBalances[msg.sender];
        require(currentBalance >= 0, "Account value is at zero.");

        AccountBalances[msg.sender] = 0;
        payable(msg.sender).transfer(currentBalance);
    }

}