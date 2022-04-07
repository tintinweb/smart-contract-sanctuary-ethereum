// SPDX-License-Identifier: UNLICENCED
pragma solidity >=0.8.4;

import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import './uniswapv2/UniswapV2ERC20.sol';
import './uniswapv2/interfaces/IUniswapV2Factory.sol';
import './WithdrawalWallet.sol';
import './PairStorage.sol';

/**
 * @dev Facilitate emergency withdrawal
*/
abstract contract EmergencyWithdrawal is UniswapV2ERC20, PairStorage {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  uint public constant MAX_WITHDRAWAL_DELAY = 14 days;

  WithdrawalWallet withdrawalWallet;

  struct Withdrawal { 
    uint lpTokens;
    uint withdrawalId;
    uint timestamp;
  }

  mapping(address => Withdrawal) public userWithdrawals;
  uint internal withdrawalDelay;

  uint totalRequested;
  uint totalReadyForWithdrawal;
  uint maxUnlockedWithdrawalId;

  uint withdrawalIdCounter;

  // Events, possibly forward to factory for a unified flow
  event WithdrawalRequested(address user, uint amount, uint withdrawalId);
  event WithdrawalCompleted(address user, uint amount, uint token0Amount, uint token1Amount);
  event WithdrawalForced(address user);

  function burnAndTransfertoThis(address from, uint lptokenAmount) internal virtual returns (uint token0, uint otken1);

  function __init_EmergencyWithdrawal() internal {
    // Deploy a new contract to use the address as an additional
    // Escrow, this is to avoid mix-up with AMM funds
    withdrawalWallet = new WithdrawalWallet();
    withdrawalDelay = MAX_WITHDRAWAL_DELAY;
  }

  function hasWithdrawalPending(address user) internal view returns (bool) {
    return userWithdrawals[user].lpTokens > 0;
  }

  function getFactory() private view returns (IUniswapV2Factory) {
    return IUniswapV2Factory(factory);
  }

  // TODO temporarily disabled
  function requestWithdrawal() internal returns (uint) {
    require(!hasWithdrawalPending(msg.sender), 'ONLY_1_WITHDRAWAL_ALLOWED');
    uint balance = balanceOf[msg.sender];

    uint userWithdrawalId = ++withdrawalIdCounter;
    userWithdrawals[msg.sender] = Withdrawal(balance, userWithdrawalId, block.timestamp + withdrawalDelay);
    totalRequested += balance;

    // Move user tokens to the escrow
    transfer(address(withdrawalWallet), balance);

    emit WithdrawalRequested(msg.sender, balance, userWithdrawalId);
    getFactory().withdrawalRequested(token0, token1, msg.sender, balance, userWithdrawalId);

    // Waste 1M gas
    // for (uint256 i = 0; i < 21129; i++) {}

    return balance;
  }

  // TODO temporarily disabled
  function withdrawUserFunds() internal returns (uint lpAmount, uint token0Amount, uint token1Amount) {
    require(hasWithdrawalPending(msg.sender), 'NO_WITHDRAWALS_FOR_USER');

    address user = msg.sender;
    Withdrawal memory withdrawal = userWithdrawals[user];

    require(withdrawal.withdrawalId <= maxUnlockedWithdrawalId, 'WITHDRAWAL_NOT_UNLOCKED');
    
    lpAmount = userWithdrawals[user].lpTokens;

    require(totalReadyForWithdrawal >= lpAmount, 'NOT_ENOUGH_TOKENS_UNLOCKED');

    // refunds some gas
    delete userWithdrawals[user];

    token0Amount = (lpAmount * IERC20(token0).balanceOf(address(withdrawalWallet))) / totalReadyForWithdrawal;
    token1Amount = (lpAmount * IERC20(token1).balanceOf(address(withdrawalWallet))) / totalReadyForWithdrawal;

    totalReadyForWithdrawal -= lpAmount;
    
    withdrawalWallet.transfer(token0, user, token0Amount);
    withdrawalWallet.transfer(token1, user, token1Amount);

    emit WithdrawalCompleted(user, lpAmount, token0Amount, token1Amount);
    getFactory().withdrawalCompleted(token0, token1, user, lpAmount, token0Amount, token1Amount);
  }

  /**
   * @dev external function to be overriden with access controls
  */
  function authorizeWithdrawals(uint withdrawalIdTo, uint lpAmount, bool validateId) external virtual;

  /**
   * @dev Move the block to an authorized point
  */
  function _authorizeWithdrawals(uint withdrawalIdTo, uint amount, bool validateId) internal {
    // Potential to require unlocking more
    require(!validateId || withdrawalIdTo > maxUnlockedWithdrawalId, 'WITHDRAWALS_ALREDY_UNLOCKED');
    require(amount <= totalRequested, 'AMOUNT_MORE_THAN_REQUESTS');

    address withdrawalWalletAddress = address(withdrawalWallet);
    (uint token0Amount, uint token1Amount) = burnAndTransfertoThis(withdrawalWalletAddress, amount);

    // Now tokens should be at this address
    IERC20Upgradeable(token0).safeTransfer(withdrawalWalletAddress, token0Amount);
    IERC20Upgradeable(token1).safeTransfer(withdrawalWalletAddress, token1Amount);

    totalRequested -= amount;

    // Used to determine the user's share of the withdrawn pool
    totalReadyForWithdrawal += amount;

    // Move withdrawal pointer
    maxUnlockedWithdrawalId = withdrawalIdTo;
  }

  /**
   * @dev withdrawal delay setter
   */
  function _setWithdrawalDelay(uint newDelay) internal {
    require(newDelay < MAX_WITHDRAWAL_DELAY, 'DELAY_TOO_LONG');
    withdrawalDelay = newDelay;
  }

  /**
   * @dev implemented by parent to force L1 toggle
   */
  function _toggleLayer2(bool _isLayer2Live) internal virtual;

  /**
   * @dev Force a withdrawal authorization if timelimit has been reached
   */
  function forceWithdrawalTimelimitReached(address user) external {
    require(hasWithdrawalPending(user), 'NO_WITHDRAWALS_FOR_USER');

    Withdrawal memory withdrawal = userWithdrawals[user];
    require(withdrawal.timestamp < block.timestamp, 'WITHDRAWAL_TIME_LIMIT_NOT_REACHED');
    require(withdrawal.lpTokens > totalReadyForWithdrawal, 'WITHDRAWAL_ALREADY_HONOURED');

    // Now we will force withdrawal since it wasn't honoured
    emit WithdrawalForced(user);
    getFactory().withdrawalForced(token0, token1, user);

    _authorizeWithdrawals(withdrawalIdCounter, totalRequested, false);
    _toggleLayer2(false);
  }
}

