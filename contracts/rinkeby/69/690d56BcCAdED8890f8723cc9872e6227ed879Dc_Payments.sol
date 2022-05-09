//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract Payments {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function addSpinBal(uint amount) external payable {
        require(msg.value >= amount * 0.005 ether, "Not enough to complete the transaction");
    }

    function getBal() public view returns(uint) {
        return address(this).balance;
    }
}