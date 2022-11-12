/**
 *Submitted for verification at Etherscan.io on 2022-11-12
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract RandomEater {
    function eatMyMoney(uint parameter) external payable {
        require(parameter != 9, "We don't like nine");
        uint256 refund = parameter % 2 == 0 ? msg.value / 2 : msg.value;
        payable(msg.sender).transfer(refund);
    }
}