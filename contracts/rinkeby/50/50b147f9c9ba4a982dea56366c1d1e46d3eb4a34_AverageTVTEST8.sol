// SPDX-License-Identifier: MIT

/*
Average TV by Average Creatures
*/

pragma solidity ^0.8.2;

import "./ERC1155.sol";
import "./ERC1155Burnable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

abstract contract CollectionContract {
   function balanceOf(address owner) external virtual view returns (uint256 balance);
}

contract AverageTVTEST8 is ERC1155, ERC1155Burnable, Ownable {
  
  using Strings for uint256;
  string public uriSuffix = ".json";
  mapping(address => uint256) public claimedList;
  bytes32 public _merkleRoot;
  bool public paused = true;

  uint256[] public _currentTokens;
  uint256 public _toLoop = 0;
  uint256 public _week = 0;
  uint256[40] claimedBitMap;

  CollectionContract private _avgcreatures = CollectionContract(0xbFEdBb9c6DFaD7Ebd105287A8286ce36001b2B27);

  constructor(string memory uri_) ERC1155(uri_) {}

  modifier claimCompliance() {
    require(_avgcreatures.balanceOf(msg.sender) > 0, "No Creatures found on this wallet.");
    require(!paused, "Average TV Claim is paused.");
    require(claimedList[msg.sender] != _week);
    
    _;
  }

  function averageTVClaim(bytes32[] calldata _merkleProof) public claimCompliance() {
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, _merkleRoot, leaf), "Invalid proof!");
    claimedList[msg.sender] = _week;
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

  function uri(uint id_) public view override returns (string memory) {
    return string(abi.encodePacked(super.uri(id_), id_.toString(), uriSuffix));
  } 

  function setURI(string memory uri_) external onlyOwner {
    _setURI(uri_);
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setWeek(uint256 newWeek) public onlyOwner {
    _week = newWeek;
  }

  function currentWeek() public view returns (uint256) {
    return _week;
  }

  function showCurrentTokens() public view returns (uint256[] memory) {
    return _currentTokens;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setMerkleRoot(bytes32 merkleRoot) public onlyOwner {
    _merkleRoot = merkleRoot;
  }

  function withdraw() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }
}