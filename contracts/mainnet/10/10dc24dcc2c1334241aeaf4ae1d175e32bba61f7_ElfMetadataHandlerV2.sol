// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "./DataStructures.sol";

contract ElfMetadataHandlerV2 {
    using DataStructures for DataStructures.Token;

    address impl_;
    address public manager;
    bool private initialized;

    enum Part {
        race,
        hair,
        primaryWeapon,
        accessories
    }

    mapping(uint8 => address) public race;
    mapping(uint8 => address) public hair;
    mapping(uint8 => address) public primaryWeapon;
    mapping(uint8 => address) public accessories;

    struct Attributes {
        uint8 hair; //MAX 3
        uint8 race; //MAX 6 Body
        uint8 accessories; //MAX 7
        uint8 sentinelClass; //MAX 3
        uint8 weaponTier; //MAX 6
        uint8 inventory; //MAX 7
    }

    string public constant header =
        '<svg id="elf" width="100%" height="100%" version="1.1" viewBox="0 0 160 160" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">';
    string public constant footer =
        "<style>#elf{shape-rendering: crispedges; image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;}</style></svg>";

   
    //initialize function
    function initialize() public {
        require(!initialized, "Already initialized");
        manager = msg.sender;
        initialized = true;
    }

    function getName(uint8 accessories_, uint16 id_)  public pure returns (string memory)  {
        
        string memory name = string(abi.encodePacked("Elf #",toString(id_))); 
        //one for ones
        if(accessories_ == 6 || accessories_ == 12 || accessories_ == 13 || accessories_ == 14 || accessories_ == 19 || accessories_ == 20 || accessories_ == 21){
          name = string(abi.encodePacked("Elf #",toString(id_),", ", getAccessoriesName(accessories_)));
        }

        return name;

    }
   
    function getSVG(
        uint8 race_,
        uint8 hair_,
        uint8 primaryWeapon_,
        uint8 accessories_,
        uint8 sentinelClass_
    ) public view returns (string memory) {
      
        uint8 accessoriesIndex = (accessories_ - 1) % 7; 
        bool specialBool = false;
        bool morphBool = false;

        
        if(sentinelClass_ == 0 && (accessoriesIndex == 1 || accessoriesIndex == 2)) {
            morphBool = true;
        }
        
        if((sentinelClass_ != 0 && accessoriesIndex >= 4) || (sentinelClass_ == 0 && accessoriesIndex >= 5)) {
            specialBool = true;
        }

        string memory druidMorph =  string(
                abi.encodePacked(
                    header,
                    get(Part.accessories, accessories_),
                    get(Part.race, race_),                    
                    get(Part.hair, hair_),
                    primaryWeapon_ == 69 ? "" : get(Part.primaryWeapon, primaryWeapon_),                                        
                    footer
                )
            );


        string memory sentinel =  string(
                abi.encodePacked(
                    header,
                    get(Part.race, race_),
                    accessoriesIndex <= 1 ? get(Part.accessories, accessories_) : "",//layer 2 armband necklace RANGE AND ASSASSIN
                    get(Part.hair, hair_),
                    accessoriesIndex <= 3 ? get(Part.accessories, accessories_) : "",//layer 4 is for body armor
                    primaryWeapon_ == 69 ? "" : get(Part.primaryWeapon, primaryWeapon_),     
                    accessoriesIndex == 4 ? get(Part.accessories, accessories_) : "",//layer 6 is for Druid claws.
                    footer
                )
            );

        string memory uniques =  string(
                abi.encodePacked(
                    header,
                    get(Part.accessories, accessories_), 
                    footer
                )
            );    

        return morphBool ? druidMorph : specialBool ? uniques : sentinel;
          
    }

    function getTokenURI(uint16 id_, uint256 sentinel)
        external
        view
        returns (string memory)
    {
        DataStructures.Token memory token = DataStructures.getToken(sentinel);
        
        string memory svg = Base64.encode(
            bytes(
                getSVG(
                    token.race,
                    token.hair,
                    token.primaryWeapon,
                    token.accessories,
                    token.sentinelClass
                )
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                //toString(id_),
                                getName(token.accessories, id_),
                                '", "description":"EthernalElves is a collection of 6666 Sentinel Elves racing to awaken the Elders. These Elves are 100% on-chain. Play EthernalElves to upgrade your abilities and grow your army. !onward", "image": "',
                                "data:image/svg+xml;base64,",
                                svg,
                                '",',
                                getAttributes(
                                    token.race,
                                    token.hair,
                                    token.primaryWeapon,
                                    token.accessories,
                                    token.level,
                                    token.healthPoints,
                                    token.attackPoints,
                                    token.sentinelClass,
                                    token.weaponTier
                                ),
                                "}"
                            )
                        )
                    )
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                    INVENTORY MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    function setRace(uint8[] calldata ids, address source) external {
        require(msg.sender == manager, "Not authorized");

        for (uint256 index = 0; index < ids.length; index++) {
            race[ids[index]] = source;
        }
    }

    function setHair(uint8[] calldata ids, address source) external {
        require(msg.sender == manager, "Not authorized");

        for (uint256 index = 0; index < ids.length; index++) {
            hair[ids[index]] = source;
        }
    }

    function setWeapons(uint8[] calldata ids, address source) external {
        require(msg.sender == manager, "Not authorized");

        for (uint256 index = 0; index < ids.length; index++) {
            primaryWeapon[ids[index]] = source;
        }
    }

    function setAccessories(uint8[] calldata ids, address source) external {
        require(msg.sender == manager, "Not authorized");

        for (uint256 index = 0; index < ids.length; index++) {
            accessories[ids[index]] = source;
        }
    }

    /*///////////////////////////////////////////////////////////////
                    INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function call(address source, bytes memory sig)
        internal
        view
        returns (string memory svg)
    {
        (bool succ, bytes memory ret) = source.staticcall(sig);
        require(succ, "failed to get data");
        
        svg = abi.decode(ret, (string));
        //  console.log("part?");
       //  console.log(svg);
    }

    function get(Part part, uint8 id)
        internal
        view
        returns (string memory data_)
    {   
       
        
        address source = part == Part.race ? race[id]
        : part == Part.hair ? hair[id]
        : part == Part.primaryWeapon ? primaryWeapon[id] : accessories[id];
        
        data_ = wrapTag(call(source, getData(part, id)));
         
        return data_;
    }

    function wrapTag(string memory uri) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<image x="1" y="1" width="160" height="160" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                    uri,
                    '"/>'
                )
            );
    }

    function getData(Part part, uint8 id)
        internal
        pure
        returns (bytes memory data)
    {
        string memory s = string(
            abi.encodePacked(
                part == Part.race ? "race" 
                    : part == Part.hair ? "hair"
                    : part == Part.primaryWeapon ? "weapon"
                    : "accessories",
                toString(id),
                "()"
            )
        );

        return abi.encodeWithSignature(s, "");
    }

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

    function getAttributes(
        uint8 race_,
        uint8 hair_,
        uint8 primaryWeapon_,
        uint8 accessories_,
        uint8 level_,
        uint8 healthPoints_,
        uint8 attackPoints_,
        uint8 sentinelClass_,
        uint8 weaponTier_
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '"attributes": [',
                    getClassAttributes(sentinelClass_),
                    ",",
                    getRaceAttributes(race_),
                    ",",
                    getHairAttributes(hair_),
                    ",",
                    getPrimaryWeaponAttributes(primaryWeapon_, weaponTier_),
                    ",",
                    getAccessoriesAttributes(accessories_),
                    ',{"trait_type": "Level", "value":',
                    toString(level_),
                    '},{"display_type": "boost_number","trait_type": "Attack Points", "value":',
                    toString(attackPoints_),
                    '},{"display_type": "boost_number","trait_type": "Health Points", "value":',
                    toString(healthPoints_),
                    "}]"
                )
            );
    }

    function getClassAttributes(uint8 sentinelClass_)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '{"trait_type":"Class","value":"',
                    getClassName(sentinelClass_),
                    '"}'
                )
            );
    }

    function getRaceAttributes(uint8 race_)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '{"trait_type":"Race","value":"',
                    getRaceName(race_),
                    '"}'
                )
            );
    }

    function getHairAttributes(uint8 hair_)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '{"trait_type":"Head","value":"',
                    getHairName(hair_),
                    '"}'
                )
            );
    }

    function getPrimaryWeaponAttributes(uint8 primaryWeapon_, uint8 weaponTier_)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '{"trait_type":"Weapon","value":"',
                    getPrimaryWeapon(primaryWeapon_),
                    '"},{"display_type":"number","trait_type":"Weapon Tier","value":',
                    toString(weaponTier_),
                    "}"
                )
            );
    }

    function getAccessoriesAttributes(uint8 accessory_)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '{"trait_type":"Accessory","value":"',
                    getAccessoriesName(accessory_),
                    '"}'
                )
            );
    }

    function getTier(uint16 id) internal pure returns (uint16) {
        if (id > 40) return 100;
        if (id == 0) return 0;
        return ((id - 1) / 4);
    }

   /*
   JANKY
    function getWeaponTier(uint16 id) internal pure returns (uint16) {
        
        if (id == 0) return 0;
        
        if (id <= 15){
            id = id/15 + 1;
        }
        if (id >= 15 && id <= 30){
            id = (id-15)/15 + 1;
        }
        if (id >= 30 && id <= 45){
            id = (id-30)/15 + 1;
        }
        
        
        return (id);
    }
    */

   
    function getClassName(uint8 id)
        public
        pure
        returns (string memory className)
    {
        className = id == 0 ? "Druid" : id == 1 ? "Assassin" : "Ranger";
    }

    function getRaceName(uint8 id)
        public
        pure
        returns (string memory raceName)
    {   
        //Dont you just fucking love modulus? 
        id = id % 4 + 1;
        raceName = id == 2 ? "Darkborne" : id == 3 ? "Lightborne" : id == 4 ? "Primeborne" : "Woodborne";
       
    }

    function getHairName(uint8 id)
        public
        pure
        returns (string memory hairName)
    {
        ///create a binary search for the hair name from ids 1 to 9
        hairName = id == 1 ? "Antlers" 
        : id == 2 ? "Hood & Mask" 
        : id == 3 ? "Hood" 
        : id == 4 ? "Brown" 
        : id == 5 ? "Dark" 
        : id == 6 ? "Light" 
        : id == 7 ? "Blue" : id == 8 ? "Blonde" : "Purple";

    }

    function getPrimaryWeapon(uint8 id) public pure returns (string memory) {
        if(id == 69){
            return "Fists";
        }
        if (id < 20) {
            if (id < 10) {
                if (id < 5) {
                    if (id < 3) {
                        return id == 1 ? "Wand of the North" : "Wandherline";
                    }
                    return id == 3 ? "Flayer's Bane" : "Scepter of the Moon";
                }
                if (id < 7) return id == 5 ? "Meadow's Wand" : "Cranium Staff";
                return
                    id == 7 ? "Apiaries Indigo" : 
                    id == 8 ? "Rumi's Staff" : "Forsaken Souls";
            }
            if (id <= 15) {
                if (id < 13) {
                    return
                        id == 10 ? "Ether Malevolence " : id == 11
                            ? "Souls of Ethernals"
                            : "Scepter of Miranda";
                }
                return
                    id == 13 ? "Scythe of Drakon" : id == 14
                        ? "Luna's Staff of Divinity"
                        : "Forbidden Scepter of Lucifer";
            }
            if (id < 18)
                return id == 16 ? "Daggafeets" : "Deceitful Dagger";
            return id == 18 ? "Cutlass of the Night" : "Axe of Haladan";
        }

        if (id < 30) {
            if (id < 25) {
                if (id < 23) {
                    return
                        id == 20 ? "Meadow's Lancer" : id == 21
                            ? "Excalibur Glaives"
                            : "Reaper of the Ancients";
                }
                return id == 23 ? "Emerald's Ravage" : "Primeborne's Resurgence";
            }

            if (id < 27)
                return id == 25 ? "Corruptors Scythe" : "Soul Prowler";
            return
                id == 27 ? "Blades of Illhaladan" : id == 28
                    ? "Twin Blades of Behemoth"
                    : "Lucifers Glaives";
        }
        if (id <= 35) {
            if (id < 33) {
                return
                    id == 30 ? "Halberd of Miranda" : id == 31
                        ? "Rope Dagger"
                        : "Boomerang of Lilith";
            }
            return
                id == 33 ? "Meadows Bow" : id == 34
                    ? "Soul-Taker"
                    : "Ethernal Boomerang";
        }

        if (id <= 40) {
            if (id < 39) {
                return
                    id == 36 ? "Bow of Janus" : id == 37
                        ? "Death by Anchors"
                        : "Glaives of Succubus";
            }
            return id == 39 ? "Meteors of the Dark Moon" : "Searing Daggerjack";
        }
        if (id <= 45) {
            if (id < 44) {
                return
                    id == 41 ? "Glimmering Moon Glaives" : id == 42
                        ? "Arrows of Miranda"
                        : "Cursed Venom";
            }
            return id == 44 ? "Monson of Ethernals" : "Nimbus Astrape";
        }
    }

    function getAccessoriesName(uint8 id) public pure returns (string memory) {
        if (id < 20) {
            if (id < 10) {
                if (id < 5) {
                    if (id < 3) {
                        return id == 1 ? "Druid 1" : "Bear";
                    }
                    return id == 3 ? "Liger" : "None";
                }
                if (id < 7)
                    return
                        id == 5 ? "Claws" : "Drus Ruler of The Oaks";
                return
                    id == 7 ? "Druid 7" : id == 8
                        ? "Necklace"
                        : "Necklace & Armband";
            }
            if (id <= 15) {
                if (id < 13) {
                    return
                        id == 10 ? "Crown of Dahagon " : id == 11
                            ? "Mechadon's Vizard"
                            : "Euriel The Protector";
                }
                return
                    id == 13 ? "Kidor The Slayer of Demons" : id == 14 ? "Lord Mecha Aker" : "Wristband";
                      }
            if (id < 18)
                return id == 16 ? "Wristband & Necklace" : "Azrael's Crest";
            return id == 18 ? "El Machina" : "Eriel Angel of Nature";
        }
            if (id < 22) {
                    return
                        id == 20 ? "Khonsuna Demon Destroyer" : "Lord Machina Ethena";
                }        
       
        
    }
}

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
/// @notice NOT BUILT BY ETHERNAL ELVES TEAM.
library Base64 {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
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

            // padding with '='
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

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;
//import "hardhat/console.sol"; ///REMOVE BEFORE DEPLOYMENT
//v 1.0.3

library DataStructures {

/////////////DATA STRUCTURES///////////////////////////////
    struct Elf {
            address owner;  
            uint256 timestamp; 
            uint256 action; 
            uint256 healthPoints;
            uint256 attackPoints; 
            uint256 primaryWeapon; 
            uint256 level;
            uint256 hair;
            uint256 race; 
            uint256 accessories; 
            uint256 sentinelClass; 
            uint256 weaponTier; 
            uint256 inventory; 
    }

    struct Token {
            address owner;  
            uint256 timestamp; 
            uint8 action; 
            uint8 healthPoints;
            uint8 attackPoints; 
            uint8 primaryWeapon; 
            uint8 level;
            uint8 hair;
            uint8 race; 
            uint8 accessories; 
            uint8 sentinelClass; 
            uint8 weaponTier; 
            uint8 inventory; 
    }

    struct ActionVariables {

            uint256 reward;
            uint256 timeDiff;
            uint256 traits; 
            uint256 class;  
    }

    struct Camps {
            uint32 baseRewards; 
            uint32 creatureCount; 
            uint32 creatureHealth; 
            uint32 expPoints; 
            uint32 minLevel;
            uint32 itemDrop;
            uint32 weaponDrop;
            uint32 spare;
    }

    /*Dont Delete, just keep it for reference

    struct Attributes { 
            uint256 hair; //MAX 3 3 hair traits
            uint256 race;  //MAX 6 Body 4 for body
            uint256 accessories; //MAX 7 4 
            uint256 sentinelClass; //MAX 3 3 in class
            uint256 weaponTier; //MAX 6 5 tiers
            uint256 inventory; //MAX 7 6 items
    }

    */

/////////////////////////////////////////////////////
function getElf(uint256 character) internal pure returns(Elf memory _elf) {
   
    _elf.owner =          address(uint160(uint256(character)));
    _elf.timestamp =      uint256(uint40(character>>160));
    _elf.action =         uint256(uint8(character>>200));
    _elf.healthPoints =       uint256(uint8(character>>208));
    _elf.attackPoints =   uint256(uint8(character>>216));
    _elf.primaryWeapon =  uint256(uint8(character>>224));
    _elf.level    =       uint256(uint8(character>>232));
    _elf.hair           = (uint256(uint8(character>>240)) / 100) % 10;
    _elf.race           = (uint256(uint8(character>>240)) / 10) % 10;
    _elf.accessories    = (uint256(uint8(character>>240))) % 10;
    _elf.sentinelClass  = (uint256(uint8(character>>248)) / 100) % 10;
    _elf.weaponTier     = (uint256(uint8(character>>248)) / 10) % 10;
    _elf.inventory      = (uint256(uint8(character>>248))) % 10; 

} 

function getToken(uint256 character) internal pure returns(Token memory token) {
   
    token.owner          = address(uint160(uint256(character)));
    token.timestamp      = uint256(uint40(character>>160));
    token.action         = (uint8(character>>200));
    token.healthPoints   = (uint8(character>>208));
    token.attackPoints   = (uint8(character>>216));
    token.primaryWeapon  = (uint8(character>>224));
    token.level          = (uint8(character>>232));
    token.hair           = ((uint8(character>>240)) / 100) % 10; //MAX 3
    token.race           = ((uint8(character>>240)) / 10) % 10; //Max6
    token.accessories    = ((uint8(character>>240))) % 10; //Max7
    token.sentinelClass  = ((uint8(character>>248)) / 100) % 10; //MAX 3
    token.weaponTier     = ((uint8(character>>248)) / 10) % 10; //MAX 6
    token.inventory      = ((uint8(character>>248))) % 10; //MAX 7

    token.hair = (token.sentinelClass * 3) + (token.hair + 1);
    token.race = (token.sentinelClass * 4) + (token.race + 1);
    token.primaryWeapon = token.primaryWeapon == 69 ? 69 : (token.sentinelClass * 15) + (token.primaryWeapon + 1);
    token.accessories = (token.sentinelClass * 7) + (token.accessories + 1);

}

function _setElf(
                address owner, uint256 timestamp, uint256 action, uint256 healthPoints, 
                uint256 attackPoints, uint256 primaryWeapon, 
                uint256 level, uint256 traits, uint256 class )

    internal pure returns (uint256 sentinel) {

    uint256 character = uint256(uint160(address(owner)));
    
    character |= timestamp<<160;
    character |= action<<200;
    character |= healthPoints<<208;
    character |= attackPoints<<216;
    character |= primaryWeapon<<224;
    character |= level<<232;
    character |= traits<<240;
    character |= class<<248;
    
    return character;
}

//////////////////////////////HELPERS/////////////////

function packAttributes(uint hundreds, uint tens, uint ones) internal pure returns (uint256 packedAttributes) {
    packedAttributes = uint256(hundreds*100 + tens*10 + ones);
    return packedAttributes;
}

function calcAttackPoints(uint256 sentinelClass, uint256 weaponTier) internal pure returns (uint256 attackPoints) {

        attackPoints = ((sentinelClass + 1) * 2) + (weaponTier * 2);
        
        return attackPoints;
}

function calcHealthPoints(uint256 sentinelClass, uint256 level) internal pure returns (uint256 healthPoints) {

        healthPoints = (level/(3) +2) + (20 - (sentinelClass * 4));
        
        return healthPoints;
}

function calcCreatureHealth(uint256 sector, uint256 baseCreatureHealth) internal pure returns (uint256 creatureHealth) {

        creatureHealth = ((sector - 1) * 12) + baseCreatureHealth; 
        
        return creatureHealth;
}

function roll(uint256 id_, uint256 level_, uint256 rand, uint256 rollOption_, uint256 weaponTier_, uint256 primaryWeapon_, uint256 inventory_) 
internal pure 
returns (uint256 newWeaponTier, uint256 newWeapon, uint256 newInventory) {

   uint256 levelTier = level_ == 100 ? 5 : uint256((level_/20) + 1);

   newWeaponTier = weaponTier_;
   newWeapon     = primaryWeapon_;
   newInventory  = inventory_;


   if(rollOption_ == 1 || rollOption_ == 3){
       //Weapons
      
        uint16  chance = uint16(_randomize(rand, "Weapon", id_)) % 100;
       // console.log("chance: ", chance);
                if(chance > 10 && chance < 80){
        
                              newWeaponTier = levelTier;
        
                        }else if (chance > 80 ){
        
                              newWeaponTier = levelTier + 1 > 5 ? 5 : levelTier + 1;
        
                        }else{

                                newWeaponTier = levelTier - 1 < 1 ? 1 : levelTier - 1;          
                        }

                                         
        

        newWeapon = newWeaponTier == 0 ? 0 : ((newWeaponTier - 1) * 3) + (rand % 3);  
        

   }
   
   if(rollOption_ == 2 || rollOption_ == 3){//Items Loop
      
       
        uint16 morerand = uint16(_randomize(rand, "Inventory", id_));
        uint16 diceRoll = uint16(_randomize(rand, "Dice", id_));
        
        diceRoll = (diceRoll % 100);
        
        if(diceRoll <= 20){

            newInventory = levelTier > 3 ? morerand % 3 + 3: morerand % 6 + 1;
            //console.log("Token#: ", id_);
            //console.log("newITEM: ", newInventory);
        } 

   }
                      
              
}


function _randomize(uint256 ran, string memory dom, uint256 ness) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(ran,dom,ness)));}



}