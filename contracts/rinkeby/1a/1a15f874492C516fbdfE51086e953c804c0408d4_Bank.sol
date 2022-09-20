/**
 *Submitted for verification at Etherscan.io on 2022-09-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Bank{
    mapping(address => uint) balances;

    constructor()
    {

    }

    function deposit() public payable {
        require(msg.value > 0);
        balances[msg.sender] = msg.value;
    }

    function withdraw() public payable {
        require(balances[msg.sender] > 0);

        payable(msg.sender).transfer(balances[msg.sender]);

        balances[msg.sender] = 0;
    }

    function getBalance(address a) public view returns(uint){
        return balances[a];
    }
}