/**
 *Submitted for verification at Etherscan.io on 2022-11-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


contract EthWallet{

    address payable owner;
    string name_;

    constructor(string memory _name){
        owner = payable(msg.sender);
        name_ = _name;
    }

    function withdrawAll() external{
        uint bal = address(this).balance;
        owner.transfer(bal);
    }

     function withdraw(uint256 _value) external{
         owner.transfer(_value);
     }

    function getBalance() external view returns(uint256){
        return address(this).balance;
    }

    function editName(string memory _newName) external{
        name_ = _newName;
    }

    function getName() public view returns(string memory){
        return name_;
    }

    event Receipt(uint256 Value);
    receive() external payable{
    emit Receipt(msg.value);
    }



}