/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.8.0 <0.9.0;

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
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
    return div(a, b, "SafeMath: division by zero");
  }

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

interface IERC20 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this;
    return msg.data;
  }
}

contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  function transferOwnership(address newOwner) public virtual onlyOwner() {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract Authorizable is Ownable {
  mapping(address => bool) private authorized;

  constructor () {
    authorized[owner()] = true;
  }

  modifier onlyAuthorized() {
    require(authorized[_msgSender()], "Only for authorized personnel");
    _;
  }

  function setAuthorization(address _address, bool shouldAuthorize) external onlyOwner() {
    authorized[_address] = shouldAuthorize;
  }

  function isAuthorized(address _address) external view returns (bool) {
    return authorized[_address];
  }
}

contract PaymentManager is Authorizable {
  using SafeMath for uint256;

  struct GamePayments {
    mapping(address => bool) hasPaid;
    mapping(address => uint256) amountPaid;
    bool hasDistributedRewards;
    uint256 totalAmount;
  }

  uint256 public networkGasFee = 0.005 ether;
  uint256 public gameFeeCollected;
  mapping(string => GamePayments) public allPaymentsPerRoom;

  constructor() {
  }


  // --------------------------------------------- //
  //          External Non-View Functions          //
  // --------------------------------------------- //

  function setNetworkGasFee(uint256 _amount) external onlyOwner() {
    networkGasFee = _amount;
  }

  function initiateNewPayment(string calldata _roomId, uint256 _paymentAmount) external payable returns (bool success) {
    require(msg.value >= (networkGasFee + _paymentAmount), "Not enough value sent with the transaction.");

    GamePayments storage gamePayments = allPaymentsPerRoom[_roomId];
    require(!gamePayments.hasDistributedRewards, "Cannot make payment to join this room.");

    gamePayments.hasPaid[msg.sender] = true;
    gamePayments.amountPaid[msg.sender] = _paymentAmount;
    gamePayments.totalAmount += _paymentAmount;
    gameFeeCollected += (msg.value - _paymentAmount);
    
    success = true;
  }

  function withdrawFees(address _receiveWallet, uint256 _amount) external onlyOwner() returns(bool success) {
    (success, ) = _receiveWallet.call{value: _amount}("");
  }

  function sendRewardToWinner(string calldata _roomId, address[] calldata _receiveWallets, uint256[] calldata _winnerRewards)
  external onlyAuthorized() returns(bool[] memory) {
    GamePayments storage gamePayments = allPaymentsPerRoom[_roomId];
    require(!gamePayments.hasDistributedRewards, "Rewards already distributed");
    require(_receiveWallets.length == _winnerRewards.length, "Length Mismatch");

    bool[] memory result = new bool[](_receiveWallets.length);
    uint256 totalDistributed = 0;

    for (uint256 i = 0; i < _receiveWallets.length; i++) {
      (result[i], ) = address(_receiveWallets[i]).call{value : _winnerRewards[i]}("");
      totalDistributed += _winnerRewards[i];
    }

    require(gamePayments.totalAmount >= totalDistributed, "Under value transfer");
    gameFeeCollected += gamePayments.totalAmount - totalDistributed;

    gamePayments.hasDistributedRewards = true;

    return result;
  }

  // --------------------------------------------- //
  //                  View Functions               //
  // --------------------------------------------- //

  function verifyPlayerPayment(string calldata _roomId, address _playerAddress, uint256 _amount) public view returns (bool hasPaid) {
    GamePayments storage gamePayments = allPaymentsPerRoom[_roomId];
    return gamePayments.hasPaid[_playerAddress] && (gamePayments.amountPaid[_playerAddress] >= _amount);
  }
}