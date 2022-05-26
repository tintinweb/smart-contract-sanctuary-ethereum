/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

//SPDX-License-Identifier: DUDE
pragma solidity ^0.8.13;

contract Refunder {

    mapping (address => uint) public balances;
    uint public paymentsCount;
    uint public refundsCount;

    event PaymentReceived (address indexed from, uint amount);
    event AccountRefunded (address indexed to, uint amount);

    receive () external payable {

        balances[msg.sender] += msg.value;
        paymentsCount += 1;

        emit PaymentReceived(msg.sender, msg.value);
    }

    function refund () public {

        uint amount = balances[msg.sender];
        require (amount > 0, 'Address balance is 0');
        require (address(this).balance >= amount, 'Contract does not contain enough ETH');

        balances[msg.sender] = 0;
        refundsCount += 1;
        (bool sent, ) = msg.sender.call{value: amount}('');
        require(sent, 'Refund has failed');

        emit AccountRefunded(msg.sender, amount);
    }
}