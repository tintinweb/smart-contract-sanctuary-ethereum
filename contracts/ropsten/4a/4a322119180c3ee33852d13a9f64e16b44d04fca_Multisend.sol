/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

contract Multisend {
  
    function multisendToken(
        IERC20 token,
        address[] memory recipients,
        uint256[] memory values
    ) external {
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++) total += values[i];
        require(token.transferFrom(msg.sender, address(this), total));
        for (uint256 i = 0; i < recipients.length; i++)
        token.transfer(recipients[i], values[i]);
    }
}