/**
 *Submitted for verification at Etherscan.io on 2022-11-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ledger {
    function getStatistics() public pure returns (
        uint256 income_yesterday,
        uint256 income_today,
        uint256 total_nodes,
        uint256 infra_balance,
        uint256 community_balance
) {
    // income_yesterday = ILedger(ledger).income(today() - 1);
    income_yesterday = 210 ether;
    // income_today = ILedger(ledger).income(today());
    income_today = 320 ether;
    // total_nodes = metaDB.totalSupply();
    total_nodes = 8230 ether;
    // infra_balance = IField(field).balanceOf(IField(field).infrastructure());
    infra_balance = 1800 ether;
    // community_balance = IField(field).balanceOf(IField(field).community());
    community_balance = 2500 ether;
    }
}