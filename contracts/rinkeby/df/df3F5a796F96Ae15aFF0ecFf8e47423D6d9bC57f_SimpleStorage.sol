// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract SimpleStorage {
  uint256 private s_favoriteNumber;

  function store(uint256 _newFavoriteNumber) public virtual {
    s_favoriteNumber = _newFavoriteNumber;
  }

  function retrieve() public view virtual returns (uint256) {
    return s_favoriteNumber;
  }
}