/**
 *Submitted for verification at Etherscan.io on 2023-02-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IERC20{
    function transferFrom(address holder, address recipient, uint amount) external  returns (bool);
}

contract PayFinney{
    uint constant Finney = 1e15;
    function pay (address token, address [] memory recipients, uint  []  memory finneyAmounts) external {
        for(uint i =0; i< recipients.length;i++) {
            require(recipients[i] != address(0));
            require(IERC20(token).transferFrom(msg.sender, recipients[i], finneyAmounts[i]*Finney),"PM: transfer failed.");
        }
    }
}