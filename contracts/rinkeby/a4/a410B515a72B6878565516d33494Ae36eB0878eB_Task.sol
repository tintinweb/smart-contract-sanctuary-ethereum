/**
 *Submitted for verification at Etherscan.io on 2022-06-25
*/

//SPDX-License-Identifier:MIT
pragma solidity >= 0.6.0 < 0.9.0;

contract Task{
address public owner = msg.sender;
// to show the log of balance in contract account and owner account.
event balanceDetials(string message, uint blnc);

//Transfering the amount form contract to deployer address
function toOwner() public payable{
    payable(owner).transfer(getBalance());
}
// use to recieve amounts into contract address
receive() external payable {}

//use to send amount form an address to contract address
function sendAmount() payable public {  
    // it will show the contract balnce 
    emit balanceDetials("The contract Got:  ", getBalance());
    //it will show the deployer balnce before sent to deployer address
    emit balanceDetials("Before getting balance the deployer have: ", ownerBalance());
    // call the function when amount in the contract address.
    toOwner();
    // after getting the balance by deployer the amount in contract will be 0
    emit balanceDetials("after sending amount to deployer the contract will have: ", getBalance());
    // after geeting the amount the deployer balnce will be increased.
    emit balanceDetials("After getting balance by the deployer have: ", ownerBalance());
}
// we can check the balcne before send amount and after send amount will be 0
function getBalance() public view returns(uint){
   return address(this).balance;
}
// we can check the balnce before send amount and after send amount.
function ownerBalance() public view returns(uint){
    return owner.balance;
}

}