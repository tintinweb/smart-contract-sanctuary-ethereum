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
import './SurvivorMetadata.sol';
// import "../raw data/Survivor/Beard1.sol";
// import "../raw data/Survivor/Beard2.sol";
// import "../raw data/Survivor/Beard3.sol";
// import "../raw data/Survivor/Body1.sol";
// import "../raw data/Survivor/Body2.sol";
// import "../raw data/Survivor/Body3.sol";
// import "../raw data/Survivor/Chest.sol";
// import "../raw data/Survivor/Hair1.sol";
// import "../raw data/Survivor/Hair2.sol";
// import "../raw data/Survivor/Hair3.sol";
// import "../raw data/Survivor/Head1.sol";
// import "../raw data/Survivor/Head2.sol";
// import "../raw data/Survivor/Knee.sol";
// import "../raw data/Survivor/L1RHWeapon.sol";
// import "../raw data/Survivor/L2RHWeapon.sol";
// import "../raw data/Survivor/L3LHWeapon.sol";
// import "../raw data/Survivor/L4LHWeapon.sol";
// import "../raw data/Survivor/L5LHWeapon.sol";
// import "../raw data/Survivor/Pant.sol";
// import "../raw data/Survivor/Shirt1.sol";
// import "../raw data/Survivor/Shirt2.sol";
// import "../raw data/Survivor/Shoe.sol";
// import "../raw data/Survivor/Shoulder1.sol";
// import "../raw data/Survivor/Shoulder2.sol";
import "../base/Strings.sol";
import "../main/ProxyTarget.sol";

pragma solidity ^0.8.0;

