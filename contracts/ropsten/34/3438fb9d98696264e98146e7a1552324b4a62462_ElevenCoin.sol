// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ERC1155.sol";
import "./IERC1155MetadataURI.sol";
import "./Ownable.sol";

contract ElevenCoin is ERC1155, Ownable {

  uint256 maxTotalSupply;

  constructor(
    uint256 totalSupply_,
    string memory _tokenURI
  ) ERC1155(_tokenURI) {
    maxTotalSupply = totalSupply_;
    _mint(msg.sender, 1, totalSupply_, "");
  }

  function setURI(string memory _newURI) public onlyOwner {
    _setURI(_newURI);
  }

  function totalSupply() public view returns (uint256) {
    return maxTotalSupply;
  }
}