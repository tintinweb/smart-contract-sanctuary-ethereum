/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

pragma solidity ^0.8.2;

contract testing {

    uint hello = 0;

    function writing(uint _num1, uint _num2) public {
        hello = _num1 + _num2;
    }

    function reading() public view returns(uint) {
        return hello;
    }
}