// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract DeploymentOptimization1 {
    uint256 public number;
    uint256 public additionResult;

    function setNumber(uint256 _number) public {
        number = _number;
    }

    function setAdditionResult() public {
        additionResult = number + number;
    }
}
//gas cost 165889