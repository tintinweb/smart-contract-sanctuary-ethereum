/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract factoryExample {
    address public token0;
    address public token1;

    constructor(address _token0, address _token1) {
        token0 = _token0;
        token1 = _token1;
    }

    function exchangeToken0ToToken1(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");

        // Transfer Token0 from sender to this contract
        require(
            IERC20(token0).transferFrom(msg.sender, address(this), amount),
            "Token0 transfer failed"
        );

        // Increase the allowance of Token1 for the contract
        IERC20(token1).increaseAllowance(msg.sender, amount);

        // Transfer the equivalent amount of Token1 to the sender
        require(
            IERC20(token1).transferFrom(address(this), msg.sender, amount),
            "Token1 transfer failed"
        );
    }

    function exchangeToken1ToToken0(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");

        // Transfer Token1 from sender to this contract
        require(
            IERC20(token1).transferFrom(msg.sender, address(this), amount),
            "Token1 transfer failed"
        );

        // Increase the allowance of Token0 for the contract
        IERC20(token0).increaseAllowance(msg.sender, amount);

        // Transfer the equivalent amount of Token0 to the sender
        require(
            IERC20(token0).transferFrom(address(this), msg.sender, amount),
            "Token0 transfer failed"
        );
    }
}

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
}