// SPDX-License-Identifier:MIT
pragma solidity ^0.8.10;

error ToSetYouHaveToInputTheNumberBiggerThan10();

contract DeploymentOptimization9 {
    uint256 private number;
    uint256 private additionResult;

    function setNumber(uint256 _number) public {
        if (_number <= 10) {
            revert ToSetYouHaveToInputTheNumberBiggerThan10();
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