/**
 *Submitted for verification at Etherscan.io on 2022-10-29
*/

pragma solidity ^0.4.24;

contract class23 {

    uint256 public integer_1 = 123456;
    uint256 public integer_2 = 654321;
    string public string_1 = "Bang!";


    event setNumber(string _from);


    constructor() public{
        integer_2 = 666;
    }

    function fn1 (string x)public returns(string){

        string_1 = x;
        emit setNumber(string_1);
        return string_1;
        
    }

}