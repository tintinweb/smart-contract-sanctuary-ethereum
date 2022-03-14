// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

error Unauthorized(address sender);

contract VendingMachine {
    address payable owner = payable(msg.sender);

    function withdraw() public {
        if (msg.sender != owner)
            revert Unauthorized(msg.sender);

        owner.transfer(address(this).balance);
    }
    // ...
}