// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {KomonERC1155} from "KomonERC1155.sol";
import {KomonAccessControlBaseStorage} from "KomonAccessControlBaseStorage.sol";

contract CreatorSpaceFacet103 is KomonERC1155 {
    uint256 private constant LESS_THAN_TOKEN_NUMBER_ALLOWED = 2;

    function mintSpaceKey(uint256 id) external payable {
        require(
            balanceOf(msg.sender, id) + 1 < LESS_THAN_TOKEN_NUMBER_ALLOWED,
            "Can't have more than 1 token id type per wallet"
        );
        uint256 tokenPrice = tokenPrice(id);
        require(
            (totalSupply(id) + 1) <= maxSupply(id),
            "Max amount of token reached."
        );
        require(tokenPrice > 0, "Token price must be more than 0.");

        uint256 total = tokenPrice * 1 wei;
        require(msg.value == total, "Amount sent is not correct.");

        distributeMintingCuts(id, total);
    }

    function mintSpaceKeyForAccount(uint256 id, address account)
        external
        payable
    {
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

        uint256 total = tokenPrice * 1 wei;
        require(msg.value == total, "Amount sent is not correct.");

        distributeMintingCuts(id, total, account);
    }
}