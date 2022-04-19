// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// ███████╗███╗   ██╗███████╗ █████╗ ██╗  ██╗██╗   ██╗     ██████╗  ██████╗ ██████╗ ██╗     ██╗███╗   ██╗███████╗
// ██╔════╝████╗  ██║██╔════╝██╔══██╗██║ ██╔╝╚██╗ ██╔╝    ██╔════╝ ██╔═══██╗██╔══██╗██║     ██║████╗  ██║██╔════╝
// ███████╗██╔██╗ ██║█████╗  ███████║█████╔╝  ╚████╔╝     ██║  ███╗██║   ██║██████╔╝██║     ██║██╔██╗ ██║███████╗
// ╚════██║██║╚██╗██║██╔══╝  ██╔══██║██╔═██╗   ╚██╔╝      ██║   ██║██║   ██║██╔══██╗██║     ██║██║╚██╗██║╚════██║
// ███████║██║ ╚████║███████╗██║  ██║██║  ██╗   ██║       ╚██████╔╝╚██████╔╝██████╔╝███████╗██║██║ ╚████║███████║
// ╚══════╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝        ╚═════╝  ╚═════╝ ╚═════╝ ╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝

// Imports
import "./Ownable.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./ReentrancyGuard.sol";

/**
 * @notice Interface for checking active staked balance of a user.
 */
interface IStaking {
  function getTotalRewards(address staker) external view returns (uint256);
}

