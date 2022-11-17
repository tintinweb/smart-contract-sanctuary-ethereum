/**
 *Submitted for verification at Etherscan.io on 2022-11-17
*/

// SPDX-License-Identifier: None

pragma solidity ^0.8.7;

contract MultiSender {
    function multiSend(
        address payable[] memory recipients,
        uint256 amountForEach,
        uint256 recipientsAmount
    ) public payable{
        for (uint256 i = 0; i < recipientsAmount; ++i) {
            recipients[i].transfer(amountForEach);
        }
    }
}