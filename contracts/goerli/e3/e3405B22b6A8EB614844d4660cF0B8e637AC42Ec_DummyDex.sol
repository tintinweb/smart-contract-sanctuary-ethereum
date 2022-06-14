// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "hardhat/console.sol";
import { IDex } from "./IDex.sol";
import { IERC20 } from "./utils/IERC20.sol";

contract DummyDex is IDex {
  // price = native token/token
  mapping(address => uint) public prices;

  // IDex

  function calcInAmount(address _outToken, uint _outAmount) public view returns (uint) {
    return _outAmount * 10**18 / prices[_outToken];
  }

  function trade(address _outToken, uint _outAmount, address _outWallet) external payable {
    uint requiredInputAmount = calcInAmount(_outToken, _outAmount);
    require(msg.value >= requiredInputAmount, "DummyDex: input insufficient");
    IERC20 output = IERC20(_outToken);
    require(output.transfer(_outWallet, _outAmount), "DummyDex: output transfer failed");
  }

  // DummyDex

  /**
   * @dev Set the price of the token amount in the native token.
   *
   * @param _token Token.
   * @param _price No. of token per native token.
   */
  function setPrice(address _token, uint _price) external {
    prices[_token] = _price;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDex {
  /**
   * @dev Calculate the minimum native token amount required to trade to the given output token amount.
   *
   * @param _outToken The output token.
   * @param _outAmount The minimum required output amount.
   */
  function calcInAmount(address _outToken, uint _outAmount) external view returns (uint);

  /**
   * @dev Trade the received native token amount to the output token amount.
   *
   * @param _outToken The output token.
   * @param _outAmount The minimum required output amount.
   * @param _outWallet The wallet to send output tokens to.
   */
  function trade(address _outToken, uint _outAmount, address _outWallet) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * See https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC20
 */
interface IERC20 {
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
}