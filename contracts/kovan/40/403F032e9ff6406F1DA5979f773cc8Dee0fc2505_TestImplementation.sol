/**
 *Submitted for verification at Etherscan.io on 2022-04-27
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
pragma abicoder v2;

contract TestImplementation {
    uint TOTAL_BORROWER_DEBT_BALANCE;
    uint TOTAL_ACTIVE_BALANCE_CURRENT_EPOCH;

    /**
    * @notice The total debt balance owed by borrowers.
    *
    * @return The number of tokens owed.
    */
    function getTotalBorrowerDebtBalance()
        external
        view
        returns (uint256)
    {
        return TOTAL_BORROWER_DEBT_BALANCE;
    }

    /**
   * @notice Get the current total active balance.
   */
    function getTotalActiveBalanceCurrentEpoch()
        public
        view
        returns (uint256)
    {
        return TOTAL_ACTIVE_BALANCE_CURRENT_EPOCH;
    }
}