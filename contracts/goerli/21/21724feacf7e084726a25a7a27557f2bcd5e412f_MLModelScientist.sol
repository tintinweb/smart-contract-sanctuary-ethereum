// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

interface Token {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);    

}

contract MLModelScientist is ERC721Enumerable, Ownable {

  struct ModelInfo {
    string description;
    string sourceName;
  }

  mapping(uint256 => ModelInfo) public modelInfo;

  event AssetMinted(uint256 tokenId, address sender);
  constructor() ERC721("ML Model Scientist", "MMS") {
  }

  function getTotalSupply() external view returns (uint256) {
    return totalSupply();
  }

  function getContractOwner() public view returns (address) {
    return owner();
  }

  function mint(address _to, string memory _sourceName, string memory _description) external {
      emit AssetMinted(totalSupply(), _to);
      _safeMint(_to, totalSupply());
      modelInfo[totalSupply()] = ModelInfo(_description, _sourceName);
  }

  function walletOfOwner(address _owner) external view returns(uint256[] memory) {
    uint tokenCount = balanceOf(_owner);
    uint256[] memory tokensId = new uint256[](tokenCount);

    for(uint i = 0; i < tokenCount; i++){
      tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokensId;
  }

}