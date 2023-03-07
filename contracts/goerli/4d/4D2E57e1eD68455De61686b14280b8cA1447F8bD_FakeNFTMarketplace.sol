// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract FakeNFTMarketplace {
    uint256 private nftPrice = 0.001 ether;

    mapping(uint256 => address) public tokens;

    function purchase(uint256 _tokenId) external payable {
        require(msg.value == nftPrice, "Insufficient Fund (need 0.001 ether)");
        tokens[_tokenId] = msg.sender;
    }

    function getPrice() external view returns (uint256) {
        return nftPrice;
    }

    function available(uint256 _tokenId) external view returns (bool) {
        if (tokens[_tokenId] == address(0)) {
            return true;
        }
        return false;
    }
}