/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

contract Task1 {
    uint32 number1;
    uint32 number2;


    function setValue(uint32 _num1,uint32 _num2) public {
        number1=_num1;
        number2=_num2;

    }

    function getValue() public view returns (uint32,uint32){
        return (number1, number2);
    }

    function math(uint32 _num1) public view returns (uint32,uint32){
        return (number1+_num1, number2+_num1);
    }
    function math2(int256 _num1,int256 _num2) public pure returns (int256){
        return _num1+_num2;
    }
}


contract Task2{
    uint32 number;
    function setNumberPublic(uint8 _number) public {
        setNumberInternal(_number);
    }
    function setNumberExternal(uint8 _number ) external {
        setNumberPrivate(_number);
    }
    function setNumberInternal(uint8 _number) internal{
        number=_number;
    }
    function setNumberPrivate(uint8 _number ) private{
        number =_number;
    }
    function getNumber() public view returns (uint32){
        return number;
    }
}


contract Task3{
    int256 number; 
    int256 iterator; 
    function setNumber(int256 _number) public returns(int256){
        number=_number;
        int256 _iterator;
        _iterator=iteration();
        return _iterator;
    }
    function iteration() public returns(int256){
        iterator++;
        return iterator; 
}
}


contract Task4{
    int256 sum; 
    int256 sub; 
    int256 mult; 
    int256 div;

    function start(int256 _number1, int256 _number2) public returns(int256, int256, int256, int256){
        addition(_number1,  _number2);
        subtraction(_number1,  _number2);
        multiplication(_number1,  _number2);
        division(_number1,  _number2);
        int256 _sum;
        int256  _sub;
        int256  _mult;
        int256  _div;
        ( _sum, _sub,  _mult,  _div) = getResult();
        return (_sum, _sub,  _mult, _div);
    }
    function addition(int256 _number1, int256 _number2)internal{
        sum=_number1+_number2;
    }
    function subtraction(int256 _number1, int256 _number2)internal{   
        sub=_number1-_number2;
    }
    function multiplication(int256 _number1, int256 _number2)internal{
        mult=_number1*_number2;
    }
    function division(int256 _number1, int256 _number2)internal{
        div=_number1/_number2;
    }
    function getResult()internal view returns(int256, int256, int256, int256){
        return (sum, sub,  mult,  div);
    }
}