// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestWhitelist {
    mapping(address => bool) public whitelistAccounts;

    function addOne(address account) external {
        whitelistAccounts[account] = true;
    }

    function addOneWithRead(address account) external {
        if (readInternal(account)) return;

        whitelistAccounts[account] = true;
    }

    function removeOne(address account) external {
        delete whitelistAccounts[account];
    }

    function removeOneWithRead(address account) external {
        if (!readInternal(account)) return;

        delete whitelistAccounts[account];
    }

    function batchAdd(address[] calldata accounts) external {
        for (uint256 i = 0; i < accounts.length; i++) {
            whitelistAccounts[accounts[i]] = true;
        }
    }

    function batchAddWithRead(address[] calldata accounts) external {
        for (uint256 i = 0; i < accounts.length; i++) {
            if (readInternal(accounts[i])) continue;

            whitelistAccounts[accounts[i]] = true;
        }
    }

    function batchRemove(address[] calldata accounts) external {
        for (uint256 i = 0; i < accounts.length; i++) {
            if (!readInternal(accounts[i])) continue;

            delete whitelistAccounts[accounts[i]];
        }
    }

    function batchRemoveWithRead(address[] calldata accounts) external {
        for (uint256 i = 0; i < accounts.length; i++) {
            if (!readInternal(accounts[i])) continue;

            delete whitelistAccounts[accounts[i]];
        }
    }

    function read(address account) external view returns (bool) {
        return whitelistAccounts[account];
    }

    function readInternal(address account) private view returns (bool) {
        return whitelistAccounts[account];
    }
}