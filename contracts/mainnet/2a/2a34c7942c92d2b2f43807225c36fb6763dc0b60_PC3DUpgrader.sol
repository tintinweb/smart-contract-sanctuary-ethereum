/**
 *Submitted for verification at Etherscan.io on 2023-01-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Managed {
  mapping(address => bool) public managers;
  modifier onlyManagers() {
    require(managers[msg.sender] == true, "Caller is not manager");
    _;
  }
  constructor() {
    managers[msg.sender] = true;
  }
  function setManager(address _wallet, bool _manager) public onlyManagers {
    require(_wallet != msg.sender, "Not allowed");
    managers[_wallet] = _manager;
  }
}

interface INFT2D {
  function balanceOf(address _owner) external view returns (uint256);
  function tokenOfOwnerByIndex(address _owner, uint256 index) external view returns (uint256);
  function getTokenDetails(uint256 index) external view returns (uint128 lastvalue, uint32 aType, uint32 customDetails, uint32 lastTx, uint32 lastPayment);
  function minters(address _minter) external returns(bool);
}

interface INFT3D {
  function balanceOf(address _owner) external view returns (uint256);
  function tokenOfOwnerByIndex(address _owner, uint256 index) external view returns (uint256);
  function getTokenDetails(uint256 index) external view returns (uint32 aType, uint32 customDetails, uint32 lastTx, uint32 lastPayment, uint256 initialvalue, string memory coin);
  function minters(address _minter) external returns(bool);
}
contract PC3DUpgrader is Managed {
  struct assetDetail {
    uint32 upgrades;
    uint32 gDetails;
  }

  mapping(uint256=>assetDetail) assets;
  INFT2D nft2D;
  INFT3D nft3D;

  constructor() {
    nft2D = INFT2D(0x57E9a39aE8eC404C08f88740A9e6E306f50c937f);
    nft3D = INFT3D(0xB20217bf3d89667Fa15907971866acD6CcD570C8);
  }

  function getTokenDetails(uint256 index) public view returns (uint32 aType, uint32 customDetails, uint32 lastTx, uint32 lastPayment, uint256 initialvalue, uint32 upgrades, uint32 gDetails, bool leased) {
    if (index >= (1 ether)) {
      (aType, customDetails, lastTx, lastPayment, initialvalue) = get2D((index/(1 ether)));
      customDetails = aType + 1000000000;
    } else {
      (aType, customDetails, lastTx, lastPayment, initialvalue) = get3D(index);
    }
      upgrades = assets[index].upgrades;
      gDetails = assets[index].gDetails;
      leased = false;
  }

  function get2D(uint256 index) private view returns (uint32 aType, uint32 customDetails, uint32 lastTx, uint32 lastPayment, uint256 initialvalue) {
    (initialvalue, aType, customDetails, lastTx, lastPayment) = nft2D.getTokenDetails(index);
  }

  function get3D(uint256 index) private view returns (uint32 aType, uint32 customDetails, uint32 lastTx, uint32 lastPayment, uint256 initialvalue) {
    (aType, customDetails, lastTx, lastPayment, initialvalue, ) = nft3D.getTokenDetails(index);
  }

  function setUpgrades(uint256 index, uint32 _upgrades) public {
    require (nft3D.minters(msg.sender) == true || managers[msg.sender] == true, "Invalid caller");
    assets[index].upgrades = _upgrades;
  }

  function setGameDetails(uint256 index, uint32 _details) public {
    require (nft3D.minters(msg.sender) == true || managers[msg.sender] == true, "Invalid caller");
    assets[index].gDetails = _details;
  }

  function getBalance(address _owner) public view returns (uint256) {
    return(nft3D.balanceOf(_owner)+nft2D.balanceOf(_owner));
  }

  function tokenOfOwnerByIndex(address _owner, uint256 index) public view returns (uint256) {
    uint256 n3db = nft3D.balanceOf(_owner);
    if (index > (n3db-1))  {
      return((nft2D.tokenOfOwnerByIndex(_owner, (index-n3db)) * 1 ether));
    } else {
      return(nft3D.tokenOfOwnerByIndex(_owner, index));
    }
  }

}