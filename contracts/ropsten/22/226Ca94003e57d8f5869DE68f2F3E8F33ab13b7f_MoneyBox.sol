/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-30
pragma solidity >= 0.7.0 < 0.9.0;

/*
1. 한번에 1이더만 내야한다
2. 중복해서 참여 불가 (단, 누군가 적립금을 받으면 초기화)
3. 관리자만 적립된 이더를 볼 수 있다
4. 3의 배수 번째 사람에게만 적립 이더를 준다
*/

contract MoneyBox {
    event WhoPaid(address indexed sender, uint256 payment);

    address owner;

    mapping(uint256 => mapping(address => bool)) paidMemberList;

    uint256 round = 1;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        require(msg.value == 0.01 ether, "Must be 1 ether.");
        require(paidMemberList[round][msg.sender] == false, "Must be a new player in each game.");

        paidMemberList[round][msg.sender] = true;

        emit WhoPaid(msg.sender, msg.value);

        if(address(this).balance == 0.03 ether) {
            (bool sent, ) = payable(msg.sender).call{value: address(this).balance}("");
            require(sent, "Failed to pay");
            round++;
        }
    }

    function checkRound() public view returns(uint256) {
        return round;
    }

    function checkValue() public view returns(uint256) {
        require(owner == msg.sender, "Only Owner can check the value");
        return address(this).balance;
    }
}