// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

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
        // plants[_id].size = plants[_id].size + (block.number - plants[_id].lastHealthBlock);
        // plants[_id].lastHealthBlock = block.number;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title SafeMath32
 * @dev SafeMath library implemented for uint32
 */
library SafeMath32 {

  function mul(uint32 a, uint32 b) internal pure returns (uint32) {
    if (a == 0) {
      return 0;
    }
    uint32 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint32 a, uint32 b) internal pure returns (uint32) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint32 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint32 a, uint32 b) internal pure returns (uint32) {
    assert(b <= a);
    return a - b;
  }

  function add(uint32 a, uint32 b) internal pure returns (uint32) {
    uint32 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title SafeMath16
 * @dev SafeMath library implemented for uint16
 */
library SafeMath16 {

  function mul(uint16 a, uint16 b) internal pure returns (uint16) {
    if (a == 0) {
      return 0;
    }
    uint16 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint16 a, uint16 b) internal pure returns (uint16) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint16 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint16 a, uint16 b) internal pure returns (uint16) {
    assert(b <= a);
    return a - b;
  }

  function add(uint16 a, uint16 b) internal pure returns (uint16) {
    uint16 c = a + b;
    assert(c >= a);
    return c;
  }
}