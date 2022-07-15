// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library AssetRenderer4 {

    /**
    * @notice render a headgear asset
    * @param smAssetId the small asset id of the gear item
    * @return string of svg
    */
    function renderHeadgear(uint256 smAssetId)
        external
        pure
        returns (string memory)
    {
        string[17] memory GEAR = [
            // START HEADGEAR
            // 0 none
            '%253Cg%253E%253C/g%253E',
            // 1 bandana
            '%253Cg%253E%253Cpath d=\'M9,3h3v1h1v2h-6v1h-1v1h-1v-2h1v-1h2v-1h1z\' fill=\'var(--dm6)\'/%253E%253Cpath d=\'M9,3h1v1h-1v1h-1v1h-1v1h-1v1h-1v-1h1v-1h1v-1h1v-1h1zM11,4h2v2h-1v-1h-1z\' fill=\'var(--dm5)\'/%253E%253Cpath d=\'M8,4h1v2h1v-1h3v2h-3v1h-1v1h-1v-3h-1v1h-1v1h-1v-2h2v-1h1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 2 leather hat
            '%253Cg%253E%253Cpath d=\'M8,2h4v1h1v1h1v2h-4v1h-3v-4h1z\' fill=\'var(--dm48)\'/%253E%253Cpath d=\'M8,2h4v1h1v1h1v2h-2v-1h1v-1h-1v-1h-3v2h2v1h2v1h-3v1h-1v1h-1v-2h-1v-4h1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 3 rusty helm
            '%253Cg%253E%253Cpath d=\'M8,2h5v1h1v4h-1v-2h-1v1h-1v-1h-2v2h-2v-4h1z\' fill=\'var(--dm48)\'/%253E%253Cpath d=\'M9,2h3v1h1v1h-1v1h-1v-1h-3v-1h1z\' fill=\'var(--dm41)\'/%253E%253Cpath d=\'M8,2h2v1h-1v2h2v1h1v-1h1v-1h1v3h-1v-1h-1v1h-1v-1h-1v1h-1v2h-1v-2h-1v-4h1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 4 feathered cap
            '%253Cg%253E%253Cpath d=\'M7,2h5v1h1v1h1v1h2v1h-9z\' fill=\'var(--dm20)\'/%253E%253Cpath d=\'M5,1h3v1h1v1h1v1h1v1h-2v-1h-2v-1h-2z\' fill=\'var(--dm38)\'/%253E%253Cpath d=\'M7,1h1v1h-1zM5,2h1v1h-1zM7,3h2v1h1v1h-1v-1h-2z\' fill=\'var(--dm37)\'/%253E%253Cpath d=\'M5,1h1v1h1v1h1v1h1v1h2v-1h-1v-1h-1v-1h1v1h1v1h3v1h-2v1h1v1h-4v2h-1v-3h-1v-3h-2z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 5 enchanted crown
            '%253Cg%253E%253Cpath d=\'M9,1h1v2h1v-2h1v2h1v-2h1v4h-7v-3h1v1h1z\' fill=\'var(--dm12)\'/%253E%253Cpath d=\'M9,1h1v1h-1zM13,1h1v1h-1zM7,3h1v1h1v1h2v1h-4zM13,4h1v1h-1z\' fill=\'var(--dm11)\'/%253E%253Cpath d=\'M11,1h1v1h-1zM13,3h1v2h-1v1h-2v1h-2v1h-1v-2h-1v-2h1v1h4v-1h1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 6 bronze helm
            '%253Cg%253E%253Cpath d=\'M8,2h5v1h1v5h-1v-3h-4v3h-2v-5h1z\' fill=\'var(--dm41)\'/%253E%253Cpath d=\'M9,2h3v1h1v1h-1v1h-2v-1h-2v-1h1z\' fill=\'var(--dm11)\'/%253E%253Cpath d=\'M9,2h3v1h-3v1h-1v2h1v-1h1v-1h1v1h-1v2h-1v1h1v1h-2v-1h-1v-4h1v-1h1zM13,4h1v4h-1v1h-1v-1h1v-1h-1v-2h1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 7 assassin's mask
            '%253Cg%253E%253Cpath d=\'M9,3h3v1h1v1h-4v1h2v-1h1v1h1v1h-3v1h2v-1h1v2h-5v-5h1z\' fill=\'var(--dm34)\'/%253E%253Cpath d=\'M9,3h1v1h3v3h-1v-1h-2v1h-1v1h1v1h-2v-5h1zM12,8h1v1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 8 iron helm
            '%253Cg%253E%253Cpath d=\'M8,2h5v1h1v6h-2v-2h1v-3h-1v1h-1v-1h-2v3h1v2h-3v-6h1z\' fill=\'var(--dm37)\'/%253E%253Cpath d=\'M9,2h4v1h1v1h-1v-1h-1v1h-1v-1h-2z\' fill=\'var(--dm38)\'/%253E%253Cpath d=\'M8,2h2v2h-2v1h1v-1h2v1h1v-1h1v1h1v1h-1v1h-1v-1h-1v-1h-1v2h-1v-1h-1v1h1v1h4v-1h1v2h-7v-6h1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 9 soul shroud
            '%253Cg%253E%253Cpath d=\'M7,2h6v1h1v2h-4v1h3v-1h1v3h-1v2h-1v1h-1v-1h-1v-1h-2v-1h-1v-1h1v-4h-1z\' fill=\'var(--dm32)\'/%253E%253Cpath d=\'M10,3h3v1h1v1h-5v-1h1zM10,6h4v1h-1v1h-1v1h-1v-2h-1z\' fill=\'var(--dm10)\'/%253E%253Cpath d=\'M7,2h3v1h1v1h-1v2h-1v-1h-1v-2h-1zM12,2h1v1h1v1h-1v-1h-1zM7,7h2v1h1v1h1v1h1v-1h1v1h-1v1h-1v-1h-1v-1h-2v-1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 10 misty hood
            '%253Cg%253E%253Cpath d=\'M9,2h4v1h1v6h-1v2h-1v-2h1v-4h-1v1h-1v2h-1v3h-1v-1h-1v-1h-1v-4h1v-2h1z\' fill=\'var(--dm35)\'/%253E%253Cpath d=\'M11,2h1v1h1v1h-1v-1h-1v1h1v1h-1v1h-1v1h-2v-1h1v-2h1v-1h1z\' fill=\'var(--dm37)\'/%253E%253Cpath d=\'M9,2h1v1h1v1h-1v2h-1v-1h-1v1h-1v-1h1v-2h1M12,2h1v1h1v1h-1v-1h-1zM12,5h2v1h-2v1h-1v-1h1zM7,7h2v1h4v-1h1v2h-3v1h-1v1h-1v-2h-2zM12,10h1v1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 11 genesis helm
            '%253Cg%253E%253Cpath d=\'M7,2h5v1h1v1h1v4h-1v-2h-3v2h-3z\' fill=\'var(--dm49)\'/%253E%253Cpath d=\'M4,1h3v1h1v2h1v1h-1v-1h-1v-1h-1v1h-1v1h-1v1h-1v-1h1v-1h1v-2h-1v1h-1v1h-1v-1h1v-1h1zM16,1h2v1h1v1h-1v-1h-1v2h1v1h-1v-1h-1v-1h-1v2h-1v-2h1v-1h1z\' fill=\'var(--dm52)\'/%253E%253Cpath d=\'M6,2h4v1h1v1h-1v2h1v-1h2v-1h2v1h-1v3h-1v1h-1v-1h1v-1h-3v-1h-3v-3h-1v1h-1v1h-1v1h-1v-1h1v-1h1v-1h1zM16,2h1v2h1v1h-1v-1h-1zM7,7h2v1h1v1h-2v-1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 12 ranger cap
            '%253Cg%253E%253Cpath d=\'M8,2h4v1h1v1h1v1h1v1h-9v-1h1v-2h1z\' fill=\'var(--dm19)\'/%253E%253Cpath d=\'M7,4h7v1h-7z\' fill=\'var(--dm48)\'/%253E%253Cpath d=\'M8,2h1v1h1v2h1v1h2v1h-3v1h-1v1h-1v-3h-2v-1h1v-2h1zM11,2h1v1h1v1h1v1h1v1h-1v-1h-1v-1h-1v-1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 13 ancient mask
            '%253Cg%253E%253Cpath d=\'M10,2h2v1h1v2h-4v1h2v-1h1v1h1v4h-1v1h-2v-1h-1v-1h-1v-6h2z\' fill=\'var(--dm41)\'/%253E%253Cpath d=\'M9,4h2v1h-2zM12,4h1v1h-1zM11,6h1v3h-2v-1h1z\' fill=\'var(--dm40)\'/%253E%253Cpath d=\'M12,3h1v1h-1v1h1v1h-5v-1h3v-1h1zM8,7h1v1h1v-1h3v3h-1v1h-2v-1h-1v-1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 14 charmed headband
            '%253Cg%253E%253Cpath d=\'M8,4h5v2h-6v1h-2v-1h1v-1h2z\' fill=\'var(--dm2)\'/%253E%253Cpath d=\'M5,4h1v1h-1zM7,5h1v1h-1v1h-1v-1h1zM11,5h1v1h-1z\' fill=\'var(--dm1)\'/%253E%253Cpath d=\'M11,3h1v2h-1z\' fill=\'var(--dm31)\'/%253E%253Cpath d=\'M8,4h1v1h1v1h-3v1h-2v-1h2v-1h1zM11,4h2v2h-2z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 15 skull helm
            '%253Cg%253E%253Cpath d=\'M8,2h5v1h1v2h-5v2h2v-2h1v2h1v-2h1v4h-1v1h-3v-1h-2v-1h-1v-5h1z\' fill=\'var(--dm38)\'/%253E%253Cpath d=\'M10,2h2v1h1v1h-1v3h-1v1h1v-1h2v1h-1v2h-2v-2h-1v-1h1v-3h-2v1h-1v-2h2z\' fill=\'white\'/%253E%253Cpath d=\'M8,2h1v2h1v1h1v1h-2v-2h-2v-1h1zM12,4h2v2h-2zM7,5h1v2h1v1h1v1h1v1h-1v-1h-2v-1h-1zM13,7h1v2h-1v2h-1v-2h1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 16 phoenix helm
            '%253Cg%253E%253Cpath d=\'M9,1h4v1h1v6h-1v-3h-4v3h-2v-6h2z\' fill=\'var(--dm41)\'/%253E%253Cpath d=\'M2,1h5v1h1v1h1v-1h3v-1h1v1h-1v1h1v-1h1v1h-1v1h-1v1h-2v-2h-1v2h-2v-1h-1v-1h-2v-1h-2z\' fill=\'var(--dm11)\'/%253E%253Cpath d=\'M9,1h2v1h-2v1h-1v1h4v1h1v-1h1v2h-6v1h1v1h1v1h-2v-1h-1v-4h-1v-1h-2v-1h3v1h1v-1h1zM13,7h1v1h-1v1h-1v-1h1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E'
            // END HEADGEAR
        ];
        return GEAR[smAssetId];
    }

    /**
    * @notice render an armor asset
    * @param smAssetId the small asset id of the gear item
    * @return string of svg
    */
    function renderArmor(uint256 smAssetId)
        external
        pure
        returns (string memory)
    {
        string[5] memory GEAR = [
            // START ARMOR
            // 0 standard armor
            '%253Cg%253E%253Cg%253E%253Cpath d=\'M12,9h1v1h1v2h1v3h-4v-3h-1v-2h1z\' fill=\'var(--dmpa2)\'/%253E%253Cpath d=\'M12,9h1v1h1v2h1v3h-4v-3h-1v-2h1z\' fill=\'var(--dmb35)\'/%253E%253Cpath d=\'M12,9h1v1h1v2h1v1h-1v2h-1v-2h1v-1h-1v-2h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253Cg%253E%253Cpath d=\'M8,9h4v1h1v5h-6v-5h1z\' fill=\'var(--dmpa1)\'/%253E%253Cpath d=\'M9,10h4v1h-1v1h-1v2h-1v-3h-1z\' fill=\'var(--dmpa4)\'/%253E%253Cpath d=\'M9,9h1v2h-1v3h1v1h-3v-3h1v-1h1zM11,9h1v1h1v5h-2v-1h1v-4h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253Cg%253E%253Cpath d=\'M6,9h3v2h-1v1h-1v1h-1v1h-1v-1h-1v-2h1v-1h1z\' fill=\'var(--dmpa2)\'/%253E%253Cpath d=\'M7,9h2v2h-1v1h-1v1h-1v-1h1v-1h1v-1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253Cg%253E%253Cpath d=\'M3,12h2v1h1v2h1v1h-4zM15,13h2v3h-3v-2h1z\' fill=\'var(--dmpa3)\'/%253E%253Cpath d=\'M3,13h1v3h-1zM5,13h1v1h-1zM14,14h1v1h1v1h-2z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253C/g%253E',
            // 1 cape
            '%253Cg%253E%253Cg%253E%253Cpath d=\'M12,9h1v1h1v2h1v3h-4v-3h-1v-2h1z\' fill=\'var(--dmpa2)\'/%253E%253Cpath d=\'M12,9h1v1h1v2h1v3h-4v-3h-1v-2h1z\' fill=\'var(--dmb35)\'/%253E%253Cpath d=\'M12,9h1v1h1v2h1v1h-1v2h-1v-2h1v-1h-1v-2h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253Cg%253E%253Cpath d=\'M8,9h4v1h1v5h-6v-5h1z\' fill=\'var(--dmpa1)\'/%253E%253Cpath d=\'M8,9h5v2h-1v1h-1v1h-2v1h-2v-1h1v-1h1v-2h-1z\' fill=\'var(--dmpa4)\'/%253E%253Cpath d=\'M12,9h1v1h-1zM7,13h1v1h-1z\' fill=\'var(--dmb4)\'/%253E%253Cpath d=\'M9,9h1v2h-1v3h1v1h-3v-3h1v-1h1zM11,9h1v1h1v5h-2v-1h1v-4h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253Cg%253E%253Cpath d=\'M6,9h3v2h-1v1h-1v1h-1v1h-1v-1h-1v-2h1v-1h1z\' fill=\'var(--dmpa2)\'/%253E%253Cpath d=\'M7,9h2v2h-1v1h-1v1h-1v-1h1v-1h1v-1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253Cg%253E%253Cpath d=\'M3,12h2v1h1v2h1v1h-4zM15,13h2v3h-3v-2h1z\' fill=\'var(--dmpa3)\'/%253E%253Cpath d=\'M3,13h1v3h-1zM5,13h1v1h-1zM14,14h1v1h1v1h-2z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253C/g%253E',
            // 2 skull
            '%253Cg%253E%253Cg%253E%253Cpath d=\'M12,9h1v1h1v2h1v3h-4v-3h-1v-2h1z\' fill=\'var(--dm37)\'/%253E%253Cpath d=\'M12,9h1v1h1v2h1v3h-4v-3h-1v-2h1z\' fill=\'var(--dmb35)\'/%253E%253Cpath d=\'M12,9h1v1h1v2h1v1h-1v2h-1v-2h1v-1h-1v-2h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253Cg%253E%253Cpath d=\'M8,9h4v1h1v5h-6v-5h1z\' fill=\'var(--dm38)\'/%253E%253Cpath d=\'M9,10h4v1h-1v1h-1v2h-1v-3h-1z\' fill=\'white\'/%253E%253Cpath d=\'M9,10h2v2h1v-2h1v2h-1v1h-1v-1h-2z\' fill=\'var(--dm36)\'/%253E%253Cpath d=\'M9,9h1v2h-1v3h1v1h-3v-3h1v-1h1zM11,9h1v1h1v5h-2v-1h1v-4h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253Cg%253E%253Cpath d=\'M6,9h3v2h-1v1h-1v1h-1v1h-1v-1h-1v-2h1v-1h1z\' fill=\'var(--dm38)\'/%253E%253Cpath d=\'M7,9h2v2h-1v1h-1v1h-1v-1h1v-1h1v-1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253Cg%253E%253Cpath d=\'M3,12h2v1h1v2h1v1h-4zM15,13h2v3h-3v-2h1z\' fill=\'white\'/%253E%253Cpath d=\'M3,13h1v3h-1zM5,13h1v1h-1zM14,14h1v1h1v1h-2z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253C/g%253E',
            // 3 chain
            '%253Cg%253E%253Cg%253E%253Cpath d=\'M12,9h1v1h1v2h1v3h-4v-3h-1v-2h1z\' fill=\'var(--dmpa2)\'/%253E%253Cpath d=\'M12,9h1v1h1v2h1v3h-4v-3h-1v-2h1z\' fill=\'var(--dmb35)\'/%253E%253Cpath d=\'M12,9h1v1h1v2h1v1h-1v2h-1v-2h1v-1h-1v-2h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253Cg%253E%253Cpath d=\'M8,9h4v1h1v5h-6v-5h1z\' fill=\'var(--dmpa1)\'/%253E%253Cpath d=\'M8,9h4v1h1v5h-6v-5h1z\' fill=\'var(--dmpa4)\'/%253E%253Cpath d=\'M9,9h1v2h-1v3h1v1h-3v-3h1v-1h1zM11,9h1v1h1v5h-2v-1h1v-4h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253Cg%253E%253Cpath d=\'M6,9h3v2h-1v1h-1v1h-1v1h-1v-1h-1v-2h1v-1h1z\' fill=\'var(--dmpa2)\'/%253E%253Cpath d=\'M7,9h2v2h-1v1h-1v1h-1v-1h1v-1h1v-1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253Cg%253E%253Cpath d=\'M3,12h2v1h1v2h1v1h-4zM15,13h2v3h-3v-2h1z\' fill=\'var(--dmpa3)\'/%253E%253Cpath d=\'M3,13h1v3h-1zM5,13h1v1h-1zM14,14h1v1h1v1h-2z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253C/g%253E',
            // 4 shimmering
            '%253Cg%253E%253Cg%253E%253Cpath d=\'M12,9h1v1h1v2h1v3h-4v-3h-1v-2h1z\' fill=\'var(--dm38)\'/%253E%253Cpath d=\'M14,13h1v1h-1z\' fill=\'var(--dm11)\'/%253E%253Cpath d=\'M12,9h1v1h1v2h1v3h-4v-3h-1v-2h1z\' fill=\'var(--dmb35)\'/%253E%253Cpath d=\'M12,9h1v1h1v2h1v1h-1v2h-1v-2h1v-1h-1v-2h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253Cg%253E%253Cpath d=\'M8,9h4v1h1v5h-6v-5h1z\' fill=\'var(--dm36)\'/%253E%253Cpath d=\'M8,10h1v1h-1zM10,10h1v1h-1zM12,10h1v1h-1zM8,12h1v1h-1zM10,12h1v1h-1zM12,12h1v1h-1zM8,14h1v1h-1zM10,14h1v1h-1zM12,14h1v1h-1z\' fill=\'var(--dm11)\'/%253E%253Cpath d=\'M9,9h1v2h-1v3h1v1h-3v-3h1v-1h1zM11,9h1v1h1v5h-2v-1h1v-4h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253Cg%253E%253Cpath d=\'M6,9h3v2h-1v1h-1v1h-1v1h-1v-1h-1v-2h1v-1h1z\' fill=\'var(--dm38)\'/%253E%253Cpath d=\'M8,9h1v1h-1zM6,10h1v1h-1zM5,12h1v1h-1z\' fill=\'var(--dm11)\'/%253E%253Cpath d=\'M7,9h2v2h-1v1h-1v1h-1v-1h1v-1h1v-1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253Cg%253E%253Cpath d=\'M3,12h2v1h1v2h1v1h-4zM15,13h2v3h-3v-2h1z\' fill=\'white\'/%253E%253Cpath d=\'M3,13h1v3h-1zM5,13h1v1h-1zM14,14h1v1h1v1h-2z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253C/g%253E'
            // END ARMOR
        ];
        return GEAR[smAssetId];
    }

    /**
    * @notice render a pants asset
    * @param smAssetId the small asset id of the gear item
    * @return string of svg
    */
    function renderPants(uint256 smAssetId)
        external
        pure
        returns (string memory)
    {
        string[4] memory GEAR = [
            // START PANTS
            // 0 standard
            '%253Cg%253E%253Cg%253E%253Cpath d=\'M7,15h6v1h1v2h-3v-1h-2v1h-3v-2h1z\' fill=\'var(--dmpp1)\'/%253E%253Cpath d=\'M7,15h1v1h-1v2h-1v-2h1zM9,16h3v1h1v1h-2v-1h-2v1h-1v-1h1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253Cg%253E%253Cpath d=\'M6,17h3v2h-1v1h-1v1h-3v-1h1v-2h1zM13,17h2v1h1v3h-3v-2h-1v-1h1z\' fill=\'var(--dmpp2)\'/%253E%253Cpath d=\'M6,17h1v1h1v-1h1v2h-1v1h-1v-2h-1v1h-1v-1h1zM14,17h1v1h1v1h-1v-1h-1zM12,18h1v1h1v1h-1v-1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253C/g%253E',
            // 1 shine
            '%253Cg%253E%253Cg%253E%253Cpath d=\'M7,15h6v1h1v2h-3v-1h-2v1h-3v-2h1z\' fill=\'var(--dmpp1)\'/%253E%253Cpath d=\'M7,15h1v1h-1v2h-1v-2h1zM9,16h3v1h1v1h-2v-1h-2v1h-1v-1h1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253Cg%253E%253Cpath d=\'M6,17h3v2h-1v1h-1v1h-3v-1h1v-2h1zM13,17h2v1h1v3h-3v-2h-1v-1h1z\' fill=\'var(--dmpp2)\'/%253E%253Cpath d=\'M7,17h1v1h-1v1h-1v-1h1zM13,17h1v1h1v1h-1v-1h-1z\' fill=\'var(--dmpp3)\'/%253E%253Cpath d=\'M6,17h1v1h1v-1h1v2h-1v1h-1v-2h-1v1h-1v-1h1zM14,17h1v1h1v1h-1v-1h-1zM12,18h1v1h1v1h-1v-1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253C/g%253E',
            // 2 ancient
            '%253Cg%253E%253Cg%253E%253Cpath d=\'M7,15h6v1h1v2h-3v-1h-2v1h-3v-2h1z\' fill=\'var(--dm44)\'/%253E%253Cpath d=\'M7,15h1v1h-1v2h-1v-2h1zM9,16h3v1h1v1h-2v-1h-2v1h-1v-1h1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253Cg%253E%253Cpath d=\'M6,17h3v2h-1v1h-1v1h-3v-1h1v-2h1zM13,17h2v1h1v3h-3v-2h-1v-1h1z\' fill=\'var(--dm41)\'/%253E%253Cpath d=\'M14,17h1v1h1v2h-1v-2h-1zM5,18h1v2h-1zM8,18h1v1h-1v1h-1v-1h1z\' fill=\'var(--dm48)\'/%253E%253Cpath d=\'M6,17h1v1h1v-1h1v2h-1v1h-1v-2h-1v1h-1v-1h1zM14,17h1v1h1v1h-1v-1h-1zM12,18h1v1h1v1h-1v-1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253C/g%253E',
            // 3 chain
            '%253Cg%253E%253Cg%253E%253Cpath d=\'M7,15h6v1h1v2h-3v-1h-2v1h-3v-2h1z\' fill=\'var(--dm48)\'/%253E%253Cpath d=\'M12,15h1v1h1v2h-3v-1h-2v1h-3v-2h6z\' fill=\'url(%2523ch1)\'/%253E%253Cpath d=\'M7,15h1v1h-1v2h-1v-2h1zM9,16h3v1h1v1h-2v-1h-2v1h-1v-1h1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253Cg%253E%253Cpath d=\'M6,17h3v2h-1v1h-1v1h-3v-1h1v-2h1zM13,17h2v1h1v3h-3v-2h-1v-1h1z\' fill=\'var(--dm48)\'/%253E%253Cpath d=\'M6,17h3v2h-1v1h-3v-2h1zM13,17h2v1h1v2h-3v-1h-1v-1h1z\' fill=\'url(%2523ch1)\'/%253E%253Cpath d=\'M6,17h1v1h1v-1h1v2h-1v1h-1v-2h-1v1h-1v-1h1zM14,17h1v1h1v1h-1v-1h-1zM12,18h1v1h1v1h-1v-1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253C/g%253E'
            // END PANTS
        ];
        return GEAR[smAssetId];
    }

    /**
    * @notice render a footwear asset
    * @param smAssetId the small asset id of the gear item
    * @return string of svg
    */
    function renderFootwear(uint256 smAssetId)
        external
        pure
        returns (string memory)
    {
        string[7] memory GEAR = [
            // START FOOTWEAR
            // 0 tiny
            '%253Cg%253E%253Cpath d=\'M4,20h3v1h1v1h-4zM13,20h3v1h1v1h-4z\' fill=\'var(--dmpf1)\'/%253E%253Cpath d=\'M4,20h1v1h1v1h-2zM13,20h1v1h2v1h-3z\' fill=\'var(--dmpf2)\'/%253E%253Cpath d=\'M6,20h1v1h1v1h-1v-1h-1v1h-2v-1h2zM13,21h2v1h-2z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 1 medium
            '%253Cg%253E%253Cpath d=\'M4,19h3v2h1v1h-5v-2h1zM12,19h4v1h1v1h1v1h-6z\' fill=\'var(--dmpf1)\'/%253E%253Cpath d=\'M5,19h1v1h1v2h-2zM13,19h2v1h1v1h1v1h-2v-1h-1v-1h-1z\' fill=\'var(--dmpf2)\'/%253E%253Cpath d=\'M5,21h2v1h-2zM15,21h2v1h-2z\' fill=\'var(--dmpf3)\'/%253E%253Cpath d=\'M4,19h1v1h-1v2h-1v-2h1zM6,19h1v2h1v1h-1v-1h-1zM12,19h2v2h2v-1h-1v-1h1v1h1v1h1v1h-1v-1h-1v1h-4z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 2 medium_tongue
            '%253Cg%253E%253Cg%253E%253Cpath d=\'M6,18h3v1h-1v1h-4v-1h2zM13,18h3v2h-4v-1h1z\' fill=\'var(--dmpf1)\'/%253E%253Cpath d=\'M6,19h1v1h-1zM15,19h1v1h-1z\' fill=\'var(--dmpf2)\'/%253E%253Cpath d=\'M8,18h1v1h-1v1h-1v-1h1zM13,18h1v2h-2v-1h1zM15,18h1v2h-1zM4,19h1v1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253Cg%253E%253Cpath d=\'M3,20h4v1h1v1h-5zM12,20h6v2h-6z\' fill=\'var(--dmpf1)\'/%253E%253Cpath d=\'M5,20h2v2h-1v-1h-1zM14,20h4v1h-1v1h-1v-1h-2z\' fill=\'var(--dmpf2)\'/%253E%253Cpath d=\'M3,20h1v1h2v-1h1v1h1v1h-1v-1h-1v1h-3zM12,20h1v1h2v1h-3zM17,20h1v2h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253C/g%253E',
            // 3 lightfoot
            '%253Cg%253E%253Cpath d=\'M4,20h3v1h1v1h-5v-1h1zM12,20h5v1h1v1h-6z\' fill=\'var(--dm35)\'/%253E%253Cpath d=\'M5,20h2v2h-1v-1h-1zM14,20h3v2h-1v-1h-2z\' fill=\'var(--dm37)\'/%253E%253Cpath d=\'M6,20h1v1h1v1h-1v-1h-1v1h-3v-1h3zM12,20h1v1h2v1h-3zM16,20h1v1h1v1h-1v-1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 4 jaguarpaw
            '%253Cg%253E%253Cpath d=\'M4,19h5v1h-1v2h-5v-2h1zM12,19h4v1h1v2h-5z\' fill=\'var(--dm11)\'/%253E%253Cpath d=\'M6,19h2v1h-1v1h1v1h-3v-2h1zM13,19h2v1h1v1h1v1h-3v-2h-1z\' fill=\'var(--dm12)\'/%253E%253Cpath d=\'M4,19h1v1h-1v1h4v1h-5v-2h1zM15,19h1v1h1v2h-5v-2h1v1h3v-1h-1z\' fill=\'var(--dmb25)\'/%253E%253Cpath d=\'M6,21h1v1h-1zM8,21h1v1h-1zM15,21h1v1h-1zM17,21h1v1h-1z\' fill=\'white\'/%253E%253C/g%253E',
            // 5 phoenix
            '%253Cg%253E%253Cpath d=\'M2,19h5v2h1v1h-5v-2h-1zM10,19h6v1h1v1h1v1h-6v-1h-1v-1h-1z\' fill=\'var(--dm41)\'/%253E%253Cpath d=\'M3,19h1v1h1v-1h1v1h1v2h-2v-1h-1v-1h-1zM11,19h2v1h1v-1h1v1h1v1h1v1h-2v-2h-1v1h-2v-1h-1z\' fill=\'var(--dm11)\'/%253E%253Cpath d=\'M5,19h2v2h1v1h-1v-1h-1v-1h-1v1h1v1h-3v-1h1v-1h1zM10,19h1v1h2v1h3v-1h-2v-1h2v1h1v1h1v1h-1v-1h-1v1h-4v-1h-1v-1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 6 heavy
            '%253Cg%253E%253Cg%253E%253Cpath d=\'M6,18h3v1h-1v1h-4v-1h2zM13,18h3v1h1v1h-5v-1h1z\' fill=\'var(--dm52)\'/%253E%253Cpath d=\'M6,19h1v1h-1zM15,19h1v1h-1z\' fill=\'var(--dm49)\'/%253E%253Cpath d=\'M8,18h1v1h-1v1h-1v-1h1zM13,18h1v2h-2v-1h1zM15,18h1v2h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253Cg%253E%253Cpath d=\'M3,20h6v2h-6zM12,20h7v2h-7z\' fill=\'var(--dm52)\'/%253E%253Cpath d=\'M5,20h3v1h-1v1h-1v-1h-1zM14,20h4v1h-1v1h-1v-1h-2z\' fill=\'var(--dm49)\'/%253E%253Cpath d=\'M3,20h1v1h5v1h-6zM12,20h1v1h2v1h-3zM17,20h1v1h1v1h-2z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253C/g%253E'
            // END FOOTWEAR
        ];
        return GEAR[smAssetId];
    }

    /**
    * @notice render a cape asset
    * @param smAssetId the small asset id of the gear item
    * @return string of svg
    */
    function renderCape(uint256 smAssetId)
        external
        pure
        returns (string memory)
    {
        if(smAssetId == 1){
            return '%253Cg%253E%253Cpath d=\'M8,16h4v3h-1v1h-1v1h-1v-2h-1z\' fill=\'var(--dmpa4)\'/%253E%253Cpath d=\'M8,16h4v3h-1v1h-1v1h-1v-2h-1z\' fill=\'var(--dmb4)\'/%253E%253C/g%253E';
        } else if (smAssetId == 4){
            return '%253Cg%253E%253Cpath d=\'M8,16h4v3h-1v1h-1v1h-1v-2h-1z\' fill=\'var(--dm8)\'/%253E%253Cpath d=\'M8,16h4v3h-1v1h-1v1h-1v-2h-1z\' fill=\'var(--dmb4)\'/%253E%253C/g%253E';
        } else {
            return '%253Cg%253E%253C/g%253E';
        }
    }
}