/**
 *Submitted for verification at Etherscan.io on 2023-03-10
*/

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8;

contract StoreEth {
    event Deposit(address indexed sender, uint256 amount, uint256 balance);

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function sendEth (address payable _to, uint256 _amount) external {
        _to.transfer(_amount);
    }
}