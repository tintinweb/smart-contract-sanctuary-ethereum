/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface SimplifiedIERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract BatchTransfer {
    constructor() {}

    function transferERC721SingleRecipient(address _tokenAddr, address _toAddr, uint256[] calldata _tokenIDs) external {
        SimplifiedIERC721 tokenContract = SimplifiedIERC721(_tokenAddr);
        unchecked {
            for(uint256 i = 0; i < _tokenIDs.length; i++)
                tokenContract.transferFrom(msg.sender, _toAddr, _tokenIDs[i]);
        }
    }

    function transferERC721MultiRecipient(address _tokenAddr, address[] calldata _toAddresses, uint256[] calldata _tokenIDs) external {
        require(_toAddresses.length == _tokenIDs.length, "length mismatch");
        
        SimplifiedIERC721 tokenContract = SimplifiedIERC721(_tokenAddr);
        unchecked {
            for(uint256 i = 0; i < _tokenIDs.length; i++)
                tokenContract.transferFrom(msg.sender, _toAddresses[i], _tokenIDs[i]);
        }
    }
}