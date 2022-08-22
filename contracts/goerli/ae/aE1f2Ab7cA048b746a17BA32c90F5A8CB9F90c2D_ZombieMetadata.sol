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
pragma solidity ^0.8.0;

/// @title ZombieMetadata
/// @notice Provides metadata information for zombies
// import "../raw data/zombies/Head1.sol";
// import "../raw data/zombies/Head2.sol";
// import "../raw data/zombies/Head3.sol";
// import "../raw data/zombies/Head4.sol";
// import "../raw data/zombies/Head5.sol";
// import "../raw data/zombies/LeftArm1.sol";
// import "../raw data/zombies/LeftArm2.sol";
// import "../raw data/zombies/LeftArm3.sol";
// import "../raw data/zombies/LeftArm4.sol";
// import "../raw data/zombies/LeftArm5.sol";
// import "../raw data/zombies/Leg1.sol";
// import "../raw data/zombies/Leg2.sol";
// import "../raw data/zombies/Leg3.sol";
// import "../raw data/zombies/Leg4.sol";
// import "../raw data/zombies/Leg5.sol";
// import "../raw data/zombies/RightArm1.sol";
// import "../raw data/zombies/RightArm2.sol";
// import "../raw data/zombies/RightArm3.sol";
// import "../raw data/zombies/RightArm4.sol";
// import "../raw data/zombies/RightArm5.sol";
// import "../raw data/zombies/Torso1.sol";
// import "../raw data/zombies/Torso2.sol";
// import "../raw data/zombies/Torso3.sol";
// import "../raw data/zombies/Torso4.sol";
// import "../raw data/zombies/Torso5.sol";
import "../base/Strings.sol";
import "../main/ProxyTarget.sol";
// import "hardhat/console.sol";

