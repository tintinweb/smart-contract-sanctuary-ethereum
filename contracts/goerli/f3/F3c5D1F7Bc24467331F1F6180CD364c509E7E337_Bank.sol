/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

contract Bank {
    mapping(address => uint) depositMap;

    function deposit() public payable {
        depositMap[msg.sender] += msg.value;
    }

    function _withdraw(address target, uint amount) private {
        require(depositMap[target] >= amount, "not enough deposit");

        depositMap[target] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function withdraw(uint amount) public {
        _withdraw(msg.sender, amount);
    }

    // 예금 조회
    function inquiryBalance(address guest) public view returns(uint) {
        return depositMap[guest];
    }

    // 자동이체 - 세금 납부용
    function eft(address target, uint amount) public {
        // require(자동이체 등록했는가?, "permission denied");
        _withdraw(target, amount);
    }
}