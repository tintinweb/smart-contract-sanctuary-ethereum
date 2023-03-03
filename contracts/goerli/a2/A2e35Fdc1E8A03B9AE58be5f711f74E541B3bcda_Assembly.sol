/**
 *Submitted for verification at Etherscan.io on 2023-03-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract Assembly {
    function addAssembly(uint256 x, uint256 y) public pure returns (uint256) {
        assembly {
            let result := add(x, y)
            mstore(0x0, result)
            return(0x0, 32)
        }
    }
}