contract ZombieMetadata is ProxyTarget {
    // head1 = Head1(addrs[0]);
    // head2 = Head2(addrs[1]);
    // head3 = Head3(addrs[2]);
    // head4 = Head4(addrs[3]);
    // head5 = Head5(addrs[4]);
    // leftArm1 = LeftArm1(addrs[5]);
    // leftArm2 = LeftArm2(addrs[6]);
    // leftArm3 = LeftArm3(addrs[7]);
    // leftArm4 = LeftArm4(addrs[8]);
    // leftArm5 = LeftArm5(addrs[9]);
    // leg1 = Leg1(addrs[10]);
    // leg2 = Leg2(addrs[11]);
    // leg3 = Leg3(addrs[12]);
    // leg4 = Leg4(addrs[13]);
    // leg5 = Leg5(addrs[14]);
    // rightArm1 = RightArm1(addrs[15]);
    // rightArm2 = RightArm2(addrs[16]);
    // rightArm3 = RightArm3(addrs[17]);
    // rightArm4 = RightArm4(addrs[18]);
    // rightArm5 = RightArm5(addrs[19]);
    // torso1 = Torso1(addrs[20]);
    // torso2 = Torso2(addrs[21]);
    // torso3 = Torso3(addrs[22]);
    // torso4 = Torso4(addrs[23]);
    // torso5 = Torso5(addrs[24]);
    
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

    enum ZombieTrait { Torso, LeftArm, RightArm, Legs, Head }

    function call(address source, bytes memory sig) internal view returns (string memory svg) {
        (bool succ, bytes memory ret)  = source.staticcall(sig);
        // require(succ, "failed to get data");
        svg = abi.decode(ret, (string));
    }

    function traitName(uint8 level, uint8 traitNumber, string memory name) public pure returns (string memory) {
        return string(
            abi.encodePacked('"',
                "Level ",
                Strings.toString(level),
                name,
                Strings.toString(traitNumber),'"'
            )
        );
    }

    function zombieTorsoTraitCount(uint8 level) public pure returns (uint8) { if(level > 0) { return 10; } else { return 0; } }
    function zombieTorsoTrait(uint8 level, uint8 traitNumber) public pure returns (string memory) {
        if(level > 0 && level <= 5 && zombieTorsoTraitCount(level) > 0) {
            return traitName(level, traitNumber, " Torso ");
        } else {
            return "";
        }
    }
    function zombieTorsoSVG(uint8 level, uint8 traitNumber) public view returns(string memory) {
        if(level == 1) {
            return call(sources[20], abi.encodeWithSignature(string(abi.encodePacked("L1Torso", Strings.toString(traitNumber-1), "()")), ""));
            // string[10] memory TORSO_L1 = torso1.TorsoL1();
            // return TORSO_L1[traitNumber - 1];
        } else if(level == 2) {
            return call(sources[21], abi.encodeWithSignature(string(abi.encodePacked("L2Torso", Strings.toString(traitNumber-1), "()")), ""));
            // string[10] memory TORSO_L2 = torso2.TorsoL2();
            // return TORSO_L2[traitNumber - 1];
        } else if(level == 3) {
            return call(sources[22], abi.encodeWithSignature(string(abi.encodePacked("L3Torso", Strings.toString(traitNumber-1), "()")), ""));
            // string[10] memory TORSO_L3 = torso3.TorsoL3();
            // return TORSO_L3[traitNumber - 1];
        } else if(level == 4) {
            return call(sources[23], abi.encodeWithSignature(string(abi.encodePacked("L4Torso", Strings.toString(traitNumber-1), "()")), ""));
            // string[10] memory TORSO_L4 = torso4.TorsoL4();
            // return TORSO_L4[traitNumber - 1];
        } else if(level == 5) {
            return call(sources[24], abi.encodeWithSignature(string(abi.encodePacked("L5Torso", Strings.toString(traitNumber-1), "()")), ""));
            // string[10] memory TORSO_L5 = torso5.TorsoL5();
            // return TORSO_L5[traitNumber - 1];
        } else {
            return "";
        }
    }

    function zombieLeftArmTraitCount(uint8 level) public pure returns (uint8) { 
        if(level == 1) return 12;
        else if(level == 2) return 8;
        else if(level == 3) return 9;
        else if(level == 4) return 9;
        else if(level == 5) return 9;
        else return 0;
    }
    function zombieLeftArmTrait(uint8 level, uint8 traitNumber) public pure returns (string memory) {

        if(level > 0 && level <= 5 && zombieLeftArmTraitCount(level) > 0) {
            return traitName(level, traitNumber, " Left Arm ");
        } else {
            return "";
        }

    }
    function zombieLeftArmSVG(uint8 level, uint8 traitNumber) public view returns(string memory) {
        // Credit to EtherOrcs for being the OG pioneers in the on-chain gaming space and their code that made this game possible.
        if(level == 1) {
            return call(sources[5], abi.encodeWithSignature(string(abi.encodePacked("L1LeftArm", Strings.toString(traitNumber-1), "()")), ""));
            // string[12] memory LEFTARM_L1 = leftArm1.LeftArmL1();
            // return LEFTARM_L1[traitNumber - 1];
        } else if(level == 2) {
            return call(sources[6], abi.encodeWithSignature(string(abi.encodePacked("L2LeftArm", Strings.toString(traitNumber-1), "()")), ""));
            // string[8] memory LEFTARM_L2 = leftArm2.LeftArmL2();
            // return LEFTARM_L2[traitNumber - 1];
        } else if(level == 3) {
            return call(sources[7], abi.encodeWithSignature(string(abi.encodePacked("L3LeftArm", Strings.toString(traitNumber-1), "()")), ""));
            // string[9] memory LEFTARM_L3 =  leftArm3.LeftArmL3();
            // return LEFTARM_L3[traitNumber - 1];
        } else if(level == 4) {
            return call(sources[8], abi.encodeWithSignature(string(abi.encodePacked("L4LeftArm", Strings.toString(traitNumber-1), "()")), ""));
            // string[9] memory LEFTARM_L4 =  leftArm4.LeftArmL4();
            // return LEFTARM_L4[traitNumber - 1];
        } else if(level == 5) {
            return call(sources[9], abi.encodeWithSignature(string(abi.encodePacked("L5LeftArm", Strings.toString(traitNumber-1), "()")), ""));
            // string[9] memory LEFTARM_L5 =  leftArm5.LeftArmL5();
            // return LEFTARM_L5[traitNumber - 1];
        } else {
            return "";
        }
    }

    function zombieRightArmTraitCount(uint8 level) public pure returns (uint8) { 
        if(level == 1) return 15;
        else if(level == 2) return 6;
        else if(level == 3) return 8;
        else if(level == 4) return 9;
        else if(level == 5) return 7;
        else return 0;
    }
    function zombieRightArmTrait(uint8 level, uint8 traitNumber) public pure returns (string memory) {
        if(level > 0 && level <= 5 && zombieRightArmTraitCount(level) > 0) {
            return traitName(level, traitNumber, " Right Arm ");
        } else {
            return "";
        }
    }
    function zombieRightArmSVG(uint8 level, uint8 traitNumber) public view returns(string memory) {
       // Credit to EtherOrcs for being the OG pioneers in the on-chain gaming space and their code that made this game possible.
        if(level == 1) {
            return call(sources[15], abi.encodeWithSignature(string(abi.encodePacked("L1RightArm", Strings.toString(traitNumber-1), "()")), ""));
            // string[15] memory RIGHTARM_L1 = rightArm1.RightArmL1();
            // return RIGHTARM_L1[traitNumber - 1];
        } else if(level == 2) {
            return call(sources[16], abi.encodeWithSignature(string(abi.encodePacked("L2RightArm", Strings.toString(traitNumber-1), "()")), ""));
            // string[6] memory RIGHTARM_L2 = rightArm2.RightArmL2();
            // return RIGHTARM_L2[traitNumber - 1];
        } else if(level == 3) {
            return call(sources[17], abi.encodeWithSignature(string(abi.encodePacked("L3RightArm", Strings.toString(traitNumber-1), "()")), ""));
            // string[8] memory RIGHTARM_L3 = rightArm3.RightArmL3();
            // return RIGHTARM_L3[traitNumber - 1];
        } else if(level == 4) {
            return call(sources[18], abi.encodeWithSignature(string(abi.encodePacked("L4RightArm", Strings.toString(traitNumber-1), "()")), ""));
            // string[9] memory RIGHTARM_L4 = rightArm4.RightArmL4();
            // return RIGHTARM_L4[traitNumber - 1];
        } else if(level == 5) {
            return call(sources[19], abi.encodeWithSignature(string(abi.encodePacked("L5RightArm", Strings.toString(traitNumber-1), "()")), ""));
            // string[7] memory RIGHTARM_L5 = rightArm5.RightArmL5();
            // return RIGHTARM_L5[traitNumber - 1];
        } else {
            return "";
        }
    }

    function zombieLegsTraitCount(uint8 level) public pure returns (uint8) { 
        if(level == 1) return 12;
        else if(level == 2) return 12;
        else if(level == 3) return 8;
        else if(level == 4) return 10;
        else if(level == 5) return 9;
        else return 0;
    }
    function zombieLegsTrait(uint8 level, uint8 traitNumber) public pure returns (string memory) {
        if(level > 0 && level <= 5 && zombieLegsTraitCount(level) > 0) {
            return traitName(level, traitNumber, " Legs ");
        } else {
            return "";
        }
    }
    function zombieLegsSVG(uint8 level, uint8 traitNumber) public view returns(string memory) {
       // Credit to EtherOrcs for being the OG pioneers in the on-chain gaming space and their code that made this game possible.
        if(level == 1) {
            return call(sources[10], abi.encodeWithSignature(string(abi.encodePacked("L1Leg", Strings.toString(traitNumber-1), "()")), ""));
            // string[12] memory LEGS_L1 = leg1.LegL1();
            // return LEGS_L1[traitNumber - 1];
        } else if(level == 2) {
            return call(sources[11], abi.encodeWithSignature(string(abi.encodePacked("L2Leg", Strings.toString(traitNumber-1), "()")), ""));
            // string[12] memory LEGS_L2 = leg2.LegL2();
            // return LEGS_L2[traitNumber - 1];
        } else if(level == 3) {
            return call(sources[12], abi.encodeWithSignature(string(abi.encodePacked("L3Leg", Strings.toString(traitNumber-1), "()")), ""));
            // string[8] memory LEGS_L3 = leg3.LegL3();
            // return LEGS_L3[traitNumber - 1];
        } else if(level == 4) {
            return call(sources[13], abi.encodeWithSignature(string(abi.encodePacked("L4Leg", Strings.toString(traitNumber-1), "()")), ""));
            // string[10] memory LEGS_L4 = leg4.LegL4();
            // return LEGS_L4[traitNumber - 1];
        } else if(level == 5) {
            return call(sources[14], abi.encodeWithSignature(string(abi.encodePacked("L5Leg", Strings.toString(traitNumber-1), "()")), ""));
            // string[9] memory LEGS_L5 = leg5.LegL5();
            // return LEGS_L5[traitNumber - 1];
        } else {
            return "";
        }
    }

    function zombieHeadTraitCount(uint8 level) public pure returns (uint8) { 
        if(level == 1) return 16;
        else if(level == 2) return 10;
        else if(level == 3) return 11;
        else if(level == 4) return 9;
        else if(level == 5) return 10;
        else return 0;
    }
    function zombieHeadTrait(uint8 level, uint8 traitNumber) public pure returns (string memory) {
        if(level > 0 && level <= 5 && zombieHeadTraitCount(level) > 0) {
            return traitName(level, traitNumber, " Head ");
        } else {
            return "";
        }
    }
    function zombieHeadSVG(uint8 level, uint8 traitNumber) public view returns(string memory) {
        // Credit to EtherOrcs for being the OG pioneers in the on-chain gaming space and their code that made this game possible.
        if(level == 1) {
            return call(sources[0], abi.encodeWithSignature(string(abi.encodePacked("L1Head", Strings.toString(traitNumber-1), "()")), ""));
            // string[16] memory HEAD_L1 = head1.HeadL1();
            // return HEAD_L1[traitNumber - 1];
        } else if(level == 2) {
            return call(sources[1], abi.encodeWithSignature(string(abi.encodePacked("L2Head", Strings.toString(traitNumber-1), "()")), ""));
            // string[10] memory HEAD_L2 = head2.HeadL2();
            // return HEAD_L2[traitNumber - 1];
        } else if(level == 3) {
            return call(sources[2], abi.encodeWithSignature(string(abi.encodePacked("L3Head", Strings.toString(traitNumber-1), "()")), ""));
            // string[11] memory HEAD_L3 = head3.HeadL3();
            // return HEAD_L3[traitNumber - 1];
        } else if(level == 4) {
            return call(sources[3], abi.encodeWithSignature(string(abi.encodePacked("L4Head", Strings.toString(traitNumber-1), "()")), ""));
            // string[9] memory HEAD_L4 = head4.HeadL4();
            // return HEAD_L4[traitNumber - 1];
        } else if(level == 5) {
            return call(sources[4], abi.encodeWithSignature(string(abi.encodePacked("L5Head", Strings.toString(traitNumber-1), "()")), ""));
            // string[10] memory HEAD_L5 = head5.HeadL5();
            // return HEAD_L5[traitNumber - 1];
        } else {
            return "";
        }
    }

    function zombieTrait(ZombieTrait trait, uint8 level, uint8 traitNumber) public pure returns (string memory) {
        if(trait == ZombieTrait.Torso) return zombieTorsoTrait(level, traitNumber);
        else if(trait == ZombieTrait.LeftArm) return zombieLeftArmTrait(level, traitNumber);
        else if(trait == ZombieTrait.RightArm) return zombieRightArmTrait(level, traitNumber);
        else if(trait == ZombieTrait.Legs) return zombieLegsTrait(level, traitNumber);
        else if(trait == ZombieTrait.Head) return zombieHeadTrait(level, traitNumber);
        else return "None";
    }

    function zombieSVG(uint8 level, uint8[] memory traits) public view returns (bytes memory) {
        string memory torsoSVG = zombieTorsoSVG(level, traits[0]);
        string memory leftArmSVG = zombieLeftArmSVG(level, traits[1]);
        string memory rightArmSVG = zombieRightArmSVG(level, traits[2]);
        string memory legsSVG = zombieLegsSVG(level, traits[3]);
        string memory headSVG = zombieHeadSVG(level, traits[4]);
        bytes32 empty = keccak256(abi.encodePacked(""));
        string memory newtorsoSVG;
        string memory newleftArmSVG;
        string memory newrightArmSVG;
        string memory newlegsSVG;
        string memory newheadSVG;
        if(keccak256(abi.encodePacked(torsoSVG))!= empty){
            newtorsoSVG = string(
                abi.encodePacked(
                    '<image x="1" y="1" width="70" height="70" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
            torsoSVG,
            '"/>'));
        }
        if(keccak256(abi.encodePacked(leftArmSVG))!=empty){
            newleftArmSVG = string(
                abi.encodePacked(
                    '<image x="1" y="1" width="70" height="70" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
            leftArmSVG,
            '"/>'));
        }
        if(keccak256(abi.encodePacked(rightArmSVG))!=empty){
            newrightArmSVG = string(
                abi.encodePacked(
                    '<image x="1" y="1" width="70" height="70" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
            rightArmSVG,
            '"/>'));
        }
        if(keccak256(abi.encodePacked(legsSVG))!=empty){
            newlegsSVG = string(
                abi.encodePacked(
                    '<image x="1" y="1" width="70" height="70" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
            legsSVG,
            '"/>'));
        }
        if(keccak256(abi.encodePacked(headSVG))!=empty){
            newheadSVG = string(
                abi.encodePacked(
                    '<image x="1" y="1" width="70" height="70" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
            headSVG,
            '"/>'));
        }
        return bytes(
            abi.encodePacked(
                '<svg id="zombie" width="100%" height="100%" version="1.1" viewBox="0 0 70 70" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                newtorsoSVG,
                newleftArmSVG,
                newrightArmSVG,
                newlegsSVG,
                newheadSVG,
                '<style>#zombie{shape-rendering: crispedges; image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;}</style>',
                '</svg>'
            )
        );
    }
}