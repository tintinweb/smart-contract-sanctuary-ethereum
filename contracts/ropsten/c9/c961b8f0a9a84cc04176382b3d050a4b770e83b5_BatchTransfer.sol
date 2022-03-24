// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Refundable.sol";

contract BatchTransfer is Refundable {
    // using SafeERC20 for IERC20;

    constructor(
        address owner_
    ) Refundable(owner_) {
        
    }

    function sendETH(
        address payable[] memory payees,
        uint256[] memory amounts
    ) public payable {
        uint256 txCount = payees.length;
        require(txCount == amounts.length, "Params not match");

        uint256 remain = msg.value;

        for (uint256 i = 0; i < txCount; i++) {
            remain -= amounts[i];
            // payees[i].transfer(amounts[i]);
            (bool success, ) = payees[i].call{ value: amounts[i] }("");
            require(success, "Transfer failed");
        }
    }

    function sendToken(
        address token,
        address payable[] memory payees,
        uint256[] memory amounts
    ) public payable {
        uint256 txCount = payees.length;
        require(txCount == amounts.length, "Params not match");

        for (uint256 i = 0; i < txCount; i++) {
            // safeTransferFrom is required
            IERC20(token).transferFrom(msg.sender, payees[i], amounts[i]);
        }
    }
}