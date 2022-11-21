/**
 *Submitted for verification at Etherscan.io on 2022-11-21
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

// etherを受け取り、送金するコントラクト
contract Transfer {
    // payable修飾子のついたaddressはetherを受け取ることができる
    address payable public owner;
    uint public mostSent;

    // payable修飾子のついたconstructorはデプロイ時にetherを受け取ることができる
    // msg.senderは関数を呼び出したアドレス（この場合はデプロイしたアドレス）
    constructor() payable {
        owner = payable(msg.sender);
    }

    // Payコントラクトアドレスにetherを送金する関数
    event Deposited(address indexed payee, uint256 weiAmount);
    function deposit() payable public {
         emit Deposited(msg.sender, msg.value);
    }

    // Payコントラクトアドレスのether残高を返す関数
    // requireでコントラクトデプロイ者のみ実行可能となっている
    function getBalance() public view returns (uint256) {
        require(owner == msg.sender);
        return address(this).balance;
    }

    function getThis() public view returns (address) {
        return address(this);
    }

    function getBalanceForAddress(address a) public view returns (uint256) {
        return a.balance;
    }

    // Payコントラクトアドレスから_toアドレスに_amount分のetherを送金する関数
    function withdraw(address payable _to, uint _amount) public {
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }

    // Payコントラクトアドレスから_toアドレスに_amount分のetherを送金する関数
    function payTransfer(address payable _to, uint _amount) public payable {
        _to.transfer(_amount);
    } 
    
    function paySender(address payable _to, uint _amount) public payable returns (bool) {
        bool success = _to.send(_amount);
        return success;
    }
}