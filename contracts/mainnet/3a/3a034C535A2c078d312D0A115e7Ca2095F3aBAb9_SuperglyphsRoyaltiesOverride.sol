//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title SuperglyphsRoyaltiesOverride
/// @author Simon Fremaux (@dievardump)
contract SuperglyphsRoyaltiesOverride {
    address public immutable nftContract;
    address public immutable moduleContract;

    constructor(address nftContract_, address moduleContract_) {
        nftContract = nftContract_;
        moduleContract = moduleContract_;
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
            interfaceId == this.royaltyInfo.selector ||
            interfaceId == this.supportsInterface.selector;
    }

    function royaltyInfo(uint256 tokenId, uint256 value)
        public
        view
        returns (address recipient, uint256 amount)
    {
        // first get royalties info from the nft contract
        (recipient, amount) = SuperglyphsRoyaltiesOverride(nftContract)
            .royaltyInfo(tokenId, value);

        // if the recipient is the SuperglyphModule itself, this means the token hasn't been frozen
        // so we must return the contract owner instead of the contract address
        //
        // because I have been dumb enough to forget to add withdraw for ERC20 in the contract itself
        // meaning: royalties paid in ERC20 (or others) and not in ETH will be locked forever in the contract
        //
        // I'm hoping to save some of them by creating this override.
        // Marketplaces using the RoyaltyRegistry will work
        if (recipient == moduleContract) {
            recipient = IOwnable(moduleContract).owner();
        }
    }
}

interface IOwnable {
    function owner() external view returns (address);
}