/**
 * @title The ERC20 smart contract.
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
  address[] public authorisedLog;
  mapping(address => uint256) public depositedAmount;
  mapping(address => uint256) public spentAmount;
  mapping(address => bool) private _isAuthorised;

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

  /**
   * @notice The smart contract constructor that initializes the contract.
   * @param stakingContract_ The address of the NFT staking smart contract.
   * @param tokenName The name of the token.
   * @param tokenSymbol The symbol of the token.
   */
  constructor(
    address stakingContract_,
    string memory tokenName,
    string memory tokenSymbol
  ) ERC20(tokenName, tokenSymbol) {
    _isAuthorised[_msgSender()] = true;
    withdrawTaxPercent = 25;
    spendTaxPercent = 25;
    stakingContract = IStaking(stakingContract_);
  }

  /**
   * @notice Returns current spendable balance of a specific user. This balance can be spent by user for other collections without
   *         withdrawal to ERC-20 SneakGoblins OR can be withdrawn to ERC-20 SneakGoblins.
   * @param user The user to get the balance of.
   * @return The user balance.
   */
  function getUserBalance(address user) public view returns (uint256) {
    return (stakingContract.getTotalRewards(user) + depositedAmount[user] - spentAmount[user]);
  }

  /**
   * @notice Deposit ERC-20 to the game balance.
   * @param amount The amount of funds to deposit.
   */
  function depositToken(uint256 amount) public nonReentrant whenNotPaused {
    require(!isDepositPaused, "Deposit Paused");
    require(balanceOf(_msgSender()) >= amount, "Insufficient balance");

    _burn(_msgSender(), amount);
    depositedAmount[_msgSender()] += amount;

    emit Deposit(_msgSender(), amount);
  }

  /**
   * @notice Withdraws in-game balance to ERC-20.
   * @param amount The amount of funds to withdraw.
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
   * @notice Transfer in-game funds from one account to another.
   * @param to The receiver address.
   * @param amount The amount of in-game funds to transfer.
   */
  function transferInGameBalance(address to, uint256 amount) public nonReentrant whenNotPaused {
    require(!isTransferPaused, "Transfer Paused");
    require(getUserBalance(_msgSender()) >= amount, "Insufficient balance");

    spentAmount[_msgSender()] += amount;
    depositedAmount[to] += amount;

    emit InternalTransfer(_msgSender(), to, amount);
  }

  /**
   * @notice Spends in-game funds of users in batch. Is used with internal purchases of other NFTs, etc.
   * @param user The array of user addresses.
   * @param amount The array of amount of funds to spend.
   */
  function spendInGameBalanceInBatch(address[] memory user, uint256[] memory amount) public onlyAuthorised nonReentrant {
    require(user.length == amount.length, "Wrong arrays passed");

    for (uint256 i; i < user.length; i++) {
      _spendInGameBalance(user[i], amount[i]);
    }
  }

  /**
   * @notice Spends in-game funds of a user. Is used with internal purchases of other NFTs, etc.
   * @param user The address of the user.
   * @param amount The amount of funds to spend.
   */
  function spendInGameBalance(address user, uint256 amount) public onlyAuthorised nonReentrant {
    _spendInGameBalance(user, amount);
  }

  /**
   * @dev Function to spend user balance. Can be called by other authorised contracts. To be used for internal purchases of other NFTs, etc.
   */
  function _spendInGameBalance(address user, uint256 amount) internal {
    require(getUserBalance(user) >= amount, "Insufficient balance");
    uint256 tax = (amount * spendTaxPercent) / 100;

    spentAmount[user] += amount;
    activeTaxCollectedAmount += tax;

    emit Spend(_msgSender(), user, amount, tax);
  }


  /**
   * @notice Deposits funds to user's in-game balance.
   * @param user The address of the user.
   * @param amount The amount of funds to deposit.
   */
  function depositInGameBalance(address user, uint256 amount) public onlyAuthorised nonReentrant {
    _depositInGameBalance(user, amount);
  }

  /**
   * @notice Distributes funds to users.
   * @param user The array of user addresses.
   * @param amount The array of amount of funds to distribute.
   */
  function distributeInGameBalance(address[] memory user, uint256[] memory amount) public onlyAuthorised nonReentrant {
    require(user.length == amount.length, "Wrong arrays passed");

    for (uint256 i; i < user.length; i++) {
      _depositInGameBalance(user[i], amount[i]);
    }
  }

  /**
   * @notice Mints tokens.
   * @param user The minter address.
   * @param amount The amount of tokens to mint.
   */
  function mint(address user, uint256 amount) external onlyAuthorised nonReentrant {
    _mint(user, amount);
  }

  /**
   * @notice Claims tokens from the tax accumulated pot.
   * @param user The address of the tax funds receiver.
   * @param amount The amount of funds to transfer.
   */
  function claimTax(address user, uint256 amount) public onlyAuthorised nonReentrant {
    require(activeTaxCollectedAmount >= amount, "Insufficient tax balance");

    activeTaxCollectedAmount -= amount;
    depositedAmount[user] += amount;
    taxClaimedAmount += amount;

    emit ClaimTax(_msgSender(), user, amount);
  }

  /**
   * @notice Deposits in-game funds to the user's balance.
   * @param user The address of the user.
   * @param amount The amount of funds to deposit.
   */
  function _depositInGameBalance(address user, uint256 amount) internal {
    require(user != address(0), "Cannot send to 0 address");
    depositedAmount[user] += amount;

    emit DepositFor(_msgSender(), user, amount);
  }

  /*
      ADMIN FUNCTIONS
  */

  /**
   * @notice Authorises  addresses.
   * @param addressToAuth The address to authorise.
   */
  function authorise(address addressToAuth) public onlyOwner {
    _isAuthorised[addressToAuth] = true;
    authorisedLog.push(addressToAuth);
  }

  /**
   * @notice Unauthorises addresses.
   * @param addressToUnAuth The address to unauthorise.
   */
  function unauthorise(address addressToUnAuth) public onlyOwner {
    _isAuthorised[addressToUnAuth] = false;
  }

  /**
   * @notice Sets the staking contract.
   * @param stakingContract_ The address of the staking contract.
   */
  function setStakingContract(address stakingContract_) public onlyOwner {
    stakingContract = IStaking(stakingContract_);
    authorise(stakingContract_);
  }

  /**
   * @notice Sets the withdrawal tax percent.
   * @param taxPercent The tax percentage.
   */
  function setWithdrawTaxPercent(uint256 taxPercent) public onlyOwner {
    require(taxPercent < MAX_TAX_PERCENT, "Wrong value passed");
    withdrawTaxPercent = taxPercent;
  }

  /**
   * @notice Sets the spending tax percent.
   * @param taxPercent The tax percentage.
   */
  function setSpendTaxPercent(uint256 taxPercent) public onlyOwner {
    require(taxPercent < MAX_TAX_PERCENT, "Wrong value passed");
    spendTaxPercent = taxPercent;
  }

  /**
   * @notice Pauses fund transactions.
   * @param _pause The state of the pause.
   */
  function setPauseGameToken(bool _pause) public onlyOwner {
    isPaused = _pause;
  }

  /**
   * @notice Pauses fund transfers.
   * @param _pause The state of the pause.
   */
  function setPauseTransfers(bool _pause) public onlyOwner {
    isTransferPaused = _pause;
  }

  /**
   * @notice Pauses fund withdrawals.
   * @param _pause The state of the pause.
   */
  function setPauseWithdraw(bool _pause) public onlyOwner {
    isWithdrawPaused = _pause;
  }

  /**
   * @notice Pauses fund deposits.
   * @param _pause The state of the pause.
   */
  function setPauseDeposits(bool _pause) public onlyOwner {
    isDepositPaused = _pause;
  }

  /**
   * @notice Burns the tokens.
   * @notice The amount of tokens to burn.
   */
  function burn(uint256 amount) external onlyOwner {
    _burn(_msgSender(), amount);
  }

  /**
   * @notice Withdraws ETH accidentally dropped to the contract.
   */
  function rescue() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }
}