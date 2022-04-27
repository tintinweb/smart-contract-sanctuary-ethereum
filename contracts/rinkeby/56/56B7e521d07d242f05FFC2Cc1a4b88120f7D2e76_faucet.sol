/**
 *Submitted for verification at Etherscan.io on 2022-04-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract faucet {

    address creator;
    mapping(address => bool) got;

    event SendEth(address indexed sender, uint amount);
    event GetEth(address indexed getter, uint amount);

    constructor() payable {
        creator = msg.sender;
        payable(address(this)).transfer(msg.value);
    }

    function sendEth() public payable {
        payable(address(this)).transfer(msg.value);
        emit SendEth(msg.sender, msg.value);
    }

    function getEth(uint amount) public {

        require(got[msg.sender] == false, "you had requested");
        require(amount <= 2 ether, "too many requset");
        payable(msg.sender).transfer(amount);

        emit GetEth(msg.sender, amount);

        got[msg.sender] = true;
    }

    function checkBalance() public view returns (uint) {
        return address(this).balance;
    }

    function refund() public {
        require(creator == msg.sender, "only creator can refund");
        payable(creator).transfer(address(this).balance);
    }

    receive() external payable {}
}