// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "./interface.sol";

/** ⚠️this contract is for test. ignore plz */

contract CreditSystem is ICreditSystem {
    function getCCALCreditLine(address user) public view override returns(uint) {
        return type(uint).max;
    }

    function getState(address user) public view override returns(bool, bool) {
        return (false, true);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;


interface ICreditSystem {
    function getCCALCreditLine(address user) external returns(uint);
    function getState(address user) external returns(bool, bool);
}

enum AssetStatus { INITIAL, BORROW, REPAY, WITHDRAW, LIQUIDATE }

struct DepositTool {
    uint cycle;
    uint minPay;
    AssetStatus status;
    uint[] toolIds;
    address holder;
    uint borrowTime;
    uint depositTime;
    uint totalAmount;
    address borrower;
    uint amountPerDay;
    uint internalId;
    address game;
}

struct FreezeTokenInfo {
    address operator;
    uint internalId;
    bool useCredit;
    address game;
    uint amount;
    uint interest;
}

struct InterestInfo {
    uint internalId;
    address game;
    uint amount;
}