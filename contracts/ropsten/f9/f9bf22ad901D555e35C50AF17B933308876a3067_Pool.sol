// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

import "./interfaces/IExchange.sol";
import "./interfaces/IPool.sol";

import "./PoolStorage.sol";

/// @title Pool
contract Pool is PoolStorage {
  /**
   * Constructor.
   * @param _entryAsset main application asset.
   * @param _feeAddress address for collecting application fees.
   * @param _investFee the fee charged for each investment.
   * @param _successFee the fee charged for the successful generation of profit from the application.
   * @param swapRouter_ wrapper over the router exchange.
   * @param wrapOfNativeToken_ address to check if entryAsset is a native blockchain token or not.
   * @param _min the minimum possible amount of tokens for investment.
   * @param _name the name of the token pool (e.g. TokenName-pool).
   * @param _fees - fee of each pool. (If pancake - empty array)
   * @param _poolTokens the addresses of the tokens to which the entryAsset will be exchanged.
   * @param _poolDistribution Asset allocation. The percentage of the pool's asset allocation.

   * @dev if entryAsset will be a native blockchain token - `_entryAsset` must be a wrapped token of it.
   * `_investFee` charged in entryAsset tokens (if entryAsset is the native blockchain token - fee will be in that).
   * `_investFee` & `_successFee` are calculated as hundredths of the amount of tokens.
   * if `wrapOfNativeToken_` is address(0) - entry asset is not a native token.
   * sum of all distributions must be equal 100.
   */
  constructor(
    address _entryAsset,
    address _feeAddress,
    uint8 _investFee,
    uint8 _successFee,
    address swapRouter_,
    address wrapOfNativeToken_,
    uint256 _min,
    string memory _name,
    uint24[] memory _fees,
    address[] memory _poolTokens,
    uint8[] memory _poolDistribution
  )
    PoolStorage(swapRouter_, wrapOfNativeToken_)
    validDistribution(_poolDistribution)
  {
    require(_poolTokens.length == _poolDistribution.length);
    require(_min > 0, "new minInvest is 0");
    require(_investFee <= 50, "new invest fee is too big");
    require(_successFee <= 50, "new success fee is too big");

    poolInfo.entryAsset = _entryAsset;
    poolInfo.poolSize = uint8(_poolTokens.length);
    poolInfo.feeAddress = _feeAddress;
    poolInfo.investFee = _investFee;
    poolInfo.successFee = _successFee;

    // an array must be not empty only when router - uniswap
    if (_fees.length != 0) {
      fees = _fees;
    }

    name = _name;
    _minInvest = _min;

    // the amount of gas consumption is less due to the removal of the overflow check
    unchecked {
      for (uint256 i; i < _poolTokens.length; i++) {
        poolInfo.poolDistribution.push(_poolDistribution[i]);
        poolInfo.poolTokens.push(_poolTokens[i]);
        _poolTokensBalances.push(0);
      }
    }
  }

  /// @notice returns address of the swapRouter
  function swapRouter() external view returns (address) {
    return address(_swapRouter);
  }

  /// @notice returns current swapped tokens balances.
  function poolTokensBalances() external view returns (uint256[] memory) {
    return _poolTokensBalances;
  }

  /// @notice returns investment by user address and array index.
  /// @dev revets with not exists investments
  function investmentByUser(address investor, uint256 investmentId)
    external
    view
    virtual
    returns (InvestmentData memory)
  {
    return _investmentDataByUser[investor][investmentId];
  }

  /// @notice returns all investments by user address.
  function investmentsByUser(address investor)
    external
    view
    virtual
    returns (InvestmentData[] memory)
  {
    return _investmentDataByUser[investor];
  }

  /// @notice returns address of entry asset.
  function entryAsset() external view returns (address) {
    return poolInfo.entryAsset;
  }

  /// @notice returns the addresses of the tokens.
  function tokenList() external view returns (address[] memory) {
    return poolInfo.poolTokens;
  }

  /// @notice returns the ssset allocation.
  function poolTokensDistributions() external view returns (uint8[] memory) {
    return poolInfo.poolDistribution;
  }

  /// @notice returns poolData.
  function poolData() external view returns (PoolData memory) {
    PoolData memory _poolData = PoolData({
      owner: owner(),
      entryAsset: poolInfo.entryAsset,
      poolTokens: poolInfo.poolTokens,
      poolDistribution: poolInfo.poolDistribution,
      poolTokensBalances: _poolTokensBalances,
      poolSize: poolInfo.poolSize,
      feeAddress: poolInfo.feeAddress,
      investFee: poolInfo.investFee,
      successFee: poolInfo.successFee,
      totalReceivedCurrency: totalReceivedCurrency,
      totalInvestFee: totalInvestFee,
      totalSuccessFee: totalSuccessFee
    });

    return _poolData;
  }

  /**
   * @notice sending assets in a native blockchain token will trigger the investment function.
   * taking the sent currency for the investment amount.
   *
   * @dev reverts when _wrapOfNativeToken is address(0).
   * @dev reverts when the amount of token to be sent is less than the minimum possible investment.
   * @dev reverts when the application is paused
   * @dev emits the `Invested` event.
   */
  receive() external payable nonReentrant whenNotPaused {
    require(_wrapOfNativeToken != address(0), "entry asset not native token");
    require(msg.value >= _minInvest, "amount is too small");
    _initInvestment(msg.sender, msg.value, msg.value > 0);
  }

  /**
   * @notice function to initialize the investment.
   * @param amount - amount of tokens for investment.
   *
   * @dev reverts when the amount of token to be sent is less than the minimum possible investment.
   * @dev reverts when the application is paused.
   * @dev if _wrapOfNativeToken is not address(0) - msg.value must be equal param `amount`.
   * @dev emits the `Invested` event.
   */
  function invest(uint256 amount) external payable whenNotPaused nonReentrant {
    require(amount >= _minInvest, "amount is too small");

    if (_wrapOfNativeToken != address(0)) {
      require(msg.value == amount, "wrong value");
    }

    _initInvestment(msg.sender, amount, msg.value > 0);
  }

  /**
   * @notice function to withdraw the investment.
   * @param investmentId - index of investment, given by user.
   *
   * @dev reverts when investmentId is not exist yet.
   * @dev reverts when investment not active.
   * @dev emits the `InvestmentWithdrawal` event.
   */
  function withdraw(uint256 investmentId) external nonReentrant {
    uint256 investCount = investmentIds[msg.sender];
    require(
      investmentId <= investCount && investCount > 0,
      "investment non-exists"
    );

    InvestmentData memory _investData = _investmentDataByUser[msg.sender][
      investmentId
    ];

    require(_investData.active, "investment not active");

    PoolInfo memory _poolInfo = poolInfo;
    uint256 entryAssetAmount;
    uint256 timestamp;
    unchecked {
      // overflow is not possible
      timestamp = block.timestamp + 1200; // 20 mins
      totalReceivedCurrency -= _investData.receivedCurrency;
    }
    uint24[] memory _fees = fees;

    for (uint256 i; i < _poolInfo.poolSize; i++) {
      uint256 tokenBalance = _investData.tokenBalances[i];
      if (tokenBalance == 0) {
        continue;
      }

      uint256 amount = _tokensToEntryAsset(
        timestamp,
        tokenBalance,
        i,
        _fees.length == 0 ? 0 : _fees[0]
      );
      unchecked {
        // overflow is not possible
        entryAssetAmount += amount;
      }
    }

    uint256 finalEntryAssetAmount = entryAssetAmount;
    if (entryAssetAmount > _investData.receivedCurrency) {
      uint256 successFee = (entryAssetAmount * _poolInfo.successFee) / 100;

      unchecked {
        // overflow is not possible
        finalEntryAssetAmount = entryAssetAmount - successFee;
        totalSuccessFee += successFee;
      }

      TransferHelper.safeTransfer(
        poolInfo.entryAsset,
        _poolInfo.feeAddress,
        successFee
      );
    }

    TransferHelper.safeTransfer(
      poolInfo.entryAsset,
      msg.sender,
      finalEntryAssetAmount
    );

    _investmentDataByUser[msg.sender][investmentId].active = false;

    emit InvestmentWithdrawal(msg.sender, finalEntryAssetAmount, investmentId);
  }

  /**
   * @notice function to toggle rebalanceEnabled flag in the investment.
   * @param investmentId - index of investment, given by user.
   *
   * @dev reverts when investmentId is not exist yet.
   * @dev reverts when investment not active.
   * @dev reverts when the pool is on pause.
   * @dev emits the `ToggleRebalance` event.
   */
  function toggleRebalance(uint256 investmentId) external whenNotPaused {
    uint256 investCount = investmentIds[msg.sender];
    require(
      investmentId <= investCount && investCount > 0,
      "investment non-exists"
    );
    InvestmentData memory _investData = _investmentDataByUser[msg.sender][
      investmentId
    ];

    require(_investData.active, "investment not active");

    _investmentDataByUser[msg.sender][investmentId]
      .rebalanceEnabled = !_investData.rebalanceEnabled;

    emit ToggleRebalance(
      msg.sender,
      investmentId,
      !_investData.rebalanceEnabled
    );
  }

  /**
   * @notice function to rebalance the investment.
   * @param investmentId - index of investment, given by user.
   *
   * @dev reverts when investmentId is not exist yet.
   * @dev reverts when investment not active.
   * @dev reverts when rebalance is not enabled.
   * @dev reverts when the pool is on pause.
   * @dev emits the `Rebalanced` event.
   */
  function rebalance(uint256 investmentId) external nonReentrant whenNotPaused {
    uint256 investCount = investmentIds[msg.sender];
    require(
      investmentId <= investCount && investCount > 0,
      "investment non-exists"
    );

    InvestmentData memory _investData = _investmentDataByUser[msg.sender][
      investmentId
    ];

    require(_investData.active, "investment not active");
    require(_investData.rebalanceEnabled, "rebalance not enabled");

    PoolInfo memory _poolInfo = poolInfo;
    uint256 allSwappedCurrency;
    uint256 timestamp;
    unchecked {
      // overflow is not possible

      timestamp = block.timestamp + 1200; // 20 mins
      totalReceivedCurrency -= _investData.receivedCurrency;
    }

    uint24[] memory _fees = fees;

    for (uint256 i; i < _poolInfo.poolSize; i++) {
      uint256 tokenBalance = _investData.tokenBalances[i];
      if (tokenBalance == 0) {
        continue;
      }
      uint256 amount = _tokensToEntryAsset(
        timestamp,
        tokenBalance,
        i,
        _fees.length == 0 ? 0 : _fees[0]
      );

      unchecked {
        // overflow is not possible
        allSwappedCurrency += amount;
      }
    }

    TransferHelper.safeApprove(
      _poolInfo.entryAsset,
      address(_swapRouter),
      allSwappedCurrency
    );

    for (uint256 i = 0; i < _poolInfo.poolSize; i++) {
      uint256 amountForToken;
      unchecked {
        // overflow is not possible
        amountForToken =
          (allSwappedCurrency * _poolInfo.poolDistribution[i]) /
          100;
      }

      if (amountForToken == 0) {
        _investData.tokenBalances[i] = 0;
        continue;
      }
      uint256 tokenBalance = _entryAssetToToken(
        _poolInfo.entryAsset,
        amountForToken,
        i,
        _fees.length == 0 ? 0 : _fees[0],
        timestamp,
        false
      );
      _investData.tokenBalances[i] = tokenBalance;
    }

    unchecked {
      // overflow is not possible
      totalReceivedCurrency += allSwappedCurrency;
    }

    _investmentDataByUser[msg.sender][investmentId]
      .receivedCurrency = allSwappedCurrency;
    _investmentDataByUser[msg.sender][investmentId].tokenBalances = _investData
      .tokenBalances;

    emit Rebalanced(
      msg.sender,
      investmentId,
      _investData.tokenBalances,
      _poolInfo.poolDistribution
    );
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IExchange {
  function swap(
    address tokenIn,
    address tokenOut,
    uint256 deadline,
    uint256 amount,
    address recipient,
    uint24 fee,
    bool inputIsNativeToken
  ) external payable returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract IPool {
  struct PoolData {
    // owner of the pool
    address owner;
    address entryAsset;
    address[] poolTokens;
    uint8[] poolDistribution;
    uint256[] poolTokensBalances;
    // number of tokens in the pool
    uint8 poolSize;
    address feeAddress;
    uint8 investFee;
    uint8 successFee;
    uint256 totalReceivedCurrency;
    uint256 totalInvestFee;
    uint256 totalSuccessFee;
  }

  struct PoolInfo {
    address entryAsset;
    address feeAddress;
    uint8 investFee;
    uint8 successFee;
    uint8 poolSize;
    uint8[] poolDistribution;
    address[] poolTokens;
  }

  struct InvestmentData {
    // receivet entryAsset by user in current investment
    uint256 receivedCurrency;
    // tokenBalances which will be exchanged back to the input asset
    uint256[] tokenBalances;
    bool rebalanceEnabled;
    bool active;
  }

  event Invested(
    address indexed user,
    uint256 amount,
    uint256[] tokenBalances,
    uint8[] tokenDistribution
  );
  event InvestmentWithdrawal(
    address indexed user,
    uint256 maticAmount,
    uint256 investmentId
  );
  event Rebalanced(
    address indexed user,
    uint256 investmentId,
    uint256[] tokenBalances,
    uint8[] tokenDistribution
  );
  event ToggleRebalance(
    address indexed user,
    uint256 investmentId,
    bool rebalanceEnabled
  );
  event Received(address sender, uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

import "./interfaces/IExchange.sol";
import "./interfaces/IPool.sol";

/// @title PoolStorage
contract PoolStorage is Ownable, IPool, Pausable, ReentrancyGuard {
  /// @notice wrapper of exchange's swap router
  IExchange internal immutable _swapRouter;
  /// @notice address to check if entryAsset is a native blockchain token or not.
  address internal immutable _wrapOfNativeToken;

  /**
   * @notice fee of each pool
   *
   * @dev all pools on uniswap have the fee.
   * e.g - pool entryAsset - poolInfo.poolTokens[i] - fee 3000 (3000 = 0.3%)
   *       pool entryAsset - poolInfo.poolTokens[i+1] - fee 100 (100 = 0.01%)
   *       pool entryAsset - poolInfo.poolTokens[i+2] - fee 10000 (10000 = 1%)
   *       pool entryAsset - poolInfo.poolTokens[i+3] - fee 500 (500 = 0.05%)
   * @dev if swapRouter - PancakeExchange - a fees array must be empty!
   */
  uint24[] public fees;

  /// @notice the name of the token pool.
  string public name;
  /// @notice the minimum possible amount of tokens for investment.
  uint256 internal _minInvest;

  PoolInfo public poolInfo;

  /// @notice current swapped tokens balances.
  uint256[] internal _poolTokensBalances;
  /// @notice current entryAsset in the contract.
  uint256 public totalReceivedCurrency;
  /// @notice the amount of investment fees over time.
  uint256 public totalInvestFee;
  /// @notice the amount of success fees over time.
  uint256 public totalSuccessFee;

  /// @notice investment data.
  mapping(address => InvestmentData[]) internal _investmentDataByUser;
  /// @notice user's counter of investments.
  mapping(address => uint256) public investmentIds;

  constructor(address swapRouter_, address wrapOfNativeToken_) {
    _swapRouter = IExchange(swapRouter_);
    _wrapOfNativeToken = wrapOfNativeToken_;
  }

  modifier validDistribution(uint8[] memory _poolDistribution) {
    uint8 res;
    for (uint256 i; i < _poolDistribution.length; i++) {
      res += _poolDistribution[i];
    }
    require(res == 100, "distribution must be eq 100");
    _;
  }

  /**
   * @notice pause pool.
   * @dev can be executed only by pool owner.
   * @dev emits `Paused` event.
   * */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @notice unpause pool.
   * @dev can be executed only by pool owner.
   * @dev emits `Unpaused` event.
   * */
  function unpause() external onlyOwner {
    _unpause();
  }

  /**
   * @notice set the new fee address for charging pool fee.
   * @dev reverts when new fee address is equal to the current address or address(0).
   * @dev can be executed only by pool owner.
   * @dev can be executed only if the pool is on pause.
   * */
  function setFeeAddress(address _feeAddress) external onlyOwner whenPaused {
    require(poolInfo.feeAddress != _feeAddress, "this address is already set");
    require(_feeAddress != address(0), "new fee address is address(0)");

    poolInfo.feeAddress = _feeAddress;
  }

  /**
   * @notice set the new invest fee.
   * @dev reverts when new invest fee is equal to the current or more than 50.
   * @dev can be executed only by pool owner.
   * @dev can be executed only if the pool is on pause.
   * */
  function setInvestFee(uint8 newInvestFee) external onlyOwner whenPaused {
    require(poolInfo.investFee != newInvestFee, "this fee is already set");
    require(newInvestFee <= 50, "new invest fee is too big");

    poolInfo.investFee = newInvestFee;
  }

  /**
   * @notice set the new success fee.
   * @dev reverts when new success fee is equal to the current or more than 50.
   * @dev can be executed only by pool owner.
   * @dev can be executed only if the pool is on pause.
   * */
  function setSuccessFee(uint8 newSuccessFee) external onlyOwner whenPaused {
    require(poolInfo.successFee != newSuccessFee, "this fee is already set");
    require(newSuccessFee <= 50, "new success fee is too big");

    poolInfo.successFee = newSuccessFee;
  }

  /**
   * @notice set the new minimum possible amount of tokens for investment.
   * @dev reverts when new minInvestment is equal zero.
   * @dev can be executed only by pool owner.
   * @dev can be executed only if the pool is on pause.
   * */
  function setMinInvestmentLimit(uint256 _minInvestmentLimit)
    external
    onlyOwner
    whenPaused
  {
    require(_minInvestmentLimit > 0, "new min invest is zero");
    _minInvest = _minInvestmentLimit;
  }

  /**
   * @notice set the new tokens distributions.
   * @dev reverts when the sum of all new distributions is not equal 100.
   * @dev can be executed only by pool owner.
   * @dev can be executed only if the pool is on pause.
   * */
  function setPoolTokensDistributions(uint8[] memory poolDistributions)
    external
    onlyOwner
    whenPaused
    validDistribution(poolDistributions)
  {
    poolInfo.poolDistribution = poolDistributions;
  }

  /**
   * @notice function called by `receive` or `invest`.
   * @dev emits the `Invested` event.
   * */
  function _initInvestment(
    address investor,
    uint256 amount,
    bool inputIsNativeToken
  ) internal {
    PoolInfo memory _poolInfo = poolInfo;
    if (!inputIsNativeToken) {
      TransferHelper.safeTransferFrom(
        _poolInfo.entryAsset,
        investor,
        address(this),
        amount
      );
    }
    uint256 managerFee = (amount * _poolInfo.investFee) / 100;
    uint256 investmentAmount;
    unchecked {
      // overflow is not possible
      investmentAmount = amount - managerFee;
      totalReceivedCurrency += investmentAmount;
    }

    uint256[] memory tokenBalances = new uint256[](_poolInfo.poolSize);
    if (!inputIsNativeToken) {
      TransferHelper.safeApprove(
        _poolInfo.entryAsset,
        address(_swapRouter),
        investmentAmount
      );
    }
    uint256 timestamp;
    unchecked {
      // overflow is not possible
      timestamp = block.timestamp + 1200; // 20 mins
    }
    uint24[] memory _fees = fees;

    for (uint256 i; i < _poolInfo.poolSize; i++) {
      uint256 amountForToken;
      unchecked {
        // overflow is not possible
        amountForToken =
          (investmentAmount * _poolInfo.poolDistribution[i]) /
          100;
      }

      if (amountForToken == 0) {
        continue;
      }
      uint256 tokenBalance = _entryAssetToToken(
        _poolInfo.entryAsset,
        amountForToken,
        i,
        _fees.length == 0 ? 0 : _fees[0],
        timestamp,
        inputIsNativeToken
      );
      tokenBalances[i] = tokenBalance;
    }

    _investmentDataByUser[investor].push(
      InvestmentData({
        receivedCurrency: investmentAmount,
        tokenBalances: tokenBalances,
        rebalanceEnabled: true,
        active: true
      })
    );

    unchecked {
      // overflow is not possible
      investmentIds[investor]++;
    }

    if (managerFee > 0) {
      unchecked {
        // overflow is not possible
        totalInvestFee += managerFee;
      }

      if (inputIsNativeToken) {
        TransferHelper.safeTransferETH(_poolInfo.feeAddress, managerFee);
      } else {
        TransferHelper.safeTransfer(
          _poolInfo.entryAsset,
          _poolInfo.feeAddress,
          managerFee
        );
      }
    }

    emit Invested(
      investor,
      investmentAmount,
      tokenBalances,
      _poolInfo.poolDistribution
    );
  }

  /// @notice helper function to exchange the entry asset for a token from the pool
  function _entryAssetToToken(
    address entryAssetAddress,
    uint256 amount,
    uint256 i,
    uint24 fee,
    uint256 timestamp,
    bool inputIsNativeToken
  ) internal returns (uint256) {
    uint256 tokenBalance;
    if (inputIsNativeToken) {
      tokenBalance = _swapRouter.swap{ value: amount }(
        entryAssetAddress,
        poolInfo.poolTokens[i],
        timestamp,
        amount,
        address(this),
        fee,
        inputIsNativeToken
      );
      _poolTokensBalances[i] += tokenBalance;

      return tokenBalance;
    }

    TransferHelper.safeTransfer(
      entryAssetAddress,
      address(_swapRouter),
      amount
    );
    tokenBalance = _swapRouter.swap(
      entryAssetAddress,
      poolInfo.poolTokens[i],
      timestamp,
      amount,
      address(this),
      fee,
      inputIsNativeToken
    );
    _poolTokensBalances[i] += tokenBalance;

    return tokenBalance;
  }

  /// @notice helper function to exchange a token from the pool for the entry asset
  function _tokensToEntryAsset(
    uint256 timestamp,
    uint256 tokenBalance,
    uint256 i,
    uint24 fee
  ) internal returns (uint256 outputAmountFromToken) {
    PoolInfo memory _poolInfo = poolInfo;
    TransferHelper.safeTransfer(
      _poolInfo.poolTokens[i],
      address(_swapRouter),
      tokenBalance
    );
    outputAmountFromToken = _swapRouter.swap(
      _poolInfo.poolTokens[i],
      _poolInfo.entryAsset,
      timestamp,
      tokenBalance,
      address(this),
      fee,
      false
    );
    _poolTokensBalances[i] -= tokenBalance;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}