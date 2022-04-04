/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract April {

    bool isSolved;
    address public solvedBy;
    bool public claimed;

    mapping (bytes32 => uint256) public ops;

    constructor() {
        ops["add(uint256,uint256)"] = asPtr(add);
        ops["sub(uint256,uint256)"] = asPtr(sub);
        ops["mul(uint256,uint256)"] = asPtr(mul);
        ops["div(uint256,uint256)"] = asPtr(div);
    }

    function solved() public {
        require(isSolved, "!solved");
        require(!claimed, "winner already claimed!");
        solvedBy = tx.origin;
        claimed = true;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {unchecked{
        return a + b;
    }}

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {unchecked{
        return a - b;
    }}

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {unchecked{
        return a * b;
    }}

    function div(uint256 a, uint256 b) internal pure returns (uint256) {unchecked{
        return a / b;
    }}

    function action(uint256[][] memory op_and_inputs) public returns (uint256) {
        require(!isSolved, "Already solved");
        uint256 prev = 0;
        for (uint256 i; i < op_and_inputs.length; i++) {
            uint256 op = op_and_inputs[i][0];
            uint256 a = op_and_inputs[i][1];
            // if a is uint256 max, that means replace it with previous output
            if (a == type(uint256).max) {
                a = prev;
            }
            uint256 b = op_and_inputs[i][2];
            // if b is uint256 max, that means replace it with previous output
            if (b == type(uint256).max) {
                b = prev;
            }
            prev = asOp(op)(a, b);
        }
        return prev;
    }

    function asOp(uint256 ptr) internal pure returns (function(uint256, uint256) returns (uint256) op) {
        assembly ("memory-safe") {
            op := ptr
        }
    }

    function asPtr(function(uint256, uint256) returns (uint256) op) internal pure returns (uint256 ptr) {
        assembly ("memory-safe") {
            ptr := op
        }
    }
}