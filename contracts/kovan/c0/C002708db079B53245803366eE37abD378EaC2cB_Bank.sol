/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;


contract Bank {

    mapping(address => uint) public balances;
    function deposit () public payable {
        balances[msg.sender] += msg.value;

    }

    function withdraw () public {
        uint bal = balances[msg.sender];
        require(bal > 0);
        (bool sent, ) = msg.sender.call{value : bal}("");
        require(sent, "fail to send Ether");
        balances[msg.sender] = 0;
    }

}