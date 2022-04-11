// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

contract ETHSplitter {
    address payable public immutable primaryAddress;
    address payable public immutable secondaryAddress;
    uint256 public immutable secondaryAmountPercent;

    constructor(
        address payable givenPrimaryAddress,
        address payable givenSecondaryAddress,
        uint256 givenSecondaryAmountPercent
    ) {
        primaryAddress = givenPrimaryAddress;
        secondaryAddress = givenSecondaryAddress;
        secondaryAmountPercent = givenSecondaryAmountPercent;
    }

    receive() external payable {
        require(msg.value > 100, "must be more than 100");
        uint256 onePercentAmount = msg.value / 100;
        uint256 secondaryAmount = onePercentAmount * secondaryAmountPercent;
        uint256 primaryAmount = msg.value - secondaryAmount;

        (bool primarySent, ) = primaryAddress.call{value: primaryAmount}("");
        require(primarySent, "failed to send to primary");

        (bool secondarySent, ) = secondaryAddress.call{value: secondaryAmount}(
            ""
        );
        require(secondarySent, "failed to send to secondary");
    }
}