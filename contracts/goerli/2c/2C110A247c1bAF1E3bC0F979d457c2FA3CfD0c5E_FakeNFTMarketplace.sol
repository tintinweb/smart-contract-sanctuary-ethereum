// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract FakeNFTMarketplace {
    /// @dev Maintain a mapping of Fake TokenID to Owner address
    mapping(uint256 => address) public tokens;

    /// @dev set the purchase price for each Fake NFT
    uint256 nftPrice = 0.1 ether;

    /// @dev purchase() accepts ETH and marks the owener of the given tokenId as the calller address
    /// @param _tokenId - the fake NFT token Id to purchase
    function purchase(uint256 _tokenId) external payable {
        require(msg.value == nftPrice, "This NFT costs 0.01 ether");
        tokens[_tokenId] = msg.sender;
    }

    /// @dev getPrice() returns the price of one NFt
    function getPrice() external view returns (uint256) {
        return nftPrice;
    }

    /// @dev available() checks whether the given tokenId has aleady been sold or not
    /// @param _tokenId - th tokenId to check for
    function available(uint256 _tokenId) external view returns (bool) {
        //address(0) = 0x00000000000000000000000000000000
        // this is the defalt value for address in solidity
        if (tokens[_tokenId] == address(0)) {
            return true;
        } else {
            return false;
        }
    }
}
/**
 * the fakeNFTMarketplace exposes some basic functions that we will be using from the DAO Contract to purchase NFTs if a proposal is apsses
 * a real NFT market place will be more complicated as not all NFTs have the same price.
 *now we will start writing the CryptoDevsDAo contract. since this is mostaly completely custom contract and relatively more complicated that what we have dones so far.
 */