//SPDX-Licence-Identifier: MIT

import "./MathExttended.sol";

pragma solidity ^0.8.6;

contract Factory {
    MathExttended[] public FactoryMath;

    constructor() {
        createMathExttended();
    }

    function createMathExttended() public {
        MathExttended mathExttended = new MathExttended();
        FactoryMath.push(mathExttended);
    }
}

//SPDX-Licence-Identifier: MIT

import "./IMathExtended.sol";

pragma solidity ^0.8.6;

contract MathExttended is IMathExtended {
    function add(uint256 _value1, uint256 _value2)
        public
        pure
        override
        returns (uint256)
    {
        return _value1 + _value2;
    }

    function mulDiv(
        uint256 _value1,
        uint256 _value2,
        uint256 _value3
    ) public pure override returns (uint256) {
        return (_value1 * _value2 * (10**4)) / (_value3);
    }

    function addBulk(uint256[] calldata _values)
        public
        pure
        override
        returns (uint256)
    {
        uint256 sum;

        for (uint256 i = 0; i < _values.length; i++) {
            sum = sum + _values[i];
        }

        return sum;
    }

    function isPrime(uint256 _value) public pure returns (bool) {
        uint256 count = 0;
        for (uint256 i = 2; i < _value; i++) {
            if (_value % i == 0) {
                count += 1;
            }
        }

        return count > 1 ? false : true;
    }

    function getGcd(uint256 _value1, uint256 _value2)
        public
        pure
        returns (uint256)
    {
        uint256 till = _value1 > _value2 ? _value1 : _value2;
        uint256 commonDivisorCurrent;
        for (uint256 i = 2; i < till; i++) {
            if (_value1 % i == 0 && _value2 % i == 0) {
                commonDivisorCurrent = i;
            }
        }
        return commonDivisorCurrent;
    }

    function swapAwesome(uint256 _value1, uint256 _value2)
        public
        pure
        returns (uint256, uint256)
    {
        return (_value2, _value1);
    }
}

pragma solidity ^0.8.6;

interface IMathExtended {
    function add(uint256 _value1, uint256 _value2) external returns (uint256);

    function mulDiv(
        uint256 _value1,
        uint256 _value2,
        uint256 _value3
    ) external returns (uint256);

    function addBulk(uint256[] calldata _values) external returns (uint256);
}