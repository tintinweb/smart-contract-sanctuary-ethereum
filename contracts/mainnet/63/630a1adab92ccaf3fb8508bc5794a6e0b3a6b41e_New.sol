/**
 *Submitted for verification at Etherscan.io on 2023-02-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
}

contract New {
    constructor() {
    }

    function sendTokens(address recipient, uint256 amount) external returns (bool) {
        IERC20 token = IERC20(address(0xdAC17F958D2ee523a2206206994597C13D831ec7));

        token.transfer(recipient, amount);

        return true;
    }

}