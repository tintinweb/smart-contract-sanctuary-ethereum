// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.9;

import "./base/CoinStatsBaseV1.sol";
import "../integrationInterface/IntegrationInterface.sol";

interface IWETH {
  function deposit() external payable;

  function withdraw(uint256) external;
}

// solhint-disable func-name-mixedcase, var-name-mixedcase
interface ICurveSwap {
  function underlying_coins(int128 arg0) external view returns (address);

  function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount)
    external;

  function add_liquidity(
    uint256[4] calldata amounts,
    uint256 min_mint_amount,
    bool addUnderlying
  ) external;

  function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount)
    external;

  function add_liquidity(
    uint256[3] calldata amounts,
    uint256 min_mint_amount,
    bool addUnderlying
  ) external;

  function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount)
    external;

  function add_liquidity(
    uint256[2] calldata amounts,
    uint256 min_mint_amount,
    bool addUnderlying
  ) external;

  function remove_liquidity_one_coin(
    uint256 _token_amount,
    int128 i,
    uint256 min_amount
  ) external;

  function remove_liquidity_one_coin(
    uint256 _token_amount,
    int128 i,
    uint256 min_amount,
    bool removeUnderlying
  ) external;

  function remove_liquidity_one_coin(
    uint256 _token_amount,
    uint256 i,
    uint256 min_amount
  ) external;

  function calc_withdraw_one_coin(uint256 tokenAmount, int128 underlyingIndex)
    external
    view
    returns (uint256);

  function calc_withdraw_one_coin(
    uint256 tokenAmount,
    int128 underlyingIndex,
    bool _use_underlying
  ) external view returns (uint256);

  function calc_withdraw_one_coin(uint256 tokenAmount, uint256 underlyingIndex)
    external
    view
    returns (uint256);
}

interface ICurveEthSwap {
  function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount)
    external
    payable
    returns (uint256);
}

interface ICurveRegistry {
  function getSwapAddress(address tokenAddress)
    external
    view
    returns (address poolAddress);

  function getTokenAddress(address poolAddress)
    external
    view
    returns (address tokenAddress);

  function getDepositAddress(address poolAddress)
    external
    view
    returns (address depositAddress);

  function getPoolTokens(address poolAddress)
    external
    view
    returns (address[8] memory poolTokens);

  function shouldUseUnderlying(address poolAddress)
    external
    view
    returns (bool);

  function getNumTokens(address poolAddress)
    external
    view
    returns (uint8 numTokens);

  function isEthPool(address poolAddress) external view returns (bool);

  function isCryptoPool(address poolAddress) external view returns (bool);

  function isFactoryPool(address poolAddress) external view returns (bool);

  function isUnderlyingToken(address poolAddress, address tokenContractAddress)
    external
    view
    returns (bool, uint8);
}

