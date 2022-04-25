pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT
import './IToken.sol';

contract BRIDGEETH {
  address public admin;
  IToken public token;
  uint256 public BSCfee;
  uint256 public ETHfee;


  constructor(address _token) {
    admin = msg.sender;
    token = IToken(_token);
    BSCfee = 20;
    ETHfee = 500;
  }

  function burn(uint amount) external {
    require(amount > ETHfee*(10**(token.decimals())),"amount less than Fee");
    token.transferFrom(msg.sender, admin, amount);
  }

  function mint(address to, uint amount) external {
    require(amount > BSCfee*(10**(token.decimals())),"amount less than Fee");
    require(msg.sender == admin, 'only admin');
    token.transferFrom(admin, to, amount - BSCfee*(10**(token.decimals())));
  }
  function changeAdmin(address newAdmin) external {
    require(msg.sender == admin, 'only admin');
    admin = newAdmin;
  }
  function setfee(uint newBSCfee, uint newETHfee) external {
    require(msg.sender == admin, 'only admin');
    BSCfee = newBSCfee;
    ETHfee = newETHfee;
  }
  function BSCtoETH(uint amount) external view returns(uint256 ) {
    if(amount < BSCfee*(10**token.decimals())){
      return 0;
    }
    else{
      return amount-(BSCfee*(10**(token.decimals())));
    }
  }
  function ETHtoBSC(uint amount) external view returns(uint256 ) {
    if(amount < ETHfee*(10**token.decimals())){
      return 0;
    }
    else{
    return amount-(ETHfee*(10**(token.decimals())));
    }
  }
}

pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT


interface IToken {
  function mint(address to, uint amount) external;
  function burn(address owner, uint amount) external;
  function burnFrom(address account, uint256 amount) external;
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address to, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(
      address from,
      address to,
      uint256 amount
  ) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}