// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "IStablePlaza.sol";
import "IStakingContract.sol";
import "IStablePlazaAddCallee.sol";
import "IStablePlazaSwapCallee.sol";
import "IStablePlazaRemoveCallee.sol";
import "Ownable.sol";
import "ERC20.sol";
import "IERC20.sol";
import "SafeERC20.sol";
import "ERC20Burnable.sol";
import "IERC20Metadata.sol";

contract StablePlaza is IStablePlaza, IStakingContract, Ownable, ERC20Burnable {
  using SafeERC20 for IERC20;

  // constants
  uint8 constant BASE_DECIMALS = 6;                 // decimals used for all USD based tokens and the LP token itself
  uint256 constant NR_OF_TOKENS = 4;                // the amount of tokens listed on the exchange
  uint16 constant TRADE_LOCK_MASK = 0x0001;         // bitmask - 1st bit is used to indicate trade is in progress
  uint16 constant ADMIN_LOCK_MASK = 0x0002;         // bitmask - 2nd bit is used to indicate admin lock is active
  uint16 constant ADMIN_UNLOCK_MASK = 0xFFFD;       // bitmask - inverse of admin lock mask
  uint64 constant MIN_SHARES = 232830643653;        // initial amount of shares belonging to nobody to ensure adequate scaling (1000 DFP2 equivalent)
  uint256 constant LP_FACTOR_ADD = 201_000_000;     // factor to get from real LPs to virtual LPs for liquidity add (201)
  uint256 constant LP_FACTOR_REMOVE = 202_493_812;  // factor to get from real LPs to virtual LPs for liquidity remove (~202.49)
  uint256 constant NORMALIZE_FACTOR = 1_000_000;    // normalization factor for the LP_FACTORS
  uint256 constant SECONDS_PER_DAY = 86400;         // the number of seconds in a day

  // immutables
  IERC20 public immutable stakingToken;             // token that is accepted as stake

  // contract state variables
  Token[NR_OF_TOKENS] public tokens;                // tokens listed on the exchange
  uint64[NR_OF_TOKENS] public reserves;             // scaled reserves of listed tokens
  uint64[NR_OF_TOKENS] public denormFactors;        // (de)normalization factors to get to 6 decimals
  mapping(address => StakerData) public stakerData; // data per staker
  mapping(IERC20 => uint256) private offsetIndex;   // helper variable to save gas on index collection
  address public admin;                             // admin with exchange (un)lock power

  Config public SPconfig = Config({
    locked: ADMIN_LOCK_MASK,            // 2nd bit is admin lock
    feeLevel: 3,                        // 3 out of 10000     --> 0.03% total fee
    flashLoanFeeLevel: 3,               // 3 out of 10000     --> 0.03% total fee
    stakerFeeFraction: 85,              // 85 out of 256      --> 0.01% stakers cut
    maxLockingBonus: 2,                 // factor of 2        --> 200% max bonus
    maxLockingTime: 180,                // max time           --> 180 days
    Delta: 0,                           // virtual liquidity  --> needs to be initialised
    unclaimedRewards: 1_000_000,        // 1$ of minimum liquidity belonging to nobody
    totalSupply: 0                      // Initialise withouth LP tokens
  });

  StakingState public stakingState = StakingState({
    totalShares: MIN_SHARES,            // Shares owned by nobody for adequate scaling
    rewardsPerShare: 0,                 // Start at zero rewards per share
    lastSyncedUnclaimedRewards: 0       // Start unsynced
  });

  /**
   * @notice Sets up exchange with the configuration of the listed tokens and the staking token.
   * @dev Initialize with ordered list of 4 token addresses.
   * Doesn't do any checks. Make sure you ONLY add well behaved ERC20s!! Does not support fee on transfer tokens.
   * @param tokensToList Ordered list of the 4 stable token addresses.
   * @param stakingTokenAddress Contract address of the ERC20 token that can be staked. Balance needs to fit in 96 bits.
   */
  constructor(IERC20[] memory tokensToList, IERC20 stakingTokenAddress) ERC20("StablePlaza", "XSP") {
    // Store the staking token address (DFP2 token is used here)
    stakingToken = stakingTokenAddress;

    // Configure the listed tokens
    uint64 d;
    IERC20 previous;
    IERC20 current;
    if (tokensToList.length != NR_OF_TOKENS) { revert(); } // dev: bad nr of tokens
    for (uint256 i; i < NR_OF_TOKENS; ) {
      // verify validity & collect data
      current = tokensToList[i];
      if (previous >= current) { revert(); } // dev: require ordered list
      d = uint64(10**(IERC20Metadata(address(current)).decimals() - BASE_DECIMALS));

      // write to storage
      denormFactors[i] = d;
      offsetIndex[current] = i + 1;
      Token storage t = tokens[i];
      t.token = current;
      t.denormFactor = d;

      // update iteration variables
      previous = current;
      unchecked { ++i; }
    }
  }

  // used for exchange (un)lock functions which may only be called by admin or owner
  modifier onlyAdmin() {
    if (msg.sender != admin && msg.sender != owner()) { revert AdminRightsRequired(); }
    _;
  }

  // LP tokens are scaled to 6 decimals which should suffice for USD based tokens
  function decimals() public view virtual override returns (uint8) { return BASE_DECIMALS; }

  /**
   * @inheritdoc IStablePlaza
   */
  function getIndex(IERC20 token) external view override returns (uint256 index)
  {
    index = offsetIndex[token];
    if (index == 0) { revert TokenNotFound(); }
    --index;
  }

  /**
   * @inheritdoc IStablePlaza
   */
  function getTokenFromIndex(uint256 index) external view override returns (IERC20 token)
  {
    token = tokens[index].token;
  }

  /**
   * @inheritdoc IStablePlaza
   */
  function getOutFromIn(
    uint256 inputIndex,
    uint256 outputIndex,
    uint256 inputAmount
  )
    public view override returns(uint256 maxOutputAmount)
  {
    // gather reserve data & calculate resulting output amount from constant product curve
    (uint256 R0, uint256 R1, uint256 d0, uint256 d1, Config memory c) = _getPairReservesAndConfig(inputIndex, outputIndex);
    uint256 oneMinusFee = 10_000 - c.feeLevel;
    uint256 Delta = uint256(c.Delta);

    inputAmount = inputAmount / d0;
    maxOutputAmount = oneMinusFee * inputAmount * (R1 + Delta) / ((R0 + Delta) * 10_000 + oneMinusFee * inputAmount) * d1;
    if (maxOutputAmount > R1 * d1) maxOutputAmount = R1 * d1;
  }

  /**
   * @inheritdoc IStablePlaza
   */
  function getInFromOut(
    uint256 inputIndex,
    uint256 outputIndex,
    uint256 outputAmount
  )
    public view override returns(uint256 minInputAmount)
  {
    // gather reserve data & calculate required input amount followin constant product cuve
    (uint256 R0, uint256 R1, uint256 d0, uint256 d1, Config memory c) = _getPairReservesAndConfig(inputIndex, outputIndex);

    outputAmount = (outputAmount - 1) / d1 + 1;
    if (outputAmount > R1) { revert InsufficientLiquidity(); }
    minInputAmount = ((R0 + c.Delta) * outputAmount * 10_000 / (((R1 + c.Delta) - outputAmount) * (10_000 - c.feeLevel)) + 1) * d0;
  }

  /**
   * @inheritdoc IStablePlaza
   */
  function getLPsFromInput(
    uint256 tokenIndex,
    uint256 inputAmount
  )
    public view override returns(uint256 maxLPamount)
  {
    // collect data reusing the function designed for swap data
    (uint256 R, uint256 d, Config memory c) = _getReservesAndConfig(tokenIndex);
    inputAmount = inputAmount / d;

    // Prevent excessive liquidity add, for which the approximations become bad.
    // At the limit, users can more than double existing liquidity.
    if (inputAmount >= R + c.Delta >> 5) { revert ExcessiveLiquidityInput(); }

    // See https://en.wikipedia.org/wiki/Binomial_series for the below algorithm
    // Computes the 6th power binomial series approximation of R.
    //
    //                 X   3 X^2   7 X^3   77 X^4   231 X^5   1463 X^6
    // (1+X)^1/4 - 1 ≈ - - ----- + ----- - ------ + ------- - --------
    //                 4    32      128     2048     8192      65536
    //
    // Note that we need to terminate at an even order to guarantee an underestimate
    // for safety. The approximation is accurate up to 10^-8.
    uint256 X = (inputAmount << 128) / (R + c.Delta);  // 0.128 bits
    uint256 X_ = X * X >> 128;                         // X**2  0.128 bits
    uint256 R_ = (X >> 2) - (X_ * 3 >> 5);             // R2    0.128 bits
    X_ = X_ * X >> 128;                                // X**3  0.128 bits
    R_ = R_ + (X_ * 7 >> 7);                           // R3    0.128 bits
    X_ = X_ * X >> 128;                                // X**4  0.128 bits
    R_ = R_ - (X_ * 77 >> 11);                         // R4    0.128 bits
    X_ = X_ * X >> 128;                                // X**5  0.128 bits
    R_ = R_ + (X_ * 231 >> 13);                        // R5    0.128 bits
    X_ = X_ * X >> 128;                                // X**6  0.128 bits
    R_ = R_ - (X_ * 1463 >> 16);                       // R6    0.128 bits

    // calculate maximum LP tokens to be generated
    maxLPamount = (R_ * LP_FACTOR_ADD * (totalSupply() + c.unclaimedRewards) / NORMALIZE_FACTOR) >> 128;
  }

  /**
   * @inheritdoc IStablePlaza
   */
  function getInputFromLPs(
    uint256 tokenIndex,
    uint256 LPamount,
    bool fromCallback
  )
    public view override returns(uint256 minInputAmount)
  {
    // collect data reusing the function designed for swap data
    uint256 F_ = 1 << 120;
    (uint256 R, uint256 d, Config memory c) = _getReservesAndConfig(tokenIndex);

    // check for out of bounds
    uint256 correction = fromCallback ? LPamount : 0;
    uint256 totalLPs = (totalSupply() - correction + c.unclaimedRewards) * LP_FACTOR_ADD / NORMALIZE_FACTOR;
    if (LPamount > totalLPs >> 6) { revert ExcessiveLiquidityInput(); }

    // raise (1+R) to the power of 4
    F_ += (LPamount << 120) / totalLPs;      // (1+R)        (2.120 bits)
    F_ = F_ * F_ >> 120;                     // (1+R)**2     (4.120 bits)
    F_ = F_ * F_ >> 120;                     // (1+R)**4     (8.120 bits)

    // calculate mimumum amount of input tokens corresponding to this amount of LPs
    minInputAmount = (((F_ - (1 << 120)) * (R + c.Delta) >> 120) + 1) * d;
  }

 /**
  * @inheritdoc IStablePlaza
  */
  function getOutputFromLPs(
    uint256 tokenIndex,
    uint256 LPamount
  )
    public view override returns(uint256 maxOutputAmount)
  {
    // collect required data
    uint256 F_ = 1 << 128;
    (uint256 R, uint256 d, Config memory c) = _getReservesAndConfig(tokenIndex);

    // calculates intermediate variable F = (1-R)^4 and then the resulting maximum output amount
    F_ -= (LPamount << 128) * NORMALIZE_FACTOR / (LP_FACTOR_REMOVE * (totalSupply() + c.unclaimedRewards));  // (1-R)      (0.128 bits)
    F_ = F_ * F_ >> 128;                                                                                     // (1-R)**2   (0.128 bits)
    F_ = F_ * F_ >> 128;                                                                                     // (1-R)**4   (0.128 bits)
    maxOutputAmount = (R + c.Delta) * ((1 << 128) - F_) >> 128;

    // apply clamping and scaling
    maxOutputAmount = maxOutputAmount > R ? R : maxOutputAmount;
    maxOutputAmount *= d;
  }

  /**
   * @inheritdoc IStablePlaza
   */
  function getLPsFromOutput(
    uint256 tokenIndex,
    uint256 outputAmount
  )
    public view override returns(uint256 minLPamount)
  {
    // collect data reusing the function designed for swap data
    (uint256 R, uint256 d, Config memory c) = _getReservesAndConfig(tokenIndex);
    outputAmount = (outputAmount - 1) / d + 1;
    if (outputAmount > R) { revert InsufficientLiquidity(); }

    // apply binomial series as in {getLPsFromInput} but now for value below 1
    uint256 X = (outputAmount << 128) / (R + c.Delta);  // X     0.128 bits
    uint256 X_ = X * X >> 128;                          // X**2  0.128 bits
    uint256 R_ = (X >> 2) + (X_ * 3 >> 5);              // R2    0.128 bits
    X_ = X_ * X >> 128;                                 // X**3  0.128 bits
    R_ = R_ + (X_ * 7 >> 7);                            // R3    0.128 bits
    X_ = X_ * X >> 128;                                 // X**4  0.128 bits
    R_ = R_ + (X_ * 77 >> 11);                          // R4    0.128 bits
    X_ = X_ * X >> 128;                                 // X**5  0.128 bits
    R_ = R_ + (X_ * 231 >> 13);                         // R5    0.128 bits
    X_ = X_ * X >> 128;                                 // X**6  0.128 bits
    R_ = R_ + (X_ * 1463 >> 16);                        // R6    0.128 bits

    // calculate minimum amount of LP tokens to be burnt
    minLPamount = (R_ * LP_FACTOR_REMOVE * (totalSupply() + c.unclaimedRewards) / NORMALIZE_FACTOR >> 128) + 1;
  }

  /**
   * @inheritdoc IStablePlaza
   */
  function easySwap(
    uint256 pairSelector,
    uint256 inputAmount,
    uint256 minOutputAmount,
    address destination
  )
    external override returns (uint256 actualOutputAmount)
  {
    // calculate actual amount of tokens that can be traded for the input tokens
    uint256 index0 = pairSelector & 0xFF;
    uint256 index1 = pairSelector >> 8;
    actualOutputAmount = getOutFromIn(index0, index1, inputAmount);
    if (actualOutputAmount < minOutputAmount) { revert InsufficientOutput(); }

    // pull in the input tokens and call low level swap function
    tokens[index0].token.safeTransferFrom(msg.sender, address(this), inputAmount);
    swap(pairSelector, actualOutputAmount, destination, new bytes(0));
  }

  /**
   * @inheritdoc IStablePlaza
   */
  function swap(
    uint256 pairSelector,
    uint256 outputAmount,
    address destination,
    bytes memory data
  )
    public override
  {
    // check that the exchange is unlocked and thus open for business
    Config memory c = SPconfig;
    if (c.locked != 0) { revert ExchangeLocked(); }
    SPconfig.locked = TRADE_LOCK_MASK;

    // gather data from storage
    SwapVariables memory v;
    uint256 index0 = pairSelector & 0xFF;
    uint256 index1 = pairSelector >> 8;
    v.token0 = tokens[index0];
    v.token1 = tokens[index1];
    uint256 allReserves;
    uint256 d0 = uint256(v.token0.denormFactor);
    assembly { allReserves := sload(reserves.slot) }

    // optimistically transfer token and callback if required
    v.token1.token.safeTransfer(destination, outputAmount);
    if (data.length != 0) {
      uint256 amountToPay = (index0 != index1) ? getInFromOut(index0, index1, outputAmount) : (((outputAmount - 1) / d0 + 1) * (c.flashLoanFeeLevel + 10_000) / 10_000) * d0;
      IStablePlazaSwapCallee(msg.sender).stablePlazaSwapCall(v.token1.token, outputAmount, v.token0.token, amountToPay, data);
    }

    { // calculate normalized reserves prior to the trade
      uint256 R0 = ((allReserves >> index0 * 64) & 0xFFFFFFFFFFFFFFFF);
      uint256 R1 = ((allReserves >> index1 * 64) & 0xFFFFFFFFFFFFFFFF);

      // check / calculate balances after the trade and calculate amount received
      v.balance0 = v.token0.token.balanceOf(address(this)) / d0;

      if (index1 == index0) { // repayment check for flashloan
        uint256 scaledOutputAmount = (outputAmount - 1) / d0 + 1;
        v.inputAmount = v.balance0 - (R0 - scaledOutputAmount);
        if (v.balance0 < R0 + scaledOutputAmount * c.flashLoanFeeLevel / 10_000) { revert InsufficientFlashloanRepayment(); }
      }
      else { // invariant check for token swap
        uint256 Delta = uint256(c.Delta);
        v.inputAmount = v.balance0 - R0;
        v.balance1 = R1 - ((outputAmount - 1) / v.token1.denormFactor + 1);
        uint256 B0 = (v.balance0 + Delta) * 10_000 - v.inputAmount * c.feeLevel;
        uint256 B1 = (v.balance1 + Delta);
        if (B0 * B1 < (R0 + Delta) * (R1 + Delta) * 10_000) { revert InvariantViolation(); }
      }
    }

    // update both token reserves with a single write to storage (token0 is second to capture flash loan balance)
    allReserves = (allReserves & (type(uint256).max - (0xFFFFFFFFFFFFFFFF << index1 * 64))) | ((v.balance1 & 0xFFFFFFFFFFFFFFFF) << index1 * 64);
    allReserves = (allReserves & (type(uint256).max - (0xFFFFFFFFFFFFFFFF << index0 * 64))) | ((v.balance0 & 0xFFFFFFFFFFFFFFFF) << index0 * 64);
    assembly { sstore(reserves.slot, allReserves) }

    // update other storage values
    SPconfig.unclaimedRewards = c.unclaimedRewards + uint64(v.inputAmount * c.feeLevel / 10_000 * c.stakerFeeFraction / 256);
    SPconfig.locked = 0;

    // update event log
    if (index1 == index0) { emit FlashLoan(msg.sender, v.token0.token, outputAmount, v.inputAmount * d0); }
    else { emit Swap(msg.sender, v.token0.token, v.token1.token, v.inputAmount * d0, outputAmount, destination); }
  }

  /**
   * @inheritdoc IStablePlaza
   */
  function easyAdd(
    uint256 tokenIndex,
    uint256 inputAmount,
    uint256 minLP,
    address destination
  )
    external override returns (uint256 actualLP)
  {
    // calculate LP tokens that can be generated from the input tokens
    actualLP = getLPsFromInput(tokenIndex, inputAmount);
    if (actualLP < minLP) { revert InsufficientOutput(); }

    // pull in tokens and call addLiquidity function
    tokens[tokenIndex].token.safeTransferFrom(msg.sender, address(this), inputAmount);
    addLiquidity(tokenIndex, actualLP, destination, new bytes(0));
  }

  /**
   * @inheritdoc IStablePlaza
   */
  function addLiquidity(
    uint256 tokenIndex,
    uint256 LPamount,
    address destination,
    bytes memory data
  )
    public override
  {
    // check that the exchange is unlocked and thus open for business
    Config memory c = SPconfig;
    if (c.locked != 0) { revert ExchangeLocked(); }
    SPconfig.locked = TRADE_LOCK_MASK;

    // collect all required data from storage
    uint256 allReserves;
    assembly { allReserves := sload(reserves.slot) }
    Token memory token = tokens[tokenIndex];
    uint256 R = ((allReserves >> tokenIndex * 64) & 0xFFFFFFFFFFFFFFFF);
    uint256 d = uint256(token.denormFactor);
    uint256 t = totalSupply();

    // optimistically mint tokens and call callback if requested
    _mint(destination, LPamount);
    if (data.length != 0) {
      uint256 amountToPay = getInputFromLPs(tokenIndex, LPamount, true);
      IStablePlazaAddCallee(msg.sender).stablePlazaAddCall(LPamount, token.token, amountToPay, data);
    }

    // lookup input token balance
    uint256 B = token.token.balanceOf(address(this)) / d;

    { // verify sufficient liquidity was added to pay for the requested LP tokens
      uint256 LP0_ = (t + c.unclaimedRewards) * LP_FACTOR_ADD / NORMALIZE_FACTOR;     // should still fit in 64 bits
      uint256 LP1_ = LP0_ + LPamount;                                                 // should still fit in 64 bits

      LP0_ = LP0_ * LP0_;                           // LP0**2 (fits in 128 bits)
      LP0_ = LP0_ * LP0_ >> 128;                    // LP0**4 (fits in 128 bits)
      LP1_ = LP1_ * LP1_;                           // LP1**2 (fits in 128 bits)
      LP1_ = LP1_ * LP1_ >> 128;                    // LP1**4 (fits in 128 bits)
      if ((B + c.Delta) * LP0_ < (R + c.Delta) * LP1_) { revert InvariantViolation(); }
    }

    // update reserves
    allReserves = (allReserves & (type(uint256).max - (0xFFFFFFFFFFFFFFFF << tokenIndex * 64))) | ((B & 0xFFFFFFFFFFFFFFFF) << tokenIndex * 64);
    assembly { sstore(reserves.slot, allReserves) }

    // update config state
    SPconfig.Delta = uint64(_calcDelta(allReserves));
    SPconfig.totalSupply = uint64(t + LPamount);
    SPconfig.locked = 0;

    // update event log
    emit LiquidityAdded(destination, token.token, (B - R) * d, LPamount);
  }

  /**
   * @inheritdoc IStablePlaza
   */
  function easyRemove(
    uint256 tokenIndex,
    uint256 LPamount,
    uint256 minOutputAmount,
    address destination
  )
    external override returns (uint256 actualOutput)
  {
    // calculate tokens that may be withdrawn with given LP amount
    actualOutput = getOutputFromLPs(tokenIndex, LPamount);
    if (actualOutput < minOutputAmount) { revert InsufficientOutput(); }

    // burns the LP tokens and call the remove liquidity function
    _burn(msg.sender, LPamount);
    removeLiquidity(tokenIndex, actualOutput, destination, new bytes(0));
  }

 /**
  * @inheritdoc IStablePlaza
  */
  function removeLiquidity(
    uint256 tokenIndex,
    uint256 outputAmount,
    address destination,
    bytes memory data
  )
    public override
  {
    // check that the exchange is unlocked and thus open for business
    Config memory c = SPconfig;
    if (c.locked & TRADE_LOCK_MASK != 0) { revert ExchangeLocked(); }
    SPconfig.locked = TRADE_LOCK_MASK;

    // optimistically transfer token and callback if required
    Token memory token = tokens[tokenIndex];
    token.token.safeTransfer(destination, outputAmount);
    if (data.length != 0) {
      uint256 LPtoBurn = getLPsFromOutput(tokenIndex, outputAmount);
      IStablePlazaRemoveCallee(msg.sender).stablePlazaRemoveCall(token.token, outputAmount, LPtoBurn, data);
    }

    // gather all data needed in calculations
    uint256 allReserves;
    assembly { allReserves := sload(reserves.slot) }
    uint256 R = ((allReserves >> tokenIndex * 64) & 0xFFFFFFFFFFFFFFFF);
    uint256 d = uint256(token.denormFactor);
    uint256 LPtokens = totalSupply();
    uint256 previousSupply = uint256(c.totalSupply);

    // normalize outputAmount to 6 decimals, rounding up
    outputAmount = (outputAmount - 1) / d + 1;

    { // verify sufficient liquidity was added to pay for the requested LP tokens
      uint256 Delta = uint256(c.Delta);
      uint256 LP0_ = (previousSupply + c.unclaimedRewards) * LP_FACTOR_REMOVE / NORMALIZE_FACTOR;  // should still fit in 64 bits
      uint256 LP1_ = LP0_ + LPtokens - previousSupply;                                             // should still fit in 64 bits

      LP0_ = LP0_ * LP0_;                     // LP0**2 (fits in 128 bits)
      LP0_ = LP0_ * LP0_ >> 128;              // LP0**4 (fits in 128 bits)
      LP1_ = LP1_ * LP1_;                     // LP1**2 (fits in 128 bits)
      LP1_ = LP1_ * LP1_ >> 128;              // LP1**4 (fits in 128 bits)
      if ((R - outputAmount + Delta) * LP0_ < (R + Delta) * LP1_) { revert InvariantViolation(); }
    }

    // update exchange reserves
    allReserves = (allReserves & (type(uint256).max - (0xFFFFFFFFFFFFFFFF << tokenIndex * 64))) | (((R - outputAmount) & 0xFFFFFFFFFFFFFFFF) << tokenIndex * 64);
    assembly { sstore(reserves.slot, allReserves) }

    // update other state variables
    SPconfig.Delta = uint64(_calcDelta(allReserves));
    SPconfig.totalSupply = uint64(LPtokens);
    SPconfig.locked = 0;

    // update event log
    emit LiquidityRemoved(msg.sender, token.token, outputAmount * d, previousSupply - LPtokens);
  }

  /**
   * @inheritdoc IStakingContract
   */
  function stake(
    uint256 amountToStake,
    uint32 voluntaryLockupTime
  )
    external override
  {
    // collect tokens
    if (amountToStake == 0) { revert ZeroStakeAdditionIsNotSupported(); }
    stakingToken.safeTransferFrom(msg.sender, address(this), amountToStake);

    // gather data for calculations
    Config memory c = SPconfig;
    StakingState memory s = stakingState;
    StakerData memory d = stakerData[msg.sender];

    // sync unlaimed rewards and claim if an active stake is already present
    uint256 unsyncedRewards = uint256(c.unclaimedRewards) - s.lastSyncedUnclaimedRewards;
    s.rewardsPerShare += uint96((unsyncedRewards << 80) / s.totalShares);
    if (d.stakedAmount != 0) { unstake(0); }

    // calculate equivalent shares and apply clamping
    uint256 maxLockTime = uint256(c.maxLockingTime) * SECONDS_PER_DAY;
    uint256 lockupTime = voluntaryLockupTime > maxLockTime ? maxLockTime : voluntaryLockupTime;
    uint64 sharesEq = uint64((amountToStake >> 32) * ((1 << 32) + uint256(c.maxLockingBonus) * lockupTime * lockupTime * (1 << 32) / (maxLockTime * maxLockTime)) >> 32);
    uint32 unlockTime = d.unlockTime > uint32(block.timestamp + lockupTime) ? d.unlockTime : uint32(block.timestamp + lockupTime);

    // write new staker data to storage
    StakerData storage D = stakerData[msg.sender];
    D.stakedAmount = d.stakedAmount + uint64(amountToStake >> 32);     // This covers all DFP2 ever in circulation
    D.sharesEquivalent = d.sharesEquivalent + sharesEq;                // Includes bonus for locking liquidity
    D.rewardsPerShareWhenStaked = s.rewardsPerShare;                   // Sync with global rewards counter
    D.unlockTime = unlockTime;                                         // When we can unstake again

    // write updated global staking state to storage
    s.totalShares += sharesEq;
    s.lastSyncedUnclaimedRewards = c.unclaimedRewards;
    stakingState = s;

    // update event log
    emit Staked(msg.sender, amountToStake, sharesEq);
  }

  /**
   * @inheritdoc IStakingContract
   */
  function unstake(
    uint256 amountToUnstake
  )
    public override
  {
    // gather required data & check unstake is allowed
    Config memory c = SPconfig;
    StakingState memory s = stakingState;
    StakerData memory d = stakerData[msg.sender];
    if (amountToUnstake != 0 && block.timestamp < d.unlockTime) { revert StakeIsStillLocked(); }

    // gather unclaimed rewards and calculate global rewards per share and rewards for the caller
    uint256 newRewards = uint256(c.unclaimedRewards) - s.lastSyncedUnclaimedRewards;
    s.rewardsPerShare += uint96((newRewards << 80) / s.totalShares);
    uint256 rewards = uint256(s.rewardsPerShare - d.rewardsPerShareWhenStaked) * d.sharesEquivalent >> 80;

    // update reward related states and write unclaimed rewards to storage
    d.rewardsPerShareWhenStaked = s.rewardsPerShare;
    c.unclaimedRewards -= uint64(rewards);
    s.lastSyncedUnclaimedRewards = c.unclaimedRewards;
    SPconfig.unclaimedRewards = c.unclaimedRewards;

    uint64 sharesDestroyed;
    if (amountToUnstake != 0) {
      // calculate remaining & destroyed stake/shares based on average bonus
      uint256 bonus = (uint256(d.sharesEquivalent) << 64) / d.stakedAmount;
      uint256 remainder = ((uint256(d.stakedAmount) << 32) - amountToUnstake) >> 32;
      uint256 sharesRemainder = remainder * bonus >> 64;
      sharesDestroyed = d.sharesEquivalent - uint64(sharesRemainder);

      // update stake / share related state
      s.totalShares -= sharesDestroyed;
      d.stakedAmount = uint64(remainder);
      d.sharesEquivalent = uint64(sharesRemainder);

      // transfer tokens
      stakingToken.safeTransfer(msg.sender, amountToUnstake);
    }

    // write updated user data and global staking state to storage
    stakingState = s;
    if (d.stakedAmount == 0) { delete stakerData[msg.sender]; }
    else { stakerData[msg.sender] = d; }

    // mint rewards
    _mint(msg.sender, rewards);

    // update event log
    emit Unstaked(msg.sender, amountToUnstake, sharesDestroyed, rewards);
  }

  /**
   * @notice Sets exchange lock, under which swap and liquidity add (but not remove) are disabled.
   * @dev Can only be called by the admin of the contract.
   */
  function lockExchange() external onlyAdmin() {
    SPconfig.locked = SPconfig.locked | ADMIN_LOCK_MASK;
    emit LockChanged(msg.sender, SPconfig.locked);
  }

  /**
   * @notice Resets exchange lock.
   * @dev Can only be called by the admin of the contract.
   */
  function unlockExchange() external onlyAdmin() {
    SPconfig.locked = SPconfig.locked & ADMIN_UNLOCK_MASK;
    emit LockChanged(msg.sender, SPconfig.locked);
  }

 /**
  * @notice Change one token in the pool for another.
  * @dev Can only be called by the owner of the contract.
  * @param outgoingIndex Index of the token to be delisted from the exchange
  * @param incomingAddress Address of the token to be listed on the exchange
  */
  function changeListedToken(uint8 outgoingIndex, IERC20 incomingAddress)
  external onlyOwner()
  {
    if (reserves[outgoingIndex] != 0) { revert TokenReserveNotEmpty(); }
    IERC20 outgoingAddress = tokens[outgoingIndex].token;

    // build new token properties struct and store at correct index
    Token memory token;
    token.token = incomingAddress;
    token.denormFactor = uint64(10**(IERC20Metadata(address(incomingAddress)).decimals() - BASE_DECIMALS));
    denormFactors[outgoingIndex] = token.denormFactor;
    tokens[outgoingIndex] = token;

    // update offsetIndex helper variable
    delete offsetIndex[outgoingAddress];
    offsetIndex[incomingAddress] = outgoingIndex + 1;

    // update event log
    emit ListingChange(outgoingAddress, incomingAddress);
  }

  /**
   * @notice Sets admin address for emergency exchange locking.
   * @dev Can only be called by the owner of the contract.
   * @param adminAddress Address of the admin to set
   */
  function setAdmin(address adminAddress) external onlyOwner() {
    admin = adminAddress;
    emit AdminChanged(adminAddress);
  }

  /**
   * @notice Update configurable parameters of the contract.
   * @dev Can only be called by the owner of the contract.
   * @param newFeeLevel The new fee level to use for swaps / liquidity adds, as parts out of 10000 (max fee 2.55%)
   * @param newFlashLoanFeeLevel The new fee level to use for flashloans, as parts out of 10000 (max fee 2.55%)
   * @param newStakerFeeFraction The new cut of the fee for the stakers (parts out of 256)
   * @param newMaxLockingBonus The new bonus that can be achieved by staking longer
   * @param newMaxLockingTime The new time at which maximum bonus is achieved
   */
  function updateConfig(
    uint8 newFeeLevel,
    uint8 newFlashLoanFeeLevel,
    uint8 newStakerFeeFraction,
    uint8 newMaxLockingBonus,
    uint16 newMaxLockingTime
  ) external onlyOwner() {
    // load current config from storage and update relevant parameters
    Config storage C = SPconfig;
    C.feeLevel = newFeeLevel;
    C.flashLoanFeeLevel = newFlashLoanFeeLevel;
    C.stakerFeeFraction = newStakerFeeFraction;
    C.maxLockingBonus = newMaxLockingBonus;
    C.maxLockingTime = newMaxLockingTime;

    // update event log
    emit ConfigUpdated(newFeeLevel, newFlashLoanFeeLevel, newStakerFeeFraction, newMaxLockingBonus, newMaxLockingTime);
  }

  /**
   * @notice Initialise the contract.
   * @dev Can only be called once and can only be called by the owner of the contract.
   */
  function initialise() external onlyOwner() {
    if (SPconfig.Delta != 0) { revert(); } // dev: already initialised
    uint256 reserve;
    uint256 allReserves;
    uint256 toMint;
    for (uint256 i; i < NR_OF_TOKENS; ) {
      Token memory token = tokens[i];
      reserve = token.token.balanceOf(address(this)) / token.denormFactor;
      allReserves = (allReserves & (type(uint256).max - (0xFFFFFFFFFFFFFFFF << i * 64))) | ((reserve & 0xFFFFFFFFFFFFFFFF) << i * 64);
      toMint += reserve;
      unchecked { ++i; }
    }
    assembly { sstore(reserves.slot, allReserves) }
    SPconfig.Delta = uint64(_calcDelta(allReserves));
    SPconfig.totalSupply = uint64(toMint);
    _mint(msg.sender, toMint);
  }

  /**
   * @notice Calculate the virtual liquidity required to project onto desired curve.
   * @dev Used when liquidity is added or removed.
   */
  function _calcDelta(uint256 allReserves) internal pure returns (uint256 Delta) {
    for (uint256 i; i < NR_OF_TOKENS; ) {
      Delta += (allReserves >> i * 64) & 0xFFFFFFFFFFFFFFFF;
      unchecked { ++i; }
    }
    Delta = Delta * 50;
  }

  /**
   * @notice Returns the normalized reserves with denormFactors for a trading pair as well as exchange config struct.
   * @dev Helper function to retrieve parameters used in calculations in multiple places.
   */
  function _getPairReservesAndConfig(uint256 inputIndex, uint256 outputIndex)
  internal view returns (
    uint256 R0,
    uint256 R1,
    uint256 d0,
    uint256 d1,
    Config memory config )
  {
    // gather data
    config = SPconfig;
    uint256 allReserves;
    uint256 allDenormFactors;
    assembly { allReserves := sload(reserves.slot) }
    assembly { allDenormFactors := sload(denormFactors.slot) }

    // bitmask relevant reserves from storage slot
    R0 = (allReserves >> inputIndex * 64) & 0xFFFFFFFFFFFFFFFF;
    R1 = (allReserves >> outputIndex * 64) & 0xFFFFFFFFFFFFFFFF;

    // bitmask relevant denormFactors from storage slot
    d0 = (allDenormFactors >> inputIndex * 64) & 0xFFFFFFFFFFFFFFFF;
    d1 = (allDenormFactors >> outputIndex * 64) & 0xFFFFFFFFFFFFFFFF;
  }

  /**
   * @notice Calculates the normalized reserves for a trading pair and the oneMinusFee helper variable.
   * @dev Helper function to retrieve parameters used in calculations in multiple places.
   */
  function _getReservesAndConfig(uint256 tokenIndex)
  internal view returns (uint256 R, uint256 d, Config memory config) {
    R = reserves[tokenIndex];
    d = denormFactors[tokenIndex];
    config = SPconfig;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "IERC20.sol";

/**
 * @title StablePlaza exchange contract, a low-cost multi token DEX for stable coins.
 * @author Jazzer9F
 */
interface IStablePlaza {
  error TokenNotFound();                        // 0xcbdb7b30
  error ExchangeLocked();                       // 0x2903d20f
  error InsufficientOutput();                   // 0xbb2875c3
  error InvariantViolation();                   // 0x302e29cb
  error StakeIsStillLocked();                   // 0x828aa811
  error AdminRightsRequired();                  // 0x9c60c1ef
  error TokenReserveNotEmpty();                 // 0x51692a42
  error InsufficientLiquidity();                // 0xbb55fd27
  error ExcessiveLiquidityInput();              // 0x5bdb0437
  error InsufficientFlashloanRepayment();       // 0x56cc0682
  error ZeroStakeAdditionIsNotSupported();      // 0xa38d3034

  // exchange configuration
  struct Config {
    uint16 locked;                    // 1st bit is function lock, 2nd bit is admin lock (16 bits to align the rest properly)
    uint8 feeLevel;                   // parts out of 10000 levied as fee on swaps / liquidity add (max fee 2.55%)
    uint8 flashLoanFeeLevel;          // parts out of 10000 levied as fee on flash loans (max fee 2.55%)
    uint8 stakerFeeFraction;          // cut of the fee for the stakers (parts out of 256)
    uint8 maxLockingBonus;            // bonus that can be achieved by staking longer
    uint16 maxLockingTime;            // time at which maximum bonus is achieved [days]
    uint64 Delta;                     // virtual liquidity, projecting onto desired curve
    uint64 unclaimedRewards;          // liquidity rewards that have no owner yet
    uint64 totalSupply;               // copy of the totalSupply for flash removals
  }

  // listed token data
  struct Token {
    IERC20 token;                     // ERC20 contract address of listed token
    uint64 denormFactor;              // factor to scale as if it used 6 decimals
  }

  // used to group variables in swap function
  struct SwapVariables {              // struct keeping variables relevant to swap together
    Token token0;                     // token used as input into the swap
    Token token1;                     // token used as output of the swap
    uint256 balance0;                 // balance of input token
    uint256 balance1;                 // balance of output token
    uint256 inputAmount;              // amount of input token supplied into swap
  }

  // global staking variables squeezed in 256 bits
  struct StakingState {
    uint64 totalShares;                 // total staking shares issued currently
    uint96 rewardsPerShare;             // rewards accumulated per staked token (16.80 bits)
    uint64 lastSyncedUnclaimedRewards;  // unclaimed rewards at last (un)stake
  }

  // struct holding data for each staker
  struct StakerData {
    uint64 stakedAmount;                // amount of staked tokens belonging to this staker (times 2^32)
    uint64 sharesEquivalent;            // equivalent shares of stake (locking longer grants more shares)
    uint96 rewardsPerShareWhenStaked;   // baseline rewards when this stake began (16.80 bits)
    uint32 unlockTime;                  // timestamp when stake can be unstaked
  }

  /**
   * @notice Retrieve the index of a token in the pool.
   * @param token The address of the token to retrieve the index of
   * @return index The index of the token in the pool
   */
  function getIndex(IERC20 token) external view returns (uint256 index);

  /**
   * @notice Retrieve the token corresponding to a certain index.
   * @param index The index of the token in the pool
   * @return token The address of the token to retrieve the index of
   */
  function getTokenFromIndex(uint256 index) external view returns (IERC20 token);

  /**
   * @notice Calculates the maximum outputToken that can be asked for a certain amount of inputToken.
   * @param inputIndex The index of the inputToken on StablePlaza tokens array
   * @param outputIndex The index of the outputToken on StablePlaza tokens array
   * @param inputAmount The amount of inputToken to be used
   * @return maxOutputAmount The maximum amount of outputToken that can be asked for
   */
  function getOutFromIn(
    uint256 inputIndex,
    uint256 outputIndex,
    uint256 inputAmount
  ) external view returns(uint256 maxOutputAmount);

  /**
   * @notice Calculates the minimum input required to swap a certain output
   * @param inputIndex The index of the inputToken on StablePlaza tokens array
   * @param outputIndex The index of the outputToken on StablePlaza tokens array
   * @param outputAmount The amount of outputToken desired
   * @return minInputAmount The minimum amount of inputToken required
   */
  function getInFromOut(
    uint256 inputIndex,
    uint256 outputIndex,
    uint256 outputAmount
  ) external view returns(uint256 minInputAmount);

  /**
   * @notice Calculates the amount of LP tokens generated for given input amount
   * @param tokenIndex The index of the token in the reserves array
   * @param inputAmount The amount of the input token added as new liquidity
   * @return maxLPamount The maximum amount of LP tokens generated
   */
  function getLPsFromInput(
    uint256 tokenIndex,
    uint256 inputAmount
  ) external view returns(uint256 maxLPamount);

  /**
   * @notice Calculates the amount of input tokens required to generate a certain amount of LP tokens
   * @param tokenIndex The index of the token in the reserves array
   * @param LPamount The amount of LP tokens to be generated
   * @param fromCallback Set to true if this function is called from IStablePlazaAddCallee to compensate for preminted LPs
   * @return minInputAmount The minimum amount of input tokens required
   */
  function getInputFromLPs(
    uint256 tokenIndex,
    uint256 LPamount,
    bool fromCallback
  ) external view returns(uint256 minInputAmount);

  /**
   * @notice Calculates the amount tokens released when withdrawing a certain amount of LP tokens
   * @param tokenIndex The index of the token in the reserves array
   * @param LPamount The amount of LP tokens of the caller to be burnt
   * @return maxOutputAmount The amount of tokens that can be withdrawn for this amount of LP tokens
   */
  function getOutputFromLPs(
    uint256 tokenIndex,
    uint256 LPamount
  ) external view returns(uint256 maxOutputAmount);

  /**
   * @notice Calculates the amount of LP tokens required for to withdraw given amount of tokens
   * @param tokenIndex The index of the token in the reserves array
   * @param outputAmount The amount of tokens the caller wishes to receive
   * @return minLPamount The minimum amount of LP tokens required
   */
  function getLPsFromOutput(
    uint256 tokenIndex,
    uint256 outputAmount
  ) external view returns(uint256 minLPamount);

  /**
   * @notice Function to allow users to swap between any two tokens listed on the DEX. Confirms the trade meets the user requirements and then invokes {swap}.
   * @dev If the amount of output tokens falls below the `minOutputAmount` due to slippage, the swap will fail.
   * @param pairSelector The index of the input token + 256 times the index of the output token
   * @param inputAmount Amount of tokens inputed into the swap
   * @param minOutputAmount Minimum desired amount of output tokens
   * @param destination Address to send the amount of output tokens to
   * @return actualOutput The actual amount of output tokens send to the destination address
   */
  function easySwap(
    uint256 pairSelector,
    uint256 inputAmount,
    uint256 minOutputAmount,
    address destination
  ) external returns (uint256 actualOutput);

  /**
   * @notice Low level function to allow users to swap between any two tokens listed on the DEX. User needs to prepay or pay in the callback function. Does not protect against overpaying. For use in smart contracts which perform safety checks.
   * @dev Follows the constant product (x*y=k) swap invariant hyperbole with virtual liquidity.
   * @param pairSelector The index of the input token + 256 times the index of the output token
   * @param outputAmount Desired amount of output received from the swap
   * @param destination Address to send the amount of output output tokens to
   * @param data When not empty, swap callback function is invoked and this data array is passed through
   */
  function swap(
    uint256 pairSelector,
    uint256 outputAmount,
    address destination,
    bytes calldata data
  ) external;

  /**
   * @notice Single sided liquidity add which takes some tokens from the user, adds them to the liquidity pool and converts them into LP tokens.
   * @notice Adding followed by withdrawing incurs a penalty of ~0.74% when the exchange is in balance. The penalty can be mitigated or even be converted into a gain by adding to a token that is underrepresented and withdrawing from a token that is overrepresented in the exchange.
   * @dev Mathematically works like adding all tokens and swapping back to 1 token at no fee.
   *
   *         R = (1 + X_supplied/X_initial)^(1/4) - 1
   *         LP_minted = R * LP_total
   *
   * Adding liquidity incurs two forms of price impact.
   *   1. Impact from single sided add which is modeled with 3 internal swaps
   *   2. Impact from the numerical approximation required for calculation
   *
   * Price impact from swaps is limited to 1.5% in the most extreme cases, slippage due to approximation is in the order of 10-8.
   * @dev Takes payment and then invokes {addLiquidity}
   * @param tokenIndex Index of the token to be added
   * @param inputAmount Amount of input tokens to add to the pool
   * @param minLP Minimum accepted amount of LP tokens to receive in return
   * @param destination Address that LP tokens will be credited to
   * @return actualLP Actual amount of LP tokens received in return
   */
  function easyAdd(
    uint256 tokenIndex,
    uint256 inputAmount,
    uint256 minLP,
    address destination
  ) external returns (uint256 actualLP);

  /**
   * @notice Low level liquidity add function that assumes required token amount is already payed or payed in the callback.
   * @dev Doesn't protect the user from overpaying. Only for use in smart contracts which perform safety checks.
   * @param tokenIndex Index of the token to be added
   * @param LPamount Amount of liquidity tokens to be minted
   * @param destination Address that LP tokens will be credited to
   * @param data When not empty, addLiquidity callback function is invoked and this data array is passed through
   */
  function addLiquidity(
    uint256 tokenIndex,
    uint256 LPamount,
    address destination,
    bytes calldata data
  ) external;

  /**
   * @notice Single sided liquidity withdrawal.
   * @notice Adding followed by withdrawing incurs a penalty of ~0.74% when the exchange is in balance. The penalty can be mitigated or even be converted into a gain by adding to a token that is underrepresented and withdrawing from a token that is overrepresented in the exchange.
   * @dev Mathematically withdraws all 4 tokens in ratio and then swaps 3 back in at no fees.
   * Calculates the following:
   *
   *        R = LP_burnt / LP_initial
   *        X_out = X_initial * (1 - (1 - R)^4)
   *
   * No fee is applied for withdrawals.
   * @param tokenIndex Index of the token to be withdrawn, ranging from 0 to 3
   * @param LPamount Amount of LP tokens to exchange for the token to be withdrawn
   * @param minOutputAmount Minimum desired amount of tokens to receive in return
   * @param destination Address where the withdrawn liquidity is sent to
   * @return actualOutput Actual amount of tokens received in return
   */
  function easyRemove(
   uint256 tokenIndex,
   uint256 LPamount,
   uint256 minOutputAmount,
   address destination
  ) external returns (uint256 actualOutput);

  /**
   * @notice Low level liquidity remove function providing callback functionality. Doesn't protect the user from overpaying. Only for use in smart contracts which perform required calculations.
   * @param tokenIndex Index of the token to be withdrawn, ranging from 0 to 3
   * @param outputAmount Amount of tokens to be withdrawn from the pool
   * @param destination Address where the withdrawn liquidity is sent to
   * @param data Any data is passed through to the callback function
   */
  function removeLiquidity(
    uint256 tokenIndex,
    uint256 outputAmount,
    address destination,
    bytes calldata data
  ) external;

  /**
   * @notice Emit Swap event when tokens are swapped
   * @param sender Address of the caller
   * @param inputToken Input token of the swap
   * @param outputToken Output token of the swap
   * @param inputAmount Amount of input tokens inputed into the swap function
   * @param outputAmount Amount of output tokens received from the swap function
   * @param destination Address the amount of output tokens were sent to
   */
  event Swap(
    address sender,
    IERC20 inputToken,
    IERC20 outputToken,
    uint256 inputAmount,
    uint256 outputAmount,
    address destination
  );

  /**
   * @notice Emit Swap event when tokens are swapped
   * @param lender Address of the caller
   * @param token Token that was loaned out
   * @param amountLoaned The amount that was loaned out Output token of the swap
   * @param amountRepayed The amount that was repayed (includes fee)
   */
  event FlashLoan(
    address lender,
    IERC20 token,
    uint256 amountLoaned,
    uint256 amountRepayed
  );

  /**
   * @notice Emit LiquidityAdded event when liquidity is added
   * @param sender Address of the caller
   * @param token The token the liquidity was added in
   * @param tokenAmount Amount of tokens added
   * @param LPs Actual ammount of LP tokens minted
   */
  event LiquidityAdded(
    address sender,
    IERC20 token,
    uint256 tokenAmount,
    uint256 LPs
  );

  /**
   * @notice Emit LiquidityRemoved event when liquidity is removed
   * @param creditor Address of the entity withdrawing their liquidity
   * @param token The token the liquidity was removed from
   * @param tokenAmount Amount of tokens removed
   * @param LPs Actual ammount of LP tokens burned
   */
  event LiquidityRemoved(
    address creditor,
    IERC20 token,
    uint256 tokenAmount,
    uint256 LPs
  );

  /**
   * @notice Emit ListingChange event when listed tokens change
   * @param removedToken Token that used to be listed before this event
   * @param replacementToken Token that is listed from now on
   */
  event ListingChange(
    IERC20 removedToken,
    IERC20 replacementToken
  );

  /**
   * @notice Emit adminChanged event when the exchange admin address is changed
   * @param newAdmin Address of new admin, who can (un)lock the exchange
   */
  event AdminChanged(
    address newAdmin
  );

  /**
   * @notice Emit LockChanged event when the exchange is (un)locked by an admin
   * @param exchangeAdmin Address of the admin making the change
   * @param newLockValue The updated value of the lock variable
   */
  event LockChanged(
    address exchangeAdmin,
    uint256 newLockValue
  );

  /**
   * @notice Emit configUpdated event when parameters are changed
   * @param newFeeLevel Fee for swapping and adding liquidity (bps)
   * @param newFlashLoanFeeLevel Fee for flashloans (bps)
   * @param newStakerFeeFraction Fraction out of 256 of fee that is shared with stakers (-)
   * @param newMaxLockingBonus Maximum staker bonus for locking liquidity longer (-)
   * @param newMaxLockingTime Amount of time for which the maximum bonus is given (d)
   */
  event ConfigUpdated(
    uint8 newFeeLevel,
    uint8 newFlashLoanFeeLevel,
    uint8 newStakerFeeFraction,
    uint8 newMaxLockingBonus,
    uint16 newMaxLockingTime
  );
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
pragma solidity >=0.6.0;

/**
 * @title StablePlaza staking interface
 * @author Jazzer9F
 */
interface IStakingContract {

 /**
  * @notice Stake configured staking token to receive a split of the the trading fee in return.
  * @param amountToStake Amount of tokens to stake
  * @param voluntaryLockupTime A voluntary lockup period to receive a fee splitting bonus.
  * Please note that it is impossible to unstake before the `voluntaryLockupTime` has expired.
  */
  function stake(
    uint256 amountToStake,
    uint32 voluntaryLockupTime
  ) external;

 /**
  * @notice Unstake tokens that have previously been staked. Rewards are in LP tokens.
  * @dev Only possible if the optional `voluntaryLockupTime` has expired.
  * @param amountToUnstake Amount of tokens to unstake
  */
  function unstake(
    uint256 amountToUnstake
  ) external;

 /**
  * @notice Emit Staked event when new tokens are staked
  * @param staker Address of the caller
  * @param stakedAmount Amount of tokens staked
  * @param sharesEquivalent The amount of tokens staked plus any bonuses due to voluntary locking
  */
  event Staked(
    address staker,
    uint256 stakedAmount,
    uint64 sharesEquivalent
  );

 /**
  * @notice Emit Unstaked event when new tokens are unstaked
  * @param staker Address of the caller
  * @param unstakedAmount Amount of tokens unstaked
  * @param sharesDestroyed The amount of tokens unstaked plus any bonuses due to voluntary locking
  * @param rewards Staking rewards in LP tokens returned to the caller
  */
  event Unstaked(
    address staker,
    uint256 unstakedAmount,
    uint64 sharesDestroyed,
    uint256 rewards
  );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "IERC20.sol";

interface IStablePlazaAddCallee {
   /**
    * @notice Called to `msg.sender` after executing a swap via IStablePlaza#swap.
    * @dev By the end of this callback the tokens owed for the LP tokens should have been payed.
    * @param LPamount Amount of LP tokens credited to the requested address.
    * @param tokenToPay The token that should be used to pay for the LP tokens.
    * @param amountToPay The amount of tokens required to repay the exchange.
    * @param data Any data passed through by the caller via the IStablePlaza#addLiquidity call
    */
    function stablePlazaAddCall(uint256 LPamount, IERC20 tokenToPay, uint256 amountToPay, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "IERC20.sol";

interface IStablePlazaSwapCallee {
   /**
    * @notice Called to `msg.sender` after executing a swap via IStablePlaza#swap.
    * @dev By the end of this callback the tokens owed for the swap should have been payed.
    * @param outputToken The token that was credited to the requested destination.
    * @param outputAmount Amount of output tokens that was credited to the destination.
    * @param tokenToPay The token that should be used to pay for the trade.
    * @param amountToPay Minimum amount required to repay the exchange.
    * @param data Any data passed through by the caller via the IStablePlaza#swap call
    */
    function stablePlazaSwapCall(IERC20 outputToken, uint256 outputAmount, IERC20 tokenToPay, uint256 amountToPay, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "IERC20.sol";

interface IStablePlazaRemoveCallee {
   /**
    * @notice Called to `msg.sender` after executing a swap via IStablePlaza#swap.
    * @dev By the end of this callback the LP tokens owed should have been burnt.
    * @param outputToken The token that is credited to the caller.
    * @param outputAmount Amount of output tokens credited to the requested address.
    * @param LPtoBurn Amount of LP tokens that should be burnt to pay for the trade.
    * @param data Any data passed through by the caller via the IStablePlaza#addLiquidity call
    */
    function stablePlazaRemoveCall(IERC20 outputToken, uint256 outputAmount, uint256 LPtoBurn, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "ERC20.sol";
import "Context.sol";

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