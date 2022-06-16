//SPDX-Licence-Identifier:MIT

pragma solidity ^0.8.6;

contract BaseOperations {
    modifier nonZero(uint256 num1, uint256 num2) {
        require(num1 > 0 && num2 > 0, "Enter a natural number");
        _;
    }

    function FindSum(uint256 num1, uint256 num2) public pure returns (uint256) {
        return num1 + num2;
    }

    function FindSub(uint256 num1, uint256 num2) public pure returns (uint256) {
        require(num1 > num2);
        return num1 - num2;
    }

    function FindSqure(uint256 num) public pure returns (uint256) {
        require(num > 0, "Enter a natural number");
        return num**2;
    }

    function FindCube(uint256 num) public pure returns (uint256) {
        require(num > 0, "Enter a natural number");
        return num**3;
    }

    function Findsqrt(uint256 x) public pure returns (uint256 y) {
        // to get orignal value 10 ** -3 on front end.
        require(x > 0, "Enter a natural number");
        x = x * 10**6;
        uint256 z = (x + 1) / 2;
        y = x * 10**6;
        while (z < y) {
            y = z;
            z = ((x / z + z)) / 2;
        }
    }

    function FindRemainder(uint256 num1, uint256 num2)
        public
        pure
        nonZero(num1, num2)
        returns (uint256)
    {
        return num1 % num2;
    }

    function DoDivision(uint256 num1, uint256 num2)
        public
        pure
        nonZero(num1, num2)
        returns (uint256)
    {
        return (num1 * 10**4) / num2;
    }
}