// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract VendingMachine {
    // 合約擁有者（也就是甜甜圈的擁有者）
    address public owner;
    // 映射：地址 => 甜甜圈數量
    mapping(address => uint256) public donutBalances;

    // set the owner as th address that deployed the contract
    // set the initial vending machine balance to 100
    constructor() {
        // 建立合約的時候賦予建立合約的地址為擁有者
        owner = msg.sender;
        // 同時在映射中建立一組資料，value 為 100
        donutBalances[address(this)] = 100;
    }

    // 函數：查詢目前合約中有多少甜甜圈
    function getVendingMachineBalance() public view returns (uint256) {
        return donutBalances[address(this)];
    }

    // 存入甜甜圈（擁有者限定）
    function restock(uint256 amount) public {
        require(msg.sender == owner, "Only the owner can restock.");
        donutBalances[address(this)] += amount;
    }

    // 購買
    function purchase(uint256 _quantity, uint256 _price) public payable {
        // 最低售價為「0.01 ether」
        require(
            // 預設範例售價為「2 ether」
            // msg.value >= amount * 2 ether,
            // "You must pay at least 2 ETH per donut"
            // 若使用 msg.value 必須使用「wei」為單位，因為不可輸入浮點數
            // msg.value >= _quantity * 10000000000000000,
            // 改用函數作為輸入則可輸入浮點數
            _price >= _quantity * 0.01 ether,
            "You must pay at least 0.01 ETH(10000000000000000 Wei) per donut"
        );
        // 必須有足夠的甜甜圈庫存供購買
        require(
            donutBalances[address(this)] >= _quantity,
            "Not enough donuts in stock to complete this purchase"
        );
        // 庫存 -1
        donutBalances[address(this)] -= _quantity;
        // 購買者 +1
        donutBalances[msg.sender] += _quantity;
    }
}