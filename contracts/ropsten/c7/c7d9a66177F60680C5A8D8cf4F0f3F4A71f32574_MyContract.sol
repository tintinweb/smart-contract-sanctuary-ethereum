// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract MyContract {
    uint256 public num;
    event Log(string operation, uint256 num);

    // no constructor
    function initialize(uint256 _num) external {
        num = _num;
    }

    // add 1
    function add() external {
        num += 1;
        emit Log("Addition", num);
    }

    // substract 1
    function substract() external {
        require(num > 0, "Cannot substract from uint 0");
        num -= 1;
        emit Log("Substraction", num);
    }
}