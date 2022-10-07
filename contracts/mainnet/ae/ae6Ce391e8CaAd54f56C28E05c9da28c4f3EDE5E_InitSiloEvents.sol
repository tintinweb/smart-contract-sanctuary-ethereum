/*
 SPDX-License-Identifier: MIT
*/

pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

/**
 * @author Publius
 * @title InitSiloEvents emits missing Stalk/Seed events
 * This script will be called after BIP-24 has been executed.
 * `siloEvents` will contain a list of accounts that transferred at least 1 Deposit before BIP-24.
 * Stalk, Roots and Seeds will contain the values of the balances that were not emitted in Deposit transfers.
**/

contract InitSiloEvents {

    struct SiloEvents {
        address account;
        int256 stalk;
        int256 roots;
        int256 seeds;
    }

    event SeedsBalanceChanged(
        address indexed account,
        int256 delta
    );

    event StalkBalanceChanged(
        address indexed account,
        int256 delta,
        int256 deltaRoots
    );

    function init(SiloEvents[] memory siloEvents) external {
        uint256 n = siloEvents.length;
        for (uint i; i < n; ++i) {
            emit SeedsBalanceChanged(siloEvents[i].account, siloEvents[i].seeds);
            emit StalkBalanceChanged(siloEvents[i].account, siloEvents[i].stalk, siloEvents[i].roots);
        }

    }
}