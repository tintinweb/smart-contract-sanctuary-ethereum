/**
 *Submitted for verification at Etherscan.io on 2023-03-19
*/

// SPDX-License-Identifier: UNLICENSED

/**
 * @title NTP Collabs Minter
 * @author 0xSumo 
 */

pragma solidity ^0.8.0;

abstract contract OwnControll {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    address public owner;
    mapping(address => bool) public admin;
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner");_; }
    modifier onlyAdmin { require(admin[msg.sender], "Not Admin"); _; }
    function setAdmin(address address_, bool bool_) external onlyOwner { admin[address_] = bool_; }
    function transferOwnership(address new_) external onlyOwner { address _old = owner; owner = new_; emit OwnershipTransferred(_old, new_); }
}

abstract contract MerkleProof {
    bytes32 internal _merkleRoot;
    function _setMerkleRoot(bytes32 merkleRoot_) internal virtual { _merkleRoot = merkleRoot_; }
    function isWhitelisted(address address_, bytes32[] memory proof_) public view returns (bool) {
        bytes32 _leaf = keccak256(abi.encodePacked(address_));
        for (uint256 i = 0; i < proof_.length; i++) {
            _leaf = _leaf < proof_[i] ? keccak256(abi.encodePacked(_leaf, proof_[i])) : keccak256(abi.encodePacked(proof_[i], _leaf));
        }
        return _leaf == _merkleRoot;
    }
}

interface iToken { function mintToken(address to, uint256 id, uint256 amount, bytes memory data) external; }

contract Minter is OwnControll, MerkleProof {

    iToken public Token = iToken(0x68607266e9118B971901239891e6280a8066fCEb);

    uint256 public activeTime = 1679227200;
    uint256 public numberOfToken;
    uint256 public constant TOKEN_ID = 6;
    uint256 public mintPrice = 0.022 ether;
    mapping(address => bool) public minter;
    mapping(address => uint256) private minted;
    modifier onlyMinter { require(minter[msg.sender], "Not Minter"); _; }
    modifier onlySender { require(msg.sender == tx.origin, "No smart contract");_; }

    function mintMany(bytes32[] memory proof_, bytes memory data) external payable onlySender {
        require(block.timestamp >= activeTime, "Inactive");
        require(isWhitelisted(msg.sender, proof_), "You are not whitelisted!");
        require(minted[msg.sender] == 0, "Exceed max per addy and tx");
        require(msg.value == mintPrice, "Value sent is not correct");
        require(numberOfToken < 100, "Exceed max token");

        numberOfToken++;
        minted[msg.sender]++;
        Token.mintToken(msg.sender, TOKEN_ID, 1, data);
    }

    function mintManyRest(bytes memory data) external payable onlyMinter {
        require(minted[msg.sender] == 0, "Exceed max per addy and tx");
        require(msg.value == mintPrice, "Value sent is not correct");
        require(numberOfToken < 100, "Exceed max token");

        numberOfToken++;
        minted[msg.sender]++;
        Token.mintToken(msg.sender, TOKEN_ID, 1, data);
    }

    function setMinter(address address_, bool bool_) external onlyAdmin { 
        minter[address_] = bool_; 
    }

    function setPrice(uint256 price_) public onlyAdmin { 
        mintPrice = price_; 
    }

    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        _setMerkleRoot(merkleRoot_);
    }

    function setActiveTime(uint256 time_) public onlyOwner { 
        activeTime = time_; 
    }
    
    function withdraw() public onlyAdmin {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}