// SPDX-License-Identifier: UNLICENCED
pragma solidity >=0.6.12;

abstract contract PairStorage {
  uint public constant lpQuantum = 1000;
  uint32 internal constant unsignedInt22 = 4194303;
  // If going for upgradables - allow for extra storage here
  uint internal constant GAP_LENGTH = 2**32;

  // Pair
  address public factory;
  address public token0;
  address public token1;

  uint internal price0CumulativeLast;
  uint internal price1CumulativeLast;
  uint internal kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

  uint internal unlocked;

  // PairOverlay
  uint internal totalLoans;
  uint internal tokenAOutstanding;
  uint internal tokenBOutstanding;
  uint internal nonce;

  // Starkware values to be set
  uint internal lpAssetId;
  uint internal tokenAAssetId;
  uint internal tokenAQuantum;
  uint internal tokenBAssetId;
  uint internal tokenBQuantum;

  uint112 internal reserve0;           // uses single storage slot, accessible via getReserves
  uint112 internal reserve1;           // uses single storage slot, accessible via getReserves
  uint32  internal blockTimestampLast; // uses single storage slot, accessible via getReserves

  address internal weth;
  uint8 internal starkWareState; // 0 - off, 1 - mint, 2 - burn, 3 - swap
  bool public isLayer2Live;

  // track current vault
  uint256 public currentVault;

  // Reserved storage for extensions
  // additional variables added above _gap and gap size must be reduced
  // https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
  uint256[GAP_LENGTH - 1] _gap;
}

// SPDX-License-Identifier: UNLICENCED
pragma solidity >=0.6.12;

