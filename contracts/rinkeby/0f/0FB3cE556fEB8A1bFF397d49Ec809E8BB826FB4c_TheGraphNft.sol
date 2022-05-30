// SPDX-License-Identifier: MIT 
pragma solidity 0.8.4;

/// Only minter can mint new NFT's
error MinterRequired();

interface ITheGraphNft {
    /** 
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
}

contract TheGraphNft is ITheGraphNft{

    uint private _tokenIds;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Minter
    address immutable _minter = msg.sender;

    // Mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function mint(address receiver, string memory tokenURI) public  {
        // if (_minter != msg.sender){
        //     revert MinterRequired();
        // }

        transfer(address(0),receiver,_tokenIds);
        _tokenURIs[_tokenIds] = tokenURI;

        unchecked { _tokenIds = ++_tokenIds; }
    }

    function transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        emit Transfer(from, to, tokenId);
    }
}