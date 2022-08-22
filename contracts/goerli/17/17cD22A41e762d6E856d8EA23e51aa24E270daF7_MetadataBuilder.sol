// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
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
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

pragma solidity ^0.8.0;

interface IMetadataFactory{
    struct nftMetadata {
        uint8 nftType;//0->Zombie 1->Survivor
        uint8[] traits;
        uint8 level;
        // uint nftCreationTime;
        // bool canClaim;
        // uint stakedTime;
        // uint lastClaimTime;
    }

    function createRandomMetadata(uint8 level, uint8 tokenType) external returns(nftMetadata memory);
    function createRandomZombie(uint8 level) external returns(uint8[] memory, uint8);
    function createRandomSurvivor(uint8 level) external returns(uint8[] memory, uint8);
    function constructNft(uint8 nftType, uint8[] memory traits, uint8 level) external view returns(nftMetadata memory);
    function buildMetadata(nftMetadata memory nft, bool survivor,uint id) external view returns(string memory);
    function levelUpMetadata(nftMetadata memory nft) external returns (nftMetadata memory);
}

pragma solidity ^0.8.0;

interface ISurvivorFactory {
    enum SurvivorTrait { Shoes, Pants, Body, Beard, Hair, Head, Shirt, ChestArmor, ShoulderArmor, LegArmor, RightWeapon, LeftWeapon }

    function survivorChestArmorTraitCount(uint8 level) external view returns (uint8);
    function survivorShoulderArmorTraitCount(uint8 level) external view returns (uint8);
    function survivorLegArmorTraitCount(uint8 level) external view returns (uint8);
    function survivorRightWeaponTraitCount(uint8 level) external view returns (uint8);
    function survivorLeftWeaponTraitCount(uint8 level) external view returns (uint8);
    function survivorShoesTraitCount() external view returns (uint8);
    function survivorPantsTraitCount() external view returns (uint8);
    function survivorBodyTraitCount() external view returns (uint8);
    function survivorBeardTraitCount() external view returns (uint8);
    function survivorHairTraitCount() external view returns (uint8);
    function survivorHeadTraitCount() external view returns (uint8);
    function survivorShirtTraitCount() external view returns (uint8);
    function survivorSVG(uint8 level, uint8[] memory traits) external view returns (bytes memory);
    function survivorTrait(SurvivorTrait trait, uint8 level, uint8 traitNumber) external view returns (string memory);
}

pragma solidity ^0.8.0;

interface IZombieMetadata {
    enum ZombieTrait { Torso, LeftArm, RightArm, Legs, Head }

