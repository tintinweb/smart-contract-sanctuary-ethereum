// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC721} from "./IERC721.sol";

import {ITransferManagerNFT} from "./ITransferManagerNFT.sol";

/**
 * @title TransferManagerERC721
 * @notice It allows the transfer of ERC721 tokens.
 */
contract TransferManagerERC721 is ITransferManagerNFT {
    address public immutable NovaPlanet_EXCHANGE;

    /**
     * @notice Constructor
     * @param _novaPlanetExchange address of the novaPlanet exchange
     */
    constructor(address _novaPlanetExchange) {
        NovaPlanet_EXCHANGE = _novaPlanetExchange;
    }

    /**
     * @notice Transfer ERC721 token
     * @param collection address of the collection
     * @param from address of the sender
     * @param to address of the recipient
     * @param tokenId tokenId
     * @dev For ERC721, amount is not used
     */
    function transferNonFungibleToken(
        address collection,
        address from,
        address to,
        uint256 tokenId,
        uint256
    ) external override {
        require(msg.sender == NovaPlanet_EXCHANGE, "Transfer: Only LooksRare Exchange");
        // https://docs.openzeppelin.com/contracts/2.x/api/token/erc721#IERC721-safeTransferFrom
        IERC721(collection).safeTransferFrom(from, to, tokenId);
    }
}