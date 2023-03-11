// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EthDistributor {
    function distribute(address payable[] calldata _recipients) external payable {
        require(_recipients.length > 0, "Recipient list cannot be empty");
        uint256 value = msg.value / _recipients.length;
        for (uint256 i = 0; i < _recipients.length; i++) {
            _recipients[i].transfer(value);
        }
    }
}