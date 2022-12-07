/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: GPL-3.0
// 20221207_TEX 
pragma solidity 0.8.0;

// 예치, 인출의 기능
contract Bank {
/*
    Goverment public gover;
    address g_addr;
    constructor(address _addr) {
        gover = Goverment(_addr); // 정부 주소 넣고 시작
        g_addr = _addr;
    }

    mapping (address => uint) accounts;


    // 예치
    function deposit(uint _amount) public payable {
        require(msg.value == _amount);
        accounts[msg.sender] += _amount;
        gover.updateBankDepositPlus(_amount);
    }

    // 인출
    function withdraw(uint _amount) public payable {
        require(accounts[msg.sender] > _amount);
        payable(msg.sender).transfer(_amount);
        accounts[msg.sender] -= _amount;
        gover.updateBankDepositMinus(_amount);
    }

    // 계좌 잔액 확인
    function getBalance() public view returns (uint) {
        return accounts[msg.sender];
    }

    // 세금 납부 : 갖고 있는 총 금액의 2%를 실시한다.
    function payingTex() public {
        uint texAmount;
        texAmount = accounts[msg.sender] / 100 * 2;
        payable(g_addr).transfer(texAmount);
    }
*/    
}