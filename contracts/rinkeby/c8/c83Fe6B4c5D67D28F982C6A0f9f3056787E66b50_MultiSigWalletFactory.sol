// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;
import "./MultiSigWallet.sol";

contract MultiSigWalletFactory {
    event ContractInstantiation(address sender, address instantiation);
    MultiSigWallet[] wallets;
    function create(string memory seedPhrases)
        public
        returns (MultiSigWallet wallet)
    {
        address[] memory par1 = new address[](1);
        par1[0] = msg.sender;
        string[] memory par2 = new string[](1);
        par2[0] = seedPhrases;
        wallet = new MultiSigWallet(par1, par2, address(this));
        wallets.push(wallet);
        emit ContractInstantiation(msg.sender, address(wallet));
        return wallet;
    }

    function recover(string memory secret) public {
        for (uint256 i = 0; i < wallets.length; i++) {
            wallets[i].recover(secret, msg.sender);
        }
    }

    function getCreatedWallets() public view returns (address[] memory){
        address[] memory ret = new address[](wallets.length);
        for (uint i = 0; i < wallets.length; i++) {
            ret[i] = address(wallets[i]);
        }
        return ret;
    }
}