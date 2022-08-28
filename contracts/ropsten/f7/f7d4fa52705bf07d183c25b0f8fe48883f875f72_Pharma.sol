/**
 *Submitted for verification at Etherscan.io on 2022-08-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Pharma {
    bool public flag;
    uint public amountDeposited;
    address public logistic = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    address payable public owner;
    constructor() payable {
        owner = payable(msg.sender);
    }
    function deposit(uint amount) public payable{
        amountDeposited = amount;
    }

    function check(uint _temp, uint _humid) public {
        if(_temp > 10 && _temp< 20){
            if(_humid >25 && _humid< 35){
                flag = true;
            }
        }
    }

    function transfer() public {
        require(flag==true,"Temperature or Humidity is out of range, transaction cannot be completed!");
        (bool success,) = payable(logistic).call{value: amountDeposited}("");
        require(success,"Failed to send Ether");
        }

    fallback() external {}
}