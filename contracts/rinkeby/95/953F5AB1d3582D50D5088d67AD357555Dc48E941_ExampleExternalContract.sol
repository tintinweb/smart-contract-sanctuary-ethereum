// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract ExampleExternalContract {
    bool public completed;

    function complete() public payable {
        completed = true;
    }

    // function withdraw(address payable _to, uint256 amount) public payable {
    //     _to.transfer(amount);
    // }
}