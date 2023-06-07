// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {KomonERC1155} from "KomonERC1155.sol";
import {Modifiers} from "Modifiers.sol";

contract CreatorSpaceFacet203 is KomonERC1155, Modifiers {
    uint256 private constant LESS_THAN_TOKEN_NUMBER_ALLOWED = 2;

    function mintSpaceKeyUSDC(uint256 id, address account) external {
        require(
            balanceOf(account, id) + 1 < LESS_THAN_TOKEN_NUMBER_ALLOWED,
            "Can't have more than 1 token id type per wallet"
        );
        uint256 tokenPrice = tokenPrice(id);
        require(
            (totalSupply(id) + 1) <= maxSupply(id),
            "Max amount of token reached."
        );
        require(tokenPrice > 0, "Token price must be more than 0.");

        distributeMintingCuts(id, tokenPrice, account);
    }
}