    function zombieTorsoTraitCount(uint8 level) external view returns (uint8);
    function zombieLeftArmTraitCount(uint8 level) external view returns (uint8);
    function zombieRightArmTraitCount(uint8 level) external view returns (uint8);
    function zombieLegsTraitCount(uint8 level) external view returns (uint8);
    function zombieHeadTraitCount(uint8 level) external view returns (uint8);
    function zombieSVG(uint8 level, uint8[] memory traits) external view returns (bytes memory);
    function zombieTrait(ZombieTrait trait, uint8 level, uint8 traitNumber) external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint` to its ASCII `string` decimal representation.
     */
    function toString(uint value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint temp = value;
        uint digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint temp = value;
        uint length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint value, uint length)
    internal
    pure
    returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

pragma solidity ^0.8.0;

/// @dev Proxy for NFT Factory
contract ProxyTarget {

    // Storage for this proxy
    bytes32 internal constant IMPLEMENTATION_SLOT = bytes32(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc);
    bytes32 internal constant ADMIN_SLOT          = bytes32(0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103);

    function _getAddress(bytes32 key) internal view returns (address add) {
        add = address(uint160(uint256(_getSlotValue(key))));
    }

    function _getSlotValue(bytes32 slot_) internal view returns (bytes32 value_) {
        assembly {
            value_ := sload(slot_)
        }
    }

    function _setSlotValue(bytes32 slot_, bytes32 value_) internal {
        assembly {
            sstore(slot_, value_)
        }
    }

}

// SPDX-License-Identifier: GPL-3.0
import '../base/Base64.sol';
import '../base/IZombieMetadata.sol';
import '../base/ISurvivorFactory.sol';
import "../base/IMetadataFactory.sol";
import '../base/Strings.sol';
import "../main/ProxyTarget.sol";

pragma solidity ^0.8.0;

/// @title MetadataBuilder
/// @notice Provides metadata builder utility functions for MetadataFactory
contract MetadataBuilder is ProxyTarget {

	bool public initialized;
    IZombieMetadata zombieMetadata;
    ISurvivorFactory survivorFactory;
    
    IMetadataFactory metadataFactory;

    function initialize(address _metaFactory, address _zombieMetadata, address _survivorFactory) external {
        require(msg.sender == _getAddress(ADMIN_SLOT), "not admin");
        require(!initialized);
        initialized = true;

        metadataFactory = IMetadataFactory(_metaFactory);
        zombieMetadata = IZombieMetadata(_zombieMetadata);
        survivorFactory = ISurvivorFactory(_survivorFactory);
    }

    function buildMetadata(IMetadataFactory.nftMetadata memory nft, bool survivor,uint id) public view returns(string memory) {

        if(survivor) {
            return string(abi.encodePacked(
                    'data:application/json;base64,', Base64.encode(survivorMetadataBytes(nft,id))));
        } else {
            return string(abi.encodePacked(
                    'data:application/json;base64,', Base64.encode(zombieMetadataBytes(nft,id))));
        }
    }

    function survivorMetadataBytes(IMetadataFactory.nftMetadata memory survivor,uint id) public view returns(bytes memory) {
        string memory firstHalf = string(abi.encodePacked(
                '{"name":"',
                'Survivor #',
                Strings.toString(id),
                '", "description":"',
                'Hunger Brainz is a 100% on-chain wargame of Zombies vs. Survivors with high risk and even higher rewards',
                '", "image":"',
                'data:image/svg+xml;base64,',
                Base64.encode(survivorFactory.survivorSVG(survivor.level, survivor.traits)),
                '", "attributes":[',
                '{"trait_type":"Character Type","value":"Survivor"},',
                '{"trait_type":"Level","value":',
                    Strings.toString(survivor.level),
                '},',
                '{"trait_type":"Shoes","value":',
                    survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.Shoes, survivor.level, survivor.traits[0]),
                '},',
                '{"trait_type":"Pants","value":',
                    survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.Pants,  survivor.level, survivor.traits[1]),
                '},',
                '{"trait_type":"Body","value":',
                    survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.Body,  survivor.level, survivor.traits[2]),
                '},',
                '{"trait_type":"Beard","value":',
                    survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.Beard,  survivor.level, survivor.traits[3]),
                '},',
                '{"trait_type":"Hair","value":',
                    survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.Hair,  survivor.level, survivor.traits[4]),
                '},',
                '{"trait_type":"Head","value":',
                    survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.Head,  survivor.level, survivor.traits[5]),
                '},'
                
                ));

        string memory secondHalf = string(abi.encodePacked(
            '{"trait_type":"Shirt","value":',
                    survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.Shirt, survivor.level, survivor.traits[6]),
                '},',
            '{"trait_type":"Chest Armor","value":',
                    survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.ChestArmor, survivor.level, survivor.traits[7]),
                '},',
                '{"trait_type":"Shoulder Armor","value":',
                    survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.ShoulderArmor, survivor.level, survivor.traits[8]),
                '},',
                '{"trait_type":"Leg Armor","value":',
                    survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.LegArmor, survivor.level, survivor.traits[9]),
                '},',
                '{"trait_type":"Right Weapon","value":',
                    survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.RightWeapon, survivor.level, survivor.traits[10]),
                '},',
                '{"trait_type":"Left Weapon","value":',
                    survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.LeftWeapon, survivor.level, survivor.traits[11]),
                '}',
                ']',
                '}'
        ));
        return bytes(abi.encodePacked(firstHalf,secondHalf));
    }

    function zombieMetadataBytes(IMetadataFactory.nftMetadata memory zombie,uint id) public view returns(bytes memory) {
        // string memory id = "1";
        return bytes(
            abi.encodePacked(
                '{"name":"',
                'Zombie #',
                Strings.toString(id),
                '", "description":"',
                'Hunger Brainz is a 100% on-chain wargame of Zombies vs. Survivors with high risk and even higher rewards',
                '", "image":"',
                'data:image/svg+xml;base64,',
                Base64.encode(zombieMetadata.zombieSVG(zombie.level, zombie.traits)),
                '", "attributes":[',
                '{"trait_type":"Character Type","value":"Zombie"},',
                '{"trait_type":"Level","value":',
                    Strings.toString(zombie.level),
                '},',
                '{"trait_type":"Torso","value":',
                    zombieMetadata.zombieTrait(IZombieMetadata.ZombieTrait.Torso, zombie.level, zombie.traits[0]),
                '},',
                '{"trait_type":"Left Arm","value":',
                    zombieMetadata.zombieTrait(IZombieMetadata.ZombieTrait.LeftArm, zombie.level, zombie.traits[1]),
                '},',
                '{"trait_type":"Right Arm","value":',
                    zombieMetadata.zombieTrait(IZombieMetadata.ZombieTrait.RightArm, zombie.level, zombie.traits[2]),
                '},',
                '{"trait_type":"Legs","value":',
                    zombieMetadata.zombieTrait(IZombieMetadata.ZombieTrait.Legs, zombie.level, zombie.traits[3]),
                '},',
                '{"trait_type":"Head","value":',
                    zombieMetadata.zombieTrait(IZombieMetadata.ZombieTrait.Head, zombie.level, zombie.traits[4]),
                '}',
                ']',
                '}'
            )
        );
    }
    
}