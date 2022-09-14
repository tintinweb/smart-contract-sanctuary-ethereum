/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract BurekTransfer {
    function batchTransfer (address token, address[] memory list, uint amount) public returns (bool) {
        for (uint i = 0; i < list.length; i++) {
            IERC20(token).transferFrom(msg.sender, list[i], amount);
        }
        return true;
    }
}