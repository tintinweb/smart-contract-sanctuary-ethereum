/**
 *Submitted for verification at Etherscan.io on 2022-05-29
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Storage {
    uint256 number;
    address owner;

    constructor() {
      owner = msg.sender;
    }

    // 写入
    function store(uint256 num) public {
        number = num;
    }
    // 读取
    function retrieve() public view returns (uint256){
        return number;
    }

    // 查询指定地址余额
    function getBalanceOfAddress(address addr) public view returns (uint256){
        return addr.balance;
    }

    // 获取合约地址余额
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // 向合约地址转账
    function transderToContract() payable public {
        payable(address(this)).transfer(msg.value);
    }

    // 合约销毁
    function kill(address addr) payable public {
        if(owner != msg.sender){
            revert();
        }
        selfdestruct(payable(address(addr)));
    }

    fallback() external payable {}
    receive() external payable {}
}