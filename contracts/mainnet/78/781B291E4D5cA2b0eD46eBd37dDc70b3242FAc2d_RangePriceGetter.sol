// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import {IPriceGetter} from "./interfaces/IPriceGetter.sol";

contract RangePriceGetter is IPriceGetter {

  uint256[2] public priceRange;
  IPriceGetter public priceGetter;
  address public owner;

  constructor(address _priceGetter, uint256[2] memory _priceRange) {
    priceGetter = IPriceGetter(_priceGetter);
    priceRange = _priceRange;
    owner = msg.sender;
  }

  function getPrice() external view override returns (uint256 price) {
    uint256 twapPrice = priceGetter.getPrice();
    uint256 minPrice = min(priceRange[0], priceRange[1]);
    uint256 maxPrice = max(priceRange[0], priceRange[1]);
    if (twapPrice > maxPrice) {
      price = maxPrice;
    } else if (twapPrice < minPrice) {
      price = minPrice;
    } else {
      price = twapPrice;
    }
  }

  function setPriceRange(uint256[2] calldata _priceRange) external onlyOwner {
    priceRange = _priceRange;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a > b ? b : a;
  }

  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a > b ? a : b;
  }

  function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    owner = newOwner;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Only owner can call this function.");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IPriceGetter {
  function getPrice() external view returns (uint256 price);
}