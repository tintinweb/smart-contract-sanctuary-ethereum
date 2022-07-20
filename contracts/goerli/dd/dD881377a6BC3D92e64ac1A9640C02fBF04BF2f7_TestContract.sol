// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestContract
{
    //int8 constant myInternalVar = 99;

    struct MyStruct
    {
        uint Number;
        bool Flag;
    }

    MyStruct s1;
    MyStruct s2;
    MyStruct s3;

    uint[3] count = [23,67,90];
    int8[3] num = [int8(45),78,34];  

    function Example1() private  returns (uint, bool)
    {

        s1 = MyStruct(22, false);
        return (s1.Number, s1.Flag);
    }

    function Example2() external  returns (uint, bool)
    {
        Example1();
        s2.Number = 100;
        s2.Flag = true;

        return (s2.Number, s2.Flag);
    }

    function Example3() external returns (uint, bool)
    {
        s3 = MyStruct({Number:555, Flag:true});
        return (s3.Number, s3.Flag);
    }

// uint8 -> 0 to 255
// int8 -> -128 to 127
    modifier verifyAge(uint age)
    {
        require(age >= 18, "You are under-age");
        _;
    }

    function ApplyForLicense(uint applicantAge) external verifyAge(applicantAge) pure returns(bool)
    {
        return true;
    }

    event LogInt(int);

    function EventDemo() external
    {
        emit LogInt(100);
        emit LogInt(200);
        emit LogInt(300);
    }
}