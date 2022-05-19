/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract Faucet {
    mapping(address => uint) public amountWithdrawnPerAddress;

    function withdraw(uint _amount) public {
        require(_amount <= 0.1 * 10 ** 18);
        amountWithdrawnPerAddress[msg.sender] += _amount;
        payable(msg.sender).transfer(_amount);
    }

    // fallback function
    receive() external payable {}
}