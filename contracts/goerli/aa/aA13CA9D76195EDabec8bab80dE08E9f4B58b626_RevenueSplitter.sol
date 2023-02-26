/**
 *Submitted for verification at Etherscan.io on 2023-02-26
*/

/**
 *Submitted for verification at Etherscan.io on 2023-02-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract RevenueSplitter {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    //@dev withdraws available balance
    function withdraw() external {
        require(msg.sender == owner, 'Unauthorized');
        address[3] memory receiverAddresses = [
            address(0x93C1e750d3F4131Ba30157610D535e9fbEC413d7),
            address(0x15B86f44478b839c49484487544B615021c940F8),
            address(0x5e866c08eb711872a84E3C94D6e1530d96Af68f3)
        ];
        uint256[3] memory receiverPcts = [
            uint256(5000),
            uint256(2500),
            uint256(2500)
        ];
        uint256 denominator = 10000;
        uint256 balance = address(this).balance;
        for (uint256 i; i < receiverAddresses.length; i++) {
            payable(receiverAddresses[i]).transfer(receiverPcts[i] * balance / denominator);
        }
    }

    //@dev sets new owner who can withdraw
    function setOwner(address _newOwner) external {
        require(msg.sender == owner, 'Unauthorized');
        owner = _newOwner;
    }

}