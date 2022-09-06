// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract ManifestWalletSelector{

    mapping(address => address) public manifestWalletToSelectedWallet;

    event Selected(address manifestWallet, address selectedWallet);

    function selectWallet(address selectedWallet) external {
        require(manifestWalletToSelectedWallet[msg.sender] == address(0), "address has already selected");
        manifestWalletToSelectedWallet[msg.sender] = selectedWallet;
        emit Selected(msg.sender, selectedWallet);
    }
}