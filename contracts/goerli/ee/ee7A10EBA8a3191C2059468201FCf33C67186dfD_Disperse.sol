// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Disperse {
    // Disperse Ether to multiple recipients with the given values
    function disperseETH(address[] memory _recipients, uint256[] memory _values) external payable {
        uint256 length = _recipients.length;
        
        // Ensure the length of recipients and values arrays are the same
        require(length == _values.length, "Arrays have different lengths");

        // Disperse the specified amounts to the recipients
        for (uint256 i = 0; i < length; i++) {
            // Ensure no overflows occur while transferring
            require(address(this).balance >= _values[i], "Insufficient contract balance");
            (bool success, ) = _recipients[i].call{value: _values[i]}("");
            require(success, "Transfer failed");
        }

        // Refund any remaining balance to the sender
        uint256 remainingBalance = address(this).balance;
        if (remainingBalance > 0) {
            (bool success, ) = msg.sender.call{value: remainingBalance}("");
            require(success, "Refund failed");
        }
    }
}