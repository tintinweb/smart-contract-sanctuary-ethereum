/**
 *Submitted for verification at Etherscan.io on 2023-01-25
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface IERC20 {
    function transfer(address recipient, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract Delego {
    function tokenTransfer(address token, address recipient, uint256 value) external {
        IERC20 erc20 = IERC20(token);
        require(erc20.transferFrom(msg.sender, address(this), value));
        require(erc20.transfer(recipient, value));
    }
}