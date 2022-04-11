/* SPDX-License-Identifier: MIT */

pragma solidity ^0.8.12;

interface RescueToadz {
    function lastPrice(uint256 tokenId) external view returns (uint256);

    function capture(uint256 tokenId) external payable;
}

contract RescueToadzNounsExecutor {
    address internal constant RESCUE_TOADZ_CONTRACT =
        0x03115Dafa9c3F23BEB8ECDA7F099fD4C09981E82;

    address internal constant NOUNS_CONTRACT =
        0x6F3940820288855418B7ef8E33a2eC23d9DeD59B;

    constructor() {}

    function lastPrice(uint256 tokenId) external view returns (uint256) {
        uint256 lastTokenPrice = RescueToadz(RESCUE_TOADZ_CONTRACT).lastPrice(
            tokenId
        );
        return lastTokenPrice;
    }

    function captureRescueToad(uint256 tokenId) external payable {
        require(tokenId <= 18, "Cannot capture token with id > 18");
        require(tokenId > 0, "Cannot capture token with id <= 0");

        uint256 lastTokenPrice = RescueToadz(RESCUE_TOADZ_CONTRACT).lastPrice(
            tokenId
        );

        if (lastTokenPrice <= msg.value) {
            RescueToadz(RESCUE_TOADZ_CONTRACT).capture(tokenId);
        }
    }
}