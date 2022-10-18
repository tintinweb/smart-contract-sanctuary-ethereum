/**
 *Submitted for verification at Etherscan.io on 2022-10-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.7.5;

interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Distribute {

    function distributes(address token, address[] memory tos, uint256[] memory amounts) external {
        uint256 length = tos.length;
        require(length == amounts.length, "length mismatch");

        for (uint256 index = 0; index < length; index ++)
            IERC20(token).transferFrom(msg.sender, tos[index], amounts[index]);
    }

    function distributesSameAmount(address token, address[] memory tos, uint256 amount) external {
        for (uint256 index = 0; index < tos.length; index ++)
            IERC20(token).transferFrom(msg.sender, tos[index], amount);
    }
}