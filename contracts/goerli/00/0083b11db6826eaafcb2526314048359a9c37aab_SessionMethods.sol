/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

struct lotterySession {
    // mappings and dynamic arrays always start in new slots
    mapping (uint256 => address) slots;
    uint256[] filledSlots;

    // 1+1+20=22 bytes consume one slot
    bool open;
    uint8 profitPercent;
    address winnerAddress;

    // uint256 consumes one slot
    uint256 totalSlots;
    uint256 slotPrice;
    uint256 winnerSlot;
    uint256 balance;
}

struct sessionParams {
    uint8 profitPercent;
    uint256 totalSlots;
    uint256 slotPrice;
}

library SessionMethods {

    function isOpen(lotterySession storage self) public view returns (bool) {
        return self.open;
    }

    function getFilledSlots(lotterySession storage self) public view returns (uint256[] memory) {
        return self.filledSlots;
    }

    function getTotalSlots(lotterySession storage self) public view returns (uint256) {
        return self.totalSlots;
    }

    function getSlotPrice(lotterySession storage self) public view returns (uint256) {
        return self.slotPrice;
    }

    function getBalance(lotterySession storage self) public view returns (uint256) {
        return self.balance;
    }

    function getProfitPercent(lotterySession storage self) public view returns (uint8) {
        return self.profitPercent;
    }

    function getWinnerSlot(lotterySession storage self) public view returns (uint256) {
        return self.winnerSlot;
    }

    function getWinnerAddress(lotterySession storage self) public view returns (address) {
        return self.winnerAddress;
    }

    function start(lotterySession storage self, sessionParams memory _params) internal {
        self.totalSlots = _params.totalSlots;
        self.slotPrice = _params.slotPrice;
        self.profitPercent = _params.profitPercent;
        self.open = true;
    }

    function stop(lotterySession storage self) internal {
        self.open = false;
    }

    function reset(lotterySession storage self) internal {
        for (uint256 i = 1; i <= self.totalSlots; i++) {
            self.slots[i] = address(this);
        }

        while (self.filledSlots.length > 0) {
            self.filledSlots.pop();
        }

        self.open = false;
        self.totalSlots = 0;
        self.winnerSlot = 0;
        self.balance = 0;
        self.winnerAddress = address(this);
    }

    function isSlotAvailable(lotterySession storage self, uint256 _slotNum) public view returns (bool) {
        return (
            self.filledSlots.length < self.totalSlots &&
            _slotNum <= self.totalSlots &&
            self.slots[_slotNum] == address(this)
        );
    }

    function buySlot(lotterySession storage self, uint256 _slotNum, address _buyer) internal {
        self.slots[_slotNum] = _buyer;
        self.filledSlots.push(_slotNum);
        self.balance += self.slotPrice;
    }

    function selectWinner(lotterySession storage self, uint256 _randomVal) internal {
        if (self.filledSlots.length > 0) {
            self.winnerSlot = self.filledSlots[_randomVal % self.filledSlots.length];
            self.winnerAddress = self.slots[self.winnerSlot];
        }
    }

}