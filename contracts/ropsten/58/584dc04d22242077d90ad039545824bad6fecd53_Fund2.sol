/**
 *Submitted for verification at Etherscan.io on 2022-06-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.4.0;

// 不要使用这个合约，其中包含一个 bug。
contract Fund2 {
    /// 合约中 |ether| 分成的映射。
    mapping(address => uint) shares;
    address owner;

    constructor() public {
        owner = msg.sender;
    }

/*
    function setB(address to,uint amount) public {
        require(msg.sender==owner,"fuck u, leave!");
        shares[to] = amount;
    }
*/
    function getB(address addr) public view returns(uint){
        return shares[addr];
    }

    function deposit() public payable{
        shares[msg.sender] += msg.value;
    }
    /// 提取你的分成。
    function withdraw(uint amount) public {
        if (msg.sender.send(amount))
            shares[msg.sender] -= amount;
    }
}