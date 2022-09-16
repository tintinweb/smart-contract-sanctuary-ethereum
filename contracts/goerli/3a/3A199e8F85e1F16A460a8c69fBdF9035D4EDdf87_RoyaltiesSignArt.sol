/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract RoyaltiesSignArt {
    event newDeposit(address _sender, uint256 _amount);

    receive() external payable {
        emit newDeposit(msg.sender, msg.value);
    }
}