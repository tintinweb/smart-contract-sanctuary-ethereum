// SPDX-License-Identifier:MIT
pragma solidity ^0.8.10;

contract DeploymentOptimization2 {
    uint256 private number;
    uint256 private additionResult;

    function setNumber(uint256 _number) public {
        number = _number;
    }

    function setAdditionResult() public {
        additionResult = number + number;
    }
}
//gas cost 136537