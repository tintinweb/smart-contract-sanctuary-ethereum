// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";

contract PRSD is ERC20, Ownable {
  bool public limited;
  uint256 public maxHoldingAmount;
  uint256 public minHoldingAmount;
  address public uniswapPair;
  mapping(address => bool) public blacklists;

    constructor(uint256 _totalSupply) ERC20(unicode"Post Rug Stress Disorder", unicode"PRSD") {
    _mint(msg.sender, _totalSupply);
  }

  function blacklist(
    address _address,
    bool _isBlacklisting
  ) external onlyOwner {
    blacklists[_address] = _isBlacklisting;
  }

  function setRule(
    bool _limited,
    address _uniswapPair,
    uint256 _maxHoldingAmount,
    uint256 _minHoldingAmount
  ) external onlyOwner {
    limited = _limited;
    uniswapPair = _uniswapPair;
    maxHoldingAmount = _maxHoldingAmount;
    minHoldingAmount = _minHoldingAmount;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    require(!blacklists[to] && !blacklists[from], "Blacklisted");

    if (uniswapPair == address(0)) {
      require(from == owner() || to == owner(), "trading is not started");
      return;
    }

    if (limited && from == uniswapPair) {
      require(
        super.balanceOf(to) + amount <= maxHoldingAmount &&
          super.balanceOf(to) + amount >= minHoldingAmount,
        "Forbid"
      );
    }
  }

  function burn(uint256 value) external {
    _burn(msg.sender, value);
  }
}