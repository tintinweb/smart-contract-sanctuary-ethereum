// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract ManifestWalletSelector2{

    mapping(address => address) public manifestWalletToSelectedWallet;

    event Selected(address manifestWallet, address selectedWallet);

    /// @notice Assign your wallet's manifest entry to a different wallet
    /// @param selectedWallet the address you'd like to assign to (can't' be a contract, can't be yourself)
    function selectWallet(address selectedWallet) external {
        require(manifestWalletToSelectedWallet[msg.sender] == address(0), "address already assigned");
        require(msg.sender != selectedWallet, "can't assign to self");

        uint256 size;
        assembly { size := extcodesize(selectedWallet) }
        require(size == 0, "can't assign to contract");

        manifestWalletToSelectedWallet[msg.sender] = selectedWallet;
        emit Selected(msg.sender, selectedWallet);
    }
}