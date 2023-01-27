/**
 *Submitted for verification at Etherscan.io on 2023-01-27
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract Transactions {
    address public owner;
    constructor(){
    owner = msg.sender;
    }
    //Address --> Contract -- deposit
    function deposit() external payable {
    }

    //Contract --> Address  -- withdrawal
    function withdraw(address payable _to, uint _amount) external {
        _to.transfer(_amount);
    }
    
    function getOwner() external view returns(address) {
        return owner;
    }

    function getBalance() external view returns(uint) {
        return address(this).balance;
    }

    function getAddress() external view returns(address) {
        return address(this);
    }

    function ownerWithdraw(address payable owner, uint _amount) external {
        owner.transfer(_amount);
    }
}