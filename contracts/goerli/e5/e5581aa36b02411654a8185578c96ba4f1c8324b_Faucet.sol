// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./EIP20Interface.sol";
import "./Ownable.sol";

contract Faucet is Ownable {
  event Funded(address fundee, EIP20Interface token, uint256 amount);
  event SkippingFundingAlreadyFunded(address fundee, EIP20Interface token, uint256 currentBalance);
  event SkippingFundingFaucetDry(address fundee, EIP20Interface token, uint256 faucetBalance);
  mapping(address => bool) public fundees;
  EIP20Interface[] public supportedTokens;

  constructor(EIP20Interface[] memory tokens) {
    supportedTokens = tokens;
  }

  function tap() external {
    address fundee = tx.origin;
    require(!fundees[fundee], "account has already been funded");
    fundees[fundee] = true;
    _seed(fundee, supportedTokens);
  }

  /*
    Allows Faucet owner to fund a fundee that has previously been funded (and therefor won't be
    to call `tap()`)
  */
  function seed(address fundee) external onlyOwner {
    _seed(fundee, supportedTokens);
  }

  function _seed(address fundee, EIP20Interface[] memory tokens) internal {
    for (uint i = 0; i < tokens.length; i += 1) {
      EIP20Interface token = tokens[i];
      /*
        Don't attempt to fund USDT; it isn't ERC20 conformant and will break the seed call because
        transfer doesn't return a bool
      */
      if (
        keccak256(abi.encodePacked(token.symbol())) != keccak256(abi.encodePacked("USDT"))
      ) {

        uint256 amount = 1000 * (10 ** (token.decimals()));
        uint256 faucetBalance = token.balanceOf(address(this));
        uint256 fundeeBalance = token.balanceOf(fundee);
        if (fundeeBalance >= amount) {
          emit SkippingFundingAlreadyFunded(fundee, token, fundeeBalance);
        } else if (faucetBalance < amount) {
          emit SkippingFundingFaucetDry(fundee, token, faucetBalance);
        } else {
          require(token.transfer(fundee, amount), "something went wrong with token transfer");
          emit Funded(fundee, token, amount);
        }

      }
    }
  }
}