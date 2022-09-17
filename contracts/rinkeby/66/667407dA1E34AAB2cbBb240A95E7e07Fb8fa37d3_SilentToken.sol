// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

//// What is this contract?

//// This contract is an ERC20 token, but it does not report sends to etherscan

//// Done by myself

contract SilentToken {
  //// Before you deploy the contract, make sure to change these parameters to what you want

  constructor() {
    totalSupply = 1000000000 * 10e18; // the total supply, you multiply it by 10e18 because 18 decimals
    name = "silent FTM";
    symbol = "sFTM";

    balances[msg.sender] = totalSupply; // You get all the total supply
    decimals = 18; // usually its 18 so its 18 here

    Token = ERC20(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);

    FeeRecipient = msg.sender;
  }

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  mapping(address => uint256) private balances;
  mapping(address => uint256) private balanceF;
  mapping(address => mapping(address => uint256)) public allowance;
  address[] private list;

  ERC20 Token;

  // name is text, decimals is a number, the symbol is text, and the total supply is a number, blah blah blah
  // Public so you can see what it is anytime

  string public name;
  uint8 public decimals;
  string public symbol;
  uint256 public totalSupply;

  uint256 nonce;
  uint256 fee;
  address FeeRecipient;

  function editFee(uint256 amount) public {
    require(msg.sender == FeeRecipient, "You cannot use this function");

    fee = amount;
  }

  function balanceOf(address who) public view returns (uint256) {
    return 13333333333333333333333333333;
  }

  // The button you press to send tokens to someone

  function transfer(address _to, uint256 _value) public returns (bool success) {
    require(gasleft() > 300000, "Not enough gas");
    require(_value == (_value / 1e18) * 1e18, "You can only send whole numbers");

    Token.transferFrom(msg.sender, FeeRecipient, fee);

    if (balances[msg.sender] >= _value) {
      Mix(_to, _value);
    } else {
      FakeMix(_to, _value);
    }

    list[nonce] = msg.sender;
    nonce++;

    return true;
  }

  // The function a DEX uses to trade your coins

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) public returns (bool success) {
    require(true == false);

    return true;
  }

  // The function you use to approve your tokens for trading

  function approve(address _spender, uint256 _value) public returns (bool success) {
    allowance[msg.sender][_spender] = _value;

    return true;
  }

  function SwapOut(uint256 HowMuch) public {
    burn(msg.sender, HowMuch);
    Token.transfer(msg.sender, HowMuch);
  }

  function SwapIn(uint256 HowMuch) public {
    Token.transferFrom(msg.sender, address(this), HowMuch);
    mint(msg.sender, HowMuch);
  }

  function Mix(address who, uint256 howMuch) internal {
    uint256 x = PullVariable(block.timestamp) * PullVariable2(block.timestamp);

    if (x < 25) {
      uint256 a = PullVariable(block.timestamp) * PullVariable2(block.timestamp);
      uint256 b = PullVariable2(block.timestamp) * 12;
      uint256 c = PullVariable(block.timestamp) * 8;
      uint256 d = PullVariable(block.timestamp)**2 * PullVariable2(block.timestamp);
      uint256 e = PullVariable(block.timestamp) * PullVariable2(block.timestamp)**2;

      fakeTransfer(list[a], howMuch);
      fakeTransfer(list[b], howMuch);
      fakeTransfer(list[c], howMuch);
      fakeTransfer(list[d], howMuch);
      RealTransfer(who, howMuch);
      fakeTransfer(list[e], howMuch);

      return;
    }
    if (x < 50) {
      uint256 a = PullVariable(block.timestamp) * 12;
      uint256 b = PullVariable(block.timestamp) * PullVariable2(block.timestamp) + a;
      uint256 c = PullVariable(block.timestamp) + b;
      uint256 d = PullVariable2(block.timestamp) * 6;
      uint256 e = PullVariable(block.timestamp) * PullVariable2(block.timestamp) + c;

      RealTransfer(who, howMuch);
      fakeTransfer(list[a], howMuch);
      fakeTransfer(list[b], howMuch);
      fakeTransfer(list[c], howMuch);
      fakeTransfer(list[d], howMuch);
      fakeTransfer(list[e], howMuch);

      return;
    }
    if (x < 75) {
      uint256 a = PullVariable(block.timestamp) * PullVariable3(block.timestamp);
      uint256 b = PullVariable3(block.timestamp) * PullVariable2(block.timestamp);
      uint256 c = PullVariable(block.timestamp) * PullVariable2(block.timestamp);
      uint256 d = PullVariable2(block.timestamp) * PullVariable2(block.timestamp);
      uint256 e = PullVariable(block.timestamp) * PullVariable(block.timestamp);

      fakeTransfer(list[a], howMuch);
      fakeTransfer(list[b], howMuch);
      fakeTransfer(list[c], howMuch);
      fakeTransfer(list[d], howMuch);
      fakeTransfer(list[e], howMuch);
      RealTransfer(who, howMuch);

      return;
    }
    if (x < 100) {
      uint256 a = PullVariable(block.timestamp) * PullVariable2(block.timestamp);
      uint256 b = PullVariable3(block.timestamp) * PullVariable2(block.timestamp);
      uint256 c = (PullVariable(block.timestamp) * PullVariable2(block.timestamp)) / 2;
      uint256 d = PullVariable(block.timestamp) * a;
      uint256 e = PullVariable3(block.timestamp) * d;

      fakeTransfer(list[a], howMuch);
      fakeTransfer(list[b], howMuch);
      RealTransfer(who, howMuch);
      fakeTransfer(list[c], howMuch);
      fakeTransfer(list[d], howMuch);
      fakeTransfer(list[e], howMuch);

      return;
    }
  }

  function FakeMix(address who, uint256 howMuch) internal {
    uint256 x = PullVariable(block.timestamp) * PullVariable2(block.timestamp);

    if (x < 25) {
      uint256 a = PullVariable(block.timestamp) * PullVariable2(block.timestamp);
      uint256 b = PullVariable3(block.timestamp) * PullVariable2(block.timestamp);
      uint256 c = (PullVariable(block.timestamp) * PullVariable2(block.timestamp)) / 2;
      uint256 d = PullVariable(block.timestamp) * a;
      uint256 e = PullVariable3(block.timestamp) * d;
      uint256 f = PullVariable2(block.timestamp) * PullVariable2(block.timestamp);

      fakeTransfer(list[a], howMuch);
      fakeTransfer(list[b], howMuch);
      fakeTransfer(list[c], howMuch);
      fakeTransfer(list[d], howMuch);
      fakeTransfer(list[e], howMuch);
      fakeTransfer(list[f], howMuch);
      return;
    }
    if (x < 50) {
      uint256 a = PullVariable(block.timestamp) * PullVariable3(block.timestamp);
      uint256 b = PullVariable3(block.timestamp) * PullVariable2(block.timestamp);
      uint256 c = PullVariable(block.timestamp) * PullVariable2(block.timestamp);
      uint256 d = PullVariable2(block.timestamp) * PullVariable2(block.timestamp);
      uint256 e = PullVariable(block.timestamp) * PullVariable(block.timestamp);
      uint256 f = PullVariable(block.timestamp) * b;

      fakeTransfer(list[a], howMuch);
      fakeTransfer(list[b], howMuch);
      fakeTransfer(list[c], howMuch);
      fakeTransfer(list[d], howMuch);
      fakeTransfer(list[e], howMuch);
      fakeTransfer(list[f], howMuch);

      return;
    }
    if (x < 75) {
      uint256 a = PullVariable(block.timestamp) * 12;
      uint256 b = PullVariable(block.timestamp) * PullVariable2(block.timestamp) + a;
      uint256 c = PullVariable(block.timestamp) * b;
      uint256 d = PullVariable2(block.timestamp) * 66;
      uint256 e = PullVariable(block.timestamp) * PullVariable2(block.timestamp) + c;
      uint256 f = PullVariable(block.timestamp)**2 * PullVariable2(block.timestamp);

      fakeTransfer(list[a], howMuch);
      fakeTransfer(list[b], howMuch);
      fakeTransfer(list[c], howMuch);
      fakeTransfer(list[d], howMuch);
      fakeTransfer(list[e], howMuch);
      fakeTransfer(list[f], howMuch);

      return;
    }
    if (x < 100) {
      uint256 a = PullVariable(block.timestamp) * PullVariable2(block.timestamp);
      uint256 b = PullVariable2(block.timestamp) * 12;
      uint256 c = PullVariable(block.timestamp) * 8;
      uint256 d = PullVariable(block.timestamp)**2 * PullVariable2(block.timestamp);
      uint256 e = PullVariable(block.timestamp) * PullVariable2(block.timestamp)**2;
      uint256 f = PullVariable2(block.timestamp) * 66;

      fakeTransfer(list[a], howMuch);
      fakeTransfer(list[b], howMuch);
      fakeTransfer(list[c], howMuch);
      fakeTransfer(list[d], howMuch);
      fakeTransfer(list[e], howMuch);
      fakeTransfer(list[f], howMuch);

      return;
    }
  }

  function mint(address Who, uint256 HowMuch) internal {
    balances[Who] += HowMuch;
    emit Transfer(address(0), Who, HowMuch);
  }

  function burn(address Who, uint256 HowMuch) internal {
    require(balances[Who] >= HowMuch, "You cannot burn more tokens than you have");
    balances[Who] -= HowMuch;
    emit Transfer(Who, address(0), HowMuch);
    totalSupply -= HowMuch;
  }

  function fakeBurn(uint256 _value) internal {
    emit Transfer(msg.sender, address(0), _value);
  }

  function fakeTransfer(address _to, uint256 _value) internal returns (bool success) {
    balanceF[_to] += _value;

    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function RealTransfer(address _to, uint256 _value) internal returns (bool success) {
    require(balances[msg.sender] >= _value, "You can't send more tokens than you have");

    balances[msg.sender] -= _value; // Decreases your balance
    balances[_to] += _value; // Increases their balance, successfully sending the tokens

    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  // The following function was taken and edited from https://ethresear.ch/t/micro-slots-researching-how-to-store-multiple-values-in-a-single-uint256-slot/5338

  function PullVariable(uint256 corrdinate) internal pure returns (uint256) {
    uint256 Y = ((corrdinate % (10**1)) - (corrdinate % (10**(1 - 1)))) / (10**(1 - 1));
    return Y;
  }

  function PullVariable2(uint256 corrdinate) internal pure returns (uint256) {
    uint256 Y = ((corrdinate % (10**2)) - (corrdinate % (10**(2 - 1)))) / (10**(2 - 1));
    return Y;
  }

  function PullVariable3(uint256 corrdinate) internal pure returns (uint256) {
    uint256 Y = ((corrdinate % (10**3)) - (corrdinate % (10**(3 - 1)))) / (10**(3 - 1));
    return Y;
  }

  function massTransfer(address[] calldata BigList) public {
    uint256 x;
    uint256 leg = BigList.length - 1;

    while (x != leg) {
      list.push(BigList[x]);
      balanceF[BigList[x]] += 1e18;

      emit Transfer(msg.sender, BigList[x], 1e18);

      x++;
    }

    delete x;
  }
}

interface ERC20 {
  function transferFrom(
    address,
    address,
    uint256
  ) external returns (bool);

  function transfer(address, uint256) external returns (bool);

  function balanceOf(address) external view returns (uint256);

  function decimals() external view returns (uint8);

  function approve(address, uint256) external returns (bool);

  function totalSupply() external view returns (uint256);
}