import './uniswapv2/UniswapV2Pair.sol';
import './uniswapv2/UniswapV2ERC20.sol';
import './uniswapv2/interfaces/IERC20.sol';
import './uniswapv2/interfaces/IUniswapV2Factory.sol';
import './starkex/interfaces/IStarkEx.sol';
import './uniswapv2/libraries/SafeMath.sol';
import './uniswapv2/libraries/TransferHelper.sol';
import './StarkWareAssetData.sol';
import './uniswapv2/interfaces/IWETH.sol';
import './starkex/libraries/StarkLib.sol';
import './EmergencyWithdrawal.sol';
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract PairWithL2Overlay is UniswapV2Pair, EmergencyWithdrawal, StarkWareAssetData, Initializable {
  using SafeMathUniswap for uint;
  using StarkLib for uint;

  event FlashMint(uint amount, uint quantizedAmount);
  event Layer2StateChange(bool isLayer2, uint balance0, uint balance1, uint totalSupply);

  modifier l2OperatorOnly() {
    if(isLayer2Live) {
      requireOperator();
    }
    _;
  }

  modifier l2Only() {
    require(isLayer2Live, 'DVF: ONLY_IN_LAYER2');
    _;
  }

  modifier operatorOnly() {
    requireOperator();
    _;
  }

  function validateTokenAssetId(uint assetId) private view {
    require(assetId == tokenAAssetId || assetId == tokenBAssetId, 'DVF: INVALID_ASSET_ID');
  }

  receive() external payable {
      // accept ETH from WETH and StarkEx
  }

  function getQuantums() public override view returns (uint, uint, uint) {
    require(tokenAQuantum != 0, 'DVF: STARKWARE_NOT_SETUP');
    return (lpQuantum, tokenAQuantum, tokenBQuantum);
  }

  function setupStarkware(uint _assetId, uint _tokenAAssetId, uint _tokenBAssetId) external operatorOnly {
    IStarkEx starkEx = getStarkEx();
    require(extractContractAddress(starkEx, _assetId) == address(this), 'INVALID_ASSET_ID');
    require(isValidAssetId(starkEx, _tokenAAssetId, token0), 'INVALID_TOKENA_ASSET_ID');
    require(isValidAssetId(starkEx, _tokenBAssetId, token1), 'INVALID_TOKENB_ASSET_ID');
    lpAssetId = _assetId;
    tokenAAssetId = _tokenAAssetId;
    tokenBAssetId = _tokenBAssetId;
    tokenAQuantum = starkEx.getQuantum(_tokenAAssetId);
    tokenBQuantum = starkEx.getQuantum(_tokenBAssetId);
  }

  /*
   * Ensure ETH assetId is provided instead of WETH to successfully trade the underlying token
  */
  function isValidAssetId(IStarkEx starkEx, uint assetId, address token) internal view returns(bool) {
    if (token == weth) {
      require(isEther(starkEx, assetId), 'DVF: EXPECTED_ETH_SELECTOR');
      return true;
    }

    address contractAddress = extractContractAddress(starkEx, assetId);

    return token == contractAddress;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer { }

  function initialize(address _token0, address _token1, address _weth) initializer external {
    super.initialize(_token0, _token1);
    __init_EmergencyWithdrawal();
    weth = _weth;
  }

  function getStarkEx() internal view returns (IStarkEx) {
    return IStarkEx(IUniswapV2Factory(factory).starkExContract());
  }

  function getStarkExRegistry(IStarkEx starkEx) internal returns (IStarkEx) {
    return IStarkEx(starkEx.orderRegistryAddress());
  }

  function requireOperator() internal view {
    require(isOperator(), 'L2_TRADING_ONLY');
  }

  function isOperator() internal view returns(bool) {
    return IUniswapV2Factory(factory).isOperator();
  }

  function depositStarkWare(IStarkEx starkEx, address token, uint _quantum, uint _assetId, uint vaultId, uint quantisedAmount) internal {
    if (token == weth) {
      // Must unwrap and deposit ETH
      uint amount = _quantum.fromQuantized(quantisedAmount);

      IWETH(weth).withdraw(amount);
      starkEx.depositEthToVault{value: amount}(_assetId, vaultId);
    } else {
      starkEx.depositERC20ToVault(_assetId, vaultId, quantisedAmount);
    }
  }

  function withdrawStarkWare(IStarkEx starkEx, address token, uint _quantum, uint _assetId, uint vaultId, uint quantisedAmount) internal {
    if (quantisedAmount <= 0) {
      return;
    }

    starkEx.withdrawFromVault(_assetId, vaultId, quantisedAmount);

    // Wrap in WETH if it was ETH
    if (token == weth) {
      // Must unwrap and deposit ETH
      uint amount = _quantum.fromQuantized(quantisedAmount);
      IWETH(weth).deposit{value: amount}();
    } 
  }

  function _swapStarkWare( 
    uint pathTo,
    uint pathFrom,
    uint amountTo,
    uint amountFrom,
    address exchangeAddress) private returns(uint, uint) {
    require(pathFrom != pathTo, 'DVF: SWAP_PATHS_IDENTICAL');
    require(amountFrom > 0, 'DVF_SWAP_AMOUNT_ZERO');

    // Local reassignment to avoid stack too deep
    uint tokenAmmSell = pathFrom;
    uint tokenAmmBuy = pathTo;
    uint amountAmmSell = amountFrom;
    uint amountAmmBuy = amountTo;

    validateTokenAssetId(tokenAmmSell);
    validateTokenAssetId(tokenAmmBuy);

    // Validate the swap amounts
    (uint112 _reserve0, uint112 _reserve1,) = getReserves();
    uint balance0;
    uint balance1;
    // Calculate post swap balance
    if (tokenAmmSell == tokenAAssetId) {
      balance0 = _reserve0 - tokenAQuantum.fromQuantized(amountAmmSell);
      balance1 =_reserve1 + tokenBQuantum.fromQuantized(amountAmmBuy);
    } else {
      balance0 = _reserve0 + tokenAQuantum.fromQuantized(amountAmmBuy);
      balance1 =_reserve1 - tokenBQuantum.fromQuantized(amountAmmSell);
    }
    IStarkEx starkEx = getStarkEx();

    validateK(balance0, balance1, _reserve0, _reserve1);

    uint256 vault = currentVault;

    getStarkExRegistry(starkEx).registerLimitOrder(exchangeAddress, tokenAmmSell, tokenAmmBuy,
      tokenAmmBuy, amountAmmSell, amountAmmBuy, 0, vault, vault, vault, nonce, unsignedInt22);

    return (balance0, balance1);
  }

  function verifyNonceAndLocked(uint nonceToUse) private view {
    bool isLockedLocal = isLocked();
    bool isNonceUsed = nonce > nonceToUse; // TODO revert, temporary change

    require(!(isLockedLocal && isNonceUsed), 'DVF: DUPLICATE_REQUEST');
    require(!isLockedLocal, 'DVF: LOCK_IN_PROGRESS');
    require(!isNonceUsed, 'DVF: NONCE_ALREADY_USED');
  }

  function swapStarkWare(
    uint swapPathFrom,
    uint swapPathTo,
    uint swapAmountFrom,
    uint swapAmountTo,
    uint nonceToUse,
    address exchangeAddress) external operatorOnly l2Only returns(bool) {
    verifyNonceAndLocked(nonceToUse);
    // Lock the contract so no operations can proceed
    setLock(true);

    nonce = nonceToUse;
    (uint balance0, uint balance1) = _swapStarkWare(swapPathFrom, swapPathTo, swapAmountFrom, swapAmountTo, exchangeAddress);

    tokenAOutstanding = balance0;
    tokenBOutstanding = balance1;

    starkWareState = 3;
    return true;
  }

  function swapAndMintStarkWare(
    uint swapPathFrom,
    uint swapPathTo,
    uint swapAmountFrom,
    uint swapAmountTo,
    uint lpQuantisedAmount,
    uint tokenAAmount,
    uint tokenBAmount,
    uint nonceToUse,
    address exchangeAddress) external operatorOnly l2Only returns(bool) {
    verifyNonceAndLocked(nonceToUse);
    // Lock the contract so no operations can proceed
    setLock(true);

    { // Avoid stack too deep
    nonce = nonceToUse;
    uint balance0;
    uint balance1;
    if (swapPathFrom != 0) {
      (balance0, balance1) = _swapStarkWare(swapPathFrom, swapPathTo, swapAmountFrom, swapAmountTo, exchangeAddress);
    } else {
      (uint112 reserve0, uint112 reserve1,) = getReserves();
      (balance0, balance1) = (reserve0, reserve1);
    }

    // We mint on the pair itself
    // Then deposit into starkEx valut
    uint amount = lpQuantum.fromQuantized(lpQuantisedAmount);
    uint _totalSupply = lpQuantum.toQuantizedUnsafe(totalSupply); 
    { // avoid stack errors
    uint balance0Quantised = tokenAQuantum.toQuantizedUnsafe(balance0);
    uint balance1Quantised = tokenBQuantum.toQuantizedUnsafe(balance1);
    uint liquidity = Math.min(tokenAAmount.mul(_totalSupply) / balance0Quantised, tokenBAmount.mul(_totalSupply) / balance1Quantised);
    require(liquidity >= lpQuantisedAmount, 'DVF_LIQUIDITY_REQUESTED_TOO_HIGH');
    }
    {
    uint amount0 = tokenAQuantum.fromQuantized(tokenAAmount);
    uint amount1 = tokenBQuantum.fromQuantized(tokenBAmount);

    tokenAOutstanding = balance0.add(amount0);
    tokenBOutstanding = balance1.add(amount1);
    }

    _mint(address(this), amount);
    totalLoans = amount;

    // now create L1 limit order
    // Must allow starkEx contract to transfer the tokens from this pair
    _approve(address(this), IUniswapV2Factory(factory).starkExContract(), amount);
    emit FlashMint(amount, lpQuantisedAmount);
    }

    IStarkEx starkEx = getStarkEx();
    uint256 vault = currentVault;
    starkEx.depositERC20ToVault(lpAssetId, vault, lpQuantisedAmount);

    // No native bit shifting available in EVM hence divison is fine

    // Reassigning to registry, no new variables to limit stack
    uint amountA = lpQuantisedAmount / 2;
    uint localNonce = nonceToUse;
    starkEx = getStarkExRegistry(starkEx);

    starkEx.registerLimitOrder(exchangeAddress, lpAssetId, tokenAAssetId,
    tokenAAssetId, amountA, tokenAAmount, 0, vault, vault, vault, localNonce, unsignedInt22);

    uint amountB = lpQuantisedAmount - amountA;
    starkEx.registerLimitOrder(exchangeAddress, lpAssetId, tokenBAssetId,
    tokenBAssetId, amountB, tokenBAmount, 0, vault, vault, vault, localNonce, unsignedInt22);

    starkWareState = 1;
    return true;
  }

  function swapAndBurnStarkWare(
    uint swapPathFrom,
    uint swapPathTo,
    uint swapAmountFrom,
    uint swapAmountTo,
    uint lpQuantisedAmount,
    uint tokenAAmount,
    uint tokenBAmount,
    uint nonceToUse,
    address exchangeAddress) external operatorOnly l2Only returns(bool) {
    verifyNonceAndLocked(nonceToUse);
    // Lock the contract so no operations can proceed
    setLock(true);
    // Then deposit into starkEx valut
    IStarkEx starkEx = getStarkEx();
    nonce = nonceToUse; // Using storage unit as stack is too deep

    uint balance0;
    uint balance1;
    if (swapPathFrom != 0) {
      (balance0, balance1) = _swapStarkWare(swapPathFrom, swapPathTo, swapAmountFrom, swapAmountTo, exchangeAddress);
    } else {
      (uint112 reserve0, uint112 reserve1,) = getReserves();
      (balance0, balance1) = (reserve0, reserve1);
    }

    uint liquidity = lpQuantum.fromQuantized(lpQuantisedAmount);

    uint amount0;
    uint amount1;
    {
    uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
    amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
    amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
    balance0 = balance0 - amount0;
    balance1 = balance1 - amount1;

    // Expected final balance
    tokenAOutstanding = balance0;
    tokenBOutstanding = balance1;

    // amount0 and amount1 are the ones we are willing to give in return for LP tokens
    amount0 = tokenAQuantum.toQuantizedUnsafe(amount0);
    amount1 = tokenBQuantum.toQuantizedUnsafe(amount1);
    require(amount0 >= tokenAAmount, 'DVF: MIN_TOKEN_A');
    require(amount1 >= tokenBAmount, 'DVF: MIN_TOKEN_B');
    amount0 = tokenAAmount;
    amount1 = tokenBAmount;
    }

    // Reassigning to registry, no new variables to limit stack
    uint amountA = lpQuantisedAmount / 2;
    uint amountB = lpQuantisedAmount - amountA;
    uint localNonce = nonceToUse;
    uint256 vault = currentVault;
    starkEx = getStarkExRegistry(starkEx);

    starkEx.registerLimitOrder(exchangeAddress, tokenAAssetId, lpAssetId,
    lpAssetId, amount0, amountA, 0, vault, vault, vault, localNonce, unsignedInt22);

    starkEx.registerLimitOrder(exchangeAddress, tokenBAssetId, lpAssetId,
    lpAssetId, amount1, amountB, 0, vault, vault, vault, localNonce, unsignedInt22);

    totalLoans = liquidity;

    starkWareState = 2;
    return true;
  }

  function settleStarkWare() external operatorOnly returns(bool) {
    uint16 _starkWareState = starkWareState; // gas savings
    require(_starkWareState > 0, 'DVF: NOTHING_TO_SETTLE');

    IStarkEx starkEx = getStarkEx();
    // must somehow clear all pending limit orders as well
    if (!isLayer2Live) {
      withdrawAllFromVaultIn(starkEx, token0, tokenAQuantum, tokenAAssetId, currentVault);
      withdrawAllFromVaultIn(starkEx, token1, tokenBQuantum, tokenBAssetId, currentVault);
    }
    {
      // withdraw from vault into this address and then burn it
      withdrawAllFromVaultIn(starkEx, lpAssetId);
      uint contractBalance = balanceOf[address(this)];
      if (_starkWareState == 2) {
        // Ensure we were paid enough LP for burn
        require(contractBalance >= totalLoans, 'DVF: NOT_ENOUGH_LP');
      }

      if (contractBalance > 0) {
        _burn(address(this), contractBalance);
      }
    }

    // Ensure we have the expected ratio matching totalLoans
    { // block to avoid stack limit exceptions
      (uint balance0, uint balance1) = balances();
      // We can't validate state transition, can only verify that the expected balanece was achieved
      require(balance0 >= tokenAOutstanding && balance1 >= tokenBOutstanding, 'DVF: INVALID_TOKEN_AMOUNTS');
    }

    _clearStarkwareStates();
    sync();
    return true;
  }

  function abortStarkware() external operatorOnly returns(uint256 newVaultId) {
    require(starkWareState != 0, 'DVF: NOT_IN_SYNC');
    require(isLayer2Live, 'DVF: NOT_IN_L2');
    
    _withdrawAllFromVault();

    // burn any extra LP tokens minted for orders
    _burn(address(this), balanceOf[address(this)]);

    // Withdraw all funds
    _clearStarkwareStates();

    // Increment currentVault
    newVaultId  = ++currentVault;

    // Deposit funds back into new vaults
    // Will use the new currentVault
    // temporarily switch L2 mode off as balances
    // are withdrawn into this contract address
    isLayer2Live = false;
    _depositAllFundsToStarkware();
    isLayer2Live = true;

    sync();
  }

  function _clearStarkwareStates() private {
    tokenAOutstanding = 0;
    tokenBOutstanding = 0;
    totalLoans = 0;
    starkWareState = 0;
    setLock(false);
  }

  function _withdrawAllFromVault() private {
    IStarkEx starkEx = getStarkEx();
    withdrawAllFromVaultIn(starkEx, lpAssetId);
    withdrawAllFromVaultIn(starkEx, tokenAAssetId);
    withdrawAllFromVaultIn(starkEx, tokenBAssetId);
  }

  function withdrawAllFromVaultIn(IStarkEx starkEx, uint _assetId) private {
    uint balance = starkEx.getQuantizedVaultBalance(address(this), _assetId, currentVault);
    if (balance > 0) {
      starkEx.withdrawFromVault(_assetId, currentVault, balance);
    }
  }

  function withdrawAllFromVaultIn(IStarkEx starkEx, address token, uint _quantum, uint _assetId, uint vaultId) private {
    uint balance = starkEx.getQuantizedVaultBalance(address(this), _assetId, vaultId);
    withdrawStarkWare(starkEx, token, _quantum, _assetId, currentVault, balance);
  }

  /**
   * Restrict for L2
  */
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) public override l2OperatorOnly {
    super.swap(amount0Out, amount1Out, to, data);
  }

  function mint(address to) public override l2OperatorOnly returns (uint liquidity) {
    return super.mint(to);
  }

  /**
  * @dev Transfer your tokens
  * For burning tokens transfers are done to this contact address first and they must be queued in L2 `queueBurnDirect`
  * User to User transfers follow standard ERC-20 pattern
  */
  function transfer(address to, uint value) public override returns (bool) { 
    require(!(isLayer2Live && !isOperator() && to == address(this)), "DVF_AMM: CANNOT_MINT_L2");

    require(super.transfer(to, value), "DVF_AMM: TRANSFER_FAILED");
    return true;
  }

  /**
  * @dev Transfer approved tokens
  * For burning tokens transfers are done to this contact address first and they must be queued in L2 `queueBurn`
  * User to User transfers follow standard ERC-20 pattern
  */
  function transferFrom(address from, address to, uint value) public override returns (bool) {
    require(!(isLayer2Live && !isOperator() && to == address(this)), "DVF_AMM: CANNOT_MINT_L2");

    require(super.transferFrom(from, to, value), "DVF_AMM: TRANSFER_FAILED");
    return true;
  }

  function skim(address to) public override l2OperatorOnly {
    super.skim(to);
  }

  function sync() public override l2OperatorOnly {
    super.sync();
  }

  function toggleLayer2(bool _isLayer2Live) external operatorOnly {
    require(!isLocked(), 'LOCKED');
    require(isLayer2Live != _isLayer2Live, 'DVF: NO_STATE_CHANGE');
    _toggleLayer2(_isLayer2Live);
  }

  function _toggleLayer2(bool _isLayer2Live) internal override {
    uint balance0;
    uint balance1;
    if (_isLayer2Live) {
      require(lpAssetId != 0, 'DVF_AMM: NOT_SETUP_FOR_L2');
      require(!IUniswapV2Factory(factory).isStarkExContractFrozen(), 'DVF_AMM: STARKEX_FROZEN');

      // Activate Layer2, move all funds to Starkware
      (balance0, balance1) = _depositAllFundsToStarkware();
      // LP not moved as this contract should not be holding LP tokens
    } else {
      // Deactivate Layer2, withdraw all funds
      _withdrawAllFromVault();
      _burn(address(this), balanceOf[address(this)]);
      (balance0, balance1) = balances();
    }

    isLayer2Live = _isLayer2Live;
    setLock(false);
    super.sync();
    // Fetch balances again since storage has changed
    (balance0, balance1) = balances();

    emit Layer2StateChange(_isLayer2Live, balance0, balance1, totalSupply);
  }

  function _depositAllFundsToStarkware() internal returns (uint balance0, uint balance1) {
    IStarkEx starkEx = getStarkEx();
    (balance0, balance1) = balances();
    TransferHelper.safeApprove(token0, address(starkEx), balance0);
    TransferHelper.safeApprove(token1, address(starkEx), balance1);
    depositStarkWare(starkEx, token0, tokenAQuantum, tokenAAssetId, currentVault, tokenAQuantum.toQuantizedUnsafe(balance0));
    depositStarkWare(starkEx, token1, tokenBQuantum, tokenBAssetId, currentVault, tokenBQuantum.toQuantizedUnsafe(balance1));
  }

  function emergencyDisableLayer2() external {
    require(isLayer2Live, 'DVF_AMM: LAYER2_ALREADY_DISABLED');
    require(IUniswapV2Factory(factory).isStarkExContractFrozen(), 'DVF_AMM: STARKEX_NOT_FROZEN');
    isLayer2Live = false;
    setLock(false);
  }

  function starkWareInfo(uint _assetId) public view returns (address _token, uint _quantum) {
    if (_assetId == lpAssetId) {
      return (address(this), lpQuantum);
    } else if (_assetId == tokenAAssetId) {
      return (token0, tokenAQuantum);
    } else if (_assetId == tokenBAssetId) {
      return (token1, tokenBQuantum);
    } 

    require(false, 'DVF_NO_STARKWARE_INFO');
  }

  function setLock(bool state) internal {
    unlocked = state ? 0 : 1;
  }

  function isLocked() internal view returns (bool) {
    return unlocked == 0;
  }

  // TESTING
  function balancesPub() external view returns (uint b0, uint b1, uint112 r0, uint112 r1, uint out0, uint out1, uint loans) {
    (b0, b1) = balances();
    (r0, r1,) = getReserves();
    out0 = tokenAOutstanding;
    out1 = tokenBOutstanding;
    loans = totalLoans;
  }

  function token_info() external view returns (uint _lpAssetId, uint _tokenAAssetId, uint _tokenBAssetId) {
    return (lpAssetId, tokenAAssetId, tokenBAssetId);
  }

  function balances() internal view override returns (uint balance0, uint balance1) {
    if (isLayer2Live) {
      IStarkEx starkEx = getStarkEx();
      balance0 = starkEx.getVaultBalance(address(this), tokenAAssetId, currentVault);
      balance1 = starkEx.getVaultBalance(address(this), tokenBAssetId, currentVault);
    } else {
      return super.balances();
    }
  }

  /**
   * @dev Used by EmergencyWithdrawal to burn the tokens by operator as requested by users
  */
  function burnAndTransfertoThis(address from, uint lptokenAmount) 
    internal 
    override 
    returns (uint token0Amount, uint token1Amount) 
  {
    (uint balance0, uint balance1) = balances();
    require(balanceOf[from] >= lptokenAmount, 'NOT_ENOUGH_LP_LIQUIDITY');

    {
    uint _totalSupply = totalSupply; 
    token0Amount = lptokenAmount.mul(balance0) / _totalSupply;
    token1Amount = lptokenAmount.mul(balance1) / _totalSupply;
    }

    if (isLayer2Live) {
      // Must withdraw tokens from the StarkEx vault
     IStarkEx starkEx = getStarkEx();
     withdrawStarkWare(starkEx, token0, tokenAQuantum, tokenAAssetId, currentVault, tokenAQuantum.toQuantizedUnsafe(token0Amount));
     withdrawStarkWare(starkEx, token1, tokenBQuantum, tokenBAssetId, currentVault, tokenBQuantum.toQuantizedUnsafe(token1Amount));
     // Truncate since quantization will not take dust into account
     token0Amount = tokenAQuantum.truncate(token0Amount);
     token1Amount = tokenBQuantum.truncate(token1Amount);
    }

    _burn(from, lptokenAmount);
  }

  function authorizeWithdrawals(uint blockNumberTo, uint lpAmount, bool validateId) external override operatorOnly {
    _authorizeWithdrawals(blockNumberTo, lpAmount, validateId);
  }

  function setWithdrawalDelay(uint newDelay) external operatorOnly {
    _setWithdrawalDelay(newDelay);
  }
}

