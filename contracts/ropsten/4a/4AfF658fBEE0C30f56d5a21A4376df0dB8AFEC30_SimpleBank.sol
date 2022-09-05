// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleBank {

    mapping (address => uint256) public balances;


    function deposit() external  payable  returns (uint256) {
        balances[msg.sender] += msg.value;

        return  balances[msg.sender];
    }


    function withdraw() external returns(uint256) {
        uint256 bal = balances[msg.sender];
        (bool send,) = msg.sender.call{value: bal}("");

        balances[msg.sender] -= bal;

        require(send, "Failed to send Ether");


        return balances[msg.sender];
    }

}