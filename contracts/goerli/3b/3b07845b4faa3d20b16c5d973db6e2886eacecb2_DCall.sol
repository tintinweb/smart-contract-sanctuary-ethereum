// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract DCall {
    enum CallType {
        Call,
        DelegateCall
    }
    struct DCallOp {
        bytes deployment;
        address to;
        bytes callData;
        CallType callType;
    }

    address public caller;

    function dcall(DCallOp[] memory ops) external {
        caller = msg.sender;
        for (uint256 i = 0; i < ops.length; ++i) {
            DCallOp memory op = ops[i];
            if (op.deployment.length > 0) {
                bytes memory deployment = op.deployment;
                assembly {
                    mstore(add(op, 0x20), create(0, add(deployment, 0x20), mload(deployment)))
                }
                require(op.to != address(0), 'deployment failed');
            }
            bool b;
            bytes memory r;
            if (op.callType == CallType.Call) {
                (b, r) = op.to.call(op.callData);
            } else {
                (b, r) = op.to.delegatecall(op.callData);
            }
            if (!b) {
                assembly { revert(add(r, 0x20), mload(r)) }
            }
        }
    }
}