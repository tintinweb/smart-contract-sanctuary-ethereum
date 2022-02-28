// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
LootCLassification.sol
Lootverse Utility contract to classifyitems found in Loot (For Adventurers) Bags.

See OG Loot Contract for lists of all possible items.
https://etherscan.io/address/0xff9c1b15b16263c61d017ee9f65c50e4ae0113d7

All functions are made public incase they are useful but the expected use is through the main
3 classification functions:

- getRank()
- getClass()
- getMaterial()
- getLevel()

Each of these take an item 'Type' (weapon, chest, head etc.) 
and an index into the list of all possible items of that type as found in the OG Loot contract.

The LootComponents(0x3eb43b1545a360d1D065CB7539339363dFD445F3) contract can be used to get item indexes from Loot bag tokenIDs.
The code from LootComponents is copied into this contract and rewritten for gas efficiency
So a typical use might be:

// get weapon classification for loot bag# 1234
{
    LootClassification classification = 
        LootClassification(_TBD_);

    uint256[5] memory weaponComponents = classification.weaponComponents(1234);
    uint256 index = weaponComponents[0];

    LootClassification.Type itemType = LootClassification.Type.Weapon;
    LootClassification.Class class = classification.getClass(itemType, index);
    LootClassification.Material material = classification.getMaterial(itemType, index);
    uint256 rank = classification.getRank(itemType, index);
    uint256 level = classification.getLevel(itemType, index);
}
*/
contract LootClassification
{
    enum Type
    {
        Weapon,
        Chest,
        Head,
        Waist,
        Foot,
        Hand,
        Neck,
        Ring
    }
    
    enum Material
    {
        Heavy,
        Medium,
        Dark,
        Light,
        Cloth,
        Hide,
        Metal,
        Jewellery
    }
    
    enum Class
    {
        Warrior,
        Hunter,
        Mage,
        Any
    }
    
    uint256 constant public WeaponLastHeavyIndex = 4;
    uint256 constant public WeaponLastMediumIndex = 9;
    uint256 constant public WeaponLastDarkIndex = 13;
    
    function getWeaponMaterial(uint256 index) pure public returns(Material)
    {
        if (index <= WeaponLastHeavyIndex)
            return Material.Heavy;
        
        if (index <= WeaponLastMediumIndex)
            return Material.Medium;
        
        if (index <= WeaponLastDarkIndex)
            return Material.Dark;
        
        return Material.Light;
    }
    
    function getWeaponRank(uint256 index) pure public returns (uint256)
    {
        if (index <= WeaponLastHeavyIndex)
            return index + 1;
        
        if (index <= WeaponLastMediumIndex)
            return index - 4;
        
        if (index <= WeaponLastDarkIndex)
            return index - 9;
        
        return index -13;
    }
    
    uint256 constant public ChestLastClothIndex = 4;
    uint256 constant public ChestLastLeatherIndex = 9;
    
    function getChestMaterial(uint256 index) pure public returns(Material)
    {
        if (index <= ChestLastClothIndex)
            return Material.Cloth;
        
        if (index <= ChestLastLeatherIndex)
            return Material.Hide;
        
        return Material.Metal;
    }
    
    function getChestRank(uint256 index) pure public returns (uint256)
    {
        if (index <= ChestLastClothIndex)
            return index + 1;
        
        if (index <= ChestLastLeatherIndex)
            return index - 4;
        
        return index - 9;
    }
    
    // Head, waist, foot and hand items all follow the same classification pattern,
    // so they are generalised as armour.
    uint256 constant public ArmourLastMetalIndex = 4;
    uint256 constant public ArmourLasLeatherIndex = 9;
    
    function getArmourMaterial(uint256 index) pure public returns(Material)
    {
        if (index <= ArmourLastMetalIndex)
            return Material.Metal;
        
        if (index <= ArmourLasLeatherIndex)
            return Material.Hide;
        
        return Material.Cloth;
    }
    
    function getArmourRank(uint256 index) pure public returns (uint256)
    {
        if (index <= ArmourLastMetalIndex)
            return index + 1;
        
        if (index <= ArmourLasLeatherIndex)
            return index - 4;
        
        return index - 9;
    }
    
    function getRingRank(uint256 index) pure public returns (uint256)
    {
        if (index > 2)
            return 1;
        else 
            return index + 1;
    }
    
    function getNeckRank(uint256 index) pure public returns (uint256)
    {
        return 1;
    }
    
    function getMaterial(Type lootType, uint256 index) pure public returns (Material)
    {
         if (lootType == Type.Weapon)
            return getWeaponMaterial(index);
            
        if (lootType == Type.Chest)
            return getChestMaterial(index);
            
        if (lootType == Type.Head ||
            lootType == Type.Waist ||
            lootType == Type.Foot ||
            lootType == Type.Hand)
        {
            return getArmourMaterial(index);
        }
            
        return Material.Jewellery;
    }
    
    function getClass(Type lootType, uint256 index) pure public returns (Class)
    {
        Material material = getMaterial(lootType, index);
        return getClassFromMaterial(material);
    }

    function getClassFromMaterial(Material material) pure public returns (Class)
    {   
        if (material == Material.Heavy || material == Material.Metal)
            return Class.Warrior;
            
        if (material == Material.Medium || material == Material.Hide)
            return Class.Hunter;
            
        if (material == Material.Dark || material == Material.Light || material == Material.Cloth)
            return Class.Mage;
            
        return Class.Any;
        
    }
    
    function getRank(Type lootType, uint256 index) pure public returns (uint256)
    {
        if (lootType == Type.Weapon)
            return getWeaponRank(index);
            
        if (lootType == Type.Chest)
            return getChestRank(index);
        
        if (lootType == Type.Head ||
            lootType == Type.Waist ||
            lootType == Type.Foot ||
            lootType == Type.Hand)
        {
            return getArmourRank(index);
        }
        
        if (lootType == Type.Ring)
            return getRingRank(index);
            
        return getNeckRank(index);  
    }

    function getLevel(Type lootType, uint256 index) pure public returns (uint256)
    {
        if (lootType == Type.Chest ||
            lootType == Type.Weapon ||
            lootType == Type.Head ||
            lootType == Type.Waist ||
            lootType == Type.Foot ||
            lootType == Type.Hand)
        {
            return 6 - getRank(lootType, index);
        } else {
            return 4 - getRank(lootType, index); 
        }
    }

    ///////////////////////////////////////////////////////////////////////////
    /*
    Gas efficient implementation of LootComponents
    https://etherscan.io/address/0x3eb43b1545a360d1D065CB7539339363dFD445F3#code
    The actual names are not needed when retreiving the component indexes only
    Header comment from orignal follows:

    // SPDX-License-Identifier: Unlicense
    
    This is a utility contract to make it easier for other
    contracts to work with Loot properties.
    
    Call weaponComponents(), chestComponents(), etc. to get 
    an array of attributes that correspond to the item. 
    
    The return format is:
    
    uint256[6] =>
        [0] = Item ID
        [1] = Suffix ID (0 for none)
        [2] = Name Prefix ID (0 for none)
        [3] = Name Suffix ID (0 for none)
        [4] = Augmentation (0 = false, 1 = true)
        [5] = Greatness
    
    See the item and attribute tables below for corresponding IDs.
    */

    uint256 constant WEAPON_COUNT = 18;
    uint256 constant CHEST_COUNT = 15;
    uint256 constant HEAD_COUNT = 15;
    uint256 constant WAIST_COUNT = 15;
    uint256 constant FOOT_COUNT = 15;
    uint256 constant HAND_COUNT = 15;
    uint256 constant NECK_COUNT = 3;
    uint256 constant RING_COUNT = 5;
    uint256 constant SUFFIX_COUNT = 16;
    uint256 constant NAME_PREFIX_COUNT = 69;
    uint256 constant NAME_SUFFIX_COUNT = 18;

    function random(string memory input) internal pure returns (uint256) 
    {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function weaponComponents(uint256 tokenId) public pure returns (uint256[6] memory) 
    {
        return tokenComponents(tokenId, "WEAPON", WEAPON_COUNT);
    }
    
    function chestComponents(uint256 tokenId) public pure returns (uint256[6] memory) 
    {
        return tokenComponents(tokenId, "CHEST", CHEST_COUNT);
    }
    
    function headComponents(uint256 tokenId) public pure returns (uint256[6] memory) 
    {
        return tokenComponents(tokenId, "HEAD", HEAD_COUNT);
    }
    
    function waistComponents(uint256 tokenId) public pure returns (uint256[6] memory) 
    {
        return tokenComponents(tokenId, "WAIST", WAIST_COUNT);
    }

    function footComponents(uint256 tokenId) public pure returns (uint256[6] memory) 
    {
        return tokenComponents(tokenId, "FOOT", FOOT_COUNT);
    }
    
    function handComponents(uint256 tokenId) public pure returns (uint256[6] memory) 
    {
        return tokenComponents(tokenId, "HAND", HAND_COUNT);
    }
    
    function neckComponents(uint256 tokenId) public pure returns (uint256[6] memory) 
    {
        return tokenComponents(tokenId, "NECK", NECK_COUNT);
    }
    
    function ringComponents(uint256 tokenId) public pure returns (uint256[6] memory) 
    {
        return tokenComponents(tokenId, "RING", RING_COUNT);
    }

    function tokenComponents(uint256 tokenId, string memory keyPrefix, uint256 itemCount) 
        internal pure returns (uint256[6] memory) 
    {
        uint256[6] memory components;
        
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        
        components[0] = rand % itemCount;
        components[1] = 0;
        components[2] = 0;
        
        components[5] = rand % 21; //aka greatness
        if (components[5] > 14) {
            components[1] = (rand % SUFFIX_COUNT) + 1;
        }
        if (components[5] >= 19) {
            components[2] = (rand % NAME_PREFIX_COUNT) + 1;
            components[3] = (rand % NAME_SUFFIX_COUNT) + 1;
            if (components[5] == 19) {
                // ...
            } else {
                components[4] = 1;
            }
        }
        return components;
    }

    function toString(uint256 value) internal pure returns (string memory) 
    {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}