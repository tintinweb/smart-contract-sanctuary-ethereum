/**
 *Submitted for verification at Etherscan.io on 2022-05-31
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/*
tx.origin 攻击

*/
contract TxUserWallet {
    event UserLog(uint256 gg);

    address owner;

    constructor() payable {
        owner = msg.sender;
    }

    function transferTo(address payable dest, uint amount) external payable{
        require(tx.origin == owner);
        emit UserLog(gasleft());
        // dest.transfer(amount);
        // dest.call{value: amount, gas: 2300}("");
        // 以上两种情况会因为gas携带不够不能完全执行
        dest.call{value: amount}("");
    }

    function getBalance() public view returns(uint) {
        uint _balance = address(this).balance;
        return _balance;
    }
}