/**
 *Submitted for verification at Etherscan.io on 2022-11-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

contract EthWallet{
    address payable owner;
    string name_;

    event Withdraw(address indexed user, address indexed owner, uint256 amount);
    constructor(string memory _name){
        owner = payable(msg.sender);
        name_ = _name;
    }

    function withdrawall() external{
        uint bal = address(this).balance;
        owner.transfer(bal);
        emit Withdraw(msg.sender,owner,bal);
    }

    function withdraw(uint256 _value /*wei*/) external{
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

}