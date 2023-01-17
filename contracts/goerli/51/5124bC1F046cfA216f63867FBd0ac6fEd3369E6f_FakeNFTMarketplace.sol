// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FakeNFTMarketplace {
    /// @dev Maintain a mapping of Fake TokenID to Owner addresses
    // bcz no actual NFT will be transfered on purchase()...
    // this Fake TokenID will be assigned to the msg.sender using this mapping 
    mapping(uint256 => address) public tokens;
    /// @dev Set the purchase price for each Fake NFT
    uint256 nftPrice = 0.01 ether;
    // dummy NFTMP bcz real-NFTMP will have all NFTs priced differently
    // set internal var. + will code a getter to return / check the nftPrice by any user
    // original is 0.1 ether
    
    // below, external only bcz contract won't call this f() internally
    // has to be payable
    /// @dev purchase() accepts ETH and marks the owner of the given tokenId as the caller address
    /// @param _tokenId - the fake NFT token Id to purchase
    function purchase(uint256 _tokenId) external payable {
        require(msg.value == nftPrice, "This NFT costs 0.01 ether");
        tokens[_tokenId] = msg.sender;
        // in this case, there does NOT exist any NFT Token with _tokenId
        // just mathematical op of assigning happened here
        // whereas, in reality, there will be an NFT with _tokenId that will be transfered to msg.sender 
    }

    /// @dev getPrice() returns the price of one NFT
    function getPrice() external view returns (uint256) {
        return nftPrice;
    }

    /// @dev available() checks whether the given tokenId has already been sold or not
    /// @param _tokenId - the tokenId to check for
    function available(uint256 _tokenId) external view returns (bool) {
        // address(0) = 0x0000000000000000000000000000000000000000
        // This is the default value for addresses in Solidity
        // cannot be checked this way in array bcz an array reverts
        // can only be done in mapping bcz it has all addresses set to address(0) by default... 
        // if not assigned to any msg.sender (not already sold)
        if (tokens[_tokenId] == address(0)) {
            return true;
        }
        return false;
    }
}