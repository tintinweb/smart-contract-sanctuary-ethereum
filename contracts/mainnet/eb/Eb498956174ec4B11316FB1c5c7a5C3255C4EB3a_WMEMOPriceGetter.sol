// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import {IPriceGetter} from "./interfaces/IPriceGetter.sol";

contract WMEMOPriceGetter is IPriceGetter {
  IPriceGetter public immutable twapPriceGetter;
  address private owner;
  address public keeper;
  uint256 public fallbackPrice;
  uint256 public deviation = 1000;
  uint256 public constant MAX_DEVIATION = 10000; // 10000 = 100%

  constructor(address _twapPriceGetter) {
    twapPriceGetter = IPriceGetter(_twapPriceGetter);
    owner = msg.sender;
  }

  function setDeviation(uint256 newDeviation) external onlyOwner {
    require(newDeviation <= MAX_DEVIATION, "deviation too high");
    deviation = newDeviation;
  }

  function setKeeper(address _keeper) external onlyOwner {
    keeper = _keeper;
  }

  function setFallbackPrice(uint256 _fallbackPrice) external onlyKeeper {
    fallbackPrice = _fallbackPrice;
  }

  function getPrice() external view override returns (uint256 price) {
    uint256 twapPrice = twapPriceGetter.getPrice();
    if (fallbackPrice > 0) {
      uint256 priceDiff = twapPrice > fallbackPrice ? twapPrice - fallbackPrice : fallbackPrice - twapPrice;
      price = priceDiff * 10000 / fallbackPrice <= deviation ? twapPrice : fallbackPrice;
    } else {
      price = twapPrice;
    }
  }

  function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    owner = newOwner;
  }

  modifier onlyOwner() {
    require(owner == msg.sender, "!owner");
    _;
  }

  modifier onlyKeeper() {
    require(msg.sender == keeper, "!keeper");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IPriceGetter {
  function getPrice() external view returns (uint256 price);
}