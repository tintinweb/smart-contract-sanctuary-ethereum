/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

pragma solidity >=0.4.22 <0.9.0;

contract HelloWorldContract {
    string public myStateVariable;

    constructor() {
        myStateVariable = "Test 1";
    }

    function updateVar() public {
        myStateVariable = "Test 2";
    }
}