/**
 *Submitted for verification at Etherscan.io on 2022-11-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract EthWallet{

    address payable owner;
    string name_;

    constructor(string memory _name){
        owner = payable(msg.sender);
        name_ = _name;
    }

    function withdrawall() external {
        uint256 bal = address(this).balance;
        owner.transfer(bal);
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
    event Reciept(uint256 value);
    receive() external payable {
       emit Reciept(msg.value); 
    }

    function withdraw(uint256 _value) external{
        owner.transfer(_value);
    }
}