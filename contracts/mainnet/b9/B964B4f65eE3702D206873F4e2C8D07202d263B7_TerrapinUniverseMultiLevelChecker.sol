// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface TerrapinUniverseInterface {
    function levelOf(uint256 tokenId) external view returns (uint256 level);
}

contract TerrapinUniverseMultiLevelChecker {
    TerrapinUniverseInterface constant HEROS =
        TerrapinUniverseInterface(0xD1f07a57928B42202Bb8e964Dd1954bD0deC8b34);
    TerrapinUniverseInterface constant VILLAINS =
        TerrapinUniverseInterface(0xBcBD44F440b4726F9469682b69fF0cd2298b1387);

    function levelOfHeros(
        uint256[] calldata tokenIds
    ) external view returns (uint256[] memory levels) {
        levels = new uint256[](tokenIds.length);
        for (uint i; i < tokenIds.length; ) {
            levels[i] = HEROS.levelOf(tokenIds[i]);
            unchecked {
                i++;
            }
        }
    }

    function levelOfVillains(
        uint256[] calldata tokenIds
    ) external view returns (uint256[] memory levels) {
        levels = new uint256[](tokenIds.length);
        for (uint i; i < tokenIds.length; ) {
            levels[i] = VILLAINS.levelOf(tokenIds[i]);
            unchecked {
                i++;
            }
        }
    }
}