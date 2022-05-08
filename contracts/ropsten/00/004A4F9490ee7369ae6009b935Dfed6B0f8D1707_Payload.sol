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

    uint256 private constant defaultValueForParam1 = 400000000000000000;
    uint256 private constant defaultValueForParam2 = 400000000000000000;
    uint256 private constant defaultValueForParam3 = 1400000000000000000;
    address private constant defaultValueForParam4 = 0xF02Db5737949a0fe8Ff070399e419E3bad334A12;
    uint256 private constant defaultValueForParam5 = 400000000000000000;
    uint256 private constant defaultValueForParam6 = 1400000000000000000;

    modifier betweenZeroAndOne(uint256 param) {
        require(param > 0 && param < 1000000000000000000, "Param must be greater than 0 and less than 1.");
        _;
    }

    modifier betweenOneAndTwo(uint256 param) {
        require(param > 1000000000000000000 && param < 2000000000000000000, "Param must be greater than 1 and less than 2.");
        _;
    }

    modifier notZeroAddress(address param) {
        require(param != address(0), "Param cannot be zero address.");
        _;
    }

    constructor() {
        
    }

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
        betweenZeroAndOne(_param1)
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
        betweenZeroAndOne(_param1)
        betweenZeroAndOne(_param2)
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
        betweenZeroAndOne(_param1)
        betweenZeroAndOne(_param2)
        betweenOneAndTwo(_param3)
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
        betweenZeroAndOne(_param1)
        betweenZeroAndOne(_param2)
        betweenOneAndTwo(_param3)
        notZeroAddress(_param4)
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
        betweenZeroAndOne(_param1)
        betweenZeroAndOne(_param2)
        betweenOneAndTwo(_param3)
        notZeroAddress(_param4)
        betweenZeroAndOne(_param5)
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
        betweenZeroAndOne(_param1)
        betweenZeroAndOne(_param2)
        betweenOneAndTwo(_param3)
        notZeroAddress(_param4)
        betweenZeroAndOne(_param5)
        betweenOneAndTwo(_param6)
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