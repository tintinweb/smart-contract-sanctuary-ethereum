/**
 *Submitted for verification at Etherscan.io on 2023-03-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Lotto {
    address admin;
    uint256 round;
    // Lotto round
    struct LottoResult {
        uint256 round;
        uint256 playersCount;
        uint256 lotteriesCount;
        string result;
    }

    // Purchasing History in that round
    struct PurchasingHistory {
        uint256 round;
        uint256 win;
        string[] lotteries;
        uint256 lotteriesCount;
    }

    mapping(address => PurchasingHistory[]) public lottoByUser;

    constructor() {
        admin = msg.sender;
        round = 1;
    }

    function purchase(string[] memory _lotteries) public payable {
        uint256 lottoPrice = 1;
        uint256 amount = _lotteries.length;
        uint256 totalPrice = lottoPrice * amount;
        require(msg.sender.balance >= totalPrice, "Insufficient balance.");

        if (lottoByUser[msg.sender][round].lotteries.length <= 0) {
            lottoByUser[msg.sender][round].win = 0;
            lottoByUser[msg.sender][round].lotteries.push();
            lottoByUser[msg.sender][round].lotteriesCount = 0;
        }

        for (uint i = 0; i < amount; i++) {
            lottoByUser[msg.sender][round].lotteries.push(_lotteries[i]);
        }

        lottoByUser[msg.sender][round].lotteriesCount += amount;
    }

    function showMyHistory() public view returns (PurchasingHistory[] memory) {
        return lottoByUser[msg.sender];
    }
}