/// @title SurvivorFactory
/// @author Gordon
/// @notice Provides metadata information for survivors
contract SurvivorFactory is ProxyTarget {
    // survivorMetadata = addrs[0];
    // survivorBeard1 = addrs[1];
    // survivorBeard2 = addrs[2];
    // survivorBeard3 = addrs[3];
    // survivorBody1 = addrs[4];
    // survivorBody2 = addrs[5];
    // survivorBody3 = addrs[6];
    // survivorChest = addrs[7];
    // survivorHair1 = addrs[8];
    // survivorHair2 = addrs[9];
    // survivorHair3 = addrs[10];
    // survivorHead1 = addrs[11];
    // survivorHead2 = addrs[12];
    // survivorKnee = addrs[13];
    // survivorWeapon1 = addrs[14];
    // survivorWeapon2 = addrs[15];
    // survivorWeapon3 = addrs[16];
    // survivorWeapon4 = addrs[17];
    // survivorWeapon5 = addrs[18];
    // survivorPant = addrs[19];
    // survivorShirt1 = addrs[20];
    // survivorShirt2 = addrs[21];
    // survivorShoe = addrs[22];
    // survivorShoulder1 = addrs[23];
    // survivorShoulder2 = addrs[24];
	bool public initialized;
    address[25] public sources;

    function initialize(
        address[] calldata addrs
    ) external {
        require(msg.sender == _getAddress(ADMIN_SLOT), "not admin");
        require(!initialized);
        initialized = true;
        require(addrs.length == 25, "invalid addrs");

        for (uint256 i = 0; i < addrs.length; i++) {
            sources[i] = addrs[i];
        }
    }
    
    enum SurvivorTrait { Shoes, Pants, Body, Beard, Hair, Head, Shirt, ChestArmor, ShoulderArmor, LegArmor, RightWeapon, LeftWeapon }


    function call(address source, bytes memory sig) internal view returns (string memory svg) {
        (bool succ, bytes memory ret)  = source.staticcall(sig);
        // require(succ, "failed to get data");
        svg = abi.decode(ret, (string));
    }

    function traitName(uint8 level, uint8 traitNumber, string memory name) public pure returns (string memory) {
        
        if(level > 0) {
            return string(
                abi.encodePacked('"',
                    "Level ",
                    Strings.toString(level),
                    name,
                    Strings.toString(traitNumber),'"'
                )
            );
        } else {
            return string(
                abi.encodePacked('"',
                    name,
                    Strings.toString(traitNumber),'"'
                )
            ); 
        }
    }

    //SHOES

    function survivorShoesTraitCount() public pure returns (uint8) { return 28; }
    function survivorShoesTrait(uint8 traitNumber) public pure returns (string memory) {
        if(traitNumber > 0 && traitNumber <= survivorShoesTraitCount()) {
            return traitName(0, traitNumber, "Shoes ");
        } else {
            return "";
        }
    }
    function survivorShoesSVG(uint8 traitNumber) public view returns(string memory) {
        if(traitNumber > 0 && traitNumber <= survivorShoesTraitCount()) {
            return call(sources[22], abi.encodeWithSignature(string(abi.encodePacked("Shoe", Strings.toString(traitNumber-1), "()")), ""));
            // return survivorShoe.ShoeL1()[traitNumber-1];
        } else {
            return "";
        }
    }

    //PANTS
    function survivorPantsTraitCount() public pure returns (uint8) { return 20; }
    function survivorPantsTrait(uint8 traitNumber) public pure returns (string memory) {
        if(traitNumber > 0 && traitNumber <= survivorPantsTraitCount()) {
            return traitName(0, traitNumber, "Pants ");
        } else {
            return "";
        }
    }
    function survivorPantsSVG(uint8 traitNumber) public view returns(string memory) {
        if(traitNumber > 0 && traitNumber <= survivorPantsTraitCount()) {
            return call(sources[19], abi.encodeWithSignature(string(abi.encodePacked("Pant", Strings.toString(traitNumber-1), "()")), ""));
            // return survivorPant.PantL1()[traitNumber-1];
        } else {
            return "";
        }
        
    }

    //BODY
    function survivorBodyTraitCount() public pure returns (uint8) { return 25; }
    function survivorBodyTrait(uint8 traitNumber) public pure returns (string memory) {
        if(traitNumber > 0 && traitNumber <= survivorBodyTraitCount()) {
            return traitName(0, traitNumber, "Body ");
        } else {
            return "";
        }
    }
    function survivorBodySVG(uint8 traitNumber) public view returns(string memory) {

        if(traitNumber < 11){
            return call(sources[4], abi.encodeWithSignature(string(abi.encodePacked("Body", Strings.toString(traitNumber-1), "()")), ""));
            // return survivorBody1.BodyL1()[traitNumber-1];
        }
        else if(traitNumber < 21){
            return call(sources[5], abi.encodeWithSignature(string(abi.encodePacked("Body", Strings.toString(traitNumber-11), "()")), ""));
            // return survivorBody2.BodyL2()[traitNumber - 11];
        }
        else if(traitNumber < 26){
            return call(sources[6], abi.encodeWithSignature(string(abi.encodePacked("Body", Strings.toString(traitNumber-21), "()")), ""));
            // return survivorBody3.BodyL3()[traitNumber-21];
        }
        else{
            return "";
        }
        
    }

    //BEARD
    function survivorBeardTraitCount() public pure returns (uint8) { return 42; }
    function survivorBeardTrait(uint8 traitNumber) public pure returns (string memory) {
        if(traitNumber > 0 && traitNumber <= survivorBeardTraitCount()) {
            return traitName(0, traitNumber, "Beard ");
        } else {
            return "";
        } 
    }
    function survivorBeardSVG(uint8 traitNumber) public view returns(string memory) {
        
        if(traitNumber< 16){
            return call(sources[1], abi.encodeWithSignature(string(abi.encodePacked("Beard", Strings.toString(traitNumber-1), "()")), ""));
            // return survivorBeard1.BeardL1()[traitNumber-1];
        }
        else if(traitNumber < 30){
            return call(sources[2], abi.encodeWithSignature(string(abi.encodePacked("Beard", Strings.toString(traitNumber-16), "()")), ""));
            // return survivorBeard2.BeardL2()[traitNumber-16];
        }
        else if(traitNumber < 43){
            return call(sources[3], abi.encodeWithSignature(string(abi.encodePacked("Beard", Strings.toString(traitNumber-30), "()")), ""));
            // return survivorBeard3.BeardL3()[traitNumber-30];
        }
        else{
            return "";
        }
    }

    //HAIR
    function survivorHairTraitCount() public pure returns (uint8) { return 39; }
    function survivorHairTrait(uint8 traitNumber) public pure returns (string memory) {
        if(traitNumber > 0 && traitNumber <= survivorHairTraitCount()) {
            return traitName(0, traitNumber, "Hair ");
        } else {
            return "";
        }   
    }
    function survivorHairSVG(uint8 traitNumber) public view returns(string memory) {
        if(traitNumber< 16){
            return call(sources[8], abi.encodeWithSignature(string(abi.encodePacked("Hair", Strings.toString(traitNumber-1), "()")), ""));
            // return survivorHair1.HairL1()[traitNumber-1];
        }
        else if(traitNumber < 29){
            return call(sources[9], abi.encodeWithSignature(string(abi.encodePacked("Hair", Strings.toString(traitNumber-16), "()")), ""));
            // return survivorHair2.HairL2()[traitNumber-16];
        }
        else if(traitNumber < 40){
            return call(sources[10], abi.encodeWithSignature(string(abi.encodePacked("Hair", Strings.toString(traitNumber-29), "()")), ""));
            // return survivorHair3.HairL3()[traitNumber-29];
        }
        else{
            return "";
        }
    }

    //HEAD
    function survivorHeadTraitCount() public pure returns (uint8) { return 40; }
    function survivorHeadTrait(uint8 traitNumber) public view returns (string memory) {
        return SurvivorMetadata(sources[0]).getHead()[traitNumber - 1];
    }
    function survivorHeadSVG(uint8 traitNumber) public view returns(string memory) {
        
        if(traitNumber<21){
            return call(sources[11], abi.encodeWithSignature(string(abi.encodePacked("Head", Strings.toString(traitNumber-1), "()")), ""));
            // return survivorHead1.HeadL1()[traitNumber -1];
        }
        else if(traitNumber < 41){
            return call(sources[12], abi.encodeWithSignature(string(abi.encodePacked("Head", Strings.toString(traitNumber-21), "()")), ""));
            // return survivorHead2.HeadL2()[traitNumber - 21];
        }
        else{
            return "";
        }
        
    }

    //SHIRTS
    function survivorShirtTraitCount() public pure returns (uint8) { return 32; }
    function survivorShirtTrait(uint8 traitNumber) public pure returns (string memory) {
        if(traitNumber > 0 && traitNumber <= survivorShirtTraitCount()) {
            return traitName(0, traitNumber, "Shirts ");
        } else {
            return "";
        } 
    }
    function survivorShirtSVG(uint8 traitNumber) public view returns(string memory) {
        
        if(traitNumber< 16){
            return call(sources[20], abi.encodeWithSignature(string(abi.encodePacked("Shirt", Strings.toString(traitNumber-1), "()")), ""));
            // return survivorShirt1.ShirtL1()[traitNumber-1];
        }
        else if(traitNumber < 33){
            return call(sources[21], abi.encodeWithSignature(string(abi.encodePacked("Shirt", Strings.toString(traitNumber-16), "()")), ""));
            // return survivorShirt2.ShirtL2()[traitNumber-16];
        }
        else{
            return "";
        }
        
    }

    //CHESTARMOR
    function survivorChestArmorTraitCount(uint8 level) public pure returns (uint8) { 
        if(level == 5) return 13;
        else return 0;
    }

    function survivorChestArmorTrait(uint8 level, uint8 traitNumber) public pure returns (string memory) {
        if(survivorChestArmorTraitCount(level) > 0) {
            return traitName(0, traitNumber, "Chest Armor ");
        } else {
            return '"None"';
        } 
    }
    function survivorChestArmorSVG(uint8 level, uint8 traitNumber) public view returns(string memory) {
        if(level == 5) {
            return call(sources[7], abi.encodeWithSignature(string(abi.encodePacked("Chest", Strings.toString(traitNumber-1), "()")), ""));
            // return survivorChest.ChestL1()[traitNumber - 1];
        } else {
            return "";
        }
    }

    //SHOULDERARMOR
    function survivorShoulderArmorTraitCount(uint8 level) public pure returns (uint8) { 
        if(level == 4) return 8; //Shoulder Armor 1-8
        if(level == 5) return 8; //Shoulder Armor 9-16
        else return 0;
    }
    function survivorShoulderArmorTrait(uint8 level, uint8 traitNumber) public pure returns (string memory) {
        if(survivorShoulderArmorTraitCount(level) > 0) {
            if(level == 4) { return traitName(0, traitNumber, "Shoulder Armor "); }
            else { return traitName(0, traitNumber + 8, "Shoulder Armor "); } //level 5
        } else {
            return '"None"';
        } 
    }
    function survivorShoulderArmorSVG(uint8 level, uint8 traitNumber) public view returns(string memory) {
        if(level == 4) {
            return call(sources[23], abi.encodeWithSignature(string(abi.encodePacked("Shoulder", Strings.toString(traitNumber-1), "()")), ""));
            // return survivorShoulder1.ShoulderL1()[traitNumber - 1];
        }  if(level == 5) {
            return call(sources[24], abi.encodeWithSignature(string(abi.encodePacked("Shoulder", Strings.toString(traitNumber-1), "()")), ""));
            // return survivorShoulder2.ShoulderL2()[traitNumber - 1];
        } else {
            return "";
        }
    }

    //LEGARMOR
    function survivorLegArmorTraitCount(uint8 level) public pure returns (uint8) { 
        if(level >= 4) return 8;
        else return 0;
    }
    function survivorLegArmorTrait(uint8 level, uint8 traitNumber) public pure returns (string memory) {
        if(survivorLegArmorTraitCount(level) > 0) {
            return traitName(0, traitNumber, "Leg Armor ");
        } else {
            return '"None"';
        } 
    }
    function survivorLegArmorSVG(uint8 level, uint8 traitNumber) public view returns(string memory) {
        if(level >= 4) {
            return call(sources[13], abi.encodeWithSignature(string(abi.encodePacked("Knee", Strings.toString(traitNumber-1), "()")), ""));
            // return survivorKnee.KneeL1()[traitNumber - 1];
        } else {
            return "";
        } 
    }

    //RIGHTWEAPON
    function survivorRightWeaponTraitCount(uint8 level) public pure returns (uint8) { 
        if(level == 1) return 8;
        else if(level >= 2) return 11;
        else return 0;
    }
    function survivorRightWeaponTrait(uint8 level, uint8 traitNumber) public pure returns (string memory) {
        if(survivorRightWeaponTraitCount(level) > 0) {
            return traitName(level, traitNumber, " Right Weapon ");
        } else {
            return '"None"';
        } 
    }
    function survivorRightWeaponSVG(uint8 level, uint8 traitNumber) public view returns(string memory) {
        if(level == 1) {
            return call(sources[14], abi.encodeWithSignature(string(abi.encodePacked("L1RHWeapon", Strings.toString(traitNumber-1), "()")), ""));
            // return survivorWeapon1.SurvivorWeaponL1()[traitNumber - 1];
        } else if(level >= 2) {
            return call(sources[15], abi.encodeWithSignature(string(abi.encodePacked("L2RHWeapon", Strings.toString(traitNumber-1), "()")), ""));
            // return survivorWeapon2.SurvivorWeaponL2()[traitNumber - 1];
        } else {
            return "";
        }
    }

    //LEFTWEAPON
    function survivorLeftWeaponTraitCount(uint8 level) public pure returns (uint8) { 
        if(level == 3) return 9;
        else if(level == 4) return 7;
        else if(level == 5) return 7;
        else return 0;
    }
    function survivorLeftWeaponTrait(uint8 level, uint8 traitNumber) public pure returns (string memory) {
        if(survivorLeftWeaponTraitCount(level) > 0) {
            return traitName(level, traitNumber, " Left Weapon ");
        } else {
            return '"None"';
        } 
    }
    function survivorLeftWeaponSVG(uint8 level, uint8 traitNumber) public view returns(string memory) {
        if(level == 3) {
            return call(sources[16], abi.encodeWithSignature(string(abi.encodePacked("L3LHWeapon", Strings.toString(traitNumber-1), "()")), ""));
            // return  survivorWeapon3.SurvivorWeaponL3()[traitNumber - 1];
        } else if(level == 4) {
            return call(sources[17], abi.encodeWithSignature(string(abi.encodePacked("L4LHWeapon", Strings.toString(traitNumber-1), "()")), ""));
            // return  survivorWeapon4.SurvivorWeaponL4()[traitNumber - 1];
        }  else if(level == 5) {
            return call(sources[18], abi.encodeWithSignature(string(abi.encodePacked("L5LHWeapon", Strings.toString(traitNumber-1), "()")), ""));
            // return  survivorWeapon5.SurvivorWeaponL5()[traitNumber - 1];
        } else {
            return "";
        }
    }

    function survivorTrait(SurvivorTrait trait, uint8 level, uint8 traitNumber) external view returns (string memory) {
        if(trait == SurvivorTrait.Shoes) return survivorShoesTrait(traitNumber);
        if(trait == SurvivorTrait.Pants) return survivorPantsTrait(traitNumber);
        if(trait == SurvivorTrait.Body) return survivorBodyTrait(traitNumber);
        if(trait == SurvivorTrait.Beard) return survivorBeardTrait(traitNumber);
        if(trait == SurvivorTrait.Hair) return survivorHairTrait(traitNumber);
        if(trait == SurvivorTrait.Head) return string(abi.encodePacked('"',survivorHeadTrait(traitNumber),'"'));
        if(trait == SurvivorTrait.Shirt) return survivorShirtTrait(traitNumber);

        if(trait == SurvivorTrait.ChestArmor) return survivorChestArmorTrait(level, traitNumber);
        if(trait == SurvivorTrait.ShoulderArmor) return survivorShoulderArmorTrait(level, traitNumber);
        if(trait == SurvivorTrait.LegArmor) return survivorLegArmorTrait(level, traitNumber);
        if(trait == SurvivorTrait.RightWeapon) return survivorRightWeaponTrait(level, traitNumber);
        if(trait == SurvivorTrait.LeftWeapon) return survivorLeftWeaponTrait(level, traitNumber);
        else return '"None"';
    }

    function survivorSVG(uint8 level, uint8[] memory traits) external view returns (bytes memory) {
        string memory shirtSVG = survivorShirtSVG(traits[6]);
        string memory chestArmorSVG = survivorChestArmorSVG(level, traits[7]);
        string memory shoulderArmorSVG = survivorShoulderArmorSVG(level, traits[8]);
        string memory LegArmorSVG = survivorLegArmorSVG(level, traits[9]);
        string memory rightWeaponSVG = survivorRightWeaponSVG(level, traits[10]);
        string memory leftWeaponSVG = survivorLeftWeaponSVG(level, traits[11]);
        string memory shoesSVG = survivorShoesSVG(traits[0]);
        string memory pantsSVG = survivorPantsSVG(traits[1]);
        string memory bodySVG = survivorBodySVG(traits[2]);
        string memory beardSVG = survivorBeardSVG(traits[3]);
        string memory hairSVG = survivorHairSVG(traits[4]);
        string memory headSVG = survivorHeadSVG(traits[5]);
        
        if(bytes(shirtSVG).length != 0){
            shirtSVG = string(
                abi.encodePacked(
                    '<image x="1" y="1" width="70" height="70" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
            shirtSVG,
            '"/>'));
        }
        if(bytes(chestArmorSVG).length != 0){
            chestArmorSVG = string(
                abi.encodePacked(
                    '<image x="1" y="1" width="70" height="70" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
            chestArmorSVG,
            '"/>'));
        }
        if(bytes(shoulderArmorSVG).length != 0){
            shoulderArmorSVG = string(
                abi.encodePacked(
                    '<image x="1" y="1" width="70" height="70" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
            shoulderArmorSVG,
            '"/>'));
        }
        if(bytes(LegArmorSVG).length != 0){
            LegArmorSVG = string(
                abi.encodePacked(
                    '<image x="1" y="1" width="70" height="70" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
            LegArmorSVG,
            '"/>'));
        }
        if(bytes(rightWeaponSVG).length != 0){
            rightWeaponSVG = string(
                abi.encodePacked(
                    '<image x="1" y="1" width="70" height="70" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
            rightWeaponSVG,
            '"/>'));
        }
        if(bytes(leftWeaponSVG).length != 0){
            leftWeaponSVG = string(
                abi.encodePacked(
                    '<image x="1" y="1" width="70" height="70" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
            leftWeaponSVG,
            '"/>'));
        }
        if(bytes(shoesSVG).length != 0){
            shoesSVG = string(
                abi.encodePacked(
                    '<image x="1" y="1" width="70" height="70" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
            shoesSVG,
            '"/>'));
        }
        if(bytes(pantsSVG).length != 0){
            pantsSVG = string(
                abi.encodePacked(
                    '<image x="1" y="1" width="70" height="70" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
            pantsSVG,
            '"/>'));
        }
        if(bytes(bodySVG).length != 0){
            bodySVG = string(
                abi.encodePacked(
                    '<image x="1" y="1" width="70" height="70" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
            bodySVG,
            '"/>'));
        }
        if(bytes(beardSVG).length != 0){
            beardSVG = string(
                abi.encodePacked(
                    '<image x="1" y="1" width="70" height="70" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
            beardSVG,
            '"/>'));
        }
        if(bytes(hairSVG).length != 0){
            hairSVG = string(
                abi.encodePacked(
                    '<image x="1" y="1" width="70" height="70" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
            hairSVG,
            '"/>'));
        }
        if(bytes(headSVG).length != 0){
            headSVG = string(
                abi.encodePacked(
                    '<image x="1" y="1" width="70" height="70" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
            headSVG,
            '"/>'));
        }
        string memory first = string(abi.encodePacked(
            abi.encodePacked(
                '<svg id="survivor" width="100%" height="100%" version="1.1" viewBox="0 0 70 70" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                bodySVG,
                pantsSVG,
                shoesSVG,
                LegArmorSVG,
                rightWeaponSVG
                    )
                )
        );

        string memory second = string(abi.encodePacked(
                shirtSVG,
                chestArmorSVG,
                shoulderArmorSVG,
                beardSVG,
                hairSVG,
                headSVG,
                leftWeaponSVG,
                '<style>#survivor{shape-rendering: crispedges; image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;}</style>',
                '</svg>'
        ));

        
        return bytes(
                abi.encodePacked(first,second)
                
            );
        
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title SurvivorMetadata
/// @author Gordon
/// @notice Provides metadata information for survivors


contract SurvivorMetadata {
    function getHead() public pure returns (string[44] memory) {
        return ["Hat 1","Hat 2","Hat 3","Hat 4","Hat 5","Hat 6","Hat 7","Hat 8","Sunglasses 1","Sunglasses 2","Face Marking 1","Face Marking 2","Face Marking 3","Hat 9","Sunglasses 3","Sunglasses 4","Sunglasses 5","Sunglasses 6","Sunglasses 7","Sunglasses 8","Sunglasses 9","Sunglasses 10","Face Marking 4","Sunglasses 11","Sunglasses 12","Sunglasses 13","Sunglasses 14","Sunglasses 15","Sunglasses 16","Sunglasses 17","Sunglasses 18","Hat 10","Hat 11","Hat 12","Hat 13","Hat 14","Hat 15","Hat 16","Hat 17","Hat 18","None","None","None","None"];
    }
}