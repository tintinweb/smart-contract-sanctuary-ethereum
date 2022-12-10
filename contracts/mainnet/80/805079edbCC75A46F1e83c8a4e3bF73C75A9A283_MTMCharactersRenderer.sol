/**
 *Submitted for verification at Etherscan.io on 2022-12-10
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Open0x Minified Ownable (by 0xInuarashi
// Only use if you know what you are doing!
// No renounce ownership. Renounce by transferring ownership to address(0x0) yourself.
abstract contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed oldOwner_, address indexed newOwner_);

    constructor() { owner = msg.sender; }

    modifier onlyOwner { require(owner == msg.sender, "Ownable: CNO"); _; }

    function _transferOwnership(address newOwner_) internal virtual {
        address _oldOwner = owner; owner = newOwner_;
        emit OwnershipTransferred(_oldOwner, newOwner_);    
    }

    function transferOwnership(address newOwner_) public virtual onlyOwner {
        _transferOwnership(newOwner_);
    }
}

// Strings for UINT to String
library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) { return "0"; }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) { digits++; temp /= 10; }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    function toString8(uint8 value) internal pure returns (string memory) {
        if (value == 0) { return "0"; }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) { digits++; temp /= 10; }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

library Base64 {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";
        string memory table = TABLE;
        uint256 encodedLen = 4 * ((data.length + 2) / 3);
        string memory result = new string(encodedLen + 32);
        assembly {
            mstore(result, encodedLen)
            let tablePtr := add(table, 1)
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            let resultPtr := add(result, 32)
            for {} lt(dataPtr, endPtr) {} {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }
        return result;
    }
}

// iFont for Base64 Font Interface
interface iFont {
    function fontBase64() external view returns (string memory);
}


// iSC for Space Capsule Data Interface
interface iSC {
    function getWeapon(uint256 tokenId) external view returns (string memory);
    function getChest(uint256 tokenId) external view returns (string memory);
    function getHead(uint256 tokenId) external view returns (string memory);
    function getLegs(uint256 tokenId) external view returns (string memory);
    function getVehicle(uint256 tokenId) external view returns (string memory);
    function getArms(uint256 tokenId) external view returns (string memory);
    function getArtifact(uint256 tokenId) external view returns (string memory);
    function getRing(uint256 tokenId) external view returns (string memory);
}

// iCS for Character Storage Data Interface
interface iCS {
    // Structs of Characters
    struct Character {
        uint8 race_;
        uint8 renderType_;
        uint16 transponderId_;
        uint16 spaceCapsuleId_;
        uint8 augments_;
        uint16 basePoints_;
        uint16 totalEquipmentBonus_;
    }
    struct Stats {
        uint8 strength_; 
        uint8 agility_; 
        uint8 constitution_; 
        uint8 intelligence_; 
        uint8 spirit_; 
    }
    struct Equipment {
        uint8 weaponUpgrades_;
        uint8 chestUpgrades_;
        uint8 headUpgrades_;
        uint8 legsUpgrades_;
        uint8 vehicleUpgrades_;
        uint8 armsUpgrades_;
        uint8 artifactUpgrades_;
        uint8 ringUpgrades_;
    }

    // View Functions
    function names(uint256 tokenId_) external view returns (string memory);
    function bios(uint256 tokenId_) external view returns (string memory);
    function characters(uint256 tokenId_) external view returns (Character memory);
    function stats(uint256 tokenId_) external view returns (Stats memory);
    function equipments(uint256 tokenId_) external view returns (Equipment memory);
    function contractToRace(address contractAddress_) external view returns (uint8);
}

// iCI for Character Image Storage Data Interface
interface iCI {
    function getCharacterImage(uint8 race_, uint8 rank_) external view returns (string memory);
    function getCharacterImage2(uint8 race_, uint8 rank_) external view returns (string memory); // NOTE: ADD THIS!!!!
    function raceToRaceName(uint8 race_) external view returns (string memory); 
}

// iCC for Character Controller Data Interface 
interface iCC {
    function getCharacterYieldRate(uint256 characterId_) external view returns (uint256);
    function getItemRarity(uint16 spaceCapsuleId_, string memory keyPrefix_) external view returns (uint8);
    function queryBaseEquipmentTier(uint8 rarity_) external view returns (uint8);
}

contract MTMCharactersRenderer is Ownable {
    // Interfaces
    iFont Font; iSC SC; iCS CS; iCI CI; iCC CC;
    function setContracts(address font_, address sc_, address cs_, address ci_, address cc_) external onlyOwner {
        Font = iFont(font_); SC = iSC(sc_); CS = iCS(cs_); CI = iCI(ci_); CC = iCC(cc_);
    }

    // Font 
    function __getFont() internal view returns (string memory) {
        return Font.fontBase64();
    }

    // SVG Bases
    string internal constant __SVGHeader = "<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' width='1200' height='1400' viewBox='0 0 1200 1400'><style>";
    string internal constant __SVGFontHeader = "@font-face{font-family:'Minecraft'; src:url('data:application/font-truetype;charset=utf-8;base64,"; 
    string internal constant __SVGFontFooter = "')}.sC0{font-family: 'Minecraft'; font-size:16px; fill: white; } .sC1{font-family: 'Minecraft'; font-size:16px; fill: #00FF00; } .sC2{font-family: 'Minecraft'; font-size:16px; fill: #FFFF00; } .sC3{font-family: 'Minecraft'; font-size:16px; fill: #FF9E3D; } .sC4{font-family: 'Minecraft'; font-size:16px; fill: #FF00D6; } .sC5{font-family: 'Minecraft'; font-size:16px; fill: #B026FF; } .sC6{font-family: 'Minecraft'; font-size:16px; fill: #F72119; } .title{font-family: 'Minecraft'; font-size:48px; fill: white; } .stats{font-family: 'Minecraft'; font-size:24px; fill: white; } .stats2{font-family: 'Minecraft'; font-size:24px; fill: cyan; } .hp{font-family: 'Minecraft'; font-size:24px; fill: red; } .mp{font-family: 'Minecraft'; font-size:24px; fill: #2380f5; }</style>"; 
    string internal constant __SVGFooter = "</svg>";

    // SVG Image Bases
    string internal constant __IMGInitRect = "<rect width='100%' height='100%' fill='black'/>";
    string internal constant __IMGInitStars = "<g fill='#fff'><path opacity='.5' d='M76 189h10v30H76z'/><path opacity='.5' d='M66 199h30v10H66zM25 506h10v30H25z'/><path opacity='.5' d='M15 516h30v10H15zM134 54h10v30h-10z'/><path opacity='.5' d='M124 64h30v10h-30zm27 356h10v30h-10z'/><path opacity='.5' d='M141 430h30v10h-30zM81 700h10v30H81z'/><path opacity='.5' d='M71 710h30v10H71zM984 74h10v30h-10z'/><path opacity='.5' d='M974 84h30v10h-30zm163 209h10v30h-10z'/><path opacity='.5' d='M1127 303h30v10h-30zm-99 112h10v30h-10z'/><path opacity='.5' d='M1018 425h30v10h-30zm99 112h10v30h-10z'/><path opacity='.5' d='M1107 547h30v10h-30zm-59 235h10v30h-10z'/><path opacity='.5' d='M1038 792h30v10h-30zM66 313h10v10H66zm62 512h10v10h-10zM96 450h10v10H96zM45 797h10v10H45zm131-593h10v10h-10zm5 469h10v10h-10zM35 104h10v10H35zm1112-15h10v10h-10zm-99 151h10v10h-10zm-84 78h10v10h-10zm153 102h10v10h-10zm30 310h10v10h-10zm-104-96h10v10h-10zm114-10h10v10h-10z'/></g>";

    // SVG Image Title
    string internal constant __IMGTitleHeader = "<text x='50%' y='90' text-anchor='middle' class='title'>";
    string internal constant __IMGTitleFooter = "</text>";

    // // Rewrite Starts Here...
    // SVG Image Character Box
    string internal constant __IMGCharacterBoxOpen = "<g transform='translate(250 130)'><g fill='#000000'><rect width='700' height='700' stroke='white' stroke-width='4'/></g>";
    string internal constant __IMGCharacterBoxClose = "</g>";

    // // Now, we have more internal functions, but they are now getter functions using view or passed in arguments instead of pure and calling the previous internal pure functions.
    function __renderInit(string memory font_) internal pure returns (string memory) {
        return string(abi.encodePacked(__SVGHeader, __SVGFontHeader, font_, __SVGFontFooter));
    }
    function __renderRect() internal pure returns (string memory) {
        return string(abi.encodePacked(__IMGInitRect, __IMGInitStars));
    }

    function __getCharacterPower(uint256 yieldRate_) internal pure returns (uint256) {
        return yieldRate_ / (10 ** 18);
    }
    function __getName(uint256 tokenId_, string memory name_, uint16 level_, uint256 power_) internal pure returns (string memory) {
        return string(abi.encodePacked(__IMGTitleHeader, name_, ' (Lv: ', Strings.toString(level_), ', Pwr: ', Strings.toString(power_), ') # ', Strings.toString(tokenId_), __IMGTitleFooter));
    }
    function __renderName(uint256 characterId_, iCS.Character memory Character_) internal view returns (string memory) {
        string memory _name = bytes(CS.names(characterId_)).length == 0 ? "Character" : CS.names(characterId_);
        return __getName(characterId_, _name, Character_.basePoints_, __getCharacterPower(CC.getCharacterYieldRate(characterId_)));
    }

    // // Rewrite of All the shits!!!!!!!!

    // // Now, we have some public functions of the renderer.
    function __getCharacterRank(uint8 augments_) internal pure returns (uint8) {
        if (augments_ <= 2) { return 1; }
        else if (augments_ >= 3 && augments_ <= 4) { return 2; }
        else if (augments_ >= 5 && augments_ <= 6) { return 3; }
        else if (augments_ >= 7 && augments_ <= 9) { return 4; }
        else if (augments_ >= 10) { return 5; }
        else { revert("Invalid augments"); }
    }
    function __getCharacterImage(uint8 race_, uint8 rank_, uint8 renderType_) internal view returns (string memory) {
        string memory _imageHeader = "<image x='2' y='2' width='696' height='696' image-rendering='pixelated' preserveAspectRatio='xMidYMid' xlink:href='data:image/png;base64,";
        string memory _imageFooter = "' />";
        if      (renderType_ == 1) { return string(abi.encodePacked(_imageHeader, CI.getCharacterImage(race_, rank_), _imageFooter)); }
        else if (renderType_ == 2) { return string(abi.encodePacked(_imageHeader, CI.getCharacterImage2(race_, rank_), _imageFooter)); }
        else { return ""; }
    }
    function __getCharacterBox(string memory base64Image_) internal pure returns (string memory) {
        return string(abi.encodePacked(__IMGCharacterBoxOpen, base64Image_, __IMGCharacterBoxClose));
    }
    function __renderCharacterImage(iCS.Character memory Character_) internal view returns (string memory) {
        return __getCharacterBox( __getCharacterImage(Character_.race_, __getCharacterRank(Character_.augments_), Character_.renderType_ ));
    }

    // Here is BIO!
    string internal constant __bioBoxOpen = "<g transform='translate(180 856)'><rect width='840' height='115' stroke='white' stroke-width='4'/></g> <defs> <path id='textPath' d='M200,890 H1000 M200,920 H1000 M200,950 H1000'></path> </defs> <text> <textPath class='stats' xlink:href='#textPath'>";
    string internal constant __bioBoxClose = "</textPath> </text>";
    function __getBioBox(string memory bio_) internal pure returns (string memory) {
        string memory _bio = bytes(bio_).length != 0 ? bio_ : "A Character beamed up to Mars through technology enabled by our breakthrough in the Ethereum Virtual Machine."; // NOTE: CHANGE THIS!!!
        return string(abi.encodePacked( __bioBoxOpen, _bio, __bioBoxClose ));
    }
    function __renderBioBox(uint256 characterId_) internal view returns (string memory) {
        return __getBioBox(CS.bios(characterId_));
    }

    // After that, we have the new STAT BOXES!
    string internal constant __statBox1Open = "<g transform='translate(40 1000)' fill='white'> <rect width='540' height='360' fill='black' stroke='white' stroke-width='4'/>";
    string internal constant __statBox1Close = "</g>";
    // So, the stat boxes has big main items and smaller sub-items.
    function __getStatBox1MainItem(string memory itemName_, string memory value_, uint256 pos_) internal pure returns (string memory) {
        uint256 _y = (pos_ * 32) + 4;
        return string(abi.encodePacked( "<text x='16' y='", Strings.toString(_y), "' class='stats'>", itemName_, value_, "</text>" ));
    }
    function __getStatBox1YieldItem(string memory itemName_, string memory value_, uint256 pos_) internal pure returns (string memory) {
        uint256 _y = (pos_ * 32) + 4;
        return string(abi.encodePacked( "<text x='16' y='",  Strings.toString(_y), "' class='stats2'>", itemName_, value_, " MES / Day", "</text>" ));
    }
    // And then, the stat boxes has the smaller sub-items.
    string internal constant __statBox1SubOpen = "<g transform='translate(0 180)'>";
    string internal constant __statBox1SubClose = "</g>";
    function __getStatBox1SubItem(string memory itemName_, string memory value_, string memory color_, uint256 pos_) internal pure returns (string memory) {
        uint256 _y = 20 * pos_;
        return string(abi.encodePacked( "<text x='16' y='",  Strings.toString(_y), "' class='sC", color_, "'>", itemName_, value_, "</text>" ));
    }
    // Now some tools for deciphering
    function __getItemLevel(uint16 spaceCapsuleId_, string memory keyPrefix_, uint8 upgrades_) internal view returns (uint8) {
        return uint8( CC.queryBaseEquipmentTier(CC.getItemRarity(spaceCapsuleId_, keyPrefix_)) + upgrades_);
    }
    function __getFormattedYieldRate(uint256 yieldRate_) public pure returns (string memory) {
        uint256 _modulus = 10 ** 14; // 4 decimal places
        uint256 _formattedRate = yieldRate_ / _modulus; // turns it to 4 decimals 
        string memory _rateString = Strings.toString(_formattedRate); // now we have a string of the rate
        bytes memory _strBytes = bytes(_rateString); // now be turn it to bytes
        string memory _formattedYieldRate; // set the local variable for returning
        if (_strBytes.length > 4) { 
            uint256 _decimalPosition = _strBytes.length - 4;
            for (uint256 i = 0; i < _strBytes.length; i++) {
                if (i != _decimalPosition) { _formattedYieldRate = string(abi.encodePacked(_formattedYieldRate, _strBytes[i])); } 
                else if (i == _decimalPosition) { _formattedYieldRate = string(abi.encodePacked(_formattedYieldRate, ".", _strBytes[i])); }
            }
        }
        else if (_strBytes.length == 4) {
            _formattedYieldRate = string(abi.encodePacked("0.", _strBytes));
        }
        else if (_strBytes.length < 4) {
            // this should never happen
            uint256 _padding = 4 - _strBytes.length;
            for (uint256 i = 0; i < _padding; i++) {
                if (i == 0) { _formattedYieldRate = string(abi.encodePacked("0.", "0")); }
                else {  _formattedYieldRate = string(abi.encodePacked(_formattedYieldRate, "0")); }
            }
            _formattedYieldRate = string(abi.encodePacked(_formattedYieldRate, _strBytes));
        }
        else if (_strBytes.length == 0) {
            return "0"; // this should never happen
        }
        return _formattedYieldRate;
    }

    bool public showYieldOnImage = true;
    function setShowYieldOnImage(bool bool_) external onlyOwner {
        showYieldOnImage = bool_; }

    // To use it, you need to make a ton of stuff. So here, we will render the first stat box.
    function __renderStatBox1(uint256 characterId_, iCS.Character memory Character_, iCS.Equipment memory Equipment_) internal view returns (string memory) {
        // Here is the first part of the stat box with the big text.
        string memory _render = string(abi.encodePacked(
            __statBox1Open,
            __getStatBox1MainItem("Transponder ID: ", Strings.toString(Character_.transponderId_), 1),
            __getStatBox1MainItem("Space Capsule ID: ", Strings.toString(Character_.spaceCapsuleId_), 2),
            __getStatBox1MainItem("Total Equipment Bonus: ", Strings.toString(Character_.totalEquipmentBonus_), 3)
        ));

        if (showYieldOnImage) {
            _render = string(abi.encodePacked(
                _render,
                __getStatBox1YieldItem("Yield: ", __getFormattedYieldRate(CC.getCharacterYieldRate(characterId_)), 4)
            ));
        }

        // Then, we have the small part which is the details of the space capsule.
        _render = string(abi.encodePacked(
            _render,
            __statBox1SubOpen,
            __getStatBox1SubItem( string(abi.encodePacked("Weapon : [", Strings.toString(__getItemLevel(Character_.spaceCapsuleId_, "WEAPONS", Equipment_.weaponUpgrades_)), "] ")), SC.getWeapon(Character_.spaceCapsuleId_), Strings.toString(__getItemLevel(Character_.spaceCapsuleId_, "WEAPONS", Equipment_.weaponUpgrades_)), 1),
            __getStatBox1SubItem( string(abi.encodePacked("Chest : [", Strings.toString(__getItemLevel(Character_.spaceCapsuleId_, "CHEST", Equipment_.chestUpgrades_)), "] ")), SC.getChest(Character_.spaceCapsuleId_), Strings.toString(__getItemLevel(Character_.spaceCapsuleId_, "CHEST", Equipment_.chestUpgrades_)), 2),
            __getStatBox1SubItem( string(abi.encodePacked("Head : [", Strings.toString(__getItemLevel(Character_.spaceCapsuleId_, "HEAD", Equipment_.headUpgrades_)), "] ")), SC.getHead(Character_.spaceCapsuleId_), Strings.toString(__getItemLevel(Character_.spaceCapsuleId_, "HEAD", Equipment_.headUpgrades_)), 3),
            __getStatBox1SubItem( string(abi.encodePacked("Legs : [", Strings.toString(__getItemLevel(Character_.spaceCapsuleId_, "LEGS", Equipment_.legsUpgrades_)), "] ")), SC.getLegs(Character_.spaceCapsuleId_), Strings.toString(__getItemLevel(Character_.spaceCapsuleId_, "LEGS", Equipment_.legsUpgrades_)), 4)
        ));
        _render = string(abi.encodePacked(
            _render,
            __getStatBox1SubItem( string(abi.encodePacked("Vehicle : [", Strings.toString(__getItemLevel(Character_.spaceCapsuleId_, "VEHICLE", Equipment_.vehicleUpgrades_)), "] ")), SC.getVehicle(Character_.spaceCapsuleId_), Strings.toString(__getItemLevel(Character_.spaceCapsuleId_, "VEHICLE", Equipment_.vehicleUpgrades_)), 5),
            __getStatBox1SubItem( string(abi.encodePacked("Arms : [", Strings.toString(__getItemLevel(Character_.spaceCapsuleId_, "ARMS", Equipment_.armsUpgrades_)), "] ")), SC.getArms(Character_.spaceCapsuleId_), Strings.toString(__getItemLevel(Character_.spaceCapsuleId_, "ARMS", Equipment_.armsUpgrades_)), 6),
            __getStatBox1SubItem( string(abi.encodePacked("Artifact : [", Strings.toString(__getItemLevel(Character_.spaceCapsuleId_, "ARTIFACTS", Equipment_.artifactUpgrades_)), "] ")), SC.getArtifact(Character_.spaceCapsuleId_), Strings.toString(__getItemLevel(Character_.spaceCapsuleId_, "ARTIFACTS", Equipment_.artifactUpgrades_)), 7),
            __getStatBox1SubItem( string(abi.encodePacked("Ring : [", Strings.toString(__getItemLevel(Character_.spaceCapsuleId_, "RINGS", Equipment_.ringUpgrades_)), "] ")), SC.getRing(Character_.spaceCapsuleId_), Strings.toString(__getItemLevel(Character_.spaceCapsuleId_, "RINGS", Equipment_.ringUpgrades_)), 8),
            __statBox1Close,
            __statBox1SubClose
        ));
        return _render;
    }

    // Then, we have the second box which contains all the other information.
    string internal constant __statBox2Open = "<g transform='translate(620 1000)' fill='white'> <rect width='540' height='152' fill='black' stroke='white' stroke-width='4'/> <rect width='270' height='208' x='270' y='152' fill='black' stroke='white' stroke-width='4'/> <rect width='270' height='208' y='152' fill='black' stroke='white' stroke-width='4'/>";
    string internal constant __statBox2Close = "</g>";
    function __getStatBox2Item(string memory itemName_, string memory value_, uint256 pos_) internal pure returns (string memory) {
        uint256 _y = (pos_ * 32) + 4;
        return string(abi.encodePacked( "<text x='16' y='", Strings.toString(_y), "' class='stats'>", itemName_, value_, "</text>" ));
    }
    function __getStatBox2HPItem(string memory itemName_, string memory value_, uint256 pos_) internal pure returns (string memory) {
        uint256 _y = (pos_ * 32) + 4;
        return string(abi.encodePacked( "<text x='16' y='", Strings.toString(_y), "' class='hp'>", itemName_, value_, "</text>" ));
    }
    function __getStatBox2MPItem(string memory itemName_, string memory value_, uint256 pos_) internal pure returns (string memory) {
        uint256 _y = (pos_ * 32) + 4;
        return string(abi.encodePacked( "<text x='16' y='", Strings.toString(_y), "' class='mp'>", itemName_, value_, "</text>" ));
    }
    function __getTranslatedAttributes(iCS.Character memory Character_, iCS.Stats memory Stats_, uint8 attribute_) internal pure returns (string memory) {
        // [ 1=HP, 2=Mana, 3=Attack, 4=Speed, 5=Regeneration ]
        if      (attribute_ == 1) { return Strings.toString((Character_.augments_ * 10) + (Stats_.constitution_ * 10) + 100); }
        else if (attribute_ == 2) { return Strings.toString((Character_.augments_ * 10) + (Stats_.intelligence_ * 10) + 100); }
        else if (attribute_ == 3) { return Strings.toString((Character_.augments_) + ((Stats_.strength_ * 3) + Stats_.intelligence_)); }
        else if (attribute_ == 4) { return Strings.toString((Character_.augments_) + (Stats_.agility_ * 3)); }
        else if (attribute_ == 5) { return Strings.toString((Character_.augments_) + ((Stats_.spirit_ * 2) + (Stats_.constitution_ / 2)) ); }
        else                      { revert("Invalid Attribute!"); }
    }
    // Now we render it
    function __renderStatBox2(iCS.Character memory Character_, iCS.Stats memory Stats_) internal view returns (string memory) {
        // First, we render the box and the top box infos
        string memory _render = string(abi.encodePacked(
            __statBox2Open,
            __getStatBox2Item("",  CI.raceToRaceName(Character_.race_), 1),
            __getStatBox2Item("Character Rank: ", Strings.toString(__getCharacterRank(Character_.augments_)), 2),
            __getStatBox2Item("Augments: ", Strings.toString(Character_.augments_), 3),
            __getStatBox2Item("Base Points: ", Strings.toString(Character_.basePoints_), 4)
        ));
        // Now, we render the info of the bottom left box
        _render = string(abi.encodePacked(
            _render,
            "<g transform='translate(0 152)'>",
            __getStatBox2Item("Strength: ", Strings.toString(Stats_.strength_), 1),
            __getStatBox2Item("Agility: ", Strings.toString(Stats_.agility_), 2),
            __getStatBox2Item("Constitution: ", Strings.toString(Stats_.constitution_), 3),
            __getStatBox2Item("Intelligence: ", Strings.toString(Stats_.intelligence_), 4),
            __getStatBox2Item("Spirit: ", Strings.toString(Stats_.spirit_), 5),
            "</g>"
        ));
        // Then, we render the info on the bottom right box
        _render = string(abi.encodePacked(
            _render,
            "<g transform='translate(270 152)'>",
            __getStatBox2HPItem("HP: ", __getTranslatedAttributes(Character_, Stats_, 1), 1),
            __getStatBox2MPItem("MP: ", __getTranslatedAttributes(Character_, Stats_, 2), 2),
            __getStatBox2Item("ATK: ", __getTranslatedAttributes(Character_, Stats_, 3), 3),
            __getStatBox2Item("SPD: ", __getTranslatedAttributes(Character_, Stats_, 4), 4),
            __getStatBox2Item("RGN: ", __getTranslatedAttributes(Character_, Stats_, 5), 5),
            "</g>",
            __statBox2Close
        ));
        // Lastly, return the rendered string
        return _render;
    }

    // Then... Very cool. We render a special character ID based on the upload of the character!
    function __getCitizenIDItem(bytes1 digit_, uint256 pos_) public pure returns (string memory) {
        uint256 _y = pos_ * 20;
        return string(abi.encodePacked( "<text text-anchor='middle' y='", Strings.toString(_y), "' class='sC0'>", digit_, "</text>" ));
    }
    function __renderCharacterCitizenID(uint256 characterId_, iCS.Character memory Character_) internal pure returns (string memory) {
        uint256 _citizenID = uint256(keccak256(abi.encodePacked(characterId_, Character_.transponderId_, Character_.spaceCapsuleId_)));
        string memory _citizenIDString = Strings.toString(_citizenID);
        bytes memory _citizenIDBytes = bytes(_citizenIDString);
        string memory _render = "<g transform='translate(600 1016)' fill='white'>";
        for (uint256 i = 0; i < _citizenIDBytes.length; i++) {
            if (i == 16) { return string(abi.encodePacked(_render, "</g>")); }
            _render = string(abi.encodePacked(_render, __getCitizenIDItem( _citizenIDBytes[i], (i+1) )));
        }
        return string(abi.encodePacked(_render, "</g>"));
    }

    bool public showCitizenId;
    function setShowCitizenId(bool bool_) external onlyOwner {
        showCitizenId = bool_; }

    function drawCharacter(uint256 tokenId_) public view returns (string memory) {
        iCS.Character memory _Character = CS.characters(tokenId_);
        iCS.Equipment memory _Equipment = CS.equipments(tokenId_);
        iCS.Stats memory _Stats = CS.stats(tokenId_);

        string memory _render = string(abi.encodePacked(
            __renderInit(__getFont()),
            __renderRect(),
            __renderName(tokenId_, _Character),
            __renderCharacterImage(_Character),
            __renderBioBox(tokenId_),
            __renderStatBox1(tokenId_, _Character, _Equipment),
            __renderStatBox2(_Character, _Stats)
        ));

        // toggle whether or not to show citizen ID
        if (showCitizenId) {
            _render = string(abi.encodePacked(
                _render,
                __renderCharacterCitizenID(tokenId_, _Character)
            ));
        }

        // then, close the SVG
        _render = string(abi.encodePacked(
            _render,
            "</svg>" 
        ));

        return Base64.encode( bytes(_render) );
    }
}