/**
 *Submitted for verification at Etherscan.io on 2022-10-29
*/

pragma solidity ^0.4.24;

contract class23 {

    uint256 public integer_1 = 123456;
    uint256 public integer_2 = 654321;
    string public string_1 = "Bang!";
    address public ownerAddr = 0xfeeDDaD9C1311FA5dC5d35C99aB852154a314e80;


    event setNumber(address ownerAddress, string mood);


    constructor() public{
        integer_2 = 666;
    }

    function fn1 (string x)public returns(string){

        string_1 = x;
        emit setNumber(ownerAddr, "in good moond !!!");
        return string_1;

    }

}