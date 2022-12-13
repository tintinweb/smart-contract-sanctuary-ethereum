// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.17;

contract Blog {
    address payable public Owner;

    constructor () {
        Owner = payable(msg.sender);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw(uint _amount) public {
        require(msg.sender == Owner, "The call is not the owner.");
        Owner.transfer(_amount);
    }
}