// SPDX-License-Identifier: MIT

/*
Average TV by Average Creatures
*/

pragma solidity ^0.8.2;

import "./ERC1155.sol";
import "./ERC1155Burnable.sol";
import "./Ownable.sol";
import "./Strings.sol";

abstract contract CollectionContract {
   function balanceOf(address owner) external virtual view returns (uint256 balance);
}

contract AverageTVTEST2 is ERC1155, ERC1155Burnable, Ownable {
  
  using Strings for uint256;
  string public uriSuffix = ".json";
  mapping(address => uint256) public claimedList;
  bool public paused = true;

  uint256[] public _currentTokens;
  uint256 public _toLoop = 0;
  uint256 public _week = 0;

  CollectionContract private _avgcreatures = CollectionContract(0xbFEdBb9c6DFaD7Ebd105287A8286ce36001b2B27);

  constructor(string memory uri_) ERC1155(uri_) {}

  modifier claimCompliance() {
    require(_avgcreatures.balanceOf(msg.sender) > 0, "No Creatures found on this wallet.");
    require(!paused, "Average TV Claim is paused.");
    require(claimedList[msg.sender] != _week);
    _;
  }

  function averageTVClaim() public claimCompliance() {
    claimedList[msg.sender] = _week;
    _mint(msg.sender, _currentTokens[randomToken()], 1, '0x0000');
  }

  function smallClaimsCourt(
    address[] memory addresses, 
    uint256[] memory ids, 
    uint256[] memory amounts, 
    bytes[] memory data
  ) external onlyOwner {
    uint numWallets = addresses.length;
    require(numWallets == ids.length, "number of ids need to match number of addresses");
    require(numWallets == amounts.length, "number of amounts need to match number of addresses");

    for (uint i = 0; i < numWallets; i++) {
      _mint(addresses[i], ids[i], amounts[i], data[i]);
    }
  }

  // Update our current Tokens being Claimed
  function updateCurrentTokens(uint256[] memory newTokens) public onlyOwner {
    _currentTokens = newTokens;
    _toLoop = 0;
  }

  // Spread token ID
  function randomToken() internal returns (uint256) {
    if (_currentTokens.length > 1) {
      if (_toLoop++ > _currentTokens.length) {
        _toLoop = 0;
      } else {
        _toLoop++;
      }
    }
    return _toLoop;
  }

  function uri(uint id_) public view override returns (string memory) {
    return string(abi.encodePacked(super.uri(id_), id_.toString(), uriSuffix));
  } 

  function setURI(string memory uri_) external onlyOwner {
    _setURI(uri_);
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function withdraw() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }
}