/**
 *Submitted for verification at Etherscan.io on 2022-07-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract TransferBalance {
    event Transfer(address indexed sender, address indexed receiver, uint amount);

    function transfer(address _receiver) public payable {
        (bool success,) = _receiver.call{value: msg.value}("");
        require(success, "failed to execute the transaction.");
        emit Transfer(msg.sender, _receiver, msg.value);
    }

}