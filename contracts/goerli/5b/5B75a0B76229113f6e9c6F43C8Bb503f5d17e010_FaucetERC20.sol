// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {ERC20} from './ERC20.sol';
import {Ownable} from './Ownable.sol';

/**
 * @title FaucetERC20
 * @dev Faucet ERC20 token with mint limitation
 */
contract FaucetERC20 is ERC20, Ownable {
  uint256 public maxAmountPerMint;

  uint256 public minMintFrequency;

  mapping(address => uint256) public lastMintTime;

  constructor(
    string memory name,
    string memory symbol,
    uint8 decimals,
    uint256 _maxAmountPerMint,
    uint256 _minMintFrequency
  ) public ERC20(name, symbol) Ownable() {
    _setupDecimals(decimals);

    maxAmountPerMint = _maxAmountPerMint;
    minMintFrequency = _minMintFrequency;

    _mint(msg.sender, 50000 * (10**decimals));
  }

  /**
   * @dev Function to mint tokens
   * @param value The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(uint256 value) external returns (bool) {
    if (lastMintTime[msg.sender] > 0) {
      require(block.timestamp >= lastMintTime[msg.sender] + minMintFrequency, 'Frequent mint');
    }

    require(value <= maxAmountPerMint, 'Too much mint amount');

    lastMintTime[msg.sender] = block.timestamp;

    _mint(msg.sender, value);

    return true;
  }

  /**
   * @dev Sets `_maxAmountPerMint` and `_minMintFrequency`. Only callable by owner.
   * @param _maxAmountPerMint amount per mint
   * @param _minMintFrequency min mint frequency
   * @return boolean
   */
  function setConfig(uint256 _maxAmountPerMint, uint256 _minMintFrequency)
    external
    onlyOwner
    returns (bool)
  {
    maxAmountPerMint = _maxAmountPerMint;
    minMintFrequency = _minMintFrequency;

    return true;
  }
}