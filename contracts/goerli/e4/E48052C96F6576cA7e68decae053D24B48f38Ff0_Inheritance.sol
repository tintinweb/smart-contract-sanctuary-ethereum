// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Inheritance {
    address payable owner;
    address heir;
    uint256 lastWithdrawal;

    constructor() {
        owner = payable(msg.sender);
        lastWithdrawal = block.timestamp;
    }

    function withdraw(uint256 _amount) public {
        require(msg.sender == owner, "Only the owner can withdraw funds.");
        require(_amount <= address(this).balance, "Insufficient funds.");
        lastWithdrawal = block.timestamp;
        owner.transfer(_amount);
    }

    function transferOwnership(address newOwner) public {
        require(msg.sender == heir, "Only the heir can transfer ownership.");
        require(block.timestamp - lastWithdrawal > 30 days, "Owner has withdrawn within the last month.");
        owner = payable(newOwner);
        heir = address(0);
    }

    function designateHeir(address newHeir) public {
        require(msg.sender == owner, "Only the owner can designate an heir.");
        heir = newHeir;
    }

    function checkInheritance() public view returns(address _owner, address _heir, uint256 _lastWithdrawal) {
        return (owner, heir, lastWithdrawal);
    }
}