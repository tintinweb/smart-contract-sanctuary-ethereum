// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <=0.9.0;

contract Accounting {
    // 合約擁有者
    address payable public contractOwner;

    // 建構子
    constructor() {
        contractOwner = payable(msg.sender);
    }

    // 打錢到帳上
    function sendMoneyToContract() public payable {}

    // 提款
    function withdraw(address payable _to, uint256 _amount) public {
        _to.transfer(_amount);
    }
}