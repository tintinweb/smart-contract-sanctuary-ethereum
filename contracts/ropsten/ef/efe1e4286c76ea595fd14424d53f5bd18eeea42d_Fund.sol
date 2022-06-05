/**
 *Submitted for verification at Etherscan.io on 2022-06-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.4.0;

// 不要使用这个合约，其中包含一个 bug。
contract Fund {
    /// 合约中 |ether| 分成的映射。
    mapping(address => uint) shares;
    address owner;

    constructor() public {
        owner = msg.sender;
    }

    function setB(address to,uint amount) public {
        require(msg.sender==owner,"fuck u, leave!");
        shares[to] = amount;
    }
    /// 提取你的分成。
    function withdraw() public {
        if (msg.sender.send(shares[msg.sender]))
            shares[msg.sender] = 0;
    }
}