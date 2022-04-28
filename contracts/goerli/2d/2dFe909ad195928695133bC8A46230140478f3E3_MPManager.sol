// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import './Common.sol';
import './Param.sol';

contract MPManager is Ownable, Param {
    address public mpe;

    uint256 public price = 100 * 10 ** 18;
    uint16 public everyoneMaxBuy = 100;

    uint16 public todayMaxBuy;
    uint16 public todayBuy;

    mapping(address => uint16) public buyInfos;

    struct WithdrawInfo {
        uint256 total;
        uint256 already;
    }

    mapping(address => WithdrawInfo) public withdrawInfos;

    event Buy(address indexed buyer, uint16 quantity);

    constructor(address _mpe) {
        mpe = _mpe;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setEveryoneMaxBuy(uint16 _everyoneMaxBuy) public onlyOwner {
        everyoneMaxBuy = _everyoneMaxBuy;
    }

    function setTodayMaxBuy(uint16 _todayMaxBuy) public onlyOwner {
        todayMaxBuy = _todayMaxBuy;
    }

    function setWithdrawInfo(address[] calldata addresses, uint256[] calldata amounts) public onlyOwner {
        require(addresses.length > 0, "MPManager: no data");
        require(addresses.length <= 100, "MPManager: length limit 100");
        require(addresses.length == amounts.length, "MPManager: the addresses is inconsistent with the amounts");
        for (uint256 i ; i < addresses.length ; i++) {
            withdrawInfos[addresses[i]].total += amounts[i];
        }
    }

    function buy(uint16 quantity) public {
        require(buyInfos[_msgSender()] + quantity <= everyoneMaxBuy, "MPManager: limit 100");
        require(todayBuy + quantity <= todayMaxBuy, "MPManager: exceed today's limit");

        uint256 usdtAmount = price * quantity;
        Address.functionCall(usdt, abi.encodeWithSelector(0x23b872dd, _msgSender(), address(this), usdtAmount));

        buyInfos[_msgSender()] += quantity;
        todayBuy += quantity;

        emit Buy(_msgSender(), quantity);
    }

    function withdraw(uint256 amount) public {
        require(withdrawInfos[_msgSender()].total - withdrawInfos[_msgSender()].already >= amount, "MPManager: insufficient balance");

        withdrawInfos[_msgSender()].already += amount;

        Address.functionCall(mpe, abi.encodeWithSelector(0xa9059cbb, _msgSender(), amount));
    }
}