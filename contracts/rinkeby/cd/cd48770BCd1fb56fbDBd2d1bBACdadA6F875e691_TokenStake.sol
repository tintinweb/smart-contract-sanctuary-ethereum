//SPDX-License-Identifier: MIT
pragma solidity  ^0.8.0;

import './interface/IERC2612.sol';
import './interface/IERC20.sol';

interface TokenRecipient {
  function tokensReceived(
      address from,
      uint amount,
      bytes calldata exData
  ) external returns (bool);
}

contract TokenStake is TokenRecipient {

  address private immutable token;


  mapping(address => uint) public staked;

  constructor(address _token) {
    token = _token;
  }

  function permitStake(address user, uint amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
    IERC2612(token).permit(msg.sender, address(this), amount, deadline, v, r, s);
    stake(user, amount);
  }

  function stake(address user, uint amount) public {
    require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Transfer from error");
    
    staked[user] += amount;
  }

  function withdraw(uint amount) external {
    require(staked[msg.sender] >= amount, "low balance");
    IERC20(token).transfer(msg.sender, amount);
  }

  function tokensReceived(address from, uint amount, bytes calldata data) external override returns (bool) {
    require(msg.sender == token, "ill caller");

    staked[from] += amount;
    return true;
  }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 */
interface IERC2612 {

    function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function nonces(address owner) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {

  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}