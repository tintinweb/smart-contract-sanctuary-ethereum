// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

interface IResolver {
  enum PaymentToken {
    SENTINEL,
    WETH,
    DAI,
    USDC,
    USDT,
    TUSD,
    HADARO
  }

  function getPaymentToken(uint8 _pt) external view returns (address);

  function setPaymentToken(uint8 _pt, address _v) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import "./interfaces/IResolver.sol";

contract Resolver is IResolver {
  address private admin;
  mapping(uint8 => address) private addresses;

  constructor(address _admin) {
    admin = _admin;
  }

  function getPaymentToken(uint8 _pt) external view override returns (address) {
    return addresses[_pt];
  }

  function setPaymentToken(uint8 _pt, address _v) external override {
    require(_pt != 0, "Hadaro::cant set sentinel");
    require(addresses[_pt] == address(0), "Hadaro::cannot reset the address");
    require(msg.sender == admin, "Hadaro::only admin");
    addresses[_pt] = _v;
  }
}