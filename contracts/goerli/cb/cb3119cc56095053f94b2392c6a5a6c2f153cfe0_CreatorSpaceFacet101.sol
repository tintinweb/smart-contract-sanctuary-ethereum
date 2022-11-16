// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {KomonERC1155} from "KomonERC1155.sol";
import {KomonAccessControlBaseStorage} from "KomonAccessControlBaseStorage.sol";
import {AddressUtils} from "AddressUtils.sol";

contract CreatorSpaceFacet101 is KomonERC1155 {
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
}