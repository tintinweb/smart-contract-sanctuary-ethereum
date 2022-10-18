/**
 *Submitted for verification at Etherscan.io on 2022-10-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7 <0.9.0;

contract Tutorial {
    uint256 private totalAmount;

    function getAmount() external view returns (uint256 amount) {
        return totalAmount;
    }

    function changeAmountValue(uint256 _val) external {
        totalAmount = _val;
    }

    function getAddress() external view returns (address) {
        return address(this);
    }

    function getTime() external view returns (uint256) {
        return block.timestamp;
    }

    function currentSender() external view returns (address) {
        return msg.sender;
    }
}