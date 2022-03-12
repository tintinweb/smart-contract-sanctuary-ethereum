/**
 *Submitted for verification at Etherscan.io on 2022-03-12
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

contract DividendHolderAndDistributor is Ownable {
  using SafeMath for uint256;

  IERC20 holdCoin;
  bool isCoinWithdrawalEnabled = false;

  mapping(address => uint256) public coinHoldingOfEachWallet;
  mapping(address => uint256) public bnbWithdrawnByWallets;
  uint256 public totalBNBAccumulated = 0;
  uint256 public totalCoinsPresent = 0;

  constructor(address holdCoinAddress, address[] memory _addresses, uint256[] memory _amounts) {
    holdCoin = IERC20(holdCoinAddress);
    require(_addresses.length == _amounts.length, "Length Mismatch");

    for (uint256 i = 0; i < _addresses.length; i++) {
      coinHoldingOfEachWallet[_addresses[i]] = _amounts[i];
      totalCoinsPresent += _amounts[i];
    }
  }

  receive() external payable {
    totalBNBAccumulated = totalBNBAccumulated.add(msg.value);
  }

  function getWaithdrawableBNB(address _address) public view returns(uint256) {
    uint256 totalBNBShare = (totalBNBAccumulated.mul(coinHoldingOfEachWallet[_address])).div(totalCoinsPresent);
    return totalBNBShare.sub(bnbWithdrawnByWallets[_address]);
  }

  function _withdrawDividends(address _address) private returns(bool) {
    uint256 withdrawableBNB = getWaithdrawableBNB(_address);
    if (withdrawableBNB > 0) {
      (bool success, ) = address(_address).call{value : withdrawableBNB}("");

      if (success) {
        bnbWithdrawnByWallets[_address] = bnbWithdrawnByWallets[_address].add(withdrawableBNB);
      }

      return success;
    } else {
      return true;
    }
  }

  function withdrawDividends() external returns(bool) {
    return _withdrawDividends(_msgSender());
  }

  function setCoinWithdrawalEnable(bool isEnabled) external onlyOwner() {
    isCoinWithdrawalEnabled = isEnabled;
  }

  function withdrawCoins() external {
    require(isCoinWithdrawalEnabled, "Coin Withdrawal Not Allowed Until Enabled By Owner");

    bool success = _withdrawDividends(_msgSender());
    if (success) {
      totalCoinsPresent = totalCoinsPresent.sub(coinHoldingOfEachWallet[_msgSender()]);
      totalBNBAccumulated = totalBNBAccumulated.sub(bnbWithdrawnByWallets[_msgSender()]);

      holdCoin.transfer(_msgSender(), coinHoldingOfEachWallet[_msgSender()]);

      coinHoldingOfEachWallet[_msgSender()] = 0;
      bnbWithdrawnByWallets[_msgSender()] = 0;
    }
  }
}