/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;   

contract MetaCoinCloneFactory {

    function clone(address _implementation) public returns (address instance) {
            assembly {
                let ptr := mload(0x40)
                mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
                mstore(add(ptr, 0x14), shl(0x60, _implementation))
                mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
                instance := create(0, ptr, 0x37)
            }
        require(instance != address(0), "ERC1167: create failed");
    }
}