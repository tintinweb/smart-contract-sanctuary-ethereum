//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract PlatformSettingsConsts {
    bytes32 public constant PIXU_PAUSED = "PixuPaused";

    bytes32 public constant PIXU_CATS_PAUSED = "PixuCatsPaused";

    bytes32 public constant YUMIOS_PAUSED = "YumiosPaused";

    // This constants were added for the farming contracts.
    bytes32 public constant FARMING_BONUS_MULTIPLIER = "FarmingBonusMultiplier";

    bytes32 public constant FARMING_ALLOW_ONLY_EOA = "FarmingAllowOnlyEOA";
}