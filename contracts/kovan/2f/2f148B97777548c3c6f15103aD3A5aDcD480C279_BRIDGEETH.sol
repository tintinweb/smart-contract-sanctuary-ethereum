pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT
import './IToken.sol';

contract BRIDGEETH {
  address public admin;
  address public vault;
  address public feeAddress;
  IToken public token;
  uint256 public taxfee;


  constructor(address _token) {
    admin = msg.sender;
    vault = msg.sender;
    feeAddress = msg.sender;
    token = IToken(_token);
    taxfee = 500;
  }

  function burn(uint amount) external {
    token.transferFrom(msg.sender, vault ,amount-(taxfee*(10**(token.decimals()))));
    token.transferFrom(msg.sender, feeAddress , (taxfee*(10**(token.decimals()))));
  }

  function mint(address to, uint amount) external {
    require(msg.sender == admin, 'only admin');
    token.transferFrom(vault, to, amount);
  }
  function getContractTokenBalance() external view returns (uint256) {
    return token.balanceOf(address(this));
  }
  function withdraw(uint amount) external {
    require(msg.sender == admin, 'only admin');
    token.transfer(msg.sender, amount);
  }
  function changeAdmin(address newAdmin) external {
    require(msg.sender == admin, 'only admin');
    admin = newAdmin;
  }
  function changeVault(address newVault) external {
    require(msg.sender == admin, 'only admin');
    vault = newVault;
  }
  function changefeeAddress(address newfeeAddress) external {
    require(msg.sender == admin, 'only admin');
    feeAddress = newfeeAddress;
  }
  function setTaxFee(uint newTaxFee) external {
    require(msg.sender == admin, 'only admin');
    taxfee = newTaxFee;
  }
  function withdrawStuckToken(IToken _token) external{
    require(msg.sender == admin, 'only admin');
    _token.transfer(msg.sender, _token.balanceOf(address(this)));
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