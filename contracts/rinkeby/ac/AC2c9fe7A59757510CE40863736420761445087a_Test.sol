/**
 *Submitted for verification at Etherscan.io on 2022-02-26
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Test {

    string public hello;
    uint public num = 51;

    function setHello(string memory _hello) public {
        hello = _hello;
    }

    function sayHello() public view returns(string memory) {
        return hello;
    }

    receive() external payable {}

}