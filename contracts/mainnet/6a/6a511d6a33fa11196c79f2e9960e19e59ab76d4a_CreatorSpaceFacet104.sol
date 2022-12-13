// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {KomonERC1155} from "KomonERC1155.sol";
import {KomonAccessControlBaseStorage} from "KomonAccessControlBaseStorage.sol";

contract CreatorSpaceFacet104 is KomonERC1155 {
    function upgradeKeyForAccount(
        uint256 previousTokenId,
        uint256 nextTokenId,
        address account
    ) external payable {
        // Caller must own the previous token id
        require(
            balanceOf(account, previousTokenId) > 0,
            "Account sent must be the owner of the token id to upgrade."
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
            account,
            account,
            assetsToKomonAccount,
            previousTokenId,
            1,
            ""
        );

        distributeMintingCuts(nextTokenId, upgradeCost, account);
    }
}