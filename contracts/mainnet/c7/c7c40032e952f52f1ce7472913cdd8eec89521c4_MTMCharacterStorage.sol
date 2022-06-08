/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

//SPDX-License-Identifier: Delayed Release MIT
pragma solidity ^0.8.0;

//////////////////////////////////////////////////////////////////////////////////
//     __  ___         __  _                                                    //
//    /  |/  /__ _____/ /_(_)__ ____  ___                                       //
//   / /|_/ / _ `/ __/ __/ / _ `/ _ \(_-<                                       //
//  /_/  /_/\_,_/_/  \__/_/\_,_/_//_/___/                                       //
//    _______                     __            ______                          //
//   / ___/ /  ___ ________ _____/ /____ ____  / __/ /____  _______ ____ ____   //  
//  / /__/ _ \/ _ `/ __/ _ `/ __/ __/ -_) __/ _\ \/ __/ _ \/ __/ _ `/ _ `/ -_)  //
//  \___/_//_/\_,_/_/  \_,_/\__/\__/\__/_/   /___/\__/\___/_/  \_,_/\_, /\__/   //
//                                                                 /___/        //
//   by: 0xInuarashi.eth                                                        //
//                                                                              //
//////////////////////////////////////////////////////////////////////////////////

// Character Storage
/* 
    Store Character Traits [/]
    Store Character Stats [/]
    Store Character Equipment [/]
*/

