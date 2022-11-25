// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {KomonERC1155} from "KomonERC1155.sol";
import {KomonAccessControlBaseStorage} from "KomonAccessControlBaseStorage.sol";

contract CreatorSpaceFacet102 is KomonERC1155 {
    uint256 private constant LESS_THAN_TOKEN_NUMBER_ALLOWED = 2;

    function mintSpaceKey(uint256 id, uint256 amount) external payable {
        require(
            balanceOf(msg.sender, id) + amount < LESS_THAN_TOKEN_NUMBER_ALLOWED,
            "Can't have more than 1 token id type per wallet"
        );
        require(amount > 0, "You have to mint at least 1 token.");
        uint256 tokenPrice = tokenPrice(id);
        require(
            (totalSupply(id) + amount) <= maxSupply(id),
            "Max amount of token reached."
        );
        require(tokenPrice > 0, "Token price must be more than 0.");

        uint256 total = amount * tokenPrice * 1 wei;
        require(msg.value == total, "Amount sent is not correct.");

        distributeMintingCuts(id, total);
    }

    function upgradeKey(uint256 previousTokenId, uint256 nextTokenId)
        external
        payable
    {
        // Caller must own the previous token id
        require(
            balanceOf(msg.sender, previousTokenId) > 0,
            "Caller must be the owner of the token id to upgrade."
        );
        // There should be upgrade tokens available
        require(
            (totalSupply(nextTokenId) + 1) <= maxSupply(nextTokenId),
            "There are not tokens to mint available."
        );

        uint256 previousTokenPrice = tokenPrice(previousTokenId);
        uint256 nextTokenPrice = tokenPrice(nextTokenId);

        // Upgrade cost must be more than original token cost
        require(
            nextTokenPrice > previousTokenPrice,
            "Upgrade token cost must be more than the original token cost"
        );

        // Calculating difference between the two prices
        uint256 upgradeCost = nextTokenPrice - previousTokenPrice;

        // Ether amount sent must be equal to upgrade cost
        require(msg.value == upgradeCost, "Amount sent is not correct.");

        // Transfer previous token id to komon assets account
        address assetsToKomonAccount = KomonAccessControlBaseStorage
            .layout()
            ._assetsToKomonAccount;
        _safeTransfer(
            msg.sender,
            msg.sender,
            assetsToKomonAccount,
            previousTokenId,
            1,
            ""
        );

        distributeMintingCuts(nextTokenId, upgradeCost);
    }
}