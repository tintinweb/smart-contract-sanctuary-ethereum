// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

library MintAllowanceLib {
    /**
     * @dev Type of the Mint Allowance, depending of the reason why the user may mint a token
     */
    enum MintAllowanceType {
        RELIC_PASS,
        DISCOUNTED_SNEAKS_LIST,
        SNEAKS_LIST,
        GUARANTEED_ALLOWLIST
    }

    /**
     * @dev A structure containing information about every token the user is allowed to mint
     */
    struct MintAllowance {
        uint8 allowanceType; // Type of the allowance (one of the values in MintAllowanceType)
        uint256 price; // Price at which the user is allowed to mint a token
        uint16 relicPassId; // Id of the Relic Pass token that gives the user the right to mint or 0 for non Relic Pass allowence
        bool isUsed; // True if the user has already minted a token using this allowance
        bool isPublicMintOnly; // True it the user is allowed to mint this token only during the Public Mint period
    }

    uint256 public constant RELIC_PASS_REDUCED_PRICE = 0.33 ether;
    uint256 public constant RELIC_PASS_FULL_PRICE = 0.45 ether;
    uint256 public constant DISCOUNTED_SNEAKS_LIST_PRICE = 0.33 ether;
    uint256 public constant SNEAKS_LIST_PRICE = 0.4 ether;
    uint256 public constant GUARANTEED_ALLOWLIST_PRICE = 0.45 ether;

    /**
     * @notice This function determines how many tokens the user is allowed to mint, at what price and if they already used some of them.
     * The user is allowed to mint tokens in the following cases:
     * 1. The user owns a Relic Pass token - they may mint 3 tokens, 1x 0.00 ether, 1x 0.33 ether and 1x 0.45 ether.
     * 2. The user is on the Burned Punk allow list - they may mint one token at 0.33 ether in addition to the tokens from the Relic Pass tokens.
     * 3. The user is on the Special Discord Role allow list - they may mint one token at 0.4 ether, but only if they don't already have any Relic Pass tokens or Burned Punk tokens.
     * @dev Get information about the tokens the user is allowed to mint and their prices
     * @param relicPassIds List of the IDs of the Relic Pass tokens the user owns
     * @param isDiscountedSneaksList True if the user is on the Discounted Sneaks List, false otherwise
     * @param isSneaksList True if the user is on the Sneaks List, false otherwise
     * @param isGuaranteedAllowlist True if the user is on the Guaranteed Allowlist, false otherwise
     * @param relicPassesUsage A list of numbers specifying how many tokens were already minted for every Relic Pass token
     * @param isDiscountedSneaksList True if the user has already minted a token from their Discounted Sneaks List, false otherwise
     * @param isSneaksList True if the user has already minted a token from their Sneaks List, false otherwise
     * @param isGuaranteedAllowlist True if the user has already minted a token from their Guaranteed Allowlist, false otherwise
     * @return mints List of MintAllowance structures. There is one entry in the list for every token the user is allowed to mint.
     */
    function mintAllowance(
        uint16[] calldata relicPassIds,
        bool isDiscountedSneaksList,
        bool isSneaksList,
        bool isGuaranteedAllowlist,
        uint8[] calldata relicPassesUsage,
        bool isDiscountedSneaksListUsed,
        bool isSneaksListUsed,
        bool isGuaranteedAllowlistUsed
    ) public pure returns (MintAllowance[] memory mints) {
        // Calculate the total number of tokens the user is allowed to mint
        uint256 relicPassCount = relicPassIds.length;

        uint256 tokensCount = relicPassCount *
            3 +
            (isDiscountedSneaksList ? 1 : 0);

        if (
            relicPassCount == 0 &&
            !isDiscountedSneaksList &&
            (isSneaksList || isGuaranteedAllowlist)
        ) {
            tokensCount = 1;
        }

        mints = new MintAllowance[](tokensCount);

        // Add the free tokens from the Relic Pass tokens
        for (uint256 i = 0; i < relicPassCount; ++i) {
            uint16 relicPassId = relicPassIds[i];

            mints[i].allowanceType = uint8(MintAllowanceType.RELIC_PASS);
            mints[i].price = 0;
            mints[i].relicPassId = relicPassId;
            mints[i].isUsed = relicPassesUsage[i] > 0;
            mints[i].isPublicMintOnly = false;
        }

        uint256 currentIndex = relicPassCount;

        // Add the token from the Discounted Sneaks List
        if (isDiscountedSneaksList) {
            mints[currentIndex].allowanceType = uint8(
                MintAllowanceType.DISCOUNTED_SNEAKS_LIST
            );
            mints[currentIndex].price = DISCOUNTED_SNEAKS_LIST_PRICE;
            mints[currentIndex].relicPassId = 0;
            mints[currentIndex].isUsed = isDiscountedSneaksListUsed;
            mints[currentIndex].isPublicMintOnly = false;

            ++currentIndex;
        }

        // Add the reduced and full price mints from the Relic Pass tokens
        for (uint256 i = currentIndex; i < currentIndex + relicPassCount; ++i) {
            uint16 relicPassId = relicPassIds[i - currentIndex];

            mints[i].allowanceType = uint8(MintAllowanceType.RELIC_PASS);
            mints[i].price = RELIC_PASS_REDUCED_PRICE;
            mints[i].relicPassId = relicPassId;
            mints[i].isUsed = relicPassesUsage[i - currentIndex] > 1;
            mints[i].isPublicMintOnly = false;

            mints[i + relicPassCount].allowanceType = uint8(
                MintAllowanceType.RELIC_PASS
            );
            mints[i + relicPassCount].price = RELIC_PASS_FULL_PRICE;
            mints[i + relicPassCount].relicPassId = relicPassId;
            mints[i + relicPassCount].isUsed =
                relicPassesUsage[i - currentIndex] > 2;
            mints[i + relicPassCount].isPublicMintOnly = true;
        }

        // Add the token from the Sneaks List and Guaranteed Allowlist
        if (relicPassCount == 0 && !isDiscountedSneaksList) {
            if (isSneaksList) {
                mints[0].allowanceType = uint8(MintAllowanceType.SNEAKS_LIST);
                mints[0].price = SNEAKS_LIST_PRICE;
                mints[0].relicPassId = 0;
                mints[0].isUsed = isSneaksListUsed;
            } else if (isGuaranteedAllowlist) {
                mints[0].allowanceType = uint8(
                    MintAllowanceType.GUARANTEED_ALLOWLIST
                );
                mints[0].price = GUARANTEED_ALLOWLIST_PRICE;
                mints[0].relicPassId = 0;
                mints[0].isUsed = isGuaranteedAllowlistUsed;
            }
        }
    }
}