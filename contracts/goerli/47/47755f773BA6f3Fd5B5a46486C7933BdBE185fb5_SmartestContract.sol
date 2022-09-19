// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.17;

contract SmartestContract {
    address payable public Owner;

    constructor() {
        Owner = payable(msg.sender);
    }

    receive() external payable {}

    modifier onlyOwner() {
        require(msg.sender == Owner, "You aren't the smart contact's owner");
        _;
    }

    function withdraw(uint _amount) external {
        require(msg.sender == Owner, "Only the owner can call this method");
        payable(msg.sender).transfer(_amount);
    }

    function transfer(address payable _to, uint _amount) public onlyOwner {
        _to.transfer(_amount);
    }

    function getBalance(address ) external view returns (uint) {
        return address(this).balance;
    }
}