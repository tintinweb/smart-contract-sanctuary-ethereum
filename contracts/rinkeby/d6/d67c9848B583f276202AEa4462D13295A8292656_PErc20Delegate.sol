pragma solidity ^0.8.2;

import "./PErc20.sol";
import "./interfaces/PDelegationInterface.sol";

/**
 * @notice PTokens which wrap an EIP-20 underlying and are delegated to
 */
contract PErc20Delegate is PErc20, PDelegateInterface {
    /**
     * @notice Construct an empty delegate
     */
    // constructor() public {}

    /**
     * @notice Called by the delegator on a delegate to initialize it for duty
     * @param data The encoded bytes data for any initialization
     */
    function _becomeImplementation(bytes memory data) override public {
        // Shh -- currently unused
        data;

        // Shh -- we don't ever want this hook to be marked pure
        if (false) {
            implementation = address(0);
        }

        require(msg.sender == admin, "only the admin may call _becomeImplementation");
    }

    /**
     * @notice Called by the delegator on a delegate to forfeit its responsibility
     */
    function _resignImplementation() override public {
        // Shh -- we don't ever want this hook to be marked pure
        if (false) {
            implementation = address(0);
        }

        require(msg.sender == admin, "only the admin may call _resignImplementation");
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "./PToken.sol";
import "./interfaces/PTokenInterface.sol";
import "./interfaces/EIP20Interface.sol";
import "./interfaces/PErc20Interface.sol";

interface PrimeLike {
  function delegate(address delegatee) external;
}

/**
 * @title Prime's PErc20 Contract
 * @notice PTokens which wrap an EIP-20 underlying
 * @author Prime
 */
abstract contract PErc20 is PToken, PErc20Interface {
  /**
   * @notice Initialize the new money market
   * @param underlying_ The address of the underlying asset
   * @param riskEngine_ The address of the risk engine
   * @param interestRateModel_ The address of the interest rate model
   * @param initialCollateralRatioModel_ Initial collateral model
   * @param initialExchangeRate_ The initial exchange rate, scaled by 1e18
   * @param name_ ERC-20 name of this token
   * @param symbol_ ERC-20 symbol of this token
   * @param decimals_ ERC-20 decimal precision of this token
   */
  function initializeToken(
    address underlying_,
    RiskEngineInterface riskEngine_,
    InterestRateModel interestRateModel_,
    InitialCollateralRatioModel initialCollateralRatioModel_,
    uint256 initialExchangeRate_,
    string memory name_,
    string memory symbol_,
    uint8 decimals_
  ) public {
    // PToken initialize does the bulk of the work
    super.initialize(
      riskEngine_,
      interestRateModel_,
      initialCollateralRatioModel_,
      initialExchangeRate_,
      name_,
      symbol_,
      decimals_,
      underlying_
    );

    // Set underlying and sanity check it
    underlying = underlying_;
    EIP20Interface(underlying).totalSupply();
  }

  /*** User Interface ***/

  /**
   * @notice Sender supplies assets into the market and receives pTokens in exchange
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param mintAmount The amount of the underlying asset to supply
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function mint(uint256 mintAmount) external override returns (bool) {
    mintInternal(mintAmount);
    return true;
  }

  /**
   * @notice Sender redeems pTokens in exchange for the underlying asset
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param redeemTokens The number of pTokens to redeem into underlying
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function redeem(uint256 redeemTokens) external override returns (bool) {
    redeemInternal(redeemTokens);
    return true;
  }

  /**
   * @notice Sender redeems pTokens in exchange for a specified amount of underlying asset
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param redeemAmount The amount of underlying to redeem
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function redeemUnderlying(uint256 redeemAmount)
    external
    override
    returns (bool)
  {
    redeemUnderlyingInternal(redeemAmount);
    return true;
  }

  /**
   * @notice A public function to sweep accidental ERC-20 transfers to this contract. Tokens are sent to admin (timelock)
   * @param token The address of the ERC-20 token to sweep
   */
  function sweepToken(EIP20NonStandardInterface token) external override {
    require(
      address(token) != underlying,
      "PErc20::sweepToken: can not sweep underlying token"
    );
    uint256 balance = token.balanceOf(address(this));
    token.transfer(admin, balance);
  }

  // /**
  //  * @notice The sender adds to reserves.
  //  * @param addAmount The amount fo underlying token to add as reserves
  //  * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
  //  */
  // function _addReserves(uint addAmount) external returns (uint) {
  //     return _addReservesInternal(addAmount);
  // }

  /*** Safe Token ***/

  /**
   * @notice Gets balance of this contract in terms of the underlying
   * @dev This excludes the value of the current message, if any
   * @return The quantity of underlying tokens owned by this contract
   */
  function getCashPrior() internal view override returns (uint256) {
    EIP20Interface token = EIP20Interface(underlying);
    return token.balanceOf(address(this));
  }

  /**
   * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
   *      This will revert due to insufficient balance or insufficient allowance.
   *      This function returns the actual amount received,
   *      which may be less than `amount` if there is a fee attached to the transfer.
   *
   *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
   *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
   */
  function doTransferIn(address from, uint256 amount)
    internal
    override
    returns (uint256)
  {
    EIP20NonStandardInterface token = EIP20NonStandardInterface(underlying);
    uint256 balanceBefore = EIP20Interface(underlying).balanceOf(address(this));
    token.transferFrom(from, address(this), amount);

    bool success;
    assembly {
      switch returndatasize()
      case 0 {
        // This is a non-standard ERC-20
        success := not(0) // set success to true
      }
      case 32 {
        // This is a compliant ERC-20
        returndatacopy(0, 0, 32)
        success := mload(0) // Set `success = returndata` of external call
      }
      default {
        // This is an excessively non-compliant ERC-20, revert.
        revert(0, 0)
      }
    }
    require(success, "TOKEN_TRANSFER_IN_FAILED");

    // Calculate the amount that was *actually* transferred
    uint256 balanceAfter = EIP20Interface(underlying).balanceOf(address(this));
    require(balanceAfter >= balanceBefore, "TOKEN_TRANSFER_IN_OVERFLOW");
    return balanceAfter - balanceBefore; // underflow already checked above, just subtract
  }

  /**
   * @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
   *      error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
   *      insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
   *      it is >= amount, this should not revert in normal conditions.
   *
   *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
   *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
   */
  function doTransferOut(address payable to, uint256 amount) internal override {
    EIP20NonStandardInterface token = EIP20NonStandardInterface(underlying);
    token.transfer(to, amount);

    bool success;
    assembly {
      switch returndatasize()
      case 0 {
        // This is a non-standard ERC-20
        success := not(0) // set success to true
      }
      case 32 {
        // This is a complaint ERC-20
        returndatacopy(0, 0, 32)
        success := mload(0) // Set `success = returndata` of external call
      }
      default {
        // This is an excessively non-compliant ERC-20, revert.
        revert(0, 0)
      }
    }
    require(success, "TOKEN_TRANSFER_OUT_FAILED");
  }

  /**
   * @notice Admin call to delegate the votes of the PRIME-like underlying
   * @param primeLikeDelegatee The address to delegate votes to
   * @dev PTokens whose underlying are not PrimeLike should revert here
   */
  function _delegateCompLikeTo(address primeLikeDelegatee) external {
    require(
      msg.sender == admin,
      "only the admin may set the prime-like delegate"
    );
    PrimeLike(underlying).delegate(primeLikeDelegatee);
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

contract PDelegationStorage {
    /**
     * @notice Implementation address for this contract
     */
    address public implementation;
}

abstract contract PDelegatorInterface is PDelegationStorage {
    /**
     * @notice Emitted when implementation is changed
     */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
     * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
     */
    function _setImplementation(address implementation_, bool allowResign, bytes memory becomeImplementationData) virtual public;
}

abstract contract PDelegateInterface is PDelegationStorage {
    /**
     * @notice Called by the delegator on a delegate to initialize it for duty
     * @dev Should revert if any issues arise which make it unfit for delegation
     * @param data The encoded bytes data for any initialization
     */
    function _becomeImplementation(bytes memory data) virtual public;

    /**
     * @notice Called by the delegator on a delegate to forfeit its responsibility
     */
    function _resignImplementation() virtual public;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./RiskEngine.sol";

import "./interfaces/PTokenInterface.sol";
import "./interfaces/EIP20Interface.sol";
import "./oracle/PrimeOracle.sol";

import "./InitialCollateralRatioModel.sol";

abstract contract PToken is Ownable, PTokenStorage, PTokenInterface {
  /**
   * @notice Initialize the money market
   * @param riskEngine_ The address of the RiskEngine
   * @param interestRateModel_ The address of the interest rate model
   * @param :initialCollateralRatioModel_ Initial collateral model
   * @param initialExchangeRate_ The initial exchange rate, scaled by 1e18
   * @param name_ EIP-20 name of this token
   * @param symbol_ EIP-20 symbol of this token
   * @param decimals_ EIP-20 decimal precision of this token
   */
  function initialize(
    RiskEngineInterface riskEngine_,
    InterestRateModel interestRateModel_,
    InitialCollateralRatioModel, /*initialCollateralRatioModel_*/
    uint256 initialExchangeRate_,
    string memory name_,
    string memory symbol_,
    uint8 decimals_,
    address underlying_
  ) public {
    //require(msg.sender == admin, "only admin may initialize the market");

    require(accrualBlockNumber == 0, "market may only be initialized once");

    // Set initial exchange rate
    initialExchangeRate = initialExchangeRate_;
    require(
      initialExchangeRate > 0,
      "initial exchange rate must be greater than zero."
    );

    // Set the riskEngine
    _setRiskEngine(riskEngine_);

    // Initialize block number and borrow index (block number mocks depend on riskEngine being set)
    accrualBlockNumber = block.number;

    // Set the interest rate model (depends on block number / borrow index)
    _setInterestRateModelFresh(interestRateModel_);

    name = name_;
    symbol = symbol_;
    decimals = decimals_;
    underlyingAsset = IERC20(underlying_);

    // The counter starts true to prevent changing it from zero to non-zero (i.e. smaller cost/refund)
    _notEntered = true;
  }

  /**
   * @notice Transfer `tokens` tokens from `src` to `dst` by `spender`
   * @dev Called by both `transfer` and `transferFrom` internally
   * @param spender The address of the account performing the transfer
   * @param src The address of the source account
   * @param dst The address of the destination account
   * @param tokens The number of tokens to transfer
   */
  function transferTokens(
    address spender,
    address src,
    address dst,
    uint256 tokens
  ) internal {
    /* Fail if transfer not allowed */

    bool allowed = riskEngine.transferAllowed(address(this), src, dst, tokens);
    require(allowed, "RISKENGINE_REJECTION | TRANSFER_RISKENGINE_REJECTION");

    /* Do not allow self-transfers */
    require(src != dst, "BAD_INPUT | SELF_TRANSFER_NOT_ALLOWED");

    /* Get the allowance, infinite for the account owner */
    uint256 startingAllowance = spender == src
      ? type(uint256).max
      : transferAllowances[src][spender];

    /* Do the calculations, checking for {under,over}flow */
    uint256 allowanceNew;
    uint256 srpTokensNew;
    uint256 dstTokensNew;

    require(startingAllowance >= tokens, "Not enough allowance");
    allowanceNew = startingAllowance - tokens;

    require(accountTokens[src] >= tokens, "Not enough tokens");
    srpTokensNew = accountTokens[src] - tokens;

    dstTokensNew = accountTokens[dst] + tokens;

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    accountTokens[src] = srpTokensNew;
    accountTokens[dst] = dstTokensNew;

    /* Eat some of the allowance (if necessary) */
    if (startingAllowance != type(uint256).max) {
      transferAllowances[src][spender] = allowanceNew;
    }

    /* We emit a Transfer event */
    emit Transfer(src, dst, tokens);

    // unused function
    // riskEngine.transferVerify(address(this), src, dst, tokens);
  }

  /**
   * @notice Transfer `amount` tokens from `msg.sender` to `dst`
   * @param dst The address of the destination account
   * @param amount The number of tokens to transfer
   */
  function transfer(address dst, uint256 amount)
    external
    override
    nonReentrant
  {
    transferTokens(msg.sender, msg.sender, dst, amount);
  }

  /**
   * @notice Transfer `amount` tokens from `src` to `dst`
   * @param src The address of the source account
   * @param dst The address of the destination account
   * @param amount The number of tokens to transfer
   */
  function transferFrom(
    address src,
    address dst,
    uint256 amount
  ) external override nonReentrant {
    transferTokens(msg.sender, src, dst, amount);
  }

  /**
   * @notice Approve `spender` to transfer up to `amount` from `src`
   * @dev This will overwrite the approval amount for `spender`
   *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
   * @param spender The address of the account which may transfer tokens
   * @param amount The number of tokens that are approved (-1 means infinite)
   * @return Whether or not the approval succeeded
   */
  function approve(address spender, uint256 amount)
    external
    override
    returns (bool)
  {
    address src = msg.sender;
    transferAllowances[src][spender] = amount;
    emit Approval(src, spender, amount);
    return true;
  }

  /**
   * @notice Get the current allowance from `owner` for `spender`
   * @param owner The address of the account which owns the tokens to be spent
   * @param spender The address of the account which may transfer tokens
   * @return The number of tokens allowed to be spent (-1 means infinite)
   */
  function allowance(address owner, address spender)
    external
    view
    override
    returns (uint256)
  {
    return transferAllowances[owner][spender];
  }

  /**
   * @notice Get the token balance of the `owner`
   * @param owner The address of the account to query
   * @return The number of tokens owned by `owner`
   */
  function balanceOf(address owner) external view override returns (uint256) {
    return accountTokens[owner];
  }

  /**
   * @notice Get the underlying balance of the `owner`
   * @dev This also accrues interest in a transaction
   * @param owner The address of the account to query
   * @return The amount of underlying owned by `owner`
   */
  function balanceOfUnderlying(address owner)
    external
    view
    override
    returns (uint256)
  {
    return accountTokens[owner];
  }

  function setRiskEngine(RiskEngineInterface _RiskEngineAddress)
    public
    onlyOwner
  {
    riskEngine = _RiskEngineAddress;
  }

  event MintComplete(address sender, address ptoken_contract, uint256 amount);

  /**
   * @notice Applies accrued interest to ptoken reserves
   * @dev This will need to be updated to reflect interest accrued from sweeping deposits
   * it is likely that this will involve some sort of function call to a third party contract
   * Prime implementation has been removed because borrows are irrelevant
   */
  function accrueInterest() public pure override {
    return;
  }

  /**
   * @dev Function to simply retrieve block number
   *  This exists mainly for inheriting test contracts to stub this result.
   */
  // To stub means a mock implementation
  // A stub is a fake implementation that conforms to the interface and is to be used for testing.
  // function getBlockNumber() internal view returns (uint256) {
  //   return block.number;
  // }

  struct MintLocalVars {
    uint256 exchangeRate;
    uint256 mintTokens;
    uint256 totalSupplyNew;
    uint256 accountTokensNew;
    uint256 actualMintAmount;
  }

  /**
   * @notice User supplies assets into the market and receives pTokens in exchange
   * @dev Assumes interest has already been accrued up to the current block
   * @param minter The address of the account which is supplying the assets
   * @param mintAmount The amount of the underlying asset to supply
   * @return (uint) the mint amount.
   */
  function mintFresh(address minter, uint256 mintAmount)
    internal
    returns (uint256)
  {
    /* Fail if mint not allowed */

    bool allowed = riskEngine.mintAllowed(address(this), minter, mintAmount);
    require(allowed, "RISKENGINE_REJECTION | MINT_RISKENGINE_REJECTION");

    // /* Verify market's block number equals current block number */
    // NOTE: Why was this check removed?
    // if (accrualBlockNumber != getBlockNumber()) {
    //     return (fail(Error.MARKET_NOT_FRESH, FailureInfo.MINT_FRESHNESS_CHECK), 0);
    // }

    MintLocalVars memory vars;
    vars.exchangeRate = exchangeRateStored();

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /*
     *  We call `doTransferIn` for the minter and the mintAmount.
     *  Note: The pToken must handle variations between ERC-20 and ETH underlying.
     *  `doTransferIn` reverts if anything goes wrong, since we can't be sure if
     *  side-effects occurred. The function returns the amount actually transferred,
     *  in case of a fee. On success, the pToken holds an additional `actualMintAmount`
     *  of cash.
     */
    vars.actualMintAmount = doTransferIn(minter, mintAmount);

    /*
     * We get the current exchange rate and calculate the number of pTokens to be minted:
     *  mintTokens = actualMintAmount / exchangeRate
     */

    vars.mintTokens =
      (vars.actualMintAmount * 10**decimals) /
      vars.exchangeRate;

    /*
     * We calculate the new total supply of pTokens and minter token balance, checking for overflow:
     *  totalSupplyNew = totalSupply + mintTokens
     *  accountTokensNew = accountTokens[minter] + mintTokens
     */
    vars.totalSupplyNew = totalSupply + vars.mintTokens;
    vars.accountTokensNew = accountTokens[minter] + vars.mintTokens;

    /* We write previously calculated values into storage */
    totalSupply = vars.totalSupplyNew;
    accountTokens[minter] = vars.accountTokensNew;
    /* We emit a Mint event, and a Transfer event */
    emit Mint(minter, vars.actualMintAmount, vars.mintTokens);
    emit Transfer(address(this), minter, vars.mintTokens);

    /* We call the defense hook */
    // unused function
    // riskEngine.mintVerify(address(this), minter, vars.actualMintAmount, vars.mintTokens);
    return vars.actualMintAmount;
  }

  /**
   * @dev Performs a transfer in, reverting upon failure. Returns the amount actually transferred to the protocol, in case of a fee.
   *  This may revert due to insufficient balance or insufficient allowance.
   */
  function doTransferIn(address from, uint256 amount)
    internal
    virtual
    returns (uint256);

  /**
   * @notice Sender supplies assets into the market and receives pTokens in exchange
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param mintAmount The amount of the underlying asset to supply
   * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual mint amount.
   */
  function mintInternal(uint256 mintAmount)
    internal
    nonReentrant
    returns (uint256)
  {
    accrueInterest(); // this function should be updated

    // mintFresh emits the actual Mint event if successful and logs on errors, so we don't need to
    return mintFresh(msg.sender, mintAmount);
  }

  /**
   * @notice Sender redeems pTokens in exchange for the underlying asset
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param redeemTokens The number of pTokens to redeem into underlying
   */
  function redeemInternal(uint256 redeemTokens) internal nonReentrant {
    accrueInterest();

    // redeemFresh emits redeem-specific logs on errors, so we don't need to
    redeemFresh(payable(msg.sender), redeemTokens, 0);
  }

  /**
   * @notice Sender redeems pTokens in exchange for a specified amount of underlying asset
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param redeemAmount The amount of underlying to receive from redeeming pTokens
   */
  function redeemUnderlyingInternal(uint256 redeemAmount)
    internal
    nonReentrant
  {
    accrueInterest();

    // redeemFresh emits redeem-specific logs on errors, so we don't need to
    redeemFresh(payable(msg.sender), 0, redeemAmount);
  }

  struct RedeemLocalVars {
    uint256 exchangeRate;
    uint256 redeemTokens;
    uint256 redeemAmount;
    uint256 totalSupplyNew;
    uint256 accountTokensNew;
  }

  /**
   * @notice User redeems pTokens in exchange for the underlying asset
   * @dev Assumes interest has already been accrued up to the current block
   * @param redeemer The address of the account which is redeeming the tokens
   * @param redeemTokensIn The number of pTokens to redeem into underlying (only one of redeemTokensIn or redeemAmountIn may be non-zero)
   * @param redeemAmountIn The number of underlying tokens to receive from redeeming pTokens (only one of redeemTokensIn or redeemAmountIn may be non-zero)
   */
  function redeemFresh(
    address payable redeemer,
    uint256 redeemTokensIn, // 0
    uint256 redeemAmountIn // 20
  ) internal {
    require(
      redeemTokensIn == 0 || redeemAmountIn == 0,
      "one of redeemTokensIn or redeemAmountIn must be zero"
    );

    RedeemLocalVars memory vars;

    /* exchangeRate = invoke Exchange Rate Stored() */
    vars.exchangeRate = exchangeRateStored();

    /* If redeemTokensIn > 0: */
    if (redeemTokensIn > 0) {
      /*
       * We calculate the exchange rate and the amount of underlying to be redeemed:
       *  redeemTokens = redeemTokensIn
       *  redeemAmount = redeemTokensIn x exchangeRateCurrent
       */
      vars.redeemTokens = redeemTokensIn;
      vars.redeemAmount = (vars.exchangeRate * redeemTokensIn) / 10**decimals;
    } else {
      /*
       * We get the current exchange rate and calculate the amount to be redeemed:
       *  redeemTokens = redeemAmountIn / exchangeRate
       *  redeemAmount = redeemAmountIn
       */

      vars.redeemTokens = (redeemAmountIn * 10**decimals) / vars.exchangeRate;
      vars.redeemAmount = redeemAmountIn;
    }

    /* Fail if redeem not allowed */
    //NEED TO FIX WHEN REDEEM ALLOWED WORKS
    bool allowed = riskEngine.redeemAllowed(
      address(this),
      redeemer,
      vars.redeemTokens
    );
    require(allowed, "RISKENGINE_REJECTION | REDEEM_RISKENGINE_REJECTION");
    // /* Verify market's block number equals current block number */
    // NOTE: Why was this check removed?
    // if (accrualBlockNumber != getBlockNumber()) {
    //     return fail(Error.MARKET_NOT_FRESH, FailureInfo.REDEEM_FRESHNESS_CHECK);
    // }

    /*
     * We calculate the new total supply and redeemer balance, checking for underflow:
     *  totalSupplyNew = totalSupply - redeemTokens
     *  accountTokensNew = accountTokens[redeemer] - redeemTokens
     */
    require(totalSupply >= vars.redeemTokens, "INSUFFICIENT_LIQUIDITY");
    vars.totalSupplyNew = totalSupply - vars.redeemTokens;

    require(
      accountTokens[redeemer] >= vars.redeemTokens,
      "Trying to redeem too much"
    );
    vars.accountTokensNew = accountTokens[redeemer] - vars.redeemTokens;

    /* Fail gracefully if protocol has insufficient cash */
    require(
      getCashPrior() >= vars.redeemAmount,
      "TOKEN_INSUFFICIENT_CASH | REDEEM_TRANSFER_OUT_NOT_POSSIBLE"
    );

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /*
     * We invoke doTransferOut for the redeemer and the redeemAmount.
     *  Note: The pToken must handle variations between ERC-20 and ETH underlying.
     *  On success, the pToken has redeemAmount less of cash.
     *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
     */
    doTransferOut(redeemer, vars.redeemAmount);

    /* We write previously calculated values into storage */
    totalSupply = vars.totalSupplyNew;
    accountTokens[redeemer] = vars.accountTokensNew;

    /* We emit a Transfer event, and a Redeem event */
    emit Transfer(redeemer, address(this), vars.redeemTokens);
    emit Redeem(redeemer, vars.redeemAmount, vars.redeemTokens);

    /* We call the defense hook */
    riskEngine.redeemVerify(
      address(this),
      redeemer,
      vars.redeemAmount,
      vars.redeemTokens
    );
  }

  /**
   * @notice Transfers collateral tokens (this market) to the liquidator.
   * @dev Will fail unless called by another pToken during the process of liquidation.
   *  Its absolutely critical to use msg.sender as the borrowed pToken and not a parameter.
   * @param liquidator The account receiving seized collateral
   * @param borrower The account having collateral seized
   * @param seizeTokens The number of pTokens to seize
   */
  function seize(
    address liquidator,
    address borrower,
    uint256 seizeTokens
  ) external override nonReentrant {
    return seizeInternal(msg.sender, liquidator, borrower, seizeTokens);
  }

  struct SeizeInternalLocalVars {
    uint256 borrowerTokensNew;
    uint256 liquidatorTokensNew;
    uint256 liquidatorSeizeTokens;
    uint256 protocolSeizeTokens;
    uint256 protocolSeizeAmount;
    uint256 totalReservesNew;
    uint256 totalSupplyNew;
  }

  /**
   * @notice Transfers collateral tokens (this market) to the liquidator.
   * @dev Called only during an in-kind liquidation, or by liquidateBorrow during the liquidation of another CToken.
   *  Its absolutely critical to use msg.sender as the seizer pToken and not a parameter.
   * @param seizerToken The contract seizing the collateral (i.e. borrowed pToken)
   * @param liquidator The account receiving seized collateral
   * @param borrower The account having collateral seized
   * @param seizeTokens The number of pTokens to seize
   */
  function seizeInternal(
    address seizerToken,
    address liquidator,
    address borrower,
    uint256 seizeTokens
  ) internal {
    /* Fail if seize not allowed */
    bool allowed = riskEngine.seizeAllowed(
      address(this),
      seizerToken,
      liquidator,
      borrower,
      seizeTokens
    );
    require(allowed, "Risk Engine rejection");

    /* Fail if borrower = liquidator */
    require(
      borrower != liquidator,
      "Borrower cannot liquidate their own position"
    );

    SeizeInternalLocalVars memory vars;

    /*
     * We calculate the new borrower and liquidator token balances, failing on underflow/overflow:
     *  borrowerTokensNew = accountTokens[borrower] - seizeTokens
     *  liquidatorTokensNew = accountTokens[liquidator] + seizeTokens
     */
    vars.borrowerTokensNew = accountTokens[borrower] - seizeTokens;

    vars.protocolSeizeTokens = (seizeTokens * protocolSeizeShare) / 1e8;
    vars.liquidatorSeizeTokens = seizeTokens - vars.protocolSeizeTokens;

    vars.protocolSeizeAmount = exchangeRateStored() * vars.protocolSeizeTokens;

    vars.totalReservesNew = totalReserves + vars.protocolSeizeAmount;
    vars.totalSupplyNew = totalSupply - vars.protocolSeizeTokens;

    vars.liquidatorTokensNew =
      accountTokens[liquidator] +
      vars.liquidatorSeizeTokens;

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /* We write the previously calculated values into storage */
    totalReserves = vars.totalReservesNew;
    totalSupply = vars.totalSupplyNew;
    accountTokens[borrower] = vars.borrowerTokensNew;
    accountTokens[liquidator] = vars.liquidatorTokensNew;

    /* Emit a Transfer event */
    emit Transfer(borrower, liquidator, vars.liquidatorSeizeTokens);
    emit Transfer(borrower, address(this), vars.protocolSeizeTokens);
    emit ReservesAdded(
      address(this),
      vars.protocolSeizeAmount,
      vars.totalReservesNew
    );

    /* We call the defense hook */
    // unused function
    // comptroller.seizeVerify(address(this), seizerToken, liquidator, borrower, seizeTokens);
  }

  /**
   * @notice Get a snapshot of the account's balance, and the cached exchange rate
   * @dev This is used by risk engine to more efficiently perform liquidity checks.
   * @param account Address of the account to snapshot
   * @return (possible error, token balance, exchange rate)
   */
  function getAccountSnapshot(address account)
    external
    view
    override
    returns (uint256, uint256)
  {
    uint256 pTokenBalance = accountTokens[account];
    uint256 exchangeRate;

    exchangeRate = exchangeRateStored();

    return (pTokenBalance, exchangeRate);
  }

  /**
   * @notice Calculates the exchange rate from the underlying to the PToken
   * @dev This function does not accrue interest before calculating the exchange rate
   * @return (calculated exchange rate scaled by 1e18)
   */
  function exchangeRateStored() public view override returns (uint256) {
    // this is where the tests are failing
    uint256 _totalSupply = totalSupply;
    if (_totalSupply == 0) {
      /*
       * If there are no tokens minted:
       *  exchangeRate = initialExchangeRate
       */
      return initialExchangeRate;
    } else {
      /*
       * Otherwise:
       *  exchangeRate = (totalCash + totalBorrows - totalReserves) / totalSupply
       */
      uint256 totalCash = getCashPrior();
      uint256 cashPlusBorrowsMinusReserves;
      uint256 exchangeRate;

      cashPlusBorrowsMinusReserves = totalCash - totalReserves;

      exchangeRate = (totalCash * 10**decimals) / _totalSupply;
      return exchangeRate;
    }
  }

  /**
   * @notice updates the interest rate model (*requires fresh interest accrual)
   * @dev Admin function to update the interest rate model
   * @param newInterestRateModel the new interest rate model to use
   */
  function _setInterestRateModelFresh(InterestRateModel newInterestRateModel)
    internal
  {
    // Used to store old model for use in the event that is emitted on success
    InterestRateModel oldInterestRateModel;

    // Check caller is admin
    // TODO: Fix this once admin functions are added
    // if (msg.sender != admin) {
    //     return fail(Error.UNAUTHORIZED, FailureInfo.SET_INTEREST_RATE_MODEL_OWNER_CHECK);
    // }

    // We fail gracefully unless market's block number equals current block number
    require(
      accrualBlockNumber == block.number,
      "MARKET_NOT_FRESH | SET_INTEREST_RATE_MODEL_FRESH_CHECK"
    );

    // Track the market's current interest rate model
    oldInterestRateModel = interestRateModel;

    // Ensure invoke newInterestRateModel.isInterestRateModel() returns true
    require(
      newInterestRateModel.isInterestRateModel(),
      "marker method returned false"
    );

    // Set the interest rate model to newInterestRateModel
    interestRateModel = newInterestRateModel;

    // Emit NewMarketInterestRateModel(oldInterestRateModel, newInterestRateModel)
    emit NewMarketInterestRateModel(oldInterestRateModel, newInterestRateModel);
  }

  function _setRiskEngine(RiskEngineInterface newRiskEngine) public override {
    // // Check caller is admin
    // TODO: Fix this once admin functions are added
    // if (msg.sender != admin) {
    //     return fail(Error.UNAUTHORIZED, FailureInfo.SET_RISKENGINE_OWNER_CHECK);
    // }

    RiskEngineInterface oldRiskEngine = riskEngine;
    // Ensure invoke riskEngine.isRiskEngine() returns true
    require(newRiskEngine.isRiskEngine(), "marker method returned false");

    // Set market's riskEngine to newRISKENGINE
    riskEngine = newRiskEngine;

    // Emit NewRiskEngine(oldRiskEngine, newRiskEngine)
    emit NewRiskEngine(oldRiskEngine, newRiskEngine);
  }

  /**
   * @notice Gets balance of this contract in terms of the underlying
   * @dev This excludes the value of the current message, if any
   * @return The quantity of underlying owned by this contract
   */
  function getCashPrior() internal view virtual returns (uint256);

  /**
   * @notice Get cash balance of this pToken in the underlying asset
   * @return The quantity of underlying asset owned by this contract
   */
  function getCash() external view override returns (uint256) {
    return getCashPrior();
  }

  /**
   * @dev Performs a transfer out, ideally returning an explanatory error code upon failure tather than reverting.
   *  If caller has not called checked protocol's balance, may revert due to insufficient cash held in the contract.
   *  If caller has checked protocol's balance, and verified it is >= amount, this should not revert in normal conditions.
   */
  function doTransferOut(address payable to, uint256 amount) internal virtual;

  /*** Reentrancy Guard ***/

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   */
  modifier nonReentrant() {
    require(_notEntered, "re-entered");
    _notEntered = false;
    _;
    _notEntered = true; // get a gas-refund post-Istanbul
  }
}

// mapping(address => PToken[]) public accountAssets;
// PToken[] memory assets = accountAssets[account];

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "./RiskEngineInterface.sol";
import "../InterestRateModel.sol";
import "../InitialCollateralRatioModel.sol";
import "./EIP20NonStandardInterface.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract PTokenStorage {
  /**
   * @dev Guard variable for re-entrancy checks
   */
  bool internal _notEntered;

  /**
   * @notice EIP-20 token name for this token
   */
  string public name;

  /**
   * @notice EIP-20 token symbol for this token
   */
  string public symbol;

  /**
   * @notice EIP-20 token decimals for this token
   */
  uint8 public decimals;

  /**
   * @notice EIP-20 token decimals for this token
   */
  IERC20 public underlyingAsset;

  /**
   * @notice Administrator for this contract
   */
  address payable public admin;

  /**
   * @notice Pending administrator for this contract
   */
  address payable public pendingAdmin;

  /**
   * @notice Contract which oversees inter-pToken operations
   */
  RiskEngineInterface public riskEngine;

  /**
   * @notice Model which tells what the current interest rate should be
   */
  InterestRateModel public interestRateModel;

  /**
   * @notice Model which tells whether a user may withdraw collateral or take on additional debt
   */
  InitialCollateralRatioModel public initialCollateralRatioModel;

  /**
   * @notice Initial exchange rate used when minting the first PTokens (used when totalSupply = 0)
   */
  uint256 internal initialExchangeRate;

  /**
   * @notice Block number that interest was last accrued at
   */
  uint256 public accrualBlockNumber;

  /**
   * @notice Total amount of reserves of the underlying held in this market
   */
  uint256 public totalReserves;

  /**
   * @notice Total number of tokens in circulation
   */
  uint256 public totalSupply;

  /**
   * @notice Official record of token balances for each account
   */
  mapping(address => uint256) internal accountTokens;

  /**
   * @notice Approved token transfer amounts on behalf of others
   */
  mapping(address => mapping(address => uint256)) internal transferAllowances;

  /**
   * @notice Share of seized collateral that is added to reserves
   */
  uint256 public constant protocolSeizeShare = 2.8e6; //2.8%
}

abstract contract PTokenInterface is PTokenStorage {
  /**
   * @notice Indicator that this is a PToken contract (for inspection)
   */
  bool public constant isPToken = true;

  /*** Market Events ***/

  /**
   * @notice Event emitted when interest is accrued
   */
  // event AccrueInterest(uint cashPrior, uint interestAccumulated, uint borrowIndex, uint totalBorrows);

  /**
   * @notice Event emitted when tokens are minted
   */
  event Mint(address minter, uint256 mintAmount, uint256 mintTokens);

  /**
   * @notice Event emitted when tokens are redeemed
   */
  event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);

  /**
   * @notice Event emitted when a borrow is liquidated
   */
  // event LiquidateBorrow(address liquidator, address borrower, uint repayAmount, address cTokenCollateral, uint seizeTokens);

  /*** Admin Events ***/

  /**
   * @notice Event emitted when pendingAdmin is changed
   */
  event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

  /**
   * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
   */
  event NewAdmin(address oldAdmin, address newAdmin);

  /**
   * @notice Event emitted when Risk Engine is changed
   */
  event NewRiskEngine(
    RiskEngineInterface oldRiskEngine,
    RiskEngineInterface newRiskEngine
  );

  /**
   * @notice Event emitted when interestRateModel is changed
   */
  event NewMarketInterestRateModel(
    InterestRateModel oldInterestRateModel,
    InterestRateModel newInterestRateModel
  );

  /**
   * @notice Event emitted when the reserve factor is changed
   */
  event NewReserveFactor(uint256 oldReserveFactor, uint256 newReserveFactor);

  /**
   * @notice Event emitted when the reserves are added
   */
  event ReservesAdded(
    address benefactor,
    uint256 addAmount,
    uint256 newTotalReserves
  );

  /**
   * @notice Event emitted when the reserves are reduced
   */
  event ReservesReduced(
    address admin,
    uint256 reduceAmount,
    uint256 newTotalReserves
  );

  /**
   * @notice EIP20 Transfer event
   */
  event Transfer(address indexed from, address indexed to, uint256 amount);

  /**
   * @notice EIP20 Approval event
   */
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 amount
  );

  /**
   * @notice Failure event
   */
  event TokenFailure(uint256 error, uint256 info, uint256 detail);

  /**
   * @notice Event emitted when comptroller is changed
   */
  event NewComptroller(
    RiskEngineInterface oldComptroller,
    RiskEngineInterface newComptroller
  );

  /*** User Interface ***/

  function transfer(address dst, uint256 amount) external virtual;

  function transferFrom(
    address src,
    address dst,
    uint256 amount
  ) external virtual;

  function approve(address spender, uint256 amount)
    external
    virtual
    returns (bool);

  function allowance(address owner, address spender)
    external
    view
    virtual
    returns (uint256);

  function balanceOf(address owner) external view virtual returns (uint256);

  function balanceOfUnderlying(address owner)
    external
    virtual
    returns (uint256);

  function getAccountSnapshot(address account)
    external
    view
    virtual
    returns (uint256, uint256);

  //function exchangeRateCurrent() virtual public returns (uint);
  function exchangeRateStored() public view virtual returns (uint256);

  function getCash() external view virtual returns (uint256);

  function accrueInterest() public virtual;

  function seize(
    address liquidator,
    address borrower,
    uint256 seizeTokens
  ) external virtual;

  /*** Admin Functions ***/

  //function _setPendingAdmin(address payable newPendingAdmin) virtual external returns (uint);
  //function _acceptAdmin() virtual external returns (uint);
  function _setRiskEngine(RiskEngineInterface newRiskEngine) public virtual;
  // function _setReserveFactor(uint newReserveFactorMantissa) virtual external returns (uint);
  //function _reduceReserves(uint reduceAmount) virtual external returns (uint);
  //function _setInterestRateModel(InterestRateModel newInterestRateModel) virtual public returns (uint);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

/**
 * @title ERC 20 Token Standard Interface
 *  https://eips.ethereum.org/EIPS/eip-20
 */
interface EIP20Interface {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    /**
      * @notice Get the total number of tokens in circulation
      * @return The supply of tokens
      */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return success Whether or not the transfer succeeded
      */
    function transfer(address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return success Whether or not the transfer succeeded
      */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved (-1 means infinite)
      * @return success Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return remaining The number of tokens allowed to be spent (-1 means infinite)
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "./EIP20NonStandardInterface.sol";
import "./PTokenInterface.sol";

contract PErc20Storage {
  /**
   * @notice Underlying asset for this CToken
   */
  address public underlying;
}

abstract contract PErc20Interface is PErc20Storage {
  /*** User Interface ***/

  function mint(uint256 mintAmount) external virtual returns (bool);

  function redeem(uint256 redeemTokens) external virtual returns (bool);

  function redeemUnderlying(uint256 redeemAmount)
    external
    virtual
    returns (bool);

  function sweepToken(EIP20NonStandardInterface token) external virtual;

  /*** Admin Functions ***/

  //function _addReserves(uint addAmount) virtual external returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
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
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

//remove when done testing
import "hardhat/console.sol";

import "./LoanAgent.sol";
import "./PUSD.sol";
import "./PToken.sol";
import "./interfaces/RiskEngineInterface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RiskEngine is RiskEngineStorage, RiskEngineInterface, Ownable {
  /// @notice Emitted when an admin supports a market
  event MarketListed(PToken pToken);

  /// @notice Emitted when an admin supports a market
  event BorrowMarketListed(LoanAgent loanAgent);

  /// @notice Emitted when an account enters a deposit market
  event MarketEntered(PToken pToken, address account);

  /// @notice Emitted when an account enters a borrow market
  event BorrowMarketEntered(LoanAgent loanAgent, address account);

  /// @notice Emitted when an account exits a market
  event MarketExited(PToken pToken, address account);

  /// @notice Emitted when an account exits a borrow market
  event BorrowMarketExited(LoanAgent loanAgent, address account);

  /// @notice Emitted when price oracle is changed
  event NewPriceOracle(
    IPriceOracle oldPriceOracle,
    IPriceOracle newPriceOracle
  );

  /// @notice Emitted when PRIME is distributed to a supplier
  event DistributedSupplierPrime(
    PToken indexed pToken,
    address indexed supplier,
    uint256 primeDelta,
    uint256 primeSupplyIndex
  );

  address PUSDAddress;

  /// @notice The initial PRIME index for a market
  uint224 public constant primeInitialIndex = 1e36;

  /// @dev Gets the account assets held by a depositor
  /// @param accountAddress Depositor into the PToken contracts
  function getAccountAssets(address accountAddress)
    external
    view
    returns (PToken[] memory)
  {
    return accountAssets[accountAddress];
  }

  /*** Assets You Are In ***/

  /**
   * @notice Add assets to be included in account liquidity calculation
   * @param pTokens The list of addresses of the pToken markets to be enabled
   * @return r indicator for whether each corresponding market was entered
   */
  function enterMarkets(address[] memory pTokens)
    public
    override
    returns (bool[] memory r)
  {
    uint256 len = pTokens.length;

    r = new bool[](len);
    for (uint256 i = 0; i < len; i++) {
      PToken pToken = PToken(pTokens[i]);

      r[i] = addToMarketInternal(pToken, msg.sender);
    }
  }

  /**
   * @notice Add the market to the borrower's "assets in" for liquidity calculations
   * @param pToken The market to enter
   * @param borrower The address of the account to modify
   */
  function addToMarketInternal(PToken pToken, address borrower)
    internal
    returns (bool)
  {
    Market storage marketToJoin = markets[address(pToken)];

    if (!marketToJoin.isListed) return false;

    // already joined
    if (marketToJoin.accountMembership[borrower] == true) return true;

    // survived the gauntlet, add to list
    // NOTE: we store these somewhat redundantly as a significant optimization
    //  this avoids having to iterate through the list for the most common use cases
    //  that is, only when we need to perform liquidity checks
    //  and not whenever we want to check if an account is in a particular market
    marketToJoin.accountMembership[borrower] = true;
    accountAssets[borrower].push(pToken);

    emit MarketEntered(pToken, borrower);

    return true;
  }

  /**
   * @notice Removes asset from sender's account liquidity calculation
   * @dev Sender must not be providing necessary collateral for an outstanding borrow.
   * @param pTokenAddress The address of the asset to be removed
   */
  function exitMarket(address pTokenAddress) external override returns (bool) {
    PToken pToken = PToken(pTokenAddress);
    /* Get sender tokensHeld and amountOwed underlying from the pToken */
    (uint256 tokensHeld, uint256 amountOwed) = pToken.getAccountSnapshot(
      msg.sender
    );

    /* Fail if the sender has a borrow balance */
    require(
      amountOwed > 0,
      "EXIT_MARKET_BALANCE_OWED"
    );

    /* Fail if the sender is not permitted to redeem all of their tokens */
    bool allowed = redeemAllowed(pTokenAddress, msg.sender, tokensHeld);
    require(allowed, "EXIT_MARKET_REJECTION");

    Market storage marketToExit = markets[address(pToken)];

    /* Return true if the sender is not already ‘in’ the market */
    if (!marketToExit.accountMembership[msg.sender]) {
      return true;
    }

    /* Set pToken account membership to false */
    delete marketToExit.accountMembership[msg.sender];

    /* Delete pToken from the account’s list of assets */
    // load into memory for faster iteration
    PToken[] memory userAssetList = accountAssets[msg.sender];
    uint256 len = userAssetList.length;
    uint256 assetIndex = len;
    for (uint256 i = 0; i < len; i++) {
      if (userAssetList[i] == pToken) {
        assetIndex = i;
        break;
      }
    }

    // We *must* have found the asset in the list or our redundant data structure is broken
    assert(assetIndex < len);

    // copy last item in list to location of item to be removed, reduce length by 1
    PToken[] storage storedList = accountAssets[msg.sender];
    storedList[assetIndex] = storedList[storedList.length - 1];
    storedList.pop();

    emit MarketExited(pToken, msg.sender);

    return true;
  }

  function redeemAllowed(
    address pToken,
    address redeemer,
    uint256 redeemTokens
  )
    public
    view
    override
    returns (
      // NOTE: This previously return uint256, rewriting it to try to revert
      // There is known misbehaviour when reverting in a view function on the network
      // I am unsure if those misbehaviours will occur in this context, as the function
      // is being called from a contract and thus not executing how a view would normally
      // if this function is called as a view function, then the requires might cause
      // major issues
      bool
    )
  {
    require(markets[pToken].isListed, "MARKET_NOT_LISTED");

    /* If the redeemer is not 'in' the market, then we can bypass the liquidity check */
    //is this check even necessary
    // NOTE: Could make this a revert instead?
    if (!markets[pToken].accountMembership[redeemer]) return true;

    /* Otherwise, perform a hypothetical liquidity check to guard against shortfall */
    (, uint256 shortfall) = getHypotheticalAccountLiquidityRedeemInternal(
      redeemer,
      PToken(pToken),
      redeemTokens
    );

    require(shortfall == 0, "INSUFFICIENT_LIQUIDITY");
    return true;
  }

  /**
   * @notice Validates redeem and reverts on rejection. May emit logs.
   * @param pToken Asset being redeemed
   * @param redeemer The address redeeming the tokens
   * @param redeemAmount The amount of the underlying asset being redeemed
   * @param redeemTokens The number of tokens being redeemed
   */
  function redeemVerify(
    address pToken,
    address redeemer,
    uint256 redeemAmount,
    uint256 redeemTokens
  ) external pure override {
    // Shh - currently unused
    pToken;
    redeemer;

    // Require tokens is zero or amount is also zero
    if (redeemTokens == 0 && redeemAmount > 0) {
      revert("REDEEM_TOKENS_ZERO");
    }
  }

  /**
   * @notice Checks if the account should be allowed to borrow the underlying asset of the given market
   * @param loanAgent The market to verify the borrow against
   * @param borrower The account which would borrow the asset
   * @param borrowAmount The amount of underlying the account would borrow
   */
  function borrowAllowed(
    address loanAgent,
    address borrower,
    uint256 borrowAmount
  ) external view override returns (bool) {
    require(loanAgent == address(borrowMarket), "MARKET_NOT_LISTED");

    // if (!borrowMarket.accountMembership[borrower]) {
    //     // only loanAgent may call borrowAllowed if borrower not in market
    //     require(msg.sender == loanAgent, "sender must be loanAgent");

    //     // attempt to add borrower to the market
    //     Error err = addToBorrowMarketInternal(LoanAgent(msg.sender), borrower);
    //     if (err != Error.NO_ERROR) {
    //         return uint(err);
    //     }

    //     // it should be impossible to break the important invariant
    //     assert(markets[loanAgent].accountMembership[borrower]);
    // }

    // if (oracle.getUnderlyingPriceBorrow(LoanAgent(loanAgent)) == 0) {
    //     return uint(Error.PRICE_ERROR);
    // }
    // Borrow cap of 0 corresponds to unlimited borrowing
    if (borrowCap != 0) {
      uint256 totalBorrows = LoanAgent(loanAgent).totalBorrows();
      uint256 nextTotalBorrows = totalBorrows + borrowAmount;
      require(nextTotalBorrows < borrowCap, "BORROW_CAP_REACHED");
    }
    (, uint256 shortfall) = getHypotheticalAccountLiquidityBorrowInternal(
      LoanAgent(loanAgent),
      borrower,
      borrowAmount
    );

    require(shortfall == 0, "INSUFFICIENT_LIQUIDITY");

    // Revisit these when we want to add prime rewards for borrowing
    // Keep the flywheel moving
    //Exp memory borrowIndex = Exp({mantissa: LoanAgent(loanAgent).borrowIndex()});
    //updatePrimeBorrowIndex(loanAgent, borrowIndex);
    //distributeBorrowerPrime(loanAgent, borrower, borrowIndex);
    return true;
  }

  /**
   * @notice Checks if the account should be allowed to mint tokens in the given market
   * @param pToken The market to verify the mint against
   * @param minter The account which would get the minted tokens
   * @param mintAmount The amount of underlying being supplied to the market in exchange for tokens
   */
  function mintAllowed(
    address pToken,
    address minter,
    uint256 mintAmount
  ) external view override returns (bool) {
    // Pausing is a very serious situation - we revert to sound the alarms
    require(!mintGuardianPaused[pToken], "MINT_PAUSED");

    // Shh - currently unused
    minter;
    mintAmount;

    require(markets[pToken].isListed, "MARKET_NOT_LISTED");

    // Keep the flywheel moving
    // Revisit this if we want to issue PRIME rewards to suppliers
    // updatePrimeSupplyIndex(pToken);
    // distributeSupplierPrime(pToken, minter);
    return true;
  }

  /**
   * @notice Accrue PRIME to the market by updating the supply index
   * @param pToken The market whose supply index to update
   * @dev Index is a cumulative sum of the PRIME per pToken accrued.
   */
  function updatePrimeSupplyIndex(address pToken) internal {
    PrimeMarketState storage supplyState = primeSupplyState[pToken];
    uint256 supplySpeed = primeSupplySpeeds[pToken];
    require(block.number <= 2**32, "BLOCK_TOO_BIG");
    uint256 deltaBlocks = block.number - uint256(supplyState.block);
    if (deltaBlocks > 0 && supplySpeed > 0) {
      uint256 supplyTokens = PToken(pToken).totalSupply();
      uint256 primeAccrued = deltaBlocks * supplySpeed;
      uint256 ratio = supplyTokens > 0
        ? (primeAccrued * 1e18) / supplyTokens
        : 0;
      require(
        supplyState.index + ratio <= 2**224,
        "224BIT_OVERFLOW"
      );
      supplyState.index = uint224(supplyState.index + ratio);
      supplyState.block = uint32(block.number);
    } else if (deltaBlocks > 0) {
      supplyState.block = uint32(block.number);
    }
  }

  function distributeSupplierPrime(address pToken, address supplier) internal {
    // TODO: Don't distribute supplier PRIME if the user is not in the supplier market.
    // This check should be as gas efficient as possible as distributeSupplierPrime is called in many places.
    // - We really don't want to call an external contract as that's quite expensive.

    PrimeMarketState storage supplyState = primeSupplyState[pToken];
    uint256 supplyIndex = supplyState.index;
    uint256 supplierIndex = primeSupplierIndex[pToken][supplier];

    // Update supplier's index to the current index since we are distributing accrued PRIME
    primeSupplierIndex[pToken][supplier] = supplyIndex;

    if (supplierIndex == 0 && supplyIndex >= primeInitialIndex) {
      // Covers the case where users supplied tokens before the market's supply state index was set.
      // Rewards the user with PRIME accrued from the start of when supplier rewards were first
      // set for the market.
      supplierIndex = primeInitialIndex;
    }

    // Calculate change in the cumulative sum of the PRIME per pToken accrued
    uint256 deltaIndex = supplyIndex - supplierIndex;
    // Double memory deltaIndex = Double({mantissa: sub_(supplyIndex, supplierIndex)});

    uint256 supplierTokens = PToken(pToken).balanceOf(supplier);

    // Calculate PRIME accrued: pTokenAmount * accruedPerPToken
    uint256 supplierDelta = supplierTokens * deltaIndex;

    uint256 supplierAccrued = primeAccrued[supplier] + supplierDelta;
    primeAccrued[supplier] = supplierAccrued;

    emit DistributedSupplierPrime(
      PToken(pToken),
      supplier,
      supplierDelta,
      supplyIndex
    );
  }

  /**
   * @notice Checks if the account should be allowed to repay a borrow in the given market
   * @param pToken The market to verify the repay against
   * @param payer The account which would repay the asset
   * @param borrower The account which would borrowed the asset
   * @param repayAmount The amount of the underlying asset the account would repay
   * @return 0 if the repay is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
   */
  function repayBorrowAllowed(
    address pToken,
    address payer,
    address borrower,
    uint256 repayAmount
  ) external view override returns (bool) {
    // Shh - currently unused
    payer;
    borrower;
    repayAmount;

    require(markets[pToken].isListed, "MARKET_NOT_LISTED");

    // Revisit when we want to distribute rewards for borrowing
    // Keep the flywheel moving
    // Exp memory borrowIndex = Exp({mantissa: PToken(pToken).borrowIndex()});
    // updateCompBorrowIndex(pToken, borrowIndex);
    // distributeBorrowerComp(pToken, borrower, borrowIndex);

    return true;
  }

  /**
   * @notice Checks if the liquidation should be allowed to occur
   * @param loanAgent Asset which was borrowed by the borrower
   * @param pTokenCollateral Asset which was used as collateral and will be seized
   * @param liquidator The address repaying the borrow and seizing the collateral
   * @param borrower The address of the borrower
   * @param repayAmount The amount of underlying being repaid
   */
  function liquidateBorrowAllowed(
    address loanAgent,
    address pTokenCollateral,
    address liquidator,
    address borrower,
    uint256 repayAmount
  ) external override returns (bool) {
    // Shh - currently unused
    liquidator;

    require(markets[pTokenCollateral].isListed, "MARKET_NOT_LISTED");

    uint256 borrowBalance = LoanAgent(loanAgent).borrowBalanceStored(borrower);

    /* The borrower must have shortfall in order to be liquidatable */
    (, uint256 shortfall) = getAccountLiquidity(borrower);

    require(shortfall != 0, "INSUFFICIENT_SHORTFALL");

    uint256 multiplier;
    {
      (bool success, bytes memory ret) = pTokenCollateral.call(
        abi.encodeWithSignature("decimals()")
      );
      require(success, "DECIMALS_FAILED");
      multiplier = 10**abi.decode(ret, (uint8));
    }

    /* The liquidator may not repay more than what is allowed by the closeFactor */
    uint256 maxClose = (closeFactor * borrowBalance) / multiplier;
    require(repayAmount <= maxClose, "TOO_MUCH_REPAY");

    return true;
  }

  /**
   * @notice Checks if the seizing of assets should be allowed to occur
   * @param pTokenCollateral Asset which was used as collateral and will be seized
   * @param loanAgent Asset which was borrowed by the borrower
   * @param :liquidator The address repaying the borrow and seizing the collateral
   * @param :borrower The address of the borrower
   * @param seizeTokens The number of collateral tokens to seize
   */
  function seizeAllowed(
    address pTokenCollateral,
    address loanAgent,
    address, /*liquidator*/
    address, /*borrower*/
    uint256 seizeTokens
  ) external view override returns (bool) {
    // Pausing is a very serious situation - we revert to sound the alarms
    require(!seizeGuardianPaused, "SEIZE_PAUSED");

    // Shh - currently unused
    seizeTokens;

    require(markets[pTokenCollateral].isListed, "MARKET_NOT_LISTED");

    require(
      PToken(pTokenCollateral).riskEngine() == PToken(loanAgent).riskEngine(),
      "RISKENGINE_MISMATCH"
    );

    // Add this in
    // Keep the flywheel moving
    // updateCompSupplyIndex(pTokenCollateral);
    // distributeSupplierComp(pTokenCollateral, borrower);
    // distributeSupplierComp(pTokenCollateral, liquidator);

    return true;
  }

  /**
   * @notice Checks if the account should be allowed to transfer tokens in the given market
   * @param cToken The market to verify the transfer against
   * @param src The account which sources the tokens
   * @param dst The account which receives the tokens
   * @param transferTokens The number of cTokens to transfer
   * @return 0 if the transfer is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
   */
  function transferAllowed(
    address cToken,
    address src,
    address dst,
    uint256 transferTokens
  ) external override returns (bool) {
    // Pausing is a very serious situation - we revert to sound the alarms
    require(!transferGuardianPaused, "TRANSFER_PAUSED");

    // Currently the only consideration is whether or not
    //  the src is allowed to redeem this many tokens
    bool allowed = redeemAllowed(cToken, src, transferTokens);
    require(allowed, "REDEEM_BLOCKED");

    // Keep the flywheel moving
    updatePrimeSupplyIndex(cToken);
    distributeSupplierPrime(cToken, src);
    distributeSupplierPrime(cToken, dst);

    return true;
  }

  /**
   * @dev Local vars for avoiding stack-depth limits in calculating account liquidity.
   *  Note that `pTokenBalance` is the number of pTokens the account owns in the market,
   *  whereas `borrowBalance` is the amount of underlying that the account has borrowed.
   */
  struct AccountLiquidityLocalVars {
    uint256 sumCollateral;
    uint256 sumBorrowPlusEffects;
    uint256 pTokenBalance;
    uint256 borrowBalance;
    uint256 collateralFactor;
    uint256 exchangeRate;
    uint256 oraclePrice;
    uint256 tokensToDenom;
  }

  /**
   * @notice Determine the current account liquidity wrt collateral requirements
   * @return (account liquidity in excess of collateral requirements,
   *          account shortfall below collateral requirements)
   */
  function getAccountLiquidity(address account)
    public
    view
    returns (uint256, uint256)
  {
    return
      getHypotheticalAccountLiquidityRedeemInternal(
        account,
        PToken(address(0)),
        0
      );
  }

  /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param pTokenModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @dev Note that we calculate the exchangeRateStored for each collateral pToken using stored data,
     *  without calculating accumulated interest.
     * @return (possible error code,
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
  function getHypotheticalAccountLiquidityRedeemInternal(
    address account,
    PToken pTokenModify,
    uint256 redeemTokens
  ) internal view returns (uint256, uint256) {
    AccountLiquidityLocalVars memory vars; // Holds all our calculation results

    /// @notice if we exit the loop early for one  PToken, we need to reset these values.
    ///   i could see an exploit where they use an old multiplier value for a specific PToken
    uint256 precision;
    uint256 multiplier;
    vars.borrowBalance = borrowMarket.getBalance(account);

    // For each asset the account is in
    PToken[] memory assets = accountAssets[account];

    for (uint256 i = 0; i < assets.length; i++) {
      PToken asset = assets[i];

      precision = asset.decimals();
      multiplier = 10**precision;

      // Read the balances and exchange rate from the pToken
      (vars.pTokenBalance, vars.exchangeRate) = asset.getAccountSnapshot(
        account
      );

      // Unlike prime protocol, getUnderlyingPrice is relatively expensive because we use ChainLink as our primary price feed.
      // If user has no supply / borrow balance on this asset, and user is not redeeming / borrowing this asset, skip it.
      if (vars.pTokenBalance == 0 && asset != pTokenModify) {
        continue;
      }

      // 1e8
      vars.collateralFactor = markets[address(asset)].collateralFactor;

      // Get the normalized price of the asset

      vars.oraclePrice = oracle.getUnderlyingPrice(asset);

      require(vars.oraclePrice != 0, "PRICE_ERROR");

      // Pre-compute a conversion factor from tokens -> ether (normalized price value)
      // exchangeRate is getAccountSnapshot (pToken => underlying); if we deposited ETH, how much pETH are you getting
      // if someone deposited 10 ETH a month ago, they could get like 1k pTokens. if someone does the same this month, they would get the new exchangeRate, which would theoretically be lower. like 200 pTokens
      // should be 1, actual is (1 * 100000000 * 100000000)
      vars.tokensToDenom =
        (vars.collateralFactor * vars.exchangeRate * vars.oraclePrice) /
        multiplier /
        multiplier; /* normalize */

      // sumCollateral += tokensToDenom * pTokenBalance
      vars.sumCollateral +=
        (vars.tokensToDenom * vars.pTokenBalance) /
        multiplier; /* normalize */

      // Calculate effects of interacting with pTokenModify
      if (asset == pTokenModify) {
        // redeem effect
        // sumBorrowPlusEffects += tokensToDenom * redeemTokens
        vars.sumBorrowPlusEffects +=
          (vars.tokensToDenom * redeemTokens) /
          multiplier; /* normalize */
      }
    }

    // //get the multiplier and the oracle price from the loanAgent
    // // Read the balances and exchange rate from the pToken
    // (vars.pTokenBalance, vars.exchangeRate) = asset.getAccountSnapshot(
    //   account
    // );
    // // sumBorrowPlusEffects += oraclePrice * borrowBalance

    uint256 borrowOraclePrice = oracle.getUnderlyingPriceBorrow(borrowMarket);
    uint256 borrowBalance = borrowMarket.borrowBalanceStored(account);

    vars.sumBorrowPlusEffects +=
      (borrowOraclePrice * borrowBalance) /
      multiplier; /* normalize */

    // These are safe, as the underflow condition is checked first
    if (vars.sumCollateral > vars.sumBorrowPlusEffects) {
      return (vars.sumCollateral - vars.sumBorrowPlusEffects, 0);
    } else {
      return (0, vars.sumBorrowPlusEffects - vars.sumCollateral);
    }
  }

  /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param :loanAgentModify The market to hypothetically borrow in
     * @param account The account to determine liquidity for
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @dev Note that we calculate the exchangeRateStored for each collateral pToken using stored data,
     *  without calculating accumulated interest.
     * @return (possible error code,
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
  function getHypotheticalAccountLiquidityBorrowInternal(
    LoanAgent, /*loanAgentModify*/
    address account,
    uint256 borrowAmount
  ) internal view returns (uint256, uint256) {
    AccountLiquidityLocalVars memory vars; // Holds all our calculation results

    // For each asset the account is in
    PToken[] memory assets = accountAssets[account];
    for (uint256 i = 0; i < assets.length; i++) {
      PToken asset = assets[i];
      // Read the balances and exchange rate from the pToken
      (vars.pTokenBalance, vars.exchangeRate) = asset.getAccountSnapshot(
        account
      );

      uint256 precision = asset.decimals();
      uint256 multiplier = 10**precision;

      // Unlike prime protocol, getUnderlyingPrice is relatively expensive because we use ChainLink as our primary price feed.
      // If user has no supply / borrow balance on this asset, and user is not redeeming / borrowing this asset, skip it.
      if (vars.pTokenBalance == 0) {
        continue;
      }
      // hardcoded for test
      vars.collateralFactor = multiplier; //markets[address(asset)].collateralFactor;

      //using hard coded price of 1, FIX THIS

      vars.oraclePrice = multiplier * oracle.getUnderlyingPrice(asset);

      require(vars.oraclePrice != 0, "PRICE_ERROR");

      // Pre-compute a conversion factor from tokens -> ether (normalized price value)
      vars.tokensToDenom = ((((vars.collateralFactor * vars.exchangeRate) /
        multiplier) * vars.oraclePrice) / multiplier);

      // sumCollateral += tokensToDenom * pTokenBalance
      vars.sumCollateral =
        (vars.tokensToDenom * vars.pTokenBalance) /
        multiplier +
        vars.sumCollateral;
    }

    //add in the existing borrow
    vars.sumBorrowPlusEffects = borrowMarket.borrowBalanceStored(account);

    // borrow effect
    // sumBorrowPlusEffects += oraclePrice * borrowAmount
    vars.sumBorrowPlusEffects += borrowAmount;

    // These are safe, as the underflow condition is checked first
    if (vars.sumCollateral > vars.sumBorrowPlusEffects) {
      return (vars.sumCollateral - vars.sumBorrowPlusEffects, 0);
    } else {
      return (0, vars.sumBorrowPlusEffects - vars.sumCollateral);
    }
  }

  /**
   * @notice Calculate number of tokens of collateral asset to seize given an underlying amount
   * @dev Used in liquidation (called in cToken.liquidateBorrowFresh)
   * @param pTokenCollateral The address of the collateral pToken
   * @param actualRepayAmount The amount of pTokenBorrowed underlying to convert into pTokenCollateral tokens
   * @return number of pTokenCollateral tokens to be seized in a liquidation
   */
  function liquidateCalculateSeizeTokens(
    address pTokenCollateral,
    uint256 actualRepayAmount
  ) external view returns (uint256) {
    /* Read oracle prices for borrowed and collateral markets */
    // PUSD Price
    uint256 priceBorrowed = oracle.getUnderlyingPriceBorrow(borrowMarket);
    //
    uint256 priceCollateral = oracle.getUnderlyingPrice(PToken(pTokenCollateral));
    require(priceCollateral > 0 && priceBorrowed > 0, "PRICE_FETCH");

    uint256 multiplier;
    {
      (bool success, bytes memory ret) = pTokenCollateral.staticcall(
        abi.encodeWithSignature("decimals()")
      );
      require(success, "DECIMAL_FAILED");
      multiplier = 10**abi.decode(ret, (uint8));
    }
    /*
     * Get the exchange rate and calculate the number of collateral tokens to seize:
     *  seizeAmount = actualRepayAmount * liquidationIncentive * priceBorrowed / priceCollateral
     *  seizeTokens = seizeAmount / exchangeRate
     *   = actualRepayAmount * (liquidationIncentive * priceBorrowed) / (priceCollateral * exchangeRate)
     */
    return ((((priceBorrowed * priceCollateral) / multiplier) /
      ((priceCollateral * PToken(pTokenCollateral).exchangeRateStored()) /
        multiplier)) * actualRepayAmount);
  }

  /**
   * @notice Add the market to the markets mapping and set it as listed
   * @dev Admin function to set isListed and add support for the market
   * @param pToken The address of the market (token) to list
   */
  function _supportMarket(PToken pToken, Version version) external {
    // TODO: Fix this once admin functions are added
    // if (msg.sender != admin) {
    //     return fail(Error.UNAUTHORIZED, FailureInfo.SUPPORT_MARKET_OWNER_CHECK);
    // }

    // Check the market doesnt already exist, fail if does
    require(
      !markets[address(pToken)].isListed,
      "SUPPORT_MARKET_EXISTS"
    );

    pToken.isPToken(); // Sanity check to make sure its really a PToken

    markets[address(pToken)].isListed = true;
    markets[address(pToken)].isPrimed = false;
    markets[address(pToken)].version = version;

    /// @notice Temporary until the collateral factor is built out. Is currently defaulting to 0 in tests which is no no
    markets[address(pToken)].collateralFactor = 1e8;

    // uint256 precision = pToken.decimals();
    // uint256 multiplier = 10**precision;

    // Note that isComped is not in active use anymore
    // markets[address(pToken)] = Market({isListed: true, isPrimed: false, accountMembership: members, collateralFactorMantissa: 0, version: version});

    _addMarketInternal(address(pToken));

    emit MarketListed(pToken);
  }

  function _addMarketInternal(address pToken) internal {
    for (uint256 i = 0; i < allMarkets.length; i++) {
      require(allMarkets[i] != PToken(pToken), "MARKET_EXISTS");
    }
    allMarkets.push(PToken(pToken));
  }

  /**
   * @notice Sets a new price oracle for the risk engine
   * @dev Admin function to set a new price oracle
   */
  function _setPriceOracle(IPriceOracle newOracle) public {
    // Check caller is admin
    // require (msg.sender == admin, "Unauthorized user trying to change oracle");

    // Track the old oracle for the risk engine
    IPriceOracle oldOracle = oracle;

    // Set risk engine's oracle to newOracle
    oracle = newOracle;

    // Emit NewPriceOracle(oldOracle, newOracle)
    emit NewPriceOracle(oldOracle, newOracle);
  }

  function _setLoanAgent(LoanAgent loanAgent) external {
    // TODO: Fix this once admin functions are added
    // if (msg.sender != admin) {
    //     return fail(Error.UNAUTHORIZED, FailureInfo.SUPPORT_MARKET_OWNER_CHECK);
    // }
    borrowMarket = loanAgent;

    emit BorrowMarketListed(loanAgent);
  }

  /**
   * @notice Returns true if the given pToken market has been deprecated
   * @dev All borrows in a deprecated pToken market can be immediately liquidated
   * @param pToken The market to check if deprecated
   */
  // TODO protocol discussion
  // function isDeprecated(PToken pToken) public view returns (bool) {
  //   return markets[address(pToken)].collateralFactor == 0;
  // }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import {AggregatorInterface} from "../dependencies/chainlink/AggregatorInterface.sol";
import "../interfaces/IPrimeOracle.sol";
import "../interfaces/IPriceOracle.sol";
import "hardhat/console.sol";
import "../interfaces/PErc20Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PrimeOracle is IPrimeOracle, IPriceOracle {

    // Map of asset price feeds (asset => priceSource)
    mapping(IERC20 => AggregatorInterface) private assetFeeds;

    IPrimeOracleGetter private _twapOracle;
    address public immutable denomCurrency;
    uint256 public immutable denomCurrencyUnit;

    //TODO: allow transfer of ownership
    address public admin;

    /**
    * @dev Only the admin can call functions marked by this modifier.
    **/
    modifier onlyAdmin {
        require(msg.sender == admin, "Unauthorized use of function");
        _;
    }

    /// @notice constructor
    /// @param assets list of addresses of the assets
    /// @param feeds The address of the feed of each asset
    /// twapOracle The address of the twap oracle to use if the data of an
    ///                       aggregator is not consistent
    /// @param _denomCurrency the denom currency used for the price quotes. If USD is used, denom currency is 0x0
    /// @param _denomCurrencyUnit the unit of the denom currency
    constructor(
        IERC20[] memory assets,
        address[] memory feeds,
        // address twapOracle,
        address _denomCurrency,
        uint256 _denomCurrencyUnit
    ) {
        admin = msg.sender;
        // _setTwapOracle(twapOracle);
        _setAssetFeeds(assets, feeds);
        // vaultAddressesProvider = _vaultAddressesProvider;
        denomCurrency = _denomCurrency;
        denomCurrencyUnit = _denomCurrencyUnit;
        emit DenomCurrencySet(_denomCurrency, _denomCurrencyUnit);
    }

    /// @inheritdoc IPrimeOracleGetter
    function getAssetPrice(IERC20 asset) public view override returns (uint256) {
        AggregatorInterface feed = assetFeeds[asset];
        //TODO: this condition will never apply for USD (0x0)

        if (address(feed) != address(0)) {
            int256 price = feed.latestAnswer();
            if (price > 0) {
                return uint256(price);
            } 
            
            return _twapOracle.getAssetPrice(asset);
        }

        if (address(feed) == address(0)) {
            return _twapOracle.getAssetPrice(asset);
        }

        if (address(asset) == denomCurrency) {
            return denomCurrencyUnit;
        }

        return 0;    
    }

    /// @inheritdoc IPrimeOracle
    function getAssetPrices(IERC20[] calldata assets)
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256[] memory prices = new uint256[](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            prices[i] = getAssetPrice(assets[i]);
        }
        return prices;
    }

    /// @inheritdoc IPrimeOracle
    function getFeedOfAsset(IERC20 asset) external view override returns (address) {
        return address(assetFeeds[asset]);
    }

    /// @inheritdoc IPrimeOracle
    function getTwapOracle() external view  override returns (address) {
        return address(_twapOracle);
    }

    function getDenomCurrency() external view override returns (address) {
        return denomCurrency;
    }

    function getDenomCurrencyUnit() external view override returns (uint256) {
        return denomCurrencyUnit;
    }

    function getUnderlyingPrice(PToken pToken) external view override returns (uint256) {
        return getAssetPrice(IERC20(pToken.underlyingAsset()));
    }

    function getUnderlyingPriceBorrow(LoanAgent loanAgent) external view override returns (uint256) {
        return 1e8;
    }

        /// @inheritdoc IPrimeOracle
    function setAssetFeeds(IERC20[] calldata assets, address[] calldata feeds)
        external
        override
        onlyAdmin
    {
        _setAssetFeeds(assets, feeds);
    }

    /// @inheritdoc IPrimeOracle
    function setTwapOracle(address twapOracle)
        external
        override
        onlyAdmin
    {
        _setTwapOracle(twapOracle);
    }

    /**
    * @notice Internal function to set the feeds for each asset
    * @param assets The addresses of the assets
    * @param feeds The address of the feed of each asset
    */
    function _setAssetFeeds(IERC20[] memory assets, address[] memory feeds) internal {
        require(assets.length == feeds.length, "ERROR: Length mismatch between 'assets' and 'feeds'");
        for (uint256 i = 0; i < assets.length; i++) {
            assetFeeds[assets[i]] = AggregatorInterface(feeds[i]);
            emit AssetFeedUpdated(assets[i], feeds[i]);
        }
    }

    /**
    * @notice Internal function to set the twap oracle
    * @param twapOracle The address of the twap oracle
    */
    function _setTwapOracle(address twapOracle) internal {
        _twapOracle = IPrimeOracleGetter(twapOracle);
        emit TwapOracleUpdated(twapOracle);
    }
    
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

/**
  * @title Prime's InitialCollateralRatioModel Interface
  */

contract InitialCollateralRatioModel {
    /// @notice future consideration to have custom max LTV ratios
    bool public constant isInitialCollateralRatioModel = true;

    modifier onlyAdmin {
        require(msg.sender == admin, "Unauthorized use of function");
        _;
    }

    event AssetLtvRatioUpdated(address asset, uint256 ltvRatio);

    address admin;

    uint256 pusdPrice;
    uint256 pusdPriceCeiling;
    uint256 pusdPriceFloor;

    mapping(address => uint256) private ltvRatios;

    // TODO: will be used for LTV lookup by collateral later
    constructor(
      uint256 _pusdPrice,
      address[] memory _assets,
      uint256[] memory _ltvRatios
    ) {
        admin = msg.sender;
        _setRequiredLTVRatios(_assets, _ltvRatios);
        pusdPrice = _pusdPrice;
        pusdPriceCeiling = 1e6;
        pusdPriceFloor = 99e4;
    }

    function getRequiredCollateralRatio(
      address asset
      //pusdPrice - assume 6 decimals
      //maxLtvRatio //how much decimal precision do we want here? starting with 6 decimals
      //this value should come from an array passed into the constructor
      //returns 18 decimals of precision
    ) external view returns (uint256) {
      uint256 _pusdPrice = _getPusdPrice();
      //price >= 1.00
      if(_pusdPrice >= pusdPriceCeiling){
        return ltvRatios[asset];
      }
      //price <= 0.99
      else if (_pusdPrice <= pusdPriceFloor){
        return 0;
      }
      else{
        uint256 priceDelta = _pusdPrice - pusdPriceFloor;
        return priceDelta * ltvRatios[asset] / 1e4;
      }
    }

    function getPusdPrice(
    ) external view onlyAdmin returns (uint256) {
      return pusdPrice;
    }

    function _getPusdPrice(
    ) internal view onlyAdmin returns (uint256) {
      return pusdPrice;
    }

    function setPusdPrice(
      uint256 price
    ) external onlyAdmin {
      pusdPrice = price;
    }

    function  setPusdPriceCeiling(
      uint256 price
    ) external onlyAdmin {
      pusdPriceCeiling = price;
    }

    function setPusdPriceFloor(
      uint256 price
    ) external onlyAdmin {
      pusdPriceFloor = price;
    }

   function setRequiredLTVRatios(
     address[] memory _assets,
     uint256[] memory _ltvRatios
   ) external onlyAdmin {
     _setRequiredLTVRatios(_assets, _ltvRatios);
   }

   function _setRequiredLTVRatios(
     address[] memory _assets,
     uint256[] memory _ltvRatios
   ) internal onlyAdmin {
      require(_assets.length == _ltvRatios.length, "ERROR: Length mismatch between 'assets' and 'assetLtvRatios'");
      for (uint256 i = 0; i < _assets.length; i++) {
          ltvRatios[_assets[i]] = _ltvRatios[i];
          emit AssetLtvRatioUpdated(_assets[i], _ltvRatios[i]);
      }
   }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "./PUSD.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";
import "./RiskEngine.sol";
import "./interfaces/LoanAgentInterface.sol";
import "./interfaces/PTokenInterface.sol";
import "./PUSD.sol";
import {InterestRateModel} from "./InterestRateModel.sol";

contract LoanAgent is
  Ownable,
  LoanAgentInterface,
  ReentrancyGuard
{
  constructor(
    InterestRateModel _interestRateModel
  ) {
    // NOTE: What is this for
    borrowIndex = 1e18;
    interestRateModel = _interestRateModel;
  }

  function setRiskEngine(RiskEngineInterface _RiskEngineAddress)
    external
    override
    onlyOwner
  {
    riskEngine = _RiskEngineAddress;
  }

  function setPUSD(PUSD _PUSDAddress) external override onlyOwner {
    PUSDAddress = _PUSDAddress;
  }

  struct BorrowLocalVars {
    uint256 accountBorrows;
    uint256 accountBorrowsNew;
    uint256 totalBorrowsNew;
  }

  /**
   * @notice Users borrow assets from the protocol to their own address
   * @param borrowAmount The amount of the underlying asset to borrow
   */
  function borrow(uint256 borrowAmount)
    external
    override
    nonReentrant
    returns (bool)
  {
    accrueInterest();
    address payable borrower = payable(msg.sender);

    /* Fail if borrow not allowed */
    bool allowed = riskEngine.borrowAllowed(
      address(this),
      borrower,
      borrowAmount
    );

    require(allowed, "RISKENGINE_REJECTION | BORROW_RISKENGINE_REJECTION");

    /* Verify market's block number equals current block number */
    require(accrualBlockNumber == block.number, "BORROW_FRESHNESS_CHECK");

    BorrowLocalVars memory vars;

    /*
     * We calculate the new borrower and total borrow balances, failing on overflow:
     *  accountBorrowsNew = accountBorrows + borrowAmount
     *  totalBorrowsNew = totalBorrows + borrowAmount
     */
    vars.accountBorrows = borrowBalanceStoredInternal(borrower);

    vars.accountBorrowsNew = vars.accountBorrows + borrowAmount;

    vars.totalBorrowsNew = totalBorrows + borrowAmount;

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /*
     * We invoke doTransferOut for the borrower and the borrowAmount.
     *  Note: The pToken must handle variations between ERC-20 and ETH underlying.
     *  On success, the pToken borrowAmount less of cash.
     *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
     */
    // This can be easily simplified because we are only issuing one token - PuSD
    // doTransferOut(borrower, borrowAmount);
    // might need a safe transfer of sorts

    PUSDAddress.mint(borrower, borrowAmount);

    /* We write the previously calculated values into storage */
    accountBorrows[borrower].principal = vars.accountBorrowsNew;
    accountBorrows[borrower].interestIndex = borrowIndex;
    totalBorrows = vars.totalBorrowsNew;
    /* We emit a Borrow event */
    emit Borrow(
      borrower,
      borrowAmount,
      vars.accountBorrowsNew,
      vars.totalBorrowsNew
    );

    return true;

    /* We call the defense hook */
    // unused function
    // comptroller.borrowVerify(address(this), borrower, borrowAmount);
  }

  /**
   * @notice Return the borrow balance of account based on stored data
   * @param account The address whose balance should be calculated
   * @return The calculated balance
   */
  function borrowBalanceStored(address account) public view returns (uint256) {
    uint256 result = borrowBalanceStoredInternal(account);
    return result;
  }

  /**
   * @notice Return the borrow balance of account based on stored data
   * @param account The address whose balance should be calculated
   * @return (error code, the calculated balance or 0 if error code is non-zero)
   */
  function borrowBalanceStoredInternal(address account)
    internal
    view
    returns (uint256)
  {
    /* Note: we do not assert that the market is up to date */
    uint256 principalTimesIndex;
    uint256 result;

    /* Get borrowBalance and borrowIndex */
    BorrowSnapshot storage borrowSnapshot = accountBorrows[account];

    /* If borrowBalance = 0 then borrowIndex is likely also 0.
     * Rather than failing the calculation with a division by 0, we immediately return 0 in this case.
     */
    if (borrowSnapshot.principal == 0) return 0;

    /* Calculate new borrow balance using the interest index:
     *  recentBorrowBalance = borrower.borrowBalance * market.borrowIndex / borrower.borrowIndex
     */
    principalTimesIndex = borrowSnapshot.principal * borrowIndex;

    result = principalTimesIndex / borrowSnapshot.interestIndex;

    return result;
  }

  /**
   * @notice Sender repays a borrow belonging to borrower
   * @param borrower the account with the debt being payed off
   * @param repayAmount The amount to repay
   * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
   */
  function repayBorrowBehalf(address borrower, uint256 repayAmount)
    external
    override
    nonReentrant
    returns (bool)
  {
    accrueInterest();

    // repayBorrowFresh emits repay-borrow-specific logs on errors, so we don't need to
    repayBorrowFresh(msg.sender, borrower, repayAmount);
    return true;
  }

  /**
   * @notice Sender repays their own borrow
   * @param repayAmount The amount to repay
   * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
   */
  function repayBorrow(uint256 repayAmount)
    external
    override
    nonReentrant
    returns (bool)
  {
    accrueInterest();

    // repayBorrowFresh emits repay-borrow-specific logs on errors, so we don't need to
    repayBorrowFresh(msg.sender, msg.sender, repayAmount);
    return true;
  }

  struct RepayBorrowLocalVars {
    uint256 repayAmount;
    uint256 borrowerIndex;
    uint256 accountBorrows;
    uint256 accountBorrowsNew;
    uint256 totalBorrowsNew;
    uint256 actualRepayAmount;
  }

  /**
   * @notice Borrows are repaid by another user (possibly the borrower).
   * @param payer the account paying off the borrow
   * @param borrower the account with the debt being payed off
   * @param repayAmount the amount of undelrying tokens being returned
   * @return the actual repayment amount.
   */
  function repayBorrowFresh(
    address payer,
    address borrower,
    uint256 repayAmount
  ) internal returns (uint256) {
    /* Fail if repayBorrow not allowed */
    // TODO - Risk Agent
    // NOTE: We don't need to check here, as the only thing this is doing at current state
    // is checking if the token is in market, but that is already handled inside the loanAgent
    // bool allowed = riskEngine.repayBorrowAllowed(pToken, payer, borrower, repayAmount);
    // require(allowed, "RISKENGINE_REJECTION | REPAY_BORROW_RISKENGINE_REJECTION");

    /* Verify market's block number equals current block number */
    require(accrualBlockNumber == block.number, "REPAY_BORROW_FRESHNESS_CHECK");

    RepayBorrowLocalVars memory vars;

    /* We remember the original borrowerIndex for verification purposes */
    vars.borrowerIndex = accountBorrows[borrower].interestIndex;

    /* We fetch the amount the borrower owes, with accumulated interest */
    vars.accountBorrows = borrowBalanceStoredInternal(borrower);

    /* If repayAmount == -1, repayAmount = accountBorrows */
    // As of Solidity v0.8 Explicit conversions between literals and an integer type T are only allowed if the literal lies between type(T).min and type(T).max. In particular, replace usages of uint(-1) with type(uint).max.
    // type(uint).max
    vars.repayAmount = repayAmount == type(uint256).max ? vars.accountBorrows : repayAmount;

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /*
     * We call doTransferIn for the payer and the repayAmount
     *  Note: The pToken must handle variations between ERC-20 and ETH underlying.
     *  On success, the pToken holds an additional repayAmount of cash.
     *  doTransferIn reverts if anything goes wrong, since we can't be sure if side effects occurred.
     *   it returns the amount actually transferred, in case of a fee.
     */
    // vars.actualRepayAmount = doTransferIn(payer, vars.repayAmount);
    PUSDAddress.burnFrom(msg.sender, repayAmount); // burn the pusd

    vars.actualRepayAmount = repayAmount;

    /*
     * We calculate the new borrower and total borrow balances, failing on underflow:
     *  accountBorrowsNew = accountBorrows - actualRepayAmount
     *  totalBorrowsNew = totalBorrows - actualRepayAmount
     */
    require(
      vars.accountBorrows >= vars.actualRepayAmount,
      "Repay greater than borrows"
    );
    vars.accountBorrowsNew = vars.accountBorrows - vars.actualRepayAmount;

    require(
      totalBorrows >= vars.actualRepayAmount,
      "Actual repay greater than total borrows"
    );
    vars.totalBorrowsNew = totalBorrows - vars.actualRepayAmount;

    /* We write the previously calculated values into storage */
    accountBorrows[borrower].principal = vars.accountBorrowsNew;
    accountBorrows[borrower].interestIndex = borrowIndex;
    totalBorrows = vars.totalBorrowsNew;

    /* We emit a RepayBorrow event */
    emit RepayBorrow(
      payer,
      borrower,
      vars.actualRepayAmount,
      vars.accountBorrowsNew,
      vars.totalBorrowsNew
    );

    /* We call the defense hook */
    // unused function
    // comptroller.repayBorrowVerify(address(this), payer, borrower, vars.actualRepayAmount, vars.borrowerIndex);

    return vars.actualRepayAmount;
  }


  function extractRevertReason(
    bytes memory revertData
  ) internal pure returns (string memory reason) {
    uint l = revertData.length;
    if (l < 68) return "";
    uint t;
    assembly {
      revertData := add (revertData, 4)
      t := mload (revertData) // Save the content of the length slot
      mstore (revertData, sub (l, 4)) // Set proper length
    }
    reason = abi.decode (revertData, (string));
    assembly {
      mstore (revertData, t) // Restore the content of the length slot
    }
  }

  /**
   * @notice The liquidator liquidates the borrowers collateral.
   *  The collateral seized is transferred to the liquidator.
   * @param borrower The borrower of this pToken to be liquidated
   * @param pTokenCollateral The market in which to seize collateral from the borrower
   * @param repayAmount The amount of the underlying borrowed asset to repay
   * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
   */
  function liquidateBorrow(
    address borrower,
    uint256 repayAmount,
    PTokenInterface pTokenCollateral
  ) external override returns (bool) {
    /* Fail if liquidate not allowed */
    address liquidator = msg.sender;
    accrueInterest();
    // TODO - liquidation approval
    bool allowed = riskEngine.liquidateBorrowAllowed(address(this), address(pTokenCollateral), liquidator, borrower, repayAmount);
    require(allowed, "RISKENGINE_REJECTION | LIQUIDATE_RISKENGINE_REJECTION");


    /* Verify market's block number equals current block number */
    require(accrualBlockNumber == block.number, "LIQUIDATE_FRESHNESS_CHECK");

    /* Fail if borrower = liquidator */
    require(borrower != liquidator, "INVALID_ACCOUNT_PAIR | LIQUIDATE_LIQUIDATOR_IS_BORROWER");

    /* Fail if repayAmount = 0 */
    require(repayAmount > 0, "INVALID_CLOSE_AMOUNT_REQUESTED | LIQUIDATE_CLOSE_AMOUNT_IS_ZERO");

    /* Fail if repayAmount = -1 */
    // NOTE: What case is this check covering?
    require(repayAmount != type(uint128).max, "INVALID_CLOSE_AMOUNT_REQUESTED | LIQUIDATE_CLOSE_AMOUNT_IS_UINT_MAX");

    /* Fail if repayBorrow fails */
    uint256 actualRepayAmount = repayBorrowFresh(
      liquidator,
      borrower,
      repayAmount
    );

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /* We calculate the number of collateral tokens that will be seized */
    (bool success, bytes memory ret) = address(riskEngine).call(
      abi.encodeWithSignature(
        "liquidateCalculateSeizeTokens(address,uint256)",
        address(pTokenCollateral),
        actualRepayAmount
      )
    );
    require(success, extractRevertReason(ret));
    uint256 seizeTokens = abi.decode(ret, (uint256));
    // uint256 seizeTokens = repayAmount;

    /* Revert if borrower collateral token balance < seizeTokens */
    require(
      pTokenCollateral.balanceOf(borrower) >= seizeTokens,
      "LIQUIDATE_SEIZE_TOO_MUCH"
    );

    pTokenCollateral.seize(liquidator, borrower, seizeTokens);

    /* We emit a LiquidateBorrow event */
    emit LiquidateBorrow(
      liquidator,
      borrower,
      actualRepayAmount,
      address(pTokenCollateral),
      seizeTokens
    );

    /* We call the defense hook */
    // unused function
    // comptroller.liquidateBorrowVerify(address(this), address(pTokenCollateral), liquidator, borrower, actualRepayAmount, seizeTokens);

    actualRepayAmount;
    return true;
  }

  /**
   * @notice Applies accrued interest to total borrows and reserves
   * @dev This calculates interest accrued from the last checkpointed block
   *   up to the current block and writes new checkpoint to storage.
   */
  function accrueInterest() public override {
    /* Remember the previous accrual block number */
    uint256 accrualBlockNumberPrior = accrualBlockNumber;

    /* Short-circuit accumulating 0 interest */
    if (accrualBlockNumberPrior == block.number) return;

    /* Read the previous values out of storage */
    // uint cashPrior = getCashPrior();
    uint256 borrowsPrior = totalBorrows;
    // TODO Deal with Reserves
    // uint reservesPrior = totalReserves;
    uint256 borrowIndexPrior = borrowIndex;

    /* Calculate the current borrow interest rate */
    // TODO interest rate model - set to 0.0002% per block for now
    uint256 borrowRate = interestRateModel.setBorrowRate();
    require(borrowRate <= borrowRateMax, "borrow rate is absurdly high");

    /* Calculate the number of blocks elapsed since the last accrual */
    require(
      block.number >= accrualBlockNumberPrior,
      "Cannot calculate data"
    );
    uint256 blockDelta = block.number - accrualBlockNumberPrior;

    /*
     * Calculate the interest accumulated into borrows and reserves and the new index:
     *  simpleInterestFactor = borrowRate * blockDelta
     *  interestAccumulated = simpleInterestFactor * totalBorrows
     *  totalBorrowsNew = interestAccumulated + totalBorrows
     *  totalReservesNew = interestAccumulated * reserveFactor + totalReserves
     *  borrowIndexNew = simpleInterestFactor * borrowIndex + borrowIndex
     */

    uint256 simpleInterestFactor;
    uint256 interestAccumulated;
    uint256 totalBorrowsNew;
    // uint totalReservesNew;
    uint256 borrowIndexNew;

    simpleInterestFactor = borrowRate * blockDelta;

    uint256 multiplier = 10**PUSDAddress.decimals();

    interestAccumulated = (simpleInterestFactor * borrowsPrior) / multiplier;

    totalBorrowsNew = interestAccumulated + borrowsPrior;

    // (mathErr, totalReservesNew) = mulScalarTruncateAddUInt(Exp({mantissa: reserveFactorMantissa}), interestAccumulated, reservesPrior);
    // if (mathErr != MathError.NO_ERROR) {
    //     return failOpaque(Error.MATH_ERROR, FailureInfo.ACCRUE_INTEREST_NEW_TOTAL_RESERVES_CALCULATION_FAILED, uint(mathErr));
    // }

    borrowIndexNew =
      (simpleInterestFactor * borrowIndexPrior) /
      multiplier +
      borrowIndexPrior;

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /* We write the previously calculated values into storage */
    accrualBlockNumber = block.number;
    borrowIndex = borrowIndexNew;
    totalBorrows = totalBorrowsNew;
    // totalReserves = totalReservesNew;

    /* We emit an AccrueInterest event */
    emit AccrueInterest(interestAccumulated, borrowIndexNew, totalBorrowsNew);

    return;
  }

  function getBalance(address borrower) public view returns (uint256) {
    BorrowLocalVars memory vars;
    vars.accountBorrows = borrowBalanceStoredInternal(borrower);
    return vars.accountBorrows;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PUSD is ERC20, ERC20Burnable {
    constructor() ERC20("Prime USD", "PUSD") {
        admin = msg.sender;
    }

    address treasuryAddress;
    address loanAgentAddress;
    address admin;

    modifier onlyAdmin {
        require(msg.sender == treasuryAddress || msg.sender == loanAgentAddress || msg.sender == admin, "Unauthorized minter");
        _;
    }

    // TODO: we need to make ownership transferrable in the future
    modifier onlyOwner {
        require(msg.sender == admin);
        _;
    }

    function setOwner(address _owner) public onlyOwner {
        admin = _owner;
    }

    function setTreasury(address _treasuryAddress) public onlyOwner {
        treasuryAddress = _treasuryAddress;
    }

    function setLoanAgent(address _loanAgentAddress) public onlyOwner {
        loanAgentAddress = _loanAgentAddress;
    }

    function mint(address to, uint256 amount) public onlyAdmin {        
        _mint(to, amount);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "./RiskEngineStorage.sol";

abstract contract RiskEngineInterface {
    /// @notice Indicator that this is a RiskEngine contract
    bool public constant isRiskEngine = true;

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata pTokens) virtual external returns (bool[] memory r);
    function exitMarket(address pToken) virtual external returns (bool);

    // /*** Policy Hooks ***/

    function mintAllowed(address pToken, address minter, uint mintAmount) virtual external returns (bool);
    //function mintVerify(address pToken, address minter, uint mintAmount, uint mintTokens) virtual external;

    function redeemAllowed(address pToken, address redeemer, uint redeemTokens) virtual external returns (bool);
    function redeemVerify(address pToken, address redeemer, uint redeemAmount, uint redeemTokens) virtual external;

    function borrowAllowed(address pToken, address borrower, uint borrowAmount) virtual external returns (bool);
    //function borrowVerify(address pToken, address borrower, uint borrowAmount) virtual external;

    function repayBorrowAllowed(
        address pToken,
        address payer,
        address borrower,
        uint repayAmount) virtual external returns (bool);
    // function repayBorrowVerify(
    //     address pToken,
    //     address payer,
    //     address borrower,
    //     uint repayAmount,
    //     uint borrowerIndex) virtual external;

    function liquidateBorrowAllowed(
        address pTokenBorrowed,
        address pTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) virtual external returns (bool);
    // function liquidateBorrowVerify(
    //     address pTokenBorrowed,
    //     address pTokenCollateral,
    //     address liquidator,
    //     address borrower,
    //     uint repayAmount,
    //     uint seizeTokens) virtual external;

    function seizeAllowed(
        address pTokenCollateral,
        address pTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) virtual external returns (bool);
    // function seizeVerify(
    //     address pTokenCollateral,
    //     address pTokenBorrowed,
    //     address liquidator,
    //     address borrower,
    //     uint seizeTokens) virtual external;

    function transferAllowed(
        address pToken,
        address src,
        address dst,
        uint transferTokens
    ) virtual external returns (bool);
    // function transferVerify(address pToken, address src, address dst, uint transferTokens) virtual external;

    // /*** Liquidity/Liquidation Calculations ***/

    // function liquidateCalculateSeizeTokens(
    //     address pTokenBorrowed,
    //     address pTokenCollateral,
    //     uint repayAmount) virtual external view returns (uint, uint);

    //Extention to the original prime comptroller interface
    //function checkMembership(address account, PToken pToken) external virtual view returns (bool);

    //function updatePTokenVersion(address pToken, RiskEngineStorage.Version version) virtual external;

    // function flashloanAllowed(
    //     address pToken,
    //     address receiver,
    //     uint256 amount,
    //     bytes calldata params
    // ) external virtual view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private reentrancyStatus = 1;

    modifier nonReentrant() {
        require(reentrancyStatus == 1, "REENTRANCY");

        reentrancyStatus = 2;

        _;

        reentrancyStatus = 1;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "../PUSD.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../RiskEngine.sol";
import "./PTokenInterface.sol";


contract LoanAgentStorage {

    PUSD public PUSDAddress;

    RiskEngineInterface public riskEngine;

    /**
     * @notice Fraction of interest currently set aside for reserves
     */
    uint public reserveFactor;

    /**
     * @notice Block number that interest was last accrued at
     */
    uint public accrualBlockNumber;

    /**
     * @notice Interest rate model
     */
    InterestRateModel public interestRateModel;

    /**
     * @notice Accumulator of the total earned interest rate since the opening of the market
     */
    uint public borrowIndex; // TODO - needs initialized

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    uint public totalBorrows;

    /**
     * @notice Maximum borrow rate that can ever be applied (.0005% / block)
     */

    uint internal constant borrowRateMax = 0.0005e16;

    /**
     * @notice Maximum fraction of interest that can be set aside for reserves
     */
    uint internal constant reserveFactorMax = 1e18;

    /**
     * @notice Container for borrow balance information
     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint principal;
        uint interestIndex;
    }

    /**
     * @notice Mapping of account addresses to outstanding borrow balances
     */
    mapping(address => BorrowSnapshot) internal accountBorrows;

    /**
     * @notice Share of seized collateral that is added to reserves - need to decide if we want this here or on PToken
     */
    uint public constant protocolSeizeShare = 2.8e16; //2.8%

}

abstract contract LoanAgentInterface is LoanAgentStorage {

    /*** Market Events ***/
    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(uint interestAccumulated, uint borrowIndex, uint totalBorrows);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint borrowAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(address payer, address borrower, uint repayAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(address liquidator, address borrower, uint repayAmount, address cTokenCollateral, uint seizeTokens);

    /*** User Interface ***/

    function borrow(uint borrowAmount) virtual external returns (bool);
    function repayBorrow(uint repayAmount) virtual external returns (bool);
    function repayBorrowBehalf(address borrower, uint repayAmount) virtual external returns (bool);
    function liquidateBorrow(address borrower, uint repayAmount, PTokenInterface pTokenCollateral) virtual external returns (bool);
    function accrueInterest() virtual public;

    /*** Admin Functions ***/
    function setRiskEngine(RiskEngineInterface _RiskEngineAddress) virtual external;
    function setPUSD(PUSD _PUSDAddress) virtual external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import { InitialCollateralRatioModel } from "./InitialCollateralRatioModel.sol";
import "hardhat/console.sol";
/**
  * @title Prime's InterestRateModel Interface
  */
contract InterestRateModel {
    // @notice use block.timestamp to calculate interest rate in the future
    bool public constant isInterestRateModel = true;

    address admin;
    uint256 pusdPrice;

    //a value from 0% to 100%
    //user would be liq'd after one block at 100% borrow interest rate (i.e. 1e18)
    uint256 borrowInterestRatePerBlock;
    uint256 basisPointsTickSize;
    uint256 basisPointsUpperTick;
    uint256 basisPointsLowerTick;
    uint lastObservationTimestamp;
    uint observationPeriod;
    uint blocksPerYear;

    modifier onlyAdmin {
        require(msg.sender == admin, "Unauthorized user");
        _;
    }

    constructor(
    ) {
        admin = msg.sender;
        //this represents 2.5e16 or 2.5% interest rate per year
        //need to divide APR by number of blocks per year
        //5e16 = 5%
        uint256 borrowInterestRatePerYear = 25e15;
        //6400 blocks per day * 365 days
        blocksPerYear = 2336000;
        //2.5% APR divided by blocks per year
        borrowInterestRatePerBlock = borrowInterestRatePerYear / blocksPerYear;
        //6 decimal precision for 0.995
        pusdPrice = 995e3;
        //APR increment/decrement when price is under/over peg
        uint256 basisPointsTickSizePerYear = 1e14;
        basisPointsTickSize = basisPointsTickSizePerYear / blocksPerYear;

        uint256 basisPointsUpperTickPerYear = 5e16;
        basisPointsUpperTick = basisPointsUpperTickPerYear / blocksPerYear;

        basisPointsLowerTick = 0;

        observationPeriod = 0;
    }

    /**
      * @notice Calculates the current borrow interest rate per block
      * @return The borrow rate per block (as a percentage, and scaled by 1e18)
      */
      //simple bump function
      //what was the price an hour...where is it now
      //twap time horizon
      //has it been enough time
      // have a snapshot of price and block time
      // how long ago was that snapshot taken
      // an hour ago or longer increase or decrease the rate
      // replace the one in storage
    function getBorrowRate() external view returns (uint256){
      return borrowInterestRatePerBlock;
    }

    function getPusdPrice() external view returns (uint256){
      return pusdPrice;
    }

    function setBorrowRate() external returns (uint256) {

      uint elapsedTime = block.timestamp - lastObservationTimestamp;

      //setBorrowRate if enough time has elapsed
      if(elapsedTime <= observationPeriod){
        return borrowInterestRatePerBlock;
      }
      uint256 priorBorrowInterestRatePerBlock = borrowInterestRatePerBlock;
      // 1.00
      if( pusdPrice > 1e6){
        //1e18 = 100%
        //5e16 =   5%
        if(borrowInterestRatePerBlock < basisPointsUpperTick )
          //decrease 10 basis points if the price is high
          borrowInterestRatePerBlock -= basisPointsTickSize;
      }
      else if(pusdPrice < 1e6){
        if(borrowInterestRatePerBlock * blocksPerYear >= basisPointsTickSize )
          //increase 10 basis points if the price is low
          borrowInterestRatePerBlock += basisPointsTickSize;
      }
      lastObservationTimestamp = block.timestamp;
      return priorBorrowInterestRatePerBlock;
    }
    //one basis point equals 0.01% or 1e14; 10 is 0.1% or 1e15
    //increase 10 basis points if the price is low
    //decrease 10 basis points if the price is high
    //cap between 0% and 5%

    function setPusdPrice(uint256 price) external onlyAdmin {
      _setPusdPrice(price);
    }

    //TODO: this is a placeholder function for experimentation
    function _setPusdPrice(uint256 price) internal onlyAdmin {
      pusdPrice = price;
    }

    function setBasisPointsTickSize(
      uint256 _basisPointsTickSize
    ) external onlyAdmin {
      basisPointsTickSize = _basisPointsTickSize;
    }

    function setBasisPointsUpperTick(
      uint256 _basisPointsUpperTick
    ) external onlyAdmin {
      basisPointsUpperTick = _basisPointsUpperTick;
    }

    function setBasisPointsLowerTick(
      uint256 _basisPointsLowerTick
    ) external onlyAdmin {
      basisPointsLowerTick = _basisPointsLowerTick;
    }

    /**
        prior borrow rate
        prior observation time
        prior PUSD price
        PUSD price
        prior estimation of the demand curve
        probably some other things, tbd
     */


    /**
      * @notice Calculates the current supply interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @param reserveFactor The current reserve factor the market has
      * @return The supply rate per block (as a percentage, and scaled by 1e18)
      */
    //not sure we need this
    //function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactor) external virtual view returns (uint);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

/**
 * @title EIP20NonStandardInterface
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface EIP20NonStandardInterface {

    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transfer(address dst, uint256 amount) external;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transferFrom(address src, address dst, uint256 amount) external;

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved
      * @return success Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return remaining The number of tokens allowed to be spent
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "../PToken.sol";
import "../LoanAgent.sol";
import "./IPrimeOracle.sol";
import "../interfaces/IPriceOracle.sol";

contract UnitrollerAdminStorage {
  /**
   * @notice Administrator for this contract
   */
  address public admin;

  /**
   * @notice Pending administrator for this contract
   */
  address public pendingAdmin;

  /**
   * @notice Active brains of Unitroller
   */
  address public implementation;

  /**
   * @notice Pending brains of Unitroller
   */
  address public pendingImplementation;
}

contract RiskEngineStorage {
  /**
   * @notice Oracle which gives the price of any given asset
   */
  IPriceOracle public oracle;

  /**
   * @notice Multiplier used to calculate the maximum repayAmount when liquidating a borrow
   */
  // TODO: Revisit in future, hardcoded 50% closeFactor
  uint256 public closeFactor = 5e7;

  /**
   * @notice Multiplier representing the discount on collateral that a liquidator receives
   */
  uint256 public liquidationIncentive;

  /**
   * @notice Max number of assets a single account can participate in (use as collateral)
   */
  uint256 public maxAssets;

  /**
   * @notice Max number of assets a single account can participate in (borrow)
   */
  uint256 public maxBorrows;

  /**
   * @notice Per-account mapping of "assets you are in", capped by maxAssets
   */
  mapping(address => PToken[]) public accountAssets;

  /**
   * @notice Per-account mapping of "borrows you are in", capped by maxBorrows
   */
  mapping(address => LoanAgent[]) public accountBorrows;

  enum Version {
    VANILLA,
    COLLATERALCAP,
    WRAPPEDNATIVE
  }

  struct Market {
    /// @notice Whether or not this market is listed
    bool isListed;

    /**
     * @notice Multiplier representing the most one can borrow against their collateral in this market.
     *  For instance, 0.9 to allow borrowing 90% of collateral value.
     *  Must be between 0 and 1.
     */
    uint256 collateralFactor;
    /// @notice Per-market mapping of "accounts in this asset"
    mapping(address => bool) accountMembership;
    /// @notice Whether or not this market receives PRIME
    bool isPrimed;
    /// @notice PToken version
    Version version;
  }

  /**
   * @notice Official mapping of pTokens -> Market metadata
   * @dev Used e.g. to determine if a market is supported
   */
  mapping(address => Market) public markets;

  /**
   * @notice The Pause Guardian can pause certain actions as a safety mechanism.
   *  Actions which allow users to remove their own assets cannot be paused.
   *  Liquidation / seizing / transfer can only be paused globally, not by market.
   */
  address public pauseGuardian;
  bool public _mintGuardianPaused;
  bool public _borrowGuardianPaused;
  bool public transferGuardianPaused;
  bool public seizeGuardianPaused;
  mapping(address => bool) public mintGuardianPaused;
  // mapping(address => bool) public borrowGuardianPaused;

  struct PrimeMarketState {
    /// @notice The market's last updated primeBorrowIndex or primeSupplyIndex
    uint224 index;
    /// @notice The block number the index was last updated at
    uint32 block;
  }

  /// @notice A list of all deposit markets
  PToken[] public allMarkets;

  /// @notice the only borrow market
  LoanAgent public borrowMarket;

  /// @notice The portion of primeRate that each market currently receives
  mapping(address => uint256) public primeSpeeds;

  /// @notice The PRIME market supply state for each market
  mapping(address => PrimeMarketState) public primeSupplyState;

  /// @notice The PRIME market borrow state for each market (initially this will be a single market with one stablecoin)
  mapping(address => PrimeMarketState) public primeBorrowState;

  /// @notice The PRIME borrow index for each market for each supplier as of the last time they accrued PRIME
  mapping(address => mapping(address => uint256)) public primeSupplierIndex;

  /// @notice The PRIME borrow index for each market for each borrower as of the last time they accrued PRIME
  mapping(address => mapping(address => uint256)) public primeBorrowerIndex;

  /// @notice The PRIME accrued but not yet transferred to each user
  mapping(address => uint256) public primeAccrued;

  // @notice The borrowCapGuardian can set borrowCaps to any number for any market. Lowering the borrow cap could disable borrowing on the given market.
  address public borrowCapGuardian;

  // @notice Borrow caps enforced by borrowAllowed. Defaults to zero which corresponds to unlimited borrowing.
  uint256 public borrowCap;

  // @notice The supplyCapGuardian can set supplyCaps to any number for any market. Lowering the supply cap could disable supplying to the given market.
  address public supplyCapGuardian;

  // @notice Supply caps enforced by mintAllowed for each pToken address. Defaults to zero which corresponds to unlimited supplying.
  mapping(address => uint256) public supplyCaps;

  // @notice flashloanGuardianPaused can pause flash loan as a safety mechanism.
  mapping(address => bool) public flashloanGuardianPaused;

  /// @notice liquidityMining the liquidity mining module that handles the LM rewards distribution.
  address public liquidityMining;

  /// @notice The rate at which the flywheel distributes PRIME, per block
  uint256 public primeRate;

  /// @notice The portion of PRIME that each contributor receives per block
  mapping(address => uint256) public primeContributorSpeeds;

  /// @notice Last block at which a contributor's PRIME rewards have been allocated
  mapping(address => uint256) public lastContributorBlock;

  /// @notice The rate at which prime is distributed to the corresponding borrow market (per block)
  mapping(address => uint256) public primeBorrowSpeeds;

  /// @notice The rate at which prime is distributed to the corresponding supply market (per block)
  mapping(address => uint256) public primeSupplySpeeds;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import {IPrimeOracleGetter} from "./IPrimeOracleGetter.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title IPrimeOracle
 * @author Prime
 * @notice The core interface for the Prime Oracle
 */
interface IPrimeOracle is IPrimeOracleGetter {

  /**
   * @dev Emitted after the price data feed of an asset is updated
   * @param asset The address of the asset
   * @param feed The price feed of the asset
   */
  event AssetFeedUpdated(IERC20 indexed asset, address indexed feed);

  /**
   * @dev Emitted after the denom currency is set
   * @param denomCurrency The denom currency used for price quotes
   * @param denomCurrencyUnit The unit of the denom currency (1e8 for USD)
   */
  event DenomCurrencySet(address indexed denomCurrency, uint256 denomCurrencyUnit);

  /**
   * @dev Emitted after the address of twap oracle is updated
   * @param twapOracle The address of the twap oracle
   */
  event TwapOracleUpdated(address indexed twapOracle);


  /**
   * @notice Sets or replaces price feeds of assets
   * @param assets The addresses of the assets
   * @param feeds The addresses of the price feeds
   */
  function setAssetFeeds(IERC20[] calldata assets, address[] calldata feeds) external;

  /**
   * @notice Sets the twap oracle
   * @param twapOracle The address of the twap oracle
   */
  function setTwapOracle(address twapOracle) external;

  /**
   * @notice Returns a list of prices from a list of assets addresses
   * @param assets The list of assets addresses
   * @return The prices of the given assets
   */
  function getAssetPrices(IERC20[] calldata assets) external view returns (uint256[] memory);

  /**
   * @notice Returns the address of the price feed for an asset address
   * @param asset The address of the asset
   * @return The address of the price feed
   */
  function getFeedOfAsset(IERC20 asset) external view returns (address);

  /**
   * @notice Returns the address of the twap oracle
   * @return The address of the twap oracle
   */
  function getTwapOracle() external view returns (address);
  
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "../PToken.sol";
import "../LoanAgent.sol";

interface IPriceOracle {
    /**
     * @notice Get the underlying price of a cToken asset
     * @param pToken The pToken to get the underlying price of
     * @return The underlying asset price.
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPrice(PToken pToken) external view returns (uint256);

    /**
     * @notice Get the underlying price of a cToken asset
     * @param loanAgent The pToken to get the underlying price of
     * @return The underlying asset price.
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPriceBorrow(LoanAgent loanAgent) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// Chainlink Contracts v0.8
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


/**
 * @title IPrimeOracleGetter
 * @author Prime
 * @notice Interface for the Prime price oracle.
 **/
interface IPrimeOracleGetter {

  /**
   * @notice Returns the price data in the denom currency
   * @param asset The address of the asset
   * @return return price of the asset from the oracle
   **/
  function getAssetPrice(IERC20 asset) external view returns (uint256);

  /**
   * @notice Returns the address for the denomination currency
   * @dev For USD, the address should be set to 0x0.
   * @return Returns the denomination currency address.
   **/
  function getDenomCurrency() external view returns (address);

  /**
   * @notice Returns the denom currency unit
   * @dev 1e8 for USD, 1 ether for ETH.
   * @return Returns the denom currency unit.
   **/
  function getDenomCurrencyUnit() external view returns (uint256);

  
}