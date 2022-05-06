// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

/** @title Test Smart Contract for Reduce Transaction Payload
 */

contract Payload {
    uint256 public param1;
    uint256 public param2;
    uint256 public param3;
    address public param4;
    uint256 public param5;
    uint256 public param6;

    uint256 private constant defaultValueForParam1 = 3000;
    uint256 private constant defaultValueForParam2 = 3000;
    uint256 private constant defaultValueForParam3 = 3000;
    address private constant defaultValueForParam4 = 0xF02Db5737949a0fe8Ff070399e419E3bad334A12;
    uint256 private constant defaultValueForParam5 = 3000;
    uint256 private constant defaultValueForParam6 = 3000;

    function M()
        public
    {
        param1 = defaultValueForParam1;
        param2 = defaultValueForParam2;
        param3 = defaultValueForParam3;
        param4 = defaultValueForParam4;
        param5 = defaultValueForParam5;
        param6 = defaultValueForParam6;
    }

    function M(uint _param1)
        public
    {
        param1 = _param1;
        param2 = defaultValueForParam2;
        param3 = defaultValueForParam3;
        param4 = defaultValueForParam4;
        param5 = defaultValueForParam5;
        param6 = defaultValueForParam6;
    }

    function M(uint _param1, uint _param2)
        public
    {
        param1 = _param1;
        param2 = _param2;
        param3 = defaultValueForParam3;
        param4 = defaultValueForParam4;
        param5 = defaultValueForParam5;
        param6 = defaultValueForParam6;
    }

    function M(uint _param1, uint _param2, uint _param3)
        public
    {
        param1 = _param1;
        param2 = _param2;
        param3 = _param3;
        param4 = defaultValueForParam4;
        param5 = defaultValueForParam5;
        param6 = defaultValueForParam6;
    }

    function M(uint _param1, uint _param2, uint _param3, address _param4)
        public
    {
        param1 = _param1;
        param2 = _param2;
        param3 = _param3;
        param4 = _param4;
        param5 = defaultValueForParam5;
        param6 = defaultValueForParam6;
    }

    function M(uint _param1, uint _param2, uint _param3, address _param4, uint _param5)
        public
    {
        param1 = _param1;
        param2 = _param2;
        param3 = _param3;
        param4 = _param4;
        param5 = _param5;
        param6 = defaultValueForParam6;
    }

    function M(uint _param1, uint _param2, uint _param3, address _param4, uint _param5, uint _param6)
        public
    {
        param1 = _param1;
        param2 = _param2;
        param3 = _param3;
        param4 = _param4;
        param5 = _param5;
        param6 = _param6;
    }
}