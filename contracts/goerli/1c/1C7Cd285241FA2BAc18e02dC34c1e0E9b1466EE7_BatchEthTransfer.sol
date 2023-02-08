// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract BatchEthTransfer {
    function send(
        address payable[] calldata recipients,
        uint256[] calldata amounts
    ) external payable {
        require(recipients.length == amounts.length, 'lengths dont match');
        for (uint256 i = 0; i < recipients.length; ) {
            (bool succ, ) = recipients[i].call{value: amounts[i]}('');
            require(succ, 'transfer failed');
            unchecked {
                ++i;
            }
        }
    }
}