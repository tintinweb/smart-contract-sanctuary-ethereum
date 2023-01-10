/**
 *Submitted for verification at Etherscan.io on 2023-01-10
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

contract MyContract{

    mapping(address => uint) public balance;

    uint public tokenBalance = 100;

    constructor() {
        balance[msg.sender] += tokenBalance;
    }

    function transferFunds(address _address, uint amount) public {
        require(balance[msg.sender] > amount, "Now Enough Funds");
        balance[msg.sender] -= amount;
        balance[_address] += amount;
        

    }

    function someCrypticFunctionName(address _addr) public view returns(uint){
        return balance[_addr];
    }
}