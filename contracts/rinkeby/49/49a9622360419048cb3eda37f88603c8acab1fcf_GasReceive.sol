/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

// SPDX-License-Identifier: MIT
//
// Ask questions or comments in this smart contract,
// Whatsapp +923014440289
// Telegram @thinkmuneeb
// discord: timon#1213
// email: [email protected]
//
// I'm Muneeb Zubair Khan
//
pragma solidity ^0.8.0;

contract GasReceive {
    function sendCoin(address _to) external payable {
         payable(_to).transfer(msg.value);
    }

    function receiveCoin() external payable {}
    receive() external payable {}
}