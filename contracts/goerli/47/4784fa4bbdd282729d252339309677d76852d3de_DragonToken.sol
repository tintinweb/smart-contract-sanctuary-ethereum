// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract DragonToken is ERC721, Ownable{

    struct Dragon {
        uint8 skill;  // 스킬
        uint8 property; // 속성
        uint8 individual; // 개체
        uint8 rarity; // 등급
    }
    
    

    bool public Material = true;

    Dragon[] public dragons; // default: [] 
    mapping (uint256 => uint256) public mspcnt;
    

    constructor (string memory _name, string memory _symbol) 
        ERC721(_name, _symbol){}



    function _createRandomSkill(uint256 _mod, uint256 cardId) internal view returns (uint256) {
        uint256 randomNum = uint256(keccak256(abi.encodePacked(block.timestamp, tx.origin, _mod, cardId)));
        return randomNum % _mod;
    }

    function _createRandomProperty(uint256 _mod, uint256 cardId) internal view returns (uint256) {
        uint256 randomNum = uint256(keccak256(abi.encodePacked(block.timestamp, _mod, cardId)));
        return randomNum % _mod;
    }

    function _createRandomIndividual(uint256 _mod, uint256 cardId) internal view returns (uint256) {
        uint256 randomNum = uint256(keccak256(abi.encodePacked(block.timestamp, _mod, cardId)));
            if (randomNum > 100) {
            return (randomNum - 100) % _mod;
        } else {
            return randomNum % _mod;
        }
    }


    function _createRandomRarity(uint256 _mod, uint256 cardId) internal view returns (uint256) {
        uint256 randomNum = uint256(keccak256(abi.encodePacked(block.timestamp, _mod, tx.origin, cardId)));
        
        if (randomNum > 100) {
            return (randomNum - 100) % _mod;
        } else {
            return randomNum % _mod;
        }
    }

    function burn(uint256 cardId) public onlyOwner{
        _burn(cardId);
    }

    function setMaterial(bool _Material) external onlyOwner{
        Material = _Material;
    }

        // msp cnt update 
    function ViewerMSPCNT(uint256 cardId) public view returns (uint256 msp){
        
        msp = mspcnt[cardId];
        
    }

    // create
    function mint(uint256 sSParam, uint256 sIParam, uint256 sPParam, uint256 sRParm, address account) public onlyOwner {
        uint256 cardId = dragons.length;
        uint8 Skill = uint8(_createRandomSkill(sSParam, cardId));
        uint8 Property = uint8(_createRandomProperty(sPParam, cardId));
        uint8 Individual = uint8(_createRandomIndividual(sIParam, cardId));
        uint8 Rarity = uint8(_createRandomRarity(sRParm, cardId));
        dragons.push(Dragon(Skill, Property, Individual, Rarity));
        mspcnt[cardId] = 0;
        _mint(account, cardId);
        
        cardId++;
    }

    
    
    function LevelUP_MSP(address MSPContract, uint amount, uint tokenId) public returns(bool){
        IERC20 MSPToken = IERC20(MSPContract);
        require(MSPToken.balanceOf(msg.sender) > 1000*10**18, "NEED 1000 MSP! ");
        require(MSPToken.approve(msg.sender, amount));

        MSPToken.transferFrom(msg.sender, owner(), amount); 

        // nft.safeTransferFrom(address(this), msg.sender, tokenId);
        mspcnt[tokenId] += 1;
        
        return true;
    }

}