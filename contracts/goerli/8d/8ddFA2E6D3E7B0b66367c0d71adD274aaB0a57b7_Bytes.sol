/**
 *Submitted for verification at Etherscan.io on 2023-02-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Bytes {
    uint public hero;
    struct MyStruct {
        string name;
        uint[2] nums;
    }

    function changeHero(uint _num) public {
        hero = _num;
    }

    function test() public pure returns (uint) {
        return 5;
    }

    function testWrite(uint _num) public pure returns (uint) {
        return _num;
    }

    function encode(
        uint num,
        address addr,
        uint[] calldata arrNums,
        MyStruct calldata myStruct
    ) public pure returns (bytes memory) {
        return abi.encode(num, addr, arrNums, myStruct);
    }

    function decode(
        bytes memory data
    )
        public
        pure
        returns (
            uint num,
            address addr,
            uint[] memory arrNums,
            MyStruct memory myStruct
        )
    {
        (num, addr, arrNums, myStruct) = abi.decode(
            data,
            (uint, address, uint[], MyStruct)
        );
    }
}