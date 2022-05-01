/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;



// File: AssetRegistry.sol

contract AssetRegistry {
    // assetChoices records the proportions of different output assets
    // that a Union member would like to split their bribes between.
    // There is a maximum of 16 available assets, although not all may be
    // used. Any uint16 can be used to express the weights, which are
    // meant to be normalized afterwards.
    // So weights of [2, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    // and [50, 25, 0, 25, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    // would be equivalent.
    mapping(address => uint16[16]) public assetAllocations;

    function recordAllocation(uint16[16] calldata choices) external {
        assetAllocations[msg.sender] = choices;
    }

    function getAllocations(address[] calldata members)
        external
        view
        returns (uint16[16][] memory)
    {
        uint256 n = members.length;
        uint16[16][] memory allocations = new uint16[16][](n);
        for (uint256 i = 0; i < n; i++) {
            allocations[i] = assetAllocations[members[i]];
        }
        return allocations;
    }
}