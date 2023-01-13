/**
 *Submitted for verification at Etherscan.io on 2023-01-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IContract {
    function attempt() external;
}

contract Winner {
    address public owner;
    address public attemptContract;
    constructor(){
        owner=msg.sender;
        attemptContract=0xcF469d3BEB3Fc24cEe979eFf83BE33ed50988502;
    }

    function callAttempt() external{
        IContract(attemptContract).attempt();
    } 
}