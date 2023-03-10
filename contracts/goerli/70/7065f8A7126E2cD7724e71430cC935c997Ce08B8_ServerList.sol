/**
 *Submitted for verification at Etherscan.io on 2023-03-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        assert(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract ServerList is Owned {
    uint256[] public servers;

    function getServers() public view returns (uint256[] memory) {
        return servers;
    }

    function addServer(uint256[] memory newServers) external onlyOwner {
        servers = newServers;
    }

    function removeServerAtIndex(uint i) external onlyOwner {
        if (i >= servers.length) return;

        uint x = i;

        while (x < servers.length - 1) {
            servers[x] = servers[x + 1];
            x++;
        }

        servers.pop();
    }
}