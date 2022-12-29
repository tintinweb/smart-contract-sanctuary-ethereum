// SPDX-License-Identifier:MIT
pragma solidity ^0.8.10;

error ShouldBiggerThan10();

contract DeploymentOptimization10 {
    uint256 private number;
    uint256 private additionResult;

    function setNumber(uint256 _number) public {
        if (_number <= 10) {
            revert ShouldBiggerThan10();
        }
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
// gas cost 176887