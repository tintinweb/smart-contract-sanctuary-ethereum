/**
 *Submitted for verification at Etherscan.io on 2022-11-27
*/

// SPDX-License-Identifier: none
pragma solidity >=0.7.0 <0.9.0;

contract HoleyBookCounter {
    uint8 public countCyclic;
    uint8 private MAX_PER_CYCLE = 2**4;
    uint256 public cyclesCompleted;

    function incrementCounter() public {
        unchecked {
            countCyclic++; // gas: 30962
            if (countCyclic % MAX_PER_CYCLE == 0) {
                cyclesCompleted++;
            }
        }
    }
}