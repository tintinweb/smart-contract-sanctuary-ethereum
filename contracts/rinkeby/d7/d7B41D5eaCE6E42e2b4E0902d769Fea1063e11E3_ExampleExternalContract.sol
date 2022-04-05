pragma solidity >=0.8.0 <0.9.0;

//SPDX-License-Identifier: MIT

contract ExampleExternalContract {

    bool public completed;
    event Received(uint);

    receive() external payable {
        emit Received(address(this).balance);
    }

    function complete() public payable {
        completed = true;
    }
}