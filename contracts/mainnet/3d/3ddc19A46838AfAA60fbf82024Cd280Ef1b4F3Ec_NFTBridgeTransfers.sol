/**
 *Submitted for verification at Etherscan.io on 2023-01-18
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

interface INFTBridgeLog {
  function outgoing(address _wallet, uint256 _assetId, uint256 _chainID, uint256 _bridgeIndex) external;
  function incoming(address _wallet, uint256 _assetId, uint256 _chainID, uint256 _logIndex, bytes32 txHash, bool _minted) external;
}

interface INFTToken {
  function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IPC3DUpgrader {
  function getTokenDetails(uint256 index) external view returns (uint32 aType, uint32 customDetails, uint32 lastTx, uint32 lastPayment, uint256 initialvalue, uint32 upgrades, uint32 gDetails, bool leased);
}

contract NFTBridgeTransfers is Managed {

  INFTBridgeLog logger;
  address public nftVault;
  INFTToken public NFT3DContract;
  INFTToken public NFT2DContract;
  IPC3DUpgrader upgrader;
  uint256 public depositIndex;
  bool public paused;
  
  struct Deposit {
    address sender;
    uint256 assetId;
    uint256 value;
    uint32 lastTx;
    uint32 lastPayment;
    uint32 aType;
    uint32 customDetails;
    uint32 upgrades;
    uint32 gDetails;
  } 
  
  mapping (uint256 => Deposit) public deposits;
  mapping (uint256 => bool) public chains;
  
  constructor() {
    NFT3DContract = INFTToken(0xB20217bf3d89667Fa15907971866acD6CcD570C8);
    NFT2DContract = INFTToken(0x57E9a39aE8eC404C08f88740A9e6E306f50c937f);
    upgrader = IPC3DUpgrader(0x2a34c7942C92d2b2f43807225C36fb6763dC0b60);
    logger = INFTBridgeLog(0x2Ec9BA7B80b1aD442390B4fDf735a2BBA061E803);
    managers[0x00d6E1038564047244Ad37080E2d695924F8515B] = true;
    nftVault = 0xf7A9F6001ff8b499149569C54852226d719f2D76;
    chains[56] = true;
    chains[112358] = true;
    depositIndex = 1;
  }

  function bridgeSend(uint256 _assetId, uint256 _chainTo) public returns (bool) {
    require(!paused, "Contract is paused");
    require(chains[_chainTo] == true, "Invalid chain");
    deposits[depositIndex] = fetchData(_assetId);
    if (_assetId >= (1 ether)) {
      NFT2DContract.safeTransferFrom(msg.sender, nftVault, (_assetId/(1 ether)));
    } else {
      NFT3DContract.safeTransferFrom(msg.sender, nftVault, _assetId);
    }
    logger.outgoing(msg.sender, _assetId, _chainTo, depositIndex);
    depositIndex += 1;
    return true;
  }

  function fetchData(uint256 _assetId) private view returns(Deposit memory _deposit) {
    (uint32 aType, uint32 customDetails, uint32 lastTx, uint32 lastPayment, uint256 initialvalue, uint32 upgrades, uint32 gDetails, ) = upgrader.getTokenDetails(_assetId);
    _deposit = Deposit(msg.sender, _assetId, initialvalue, lastTx, lastPayment, aType, customDetails, upgrades, gDetails);
  }
  
  function pauseBridge(bool _paused) public onlyManagers {
    paused = _paused;
  }

  function setNFTVault(address _vault) public onlyManagers {
    nftVault = _vault;
  }

  function setChain(uint256 _chain, bool _available) public onlyManagers {
    chains[_chain] = _available;
  }

  function setLogger (address _logger) public onlyManagers {
    logger = INFTBridgeLog(_logger);
  }
    
}