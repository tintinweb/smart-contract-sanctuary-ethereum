// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract EtherWallet {
     
     address payable public owner;
     event Deposit(address indexed account, uint amount);
     event Withdraw(address indexed account, uint amount);
     
     constructor(){
        owner = payable (msg.sender);
     }

     modifier onlyOwner (){
        require(msg.sender == owner, "caller is not owner");
        _;
     }

     function getBalance() external view returns (uint balance){
        return address(this).balance;
     }

     function withdraw(uint amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount);
     }

     receive() external payable {
        emit Deposit(msg.sender, msg.value);
     }

     fallback() external payable {}


}