/**
 *Submitted for verification at Etherscan.io on 2022-06-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    function dedMint(uint256 _amount) external;

    function totalSupply() external view returns (uint256);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

contract MintBot  is IERC721Receiver {

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function run(address _nftAddress, uint256 _count, uint256 _cntPerTx) public payable {
        
        IERC721 nft = IERC721(_nftAddress);
        uint256 startTokenId = nft.totalSupply();

        for (uint256 i = 0; i < _count; i++) {
            nft.dedMint(_cntPerTx);

            for (uint256 j = 1; j <= _cntPerTx; j++) {
                startTokenId++;
                nft.transferFrom(address(this), msg.sender, startTokenId);
            }
        }

    }

}