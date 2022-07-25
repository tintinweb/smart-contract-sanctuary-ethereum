// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IEveraiDataCard {
    function burn(uint256 tokenId) external;

    function mint(address to, uint256 quantity) external;
}

contract EveraiUpgradeArchive {
    IEveraiDataCard public everaiDataCard;

    event UpgradeArchive(uint256[] memoryCoreIds, uint256 archiveType);

    constructor(address memoryCoreAddress) {
        everaiDataCard = IEveraiDataCard(memoryCoreAddress);
    }

    function upgrade(uint256[] calldata tokenIds, uint256 archiveType)
        external
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            everaiDataCard.burn(tokenIds[i]);
            emit UpgradeArchive(tokenIds, archiveType);
        }
    }
}