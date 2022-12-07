// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

abstract contract ERC721Interface {
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public virtual;
}

contract DudelzAirdrop {

    function erc721Airdrop(address _addressOfNFT, address[] memory _recipients, uint256[] memory _tokenIds) public {
        ERC721Interface erc721 = ERC721Interface(_addressOfNFT);
        for(uint i = 0; i < _recipients.length; i++) {
            erc721.safeTransferFrom(msg.sender, _recipients[i], _tokenIds[i]);
        }
    }
}