/**
 *Submitted for verification at Etherscan.io on 2023-02-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

/**
 * @title Test
 * @dev Sets and Gets a uint variable called Pointer
 */
contract Test{

    uint256 public pointer;

    constructor() {
        pointer = 100;
    }

    function setPointer(uint256 _num) public {
        pointer = _num;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getPointer() external view returns (uint256) {
        return pointer;
    }
} 

// Goerli Deployment - 0x424E4e7003E8B8d7Ba734C2C6FA2d0e029D9FecC