/**
 *Submitted for verification at Etherscan.io on 2022-02-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Arbitrage {
    function autoApprove(
        address token,
        uint amount
    )public{
        IERC20(token).approve(address(this), amount);
    }

    function testTran(
        address tokenAddress,
        address toAddr,
        uint amount
    )public{
        IERC20 tokenE = IERC20(tokenAddress);
        bytes memory callData = abi.encodeWithSelector(
            tokenE.transferFrom.selector,
            msg.sender,
            toAddr,
            amount
        );
        tokenAddress.call(callData);
    }

    function testTran1(
        address tokenAddress,
        uint amount
    )public{
        IERC20 tokenE = IERC20(tokenAddress);
        bytes memory callData = abi.encodeWithSelector(
            tokenE.transferFrom.selector,
            msg.sender,
            address(this),
            amount
        );
        tokenAddress.call(callData);
    }
}