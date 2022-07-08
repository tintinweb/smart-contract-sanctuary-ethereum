/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;


abstract contract Ownable {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    _transferOwnership(msg.sender);
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(owner() == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

interface IERC20Interface {
  function transfer(address _to, uint256 _value) external returns (bool success);
  function balanceOf(address account) external view returns (uint256);
}

struct FaucetAllowance {
  uint256 amount;
  uint256 interval;
}

struct FaucetWithdrawal {
  uint256 time;
  uint256 amount;
}

contract PoWFaucetVault is Ownable {

  mapping(address => FaucetAllowance) private _faucetAllowances;
  mapping(address => mapping(uint256 => FaucetWithdrawal)) private _faucetWithdrawals;
  mapping(address => uint256) private _faucetWithdrawalCount;

  constructor() {
  }

  function _drainToken(address tokenAddr, address addr) public onlyOwner() {
    IERC20Interface token = IERC20Interface(tokenAddr);
    uint256 balance = token.balanceOf(address(this));
    if(balance > 0) {
      token.transfer(addr, balance);
    }
  }

  function _drainEther(address to) public onlyOwner() {
    uint balance = address(this).balance;
    require(balance >= 0, "not enough funds");

    (bool sent, ) = payable(to).call{value: balance}("");
    require(sent, "failed to send ether");
  }

  function _selfdestruct(address addr) public onlyOwner() {
    selfdestruct(payable(addr));
  }


  receive() external payable {
  }

  function setAllowance(address addr, uint256 amount, uint256 interval) public onlyOwner() {
    _faucetAllowances[addr] = FaucetAllowance({
      amount: amount,
      interval: interval
    });
  }

  function getWithdrawnAmount(address addr, uint256 time) public view returns (uint256) {
    uint256 withdrawalIndex = _faucetWithdrawalCount[addr];
    uint256 amount = 0;
    while(withdrawalIndex > 0) {
      withdrawalIndex--;
      FaucetWithdrawal memory withdrawal = _faucetWithdrawals[addr][withdrawalIndex];
      if(withdrawal.time < time)
        break;
      amount += withdrawal.amount;
    }
    return amount;
  }

  function getAllowance(address addr) public view returns (uint256) {
    FaucetAllowance memory allowance = _faucetAllowances[addr];
    uint256 amount = allowance.amount;
    if(amount > 0) {
      uint256 withdrawn = getWithdrawnAmount(addr, block.timestamp - allowance.interval);
      if(withdrawn >= amount)
        amount = 0;
      else
        amount -= withdrawn;
    }
    return amount;
  }

  function withdraw(uint256 amount) public {
    uint256 allowance = getAllowance(msg.sender);
    require(allowance > 0, "withdrawal denied");
    require(amount <= allowance, "amount exceeds allowance");

    uint256 withdrawalIndex = _faucetWithdrawalCount[msg.sender];
    _faucetWithdrawals[msg.sender][withdrawalIndex] = FaucetWithdrawal({
      time: block.timestamp,
      amount: amount
    });
    _faucetWithdrawalCount[msg.sender] = withdrawalIndex + 1;

    (bool sent, ) = msg.sender.call{value: amount}("");
    require(sent, "failed to send ether");
  }

}