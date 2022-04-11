/* SPDX-License-Identifier: MIT */

pragma solidity ^0.8.12;

contract RescueToadzNounsExecutor {
    address internal constant RESCUE_TOADZ_CONTRACT =
        0x03115Dafa9c3F23BEB8ECDA7F099fD4C09981E82;

    address internal constant NOUNS_CONTRACT =
        0x6F3940820288855418B7ef8E33a2eC23d9DeD59B;

    constructor() {}

    function captureRescueToad(uint256 tokenId) external payable {
        require(tokenId <= 18, "Cannot capture token with id > 18");
        require(tokenId > 0, "Cannot capture token with id <= 0");

        bytes memory payload = abi.encodeWithSignature(
            "lastPrice(uint256)",
            tokenId
        );

        (bool success, bytes memory result) = RESCUE_TOADZ_CONTRACT.call(
            payload
        );

        if (success) {
            uint256 lastTokenPrice = abi.decode(result, (uint256));

            if (lastTokenPrice <= msg.value) {
                bytes memory capturePayload = abi.encodeWithSignature(
                    "capture(uint256)",
                    tokenId
                );

                (bool s, bytes memory r) = RESCUE_TOADZ_CONTRACT.call(
                    capturePayload
                );
            }
        }
    }
}