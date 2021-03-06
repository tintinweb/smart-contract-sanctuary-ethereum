/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.5;

contract DebugNoCheck {
    
    struct Action {
        uint256 value;
        address to;
        address proposer;
        bool executed;
        bytes data;
        address conditionTarget;
        bytes conditionData;
        bytes conditionExpectedState;
        uint256 conditionExecTime;
    }
    
    event Called(bytes returnedData);
 
     
    function proposeAndExecuteAction(
        address actionTo,
        uint256 actionValue,
        bytes calldata actionData,
        bytes calldata conditionData,
        bytes calldata conditionExpectedState,
        address conditionTarget,
        string calldata details,
        uint256 conditionExecTime
    ) external returns (bytes memory retData) {
        // No calls to zero address allows us to check that proxy submitted
        // the proposal without getting the proposal struct from parent moloch
        require(actionTo != address(0), "invalid actionTo");

        Action memory action = Action({
            value: actionValue,
            to: actionTo,
            proposer: msg.sender,
            executed: false,
            data: actionData,
            conditionTarget: conditionTarget,
            conditionData: conditionData,
            conditionExpectedState: conditionExpectedState,
            conditionExecTime: conditionExecTime
        });

        if(action.conditionTarget != address(0)) {
            (bool conditionSuccess, bytes memory conditionRetData) =
                action.conditionTarget.call{value: 0}(action.conditionData);
            require(conditionSuccess, "Condition call failed");
            emit Called(conditionRetData);
            require(
                conditionRetData.length == action.conditionExpectedState.length,
                "Condition return does not match expected state length"
            );
            //for (uint256 i = 0; i < conditionRetData.length; i++) {
            //    require(conditionRetData[i] == action.conditionExpectedState[i], "Condition return does not match expected state");
            //}
            return conditionRetData;

        }
        return retData;
        
    }


    
}