// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {KomonERC1155} from "KomonERC1155.sol";
import {KomonAccessControlBaseStorage} from "KomonAccessControlBaseStorage.sol";
import {Modifiers} from "Modifiers.sol";
import {AddressUtils} from "AddressUtils.sol";

contract CreatorSpaceFacet is KomonERC1155, Modifiers {
    function createSpaceToken(
        uint256[] calldata maxSupplies,
        uint256[] calldata prices,
        uint8[] calldata percentages,
        address creatorAccount
    ) external onlyKomonWeb {
        _createSpaceToken(maxSupplies, prices, percentages, creatorAccount);
    }

    function updateTokensPrice(
        uint256[] calldata tokenIds,
        uint256[] calldata prices
    ) external onlyKomonWeb {
        setTokensPrice(tokenIds, prices, true);
    }

    function updateTokensPercentage(
        uint256[] calldata tokenIds,
        uint8[] calldata percentages
    ) external onlyKomonWeb {
        setTokensPercentage(tokenIds, percentages, true);
    }

    function mintSpaceKey(uint256 id, uint256 amount) external payable {
        require(amount > 0, "You have to mint at least 1 token.");
        uint256 tokenPrice = tokenPrice(id);
        require(
            (totalSupply(id) + amount) <= maxSupply(id),
            "Max amount of token reached."
        );
        require(tokenPrice > 0, "Token price must be more than 0.");

        uint256 total = amount * tokenPrice * 1 wei;
        require(msg.value == total, "Amount sent is not correct.");

        uint256 creatorCut = calculateCreatorCut(id, total);
        uint256 komonCut = total - creatorCut;

        address komonExchangeAccount = KomonAccessControlBaseStorage
            .layout()
            ._komonExchangeAccount;
        address creatorAccount = creatorTokenOwner(id);

        AddressUtils.sendValue(payable(komonExchangeAccount), komonCut);
        AddressUtils.sendValue(payable(creatorAccount), creatorCut);

        _safeMint(msg.sender, id, amount, "");
    }

    function mintInternalKey(uint256 amount) external onlyKomonWeb {
        require(amount > 0, "You have to mint at least 1 token.");
        _mintInternalKey(amount);
    }
}