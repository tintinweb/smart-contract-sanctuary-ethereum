// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Patreon
 * @dev Implements a decentralized version of patreon
 */

contract Payment {
    address immutable _owner = 0xF3fb3Cb8b34F5331B82219183c5AdEf40EE10ba5;

    function deposit(address _influencerAddress) external payable {
        //require(msg.value == _amount, "Insufficient funds");
        payable(_owner).transfer((msg.value * 5) / 100);
        payable(_influencerAddress).transfer((msg.value * 95) / 100);
    }
}