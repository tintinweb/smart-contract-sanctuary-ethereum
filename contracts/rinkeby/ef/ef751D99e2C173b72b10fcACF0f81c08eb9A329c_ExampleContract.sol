// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract ExampleContract {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }


    function deposit() external payable {
        //thank you)
    }

    function withdrawNative(address payable receiver, uint256 amount) public {
        sendNative(receiver, amount);
    }

    function sendNative(address payable account, uint256 amount) private {
        (bool sent, ) = account.call{gas: 10000, value: amount}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {}
}