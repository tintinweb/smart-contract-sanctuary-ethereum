// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


contract GetCurrentBlockNumber {
    
    /**
     * @dev Return current block number.
     * @return Block number
     */
    function blockNum() public view returns (uint256) {
        return block.number;
    }
}