contract MTMCharacterStorage {

    // // Access
    // Minified Ownable
    address public owner;
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(msg.sender == owner, "You are not the owner!"); _; }
    function setNewOwner(address address_) external onlyOwner { owner = address_; }

    // Controller 
    mapping(address => bool) public controllers;
    modifier onlyController { require(controllers[msg.sender], "No access!"); _; }
    function setController(address address_, bool bool_) external onlyOwner {
        controllers[address_] = bool_; }

    // Controller 
    address public characterMain;
    modifier onlyCharacterMain { require(msg.sender == characterMain, "No access!"); _; }
    function setCharacterMain(address address_) external onlyOwner { characterMain = address_; }

    // Managers
    modifier onlyManagers { require(msg.sender == owner || controllers[msg.sender], "No access!"); _; }
    
    // character
    struct Character {
        // general info
        uint8 race_;
        uint8 renderType_;

        // equipment
        uint16 transponderId_;
        uint16 spaceCapsuleId_;

        // stats
        uint8 augments_;
        uint16 basePoints_;
        uint16 totalEquipmentBonus_;
    }

    // roleplay stats
    struct Stats {
        uint8 strength_; 
        uint8 agility_; 
        uint8 constitution_; 
        uint8 intelligence_; 
        uint8 spirit_; 
    }

    // equipment upgrades
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

    // // Mappings
    mapping(uint256 => string) public names; // tokenId mapping to Names
    mapping(uint256 => string) public bios; // tokenId mapping to Bios
    mapping(uint256 => Character) public characters; // tokenId mapping to Character
    mapping(uint256 => Stats) public stats; // tokenId mapping to Role Play Stats
    mapping(uint256 => Equipment) public equipments; // tokenId mapping to Equipment

    // // Mappings for Race
    mapping(address => uint8) public _contractToRace;
    function setContractToRace(address[] memory contractAddresses_, uint8[] memory races_) external onlyManagers {
        require(contractAddresses_.length == races_.length, "Length mismatch");
        for (uint256 i = 0; i < contractAddresses_.length; i++) {
            _contractToRace[contractAddresses_[i]] = races_[i];
        }
    }
    
    // Contract To Race function. We proxy this so that people cannot query unsupported races
    function contractToRace(address address_) public view returns (uint8) {
        require(_contractToRace[address_] != 0, "Invalid Race!");
        return _contractToRace[address_];
    }

    // // Main Creator
    function createCharacter(uint256 tokenId_, Character memory Character_) public onlyCharacterMain {
        characters[tokenId_] = Character_;
    }

    // // Characters
    function setName(uint256 tokenId_, string memory name_) external onlyController {
        names[tokenId_] = name_;
    }
    function setBio(uint256 tokenId_, string memory bio_) external onlyController {
        bios[tokenId_] = bio_;
    }
    function setRace(uint256 tokenId_, uint8 race_) external onlyController {
        characters[tokenId_].race_ = race_;
    }
    function setRenderType(uint256 tokenId_, uint8 renderType_) external onlyController {
        characters[tokenId_].renderType_ = renderType_;
    }
    function setTransponderId(uint256 tokenId_, uint16 transponderId_) external onlyManagers {
        characters[tokenId_].transponderId_ = transponderId_;
    }
    function setSpaceCapsuleId(uint256 tokenId_, uint16 spaceCapsuleId_) external onlyManagers {
        characters[tokenId_].spaceCapsuleId_ = spaceCapsuleId_;
    }
    function setAugments(uint256 tokenId_, uint8 augments_) external onlyController {
        characters[tokenId_].augments_ = augments_;
    }
    function setBasePoints(uint256 tokenId_, uint16 basePoints_) external onlyController {
        characters[tokenId_].basePoints_ = basePoints_;
    }
    function setTotalEquipmentBonus(uint256 tokenId_, uint16 totalEquipmentBonus_) external onlyController {
        characters[tokenId_].totalEquipmentBonus_ = totalEquipmentBonus_;
    }
    function multiSetRenderTypes(uint256[] memory tokenIds_, uint8 renderType_) external onlyManagers {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            characters[tokenIds_[i]].renderType_ = renderType_;
        }
    }

    // // Stats
    function setStrength(uint256 tokenId_, uint8 strength_) external onlyController {
        stats[tokenId_].strength_ = strength_;
    }
    function setAgility(uint256 tokenId_, uint8 agility_) external onlyController {
        stats[tokenId_].agility_ = agility_;
    }
    function setConstitution(uint256 tokenId_, uint8 constitution_) external onlyController {
        stats[tokenId_].constitution_ = constitution_;
    }
    function setIntelligence(uint256 tokenId_, uint8 intelligence_) external onlyController {
        stats[tokenId_].intelligence_ = intelligence_;
    }
    function setSpirit(uint256 tokenId_, uint8 spirit_) external onlyController {
        stats[tokenId_].spirit_ = spirit_;
    }

    // // Equipment
    function setWeaponUpgrades(uint256 tokenId_, uint8 upgrade_) external onlyController {
        equipments[tokenId_].weaponUpgrades_ = upgrade_;
    }
    function setChestUpgrades(uint256 tokenId_, uint8 upgrade_) external onlyController {
        equipments[tokenId_].chestUpgrades_ = upgrade_;
    }
    function setHeadUpgrades(uint256 tokenId_, uint8 upgrade_) external onlyController {
        equipments[tokenId_].headUpgrades_ = upgrade_;
    }
    function setLegsUpgrades(uint256 tokenId_, uint8 upgrade_) external onlyController {
        equipments[tokenId_].legsUpgrades_ = upgrade_;
    }
    function setVehicleUpgrades(uint256 tokenId_, uint8 upgrade_) external onlyController {
        equipments[tokenId_].vehicleUpgrades_ = upgrade_;
    }
    function setArmsUpgrades(uint256 tokenId_, uint8 upgrade_) external onlyController {
        equipments[tokenId_].armsUpgrades_ = upgrade_;
    }
    function setArtifactUpgrades(uint256 tokenId_, uint8 upgrade_) external onlyController {
        equipments[tokenId_].artifactUpgrades_ = upgrade_;
    }
    function setRingUpgrades(uint256 tokenId_, uint8 upgrade_) external onlyController {
        equipments[tokenId_].ringUpgrades_ = upgrade_;
    }
}