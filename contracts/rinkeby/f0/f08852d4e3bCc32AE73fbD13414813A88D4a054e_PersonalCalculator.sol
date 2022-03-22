// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PersonalCalculator {
    mapping(address => int256) public valuesStored;
    function(int256, int256) internal pure returns (int256)[] operations;

    constructor() {
        operations.push(_sum);
        operations.push(_subtraction);
        operations.push(_divison);
        operations.push(_multiplication);
        operations.push(_modulo);
    }

    function _sum(int256 _a, int256 _b) internal pure returns (int256) {
        return _a + _b;
    }

    function _subtraction(int256 _a, int256 _b) internal pure returns (int256) {
        return _a - _b;
    }

    function _divison(int256 _a, int256 _b) internal pure returns (int256) {
        return _a / _b;
    }

    function _multiplication(int256 _a, int256 _b)
        internal
        pure
        returns (int256)
    {
        return _a * _b;
    }

    function _modulo(int256 _a, int256 _b) internal pure returns (int256) {
        return _a % _b;
    }

    function calculate(uint256 _operandNumber, int256 _number)
        external
        returns (int256)
    {
        return
            valuesStored[msg.sender] = operations[_operandNumber](
                valuesStored[msg.sender],
                _number
            );
    }
}