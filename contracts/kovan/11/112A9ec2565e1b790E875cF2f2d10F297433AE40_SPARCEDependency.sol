/**
 *Submitted for verification at Etherscan.io on 2022-04-27
*/

pragma solidity 0.8.4;
//SPDX-License-Identifier: UNLICENSED

interface SPARCESpawningManager {
	function isSpawningAllowed(uint256 _genes, address _owner) external returns (bool);
  function isRebirthAllowed(uint256 _sparceId, uint256 _genes) external returns (bool);
}

interface SPARCERetirementManager {
  function isRetirementAllowed(uint256 _sparceId, bool _rip) external returns (bool);
}

interface SPARCEMarketplaceManager {
  function isTransferAllowed(address _from, address _to, uint256 _sparceId) external returns (bool);
}

interface SPARCEGeneManager {
  function isEvolvementAllowed(uint256 _sparceId, uint256 _newGenes) external returns (bool);
}


contract SPARCEDependency {

  address public whitelistSetterAddress;

  SPARCESpawningManager public spawningManager;
  SPARCERetirementManager public retirementManager;
  SPARCEMarketplaceManager public marketplaceManager;
  SPARCEGeneManager public geneManager;

  mapping (address => bool) public whitelistedSpawner;
  mapping (address => bool) public whitelistedByeSayer;
  mapping (address => bool) public whitelistedMarketplace;
  mapping (address => bool) public whitelistedGeneScientist;

  constructor() {
    whitelistSetterAddress = msg.sender;
  }

  modifier onlyWhitelistSetter() {
    require(msg.sender == whitelistSetterAddress);
    _;
  }

  modifier whenSpawningAllowed(uint256 _genes, address _owner) {
    require(
      address(spawningManager) == address(0) ||
        spawningManager.isSpawningAllowed(_genes, _owner)
    );
    _;
  }

  modifier whenRebirthAllowed(uint256 _sparceId, uint256 _genes) {
    require(
      address(spawningManager) == address(0) ||
        spawningManager.isRebirthAllowed(_sparceId, _genes)
    );
    _;
  }

  modifier whenRetirementAllowed(uint256 _sparceId, bool _rip) {
    require(
      address(retirementManager) == address(0) ||
        retirementManager.isRetirementAllowed(_sparceId, _rip)
    );
    _;
  }

  modifier whenTransferAllowed(address _from, address _to, uint256 _sparceId) {
    require(
      address(marketplaceManager) == address(0) ||
        marketplaceManager.isTransferAllowed(_from, _to, _sparceId)
    );
    _;
  }

  modifier whenEvolvementAllowed(uint256 _sparceId, uint256 _newGenes) {
    require(
      address(geneManager) == address(0) ||
        geneManager.isEvolvementAllowed(_sparceId, _newGenes)
    );
    _;
  }

  modifier onlySpawner() {
    require(whitelistedSpawner[msg.sender]);
    _;
  }

  modifier onlyByeSayer() {
    require(whitelistedByeSayer[msg.sender]);
    _;
  }

  modifier onlyMarketplace() {
    require(whitelistedMarketplace[msg.sender]);
    _;
  }

  modifier onlyGeneScientist() {
    require(whitelistedGeneScientist[msg.sender]);
    _;
  }

  /*
   * @dev Setting the whitelist setter address to `address(0)` would be a irreversible process.
   *  This is to lock changes to SPARC-E's contracts after their development is done.
   */
  function setWhitelistSetter(address _newSetter) external onlyWhitelistSetter {
    whitelistSetterAddress = _newSetter;
  }

  function setSpawningManager(address _manager) external onlyWhitelistSetter {
    spawningManager = SPARCESpawningManager(_manager);
  }

  function setRetirementManager(address _manager) external onlyWhitelistSetter {
    retirementManager = SPARCERetirementManager(_manager);
  }

  function setMarketplaceManager(address _manager) external onlyWhitelistSetter {
    marketplaceManager = SPARCEMarketplaceManager(_manager);
  }

  function setGeneManager(address _manager) external onlyWhitelistSetter {
    geneManager = SPARCEGeneManager(_manager);
  }

  function setSpawner(address _spawner, bool _whitelisted) external onlyWhitelistSetter {
    require(whitelistedSpawner[_spawner] != _whitelisted);
    whitelistedSpawner[_spawner] = _whitelisted;
  }

  function setByeSayer(address _byeSayer, bool _whitelisted) external onlyWhitelistSetter {
    require(whitelistedByeSayer[_byeSayer] != _whitelisted);
    whitelistedByeSayer[_byeSayer] = _whitelisted;
  }

  function setMarketplace(address _marketplace, bool _whitelisted) external onlyWhitelistSetter {
    require(whitelistedMarketplace[_marketplace] != _whitelisted);
    whitelistedMarketplace[_marketplace] = _whitelisted;
  }

  function setGeneScientist(address _geneScientist, bool _whitelisted) external onlyWhitelistSetter {
    require(whitelistedGeneScientist[_geneScientist] != _whitelisted);
    whitelistedGeneScientist[_geneScientist] = _whitelisted;
  }
}