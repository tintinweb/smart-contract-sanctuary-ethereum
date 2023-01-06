// SPDX-License-Identifier: MIT
import "ERC721A.sol";
import "Ownable.sol";
import "OwnableEpochContract.sol";

pragma solidity 0.8.17;

contract GoerliQ00tants is ERC721A, OwnableEpochContract {
  constructor(string memory _uri) ERC721A("Q00tants", "q00tants") {
    baseTokenURI = _uri;
  }

  string private baseTokenURI;

  function initialize(address[] calldata _users, uint256[] calldata _amounts) external onlyOwner {
    if (_users.length != _amounts.length) revert();

    for (uint256 i = 0; i < _users.length; i++) {
      _mint(_users[i], _amounts[i]);
    }
  }

  function isApprovedForAll(address, address operator) public view override returns (bool) {
    return epochRegistry.isApprovedAddress(operator);
  }

  function setBaseTokenURI(string calldata _baseTokenURI) public onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseTokenURI;
  }

  function transferFrom(address from, address to, uint256 tokenId) public payable override onlyEpoch {
    super.transferFrom(from, to, tokenId);
  }
}