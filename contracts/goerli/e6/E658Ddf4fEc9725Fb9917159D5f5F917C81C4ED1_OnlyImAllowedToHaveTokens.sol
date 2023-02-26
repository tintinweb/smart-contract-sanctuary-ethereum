// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract OnlyImAllowedToHaveTokens {
    function bye() external {
        selfdestruct(payable(msg.sender));
    }
}