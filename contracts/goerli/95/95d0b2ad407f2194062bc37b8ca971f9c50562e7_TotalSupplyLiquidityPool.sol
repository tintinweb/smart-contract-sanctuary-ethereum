/**
 *Submitted for verification at Etherscan.io on 2023-01-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

library SafeAddSubDiv {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
}

interface ERC20_SLIM {
    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract TotalSupplyLiquidityPool {
    using SafeAddSubDiv for uint256;

    address private _TOKEN;
    address private _OWNER;
    uint256 private _TEST;

    constructor(
        address token,
        address ownerAddress
    ) {
        _TOKEN = token;
        _OWNER = ownerAddress;
        _TEST = 0;
    }

    function tokenContract() external view returns (address) {
        return _TOKEN;
    }

    function ownerContract() external view returns (address) {
        return _OWNER;
    }

   
    function test1(uint256 tokenValue) external {
        _TEST += 1;
        ERC20_SLIM(_TOKEN).transferFrom(msg.sender, _OWNER, tokenValue);
    }
}