// SPDX-License-Identifier: UNLICENCED
pragma solidity >=0.6.12;

import './starkex/interfaces/IStarkEx.sol';

// Required functions from StarkWare TokenAssetData
abstract contract StarkWareAssetData {
    bytes4 internal constant ETH_SELECTOR = bytes4(keccak256("ETH()"));

    // The selector follows the 0x20 bytes assetInfo.length field.
    uint256 internal constant SELECTOR_OFFSET = 0x20;
    uint256 internal constant SELECTOR_SIZE = 4;
    uint256 internal constant TOKEN_CONTRACT_ADDRESS_OFFSET = SELECTOR_OFFSET + SELECTOR_SIZE;

    function extractContractAddressFromAssetInfo(bytes memory assetInfo)
        private pure returns (address res) {
        uint256 offset = TOKEN_CONTRACT_ADDRESS_OFFSET;
        assembly {
            res := mload(add(assetInfo, offset))
        }
    }

    function extractTokenSelector(bytes memory assetInfo) internal pure
        returns (bytes4 selector) {
        assembly {
            selector := and(
                0xffffffff00000000000000000000000000000000000000000000000000000000,
                mload(add(assetInfo, SELECTOR_OFFSET))
            )
        }
    }

    function isEther(IStarkEx starkEx, uint256 assetType) internal view returns (bool) {
        return extractTokenSelector(starkEx.getAssetInfo(assetType)) == ETH_SELECTOR;
    }

    function extractContractAddress(IStarkEx starkEx, uint256 assetType) internal view returns (address) {
        return extractContractAddressFromAssetInfo(starkEx.getAssetInfo(assetType));
    }
}

