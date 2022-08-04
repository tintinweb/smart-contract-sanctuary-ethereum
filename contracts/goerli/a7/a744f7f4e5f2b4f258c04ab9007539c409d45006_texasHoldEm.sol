/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

contract texasHoldEm {

    mapping(address => uint) public userBalance;
    mapping(address => uint) public userClaimed;

    event Deposit(address user, uint value);
    event Withdraw(address user, uint value);

    address public owner;
    uint256 public processFee;

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        processFee = 1 * 10 ** 15;
    }

    function deposit() public payable {
        userBalance[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(address _claimer, uint256 _fee) public onlyOwner {
        payable(owner).transfer(processFee);
        payable(_claimer).transfer(_fee - processFee);
        userClaimed[_claimer] += _fee;
        emit Withdraw(_claimer, _fee);
    }

    function updateProcessFee(uint256 _fee) public onlyOwner {
        processFee = _fee;
    }
}