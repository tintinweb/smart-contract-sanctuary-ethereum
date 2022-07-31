//SPDX-License-Identifier: MIT

// @author st4rgard3n / Raid Guild
pragma solidity ^0.8.4;

interface IERC721 {
     function transferFrom(address from, address to, uint256 tokenId) external;
}

contract Volley {

    function volley(IERC721 token, address[] calldata recipients, uint256[] calldata tokenId) external {

        for (uint256 i = 0; i < recipients.length; ) {

            token.transferFrom(msg.sender, recipients[i], tokenId[i]);

            unchecked {
            i++;
        }
        }
    }

    function inefficientVolley(IERC721 token, address[] calldata recipients, uint256[] calldata tokenId) external {

        for (uint256 i = 0; i < recipients.length; i++) {

            token.transferFrom(msg.sender, recipients[i], tokenId[i]);
        }
    }
}