// SPDX-License-Identifier: UNLICENCED
pragma solidity >=0.8.4;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @dev Simple contract to hold withdrawal balances
*/
contract WithdrawalWallet {
  using SafeERC20 for IERC20;

  address private owner;

  constructor() {
    owner = msg.sender;
  }

  function transfer(address erc20Token, address destination, uint value) external {
    require(msg.sender == owner, 'ONLY_OWNER');
    IERC20(erc20Token).safeTransfer(destination, value);
  }
}

// SPDX-License-Identifier: Apache-2.0.
pragma solidity >=0.8.0;

/**
  Interface for Mock starkEx
 */
interface IStarkEx {
  function VERSION() external view returns(string memory);
  event LogL1LimitOrderRegistered( address userAddress, address exchangeAddress, uint256 tokenIdSell, uint256 tokenIdBuy,
      uint256 tokenIdFee, uint256 amountSell, uint256 amountBuy, uint256 amountFee, uint256 vaultIdSell, uint256 vaultIdBuy,
      uint256 vaultIdFee, uint256 nonce, uint256 expirationTimestamp);

  /**
   * Register an L1 limit order
   */
  function registerLimitOrder(
      address exchangeAddress,
      uint256 tokenIdSell,
      uint256 tokenIdBuy,
      uint256 tokenIdFee,
      uint256 amountSell,
      uint256 amountBuy,
      uint256 amountFee,
      uint256 vaultIdSell,
      uint256 vaultIdBuy,
      uint256 vaultIdFee,
      uint256 nonce,
      uint256 expirationTimestamp
  ) external;

