// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Strings.sol";
import "../Structs/Attempt.sol";
import "../Structs/Miner.sol";
import "../Structs/PackedVars.sol";
import "./AssetRenderer1.sol";
import "./AssetRenderer2.sol";
import "./AssetRenderer3.sol";
import "./AssetRenderer4.sol";
import "./AssetRenderer5.sol";
import "./Calcs.sol";
import "./LgSVG.sol";
import "./SmSVG.sol";

library Metadata {
    using Strings for *;

    /**
    * @notice build metadata strings for a miner
    * @param attempt the attempt struct for this miner
    * @param minerIn the miner struct to ingest
    * @param chambers an array of chamber hashes
    * @return array of strings (first json metadata, second image data)
    */
    function build(Attempt memory attempt, Miner memory minerIn, bytes32[47] memory chambers)
        external
        pure
        returns(string memory,string memory)
    {
        // Define a PackedVars struct to efficiently assign/reassign values during calculation
        PackedVars memory packedData;

        // Check if an attempt has started yet
        if(attempt.startTokenId == 0){
            // Attempt has not started - generate miner
            (Miner memory miner, string memory metaAttributes) = _initCodeGen(
                minerIn,
                packedData
            );

            // Set svgBody to large miner render
            string memory svgBody = _lgRender(miner);

            // Return the metadata and image data
            return (
                metaAttributes,
                LgSVG.render(
                    Calcs.ctString(attempt.hash),
                    svgBody,
                    1,
                    7
                )
            );
        } else {
            (Miner memory miner, string memory svgBody, string memory metaAttributes) = _codeGen(
                minerIn,
                chambers,
                packedData
            );

            if(miner.health <= 0 || miner.currentChamber == 46){
                // Miner is dead or won!

                // Set svgBody to large miner render
                svgBody = _lgRender(miner);
                if(miner.currentChamber == 46){
                    // Winner winner, chicken dinner!

                    // Set background value to 2
                    packedData.var_uint8_2 = 2;

                    // Set frame value to 6
                    packedData.var_uint8_1 = 6;
                } else {
                    // Miner es muerto;

                    // Set frame value to current floor
                    packedData.var_uint8_1 = (miner.currentChamber / 8);
                }
                // Return the metadata and image data
                return (
                    metaAttributes,
                    LgSVG.render(
                        Calcs.ctString(attempt.hash),
                        svgBody,
                        packedData.var_uint8_2,
                        packedData.var_uint8_1
                    )
                );
            } else {
                // Miner is alive!
                // Define string var for bottom stats attributes based on attempt stats
                string memory minerStats;

                // Loop through all gear types to generate style tags for miner
                for(packedData.var_uint8_1 = 0; packedData.var_uint8_1 < 5; packedData.var_uint8_1++){
                    // Generate and append color defs to the minerStats var
                    if(packedData.var_uint8_1 == 0){
                        minerStats = string(abi.encodePacked(
                            minerStats,
                            AssetRenderer1.cssSkinVar(miner.skintoneId)
                        ));
                    } else if(packedData.var_uint8_1 == 1){
                        minerStats = string(abi.encodePacked(
                            minerStats,
                            // AssetRenderer1.cssVar(GEAR[miner.armorId])
                            AssetRenderer1.cssVar(miner.armorId)
                        ));
                    } else if(packedData.var_uint8_1 == 2){
                        minerStats = string(abi.encodePacked(
                            minerStats,
                            // AssetRenderer1.cssVar(GEAR[miner.pantsId])
                            AssetRenderer1.cssVar(miner.pantsId)
                        ));
                    } else if(packedData.var_uint8_1 == 3){
                        minerStats = string(abi.encodePacked(
                            minerStats,
                            // AssetRenderer1.cssVar(GEAR[miner.footwearId])
                            AssetRenderer1.cssVar(miner.footwearId)
                        ));
                    } else if(packedData.var_uint8_1 == 4){
                        minerStats = string(abi.encodePacked(
                            minerStats,
                            // AssetRenderer1.cssVar(GEAR[miner.weaponId])
                            AssetRenderer1.cssVar(miner.weaponId)
                        ));
                    }
                }
                for(packedData.var_uint8_2 = 0; packedData.var_uint8_2 < 7; packedData.var_uint8_2++){
                    // Generate and append avatar image data to the minerStats var
                    if(packedData.var_uint8_2 == 0){
                        minerStats = string(abi.encodePacked(
                            minerStats,
                            AssetRenderer4.renderCape(uint16(Calcs.armorStats(miner.armorId)[4]))
                        ));
                    } else if(packedData.var_uint8_2 == 1){
                        minerStats = string(abi.encodePacked(
                            minerStats,
                            AssetRenderer4.renderPants(uint16(Calcs.pantsStats(miner.pantsId)[4]))
                        ));
                    } else if(packedData.var_uint8_2 == 2){
                        minerStats = string(abi.encodePacked(
                            minerStats,
                            AssetRenderer4.renderFootwear(uint16(Calcs.footwearStats(miner.footwearId)[4]))
                        ));
                    } else if(packedData.var_uint8_2 == 3){
                        minerStats = string(abi.encodePacked(
                            minerStats,
                            AssetRenderer4.renderArmor(uint16(Calcs.armorStats(miner.armorId)[4]))
                        ));
                    } else if(packedData.var_uint8_2 == 4){
                        minerStats = string(abi.encodePacked(
                            minerStats,
                            '%253Cg fill=\'var(--dms)\'%253E%253Cpath d=\'M8,4h5v5h-5z\'/%253E%253Cpath d=\'M4,14h3v3h-3zM16,14h3v3h-3z\'/%253E%253C/g%253E'
                        ));
                    } else if(packedData.var_uint8_2 == 5){
                        minerStats = string(abi.encodePacked(
                            minerStats,
                            AssetRenderer4.renderHeadgear(uint16(Calcs.headgearStats(miner.headgearId)[4]))
                        ));
                    } else if(packedData.var_uint8_2 == 6){
                        minerStats = string(abi.encodePacked(
                            minerStats,
                            AssetRenderer1.weapon(uint16(Calcs.weaponStats(miner.weaponId)[4])),
                            '%253C/g%253E'
                        ));
                    }
                }

                // Loop through all miner stats to generate image data for bottom stats bar
                for(packedData.var_uint8_3 = 0; packedData.var_uint8_3 < 6; packedData.var_uint8_3++){
                    // Generate and append miner stats image data to the minerStats var
                    minerStats = string(abi.encodePacked(
                        minerStats,
                        AssetRenderer1.smMinerStat(packedData.var_uint8_3,miner)
                    ));
                }

                // Return the metadata and image data
                return (
                    metaAttributes,
                    SmSVG.render(
                        svgBody,
                        minerStats
                    )
                );
            }
        }
    }

    /**
    * @notice render a miner portrait
    * @param miner the miner struct
    * @return string of miner portrait image data
    */
    function _lgRender(Miner memory miner)
        internal
        pure
        returns(string memory)
    {
        PackedVars memory packedData;
        string memory svgBody;

        // Loop through all gear types to generate style tags for miner
        for(packedData.var_uint8_1 = 0; packedData.var_uint8_1 < 11; packedData.var_uint8_1++){
            // Generate and append color defs to the svgBody var
            if(packedData.var_uint8_1 == 0){
                svgBody = string(abi.encodePacked(
                    svgBody,
                    AssetRenderer1.cssSkinVar(miner.skintoneId)
                ));
            } else if(packedData.var_uint8_1 == 1){
                svgBody = string(abi.encodePacked(
                    svgBody,
                    AssetRenderer1.cssHairVar(miner.hairColorId)
                ));
            } else if(packedData.var_uint8_1 == 2){
                svgBody = string(abi.encodePacked(
                    svgBody,
                    AssetRenderer1.cssEyeVar(miner.eyeColorId)
                ));
            } else if(packedData.var_uint8_1 == 3){
                svgBody = string(abi.encodePacked(
                    svgBody,
                    LgSVG.renderBase(miner.genderId,miner.classId,miner.eyeTypeId,miner.mouthId)
                ));
            } else if(packedData.var_uint8_1 == 4){
                svgBody = string(abi.encodePacked(
                    svgBody,
                    AssetRenderer3.renderArmor(uint16(Calcs.armorStats(miner.armorId)[5]))
                ));
            } else if(packedData.var_uint8_1 == 5){
                svgBody = string(abi.encodePacked(
                    svgBody,
                    AssetRenderer2.renderHairDefs(uint16(Calcs.headgearStats(miner.headgearId)[5]),miner.hairTypeId,miner.genderId)
                ));
            } else if(packedData.var_uint8_1 == 6){
                svgBody = string(abi.encodePacked(
                    svgBody,
                    // AssetRenderer3.renderHair(miner.hairTypeId,GEAR[miner.headgearId].lgAssetId)
                    AssetRenderer3.renderHair(miner.hairTypeId,uint16(Calcs.headgearStats(miner.headgearId)[5]))
                ));
            } else if(packedData.var_uint8_1 == 7){
                svgBody = string(abi.encodePacked(
                    svgBody,
                    LgSVG.renderMod((miner.genderId * 4) + miner.classId)
                ));
            } else if(packedData.var_uint8_1 == 8){
                svgBody = string(abi.encodePacked(
                    svgBody,
                    // AssetRenderer2.renderHeadgear(GEAR[miner.headgearId].lgAssetId,miner.genderId)
                    AssetRenderer2.renderHeadgear(uint16(Calcs.headgearStats(miner.headgearId)[5]),miner.genderId)
                ));
            } else if(packedData.var_uint8_1 == 9 && miner.classId == 2){
                svgBody = string(abi.encodePacked(
                    svgBody,
                    AssetRenderer2.renderEarMod(miner.headgearId)
                ));
            } else if(packedData.var_uint8_1 == 10){
                svgBody = string(abi.encodePacked(
                    svgBody,
                    AssetRenderer5.renderWeapon(uint16(Calcs.weaponStats(miner.weaponId)[5]))
                ));
            }
        }
        return svgBody;
    }

    /**
    * @notice return the name of a gear item
    * @param gearId the gear id of the gear item
    * @return string of quotation mark-wrapped gear item
    */
    function _gearName(uint8 gearId)
        internal
        pure
        returns(string memory)
    {
        if(gearId < 17){
            // Headgear
            return ['"None"','"Bandana"','"Leather Hat"','"Rusty Helm"','"Feathered Cap"','"Enchanted Crown"','"Bronze Helm"','"Assassin\'s Mask"','"Iron Helm"','"Skull Helm"','"Charmed Headband"','"Ranger Cap"','"Misty Hood"','"Phoenix Helm"','"Ancient Mask"','"Genesis Helm"','"Soul Shroud"'][gearId];
        } else if(gearId < 34){
            // Armor - 17
            return ['"Cotton Shirt"','"Thick Vest"','"Leather Chestplate"','"Rusty Chainmail"','"Longcoat"','"Chainmail"','"Bronze Chestplate"','"Blessed Armor"','"Iron Chestplate"','"Skull Armor"','"Cape of Deception"','"Mystic Cloak"','"Shimmering Cloak"','"Phoenix Chestplate"','"Ancient Robe"','"Genesis Cloak"','"Soul Cloak"'][gearId - 17];
        } else if(gearId < 51){
            // Pants - 34
            return ['"Cotton Pants"','"Thick Pants"','"Leather Greaves"','"Rusty Chainmail Pants"','"Reliable Leggings"','"Padded Leggings"','"Bronze Greaves"','"Enchanted Pants"','"Iron Greaves"','"Skull Greaves"','"Swift Leggings"','"Forest Greaves"','"Silent Leggings"','"Phoenix Greaves"','"Ancient Greaves"','"Genesis Greaves"','"Soul Greaves"'][gearId - 34];
        } else if(gearId < 68){
            // Footwear - 51
            return ['"None"','"Sturdy Cleats"','"Leather Boots"','"Rusty Boots"','"Lightweight Shoes"','"Bandit\'s Shoes"','"Bronze Boots"','"Heavy Boots"','"Iron Boots"','"Skull Boots"','"Enchanted Boots"','"Jaguarpaw Boots"','"Lightfoot Boots"','"Phoenix Boots"','"Ancient Boots"','"Genesis Boots"','"Soul Boots"'][gearId - 51];
        } else {
            // Weapons - 68
            return ['"Fists"','"Rusty Sword"','"Wooden Club"','"Pickaxe"','"Brass Knuckles"','"Weathered Greataxe"','"Polished Scepter"','"Poisoned Spear"','"Kusarigama"','"Bronze Sword"','"Bronze Staff"','"Bronze Shortsword"','"Bronze Daggers"','"Dusty Scmitar"','"Silver Wand"','"Dual Handaxes"','"Dual Shortswords"','"Holy Sword"','"Holy Staff"','"Holy Bow"','"Holy Daggers"','"Soulcutter"','"Shadow Staff"','"Shadow Bow"','"Shadowblades"','"Phoenix Blade"','"Ancient Scepter"','"Genesis Bow"','"Soul Daggers"'][gearId - 68];
        }
    }

    /**
    * @notice calculate the result of an escape attempt and return miner, metadata and image data
    * @param minerIn the miner struct to ingest
    * @param chambers an array of chamber hashes
    * @param packedData a packed struct of variables
    * @return array of miner struct, metadata string and image data string
    */
    function _codeGen(Miner memory minerIn, bytes32[47] memory chambers, PackedVars memory packedData)
        internal
        pure
        returns (Miner memory, string memory, string memory)
    {
        // Define string var for all chambers image data starting with the initial chamber
        Miner memory miner = minerIn;

        // Define string var for all chambers image data starting with the initial chamber
        string memory svgBody = string(abi.encodePacked(
            AssetRenderer1.smChamber(
                'a',
                Calcs.ctString(chambers[0]),
                'x',
                0
            )
        ));

        // Loop through all chambers and calculate attempt data
        for(packedData.var_uint8_1 = 1; packedData.var_uint8_1 < 47; packedData.var_uint8_1++){
            // Check if the miner is alive
            if(miner.health > 0){
                // The miner lives! Do chambery shit

                // Check if the current chamber has been mined yet
                if(chambers[packedData.var_uint8_1] != bytes32(0)){
                    // This chamber has been mined! Do more chambery shit

                    // Set the current chamber to current loop value
                    miner.currentChamber = packedData.var_uint8_1;

                    // Calculate and return the miner and stats after traversing this chamber
                    miner = Calcs.chamberStats(keccak256(abi.encodePacked(chambers[0],chambers[packedData.var_uint8_1])),miner);

                    // Generate and append chamber image data to the svgBody var
                    svgBody = string(abi.encodePacked(
                        svgBody,
                        AssetRenderer1.smChamber(
                            'a',
                            Calcs.ctString(chambers[packedData.var_uint8_1]),
                            Calcs.etString(keccak256(abi.encodePacked(chambers[0],chambers[packedData.var_uint8_1]))),
                            packedData.var_uint8_1
                        )
                    ));
                } else {
                    // This chamber hasn't been mined yet

                    // Generate and append pending chamber image data to the svgBody var
                    svgBody = string(abi.encodePacked(
                        svgBody,
                        chambers[packedData.var_uint8_1 - 1] != bytes32(0) ? AssetRenderer1.smNext(packedData.var_uint8_1) : '',
                        AssetRenderer1.smChamber('u','x','x',packedData.var_uint8_1)
                    ));
                }
            } else {
                // Break the loop
                break;
            }
        }

        // Append status elements to the svgBody var
        svgBody = string(abi.encodePacked(
            svgBody,
            '%253Cg class=\'se\' transform=\'translate(4,88)\'%253E'
        ));
        if(miner.buffTurns > 0){
            // Add buff indicator
            svgBody = string(abi.encodePacked(
                svgBody,
                '%253Cpath d=\'M10,10h2v2h-2z\' fill=\'var(--dm18)\'/%253E'
            ));
        }
        if(miner.debuffTurns > 0){
            // Add buff indicator
            svgBody = string(abi.encodePacked(
                svgBody,
                '%253Cpath d=\'M10,10h2v2h-2z\' fill=\'var(--dm6)\'/%253E'
            ));
        }
        if(miner.curseTurns > 0){
            // Add buff indicator
            svgBody = string(abi.encodePacked(
                svgBody,
                '%253Cpath d=\'M10,10h2v2h-2z\' fill=\'var(--dm3)\'/%253E'
            ));
        }
        svgBody = string(abi.encodePacked(
            svgBody,
            '%253C/g%253E'
        ));

        // Define string var for JSON attributes based on attempt stats
        string memory metaAttributes;

        // Check if miner is still alive after all chambers have been calculated
        if(miner.health > 0){
            // Still alive!

            // Check if the miner has reached the exit
            if(miner.currentChamber == 46){
                // Winner winner, chicken dinner!
                metaAttributes = '{"trait_type":"Miner Status","value":"Escaped"}';

            } else {
                // Attempt is in progress

                metaAttributes = '{"trait_type":"Miner Status","value":"Exploring"}';

                // Generate and append exit image data to the svgBody var
                svgBody = string(abi.encodePacked(
                    svgBody,
                    AssetRenderer1.smExit()
                ));
            }
        } else {
            metaAttributes = '{"trait_type":"Miner Status","value":"Dead"}';
        }

        // Loop through all miner attributes to be calculated for metadata
        for(packedData.var_uint8_1 = 0; packedData.var_uint8_1 < 21; packedData.var_uint8_1++){
            // Generate and append miner attribute data to the metaAttributes var
            metaAttributes = string(abi.encodePacked(
                metaAttributes,
                _minerAttribute(packedData.var_uint8_1,miner)
            ));
        }

        // Return miner, svg body and metadata
        return (miner, svgBody, metaAttributes);
    }

    /**
    * @notice calculate the initial status of an escape attempt and return miner and metadata
    * @param miner the miner struct
    * @param packedData a packed struct of variables
    * @return array of miner struct and metadata string
    */
    function _initCodeGen(Miner memory miner, PackedVars memory packedData)
        internal
        pure
        returns (Miner memory, string memory)
    {

        // Define string var for JSON attributes based on attempt stats
        string memory metaAttributes = '{"trait_type":"Miner Status","value":"In Village"}';

        // Loop through all miner attributes to be calculated for metadata
        for(packedData.var_uint8_2 = 0; packedData.var_uint8_2 < 19; packedData.var_uint8_2++){
            // Generate and append miner attribute data to the metaAttributes var
            metaAttributes = string(abi.encodePacked(
                metaAttributes,
                _minerAttribute(packedData.var_uint8_2,miner)
            ));
        }

        // Append blank values to end of metaAttributes
        metaAttributes = string(abi.encodePacked(
            metaAttributes,
            ',{"trait_type":"Chambers Cleared","value":0},{"trait_type":"Gold","value":0}'
        ));

        // Return miner and metadata
        return (miner,metaAttributes);
    }

    /**
    * @notice render the attributes for json metadata
    * @param index name of stat
    * @param miner number of string
    * @return string of a single attribute key/value pair in json object key/value format
    */
    function _minerAttribute(uint256 index, Miner memory miner)
        internal
        pure
        returns (string memory)
    {
        string memory stat;
        string memory value;

        if(index == 0){
            stat = 'Class';
            if(miner.classId == 0){
                value = '"Warrior"';
            } else if(miner.classId == 1){
                value = '"Mage"';
            } else if(miner.classId == 2){
                value = '"Ranger"';
            } else {
                value = '"Assassin"';
            }
        } else if(index == 1){
            stat = 'Gender';
            value = miner.genderId == 0 ? '"Male"' : '"Female"';
        } else if(index == 2){
            stat = 'HP';
            value = (miner.health < 0 ? 0 : uint16(miner.health)).toString();
        } else if(index == 3){
            stat = 'AP';
            value = (miner.armor < 0 ? 0 : uint16(miner.armor)).toString();
        } else if(index == 4){
            stat = 'Base HP';
            value = (miner.baseHealth < 0 ? 0 : uint16(miner.baseHealth)).toString();
        } else if(index == 5){
            stat = 'Base AP';
            value = (miner.baseArmor < 0 ? 0 : uint16(miner.baseArmor)).toString();
        } else if(index == 6){
            stat = 'Base ATK';
            value = (miner.attack < 0 ? 0 : uint16(miner.attack)).toString();
        } else if(index == 7){
            stat = 'Base SPD';
            value = (miner.speed < 0 ? 0 : uint16(miner.speed)).toString();
        } else if(index == 8){
            stat = 'Headgear';
            value = _gearName(miner.headgearId);
        } else if(index == 9){
            stat = 'Armor';
            value = _gearName(miner.armorId);
        } else if(index == 10){
            stat = 'Pants';
            value = _gearName(miner.pantsId);
        } else if(index == 11){
            stat = 'Footwear';
            value = _gearName(miner.footwearId);
        } else if(index == 12){
            stat = 'Weapon';
            value = _gearName(miner.weaponId);
        } else if(index == 13){
            stat = 'Skin Tone';
            value = AssetRenderer2.skintoneName(miner.skintoneId);
        } else if(index == 14){
            stat = 'Hair Type';
            value = AssetRenderer2.hairTypeName(miner.hairTypeId);
        } else if(index == 15){
            stat = 'Hair Color';
            value = AssetRenderer2.hairColorName(miner.hairColorId);
        } else if(index == 16){
            stat = 'Eye Type';
            value = AssetRenderer2.eyeTypeName(miner.eyeTypeId);
        } else if(index == 17){
            stat = 'Eye Color';
            value = AssetRenderer2.eyeColorName(miner.eyeColorId);
        } else if(index == 18){
            stat = 'Mouth Type';
            value = AssetRenderer2.mouthTypeName(miner.mouthId);
        } else if(index == 19){
            stat = 'Gold';
            value = miner.gold.toString();
        } else if(index == 20){
            stat = 'Chambers Cleared';
            value = miner.currentChamber.toString();
        }
        return string(abi.encodePacked(
            ',{"trait_type":"',
            stat,
            '","value":',
            value,
            '}'
        ));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

struct Attempt {
    bytes32 hash;
    uint256 startTokenId;
    uint8 genderId;
    uint8 classId;
    uint8 itemId;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

struct Miner {
    int16 baseHealth;
    int16 baseArmor;
    int16 health;
    int16 armor;
    int16 attack;
    int16 speed;
    uint16 gold;
    uint8 genderId;
    uint8 classId;
    uint8 skintoneId;
    uint8 hairColorId;
    uint8 hairTypeId;
    uint8 eyeColorId;
    uint8 eyeTypeId;
    uint8 mouthId;
    uint8 headgearId;
    uint8 armorId;
    uint8 pantsId;
    uint8 footwearId;
    uint8 weaponId;
    uint8 curseTurns;
    uint8 buffTurns;
    uint8 debuffTurns;
    uint8 revives;
    uint8 currentChamber;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

struct PackedVars {
    int8 var_int8_1;
    int8 var_int8_2;
    int8 var_int8_3;
    int8 var_int8_4;
    int8 var_int8_5;
    int8 var_int8_6;
    uint8 var_uint8_1;
    uint8 var_uint8_2;
    uint8 var_uint8_3;
    uint8 var_uint8_4;
    uint8 var_uint8_5;
    uint8 var_uint8_6;
    int16 var_int16_1;
    int16 var_int16_2;
    int16 var_int16_3;
    int16 var_int16_4;
    uint16 var_uint16_1;
    uint16 var_uint16_2;
    uint16 var_uint16_3;
    uint16 var_uint16_4;
    uint32 var_uint32_1;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Strings.sol";
import "../Structs/Miner.sol";

library AssetRenderer1 {
    using Strings for *;

    /**
    * @notice generate CSS color variables
    * @param colorId color id of skintone
    * @return string of css
    */
    function cssSkinVar(uint256 colorId)
        external
        pure
        returns (string memory)
    {
        // Array of potential color values
        string[16] memory COLORS = [
            'var(--dm59)',  // 0  | porcelain
            'var(--dm58)',  // 1  | creme
            'var(--dm57)',  // 2  | sienna
            'var(--dm56)',  // 3  | sand
            'var(--dm55)',  // 4  | beige
            'var(--dm54)',  // 5  | honey
            'var(--dm53)',  // 6  | almond
            'var(--dm52)',  // 7  | bronze
            'var(--dm51)',  // 8  | espresso
            'var(--dm50)',  // 9  | ebony
            'var(--dm5)',   // 10 | demon
            'var(--dm17)',  // 11 | orc
            'var(--dm26)',  // 12 | djinn
            'var(--dm39)',  // 13 | spectre
            'var(--dm2)',   // 14 | mystic
            'var(--dm34)'   // 15 | golem
        ];
        return string(abi.encodePacked(
            '%253Cstyle%253E:root{--dms:',
            COLORS[colorId],
            ';'
        ));
    }

    /**
    * @notice generate CSS color variables
    * @param colorId color id of hair color
    * @return string of css
    */
    function cssHairVar(uint256 colorId)
        external
        pure
        returns (string memory)
    {
        // Array of potential color values
        string[8] memory COLORS = [
            'var(--dm48)',  // 0 | light brown
            'var(--dm46)',  // 1 | dark brown
            'var(--dm41)',  // 2 | dirty blonde
            'var(--dm13)',  // 3 | blonde
            'var(--dm36)',  // 4 | gray
            'var(--dm43)',  // 5 | dark brownish/gray
            'var(--dm24)',  // 6 | black
            'var(--dm11)'   // 7 | orange/red

        ];
        return string(abi.encodePacked(
            '--dmh:',
            COLORS[colorId],
            ';'
        ));
    }

    /**
    * @notice generate CSS color variables
    * @param colorId color id of eye color
    * @return string of css
    */
    function cssEyeVar(uint256 colorId)
        external
        pure
        returns (string memory)
    {
        // Array of potential color values
        string[13] memory COLORS = [
            'black',        // 0  | black
            'var(--dm29)',  // 1  | gray
            'var(--dm20)',  // 2  | light green
            'var(--dm17)',  // 3  | green
            'var(--dm41)',  // 4  | amber
            'var(--dm45)',  // 5  | light brown
            'var(--dm47)',  // 6  | brown
            'var(--dm28)',  // 7  | light blue
            'var(--dm26)',  // 8  | blue
            'var(--dm11)',  // 9  | orange
            'var(--dm2)',   // 10 | purple
            'var(--dm5)',   // 11 | red
            'transparent'   // 12 | none
        ];
        return string(abi.encodePacked(
            '--dmi:',
            COLORS[colorId],
            '}%253C/style%253E'
        ));
    }

    /**
    * @notice generate CSS color variables for gear items
    * @param gearId gear id of gear item
    * @return string of css
    */
    function cssVar(uint256 gearId)
        external
        pure
        returns (string memory)
    {
        // Array of potential color values
        string[46] memory COLORS = [
            'var(--dm14)',      // 0  | BRIGHT YELLOW
            'var(--dm42)',      // 1  | LIGHT DULL YELLOW
            'var(--dm44)',      // 2  | DULL BROWN
            'var(--dm48)',      // 3  | BRIGHT BROWN
            'var(--dm43)',      // 4  | DARK DULL BROWN
            'var(--dm37)',      // 5  | GRAY
            'var(--dm36)',      // 6  | DARK GRAY
            'var(--dm38)',      // 7  | LIGHT GRAY
            'var(--dm41)',      // 8  | DARK ORANGE
            'var(--dm11)',      // 9  | ORANGE
            'var(--dm12)',      // 10 | BRIGHT YELLOW
            'var(--dm2)',       // 11 | BRIGHT PURPLE & skintone 14
            'var(--dm17)',      // 12 | GREEN && skintone 12
            'var(--dm46)',      // 13 | DARK BROWN
            'var(--dm49)',      // 14 | MID BRIGHT BROWN
            'var(--dm32)',      // 15 | LIGHT BLUE
            'var(--dm10)',      // 16 | LIGHT PINK
            'white',            // 17 | WHITE
            'var(--dm15)',      // 18 | LIGHT YELLOW
            'var(--dm35)',      // 19 | DARK GRAY
            'var(--dm37)',      // 20 | MID GRAY
            'var(--dm1)',       // 21 | DARK PURPLE
            'var(--dm25)',      // 22 | DARK BLUE
            'var(--dm26)',      // 23 | LIGHT BLUE
            'var(--dm19)',      // 24 | LIGHT GREEN
            'var(--dm52)',      // 25 | DARK BROWN & skintone 8
            'var(--dm21)',      // 26 | SLIME GREEN
            'var(--dm20)',      // 27 | LIGHT GREEN
            'var(--dm59)',      // 28 | skintone 1
            'var(--dm58)',      // 29 | skintone 2
            'var(--dm57)',      // 30 | skintone 3
            'var(--dm56)',      // 31 | skintone 4
            'var(--dm55)',      // 32 | skintone 5
            'var(--dm54)',      // 33 | skintone 6
            'var(--dm53)',      // 34 | skintone 7
            'var(--dm51)',      // 35 | skintone 9
            'var(--dm50)',      // 36 | skintone 10
            'var(--dm5)',       // 37 | skintone 11
            'var(--dm26)',      // 38 | skintone 13
            'var(--dm39)',      // 39 | skintone 14
            'var(--dm2)',       // 40 | skintone 15
            'url(%2523ch)',     // 41 | chain
            'url(%2523ch2)',    // 42 | chain2
            'url(%2523ch3)',    // 43 | chain3
            'var(--dms)',       // 44 | skintone
            'transparent'       // 45 | transparent
        ];
        if(gearId < 17){
            return '';
        } else if(gearId < 34){
            uint8[4] memory gear = [
                [0,1,0,45],
                [2,1,0,45],
                [3,1,0,45],
                [8,1,0,43],
                [2,4,2,45],
                [7,5,7,42],
                [8,5,7,9],
                [9,5,10,10],
                [5,5,7,7],
                [7,7,17,6],
                [3,3,3,11],
                [3,3,3,12],
                [6,7,17,9],
                [8,5,9,9],
                [3,3,8,8],
                [3,3,13,14],
                [15,15,16,16]
            ][gearId - 17];
            return string(abi.encodePacked(
                '--dmpa1:',
                COLORS[gear[0]],
                ';--dmpa2:',
                COLORS[gear[1]],
                ';--dmpa3:',
                COLORS[gear[2]],
                ';--dmpa4:',
                COLORS[gear[3]],
                ';'
            ));
        } else if(gearId < 51){
            uint8[3] memory gear = [
                [0,18,45],
                [4,2,45],
                [2,3,45],
                [3,3,41],
                [19,20,45],
                [2,18,45],
                [2,8,9],
                [21,11,45],
                [2,5,7],
                [2,17,45],
                [22,23,45],
                [2,24,45],
                [20,19,45],
                [8,9,45],
                [2,8,3],
                [35,14,45],
                [15,16,45]
            ][gearId - 34];
            return string(abi.encodePacked(
                '--dmpp1:',
                COLORS[gear[0]],
                ';--dmpp2:',
                COLORS[gear[1]],
                ';--dmpp3:',
                COLORS[gear[2]],
                ';'
            ));
        } else if(gearId < 68){
            uint8[3] memory gear = [
                [44,45,45],
                [2,45,45],
                [3,45,45],
                [3,8,45],
                [7,5,45],
                [19,20,45],
                [8,9,45],
                [45,45,45],
                [5,7,45],
                [7,17,45],
                [21,11,45],
                [45,45,45],
                [45,45,45],
                [45,45,45],
                [3,8,45],
                [35,45,14],
                [15,16,45]
            ][gearId - 51];
            return string(abi.encodePacked(
                '--dmpf1:',
                COLORS[gear[0]],
                ';--dmpf2:',
                COLORS[gear[1]],
                ';--dmpf3:',
                COLORS[gear[2]],
                ';'
            ));
        } else {
            uint8[4] memory gear = [
                [44,45,45,45],
                [7,5,45,45],
                [3,8,45,45],
                [3,8,7,45],
                [5,7,45,45],
                [7,3,8,45],
                [9,8,45,45],
                [3,8,27,26],
                [7,8,3,45],
                [9,8,45,45],
                [8,9,3,45],
                [9,8,45,45],
                [9,8,45,45],
                [5,7,45,45],
                [7,5,45,45],
                [7,8,3,45],
                [7,5,45,45],
                [10,9,45,45],
                [9,10,9,45],
                [10,9,10,45],
                [10,9,45,45],
                [15,16,45,45],
                [19,20,19,45],
                [20,19,20,45],
                [20,19,45,45],
                [8,9,45,45],
                [8,3,45,45],
                [26,14,27,45],
                [16,15,45,45]
            ][gearId - 68];
            return string(abi.encodePacked(
                '--dmpw1:',
                COLORS[gear[0]],
                ';--dmpw2:',
                COLORS[gear[1]],
                ';--dmpw3:',
                COLORS[gear[2]],
                ';--dmpw4:',
                COLORS[gear[3]],
                ';%253C/style%253E%253Cg class=\'h\' transform=\'translate(4,88)\'%253E'
            ));
        }
    }

    /**
    * @notice render a weapon asset
    * @param smAssetId the small asset id of the gear item
    * @return string of svg
    */
    function weapon(uint256 smAssetId)
        external
        pure
        returns (string memory)
    {
        string[20] memory GEAR = [
            // START WEAPONS
            // 0 empty
            '%253Cg%253E%253C/g%253E',
            // 1 sword
            '%253Cg%253E%253Cpath d=\'M17,9h2v2h-1v1h-1v1h-2v1h-2v1h-2v1h-2v1h-2v-3h2v-1h2v-1h2v-1h2v-1h2z\' fill=\'var(--dmpw1)\'/%253E%253Cpath d=\'M18,10h1v1h-1v1h-1v1h-2v1h-2v1h-2v1h-2v1h-2v-1h2v-1h2v-1h2v-1h2v-1h2v-1h1z\' fill=\'var(--dmpw2)\'/%253E%253Cpath d=\'M17,9h2v2h-1v1h-1v1h-1v-1h1v-1h1v-1h-1v1h-2v-1h2zM13,11h1v1h-1zM11,12h1v1h-1v1h-1v1h1v1h-2v1h-1v-3h1v-1h2zM12,14h1v1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 2 daggers
            '%253Cg%253E%253Cpath d=\'M15,10h2v1h1v1h1v2h-3v-2h-1zM8,14h2v-1h2v2h-1v1h-1v1h-2z\' fill=\'var(--dmpw1)\'/%253E%253Cpath d=\'M16,10h1v1h1v1h1v2h1v1h-5v-1h3v-2h-1v-1h-1zM7,13h1v3h2v-1h1v-1h1v1h-1v1h-1v1h-2v1h-1z\' fill=\'var(--dmpw2)\'/%253E%253Cpath d=\'M15,11h1v1h1v3h-2v-1h1v-2h-1zM10,13h2v1h-2v1h-2v1h2v-1h1v-1h1v1h-1v1h-1v1h-2v1h-1v-3h1v-1h2zM18,13h1v1h1v1h-2z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 3 bow
            '%253Cg%253E%253Cpath d=\'M11,9h1v1h-1v1h-2v1h-1v1h-2v1h-2v1h-1v-1h1v-1h2v-1h2v-1h1v-1h2zM7,15h1v1h1v1h1v1h1v1h-1v-1h-1v-1h-1v-1h-1z\' fill=\'var(--dmpw1)\'/%253E%253Cpath d=\'M13,8h1v1h-1v1h-1v-1h1zM2,14h1v1h-1z\' fill=\'var(--dmpw3)\'/%253E%253Cpath d=\'M14,7h1v3h-1v2h-1v1h-1v1h-1v1h-1v1h-2v1h-1v-1h1v-1h2v-1h1v-1h1v-1h1v-2h1zM1,15h1v1h2v1h-2v-1h-1zM11,18h1v2h-2v-1h1z\' fill=\'var(--dmpw2)\'/%253E%253Cpath d=\'M14,7h1v2h-2v1h1v-1h1v1h-1v2h-1v1h-1v-1h1v-2h-1v-1h1v-1h1zM2,14h1v1h-1v1h2v1h-2v-1h-1v-1h1zM7,15h1v1h1v1h-2zM11,18h1v1h-1v1h-1v-1h1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 4 staff
            '%253Cg%253E%253Cpath d=\'M6,5h1v1h1v4h-1v2h-1v-2h-1v-4h1z\' fill=\'var(--dmpw1)\'/%253E%253Cpath d=\'M6,6h1v2h1v1h-1v2h-1v-2h-1v-1h1z\' fill=\'var(--dmpw2)\'/%253E%253Cpath d=\'M6,12h1v2h-1zM5,17h1v5h-1z\' fill=\'var(--dmpw3)\'/%253E%253Cpath d=\'M5,8h1v1h1v-1h1v2h-1v2h-1v-2h-1zM6,13h1v1h-1zM5,17h1v3h-1zM5,21h1v1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 5 scepter
            '%253Cg%253E%253Cpath d=\'M15,10h3v2h-1v1h-4v1h-2v1h-2v1h-2v-1h2v-1h2v-1h2v-1h1v-1h1z\' fill=\'var(--dmpw1)\'/%253E%253Cpath d=\'M18,9h1v1h-1zM15,11h1v1h1v-1h1v1h-1v1h-1v-1h-1v1h-1v-1h1zM12,13h1v1h-1zM7,15h1v1h-1z\' fill=\'var(--dmpw2)\'/%253E%253Cpath d=\'M18,9h1v1h-1v2h-1v1h-3v-1h2v-1h1v-1h1zM9,14h1v1h-1v1h-2v-1h2z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 6 knuckles
            '%253Cg%253E%253Cpath d=\'M5,14h3v3h-1v1h-2v-1h1v-2h-1zM17,14h3v3h-1v1h-2v-1h1v-2h-1z\' fill=\'var(--dmpw1)\'/%253E%253Cpath d=\'M5,13h2v1h1v2h-1v-1h-1v-1h-1zM17,13h2v1h1v2h-1v-1h-1v-1h-1z\' fill=\'var(--dmpw2)\'/%253E%253Cpath d=\'M6,13h1v1h-1zM5,15h1v1h1v2h-2zM17,15h1v1h1v2h-2z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 7 pickaxe
            '%253Cg%253E%253Cpath d=\'M9,13h4v1h-2v1h-2v1h-2v-2h2zM3,16h1v1h1v1h-2z\' fill=\'var(--dmpw1)\'/%253E%253Cpath d=\'M11,12h2v1h-2v1h-2v1h-1v-1h1v-1h2z\' fill=\'var(--dmpw2)\'/%253E%253Cpath d=\'M11,7h2v1h1v1h1v2h1v4h-1v2h-1v1h-1v1h-1v-1h1v-8h-1v-2h-1z\' fill=\'var(--dmpw3)\'/%253E%253Cpath d=\'M11,7h2v1h1v1h1v1h-1v-1h-1v1h1v5h1v-4h1v4h-1v2h-1v1h-1v1h-1v-2h1v-3h-2v1h-2v1h-2v-2h3v-1h2v-1h1v-2h-1v-2h-1zM3,17h2v1h-2z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 8 club
            '%253Cg%253E%253Cpath d=\'M13,9h3v1h1v3h-1v1h-2v1h-3v1h-4v-2h1v-1h1v-1h1v-1h2v-1h1z\' fill=\'var(--dmpw1)\'/%253E%253Cpath d=\'M13,10h3v1h-1v1h-2v1h-1v1h-2v1h-2v-1h1v-1h1v-1h2v-1h1z\' fill=\'var(--dmpw2)\'/%253E%253Cpath d=\'M13,9h1v1h-1zM10,11h1v1h-1v1h-1v1h-1v2h-1v-2h1v-1h1v-1h1zM16,11h1v2h-1v1h-2v1h-3v1h-2v-1h2v-1h2v-1h2v-1h1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 9 shadowblades
            '%253Cg%253E%253Cpath d=\'M17,9h2v1h1v1h1v5h-3v-5h-1zM11,15h1v2h-1v1h-1v1h-5v-3h6z\' fill=\'var(--dmpw1)\'/%253E%253Cpath d=\'M18,9h1v1h1v1h1v1h-1v-1h-1v-1h-1v1h-1v-1h1zM18,12h1v2h-1v1h1v1h1v-2h1v2h-1v1h-1v1h-2v-1h1v-2h-1v-1h1zM3,15h1v1h2v-1h1v1h2v1h-2v-1h-1v1h-1v1h2v1h-2v-1h-1v-1h-1zM10,15h1v1h1v1h-1v1h-1v1h-1v-1h1v-1h1v-1h-1z\' fill=\'var(--dmpw2)\'/%253E%253Cpath d=\'M18,13h1v1h-1zM3,15h1v1h2v-1h1v1h-1v1h1v1h1v1h-3v-1h-1v-1h-1zM19,15h2v1h-1v1h-1v1h-2v-1h1v-1h1zM8,16h2v1h-2z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 10 shortswords
            '%253Cg%253E%253Cpath d=\'M14,8h2v1h1v1h1v4h-2v-2h-1v-2h-1zM11,12h2v2h-1v1h-1v1h-4v-2h2v-1h2z\' fill=\'var(--dmpw1)\'/%253E%253Cpath d=\'M15,8h1v1h1v1h1v2h1v2h-1v-2h-1v-2h-1v-1h-1zM12,13h1v1h-1v1h-1v1h-2v1h-2v-1h2v-1h2v-1h1z\' fill=\'var(--dmpw2)\'/%253E%253Cpath d=\'M14,8h2v1h-1v1h1v-1h1v1h1v1h-1v-1h-1v2h-1v-2h-1zM11,12h2v1h-2v1h1v-1h1v1h-1v1h-1v1h-1v-1h1v-1h-2v-1h2zM16,13h1v1h-1zM7,14h1v1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 11 kusarigama
            '%253Cg%253E%253Cpath d=\'M14,9h3v1h2v1h1v1h1v1h-1v-1h-2v-1h-2v1h-2v-1h-1v-1h1zM3,17h1v1h1v2h-1v1h-1v-1h-1v-2h1zM7,17h1v1h1v1h6v-1h1v-1h1v1h-1v1h-1v1h-6v-1h-1v-1h-1z\' fill=\'var(--dmpw1)\'/%253E%253Cpath d=\'M15,12h2v2h1v2h-2v-2h-1z\' fill=\'var(--dmpw2)\'/%253E%253Cpath d=\'M16,12h1v2h1v2h-1v-2h-1z\' fill=\'var(--dmpw3)\'/%253E%253Cpath d=\'M16,9h1v1h-1zM13,10h1v1h2v1h1v2h1v2h-2v-2h-1v-1h1v-1h-2v-1h-1zM18,11h1v1h-1zM20,12h1v1h-1zM3,17h1v1h-1zM7,17h1v1h1v1h1v1h-1v-1h-1v-1h-1zM16,17h1v1h-1v1h-1v1h-1v-1h1v-1h1zM2,19h1v1h1v-1h1v1h-1v1h-1v-1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 12 handaxes
            '%253Cg%253E%253Cpath d=\'M16,8h3v1h1v1h1v2h-1v1h-1v-1h-3v-2h1v-1h-1zM9,14h2v1h1v-1h1v3h-1v1h-1v1h-2v-1h-1v-1h1z\' fill=\'var(--dmpw1)\'/%253E%253Cpath d=\'M14,10h2v2h1v4h-1v-2h-1v-2h-1zM9,12h2v2h-2v1h-3v-1h1v-1h2z\' fill=\'var(--dmpw2)\'/%253E%253Cpath d=\'M14,10h2v2h1v2h1v2h-1v-2h-1v-2h-1v-1h-1zM10,12h1v2h-2v1h-2v1h-1v-1h1v-1h2v-1h1z\' fill=\'var(--dmpw3)\'/%253E%253Cpath d=\'M17,9h1v1h1v-1h1v1h1v1h-1v-1h-1v2h1v1h-1v-1h-2v2h1v2h-2v-2h-1v-1h1v-3h1zM7,13h1v2h-1v1h-1v-2h1zM10,13h1v2h1v-1h1v3h-1v1h-1v1h-2v-1h-1v-1h1v1h2v-1h1v-1h-1v-1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 13 shortsword
            '%253Cg%253E%253Cpath d=\'M13,11h2v2h-1v1h-1v1h-2v1h-4v-2h2v-1h2v-1h2z\' fill=\'var(--dmpw1)\'/%253E%253Cpath d=\'M14,12h1v1h-1v1h-1v1h-2v1h-2v1h-2v-1h2v-1h2v-1h2v-1h1z\' fill=\'var(--dmpw2)\'/%253E%253Cpath d=\'M13,11h2v1h-2v1h1v-1h1v1h-1v1h-1v1h-1v-1h1v-1h-2v-1h2zM9,13h1v1h-1zM7,14h1v1h-1zM8,16h1v1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 14 poison spear
            '%253Cg%253E%253Cpath d=\'M5,5h1v9h-1zM5,17h1v5h-1z\' fill=\'var(--dmpw1)\'/%253E%253Cpath d=\'M4,3h2v3h-1v-1h-1z\' fill=\'var(--dmpw2)\'/%253E%253Cpath d=\'M5,1h1v2h1v3h-1v-1h-1zM6,7h1v1h-1z\' fill=\'var(--dmpw3)\'/%253E%253Cpath d=\'M5,3h1v1h1v1h-1v-1h-1z\' fill=\'var(--dmpw4)\'/%253E%253Cpath d=\'M5,1h1v1h-1zM5,6h1v1h-1zM5,8h1v4h-1zM5,17h1v2h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 15 wand
            '%253Cg%253E%253Cpath d=\'M13,11h2v1h-2v1h-2v1h-2v1h-2v-1h2v-1h2v-1h2z\' fill=\'var(--dmpw1)\'/%253E%253Cpath d=\'M15,10h2v1h-2v1h-1v-1h1zM7,14h1v1h-1z\' fill=\'var(--dmpw2)\'/%253E%253Cpath d=\'M16,10h1v1h-1zM9,13h1v1h-1v1h-2v-1h2z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 16 phoenix
            '%253Cg%253E%253Cpath d=\'M5,11h5v1h2v1h1v1h1v1h1v2h-2v1h-3v-1h1v-1h-4v-2h1v-1h-1v-1h-2z\' fill=\'var(--dmpw1)\'/%253E%253Cpath d=\'M6,11h3v1h2v1h1v1h1v1h1v1h1v1h-2v-1h-1v-1h-1v-1h-2v1h1v1h-1v-1h-1v-1h1v-1h-1v-1h-2z\' fill=\'var(--dmpw2)\'/%253E%253Cpath d=\'M5,11h2v1h2v1h1v1h1v1h2v-1h1v1h-1v1h1v-1h1v2h-4v1h-1v-1h1v-1h-4v-2h1v-1h-1v-1h-2z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 17 cutter
            '%253Cg%253E%253Cpath d=\'M20,3h1v3h-1v2h-1v3h-1v1h-1v1h-2v1h-2v1h-2v1h-2v1h-2v-3h2v-1h2v-1h2v-1h2v-1h-3v-1h1v-1h1v-1h1v-1h1v-1h2v-1h2z\' fill=\'var(--dmpw1)\'/%253E%253Cpath d=\'M19,4h1v3h-1v1h-1v2h-1v1h-1v1h-1v1h-2v-1h1v-1h1v-1h1v-1h1v-1h1v-1h1v-1h-1v1h-1v1h-1v1h-2v-1h1v-1h1v-1h2v-1h1z\' fill=\'var(--dmpw2)\'/%253E%253Cpath d=\'M16,5h1v1h-1zM20,5h1v1h-1zM17,7h1v1h-1v2h-1v1h-1v1h-2v1h-2v1h-2v1h-1v1h1v-1h2v-1h2v1h-2v1h-2v1h-2v-3h2v-1h2v-1h2v-1h2v-1h-1v-1h-1v1h-1v-1h1v-1h1v1h1v-1h2zM18,10,h1v1h-1v1h-1v1h-1v-1h1v-1h1zM14,13h1v1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 18 scmitar
            '%253Cg%253E%253Cpath d=\'M16,8h3v3h-1v1h-1v1h-1v1h-2v1h-3v1h-2v1h-2v-2h2v-1h2v-1h1v-1h1v-1h1v-1h2z\' fill=\'var(--dmpw1)\'/%253E%253Cpath d=\'M17,5h1v1h1v2h-1v2h-1v1h-1v1h-1v1h-2v1h-2v1h-2v1h-2v-1h2v-1h2v-1h2v-1h1v-1h1v-2h1v-2h1z\' fill=\'var(--dmpw2)\'/%253E%253Cpath d=\'M17,5h1v2h-1v2h-1v1h-1v1h-1v1h-1v1h-1v1h-1v2h-2v1h-2v-2h2v-1h2v-1h1v-1h1v-1h1v-1h1v-1h1v-2h1zM18,9h1v2h-1v1h-1v1h-1v1h-1v-1h1v-1h1v-1h1zM13,14h1v1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 19 greataxe
            '%253Cg%253E%253Cpath d=\'M17,11h2v1h1v-1h1v3h-1v1h-2v1h-4v-1h1v-3h2z\' fill=\'var(--dmpw1)\'/%253E%253Cpath d=\'M17,9h2v2h-2v1h-2v1h-2v1h-2v1h-2v1h-2v-2h2v-1h2v-1h2v-1h2v-1h2zM3,16h1v1h1v1h-2v1h-2v-2h2z\' fill=\'var(--dmpw2)\'/%253E%253Cpath d=\'M17,9h1v1h-1v1h-2v1h-2v1h-2v1h-2v1h-1v-1h1v-1h2v-1h2v-1h2v-1h2z\' fill=\'var(--dmpw3)\'/%253E%253Cpath d=\'M18,10h1v2h1v-1h1v3h-1v1h-1v-1h1v-1h-1v-1h-1zM15,12h1v2h1v1h1v1h-4v-1h1zM7,14h3v1h-1v1h-2zM1,17h1v1h1v-1h2v1h-2v1h-2z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E'
            // END WEAPONS
        ];
        return GEAR[smAssetId];
    }

    /**
    * @notice render a chamber with an encounter
    * @param ct chamber type
    * @param et encounter type
    * @param index chamber index
    * @return string of svg
    */
    function smChamber(string memory ut, string memory ct, string memory et, uint256 index)
        external
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(
            '%253Cg transform=\'translate(',
            // Calculate the starting x position of the chamber
            (((index % 8) * 14) + 2).toString(),
            ',',
            // Calculate the starting y position of the chamber
            (((index / 8) * 14) + 2).toString(),
            ')\'%253E%253Cuse href=\'%2523',
            ut,
            '\' class=\'c',
            ct,
            '\'/%253E%253Cuse href=\'%2523e',
            et,
            '\'/%253E%253C/g%253E'
        ));
    }

    /**
    * @notice render the next upcoming chamber
    * @param index next chamber index
    * @return string of svg
    */
    function smNext(uint256 index)
        external
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(
            '%253Cg transform=\'translate(',
            // Calculate the starting x position of the chamber
            (((index % 8) * 14) + 2).toString(),
            ',',
            // Calculate the starting y position of the chamber
            (((index / 8) * 14) + 2).toString(),
            ')\'%253E%253Cuse href=\'%2523u\' class=\'n\'/%253E%253C/g%253E'
        ));
    }

    /**
    * @notice render the exit chamber
    * @return string of svg
    */
    function smExit()
        external
        pure
        returns (string memory)
    {
        return '%253Cg transform=\'translate(100,72)\'%253E%253Cimage href=\'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAMAAABhq6zVAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABhQTFRF2dnZ/NYXG4YtIJ41YDEU////HcDtgEIb7MtdQwAAADdJREFUeNpcysERACAIA0FQif13bBxRkPvtJDJTUgAYANUDMwl4AY5+k7JcdNbYwyYxUh+WAAMAA0sDCBfICVcAAAAASUVORK5CYII=\'/%253E%253C/g%253E';
    }

    /**
    * @notice render portions of the bottom stats block
    * @param index index to render
    * @param miner current miner instance
    * @return string of svg
    */
    function smMinerStat(uint256 index, Miner memory miner)
        external
        pure
        returns (string memory)
    {
        if(index == 0){ // health
            return string(abi.encodePacked(
                '%253Ctext x=\'39\' y=\'90.75\' font-family=\'txt\' font-size=\'10\' dominant-baseline=\'hanging\' fill=\'white\'%253E',
                (miner.health < 0 ? 0 : uint16(miner.health)).toString(),
                '%253C/text%253E'
            ));

        } else if(index == 1){ // attack
            return string(abi.encodePacked(
                '%253Ctext x=\'67\' y=\'90.75\' font-family=\'txt\' font-size=\'10\' dominant-baseline=\'hanging\' fill=\'white\'%253E',
                (miner.attack < 0 ? 0 : uint16(miner.attack)).toString(),
                '%253C/text%253E'
            ));
        } else if(index == 2){ // gold
            return string(abi.encodePacked(
                '%253Ctext x=\'95\' y=\'90.75\' font-family=\'txt\' font-size=\'10\' dominant-baseline=\'hanging\' fill=\'white\'%253E',
                miner.gold.toString(),
                '%253C/text%253E'
            ));
        } else if(index == 3){ // armor
            return string(abi.encodePacked(
                '%253Ctext x=\'39\' y=\'101.75\' font-family=\'txt\' font-size=\'10\' dominant-baseline=\'hanging\' fill=\'white\'%253E',
                (miner.armor < 0 ? 0 : uint16(miner.armor)).toString(),
                '%253C/text%253E'
            ));
        } else if(index == 4){ // speed
            return string(abi.encodePacked(
                '%253Ctext x=\'67\' y=\'101.75\' font-family=\'txt\' font-size=\'10\' dominant-baseline=\'hanging\' fill=\'white\'%253E',
                (miner.speed < 0 ? 0 : uint16(miner.speed)).toString(),
                '%253C/text%253E'
            ));
        } else { // chamber count
            return string(abi.encodePacked(
                '%253Ctext x=\'95\' y=\'101.75\' font-family=\'txt\' font-size=\'10\' dominant-baseline=\'hanging\' fill=\'white\'%253E',
                miner.currentChamber.toString(),
                '%253C/text%253E'
            ));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library AssetRenderer2 {

    /**
    * @notice render defs tag
    * @param lgHeadgearAssetId the lgHeadgearAssetId of the gear item
    * @param genderId the gender of the miner (0 == male, 1 == female)
    * @return string of svg
    */
    function renderHairDefs(uint256 lgHeadgearAssetId, uint256 lgHairAssetId, uint256 genderId)
        external
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(
            '%253Cdefs%253E%253Cmask id=\'hm\'%253E%253Cpath d=\'M0,0h57v57h-57z\' fill=\'white\'/%253E',
            (lgHeadgearAssetId < 7 ? '' : '%253Cpath d=\'M0,0h57v22h-57z\' fill=\'black\'/%253E'),
            (lgHairAssetId == 5 ? '%253C/mask%253E%253C/defs%253E%253Cg mask=\'url(%2523hm)\'%253E' : (genderId == 0 ? '%253Cpath d=\'M0,57v-5h1v-1h2v-1h2v-1h4v-1h3v-1h2v-1h2v-1h2v-1h1v-7h-1v-1h-1v-1h-1v-1h-1v-5h28v9h-1v5h-1v3h-1v1h-1v1h2v1h2v1h4v1h2v1h4v1h2v1h1v1h1v2z\' fill=\'black\'/%253E%253C/mask%253E%253C/defs%253E%253Cg mask=\'url(%2523hm)\'%253E' : '%253Cpath d=\'M0,57v-5h1v-1h2v-1h2v-1h4v-1h3v-1h2v-1h3v-1h2v-8h-1v-1h-1v-1h-1v-1h-1v-5h28v9h-1v2h-1v1h-1v2h-1v2h-1v1h-1v2h4v1h2v1h4v1h2v1h4v1h2v1h1v1h1v2z\' fill=\'black\'/%253E%253C/mask%253E%253C/defs%253E%253Cg mask=\'url(%2523hm)\'%253E'))
        ));
    }

    /**
    * @notice render a headgear asset
    * @param lgAssetId the large asset id of the gear item
    * @return string of base64-encoded image
    */
    function renderHeadgear(uint256 lgAssetId, uint256 genderId)
        external
        pure
        returns (string memory)
    {
        string[18] memory HEADGEAR = [
            // START HEADGEAR
            // 0 assassin's mask
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAylJREFUeNrsmsFv0zAUxu2qRw5dDxPHZqtAAs5w4cJf3h64wA0JkEAb3RHtMHZg57LPyxc9PWwnWZzG22wpchunyfv5e355tmv3+7157GVmnkApkAWyQBbIAlkgC+QTh5wP+bG1tvms00PZhrKqToP548Xu3OpzvF/sGQeBjD0Y56uTddO4WCzN4mhprv9cuRrl+Pi5ubz87S7ndbtfZ5ZwuIcP9uCQoQJAgDnAGg5QOFBqOFfevnvvvqNNdIzNwl1DcFo5gvmKbltV68YZ7gS0ZuhMaT6Weo2bHi07wflg6w4brOhsLPf0Ga7dtE1d3I8Ba4iasxRBx6dgV/eMtYe84OBKhgC1gb6A01VNGaUnTwZibnof2DbVs8t4CMW6DaCr4qND0lX7jB2tZAhGdoKItHko2QYcgtLns1FyTLdOGWEfxCxkaACaT6ES658/vjdtofQP53FkBekzllAXu7PoOJadgGtD12er5J3R5x8CzRsmFE6566v/rr1N7zZZj8m2MQUggDlID2CWgadn+N8mumY6d5U56Os3zzbfvn6xfeFjSydZjUkEFwDf3Pz1GszJcl1vdNuQIDQapI6y/AyDubajax/00NdHsjEZMsQ3NrvMULDmQ+WyznhonHzh+zoBHZQyT00OifVShv6YWrGZBjuDsKg/f/ooF7TyTAZ8c0YoyuAT6hTWL16+au4h12kng4Saq8q4eWVobMJ4tgEWELJAOZn2scbYTBF4kqygY3GUoH0V75ruTR54uGonx6dWQLqcTNhrwK3vkOleNtEVwSJmlAw0HVO2bQq70i9/3LoXx1SfVwM3d+SRdXR1QUgo6tsSQAcgsJh6R6s6WXs847TpNN/23uRpnQTl6yPk4r60ri2bOjikXkXnbpbMP+UyRtdkIZv5JABD2Yl8uUsloWwsnePvxCqBnRQSO8Ndp0ESFsZTXamsTO9SAKLYIVGMG6SoObGVLqq3zXXd1jkE5DMm+8+ANsiI/f+2nBPRNTRLYdBK8SpJAqkMseJPDHudk+rxK2chDFgpAZO4a/+sqH29JjQO72urLX/PLpAFskAWyBHKPwEGAAnHFCRzB+E2AAAAAElFTkSuQmCC',
            // 1 misty hood male
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAA6BJREFUeNrsmj2O4kAQhW1ETEZIQDITIIHECTg0B+AESCARDAkBIRkZEctD80ZFTfWP222b3XVJIwZj4/761U9Xm/J+vxf/ug2K/8B6yB6yh+whe8geMtGGVU4uy7LWzebzeXDlsd/vo28Su5AZpg44dIPFYnE3jhXX6/Xl2Gg0er6K48/rdrtdmWuyyyrLOvnlrusIByDLAAOw5XJZbLfbl2NyAk6nU+GC5Thix54VEoAaTsPMZrPifD6/qIdj4/H45TwfbGeQAJxOpz/uBzgYBw6bTCY/MARZrVa/ztOghCVoVchhjuxFQKmeNWAASiOgvO5yuRSHw+GpLq/ZbDbvU0IYa1YMctBUke9dgIAjIL3DSmatKKlVjDWtKtUioLSHmxa4B1w2pYxlVVKryEFDOQ7cUpGAcF8JCGWpIl4BGlNrG4PkYEKfaaUkoITDH7IwVETGtiawNXf1AWKgUmG+pzGjakAYYhPuWRewNqSsi3ogHKxUTf7PBBQLqEtM60pWNcBoQBpcFICIP5zDyeCxziBd7qSzpK9GyhiUKx0Y4Kx1b+dK6izJ9zoueYwu+uhCPr87li/AyUSV6rK1IWNmVwPqCQCg0XIB9guQnCThMfcqLdmg6djTsC4XlipKwwRYk/AW7ipd1HeOD4Bqwm0tNbFWb01JrZgLUMaUBHSpSFB8jnOteG5dSWZItFQWnGtREGuyO2l9WQfVOHD2jJZ6uuBbKj56xKNLzVDJasVdtYtKQDkwj5seXaBvkXhkH2i5qAass/tWtV4mKyn7SA6cgOgsQvUz5KY51aytpNyYkq2TtUtABRTgscq92ES3uhiQtYsQLkBD3WNgwyyLmllXPHJPVatHQKsmBmLxGBvTjUMSwpfeY92U0Ba8bweilRLCAVA9vAIaceoCDGXUHD/cGOQAhAtJQK2mmv3Kcca2K3Wh3thuHWHx+p0NPzVgVZUwWVUzazZIK9mEll4pgKk7A7UhpQtZZcJSMSXOrP3aRiGxwctdOqsm+nbYqgI+auYH/1+v197nltmV1Io5ir1eeHexOVjPXfXD1NxGFW+3W7Kr1lq76poYKtapborygdBIddUkSMYj90dp7Ei4ISzjNNVNWR9b7UL4RAmAelZl60XQOm4q911ll5P0fbkep+Mz/ViNGdialNhelbHI3XV8TyeP03nD8vcT0uDPVWLrcMrCvLaSTZvvYSuXdY38+uNvtf4HhD1kD9lDtm5/BBgAJ3vz25dUcNcAAAAASUVORK5CYII=',
            // 2 misty hood female
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAA49JREFUeNrsmjGO8jAQhRNETUdJQbUFEkicgENzAE6ABBLF0lBQ0nGB/DzEQ8Ps2I4dJ7D7Z6QVSwhkPr/xzNhJWVVV8ddtUPwH1kP2kD1kD9lD9pCJNow5uSzLRhebz+fBzmO/39e+SN1GZpjqcOgCi8WiMo4V1+v15dhoNLq/iuP37+12uzLXYJcxbZ38cdf3CAcgywADsOVyWWy325djcgBOp1PhgqUfdX3PCglADadhZrNZcT6fX9TDsfF4/HKeD/ZtkACcTqfP8AMcjI7DJpPJE4Ygq9Xqx3kalLAEjYUc5sheBJTqWQ4DUBoB5fcul0txOBzu6vI7m83mc0oI55o1B+k0VeR7FyDgCMjosJJZJ0pqFeuaVpVqEVDaLUwLXAMhm1LGsiqpVaTTUI6OWyoSEOErAaEsVcQrQOvU2tYg6UzoM62UBJRw+EMWhorI2NYAdhauPkA4KhXmexozqgaEYW4iPJsCNoaUdVE7QmelavJ/JqC6gLrEdK5krAFGA9IQogDE/MM5HAweexukK5x0lvTVSDkHZacDA5zV975dSZ0l+V7PSx5jiN5WIV+PFcs34GSiSg3ZxpB1RlcD6gEAoLHkAuw3IDlIImKqmCXZoO25p2FdISxVlIYBsAbhI8JVhqjvHB8A1UTYWmqiV+9MSa2YC1DOKQnoUpGg+BznWvO5cyWZIbGksuBcTUFdk6uTzts6qEbHuWa01NMF31LxtkY8utQMlaxOwlWHqASUjnnC9OgC/YjEI9eBVohqwCa7b7H1MllJuY6k4wTEyiJUP0NhmlPNxkrKjSm5dLJ2CaiAAjzGXIuL6E6bAVm7COECNNQ9BjbMsqiZteORe6paPQJaNTEwF49153TrkITwpfe6YUpoC963A9FJCaEDVA+vgMY8dQGGMmqOBzcGOQARQhJQq6lGP3qecdmV2qi3tltHWLw+suGXBoxVCYMVm1mzQVrJJtR6pQCm7gw0hpQhZJUJS8UYQDYd1n5tq5DY4OUunVUTfTtsTRLJer323rfMrqRWzFHsdeOd3Dq+Lbvqm6ltWmqoNoLUNTFUrJuoiN9MDdWkBp3zkfujNDrEDWE5T98VpkmQvKMEQD2q0jGC5gpTucppHdJXhB+fVQqcf1VqqHFLhQOZ8jvZdgYQkuXPO6TBx1Xq1uGUxvy5dEt9MKJt891sZUS18vTHb7X+AcIesofsITu3fwIMAGcE6Bijid9KAAAAAElFTkSuQmCC',
            // 3 none
            '',
            // 4 enchanted crown
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAblJREFUeNrsmDFuwjAUhu0KqUywdWPkGEWtVHWgF+jEBXqEsjU9Qi/QiRMwoA5ROEZGNrZmol3cvFAHK7KTWHET0/xPinDC48Wf//eeQ7gQgv13u2A9MEACsi+QnPPKY/kwFq58vFbyeT4SLnw6g6QtyHTQxGfTYakf+dw9JZU+3tfkcj4uTbeba49rsu4KDxe78+6uTRoC/VamM6WsLpbqc7ZbyGx66b+SJgWk3b/sa8XR1SXFlU2pU8jvzVUOSvuZKc2KzYfGdE21YHWM06QEWktXCaiqSM1H12WLTSkD/fWjsQsbuAhCagarFOgx67bcVGsZKJtoVSz6BQt3iz5wFejwPklBd7mKpm1Dgra5tThN1yNokqlIY5OPbZZ4AxnFX1b+dVS0XZDWGk/ZxOR3ZYDh9vRpu3B/XpM2ChIApWEUH7Q+H2/5svgPKZWTikTxJ2PrUQ7wuk5uLcKFgQ+QJxi9AgpU2Gb28CavJE1PJgWFQnkP9YmIrqnndf+7dqJkClQ5Ux2MLWBnSvbiRRYgAQlIQAISkIAEJCABCUhAAhKQgAQkIAEJSEACEpCABCQgAQlIV/YjwACgM+38l8jvfwAAAABJRU5ErkJggg==',
            // 5 ancient mask
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAhpJREFUeNrsmj1LxEAQhrOiKFEQO9HKQ60ED8RWYu3vtb70h3C2Kmel2ImFQbGImSOj42bzcckku4kzEHKX7C377MzuzryciuPYG7qteP/ABFIgBVIgBVIgBVIgBXIQtsrVkVIq8+z0wGfN/mfzd2UVEo1WNePRpre7s7a4wM4O/Vp9Xk/fvJfXLwlXgRRIgRRIgextMlBkeMbdPES5bfQztKitk5BgkBAUJQMAhe/pZ/zeJBlggUwymzhJ4X6ynMGG63jkZ2Z/No9qhSB4jbZt4kU2yNvHCBLnOC8/hVBddqBNwVrxJILq3qOgRe+ch4TKA0qtFDQgpdbEMBmX2R78ycXJ1h9AvZ2pL5u7a5jeg5L3VfvpzxEClnqrUiHNWXC3VjSblIKjvY3FxbFT9z6t49x0OoPkHrSTkKYjYpBViE1vdhauNr3ZWbiKJ4ndP3/0s2guW5MgHh/vr/dbGcjbYQEOn989fWbKMpiYq/PtxqFudXdFtQDuAEPv+JzjCOo046m73nrjSRNoVzuuSJLcRjeXKtUIl6db96RpoBS2bJ1ynJuK66+gWD9q9WRApQvTLgnnI0Dn3YkcUnusnYTrr16ThdXPR1MkpNqRe2syFbdQpwnKYE0hbRK0nArXHAkk0HScDCyGKQEMdWnFKci6sAiY9BXS3zoNuSysDoi6rnXIOhOSB8vlQauQRbDcgNYhB6UM2LZvAQYAsylEU82de7EAAAAASUVORK5CYII=',
            // 6 charmed headband
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAg9JREFUeNrs2b9Lw0AUB/CLRCgpYoWC4haxk0IL4q6Dk3+Bs39XN8G/wMnB7iK0g4NUzCYKBetgKDjEvNjXvl4usSQpJfX7QK7NJeY+9+5HolYQBGrVY039gwASSCCBBBJIIIEEEkgggUyO6mErsCxrdZEErF9cKuegWSjUWsZL8161Fbvpu6sUATkG12217U3rPb+Xua32MnCu05oc23eOovJKtWPnn9V/0c/+AxV0rVUoUu/tl6+ulTdrhGOUKUZeX1XcRlTKoGs8v5u5c+2khnEv6o2dF8vn19Z31Fb4w7hxVqL4+H6bXrChIqCM11Ff7VYa6nbQzjWCbFPjqGH3nzfRd2ogDx1qINUnQWXW6Hccb55P6iSOwPRd1j+Fw5UzyUFAHgGFZZKBQ9HD/Jl7nW5oWjhMc41hMxkLgztQwimTevB5eSOWSULRShYHRBM/quehTMOoNs60DELJBg41ZNpxOR+TrsuFlDhermm/cp1mwEOW58dMFrQ5pjfO1GmG+5yExR0f9x97p+EO0il8nySQvhfJRYhgBKF5SmVST5tQf+1xY6QeHdnZWffJ1A2WgXJuZcnSXA1JeMIp4mHFngcoh6GOKsO/GVKfeBjI2WPgImCL7KxUJANNC1LpX7Xkfll2YOqr1qoAl/aqhT9/AAkkkEACCSSQQAIJJJBAAgkkkEACCSSQQJY7fgQYADSdKGHvFBOyAAAAAElFTkSuQmCC',
            // 7 bandana
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAf1JREFUeNrsmU1OwzAQhW0aVbSUFQvELVj1FrDhAtyFO7DmAmzoLbgIQqISqD+RkKqQkZho6o6bEDvglDerKj+OP7+ZzHNqi6Iwhx5H5h8EIAEJSEACEpAtI/utB12PJ7WuY5avbBfmxHbleFyo6XBkzgcDczM+3bn2cb0wr5uNef7Mq2NP66VNFpLhCIrDB+cLgp7ly2igUSEJMBSOglSlIGVjgEaDlIAER/ETQC19GTS0VrPUAOW9BPs9bmHLaAsatYXEAHRTN4kW4tZhDEA5zv3ivVKTyutP+ySryCqEwEoVaVyuz2TMQF2auee1xXCPhaZu1rSZN3mV0+S0CVHKhdQr3UN9MyokAT6cXajQElbWI6UUA8p6cvulXARfGvKCXA6Pzd3HW3wzoDV0qRI7Ec3ZsC2jY/RbLpSE47GaqhrqgLYgGVB6SOk9GdqXOlejiZq6dYrVKRvqfjJtMHIYyrXVarBCt/OXLSXlZDlVpcJJbLUkHCtcGo1SoZOC4QjM98aTVsw37s7KiUyiZ3UR1n2IVqOsHHtK7l0+hTSoUI+szS2KQWdAWVttVUryy4AEdHcEKYK0djzujp0B+/b/yV5IBtReSL3/Wif7Zd8B9+4nDwWw0691vVASkIAEJCABCUhAAhKQgAQkIAEJSEACEpCABCQgAdkqvgQYAOQdZ2oZpwBLAAAAAElFTkSuQmCC',
            // 8 feathered cap
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAc5JREFUeNrs2LFOwzAQBmC76pIFJBgJY9jISFbEIzCSiDfgFRh4Bd4AKYyMGRGsHcNGRsIIEizdMDkLFzdNWmonboH/pKpulTr6HPvuVC6EYH89BuwfBJBAAgmk8xja/DhJkpn6k6Yp90+CpetSeV3wvsrZ0AYYRRELgkB+LopCju/FSGyGWzPXb+xvN87z/vDyNQrEbrzHntJH3jXSaPUIWL2mcPo4z3N2JW7m4tqwb/mrfO8Sa4wMw/B7q5XlZExIhb74uFx67j6wRkjOOYvjWEIV0Pf9KbTC2kAV1hZqjKQgaHUGJ9+rs3jKj9cKapXRCEuZtCnREJTC8zxjaH37mkKt6uS8BaLEQ09zPB7LhHQ+ODO6h0pctJBV9hXOkXTTtnJBr9udkcQSksIU2nRUVtrx6CVDjQmbZZn1nLSgJo1G722d/lQJ2sXTdJp46meEVpoSRH0LE1IlkKPnAwluaxToOv16NZ+qm3r8NBFZI5tAfUe9YVjU9w7ZLwy1kNqCkpA7Q+pFfF2i0zO5qli0XW07nkOHljuTpqSTtq4Kp1CjXht/LgMJJJBAAgkkkEACCSSQQAIJJJBAAgkkkEACCSSQQAIJJJCO4lOAAQCEf/kz0iBcCgAAAABJRU5ErkJggg==',
            // 9 ranger cap
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAXxJREFUeNrs2LFOAjEcx/HWNDHRCWMc1IHECRJG9RF8BJ+VR1B3nEwYlMGYMGHidFLkL1y56921BQG//+XgUsp9+Pd6v6CzLFP7XgfqHxRIkCBBbrzMOifXNxfxz6enkY59zJm1ou6u8gO6p/UnG3zIKzunjrquVGFgBnRRoUAX2n9R2eOb/tNOeoEhODaefUMmWgW70cnprRCzUyfZeLpnR7+T3F4eq4fXyexoq906VMPxV+61Pbol52WsW3bOwftn0OZjUgAFJHXfO1kZtwwsgsp7d9xWLlf34t0LLutk2Q+SW3Y67CliUnaxCrh8vmi873Pz7wkKBkH3pGwCneE4d969H2NL5rJHqed26ycGNQgHjZG1ko1NKilDwCLiLWqagupiK5GVedQHTI0tws+xviDvRa50bQsimg9b1lUTvWxSpxfpfsx3Neqk3bKvz3fjP8vQ5UpABwkSJEiQIEGCBAkSJEiQIEGCBAkSJEiQIEGCBAkSJMhm9S3AAKKYsH+jEASqAAAAAElFTkSuQmCC',
            // 10 leather hat
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAfZJREFUeNrsmsFKw0AQhneliATai4J6rBcv4jPUB9CX3Qewz6BevNhjLbSXFqKIEDPBaYeFbNLd2WaNM1DSkKbZr/+fnT9JdVEUqu91pP5BCaRACqRACqRAetbgUAe6uxo1po7pbKNjhBMdK/HYUJfD42o533ypyXikXpef223XZyfVOmzDenxb62QhEQ6gXha5ujnPttsQsK4oOHyWC5QVEgBRMRsQ1GpTMUDZIF2ATQq6gDlAWSA5FIwJGrWFwOCo/Xwq9EdigaQqxhokfH+bFnQQJW2rclXoDxUEeXuRFS5gl8L71ir/VlrrbpWsUzH0nOy0T7pUpHWaDYIVpPX0nu8tZ9AIAMC2JMdEQ11AIyC4JYkWggOybdpkW7ofvuz9fF0R5SoEBoahG/slXdbZEpQCEHhPgWzLJnVO4kDLS6gHj0OY3+U9XfcZr7eSz4sPPRkPnUEAlPMErOBKIOPbNtjPSbAmTjicE08JiCpWCvq6zltJOGAZtdrOrEbu8fTlHk+XD5bYlZzO1rZtTddKskOG9rQ/YVc7laTw/JNFSRq9MGtij+Toc51Cwn0XO6qlcGnFFutIw1Z28iFJx6Rg2eBzEgBK0Cri7WbYHWAvlKyJYialiUfLvz8EUiAFUiAFUiAFUiAFUiAFUiAFUiAFst/1I8AAx7MirNZCeJoAAAAASUVORK5CYII=',
            // 11 rusty helm
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAn9JREFUeNrsms9Kw0AQxndjW5QqFdFLQTyJF28K0kdQ0Ie1oI/Qi968iCcRerGIIqLUP7Ff5IvTmLTBbJutzkDYZrub7i/f7OzsUhuGofnrFph/YAqpkAqpkAqpkL+0yrR+6GB3eWzWcXr+YCeRnNhJZTxJqL3GYlRe9l7MffXNLL9+vd+lZmBubvvRPeppJ2f31ltIwhFia3U+Klc25+I2nc5TDNpq1b9UPHsw62u16PNj9yP63hVo4BoQA5eAgCPg3dV7VAKMyrFuf7cRKUp18X0eF58qJAEJR4VoF9fPQ7AAofvSCLq9sRC/CBegwSQAAQMQljAMnIb6Zr/2Q02CwnWl4ni+tdYPd00DlHNRGuo5X6WaEljO6VKVpIp0PxlksgClJdVEH6km7tFmf6cRlqokAOF+eQ3zM+9LcKGmE0iE/DSjOoSiYX6yLo/LerWEJJXhvQw6hJageZ9TCqSMqlSAV5qCSSVRSgWz3Nrr3DVNwTSXHQdX1H0rLl01bTCy7rH3PXc73adMQLwAJAWY63G7qgeQck0kGHJUWJx4V8dHXQBG/apmKGH30l0xYA5ysIU6Gtd+sA4eL5la3C+lT9uL6CoXdLFHPMrTF+3gorjy9pmqknKta23Wfx0VR8EV2RI6ddcRmUnblGjOz3hcZyveQObJSOBuRa7SIZPqJZL19swrKbdYDD5QNitpn0lIwtBlEXyksi7czQslu7X+UMbDY0csCUWOLbyAxGEwT9iYu47aVZRlhc5dqRKOJuSWS6Rl7aILeekZDwc/gLXyDEYCzrySGeoeSkAf/nhh9d8fCqmQCqmQCqmQCqmQCqmQCqmQCqmQCvm37VOAAQBcRKGlaSUs1AAAAABJRU5ErkJggg==',
            // 12 bronze helm
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAcRJREFUeNrsmrFOwzAQhu1SBHTp2hdAwFYkZlR2Blh4HAZegndgoQMPUHYk2BreoGuFVJAQCj2EI+M6IfgusYH/pChDYzuf73z3243O81z9deuof2CABCQgAQlIQAZal9NYa1372ZPh1reqY/zwXNlhqHDpcmepbODT/d6XH/YG62p3eZ0d9FaevbpbqGz2qtRQFW2u7xc6dEJXnMGRdTSw297AEZSxMrgyu7iZq+kS2gb1jRUFkgBtuBDAMlAOpFjicQFHO5sFIIXjT+38uP8RDdQvJ1TFIH2As/lbARjiSRu0TtJqtYRIAdrhHrWE+LwoCUhGfViZVyfhSRswZC024c2OdKjagBKeTE7WTR5f1KC/Jg7I7YtVJ11V07S5Kqi1xOMWfwpZ8ijdyQ63N9hwRhhEy66+kPXdQ5JHxgAThaw7w1OhF44ariY8bbu8fTJbqCOJIImeXSksSQjQRevQrEUhwLiebNoLOP5IzJOK+58LZ7uF07pQkxLmSUNK7kDgyRiQWURV02p2TRGUfSRZdcj0qXYmUiUkyrmrU79GVUon5rcJGh9GABKQgAQkIAEJSEACEpCABCQgAQlIQP56exdgAFsb1LS8gb46AAAAAElFTkSuQmCC',
            // 13 iron helm
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAf5JREFUeNrsmsGNgzAQRTFKBRRACRF3OLCNUAnV0Eg4wD2ihBSQFlg+wshiYSGecUx2ZySHS+zkecYz3zaq7/vgr1sY/AMTSIEUSIEUSIG0tMu7fijLsl3V0batciFOlCvFs4SK43hseZ7/+G5d18Hj8RibtqZp1GkhNRyATMA1uC2rqmoE5gJlhQSgCWcD6AI0dAWYJMkMiHB81YqiGPtjXKWUf8g1wOfzOQPaeNIETdOUBMpeQrgAzXD3XkKWXuQEhGGMKevCm1Y5hN2TJqDNWnThzZA7VE1ADk/CzPrpHfJ+vwdRFJEBu66bn2iYPG918ohU4zRb2XfhXi+YdXhUz/71eiWND09iPErIsgt0/CGAI8tqXeprLTqBNBUOnlqaHe2L4q8nZpBz59tqITx1aOqkowGHtfT1W99B0dzWvL7oV3uHRJjqEDUz6x7g0TBFwrGVdu/YNNcEuHoJeuqTgZ3SAG/fPvb448jsIwy3wppjv3sKT1KSiheBTq2NHxOur+5AXF8fOvfkdHyRU48wKDqZFXJZAsqyHJsu9hTAoVmDsntSg+LJuTYpWzcn4WqCcq07yoQ5vwuBSPdtJEgc/HJth05bQqaMiQ/nJwSUrRf7XQjKxday8vU6zbvuJ71KICUvKwmkQAqkQAqkQAqkQAqkQAqkQAqkhX0LMACoRR6lieJO6AAAAABJRU5ErkJggg==',
            // 14 soul shroud
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAA19JREFUeNrsm71u2zAQgMkiQJB36JLBWxGgDToEyGBnq7f0HdytS/ocLdBmS96ho7tFGQx0CJwAQTcPWfoORifVZ+vs84WURPJIJq0OEAwblsWP93+SdVmW6l+XF+o/kA6yg+wgO8gOMobsSP7YyfBDY9Itflzq1Ll5RxJqv/dGbb8/NJ1WLs579OHV+ELHgnTaVROUBeSRfOztLV/PZ/Otzx9m0+r1NhqwMyRqi8IhQIggPEAjsBSsNyTIl+FxFPNC4KvxpQisE6TWWg3ejUruezGAuWZDQJ0hQWyg0sBSoM7hnII2RVUJXwU5G0/WwcknBTkXA3ABOOBiFBAWAHBwAJwUoIRleFc8fDdPhiNR7ZlAYUOpBSWveMBvQIs8D5py5bMt62gypz4J0BJw4Jfok0pdpIVEuDpzlQLNpkkaWSkINVsw5bMZBqftignN3GbS8Dv4HWotyc0VggIsBkM9LhorFtS0qc7lnyEUlfcvd5Wa/1IPyw1aBh6dHJLmsbYmXCu97ZQxub/Ja67UhGKlkeODt5X5T/P6ZF2V4xN40KfxvNdgrilqV5dJAMBjoKFBhmvfVXzKOtHoagsoNABVCx24XmdR6RRYSmad8XBA1JgPlK2UxAYhKyRNH1JwdTVzcsgawGuVUbwDjy3oYMBp6z+uXUWywMNnPaa82XbxnwZHyzzYJtWcfv2WLk/CGIKDoqmGNrgUlI4/2o4+RZtmMJuQfNem36TveT2bJPBU4VxDwbzyw9UiztVhUKMcoyULiq4clO84nRT4Lh7Om8x31ffff/IV6Bw0xHe4YPcRAhilGEBN4tQuFPBu75V39yEKaTJbPh1wNdlNe7VJTU+qdjVFQx//xO/B6ORJmKtNmyYfdekvqTZ9qzNRTVagi5p1VPCKyMc/62a4SYqBhkJhsJn3TNcLpkfKnCl+/77q9/rY6DbdYm8CgSj7ufgZ9KxBrKc/rrlGaUDCo41JhubIKJBkt62gXKM2UCmfjJJCyJgCQPurBnpU0JkQaNKlYwlxq2h50gwKsoGFobStMpLSYpTAYwlEKH0yESjozNZ2D8T37nJSSAOoMfry230UMNRckz4CZtKqCZQMw7SET+ocz6AT2DWoafIgAZgNkgH3eY4VL1C6fxN0kM9H/gowAL65SgCwf/y4AAAAAElFTkSuQmCC',
            // 15 genesis helm
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAwtJREFUeNrsms9u00AQxr2Vq6LQSvSWHpB65hRuHMsb8Ki8ATlyoyeuVOLQ3FpBKVQFgr9tvmg8Xa9jrxuvyKxkJY3dnfnNny+TOG65XBb/+9ordmDtBGS5yUWvT57Xavp8cevGKnPnXDGbTmrGP13+cL0hCffu1bE+tayMbR2UgPTn4uqu5mcTbBkDnJ1M/POPX2+Kxfd7/xyvrYxgY7dNSAIC7vzy1r82Pdp/OA73vc8h0GA2CLi4uV/DsURxjpF8//mqtVSGWrRLQOkPYbHgr/apbAJkpLCZvgaZffPyMAtRoX+zYrKG1RkNlisjVWtCkXFECxFFZJtK5CmzqP1Cr2rY1p7kPxAMRqqjkCLEpu/iaNs1sWDB3unxgT/IR58qPx2FCb5r9X3Uk7hQRkn2oAQTxoK9qaEoYtHSE1niftiH/QZxgV3th7YPBskVhaSaoQdZprLJ2ZcwQse0EMAxHZRYtrwdIXhyL+7HYFAc+RpBNeSjcpUlyj6QCivrHvAwwEzr7DHymy59LexKQPwt1VPaAzD1QSeubItsSIQ0LKKpIw5nUhSYFfDr99/iWbnn99N+AMgPCAGx6T27IkI8CMvoyoPZnX/51gtQZrQJMKT6ut02gpRZ1JsRlufXPXhUL9GuKixBmU1tM6TKsoe7QTYA6lFLC0NfsKayxf76baHJ106za59PGnDm4vquuP75xz+evjjoJDyhbG4asJWvrlMmOwOuSgs95Es2ETDbD81QU19eqpdS1hCBSoLkNEIoPYkM2ZtZfv3BWZOgeOTRVXVTK6N8KkgJyLFwPSishgeOZG2L148KGXLWj4OEibyHxc5t9YuspAA8TCtvU/ep1H6eXU/yk8QQgNlkkiUb6bP5WJCDZVICBoQiGRCDd2j4Hi2TqhfnfaeoLN8nY1I/5o2lrdwLGfvOmd3VMshdhwwpq2UyZ0hkSw/YOos5/CYh6UZqNYGc4XE2nXyQ4DkMAENC8ulZaITL5Zclzn7iYpAGaZAGaZAGaZAGaZAGaZAGaZAGucOQ/wQYAFKtQwRx1IOxAAAAAElFTkSuQmCC',
            // 16 skull helm
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAvtJREFUeNrsmt2t4jAQhcMqVVzxnO2AZ65EGaygDgqgDlAoAyk800HyjGgjm4NyomFkm4Dzt3s9koVFEsOXM57MDMzKsoz+d/sV/QALkAEyQAbIABkgA+QPh4yH+qDtdmvNH4/H46zP9DIeCmy1WkWLxeLpeJIknJbVuY/J4XCYdf09eruDAAQYTQIKONN1nasb96WeBFyv162vr5SMiqJ4qAsRKou8YbFAV2Oz2ZRpmjZDWpZlpclM7+d5/hhYr4vvGPflnlK9y+US3W63Zk5bLpePoQ3uDDXr9UrI6aNm3DcgYQB3Op1auy737fl8Hn9PugIMDXCEB6xJPZt1oWanyYANcD6fNwpSVZvVQadR07TmoJCIfC5AGAC1cgQ1wdoeLz570gsS0U+6qjaXa8qgI9WTc+myroxpEHc1qWgDBIQGYTSFXa9X63mTSQbobjYFeRwABKJJQOm2mPtE2bgPFdveDFd6N7kEHQrYYF37kmryWgndlat2AqldTrqaBMQceWkbhbHGfr+fXqnlUpOJd1VZ/LEcThmlCajPrSJ5Ovmi2WU1UIqEAaWW42aMm/FIFVvsp6sYPucMp+SbEZZfWt4J2wLFi+PDKamDj8xqDICFAvzCfmNQwmu9/4pJBh6pqn6g122NvNpvv2uAZQWTEYznYL7b7dgZwP78nlzGI6MsQO/3e5On1srmMuKaejwCFJaN3sjS9aTJbIWyDFD6ucheDz0Ead2nnTzvPYkPfpVXoqbE0KVVm9RuMvWkDRTvccDQ57HBwuCiwk07y2293JWQXEPXfHWQYcaSqyD0VE8SCDcB6slqBa7s03T2DjwAFLBoxSSG59wTMIIPQbViev8icPGGfiyITz9TXv+qRVEfSzjQVWDPFa+2Oc7Tn/Xu6Cytk4o6ejM6EYjEbyBPlYpUelLPSa2k3rPa2HB+9Tp64Hnnep7PfSuDkaNCYYb08Z6cjfG3s1rhts8HL8DRIIe28J+BABkgA2SADJABMkAGyAD5r9hfAQYAS+f6+Tif5loAAAAASUVORK5CYII=',
            // 17 phoenix helm
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAqNJREFUeNrsmr9KA0EQxm8logbE1hcQky6CtZreQhvBR/AlLHwOn8BGC3uDtWA6I76AhU2aqIic+Y6bsBlnL7u3J/njDASjxt353fft7OyiSdM0WfRYSv5BKKRCKuRsRW0akx7v1EuV9Jvuu6H3IbtCrcokpLh+HBg+dnNzOXt/sL366/N7WyviOFcPg4yNjxelJBJBEp3nDzEZKXiCSAxQlNgkQMT9y6c41sluffSQQkGNJLuUDCZFAq4n7QqAXncHXp+lOSkaw+8Jjo8H6/paVvygMSY5aq2lfFJ7clfwpChOL99G7uBKIfHe61fyNHxxYA6a2zYD9VXUCYkAaKj/JTsSEEDP9tcnuuLitp8Bu0Dp976Q4poEOEBhCa5orH2xxosKDOL8cGMMFCqXmatQSUlRX+u67GrbEhA+SXNF6e/woEKUnLh4fa0rqc0Vs9elryoclCp+tF25dXPYMesWJUoqUZEYVe1WPVMyxOpwCl4oNM2CgldJx5PDGt4oSIkSoMu6IesLY0BNPCDaiqCi3f1U3taNBm8lqV1I7CpIgDYobfLkgBDQRkkFvddk0VqVKi91SFKnZP8spFJSweIq+uZe+hSCCTCZvYGHAJKyvpaNUTPqFCJVXF/AECXx+Z71MEPdF33Ugl1tNclSvNHnRScE1F73UztPTirtPEn6Hl+LbNhjD28mDs1UOamq0kZeFE8BIH++T/oA8taOAIYFqh07/nD93039jgfWe+1//+pyqgCclzuejt7WLQok9raYlyo5DUhefBYSkk4gquS8QtptWH432p4FyMr3yar6zZlREhdJUu+ZH2zbVTcCodce0TcD/IbA0cp1yp4BXXOVGcvoP0YopEIqpEIqpEIqpEIqpEIqpEIqpEIqpELOffwIMABPLOUxc/z/CAAAAABJRU5ErkJggg=='
            // END HEADGEAR
        ];
        return string(abi.encodePacked(
            '%253Cimage href=\'data:image/png;base64,',
            HEADGEAR[(lgAssetId == 1 ? (lgAssetId + genderId) : lgAssetId)],
            '\'/%253E'
        ));
    }

    /**
    * @notice renders the ear modifier for the ranger class
    * @param headgearId the id of the headgear item
    * @return string of svg
    */
    function renderEarMod(uint8 headgearId)
        external
        pure
        returns (string memory)
    {
        if(headgearId == 0 || headgearId == 1 || headgearId == 4 || headgearId == 5 || headgearId == 10 || headgearId == 11 || headgearId == 14){
            return '%253Cg%253E%253Cpath d=\'M15,20h1v2h1v1h1v1h1v2h1v3h-1v-1h-1v-1h-1v1h-2z\' fill=\'var(--dms)\'/%253E%253Cpath d=\'M15,20h1v2h1v1h1v1h1v2h1v2h-1v-2h-1v-2h-1v-1h-1v5h-1z\' fill=\'var(--dmb5)\'/%253E%253Cpath d=\'M15,20h1v2h1v1h1v1h1v2h1v3h-1v-1h-1v-1h-1v-1h1v-1h-1v-1h-1v4h-1z\' fill=\'var(--dmb15)\'/%253E%253C/g%253E';
        }
        return '';
    }

    /**
    * @notice return skintone color name
    * @param colorId colorId of skintone
    * @return string of quotation mark-wrapped skintone value
    */
    function skintoneName(uint256 colorId)
        external
        pure
        returns (string memory)
    {
        // Array of potential color values
        string[16] memory SKINTONE_COLORS = [
            '"Porcelain"', // 0
            '"Cream"',     // 1
            '"Sienna"',    // 2
            '"Sand"',      // 3
            '"Beige"',     // 4
            '"Honey"',     // 5
            '"Almond"',    // 6
            '"Bronze"',    // 7
            '"Espresso"',  // 8
            '"Ebony"',     // 9
            '"Demonic"',   // 10
            '"Orc"',       // 11
            '"Djinn"',     // 12
            '"Spectre"',   // 13
            '"Mystic"',    // 14
            '"Golem"'      // 15
        ];
        return SKINTONE_COLORS[colorId];
    }

    /**
    * @notice return hair color name
    * @param colorId colorId of hair color
    * @return string of quotation mark-wrapped hair color value
    */
    function hairColorName(uint256 colorId)
        external
        pure
        returns (string memory)
    {
        // Array of potential color values
        string[8] memory HAIR_COLORS = [
            '"Light Brown"',  // 0
            '"Dark Brown"',   // 1
            '"Dirty Blonde"', // 2
            '"Blonde"',       // 3
            '"Gray"',         // 4
            '"Gray-Brown"',   // 5
            '"Black"',        // 6
            '"Red"'           // 7

        ];
        return HAIR_COLORS[colorId];
    }

    /**
    * @notice return eye color name
    * @param colorId colorId of eyes
    * @return string of quotation mark-wrapped eye color value
    */
    function eyeColorName(uint256 colorId)
        external
        pure
        returns (string memory)
    {
        // Array of potential color values
        string[13] memory EYE_COLORS = [
            '"Black"',       // 0
            '"Gray"',        // 1
            '"Light Green"', // 2
            '"Green"',       // 3
            '"Amber"',       // 4
            '"Light Brown"', // 5
            '"Brown"',       // 6
            '"Light Blue"',  // 7
            '"Blue"',        // 8
            '"Orange"',      // 9
            '"Purple"',      // 10
            '"Red"',         // 11
            '"Transparent"'  // 12
        ];
        return EYE_COLORS[colorId];
    }

    /**
    * @notice return hair type name
    * @param assetId assetId of hair
    * @return string of quotation mark-wrapped hair type value
    */
    function hairTypeName(uint256 assetId)
        external
        pure
        returns (string memory)
    {
        // Array of potential color values
        string[8] memory HAIR_TYPES = [
            '"Bald"',    // 0
            '"Buzzed"',  // 1
            '"Spiked"',  // 2
            '"Mohawk"',  // 3
            '"Short"',   // 4
            '"Braided"', // 5
            '"Long"',    // 6
            '"Ponytail"' // 7
        ];
        return HAIR_TYPES[assetId];
    }

    /**
    * @notice return eye type name
    * @param assetId assetId of eyes
    * @return string of quotation mark-wrapped eye type value
    */
    function eyeTypeName(uint256 assetId)
        external
        pure
        returns (string memory)
    {
        // Array of potential color values
        string[4] memory EYE_TYPES = [
            '"Normal"',   // 0
            '"Angry"',    // 1
            '"Sad"',      // 2
            '"Surprised"' // 3
        ];
        return EYE_TYPES[assetId];
    }

    /**
    * @notice return mouth type name
    * @param assetId assetId of mouth
    * @return string of quotation mark-wrapped mouth type value
    */
    function mouthTypeName(uint256 assetId)
        external
        pure
        returns (string memory)
    {
        // Array of potential color values
        string[8] memory MOUTH_TYPES = [
            '"Toothy Smile"',      // 0
            '"Small Smile"',       // 1
            '"Smile"',             // 2
            '"Frown"',             // 3
            '"Stoic"',             // 4
            '"Sewn"',              // 5
            '"Small Smile Fangs"', // 6
            '"Stoic Fangs"'        // 7
        ];
        return MOUTH_TYPES[assetId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library AssetRenderer3 {

    /**
    * @notice render hair asset
    * @param lgHairAssetId the lgHairAssetId of the gear item
    * @param lgHeadgearAssetId the large headgear asset id of the gear item
    * @return string of svg
    */
    function renderHair(uint256 lgHairAssetId, uint256 lgHeadgearAssetId)
        external
        pure
        returns (string memory)
    {
        string[11] memory HAIR = [
            // START HAIR
            // 0 bald
            '%253C/g%253E',
            // 1 buzzed
            '%253Cpath d=\'M26,10h7v1h3v1h2v1h1v1h1v1h1v1h1v2h1v6h-1v-3h-1v-2h-2v-1h-11v1h-2v1h-1v1h-1v3h-1v1h-1v2h-1v1h-1v1h-1v-2h-2v1h-2v-7h1v-3h1v-2h1v-1h1v-1h1v-1h2v-1h1v-1h3z\' fill=\'var(--dmh)\'/%253E%253Cimage href=\'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAZZJREFUeNrs2dGtgyAUBmBsXOKu0BF8MnEKhvGJYZzCxCdH6Ap3DCs355i/NN7bi1Bt+5MYEgT0K3BQW0zTZN49ncwHJCKJJJJIIokkcj2Vz7pQURT9L6ebnE9eRdbOb2Gj5BcoO0teacF8P83LIAU4QpHHdfNh52t2Ugeb1H5EFZwSmxwJozcGo/YD9LleM0BqsjLCVappnBS5Mno6LRFsdDShbdidSwU9ZQTimrsDzvWttLNSthzQxvfXH2ILWQHe4aC+VSiCgym7jKjvf2VqP2+6AvLyR9UzRtIHkoNgFD1tNyMB6PMvDDAaSec6DnDuH923EMSq6IiLayHmEFwNU8xK+ZJDndjk2/fR95gI6TIC90UCsH4UuOVasW1TRNdegkMXRk05PyDwld9CdMQU9i3BxuwNzPGqVcN+VulaTQRsjoLUB+1WgMM7vTS3sKeZcC2mSFtmQ5kI2MDavNnwj/A3RLnx121W3h6GowCzfxnghywiiSSSSCKJJJJIIokkkkgiiSSSSCKJJJJIIokkcud0FWAAiOX1bCeUzIsAAAAASUVORK5CYII=\'/%253E%253C/g%253E',
            // 2 spiked
            '%253Cpath d=\'M13,13h4v-1h1v-2h1v-1h2v-1h1v1h1v1h1v-1h3v-1h2v-1h1v2h1v1h2v-1h1v-2h1v1h2v-1h1v1h1v1h4v-1h1v3h1v1h2v1h-1v1h-1v1h-1v1h-1v6h-1v-1h-1v-2h-13v1h-1v1h-1v3h-1v1h-1v1h-2v1h-1v1h-1v-1h-1v-1h-2v1h-1v1h-1v-9h-1v-4h-1z\' fill=\'var(--dmh)\'/%253E%253Cimage href=\'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAkFJREFUeNrsmcuNgzAQhk2UJtICJXCy5Cq4bxs5uY29U4UlTimBFigja0cz0b+zZhMMJLvJWEIYg/F88/KEVOfz2bx625k3aAqpkAqpkO8BWVVViMfkWO7+n4OcEpLGwy9T+b6j/l3vvdX2a8OlcywwHAuLUGkcnmOYyzXN8fFyiIcF6G9rlBQv+0KYHwuyoNRvAeaUBI/3OhrzNMWjAmhOuj4wfGyfMC/d/yiRd7+BqyZhahaSzgjYEHhqLimKFNTFs6VnLVm0g/c1oDg3x6JVifmlJWlhBhrBEkeYxi7Yi2tHz3myJI4hoOM1MSy2tGRAWHYr0jovPIBQHGudeA8De4xR6vuMojys6R7hruxqLQAaIRgLdRRzbQbUASj3e6GAZi7g1eXmHqBtFLYF7XPfZjKjnRDFwnwr5lvhzrNkXxKTnDmlmx1IgA7TP8SvEYoZpYtTqzE0yBtcyVayRjGAroOALUFcLJEypwD0AjAAGLq4y3nfLKOsYMmpNsC2gLEXSrV5bzZdNfHcAB0B0GSy5r2tX6KYLYoBjE9HMTaCoD5ao1+z+H50gR4y8VNTnF4BS2Kq1E0XWZL2RyNibEqQGmMyV/duDbpbkARMpiIxsBUMU+Xgo9taMcmgp4zbNpxsnvWNd+3E02T6HraP/wtJP3gxPhvYKp4KWFy7Qg0b5DsyNe3idZYe1ZI4mfhCYKX1nv1/S6V/+CikQiqkQiqkQiqkQiqkQiqkQiqkQiqkQiqkQiqkQiqkQirkC7cvAQYAWS7RDIfHvMcAAAAASUVORK5CYII=\'/%253E%253C/g%253E',
            // 3 mohawk
            '%253Cpath d=\'M37,7h4v2h-1v1h-1v1h-1v1h-1v3h-1v1h-1v1h-1v-1h-1v-1h-13v1h-1v1h-2v-4h1v-2h1v-1h1v-1h3v-1h14z\' fill=\'var(--dmh)\'/%253E%253Cimage href=\'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAARNJREFUeNrs190NgjAQwHFKWIIFXIRHJ2AEX53H907AI4u4AGPUq6GmVCAI5UP9X0L4CK33y5VDlDEm+fVIkz8IkCBBgtw8srV/QCnVOZ/yypIxdTCmOCwyTLYPPRA3gWm59yrH58NVMoBV3nHjVUZPmMcBi8U5xfzH0wKrkVua8EIIljlK2eUWaJeprfzSHLONgbkH1WHyfcBv6665B7VRDjynnQrGWGnpRlX0oa+9rVxbvTnNadfuOrcbaoeP/WWUrQC8SJL3T1dCW73n+BjN5u3lvHSTsMu1nvsMeXOc3PgYeblN8dEMEiRIkCBBggQJEiRIkCBBggQJEiRIkCBBggQJEiRIkCBBggQJEuTu8RBgAGYWyYhxyBs+AAAAAElFTkSuQmCC\'/%253E%253C/g%253E',
            // 4 short
            '%253Cpath d=\'M26,10h4v1h3v1h1v-1h4v1h1v1h2v1h1v3h1v7h-1v-3h-1v-2h-2v-1h-1v-2h-2v1h-1v1h-1v1h-2v1h-1v1h-1v1h-2v1h-2v1h-1v1h-1v1h-2v1h-1v1h-1v-1h-1v-1h-2v1h-1v1h-1v-8h1v-4h1v-2h1v-1h2v-1h2v-1h4zM15,34h1v1h1v1h1v1h1v4h-1v-2h-1v-2h-1v-2h-1z\' fill=\'var(--dmh)\'/%253E%253Cimage href=\'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAe9JREFUeNrsmk1uwyAQhe0ql+hVWFli2RN4n2t45WWlnqD7nKBLJFY+Qq6QY7hQDdVkAm78k0CTNxJSbMDm4w3DYKUex7F6dHupnsAACUhAAhKQgARk2nZrOtd1Pae5Edd67vuWZme7tbOUerGbACPaaXevYXBG1F20XziZl2NZk7v6l8v+bLCfru4woXzDFFWuDK50/nmuXe/vBdDQL5uSEbghUtfSTw5tRTMP2ru2Rw/rSsueqbMqyVxvEOvPQ/R03UUUl6oGRauYqr4+u5ICUFMxEcXOXI9grVA0qKpK2UK4ikYEFvuHJ7QE6935NcBRUTHXL2Gf5IAfNPgfd/SRlbsoAR7Yet1Tf5uYHJNln5wwD/hOgabhgSZAMcA91ffiGT0FoLzJQMLeXPly5cQAg/2qxwB7PglsrVp23+SElFFVEWBw3SPBdrTmTpQQVDHAiFmKsFmTAb43pgKFEq7YMXe0U9lTSDYI0vAsKAdklUgEOLgSa89em5cWk/FE3LYSgLPhSjxqKaFeEYC3iK5Xuee9P2hvAslOC6YU9bZ2Vy1giwK81Xmy2RpubXTd6qh1F1s6VnytAyQgHwvSPAOk/g+gW7mreXRIXTooAs+S/BVKZrIaf1YCJCABCUhAAhKQgAQkIAEJSEAusG8BBgC8BuDSh5XbAAAAAABJRU5ErkJggg==\'/%253E%253C/g%253E',
            // 5 braided
            '%253Cpath d=\'M26,10h4v1h3v1h1v-1h4v1h1v1h2v1h1v3h1v7h-1v-3h-1v-2h-2v-1h-1v-2h-2v1h-1v1h-1v1h-2v1h-1v1h-1v1h-2v1h-2v1h-1v1h-1v1h-2v1h-1v1h-1v-1h-1v-1h-2v1h-1v1h-1v6h1v2h-1v3h1v2h1v1h1v4h1v2h1v2h1v5h-1v1h-1v-1h-1v-2h-1v-1h-1v-2h-1v-1h-1v-1h-1v-2h-1v-3h-1v-2h-1v-2h-1v-5h1v-1h1v-5h1v-1h1v-2h1v-2h1v-3h1v-4h1v-2h1v-1h2v-1h2v-1h4z\' fill=\'var(--dmh)\'/%253E%253Cimage href=\'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAutJREFUeNrsmk1uqzAUhU2UHTypUrfADp5HSFkFsw66DUZsI/OswpJHWUK2UKmbSG3p3vbkPtNgYgL2w5JFCSb4y7l/Nq2u16sqve3Uf9A2yA1yg9wgN8gNcoMcbvsxg6qqSvEsI84PsV8wtTrbz/UA98MYcf/BfdYAnBHX/hmf6keuxkzeP2QsJEz26O45/WIRDSiqXT+73vnnuHG9/4xB+b7ZlYyAOweutfQnQlsxzIP2buzFw7rewnceFlWSfmUj4AxB9HTeyfsDqrKiKqSqv764kgLwQN0EFLsxPYK1QlFWVa8lhaCKRgQWi8oFOpuxP74yHHUdMv015EkE7GjybI6NGNuSj/KYd7rfDqhvZs2TE5oHPBJEIwINBqGW4BT4r4Lz7mnFQGRjM/u4ox4D9gPR1sLRLAZJIR795gXOveldCLYjn0Pw3wC/QSnCLlcMiNw4FCi0MMUOzNGOqbQ4TWEVtASkGigEEFwL37NjJohKPj1P3gHU4jMdC5eyTVYyAMlQ3i8/B8w1GjCFkrupKpJ/hMzzU1YuSymYOoXI5dMq4G7M4V7HcQRiCOLGZN/+/uHroQpn8vxi5hqcfwwkAbQA+g0HY5vUIjwKWcU4MwWbo6g11dwvjRYJPCn2XXIIPCcq0crZrQu09UTOlObKuZE2py4qo7YbC+gDDqzklYywRZgrby/SxpIq0ie9imCqJ7GfU4ZPulaTuZ5UZi02utZU8dS55MiopZYwz57M9n3qan3NFQ9H10tOZhtbu7KCNRz13Go+qmTckuVniSWVNVNXCGNXQY+sQmLNFV/KtLnkyn2s6mQ6HGFrDkYx7zDXnCdlKulUom381UFSkNGkJu8CHNdcx47+x4iAKdZ07GCnIF8lA4D8/rAmNb2q54G92CT7PI/4+9RFswUV+aXOB0TefIsBmZxJRX4Xye0ppd7s0RUSrRX+WZeUQob8U5UKaQG0WEgMRGVCQuBiNftE/3C4bHTNrX0JMADsD3hOWpkfdAAAAABJRU5ErkJggg==\'/%253E%253C/g%253E',
            // 6 long - NEEDS MASK
            '%253Cpath d=\'M26,10h4v1h3v1h1v-1h4v1h1v1h2v1h1v3h1v7h-1v-3h-1v-2h-2v-1h-1v-2h-2v1h-1v1h-1v1h-2v1h-1v1h-1v1h-2v1h-2v1h-1v1h-1v1h-2v1h-1v1h-1v-1h-1v-1h-2v1h-1v1h-1v6h1v1h1v1h1v1h1v12h-14v-7h1v-3h1v-2h1v-1h1v-3h1v-4h1v-3h1v-3h1v-1h1v-1h1v-2h1v-3h1v-2h1v-1h2v-1h2v-1h4zM37,29h7v3h1v10h1v4h1v3h1v2h-11z\' fill=\'var(--dmh)\'/%253E%253Cimage href=\'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAvBJREFUeNrsms2NpDAQhQ0iiU6BEDhZchTcJw1OpDF3orDEiRCcQofRi1fl3aK2oDG2gZ61JURDM9Af79WPYYrX6yV++ijFfzAyZIbMkBkyQ2bIDLk+Km5nURQprqXJtvI9wdHurOD+0EKGtnvzOTT5gWreJxFcQ7775/hYdzc6JPqx3/M5hg2HSKSoBZ7mpbPXnY/r7b5YoFW0u/UXbmK+a+Ejhh7JYRa0n481FnZeWnfOUNhgJUEdTeA0QPSw3dHzMaoqZOGoqlaJEoyCRTOKLZIIwI5EUadqc5cSglXUKLEsAC0Mszgb2/XDwcHScNa/Q53EgB38eGdHSY5tIUbdMV/w9yOnPs2+V9tVAOA3QEiSaHASagFOoPgVaLu7PLvC3Z2YLGn3Pd+o5wD7lWw7orW+DJIZOI6s9QzAdhBzGHwL8A8oZNhrmgFGxbVE0RArdsiO495Wzl7vaBmpItp0S1lcA9+pd06DvqUiAbR2rHEfSj5PjJqnwcWISbPx3bRi18OAV3U8NaqJDROXl9kzCBJZ1SBIgWqivoM9Y3c8DmqwcQyWuhXgUbualaItfErDmaPwmFJRqy4a8JgvjmB6xZakIwnI164dmfhGB7xLTLZ4xvEJr/7KnfbBM/ghtGEOGNORKddeJTUzFRIwe7+9kkeyqyTlI24mTHDTfGNSkfVv2BPV1EkgIQZ6mA8KtFaoT9V3tmu5ZRsEqMhcUMd8BnPASXEgmdLwRM9mFLHQ9JF2RSpiBTG8RtaNpmKKuuvdDKAn5rh3VScpOaaCHFdKiGIKdUpAE1VJJuHItYuCvcwJsfjEXY/PDS097t7IfB7gUX+dOtnMN3NMGZNSLJ9+K6ZZTzkeoTH/DrKGC7RkutWS5zwmoWVr6Krk0dgsdwY8fjHTxkgGnnZVSM3BdVl743JvCdlly8g1ziC7GoCVZ02azxiGrOuQtq7a6hFDMloC6AfZNmL50vfjlNyC9c7oRf737AyZITNkhkwwfgkwAOKsJLPTk5emAAAAAElFTkSuQmCC\'/%253E%253C/g%253E',
            // 7 ponytail
            '%253Cpath d=\'M26,10h4v1h3v1h1v-1h4v1h1v1h2v1h1v3h1v7h-1v-3h-1v-2h-2v-1h-1v-2h-2v1h-1v1h-1v1h-2v1h-1v1h-1v1h-2v1h-2v1h-1v1h-1v1h-2v1h-1v1h-1v-1h-1v-1h-2v1h-1v1h-1v4h-1v3h-1v2h-1v4h-1v2h-1v2h-1v1h-1v1h-2v1h-2v-10h1v-3h1v-2h1v-1h1v-1h1v-1h1v-1h1v-1h1v-1h1v-2h1v-2h1v-3h1v-4h1v-2h1v-1h2v-1h2v-1h4z\' fill=\'var(--dmh)\'/%253E%253Cimage href=\'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAlxJREFUeNrsmkGOgyAUhrHxDJPMFTwCKxNO4X6uwcpruJ9TkLDyCL3CJL1EB5LH5PUNVK1YCoWEtCqCn//P42nbXK9XVno5sTcoFbJCVsgKWSErZIUMl5buaJrmqLEU2RZbO3g0O2tjdkZuliJ9CrOvR3CKHPvXPtaNbyiQ7XAPJLrYyfTzfcclPVKUmzqbKu3Ypt1o9zlQd15UJXfCzZ5jA3zF0Jo0s6CjaXu2sKYOqE+RVEm4y4rAKYAYYVv6xiGqOkWZT1V7PLmSBFBAVR7FbqwHsJoo6lTlr7KEYBUVCSwaK+epzsb289PBQeU+67/COokBJVy8s2NP2g4wR12bLzhfB9RX0dbJSMUCTgDRk0CDg9AAcAzNX4a25SHJQITibPazoJ4DHAPRVqNPlQwSQjyeNx9o21rvDLAS5hwGvwf4BwoRNl0yQNbGUKDgxIoS2VGvSeXcMoWzoBSQLJAIYHBO5p5eMwZW8unr5AIgJ/v4VriY5WElPZAOys7LS8CumwFjKHnaoeIYsOeFZi6pFIy6hKCnBfUK9txtV09EvUmckcpRAGPYdROkZx4KOjg8GEdT76nRNRBofBeV3J4PQYYAc/lF7BRLwWwhPbnp7HvRlC1kAFAVpyRJ0SRE0zk3yHYho9HwaETfwYhSlNSeh95i7arRciFzUzEEadWaAEqTTCar9XFJyY68clC5Aq6xq1NvytGmayAHAsZzBV1SkgNsV2pa15Wg4hIkh7mYtYpr7NphFXP9s6HvzcDu3/aPKke8GRCskNLU/7tWyApZIStkhayQ7w35K8AAbRsZgzu5pK4AAAAASUVORK5CYII=\'/%253E%253C/g%253E',
            // 8 MODIFIED braided (helmeted)
            '%253Cpath d=\'M18,39h1v6h-1v1h-1v4h1v2h1v3h1v2h-4v-2h-1v-1h-1v-2h-1v-2h-1v-3h1v-2h1v-2h1v-1h1v-1h1v-1h1z\' fill=\'var(--dmh)\'/%253E%253Cimage href=\'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAPtJREFUeNrs2ssJwzAMgOG4W3SVnAqeosP0lDV6zxSBnjpCVsgYrgQy+FawW1DV3yAaXwIfeqBAUyllin5O0x8ckCBBggQJEiRIkCBBggQJEiRIkCBBggQJEiRIkCBBggQJEiRIkO9OSmmTiItUoPw8w2bSO3AYacAlbE8a8C6RJbawmSylrM119opMPX8gbPpwV6jds8FDZXKXcA/sQipKMNmu16Z0Y/WkQOtEPbwDh8rVhk6OutYpbJZsaqnedABZX4bN5G8c7aeesAVgaQbQ1vuub8cnFnQFrlHLNduWo8BL5O/JureetXS9DqDR3bU+HvL88JrJlwADAD8o5HEwnUYAAAAAAElFTkSuQmCC\'/%253E%253C/g%253E',
            // 9 MODIFIED long (helmeted) - NEEDS MASK
            '%253Cpath d=\'M16,35h1v1h1v1h1v10h-7v-2h1v-2h1v-1h1v-3h1zM37,40h5v4h1v4h1v2h-7z\' fill=\'var(--dmh)\'/%253E%253Cimage href=\'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAR9JREFUeNrs2sENgjAUgGFKXMBjV3AETySdgjW8e2IYpjBhG8bANnk1jZqItoUK/0saDQd4X99rgQQ1TVO19airHQRIkCBBggQJEiRIkCBBggQJEiRIkCBBggQJEiRIkCBBgiwJqZS65UjMnvcxiqikTaTdQ7v2JUPr2JaSaOwYU7SWD/dVih9vrrdoJd167OT/sIfdtcmVZOzmlgppfItlAHarVVJm1yWg5ZDeVLsGQCOHrpnatJFzH9du19H/ptxdn+LiJvbX5VBHVNFXUMvFhwxVTHLOQ8R9zCfQZ2rTcNfWi7arxZkA+HLz/vDQ8G20su6jJlKV+L1rOCkuP3lkPNlxdpNcHHJuFefkIZuP2UQleWkGCRIkyH+IuwADANsRUZnVIli4AAAAAElFTkSuQmCC\'/%253E%253C/g%253E',
            // 10 MODIFIED ponytail - NEEDS MASK
            '%253Cpath d=\'M16,35h1v1h1v1h1v10h-7v-5h1v-3h1v-1h1v-2h1z\' fill=\'var(--dmh)\'/%253E%253Cimage href=\'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAALlJREFUeNrs2rENwjAQBdAYsRmrsBtTWHKVEajYxaQBRRYNcYF9vJNSpLClp2/7mku11iV6nZY/KEhISEhISEhISEhISEhISEhISEhISEhISEhISEjIXyJTSu1/Hh2Zvp0ZaJBv4LbPJfxxHTnRHmQOeydnAx5CfrjDa/QWss6Q6pEWknfp3bdky+hp9iT52L5r2zcjPjyv3phH7pPnjrW33UNUoh7XMsuEZTIKCgkJCQkJCRm+ngIMABnbKuzQgeCHAAAAAElFTkSuQmCC\'/%253E%253C/g%253E'
            // END HAIR
        ];
        if(lgHairAssetId == 0 || lgHeadgearAssetId < 3){
            return '%253C/g%253E';
        } else if(lgHairAssetId > 4 && lgHeadgearAssetId > 8){
            return HAIR[lgHairAssetId + 3];
        } else {
            return HAIR[lgHairAssetId];
        }
    }

    /**
    * @notice render an armor asset
    * @param lgAssetId the large asset id of the gear item
    * @return string of base64-encoded image
    */
    function renderArmor(uint256 lgAssetId)
        external
        pure
        returns (string memory)
    {
        string[17] memory ARMOR = [
            // 0 cotton shirt
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAYlJREFUeNrs2j1SwzAQBWDL4wNAQ28ahooOSs5ADuAU9NQcgZqeAg4AZ6AkHRVDlZ4GbiBYMeu8mLVsocB44G0jZ2PJ+0U/buK898Vfj7L4B0EkkUQSSSSRRBJJJJFEEkkkkUQSSSSRRBJJJJFEEkkkkUQSSSSRRBJJJJFEEkkkkb+JnM92vXNu0sgqByftwf5W0RS1QN1U/3GZXBjiMB6f3kJ7c7ecHHZUQQqzcKv89ifydtnmcsH63NxxzM6I6oMpajWTryF3fLjT5k7PH770GyoYn93M6jBu7ipZ64RLUQaO4RCjcXn9PHiPBce4ujhqr+8XLwHZ3RKpKyXcFNtnmsOZs4q3QorEwH7yg5zN99Yw3c8SmNMVk3oOuOak9n37TAeSZZMKHIuWnLaIUJzVPza7Froa2m84SA6w218Lxpxcx56B3ynU2lrySvtYnS226jtIcPPLiYmzucnQmUwNrRdntXtQ6vu7jAF/MrS47wCxj9Sus2lhZTuWY4G5S3XTMbYegb4LMAA6uttKyO8nkgAAAABJRU5ErkJggg==',
            // 1 thick vest
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAZ1JREFUeNrs2rFKA0EQBuDdI4VaeYHYaCNYxSIgouA7WMZOO0ufI72WYqWdbyFoIXKlNopiqaC+wZo5nLvd2Y25ywY59R84lhy7e/PtzIUU0cYY9dcjUf8ggAQSSCCBBBJIIIEEEkgggQQSSCCBBBJIIIEEEkgggQQSSCCBBBJIIIEEEkgggQTyJ5HdlWWjtW40shWDo7HTTmkgqG7qPy5rJyZwRby+vefj3cNT47CVEmJYCCeDsdMA83Nj9wku3tvZNDfZi7JhlLwN7LTnBe7Du3d7/+jtPS7h0IHGdomziHA09rpL6uQsKx5CyROCoRJTJ0JwgfQOL9QlddD5JBtnxyioTGSSkJUPdYKE2s/mXKpg9W5/w0hcCMoJUCViq2mj5Pjd/FHQ9bUFZ+7p+bWDboWAvdVF61M29qRjouqe5UGk+UETlNdeXD6rg/2tcnJfmWF3FtjEhvFlx+Fg23kXaHP5bsRWdJID4XV0b252xi3SsHB0UZfSD5XEr1y1hOokN41K2vP5276Epuro+MrvyC9oUhX4W4OgnwIMAOZZ5/3FwvtMAAAAAElFTkSuQmCC',
            // 2 leather chestplate
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAa5JREFUeNrs2r9Lw0AUB/BLiEgMCIqtoA4SnSqlY110cNLJ0T9AJwX/GEEn/QP8C9xcnDpncDI4iFAiCkIponDmBZPeXc/84FCCft9y/XHv8j69d+kSi3PO/nrY7B8EkEACCSSQQAIJJJBAAgkkkEACCSSQQAIJJJBAAgkkkEACCSSQQAIJJJBAAgkkkED+JrLVnOKWZdUa6ZjgaGx4tIRLUKuuT1xWLkzGjSIafCTjbTSsHbZUQSlMh0vDn5lMxt7DIPvMFJxe13QdbfLm+ip/Ch9ZHqzhTSg7+Z5Al7+wFJfB81heUcHiD9pd8lj48mbcJVIS4Wjc3e6wi7OrXFx73h377jp8LZyjg4ux157NXt/HQEKqR6JqpySTRJwYIlTcOV3xugj6Q+l92TwRt+VPS2tRx1S9D1gb3RWu4lRoq+lWLrQMWi1ajBSny1ehc/6CNO+mdyehHR2ws7aovbAJ8Pt8t3J+0B9BqdOi+P6xf7gjTuVxd2ZYpwh2cnrAjo/Opd2sQ6THR9cJwsYl/992HrCuIXYEYWk36VjpsHQc7bJA01b9SWheEPRTgAEA57jAd/wBs+kAAAAASUVORK5CYII=',
            // 3 rusty chainmail
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAehJREFUeNrs2s1OAjEQB/B21WA0KH6ciAcw8gAa4hmP+hS+pVfPRn0BTPRgSDwoItFIiK5McZahO/shmxii/yZk3KXtzq/TLRdtGIbmr7fA/IMGJJBAAgkkkEACCSSQQAIJJJBAAgkkkEACCSSQQAIJJJBAAgkkkEACCSSQQAIJJJC/iTzaXQuttXONXCyCo1irlEyrbghq5/U/Ln+cmMTJ9hAMXTy76s0dNldCDNNw3Mo7451/0xlE94qC+bnnt/1C86iDJSoNpkEb1eUJ8rIX65MFP2lWoi/3qiXTv/80d8/jhZsVOzVIbkWaWMPVNib3NhsL5qn9YR5Xhy4Zvw99H0MqcNmOm+vR3+3O+9S8jOWWF+06Jb1nEqrhKF5fvLkKUjJ+1MblaRJH4/l5LqfuIIbOwtpWvRymbUcfKoGzxNj83UHi1t96XVLHa9C0CgdJW5I/2irTQyjK67TE5TVXk+PB4Yp7Dkc+wPxx/DwaJ/OKCjCK/KHCyd9ve7q/HfrbKr4yL24wry69gxzl9qRE+R2VVZD9tOr4/XiepPH+AiadH3SfqhpkAbXGJyhFHsuRV9+PMqm06vu5aP0ILfvzQRnbkd9VDfICuVpaFWR1qAp0zdWQ1zLSfP7hpVWZ72vz5GkE/RJgAPKbdC9Pa9uUAAAAAElFTkSuQmCC',
            // 4 longcoat
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAbRJREFUeNrs2stLw0AQBvBsKFSsilTaKlYFvXjw4NH//+SxBz2JHnwgtVhErdfoLHxhsk7XrBEp+g2ENN1H5revXuqKosj+euTZPwgiiSSSSCKJJJJIIokkkkgiiSSSSCKJJJJIIokkkkgiiSSSSCKJJJJIIokkkkgiifxN5HCzXzjnFhrZaoKT+2pnOdse9ATqFvUfl8mJAQcg4mX25u9348nCYWslFIPhub/R9ffL69uyvCkY723aj9lYo0IYYm2lA0hZR6C97npZ53R09qndVwnrdx/sDrOHx2njVVJppPeZniULt7M1KL+bTJ/8DKK+VScG13FyfFTpV5B6O6QMWAWpcTo0FInPSx5QHR8HUuVZtzu/uPL9h7MlSI2T1YEBlByeX2fJ54CTk9GaMd2RTtYCWmC9PwUiIYljsJbabV+OMnwGCDi0l21wcz/2zxY0NsPucH+vmLckseeArAOsM8N6zyFCsC7X+1xCsCE0dtK3LFi45DQ0NSRBuTC7GmV9r0EhzpoIjQ0PSvx+5zHgTwawuGKQsE4YekVJ7jgoLaxA87rA7yzVlAFIjbr5CPRdgAEASZD7DWDIBSwAAAAASUVORK5CYII=',
            // 5 chainmail
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAbxJREFUeNrsmj2Og0AMhRm0DXdISVruEc6QK3AruEJyD1pSUqelZOORHnIc85NFWkW7z1JkZmLP+ON5Jk3COI7JX7c0+QdGSEISkpCEJCQhCUlIQhKSkIQkJCEJSUhCEpKQhCQkIQlJSEISkpCEJCQhCUlIQhKSkIQk5G9ClmU5hhA+GvJrD5z4PM+T0+kkoOFT/3H5dmEaTtv9fo++aZqPg91UEMA8ONjhcIi+bdtpbi8w9r1er7vWcZM11BKYB1oUxTSu6/olZg38fD5PX8pafd8nt9st2QP7lKRbURb24I7H49Nz13XJMAyxGBujY5fADeT0LF2h1wUsbCt0DJo7ZxrUgxN/uVyiglKM9V7eFtNwkoP9xOA19BpskJtxqR0tqAb8ibfmzaH1syxz8z3QJYXTuZbEx3vLsgkuGIyXCtdj28qPLorP8LjAbB72s3WhfvH4iHD69ztUVTWutdLjzcRkvF05g/C6PaVQnFGtgo7z1LFxWGcu377AuftD5kXV9J2zom89eKuMbSlP1SX1bS1enEDreFyU1qBquhUQankqaHVEBRlDDT3WXtazl5enMua9dbaYgH4LMADf73a61aRdeAAAAABJRU5ErkJggg==',
            // 6 bronze chestplate
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAYtJREFUeNrs2rFOwzAQBmA7KqJkICsvUAFbkJgrRgQMdOFdkBBDBS/DAgPqjDozdKOoL8BahlLEYOqoZ51TJ3VkhCz4b0nqxJf75HOyVCqlxF+PRPyDABJIIIEEEkgggQQSSCCBBBJIIIEEEkgggQQSSCCBBBJIIIEEEkgggQQSSCCBBBLI30T2DlIlpYwa2QrB6eP+zoYQudBQGes/LhsXZuF4Syx74nbwHh3WqyCCuXAUR7vt4jiczM1YKJie+zD6CMrjnMxRVbC90tj47auAdjubZuxmMF2Ztw5+dZqZi91OWzy9zsXLIncI1prEW1EnrsNdHKYr1/qP07X3uOAW8iQz58PJZ4GkICyFL7q4qWqfcShfOVfxrrh7nlm/fedx3PVZZuUaM6jvCsvzfEtV7TNK1MvTxoX6oMtF8yCca74LWrfC8vJ4W9Xtt/vRzCBDgD8ZGluG8oUqr3Cr6kVi9ukCyKGxBNXr6gQDXn6/kzpgrME7StdOL0oXVm/HxBcYS6s2rUdDvwUYAOkWv84DyblmAAAAAElFTkSuQmCC',
            // 7 blessed armor
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAadJREFUeNrs2r9Lw0AUB/B3pWjRoVsHwTHZ3Wvp1CH5Hxz8C7JWKrSo5L9w8H8wQ6ei4uoeR8GhoyBEl9NLSXJ3OZqEiBz6fcvlcj/yPum7dinjnNNfjw79gwASSCCBBBJIIIEEEkgggQQSSCCBBBJIIIEEEkgggQQSSCCBBBJIIIEEEkgggQQSyN9Ezvw+Z4xZjey2wYl25PSIPBJQZus/LhsnpuCkeNxbp+0iJOuwtRLKYCZcFjuTDXL1UNxrC86eexW9tdrHuNj3fX5ERbYm2MjZVfp3zx8pdHxc3JuH5QdWwednLB8cD4k+l4PvvRNqg1UWCZxoXdel/fh6K6538lIaW54PKueY4Mr4tLhe3W+QxYtMlLl10ekkGSeHDJU/OVPypkhuDpV+3XUybnKxVvYSFaOjq7DM8zyu43TozOs3TrQOWk9ajgxnWq9Dn2iozIuiSEGzIAhKr8BxnPz69XaaI9sAfzIEVoe+u6d5P45jBds1weQ48EO6lKC2RHZ8TJUgVWb6+93ZBrQ15IoSWPG9IY6VCSuOY6cu0JZSbZqPgH4JMAABcr3iOf9YBgAAAABJRU5ErkJggg==',
            // 8 iron chestplate
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAZ9JREFUeNrs2rFOhDAYB3BKLnF0c5MnOAkuupAcuecgDE4O+ghqjK/g4OSA8BbGYCKDk+TiE+Dm5uiE92EKbWk4CMY0+v+SS4/Sr9cf/RqWY1VVWX89bOsfBJBAAgkkkEACCSSQQAIJJJBAAgkkkEACCSSQQAIJJJBAAgkkkEACCSSQQAIJJJBA/ibS9/2KMWY0cjYFR63jONQQlJn6j8vRC1NwbUnY30WRpqlx2EEL4jAdjofneXW7Wq2avqlg/rt5nk+aR5t8frpXPbxsW30wta8syxrqum7TlyRJJ28TPAzD5ibNVRRFPfcUrJREOGoXhzvWxc1nLy4Igs69OI43jtHBFWTznaqCkOKDFGMouh4k4sQQoSJYt3hdZFkmXQ/NE3FRFElzidChO8zOTuaVilOh67MxeqFD0Lrd4cFxunwVutz/kMZdXb9KaHZ/t+w8gsVBiw6O3hrkFOBPBmFV6OXxVnP9+PwuYWc6mDTh7e4a+iTtpgnBj4+uEtrKnNfvb7sPaGqIFUVY+tCx0mHpONpDgaaU6tj1EPRLgAEACjfFOwGC4DgAAAAASUVORK5CYII=',
            // 9 skull armor
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAVVJREFUeNrs2tFtgzAQgOG4YiBGYBMYBTaBSWAERmEDJ0Y65Lo+2wlJhdr/JOQIw5mPs4GHGGvt7a/H1+0fBEiQIEGCBAkSJEiQIEGCBAkSJEiQIEGCBAkSJEiQIEGCBAkSJEiQIEGCBPmbyK7rrDHm0sjqDM61dV27xkHNVf9x+fSFBbgjtm3b22EYLoctuiCBxXDh/mVZjn1nwTLuNE2n8kRP9lEaTMM2TXP87vv+R38O/jjH+rnWdd23M9hvJ/lT0SVO4XyMhFQx1peCa/2ST5DSSpSi94O0deZDY32pCI9PwbWblRuvtMKmbVurTT1J9LgJL13suyOsrIYP0VVuvflJBBgb7JlITfkUSMsVWVrWFUawVe5B4g4exzFazU9WNTWGP51jN8Gz7O/vKgUsWTOvVLNkvboxSnNrD8rjQ2We5+zjyVXSbVcLf0prbwMXdwEGAGMx1b1iXMhzAAAAAElFTkSuQmCC',
            // 10 cape of deception
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAkhJREFUeNrs2r9v00AUB/Bz5CqVUxKyBbI0VUMGBlxVXWFF4m/kz2DiT0BI6cCQBrUsRhmQoECjVpFq8uw8593z+UcyNBL9viWKfXd+n3t358VeHMfmf4+GeQQBJJBAAgkkkEACCSSQQAIJJJBAAgkkkEACCSSQQAIJJJBAAgkkkEACCSSQQAIJJJAbhF+nked5zuuD4FX29eHV/NzbFaLqI0h/24EJOAhC83MxM929XvKsXWMLi1TnU1BZSa7e0xRm+s0Xye/z/aH5Ov+8RI6tvg+BrjLUQh61wqwR43Ro7Bo53hrLE1rVd6vlevKspXoNLRyBCEPx6fpD8hvdXWTQ4+DUmYvrogTIPS4ndBCs+17ejL2iM6JWJRnXe7KXaziJDpOHdgWWMd9vpwmSg9q4oLLCutIpJrTu0X7niaPxaVzZvqzC0pUgy3ASqZPQUE6GoSVVzU2M7BM02tZ1OSaNx31/LSeh056a8WzulSLDXhCX4XoH6b3Z30UG5cS5MjzjvIQ12LXMuU1R6L5nnXfW/48/3ptR/1ua25+FdY/QFvLtsBMXwXQw9OXB6yxZCXUt1aIKc/s6IYGyiozM5blCM9avguXwy4G/ROuDhpYWg/kg4sOIkpP3rP1m0verxvIe5JPatcSpHyEpH5r4XJ6rlRmaIKZTyq8L1EEPmt//tpKkpHjWqcKM1XvOtXS50jSm3ssS11WvMJm7BhOWoP6mQGo/WS03fqjeP3x4BM12bpnKPacnSZ/E8p7sTyfsm1HkzM0F/SfAANbvOCIM8jKOAAAAAElFTkSuQmCC',
            // 11 mystic cloak
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAhlJREFUeNrs2rFOAkEQBuA9BRNPDBRHgjbYmEhssLC29TF8QB/A1jewMVhKRwIFRnImEnM6LMPNzu0eB4Uk+k9CCHe7e/Pt7G4oLsqyzPz12DP/IIAEEkgggQQSSCCBBBJIIIEEEkgggQQSSCCBBBJIIIEEEkgggQQSSCCBBBJIIIEEcoOoVWkURZH/xkWSv334Mol2hVj3EmRt65EJ2EuMmaTGJPHiWbvGBotU5VVQp5JcvXZsf5+17He3aczz2JjBxO38C+h1hmrIXjtvxDgdGsvB6G2wPKFr+m61XK9OjtxerdjFEYgwFI9D+/06zaGXbW8u3gwkQO5xZ0Lz69lgHAXPiCqVZFznuF5o+LBftw9NBJYxwzeL5KA2PqissK40Be1xGbTfeeJofBpXti+psHQtkGU4B6mT0FBOhqHhqhYnRvZpHLjX5Zg0Hvcdp6Y/Tc3TKI1Kkf1OnJXhOg17bzSb51BOnCvDM85LWIN9y5zbhEL3vem6v+8H5vZrbnN7nzu3CO0gb8+bWQimYwW9Ps2TlVDfUg1VmNtXCQkUVWRkIc8lmrErZAgWhNL+lCcqBx9EvuR0pQissTymHlcCl3vz7tDmE8z1B0vQ2ibAwv6ZfbpJUlIMowpLsKyib+lypWlMvZclLomDq06DaRv2TZzVNgUu2n+Y/J8OffT+4cODPnqZykrqSdInsbwn+y+r6MvNB/0WYABwgfXw0R+8SwAAAABJRU5ErkJggg==',
            // 12 shimmering cloak
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAm9JREFUeNrs2rFrU0EcB/B7UjXUQVySIhgkCQSHQIbWJRWypAgu2gSd4uAkmLgU/SOcxESQrpkUgoJVJEEyZWkdHiSgkSSIFGyyiIOidnjy++kd917vtY0PS6jfH4Tf9eXu3n3e7+5lqeU4jjjscUT8BwEkkEACCSSQQAIJJJBAAgkkkEACCSSQQAIJJJBAAgkkkEACCSSQQAIJJJBAAgkkkAeJTKVSjmVZU42cCYKjHIlEKBHUmtb/uJx4YR6citFoxLnb7U4ddl8LkjAv7vzRDc7r2wsikUhwu91uq++DguV9g85jHFwoFJxeryd2g304dck15uznFyKbDAn79Iq6VqvVdsy914L1B5rJZES/3w+8S1yDCEe5VCqJcrmscHrFwuEwt9PptLh9osrtB19LnBuNBufrZ2zOW+fu7rihCa5HsVh0zSvn1I/EpDuFO+k4GT+fXRMrr8MKKnEXjzfE1flZBZPhBVPYts39KV79WOIH4xfD4VAMBgMRj8dFLBbjsfrDfPLmG88xHo8nfg9Y+XzekTiCHbv8WGUKquid+U/GhZpgu12fe3tPzaPjO52OOha0cMprV94bH5o8GnJnUf9kMum6T71ed6GtVqvl6ECKbDbL+fvDqFh4dJLOie8W/VuwXzUpqKK5XM53HsLKitJRer4ZFZVKRfWtVqsurELqsNCtjyr/eRlwNb1nLChY/7vZbHKbtqvctvdTL/fcEYSlahJSLxS1VzcvMJSRXqDhjceff11Jv/NpmkduXdr277a2VTVNUCqns4/fK7Fx80tgmOm6X1+CLoee/gZpP0v6mBvtRc56NU3xS4ABAIDuiOkug0P6AAAAAElFTkSuQmCC',
            // 13 phoenix chestplate
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAaxJREFUeNrs2iFPw0AYBuC7ZQ1dxYpAVECCWYBgugS9IAlgZvg1BEHgz2BAkGkyjahjZAaBmEBQRFdScXCFa+/ay9amhFzgfc2t197te3Z3mxlljJG/nhb5BwESSCCBBBJIIIEEEkgggQQSSCCBBBJIIIEEEkgggQQSSCCBBBJIIIEEEkgggQQSyN9EDvsOo5QajWw3wfF2x7MI8QmHUlP/cVm7MAUnb4nvPXE5ejMOW6kgAdPhRPa37LQdT+OsrylYvO9NMG80j3Zwf8Nhm2v5tQ62XeibzJIUOuitZH0Xo7A0bhn89MjNbg56Nrl7jMnD59xNsMogjuOt51rEtpKFuJM9p3Tv/DZc+owOriAP3ez1ePqeIkUEVqQqOn1IxsmRofLK6YrX5eo+Uq6rjpNxZ8euMtdEglZdYeqvd1gRV4QOfad2oVXQxaLlCJxufBH69KI+FzyraHqw2y19BF43R7/OowzZBPiT4dgiNE7ymmdhomDbOpic1Y5DroNIWU0TIo6PbieInemTr9/v1iKgqZF3FMfy7w1+rHRYfhxbVYGmbNW69XDohwADAHv5uuS4OWuFAAAAAElFTkSuQmCC',
            // 14 ancient robe
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAdVJREFUeNrs2r9PwkAUB/BrwSAa+eVGHMDIposSZlxMcPQPdTVxcjbqohsmMhgSB36FKDSNnLySK6/lKMUSQvT7EtLrcb8+vXdlwZBSir8epvgHASSQQAIJJJBAAgkkkEACCSSQQAIJJJBAAgkkkEACCSSQQAIJJJBAAgkkkEACCSSQ60SeH6akYRgbjYxHwdG1kEmIalEQ1NjUf1wuvTCO4/Fh2s715rG3cdhQC1IwHU7F3sEk81+bllsXFazmvXvrRxpH2/mynJGD9kgEwQpZb12jYznQUn57inzozfRbBKe5VfkonxD995FodCcP7rdYTyc1AQ3+/DIIxOVKsZnvnu6/FrbRwXnUymm3XG8OHaT7ILuWp21YtNOI43hwKN853eJ10a5/e+7D9uO408qOZyzKGD96EdaonaWlH+eHVouppRcaBu1fNKX7/ueWaO3aztU/1zxoMmcGHom4DsjPFSFXAZzXv9WcnmNK91IlNq6znbaE4n3ccj3hQinTGm1LnBwnpykv0nKcnS42roPxuLrIiuvbjmc3Vxk0L6Wn7mUWFKot31X+wlJY+v02g4DrCpqfPmr3FFzdB2UEYWk3ecZxLB1HMywwaqquOsKuh6A/AgwA4k/bm7b7+74AAAAASUVORK5CYII=',
            // 15 genesis cloak
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAixJREFUeNrs281OwkAQB/BW+SogERIwJsYgepHEo/HuxWf1JXwJEjxJiDchQaMg8iGVbZkyO2xL4SCJ/ufS0O4u89vZXS7Fdl3X+uuxZ/2DABJIIIEEEkgggQQSSCCBBBJIIIEEEkgggQQSSCCBBBJIIIEEEkgggQQSSCCBBBLIDSIRp5Ft28b7l2UnePvwsTu0d4VY9xJkYtuBFbBecazuYGKVc0nvu3aNDS1SnFdBeSWpeuWcPz+1Ytq7VufXxsvQanaGWt/fQK8zxELWK9mgEeFkSCwFobfB0oSu67vVcr0oZrReqeSehlOg6gL10Hr3rq3XUQC9OnKMuZhucgDf4/qELu83O5922BkRq5KEKzn7Kw37U9f70sX+0zDtOVAhl8kljVBeYVlpf8XofdR+p4lT46txefuoCnOXh4zCcaRMQkIpGYJGVHVlYnifg5T+y8bHVONR3+5gao0nM+vpbWRHIs8P024UrpTxl0zvaxpAKXGqDM04LWEJNi3ztngmQ/a9rRW0z/eNnpVP+Lbe8Ft7ptAa8vo464bBZBD05iQXJMuhpqUaVmFqHyc4kFeRkCt5LtCEDZBhsDCo2p/8RKWgg8iUnKyUAktsjY3Fx+VA2pun+aSXT2iuc6yCJjYByv3zMZ5pSaqkCKYqzMG8ivrSdbT9qcaUe5nj+Bgydwn2t2Hate/OChv/MeS5P9FOWoLWxMyblik/OU2V5O34M36fqhi20mT8CDAAUE88AME8AowAAAAASUVORK5CYII=',
            // 16 soul cloak
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAlxJREFUeNrs27FLG1EcB/A7yeoiCk6BRMRNJCW4RNqKGeoQBwWhQ4aCmUTo2o62/QdaKNTNQRDaoQ46pFDFLBoaSjcRW8gkKF36B1z9veR3+b1f3l0uGRqo399y5O69d7/P+733posfBIH3v8eIdw8CSCCBBBJIIIEEEkgggQQSSCCBBBJIIIEEEkgggQQSSCCBBBJIIIEEEkgggQQSSCD7iFSSRr7vO++XCkvh14cHtS/+sBC9PoJMDTowAUuFonfR/OnNpLPmXcPGRhYpyaegspJcvZn0lPn9cG7eXAuzee/j8eEdsmr1/RfoXoZEyJWFYtiIcTo0toOsDozlCe3Vd6DlurhcsXqNKhyBCEPxeveduZ58Pwuha4+Wnbm4bkqA3ONyQkuFTt/Pp1U/6oxIVEnGZaZzXQ1vG5/MS9v7z8LUftQNspNc1gmVFdaVbmGK1jPa7zxxND6NK9vHVVi6DDIOJ5E6CQ3lZBgaU9WuiZF9JscmrPtyTBqP+140r7w/oxnv69GOH4t8/GQjiMNlph+Y66/LbyGUE+fK8IzzEtZg1zLnNlGh+74sb1q/y6+ee+O51XZuDesZoS3ks633QRRMB0MrpadhshLqWqpRFeb2SUICZRUZ2Z1nw8KmesFc+A8He+FBQ0uLwXwQ8WFEyclner8RWGN5D/JJ7VrirX5XJh+a+O48eWVuBHRKpZICddCLrn/fWElSUjzrVGHG6j3nWrpcaRpT72WJk2Po3DW4hb2Dbr897/uPIfX9F9YhxFBZBdehkaSSsp18Ju/TCZtffxO5pXT8FWAAwKc5BAY2wHQAAAAASUVORK5CYII='
        ];

        return string(abi.encodePacked(
            '%253Cimage href=\'data:image/png;base64,',
            ARMOR[lgAssetId],
            '\'/%253E'
        ));
    }
}

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library AssetRenderer5 {

    /**
    * @notice render a weapon asset
    * @param lgAssetId the large asset id of the gear item
    * @return string of base64-encoded image
    */
    function renderWeapon(uint256 lgAssetId)
        external
        pure
        returns (string memory)
    {
        string[29] memory WEAPONS = [
            // START WEAPONS
            // 0 brass knuckles
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAANhJREFUeNrs27sNwyAQgGEu8gS0NLCXx2MGWtcuPAEbsIQTpBg5rw6InfzXICgOfUJcdSfruqpfj4v6gwAJEiRIkCBBggQJEiRIkCBBggQJEiRIkCBBggQJEiRIkCBBggQJEiRIkCBBggR52hhqJhvH8aFD2HsvR0BKrc7lDHTOlb21Vk3TdAjs0CJpBhpjMvzlhb8Blpo96HvMBnyOG7I7VFo12m/gd9jeUGk9TbDHxhjL+TzP3aDSa2QiY/fQlJJalkWFEOSUhefDX5T7Wqqw1rrL3VcBBgAXRk2XfNaHnAAAAABJRU5ErkJggg==',
            // 1 pickaxe
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAX9JREFUeNrs2jFLw0AUB/B3V0ulUJG6FYdayJrBwVk/R/Jh/Ca65DOELtq5g4UMXQrSRRwUFcWhg5y+KwchLfRaB/PO/4OjR0tKfnnvLtdelDGGQg9N/yCABBJIIIEEEkgggQQSSCCBBBJIIIEEEkgggQQSSCCBBLL+sbfLQWma2k3NLMuUhP1NvQswjmPbF7OByyfq25IkMXmeG37d9ti/bHqbDP40KooizInHATkYKWUseiOrwKBvIWWgtCdGtG8Wg18MuCy68RgMUvJs+uvFgMQnuLRvFqWWqtfaNehyZRy35nRoG8f5SccEgazeNjrHmk7P2hQ9jqh/2KKLwYHhJr5cXYlyBj+40yPqRg3qUpv6sxbNXxfkoLf370r0mJy/LZad8TKjUW9fJHZloc3lWp5F+XOGcKm68mWsi5fZl8W6C1JH7ApSqfXn6CadTdiruycZyPJ7VfQ67NFnky5vHlRdFwsbfxf6ZPZ68my/p3qBxCBDCPzvCqSg+BZgALDGXYBnH6DbAAAAAElFTkSuQmCC',
            // 2 shadowblades
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAb5JREFUeNrsmTGOgzAQRTHiAjQgUdOGLieg5QZ03C03oOUEdKShSB0pnAGJzSA5GlkGAizgZf80FgmW5/l/2wOIruuss4dt/YMAJCABCUhAAhKQgAQkIAEJSEACEpCABCQgAQlIQAISkIAEJCABCci9wjlqYCFE314ul/5T9/1+F1t99XZMmOk3KDVEKE5lV1JNKvd6vXrQKIq6065J3/c/is4Fpfun+hgBSUpy684F9TxvtI9RSlJcr9dF/ccmxzgll6gp+w/1M+6cLMtytprcCTrQUxQD3Am6CTIWcs2Rova1TVTjt+2O2nVtDNmtqqrJ8o3UeNezs5yg24BoLGdLQDqk+Q4obSQH5/fwBP+EkjL5oig+isVx3NF6ociybLM6dVe7ckB+TUV5mqZdEARW27aDKsoJWXJWqnbfZOOhZ0Pd04aM2+0mns+ndndV2zlLYnclVTB+rSYnNw3ZPh6PVSruUgx8+4TfNI0WNAzD/j/uiCkVVQfkeX7cOcmTU622VMkpJxhXDLiuO+kI3VpUncAtbB+l4ljUdT3b7qoTaGeVdt9dSUpCTU7+niTJJ/mx9cjfCIzVwNIJPwIMANQO9dNShroWAAAAAElFTkSuQmCC',
            // 3 kusarigama
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAhJJREFUeNrsmr9PAjEUx9vzTESCRt2MCyZswmCMMy4aV1f4A5xcWRxd/A/8A2B1cJFNJwcHB1YSdVA2jZH4K0Yr77iSR3MHeCA0+H1J0165Nnz6fe+1l1QqpcS4myP+gQESkIAEJCABCUhAAhKQgAQkIAEJSEACEpCABCQgAQlIQAISkIAEJCABCUhAjq25Nv0ZKaXQV26orU335fP50Ps4pVJJ8netheSwHFDDNepOw5Q/VpqgctSXlcLU05bL5VQXuDYrFostZfW8I1eSL7K54KRgL4CVSqXVzmQyXqHptKpWuuvG8oxHu727HwrTrd9fHJpHujYCpldiIrU4Jd58AFLGBOHPOulwB+G/S5suEJJ73l+ciJ3NOe/5sfolYlt7PYFxDjNxuTYBkosdNiAJbj41IR7in2KJwXUCM/s5qHXuSnF4enQg0vGmyx432uc3ddkNrFNCs+rEQ4pp1ep3314dm3fEbwGtPtb5qd9T7vbpo6ns2qzIJhOqn9zh9htHbBOWg1CS29Xlq1hdn25Tc6hKEiCtPCULqoNOK1GVJNW0mtXau6em3juHBqkzIa08HaMKhYIcVEya8RcUm3/urlpBggvYhPtWkoOSmtmkUIma01Lz7PpZDkVJ7la8DDomuZrktlHVdGxRUbu/Oa+ZaaPEphNVxbBPoyifWuVyWfGFoz5dtC28TLaNCStB9iPAAAMvFtd8U1D+AAAAAElFTkSuQmCC',
            // 4 phoenix blade
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAcBJREFUeNrs2rFOwzAQBuC4ilQmwtwZxk70JcJbMLDyPoh3YO1LwMQIE0P3bjCZ/lEuuFe7juUmRPCf1CFRYvvz2ZdUirHWFn89ZsU/CCKJJJJIIokkkkgiiSSSSCKJJJJIIokkkkgiiSSSSCKJJJJIIokkkkgiiZx4lCkX36wuol82rV+2ZmofQJUpsHpVdefvlj+Qx1fj3mJ390wKHRyA4ABzQSkB/Pp5++tgb6cAujiVqV7hy7SAx8YedCbAU8UUsN2eNMYU9XVlLxfz4m3z2buBq8VZdMkegqumj7qorEHH2MgDYjukAFPDNyEhuIAb7HK+O26us+0kD5bVver6vvlKujk0KRqu0XtYldUhoF2j7apJCmRfYzFRPnwou25xw17FPtXX5ML3kLHGfBMh0GOZjWFj0FzkLKUhXOP+ZB/jh4Ehi3rJ62PfHnaXLyq7O3GDvgz0eRN6uj1vBnj/8GFiyzgno7mZLHNu1kBn6TfnUExCWMmoi0V7gEpBQpO+PToqUgaqZxrHcMoAgRWoLkxoIwbNrbplMUIAK9BQVjXUfcS0z1KTXXhOHVKcXOix53CoIEkx6vM3LxTfAgwAuBAia6t2+pUAAAAASUVORK5CYII=',
            // 5 none
            '',
            // 6 rusty sword
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAASdJREFUeNrsmosJhDAQRN0jXViNdWh5WofVWEfOPVS8nJII52cnExBBEHy+bDKJive+QG+vIoNGSEISkpCEJCQhCUlIQhKSkIQ8F7JpGi8i+CbruoYDdeGFqqr0pKBJpBa2T9zWxbHbfp6/67ooaPgungi9O/AoqHZd+NEVBTQ6hSCAbkIOwwAFumsSCfQLUkfTvu/hQA/HOougP5Axm3NgsASa7yokZrMsS1M2szAp66wZ5lA1NQX2xWA4zajxlIx7Z7blzgBKbdIkik2aRLFJkyg2aTJsbduatOnujlyP7K4WazOLmnRHb9AuPX1CWFYoanO9QpltFom78DR5h0mLNmkSxSYTD8q8yZo8YjO1NsdDaPKEJv8M5fqLTMo+ra5mroR8CzAAlOHbWwh1ahQAAAAASUVORK5CYII=',
            // 7 bronze sword
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAVVJREFUeNrsmEEOwUAUhmdkdhK1cgNLKy6hDuAETsGSUzgBe1yitbHTE7BSiZ1kGDJoaVTS4r3+L5k0bSZNvn7zOm+e1FoL7lESBQhAAhKQgAQkIAEJSEACEpCABGS+kIOOo6WU/E323Qo7UBV/0G2VzcWApiKl0D6JmFxurlwD17kYTfMC8y0eB4nlOl1/Dkry7zpe8QJN3EI4gb6E3IZHVqCJJi3obQ8lDBqBXPih9INDBNTapAz6cVlHEfQJ8p1NWzBQAi3uKeSdzXpNkbJZCJPyscCO157tpqOb9fLtvuYo0Wvc5wfbo5h4BzGa71MXrb8o6NEZ4JKbMMnFJkxysQmTXGzCZDzm3o6kTfXrkusvlyvF3EROJp0iqNmESS42YZKLTZjksm8WwqTK4iXGpklT29m72rx39qxNM+c8JEzmEDLLotxtVVP1aYez8Ks2TwIMANdQ/b4gmemwAAAAAElFTkSuQmCC',
            // 8 holy sword
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAW1JREFUeNrsmc1qwkAURu8tWQgF3RW66K76BH2Kui6Ci76HtVAFf96ji0Lpppv6FN24VXfduVMQWhCmTnWCiRVnoGrvzTcQQkISODlzM99M2BhD2tsJZaABEpCABCQgAQlIQAISkIAEJCD3C9m4Y8PM+k0+1EgdaJQ+Ub352VlQL1IJyycJk/N+ftlta0ujPg+w72J9E9Fdv17Pg0FFfl0/Hy9UgW4dQjSB/go5HM9VgW416UDjMVQwaAKy3Zvy8/ssAepsSgYNjnUSQTcgd9l0gUESaHZnIbtsli5l2cyESV4P2OnsWb/Om8rVaXxcPIsod/sRHw9GRE8vRM0ueYfWYwR6rAxoqU2Y1GITJrXYhEktNmEy3VpvE5E2o2NHrn/ZXSXWZiZqMgq9wXbp1S+EeIZibRYXNt0Mxdm014TMUGDykCYl2oRJLTaReLSMm6jJEJu+tbnYGCb30PgvQ/l9ueC1TtvomIPa/BZgAE9a8+L8u4WmAAAAAElFTkSuQmCC',
            // 9 bronze daggers
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAaNJREFUeNrsmrFuwjAURW2rUtjSmbGCkanMXRFVf6M/wy/wGwj2zu3Ukaojc7vB5PISHB4IWttxXlS4liIYIj8f3+PElqKtterSm1FX0AAJSEACEpCABCQgAQlIQAISkIAEJCABCUhAAhKQgAQkIAEJSEACEpCABOR1Qt743vg4vK0+E1m8fev/9NVIUJK9blZc4/vccuiLSdK1pzulZiqr0p2/fmmpwfKJDanrnSQp+rHaqNlnCToZlalKJ+psorq+tYN05aAvy80BqNZigRaTzGGTQZ570DhQWqdNw5GiMTYFJUmgPM1jUIlEY2yq9Z6kIqcSlVTXxyaTYjYlW4xNpokHgmSaPjYlhXzoZ2KJhthUG/K4SL/baXV3c8omk6JTvjaeB1bsleJrk0mhC4FO33Vr6f1lUzAkPd3cxYtQgm0p+5tNpKxJVYQnSUXGw7zxfa2vTUGnkHODLmdxraZqn+Byta51cvDdYm77r8YwGR3aRBMQddQiDVwnXNFd+f3fQbad2U4F6wo2qSwl6cZU/ubFoIIhQ9ebuz8VZIxNPwIMAM/39ASfB+UaAAAAAElFTkSuQmCC',
            // 10 holy daggers
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAc1JREFUeNrsmjFOwzAUhp+jiHaiWzbGHoOIqUO4A1fgAJSpcBHuUCRYisIxOrJ1I1PLYvJcObhRC3biOKL9nxQpkaz8+fx+Pz9LEVJKOvaI6AQCkIAEJCABCUhAAhKQgAQkIAEJSEACEpCABCQgAQlIQAISkIAEJCABCUhAniZkbDtwej2qfhN5fC7Ef/prJHYZnI6H25uMZAlND/NPcXSQHGeTFaWUVNkNCWq6yUXXek2yRfPlmr5eEwU6ma1UZk3hEMGaWtdW26nwmKBv77QDKkQ45yo3GbDeIA8VGg16l513nlG2aCM38ce7XBwM9HKbSFlQdfGzBnV9Z1P9xdxOO24zs2zZq8ufjNJ9oipvad2gW4ypXT4KL81AfW2GDJ48U7++bPbVh9h7QaCw2bRxk9e2TouFCBc3tYasi6TjQa/djd5euBBp20Y+XmqujeHNR7AtxdZNkQ+7MOj66aK37P3lJmfI+p6lRTiDfVn2NzexZSNfImYmWWSajTrva23d5LSFHPpoFslpQ6khki83rU4Oti0mH/kqN8123cQT0Gif1GdKfsnWosX+LoTHlNAaVgt2aVnOpF42yk2kJl02gBw0Gu8LsombvgUYAEB2jLqBBdg1AAAAAElFTkSuQmCC',
            // 11 soul daggers
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAbxJREFUeNrsmr1OwzAUhW0rEuIdWDpkZWjEloVuzcg7hI2FB+nSDd6hY9lgYUPtwJqhC++AmEJuisNtS8F2HEe050pVO1g9/u458Y8UWZalOPRS4ggKkIAEJCABCUhAAhKQgAQkIAEJSEACEpCABCQgAQlIQAISkIAEJCABCUhAHidkZDpwlF03r4k8PdzL//TWSGQzeBAPv37lZQUtHud38uAgqa7OTsRMDBt3Q4LyNNnoGj+TFNFVsRSzt48adJKltbNcOESRptY11bZaeDjo8+vLBqiU4ZJLTeaw3iD3LTQa9HKcd+4oRdQlTVZOEih3cxs0hKMuaWq1T5LIT46GjK5JmpSPboYslzRFvheE9fZSuxnkwEBNTs8vGtDbudjR93qs02IhyiZNrSG3RQZx0uvpRm8vfG1QXiLKno2b+DTYlmKaJuUjLgQ6Ld57c++vNFlD0sOsP1yEHOwrsr+liSKrfIlwJ0lklOWdn2tN02S1heyb9LqLCzEV3w6uikWrm4PpEZOufHoOk2wzTdQAp31S3ynpT3hEdypOq84mDawW7DKy5KSeU/1dpYl64gCZOI33BemSpk8BBgBS2xHKk2R9CQAAAABJRU5ErkJggg==',
            // 12 holy bow
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAbZJREFUeNrsmr1Ow0AMx++iSAxIdGNj42NEQn2KsLDxMGQAiY9n4QHoU/AE0B2JjUpsSEcc5Cq9XpO0dyi2Y0s3ROryy9/+2+fUOueM9MjMCEIhFVIhFVIhFVIhRw6ZNx/Ky0k94z3MFjb0Y64j4JqSZTExN8WBE6skKJifL1xZHNXCbVKUNSTG++dPrSiA3r98sQfNQjW3d/WxBMU6Femuz6/fK6DWWuMf9pBVba6kLmczau2ToKYE0FZIcFcE5dxeOiceBAU1RbWQECiY7/V0f9laOPXQoJKnx4JnV4y3eT81q2NFK8lpUNjqquWbEBfQre+THN12p0tzs39yULMVEgb2TQcnIdHrD05qRu94OKi5M6S/76GsZpJtHXU1oyBDtxSKakZBNlOWsprR6eqrKbYmqRtQNCSHlNUPPn0DFtCUXVaVTGFAFJbQWd/1B+fpJ9kiy69L8pAxSnYN8uKMp97sEXDZf4HEujw5zOmma6p+Oao+OXQbCebT2cXfZvz2MU1dgv9UoHYoE1pT8u7JiPgzRKeSKd84mA+qaQb6dpKlBkTzoTT56ICeMmVVSYWMj18BBgBBAfIoY/ffzAAAAABJRU5ErkJggg==',
            // 13 shadow bow
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAZFJREFUeNrsmjESgkAMRQljS0lDxQXgmNyJa8AF6BkqDoDGmTi4rojuKklMZrbQsXn+5CcbgGVZEu2RJn8QBmmQBmmQBmmQBvnnkKf1h7qurzNe3/fg+7HUEfBByaqq8Cxq0xUVnKZJHejJ9+U8z1dQzNCu60CVklRzCEigVKcq3XUYhjtQAEjcIx6yKIq71JVco5t9EtXUALoJiW5LoJLby8uJh0BRTVUtxAeK5luW5a21PJuKxCiZ57ne2ZViHMddal4OqFZS0qDw1lXLNSEpoG/fJyW67UeX5nX/lKDmJiQO7M8OTUKq1x+S1Aze8UhQ82NId9/DWc0o2zruagZB+m4pHNUMglynLGc1g9PVVVNtTXI3oGBICSlrD3z2Bi6gObusKRnDgDgsodO96w/J00+0RZZbl+whQ5R8NcirMx7c7HFw2a9AUl1mWabPXbnW5U/65NFtxLtBb5oGYtYl+s8FFI4yoQcl27YV/47ALiVj/uNoPqRmctCzkzQ2IJkPp8nHBvSYKWtKGmR4nAUYAM9Y8XxdtZLpAAAAAElFTkSuQmCC',
            // 14 genesis bow
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAcBJREFUeNrsmrFOAkEQhnfJmZAckZIYrZHe+BIEa9/A3nfwQWy0NtEXoKaAUqXFGEsNJBYmJ4MZchzLcbBrbmZuNrkCQsHHP/PPf3PYJEmM9FMzFTgKqZAKqZAKqZAKWXHIKP3iotNcZLynly/r+jDXCLimZK/TNL3Tw0RsuYKCN3FdHGjkevNj+rMAhQp9fP60opTEnnu4bC9BsU9FuutgMlsBtdaa7MUecnTWWildzj2aOydBTQmguZDgtgjKebxsTTwICmqKGiEuUDDf85N4OVo2pSI2StaPY7nZFc/326yQmvPLilaSU1DY6VYra0JcQJ2Q190DUW67101zen5yUDMXEgL7pguTkOj1Byc1vXc8HNTcGzK776GsZpBtHXU1vSBddykU1fSCTJcsZTW9yzWrptiepG5A3pAcSlYf+BQ9sICm7LKqZAgDorCEdkK+v05FpR8n5FG74d2X5CF9lNwW5MlA3vbDlBxs9ii47L8YD/ZlqxHRLddQ87JSc7LsMeKsp+FV/+9b3YXpS/CfOagty4TWlJzcj9n/R6CQkiF/cTAfVNOU9OykFhoQzYdS8tGAHrJkVUmF9D+/AgwAs5/02YmME18AAAAASUVORK5CYII=',
            // 15 bronze staff
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAXBJREFUeNrs2TFuwkAQBdBdZKUgAiMhJTXpXcEBnNKU1LQ5Q+7AFbgBF0jLBVzRQUENEgVCuLKy8SxsMEQCO4mQZvynsZHdPM3uzKzRxhglPWqqAgEkkEACeffwyrzc77Vsv/mIt5pT6/HKAKOe734anQUX6E1kZlFR17fAt8ChfFbQm8ifQHW85wMtVHjyQPGF5xK+3j7abNKqZos8FZvzTI5nOgOmcvukAz75nszlulinGVBboOhMYqzjiqRlSfuQYjLXMpGcCsyfMlmZPemWLMfMFkbShMOtdfwqk24I4AYt1UIckNuSvYqkLwDxYv+ductM0jN6R0wm81BRR63jYVi/vjRN8FxX7bqnNskBOVslarrcaVF7koDvg5q9VubQnMs0BnQggQQSSCArj3STDsco/Ulyk3yyQxb+s8bNr/m5VdTEQ8Cw01Sj4YOdXek+7DSM6D3JbX+iugIJJJBAAgkkkEACCSSQQP57fAkwABKgngHgRL4dAAAAAElFTkSuQmCC',
            // 16 holy staff
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAVhJREFUeNrs2TsOgkAQBuDFUJiYaGdiYekNPAUegM6LSKkXsbOz0VN4ArGzo5PERBMTZNBV2UJYSIwz/FOB0nyZ3Zl9OEmSKOnRUg0IIIEEEsifh2vzcTDpZf1msY0dTq3HtQEGXk+/Jk4aXKCFyNSiZl43A7anxwdYDVlBC5EmkIKeOUFLFZ5PoPjCY8L9aJBlk0Y1W+S72MS53y/LoQqjm9w+qYGjvitzuO4PSl2fQNGZxLKOK5KGJc1Diut6IBPJqcDUymRj5qQeshwzWxpJKxxuraNSJkOGPdK6hWggtyH7FUknAKvd+ZU5M5P0H30jJpOfUFFzkjbD880py6ZZWblk0SqTBNQVtjGbZp1pLNCBBBJIIIEEkvfmudKRJLcofVlDp+n+uJNbt4q5utNAfbNFm+fnPeXf34HUmpOiTwbQQoAEEkgggQQSSCCBBBJIIMvEXYABAPzeoLvJeT1tAAAAAElFTkSuQmCC',
            // 17 shadow staff
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAATVJREFUeNrs2bENgzAQBVCIaNmBBaBj/wHoYAF6SgZwOItDxIqCDRLKP/5ViaB5+rbPxrlzLrNer+wBRSSRRBJ5exUpLzdN4/vNMAw5UuspUoB1Xetfly+FAj1ELpZswXlg27b7RzDQQ+Q34O43BDRq4QkStL3whPB5nn2aMqphkcFis1XXdQq02ScVWJalTeQ0TRvQdJLc1qEiZVjKPFy3czaRSAvMpSQfMyd1yCImG42UHQ5a6ziVJGKPTG4hCkQbsj+R8gVgHMctuTBJeSbvmElyDzU1J+Uw3Pe9TzNcWVFSTEpSgLrCPubQrElzg04kkUQSSSSR2IfnU58k0Sr6ska+pldV9bFvNXN1p0C92ZLD83p18Pd3IJfmpOkvA2whRBJJJJFEEkkkkUQSSSSRMfUWYAAGQqCvXabbLAAAAABJRU5ErkJggg==',
            // 18 polished scepter
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAVdJREFUeNrs2jEOgkAQBdBd3c5ErLyBpRWUXgBLb2DhKTwKd7D1FFSU3sCOws5kZZCNqxEFpGDGPwkhUPnymd2RoK21SnqN1B8UkEACCSSQQAIJJJBAAgkkkEACCSSQQAIJJJBAAgmkhFpHM0vH630jBUfncDFR6ekiL0kCxlGgDtupmgdG3uPqgLulldmTTYFskQSk/vOBSabVOb/KSrKu/0Qg26bINsk2KbLdJym1JDNP16InHh9Ig8AxzTWrJLXWb28XR9mXftUBWSe5X43L3iTcJyC7nozDoFxSaYTzV1QHrPu6zHAC0oTjYHR2CX77dI5VkrQ30qqaZPdtpOpLW/UpfyQltilA9Kg+hoBmP5/V4+r3ovvf+GnBYT0MfFtNWW4hrym2rZH0FFkgf02RXZJdUhw8so8UWSXZNcVBI+kNQB8pskjSn1FFIf0U277qeFc3AQYAB7+0h6in7acAAAAASUVORK5CYII=',
            // 19 ancient scepter
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAVRJREFUeNrs2rEKwjAQBuCkCkLBgjo4KziKr1AXH8DHdfIdHDt0dtBBwUmJXmwllra2tYN3/geltNvHf0nOojbGKOnlqT8oIIEEEkgggQQSSCCBBBJIIIEEEkgggQQSSCCBBBJICbWcBoau7PuuFBzd52Nf7fYXJQ5JwHASqOGso47RTV67ukCRa7IqkC2SgLT+XCC16uFylZXkyK++nXjSU2SbZJ0U2R4hNrUo8yx54nGBNAhs47NmlaTWOvf147Lr0q0iIOuJZ7bo2Q1nG5/scxGQHTKc9O2Mul4N3nbUFFj077IuJyBNOCmM7mmLfvrrHKsk7dkYPc9FOkaSdWmSdcofaVtyowy16qsiYecktau7FtPfjWUbDuvdtey4YDsMZFOsW570FFkgv02RXZJNUvx5ZBspskqyaYo/jaQvAG2kyCJJd0YVhXRTrPupI6/uAgwAniy3YrjrwnkAAAAASUVORK5CYII=',
            // 20 club
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAeVJREFUeNrs2jlPw0AQBeC1AXEpEkeHKEKRDhoKav451BT8gUiQAtFxiAhEhCDoGT1r7Hh9NHgCb5rEjpTk8+zMjqMk8/k8/PVIwz8IIYUUUkghhRRSSCGFFFJIIYUUUkghhRRSSCGFFFJIIYUUUkghhRRyIVarTiZJUjg+PxpE/z1xeTtNunxgH3/ESKo+lEjiTo43C6+PDjbC9dVb9nzyPCtg6xB4X1dIAIc76/m5wWGa4RCP48/wsP2xgG2C9oVsXZMEIvZGK2H/dS2M79/DcPfnQuCCMPPl5e6y8dgsnp5tZRBmzEKnd1/ZI6FL212BA6QqcAGIzy6GyebSbSGoQSDwWA5kEfWJ11C3sQ7tHjl5muVLFJlDLZaXLevWYzZbNx7gmFGgLBTncCG8ZrPzxEMowkJtF/aWzTQ2xXCTt4HaK28phALO2rTd1kM2O2eSEDYhYAHFMfZOdmJP2UzrZtJyNtlgCOFAYM8R72nvrM1kDAoYUJx8uGwJZTdmNvteso3LNQblEGChPM5HPSfZbFWTsUZkRz27raBu2aQ8ZLN144lBuUyRtfL+6SWbnbprXY3G7lY8dNram+ZY8Avb+00bdupBvaIR8X7T3S8DTVGF5cBOIJ5z6wH04ubl14vzW4ABAN8HHrujN7U3AAAAAElFTkSuQmCC',
            // 21 dual shortswords
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAWJJREFUeNrsmkGKhDAQRZOQK7hwK+jSi3gEPZ4eQQ+j4NYLuM9QDhkaWjqJ3ZmUM79ADBJKX/38UlFpjBF/PZT4BwFIQAISkIAEJCABCUhAAhKQgAQkIAEJSEACEpCABCQgAQlIQAISkCwgm6YxXdcZKaW4unEI7ZqQZZlo2/b45t73vbyjktpnEoHmeS5I1TvCenmyLEtR1zVB2n2yvymshT4Oue/7z5ggU4PSyqLz+16DF+S2bafHUzYcArXFdsG+hJymSc7zfIzXdX1S0zakFBFiIe/75LIsrJpJiIWckFzVDLGQE/LxtzQOal4puoqV+DfCt+j6SuKiKJIpSStLfrdvU1XVUXR7PVRwO20YBhnceDipGWohFXOZcPGmim16Dt5UsU3PQU0Vc5lwUVO/mzhlp7VFd3VaHSsxPXykUPOs6Cq26Tl4U8VKnOp986zoKrbpOaj5FuQ4jrdQ80uAAQAbKgRqdtaMpAAAAABJRU5ErkJggg==',
            // 22 dual handaxes
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAnRJREFUeNrsmb8vg0EYx+89Er+iwViWim50EDGYajEYDNZ29KfYbCZ/QJuYDBZhYZIwGEpiaKIGbEraRIlwPC9P8/Z674/24t7D8ySXXt/m23w//d7d+97VEUKwv16c/YMiSIIkSIIkSIIkSIIkSIIkSIIkSIIkSIIkSIIkSIIkSIIkyD8B6ThOYMvn80K+xnXEQS3OyuVyAlqTDf/VAmNB/3ABJPYLhYJja9Lg87OxUqnkto4hZbFtsOAxk8m4fXwFr5Eg/cTQbAEF/zBE0R8WvOdRxN5COBBD8w7juOehChC8ch2xbaAqj13dQrxiBDVdy3MjAppqOske2yA7FXuvm0pzcTIhppJ9DBr0o3jsxU42NeyK8YvGF1ZYFMCwz36i6jfvbHZ+0O1XI/jgsjid7Gcz0wORIfC6qTQPr2rO9eMLK989u15vj3dDPTYhjyr1jsVy0iYLAoFaXRpt+bFVHrmOGBcek0NVDgTqcnsj0CPXEatuLSaGLD60YCA4P/08ch1xGLTJNBv7m75+uI5YXnxMlhzIWLrH1yPXEasATd4zMRAsCETlkeuI/R4MTKd5dvrUDETlkeuI/e6Zcay0WCcba21+uI7YhpIDUXnkOmJbyrtYwqjzBhK6CwkT25YmLpZHlVp0yDCxjWni09re1npzgx96/AHXYYeCj3k7Bw8Mdih+q2pcRyLoM5tKsPuhV3Z+0XDBW7ZaYVUtv7liqGKxqIIQcQ9Z5+usRsAu6nsnJWDX0qsjln5JB49L4h66ML2GJ3j7prkbsWr+Am/caWZTn4FMfAUCBwA8qtg7sVH8G1bajg6yVGJbC08PMJAPAQYAfd4Z6gyxGIoAAAAASUVORK5CYII=',
            // 23 bronze shortsword
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAATFJREFUeNrs2jEKwjAYhuE/Wmgn69xZcXJzdreew1O0o7fwGoqncHJUHLvXqU6RRCiCiKQJNH/8AoUOUnx4G2lihZSSQh8D+oMBJJBAAgkkkEACCSSQQAIJJJBAAgkkkEACCSSQQAIJJJBAAukdMl+MZblOpRCCuh59jcjkw/dhQkVO+v/37aE2+tZ9Io1vVwVdThNSVdUR5JycZgoZU5mnLTY45Cxp2nOF5QA1Ru5v3+ecbz84xsjjqRbX6qHPd2fxUbPIRzKYkmpcqibchwGuNY2Q76+ocappfLtyrGn17MqlZickt5rWqxAONTsjOdV0sp70vaYVkktNZzsDPteMbC+gaq4olZMs1jU3c9nWfG0p6EW2CKKkzzWdIH/Nzb7Xm85363ysGbm6kM9z8ynAAIAhhYiPD/6GAAAAAElFTkSuQmCC',
            // 24 poisoned spear
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAYVJREFUeNrsmb1KA1EQhedqJGKxYsRGELLCtRC0srOJIAipbINP4YOIrT5AbLQStBQrCxFB8Ae8hYEESxMISILoNbOwsgY02e1mcqa5P93HmTk7O9d470l7jNEIBCD7Y2FnyRtjxEHm0gBOrxZ6O8tFbNQqGazM6k3XWMXd8kRvb6OzSiWlqpjJXVlNdZAbi4HffGrS1t7dzx2nriSnHVrJgh2n/fMPkak7FGRxJk9v7pMqp/cRqLSUTaWk1MgNqsdSGPzxWbG8iGgMBipZa3Z/nTllpblspgY9NiBVvWt/Pa4d3NDDlNWh5OVL29RaXbq9fif32onueL1YD3UpyaClkHyR8uSoQ+3GF80dPtIJLetQkkcjGsYjqYzHzk+KbNgzjz/qVUeNI2dUQXJrl1zr1WejXknV/5PJDkiKKUHJ/+KYtr16SEn9a2bIq/IZ3BWQgAQkIAEJSEACEpCABCQgAQlIQGqDjF+21ELyvDX5FqISkp8HoCRqEu4KSEACcsQgvwUYAHt3cFOqYEgzAAAAAElFTkSuQmCC',
            // 25 silver wand
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAARhJREFUeNrs2ksKgzAUheEkZC0O3YJzXYvLU3ArCk5dRuoNVUpJQaMDz+25IKQOCh8/Plq1IQSjfZz5gyGSSCKJJJJIIokkkkgiiSSSSCKJJJJIIokkkkgiiSSSyOeP14BomiY+ZO373qaet3oNwLZtt4/BrvMN9ejAdYvreZ7Ney1Cq6rkNE3J9edY9HcGpGZRFHE9jqPpus5Cnl3Xwyy5CbCqqh0oJx7Zr+4SUpblDlR3nazrOlYchmHf9+vQc9oqpqBOS0WVt3VHjkVYpFSUO5yjFaFLHq0Ih8ypCFvyTEUoZG5FyJJnK8Igr1SEK5lTEQK5/dLIrQhVMrfi45FbxWVZLn2P017x0ci7Ksp4lIpX/ot6CTAAIumXDiDKUh4AAAAASUVORK5CYII=',
            // 26 soulcutter
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAfpJREFUeNrsmb9Sg0AQhw8mjY+RgtbCjIUzNLGT98BOnYnvYWNnHsIudrGxjS9AkcewRH53HLMqfy4TkFuyOwNkmJDJx7e7dxxBnudq6hGqEwiBFEiBFEiBFEiBFEiBFEiBFEiBFEiBPGXIYHmT/lnkeX9bB1Na+5lhN48ufp1O8+vkdjKwGnKffarH5ZWKzy/1yedsUZzbadigCO6gAXaAKMzlMDqPFuouOitAv/QXtpt1eXwJWJssZJXAZX1GsQbVkaTaKm4CV9iwLhWtRQRgn5K4gEx17VpYdkOIBYUl1Kepx58BWKQyYAFa2ueTrhSU2rS1aVOXpjAu4dKUZnVjJK1NWF1lqmpIFnavhx3TfZt+3JcbELb9sdXmQ9ejGWZ2Va3iCGjUaN1kgsW0ztamDfu5rlYnMXeFtdeH+wqU1igXm42QtNPSIYWjTaenEDMZSNnabIVEp6W1ydVmKyTttJxtdqbrFGwetDKAJxIKzcVmJ2TbrIWLTSeT1p6Z8il2Np3T1QJytOkEWZeynGz2siTpu82jILts+rKK0Nviss82j4bkYNMZEs2naWuyCVDE2OtBvaQrfcimNg2o6bQAtRvbmuyySeO/QXuDdLHJvrseapMtZFOnHdvmYC9hfbLZO6SPNgd9ne6LzUEgfbM5qMk6c2PY/BZgACwVbLFh8QNzAAAAAElFTkSuQmCC',
            // 27 dusty scmitar
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAZtJREFUeNrsmU2uREAQx7snlk4hYekK9tzX3hUsSWwdo19KtNDqaW80qvtVJRM9E8HPv6rrY6RSSoRuH/EPjCEZkiEZkiEZkiEZkiEZkiEZkiEZkiEZkiH9twj7saoq6wivrmvpy6Rv86AariiK6Xue55uT27Zd1k3TLLBHN6DwInZKZlkmxnGc1nEcT8ckSXbQsJ6h1RlYMkpKKUVZlgpATUvTdIHF1AVlMVCSSs4PugPt+36j6lrRNRNFRSPzrYOafwU1YMmBRke7ZyigX+VJAB2Gwe88eRbUEqNk1PzYEn7XdVbQYJXUBm57pCZkJu9rVx/UdFKgY5uQVhNSkvfuqtXEUspcAytpkD5dBTlrtSinlNOQsMvqz1kzuxjS7gpgRs5DKyHMZb1R8kpSh7iEzoY0JAb4W5FANS6dzniwnEkhLr+G9EnNR6Z1b8flJUhMTYpl3i1Kmi77dlw+Nlx+02VvgaTmspchbY110LsrpbiM7rowVsuuW68n2y0nSlJ3Wf5/MpS4dBaT2MT9KC7Fg1M8dtdQ7EeAAQB0N9nOgpmylgAAAABJRU5ErkJggg==',
            // 28 weathered greataxe
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAn9JREFUeNrsmrFOwzAQhp1QRBECAd2AoUXKBh0ZmOAFeIGWF2Fm4wV4gFaClYURJkaGLgxIwIDYQAgEAiEI/U1TJSZx7CaidyWWrERJOnz67uyzXcf3fTHqzRX/oBWQBWQBWUAWkAVkAfnPIUu6l81mU9Z87Xbb4Vz+pZqs1+ui0Wj4ATDHlmoIcABFb7Va8ln36oxMuAah2r34PeBIGHOBNcq1wGY4hHuQLMwaDygqKCfYUpYfdzodoYYxRdDc5kkAA5biKJwZEiEbGKUK6uYFSNmom2XQUQFZVTybyzM+uo1B9R0lm6U4wNWVyf794vqWUOfINEDVOimTgKrOTghvoSw77rMAUrHpqoBoD5ef8jq95LI2mJiTYTDYvDjYi0z8poDh7x3HoZWTz7dfojL3Y3PeG4tA2wCGByAU+F3Qoa1J+wSn18/OzeO7vL+f+oi1aQtIegqBTTU34wYgDoARSISSzubhzjZLQO0qBDa9tbFIbg4K2PseCekMPVxVm5d3b79s2gJSmFq0tStswmLcvEk9RFMhk2yiBbnJBdBoFRK2iZAdmVWIziZCFja5ABqvJ5Ns2u4FkYTU2YyrglibTLJ5vL9rZAnf9DapaRUDYZsbNSGXYbBZEeN9m1UxIW7OjtRJn0/Fk1YFeV5ZnN++yuchSz5FUKNw1eUmDG/UpvtHfBRHXestSduRdtj5aAXJ2eZAm8umNgOLKPyHeVJtBWlqk0qYZjJpYpMKoNxIU8PIZGcNxmAOBisv4xIWZgEO0zAeXqOyNZlHTUsa0iY3WeckJ5sDQ3KymctxOnWbvyBtJm4uNnP7YwRlm4mQgdG0fnL1pLWpO7H+q/YtwADFMTLO/0vp8QAAAABJRU5ErkJggg=='
            // END WEAPONS
        ];
        return string(abi.encodePacked(
            (lgAssetId < 5 ? '%253Cg%253E%253Cpath d=\'M23,48h3v1h3v1h2v1h1v1h1v1h1v3h-1v1h-17v-4h1v-1h1v-1h2v-1h2v-1h1z\' fill=\'var(--dms)\'/%253E%253Cpath d=\'M25,49h1v1h-1v1h-1v1h-1v1h-1v-1h1v-1h1v-1h1zM28,50h1v1h-1v1h-1v1h-2v1h-1v-1h1v-1h2v-1h1zM30,51h1v2h-1v1h-2v1h-1v-1h1v-1h2zM18,52h2v1h-1v2h-1v1h-1v-1h1v-1h-1v-1h1zM31,55h1v1h-1z\' fill=\'var(--dmb35)\'/%253E%253Cpath d=\'M23,48h3v1h3v1h2v1h1v1h1v1h1v3h-1v1h-4v-1h1v-1h2v-1h-1v-2h-3v-1h-2v-1h-1v1h-1v-1h-2v1h-1v1h-2v1h1v1h1v1h2v1h4v1h-11v-4h1v1h1v1h1v-1h-1v-1h-1v-1h1v-1h2v-1h2v-1h1z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M23,48h3v1h3v1h2v1h1v1h1v1h1v3h-1v1h-2v-1h2v-3h-1v-1h-1v-1h-2v-1h-3v-1h-3v1h-1v1h-2v1h-2v1h-1v4h-1v-4h1v-1h1v-1h2v-1h2v-1h1z\' fill=\'var(--dmb5)\'/%253E%253Cimage href=\'data:image/png;base64,' : '%253Cg%253E%253Cimage href=\'data:image/png;base64,'),
            WEAPONS[lgAssetId],
            '\'/%253E%253C/g%253E'
        ));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Strings.sol";
import "../Structs/PackedVars.sol";
import "../Structs/Monster.sol";
import "../Structs/Miner.sol";

library Calcs {
    using Strings for *;

    /**
    * @notice return a headgear stats array
    * @param gearId the gear id of the headgear item
    * @return array of int16 values representing the HP buff, AP buff, ATK buff, SPD buff, small asset id and large asset id of the item
    */
    function headgearStats(uint256 gearId)
        public
        pure
        returns (int16[6] memory)
    {
        int16[6][17] memory GEAR = [
            [int16(0),0,0,0,    0,3],       // 0  | C | none

            // uncommon = 8 total
            // Health & Attack
            [int16(3),0,5,0,    1,7],       // 1  | U | bandana
            [int16(6),0,2,0,    2,10],      // 2  | U | leather hat
            [int16(2),0,6,0,    3,11],      // 3  | U | rusty helm
            [int16(4),0,4,0,    4,8],       // 4  | U | feathered cap

            // rare = 14 total
            // Health & Armor & Attack
            [int16(7),5,2,0,    5,4],       // 5  | R | enchanted crown
            [int16(5),5,4,0,    6,12],      // 6  | R | bronze helm
            [int16(2),4,8,0,    7,0],       // 7  | R | assassin's mask

            // epic = 24 total
            // Health & Armor & Attack
            [int16(6),12,6,0,    8,13],     // 8  | E | iron helm
            [int16(9),6,9,0,    15,16],     // 9  | E | skull helm
            [int16(9),6,9,0,    14,6],      // 10 | E | charmed headband
            [int16(9),6,9,0,    12,9],      // 11 | E | ranger cap
            [int16(9),6,9,0,    10,1],      // 12 | E | misty hood

            // legendary = 42 total
            // Health & Armor & Attack & Speed
            [int16(13),10,13,6,    16,17],  // 13 | L | phoenix helm
            [int16(13),10,13,6,    13,5],   // 14 | L | ancient mask
            [int16(13),10,13,6,    11,15],  // 15 | L | genesis helm
            [int16(13),10,13,6,    9,14]    // 16 | L | soul shroud
        ];
        return GEAR[gearId];
    }

    /**
    * @notice return an armor stats array
    * @param gearId the gear id of the armor item
    * @return array of int16 values representing the HP buff, AP buff, ATK buff, SPD buff, small asset id and large asset id of the item
    */
    function armorStats(uint256 gearId)
        public
        pure
        returns (int16[6] memory)
    {
        int16[6][17] memory GEAR = [
            [int16(0),0,0,0,    0,0],       // 17 | C | cotton shirt

            // uncommon = 8 total
            // Health & Armor
            [int16(3),5,0,0,    0,1],       // 18 | U | thick vest
            [int16(4),4,0,0,    0,2],       // 19 | U | leather chestplate
            [int16(2),6,0,0,    3,3],       // 20 | U | rusty chainmail
            [int16(6),2,0,0,    0,4],       // 21 | U | longcoat

            // rare = 14 total
            // Health & Armor & Attack
            [int16(6),4,4,0,    3,5],       // 22 | R | chainmail
            [int16(5),6,3,0,    0,6],       // 23 | R | bronze chestplate
            [int16(6),6,2,0,    0,7],       // 24 | R | blessed armor

            // epic = 24 total
            // Health & Armor & Attack
            [int16(6),7,11,0,    0,8],      // 25 | E | iron chestplate
            [int16(9),9,6,0,    2,9],       // 26 | E | skull armor
            [int16(9),9,6,0,    1,10],      // 27 | E | cape of deception
            [int16(9),9,6,0,    1,11],      // 28 | E | mystic cloak
            [int16(9),9,6,0,    4,12],      // 29 | E | shimmering cloak

            // legendary = 42 total
            // Health & Armor & Attack & Speed
            [int16(13),13,10,6,    0,13],   // 30 | L | phoenix chestplate
            [int16(13),13,10,6,    0,14],   // 31 | L | ancient robe
            [int16(13),13,10,6,    1,15],   // 32 | L | genesis cloak
            [int16(13),13,10,6,    1,16]    // 33 | L | soul cloak
        ];
        return GEAR[gearId - 17];
    }

    /**
    * @notice return a pants stats array
    * @param gearId the gear id of the pants item
    * @return array of int16 values representing the HP buff, AP buff, ATK buff, SPD buff, small asset id and large asset id of the item
    */
    function pantsStats(uint256 gearId)
        public
        pure
        returns (int16[6] memory)
    {
        int16[6][17] memory GEAR = [
            [int16(0),0,0,0,    0,0],       // 34 | C | cotton pants

            // uncommon = 8 total
            // Armor & Speed
            [int16(0),6,0,2,    0,0],       // 35 | U | thick pants
            [int16(0),4,0,4,    0,0],       // 36 | U | leather greaves
            [int16(0),3,0,5,    3,0],       // 37 | U | rusty chainmail pants
            [int16(0),2,0,6,    0,0],       // 38 | U | reliable leggings

            // rare = 14 total
            // Health & Armor & Speed
            [int16(2),4,0,8,    0,0],       // 39 | R | padding leggings
            [int16(3),5,0,6,    1,0],       // 40 | R | bronze greaves
            [int16(5),5,0,4,    0,0],       // 41 | R | enchanted pants

            // epic = 24 total
            // Health & Armor & Speed
            [int16(8),9,0,7,    1,0],       // 42 | E | iron greaves
            [int16(6),9,0,9,    0,0],       // 43 | E | skull greaves
            [int16(6),9,0,9,    0,0],       // 44 | E | swift leggings
            [int16(6),9,0,9,    0,0],       // 45 | E | forest greaves
            [int16(6),9,0,9,    0,0],       // 46 | E | silent leggings

            // legendary = 42 total
            // Health & Armor & Attack & Speed
            [int16(10),13,6,13,    0,0],    // 47 | L | phoenix greaves
            [int16(10),13,6,13,    2,0],    // 48 | L | ancient greaves
            [int16(10),13,6,13,    0,0],    // 49 | L | genesis greaves
            [int16(10),13,6,13,    0,0]     // 50 | L | soul greaves
        ];
        return GEAR[gearId - 34];
    }

    /**
    * @notice return a footwear stats array
    * @param gearId the gear id of the footwear item
    * @return array of int16 values representing the HP buff, AP buff, ATK buff, SPD buff, small asset id and large asset id of the item
    */
    function footwearStats(uint256 gearId)
        public
        pure
        returns (int16[6] memory)
    {
        int16[6][17] memory GEAR = [
            [int16(0),0,0,0,    0,0],       // 51 | C | none

            // uncommon = 8 total
            // Health & Speed
            [int16(3),0,0,5,    1,0],       // 52 | U | sturdy cleats
            [int16(4),0,0,4,    1,0],       // 53 | U | leather boots
            [int16(6),0,0,2,    2,0],       // 54 | U | rusty boots
            [int16(2),0,0,6,    0,0],       // 55 | U | lightweight shoes

            // rare = 14 total
            // Health & Attack & Speed
            [int16(2),0,3,9,    2,0],       // 56 | R | bandit's shoes
            [int16(5),0,4,5,    2,0],       // 57 | R | bronze boots
            [int16(6),0,5,3,    6,0],       // 58 | R | heavy boots

            // epic = 24 total
            // Health & Attack & Speed
            [int16(9),0,10,5,    2,0],      // 59 | E | iron boots
            [int16(9),0,6,9,    1,0],       // 60 | E | skull boots
            [int16(9),0,6,9,    1,0],       // 61 | E | enchanted boots
            [int16(9),0,6,9,    4,0],       // 62 | E | jaguarpaw boots
            [int16(9),0,6,9,    3,0],       // 63 | E | lightfoot boots

            // legendary = 42 total
            // Health & Armor & Attack & Speed
            [int16(13),6,10,13,    5,0],    // 64 | L | phoenix boots
            [int16(13),6,10,13,    1,0],    // 65 | L | ancient boots
            [int16(13),6,10,13,    1,0],    // 66 | L | genesis boots
            [int16(13),6,10,13,    2,0]     // 67 | L | soul boots
        ];
        return GEAR[gearId - 51];
    }

    /**
    * @notice return a weapon stats array
    * @param gearId the gear id of the weapon item
    * @return array of int16 values representing the HP buff, AP buff, ATK buff, SPD buff, small asset id and large asset id of the item
    */
    function weaponStats(uint256 gearId)
        public
        pure
        returns (int16[6] memory)
    {
        int16[6][29] memory GEAR = [
            [int16(0),0,0,0,    0,5],       // 68 | C | fists

            // uncommon = 8 total
            // Attack & Speed
            [int16(0),0,4,4,    1,6],       // 69 | U | rusty sword
            [int16(0),0,6,2,    8,20],      // 70 | U | wooden club
            [int16(0),0,5,3,    7,1],       // 71 | U | pickaxe
            [int16(0),0,2,6,    6,0],       // 72 | U | brass knuckles

            // rare = 14 total
            // Armor & Attack & Speed
            [int16(0),2,6,6,    19,28],     // 73 | R | weathered greataxe
            [int16(0),2,6,6,    5,18],      // 74 | R | polished scepter
            [int16(0),2,6,6,    14,24],     // 75 | R | poisoned spear
            [int16(0),2,6,6,    11,3],      // 76 | R | kusarigama
            [int16(0),4,4,6,    1,7],       // 77 | R | bronze sword
            [int16(0),4,4,6,    4,15],      // 78 | R | bronze staff
            [int16(0),4,4,6,    13,23],     // 79 | R | bronze shortsword
            [int16(0),4,4,6,    2,9],       // 80 | R | bronze daggers
            [int16(0),2,4,8,    18,27],     // 81 | R | dusty scmitar
            [int16(0),2,4,8,    15,25],     // 82 | R | silver wand
            [int16(0),2,4,8,    12,22],     // 83 | R | dual handaxes
            [int16(0),2,4,8,    10,21],     // 84 | R | dual shortswords

            // epic = 24 total
            // Armor & Attack & Speed
            [int16(0),7,9,8,    1,8],       // 85 | E | holy sword
            [int16(0),7,9,8,    4,16],      // 86 | E | holy staff
            [int16(0),7,9,8,    3,12],      // 87 | E | holy bow
            [int16(0),7,9,8,    2,10],      // 88 | E | holy daggers
            [int16(0),5,9,10,    17,26],    // 89 | E | soulcutter
            [int16(0),5,9,10,    4,17],     // 90 | E | shadow staff
            [int16(0),5,9,10,    3,13],     // 91 | E | shadow bow
            [int16(0),5,9,10,    9,2],      // 92 | E | shadowblades

            // legendary = 42 total
            // Health & Armor & Attack & Speed
            [int16(6),10,13,13,    16,4],   // 93 | L | phoenix blade
            [int16(6),10,13,13,    5,19],   // 94 | L | ancient scepter
            [int16(6),10,13,13,    3,14],   // 95 | L | genesis bow
            [int16(6),10,13,13,    2,11]    // 96 | L | soul daggers
        ];

        return GEAR[gearId - 68];
    }

    /**
    * @notice return a uint16 value from a bytes32 hash, given an offset
    * @param hash the bytes32 hash to retrieve a uint16 from
    * @param offset the offset from 0 to grab the data from
    * @return uint16 value cast to a uint256
    */
    function _hashToUint16(bytes32 hash, uint256 offset)
        internal
        pure
        returns (uint256)
    {
        require(30 >= offset, "oob");
        return uint256((hash << (offset * 8)) >> 240);
    }

    /**
    * @notice calculate a gear type
    * @param typeVal a uint value between 0-255
    * @return uint8 value of gear type for an item
    */
    function gType(uint8 typeVal)
        public
        pure
        returns (uint8)
    {
        /*
        0  | common     | 0-127   | 1/2   | 128 | 50%    | 0%
        1  | uncommon 1 | 128-151 | 3/32  | 24  | 9.375% | 18.75%
        2  | uncommon 2 | 152-175 | 3/32  | 24  | 9.375% | 18.75%
        3  | uncommon 3 | 176-199 | 3/32  | 24  | 9.375% | 18.75%
        4  | uncommon 4 | 200-223 | 3/32  | 24  | 9.375% | 18.75%
        5  | rare 1     | 224-232 | 9/256 | 9   | 3.516% | 7.031%
        6  | rare 2     | 233-241 | 9/256 | 9   | 3.516% | 7.031%
        7  | rare 3     | 242-250 | 9/256 | 9   | 3.516% | 7.031%
        8  | epic 1     | 251-252 | 1/32  | 2   | 0.781% | 1.563%
        9  | epic 2     | 253-254 | 1/32  | 2   | 0.781% | 1.563%
        10 | legendary  | 255     | 1/256 | 1   | 0.391% | 0.781%
        */

        // Sorting from middle-out (reduce gas by probability)
        if(typeVal < 128){
            return 0;
        } else {
            if(typeVal < 224) {
                if(typeVal < 176){
                    return typeVal < 152 ? 1 : 2;
                } else {
                    return typeVal < 200 ? 3 : 4;
                }
            } else {
                if(typeVal < 251){
                    if(typeVal < 233){
                        return 5;
                    } else {
                        return typeVal < 242 ? 6 : 7;
                    }
                } else {
                    if(typeVal < 253){
                        return 8;
                    } else {
                        return typeVal < 255 ? 9 : 10;
                    }
                }
            }
        }
    }

    /**
    * @notice calculate a chamber type
    * @param hash the bytes32 hash value of a chamber
    * @return uint256 value of chamber type
    */
    function _cType(bytes32 hash)
        internal
        pure
        returns (uint256)
    {
        return (uint256(uint8(hash[4])) / 32);
    }

    /**
    * @notice calculate a chamber type and return as a string
    * @param hash the bytes32 hash value of a chamber
    * @return string of chamber type
    */
    function ctString(bytes32 hash)
        external
        pure
        returns (string memory)
    {
        return _cType(hash).toString();
    }

    /**
    * @notice calculate an encounter type
    * @param hash the bytes32 hash value of a chamber
    * @return uint8 value of the encounter type
    */
    function _eType(bytes32 hash)
        internal
        pure
        returns (uint8)
    {
        uint256 typeVal = uint256(_hashToUint16(hash,14));

        /*

        #  | type       | value range | size | probability
        ---+------------+-------------+------+-------------------
        0  | slime      | 0-6143      | 6144 | 9.375%
        1  | crawler    | 6144-12287  | 6144 | 9.375%
        2  | poison bat | 12288-18431 | 6144 | 9.375%
        3  | skeleton   | 18432-24575 | 6144 | 9.375%
        4  | trap       | 24576-28475 | 3900 | 5.950927734375%
        5  | curse      | 28476-32375 | 3900 | 5.950927734375%
        6  | buff       | 32376-36275 | 3900 | 5.950927734375%
        7  | debuff     | 36276-40175 | 3900 | 5.950927734375%
        8  | gold       | 40176-44075 | 3900 | 5.950927734375%
        9  | thief      | 44076-47975 | 3900 | 5.950927734375%
        10 | empty      | 47976-51875 | 3900 | 5.950927734375%
        11 | rest       | 51876-55775 | 3900 | 5.950927734375%
        12 | gear       | 55776-58780 | 3005 | 4.58526611328125%
        13 | merchant   | 58781-61785 | 3005 | 4.58526611328125%
        14 | treasure   | 61786-63600 | 1815 | 2.76947021484375%
        15 | heal       | 63601-65415 | 1815 | 2.76947021484375%
        16 | revive     | 65416-65495 | 80   | 0.1220703125%
        17 | armory     | 65496-65535 | 40   | 0.06103515625%

        */

        // Sorting from middle-out (reduce gas by probability)
        if(typeVal < 32376){
            if(typeVal < 18432){
                if(typeVal < 12288){
                    return typeVal < 6144 ? 0 : 1;
                } else {
                    return 2;
                }
            } else {
                if(typeVal < 24576){
                    return 3;
                } else {
                    return typeVal < 28476 ? 4 : 5;
                }
            }
        } else {
            if(typeVal < 47976){
                if(typeVal < 40176){
                    return typeVal < 36276 ? 6 : 7;
                } else {
                    return typeVal < 44076 ? 8 : 9;
                }
            } else {
                if(typeVal < 55776){
                    return typeVal < 51876 ? 10 : 11;
                } else {
                    if(typeVal < 61786){
                        return typeVal < 58781 ? 12 : 13;
                    } else {
                        if(typeVal < 63601){
                            return 14;
                        } else {
                            if(typeVal < 65416){
                                return 15;
                            } else {
                                return typeVal < 65496 ? 16 : 17;
                            }
                        }
                    }
                }
            }
        }

    }

    /**
    * @notice calculate an encounter type and return as a string
    * @param hash the bytes32 hash value of a chamber
    * @return string of the encounter type
    */
    function etString(bytes32 hash)
        external
        pure
        returns (string memory)
    {
        return _eType(hash).toString();
    }

    /**
    * @notice calculate an encounter outcome
    * @param hash chamber hash
    * @param miner the current Miner instance
    * @return array representing the post-encounter miner struct
    */
    function chamberStats(bytes32 hash, Miner memory miner)
        external
        pure
        returns (Miner memory)
    {
        // Define chamberData
        PackedVars memory chamberData;

        // Define encounter type for this chamber
        chamberData.var_uint8_1 = _eType(hash);

        // Pre-encounter calcuations

        // Check Miner's class
        if(miner.classId == 0){
            // Miner is a warrior! Restore 2 armor
            miner.armor = miner.armor + 2;
            // Check if armor is greater than baseArmor
            if(miner.armor > miner.baseArmor){
                // Set armor to baseArmor
                miner.armor = miner.baseArmor;
            }
        } else if(miner.classId == 2){
            // Miner is a ranger! Restore 3 health and add 2 to baseHealth
            // Restore health
            miner.health = miner.health + 3;
            // Check if health is greater than baseHealth
            if(miner.health > miner.baseHealth){
                // Set health to baseHealth
                miner.health = miner.baseHealth;
            }
            // Add 2 to baseHealth
            miner.baseHealth = miner.baseHealth + 2;
        }

        // Check if Miner is cursed and make sure this isn't a curse chamber to avoid doing double damage
        if(miner.curseTurns > 0 && chamberData.var_uint8_1 != 5){
            // Miner is cursed!
            // Calculate curse damage taken (10 percent of current health or 5 if Miner has less than 50 health)
            chamberData.var_int16_1 = miner.health < 50 ? int16(5) : (miner.health / 10);
            // Set Miner health
            miner.health = miner.health - chamberData.var_int16_1;
            // Check if Miner is dead but has a revive
            if(miner.health < 1 && miner.revives > 0){
                // Revive with 1/4 health and 1/4 armor IF current armor is less than current armor
                miner.health = miner.baseHealth / 4;
                miner.armor = miner.armor < (miner.baseArmor / 4) ? (miner.baseArmor / 4) : miner.armor;
                // Remove revive from inventory
                miner.revives--;
            }
            // Remove curse turn
            miner.curseTurns--;
        }

        // Encounter calculations

        // Check if Miner is still alive after potential curse damage has been calculated
        if(miner.health > 0){
            // Miner is alive! Loop through potential encounter types to calculate results
            if(chamberData.var_uint8_1 < 4){ // MONSTER
                // Define monster
                Monster memory monster;
                // Check what kind of monster we've encountered and adjust stats
                if(chamberData.var_uint8_1 == 0){ // SLIME
                    monster.health = int16(int8(uint8(hash[0]) % 48)) + 70 + (10 * int16(uint16(miner.currentChamber / 8)));
                    monster.attack = int16(int8(uint8(hash[2]) % 24)) + 15 + (5 * int16(uint16(miner.currentChamber / 8)));
                    monster.speed = int16(int8(uint8(hash[3]) % 24)) + 35;
                    monster.mtype = chamberData.var_uint8_1;
                } else if(chamberData.var_uint8_1 == 1){ // CRAWLER
                    monster.health = int16(int8(uint8(hash[0]) % 48)) + 65 + (10 * int16(uint16(miner.currentChamber / 8)));
                    monster.attack = int16(int8(uint8(hash[2]) % 24)) + 25 + (5 * int16(uint16(miner.currentChamber / 8)));
                    monster.speed = int16(int8(uint8(hash[3]) % 24)) + 50;
                    monster.mtype = chamberData.var_uint8_1;
                } else if(chamberData.var_uint8_1 == 2){ // POISON BAT
                    monster.health = int16(int8(uint8(hash[0]) % 48)) + 60 + (10 * int16(uint16(miner.currentChamber / 8)));
                    monster.attack = int16(int8(uint8(hash[2]) % 24)) + 15 + (5 * int16(uint16(miner.currentChamber / 8)));
                    monster.speed = int16(int8(uint8(hash[3]) % 24)) + 55;
                    monster.mtype = chamberData.var_uint8_1;
                } else { // SKELETON
                    monster.health = int16(int8(uint8(hash[0]) % 48)) + 80 + (10 * int16(uint16(miner.currentChamber / 8)));
                    monster.attack = int16(int8(uint8(hash[2]) % 24)) + 30 + (5 * int16(uint16(miner.currentChamber / 8)));
                    monster.speed = int16(int8(uint8(hash[3]) % 24)) + 40;
                    monster.mtype = chamberData.var_uint8_1;
                }

                // Define turn counter
                chamberData.var_uint8_2 = 0;

                // Loop through battle turns until someone dies
                while(miner.health > 0 && monster.health > 0){
                    // Check variable monster turn speed vs. variable Miner turn speed
                    if((monster.speed + int16(int8(uint8(keccak256(abi.encodePacked(hash,chamberData.var_uint8_2))[7]) % 24))) > (miner.speed + int16(int8(uint8(keccak256(abi.encodePacked(hash,chamberData.var_uint8_2))[6]) % 24)))){
                        // Monster goes first

                        // Get random offset from monster's base attack for this turn
                        chamberData.var_int16_4 = int16(int8(uint8(keccak256(abi.encodePacked(hash,chamberData.var_uint8_2))[14]) % 8));
                        // Adjust monster's attack modifier to be a range of -4 to 4, no zero (positive numbers will be a buff, negative will be debuff)
                        chamberData.var_int16_4 = chamberData.var_int16_4 - (chamberData.var_int16_4 < 4 ? int16(4) : int16(3));

                        // Calculate total damage taken
                        chamberData.var_int16_2 = monster.attack + chamberData.var_int16_4;

                        // Sub 1/3 of total damage from total damage for armor damage (do this instead of dmg / 3 * 2 because of integer floor rounding - would favor health damage instead of armor)
                        // Value is 1/2 instead of 1/3 for Warriors
                        chamberData.var_int16_3 = chamberData.var_int16_2 - (chamberData.var_int16_2 / (miner.classId == 0 ? int16(2) : int16(3)));

                        // Sub armor damage from armor
                        miner.armor = miner.armor - chamberData.var_int16_3;
                        // Sub health damage from health
                        miner.health = miner.health - (chamberData.var_int16_2 - chamberData.var_int16_3);
                        // If armor has been broken, pass excess damage to health and set armor to zero
                        if(miner.armor < 0){
                            miner.health = miner.health + miner.armor;
                            miner.armor = 0;
                        }

                        // Check if Miner is dead
                        if(miner.health < 1){
                            // Check if Miner has a revive
                            if(miner.revives > 0){
                                // Revive with 1/4 health and 1/4 armor IF current armor is less than current armor
                                miner.health = miner.baseHealth / 4;
                                miner.armor = miner.armor < (miner.baseArmor / 4) ? (miner.baseArmor / 4) : miner.armor;
                                // Remove revive from inventory
                                miner.revives--;
                            } else {
                                // He/she dead, bro
                                break;
                            }
                        }

                        // Get random offset from Miner's base attack for this turn
                        chamberData.var_int16_1 = int16(int8(uint8(keccak256(abi.encodePacked(hash,chamberData.var_uint8_2))[13]) % 8));
                        // Adjust Miner's attack modifier to be a range of -4 to 4, no zero (negative numbers will be a buff, positive will be debuff)
                        chamberData.var_int16_1 = chamberData.var_int16_1 - (chamberData.var_int16_1 < 4 ? int16(4) : int16(3));

                        // Attack monster
                        monster.health = monster.health - miner.attack - chamberData.var_int16_1 - (miner.buffTurns > 0 ? int16(4) : int16(0)) + (miner.debuffTurns > 0 ? int16(4) : int16(0));

                    } else {
                        // Miner goes first

                        // Get random offset from Miner's base attack for this turn
                        chamberData.var_int16_1 = int16(int8(uint8(keccak256(abi.encodePacked(hash,chamberData.var_uint8_2))[13]) % 8));
                        // Adjust Miner's attack modifier to be a range of -4 to 4, no zero (negative numbers will be a buff, positive will be debuff)
                        chamberData.var_int16_1 = chamberData.var_int16_1 - (chamberData.var_int16_1 < 4 ? int16(4) : int16(3));

                        // Attack monster
                        monster.health = monster.health - miner.attack - chamberData.var_int16_1 - (miner.buffTurns > 0 ? int16(4) : int16(0)) + (miner.debuffTurns > 0 ? int16(4) : int16(0));

                        // Check if monster is dead
                        if(monster.health < 1){
                            // It dead, bro
                            break;
                        } else {

                            // Get random offset from monster's base attack for this turn
                            chamberData.var_int16_4 = int16(int8(uint8(keccak256(abi.encodePacked(hash,chamberData.var_uint8_2))[14]) % 8));
                            // Adjust monster's attack modifier to be a range of -4 to 4, no zero (positive numbers will be a buff, negative will be debuff)
                            chamberData.var_int16_4 = chamberData.var_int16_4 - (chamberData.var_int16_4 < 4 ? int16(4) : int16(3));

                            // Calculate total damage taken
                            chamberData.var_int16_2 = monster.attack + chamberData.var_int16_4;

                            // Sub 1/3 of total damage from total damage for armor damage (do this instead of dmg / 3 * 2 because of integer floor rounding - would favor health damage instead of armor)
                            // Value is 1/2 instead of 1/3 for Warriors
                            chamberData.var_int16_3 = chamberData.var_int16_2 - (chamberData.var_int16_2 / (miner.classId == 0 ? int16(2) : int16(3)));

                            // Sub armor damage from armor
                            miner.armor = miner.armor - chamberData.var_int16_3;
                            // Sub health damage from health
                            miner.health = miner.health - (chamberData.var_int16_2 - chamberData.var_int16_3);
                            // If armor has been broken, pass excess damage to health and set armor to zero
                            if(miner.armor < 0){
                                miner.health = miner.health + miner.armor;
                                miner.armor = 0;
                            }

                            // Check if Miner is dead but has a revive
                            if(miner.health < 1 && miner.revives > 0){
                                // Revive with 1/4 health and 1/4 armor IF current armor is less than current armor
                                miner.health = miner.baseHealth / 4;
                                miner.armor = miner.armor < (miner.baseArmor / 4) ? (miner.baseArmor / 4) : miner.armor;
                                // Remove revive from inventory
                                miner.revives--;
                            }
                        }
                    }
                    // Add one to loop/turn count
                    chamberData.var_uint8_2++;
                }
            } else if(chamberData.var_uint8_1 == 4){ // TRAP

                // Calculate trap damage
                chamberData.var_int16_2 = int16(int8(uint8(hash[2]) % 16) + 32);

                // Check if Miner is an assassin
                if(miner.classId == 3){
                    // // Miner is an assassin! Cut trap damage in half
                    chamberData.var_int16_2 = (chamberData.var_int16_2 / 2);
                }

                // Sub 1/3 of total damage from total damage for armor damage (do this instead of dmg / 3 * 2 because of integer floor rounding - would favor health damage instead of armor)
                // Value is 1/2 instead of 1/3 for Warriors
                chamberData.var_int16_3 = chamberData.var_int16_2 - (chamberData.var_int16_2 / (miner.classId == 0 ? int16(2) : int16(3)));

                // Sub armor damage from armor
                miner.armor = miner.armor - chamberData.var_int16_3;
                // Sub health damage from health
                miner.health = miner.health - (chamberData.var_int16_2 - chamberData.var_int16_3);
                // If armor has been broken, pass excess damage to health and set armor to zero
                if(miner.armor < 0){
                    miner.health = miner.health + miner.armor;
                    miner.armor = 0;
                }

                // Check if Miner is dead but has a revive
                if(miner.health < 1 && miner.revives > 0){
                    // Revive with 1/4 health and 1/4 armor IF current armor is less than current armor
                    miner.health = miner.baseHealth / 4;
                    miner.armor = miner.armor < (miner.baseArmor / 4) ? (miner.baseArmor / 4) : miner.armor;
                    // Remove revive from inventory
                    miner.revives--;
                }
            } else if(chamberData.var_uint8_1 == 5){ // CURSE

                // Check if the Miner IS NOT a mage
                if(miner.classId != 1){
                    // Miner is not a mage! Curse this mf
                    // Calculate curse damage taken (10 percent of current health or 5 if Miner has less than 50 health)
                    chamberData.var_int16_1 = miner.health < 50 ? int16(5) : (miner.health / 10);

                    // Sub curse damage from health
                    miner.health = miner.health - chamberData.var_int16_1;

                    // Check if Miner is dead but has a revive
                    if(miner.health < 1 && miner.revives > 0){
                        // Revive with 1/4 health and 1/4 armor IF current armor is less than current armor
                        miner.health = miner.baseHealth / 4;
                        miner.armor = miner.armor < (miner.baseArmor / 4) ? (miner.baseArmor / 4) : miner.armor;
                        // Remove revive from inventory
                        miner.revives--;
                    }

                    // Add curse for 4 more chambers
                    miner.curseTurns = 4;
                }

            } else if(chamberData.var_uint8_1 == 6){ // BUFF
                // Add buff for 3 chambers (adding one extra because it will be removed at the end of loop)
                miner.buffTurns = miner.buffTurns + 4;
            } else if(chamberData.var_uint8_1 == 7){ // DEBUFF
                // Add debuff for 3 chambers (adding one extra because it will be removed at the end of loop)
                miner.debuffTurns = miner.debuffTurns + 4;
            } else if(chamberData.var_uint8_1 == 8){ // GOLD
                // Add gold to inventory
                miner.gold = miner.gold + uint16(uint8(hash[8]) % 24) + 2;

            } else if(chamberData.var_uint8_1 == 9){ // THIEF
                // Check if the Miner is an assassin
                if(miner.classId == 3){
                    // Miner is an assassin! Give a low-tier item (uncommon or rare)

                    // Gear type (0 == headgear, 1 == armor, 2 == pants, 3 == footwear, 4 == weapon)
                    chamberData.var_uint8_2 = uint8(hash[13]) % 5;

                    // Gear rarity
                    // Add 128 to modulo 123 to get item from uncommon or rare rarity tiers
                    chamberData.var_uint8_3 = gType((uint8(hash[16 + chamberData.var_uint8_2]) % 123) + 128);

                    // Gear ID
                    chamberData.var_uint8_4 = (chamberData.var_uint8_2 < 4 ? chamberData.var_uint8_3 : (chamberData.var_uint8_3 > 4 ? (((chamberData.var_uint8_3 - 5) * 4) + 8) : chamberData.var_uint8_3)) + (17 * chamberData.var_uint8_2);

                    // Define array for gearItem stats
                    int16[6] memory gearItem;

                    // Check which gear type and add values appropriately
                    if(chamberData.var_uint8_2 == 0){
                        // Get headgear stats
                        gearItem = headgearStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        if(chamberData.var_uint8_4 > miner.headgearId){
                            miner.headgearId = chamberData.var_uint8_4;
                        }
                    } else if(chamberData.var_uint8_2 == 1){
                        // Get armor stats
                        gearItem = armorStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        if(chamberData.var_uint8_4 > miner.armorId){
                            miner.armorId = chamberData.var_uint8_4;
                        }
                    } else if(chamberData.var_uint8_2 == 2){
                        // Get pants stats
                        gearItem = pantsStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        if(chamberData.var_uint8_4 > miner.pantsId){
                            miner.pantsId = chamberData.var_uint8_4;
                        }
                    } else if(chamberData.var_uint8_2 == 3){
                        // Get footwear stats
                        gearItem = footwearStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        if(chamberData.var_uint8_4 > miner.footwearId){
                            miner.footwearId = chamberData.var_uint8_4;
                        }
                    } else {
                        // Get weapon stats
                        gearItem = weaponStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        if(chamberData.var_uint8_4 > miner.weaponId){
                            miner.weaponId = chamberData.var_uint8_4;
                        }
                    }
                    // Add gear health buff to baseHealth
                    miner.baseHealth = miner.baseHealth + gearItem[0];
                    // Add gear health buff to health
                    miner.health = miner.health + gearItem[0];
                    // Add gear armor buff to baseArmor
                    miner.baseArmor = miner.baseArmor + gearItem[1];
                    // Add gear armor buff to armor
                    miner.armor = miner.armor + gearItem[1];
                    // Add gear attack buff to attack
                    miner.attack = miner.attack + gearItem[2];
                    // Add gear speed buff to speed
                    miner.speed = miner.speed + gearItem[3];

                } else {
                    // Miner IS NOT an assassin, let's steal some gold
                    // uint16 goldStolen
                    chamberData.var_uint16_1 = uint16(uint8(hash[8]) % 16) + 1;

                    // Remove stolen gold from Miner
                    miner.gold = miner.gold > chamberData.var_uint16_1 ? (miner.gold - chamberData.var_uint16_1) : 0;
                }
            // } else if(chamberData.var_uint8_1 == 10){ // EMPTY
                // Nothing happens here
            } else if(chamberData.var_uint8_1 == 11){ // REST
                // Restore health
                miner.health = miner.health + int16(int8(uint8(hash[9]) % 24)) + 7;

                // Check if health is greater than baseHealth
                if(miner.health > miner.baseHealth){
                    // Miner is way too healthy, set health to baseHealth
                    miner.health = miner.baseHealth;
                }

            } else if(chamberData.var_uint8_1 == 12){ // GEAR
                // Gear type (0 == headgear, 1 == armor, 2 == pants, 3 == footwear, 4 == weapon)
                chamberData.var_uint8_2 = uint8(hash[13]) % 5;

                // Gear rarity
                // If less than 128, add 128 to the hash val (rarity tiers start at uncommon and double chance for each tier)
                chamberData.var_uint8_3 = gType((uint8(hash[16 + chamberData.var_uint8_2]) < 128 ? uint8(hash[16 + chamberData.var_uint8_2]) + 128 : uint8(hash[16 + chamberData.var_uint8_2])));

                // Gear ID
                chamberData.var_uint8_4 = (chamberData.var_uint8_2 < 4 ? (chamberData.var_uint8_3 > 8 ? (((chamberData.var_uint8_3 - 9) * 4) + 9 + miner.classId) : chamberData.var_uint8_3) : (chamberData.var_uint8_3 > 4 ? (((chamberData.var_uint8_3 - 5) * 4) + 5 + miner.classId) : chamberData.var_uint8_3)) + (17 * chamberData.var_uint8_2);

                // Define array for gearItem stats
                int16[6] memory gearItem;

                // Check which gear type and add values appropriately
                if(chamberData.var_uint8_2 == 0){
                    // Get headgear stats
                    gearItem = headgearStats(chamberData.var_uint8_4);
                    // If gearId is higher than Miner's current gearId, reassign visible gear
                    if(chamberData.var_uint8_4 > miner.headgearId){
                        miner.headgearId = chamberData.var_uint8_4;
                    }
                } else if(chamberData.var_uint8_2 == 1){
                    // Get armor stats
                    gearItem = armorStats(chamberData.var_uint8_4);
                    // If gearId is higher than Miner's current gearId, reassign visible gear
                    if(chamberData.var_uint8_4 > miner.armorId){
                        miner.armorId = chamberData.var_uint8_4;
                    }
                } else if(chamberData.var_uint8_2 == 2){
                    // Get pants stats
                    gearItem = pantsStats(chamberData.var_uint8_4);
                    // If gearId is higher than Miner's current gearId, reassign visible gear
                    if(chamberData.var_uint8_4 > miner.pantsId){
                        miner.pantsId = chamberData.var_uint8_4;
                    }
                } else if(chamberData.var_uint8_2 == 3){
                    // Get footwear stats
                    gearItem = footwearStats(chamberData.var_uint8_4);
                    // If gearId is higher than Miner's current gearId, reassign visible gear
                    if(chamberData.var_uint8_4 > miner.footwearId){
                        miner.footwearId = chamberData.var_uint8_4;
                    }
                } else {
                    // Get weapon stats
                    gearItem = weaponStats(chamberData.var_uint8_4);
                    // If gearId is higher than Miner's current gearId, reassign visible gear
                    if(chamberData.var_uint8_4 > miner.weaponId){
                        miner.weaponId = chamberData.var_uint8_4;
                    }
                }
                // Add gear health buff to baseHealth
                miner.baseHealth = miner.baseHealth + gearItem[0];
                // Add gear health buff to health
                miner.health = miner.health + gearItem[0];
                // Add gear armor buff to baseArmor
                miner.baseArmor = miner.baseArmor + gearItem[1];
                // Add gear armor buff to armor
                miner.armor = miner.armor + gearItem[1];
                // Add gear attack buff to attack
                miner.attack = miner.attack + gearItem[2];
                // Add gear speed buff to speed
                miner.speed = miner.speed + gearItem[3];

            } else if(chamberData.var_uint8_1 == 13){ // MERCHANT

                // Check if Miner has enough gold for item (min 25)
                if(miner.gold > 24){
                    // Miner can afford to purchase some gear, assign gear type
                    // Gear type (0 == headgear, 1 == armor, 2 == pants, 3 == footwear, 4 == weapon)
                    chamberData.var_uint8_2 = uint8(hash[13]) % 5;

                    // Check what the Miner can afford
                    if(miner.gold < 50){
                        // Buy uncommon item

                        // Gear rarity - assign 1-4 for uncommon
                        chamberData.var_uint8_3 = (uint8(hash[16 + chamberData.var_uint8_2]) % 4) + 1;
                        // Pay the merchant
                        miner.gold = miner.gold - 25;
                    } else if (miner.gold < 75){
                        // Buy rare item

                        // Gear rarity - assign 5-7 for rare
                        chamberData.var_uint8_3 = (uint8(hash[16 + chamberData.var_uint8_2]) % 3) + 5;
                        // Pay the merchant
                        miner.gold = miner.gold - 50;
                    }
                    else if (miner.gold < 100){
                        // Buy epic item

                        // Gear rarity - assign 8-9 for epic
                        chamberData.var_uint8_3 = (uint8(hash[16 + chamberData.var_uint8_2]) % 2) + 8;
                        // Pay the merchant
                        miner.gold = miner.gold - 75;
                    } else {
                        // Buy legendary item

                        // Gear rarity - assign 10 for legendary
                        chamberData.var_uint8_3 = 10;
                        // Pay the merchant
                        miner.gold = miner.gold - 100;
                    }

                    // Determine Gear ID
                    chamberData.var_uint8_4 = (chamberData.var_uint8_2 < 4 ? (chamberData.var_uint8_3 > 8 ? (((chamberData.var_uint8_3 - 9) * 4) + 9 + miner.classId) : chamberData.var_uint8_3) : (chamberData.var_uint8_3 > 4 ? (((chamberData.var_uint8_3 - 5) * 4) + 5 + miner.classId) : chamberData.var_uint8_3)) + (17 * chamberData.var_uint8_2);

                    // Define array for gearItem stats
                    int16[6] memory gearItem;

                    // Check which gear type and add values appropriately
                    if(chamberData.var_uint8_2 == 0){
                        // Get headgear stats
                        gearItem = headgearStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        if(chamberData.var_uint8_4 > miner.headgearId){
                            miner.headgearId = chamberData.var_uint8_4;
                        }
                    } else if(chamberData.var_uint8_2 == 1){
                        // Get armor stats
                        gearItem = armorStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        if(chamberData.var_uint8_4 > miner.armorId){
                            miner.armorId = chamberData.var_uint8_4;
                        }
                    } else if(chamberData.var_uint8_2 == 2){
                        // Get pants stats
                        gearItem = pantsStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        if(chamberData.var_uint8_4 > miner.pantsId){
                            miner.pantsId = chamberData.var_uint8_4;
                        }
                    } else if(chamberData.var_uint8_2 == 3){
                        // Get footwear stats
                        gearItem = footwearStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        if(chamberData.var_uint8_4 > miner.footwearId){
                            miner.footwearId = chamberData.var_uint8_4;
                        }
                    } else {
                        // Get weapon stats
                        gearItem = weaponStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        if(chamberData.var_uint8_4 > miner.weaponId){
                            miner.weaponId = chamberData.var_uint8_4;
                        }
                    }
                    // Add gear health buff to baseHealth
                    miner.baseHealth = miner.baseHealth + gearItem[0];
                    // Add gear health buff to health
                    miner.health = miner.health + gearItem[0];
                    // Add gear armor buff to baseArmor
                    miner.baseArmor = miner.baseArmor + gearItem[1];
                    // Add gear armor buff to armor
                    miner.armor = miner.armor + gearItem[1];
                    // Add gear attack buff to attack
                    miner.attack = miner.attack + gearItem[2];
                    // Add gear speed buff to speed
                    miner.speed = miner.speed + gearItem[3];
                }

            } else if(chamberData.var_uint8_1 == 14){ // TREASURE

                // Add found gold to gold
                miner.gold = miner.gold + uint16(uint8(hash[8]) % 48) + 28;

                // Gear type (0 == headgear, 1 == armor, 2 == pants, 3 == footwear, 4 == weapon)
                chamberData.var_uint8_2 = uint8(hash[13]) % 5;

                // Gear rarity
                // Modulo of 32, add 224 to the hash val to get a value between 224-255 (rarity tiers start at rare)
                chamberData.var_uint8_3 = gType((uint8(hash[16 + chamberData.var_uint8_2]) % 32) + 224);

                // Determine Gear ID
                chamberData.var_uint8_4 = (chamberData.var_uint8_2 < 4 ? (chamberData.var_uint8_3 > 8 ? (((chamberData.var_uint8_3 - 9) * 4) + 9 + miner.classId) : chamberData.var_uint8_3) : (((chamberData.var_uint8_3 - 5) * 4) + 5 + miner.classId)) + (17 * chamberData.var_uint8_2);

                // Define array for gearItem stats
                int16[6] memory gearItem;

                // Check which gear type and add values appropriately
                if(chamberData.var_uint8_2 == 0){
                    // Get headgear stats
                    gearItem = headgearStats(chamberData.var_uint8_4);
                    // If gearId is higher than Miner's current gearId, reassign visible gear
                    if(chamberData.var_uint8_4 > miner.headgearId){
                        miner.headgearId = chamberData.var_uint8_4;
                    }
                } else if(chamberData.var_uint8_2 == 1){
                    // Get armor stats
                    gearItem = armorStats(chamberData.var_uint8_4);
                    // If gearId is higher than Miner's current gearId, reassign visible gear
                    if(chamberData.var_uint8_4 > miner.armorId){
                        miner.armorId = chamberData.var_uint8_4;
                    }
                } else if(chamberData.var_uint8_2 == 2){
                    // Get pants stats
                    gearItem = pantsStats(chamberData.var_uint8_4);
                    // If gearId is higher than Miner's current gearId, reassign visible gear
                    if(chamberData.var_uint8_4 > miner.pantsId){
                        miner.pantsId = chamberData.var_uint8_4;
                    }
                } else if(chamberData.var_uint8_2 == 3){
                    // Get footwear stats
                    gearItem = footwearStats(chamberData.var_uint8_4);
                    // If gearId is higher than Miner's current gearId, reassign visible gear
                    if(chamberData.var_uint8_4 > miner.footwearId){
                        miner.footwearId = chamberData.var_uint8_4;
                    }
                } else {
                    // Get weapon stats
                    gearItem = weaponStats(chamberData.var_uint8_4);
                    // If gearId is higher than Miner's current gearId, reassign visible gear
                    if(chamberData.var_uint8_4 > miner.weaponId){
                        miner.weaponId = chamberData.var_uint8_4;
                    }
                }
                // Add gear health buff to baseHealth
                miner.baseHealth = miner.baseHealth + gearItem[0];
                // Add gear health buff to health
                miner.health = miner.health + gearItem[0];
                // Add gear armor buff to baseArmor
                miner.baseArmor = miner.baseArmor + gearItem[1];
                // Add gear armor buff to armor
                miner.armor = miner.armor + gearItem[1];
                // Add gear attack buff to attack
                miner.attack = miner.attack + gearItem[2];
                // Add gear speed buff to speed
                miner.speed = miner.speed + gearItem[3];
            } else if(chamberData.var_uint8_1 == 15){ // HEAL

                // Restore health by 1/2 baseHealth
                miner.health = miner.health + (miner.baseHealth / 2);
                // Check if health is greater than baseHealth
                if(miner.health > miner.baseHealth){
                    // Miner is way too healthy, set health to baseHealth
                    miner.health = miner.baseHealth;
                }

                // Restore armor by 1/2 baseArmor
                miner.armor = miner.armor + (miner.baseArmor / 2);

                // Check if armor is greater than baseArmor
                if(miner.armor > miner.baseArmor){
                    // Miner is way too tanky, set armor to baseArmor
                    miner.armor = miner.baseArmor;
                }
            } else if(chamberData.var_uint8_1 == 16){ // REVIVE
                // Add revive to inventory
                miner.revives++;

            } else if(chamberData.var_uint8_1 == 17){ // ARMORY
                // Oh baby, this Miner is about to get BROLIC

                // Loop through gear types to add all to gear stats
                for(chamberData.var_uint8_2 = 0; chamberData.var_uint8_2 < 5; chamberData.var_uint8_2++){

                    // Gear rarity
                    // 3/4 chance of epic, 1/4 chance of legendary
                    chamberData.var_uint8_3 = (uint8(hash[16 + chamberData.var_uint8_2]) % 4) < 3 ? 9 : 10;

                    // Determine Gear ID
                    chamberData.var_uint8_4 = (chamberData.var_uint8_2 < 4 ? (((chamberData.var_uint8_3 - 9) * 4) + 9 + miner.classId) : (((chamberData.var_uint8_3 - 5) * 4) + 5 + miner.classId)) + (17 * chamberData.var_uint8_2);

                    // Define array for gearItem stats
                    int16[6] memory gearItem;

                    // Check which gear type and add values appropriately
                    if(chamberData.var_uint8_2 == 0){
                        // Get headgear stats
                        gearItem = headgearStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        if(chamberData.var_uint8_4 > miner.headgearId){
                            miner.headgearId = chamberData.var_uint8_4;
                        }
                    } else if(chamberData.var_uint8_2 == 1){
                        // Get armor stats
                        gearItem = armorStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        if(chamberData.var_uint8_4 > miner.armorId){
                            miner.armorId = chamberData.var_uint8_4;
                        }
                    } else if(chamberData.var_uint8_2 == 2){
                        // Get pants stats
                        gearItem = pantsStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        if(chamberData.var_uint8_4 > miner.pantsId){
                            miner.pantsId = chamberData.var_uint8_4;
                        }
                    } else if(chamberData.var_uint8_2 == 3){
                        // Get footwear stats
                        gearItem = footwearStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        if(chamberData.var_uint8_4 > miner.footwearId){
                            miner.footwearId = chamberData.var_uint8_4;
                        }
                    } else {
                        // Get weapon stats
                        gearItem = weaponStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        if(chamberData.var_uint8_4 > miner.weaponId){
                            miner.weaponId = chamberData.var_uint8_4;
                        }
                    }
                    // Add gear health buff to baseHealth
                    miner.baseHealth = miner.baseHealth + gearItem[0];
                    // Add gear armor buff to baseArmor
                    miner.baseArmor = miner.baseArmor + gearItem[1];
                    // Add gear attack buff to attack
                    miner.attack = miner.attack + gearItem[2];
                    // Add gear speed buff to speed
                    miner.speed = miner.speed + gearItem[3];
                }
                // Set current Miner health to base health
                miner.health = miner.baseHealth;
                // Set current Miner armor to base armor
                miner.armor = miner.baseArmor;
            }
        }

        // Post-encounter calculations

        // If the Miner has at least one buff turn remaining, remove a buff turn
        if(miner.buffTurns > 0){
            miner.buffTurns--;
        }
        // If the Miner has at least one debuff turn remaining, remove a debuff turn
        if(miner.debuffTurns > 0){
            miner.debuffTurns--;
        }
        // Return the Miner
        return miner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library LgSVG {

    /**
    * @notice render an eyes asset
    * @param lgAssetId the large asset id of the eyes item
    * @return string of svg
    */
    function _eyes(uint256 lgAssetId)
        internal
        pure
        returns (string memory)
    {
        string[8] memory EYES = [
            // 0 normal male
            '%253Cpath d=\'M29,29h3v1h-3zM38,29h3v1h-3z\' fill=\'var(--dme)\'/%253E%253Cpath d=\'M30,29zh1v1h-1zM39,29h1v1h-1z\' fill=\'var(--dmi)\'/%253E%253Cpath d=\'M28,24h6v1h1v2h-9v-1h1v-1h1zM38,24h4v3h-5v-2h1z\' fill=\'var(--dmh)\'/%253E%253Cpath d=\'M28,24h6v1h-3v1h2v-1h2v2h-1v1h1v1h-1v1h-2v-1h-3v1h-1v-1h-2v-1h1v-1h-1v-1h1v-1h1zM38,24h4v1h-3v1h2v-1h1v5h-1v-1h-3v1h-1v-2h1v-1h-1v-2h1z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M28,24h6v1h-6v1h6v-1h1v2h-9v-1h1v-1h1zM38,24h4v1h-4v1h4v1h-5v-2h1zM29,28h3v1h1v1h-1v-1h-3v1h-1v-1h1zM38,28h3v1h1v1h-1v-1h-3v1h-1v-1h1z\' fill=\'var(--dmb5)\'/%253E',
            // 1 angry male
            '%253Cpath d=\'M29,29h3v1h-3zM38,29h3v1h-3z\' fill=\'var(--dme)\'/%253E%253Cpath d=\'M30,29zh1v1h-1zM39,29h1v1h-1z\' fill=\'var(--dmi)\'/%253E%253Cpath d=\'M28,24h3v1h3v1h1v2h-4v-1h-5v-1h1v-1h1zM40,24h2v3h-2v1h-3v-2h1v-1h2z\' fill=\'var(--dmh)\'/%253E%253Cpath d=\'M28,24h3v1h3v1h-3v1h2v-1h2v3h-1v1h-1v-1h-3v1h-1v-1h-2v-1h1v-1h-2v-1h1v-1h1zM40,24h2v6h-1v-1h-3v1h-1v-4h1v-1h2v1h-1v1h1v-1h1v-1h-1v-1h1z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M28,24h3v1h3v1h1v2h-3v1h1v1h-1v-1h-3v1h-1v-1h1v-1h2v-1h-5v-1h1v-1h1v1h3v1h3v-1h-3v-1h-3zM40,24h2v1h-2v1h-2v1h2v-1h2v1h-2v1h1v1h1v1h-1v-1h-3v1h-1v-1h1v-1h-1v-2h1v-1h2z\' fill=\'var(--dmb5)\'/%253E',
            // 2 sad male
            '%253Cpath d=\'M29,29h3v1h-3zM38,29h3v1h-3z\' fill=\'var(--dme)\'/%253E%253Cpath d=\'M30,29zh1v1h-1zM39,29h1v1h-1z\' fill=\'var(--dmi)\'/%253E%253Cpath d=\'M31,24h3v1h1v2h-4v1h-5v-1h1v-1h1v-1h3zM38,24h2v1h2v3h-2v-1h-3v-2h1z\' fill=\'var(--dmh)\'/%253E%253Cpath d=\'M31,24h3v1h1v2h-1v1h1v1h-1v1h-2v-1h-3v1h-1v-1h-2v-2h1v-1h1v-1h3v1h2v-1h-2zM38,24h2v1h-1v1h1v1h1v-1h-1v-1h1v-1h1v6h-1v-1h-3v1h-1v-2h1v-1h-1v-2h1z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M31,24h3v1h1v2h-4v1h1v1h1v1h-1v-1h-3v1h-1v-1h1v-1h-3v-1h1v-1h1v-1h3v1h-3v1h3v-1h3v-1h-3zM38,24h2v1h2v1h-2v1h2v1h-1v1h1v1h-1v-1h-3v1h-1v-1h1v-1h2v-1h-3v-2h1v1h2v-1h-2z\' fill=\'var(--dmb5)\'/%253E',
            // 3 surprised male
            '%253Cpath d=\'M29,28h3v2h-3zM38,28h3v2h-3z\' fill=\'var(--dme)\'/%253E%253Cpath d=\'M30,29zh1v1h-1zM39,29h1v1h-1z\' fill=\'var(--dmi)\'/%253E%253Cpath d=\'M28,24h6v1h1v2h-9v-1h1v-1h1zM38,24h4v3h-5v-2h1z\' fill=\'var(--dmh)\'/%253E%253Cpath d=\'M28,24h6v1h-3v1h2v-1h2v2h-1v1h1v1h-1v1h-2v1h-3v-1h3v-1h-3v1h-1v-1h-2v-1h1v-1h-1v-1h1v-1h1zM38,24h4v1h-3v1h2v-1h1v5h-1v-1h-3v1h3v1h-3v-1h-1v-2h1v-1h-1v-2h1z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M28,24h6v1h-6v1h6v-1h1v2h-3v1h-3v-1h-3v-1h1v-1h1zM38,24h4v1h-4v1h4v1h-1v1h-3v-1h-1v-2h1zM28,29h1v1h-1zM32,29h1v1h-1zM37,29h1v1h-1zM41,29h1v1h-1z\' fill=\'var(--dmb5)\'/%253E',
            // 4 normal female
            '%253Cpath d=\'M29,29h3v1h-3zM38,29h3v1h-3z\' fill=\'var(--dme)\'/%253E%253Cpath d=\'M30,29zh1v1h-1zM39,29h1v1h-1z\' fill=\'var(--dmi)\'/%253E%253Cpath d=\'M29,25h4v1h1v1h-6v-1h1zM38,25h3v1h1v1h-5v-1h1z\' fill=\'var(--dmh)\'/%253E%253Cpath d=\'M28,25h3v1h2v-1h1v1h1v1h-1v1h1v2h-3v-1h-3v1h-2v-1h-1v-1h1v-2h1zM37,25h2v1h2v-1h1v5h-1v-1h-3v1h-2v-1h1v-1h1v-1h-1z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M27,26h8v1h-8zM37,26h5v1h-5zM29,28h5v1h-1v1h-1v-1h-3v1h-1v-1h1zM38,28h4v2h-1v-1h-3v1h-1v-1h1z\' fill=\'var(--dmb5)\'/%253E',
            // 5 angry female
            '%253Cpath d=\'M29,29h3v1h-3zM38,29h3v1h-3z\' fill=\'var(--dme)\'/%253E%253Cpath d=\'M30,29zh1v1h-1zM39,29h1v1h-1z\' fill=\'var(--dmi)\'/%253E%253Cpath d=\'M29,25h2v1h2v1h1v1h-3v-1h-3v-1h1zM40,25h1v1h1v1h-2v1h-3v-1h1v-1h2z\' fill=\'var(--dmh)\'/%253E%253Cpath d=\'M28,25h4v1h3v1h-1v1h1v2h-3v-1h-3v1h-2v-1h-1v-1h1v-2h1zM39,25h1v1h1v-1h1v5h-1v-1h-3v1h-2v-1h1v-1h1v-1h-1v-1h2z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M27,26h4v1h4v1h-1v1h-1v1h-1v-1h-3v1h-1v-1h1v-1h2v-1h-4zM40,26h2v1h-2v1h2v2h-1v-1h-3v1h-1v-1h1v-1h-1v-1h3z\' fill=\'var(--dmb5)\'/%253E',
            // 6 sad female
            '%253Cpath d=\'M29,29h3v1h-3zM38,29h3v1h-3z\' fill=\'var(--dme)\'/%253E%253Cpath d=\'M30,29zh1v1h-1zM39,29h1v1h-1z\' fill=\'var(--dmi)\'/%253E%253Cpath d=\'M31,25h2v1h1v1h-3v1h-3v-1h1v-1h2zM38,25h2v1h1v1h1v1h-2v-1h-3v-1h1z\' fill=\'var(--dmh)\'/%253E%253Cpath d=\'M28,25h3v1h2v-1h1v1h1v1h-1v1h1v2h-3v-1h-3v1h-2v-1h-1v-1h1v-2h1zM37,25h2v1h2v-1h1v5h-1v-1h-3v1h-2v-1h1v-1h1v-1h-1z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M31,26h4v1h-3v1h2v1h-1v1h-1v-1h-3v1h-1v-1h1v-1h-2v-1h4zM37,26h3v1h2v3h-1v-1h-3v1h-1v-1h1v-1h1v-1h-2z\' fill=\'var(--dmb5)\'/%253E',
            // 7 surprised female
            '%253Cpath d=\'M29,28h3v2h-3zM38,28h3v2h-3z\' fill=\'var(--dme)\'/%253E%253Cpath d=\'M30,29zh1v1h-1zM39,29h1v1h-1z\' fill=\'var(--dmi)\'/%253E%253Cpath d=\'M29,24h4v1h1v1h-6v-1h1zM38,24h3v1h1v1h-5v-1h1z\' fill=\'var(--dmh)\'/%253E%253Cpath d=\'M28,24h3v1h2v-1h1v1h1v1h-1v1h1v3h-3v-1h-3v1h-2v-1h-1v-2h1v-2h1zM37,24h2v1h2v-1h1v6h-1v-1h-3v1h-2v-1h1v-2h1v-1h-1z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M27,25h8v1h-8zM37,25h5v1h-5zM29,27h5v1h-1v2h-1v-2h-3v2h-1v-2h1zM38,27h4v3h-1v-2h-3v2h-1v-2h1z\' fill=\'var(--dmb5)\'/%253E'
        ];
        return EYES[lgAssetId];
    }

    /**
    * @notice render a mouth asset
    * @param lgAssetId the large asset id of the mouth item
    * @return string of svg
    */
    function _mouth(uint256 lgAssetId)
        internal
        pure
        returns (string memory)
    {
        string[16] memory MOUTHS = [
            // 0 toothy smile male
            '%253Cpath d=\'M33,40h5v1h-5z\' fill=\'white\'/%253E%253Cpath d=\'M32,40h2v1h-2zM38,41h1v1h-1z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M32,40h1v1h5v-1h1v1h-1v1h-5v-1h-1z\' fill=\'var(--dmb35)\'/%253E',
            // 1 small smile male
            '%253Cpath d=\'M34,40h3v1h-3z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M32,39h1v1h5v1h-5v-1h-1zM35,42h2v1h-2z\' fill=\'var(--dmb35)\'/%253E',
            // 2 large smile male
            '%253Cpath d=\'M33,40h5v1h-5z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M31,39h1v1h7v-1h1v1h-1v1h-7v-1h-1zM35,42h2v1h-2z\' fill=\'var(--dmb35)\'/%253E',
            // 3 frown male
            '%253Cpath d=\'M34,40h4v1h-4z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M33,40h6v1h1v1h-1v-1h-6v1h-1v-1h1zM35,42h2v1h-2z\' fill=\'var(--dmb35)\'/%253E',
            // 4 stoic male
            '%253Cpath d=\'M34,40h4v1h-4z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M33,40h6v1h-6zM35,42h3v1h-3z\' fill=\'var(--dmb35)\'/%253E',
            // 5 sewn male
            '%253Cpath d=\'M31,38h1v1h-1zM36,39h1v1h1v-1h1v2h-1v1h-3v-1h-1v-1h2zM32,40h1v2h-1zM37,43h1v1h-1z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M32,39h1v1h2v-1h1v1h1v-1h1v1h2v1h-1v1h-1v-1h-1v2h-1v-2h-1v1h-1v-1h-3v-1h1z\' fill=\'var(--dmb35)\'/%253E',
            // 6 small smile fangs male
            '%253Cpath d=\'M34,41h1v2h-1zM38,41h1v2h-1z\' fill=\'white\'/%253E%253Cpath d=\'M32,40h1v1h1v-1h4v1h1v1h-6v-1h-1z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M32,39h1v1h6v1h-6v-1h-1z\' fill=\'var(--dmb35)\'/%253E',
            // 7 stoic fangs male
            '%253Cpath d=\'M34,41h1v2h-1zM38,41h1v2h-1z\' fill=\'white\'/%253E%253Cpath d=\'M34,40h4v1h1v1h-6v-1h1z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M33,40h6v1h-6z\' fill=\'var(--dmb35)\'/%253E',
            // 8 toothy smile female
            '%253Cpath d=\'M32,40h5v1h-5z\' fill=\'white\'/%253E%253Cpath d=\'M31,40h2v1h-2z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M31,40h1v1h5v-1h1v1h-1v1h-5v-1h-1z\' fill=\'var(--dmb35)\'/%253E',
            // 9 small smile female
            '%253Cpath d=\'M33,41h3v1h-3z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M31,40h1v1h5v1h-5v-1h-1z\' fill=\'var(--dmb35)\'/%253E',
            // 10 large smile female
            '%253Cpath d=\'M32,41h5v1h-5z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M30,40h1v1h7v-1h1v1h-1v1h-7v-1h-1z\' fill=\'var(--dmb35)\'/%253E',
            // 11 frown female
            '%253Cpath d=\'M33,40h3v1h-3z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M32,40h4v1h1v1h-1v-1h-4v1h-1v-1h1z\' fill=\'var(--dmb35)\'/%253E',
            // 12 stoic female
            '%253Cpath d=\'M32,41h4v1h-4z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M31,41h6v1h-6z\' fill=\'var(--dmb35)\'/%253E',
            // 13 sewn female
            '%253Cpath d=\'M30,38h1v1h-1zM35,39h1v1h1v-1h1v2h-1v1h-3v-1h-1v-1h2zM31,40h1v2h-1zM36,43h1v1h-1z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M31,39h1v1h2v-1h1v1h1v-1h1v1h2v1h-1v1h-1v-1h-1v2h-1v-2h-1v1h-1v-1h-3v-1h1z\' fill=\'var(--dmb35)\'/%253E',
            // 14 small smile fangs female
            '%253Cpath d=\'M32,42h1v2h-1zM36,42h1v2h-1z\' fill=\'white\'/%253E%253Cpath d=\'M30,41h1v1h1v-1h4v1h1v1h-6v-1h-1z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M30,40h1v1h6v1h-6v-1h-1z\' fill=\'var(--dmb35)\'/%253E',
            // 15 stoic fangs female
            '%253Cpath d=\'M32,42h1v2h-1zM36,42h1v2h-1z\' fill=\'white\'/%253E%253Cpath d=\'M32,41h4v1h1v1h-6v-1h1z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M31,41h6v1h-6z\' fill=\'var(--dmb35)\'/%253E'
        ];
        return MOUTHS[lgAssetId];
    }

    /**
    * @notice render the miner base
    * @param classId class id (0 == warrior, 1 == mage, 2 == ranger, 3 == assassin)
    * @param genderId gender id (0 == male, 2 == female)
    * @return string of svg
    */
    function renderBase(uint256 genderId, uint256 classId, uint256 eyesId, uint256 mouthId)
        external
        pure
        returns (string memory)
    {
        string[2] memory MINERS = [
            // 0 base male
            '%253Cpath d=\'M0,57v-5h1v-1h2v-1h2v-1h4v-1h3v-1h2v-1h2v-1h2v-1h1v-7h-1v-1h-1v-1h-1v-1h-1v-13h1v-3h1v-1h1v-1h1v-1h1v-1h2v-1h1v-1h3v-1h7v1h3v1h2v1h1v1h1v1h1v2h1v3h1v17h-1v5h-1v3h-1v1h-1v1h2v1h2v1h4v1h2v1h4v1h2v1h1v1h1v2z\' fill=\'var(--dms)\'/%253E%253Cimage href=\'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAApNJREFUeNrsm12OwiAQx0vjRfaF03gVXjyBJ9gXrtLT8LJHca0BM5JhGGCgVtukibak8uM/zFejut1u06cf8/QFxwF5QB6QB+QBeUAekF8OqQb+liXumT1D2gpIsycrWaG0PzlHGGszC/I2cLYALgVsP0W93YFCQC30TBHQWdhEw+GEnus+WUFRNU89qENLRSnFHovGNyUT4bpAhsmtAKmJjoDrZao6B7JeKzklTFZaSYdBQWUolSjl3zZBz004Uosa495uT5Y6maAg3MuSx2n0JqYcEdest4I0qQoiVoerUjxuS49rC8qpnvVod8djSjKd0hAisT9nQXPV3II3OJlggv7zBbn2OFtBJRP0HKDG9hb4vtzPS2bM5kq+wCCAuVjnMs/YFJJjpo65X3+5+e0WSurSJBx7BjDLs6Sas4CZmsj5nDvVlNspeVfLIGGktIDWkXqr2Z7vyooU4pJpxOph/7yXhIvgMt4xAC7IPXj9sZg1lYpk7mqwrMSrQTkg50EwM1/8/SY1RybojmiTOERJB+6bqaGzPhLyGSsTPSCHeePIEqoSg+FvtTDAVI7qU7rmtuRoSA0m/zxhnorktXpvkI9JQzUxRaU7A70hzylQAKfjFkh07xk6ahdhFtxn2Cu3hYCFgV4jDkUsrZPwrtZPkKpEYBxcClI3kRSxJeOxqb4OMD/OxBfC1H+CqXIbYlKQL3CpNAs4F12zbwPgSCVtokAmX+5EC1CzxwxlLa2Qlqj8yZoxhkWU5sI67tYohUw+jOu2GZA5h+OYFsWGVtyVaoGUaEZR0L6mTc5FTbxOWzUkU83WxbBxIf/yyqE0sa6BpBLzltBQG95IyJZuN2dsh382XDdXctDevapv+F/IvwADAGp6okFeqr7oAAAAAElFTkSuQmCC\'/%253E',
            // 1 base female
            '%253Cpath d=\'M0,57v-5h1v-1h2v-1h2v-1h4v-1h3v-1h2v-1h3v-1h2v-8h-1v-1h-1v-1h-1v-1h-1v-13h1v-3h1v-1h1v-1h1v-1h1v-1h2v-1h1v-1h3v-1h7v1h3v1h2v1h1v1h1v1h1v2h1v3h1v17h-1v2h-1v1h-1v2h-1v2h-1v1h-1v2h4v1h2v1h4v1h2v1h4v1h2v1h1v1h1v2z\' fill=\'var(--dms)\'/%253E%253Cimage href=\'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAodJREFUeNrsm+1twyAQho2VRfqHBbJGFugQ7JAdGCILeI0uwDKuqUC6UA4OOIidGMlSZdOYh/c+iSLWdZ3efczTB4wT8oQ8IU/IE/KEPCE/HFIMfJdOPFNHhtQVkOpIVmKhpLsow8/VmQ3ZDZwugMOA9buodzhQCCiZPpMFdGY2UT8M0+ead1aQVc1LD2p/pCKEIM+N5jfBk+G6QPrFWQBsoSPgepmqzIHYeyUXh8lyK2liUFCZlEop5XdboOcWHKiVmmN255OlQcYrCH2Zc1xGO3EqEFHN+lWQCusgQnWoKoXzXhlxdUE71bMf7R54VEmlU5pCOPxzZjRXSW14fZDxJhjzRTinFZSzQFc1pV4KlMsfZ+bAM8VMt1eSHwmZNVMq4DZPQtPkypdcSsrSIhwZ1z0qqYIcaWFvNb0l8FlJ3cRhSm6LU1gaQRacUvxh1eQu65ohnb95UKviUqICrFsd3GP7+7umyR5Ru6pEVSKx8xq3Sfb5FQSon+DZsQp0xA9NphdVU8PJes9+8oaZrS/XYNVDNcuafNsTcomARisfrF51getPxZZgNPqrO+kBIRCsU8ElW810FGRWTUxRDjMdqeQTqFUo5ouBok8qtrZfLJCRFxsE9Iblzp4FvOAA3BaoQctlwH2JRN0lsSH/VIz1lCWb0gKpYWnngEwkx8lEelky9TCaTnpDauzQKpMqJCGX2vHl6mE2ExalqpWE9EizTCnRFPFeM6SmviTnKzWg9sQ8+B/dAiuopkgN2wRIDNQUWhQZWlB3qgWyY4rQoKdF1yIoJ20tkNSDrMbN0GEj/3T6V9oW1UCmCvNORUGdD7eedlPmdvhlw/3lSg7y3bv4hN+F/AowAGIWzHdTKpamAAAAAElFTkSuQmCC\'/%253E'
        ];

        return string(abi.encodePacked(
            (genderId == 0 && classId == 1 ? '%253Cdefs%253E%253Cmask id=\'mhm\'%253E%253Cpath d=\'M0,0h57v57h-57z\' fill=\'white\'/%253E%253Cpath d=\'M31,37h10v19h-10z\' fill=\'black\'/%253E%253C/mask%253E%253C/defs%253E' : ''),
            MINERS[genderId],
            _eyes((genderId * 4) + eyesId),
            _mouth((genderId * 8) + mouthId)
        ));
    }

    /**
    * @notice render the miner mods
    * @param modId class id (0-3 male, 4-7 female)
    * @return string of svg
    */
    function renderMod(uint256 modId)
        external
        pure
        returns (string memory)
    {
        string[8] memory CLASS_MODS = [
            // 0 warrior male
            '',
            // 1 mage male
            '%253Cpath d=\'M20,33h1v1h1v1h2v1h1v1h2v1h2v1h2v-1h9v1h1v-1h1v-1h1v7h-1v4h-1v2h-1v2h-1v2h-1v1h-1v1h-2v-1h-2v-1h-2v-1h-1v-1h-1v-2h-1v-1h-2v-1h-2v-1h-1v-1h-1v-1h-1v-1h-1v-1h-1v-7h1z\' fill=\'var(--dmh)\'/%253E%253Cimage href=\'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAdJJREFUeNrsm0GOgyAYhaWZ03gEViacwj3XmNVcw72nIJlVjzDX6UDy0/zzQm0TsTDtIyHWSg2f7/GgRs3lchlevZyGNyiEJCQhCUlIQhKSkIQkJCEJSUhCEpKQhCQkIQlJSEISkpCEJCQhXxPSGPMV6xTrWyjZDeiRkN+ibHPYU2WrznETCrBNQWsr6fWOeuhit6rxd6EnuzoFNcPTJX9gU8dF/aIr5Pi0u0epE7WqWHXKli0c1yUUjk9SB7UNt9o/Wj8OUjKVpNAqal63ynpOVErtLZzjUyu/txwBmTp8VkHkkzURNF3huJ8Blxvje1YXrCvIs1LmRwA8Bk5aNCjAVadyvABJ5QTp5XNXkE46i6CYA06l5Srj0ZXa5TaY3D2k69WysYxbY3fj2b4F5l7XDaRSxYKFvep0brfAQkKfZ/0Py7pSag5bUPq7PZP/oZDZesqCGdRq6+bURTBU+47d2ysJoE5NL7nTS1arkJ46Ve2e8Xj4n2YIFaeUHVW4eEjdqiq2ujOAoDgeq6r4FEhct4K644Ztxw1X9KkkwJaSd4Rgsg/Mpf3eyIK51MvYtCUVa7wIYFq9TQBr2VAIIlcL1LR8ZaJwlyDUBmwO+azyK8AAkbk+yZJBIeYAAAAASUVORK5CYII=\'/%253E',
            // 2 ranger male
            '%253Cpath d=\'M34,29h2v2h2v2h1v2h1v3h-2v1h-5v-1h-2v-3h1v-2h1v-1h1z\' fill=\'var(--dms)\'/%253E%253Cpath d=\'M36,30h1v2h1v4h1v3h-4v-1h-1v-1h1v1h3v-2h-1v-4h-1z\' fill=\'var(--dmb35)\'/%253E%253Cpath d=\'M36,29h1v1h-1zM37,33h1v2h1v1h-1v-1h-1zM32,36h1v1h1v1h1v1h-1v-1h-1v-1h-1zM37,37h2v1h-1v1h-2v-1h1z\' fill=\'var(--dmb15)\'/%253E',
            // 3 assassin male
            '%253Cimage href=\'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAARhJREFUeNrs2oENgyAQQFFwIkdgJEZxJEfoRjQaSK5U1MqRUP0k5GxSlZc7j5hoQwjm7mMwDxggQYIECRIkSJAgQYIECRIkSJAgQYIECRIkSJAgQYK8H9Jau0wXo9rsNZPuCeU6R6i7I9KJOPeS1aFBBseUyRDCCo0fXyy/za9TZVy58cGCXAIdxbPXrF5XA6TXhF6tADlbNJ5XLNl1O1lKditm287Hsca20bq7jkdQAXTimf2qCvnfqv1b84sskQGfZXa3WW2tQQJTA+sNmUNlGct4qmPXrrElcgu8Bx0L2a9Gqj+ThQVNGaQUmwz1TMrrFTLrz3bp2KhMd+VaaCJ7p/lCRUzpvK6QvDSDBAkSJEiQ/zfeAgwAaFfCwD9utk4AAAAASUVORK5CYII=\'/%253E',
            // 4 warrior female
            '',
            // 5 mage female
            '%253Cstyle%253E:root{--dme:var(--dm31)}%253C/style%253E',
            // 6 ranger female
            '%253Cpath d=\'M34,29h2v2h2v2h1v2h1v3h-2v1h-5v-1h-2v-3h1v-2h1v-1h1z\' fill=\'var(--dms)\'/%253E%253Cpath d=\'M35,30h1v2h1v4h1v3h-4v-1h-1v-1h1v1h3v-2h-1v-4h-1z\' fill=\'var(--dmb35)\'/%253E%253Cpath d=\'M35,29h1v1h-1zM36,33h1v2h1v1h-1v-1h-1zM31,36h1v1h1v1h1v1h-1v-1h-1v-1h-1zM36,37h2v1h-1v1h-2v-1h1z\' fill=\'var(--dmb15)\'/%253E',
            // 7 assassin female
            '%253Cpath d=\'M27,29h1v1h-1v1h1v1h-1v-1h-2v1h-2v-1h2v-1h2zM32,30h1v1h1v1h-1v-1h-1zM41,31h1v1h-1v1h-1v1h-1v-1h1v-1h1zM23,35h1v1h1v1h2v-1h1v1h-1v1h1v1h1v1h1v1h-1v-1h-1v-1h-1v-1h-2v1h-1v-1h1v-1h-1v-1h-1zM35,44h1v1h-1v1h-2v1h-1v-1h1v-1h2z\' fill=\'var(--dmb2)\'/%253E'
        ];
        return CLASS_MODS[modId];
    }

    /**
    * @notice return a background image
    * @param bgType background type
    * @return string of base64-encoded image
    */
    function _background(uint256 bgType)
        internal
        pure
        returns (string memory)
    {
        string[3] memory backgrounds = [
            // 0 Dungeon
            'R0lGODlhOQA5AJEAABsbGwcHBxAQEAAAACH5BAAAAAAALAAAAAA5ADkAAAL/VCIAhid/onSqsrScg1OaB34b01HV8oUiwpUNB12wFSVqujXsRWtwGkKcMjsPK3cTni6jmiqgeB6dzREIirq6nJzsdNdyBaHX8Hai1Z3XVTVriPKQfun3MNzKw5fU4o23F9VX9hciOEX4VAhySFckpmBFCPbVgSEZU8clozgHVDL2B0Yy6hnkOIa5mbmomSrV6poWS8om12qbC0mku4YRyKtE9Dv8AEz6C5hl2HhHdtraQ5yxXFj8FMcazRkUB6olCu5mCZ6kuYmJ43MWal6rWqr+8l6ajri4mlmTnmRv5ttuXy9JOQaimWNQDAM4phTGqLGn4TdjDEdxqbcjosUD7oJo1YPWDl+SKEDMaEtAqV8qJNgS1SpDBWS5lw9ZngwX0yUykTm1bfFU8FEuoF9CMhHqMFSjNqA+MiXn7tRTNPd0gOsRT13Nq4fm2SzjDKnWkjHCcsqHBdbONiOrsRnjJc/KiQsnDZyVEKrADQzXFpTCDw9RYRr/3uRWaNBhFY3OhqMlo8k5iAD8lax0ELFPqJrlsaJruU6/j45FA44aK7MpOrhurU6c0GPeoZNnY2hNECNk18pSxyO9+3c1fL8nQWZ9xRvn0Ot+zgSZ1PI+euiK01Ppbvp1tZ0Cv9anIevp7LrU7u1lfnZR9XIOFAAAOw==',
            // 1 Village
            'R0lGODlhOQA5AMQAAEw0NF5lj5WAdmBPZXpwYC1qRSopQFRTYjw8TklIVyEgMGZMSR1KQTs2Q1tKU0Y/Sx1ZSVc+OYRnXjl2Tx1uUwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAAAAAAALAAAAAA5ADkAAAX/YCCOoyQIZoqa6OK6URy9s2zLQG7nAFlKwBTwxALOFjUb7QbD6QARni8QLA5VwdgSKeMyvVEeNDcVVlfEk6DWTN7eO7GUdF6d72C4/i0n/4J2VYISe4V6fT1/g4tVho5xYoqMRHVvLY98kVSMgIGdNi1tmDFjPZynZzJBL6KPT6iwJqoSrEt7eWOxpwJcQLWsbw7Cww/FDVERBYLKuidIvqzQbg4DA8LW1APFDw0AEIIQzLC8LrTR0F7D6uvbDeFBBRDfuuXVDg/lSKzY2evq2/GYhZtXRdyZBRLYPUiCBJu9YQ/5FRtYoKI8ZeLeCVrw8Nq9Bsdi+LvGzyM2BuFQ/waEsIDlgngEfakr+TGkgZs4c+rUyaAng3gqC/zsGa+WR3/2QC4AybSp06c+IfiMKk/qzwU+d2q9GYFbA2HbHoD1ys2YVKtoq6pN20AsyJpMvUYAGVasgrsK2jWdurYqhbU9IbQNe1cvSAaDtznAizcs08Dy/kamQLkyZXkMxG5jDPaxZsKM894j2xeC5dOWEyR+wNhxAwSr7YZ27U7yZAoTTuemcCCBatCFi338LXZ06LzCvU7OvRv1gd6+YY9trRd2XdazDaPGzfu5b9/PEYinW0zBTdHtrI9dnH00SNy5n8uHnqC3eASQIZu2bbUneeF35VTXWw/I9x109+m3n/9aFBBAAH9VZZbYYjoVZ8xXoyVwn3gK+rXdBAQ0N4FafN0m2VQ9SYQfSqVtxx1lE8T4Yl+olYZZRxN5qJuML1YGooiX7QdfkDZCNBZqzblo2Y9Jwuegj9tVNZM1xujm4nwHiAffbjHyCOOSYFKjEDdfWjbffd/5tmWXMfb2nJLcTUDSP1VShiUC0YGHJgJrtgnefM55N5OY7jUgH55ppomAd1qyOYF3WSKqYXfegdfRnBeGhyeimm6IgDyO2qdonon6ttVOenqqKn6gsknBpvXZt+F8Gj711HcJshhhiRDEGOJuulIlVaz3XThYUw9Et+JpNvbqaI0m6sfAXU951QDCVWXC2eWvPcKpVmNxxcWikl7CuG2XO8JJQWPCIaujlTv6iq6627HbjnJC0uuoq/SCaW+7IL3r4r7PktskZf8aw824XCZJ8K/zbtmvAcGNxRSDSO7roIOuHjxwbuddd9ha5hLs68b8krsdTmF9pGtkJrOJMscR90sZy2Hpt6SjKMtMcLzw3nyTMFF9fDLEMddsM4ooaXt00kwqTS/GTpsMZczZImlZvupanTHWPpZrc7xif3hyymPr63HZW/bscboUhAAAOw==',
            // 2 Escaped
            'R0lGODlhOQA5AMQAAB1BO3h3hTs2QyEgMHpwYGFgblRTYkdHWZqGNjw8Tkw0NCwsWWZMSVc+OZyUKjl2T4uKmCopQB1KQS1qRV5lj1JahB1ZSVhgih1uUwAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAAAAAAALAAAAAA5ADkAAAX/YCWOZGmeaKquULu+cDwGreu+d4w4DgIHtJpQJaytdrykbwUMNgMqYO2JQiaVsmylBVxdvw6t6UIum89kkxXcU6Hf8PiZ/S3J7/g3/TrK+/9rYAh/hH97DoV+NXmBSmeLiWUthI2DkkUBkXAQmXJIlmYMRZwXk5qnoaKjkHcUrq8UqGQQDQ2qC0JAZ7C8vb69aKO1DBHFuE0Qv8rLy6u0w8URC77TzNbKXAEUnAHDDMTG1a7SuELb2tfprxHettEL09Hko+i84uv3y8W1tt/g8PLILZBirBe5de+sGWugoF8/gRPewVsQkCIFaQkvRphAEZ4vaRqlMfTmj5wFYwI7/6oMtxHgRgscJ1KYMA7lOwUNHfpbMAEmRnIRpcUMyhMmxQgSevKceBIlz2IccfL79hCmBXgRi0ZU2jOrVZ49JSS9qjVcV6VS2/mTYCFp141dLVjt+VJsz7ltObZtCs9q3rQkGdgaO/auXL8TCs9lK/ar3a2JYY7FmVNnv72PYYadELdx26RuxRamK9ezWMpTvykQ/G30Xs6bI4OOnHg0W82SE8NGnZOq6m95cecdO9y15NucFXe2QLmhv1qrGUTXLTduWLxW2dKmfn2zZtQMBogXPIwhg7CKP3NHzxlve7va4zLHGV78+H6CG55lDDt7dezo4dXYgBNIVZ99luH0Wf9uh3lnWnbxNaZbaD1JZd+FtpSnQGi3wRfgbNstSBuEMNEnD4LkQacAAABoxuKLAHQlwYvVefehaLBJYGJAEeQkFU4CCPBikAJIECSMR7JoAYxMNtkiAFIFlMCUgEFnpGhYilVkkaIFqaWRXG4J5pg7RjDlAQcYYACaaxqQ5WFwvvlZlnTWqWNDxZyZpgEFGJAAmgfAKeighBZq6HwN6clnAYyqKRcGh8IJaaGTVjqpoJQJ9qeajHZagAUYhAppqI8+aulhooIq6qqXomqgdAks2ikBrIr6QK245hrqramqGqpzGcbKKQEEPMCrrsgmm+ut/CTKJgbGRrvqscraWi17q6hJECioBWBQbLHGVkttsuNiuyFbCahqwK4PEBvutfDqeq6k1hoLbrnxxisaqrjaK624rOI77aqe+RpwtAgPnG+1numK8L0CL6xrY+QinLDEuyZ7W8DTPnyxwiDnu7HAD0Mccbz4mupwtMS6+y/GyKq8LMstfwxzriEAADs='
        ];
        return backgrounds[bgType];
    }

    /**
    * @notice return a fill color for the frame
    * @param frameType frame type
    * @return string of css color variable
    */
    function _frame(uint256 frameType)
        internal
        pure
        returns (string memory)
    {
        string[8] memory frames = [
            'black',
            'var(--dm17)',
            'var(--dm26)',
            'var(--dm4)',
            'url(%2523s)',
            'url(%2523g)',
            'url(%2523f)',
            'url(%2523c)'
        ];
        return frames[frameType];
    }

    /**
    * @notice render a double-encoded data URI for the profile SVG
    * @param spawnType chamber type of spawn
    * @param body body of the SVG markup
    * @param bgType the background type of the image
    * @param frameType the frame type of the image
    * @return string of svg as a data uri
    */
    function render(string memory spawnType, string memory body, uint256 bgType, uint256 frameType)
        external
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(
            'data:image/svg+xml,%253Csvg xmlns=\'http://www.w3.org/2000/svg\' width=\'100%\' height=\'100%\' viewBox=\'0 0 57 57\' preserveAspectRatio=\'xMidYMid meet\'%253E%253Cstyle%253E*{shape-rendering:crispedges;image-rendering:-webkit-crisp-edges;image-rendering:-moz-crisp-edges;image-rendering:crisp-edges;image-rendering:pixelated;-ms-interpolation-mode:nearest-neighbor}:root{--dm0:%25237a09fa;--dm1:%252337104f;--dm2:%2523661e92;--dm3:%2523db3ffd;--dm4:%2523630460;--dm5:%2523b0151a;--dm6:%2523ed1c24;--dm7:%2523f01343;--dm8:%2523876776;--dm9:%2523b48a9e;--dm10:%2523f0b8d3;--dm11:%2523f7941d;--dm12:%2523fff200;--dm13:%2523fcd617;--dm14:%2523fbd958;--dm15:%2523fae391;--dm16:%2523005d2e;--dm17:%2523007c3d;--dm18:%2523209e35;--dm19:%252300a651;--dm20:%252339b54a;--dm21:%2523aaff4f;--dm22:%25232d1c50;--dm23:%252309080b;--dm24:%25231b1a2c;--dm25:%25231e205e;--dm26:%25232e3192;--dm27:%25231452cc;--dm28:%25231dc0ed;--dm29:%2523393754;--dm30:%25232a4c69;--dm31:%25231e8492;--dm32:%25238393ca;--dm33:%2523404247;--dm34:%252356585f;--dm35:%25235a5a5a;--dm36:%2523707070;--dm37:%2523898989;--dm38:%2523b7b7b7;--dm39:%2523dddddd;--dm40:%25234f3810;--dm41:%252392671e;--dm42:%2523bbaa6d;--dm43:%25233e3531;--dm44:%2523534741;--dm45:%25237d5e52;--dm46:%252347210e;--dm47:%2523603114;--dm48:%252380421b;--dm49:%2523984f1d;--dm50:%25233e2309;--dm51:%2523522b0c;--dm52:%252376451d;--dm53:%252394623d;--dm54:%2523cf9768;--dm55:%2523efc088;--dm56:%2523f1c998;--dm57:%2523e4af8f;--dm58:%2523e9c4af;--dm59:%2523f0d0bd;--dmw15:rgba(255,255,255,.15);--dmw25:rgba(255,255,255,.25);--dmb15:rgba(0,0,0,.15);--dmb2:rgba(0,0,0,.2);--dmb25:rgba(0,0,0,.25);--dmb35:rgba(0,0,0,.35);--dmb4:rgba(0,0,0,.4);--dmb5:rgba(0,0,0,.5);--dmb6:rgba(0,0,0,.6);--dmb68:rgba(0,0,0,.68);--dmtl:rgba(255,215,0,.1);--dmc:var(--dm29);--dme:white;}.c0{fill:var(--dm6)}.c1{fill:var(--dm11)}.c2{fill:var(--dm12)}.c3{fill:var(--dm18)}.c4{fill:var(--dm28)}.c5{fill:var(--dm27)}.c6{fill:var(--dm0)}.c7{fill:var(--dm3)}%253C/style%253E%253Cdefs%253E%253Cpattern id=\'c\' width=\'2\' height=\'2\' viewBox=\'0 0 2 2\' patternUnits=\'userSpaceOnUse\'%253E%253Cpath d=\'M0,0h2v2h-2z\' fill=\'var(--dm38)\'/%253E%253Cpath d=\'M0,0h1v1h1v1h-1v-1h-1z\' fill=\'var(--dm33)\'/%253E%253C/pattern%253E%253ClinearGradient id=\'s\' x1=\'0\' x2=\'1\' y1=\'0\' y2=\'1\'%253E%253Cstop offset=\'0%2525\' stop-color=\'var(--dm38)\'/%253E%253Cstop offset=\'100%2525\' stop-color=\'var(--dm37)\'/%253E%253C/linearGradient%253E%253ClinearGradient id=\'g\' x1=\'0\' x2=\'1\' y1=\'0\' y2=\'1\'%253E%253Cstop offset=\'0%2525\' stop-color=\'var(--dm42)\'/%253E%253Cstop offset=\'100%2525\' stop-color=\'var(--dm41)\'/%253E%253C/linearGradient%253E%253ClinearGradient id=\'f\' x1=\'0\' x2=\'1\' y1=\'0\' y2=\'1\'%253E%253Cstop offset=\'0%2525\' stop-color=\'%25238393ca\'%253E%253Canimate attributeName=\'stop-color\' values=\'%25238393ca;%25231dc0ed;%2523aaff4f;%2523db3ffd;%25238393ca\' dur=\'6s\' repeatCount=\'indefinite\'%253E%253C/animate%253E%253C/stop%253E%253Cstop offset=\'33%2525\' stop-color=\'%25231dc0ed\'%253E%253Canimate attributeName=\'stop-color\' values=\'%25231dc0ed;%2523aaff4f;%2523db3ffd;%25238393ca;%25231dc0ed\' dur=\'6s\' repeatCount=\'indefinite\'%253E%253C/animate%253E%253C/stop%253E%253Cstop offset=\'66%2525\' stop-color=\'%2523aaff4f\'%253E%253Canimate attributeName=\'stop-color\' values=\'%2523aaff4f;%2523db3ffd;%25238393ca;%25231dc0ed;%2523aaff4f\' dur=\'6s\' repeatCount=\'indefinite\'%253E%253C/animate%253E%253C/stop%253E%253Cstop offset=\'100%2525\' stop-color=\'%2523db3ffd\'%253E%253Canimate attributeName=\'stop-color\' values=\'%2523db3ffd;%25238393ca;%25231dc0ed;%2523aaff4f;%2523db3ffd\' dur=\'6s\' repeatCount=\'indefinite\'%253E%253C/animate%253E%253C/stop%253E%253C/linearGradient%253E%253C/defs%253E%253Cimage href=\'data:image/gif;base64,',
            _background(bgType),
            '\'/%253E%253Cpath d=\'M0,0h57v57h-57z\' class=\'c',
            spawnType,
            (bgType == 0 ? '\' style=\'mix-blend-mode:color\'/%253E' : '\' style=\'display:none\'/%253E'),
            body,
            '%253Cpath d=\'M0,0h57v57h-57v-56h1v55h55v-55h-56z\' fill=\'',
            _frame(frameType),
            '\'/%253E%253C/svg%253E'
        ));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library SmSVG {

    /**
    * @notice render a double-encoded data URI for the attempt SVG
    * @param body body of the SVG markup
    * @return string of svg as a data uri
    */
    function render(string memory body, string memory minerStats)
        external
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(
            'data:image/svg+xml,%253Csvg xmlns=\'http://www.w3.org/2000/svg\' width=\'100%\' height=\'100%\' viewBox=\'0 0 114 114\' preserveAspectRatio=\'xMidYMid meet\'%253E%253Cstyle%253E*{shape-rendering:crispedges;image-rendering:-webkit-crisp-edges;image-rendering:-moz-crisp-edges;image-rendering:crisp-edges;image-rendering:pixelated;-ms-interpolation-mode:nearest-neighbor}:root{--dm0:%25237a09fa;--dm1:%252337104f;--dm2:%2523661e92;--dm3:%2523db3ffd;--dm4:%2523630460;--dm5:%2523b0151a;--dm6:%2523ed1c24;--dm7:%2523f01343;--dm8:%2523876776;--dm9:%2523b48a9e;--dm10:%2523f0b8d3;--dm11:%2523f7941d;--dm12:%2523fff200;--dm13:%2523fcd617;--dm14:%2523fbd958;--dm15:%2523fae391;--dm16:%2523005d2e;--dm17:%2523007c3d;--dm18:%2523209e35;--dm19:%252300a651;--dm20:%252339b54a;--dm21:%2523aaff4f;--dm22:%25232d1c50;--dm23:%252309080b;--dm24:%25231b1a2c;--dm25:%25231e205e;--dm26:%25232e3192;--dm27:%25231452cc;--dm28:%25231dc0ed;--dm29:%2523393754;--dm30:%25232a4c69;--dm31:%25231e8492;--dm32:%25238393ca;--dm33:%2523404247;--dm34:%252356585f;--dm35:%25235a5a5a;--dm36:%2523707070;--dm37:%2523898989;--dm38:%2523b7b7b7;--dm39:%2523dddddd;--dm40:%25234f3810;--dm41:%252392671e;--dm42:%2523bbaa6d;--dm43:%25233e3531;--dm44:%2523534741;--dm45:%25237d5e52;--dm46:%252347210e;--dm47:%2523603114;--dm48:%252380421b;--dm49:%2523984f1d;--dm50:%25233e2309;--dm51:%2523522b0c;--dm52:%252376451d;--dm53:%252394623d;--dm54:%2523cf9768;--dm55:%2523efc088;--dm56:%2523f1c998;--dm57:%2523e4af8f;--dm58:%2523e9c4af;--dm59:%2523f0d0bd;--dmw15:rgba(255,255,255,.15);--dmw25:rgba(255,255,255,.25);--dmb15:rgba(0,0,0,.15);--dmb2:rgba(0,0,0,.2);--dmb25:rgba(0,0,0,.25);--dmb35:rgba(0,0,0,.35);--dmb4:rgba(0,0,0,.4);--dmb5:rgba(0,0,0,.5);--dmb6:rgba(0,0,0,.6);--dmb68:rgba(0,0,0,.68);--dmtl:rgba(255,215,0,.1);--dmc:var(--dm29)}.n{animation:a 1s infinite}.c0{fill:var(--dm6)}.c1{fill:var(--dm11)}.c2{fill:var(--dm12)}.c3{fill:var(--dm18)}.c4{fill:var(--dm28)}.c5{fill:var(--dm27)}.c6{fill:var(--dm0)}.c7{fill:var(--dm3)}@keyframes a{from{opacity:1}50%25{opacity:0}to{opacity:1}}@keyframes b{from{transform:translate(0,0)}50%25{transform:translate(1px,0)}to{transform:translate(0,0)}}@keyframes c{from{transform:translate(0,0);opacity:1}10%25{transform:translate(0,-4px);opacity:0}to{transform:translate(0,-4px);opacity:0}}@keyframes d{from{transform:rotateX(0deg)}25%25{transform:rotateX(30deg)}50%25{transform:rotateX(0deg)}to{transform:rotateX(0deg)}}@keyframes e{from{opacity:0.8}25%25{opacity:0}to{opacity:0}}@keyframes f{from{transform:translate(0,0)}5%25{transform:translate(1px,0)}20%25{transform:translate(1px,0)}25%25{transform:translate(0,0)}to{transform:translate(0,0)}}@keyframes g{from{transform:translate(0,0)}25%25{transform:translate(0,-1px)}50%25{transform:translate(0,0)}75%25{transform:translate(0,0)}to{transform:translate(0,0)}}@keyframes h{from{transform:translate(0,0) rotateZ(0)}25%25{transform:translate(0,-1px) rotateZ(2deg)}50%25{transform:translate(0,0) rotateZ(0)}75%25{transform:translate(0,-1px) rotateZ(-2deg)}to{transform:translate(0,0) rotateZ(0)}}@keyframes i{from{transform:translate(0,0)}50%25{transform:translate(0,3px)}to{transform:translate(0,0)}}@keyframes j{from{transform:rotateY(-90deg) translateZ(1px);filter:brightness(150%25)}50%25{transform:rotateY(0) translateZ(1px);filter:brightness(100%25)}to{transform:rotateY(90deg) translateZ(1px);filter:brightness(50%25)}}@keyframes k{from{transform:translate(0,.5px) rotateZ(2deg)}25%25{transform:translate(0,0) rotateZ(0)}50%25{transform:translate(0,.5px) rotateZ(-2deg)}75%25{transform:translate(0,0) rotateZ(0)}to{transform:translate(0,.5px) rotateZ(2deg)}}@keyframes l{from{transform:translate(0,0)}50%25{transform:translate(0,.5px)}to{transform:translate(0,0)}}@keyframes m{from{transform:translate(0,0);opacity:1}5%25{transform:translate(0,3px);opacity:1}10%25{transform:translate(0,6px);opacity:0}to{transform:translate(0,6px);opacity:0}}@keyframes n{from{filter:invert(0)}50%25{filter:invert(1)}to{filter:invert(0)}}@keyframes o{from{transform:scale(1);opacity:1}20%25{transform:scale(11);opacity:0}to{transform:scale(1);opacity:0}}%2523e0{transform-origin:6px 10px;animation:d 4s infinite}.f path{animation:b 1s infinite}%2523e1 g:nth-of-type(1),%2523e1 g:nth-of-type(2){animation:g 2s infinite}%2523e1 g:nth-of-type(2){animation-delay:-1s}%2523e1 g:nth-of-type(3){transform-origin:6px 6px;animation:k 2s infinite}%2523e1 g:nth-of-type(1) path:nth-of-type(2),%2523e1 g:nth-of-type(2) path:nth-of-type(3){animation:a 2s infinite;animation-delay:-1s}%2523e1 g:nth-of-type(1) path:nth-of-type(3),%2523e1 g:nth-of-type(2) path:nth-of-type(2){animation:a 2s infinite}%2523e2{animation:h 4s infinite;transform-origin:6px 6px}%2523e2 g{animation:i 2s infinite}%2523e3 g:nth-of-type(1){animation:l 2s infinite}%2523e3 g:nth-of-type(2){animation:l 2s infinite;animation-delay:-1.9s}%2523e3 g:nth-of-type(5),%2523e3 g:nth-of-type(6){animation:l 2s infinite;animation-delay:-1.8s}%2523e3 g:nth-of-type(5) path:nth-of-type(3){animation:m 7s infinite linear}%2523e5{animation:l 4s infinite}%2523e5 path:first-of-type{animation:n 2.5s infinite}%2523e6 path:nth-of-type(2),%2523e6 path:nth-of-type(3),%2523e7 path:nth-of-type(2),%2523e7 path:nth-of-type(3){animation:j 3s infinite;transform-origin:6px 6px}%2523e6 path:nth-of-type(2),%2523e7 path:nth-of-type(2){animation-delay:-1.5s}%2523e8 %253E g path{animation:e infinite}%2523e8 %253E g path:nth-of-type(1){animation-duration:4s;animation-delay:-0.75s}%2523e8 %253E g path:nth-of-type(2){animation-duration:3s}%2523e8 %253E g path:nth-of-type(3){animation-duration:5s;animation-delay:-2.15s}%2523e8 %253E g path:nth-of-type(4){animation-duration:6s;animation-delay:-1s}%2523e9 path:nth-of-type(2){animation:f 8s infinite}%2523e15 path{animation:b 4s infinite}%2523e15 path:nth-of-type(2){animation-delay:-2s}%2523e16 rect,%2523e6 rect,%2523e7 rect{animation:c infinite}%2523e16 rect:nth-of-type(1){animation-duration:7s;animation-delay:-0.75s}%2523e16 rect:nth-of-type(2){animation-duration:4s}%2523e16 rect:nth-of-type(3){animation-duration:10s;animation-delay:-2.15s}%2523e16 rect:nth-of-type(4){animation-duration:5s;animation-delay:-1s}.h %253E g,.h %253E g:nth-of-type(3) %253E g:first-of-type,.h %253E g:nth-of-type(4) %253E g,.h %253E g:nth-of-type(5) path{animation:l 2s infinite}.h %253E g:nth-of-type(3),.h %253E g:nth-of-type(4),.h %253E g:nth-of-type(5){animation:none}.h %253E g:nth-of-type(4) %253E g:nth-of-type(1),.h %253E g:nth-of-type(4) %253E g:nth-of-type(3){animation-delay:-1.95s}.h %253E g:nth-of-type(4) %253E g:nth-of-type(4){animation-delay:-1.9s}.h %253E g:nth-of-type(5) path:nth-of-type(2),.h %253E g:nth-of-type(7){animation-delay:-1.85s}.se path{transform-origin:11px 11px;animation:o 6s infinite}.se path:nth-of-type(2){animation-delay:-2s}.se path:nth-of-type(3){animation-delay:-4s}@font-face{font-family:\'txt\';src:url(data:application/font-woff;charset=utf-8;base64,d09GRgABAAAAAAdsABAAAAAAC7AAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAABGRlRNAAABbAAAABwAAAAcja3TXUdERUYAAAGIAAAAHAAAAB4AJwAWR1BPUwAAAaQAAACkAAAA+BVXIoxHU1VCAAACSAAAACwAAAAwuP+4/k9TLzIAAAJ0AAAAUQAAAGBaR5KLY21hcAAAAsgAAABXAAABUhJ0SA5jdnQgAAADIAAAAAQAAAAEACECeWdhc3AAAAMkAAAACAAAAAj//wADZ2x5ZgAAAywAAAHAAAADYIgAY9poZWFkAAAE7AAAADMAAAA2FUXaomhoZWEAAAUgAAAAHAAAACQGEAHsaG10eAAABTwAAAAnAAAANhH1AeNsb2NhAAAFZAAAACIAAAAiBsgGDG1heHAAAAWIAAAAHwAAACAAWQBNbmFtZQAABagAAAF6AAAC7iBFbQlwb3N0AAAHJAAAAEYAAABYUqv82AAAAAEAAAAA2odvjwAAAADVbK0RAAAAAN25trx42mNgZGBg4AFiMSBmYmAEQn4gZgHzGAAEQwA+eNpNjr0NwjAUhL/8kDjBZABKJkBUVKkQFWUWIBISEigFQszBAIiKeRiAXYg5OykoPt/5vTvZREDJkpp4s901VOf9tWNOqjnO4ff/PjodLh3Gu0BKHNSIV0haFjS0HEXLLZx38dQm6S1pXzP5fsikuTDyhSjlp8LKz6SVNCFxbzUshVvrBX8bZoV7YEU2JLwTuTDjZuyq57PqstJfvVbwAzvDOvV42mNgZGBg4GLQYdBjYHJx8wlh4MtJLMljkGBgAYoz/P8PJBAsIAAAnsoHa3jaY2BhfMI4gYGVgYWpi2k3AwNDD4RmvM9gyMjEwMDEwMrMAAPMAiABKPAOcMtkOMCgoPqHWeG/BVBSgdEBKMwIkmP8wrQHSCkwMAEAfGEMtAAAAHjaY2BgYGaAYBkGRgYQ8AHyGMF8FgYDIM0BhExAWoHBUvXP//9glj6I9f/x/6u3hKG6wICRjQHOZQTpYWJABYwQq5AACysbOwcnFzcPLx/DsAAAGUoM1AAAIQJ5AAAAAf//AAJ42nVTwUoDMRCdSVqXYkVCWUSkh2XBghSFXZZe6s1/sB8QPPdTeu4XeG3P9eKl+YAe/QAveupJ7OKbJF2raCDZJLvz5r03s6QoI+IrNSdNCV0vmG7Gy6RFb8XiqP0yXmqFLS20XLflepkc8ed4yXJfmswMSpNn3Hldr9V895CpCQGnIFLvauUxj+mUenRGF0RlVaa3/Pcs7P+DiFqCyc/qqcGkkSlNWo1SjXnOpSmsc85a3tZdrFbdY6m7ckQ8Szx9gFNC1KvAxORGcvLW2t0db/FWxxwr6tAJpZ4vGOdplnJkHqKc42E9tUjmbITAqDc8pHaDISyj7hGigVPpquzzr72geRzngliexSMPZXWw0vt5CUxxUtinZZVDAXDAZxBQPBdneSi7euPpOO/dty4ddAkfXWXQJUyMIJlcKsCzeuMiEZ75J8yE2M1hDVZNTaUG3iHM/t4jHVVFIHEnkBNNEBf0ND5DT4bs0FNp8CjkE3yuJiLCut2jpD/IrQ9d1b5CoiLfa2m6yZvoopXhADlTz+MHXhK1BLwUGOKudEjUEmO9HkA5X3sHZ0DSSm9Jg23RQ5oIv0QmPRf67gvXHN4geNpjYGQAAmPjswfWpMbz23xlkGd+ARK5mrNWEETf3bltD4hmese0F0hxMDCBeAB6vgxvAHjaY2BkYGBW+HcARDIAAdM7BkYGVMANAE1nAwJ42mPMYVBkAAJGXyCRwsDArMBgxPgFiHWgNBAzRUBoOGQAAMdwB+UAAAAAKgAqACoAKgBUAHQAhgCoANIA8gEWAToBVAF8AaIBsAAAeNpjYGRgYBBgkGFgZwABJiBmZACJOTDogQQACCwApwB42n1RXUsCQRQ9s1rUQ9JTiPQw9BAFYetihT71AUElGSn1nLaZuK3mbkJ/pJ8R/Yyy/kA99St67szdSURChrn33HvPnHtnBkAGz0hBpecBvHAnWGGZUYIdcj4sTjH/ZXEaG/ixeAZZtWLxLHKqbPEC9lXd4gyK6sniVyypocVvcNW3xUPMOYsWvyPjZBP8mULOWcUBuujhEX200cItYmisoYl1eg8uCihxJo1jXCEi0yfTxOc815AottUGAuZCsjrU0tjlPiEKyYrpmzgjw6jc0WocCjtmbPT2WAtE92+OSCKf3nQZ0F4jL/OGotkUVRNpHMky7BYepEt/KnNaTU/oXEj/aMRyOYVH/59GolDjrpBRlfcKx+6qmTcv4cs7+Ywn1QtUL8j9Y54uY5Mr4gnzPz15lbywA/ousy3Wq9Sv4JJKDdyMOhklF3Xew/Q5ZX4g2W2xRWp72KHdok3+2mO+Q7bPTj07l8/z0dj8Ndwz02atz1rwC0zLcWwAAHjaY2BiAIP/zQxGDNiAAAMDIxMjMwMzgxCDMIMIgyiDGIM4gwSDJIMUgzSDDCMLW3pOZUGGIYQyYi/NyzQydXMGAAIJCc0AAA==) format(\'woff\');font-weight:normal;font-style:normal}text{filter:drop-shadow(0px 1px 0px rgba(0,0,0,.2))}%253C/style%253E%253Cdefs%253E%253Cpattern id=\'ch1\' x=\'1\' y=\'0\' width=\'2\' height=\'2\' viewBox=\'0 0 2 2\' patternUnits=\'userSpaceOnUse\'%253E%253Cpath d=\'M0,0h1v1h1v1h-1v-1h-1z\' fill=\'var(--dm41)\'/%253E%253C/pattern%253E%253Cpattern id=\'ch2\' x=\'1\' y=\'0\' width=\'2\' height=\'2\' viewBox=\'0 0 2 2\' patternUnits=\'userSpaceOnUse\'%253E%253Cpath d=\'M0,0h1v1h1v1h-1v-1h-1z\' fill=\'var(--dm37)\'/%253E%253C/pattern%253E%253Cpattern id=\'ch3\' x=\'1\' y=\'0\' width=\'2\' height=\'2\' viewBox=\'0 0 2 2\' patternUnits=\'userSpaceOnUse\'%253E%253Cpath d=\'M0,0h1v1h1v1h-1v-1h-1z\' fill=\'var(--dm48)\'/%253E%253C/pattern%253E%253Cg id=\'a\'%253E%253Cpath d=\'M0,0h12v12h-12z\'/%253E%253Cpath d=\'M0,10h12v2h-12z\' fill=\'var(--dmb25)\'/%253E%253Cpath d=\'M2,2h8v8h2v2h-2v-1h-1v-1h-6v1h-1v1h-2v-2h2z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M2,2h8v8h2v2h-1v-1h-1v-1h-8v1h-1v1h-1v-2h2z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M2,2h8v8h-8z\' fill=\'var(--dmb35)\'/%253E%253Cpath d=\'M2,2h8v8h-3v-2h-2v2h-3z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M2,2h8v8h-2v-2h-1v-1h-2v1h-1v2h-2z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M2,2h8v8h-1v-3h-1v-1h-4v1h-1v3h-1z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M2,2h8v3h-1v-1h-6v1h-1z\' fill=\'var(--dmb15)\'/%253E%253C/g%253E%253Cpath id=\'u\' d=\'M0,0h12v12h-12z\' fill=\'var(--dmw15)\'/%253E%253Cg id=\'e0\'%253E%253Cpath d=\'M5,6h2v1h1v1h1v2h-6v-2h1v-1h1z\' fill=\'var(--dm6)\'/%253E%253Cpath d=\'M4,8h1v1h-1zM6,8h1v1h-1z\' fill=\'black\'/%253E%253Cpath d=\'M6,6h1v1h1v1h1v2h-1v-2h-1v-1h-1zM4,9h1v1h-1zM6,9h1v1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253Cg id=\'e1\'%253E%253Cpath d=\'M4,7h4v2h-4z\' fill=\'var(--dm4)\'/%253E%253Cg%253E%253Cpath d=\'M3,8h1v2h-1z\' fill=\'var(--dm4)\'/%253E%253Cpath d=\'M3,8h1v1h-1z\' fill=\'var(--dmb25)\'/%253E%253Cpath d=\'M3,9h1v1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253Cg%253E%253Cpath d=\'M8,8h1v2h-1z\' fill=\'var(--dm4)\'/%253E%253Cpath d=\'M8,8h1v1h-1z\' fill=\'var(--dmb25)\'/%253E%253Cpath d=\'M8,9h1v1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253Cg%253E%253Cpath d=\'M4,4h4v1h1v1h-1v1h-1v1h-2v-1h-1v-1h-1v-1h1z\' fill=\'white\'/%253E%253Cpath d=\'M4,5h1v1h-1zM7,5h1v1h-1z\' fill=\'var(--dm6)\'/%253E%253Cpath d=\'M4,4h1v1h-1zM7,4h1v1h1v1h-1v2h-1v1h-2v-1h-1v-1h1v1h1v-1h1v-1h1v-1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253C/g%253E%253Cg id=\'e2\'%253E%253Cg%253E%253Cpath d=\'M3,3h1v3h-1zM8,3h1v3h-1z\' fill=\'var(--dm4)\'/%253E%253Cpath d=\'M8,3h1v3h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253Cpath d=\'M4,4h1v4h-1zM7,4h1v4h-1z\' fill=\'var(--dm4)\'/%253E%253Cpath d=\'M5,5h2v3h1v1h-1v-1h-2v1h-1v-1h1z\' fill=\'var(--dm18)\'/%253E%253Cpath d=\'M5,6h2v1h-2z\' fill=\'white\'/%253E%253Cpath d=\'M4,4h1v2h-1zM6,5h1v1h1v3h-1v-1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253Cg id=\'e3\'%253E%253Cg%253E%253Cpath d=\'M5,3h2v2h-2z\' fill=\'white\'/%253E%253Cpath d=\'M6,4h1v1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253Cg%253E%253Cpath d=\'M4,5h1v1h-1zM7,5h1v1h-1z\' fill=\'white\'/%253E%253C/g%253E%253Cg%253E%253Cpath d=\'M5,6h2v2h-2z\' fill=\'white\'/%253E%253Cpath d=\'M6,6h1v2h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253Cg%253E%253Cpath d=\'M4,8h1v2h-1zM7,8h1v2h-1z\' fill=\'white\'/%253E%253Cpath d=\'M7,8h1v2h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253Cg%253E%253Cpath d=\'M3,6h1v1h-1z\' fill=\'white\'/%253E%253Cpath d=\'M3,4h1v2h-1z\' fill=\'var(--dm38)\'/%253E%253Cpath d=\'M3,3h1v1h-1z\' fill=\'var(--dm6)\'/%253E%253Cpath d=\'M3,3h1v1h-1z\' fill=\'var(--dm6)\'/%253E%253C/g%253E%253Cg%253E%253Cpath d=\'M7,6h1v2h-1z\' fill=\'white\'/%253E%253Cpath d=\'M8,6h1v3h-1z\' fill=\'var(--dm48)\'/%253E%253Cpath d=\'M7,6h1v1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253C/g%253E%253Cg id=\'e4\'%253E%253Cpath d=\'M3,9h1v-1h2v1h2v-1h1v2h-6z\' fill=\'var(--dm38)\'/%253E%253Cpath d=\'M3,7h1v2h-1zM5,7h2v2h-1v-1h-1zM8,7h1v1h-1z\' fill=\'var(--dm6)\'/%253E%253Cpath d=\'M4,8h1v2h-1zM6,7h1v3h-1zM8,7h1v3h-1z\' fill=\'var(--dmb15)\'/%253E%253C/g%253E%253Cg id=\'e5\'%253E%253Cpath d=\'M3,3h1v1h4v-1h1v1h-1v3h-1v1h-2v-1h-1v-3h-1zM3,8h1v1h-1zM8,8h1v1h-1z\' fill=\'var(--dm9)\'/%253E%253Cpath d=\'M4,4h1v1h1v1h-1v-1h-1zM5,7h1v1h-1z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M3,3h1v1h-1zM8,3h1v1h-1v3h-1v1h-1v-1h1v-1h-1v-1h1v-1h1zM3,8h1v1h-1zM8,8h1v1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253Cg id=\'e6\'%253E%253Cpath d=\'M4,8h4v1h-1v1h-2v-1h-1z\' fill=\'var(--dm36)\'/%253E%253Cpath d=\'M5,5h2v2h-2z\' fill=\'var(--dm18)\'/%253E%253Cpath d=\'M5,5h2v2h-2z\' fill=\'var(--dm18)\'/%253E%253Cpath d=\'M7,8h1v1h-1v1h-1v-1h1z\' fill=\'var(--dmb15)\'/%253E%253C/g%253E%253Cg id=\'e7\'%253E%253Cpath d=\'M4,8h4v1h-1v1h-2v-1h-1z\' fill=\'var(--dm36)\'/%253E%253Cpath d=\'M5,5h2v2h-2z\' fill=\'var(--dm6)\'/%253E%253Cpath d=\'M5,5h2v2h-2z\' fill=\'var(--dm6)\'/%253E%253Cpath d=\'M7,8h1v1h-1v1h-1v-1h1z\' fill=\'var(--dmb15)\'/%253E%253C/g%253E%253Cg id=\'e8\'%253E%253Cpath d=\'M3,9h1v-2h2v1h2v1h1v1h-6z\' fill=\'var(--dm13)\'/%253E%253Cpath d=\'M3,9h1v1h-1zM5,7h1v3h-1zM7,8h1v2h-1z\' fill=\'var(--dmb25)\'/%253E%253Cg%253E%253Cpath d=\'M4,7h1v1h-1z\' fill=\'white\'/%253E%253Cpath d=\'M8,9h1v1h-1z\' fill=\'white\'/%253E%253Cpath d=\'M6,8h1v1h-1z\' fill=\'white\'/%253E%253Cpath d=\'M4,9h1v1h-1z\' fill=\'white\'/%253E%253C/g%253E%253C/g%253E%253Cg id=\'e9\'%253E%253Cpath d=\'M5,4h2v2h-2z\' fill=\'var(--dm33)\'/%253E%253Cpath d=\'M5,5h1v1h-1z\' fill=\'var(--dm58)\'/%253E%253Cpath d=\'M5,7h1v1h-1zM7,7h1v1h-1z\' fill=\'var(--dm58)\'/%253E%253Cpath d=\'M6,6h2v1h-1v1h-1z\' fill=\'var(--dm48)\'/%253E%253Cpath d=\'M5,8h2v1h1v1h-1v-1h-1v1h-1z\' fill=\'var(--dm26)\'/%253E%253Cpath d=\'M3,5h1v1h1v1h-1v-1h-1z\' fill=\'var(--dm38)\'/%253E%253Cpath d=\'M6,4h1v2h1v1h-1v-1h-1zM5,9h1v1h-1zM7,9h1v1h-1z\' fill=\'var(--dmb15)\'/%253E%253C/g%253E%253Cg id=\'e10\'%253E%253C/g%253E%253Cg id=\'e11\'%253E%253Cpath d=\'M8,7h1v3h-6v-2h5z\' fill=\'var(--dm48)\'/%253E%253Cpath d=\'M4,8h3v1h-3z\' fill=\'var(--dm38)\'/%253E%253Cpath d=\'M7,8h1v1h-1z\' fill=\'white\'/%253E%253Cpath d=\'M4,9h4v1h-4z\' fill=\'var(--dmb15)\'/%253E%253C/g%253E%253Cg id=\'e12\'%253E%253Cpath d=\'M4,6h4v3h-1v1h-2v-1h2v-1h-2v1h-1z\' fill=\'var(--dm38)\'/%253E%253Cpath d=\'M7,6h1v3h-1v1h-1v-1h1v-1h-2v-1h2z\' fill=\'var(--dmb15)\'/%253E%253C/g%253E%253Cg id=\'e13\'%253E%253Cpath d=\'M6,7h1v1h-1z\' fill=\'var(--dm27)\'/%253E%253Cpath d=\'M6,6h1v1h-1z\' fill=\'var(--dm58)\'/%253E%253Cpath d=\'M3,5h1v3h4v-3h1v5h-6z\' fill=\'var(--dm48)\'/%253E%253Cpath d=\'M3,4h6v1h-6zM4,8h4v1h-4z\' fill=\'var(--dm38)\'/%253E%253Cpath d=\'M4,4h1v1h-1zM6,4h1v1h-1zM8,4h1v1h-1z\' fill=\'var(--dm6)\'/%253E%253Cpath d=\'M3,5h1v1h-1zM8,5h1v5h-1v-1h-1v-1h1z\' fill=\'var(--dmb15)\'/%253E%253C/g%253E%253Cg id=\'e14\'%253E%253Cpath d=\'M4,6h4v1h1v3h-6v-3h1z\' fill=\'var(--dm48)\'/%253E%253Cpath d=\'M5,7h2v1h-2z\' fill=\'var(--dm12)\'/%253E%253Cpath d=\'M4,6h1v2h1v-2h2v1h-1v1h1v-1h1v3h-1v-1h-1v1h-1v-1h-1v1h-1v-1h-1v-1h1z\' fill=\'var(--dmb15)\'/%253E%253C/g%253E%253Cg id=\'e15\'%253E%253Cpath d=\'M5,5h1v1h1v1h-1v1h-1v-1h-1v-1h1z\' fill=\'var(--dm5)\'/%253E%253Cpath d=\'M5,5h1v1h1v1h-1v1h-1v-1h-1v-1h1z\' fill=\'var(--dm6)\'/%253E%253C/g%253E%253Cg id=\'e16\'%253E%253Crect x=\'5\' y=\'8\' height=\'1\' width=\'1\' fill=\'var(--dm28)\'/%253E%253Crect x=\'5\' y=\'8\' height=\'1\' width=\'1\' fill=\'var(--dm28)\'/%253E%253Crect x=\'6\' y=\'8\' height=\'1\' width=\'1\' fill=\'var(--dm28)\'/%253E%253Crect x=\'6\' y=\'8\' height=\'1\' width=\'1\' fill=\'var(--dm28)\'/%253E%253Cpath d=\'M4,8h4v1h-1v1h-2v-1h-1z\' fill=\'var(--dm28)\'/%253E%253Cpath d=\'M5,6h2v2h1v1h-1v1h-2v-1h-1v-1h1v1h2v-1h-2z\' fill=\'var(--dmw25)\'/%253E%253Cpath d=\'M5,6h2v1h-1v1h-1v1h1v1h-1v-1h-1v-1h1z\' fill=\'var(--dmw25)\'/%253E%253Cpath d=\'M6,6h1v2h1v1h-1v1h-2v-1h2v-1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253Cg id=\'e17\'%253E%253Cpath d=\'M3,3h1v1h1v1h-1v-1h-1zM8,3h1v1h-1v1h-1v-1h1z\' fill=\'var(--dm28)\'/%253E%253Cpath d=\'M3,5h1v1h4v-1h1v2h-1v1h-1v1h-2v-1h-1v-1h-1z\' fill=\'white\'/%253E%253Cpath d=\'M3,5h1v1h-1zM8,5h1v1h-1zM5,6h2v1h-2zM4,7h1v1h2v-1h1v1h-1v1h-2v-1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E%253C/defs%253E%253Cimage href=\'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAHIAAAByCAMAAAC4A3VPAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAFpQTFRFNS0qW1NQDw4ZCwoTFxYlFBMhLiglGxost7e3FBMg7RwkIJ41vaARgEIbPiMJ/NYXiYmJshUbYDEUGHYoERAbv7+/////LhoHg5PKYm6XPjUxHBsqGxopGhknav76VwAAAaxJREFUeNrsl21vgjAUhWFzXWdhyngRu/H//+baWwZM762BzPph58Q0JjU8uSePN5oNyZMNX58uKU+H9El5Zg8oNnGr7swStzo8plgYC2NhLIyFsTAWxsJYGAtjYSyMhbEwFsbCWBgLY2EsjIWxMBbGwlgYC2NhLIyFsTAWxsJYGAtjYexmY/OkoWJzmzAZGZvbZzb3QZKxiZGh2AhyX/mXHK3Fq0MhFDvQlE9XCcg9pYoQjyuRwdjtSEdUIo9HTsVuQfYRouMdiiJqrIRUROSfq3qZSEhuzNlYx3hZZEJ6ZiU9tz+LxEJGLorlkVbJRKXO65FLYwWkFSdRsbuQG8Y60ivlAnmvVZAOuTQ21ZS/jWWQWosLpuva1hrD3pUhW4rVWmZ6P4ypeeS7T3nb2HXIzs9YR5CmlI1tmjfKjhLeNw0hyXVpSk9UItKcIsU2M2+mBiR9jke2xiGFb2ZpHFEq1ht7ARyhhDz+HNwqcEwjIE+OyCJHY6+ABKXHepqwvLtW1RLzI0QudsdmWndKWmqWX2rRhTcaG0H++SoYjU35o5KKzZLmv/zz+hZgABfeLcXmx3tAAAAAAElFTkSuQmCC\'/%253E',
            body,
            minerStats,
            '%253C/svg%253E'
        ));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

struct Monster {
    int16 health;
    int16 attack;
    int16 speed;
    uint8 mtype;
}