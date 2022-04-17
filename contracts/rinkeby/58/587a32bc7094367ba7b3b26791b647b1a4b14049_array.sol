//SPDX-License-Identifier: GPL -3.0
pragma solidity >0.8.0 <=0.9.0;

contract array {
   // uint[4] public staticarray= [10,20,30,40];

    uint[] public dynamicarray;

    function pushelement(uint element) public
    {
        dynamicarray.push(element);
    } 
    function popelement() public
    {
        dynamicarray.pop();
    }
    function dynamicarraylength() public view returns(uint)
    {
        return dynamicarray.length;
    }

    }