pragma solidity ^0.8.4;

import '@uniswap/v2-periphery/contracts/interfaces/IERC20.sol';

interface IOptiVaultBalanceLookup {
  function sharesOf(address user) external view returns (uint256 _shares); //shares
}

contract OptiVault {
  // **********************************************************************************
  // *       OptiVaults provide an easy way to lock tokens as a group.                *
  // *    Reflective staking means that early withdrawals are allowed,                *
  // *      for a 20% penalty that is distributed to everyone else.                   *
  // **********************************************************************************

  bool private initialized;
  IERC20 public token; 
  uint256 public lockupDate;                         // deposits cannot be made after this
  uint256 public minimumTokenCommitment;             // deposited tokens must exceed this amount to lock
  bool public failed;                                // campaign failed to reach minimum and is not subject to lock
  bool public succeeded;                             // campaign reached minimum and is locked
  uint256 public withdrawalsLockedUntilTimestamp;    // time at which haircut-free withdrawal is available.
  mapping (address => uint256) private shareBalance; // internal balance tracking for self-contained campaigns
  uint256 private totalShares;                       // the denominator which decreases faster than the token balance
  IOptiVaultBalanceLookup public shareBalanceLookup; // external balance tracking for use by other contracts
  mapping (address => bool) public withdrawn;        // instead of zeroing share balances, this flag is set.

  function initialize(address _token, uint256 _lockupDate, uint256 _minimumTokenCommitment, uint256 _withdrawalsLockedUntilTimestamp, address _balanceLookup) external {
     require(!initialized);
     token = IERC20(_token);
     lockupDate = _lockupDate;
     minimumTokenCommitment = _minimumTokenCommitment;
     withdrawalsLockedUntilTimestamp = _withdrawalsLockedUntilTimestamp;
     if (lockupDate == 0) {
       totalShares = token.balanceOf(address(this));
     }
     shareBalanceLookup = IOptiVaultBalanceLookup(_balanceLookup);
     initialized = true;
   }
 
  function unlockTimestamp() external view returns (uint256 _unlockTimestamp) {
    _unlockTimestamp = withdrawalsLockedUntilTimestamp;
  }

  function sharesOf(address user) external view returns (uint256 _shares) {
    //Shares in the staking venture.    
    _shares = shareBalance[user];
  }

  function tokenBalanceOf(address user) external view returns (uint256 _amount) {
    //The number of tokens redeemable by the user's share.
    if (withdrawn[msg.sender]) {
      return 0;
    }
    uint256 shares = shareBalanceLookup.sharesOf(user);
    _amount = (shares * token.balanceOf(address(this))) / totalShares;
  }

  function tokenLocked() external view returns (address _token) {
    _token = address(token);
  }

  function withdrawable() public view returns (bool) {
    return (failed || block.timestamp >= withdrawalsLockedUntilTimestamp);
  }

  function contribute(uint tokenAmount) public {
    require(block.timestamp < lockupDate, "OptiVault: Pooling phase has ended.");
    token.transferFrom(msg.sender, address(this), tokenAmount);
    shareBalance[msg.sender] += tokenAmount;
    totalShares += tokenAmount;
    if (token.balanceOf(address(this)) >= minimumTokenCommitment) {
      succeeded = true;
    }
  }

  function fail() public {
    require(block.timestamp > lockupDate, "OptiVault: Still in Pooling phase.");
    require(token.balanceOf(address(this)) < minimumTokenCommitment, "OptiVault: Staking succesful.");
    require(!succeeded, "OptiVault: Campaign already succeeded.");
    require(!failed, "OptiVault: Campaign already marked failed.");
    failed = true;
  }

  function earlyWithdrawTokens() public {
    require(withdrawn[msg.sender] == false, "OptiVault: Already withdrawn.");
    require(block.timestamp > lockupDate, "OptiVault: Still in Pooling phase.");
    require(!withdrawable(), "OptiVault: Staking period has ended.");
    uint userTokenBalance = this.tokenBalanceOf(msg.sender);
    uint userShareBalance = shareBalanceLookup.sharesOf(msg.sender);

    uint toTransfer; 
    if (userShareBalance == totalShares) {
      toTransfer = userTokenBalance;
    } else {
      toTransfer = userTokenBalance * 80 / 100;
    }

    totalShares -= userShareBalance;
    token.transfer(msg.sender, toTransfer);
    withdrawn[msg.sender] = true;
  }

  function withdrawTokens() public {
    require(withdrawable(), "OptiVault: Tokens still locked.");
    require(withdrawn[msg.sender] == false, "OptiVault: Already withdrawn.");
    uint toTransfer =  this.tokenBalanceOf(msg.sender);
    token.transfer(msg.sender, toTransfer);
    totalShares -= shareBalanceLookup.sharesOf(msg.sender);
    withdrawn[msg.sender] = true;
  }
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}