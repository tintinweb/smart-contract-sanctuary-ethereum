// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {IERC20} from '../dependencies/openzeppelin/contracts/IERC20.sol';
import {SafeERC20} from '../dependencies/openzeppelin/contracts/SafeERC20.sol';
import {SafeMath} from '../dependencies/openzeppelin/contracts/SafeMath.sol';
import {IWETH} from '../interfaces/IWETH.sol';
import {Ownable} from '../dependencies/openzeppelin/contracts/Ownable.sol';
import {Invoke} from '../dependencies/Invoke.sol';
import {AaveCall} from './AaveCall.sol';
import {ILeverageStake} from '../interfaces/ILeverageStake.sol';
import {IETF, IFactory} from '../interfaces/IETF.sol';
import {IBpool} from '../interfaces/IBpool.sol';
import '../interfaces/IAggregationInterface.sol';

contract LeverageStake is ILeverageStake, Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using AaveCall for IETF;
  using Invoke for IETF;

  uint256 public constant MAX_LEVERAGE = 5000;
  uint256 public borrowRate = 670;
  uint256 public reservedAstEth;
  uint256 public defaultSlippage = 99;

  IAaveAddressesProvider public aaveAddressProvider =
    IAaveAddressesProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
  ILendingPool public lendingPool = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
  IERC20 public stETH = IERC20(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
  IWETH public WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  ILidoCurve public lidoCurve = ILidoCurve(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022);

  address public factory;
  IETF public etf;
  IERC20 public astETH; // 0x1982b2F5814301d4e9a8b0201555376e62F82428
  IERC20 public debtToken; // 0xA9DEAc9f00Dc4310c35603FCD9D34d1A750f81Db

  constructor(address _etf, address _factory) public {
    etf = IETF(_etf);
    factory = _factory;

    DataTypes.ReserveData memory reserve = lendingPool.getReserveData(address(stETH));
    astETH = IERC20(reserve.aTokenAddress);

    DataTypes.ReserveData memory reserveDebt = lendingPool.getReserveData(address(WETH));
    debtToken = IERC20(reserveDebt.variableDebtTokenAddress);
  }

  //*********************** events ******************************

  event FactoryUpdated(address old, address newF);
  event BorrowRateChanged(uint256 oldRate, uint256 newRate);
  event BatchLeverIncreased(
    address collateralAsset,
    address borrowAsset,
    uint256 totalBorrowed,
    uint256 leverage
  );
  event BatchLeverDecreased(
    address collateralAsset,
    address repayAsset,
    uint256 totalRepay,
    bool noDebt
  );
  event LeverIncreased(address collateralAsset, address borrowAsset, uint256 borrowed);
  event LeverDecreased(address collateralAsset, address repayAsset, uint256 amount);
  event LendingPoolUpdated(address oldPool, address newPool);
  event SlippageChanged(uint256 oldSlippage, uint256 newSlippage);

  // *********************** view functions ******************************

  /// @dev Returns all the astETH balance
  /// @return balance astETH balance
  function getAstETHBalance() public view override returns (uint256 balance) {
    balance = astETH.balanceOf(etf.bPool());
  }

  function getBalanceSheet() public view override returns (uint256, uint256) {
    uint256 debtTokenBal = debtToken.balanceOf(etf.bPool());
    uint256 wethBal = WETH.balanceOf(etf.bPool());

    return (debtTokenBal, wethBal);
  }

  /// @dev Returns all the stETH balance
  /// @return balance the balance of stETH left
  function getStethBalance() public view override returns (uint256 balance) {
    balance = stETH.balanceOf(etf.bPool());
  }

  /// @dev Returns the user account data across all the reserves
  /// @return totalCollateralETH the total collateral in ETH of the user
  /// @return totalDebtETH the total debt in ETH of the user
  /// @return availableBorrowsETH the borrowing power left of the user
  /// @return currentLiquidationThreshold the liquidation threshold of the user
  /// @return ltv the loan to value of the user
  /// @return healthFactor the current health factor of the user
  function getLeverageInfo()
    public
    view
    override
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    )
  {
    (
      totalCollateralETH,
      totalDebtETH,
      availableBorrowsETH,
      currentLiquidationThreshold,
      ltv,
      healthFactor
    ) = lendingPool.getUserAccountData(etf.bPool());
  }

  // *********************** external functions ******************************

  function manualUpdatePosition() external {
    _checkTx();

    if (IBpool(etf.bPool()).isBound(address(astETH))) {
      etf.invokeRebind(address(astETH), getAstETHBalance(), 50e18, true);
    }
  }

  /// @dev Deposits an `amount` of underlying asset into the reserve
  /// @param amount The amount to be deposited to aave
  function deposit(uint256 amount) internal returns (uint256) {
    _checkTx();

    uint256 preBal = getAstETHBalance();

    // approve stETH first
    etf.invokeApprove(address(stETH), address(lendingPool), amount.add(1), true);

    // deposit stETH to aave
    etf.invokeDeposit(lendingPool, address(stETH), amount);

    return getAstETHBalance().sub(preBal);
  }

  /// @dev Allows users to borrow a specific `amount` of the reserve underlying asset
  /// @param amount The amount to be borrowed
  /// @param referralCode Code used to register the integrator originating the operation, for potential rewards.
  function borrow(uint256 amount, uint16 referralCode) internal {
    _checkTx();

    // borrow WETH
    etf.invokeBorrow(lendingPool, address(WETH), amount, 2, referralCode);

    // unwrap WETH to ETH
    etf.invokeUnwrapWETH(address(WETH), amount);
  }

  /// @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
  /// @param amount The underlying amount to be withdrawn
  function withdraw(uint256 amount) internal {
    _checkTx();

    etf.invokeWithdraw(lendingPool, address(stETH), amount);
  }

  /// @dev Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
  /// @param amount The amount to repay
  /// @return The final amount repaid
  function repayBorrow(uint256 amount) public override returns (uint256) {
    _checkTx();

    uint256 preRepay = WETH.balanceOf(etf.bPool());

    etf.invokeApprove(address(WETH), address(lendingPool), amount.add(1), true);
    etf.invokeRepay(lendingPool, address(WETH), amount, 2);

    uint256 postRepay = WETH.balanceOf(etf.bPool());

    return preRepay.sub(postRepay);
  }

  /// @dev Allows ETF to enable/disable a specific deposited asset as collateral
  /// @param _asset                The address of the underlying asset deposited
  /// @param _useAsCollateral      true` if the user wants to use the deposit as collateral, `false` otherwise
  function setUserUseReserveAsCollateral(address _asset, bool _useAsCollateral) external {
    _checkTx();

    etf.invokeSetUserUseReserveAsCollateral(lendingPool, _asset, _useAsCollateral);
  }

  /// @dev Achieves the expected leverage in batch actions repeatly
  /// @param collateral The collateral amount to use
  /// @param leverage The expected leverage
  /// @param referralCode Code used to register the integrator originating the operation, for potential rewards
  /// @param isTrade The way to get stETH, if isTrade is true, buying stETH in curve, or depositing ETH to Lido for that
  function batchIncreaseLever(
    uint256 collateral,
    uint256 leverage,
    uint16 referralCode,
    bool isTrade
  ) external override {
    require(leverage <= MAX_LEVERAGE, 'EXCEEDS_MAX_LEVERAGE');

    uint256 borrowSize = collateral.mul(borrowRate).div(1000);
    uint256 totalBorrowed;

    while (true) {
      uint256 newCollateral = increaseLever(borrowSize, referralCode, isTrade);

      totalBorrowed = totalBorrowed.add(borrowSize);

      borrowSize = newCollateral.mul(borrowRate).div(1000);

      if (totalBorrowed >= collateral.mul(leverage.sub(1000)).div(1000)) break;
    }

    emit BatchLeverIncreased(address(stETH), address(WETH), totalBorrowed, leverage);
  }

  /// @dev Decrease leverage in batch actions repeatly
  /// @param startAmount The start withdrawal amount for deleveraging
  function batchDecreaseLever(uint256 startAmount) external override {
    uint256 newWithdrawal = startAmount;
    uint256 totalRepay;

    bool isRepayAll;
    while (true) {
      (uint256 repay, bool noDebt) = decreaseLever(newWithdrawal);

      isRepayAll = noDebt;

      newWithdrawal = repay.mul(1000).div(borrowRate);

      totalRepay = totalRepay.add(repay);

      if (repay == 0 || noDebt) {
        break;
      }
    }

    emit BatchLeverDecreased(address(stETH), address(WETH), totalRepay, isRepayAll);
  }

  /// @dev Utilizing several DeFi protocols to increase the leverage in batch actions
  /// @param amount The initial borrow amount
  /// @param referralCode Code used to register the integrator originating the operation, for potential rewards.
  function increaseLever(
    uint256 amount,
    uint16 referralCode,
    bool isTrade
  ) public override returns (uint256) {
    require(amount != 0, 'ZERO AMOUNT');

    (uint debt, ) = getBalanceSheet();
    require(debt <= reservedAstEth.mul(MAX_LEVERAGE.sub(1000)).div(1000), 'EXCEEDS_MAX_LEVERAGE');

    // first step: borrow
    borrow(amount, referralCode);

    // second step: convert ETH to stETH
    uint256 preStETH = stETH.balanceOf(etf.bPool());
    if (isTrade) {
      exchange(0, 1, amount);
    } else {
      etf.invokeMint(address(stETH), address(0), amount);
    }

    uint256 receivedStETH = stETH.balanceOf(etf.bPool()).sub(preStETH);

    // third step: deposit stETH to aave
    uint256 astEthGot = deposit(receivedStETH);

    etf.invokeRebind(address(astETH), getAstETHBalance(), 50e18, true);

    emit LeverIncreased(address(stETH), address(WETH), amount);

    return astEthGot;
  }

  /// @dev Decrease leverage in batch actions from several DeFi protocols
  /// @param amount The initial amount to input for first withdrawal
  function decreaseLever(uint256 amount) public override returns (uint256, bool) {
    require(amount != 0, 'ZERO AMOUNT');

    (uint256 debt, ) = getBalanceSheet();

    // uint256 ava = getAstETHBalance().sub(reservedAstEth.mul(99).div(100));
    uint256 ava = getAstETHBalance().sub(reservedAstEth).sub(1);

    if (ava < amount) {
      amount = ava;
    }

    uint256 repayAmount;

    if (amount > 0 && debt > 0) {
      // first step: withdraw avaiable stETH
      withdraw(amount);

      // second step: convert stETH to ETH by curve, cause Lido deposit is irreversible
      uint256 receivedETH = exchange(1, 0, amount);

      // third step: wrap ETH to WETH
      etf.invokeWrapWETH(address(WETH), receivedETH);

      // fourth step: repay WETH to aave
      repayAmount = repayBorrow(receivedETH);

      etf.invokeRebind(address(astETH), getAstETHBalance(), 50e18, true);

      emit LeverDecreased(address(stETH), address(WETH), amount);
    }

    return (repayAmount, debt.sub(repayAmount) == 0);
  }

  /// @dev Trading between stETH and ETH by curve
  /// @param i trade direction
  /// @param j trade direction
  /// @param dx trade amount
  function exchange(int128 i, int128 j, uint256 dx) internal returns (uint256) {
    // minimum amount expected to receive
    uint256 minDy = dx.mul(defaultSlippage).div(100);

    uint256 callValue = i == 0 ? dx : 0;
    uint256 preEthBal = etf.bPool().balance;
    uint256 preStEthBal = stETH.balanceOf(etf.bPool());

    if (i == 1) {
      etf.invokeApprove(address(stETH), address(lidoCurve), dx, true);
    }

    bytes memory methodData = abi.encodeWithSignature(
      'exchange(int128,int128,uint256,uint256)',
      i,
      j,
      dx,
      minDy
    );

    etf.execute(address(lidoCurve), callValue, methodData, true);

    if (i == 0) {
      return stETH.balanceOf(etf.bPool()).sub(preStEthBal);
    } else {
      return (etf.bPool().balance).sub(preEthBal);
    }
  }

  /// @dev convert WETH to astETH by a batch of actions
  /// @param isTrade The way to get stETH, if isTrade is true, buying stETH in curve, or depositing ETH to Lido for that
  function convertToAstEth(bool isTrade) external override {
    _checkTx();

    uint256 convertedAmount = WETH.balanceOf(etf.bPool());

    // convert WETH to ETH
    etf.invokeUnwrapWETH(address(WETH), convertedAmount);

    // convert ETH to stETH
    uint256 receivedStEth;
    if (isTrade) {
      receivedStEth = exchange(0, 1, convertedAmount);
    } else {
      uint256 preStethBal = stETH.balanceOf(etf.bPool());
      etf.invokeMint(address(stETH), address(0), convertedAmount);

      receivedStEth = stETH.balanceOf(etf.bPool()).sub(preStethBal);
    }

    // deposit stETH to aave to get astETH
    uint256 astEthGot = deposit(receivedStEth);

    if (reservedAstEth == 0) {
      reservedAstEth = astEthGot;

      _updatePosition(address(WETH), address(astETH), getAstETHBalance(), 50e18);
    } else {
      reservedAstEth = reservedAstEth.add(astEthGot);

      etf.invokeRebind(address(astETH), getAstETHBalance(), 50e18, true);
    }
  }

  /// @dev convert astETH to WETH by a batch of actions
  function convertToWeth() external override {
    uint256 withdrawnAmount = getAstETHBalance().sub(1);

    // withdraw stETH from aave
    withdraw(withdrawnAmount);

    // convert stETH to ETH
    uint256 receivedETH = exchange(1, 0, withdrawnAmount);

    // wrap ETH to WETH
    etf.invokeWrapWETH(address(WETH), receivedETH);

    reservedAstEth = 0;

    (, uint256 wethBal) = getBalanceSheet();

    _updatePosition(address(astETH), address(WETH), wethBal, 50e18);
  }

  function setFactory(address _factory) external onlyOwner {
    require(_factory != address(0), 'ZERO ADDRESS');

    emit FactoryUpdated(factory, _factory);

    factory = _factory;
  }

  function setBorrowRate(uint256 _rate) external onlyOwner {
    require(_rate > 0, 'ZERO_LEVERAGE');

    emit BorrowRateChanged(borrowRate, _rate);

    borrowRate = _rate;
  }

  function setDefaultSlippage(uint256 _slippage) external onlyOwner {
    require(_slippage > 80, 'INVALID_SLIPPAGE');

    emit SlippageChanged(defaultSlippage, _slippage);

    defaultSlippage = _slippage;
  }

  function updateLendingPoolInfo() external onlyOwner {
    address _lendingpool = aaveAddressProvider.getLendingPool();

    emit LendingPoolUpdated(address(lendingPool), _lendingpool);

    lendingPool = ILendingPool(_lendingpool);

    DataTypes.ReserveData memory reserve = lendingPool.getReserveData(address(stETH));
    astETH = IERC20(reserve.aTokenAddress);

    DataTypes.ReserveData memory reserveDebt = lendingPool.getReserveData(address(WETH));
    debtToken = IERC20(reserveDebt.variableDebtTokenAddress);
  }

  function _updatePosition(address token0, address token1, uint256 amount, uint256 share) internal {
    etf.invokeUnbind(token0);
    etf.invokeRebind(token1, amount, share, false);
  }

  function _checkTx() internal view {
    require(!IFactory(factory).isPaused(), 'PAUSED');

    require(etf.adminList(msg.sender) || msg.sender == etf.getController(), 'NOT_CONTROLLER');

    (, uint256 collectEndTime, , uint256 closureEndTime, , , , , , , ) = etf.etfStatus();

    require(etf.isCompletedCollect(), 'COLLECTION_FAILED');
    require(
      block.timestamp > collectEndTime && block.timestamp < closureEndTime,
      'NOT_REBALANCE_PERIOD'
    );
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import {IERC20} from '../dependencies/openzeppelin/contracts/IERC20.sol';
import {SafeMath} from '../dependencies/openzeppelin/contracts/SafeMath.sol';
import {IETF} from '../interfaces/IETF.sol';

/**
 * @title Invoke
 * @author Desyn Protocol
 *
 * A collection of common utility functions for interacting with the Etf's invoke function
 */
library Invoke {
  using SafeMath for uint256;

  /* ============ Internal ============ */

  /**
   * Instructs the Etf to set approvals of the ERC20 token to a spender.
   *
   * @param _etf        Etf instance to invoke
   * @param _token           ERC20 token to approve
   * @param _spender         The account allowed to spend the Etf's balance
   * @param _quantity        The quantity of allowance to allow
   */
  function invokeApprove(
    IETF _etf,
    address _token,
    address _spender,
    uint256 _quantity,
    bool isUnderlying
  ) internal {
    bytes memory callData = abi.encodeWithSignature(
      'approve(address,uint256)',
      _spender,
      _quantity
    );
    _etf.execute(_token, 0, callData, isUnderlying);
  }

  /**
   * Instructs the Etf to transfer the ERC20 token to a recipient.
   *
   * @param _etf        Etf instance to invoke
   * @param _token           ERC20 token to transfer
   * @param _to              The recipient account
   * @param _quantity        The quantity to transfer
   */
  function invokeTransfer(
    IETF _etf,
    address _token,
    address _to,
    uint256 _quantity,
    bool isUnderlying
  ) internal {
    if (_quantity > 0) {
      bytes memory callData = abi.encodeWithSignature('transfer(address,uint256)', _to, _quantity);
      _etf.execute(_token, 0, callData, isUnderlying);
    }
  }

  /**
   * Instructs the Etf to transfer the ERC20 token to a recipient.
   * The new Etf balance must equal the existing balance less the quantity transferred
   *
   * @param _etf        Etf instance to invoke
   * @param _token           ERC20 token to transfer
   * @param _to              The recipient account
   * @param _quantity        The quantity to transfer
   */
  function strictInvokeTransfer(
    IETF _etf,
    address _token,
    address _to,
    uint256 _quantity
  ) internal {
    if (_quantity > 0) {
      // Retrieve current balance of token for the Etf
      uint256 existingBalance = IERC20(_token).balanceOf(address(_etf));

      Invoke.invokeTransfer(_etf, _token, _to, _quantity, false);

      // Get new balance of transferred token for Etf
      uint256 newBalance = IERC20(_token).balanceOf(address(_etf));

      // Verify only the transfer quantity is subtracted
      require(newBalance == existingBalance.sub(_quantity), 'Invalid post transfer balance');
    }
  }

  /**
   * Instructs the Etf to unwrap the passed quantity of WETH
   *
   * @param _etf        Etf instance to invoke
   * @param _weth            WETH address
   * @param _quantity        The quantity to unwrap
   */
  function invokeUnwrapWETH(IETF _etf, address _weth, uint256 _quantity) internal {
    bytes memory callData = abi.encodeWithSignature('withdraw(uint256)', _quantity);
    _etf.execute(_weth, 0, callData, true);
  }

  /**
   * Instructs the Etf to wrap the passed quantity of ETH
   *
   * @param _etf        Etf instance to invoke
   * @param _weth            WETH address
   * @param _quantity        The quantity to unwrap
   */
  function invokeWrapWETH(IETF _etf, address _weth, uint256 _quantity) internal {
    bytes memory callData = abi.encodeWithSignature('deposit()');
    _etf.execute(_weth, _quantity, callData, true);
  }

  function invokeMint(IETF _etf, address _token, address _referral, uint256 value) internal {
    bytes memory callData = abi.encodeWithSignature('submit(address)', _referral);
    _etf.execute(_token, value, callData, true);
  }

  function invokeUnbind(IETF _etf, address _token) internal {
    bytes memory callData = abi.encodeWithSignature('unbindPure(address)', _token);
    _etf.execute(_etf.bPool(), 0, callData, false);
  }

  function invokeRebind(
    IETF _etf,
    address _token,
    uint256 _balance,
    uint256 _weight,
    bool _isBound
  ) internal {
    bytes memory callData = abi.encodeWithSignature(
      'rebindPure(address,uint256,uint256,bool)',
      _token,
      _balance,
      _weight,
      _isBound
    );
    _etf.execute(_etf.bPool(), 0, callData, false);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

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
    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      codehash := extcodehash(account)
    }
    return (codehash != accountHash && codehash != 0x0);
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
    require(address(this).balance >= amount, 'Address: insufficient balance');

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'Address: unable to send value, recipient may have reverted');
  }

  /**
   * @dev Performs a Solidity function call using a low level `call`. A
   * plain`call` is an unsafe replacement for a function call: use this
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
    return functionCall(target, data, 'Address: low-level call failed');
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
    return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
    require(address(this).balance >= value, 'Address: insufficient balance for call');
    require(isContract(target), 'Address: call to non-contract');

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function _verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) private pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      // Look for revert reason and bubble it up if present
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly

        // solhint-disable-next-line no-inline-assembly
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
pragma solidity 0.6.12;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import './Context.sol';
import './IERC20.sol';
import './SafeMath.sol';
import './Address.sol';

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
  using SafeMath for uint256;
  using Address for address;

  mapping(address => uint256) private _balances;

  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply;

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  /**
   * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
   * a default value of 18.
   *
   * To select a different value for {decimals}, use {_setupDecimals}.
   *
   * All three of these values are immutable: they can only be set once during
   * construction.
   */
  constructor(string memory name, string memory symbol) public {
    _name = name;
    _symbol = symbol;
    _decimals = 18;
  }

  /**
   * @dev Returns the name of the token.
   */
  function name() public view returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() public view returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the number of decimals used to get its user representation.
   * For example, if `decimals` equals `2`, a balance of `505` tokens should
   * be displayed to a user as `5,05` (`505 / 10 ** 2`).
   *
   * Tokens usually opt for a value of 18, imitating the relationship between
   * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
   * called.
   *
   * NOTE: This information is only used for _display_ purposes: it in
   * no way affects any of the arithmetic of the contract, including
   * {IERC20-balanceOf} and {IERC20-transfer}.
   */
  function decimals() public view returns (uint8) {
    return _decimals;
  }

  /**
   * @dev See {IERC20-totalSupply}.
   */
  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {IERC20-balanceOf}.
   */
  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev See {IERC20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {IERC20-allowance}.
   */
  function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {IERC20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {IERC20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {ERC20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for ``sender``'s tokens of at least
   * `amount`.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(amount, 'ERC20: transfer amount exceeds allowance')
    );
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(
        subtractedValue,
        'ERC20: decreased allowance below zero'
      )
    );
    return true;
  }

  /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), 'ERC20: transfer from the zero address');
    require(recipient != address(0), 'ERC20: transfer to the zero address');

    _beforeTokenTransfer(sender, recipient, amount);

    _balances[sender] = _balances[sender].sub(amount, 'ERC20: transfer amount exceeds balance');
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements
   *
   * - `to` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), 'ERC20: mint to the zero address');

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), 'ERC20: burn from the zero address');

    _beforeTokenTransfer(account, address(0), amount);

    _balances[account] = _balances[account].sub(amount, 'ERC20: burn amount exceeds balance');
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
   *
   * This is internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), 'ERC20: approve from the zero address');
    require(spender != address(0), 'ERC20: approve to the zero address');

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * @dev Sets {decimals} to a value other than the default one of 18.
   *
   * WARNING: This function should only be called from the constructor. Most
   * applications that interact with token contracts will not expect
   * {decimals} to ever change, and may work incorrectly if it does.
   */
  function _setupDecimals(uint8 decimals_) internal {
    _decimals = decimals_;
  }

  /**
   * @dev Hook that is called before any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * will be to transferred to `to`.
   * - when `from` is zero, `amount` tokens will be minted for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {IERC20} from './IERC20.sol';

interface IERC20Detailed is IERC20 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import './Context.sol';

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() internal {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import {IERC20} from './IERC20.sol';
import {SafeMath} from './SafeMath.sol';
import {Address} from './Address.sol';

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
  using SafeMath for uint256;
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      'SafeERC20: approve from non-zero to non-zero allowance'
    );
    callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function callOptionalReturn(IERC20 token, bytes memory data) private {
    require(address(token).isContract(), 'SafeERC20: call to non-contract');

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = address(token).call(data);
    require(success, 'SafeERC20: low-level call failed');

    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath: addition overflow');

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, 'SafeMath: subtraction overflow');
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, 'SafeMath: multiplication overflow');

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, 'SafeMath: division by zero');
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, 'SafeMath: modulo by zero');
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import './BaseAdminUpgradeabilityProxy.sol';

/**
 * @title AdminUpgradeabilityProxy
 * @dev Extends from BaseAdminUpgradeabilityProxy with a constructor for
 * initializing the implementation, admin, and init data.
 */
