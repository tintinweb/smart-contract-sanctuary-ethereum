/**
 *Submitted for verification at Etherscan.io on 2023-03-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

contract EthSplitter {
    address payable public address1 = payable(0x473F1953Db0AE110789Ca1c84561F1545d895c6C);
    address payable public address2 = payable(0x070a57ADAeDf31DCCE7885ecbBfd4e1D7a44969d);

    receive() external payable {
        require(msg.value > 0, "Invalid amount");

        uint256 amount = msg.value / 2;
        address1.transfer(amount);
        address2.transfer(amount);
    }
}