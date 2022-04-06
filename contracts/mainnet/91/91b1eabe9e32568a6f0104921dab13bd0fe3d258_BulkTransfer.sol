// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) external;
}

contract BulkTransfer {
    function transferBulk(
        address to,
        IERC721 token,
        uint256[] calldata ids
    ) external {
        unchecked {
            for (uint256 i; i < ids.length; ++i) token.transferFrom(msg.sender, to, ids[i]);
        }
    }

    function transferBulk(
        address to,
        IERC721[] calldata tokens,
        uint256[] calldata ids
    ) external {
        unchecked {
            for (uint256 i; i < ids.length; ++i) tokens[i].transferFrom(msg.sender, to, ids[i]);
        }
    }
}