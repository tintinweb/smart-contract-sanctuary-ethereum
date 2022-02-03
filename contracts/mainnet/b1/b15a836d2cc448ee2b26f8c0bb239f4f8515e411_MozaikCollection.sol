// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title Creature
 * Creature - a contract for my non-fungible creatures.
 */
contract MozaikCollection is ERC721Tradable {
    constructor(address _proxyRegistryAddress)
        ERC721Tradable("MozaikCollection", "MNC", _proxyRegistryAddress)
    {}

    function baseTokenURI() override public pure returns (string memory) {
        return "https://mozaik-nft.s3.us-east-2.amazonaws.com/collection/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://mozaik-nft.s3.us-east-2.amazonaws.com/contract-metadata";
    }

    /**
     * @dev Withdraw the contract balance to the dev address or splitter address
     */
    function withdraw() external onlyOwner {
        sendEth(owner(), address(this).balance);
    }

    function sendEth(address to, uint amount) internal {
        (bool success,) = to.call{value: amount}("");
        require(success, "Failed to send ether");
    }
}