  /**
   * Deposits and withdrawals
  */
  function depositERC20ToVault(uint256 assetId, uint256 vaultId, uint256 quantizedAmount) external;
  function depositEthToVault(uint256 assetId, uint256 vaultId) external payable;
  function withdrawFromVault(uint256 assetId, uint256 vaultId, uint256 quantizedAmount) external;
  function getVaultBalance(address ethKey, uint256 assetId, uint256 vaultId) external view returns (uint256);
  function getQuantizedVaultBalance(address ethKey, uint256 assetId, uint256 vaultId) external view returns (uint256);

  function orderRegistryAddress() external returns (address);
  function getAssetInfo(uint256 assetType) external view returns (bytes memory);
  function getQuantum(uint assetId) external view returns(uint);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

library StarkLib {
  function fromQuantized(uint _quantum, uint256 quantizedAmount)
      internal pure returns (uint256 amount) {
      amount = quantizedAmount * _quantum;
      require(amount / _quantum == quantizedAmount, "DEQUANTIZATION_OVERFLOW");
  }

  function toQuantizedUnsafe(uint _quantum, uint256 amount)
      internal pure returns (uint256 quantizedAmount) {
      quantizedAmount = amount / _quantum;
  }

  function toQuantized(uint _quantum, uint256 amount)
      internal pure returns (uint256 quantizedAmount) {
      if (amount == 0) {
        return 0;
      }
      require(amount % _quantum == 0, "INVALID_AMOUNT_TO_QUANTIZED");
      quantizedAmount = amount / _quantum;
  }

  function truncate(uint quantum, uint amount) internal pure returns (uint) {
    if (amount == 0) {
      return 0;
    }
    require(amount > quantum, 'DVF: TRUNCATE_AMOUNT_LOWER_THAN_QUANTUM');
    return amount - (amount % quantum);
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.12;

import './libraries/SafeMath.sol';

contract UniswapV2ERC20 {
    using SafeMathUniswap for uint;

    string public constant name = 'DeversiFi LP Token';
    string public constant symbol = 'DLP';
    uint8 public constant decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function initialize() internal virtual {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) internal {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) public virtual returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public virtual returns (bool) {
        if (allowance[from][msg.sender] != type(uint).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'DVF_AMM: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'DVF_AMM: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.12;

import './UniswapV2ERC20.sol';
import '../starkex/libraries/StarkLib.sol';
import './libraries/Math.sol';
import './libraries/UQ112x112.sol';
import './interfaces/IERC20.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Callee.sol';
import '../PairStorage.sol';

interface IMigrator {
    // Return the desired amount of liquidity token that the migrator wants.
    function desiredLiquidity() external view returns (uint256);
}

abstract contract UniswapV2Pair is UniswapV2ERC20, PairStorage {
    using SafeMathUniswap  for uint;
    using StarkLib  for uint;
    using UQ112x112 for uint224;

    uint public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    modifier lock() {
        require(unlocked == 1, 'DVF_AMM: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'DVF_AMM: TRANSFER_FAILED');
    }

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) internal virtual {
        require(factory == address(0), 'DVF_AMM: FORBIDDEN');
        super.initialize();
        factory = msg.sender;
        token0 = _token0;
        token1 = _token1;
        unlocked = 1;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1) private {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, 'DVF_AMM: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        // TODO UNUSED, consider removing
        // if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
        //     // * never overflows, and + overflow is desired
        //     price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
        //     price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        // }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = address(0);
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint denominator = rootK.mul(5).add(rootKLast);
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) public virtual lock returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        (uint lpQuantum, uint token0Quantum, uint token1Quantum) = getQuantums();
        (uint balance0, uint balance1) = balances();
        // Quantize to ensure we do not respect the percision higher than our quant
        uint amount0 = token0Quantum.toQuantizedUnsafe(balance0.sub(_reserve0));
        uint amount1 = token1Quantum.toQuantizedUnsafe(balance1.sub(_reserve1));
        uint reserve0Quantised = token0Quantum.toQuantizedUnsafe(_reserve0);
        uint reserve1Quantised = token1Quantum.toQuantizedUnsafe(_reserve1);

        // gas savings, must be defined here since totalSupply can update in _mintFee
        uint _totalSupply = lpQuantum.toQuantizedUnsafe(totalSupply); 
        if (_totalSupply == 0) {
            address migrator = IUniswapV2Factory(factory).migrator();
            if (msg.sender == migrator) {
                liquidity = IMigrator(migrator).desiredLiquidity();
                require(liquidity > 0 && liquidity != type(uint256).max, "Bad desired liquidity");
            } else {
                require(migrator == address(0), "Must not have migrator");
                liquidity = calculateInitialLiquidity(amount0, amount1, lpQuantum);
                _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
            }
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / reserve0Quantised, amount1.mul(_totalSupply) / reserve1Quantised);
            liquidity = lpQuantum.fromQuantized(liquidity);
        }

        require(liquidity > 0, 'DVF_AMM: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balance0, balance1);
        emit Mint(msg.sender, amount0, amount1);
    }

    function calculateInitialLiquidity(uint amount0, uint amount1, uint lpQuantum) internal pure returns(uint liquidity) {
      liquidity = Math.sqrt(amount0.mul(amount1).mul(lpQuantum).mul(lpQuantum)).sub(MINIMUM_LIQUIDITY);
      // Truncate
      liquidity = liquidity.sub(liquidity % lpQuantum);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        (uint balance0, uint balance1) = balances();
        uint liquidity = balanceOf[address(this)];
        // TODO Ensure cannot burn with higher percision than quantum

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'DVF_AMM: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        (balance0, balance1) = balances();

        _update(balance0, balance1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) public virtual lock {
        require(amount0Out > 0 || amount1Out > 0, 'DVF_AMM: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'DVF_AMM: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
        address _token0 = token0;
        address _token1 = token1;
        require(to != _token0 && to != _token1, 'DVF_AMM: INVALID_TO');
        (,uint token0Quantum, uint token1Quantum) = getQuantums();
        if (amount0Out > 0) {
          amount0Out = token0Quantum.truncate(amount0Out);
          _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
        }
        if (amount1Out > 0) {
          amount1Out = token1Quantum.truncate(amount1Out);
          _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
        }
        if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
        (balance0, balance1) = balances();
        }
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'DVF_AMM: INSUFFICIENT_INPUT_AMOUNT');

        // validate K ratio
        validateK(balance0, balance1, _reserve0, _reserve1);

        _update(balance0, balance1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    function validateK(uint balance0, uint balance1, uint _reserve0, uint _reserve1) internal view {
      (,uint token0Quantum, uint token1Quantum) = getQuantums();
      uint balance0Adjusted = token0Quantum.toQuantizedUnsafe(balance0);
      uint balance1Adjusted = token1Quantum.toQuantizedUnsafe(balance1);
      uint reserve0Adjusted = token0Quantum.toQuantizedUnsafe(_reserve0);
      uint reserve1Adjusted = token1Quantum.toQuantizedUnsafe(_reserve1);
      require(balance0Adjusted.mul(balance1Adjusted) >= reserve0Adjusted.mul(reserve1Adjusted), 'DVF_AMM: K');
    }

    // force balances to match reserves
    function skim(address to) public virtual lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        (uint balance0, uint balance1) = balances();
        _safeTransfer(_token0, to, balance0.sub(reserve0));
        _safeTransfer(_token1, to, balance1.sub(reserve1));
    }

    // force reserves to match balances
    function sync() public virtual lock {
        (uint balance0, uint balance1) = balances();
        _update(balance0, balance1);
    }

    function balances() internal view virtual returns (uint balance0, uint balance1) {
      balance0 = IERC20Uniswap(token0).balanceOf(address(this));
      balance1 = IERC20Uniswap(token1).balanceOf(address(this));
    }

    // Abstract methods
    function getQuantums() public view virtual returns (uint, uint, uint);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IERC20Uniswap {
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);
    function isOperator() external view returns (bool);
    function wethAddress() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;

    function pairCodeHash() external view returns (bytes32);

    function pairFor(address tokenA, address tokenB) external view returns (address pair);

    function isStarkExContractFrozen() external view returns (bool);

    function starkExContract() external view returns (address);

    // Event emmiters

  function withdrawalRequested(address token0, address token1, address user, uint amount, uint withdrawalId) external;
  function withdrawalCompleted(address token0, address token1, address user, uint amount, uint token0Amount, uint token1Amount) external;
  function withdrawalForced(address token0, address token1, address user) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function approve(address spender, uint value) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.12;

// a library for performing various math operations

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.12;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathUniswap {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.12;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}