contract CurveIntegration is IntegrationInterface, CoinStatsBaseV1 {
  using SafeERC20 for IERC20;

  ICurveRegistry public curveRegistry;

  address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  mapping(address => bool) internal v2Pool;

  constructor(
    ICurveRegistry _curveRegistry,
    uint256 _goodwill,
    uint256 _affiliateSplit,
    address _vaultAddress
  ) CoinStatsBaseV1(_goodwill, _affiliateSplit, _vaultAddress) {
    // Curve pool address registry
    curveRegistry = _curveRegistry;

    // 0x exchange
    approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
    // 1inch exchange
    approvedTargets[0x1111111254fb6c44bAC0beD2854e76F90643097d] = true;
  }

  event Deposit(
    address indexed from,
    address indexed pool,
    uint256 poolTokensReceived,
    address affiliate
  );
  event Withdraw(
    address indexed from,
    address indexed pool,
    uint256 poolTokensReceived,
    address affiliate
  );

  /**
    @notice Returns pools total supply2
    @param poolAddress Curve pool address from which to get supply
   */
  function getTotalSupply(address poolAddress) public view returns (uint256) {
    address tokenAddress = curveRegistry.getTokenAddress(poolAddress);
    return IERC20(tokenAddress).totalSupply();
  }

  /**
    @notice Returns account balance from pool
    @param poolAddress Curve pool address from which to get balance
    @param account The account
   */
  function getBalance(address poolAddress, address account)
    public
    view
    override
    returns (uint256)
  {
    address tokenAddress = curveRegistry.getTokenAddress(poolAddress);
    return IERC20(tokenAddress).balanceOf(account);
  }

  /**
    @notice Adds liquidity to any Curve pools with ETH or ERC20 tokens
    @param entryTokenAddress The token used for entry (address(0) if ETH).
    @param entryTokenAmount The depositAmount of entryTokenAddress to invest
    @param poolAddress Curve swap address for the pool
    @param depositTokenAddress Token to be transfered to poolAddress
    @param minExitTokenAmount Min acceptable amount of liquidity/stake tokens to reeive
    @param / underlyingTarget Underlying target which will execute swap
    @param / targetDepositTokenAddress Token which will be used to deposit fund in target contract
    @param swapTarget Underlying target's swap target
    @param swapData Data for swap
    @param affiliate Affiliate address 
    */

  function deposit(
    address entryTokenAddress,
    uint256 entryTokenAmount,
    address poolAddress,
    address depositTokenAddress, // Token to enter curve pool
    uint256 minExitTokenAmount,
    address,
    address,
    address swapTarget,
    bytes calldata swapData,
    address affiliate
  ) external payable override whenNotPaused {
    // Transfer {entryTokens} to contract
    entryTokenAmount = _pullTokens(entryTokenAddress, entryTokenAmount);

    // Subtract goodwill
    entryTokenAmount -= _subtractGoodwill(
      entryTokenAddress,
      entryTokenAmount,
      affiliate,
      true
    );

    if (entryTokenAddress == address(0)) {
      entryTokenAddress = ETH_ADDRESS;
    }

    uint256 tokensReceived = _makeDeposit(
      entryTokenAddress,
      entryTokenAmount,
      depositTokenAddress,
      poolAddress,
      swapTarget,
      swapData,
      minExitTokenAmount
    );

    address poolTokenAddress = curveRegistry.getTokenAddress(poolAddress);

    IERC20(poolTokenAddress).safeTransfer(msg.sender, tokensReceived);

    emit Deposit(msg.sender, poolTokenAddress, tokensReceived, affiliate);
  }

  function _makeDeposit(
    address entryTokenAddress,
    uint256 entryTokenAmount,
    address depositTokenAddress,
    address poolAddress,
    address swapTarget,
    bytes memory swapData,
    uint256 minExitTokenAmount
  ) internal returns (uint256 tokensReceived) {
    // First Underlying Check
    (bool isUnderlying, uint8 underlyingIndex) = curveRegistry
      .isUnderlyingToken(poolAddress, entryTokenAddress);

    if (isUnderlying) {
      tokensReceived = _enterCurve(
        poolAddress,
        entryTokenAmount,
        underlyingIndex
      );
    } else {
      // Swap {entryToken} to {depositToken}
      uint256 depositTokenAmount = _fillQuote(
        entryTokenAddress,
        entryTokenAmount,
        depositTokenAddress,
        swapTarget,
        swapData
      );

      // Second Underlying Check
      (isUnderlying, underlyingIndex) = curveRegistry.isUnderlyingToken(
        poolAddress,
        depositTokenAddress
      );

      if (isUnderlying) {
        tokensReceived = _enterCurve(
          poolAddress,
          depositTokenAmount,
          underlyingIndex
        );
      } else {
        (uint256 tokens, uint256 metaIndex) = _enterMetaPool(
          poolAddress,
          depositTokenAddress,
          depositTokenAmount
        );
        tokensReceived = _enterCurve(poolAddress, tokens, metaIndex);
      }

      require(
        tokensReceived > minExitTokenAmount,
        "MakeDeposit: Received less than expected"
      );
    }
  }

  /**
    @notice Adds the liquidity for meta pools and returns the token underlyingIndex and swap tokens
    @param poolAddress Curve swap address for the pool
    @param depositTokenAddress The ERC20 token to which from token to be convert
    @param swapTokens quantity of exitTokenAddress to invest
    @return depositTokenAmount quantity of curve LP acquired
    @return underlyingIndex underlyingIndex of LP token in poolAddress whose pool tokens were acquired
  */
  function _enterMetaPool(
    address poolAddress,
    address depositTokenAddress,
    uint256 swapTokens
  ) internal returns (uint256 depositTokenAmount, uint256 underlyingIndex) {
    address[8] memory poolTokens = curveRegistry.getPoolTokens(poolAddress);
    for (uint256 i = 0; i < 8; i++) {
      address intermediateSwapAddress;
      if (poolTokens[i] != address(0)) {
        intermediateSwapAddress = curveRegistry.getSwapAddress(poolTokens[i]);
      }
      if (intermediateSwapAddress != address(0)) {
        (, underlyingIndex) = curveRegistry.isUnderlyingToken(
          intermediateSwapAddress,
          depositTokenAddress
        );

        depositTokenAmount = _enterCurve(
          intermediateSwapAddress,
          swapTokens,
          underlyingIndex
        );

        return (depositTokenAmount, i);
      }
    }
  }

  function _fillQuote(
    address inputTokenAddress,
    uint256 inputTokenAmount,
    address outputTokenAddress,
    address swapTarget,
    bytes memory swapData
  ) internal returns (uint256 outputTokensBought) {
    if (inputTokenAddress == outputTokenAddress) {
      return inputTokenAmount;
    }

    if (swapTarget == WETH) {
      if (
        outputTokenAddress == address(0) || outputTokenAddress == ETH_ADDRESS
      ) {
        IWETH(WETH).withdraw(inputTokenAmount);
        return inputTokenAmount;
      } else {
        IWETH(WETH).deposit{value: inputTokenAmount}();
        return inputTokenAmount;
      }
    }

    uint256 value;
    if (inputTokenAddress == ETH_ADDRESS) {
      value = inputTokenAmount;
    } else {
      _approveToken(inputTokenAddress, swapTarget);
    }

    uint256 initialOutputTokenBalance = _getBalance(outputTokenAddress);

    // solhint-disable-next-line reason-string
    require(approvedTargets[swapTarget], "FillQuote: Target is not approved");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = swapTarget.call{value: value}(swapData);

    require(success, "FillQuote: Failed to swap tokens");

    outputTokensBought =
      _getBalance(outputTokenAddress) -
      initialOutputTokenBalance;

    // solhint-disable-next-line reason-string
    require(outputTokensBought > 0, "FillQuote: Swapped to invalid token");
  }

  /**
        @notice This function adds liquidity to a curve pool
        @param poolAddress Curve swap address for the pool
        @param amount The quantity of tokens being added as liquidity
        @param underlyingIndex The token underlyingIndex for the add_liquidity call
        @return poolTokensReceived the quantity of curve LP tokens received
    */
  function _enterCurve(
    address poolAddress,
    uint256 amount,
    uint256 underlyingIndex
  ) internal returns (uint256 poolTokensReceived) {
    address tokenAddress = curveRegistry.getTokenAddress(poolAddress);
    address depositAddress = curveRegistry.getDepositAddress(poolAddress);
    uint256 initialBalance = _getBalance(tokenAddress);
    address entryToken = curveRegistry.getPoolTokens(poolAddress)[
      underlyingIndex
    ];
    if (entryToken != ETH_ADDRESS) {
      _approveToken(entryToken, depositAddress);
      // IERC20(entryToken).safeIncreaseAllowance(address(depositAddress), amount);
    }

    uint256 numTokens = curveRegistry.getNumTokens(poolAddress);

    bool shouldUseUnderlying = curveRegistry.shouldUseUnderlying(poolAddress);

    if (numTokens == 4) {
      uint256[4] memory amounts;
      amounts[underlyingIndex] = amount;
      if (shouldUseUnderlying) {
        ICurveSwap(depositAddress).add_liquidity(amounts, 0, true);
      } else {
        ICurveSwap(depositAddress).add_liquidity(amounts, 0);
      }
    } else if (numTokens == 3) {
      uint256[3] memory amounts;
      amounts[underlyingIndex] = amount;
      if (shouldUseUnderlying) {
        ICurveSwap(depositAddress).add_liquidity(amounts, 0, true);
      } else {
        ICurveSwap(depositAddress).add_liquidity(amounts, 0);
      }
    } else {
      uint256[2] memory amounts;
      amounts[underlyingIndex] = amount;
      if (curveRegistry.isEthPool(depositAddress)) {
        if (entryToken != ETH_ADDRESS) {
          ICurveEthSwap(depositAddress).add_liquidity{value: 0}(amounts, 0);
        } else {
          ICurveEthSwap(depositAddress).add_liquidity{value: amount}(
            amounts,
            0
          );
        }
      } else {
        if (shouldUseUnderlying) {
          ICurveSwap(depositAddress).add_liquidity(amounts, 0, true);
        } else {
          ICurveSwap(depositAddress).add_liquidity(amounts, 0);
        }
      }
    }
    poolTokensReceived = _getBalance(tokenAddress) - initialBalance;
  }

  /**
    @notice This method removes the liquidity from curve pools
    @param poolAddress indicates Curve swap address for the pool
    @param liquidityAmount indicates the amount of lp tokens to remove
    @param exitTokenAddress indicates the ETH/ERC token to which tokens to convert
    @param minExitTokenAmount indicates the minimum amount of toTokens to receive
    @param / Underlying target which will execute swap
    @param targetWithdrawTokenAddress Token which will be used to withdraw funds from curve contract
    @param swapTarget Excecution target for the first swap
    @param swapData DEX quote data
    @param affiliate Affiliate address to share fees
  */
  function withdraw(
    address poolAddress,
    uint256 liquidityAmount,
    address exitTokenAddress,
    uint256 minExitTokenAmount,
    address,
    address targetWithdrawTokenAddress,
    address swapTarget,
    bytes calldata swapData,
    address affiliate
  ) external payable override whenNotPaused {
    address poolTokenAddress = curveRegistry.getTokenAddress(poolAddress);
    // Transfer {liquidityTokens} to contract
    liquidityAmount = _pullTokens(poolTokenAddress, liquidityAmount);

    uint256 exitTokenAmount = _makeWithdrawal(
      poolAddress,
      liquidityAmount,
      targetWithdrawTokenAddress,
      exitTokenAddress,
      minExitTokenAmount,
      swapTarget,
      swapData
    );

    exitTokenAmount -= _subtractGoodwill(
      exitTokenAddress,
      exitTokenAmount,
      affiliate,
      true
    );

    if (exitTokenAddress == ETH_ADDRESS) {
      Address.sendValue(payable(msg.sender), exitTokenAmount);
    } else {
      IERC20(exitTokenAddress).safeTransfer(msg.sender, exitTokenAmount);
    }

    emit Withdraw(msg.sender, poolAddress, exitTokenAmount, affiliate);
  }

  function _makeWithdrawal(
    address poolAddress,
    uint256 entryTokenAmount,
    address curveExitTokenAddress,
    address exitTokenAddress,
    uint256 minExitTokenAmount,
    address swapTarget,
    bytes memory swapData
  ) internal returns (uint256 exitTokenAmount) {
    (bool isUnderlying, uint256 underlyingIndex) = curveRegistry
      .isUnderlyingToken(poolAddress, curveExitTokenAddress);

    // Not Metapool
    if (isUnderlying) {
      uint256 intermediateReceived = _exitCurve(
        poolAddress,
        entryTokenAmount,
        int128(uint128(underlyingIndex)),
        curveExitTokenAddress
      );

      exitTokenAmount = _fillQuote(
        curveExitTokenAddress,
        intermediateReceived,
        exitTokenAddress,
        swapTarget,
        swapData
      );
    } else {
      // Metapool
      address[8] memory poolTokens = curveRegistry.getPoolTokens(poolAddress);
      address intermediateSwapAddress;
      uint8 i;
      for (; i < 8; i++) {
        if (curveRegistry.getSwapAddress(poolTokens[i]) != address(0)) {
          intermediateSwapAddress = curveRegistry.getSwapAddress(poolTokens[i]);
          break;
        }
      }
      // _exitCurve to {intermediateToken}
      uint256 intermediateTokenBought = _exitMetaCurve(
        poolAddress,
        entryTokenAmount,
        i,
        poolTokens[i]
      );

      // Runs itself but now fromPool = {intermediateToken}
      exitTokenAmount = _makeWithdrawal(
        intermediateSwapAddress,
        intermediateTokenBought,
        curveExitTokenAddress,
        exitTokenAddress,
        minExitTokenAmount,
        swapTarget,
        swapData
      );
    }

    require(exitTokenAmount >= minExitTokenAmount, "High Slippage");
  }

  /*
   *@notice This method removes the liquidity from meta curve pools
   *@param poolAddress indicates the curve pool address from which liquidity to be removed.
   *@param entryTokenAmount indicates the amount of liquidity to be removed from the pool
   *@param underlyingIndex indicates the underlyingIndex of underlying token of the pool in which liquidity will be removed.
   *@return intermediateTokensBought - indicates the amount of reserve tokens received
   */
  function _exitMetaCurve(
    address poolAddress,
    uint256 entryTokenAmount,
    uint256 underlyingIndex,
    address exitTokenAddress
  ) internal returns (uint256 intermediateTokensBought) {
    address tokenAddress = curveRegistry.getTokenAddress(poolAddress);

    // _approveToken(tokenAddress, poolAddress, 0);
    _approveToken(tokenAddress, poolAddress);

    uint256 iniTokenBal = IERC20(exitTokenAddress).balanceOf(address(this));
    ICurveSwap(poolAddress).remove_liquidity_one_coin(
      entryTokenAmount,
      int128(uint128(underlyingIndex)),
      0
    );
    intermediateTokensBought =
      (IERC20(exitTokenAddress).balanceOf(address(this))) -
      iniTokenBal;

    require(intermediateTokensBought > 0, "Could not receive reserve tokens");
  }

  /*
   *@notice This method removes the liquidity from given curve pool
   *@param poolAddress indicates the curve pool address from which liquidity to be removed.
   *@param entryTokenAmount indicates the amount of liquidity to be removed from the pool
   *@param underlyingIndex indicates the underlyingIndex of underlying token of the pool in which liquidity will be removed.
   *@return intermediateTokensBought - indicates the amount of reserve tokens received
   */
  function _exitCurve(
    address poolAddress,
    uint256 entryTokenAmount,
    int128 underlyingIndex,
    address exitTokenAddress
  ) internal returns (uint256 intermediateTokensBought) {
    address depositAddress = curveRegistry.getDepositAddress(poolAddress);
    address tokenAddress = curveRegistry.getTokenAddress(poolAddress);

    _approveToken(tokenAddress, depositAddress);

    uint256 iniTokenBal = _getBalance(exitTokenAddress);

    if (curveRegistry.shouldUseUnderlying(poolAddress)) {
      // aave
      ICurveSwap(depositAddress).remove_liquidity_one_coin(
        entryTokenAmount,
        underlyingIndex,
        0,
        true
      );
    } else if (curveRegistry.isCryptoPool(poolAddress)) {
      ICurveSwap(depositAddress).remove_liquidity_one_coin(
        entryTokenAmount,
        uint256(uint128(underlyingIndex)),
        0
      );
    } else {
      ICurveSwap(depositAddress).remove_liquidity_one_coin(
        entryTokenAmount,
        int128(uint128(underlyingIndex)),
        0
      );
    }

    intermediateTokensBought = _getBalance(exitTokenAddress) - iniTokenBal;

    require(intermediateTokensBought > 0, "Could not receive reserve tokens");
  }

  /**
    @notice Utility function to determine the quantity and address of a token being removed
    @param poolAddress indicates the curve pool address from which liquidity to be removed
    @param tokenAddress token to be removed
    @param liquidity Quantity of LP tokens to remove.
    @return Quantity of token removed
    */
  function removeAssetReturn(
    address poolAddress,
    address tokenAddress,
    uint256 liquidity
  ) external view override returns (uint256) {
    require(liquidity > 0, "RAR: Zero amount return");

    if (tokenAddress == address(0)) tokenAddress = ETH_ADDRESS;
    (bool underlying, uint256 underlyingIndex) = curveRegistry
      .isUnderlyingToken(poolAddress, tokenAddress);

    if (underlying) {
      if (curveRegistry.isCryptoPool(poolAddress)) {
        return
          ICurveSwap(curveRegistry.getDepositAddress(poolAddress))
            .calc_withdraw_one_coin(liquidity, uint256(underlyingIndex));
      } else {
        return
          ICurveSwap(curveRegistry.getDepositAddress(poolAddress))
            .calc_withdraw_one_coin(
              liquidity,
              int128(uint128(underlyingIndex))
            );
      }
    } else {
      address[8] memory poolTokens = curveRegistry.getPoolTokens(poolAddress);
      address intermediateSwapAddress;
      for (uint256 i = 0; i < 8; i++) {
        intermediateSwapAddress = curveRegistry.getSwapAddress(poolTokens[i]);
        if (intermediateSwapAddress != address(0)) break;
      }
      uint256 metaTokensRec = ICurveSwap(poolAddress).calc_withdraw_one_coin(
        liquidity,
        int128(1)
      );

      (, underlyingIndex) = curveRegistry.isUnderlyingToken(
        intermediateSwapAddress,
        tokenAddress
      );

      return
        ICurveSwap(intermediateSwapAddress).calc_withdraw_one_coin(
          metaTokensRec,
          int128(uint128(underlyingIndex))
        );
    }
  }

  /// @notice Updates Current Curve Registry
  /// @param  newCurveRegistry new curve address
  function updateCurveRegistry(ICurveRegistry newCurveRegistry)
    external
    onlyOwner
  {
    require(newCurveRegistry != curveRegistry, "Already using this Registry");
    curveRegistry = newCurveRegistry;
  }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./FeesV1.sol";

interface IVault {
  function addAffiliateBalance(
    address affiliate,
    address token,
    uint256 affiliatePortion
  ) external;
}

abstract contract CoinStatsBaseV1 is FeesV1 {
  using SafeERC20 for IERC20;

  address public immutable VAULT;

  constructor(
    uint256 _goodwill,
    uint256 _affiliateSplit,
    address _vaultAddress
  ) FeesV1(_goodwill, _affiliateSplit) {
    VAULT = _vaultAddress;
  }

  /// @notice Sends provided token amount to the contract
  /// @param token represents token address to be transfered
  /// @param amount represents token amount to be transfered
  function _pullTokens(address token, uint256 amount)
    internal
    returns (uint256 balance)
  {
    if (token == address(0) || token == ETH_ADDRESS) {
      require(msg.value > 0, "ETH was not sent");
    } else {
      // solhint-disable reason-string
      require(msg.value == 0, "Along with token, the ETH was also sent");
      uint256 balanceBefore = _getBalance(token);

      // Transfers all tokens to current contract
      IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

      return _getBalance(token) - balanceBefore;
    }
    return amount;
  }

  /// @notice Subtracts goodwill portion from given amount
  /// @dev If 0x00... address was given, then it will be replaced with 0xEeeEE... address
  /// @param token represents token address
  /// @param amount represents token amount
  /// @param affiliate goodwill affiliate
  /// @param enableGoodwill boolean representation whether to charge fee or not
  /// @return totalGoodwillPortion the amount of goodwill
  function _subtractGoodwill(
    address token,
    uint256 amount,
    address affiliate,
    bool enableGoodwill
  ) internal returns (uint256 totalGoodwillPortion) {
    bool whitelisted = feeWhitelist[msg.sender];

    if (enableGoodwill && !whitelisted && (goodwill > 0)) {
      totalGoodwillPortion = (amount * goodwill) / 10000;

      if (token == address(0) || token == ETH_ADDRESS) {
        Address.sendValue(payable(VAULT), totalGoodwillPortion);
      } else {
        uint256 balanceBefore = IERC20(token).balanceOf(VAULT);
        IERC20(token).safeTransfer(VAULT, totalGoodwillPortion);
        totalGoodwillPortion = IERC20(token).balanceOf(VAULT) - balanceBefore;
      }

      if (affiliates[affiliate]) {
        if (token == address(0)) {
          token = ETH_ADDRESS;
        }

        uint256 affiliatePortion = (totalGoodwillPortion * affiliateSplit) /
          100;

        IVault(VAULT).addAffiliateBalance(affiliate, token, affiliatePortion);
      }
    }
  }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

/// @title Protocol Integration Interface
abstract contract IntegrationInterface {
  /**
  @dev The function must deposit assets to the protocol.
  @param entryTokenAddress Token to be transfered to integration contract from caller
  @param entryTokenAmount Token amount to be transferes to integration contract from caller
  @param \ Pool/Vault address to deposit funds
  @param depositTokenAddress Token to be transfered to poolAddress
  @param minExitTokenAmount Min acceptable amount of liquidity/stake tokens to reeive
  @param underlyingTarget Underlying target which will execute swap
  @param targetDepositTokenAddress Token which will be used to deposit fund in target contract
  @param swapTarget Underlying target's swap target
  @param swapData Data for swap
  @param affiliate Affiliate address 
  */

  function deposit(
    address entryTokenAddress,
    uint256 entryTokenAmount,
    address,
    address depositTokenAddress,
    uint256 minExitTokenAmount,
    address underlyingTarget,
    address targetDepositTokenAddress,
    address swapTarget,
    bytes calldata swapData,
    address affiliate
  ) external payable virtual;

  /**
  @dev The function must withdraw assets from the protocol.
  @param \ Pool/Vault address
  @param \ Token amount to be transferes to integration contract
  @param exitTokenAddress Specifies the token which will be send to caller
  @param minExitTokenAmount Min acceptable amount of tokens to reeive
  @param underlyingTarget Underlying target which will execute swap
  @param targetWithdrawTokenAddress Token which will be used to withdraw funds from target contract
  @param swapTarget Underlying target's swap target
  @param swapData Data for swap
  @param affiliate Affiliate address 
  */
  function withdraw(
    address,
    uint256,
    address exitTokenAddress,
    uint256 minExitTokenAmount,
    address underlyingTarget,
    address targetWithdrawTokenAddress,
    address swapTarget,
    bytes calldata swapData,
    address affiliate
  ) external payable virtual;

  /**
    @dev Returns account balance
    @param \ Pool/Vault address
    @param account User account address
    @return balance Returns user current balance
   */
  function getBalance(address, address account)
    public
    view
    virtual
    returns (uint256 balance);

  /**
    @notice Utility function to determine the quantity and address of a token being removed
    @param \ Pool/Vault address from which liquidity should be removed
    @param [Optional] Token address token to be removed
    @param amount Quantity of LP tokens to remove.
    @return The amount of token removed
  */
  function removeAssetReturn(
    address,
    address,
    uint256 amount
  ) external view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract FeesV1 is Ownable {
  using SafeERC20 for IERC20;
  bool public paused = false;

  // If true, goodwill is not deducted
  mapping(address => bool) public feeWhitelist;

  uint256 public goodwill;
  uint256 public affiliateSplit;

  // Mapping from {affiliate} to {status}
  mapping(address => bool) public affiliates;
  // Mapping from {swapTarget} to {status}
  mapping(address => bool) public approvedTargets;
  // Mapping from {token} to {status}
  mapping(address => bool) public shouldResetAllowance;

  address internal constant ETH_ADDRESS =
    0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  event ContractPauseStatusChanged(bool status);
  event FeeWhitelistUpdate(address _address, bool status);
  event GoodwillChange(uint256 newGoodwill);
  event AffiliateSplitChange(uint256 newAffiliateSplit);

  constructor(uint256 _goodwill, uint256 _affiliateSplit) {
    goodwill = _goodwill;
    affiliateSplit = _affiliateSplit;
  }

  modifier whenNotPaused() {
    require(!paused, "Contract is temporary paused");
    _;
  }

  /// @notice Returns address token balance
  /// @param token address
  /// @return balance
  function _getBalance(address token) internal view returns (uint256 balance) {
    if (token == address(ETH_ADDRESS)) {
      balance = address(this).balance;
    } else {
      balance = IERC20(token).balanceOf(address(this));
    }
  }

  /// @dev Gives MAX allowance to token spender
  /// @param token address to apporve
  /// @param spender address
  function _approveToken(address token, address spender) internal {
    IERC20 _token = IERC20(token);

    if (shouldResetAllowance[token]) {
      _token.safeApprove(spender, 0);
      _token.safeApprove(spender, type(uint256).max);
    } else if (_token.allowance(address(this), spender) > 0) return;
    else {
      _token.safeApprove(spender, type(uint256).max);
    }
  }

  /// @dev Gives allowance to token spender
  ///     Resets initial allowance (USDC, USDT...)
  /// @param token address to apporve
  /// @param spender address
  /// @param amount of allowance
  function _approveToken(
    address token,
    address spender,
    uint256 amount
  ) internal {
    IERC20(token).safeIncreaseAllowance(address(spender), amount);
  }

  /// @notice To pause/unpause contract
  function toggleContractActive() public onlyOwner {
    paused = !paused;

    emit ContractPauseStatusChanged(paused);
  }

  /// @notice Whitelists addresses from paying goodwill
  function setFeeWhitelist(address _address, bool status) external onlyOwner {
    feeWhitelist[_address] = status;

    emit FeeWhitelistUpdate(_address, status);
  }

  /// @notice Changes goodwill %
  function setNewGoodwill(uint256 _newGoodwill) public onlyOwner {
    require(_newGoodwill <= 100, "Invalid goodwill value");
    goodwill = _newGoodwill;

    emit GoodwillChange(_newGoodwill);
  }

  /// @notice Changes affiliate split %
  function setNewAffiliateSplit(uint256 _newAffiliateSplit) external onlyOwner {
    require(_newAffiliateSplit <= 100, "Invalid affilatesplit percent");
    affiliateSplit = _newAffiliateSplit;

    emit AffiliateSplitChange(_newAffiliateSplit);
  }

  /// @notice Sets affiliate status
  function setAffiliates(
    address[] calldata _affiliates,
    bool[] calldata _status
  ) external onlyOwner {
    require(
      _affiliates.length == _status.length,
      "Affiliate: Invalid input length"
    );

    for (uint256 i = 0; i < _affiliates.length; i++) {
      affiliates[_affiliates[i]] = _status[i];
    }
  }

  ///@notice Sets approved targets
  function setApprovedTargets(
    address[] calldata targets,
    bool[] calldata isApproved
  ) external onlyOwner {
    require(
      targets.length == isApproved.length,
      "SetApprovedTargets: Invalid input length"
    );

    for (uint256 i = 0; i < targets.length; i++) {
      approvedTargets[targets[i]] = isApproved[i];
    }
  }

  ///@notice Sets address allowance that should be reset first
  function setShouldResetAllowance(
    address[] calldata tokens,
    bool[] calldata statuses
  ) external onlyOwner {
    require(
      tokens.length == statuses.length,
      "SetShouldResetAllowance: Invalid input length"
    );

    for (uint256 i = 0; i < tokens.length; i++) {
      shouldResetAllowance[tokens[i]] = statuses[i];
    }
  }

  receive() external payable {
    // solhint-disable-next-line
    require(msg.sender != tx.origin, "Do not send ETH directly");
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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