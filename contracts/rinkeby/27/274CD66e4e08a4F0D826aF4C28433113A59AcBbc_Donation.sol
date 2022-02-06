/**
 *Submitted for verification at Etherscan.io on 2022-02-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Donation{

    address payable public owner;
    address[] public donators;
    mapping (address => uint) public donationAddresses;
    constructor () {
      owner = payable(msg.sender);
      
    }
    
    function donations() public payable{
       // require(msg.value >= .001 ether);
        donators.push(msg.sender);
        donationAddresses[msg.sender] =  msg.value;
    }

    receive() external payable {
        donators.push(msg.sender);
        donationAddresses[msg.sender] =  msg.value;
    }

    
    //выводим пожертвование на определенный адрес, вывести может только создатель контракта
    function transferToCertainAddress(address payable toAddr) public {
        //проверям условие того, что функция вызвана владельцем контракта
        require(msg.sender == owner, "Not an owner");
        //выводим на конкретный адрес
        toAddr.transfer(address(this).balance);
    }

    function getBalance() public view returns (uint256){
        return address(this).balance;
    }


}