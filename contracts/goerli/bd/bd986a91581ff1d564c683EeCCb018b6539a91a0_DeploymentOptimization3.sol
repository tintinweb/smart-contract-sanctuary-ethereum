// SPDX-License-Identifier:MIT
pragma solidity ^0.8.10;

contract DeploymentOptimization3 {
    uint256 public number;
    uint256 public additionResult;

    function setNumber(uint256 _number) public {
        number = _number;
    }

    function getNumber() public view returns (uint256) {
        return number;
    }

    function setAdditionResult() public {
        additionResult = number + number;
    }

    function getAdditionResult() public view returns (uint256) {
        return additionResult;
    }
}
//gas cost 187759