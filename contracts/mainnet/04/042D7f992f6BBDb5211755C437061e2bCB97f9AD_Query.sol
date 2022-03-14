// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Pellar 2022

contract Query {
  struct CallMapper {
    address contractAddress;
    bytes bytesCaller;
  }
  function getTokensByAccount(address _contract, address _account) public view returns (uint256[] memory) {
    uint256 balance = INFT(_contract).balanceOf(_account);
    uint256[] memory tokens = new uint256[](balance);
    for (uint256 i = 0; i < balance; i++) {
      tokens[i] = INFT(_contract).tokenOfOwnerByIndex(_account, i);
    }
    return tokens;
  }

  function callContractsWith(CallMapper[] calldata _callers) public view returns (bool[] memory, bytes[] memory) {
    uint256 size = _callers.length;
    bool[] memory successes = new bool[](size);
    bytes[] memory responses = new bytes[](size);
    for (uint256 i = 0; i < _callers.length; i++) {
      (bool success, bytes memory res) = _callers[i].contractAddress.staticcall(_callers[i].bytesCaller);
      successes[i] = success;
      responses[i] = res;
    }
    return (successes, responses);
  }
}

interface INFT {
  function totalSupply() external view returns (uint256);

  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

  function tokenByIndex(uint256 index) external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256 balance);

  function ownerOf(uint256 tokenId) external view returns (address owner);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function approve(address to, uint256 tokenId) external;

  function getApproved(uint256 tokenId) external view returns (address operator);

  function setApprovalForAll(address operator, bool _approved) external;

  function isApprovedForAll(address owner, address operator) external view returns (bool);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external;
}