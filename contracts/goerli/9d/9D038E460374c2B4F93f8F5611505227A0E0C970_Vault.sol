// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Vault {
    address payable public owner;

    event Deposit(uint256 amount, uint256 when);
    event Withdrawal(uint256 amount, uint256 when);

    constructor() {
        // owner = payable(msg.sender);
        owner = payable(0x65FDCEf343c2bf2544859a438309749Fc873Aa95);
    }

    function deposit() public payable {
        emit Deposit(msg.value, block.timestamp);
    }

    function withdraw() public {
        require(msg.sender == owner, "you aren't the owner");

        emit Withdrawal(address(this).balance, block.timestamp);

        owner.transfer(address(this).balance);
    }
}