// SPDX-License-Identifier: MIT


import "./Dependencies.sol";


pragma solidity ^0.8.11;

interface TokenURI {
  function uri(uint256) external view returns (string memory);
}

contract Editions is ERC1155, Ownable {
  mapping(uint256 => address) public tokenIdToMinter;
  mapping(uint256 => address) public tokenIdToURIContract;

  string public constant name = 'Editions';
  string public constant symbol = 'EDTN';
  address public defaultURIContract;

  modifier onlyMinter(uint256 id) {
    require(msg.sender == tokenIdToMinter[id], 'Caller is not the minter');
    _;
  }

  function mint(address to, uint256 id, uint256 amount) external onlyMinter(id) {
    _mint(to, id, amount, "");
  }

  function batchMint(address[] calldata recipients, uint256 id, uint256[] calldata amounts) external onlyMinter(id) {
    uint256 recipientCount = recipients.length;
    require(recipientCount == amounts.length, 'Length of recipient and amount arrays mismatched');

    for (uint256 i; i < recipientCount; ++i) {
      _mint(recipients[i], id, amounts[i], "");
    }
  }

  function setMinterForToken(uint256 id, address minter) external onlyOwner {
    tokenIdToMinter[id] = minter;
  }

  function setURIContractForToken(uint256 id, address addr) external onlyOwner {
    tokenIdToURIContract[id] = addr;
  }

  function setDefaultURIContract(address addr) external onlyOwner {
    defaultURIContract = addr;
  }

  function uri(uint256 id) external view returns (string memory) {
    if (tokenIdToURIContract[id] == address(0)) {
      return TokenURI(defaultURIContract).uri(id);
    } else {
      return TokenURI(tokenIdToURIContract[id]).uri(id);
    }
  }
}