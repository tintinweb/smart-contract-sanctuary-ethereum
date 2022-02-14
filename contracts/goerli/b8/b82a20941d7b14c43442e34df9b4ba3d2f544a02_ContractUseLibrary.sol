/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

struct Data {
    uint origin;
}

library LinkedLibrary {
    uint constant OFFSET = 10;

    function addOffset(uint _origin) public pure returns (uint) {
        return _origin + OFFSET;
    }

    function addOffset(Data storage _data) public view returns (uint) {
        return _data.origin + OFFSET;
    }

    function subOffset(Data memory _data) public pure returns (uint) {
        return _data.origin - OFFSET;
    }

    function regulateWithOffset(Data storage _data) public {
        _data.origin += OFFSET;
    }
}

contract ContractUseLibrary {
    using LinkedLibrary for uint;
    using LinkedLibrary for Data;

    Data data;

    constructor(uint val) {
        data.origin = val;
    }

    function addOffsetExample(uint _input) public pure returns (uint) {
        return _input.addOffset();
    }

    function addOffsetExample2() public view returns (uint) {
        return data.addOffset();
    }

    function subOffsetExample() public view returns (uint) {
        return data.subOffset();
    }

    function regulateWithOffsetExample() public returns (uint) {
        data.regulateWithOffset();
        return data.origin;
    }
}