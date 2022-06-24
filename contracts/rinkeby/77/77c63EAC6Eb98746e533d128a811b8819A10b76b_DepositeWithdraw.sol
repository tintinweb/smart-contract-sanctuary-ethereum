// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

contract DepositeWithdraw {
    uint256 public balanceReceived;

    function deposite() public payable {
        balanceReceived += msg.value;
    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function withdraw() public {
        address payable to = payable(msg.sender);
        to.transfer(getBalance());
    }
}