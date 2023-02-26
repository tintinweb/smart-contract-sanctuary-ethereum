/**
 *Submitted for verification at Etherscan.io on 2023-02-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract RevenueSplitter {
    address[] public receiverAddresses = [
        address(0x93C1e750d3F4131Ba30157610D535e9fbEC413d7),
        address(0x15B86f44478b839c49484487544B615021c940F8),
        address(0x5e866c08eb711872a84E3C94D6e1530d96Af68f3)
    ];
    uint256[] public receiverPcts = [
        50,
        25,
        25
    ];
    uint256 public denominator = 100;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    //@dev withdraws available balance
    function withdraw() external {
        require(msg.sender == owner, 'Unauthorized');
        uint256 balance = address(this).balance;
        for (uint256 i; i < receiverAddresses.length; i++) {
            payable(receiverAddresses[i]).transfer(receiverPcts[i] * balance / denominator);
        }
    }

    //@dev sets split
    function setSplit(address[] calldata _receiverAddresses, uint256[] calldata _receiverPcts, uint256 _denominator) external {
        require(msg.sender == owner, 'Unauthorized');
        require(_receiverAddresses.length == _receiverPcts.length, 'Array sizes do not match');
        receiverAddresses = _receiverAddresses;
        receiverPcts = _receiverPcts;
        denominator = _denominator;
    }
}