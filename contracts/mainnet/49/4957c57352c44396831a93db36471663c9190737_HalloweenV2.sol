/**
 *Submitted for verification at Etherscan.io on 2022-11-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Token {
  function balanceOf(address who) external view returns(uint256);
  function transfer(address to, uint256 value) external returns(bool);
}

interface InventoryV2 {
  function ownerOf(uint256 tokenId) external view returns(address);
  function getTemplateIDsByTokenIDs(uint[] memory _tokenIds) external view returns(uint[] memory);
  function burn(uint256 _tokenId) external returns(bool);
  function createFromTemplate(uint256 _templateId, uint8 _feature1, uint8 _feature2, uint8 _feature3, uint8 _feature4, uint8 _equipmentPosition) external returns(uint256);
}

contract HalloweenV1 {
  mapping(address => bool) public vidyans;
}

contract HalloweenV2 {

  // Dev 
  address public dev;

  // Status
  bool public unlocked;

  // Vidyans that have claimed 
  mapping(address => bool) public claimed;

  // Keyholes with keys in them 
  mapping(uint256 => bool) public keys;

  /* TemplateIds that unlock this contract
     61: Blood chalice 
     62: Burnt offering 
     63: Stolen bone 
     64: Manifest
     65: Lock of hair */
  uint256[] public Keys = [61, 62, 63, 64, 65];

  // Template ids of the main prizes
  uint256 public PlagueDoctorMask = 43;
  uint256 public CreditChip = 44;

  // Otherworld armour  
  uint256 public OtherworldArmour = 42;
  uint256 public OtherworldArmourCap = 23;
  uint256 public OtherworldArmourCounter;

  // Additional prize in vidya for keys 
  uint256 public vidya = 10000000000000000000000; // 10k tokens 

  // inventory 
  InventoryV2 inv = InventoryV2(address(0x9680223F7069203E361f55fEFC89B7c1A952CDcc));

  // vidya
  Token token = Token(address(0x3D3D35bb9bEC23b06Ca00fe472b50E7A4c692C30));

  // Old halloween contract 
  HalloweenV1 halloween = HalloweenV1(address(0xf9360e25F4f47a0de4b456C9DB55F7A953b819dB));

  // Check if keys fall in the correct range 
  modifier onlyKey(uint256 _tokenId) {
    require(_templateId(_tokenId) > Keys[0] - 1 && _templateId(_tokenId) < Keys[4] + 1, "Not the right key.");
    _;
  }

  // Check if contract is unlocked 
  modifier onlyUnlocked() {
    require(unlocked, "Not unlocked.");
    _;
  }

  // Check if msg.sender is a vidyan on HalloweenV1 contract 
  modifier onlyVidyan() {
    require(halloween.vidyans(msg.sender), "Not a vidyan.");
    _;
  }

  // Check if msg.sender has not claimed 
  modifier notClaimed() {
    require(!claimed[msg.sender], "Already claimed.");
    _;
  }

  // Check if dev 
  modifier onlyDev() {
    require(msg.sender == dev, "Not the dev.");
    _;
  }

  constructor() {
    dev = msg.sender;
    // Add the found keys 
    keys[62] = true; // Burnt offering 
    keys[64] = true; // Manifest 
  }

  // Put the key in the hole 
  function putKey(uint256 _tokenId) external onlyKey(_tokenId) returns(bool) {
    uint256 key = _templateId(_tokenId);
    require(!keys[key], "Key already in place.");
    require(inv.ownerOf(_tokenId) == msg.sender, "Not in possession of the key.");
    require(inv.burn(_tokenId), "InventoryV2: token burn failed.");
    require(token.transfer(msg.sender, vidya), "Token transfer failed. Do we have enough?");
    keys[key] = true;
    return _unlock();
  }

  // Return the templateId of given tokenId from InventoryV2 
  function _templateId(uint256 _tokenId) internal view returns(uint256) {
    uint256[] memory tempArray = new uint256[](1);
    tempArray[0] = _tokenId;
    uint256[] memory result = inv.getTemplateIDsByTokenIDs(tempArray);
    return result[0];
  }

  // Unlocks the contract when all keys are set 
  function _unlock() internal returns(bool) {
    if (keys[Keys[0]] && keys[Keys[1]] && keys[Keys[2]] && keys[Keys[3]] && keys[Keys[4]]) {
      unlocked = true;
    }
    return unlocked;
  }

  // Vidyans can get spooked
  function getSpooked() external onlyUnlocked onlyVidyan notClaimed {
    claimed[msg.sender] = true;
    if (OtherworldArmourCounter < OtherworldArmourCap) {
      OtherworldArmourCounter++;
      inv.createFromTemplate(OtherworldArmour, 0, 0, 0, 0, 0);
    }
    inv.createFromTemplate(PlagueDoctorMask, 0, 0, 0, 0, 0);
    inv.createFromTemplate(CreditChip, 0, 0, 0, 0, 0);
  }

  // Dev function for withdrawing tokens 
  function withdraw(address _token) external onlyDev {
    Token tok = Token(_token);
    uint256 amount = tok.balanceOf(address(this));
    tok.transfer(dev, amount);
  }

  // UI can view the keys 
  function insertedKeys() external view returns(bool[] memory) {
    bool[] memory temp = new bool[](5);
    for (uint i = 0; i < 5; i++) {
      if (keys[Keys[i]]) {
        temp[i] = true;
      }
    }
    return temp;
  }

}