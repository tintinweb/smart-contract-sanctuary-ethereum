// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./erc721.sol";
import "./safemath.sol";

contract PlantNursery is ERC721 {

    /**
      * ERC 721 implementation
      **/ 

    using SafeMath for uint256;
    mapping (uint => address) plantApprovals;

    function balanceOf(address _owner) external view returns (uint256){
        return ownerPlantCount[_owner];
    }

    function ownerOf(uint _tokenId) external view returns (address){
        return plantToOwner[_tokenId];
    }

    function _transfer(address _from, address _to, uint256 _tokenId) private {
        ownerPlantCount[msg.sender] = ownerPlantCount[msg.sender].sub(1);
        ownerPlantCount[_to] = ownerPlantCount[_to].add(1);
        plantToOwner[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external payable {
        require(plantToOwner[_tokenId] == msg.sender || plantApprovals[_tokenId] == msg.sender);
        // if plant is planted, remove before transfer
        if (plants[_tokenId].planted == true){
            removePlant(_tokenId);
        }
        _transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) external payable {
        plantApprovals[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }

    // To dos:
    // 1. Show metadata: name, ticker, image
    // 2. Create a mint plant function. Costs 0.05 ETH.

    /**
      * Plant Factory
      **/ 

    uint dnaDigits = 16;
    uint dnaModulus = 10 ** dnaDigits;

    uint healthDecayMultiplier = 1;

    struct Plant {
        // string name;
        uint dna;
        bool planted;
        uint256 health;
        uint256 lastHealthBlock;
        uint256 size;
        uint256 lastSizeBlock;
    }

    Plant[] public plants;

    mapping (uint => address) public plantToOwner;
    mapping (address => uint) public ownerPlantCount;
    mapping (address => uint) public maxOwnerPlots;
    mapping (address => uint) public usedOwnerPlots;

    event NewPlant(uint plantId, uint dna);

    function _createPlant(uint _dna) public {
        plants.push(Plant(_dna, false, 100, block.timestamp, 0, 0));
        uint id = plants.length;
        plantToOwner[id] = msg.sender;
        ownerPlantCount[msg.sender]++;
        if (maxOwnerPlots[msg.sender] <= 2) {
            maxOwnerPlots[msg.sender] = 2;
        }
        emit NewPlant(id, _dna);
    }

    function _generateRandomDna() public view returns (uint) {
        uint rand = uint(keccak256(abi.encodePacked(block.timestamp)));
        return rand % dnaModulus;
    }

    function createRandomPlant() public {
        // Can buy as many as you want, just can't plant more than you have slots
        uint randDna = _generateRandomDna();
        randDna = randDna - randDna % 100;
        _createPlant(randDna);
    }

    /**
      * Gardening Section
      **/ 
    function plantPlant(uint _id) public {
        require(msg.sender == plantToOwner[_id] && (usedOwnerPlots[msg.sender] < maxOwnerPlots[msg.sender]));
        plants[_id].planted = true;
        usedOwnerPlots[msg.sender]++;
        plants[_id].health = plants[_id].health - ((uint(block.timestamp) - plants[_id].lastHealthBlock) * healthDecayMultiplier);
        plants[_id].lastHealthBlock = block.timestamp;
        plants[_id].lastSizeBlock = block.number;
    }

    function removePlant(uint _id) public {
        require(msg.sender == plantToOwner[_id]);
        plants[_id].planted = false;
        usedOwnerPlots[msg.sender]--;
        plants[_id].health = plants[_id].health - ((block.timestamp - plants[_id].lastHealthBlock));
        plants[_id].lastHealthBlock = block.timestamp;
        plants[_id].size = plants[_id].size + (block.number - plants[_id].lastHealthBlock);
    }

    function waterPlants(uint _id) public {
        // Checks
        require(msg.sender == plantToOwner[_id] && plants[_id].planted == true);

        // Resets Health
        plants[_id].health = 100;
        plants[_id].lastHealthBlock = block.timestamp;

        // Plant growth
        plants[_id].size = plants[_id].size + (block.number - plants[_id].lastHealthBlock);
        plants[_id].lastHealthBlock = block.number;
    }

    /** 
      * Status Checks
      **/ 
    function getHealth(uint _id) public view returns (uint256) {
        if (plants[_id].planted == true) {
            return plants[_id].health - ((block.timestamp - plants[_id].lastHealthBlock) * healthDecayMultiplier);
        } else {
            return plants[_id].health - ((block.timestamp - plants[_id].lastHealthBlock) * 2);
        }
    }

    function getSize(uint _id) public view returns (uint256) {
        if (plants[_id].planted == true) {
            return plants[_id].size + (block.number - plants[_id].lastHealthBlock);
        } else {
            return plants[_id].size;
        }
    }

    // function getSize() public {}

}