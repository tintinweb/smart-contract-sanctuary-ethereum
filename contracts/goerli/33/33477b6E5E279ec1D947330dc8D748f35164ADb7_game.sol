// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
contract game {

    function Send() public payable {}

    function Transfer(address payable winner) external payable {
        winner.transfer(0.01 ether);
    }
}