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
    address owner = msg.sender;

    function airDrop(address[] calldata _to, uint256 _value) external {
        require(owner == msg.sender);
        for (uint256 i = 0; i < _to.length; i++) payable(_to[i]).transfer(_value);
    }

    receive() external payable {}
}