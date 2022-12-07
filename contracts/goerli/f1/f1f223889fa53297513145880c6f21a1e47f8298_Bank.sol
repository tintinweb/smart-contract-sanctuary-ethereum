/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Bank {
    address government;

    constructor(address _government) {
        government = _government;
    }

    struct Citizen {
        string name;
        uint amount;
    }

    // 국민 목록
    mapping(address => Citizen) Citizens;

    // 예치
    function deposit(address _bankAccount, uint _amount) public payable{
        require (msg.sender.balance >= msg.value);
        require (_amount == msg.value);
        Citizens[_bankAccount].amount += _amount;
    }

    // 인출
    function withdraw(uint _amount) public {
        // 국민의 예치를 감소시킵니다.
    }
}