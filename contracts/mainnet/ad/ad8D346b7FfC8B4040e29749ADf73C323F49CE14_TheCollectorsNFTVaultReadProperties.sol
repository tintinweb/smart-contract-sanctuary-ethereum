// SPDX-License-Identifier: UNLICENSED
// © 2022 The Collectors. All rights reserved.
pragma solidity ^0.8.13;

/*
    @dev
    The facet that handling read only properties for the The Collectors NFT Vault
    and can be called only by @TheCollectorsNFTVaultDiamond
    This contract is part of a diamond / facets implementation as described
    in EIP 2535 (https://eips.ethereum.org/EIPS/eip-2535)
*/
contract TheCollectorsNFTVaultReadProperties {

    function name() public view returns (string memory) {
        return "The Collectors NFT Vault";
    }

    function symbol() public view returns (string memory) {
        return "TheCollectorsNFTVault";
    }

}