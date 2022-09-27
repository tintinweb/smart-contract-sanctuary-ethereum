/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract DCall {
    function dcall(bytes[] memory deployments, bytes[] memory callDatas) external {
        for (uint256 i = 0; i < deployments.length; ++i) {
            bytes memory deployCode = deployments[i];
            address target;
            assembly {
                target := create(0, add(deployCode, 0x20), mload(deployCode))
            }
            require(target != address(0), 'deployment failed');
            (bool b, bytes memory r) = target.delegatecall(callDatas[i]);
            if (!b) {
                assembly { revert(add(r, 0x20), mload(r)) }
            }
        }
    }
}