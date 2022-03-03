/**
 *Submitted for verification at Etherscan.io on 2022-03-03
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

contract SendEth2Me {
    address private _owner;

    modifier onlyOwner() {
        require(_owner == msg.sender, "Caller is not the owner");
        _;
    }

    modifier notZero(address _address) {
        require(_address != address(0), "Avoid using zero address");
        _;
    }

    modifier hasValue() {
        require(msg.value > 0, "0 ether (wei) will not support anybody");
        _;
    }

    modifier hasBalance() {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "Contract has no balance");
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function transferOwnership(address newOwner)
        public
        onlyOwner
        notZero(newOwner)
    {
        _owner = newOwner;
    }

    function sendEther(address recipient) public payable hasValue {
        uint256 amount;
        if (msg.value == 1) {
            amount = 1;
        } else {
            amount = msg.value;
            if (msg.value <= 100) {
                amount -= 1;
            } else {
                uint256 onePercent = msg.value / 100;
                amount -= onePercent;
            }
        }

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Sending amount to recipient failed");
    }

    function withdraw() public payable onlyOwner hasBalance {
        uint256 contractBalance = address(this).balance;
        (bool success, ) = _owner.call{value: contractBalance}("");
        require(success, "Withdraw contract balance failed");
    }
}