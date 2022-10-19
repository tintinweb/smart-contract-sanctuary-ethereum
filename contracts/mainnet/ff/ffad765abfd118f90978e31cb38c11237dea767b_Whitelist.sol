/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

// SPDX-License-Identifier: MIT
// File: contracts/IWhitelist.sol


pragma solidity 0.8.15;

contract Whitelist {
    address public ownerAddress;

    mapping(address => bool) public whitelistedAddresses;

    modifier onlyOwner() {
        require(msg.sender == ownerAddress, "Only owner address");
        _;
    }

    constructor() {
        ownerAddress = msg.sender;
    }

    function addAddresses(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; ++i) {
            if (!whitelistedAddresses[addresses[i]])
                whitelistedAddresses[addresses[i]] = true;
        }
    }
}