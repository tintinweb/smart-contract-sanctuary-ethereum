/**
 *Submitted for verification at Etherscan.io on 2023-02-25
*/

pragma solidity 0.8.13;
// SPDX-License-Identifier: MIT

contract PaymentsDistributor {
    function send(uint256[] memory amounts, address[] memory addresses) public payable {
        for (uint256 i = 0; i < amounts.length; ++i) {
            (bool sent,) = addresses[i].call{value: amounts[i]}("");
            require(sent, "Failed to send ETH");
        }
    }
}