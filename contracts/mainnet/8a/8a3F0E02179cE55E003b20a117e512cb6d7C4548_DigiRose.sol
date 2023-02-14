// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.17;

import "./ERC721Rebased.sol";

/**
 * @dev DigiRose - Fully on-chain ERC721 NFT Contract
 *
 *          <= ERC721Rebased
 *          <= ERC721RoyaltyOwnable
 *          <= ERC721WithOperatorFilter
 *          <= ERC721Royalty
 *          <= ERC721Enumerable
 *          <= ERC721
 */
contract DigiRose is ERC721Rebased {
    uint256 private _DEAD_LINE = 1676458799;

    constructor(
        string memory name_,
        string memory symbol_,
        address dataURIContract_,
        address newOwner_
    )
        ERC721(name_, symbol_)
        ERC721Rebased(dataURIContract_)
        ERC721RoyaltyOwnable(newOwner_)
    {}

    function mint(address to_) public {
        require(block.timestamp < _DEAD_LINE, "DigiRose: minting is closed");
        require(_msgSender() != to_, "DigiRose: cannot mint to self");
        _mintNFT(to_);
    }

    function _mintNFT(address to_) internal {
        uint256 tokenId = totalSupply() + 1;

        _dna[tokenId] = keccak256(
            abi.encodePacked(
                tokenId,
                _msgSender(),
                block.difficulty,
                block.coinbase,
                blockhash(block.number - 1)
            )
        );

        _safeMint(to_, tokenId);
    }
}