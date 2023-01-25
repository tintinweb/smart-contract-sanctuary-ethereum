// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {KomonERC1155} from "KomonERC1155.sol";
import {Modifiers} from "Modifiers.sol";

contract CreatorSpaceFacet105 is KomonERC1155, Modifiers {
    function removeLastSpaceToken() external onlyKomonWeb {
        _removeLastSpaceToken();
    }
}