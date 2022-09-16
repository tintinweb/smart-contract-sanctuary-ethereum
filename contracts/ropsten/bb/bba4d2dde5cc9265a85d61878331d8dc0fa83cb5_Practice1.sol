pragma solidity ^0.8.12;

import "./IDataTypesPractice.sol";

contract Practice1 is IDataTypesPractice {
    function getInt256() external pure returns (int256)
    {
        return 12;
    }

    function getUint256() external pure returns (uint256)
    {
        return 134;
    }

    function getIint8() external pure returns (int8)
    {
        return 11;
    }

    function getUint8() external pure returns (uint8)
    {
        return 213;
    }

    function getBool() external pure returns (bool)
    {
        return true;
    }

    function getAddress() external view returns (address)
    {
        return address(this);
    }

    function getBytes32() external pure returns (bytes32)
    {
        return "Hello World!";
    }

    function getArrayUint5() external pure returns (uint256[5] memory)
    {
        return [uint256(1), 2, 3, 4, 5];
    }

    function getArrayUint() external pure returns (uint256[] memory)
    {
        uint[] memory arr = new uint[](1);
        arr[0] = 1;
        return arr;
    }

    function getString() external pure returns (string memory)
    {
        return "Hello World!";
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