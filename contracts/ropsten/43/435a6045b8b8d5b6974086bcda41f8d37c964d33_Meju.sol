/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.12;

contract Meju {
    uint256[][] partsMatrix;
    uint256 maxArmorParts = 6;
    uint256 maxProb = 100;

    function setPartsMatrix(uint256[][] memory parts) public {
        partsMatrix = parts;
    }

    function getPartsMatrix() public view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory) {
        return (partsMatrix[0], partsMatrix[1], partsMatrix[2], partsMatrix[3], partsMatrix[4], partsMatrix[5]);
    }

    function random(uint256 nonce) internal view returns (uint256) {
        uint256 randomNumber = uint256(
            keccak256(abi.encodePacked(block.difficulty, block.timestamp, nonce))
        );

        return randomNumber;
    }

    function getRandomOriginGene() public view returns (uint256) {
        uint256 tempNonce = uint256(
            keccak256(abi.encodePacked('2'))
        );

        uint256[6][3] memory randomedParts;
        // uint256 randomRandom;

        for (uint8 i = 0; i < 3; i++) {
            for (uint8 j = 0; j < 6; j++) {
                for (uint256 k = 0; k < partsMatrix[j].length; k++) {
                    tempNonce++;
                    if ((random(tempNonce) % maxProb) < partsMatrix[j][k]) {
                        randomedParts[i][j] = k;
                        break;
                    }
                }
            }
        }

        uint256 randomClass = random(tempNonce) % 6;

        uint256 veryRandomGene = generateGene(
        randomedParts[0],
        randomedParts[1],
        randomedParts[2],
        randomClass
        );

        return veryRandomGene;
    }

    function generateGene(
        uint256[6] memory DpartName,
        uint256[6] memory R1PartName,
        uint256[6] memory R2PartName,
        uint256 class
    ) public pure returns (uint256) {
        uint256 gene = 0;

        gene = class << 200; // 8 bits also, we can reduce it to 4 bits or something. Just want to make it 8(No reason why)

        for (uint8 i = 0; i < 6; i++) {
        // shift left 24 bits to get last 8 bits from 32 bits
        // shift left 16 bits to get last 16 bits from 32 bits
        // shift left 8 bits to get last 24 bits from 32 bits
        uint256 result = ((DpartName[i] << (32 * i)) << 24) |
            ((R1PartName[i] << (32 * i)) << 16) |
            ((R2PartName[i] << (32 * i)) << 8);
        gene |= result;
        }

        return gene;
    }

    function parseGene(uint256 gene)
        public
        pure
        returns (
            uint256[] memory DPart,
            uint256[] memory R1Part,
            uint256[] memory R2Part,
            uint256 class
        )
    {
        uint256[] memory DpartNamePart = new uint256[](6);
        uint256[] memory R1partNamePart = new uint256[](6);
        uint256[] memory R2partNamePart = new uint256[](6);

        for (uint256 i = 0; i < 6; i++) {
        // shift right 24 to get 8 bits from the last of the first 32 bits,
        // still will get some amount of bits because we have 4 parts
        // & with 0xff to make sure we only take the 8 bits
        // and so on
        uint256 DpartName = (gene >> 24) & 0xff;
        uint256 R1partName = (gene >> 16) & 0xff;
        uint256 R2partName = (gene >> 8) & 0xff;

        // continue to parse the next 32 bits of the gene
        // this will make sure that the gene is 32 bits aligned
        gene = gene >> 32;

        DpartNamePart[i] = DpartName;
        R1partNamePart[i] = R1partName;
        R2partNamePart[i] = R2partName;
        }

        class = gene >> 8;
        DPart = DpartNamePart;
        R1Part = R1partNamePart;
        R2Part = R2partNamePart;
    }
}