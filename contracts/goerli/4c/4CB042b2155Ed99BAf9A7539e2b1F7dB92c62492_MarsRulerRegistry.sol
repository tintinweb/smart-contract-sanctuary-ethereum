/**
 *Submitted for verification at Etherscan.io on 2022-12-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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

interface iCharacters {
    function ownerOf(uint256 tokenId_) external view returns (address);
}

interface iMES {
    function transferFrom(address from_, address to_, uint256 amount_) 
    external returns (bool);
}

interface iMarsRulerRegistry {

    struct GearConfig {
        bool hasConfig;
        uint8 weaponType;
        uint8 chestType;
        uint8 headType;
        uint8 legsType;
        uint8 vehicleType;
        uint8 armsType;
        uint8 artifactType;
        uint8 ringType;
    }

    function characterToGearconfig(uint256 tokenId_) external view
    returns (GearConfig memory);
}

contract MarsRulerRegistry is Ownable {
    
    event GearChange(uint256 indexed tokenId_, GearConfig config_);
    event GearReset(uint256 indexed tokenId_);

    iCharacters public Characters = 
        iCharacters(0x53beA59B69bF9e58E0AFeEB4f34f49Fc29D10F55);
    iCS public CS = iCS(0xC7C40032E952F52F1ce7472913CDd8EeC89521c4);
    iMES public MES = iMES(0x3C2Eb40D25a4b2B5A068a959a40d57D63Dc98B95);

    function setContracts(address characters_, address cs_, address mes_) 
    external onlyOwner {
        Characters = iCharacters(characters_); CS = iCS(cs_); MES = iMES(mes_);
    }

    struct GearConfig {
        bool hasConfig;
        uint8 weaponType;
        uint8 chestType;
        uint8 headType;
        uint8 legsType;
        uint8 vehicleType;
        uint8 armsType;
        uint8 artifactType;
        uint8 ringType;
    }

    mapping(uint256 => GearConfig) public characterToGearConfig;

    uint256 public gearChangeCost = 1000 ether;

    function setGearConfigOfRuler(uint256 tokenId_, GearConfig calldata config_) 
    external {
        // // First, you have to be the owner of the token
        // require(msg.sender == Characters.ownerOf(tokenId_), 
        //         "You are not the owner!");
        
        // // Then, require that the augment must be 10
        // require(10 == CS.characters(tokenId_).augments_,
        //         "Your Martian is not a Ruler yet!");
        
        // // Consume $MES
        // bool _success = MES.transferFrom(msg.sender, address(this), gearChangeCost);
        // require(_success, "$MES deduction failed!");

        // Set Gear Config
        characterToGearConfig[tokenId_] = config_;

        // Emit Gear Change Event
        emit GearChange(tokenId_, config_);
    }

    function resetGearConfigOfRuler(uint256 tokenId_) external {
        // First, you have to be the owner of the token
        // require(msg.sender == Characters.ownerOf(tokenId_), 
        //         "You are not the owner!");
        
        // // If the character has a Gear Config, it is safe to assume
        // // that it is fully augmented and skip that check.
        // require(characterToGearConfig[tokenId_].hasConfig,
        //         "Character does not have config!");
        
        delete characterToGearConfig[tokenId_];

        emit GearReset(tokenId_);
    }
}