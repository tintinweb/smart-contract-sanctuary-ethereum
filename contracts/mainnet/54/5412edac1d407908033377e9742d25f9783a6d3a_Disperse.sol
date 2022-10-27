/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

//  ▄▄▄▄▄▄▄ ▄▄▄▄▄▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄   ▄▄   ▄▄ ▄▄▄▄▄▄ ▄▄▄▄▄▄▄ ▄▄   ▄▄ ▄▄   ▄▄ ▄▄   ▄▄ 
// █       █      █       █       █   ▄  █ █  █ █  █      █       █  █ █  █  █ █  █  █▄█  █
// █    ▄  █  ▄   █    ▄  █    ▄▄▄█  █ █ █ █  █▄█  █  ▄   █       █  █ █  █  █ █  █       █
// █   █▄█ █ █▄█  █   █▄█ █   █▄▄▄█   █▄▄█▄█       █ █▄█  █     ▄▄█  █▄█  █  █▄█  █       █
// █    ▄▄▄█      █    ▄▄▄█    ▄▄▄█    ▄▄  █       █      █    █  █       █       █       █
// █   █   █  ▄   █   █   █   █▄▄▄█   █  █ ██     ██  ▄   █    █▄▄█       █       █ ██▄██ █
// █▄▄▄█   █▄█ █▄▄█▄▄▄█   █▄▄▄▄▄▄▄█▄▄▄█  █▄█ █▄▄▄█ █▄█ █▄▄█▄▄▄▄▄▄▄█▄▄▄▄▄▄▄█▄▄▄▄▄▄▄█▄█   █▄█

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

contract Disperse {
    function disperseNFT(address tokenAddress, address[] calldata recipients, uint256[] calldata tokenIds) external {
        IERC721 token = IERC721(tokenAddress);
        require(token.isApprovedForAll(msg.sender, address(this)), "Need to set approval");
        require(recipients.length == tokenIds.length);
        uint count = tokenIds.length;
        for(uint i = 0; i < count;) {
            token.safeTransferFrom(msg.sender, recipients[i], tokenIds[i]);
            unchecked {
                i++;
            }
        }
    }
}