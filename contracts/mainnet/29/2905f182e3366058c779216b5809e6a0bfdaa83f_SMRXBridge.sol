// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./SMRXToken.sol";
import "./Bridge.sol";

contract SMRXBridge is Bridge {
    SMRXToken public token;

    constructor(address tokenAddress, uint256 tax) Bridge(tax) {
        token = SMRXToken(tokenAddress);
    }

    function _deposit(uint256 amount) internal override {
        token.transferFrom(_msgSender(), owner(), amount);
    }

    function _withdraw(address account, uint256 amount) internal override {
        token.transferFrom(_msgSender(), account, amount);
    }
}