/**
 *Submitted for verification at Etherscan.io on 2022-12-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract BreedScience 
{
    uint256 private GlobalSeed = 1;
    uint256 private randomSideWeight = 50;
    uint256 private randomIdWeight = 10;
    uint256 private rarityPercent = 100; // 100 == 1%, 10000 == 100%

    uint8 private maxBodyParts = 9; // head,body,left-hand,right-hand,left-foot,right-foot,eyes,mouse,horns
    uint8 private maxId = 37; //1-36 (36 include)

    function encode(uint8[] memory _traits) public pure returns (uint256 _genes) {
       _genes = 0;
        
        for(uint256 i = 0; i < _traits.length; i++) {
            _genes = _genes << 8;
            // bitwise OR trait with _genes
            _genes = _genes | _traits[_traits.length - 1 - i];
        }

        return _genes; 
    }

    function decode(uint256 _genes) public pure returns (uint8[] memory _traits) {
        _traits = new uint8[](27);
        
        for(uint256 i = 0; i < _traits.length; i++) {
            _traits[i] = get8Bits(_genes, i);
        }

        return _traits;
    }

    /// @dev Get a 8 bit slice from an input as a number
    /// @param _input bits, encoded as uint
    /// @param _slot from 0 to 27
    function get8Bits(uint256 _input, uint256 _slot) internal pure returns(uint8) {
        return uint8(sliceNumber(_input, uint256(8), _slot * 8));
    }

    /// @dev given a number get a slice of any bits, at certain offset
    /// @param _n a number to be sliced
    /// @param _nbits how many bits long is the new number
    /// @param _offset how many bits to skip
    function sliceNumber(uint256 _n, uint256 _nbits, uint256 _offset) private pure returns (uint256) {
        // mask is made by shifting left an offset number of times
        uint256 mask = uint256((2**_nbits) - 1) << _offset;
        // AND n with mask, and trim to max of _nbits bits
        return uint256((_n & mask) >> _offset);
    }

    function breading(uint256 genes1, uint256 genes2, uint256 generation) public returns(uint256)
    {
        uint8[] memory _traits1 = decode(genes1);
        uint8[] memory _traits2 = decode(genes2);
        uint8[] memory _newTraits = new uint8[](_traits1.length);
        
        //
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, block.difficulty, genes1, genes2, GlobalSeed))); 
        require(randomSeed != 0, "randomSeed = 0");
        uint256 randomIndex;
        uint8 j = 0;
        uint256 i;
        for (i = 0; i < _traits1.length ; i++)
        {
            uint8 left = _traits1[i];
            uint8 right = _traits2[i];

            // id
            if (j == 0)
            {
                _newTraits[i] = getRandomId(randomSeed, randomIndex, left, right);
                j++;
                randomIndex+=2;
                continue;
            } 

            // level
            if (j == 1)
            {
                _newTraits[i] = 1;
                j++;
                continue;
            }

            _newTraits[i]  = getRarity(randomSeed, randomIndex++, generation);
            j = 0;
            randomIndex++;
            continue;
        }
        
        GlobalSeed++;
        return encode(_newTraits);
    }

    function getRandomId(uint256 randomSeed, uint256 randomIndex, uint8 left, uint8 right) internal view returns (uint8)
    {
        uint256 current = 0;
        uint256 resultIndex = 0;
        uint256 randomWeight = random(randomSeed, randomIndex, 0, totalWeight()); // random value of total weight

        for(uint256 i = 0; i < 3; i++)
        {
            current += weight(i); 
            if(current >= randomWeight)
            {
                resultIndex = i;
                break;
            }
        }

        if (resultIndex == 0) return left;
        if (resultIndex == 1) return right;
        
        return uint8(random(randomSeed, ++randomIndex, 1, maxId)); // 1-36
    }

    function getRarity(uint256 randomSeed, uint256 randomIndex, uint256 generation) internal view returns(uint8) {
        if (generation == 0) return 0;
        uint256 value = generation / rarityPercent; //????????????????????????????

        if (random(randomSeed, randomIndex, 0, 10000) <= value) {
            return 1;
        }
        
        return 0;
    }

    function random(uint256 seed, uint256 index, uint256 minNumber, uint256 maxNumber) internal pure returns (uint256 value) {
        value = uint256(keccak256(abi.encodePacked(seed, index))) % (maxNumber-minNumber);
        value = value + minNumber;
        return value;
    }

    function totalWeight() internal view returns(uint256)
    {
        return randomSideWeight + randomSideWeight + randomIdWeight;
    }

    function weight(uint256 i) internal view returns(uint256)
    {
        return i == 2 ? randomIdWeight : randomSideWeight;
    }

    function testRandom() public returns(uint256[] memory array)
    {
        array = new  uint256[](4);
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, block.difficulty, GlobalSeed))); 
        uint256 randomIndex;

        array[0] = random(randomSeed, randomIndex++, 0, 100);
        array[1] = random(randomSeed, randomIndex++, 0, 100);
        array[2] = random(randomSeed, randomIndex++, 0, 100);
        array[3] = random(randomSeed, randomIndex++, 0, 100);

        GlobalSeed++;

        return array;
    }
}