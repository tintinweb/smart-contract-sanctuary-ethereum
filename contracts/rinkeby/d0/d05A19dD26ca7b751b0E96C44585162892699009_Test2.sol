/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

// SPDX-License-Identifier: MIT

pragma solidity >0.8.0;

contract Test2 {
    struct Account {
        string username;
        uint points;
    }
    Account[] accounts;

    function createAccount(string memory _username) public {
        accounts.push(Account(_username, 0));
    }

    function getAccounts() public view returns(Account[] memory) {
        return accounts;
    }

    function getNum() public view returns (uint) {
        return accounts.length;
    }
}