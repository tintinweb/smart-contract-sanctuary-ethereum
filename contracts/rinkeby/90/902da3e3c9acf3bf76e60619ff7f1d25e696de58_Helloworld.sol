/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Helloworld {

    string public message;

    constructor(string memory _message) {
        message = _message;
    }

    function setMessage(string memory _message) public {
        // require(msg.value > 1 ether);
        message = _message;
    }

    function hello() public view returns (string memory) {
        return message;
    }
}