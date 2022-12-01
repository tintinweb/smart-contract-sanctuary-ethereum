// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

/*//////////////////////////////////////////////////////////////   
                            Custom Errors
//////////////////////////////////////////////////////////////*/
error purchase_NotEnoughETH();

/// @title NFT marketplace
/// @author Kehinde A.
/// @notice A Crypto Dev Marketplace. A simplified NFT marketplace to be able to purchase NFTs automatically when a proposal is passed.
contract NFTMarketplace {
    /*//////////////////////////////////////////////////////////////   
                            State Variables
    //////////////////////////////////////////////////////////////*/
    // Maintain a mapping of TokenID to Owner addressess
    mapping(uint256 => address) private tokens;

    // Set the purchase price for each NFT
    uint256 private constant NFTPRICE = 0.1 ether;

    /*//////////////////////////////////////////////////////////////   
                            Functions
    //////////////////////////////////////////////////////////////*/

    // @Dev purchase() accepts ETH and marks the owner of the given tokenID as the caller address
    /// @param _tokenId - the nft token Id to purchase
    function purchase(uint256 _tokenId) external payable {
        if (msg.value != NFTPRICE) {
            revert purchase_NotEnoughETH();
        }

        tokens[_tokenId] = msg.sender;
    }

    /// @dev avaiable() checks whether the given tokenId has already been sold or not
    /// @param _tokenId - the fake NFT token Id to purchsae
    function available(uint256 _tokenId) external view returns (bool) {
        if (tokens[_tokenId] == address(0)) {
            return true;
        }
        return false;
    }

    receive() external payable {}

    fallback() external payable {}

    /*//////////////////////////////////////////////////////////////   
                            Functions
    //////////////////////////////////////////////////////////////*/
    /// @dev getOwnerOfToken returns the address of the token owner based on the inputed Id
    // @param id - the Id corespponding to the token owner
    function getOwnerOfToken(uint256 id) public view returns (address) {
        return tokens[id];
    }

    /// @dev getPrice() returns the price of one NFT
    function getNFTPrice() public pure returns (uint256) {
        return NFTPRICE;
    }
}
/**
 * NFTMarketplace Contract deployed at: 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9
 */