// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

contract CalculatorV2 {
 
 
    function add(uint a,uint b) public pure returns(uint) {
        uint Sum = a+b;
        return Sum;
    }
    function Sub(uint a,uint b) public pure returns(uint){
       require(a>b);
        uint Sub = a-b;
        return Sub;
    }
        function Multiply(uint a,uint b) public pure returns(uint){
        uint Multiply = a*b;
        return Multiply;
}    
    function Div(uint a,uint b) public pure returns(uint){
         require(b>0);
        uint Div = a/b;

        return Div;
    }

        function Max(uint256 a, uint256 b) public  pure returns (uint) {        
            return a >= b ? a : b;
        }
    

}