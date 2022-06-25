/**
 *Submitted for verification at Etherscan.io on 2022-06-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SmartSync {
    //address public owner;

    event PaymentSuccessful(
        address indexed addr,
        uint256 userId,
        uint256 meetingId,
        uint256 amount
    );

    event Paid(
        address indexed addr1,
        address indexed addr2,
        uint256 userId,
        uint256 meetingId,
        uint256 amount
    );

    constructor() {
        //owner = msg.sender;
    }

    function pay(
        address _addr,
        uint256 _userId,
        uint256 _meetingId,
        uint256 _amount,
        uint256 _date
    ) external payable {
        // _msg.value instead of amount?
        emit PaymentSuccessful(_addr, _userId, _meetingId, msg.value);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function withdraw(
        address _addr,
        address recipient,
        uint256 _userId,
        uint256 _meetingId,
        uint256 _amount,
        uint256 _date
    ) external {
        //require(msg.sender == owner, "Caller not owner");
        (bool success, ) = payable(recipient).call{value: _amount}("");
        require(success, "Transfer failed.");
        emit Paid(_addr, recipient, _userId, _meetingId, _amount);
    }
}