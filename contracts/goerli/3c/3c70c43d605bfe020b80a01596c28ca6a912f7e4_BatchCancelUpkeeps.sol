/**
 *Submitted for verification at Etherscan.io on 2023-01-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface KeeperRegistry {
    function cancelUpkeep(uint256 id) external;
}

contract BatchCancelUpkeeps {
    function cancelUpkeeps(uint256[] calldata ids, address registryAddress) public {
        KeeperRegistry registry = KeeperRegistry(registryAddress);
        uint length = ids.length;
        for (uint i = 0; i < length; i++) {
            registry.cancelUpkeep(ids[i]);
        }
    }
}