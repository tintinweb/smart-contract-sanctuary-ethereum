/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

pragma solidity ^0.8.13;

contract Switch {
    bool public test;

    function testSwitch() public {
        test = !test;
    }

    function viewTest() public view returns (bool) {
        return test;
    }
}