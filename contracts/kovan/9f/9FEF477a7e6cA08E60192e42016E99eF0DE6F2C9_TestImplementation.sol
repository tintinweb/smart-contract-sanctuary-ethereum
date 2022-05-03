/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
pragma abicoder v2;

contract TestImplementation {
    address borrower;
    uint256 oldAllocation;
    uint256 newAllocation;
    uint256 epochNumber;

    event ScheduledBorrowerAllocationChange(
        address indexed borrower,
        uint256 oldAllocation,
        uint256 newAllocation,
        uint256 epochNumber
    );

    /**
     * @notice Change the allocation of a certain borrower.
     */
    function setBorrowerAllocations() external {
        emit ScheduledBorrowerAllocationChange(borrower, oldAllocation, newAllocation, epochNumber);
    }
}