contract AdminUpgradeabilityProxy is BaseAdminUpgradeabilityProxy, UpgradeabilityProxy {
  /**
   * Contract constructor.
   * @param _logic address of the initial implementation.
   * @param _admin Address of the proxy administrator.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  constructor(
    address _logic,
    address _admin,
    bytes memory _data
  ) public payable UpgradeabilityProxy(_logic, _data) {
    assert(ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1));
    _setAdmin(_admin);
  }

  /**
   * @dev Only fall back when the sender is not the admin.
   */
  function _willFallback() internal override(BaseAdminUpgradeabilityProxy, Proxy) {
    BaseAdminUpgradeabilityProxy._willFallback();
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import './UpgradeabilityProxy.sol';

/**
 * @title BaseAdminUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with an authorization
 * mechanism for administrative tasks.
 * All external functions in this contract must be guarded by the
 * `ifAdmin` modifier. See ethereum/solidity#3864 for a Solidity
 * feature proposal that would enable this to be done automatically.
 */
contract BaseAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
  /**
   * @dev Emitted when the administration has been transferred.
   * @param previousAdmin Address of the previous admin.
   * @param newAdmin Address of the new admin.
   */
  event AdminChanged(address previousAdmin, address newAdmin);

  /**
   * @dev Storage slot with the admin of the contract.
   * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant ADMIN_SLOT =
    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  /**
   * @dev Modifier to check whether the `msg.sender` is the admin.
   * If it is, it will run the function. Otherwise, it will delegate the call
   * to the implementation.
   */
  modifier ifAdmin() {
    if (msg.sender == _admin()) {
      _;
    } else {
      _fallback();
    }
  }

  /**
   * @return The address of the proxy admin.
   */
  function admin() external ifAdmin returns (address) {
    return _admin();
  }

  /**
   * @return The address of the implementation.
   */
  function implementation() external ifAdmin returns (address) {
    return _implementation();
  }

  /**
   * @dev Changes the admin of the proxy.
   * Only the current admin can call this function.
   * @param newAdmin Address to transfer proxy administration to.
   */
  function changeAdmin(address newAdmin) external ifAdmin {
    require(newAdmin != address(0), 'Cannot change the admin of a proxy to the zero address');
    emit AdminChanged(_admin(), newAdmin);
    _setAdmin(newAdmin);
  }

  /**
   * @dev Upgrade the backing implementation of the proxy.
   * Only the admin can call this function.
   * @param newImplementation Address of the new implementation.
   */
  function upgradeTo(address newImplementation) external ifAdmin {
    _upgradeTo(newImplementation);
  }

  /**
   * @dev Upgrade the backing implementation of the proxy and call a function
   * on the new implementation.
   * This is useful to initialize the proxied contract.
   * @param newImplementation Address of the new implementation.
   * @param data Data to send as msg.data in the low level call.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   */
  function upgradeToAndCall(address newImplementation, bytes calldata data)
    external
    payable
    ifAdmin
  {
    _upgradeTo(newImplementation);
    (bool success, ) = newImplementation.delegatecall(data);
    require(success);
  }

  /**
   * @return adm The admin slot.
   */
  function _admin() internal view returns (address adm) {
    bytes32 slot = ADMIN_SLOT;
    //solium-disable-next-line
    assembly {
      adm := sload(slot)
    }
  }

  /**
   * @dev Sets the address of the proxy admin.
   * @param newAdmin Address of the new proxy admin.
   */
  function _setAdmin(address newAdmin) internal {
    bytes32 slot = ADMIN_SLOT;
    //solium-disable-next-line
    assembly {
      sstore(slot, newAdmin)
    }
  }

  /**
   * @dev Only fall back when the sender is not the admin.
   */
  function _willFallback() internal virtual override {
    require(msg.sender != _admin(), 'Cannot call fallback function from the proxy admin');
    super._willFallback();
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import './Proxy.sol';
import '../contracts/Address.sol';

/**
 * @title BaseUpgradeabilityProxy
 * @dev This contract implements a proxy that allows to change the
 * implementation address to which it will delegate.
 * Such a change is called an implementation upgrade.
 */
contract BaseUpgradeabilityProxy is Proxy {
  /**
   * @dev Emitted when the implementation is upgraded.
   * @param implementation Address of the new implementation.
   */
  event Upgraded(address indexed implementation);

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant IMPLEMENTATION_SLOT =
    0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  /**
   * @dev Returns the current implementation.
   * @return impl Address of the current implementation
   */
  function _implementation() internal view override returns (address impl) {
    bytes32 slot = IMPLEMENTATION_SLOT;
    //solium-disable-next-line
    assembly {
      impl := sload(slot)
    }
  }

  /**
   * @dev Upgrades the proxy to a new implementation.
   * @param newImplementation Address of the new implementation.
   */
  function _upgradeTo(address newImplementation) internal {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }

  /**
   * @dev Sets the implementation address of the proxy.
   * @param newImplementation Address of the new implementation.
   */
  function _setImplementation(address newImplementation) internal {
    require(
      Address.isContract(newImplementation),
      'Cannot set a proxy implementation to a non-contract address'
    );

    bytes32 slot = IMPLEMENTATION_SLOT;

    //solium-disable-next-line
    assembly {
      sstore(slot, newImplementation)
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import './BaseAdminUpgradeabilityProxy.sol';
import './InitializableUpgradeabilityProxy.sol';

/**
 * @title InitializableAdminUpgradeabilityProxy
 * @dev Extends from BaseAdminUpgradeabilityProxy with an initializer for
 * initializing the implementation, admin, and init data.
 */
contract InitializableAdminUpgradeabilityProxy is
  BaseAdminUpgradeabilityProxy,
  InitializableUpgradeabilityProxy
{
  /**
   * Contract initializer.
   * @param logic address of the initial implementation.
   * @param admin Address of the proxy administrator.
   * @param data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  function initialize(
    address logic,
    address admin,
    bytes memory data
  ) public payable {
    require(_implementation() == address(0));
    InitializableUpgradeabilityProxy.initialize(logic, data);
    assert(ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1));
    _setAdmin(admin);
  }

  /**
   * @dev Only fall back when the sender is not the admin.
   */
  function _willFallback() internal override(BaseAdminUpgradeabilityProxy, Proxy) {
    BaseAdminUpgradeabilityProxy._willFallback();
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import './BaseUpgradeabilityProxy.sol';

/**
 * @title InitializableUpgradeabilityProxy
 * @dev Extends BaseUpgradeabilityProxy with an initializer for initializing
 * implementation and init data.
 */
contract InitializableUpgradeabilityProxy is BaseUpgradeabilityProxy {
  /**
   * @dev Contract initializer.
   * @param _logic Address of the initial implementation.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  function initialize(address _logic, bytes memory _data) public payable {
    require(_implementation() == address(0));
    assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
    _setImplementation(_logic);
    if (_data.length > 0) {
      (bool success, ) = _logic.delegatecall(_data);
      require(success);
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.6.0;

/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
abstract contract Proxy {
  /**
   * @dev Fallback function.
   * Implemented entirely in `_fallback`.
   */
  fallback() external payable {
    _fallback();
  }

  /**
   * @return The Address of the implementation.
   */
  function _implementation() internal view virtual returns (address);

  /**
   * @dev Delegates execution to an implementation contract.
   * This is a low level function that doesn't return to its internal call site.
   * It will return to the external caller whatever the implementation returns.
   * @param implementation Address to delegate.
   */
  function _delegate(address implementation) internal {
    //solium-disable-next-line
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize())

      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

      // Copy the returned data.
      returndatacopy(0, 0, returndatasize())

      switch result
        // delegatecall returns 0 on error.
        case 0 {
          revert(0, returndatasize())
        }
        default {
          return(0, returndatasize())
        }
    }
  }

  /**
   * @dev Function that is run as the first thing in the fallback function.
   * Can be redefined in derived contracts to add functionality.
   * Redefinitions must call super._willFallback().
   */
  function _willFallback() internal virtual {}

  /**
   * @dev fallback implementation.
   * Extracted to enable manual triggering.
   */
  function _fallback() internal {
    _willFallback();
    _delegate(_implementation());
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import './BaseUpgradeabilityProxy.sol';

/**
 * @title UpgradeabilityProxy
 * @dev Extends BaseUpgradeabilityProxy with a constructor for initializing
 * implementation and init data.
 */
contract UpgradeabilityProxy is BaseUpgradeabilityProxy {
  /**
   * @dev Contract constructor.
   * @param _logic Address of the initial implementation.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  constructor(address _logic, bytes memory _data) public payable {
    assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
    _setImplementation(_logic);
    if (_data.length > 0) {
      (bool success, ) = _logic.delegatecall(_data);
      require(success);
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface DataTypes {
  // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }
}

interface ILendingPool {
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

  function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

  function withdraw(address asset, uint256 amount, address to) external returns (uint256);

  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  function repay(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external returns (uint256);

  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) external;

  function getUserAccountData(
    address user
  )
    external
    view
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );
}

interface IAaveAddressesProvider {
  function getLendingPool() external view returns (address);
}

interface ILidoCurve {
  function exchange(
    int128 i,
    int128 j,
    uint256 dx,
    uint256 min_dy
  ) external payable returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IAggregationRouterV5 {
  function clipperSwap(
    address clipperExchange,
    address srcToken,
    address dstToken,
    uint256 inputAmount,
    uint256 outputAmount,
    uint256 goodUntil,
    bytes32 r,
    bytes32 vs
  ) external payable returns (uint256 returnAmount);

  function clipperSwapTo(
    address clipperExchange,
    address recipient,
    address srcToken,
    address dstToken,
    uint256 inputAmount,
    uint256 outputAmount,
    uint256 goodUntil,
    bytes32 r,
    bytes32 vs
  ) external payable returns (uint256 returnAmount);

  function clipperSwapToWithPermit(
    address clipperExchange,
    address recipient,
    address srcToken,
    address dstToken,
    uint256 inputAmount,
    uint256 outputAmount,
    uint256 goodUntil,
    bytes32 r,
    bytes32 vs,
    bytes memory permit
  ) external returns (uint256 returnAmount);

  function fillOrder(
    OrderLib.Order memory order,
    bytes memory signature,
    bytes memory interaction,
    uint256 makingAmount,
    uint256 takingAmount,
    uint256 skipPermitAndThresholdAmount
  ) external payable returns (uint256, uint256, bytes32);

  function fillOrderRFQ(
    OrderRFQLib.OrderRFQ memory order,
    bytes memory signature,
    uint256 flagsAndAmount
  ) external payable returns (uint256, uint256, bytes32);

  function fillOrderRFQCompact(
    OrderRFQLib.OrderRFQ memory order,
    bytes32 r,
    bytes32 vs,
    uint256 flagsAndAmount
  )
    external
    payable
    returns (uint256 filledMakingAmount, uint256 filledTakingAmount, bytes32 orderHash);

  function fillOrderRFQTo(
    OrderRFQLib.OrderRFQ memory order,
    bytes memory signature,
    uint256 flagsAndAmount,
    address target
  )
    external
    payable
    returns (uint256 filledMakingAmount, uint256 filledTakingAmount, bytes32 orderHash);

  function fillOrderRFQToWithPermit(
    OrderRFQLib.OrderRFQ memory order,
    bytes memory signature,
    uint256 flagsAndAmount,
    address target,
    bytes memory permit
  ) external returns (uint256, uint256, bytes32);

  function fillOrderTo(
    OrderLib.Order memory order_,
    bytes memory signature,
    bytes memory interaction,
    uint256 makingAmount,
    uint256 takingAmount,
    uint256 skipPermitAndThresholdAmount,
    address target
  )
    external
    payable
    returns (uint256 actualMakingAmount, uint256 actualTakingAmount, bytes32 orderHash);

  function fillOrderToWithPermit(
    OrderLib.Order memory order,
    bytes memory signature,
    bytes memory interaction,
    uint256 makingAmount,
    uint256 takingAmount,
    uint256 skipPermitAndThresholdAmount,
    address target,
    bytes memory permit
  ) external returns (uint256, uint256, bytes32);

  function swap(
    address executor,
    GenericRouter.SwapDescription memory desc,
    bytes memory permit,
    bytes memory data
  ) external payable returns (uint256 returnAmount, uint256 spentAmount);

  function uniswapV3Swap(
    uint256 amount,
    uint256 minReturn,
    uint256[] memory pools
  ) external payable returns (uint256 returnAmount);

  function uniswapV3SwapTo(
    address recipient,
    uint256 amount,
    uint256 minReturn,
    uint256[] memory pools
  ) external payable returns (uint256 returnAmount);

  function uniswapV3SwapToWithPermit(
    address recipient,
    address srcToken,
    uint256 amount,
    uint256 minReturn,
    uint256[] memory pools,
    bytes memory permit
  ) external returns (uint256 returnAmount);

  function unoswap(
    address srcToken,
    uint256 amount,
    uint256 minReturn,
    uint256[] memory pools
  ) external payable returns (uint256 returnAmount);

  function unoswapTo(
    address recipient,
    address srcToken,
    uint256 amount,
    uint256 minReturn,
    uint256[] memory pools
  ) external payable returns (uint256 returnAmount);

  function unoswapToWithPermit(
    address recipient,
    address srcToken,
    uint256 amount,
    uint256 minReturn,
    uint256[] memory pools,
    bytes memory permit
  ) external returns (uint256 returnAmount);
}

interface OrderLib {
  struct Order {
    uint256 salt;
    address makerAsset;
    address takerAsset;
    address maker;
    address receiver;
    address allowedSender;
    uint256 makingAmount;
    uint256 takingAmount;
    uint256 offsets;
    bytes interactions;
  }
}

interface OrderRFQLib {
  struct OrderRFQ {
    uint256 info;
    address makerAsset;
    address takerAsset;
    address maker;
    address allowedSender;
    uint256 makingAmount;
    uint256 takingAmount;
  }
}

interface GenericRouter {
  struct SwapDescription {
    address srcToken;
    address dstToken;
    address srcReceiver;
    address dstReceiver;
    uint256 amount;
    uint256 minReturnAmount;
    uint256 flags;
  }
}

interface IUniswapV2Router02 {
  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);
}

interface IUniswapV3Pool {
  function token0() external view returns (address);

  function token1() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

interface IBpool {
  function MAX_BOUND_TOKENS() external view returns (uint256);

  function MAX_WEIGHT() external view returns (uint256);

  function MIN_WEIGHT() external view returns (uint256);

  function execute(
    address _target,
    uint256 _value,
    bytes calldata _data
  ) external returns (bytes memory _returnValue);

  function getBalance(address token) external view returns (uint256);

  function getDenormalizedWeight(address token) external view returns (uint256);

  function getNumTokens() external view returns (uint256);

  function isBound(address t) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

interface IETF {
  function getController() external view returns (address);

  function adminList(address) external view returns (bool);

  function bPool() external view returns (address);

  function etype() external view returns (uint8);

  function isCompletedCollect() external view returns (bool);

  function _verifyWhiteToken(address token) external view;

  function etfStatus()
    external
    view
    returns (
      uint256 collectPeriod,
      uint256 collectEndTime,
      uint256 closurePeriod,
      uint256 closureEndTime,
      uint256 upperCap,
      uint256 floorCap,
      uint256 managerFee,
      uint256 redeemFee,
      uint256 issueFee,
      uint256 perfermanceFee,
      uint256 startClaimFeeTime
    );

  function execute(
    address _target,
    uint256 _value,
    bytes calldata _data,
    bool isUnderlying
  ) external returns (bytes memory _returnValue);
}

interface ICrpFactory {
  function isCrp(address addr) external view returns (bool);
}

interface IFactory {
  function isPaused() external view returns (bool);
}

pragma solidity 0.6.12;

interface ILeverageStake {
  function getAstETHBalance() external view returns (uint256 balance);

  function getStethBalance() external view returns (uint256 balance);

  function getBalanceSheet() external view returns (uint256, uint256);

  function getLeverageInfo()
    external
    view
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );

  function repayBorrow(uint256 amount) external returns (uint256);

  function batchIncreaseLever(
    uint256 collateral,
    uint256 leverage,
    uint16 referralCode,
    bool isTrade
  ) external;

  function batchDecreaseLever(uint256 startAmount) external;

  function increaseLever(
    uint256 amount,
    uint16 referralCode,
    bool isTrade
  ) external returns (uint256);

  function decreaseLever(uint256 amount) external returns (uint256, bool);

  function convertToAstEth(bool isTrade) external;

  function convertToWeth() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {IETF} from './IETF.sol';
import {IBpool} from './IBpool.sol';

interface IRebalanceAdapter {
  enum SwapType {
    UNISWAPV2,
    UNISWAPV3,
    ONEINCH
  }

  struct RebalanceInfo {
    address etf; // etf address
    address token0;
    address token1;
    address aggregator; // the swap router to use
    SwapType swapType;
    uint256 quantity;
    bytes data; // v3: (uint,uint256[]) v2: (uint256,address[])
  }

  function getUnderlyingInfo(
    IBpool bpool,
    address token
  ) external view returns (uint256 tokenBalance, uint256 tokenWeight);

  function approve(IETF etf, address token, address spender, uint256 amount) external;

  function approveSwapRouter(address router, bool isApproved) external;

  function rebalance(RebalanceInfo calldata rebalanceInfo) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface IWETH {
  function deposit() external payable;

  function withdraw(uint256) external;

  function approve(address guy, uint256 wad) external returns (bool);

  function transferFrom(address src, address dst, uint256 wad) external returns (bool);

  function balanceOf(address user) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {ERC20} from '../../dependencies/openzeppelin/contracts/ERC20.sol';

/**
 * @title ERC20Mintable
 * @dev ERC20 minting logic
 */
contract MintableDelegationERC20 is ERC20 {
  address public delegatee;

  constructor(
    string memory name,
    string memory symbol,
    uint8 decimals
  ) public ERC20(name, symbol) {
    _setupDecimals(decimals);
  }

  /**
   * @dev Function to mint tokensp
   * @param value The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(uint256 value) public returns (bool) {
    _mint(msg.sender, value);
    return true;
  }

  function delegate(address delegateeAddress) external {
    delegatee = delegateeAddress;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {ERC20} from '../../dependencies/openzeppelin/contracts/ERC20.sol';

/**
 * @title ERC20Mintable
 * @dev ERC20 minting logic
 */
contract MintableERC20 is ERC20 {
  constructor(
    string memory name,
    string memory symbol,
    uint8 decimals
  ) public ERC20(name, symbol) {
    _setupDecimals(decimals);
  }

  /**
   * @dev Function to mint tokens
   * @param value The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(uint256 value) public returns (bool) {
    _mint(_msgSender(), value);
    return true;
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {IERC20} from '../dependencies/openzeppelin/contracts/IERC20.sol';
import {SafeMath} from '../dependencies/openzeppelin/contracts/SafeMath.sol';
import {Ownable} from '../dependencies/openzeppelin/contracts/Ownable.sol';
import {IBpool} from '../interfaces/IBpool.sol';
import {Invoke} from '../dependencies/Invoke.sol';
import {IRebalanceAdapter} from '../interfaces/IRebalanceAdapter.sol';
import '../interfaces/IETF.sol';
import '../interfaces/IAggregationRouterV5.sol';

contract RebalanceAdapter is IRebalanceAdapter, Ownable {
  using SafeMath for uint256;
  using Invoke for IETF;

  modifier onlyManager(address _etf) {
    require(
      IETF(_etf).adminList(msg.sender) || msg.sender == IETF(_etf).getController(),
      'onlyAdmin'
    );
    _;
  }

  modifier validEtf(address _etf) {
    require(ICrpFactory(crpFactory).isCrp(_etf), 'NOT_VALID_ETF');
    _;
  }

  uint256 private constant _ONE_FOR_ZERO_MASK = 1 << 255;

  // swap router should be approved before using
  mapping(address => bool) public isRouterApproved;
  address public factory;
  address public crpFactory;

  // =========== events ===================
  event CrpFactoryUpdated(address old, address newCrp);
  event FactoryUpdated(address old, address newF);
  event RouterStateChange(address router, bool isApproved);
  event TokenApproved(address etf, address token, address spender, uint256 amount);
  /// @notice Event emited after rebalancing
  /// @param token0 The token to sell
  /// @param token1 The token to buy
  /// @param newWeight0 New weight of token0
  /// @param newWeight1 New weight of token1
  /// @param newBalance0 New balance of token0
  /// @param newBalance1 New balance of token1
  /// @param isSoldOut Is sold out token0
  event Rebalanced(
    address indexed token0,
    address indexed token1,
    uint newWeight0,
    uint newWeight1,
    uint newBalance0,
    uint newBalance1,
    bool isSoldOut
  );

  constructor(address _crpFactory, address _factory) public {
    crpFactory = _crpFactory;
    factory = _factory;
  }

  // =========== view functions ===================

  /// @notice Returns the new weight and balance of underlying tokens after rebalancing
  /// @param bPool The underlying pool of etf
  /// @param token The rebalanced token address
  /// @return tokenBalance The new balance of token
  /// @return tokenWeight The new weight of token
  function getUnderlyingInfo(
    IBpool bPool,
    address token
  ) external view override returns (uint256 tokenBalance, uint256 tokenWeight) {
    tokenBalance = bPool.getBalance(token);
    tokenWeight = bPool.getDenormalizedWeight(token);
  }

  /// @notice Returns the allowance the underlying token approved to the spender
  /// @param bPool The underlying pool of etf
  /// @param token The token which reside in the bPool
  /// @param spender The account the bPool gives allowance to
  /// @return allowance The remaining allowance
  function getUnderlyingAllowance(
    address bPool,
    address token,
    address spender
  ) external view returns (uint256 allowance) {
    allowance = IERC20(token).allowance(bPool, spender);
  }

  function getSig(bytes memory _data) private pure returns (bytes4 sig) {
    assembly {
      sig := mload(add(_data, 32))
    }
  }

  // =========== external functions ===================

  /// @notice Enable or disable a swap router to use across the adapter
  /// @param router The swap router address
  /// @param isApproved The state want to change to, true or false
  function approveSwapRouter(address router, bool isApproved) external override onlyOwner {
    require(router != address(0), '!ZERO');
    isRouterApproved[router] = isApproved;

    emit RouterStateChange(router, isApproved);
  }

  /// @notice Approve allowance for underlying token
  /// @param etf The etf which contains the token
  /// @param token The underlying token to approve
  /// @param spender The account to consume the allowance
  /// @param amount The allowance amount
  function approve(
    IETF etf,
    address token,
    address spender,
    uint256 amount
  ) external override validEtf(address(etf)) onlyManager(address(etf)) {
    require(isRouterApproved[spender], 'SPENDER_NOT_APPROVED');

    etf.invokeApprove(token, spender, amount, true);

    emit TokenApproved(address(etf), token, spender, amount);
  }

  /// @notice Rebalance the position of the underlying tokens in etf
  /// @param rebalanceInfo Key information to perform rebalance
  function rebalance(
    IRebalanceAdapter.RebalanceInfo calldata rebalanceInfo
  ) external override validEtf(rebalanceInfo.etf) onlyManager(rebalanceInfo.etf) {
    IETF etf = IETF(rebalanceInfo.etf);
    IBpool bPool = IBpool(etf.bPool());

    require(address(bPool) != address(0), 'ZERO_BPOOL');
    require(!IFactory(factory).isPaused(), 'PAUSED');

    etf._verifyWhiteToken(rebalanceInfo.token1);

    require(bPool.isBound(rebalanceInfo.token0), 'TOKEN_NOT_BOUND');

    (, uint256 collectEndTime, , uint256 closureEndTime, , , , , , , ) = etf.etfStatus();
    if (etf.etype() == 1) {
      require(etf.isCompletedCollect(), 'COLLECTION_FAILED');
      require(
        block.timestamp > collectEndTime && block.timestamp < closureEndTime,
        'NOT_REBALANCE_PERIOD'
      );
    }

    if (!bPool.isBound(rebalanceInfo.token1)) {
      IETF(rebalanceInfo.etf).invokeApprove(rebalanceInfo.token1, address(bPool), 0, false);
      IETF(rebalanceInfo.etf).invokeApprove(
        rebalanceInfo.token1,
        address(bPool),
        uint256(-1),
        false
      );
    }

    require(rebalanceInfo.token0 != rebalanceInfo.token1, 'TOKENS_SAME');

    uint256 receivedAmount = _makeSwap(rebalanceInfo, etf.bPool());

    _rebalance(etf, bPool, rebalanceInfo, receivedAmount);
  }

  function setFactory(address _factory) external onlyOwner {
    require(_factory != address(0), 'ZERO ADDRESS');

    emit FactoryUpdated(factory, _factory);

    factory = _factory;
  }

  function setCrpFactory(address _crpFactory) external onlyOwner {
    require(_crpFactory != address(0), 'ZERO ADDRESS');

    emit CrpFactoryUpdated(crpFactory, _crpFactory);

    crpFactory = _crpFactory;
  }

  struct RebalanceResult {
    uint256 newWeight0;
    uint256 newWeight1;
    uint256 newBalance0;
    uint256 newBalance1;
    bool isSoldOut;
  }

  /// @notice Internal function to perform rebalance
  /// @param etf The etf expected to rebalance
  /// @param bPool The underlying pool of the etf
  /// @param rebalanceInfo Key information to perform rebalance
  /// @param token1Received The amount received after exchange by a swap router
  function _rebalance(
    IETF etf,
    IBpool bPool,
    IRebalanceAdapter.RebalanceInfo calldata rebalanceInfo,
    uint256 token1Received
  ) internal {
    uint256 currentWeight0 = bPool.getDenormalizedWeight(rebalanceInfo.token0);
    uint256 currentBalance0 = bPool.getBalance(rebalanceInfo.token0);

    uint256 deltaWeight = currentWeight0.mul(rebalanceInfo.quantity).div(currentBalance0);

    require(deltaWeight <= currentWeight0, 'DELTA_WEIGHT_TOO_BIG');

    RebalanceResult memory vars;

    vars.isSoldOut = rebalanceInfo.quantity == currentBalance0;
    if (vars.isSoldOut) {
      etf.invokeUnbind(rebalanceInfo.token0);
    } else {
      vars.newWeight0 = currentWeight0.sub(deltaWeight);
      vars.newBalance0 = currentBalance0.sub(rebalanceInfo.quantity);
      require(vars.newWeight0 >= bPool.MIN_WEIGHT(), 'MIN_WEIGHT_WRONG');

      etf.invokeRebind(rebalanceInfo.token0, vars.newBalance0, vars.newWeight0, true);
    }

    if (bPool.isBound(rebalanceInfo.token1)) {
      // token1 alread exists
      uint256 currentWeight1 = bPool.getDenormalizedWeight(rebalanceInfo.token1);
      uint256 currentBalance1 = bPool.getBalance(rebalanceInfo.token1);
      vars.newWeight1 = currentWeight1.add(deltaWeight);
      vars.newBalance1 = currentBalance1.add(token1Received);

      require(vars.newWeight1 <= bPool.MAX_WEIGHT(), 'EXCEEDS_MAX_WEIGHT');
      etf.invokeRebind(rebalanceInfo.token1, vars.newBalance1, vars.newWeight1, true);
    } else {
      // token1 is out of the etf
      require(bPool.getNumTokens() < bPool.MAX_BOUND_TOKENS(), 'MAX_BOUND_TOKENS');

      require(deltaWeight >= bPool.MIN_WEIGHT(), 'MIN_WEIGHT_WRONG');

      vars.newWeight1 = deltaWeight;
      vars.newBalance1 = token1Received;

      etf.invokeRebind(rebalanceInfo.token1, vars.newBalance1, vars.newWeight1, false);
    }

    emit Rebalanced(
      rebalanceInfo.token0,
      rebalanceInfo.token1,
      vars.newWeight0,
      vars.newWeight1,
      vars.newBalance0,
      vars.newBalance1,
      vars.isSoldOut
    );
  }

  /// @notice Internal function to execute swap
  /// @param rebalanceInfo Key information to perform rebalance
  /// @param bPool Underlying pool of etf
  function _makeSwap(
    IRebalanceAdapter.RebalanceInfo calldata rebalanceInfo,
    address bPool
  ) internal returns (uint256 postSwap) {
    require(isRouterApproved[rebalanceInfo.aggregator], 'ROUTER_NOT_APPROVED');

    // approve first
    IETF(rebalanceInfo.etf).invokeApprove(
      rebalanceInfo.token0,
      rebalanceInfo.aggregator,
      rebalanceInfo.quantity,
      true
    );

    uint256 preSwap = IERC20(rebalanceInfo.token1).balanceOf(bPool);

    if (rebalanceInfo.swapType == IRebalanceAdapter.SwapType.UNISWAPV3) {
      (uint256 minReturn, uint256[] memory pools) = abi.decode(
        rebalanceInfo.data,
        (uint256, uint256[])
      );

      _checkPools(pools[pools.length - 1], rebalanceInfo.token1);

      bytes memory swapData = abi.encodeWithSignature(
        'uniswapV3Swap(uint256,uint256,uint256[])',
        rebalanceInfo.quantity,
        minReturn,
        pools
      );

      IETF(rebalanceInfo.etf).execute(rebalanceInfo.aggregator, 0, swapData, true);
    } else if (rebalanceInfo.swapType == IRebalanceAdapter.SwapType.UNISWAPV2) {
      (uint256 minReturn, address[] memory paths) = abi.decode(
        rebalanceInfo.data,
        (uint256, address[])
      );

      address output = paths[paths.length - 1];
      require(output == rebalanceInfo.token1, 'MALICIOUS_PATH');

      bytes memory swapData = abi.encodeWithSignature(
        'swapExactTokensForTokens(uint256,uint256,address[],address,uint256)',
        rebalanceInfo.quantity,
        minReturn,
        paths,
        bPool,
        block.timestamp.add(1800)
      );

      IETF(rebalanceInfo.etf).execute(rebalanceInfo.aggregator, 0, swapData, true);
    } else {
      _validateData(rebalanceInfo.quantity, rebalanceInfo.data, rebalanceInfo.token1, bPool);

      IETF(rebalanceInfo.etf).execute(rebalanceInfo.aggregator, 0, rebalanceInfo.data, true);
    }

    postSwap = IERC20(rebalanceInfo.token1).balanceOf(bPool).sub(preSwap);
  }

  function _checkPools(uint256 pool, address expectedOutput) internal view {
    bool zeroForOne = pool & _ONE_FOR_ZERO_MASK == 0;
    address output = zeroForOne
      ? IUniswapV3Pool(address(uint160(pool))).token1()
      : IUniswapV3Pool(address(uint160(pool))).token0();
    require(output == expectedOutput, 'MIS_OUTPUT');
  }

  /**
   * @notice Internal function to validate transaction data
   * @param quantity The token amount to consume
   * @param data The calldata to call the aggregator
   * @param expectedReceiver The expected account to receive the swapped asset
   **/
  function _validateData(
    uint256 quantity,
    bytes calldata data,
    address output,
    address expectedReceiver
  ) internal view {
    bytes4 selector = getSig(data);
    if (selector == IAggregationRouterV5.swap.selector) {
      (, GenericRouter.SwapDescription memory desc, , ) = abi.decode(
        data[4:],
        (address, GenericRouter.SwapDescription, bytes, bytes)
      );
      require(quantity == desc.amount, 'QUANTITY_MISMATCH');
      require(output == desc.dstToken, 'MIS_OUTPUT');
      require(expectedReceiver == desc.dstReceiver, 'WRONG_RECEIVE');
    } else if (selector == IAggregationRouterV5.unoswap.selector) {
      (, uint256 amount, , uint256[] memory pools) = abi.decode(
        data[4:],
        (address, uint256, uint256, uint256[])
      );

      _checkPools(pools[pools.length - 1], output);

      require(quantity == amount, 'QUANTITY_MISMATCH');
    } else if (selector == IAggregationRouterV5.unoswapTo.selector) {
      (address recipient, , uint256 amount, , uint256[] memory pools) = abi.decode(
        data[4:],
        (address, address, uint256, uint256, uint256[])
      );

      _checkPools(pools[pools.length - 1], output);

      require(quantity == amount, 'QUANTITY_MISMATCH');
      require(expectedReceiver == recipient, 'WRONG_RECEIVE');
    } else if (selector == IAggregationRouterV5.uniswapV3Swap.selector) {
      (uint256 amount, , uint256[] memory pools) = abi.decode(
        data[4:],
        (uint256, uint256, uint256[])
      );

      _checkPools(pools[pools.length - 1], output);

      require(quantity == amount, 'QUANTITY_MISMATCH');
    } else if (selector == IAggregationRouterV5.uniswapV3SwapTo.selector) {
      (address recipient, uint256 amount, , uint256[] memory pools) = abi.decode(
        data[4:],
        (address, uint256, uint256, uint256[])
      );

      _checkPools(pools[pools.length - 1], output);

      require(quantity == amount, 'QUANTITY_MISMATCH');
      require(expectedReceiver == recipient, 'WRONG_RECEIVE');
    } else if (selector == IAggregationRouterV5.clipperSwap.selector) {
      (, , address dstToken, uint256 inputAmount, , , , ) = abi.decode(
        data[4:],
        (address, address, address, uint256, uint256, uint256, bytes32, bytes32)
      );

      require(output == dstToken, 'MIS_OUTPUT');
      require(quantity == inputAmount, 'QUANTITY_MISMATCH');
    } else if (selector == IAggregationRouterV5.clipperSwapTo.selector) {
      (, address recipient, , address dstToken, uint256 inputAmount, , , , ) = abi.decode(
        data[4:],
        (address, address, address, address, uint256, uint256, uint256, bytes32, bytes32)
      );

      require(quantity == inputAmount, 'QUANTITY_MISMATCH');
      require(output == dstToken, 'MIS_OUTPUT');
      require(expectedReceiver == recipient, 'WRONG_RECEIVE');
    } else if (selector == IAggregationRouterV5.fillOrder.selector) {
      (OrderLib.Order memory order, , , , , ) = abi.decode(
        data[4:],
        (OrderLib.Order, bytes, bytes, uint256, uint256, uint256)
      );

      require(quantity == order.makingAmount, 'QUANTITY_MISMATCH');
      require(output == order.takerAsset, 'MIS_OUTPUT');
      require(expectedReceiver == order.receiver, 'WRONG_RECEIVE');
    } else if (selector == IAggregationRouterV5.fillOrderRFQ.selector) {
      (OrderRFQLib.OrderRFQ memory order, , ) = abi.decode(
        data[4:],
        (OrderRFQLib.OrderRFQ, bytes, uint256)
      );

      require(quantity == order.makingAmount, 'QUANTITY_MISMATCH');
    } else if (selector == IAggregationRouterV5.fillOrderRFQTo.selector) {
      (OrderRFQLib.OrderRFQ memory order, , , address target) = abi.decode(
        data[4:],
        (OrderRFQLib.OrderRFQ, bytes, uint256, address)
      );

      require(quantity == order.makingAmount, 'QUANTITY_MISMATCH');
      require(output == order.takerAsset, 'MIS_OUTPUT');
      require(expectedReceiver == target, 'WRONG_RECEIVE');
    } else if (selector == IAggregationRouterV5.fillOrderTo.selector) {
      (OrderLib.Order memory order, , , , , , address target) = abi.decode(
        data[4:],
        (OrderLib.Order, bytes, bytes, uint256, uint256, uint256, address)
      );

      require(quantity == order.makingAmount, 'QUANTITY_MISMATCH');
      require(output == order.takerAsset, 'MIS_OUTPUT');
      require(expectedReceiver == target, 'WRONG_RECEIVE');
    } else {
      revert('WRONG_METHOD');
    }
  }
}

pragma solidity 0.6.12;

import {IERC20} from '../dependencies/openzeppelin/contracts/IERC20.sol';
import {ILendingPool} from '../interfaces/IAggregationInterface.sol';
import {IETF} from '../interfaces/IETF.sol';

/**
 * @title AaveCall
 * @author Desyn Protocol
 *
 * Collection of helper functions for interacting with AaveCall integrations.
 */
library AaveCall {
  /* ============ External ============ */

  /**
   * Get deposit calldata from ETF
   *
   * Deposits an `_amountNotional` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param _lendingPool          Address of the LendingPool contract
   * @param _asset                The address of the underlying asset to deposit
   * @param _amountNotional       The amount to be deposited
   * @param _onBehalfOf           The address that will receive the aTokens, same as msg.sender if the user
   *                              wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *                              is a different wallet
   * @param _referralCode         Code used to register the integrator originating the operation, for potential rewards.
   *                              0 if the action is executed directly by the user, without any middle-man
   *
   * @return address              Target contract address
   * @return uint256              Call value
   * @return bytes                Deposit calldata
   */
  function getDepositCalldata(
    ILendingPool _lendingPool,
    address _asset,
    uint256 _amountNotional,
    address _onBehalfOf,
    uint16 _referralCode
  ) internal pure returns (address, uint256, bytes memory) {
    bytes memory callData = abi.encodeWithSignature(
      'deposit(address,uint256,address,uint16)',
      _asset,
      _amountNotional,
      _onBehalfOf,
      _referralCode
    );

    return (address(_lendingPool), 0, callData);
  }

  /**
   * Invoke deposit on LendingPool from ETF
   *
   * Deposits an `_amountNotional` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. ETF deposits 100 USDC and gets in return 100 aUSDC
   * @param _etf             Address of the ETF
   * @param _lendingPool          Address of the LendingPool contract
   * @param _asset                The address of the underlying asset to deposit
   * @param _amountNotional       The amount to be deposited
   */
  function invokeDeposit(
    IETF _etf,
    ILendingPool _lendingPool,
    address _asset,
    uint256 _amountNotional
  ) internal {
    (, , bytes memory depositCalldata) = getDepositCalldata(
      _lendingPool,
      _asset,
      _amountNotional,
      address(_etf.bPool()),
      0
    );

    _etf.execute(address(_lendingPool), 0, depositCalldata, true);
  }

  /**
   * Get withdraw calldata from ETF
   *
   * Withdraws an `_amountNotional` of underlying asset from the reserve, burning the equivalent aTokens owned
   * - E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param _lendingPool          Address of the LendingPool contract
   * @param _asset                The address of the underlying asset to withdraw
   * @param _amountNotional       The underlying amount to be withdrawn
   *                              Note: Passing type(uint256).max will withdraw the entire aToken balance
   * @param _receiver             Address that will receive the underlying, same as msg.sender if the user
   *                              wants to receive it on his own wallet, or a different address if the beneficiary is a
   *                              different wallet
   *
   * @return address              Target contract address
   * @return uint256              Call value
   * @return bytes                Withdraw calldata
   */
  function getWithdrawCalldata(
    ILendingPool _lendingPool,
    address _asset,
    uint256 _amountNotional,
    address _receiver
  ) internal pure returns (address, uint256, bytes memory) {
    bytes memory callData = abi.encodeWithSignature(
      'withdraw(address,uint256,address)',
      _asset,
      _amountNotional,
      _receiver
    );

    return (address(_lendingPool), 0, callData);
  }

  /**
   * Invoke withdraw on LendingPool from ETF
   *
   * Withdraws an `_amountNotional` of underlying asset from the reserve, burning the equivalent aTokens owned
   * - E.g. ETF has 100 aUSDC, and receives 100 USDC, burning the 100 aUSDC
   *
   * @param _etf         Address of the ETF
   * @param _lendingPool      Address of the LendingPool contract
   * @param _asset            The address of the underlying asset to withdraw
   * @param _amountNotional   The underlying amount to be withdrawn
   *                          Note: Passing type(uint256).max will withdraw the entire aToken balance
   *
   * @return uint256          The final amount withdrawn
   */
  function invokeWithdraw(
    IETF _etf,
    ILendingPool _lendingPool,
    address _asset,
    uint256 _amountNotional
  ) internal returns (uint256) {
    (, , bytes memory withdrawCalldata) = getWithdrawCalldata(
      _lendingPool,
      _asset,
      _amountNotional,
      address(_etf.bPool())
    );

    return abi.decode(_etf.execute(address(_lendingPool), 0, withdrawCalldata, true), (uint256));
  }

  /**
   * Get borrow calldata from ETF
   *
   * Allows users to borrow a specific `_amountNotional` of the reserve underlying `_asset`, provided that
   * the borrower already deposited enough collateral, or he was given enough allowance by a credit delegator
   * on the corresponding debt token (StableDebtToken or VariableDebtToken)
   *
   * @param _lendingPool          Address of the LendingPool contract
   * @param _asset                The address of the underlying asset to borrow
   * @param _amountNotional       The amount to be borrowed
   * @param _interestRateMode     The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param _referralCode         Code used to register the integrator originating the operation, for potential rewards.
   *                              0 if the action is executed directly by the user, without any middle-man
   * @param _onBehalfOf           Address of the user who will receive the debt. Should be the address of the borrower itself
   *                              calling the function if he wants to borrow against his own collateral, or the address of the
   *                              credit delegator if he has been given credit delegation allowance
   *
   * @return address              Target contract address
   * @return uint256              Call value
   * @return bytes                Borrow calldata
   */
  function getBorrowCalldata(
    ILendingPool _lendingPool,
    address _asset,
    uint256 _amountNotional,
    uint256 _interestRateMode,
    uint16 _referralCode,
    address _onBehalfOf
  ) internal pure returns (address, uint256, bytes memory) {
    bytes memory callData = abi.encodeWithSignature(
      'borrow(address,uint256,uint256,uint16,address)',
      _asset,
      _amountNotional,
      _interestRateMode,
      _referralCode,
      _onBehalfOf
    );

    return (address(_lendingPool), 0, callData);
  }

  /**
   * Invoke borrow on LendingPool from ETF
   *
   * Allows ETF to borrow a specific `_amountNotional` of the reserve underlying `_asset`, provided that
   * the ETF already deposited enough collateral, or it was given enough allowance by a credit delegator
   * on the corresponding debt token (StableDebtToken or VariableDebtToken)
   * @param _etf             Address of the ETF
   * @param _lendingPool          Address of the LendingPool contract
   * @param _asset                The address of the underlying asset to borrow
   * @param _amountNotional       The amount to be borrowed
   * @param _interestRateMode     The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   */
  function invokeBorrow(
    IETF _etf,
    ILendingPool _lendingPool,
    address _asset,
    uint256 _amountNotional,
    uint256 _interestRateMode,
    uint16 referralCode
  ) internal {
    (, , bytes memory borrowCalldata) = getBorrowCalldata(
      _lendingPool,
      _asset,
      _amountNotional,
      _interestRateMode,
      referralCode,
      address(_etf.bPool())
    );

    _etf.execute(address(_lendingPool), 0, borrowCalldata, true);
  }

  /**
   * Get repay calldata from ETF
   *
   * Repays a borrowed `_amountNotional` on a specific `_asset` reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param _lendingPool          Address of the LendingPool contract
   * @param _asset                The address of the borrowed underlying asset previously borrowed
   * @param _amountNotional       The amount to repay
   *                              Note: Passing type(uint256).max will repay the whole debt for `_asset` on the specific `_interestRateMode`
   * @param _interestRateMode     The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param _onBehalfOf           Address of the user who will get his debt reduced/removed. Should be the address of the
   *                              user calling the function if he wants to reduce/remove his own debt, or the address of any other
   *                              other borrower whose debt should be removed
   *
   * @return address              Target contract address
   * @return uint256              Call value
   * @return bytes                Repay calldata
   */
  function getRepayCalldata(
    ILendingPool _lendingPool,
    address _asset,
    uint256 _amountNotional,
    uint256 _interestRateMode,
    address _onBehalfOf
  ) internal pure returns (address, uint256, bytes memory) {
    bytes memory callData = abi.encodeWithSignature(
      'repay(address,uint256,uint256,address)',
      _asset,
      _amountNotional,
      _interestRateMode,
      _onBehalfOf
    );

    return (address(_lendingPool), 0, callData);
  }

  /**
   * Invoke repay on LendingPool from ETF
   *
   * Repays a borrowed `_amountNotional` on a specific `_asset` reserve, burning the equivalent debt tokens owned
   * - E.g. ETF repays 100 USDC, burning 100 variable/stable debt tokens
   * @param _etf             Address of the ETF
   * @param _lendingPool          Address of the LendingPool contract
   * @param _asset                The address of the borrowed underlying asset previously borrowed
   * @param _amountNotional       The amount to repay
   *                              Note: Passing type(uint256).max will repay the whole debt for `_asset` on the specific `_interestRateMode`
   * @param _interestRateMode     The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   *
   * @return uint256              The final amount repaid
   */
  function invokeRepay(
    IETF _etf,
    ILendingPool _lendingPool,
    address _asset,
    uint256 _amountNotional,
    uint256 _interestRateMode
  ) internal returns (uint256) {
    (, , bytes memory repayCalldata) = getRepayCalldata(
      _lendingPool,
      _asset,
      _amountNotional,
      _interestRateMode,
      address(_etf.bPool())
    );

    return abi.decode(_etf.execute(address(_lendingPool), 0, repayCalldata, true), (uint256));
  }

  /**
   * Get setUserUseReserveAsCollateral calldata from ETF
   *
   * Allows borrower to enable/disable a specific deposited asset as collateral
   * @param _lendingPool          Address of the LendingPool contract
   * @param _asset                The address of the underlying asset deposited
   * @param _useAsCollateral      true` if the user wants to use the deposit as collateral, `false` otherwise
   *
   * @return address              Target contract address
   * @return uint256              Call value
   * @return bytes                SetUserUseReserveAsCollateral calldata
   */
  function getSetUserUseReserveAsCollateralCalldata(
    ILendingPool _lendingPool,
    address _asset,
    bool _useAsCollateral
  ) internal pure returns (address, uint256, bytes memory) {
    bytes memory callData = abi.encodeWithSignature(
      'setUserUseReserveAsCollateral(address,bool)',
      _asset,
      _useAsCollateral
    );

    return (address(_lendingPool), 0, callData);
  }

  /**
   * Invoke an asset to be used as collateral on Aave from ETF
   *
   * Allows ETF to enable/disable a specific deposited asset as collateral
   * @param _etf             Address of the ETF
   * @param _lendingPool          Address of the LendingPool contract
   * @param _asset                The address of the underlying asset deposited
   * @param _useAsCollateral      true` if the user wants to use the deposit as collateral, `false` otherwise
   */
  function invokeSetUserUseReserveAsCollateral(
    IETF _etf,
    ILendingPool _lendingPool,
    address _asset,
    bool _useAsCollateral
  ) internal {
    (, , bytes memory callData) = getSetUserUseReserveAsCollateralCalldata(
      _lendingPool,
      _asset,
      _useAsCollateral
    );

    _etf.execute(address(_lendingPool), 0, callData, true);
  }

  /**
   * Get swapBorrowRate calldata from ETF
   *
   * Allows a borrower to toggle his debt between stable and variable mode
   * @param _lendingPool      Address of the LendingPool contract
   * @param _asset            The address of the underlying asset borrowed
   * @param _rateMode         The rate mode that the user wants to swap to
   *
   * @return address          Target contract address
   * @return uint256          Call value
   * @return bytes            SwapBorrowRate calldata
   */
  function getSwapBorrowRateModeCalldata(
    ILendingPool _lendingPool,
    address _asset,
    uint256 _rateMode
  ) internal pure returns (address, uint256, bytes memory) {
    bytes memory callData = abi.encodeWithSignature(
      'swapBorrowRateMode(address,uint256)',
      _asset,
      _rateMode
    );

    return (address(_lendingPool), 0, callData);
  }

  /**
   * Invoke to swap borrow rate of ETF
   *
   * Allows ETF to toggle it's debt between stable and variable mode
   * @param _etf         Address of the ETF
   * @param _lendingPool      Address of the LendingPool contract
   * @param _asset            The address of the underlying asset borrowed
   * @param _rateMode         The rate mode that the user wants to swap to
   */
  function invokeSwapBorrowRateMode(
    IETF _etf,
    ILendingPool _lendingPool,
    address _asset,
    uint256 _rateMode
  ) internal {
    (, , bytes memory callData) = getSwapBorrowRateModeCalldata(_lendingPool, _asset, _rateMode);

    _etf.execute(address(_lendingPool), 0, callData, true);
  }
}