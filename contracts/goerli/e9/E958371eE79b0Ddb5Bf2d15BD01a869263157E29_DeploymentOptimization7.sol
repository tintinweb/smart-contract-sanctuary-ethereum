// SPDX-License-Identifier:MIT
pragma solidity ^0.8.10;

contract DeploymentOptimization7 {
    uint256 private number;
    uint256 private additionResult;

    function setNumber(uint256 _number) public {
        number = _number;
        setAdditionResult();
    }

    function getNumber() public view returns (uint256) {
        return number;
    }

    function setAdditionResult() internal {
        additionResult = number + number;
    }

    function getAdditionResult() public view returns (uint256) {
        return additionResult;
    }
}
// gas cost 164593