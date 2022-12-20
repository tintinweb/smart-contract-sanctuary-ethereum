// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <=0.9.0;

contract Accounting {
    // 條件：只有合約擁有者才能執行
    modifier onlyContractOwner() {
        require(
            msg.sender == contractOwner,
            "Only contract owner can call this function."
        );
        _;
    }
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

    // 終止帳號
    function closeAccount() public onlyContractOwner {
        selfdestruct(contractOwner);
    }

    // 餘額結清
    function clearBalance() public onlyContractOwner {
        contractOwner.transfer(address(this).balance);
    }
}