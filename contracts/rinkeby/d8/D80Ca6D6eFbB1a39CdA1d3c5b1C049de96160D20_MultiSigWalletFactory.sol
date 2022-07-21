// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;
import "./MultiSigWallet.sol";
import "./Factory.sol";

contract MultiSigWalletFactory is Factory {
    MultiSigWallet[] wallets;
    function create(address[] memory _owners, string[] memory seedPhrases)
        public
        returns (MultiSigWallet wallet)
    {
        wallet = new MultiSigWallet(_owners, seedPhrases, address(this));
        wallets.push(wallet);
        register(address(wallet));
    }

    function recover(string memory secret) public {
        for (uint256 i = 0; i < wallets.length; i++) {
            wallets[i].recover(secret, msg.sender);
        }
    }
}