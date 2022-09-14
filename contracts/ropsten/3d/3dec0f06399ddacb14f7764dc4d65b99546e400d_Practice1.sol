pragma solidity ^0.8.12;

import "./IDataTypesPractice.sol";

contract Practice1 is IDataTypesPractice {
    int256 intVariable = 12;

    function getInt256() external view returns (int256)
    {
        return intVariable;
    }

    uint256 uintVariable = 134;

    function getUint256() external view returns (uint256)
    {
        return uintVariable;
    }

    int8 int8Variable = 11;

    function getIint8() external view returns (int8)
    {
        return int8Variable;
    }

    uint8 uint8Variable = 213;

    function getUint8() external view returns (uint8)
    {
        return uint8Variable;
    }

    bool boolVariable = true;

    function getBool() external view returns (bool)
    {
        return boolVariable;
    }

    address addressVariable = address(this);

    function getAddress() external view returns (address)
    {
        return addressVariable;
    }

    bytes32 bytes32Variable = "Hello World!";

    function getBytes32() external view returns (bytes32)
    {
        return bytes32Variable;
    }

    uint256[5] arrUint5Variable = [1, 2, 3, 4, 5];

    function getArrayUint5() external view returns (uint256[5] memory)
    {
        return arrUint5Variable;
    }

    uint256[] arrUintVariable = [5, 2, 5, 4, 5];

    function getArrayUint() external view returns (uint256[] memory)
    {
        return arrUintVariable;
    }

    string stringVariable = "Hello World!";

    function getString() external view returns (string memory)
    {
        return stringVariable;
    }

    function getBigUint() external pure returns (uint256)
    {
        uint256 v1 = 1;
        uint256 v2 = 2;
    unchecked {
        return v1 - v2;
    }
    }
}