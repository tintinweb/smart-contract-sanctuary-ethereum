// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.13;

error OutError();

contract Test {
    error InsideError();

    function TestOutError() external {
        revert OutError();
    }

    function TestInsideError() external {
        revert InsideError();
    }

    function TestStringError() external {
        revert("string error");
    }
}