// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract ExampleContract {
    address public owner;
    event Deposit(uint256 value);
    event Withdraw(address indexed receiver, uint256 value);

    constructor() public {
        owner = msg.sender;
    }


    function deposit() external payable {
        //thank you)
        emit Deposit(msg.value);
    }

    function withdrawNative(address payable receiver, uint256 amount) public {
        sendNative(receiver, amount);
        emit Withdraw(receiver, amount);
    }

    function sendNative(address payable account, uint256 amount) private {
        (bool sent, ) = account.call{gas: 10000, value: amount}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {}
}