// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.21 <0.9.0;

contract ClientReceipt {
    event Deposit(
        address indexed from,
        uint256 indexed id
    );

    function deposit(uint256 id) public {
        emit Deposit(msg.sender, id);
    }
}