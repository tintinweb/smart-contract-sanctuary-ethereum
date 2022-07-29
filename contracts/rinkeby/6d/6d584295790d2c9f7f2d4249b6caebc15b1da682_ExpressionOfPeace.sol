/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

// import "hardhat/console.sol";

contract ExpressionOfPeace {
    string current_expression;

    constructor(string memory _expression) {
        // console.log("Deployed by: ", msg.sender);
        // console.log("Deployed with value: %s", _storedData);
        current_expression = _expression;
    }

    function set(string memory _expression) public {
        // console.log("Set value to: %s", x);
        current_expression = _expression;
    }

    function get() public view returns (string memory) {
        // console.log("Retrieved value: %s", storedData);
        return current_expression;
    }
}