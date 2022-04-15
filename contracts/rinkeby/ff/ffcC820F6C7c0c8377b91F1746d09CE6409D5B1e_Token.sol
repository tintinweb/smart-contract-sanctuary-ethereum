// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Ownable.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./ReentrancyGuard.sol";

/**
 * @dev Interface for checking active staked balance of a user.
 */
interface IStaking {
  function getTotalRewards(address staker) external view returns (uint256);
}

/**
 * @dev Implementation of the {IERC20} interface.
 */
contract Token is ERC20, ReentrancyGuard, Ownable {
  IStaking public stakingContract;

  uint256 public MAX_SUPPLY;
  uint256 public constant MAX_TAX_PERCENT = 100;

  uint256 public spendTaxPercent;
  uint256 public withdrawTaxPercent;

  uint256 public taxClaimedAmount;
  uint256 public activeTaxCollectedAmount;

  bool public isPaused;
  bool public isDepositPaused;
  bool public isWithdrawPaused;
  bool public isTransferPaused;

  mapping(address => bool) private _isAuthorised;
  address[] public authorisedLog;

  mapping(address => uint256) public depositedAmount;
  mapping(address => uint256) public spentAmount;

  modifier onlyAuthorised() {
    require(_isAuthorised[_msgSender()], "Not Authorised");
    _;
  }

  modifier whenNotPaused() {
    require(!isPaused, "Token game is paused");
    _;
  }

  event Withdraw(address indexed userAddress, uint256 amount, uint256 tax);
  event Deposit(address indexed userAddress, uint256 amount);
  event DepositFor(address indexed caller, address indexed userAddress, uint256 amount);
  event Spend(address indexed caller, address indexed userAddress, uint256 amount, uint256 tax);
  event ClaimTax(address indexed caller, address indexed userAddress, uint256 amount);
  event InternalTransfer(address indexed from, address indexed to, uint256 amount);

  constructor(
    address stakingContract_,
    string memory tokenName,
    string memory tokenSymbol
  ) ERC20(tokenName, tokenSymbol) {
    _isAuthorised[_msgSender()] = true;
    isPaused = true;
    isTransferPaused = true;

    withdrawTaxPercent = 25;
    spendTaxPercent = 25;

    stakingContract = IStaking(stakingContract_);
  }

  /**
   * @dev Returnes current spendable balance of a specific user. This balance can be spent by user for other collections without
   *      withdrawal to ERC-20 SneakGoblins OR can be withdrawn to ERC-20 SneakGoblins.
   */
  function getUserBalance(address user) public view returns (uint256) {
    return (stakingContract.getTotalRewards(user) + depositedAmount[user] - spentAmount[user]);
  }

  /**
   * @dev Function to deposit ERC-20 SneakGoblins to the game balance.
   */
  function depositToken(uint256 amount) public nonReentrant whenNotPaused {
    require(!isDepositPaused, "Deposit Paused");
    require(balanceOf(_msgSender()) >= amount, "Insufficient balance");

    _burn(_msgSender(), amount);
    depositedAmount[_msgSender()] += amount;

    emit Deposit(_msgSender(), amount);
  }

  /**
   * @dev Function to withdraw game SneakGoblins to ERC-20 SneakGoblins.
   */
  function withdrawToken(uint256 amount) public nonReentrant whenNotPaused {
    require(!isWithdrawPaused, "Withdraw Paused");
    require(getUserBalance(_msgSender()) >= amount, "Insufficient balance");
    uint256 tax = (amount * withdrawTaxPercent) / 100;

    spentAmount[_msgSender()] += amount;
    activeTaxCollectedAmount += tax;
    _mint(_msgSender(), (amount - tax));

    emit Withdraw(_msgSender(), amount, tax);
  }

  /**
   * @dev Function to transfer game SneakGoblins from one account to another.
   */
  function transferInGameBalance(address to, uint256 amount) public nonReentrant whenNotPaused {
    require(!isTransferPaused, "Transfer Paused");
    require(getUserBalance(_msgSender()) >= amount, "Insufficient balance");

    spentAmount[_msgSender()] += amount;
    depositedAmount[to] += amount;

    emit InternalTransfer(_msgSender(), to, amount);
  }
  /**
   * @dev Function to spend user balance in batch. Can be called by other authorised contracts. To be used for internal purchases of other NFTs, etc.
   */
  function spendInGameBalanceInBatch(address[] memory user, uint256[] memory amount) public onlyAuthorised nonReentrant {
    require(user.length == amount.length, "Wrong arrays passed");

    for (uint256 i; i < user.length; i++) {
      spendInGameBalance(user[i], amount[i]);
    }
  }

  /**
   * @dev Function to spend user balance. Can be called by other authorised contracts. To be used for internal purchases of other NFTs, etc.
   */
  function spendInGameBalance(address user, uint256 amount) public onlyAuthorised nonReentrant {
    require(getUserBalance(user) >= amount, "Insufficient balance");
    uint256 tax = (amount * spendTaxPercent) / 100;

    spentAmount[user] += amount;
    activeTaxCollectedAmount += tax;

    emit Spend(_msgSender(), user, amount, tax);
  }

  /**
   * @dev Function to deposit tokens to a user balance. Can be only called by an authorised contracts.
   */
  function depositInGameBalance(address user, uint256 amount) public onlyAuthorised nonReentrant {
    _depositInGameBalance(user, amount);
  }

  /**
   * @dev Function to tokens to the user balances. Can be only called by an authorised users.
   */
  function distributeInGameBalance(address[] memory user, uint256[] memory amount) public onlyAuthorised nonReentrant {
    require(user.length == amount.length, "Wrong arrays passed");

    for (uint256 i; i < user.length; i++) {
      _depositInGameBalance(user[i], amount[i]);
    }
  }

  function _depositInGameBalance(address user, uint256 amount) internal {
    require(user != address(0), "Cannot send to 0 address");
    depositedAmount[user] += amount;

    emit DepositFor(_msgSender(), user, amount);
  }

  /**
   * @dev Function to mint tokens to a user balance. Can be only called by an authorised contracts.
   */
  function mint(address user, uint256 amount) external onlyAuthorised nonReentrant {
    _mint(user, amount);
  }

  /**
   * @dev Function to claim tokens from the tax accumulated pot. Can be only called by an authorised contracts.
   */
  function claimTax(address user, uint256 amount) public onlyAuthorised nonReentrant {
    require(activeTaxCollectedAmount >= amount, "Insufficiend tax balance");

    activeTaxCollectedAmount -= amount;
    depositedAmount[user] += amount;
    taxClaimedAmount += amount;

    emit ClaimTax(_msgSender(), user, amount);
  }

  /*
      ADMIN FUNCTIONS
  */

  /**
   * @dev Function allows admin add authorised address. The function also logs what addresses were authorised for transparancy.
   */
  function authorise(address addressToAuth) public onlyOwner {
    _isAuthorised[addressToAuth] = true;
    authorisedLog.push(addressToAuth);
  }

  /**
   * @dev Function allows admin add unauthorised address.
   */
  function unauthorise(address addressToUnAuth) public onlyOwner {
    _isAuthorised[addressToUnAuth] = false;
  }

  /**
   * @dev Function allows admin update the address of staking address.
   */
  function changeStakingContract(address stakingContract_) public onlyOwner {
    stakingContract = IStaking(stakingContract_);
    authorise(stakingContract_);
  }

  /**
   * @dev Function allows admin to update limmit of tax on withdraw.
   */
  function updateWithdrawTaxPercent(uint256 taxPercent) public onlyOwner {
    require(taxPercent < MAX_TAX_PERCENT, "Wrong value passed");
    withdrawTaxPercent = taxPercent;
  }

  /**
   * @dev Function allows admin to update tax amount on spend.
   */
  function updateSpendTaxPercent(uint256 taxPercent) public onlyOwner {
    require(taxPercent < MAX_TAX_PERCENT, "Wrong value passed");
    spendTaxPercent = taxPercent;
  }

  /**
   * @dev Function allows admin to pause all in game SneakyGoblins transfactions.
   */
  function pauseGameToken(bool _pause) public onlyOwner {
    isPaused = _pause;
  }

  /**
   * @dev Function allows admin to pause in game SneakyGoblins transfers.
   */
  function pauseTransfers(bool _pause) public onlyOwner {
    isTransferPaused = _pause;
  }

  /**
   * @dev Function allows admin to pause in game SneakyGoblins withdraw.
   */
  function pauseWithdraw(bool _pause) public onlyOwner {
    isWithdrawPaused = _pause;
  }

  /**
   * @dev Function allows admin to pause in game SneakyGoblins deposit.
   */
  function pauseDeposits(bool _pause) public onlyOwner {
    isDepositPaused = _pause;
  }

  function burn(uint256 amount) external onlyOwner {
    _burn(_msgSender(), amount);
  }

  /**
   * @dev Function allows admin to withdraw ETH accidentally dropped to the contract.
   */
  function rescue() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }
}