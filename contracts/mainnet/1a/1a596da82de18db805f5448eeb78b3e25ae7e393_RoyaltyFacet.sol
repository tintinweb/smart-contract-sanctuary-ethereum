// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {KomonERC2981} from "KomonERC2981.sol";
import {Modifiers} from "Modifiers.sol";

contract RoyaltyFacet is KomonERC2981, Modifiers {
    function updateDefaultRoyaltyInfo(
        address defaultReceiver,
        uint256 defaultRoyalty
    ) external onlyKomonWeb {
        setDefaultRoyaltyInfo(defaultReceiver, defaultRoyalty);
    }

    function updateTokenRoyaltyInfo(
        uint256 tokenId,
        address receiver,
        uint256 royalty
    ) external onlyKomonWeb {
        setTokenRoyaltyInfo(tokenId, receiver, royalty);
    }
}