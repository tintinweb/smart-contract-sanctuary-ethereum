/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Test {

    uint test = 0;

    uint8 constant HAPPINESS = 0;
    uint8 constant HIGIENE = 1;
    uint8 constant HUNGER = 2;

    struct TestStruct{
        uint32[3] testFirstArray;
        uint32[3] testSecondArray;
    }

    TestStruct[] testStructs;

    // mapping(uint8 => uint32) public testFirstMap;
    // mapping(uint8 => uint32) public testSecondMap;

    // function uslessAdd256(uint256 value) external returns(uint256){
    //     test++;
    //     return value + value;
    // }

    // function uslessMul256(uint256 value) external returns(uint256){
    //     test++;
    //     return value << 1;
    // }

    // function addElemToAttay(uint32 testInput)public{
    //     testArray[test] = testInput;
    //     test++;
    // }

    // function testMapGeneration() public{
    //     mapping(uint8 => uint32) memory testNewMap;
    //     testNewMap[HAPPINESS] = 123;
    //     testNewMap[HIGIENE] = 123;
    //     testNewMap[HUNGER] = 123;
    //     testFirstMap = testNewMap;
    //     testSecondMap = testNewMap;
    // }

    // function changeFirstMap() public{
    //     testFirstMap[HAPPINESS]++;
    // }


    // function testArrayGeneration() public{
    //     uint32[3] memory testArray;
    //     testArray[HAPPINESS] = 111;
    //     testArray[HIGIENE] = 222;
    //     testArray[HUNGER] = 333;
    //     TestStruct memory t = TestStruct(testArray, testArray);
    //     testStructs.push(t);
    // }

    // function changeFirstMap() public{
    //     testStructs[0].testFirstArray[0]++;
    // }

    // function getTest() public view returns( TestStruct memory){
    //     return testStructs[0];
    // }

    // TEST 3/4
    // function test1(uint256 value) public  pure returns(uint256){
    //     return (value >> 1) + (value >> 2);
    // }

    // function test2(uint256 value) public pure  returns(uint256){
    //     return ((value >> 1) + value) >> 1;
    // }

    // function test3(uint256 value) public  pure returns(uint256){
    //     return value*3/4;
    // }


    function test1(uint256 value) public  pure returns(uint256){
        return value/4;
    }

    function test2(uint256 value) public pure  returns(uint256){
        return value >> 2;
    }


}