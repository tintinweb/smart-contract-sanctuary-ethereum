/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

pragma solidity ^0.8.3;

contract Calc{
    uint8 public val=0;
   
    event mine(string,uint8);

    function add (uint8 ValA,uint8 ValB) public returns(uint){
        val = ValA + ValB;
        emit mine("the Addtion is : " , val);
        return val;        
    }
    function sub (uint8 ValA,uint8 ValB) public returns(uint){
        val = ValA - ValB;
        emit mine("the Subcribstion is : " , val);
        return val;
    }

    function dev (uint8 ValA,uint8 ValB) public returns(uint){
        val = ValA / ValB;
        emit mine("the Divide is : " , val);
        return val;
    }

    function mul (uint8 ValA,uint8 ValB) public returns(uint){
        val = ValA * ValB;
        emit mine("the Multiplication is : " , val);
        return val;
    }
}