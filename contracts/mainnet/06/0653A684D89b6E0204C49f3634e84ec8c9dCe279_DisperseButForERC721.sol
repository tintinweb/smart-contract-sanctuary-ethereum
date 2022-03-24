// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DisperseButForERC721 {
    function disperseToken(
        IERC721 token,
        address[] calldata recipients,
        uint256[][] calldata tokenIds
    ) external {
        require(recipients.length == tokenIds.length, "LENGTH_MISMATCH");

        for (uint256 i; i < recipients.length; i++) {
            for (uint256 j; j < tokenIds[i].length; j++) {
                token.transferFrom(msg.sender, recipients[i], tokenIds[i][j]);
            }
        }
    }

    function disperseTokenSafe(
        IERC721 token,
        address[] calldata recipients,
        uint256[][] calldata tokenIds
    ) external {
        require(recipients.length == tokenIds.length, "LENGTH_MISMATCH");

        for (uint256 i; i < recipients.length; i++) {
            for (uint256 j; j < tokenIds[i].length; j++) {
                token.safeTransferFrom(
                    msg.sender,
                    recipients[i],
                    tokenIds[i][j]
                );
            }
        }
    }
}

interface IERC721 {
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
}