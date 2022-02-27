pragma solidity ^0.8.4;

contract Callee {
    uint[] public values;

    function getValue(uint initial) external pure returns(uint) {
        return initial + 150;
    }
    function storeValue(uint value) external payable {
        values.push(value);
    }
    function getValues() external view returns(uint) {
        return values.length;
    }
}