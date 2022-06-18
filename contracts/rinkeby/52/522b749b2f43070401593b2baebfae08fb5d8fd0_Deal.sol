/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

contract Deal {
    address public dealAddress;
    uint public amount;
    uint public lastTime = block.timestamp;
    event newInfo(address indexed, address indexed, uint);

    function makeDeal(address _dealAddress, uint _amount) public {
        require (block.timestamp > lastTime + 30, "Cool down bro");
        dealAddress = _dealAddress;
        amount = _amount;
        lastTime = block.timestamp;
        emit newInfo(msg.sender, dealAddress, amount);
    }
}