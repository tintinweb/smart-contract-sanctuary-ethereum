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

// Strings Library
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

interface iCC {
    function getCharacterYieldRate(uint256 characterId_) external view returns (uint256);
    function getItemRarity(uint16 spaceCapsuleId_, string memory keyPrefix_) external view returns (uint8);
    function queryBaseEquipmentTier(uint8 rarity_) external view returns (uint8);
}

interface iCI {
    function raceToRaceName(uint8 race_) external view returns (string memory);
}

interface iRender {
    function drawCharacter(uint256 tokenId_) external view returns (string memory);
}

contract MTMCharactersMetadata is Ownable {
    // Interfaces
    iCS CS; iSC SC; iCC CC; iCI CI; iRender Render; iRender Render2;
    constructor() {}
    function setContracts(address cs_, address sc_, address cc_, address ci_, address render_, address render2_) external onlyOwner {
        CS = iCS(cs_); SC = iSC(sc_); CC = iCC(cc_); CI = iCI(ci_); Render = iRender(render_); Render2 = iRender(render2_);
    }

    function __header() internal pure returns (string memory) {
    //    return "data:application/json;utf8,"; // json
        return "data:application/json;base64,"; // base64
    }
    function __tokenName(uint256 tokenId_) internal view returns (string memory) {
        if (bytes(CS.names(tokenId_)).length > 0) { return CS.names(tokenId_); } 
        else { return "Character"; }
    }
    function __imageHeader() internal pure returns (string memory) {
        // return "data:image/svg+xml;utf8,";
        return "data:image/svg+xml;base64,";
    }

    string internal externalUrlString = "https://messagetomartians.com";
    function setExternalUrl(string memory url_) external onlyOwner {
        externalUrlString = url_; }

    function __externalUrl() internal view returns (string memory) {
        return externalUrlString;
    }
    // NOTE: MODIFY THIS!!
    string internal descriptionString = "Message To Martians Characters are the core aspect of the Message to Martians Ecosystem. To be continued.";
    function setDescription(string memory description_) external onlyOwner {
        descriptionString = description_; }

    function __description() internal view returns (string memory) {
        return descriptionString;
    }

    function __renderName(uint256 tokenId_, uint16 level_, uint256 yieldRate_, string memory name_) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '"name": "',
            name_,
            ' (Lv: ',
            Strings.toString(level_),
            ', Pwr: ',
            Strings.toString(yieldRate_ / (10 ** 18)),
            ') # ',
            Strings.toString(tokenId_),
            '"'
        ));
    }
    function __renderDescription(string memory bio_) internal view returns (string memory) {
        string memory _description = bytes(bio_).length == 0 ? __description() : bio_;
        return string(abi.encodePacked(
            '"description": "',
            _description,
            '"'
        ));
    }
    function __renderExternalUrl() internal view returns (string memory) {
        return string(abi.encodePacked(
            '"external_url": "',
            __externalUrl(),
            '"'
        ));
    }
    function __renderImage(uint256 tokenId_) internal view returns (string memory) {
        return string(abi.encodePacked(
            '"image": "',
            __imageHeader(),
            Render.drawCharacter(tokenId_),
            '"'
        ));
    }
    function __renderTrait(string memory traitName_, string memory traitValue_, bool lastTrait_) internal pure returns (string memory) {
        string memory _trait = string(abi.encodePacked('{"trait_type": "', traitName_, '", "value": "', traitValue_, '"}'));
        if (!lastTrait_) { return string(abi.encodePacked(_trait, ',')); }
        return _trait;
    }
    function __renderNumberTrait(string memory traitName_, string memory traitValue_, bool lastTrait_) internal pure returns (string memory) {
        string memory _trait = string(abi.encodePacked('{"trait_type": "', traitName_, '", "value": ', traitValue_, '}'));
        if (!lastTrait_) { return string(abi.encodePacked(_trait, ',')); }
        return _trait;    
    }

    // For equipments
    function __getItemLevel(uint16 spaceCapsuleId_, string memory keyPrefix_, uint8 upgrades_) internal view returns (string memory) {
        return Strings.toString( CC.queryBaseEquipmentTier((CC.getItemRarity(spaceCapsuleId_, keyPrefix_)) + upgrades_));
    }

    function __renderStatTrait(string memory traitName_, string memory traitValue_, bool lastTrait_) internal pure returns (string memory) {
        string memory _trait = string(abi.encodePacked('{"trait_type": "', traitName_, '", "display_type": "number", "value": "', traitValue_, '"}'));
        if (!lastTrait_) { return string(abi.encodePacked(_trait, ',')); }
        return _trait;
    }
    function __renderBoostNumberTrait(string memory traitName_, string memory traitValue_, bool lastTrait_) internal pure returns (string memory) {
        string memory _trait = string(abi.encodePacked('{"trait_type": "', traitName_, '", "display_type": "boost_number", "value": "', traitValue_, '"}'));
        if (!lastTrait_) { return string(abi.encodePacked(_trait, ',')); }
        return _trait;
    }

    // For equipment base ranks
    function __getAmountOfQuotes(uint16 spaceCapsuleId_) internal view returns (string memory) {
        uint256 _quotes;
        if ( CC.getItemRarity(spaceCapsuleId_, "WEAPONS") == 19 ) { _quotes++; }
        if ( CC.getItemRarity(spaceCapsuleId_, "CHEST") == 19 ) { _quotes++; }
        if ( CC.getItemRarity(spaceCapsuleId_, "HEAD") == 19 ) { _quotes++; }
        if ( CC.getItemRarity(spaceCapsuleId_, "LEGS") == 19 ) { _quotes++; }
        if ( CC.getItemRarity(spaceCapsuleId_, "VEHICLE") == 19 ) { _quotes++; }
        if ( CC.getItemRarity(spaceCapsuleId_, "ARMS") == 19 ) { _quotes++; }
        if ( CC.getItemRarity(spaceCapsuleId_, "ARTIFACTS") == 19 ) { _quotes++; }
        if ( CC.getItemRarity(spaceCapsuleId_, "RINGS") == 19 ) { _quotes++; }
        return Strings.toString(_quotes);
    }
    function __getAmountOfRares(uint16 spaceCapsuleId_) internal view returns (string memory) {
        uint256 _rares;
        if ( CC.getItemRarity(spaceCapsuleId_, "WEAPONS") == 20 ) { _rares++; }
        if ( CC.getItemRarity(spaceCapsuleId_, "CHEST") == 20 ) { _rares++; }
        if ( CC.getItemRarity(spaceCapsuleId_, "HEAD") == 20 ) { _rares++; }
        if ( CC.getItemRarity(spaceCapsuleId_, "LEGS") == 20 ) { _rares++; }
        if ( CC.getItemRarity(spaceCapsuleId_, "VEHICLE") == 20 ) { _rares++; }
        if ( CC.getItemRarity(spaceCapsuleId_, "ARMS") == 20 ) { _rares++; }
        if ( CC.getItemRarity(spaceCapsuleId_, "ARTIFACTS") == 20 ) { _rares++; }
        if ( CC.getItemRarity(spaceCapsuleId_, "RINGS") == 20 ) { _rares++; }
        return Strings.toString(_rares);
    }

    // Translated Stats Functions
    function __getTranslatedAttributes(iCS.Character memory Character_, iCS.Stats memory Stats_, uint8 attribute_) internal pure returns (string memory) {
        // [ 1=HP, 2=Mana, 3=Attack, 4=Speed, 5=Regeneration ]
        if      (attribute_ == 1) { return Strings.toString((Character_.augments_ * 10) + (Stats_.constitution_ * 10) + 100); }
        else if (attribute_ == 2) { return Strings.toString((Character_.augments_ * 10) + (Stats_.intelligence_ * 10) + 100); }
        else if (attribute_ == 3) { return Strings.toString((Character_.augments_) + ((Stats_.strength_ * 3) + Stats_.intelligence_)); }
        else if (attribute_ == 4) { return Strings.toString((Character_.augments_) + (Stats_.agility_ * 3)); }
        else if (attribute_ == 5) { return Strings.toString((Character_.augments_) + ((Stats_.spirit_ * 2) + (Stats_.constitution_ / 2)) ); }
        else                      { revert("Invalid Attribute!"); }
    }
    function __renderCharacterCitizenID(uint256 characterId_, iCS.Character memory Character_) internal pure returns (string memory) {
        uint256 _citizenID = uint256(keccak256(abi.encodePacked(characterId_, Character_.transponderId_, Character_.spaceCapsuleId_)));
        string memory _citizenIDString = Strings.toString(_citizenID);
        bytes memory _citizenIDBytes = bytes(_citizenIDString);
        string memory _id;
        for (uint256 i = 0; i < _citizenIDBytes.length; i++) {
            if (i == 16) { return _id; }
            _id = string(abi.encodePacked(_id, _citizenIDBytes[i]));
        }
        return _id;
    }
    
    function __renderAttributes(uint256 tokenId_) internal view returns (string memory) {
        iCS.Character memory _Character = CS.characters(tokenId_);
        iCS.Equipment memory _Equipment = CS.equipments(tokenId_);
        iCS.Stats memory _Stats = CS.stats(tokenId_);

        // Character Stats
        string memory _attributes = string(abi.encodePacked(
            '"attributes": [',
            __renderTrait("Name", CS.names(tokenId_), false),
            __renderTrait("Race", CI.raceToRaceName(_Character.race_), false),
            __renderTrait("Transponder", Strings.toString(_Character.transponderId_), false),
            __renderTrait("Space Capsule", Strings.toString(_Character.spaceCapsuleId_), false),
            __renderTrait("Citizen ID", __renderCharacterCitizenID(tokenId_, _Character), false)
        ));

        _attributes = string(abi.encodePacked(
            _attributes,
            __renderStatTrait("Total Equipment Bonus", Strings.toString(_Character.totalEquipmentBonus_), false),
            __renderStatTrait("Augments", Strings.toString(_Character.augments_), false),
            __renderStatTrait("Base Points", Strings.toString(_Character.basePoints_), false),
            __renderStatTrait("Strength", Strings.toString(_Stats.strength_), false),
            __renderStatTrait("Agility", Strings.toString(_Stats.agility_), false),
            __renderStatTrait("Constitution", Strings.toString(_Stats.constitution_), false),
            __renderStatTrait("Intelligence", Strings.toString(_Stats.intelligence_), false),
            __renderStatTrait("Spirit", Strings.toString(_Stats.spirit_), false)
        ));

        // Equipment
        _attributes = string(abi.encodePacked(
            _attributes,
            __renderTrait("Weapon", SC.getWeapon(_Character.spaceCapsuleId_), false),
            __renderTrait("Chest", SC.getChest(_Character.spaceCapsuleId_), false),
            __renderTrait("Head", SC.getHead(_Character.spaceCapsuleId_), false),
            __renderTrait("Legs", SC.getLegs(_Character.spaceCapsuleId_), false),
            __renderTrait("Vehicle", SC.getVehicle(_Character.spaceCapsuleId_), false),
            __renderTrait("Arms", SC.getArms(_Character.spaceCapsuleId_), false),
            __renderTrait("Artifact", SC.getArtifact(_Character.spaceCapsuleId_), false),
            __renderTrait("Ring", SC.getRing(_Character.spaceCapsuleId_), false)
        ));

        // Equipment Level
        _attributes = string(abi.encodePacked(
            _attributes,
            __renderNumberTrait("Weapon Item Level", __getItemLevel(_Character.spaceCapsuleId_, "WEAPONS", _Equipment.weaponUpgrades_), false),
            __renderNumberTrait("Chest Item Level", __getItemLevel(_Character.spaceCapsuleId_, "CHEST", _Equipment.chestUpgrades_), false),
            __renderNumberTrait("Head Item Level", __getItemLevel(_Character.spaceCapsuleId_, "HEAD", _Equipment.headUpgrades_), false),
            __renderNumberTrait("Legs Item Level", __getItemLevel(_Character.spaceCapsuleId_, "LEGS", _Equipment.legsUpgrades_), false),
            __renderNumberTrait("Vehicle Item Level", __getItemLevel(_Character.spaceCapsuleId_, "VEHICLE", _Equipment.vehicleUpgrades_), false),
            __renderNumberTrait("Arms Item Level", __getItemLevel(_Character.spaceCapsuleId_, "ARMS", _Equipment.armsUpgrades_), false),
            __renderNumberTrait("Artifact Item Level", __getItemLevel(_Character.spaceCapsuleId_, "ARTIFACTS", _Equipment.artifactUpgrades_), false),
            __renderNumberTrait("Ring Item Level", __getItemLevel(_Character.spaceCapsuleId_, "RINGS", _Equipment.ringUpgrades_), false)
        ));

        // Equipment Upgrades
        _attributes = string(abi.encodePacked(
            _attributes,
            __renderBoostNumberTrait("Weapon Upgrades", Strings.toString(_Equipment.weaponUpgrades_), false),
            __renderBoostNumberTrait("Chest Upgrades", Strings.toString(_Equipment.chestUpgrades_), false),
            __renderBoostNumberTrait("Head Upgrades", Strings.toString(_Equipment.headUpgrades_), false),
            __renderBoostNumberTrait("Legs Upgrades", Strings.toString(_Equipment.legsUpgrades_), false),
            __renderBoostNumberTrait("Vehicle Upgrades", Strings.toString(_Equipment.vehicleUpgrades_), false),
            __renderBoostNumberTrait("Arms Upgrades", Strings.toString(_Equipment.armsUpgrades_), false),
            __renderBoostNumberTrait("Artifact Upgrades", Strings.toString(_Equipment.artifactUpgrades_), false),
            __renderBoostNumberTrait("Ring Upgrades", Strings.toString(_Equipment.ringUpgrades_), false)
        ));


        // Translated Stats
        _attributes = string(abi.encodePacked(
            _attributes,
            __renderStatTrait("Hit Points", __getTranslatedAttributes(_Character, _Stats, 1), false),
            __renderStatTrait("Mana", __getTranslatedAttributes(_Character, _Stats, 2), false),
            __renderStatTrait("Attack", __getTranslatedAttributes(_Character, _Stats, 3), false),
            __renderStatTrait("Speed", __getTranslatedAttributes(_Character, _Stats, 4), false),
            __renderStatTrait("Regeneration", __getTranslatedAttributes(_Character, _Stats, 5), false)
        ));

        // Additional Character Stats
        _attributes = string(abi.encodePacked(
            _attributes,
            __renderStatTrait("Amount of Uncommon Items (Quotes)", __getAmountOfQuotes(_Character.spaceCapsuleId_), false),
            __renderStatTrait("Amount of Rare Items (+1)", __getAmountOfRares(_Character.spaceCapsuleId_), false),
            __renderStatTrait("Level", Strings.toString(_Stats.strength_), false),
            __renderStatTrait("Power", Strings.toString(_Stats.strength_), false),
            __renderNumberTrait("MES Yield per Day", __getFormattedYieldRate(CC.getCharacterYieldRate(tokenId_)), true),
            "]"
        ));

        return _attributes;
    }
    // Converter Functions
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

    // Some touches on Render Type Supports
    string internal IPFSBaseURI; string internal IPFSBaseURI_EXT;
    string internal APIBaseURI; string internal APIBaseURI_EXT;
    function setURIs(string memory baseURI_, string memory baseEXT_, uint8 type_) external onlyOwner {
        if      (type_ == 3) { IPFSBaseURI = baseURI_; IPFSBaseURI_EXT = baseEXT_; }
        else if (type_ == 4) { APIBaseURI = baseURI_; APIBaseURI_EXT = baseEXT_; }
        else revert("Unsupported type!");
    }
    function __IPFSTokenURI(uint256 tokenId_) internal view returns (string memory) {
        return string(abi.encodePacked( IPFSBaseURI, Strings.toString(tokenId_), IPFSBaseURI_EXT ));
    }
    function __APITokenURI(uint256 tokenId_) internal view returns (string memory) {
        return string(abi.encodePacked( APIBaseURI, Strings.toString(tokenId_), IPFSBaseURI_EXT ));
    }
    // Render Type 2,3,4
    function __renderImage2(uint256 tokenId_) internal view returns (string memory) {
        return string(abi.encodePacked(
            '"image": "', __imageHeader(), Render2.drawCharacter(tokenId_), '"' ));
    }
    function __renderIPFS(uint256 tokenId_) internal view returns (string memory) {
        return string(abi.encodePacked(
            '"image": "', __IPFSTokenURI(tokenId_), '"' ));
    }
    function __renderAPI(uint256 tokenId_) internal view returns (string memory) {
        return string(abi.encodePacked(
            '"image": "', __APITokenURI(tokenId_), '"' ));
    }

    function renderMetadata(uint256 tokenId_) public view returns (string memory) {
        iCS.Character memory _Character = CS.characters(tokenId_);
        string memory _name = __renderName(tokenId_, _Character.basePoints_, CC.getCharacterYieldRate(tokenId_), __tokenName(tokenId_));
        string memory _description = __renderDescription(CS.bios(tokenId_));
        
        // Render Types Support
        string memory _image;
        if      (_Character.renderType_ == 1) { _image = __renderImage(tokenId_); }
        else if (_Character.renderType_ == 2) { _image = __renderImage2(tokenId_); }
        else if (_Character.renderType_ == 3) { _image = __renderIPFS(tokenId_); }
        else if (_Character.renderType_ == 4) { _image = __renderAPI(tokenId_); }
        else    { _image = '"image": ""'; }

        return string(abi.encodePacked
            (__header(),
            Base64.encode(bytes(string(abi.encodePacked(
                '{',
                _name,
                ',',
                _description,
                ',',
                __renderExternalUrl(), 
                ',',
                _image,
                ',',
                __renderAttributes(tokenId_),
                '}'
            ))))
        ));
    }
}