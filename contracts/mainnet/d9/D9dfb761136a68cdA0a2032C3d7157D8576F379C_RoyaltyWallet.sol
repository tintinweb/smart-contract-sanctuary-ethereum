// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract RoyaltyWallet {
    struct Split {
        address account;
        uint16 share;
    }

    Split[] public splits;

    constructor(address[] memory accounts, uint16[] memory shares) {
        uint256 tally = 0;

        require(
            accounts.length == shares.length,
            "Accounts and shares must be the same length"
        );

        for (uint256 i = 0; i < accounts.length; i++) {
            tally += shares[i];
            splits.push(Split(accounts[i], shares[i]));
        }

        require(tally == 10000, "The sum of shares must equal 100");
    }

    function withdraw() public {
        uint256 balance = address(this).balance;
        for (uint256 i = 0; i < splits.length; i++) {
            address payable account = payable(splits[i].account);
            uint16 share = splits[i].share;

            (bool sent, ) = account.call{value: (balance * share) / 10000}("");
            require(sent, "Something went wrong during the withdrawal");
        }
    }

    receive() external payable {}
}