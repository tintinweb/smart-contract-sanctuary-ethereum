// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function decimals() external view returns (uint8);
}

interface IBondingCalculator {
  function valuation(address _token, uint _amount) external view returns (uint _value);
  function markdown(address _token) external view returns (uint);
}

contract ZeroValueBondCalculator is IBondingCalculator {
  function valuation(address, uint) external view override returns (uint _value) {
    _value = 0;
  }

  function markdown(address _token) external view override returns (uint) {
    return 10 ** IERC20(_token).decimals();
  }
}