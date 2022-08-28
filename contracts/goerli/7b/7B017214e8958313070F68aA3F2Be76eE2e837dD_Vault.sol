// SPDX-License-Identifier: MIT
  pragma solidity ^0.8.9;
  
  contract Vault {
      IERC20 public immutable token;
      uint256 public totalSupply;
  
      mapping(address => uint256) public balanceOf;
  
      constructor(address _token) {
          token = IERC20(_token);
      }
  
      function mint(address _to, uint256 shares) private {
          totalSupply += shares;
          balanceOf[_to] += shares;
      }
  
      function burn(address _from, uint256 shares) private {
          totalSupply -= shares;
          balanceOf[_from] -= shares;
      }
  
      function deposit(uint256 _amount) external {
          uint256 shares;
          if (totalSupply == 0) {
              shares = _amount;
          } else {
              shares = (_amount * totalSupply) / token.balanceOf(address(this));
          }
  
          mint(msg.sender, shares);
          token.transferFrom(msg.sender, address(this), _amount);
      }
  
      function withdraw(uint256 _shares) external {
          uint256 amount = (_shares * token.balanceOf(address(this))) /
              totalSupply;
          burn(msg.sender, _shares);
          token.transfer(msg.sender, amount);
      }
  }
  
  interface IERC20 {
      function totalSupply() external view returns (uint256);
  
      function balanceOf(address account) external view returns (uint256);
  
      function transfer(address recipient, uint256 amount)
          external
          returns (bool);
  
      function allowance(address owner, address spender)
          external
          view
          returns (uint256);
  
      function approve(address spender, uint256 amount) external returns (bool);
  
      function transferFrom(
          address sender,
          address recipient,
          uint256 amount
      ) external returns (bool);
  
      event Transfer(address indexed from, address indexed to, uint256 amount);
      event Approval(
          address indexed owner,
          address indexed spender,
          uint256 amount
      );
  }