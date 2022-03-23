// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IERC20 {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
}

contract TokenInfo {

  function getTokenInfo(address[] calldata _tokens) public view returns (
    address[] memory addresses,
    string[] memory names,
    string[] memory symbols,
    uint[] memory decimals
  ) {
    addresses = new address[](_tokens.length);
    names = new string[](_tokens.length);
    symbols = new string[](_tokens.length);
    decimals = new uint[](_tokens.length);
    for (uint i; i < _tokens.length; i++) {
      IERC20 token = IERC20(_tokens[i]);
      (addresses[i]) = _tokens[i];
      (names[i]) = token.name();
      (symbols[i]) = token.symbol();
      (decimals[i]) = token.decimals();
    }
  }

}