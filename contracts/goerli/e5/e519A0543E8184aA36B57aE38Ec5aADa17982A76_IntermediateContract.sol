// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface TargetInterface {
    function attempt() external;
}

contract IntermediateContract {
    address public constant TARGET_CONTRACT_ADDRESS = 0xcF469d3BEB3Fc24cEe979eFf83BE33ed50988502;
    TargetInterface TargetContract = TargetInterface(TARGET_CONTRACT_ADDRESS);

    function callTarget() external {
        TargetContract.attempt();
    }
}