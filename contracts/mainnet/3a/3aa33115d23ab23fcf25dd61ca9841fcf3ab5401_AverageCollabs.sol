// SPDX-License-Identifier: MIT

// Average Collabs by Average Creatures

pragma solidity ^0.8.2;

import "./ERC1155.sol";
import "./ERC1155Burnable.sol";
import "./Ownable.sol";
import "./Strings.sol";

abstract contract CollectionContract {
   function balanceOf(address owner) external virtual view returns (uint256 balance);
   function ownerOf(uint256 tokenId) public virtual view returns (address tokenOwner);
}

contract AverageCollabs is ERC1155, ERC1155Burnable, Ownable {
  
  using Strings for uint256;
  string public uriSuffix = ".json";
  mapping(address => uint256) public claimedList;
  bool public paused = true;
  bool public overdrive = false;

  uint256[] public _currentTokens;
  uint256 public _toLoop = 0;
  uint256 public _week = 0;
  uint256 public holderCost;
  uint256 public publicCost;
  uint256 public collabCost;
  address public guestContract;
  CollectionContract private _avgcreatures = CollectionContract(0xbB00B6B675b9a8Db9aA3b68Bf0aAc5e25f901656);
  CollectionContract private _collabContract;


  constructor(string memory uri_, uint256 _holderCost, uint256 _publicCost, uint256 _collabCost) ERC1155(uri_) {
    holderCost = _holderCost;
    publicCost = _publicCost;
    collabCost = _collabCost;
  }

  // Bouncer
  modifier claimCompliance() {
    require(!paused, "Average Token Claim is paused.");
    require(claimedList[msg.sender] != _week, "This wallet already claimed.");
    _;
  }

  // Paywall
  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= calculateCost(msg.sender) * _mintAmount, "Insufficient funds!");
    _;
  }

  // Tiered Cost
  function calculateCost(address addy) public view returns (uint256) {
    if (_collabContract.balanceOf(addy) > 0) {
      return collabCost;
    } else if (_avgcreatures.balanceOf(addy) > 0) {
      return holderCost;
    }
    return publicCost;
  }

  // Claim your Tokens!
  function averageClaim(uint256 _mintAmount) public payable claimCompliance() mintPriceCompliance(_mintAmount) {
    if (!overdrive) {
      claimedList[msg.sender] = _week;
    }    
    _mint(msg.sender, _currentTokens[_toLoop], 1, '0x0000');
    randomToken();
  }

  // Spread token ID
  function randomToken() internal {
    if (_currentTokens.length > 1) {
      if (_toLoop + 1 > _currentTokens.length - 1) {
        _toLoop = 0;
      } else {
        _toLoop++;
      }
    }
  }

  // Justice for all
  function smallClaimsCourt(
    address[] memory addresses, 
    uint256[] memory ids, 
    uint256[] memory amounts, 
    bytes[] memory data
  ) external onlyOwner {
    uint numWallets = addresses.length;
    require(numWallets == ids.length, "Number of ids need to match number of addresses");
    require(numWallets == amounts.length, "Number of -amounts- need to match number of addresses");

    for (uint i = 0; i < numWallets; i++) {
      _mint(addresses[i], ids[i], amounts[i], data[i]);
    }
  }

  // Update our current Tokens being Claimed
  function updateCurrentTokens(uint256[] memory newTokens) public onlyOwner {
    _currentTokens = newTokens;
    _toLoop = 0;
  }

  // Retrieve URI
  function uri(uint id_) public view override returns (string memory) {
    return string(abi.encodePacked(super.uri(id_), id_.toString(), uriSuffix));
  } 

  // Set new URI prefix
  function setURI(string memory uri_) external onlyOwner {
    _setURI(uri_);
  }

  // Set new URI suffix
  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  // Set current claim week
  function setWeek(uint256 newWeek) public onlyOwner {
    _week = newWeek;
  }

  // Retrieve current claim week
  function currentWeek() public view returns (uint256) {
    return _week;
  }

  // Update Token Public Price
  function setPublicCost(uint256 _publicCost) public onlyOwner {
    publicCost = _publicCost;
  }

  // Update Token Holder Price
  function setHolderCost(uint256 _holderCost) public onlyOwner {
    holderCost = _holderCost;
  }

  // Update Token Collab Price
  function setCollabCost(uint256 _collabCost) public onlyOwner {
    collabCost = _collabCost;
  }

  // Show tokens being claimed
  function showCurrentTokens() public view returns (uint256[] memory) {
    return _currentTokens;
  }

  // Pause contract...
  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  // Set new Collab Contract Address
  function setCollabContract(address collabContract) public onlyOwner {
    _collabContract = CollectionContract(collabContract);
  }

  // Overdrive max amount of tokens claimable per wallet
  function setOverdrive(bool _overdrive) public onlyOwner {
    overdrive = _overdrive;
  }

  // Average Revenue Agency
  function withdraw() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }
}