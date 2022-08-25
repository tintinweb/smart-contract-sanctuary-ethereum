//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract FakeNFTMarketPlace {
    uint256 nftPrice = 0.001 ether;
    mapping(uint256 => address) public tokens;

    function purchase(uint256 _tokenId) external payable {
        require(msg.value >= nftPrice, "Not enough eth");
        require(tokens[_tokenId] == address(0), "token has been sold");

        tokens[_tokenId] = msg.sender;
    }

    function getPrice() external view returns(uint256) {
        return nftPrice;
    }

    function available(uint256 _tokenId) external view returns(bool) {
        if(tokens[_tokenId] == address(0)) {
            return true;
        } else {
            return false;
        }
    }
}