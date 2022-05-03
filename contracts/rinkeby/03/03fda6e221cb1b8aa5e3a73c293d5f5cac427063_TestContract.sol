/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.7;

interface TestInterface {
    function claimRewards(uint[] calldata tokenIds) external;
}

contract TestContract {
    function callByContract(TestInterface _contract, uint[] calldata tokenIds) external {
        _contract.claimRewards(tokenIds);
    }
}