/**
 *Submitted for verification at Etherscan.io on 2022-11-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

contract EthWallet{

    // make a contract which can store Eth for an owner.

    address payable owner;
    string name_;

    event Withdraw(address indexed User, address indexed Owner, uint256 Amount);
    constructor(string memory _name) {
        owner = payable(msg.sender); // deployer
        name_ = _name;
    }

    function withdrawAll() external {
        uint bal = address(this).balance;
        owner.transfer(bal);
        emit Withdraw(msg.sender,owner,bal);
    }

    function withdraw(uint256 _value /*wei*/)external {
        owner.transfer(_value);
        emit Withdraw(msg.sender,owner,_value);
    }

    function getBalance() external view returns(uint256){
        return address(this).balance;
    }

    function editName(string memory _newName) external {
        name_ = _newName;
    }
    function name() external view returns(string memory){
        return name_;
    }

    event Receipt(uint256 Value);
    receive() external payable{
        emit Receipt(msg.value);
    }

    // Deposit    
}