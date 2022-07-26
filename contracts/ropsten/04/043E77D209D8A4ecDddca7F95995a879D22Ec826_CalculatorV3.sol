// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

contract CalculatorV3 {
 
 
    function addition(uint a,uint b) public pure returns(uint) {
        uint Sum = a+b;
        return Sum;
    }
    function Subtraction(uint a,uint b) public pure returns(uint){
       require(a>b);
        uint S = a-b;
        return S;
    }
        function Multiplym(uint a,uint b) public pure returns(uint){
        uint m = a*b;
        return m;
}    
    function Division(uint a,uint b) public pure returns(uint){
         require(b>0);
        uint Div = a/b;

        return Div;
    }

        function Max(uint256 a, uint256 b) public  pure returns (uint) {        
            return a >= b ? a : b;
        }
        function Min(uint256 a, uint256 b) public  pure returns (uint) {        
            return a <= b ? a : b;
        }
    

}