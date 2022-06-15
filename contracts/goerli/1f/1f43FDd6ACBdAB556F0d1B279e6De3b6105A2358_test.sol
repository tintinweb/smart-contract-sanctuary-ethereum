//SPDX-Lincence-Identifier: MIT

pragma solidity ^0.8.6;

contract test {
    function checkLength(uint256[] calldata _values)
        public
        pure
        returns (uint256)
    {
        return _values.length;
    }

    function getGcd(uint256 _value1, uint256 _value2)
        public
        pure
        returns (uint256)
    {
        uint256 commonDivisorCurrent;
        for (uint256 i = 0; i < _value1; i++) {
            if (_value1 % i == 0 && _value2 % i == 0) {
                commonDivisorCurrent = i;
            }
        }
        return commonDivisorCurrent;
    }
}