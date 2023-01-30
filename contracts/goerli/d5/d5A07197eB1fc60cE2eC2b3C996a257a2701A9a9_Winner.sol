/**
 *Submitted for verification at Etherscan.io on 2023-01-30
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IContract {
    function attempt() external;
}

contract Winner {
    function winAttempt(address cont) external {
        IContract(cont).attempt();
    } 
}