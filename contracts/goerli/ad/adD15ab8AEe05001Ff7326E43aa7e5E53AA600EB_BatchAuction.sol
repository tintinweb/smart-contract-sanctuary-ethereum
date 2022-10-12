// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
pragma abicoder v2;

// import "hardhat/console.sol";

import "../interfaces/interfaces.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/*
TODO:
Notes:
*/

contract BatchAuction is Ownable, ReentrancyGuard {
  using SafeMath for uint128;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /// @notice the auction token for offering
  IERC20 private AUCTION_TOKEN;

  /// @notice the address that funds the token for the Auction
  address private AUCTION_TOKEN_VAULT;

  /// @notice where the auction funds will be transferred
  address payable private AUCTION_WALLET;

  /// @notice 
  address private AUCTION_TREASURY;

  /// @notice Amount of commitments per user
  mapping(address => uint256) private COMMITMENTS;

  /// @notice Accumulated amount of commitments per user
  mapping(address => uint256) private ACCUMULATED;

  /// @notice 
  mapping(address => uint256) private INSTANT_TOKEN_CLAIMED;

  /// @notice 
  mapping(address => uint256) private VESTED_BPT_CLAIMED;

  /// @notice to check user instantly claimed or not
  mapping(address => bool) private USER_RECEIVED_INSTANT_TOKENS;

  /// @notice Auction Data variable
  AuctionData public auctionData;

  /// @notice
  uint256 private constant PERCENT_DENOMINATOR = 10000;

  /// @notice Withdraw cap 
  /// TODO: comment
  uint256 private WITHDRAW_CAP_MIN_THRESHOLD;
  uint256 private WITHDRAW_CAP_MAX_THRESHOLD;
  uint256 private WITHDRAW_CAP_LIMIT;
  uint256 private WITHDRAW_CAP_INTERCEPT;
  uint256 private WITHDRAW_CAP_INTERCEPT_PLUS;
  uint8 private constant PRECISION = 18;

  /// @dev vesting period in second, 60 days => 5184000 seconds
  uint128 private VESTING_PERIOD;

  /// @dev token claim period in second, 90 days => 7776000 seconds
  uint128 private CLIAMABLE_PERIOD;

  /// @dev to check commit currency is ETH or ERC 20 token
  address private COMMIT_CURRENCY;

  /// @dev The placeholder ETH address.
  address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  // GOERLI
  address goerli_balancerValutAddress = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
  address goerli_weightedpoolfactory = 0x8E9aa87E45e92bad84D5F8DD1bff34Fb92637dE9;
  IBalancerVault private BALANCER_VAULT;
  address private constant BALANCER_ETH_ADDRESS = 0x0000000000000000000000000000000000000000;
  uint256 private constant BALANCER_POOL_WEIGHT_80 = 0.8e18; // 80%
  uint256 private constant BALANCER_POOL_WEIGHT_20 = 0.2e18; // 20%
  uint256 private constant BALANCER_POOL_SWAP_FEE_PERCENTAGE = 0.1e17; // 1%
  address private constant BALANCER_POOL_OWNER_ADDRESS = 0xBA1BA1ba1BA1bA1bA1Ba1BA1ba1BA1bA1ba1ba1B;
  uint256 private constant BALANCER_POOL_NUM_OF_TOKEN = 2;

  address public BALANCER_POOL_ADDRESS;
  IBalancerPool public BALANCER_BPT;
  uint256 public BALANCER_BPT_AMOUNT;
  bytes32 public BALANCER_POOL_ID;

  IWeightedPoolFactory public balancerWeightedPoolFactory;

  address public STAKING_CONTRACT_ADDRESS;

  // TODO DEV
  address private constant hotbody = 0xa488533be3018a0720C4c0647F407F3b41e6Cb82;
  address private constant WETH_ADDRESS = 0xdFCeA9088c8A88A76FF74892C1457C17dfeef9C1;
  address private constant USDC = 0xe0C9275E44Ea80eF17579d33c55136b7DA269aEb;

  bool public DEBUG = true;

  /* ========== EVENTS ========== */
  event AuctionConstructed(address _address);
  event AuctionInitialized(
    address indexed _commitCurrency,
    IERC20 indexed _token,
    address _tokenVault,
    uint128 _startTime,
    uint128 _endTime,
    uint256 _totalOfferingTokens,
    uint256 _minimumCommitmentAmount,
    address _treasury,
    address _wallet
  );
  event ETHCommitted(address indexed _user, uint256 _amount);
  event TokenCommitted(address indexed _user, uint256 _amount);
  event CommitmentAdded(address indexed _user, uint256 _amount);
  event InstantTokenClaimed(address indexed _user, uint256 _amount, uint256 _userCommitments);
  event VestedBPTClaimed(address indexed _user, uint256 _amount);
  event ETHWithdrawan(address indexed _user, uint256 _amount);
  event ERC20TokenWithdrawan(address indexed _user, uint256 _amount);
  event UnclaimedTokenWithdrawan(address indexed _treasury, uint256 _amount);
  event ClaimedCommitmentBack(address indexed _user, uint256 _amount);
  event AuctionTokenTransferredFromVault(address _vault, uint256 _amount);
  event AuctionCancelled();
  event AuctionFinalizedWithFailure(uint256 _totalOfferingTokens);
  event AuctionFinalizedWithSuccess(
    uint256 _transferAmount,
    uint256 _token80Amount,
    uint256 _token20Amount,
    uint256 _bptTokenAmount
  );
  event BalancerWeightedPoolCreatedAndJoined(
    string _poolSymbol,
    IAsset[] _tokens,
    uint256[] _weights,
    uint256[] _amountsIn,
    uint256 _fee,
    address _address,
    uint256 _bptAmount
  );
  event StakingContractAddressSet(address _addr);

  /* ========== TEMPORARY FUNCTIONS FOR DEV ========== */
  /* ========== TEMPORARY FUNCTIONS FOR DEV ========== */
  /* ========== TEMPORARY FUNCTIONS FOR DEV ========== */
  function set_dev_test_env() public {
    // GOERLI
    //setStakingContractAddress();
  }
  function changeDebugStatus(bool _debug) external {
    DEBUG = _debug;
  }
  function changeStartAndEndTime(uint128 _startTime, uint128 _endTime) external {
    auctionData.startTime = _startTime; auctionData.endTime = _endTime;
  }
  function changeWithdrawThresholds(uint256 _min, uint256 _max, uint256 _limit) external {
    WITHDRAW_CAP_MIN_THRESHOLD = _min;
    WITHDRAW_CAP_MAX_THRESHOLD = _max;
    WITHDRAW_CAP_LIMIT = _limit;
    WITHDRAW_CAP_INTERCEPT = 285714290000000000000;
    WITHDRAW_CAP_INTERCEPT_PLUS = 714285710000000000000;
  }
  function changeCommitmentCurrency(address _address) external {
    COMMIT_CURRENCY = _address;
  }
  function changePeriodsAsSecond(
    uint128 _claimablePeriod,
    uint128 _vestingPeriod
  ) external {
    CLIAMABLE_PERIOD = _claimablePeriod;
    VESTING_PERIOD = _vestingPeriod;
  }

  /* ========== end of TEMPORARY FUNCTIONS FOR DEV ========== */
  /* ========== end of TEMPORARY FUNCTIONS FOR DEV ========== */
  /* ========== end of TEMPORARY FUNCTIONS FOR DEV ========== */

  /* ========== CONSTRUCTOR ========== */
  constructor() {
    WITHDRAW_CAP_MIN_THRESHOLD = 0.0001 ether; // 1 ETH
    WITHDRAW_CAP_MAX_THRESHOLD = 0.0015 ether; // 15 ETH
    WITHDRAW_CAP_LIMIT = 1.5 ether; // 15 ETH
    WITHDRAW_CAP_INTERCEPT = 285714290000000000000;
    WITHDRAW_CAP_INTERCEPT_PLUS = 714285710000000000000;

    // GOERLI
    BALANCER_VAULT = IBalancerVault(goerli_balancerValutAddress);
    balancerWeightedPoolFactory = IWeightedPoolFactory(goerli_weightedpoolfactory);

    IERC20(hotbody).safeApprove(address(BALANCER_VAULT), 0);
    IERC20(hotbody).safeApprove(address(BALANCER_VAULT), type(uint256).max);
    IERC20(WETH_ADDRESS).safeApprove(address(BALANCER_VAULT), 0);
    IERC20(WETH_ADDRESS).safeApprove(address(BALANCER_VAULT), type(uint256).max);
    IERC20(USDC).safeApprove(address(BALANCER_VAULT), 0);
    IERC20(USDC).safeApprove(address(BALANCER_VAULT), type(uint256).max);

    emit AuctionConstructed(address(this));
  }

  function initAuction(
    address _commitCurrency,
    IERC20 _token,
    address _tokenVault,
    uint128 _startTime,
    uint128 _endTime,
    uint128 _vestingPeriod,
    uint128 _claimablePeriod,
    uint256 _totalOfferingTokens,
    uint256 _minimumCommitmentAmount,
    address _treasury,
    address payable _wallet
  ) external onlyOwner {
      // TODO
      // TODO
      // TODO
      //require(_startTime >= block.timestamp, "INVALID_AUCTION_START_TIME");
    require(_endTime > _startTime, "INVALID_AUCTION_END_TIME");
    require(_vestingPeriod > 0, "INVALID_VESTING_PERIOD");
    require(_claimablePeriod > 0, "INVALID_CLAIMABLE_PERIOD");
    require(_totalOfferingTokens > 0,"INVALID_TOTAL_OFFERING_TOKENS");
    require(_minimumCommitmentAmount > 0,"INVALID_MINIMUM_COMMITMENT_AMOUNT");
    require(_tokenVault != address(0), "INVALID_AUCTION_TOKEN_VAULT");
    require(_treasury != address(0), "INVALID_TREASURY_ADDRESS");
    require(_wallet != address(0), "INVALID_AUCTION_WALLET_ADDRESS");

    COMMIT_CURRENCY = _commitCurrency;

    AUCTION_TOKEN = _token;
    AUCTION_TOKEN_VAULT = _tokenVault;
    AUCTION_TREASURY = _treasury;
    AUCTION_WALLET = _wallet;

    VESTING_PERIOD = _vestingPeriod;
    CLIAMABLE_PERIOD = _claimablePeriod;

    auctionData.startTime = _startTime;
    auctionData.endTime = _endTime;
    auctionData.totalOfferingTokens = _totalOfferingTokens;
    auctionData.minCommitmentsAmount = _minimumCommitmentAmount;
    auctionData.finalized = false;
    auctionData.totalBPTAmount = 0;

    /// TODO: DEV REMOVE
    set_dev_test_env();

    emit AuctionInitialized(
      _commitCurrency,
      _token,
      _tokenVault,
      _startTime,
      _endTime,
      _totalOfferingTokens,
      _minimumCommitmentAmount,
      _treasury,
      _wallet
    );
  }

  /**
   * @notice Transfer Auction Token to this contract
   * @dev Only Owner can call this function
   */
  function transferAuctionTokenFromVault() external onlyOwner nonReentrant {
    uint256 amount = auctionData.totalOfferingTokens;
    require(amount > 0, 'INVALID_TOTAL_OFFERING_TOKENS');

    IERC20(AUCTION_TOKEN).safeTransferFrom(AUCTION_TOKEN_VAULT, address(this), amount);

    emit AuctionTokenTransferredFromVault(AUCTION_TOKEN_VAULT, amount);
  }

  // TODO: get auction token balance
  function getAuctionTokenBalance() public view returns (uint256) {
    require(address(AUCTION_TOKEN) != address(0), "INVALID_AUCTION_TOKEN");
    return IERC20(AUCTION_TOKEN).balanceOf(address(this));
  }

  /**
   * @notice Cancel Auction
   * @dev Only Owner can cancel the auction before it starts
   */
  function cancelAuctionBeforeStarts() external onlyOwner nonReentrant {
    require(!isAuctionFinalized(), "AUCTION_ALREADY_FINALIZED");
    require(auctionData.totalCommitments == 0, "AUCTION_HAS_COMMITMENTS");

    IERC20(AUCTION_TOKEN).safeTransfer(AUCTION_TOKEN_VAULT, auctionData.totalOfferingTokens);

    auctionData.finalized = true;

    emit AuctionCancelled();
  }

  /**
   * @notice Commit ETH
   */
  function commitETH() external payable {
    require(COMMIT_CURRENCY == ETH_ADDRESS, "COMMIT_CURRENCY_IS_NOT_ETH");

    addCommitment(msg.sender, msg.value);

    /// @dev Revert if totalCommitments exceeds the balance
    require(auctionData.totalCommitments <= address(this).balance, "INVALID_COMMITMENTS_TOTAL");

    emit ETHCommitted(msg.sender, msg.value);
  }

  /**
   * @notice Commit ERC20 Token
   */
  function commitERC20Token(uint256 _amount) private nonReentrant {
    require(COMMIT_CURRENCY != ETH_ADDRESS, "COMMIT_CURRENCY_IS_NOT_ERC20_TOKEN");

    addCommitment(msg.sender, _amount);

    IERC20(COMMIT_CURRENCY).safeTransferFrom(msg.sender, address(this), _amount);

    emit TokenCommitted(msg.sender, _amount);
  }

  function addCommitment(address _address, uint256 _amount) internal {
    require(auctionData.startTime <= block.timestamp 
            && block.timestamp <= auctionData.endTime, "INVALID_AUCTION_TIME");
    require(_amount > 0, "INVALID_COMMITMENT_VALUE");
    require(!isAuctionFinalized(), "AUCTION_ALREADY_FINALIZED");

    // TODO: whitelist check // merkle tree or something else?

    COMMITMENTS[_address] = COMMITMENTS[_address].add(_amount);
    auctionData.totalCommitments = auctionData.totalCommitments.add(_amount);

    /// @dev accumulated amount of commitments
    ACCUMULATED[_address] = Math.max(ACCUMULATED[_address], COMMITMENTS[_address]);

    emit CommitmentAdded(_address, _amount);
  }
  
  // withdraw before the auction finished
  /// @notice Withdraws bought tokens, or returns commitment if the sale is unsuccessful.
  function withdrawETH(uint256 _amount) public nonReentrant {
    require(COMMIT_CURRENCY == ETH_ADDRESS, "COMMIT_CURRENCY_IS_NOT_ETH");

    withdrawCommitment(msg.sender, _amount);

    payable(msg.sender).transfer(_amount);

    emit ETHWithdrawan(msg.sender, _amount);
  }

  function withdrawERC20Token(uint256 _amount) private nonReentrant {
    require(COMMIT_CURRENCY != ETH_ADDRESS, "COMMIT_CURRENCY_IS_NOT_ERC20_TOKEN");

    withdrawCommitment(msg.sender, _amount);

    IERC20(COMMIT_CURRENCY).safeTransfer(msg.sender, _amount);

    emit ERC20TokenWithdrawan(msg.sender, _amount);
  }

  function withdrawCommitment(address _user, uint256 _amount) internal {
    require(auctionData.startTime <= block.timestamp 
            && block.timestamp <= auctionData.endTime, "INVALID_AUCTION_TIME");
    require(_amount <= COMMITMENTS[_user], "INSUFFICIENT_COMMITMENTS_BALANCE");
    require(_amount <= getWithdrawableAmount(_user), "INVALID_WITHDRAW_AMOUNT");
    require(!isAuctionFinalized(), "AUCTION_ALREADY_FINALIZED");

    COMMITMENTS[_user] = COMMITMENTS[_user].sub(_amount);
    auctionData.totalCommitments = auctionData.totalCommitments.sub(_amount);
  }

  function claimInstantToken() external {
    require(auctionData.endTime < block.timestamp, "AUCTION_NOT_ENDED");
    require(isClaimablePeriodValid(), "CLIAMABLE_PERIOD_EXPIRED");
    require(COMMITMENTS[msg.sender] > 0, "NO_COMMITMENTS");
    require(isAuctionSuccessful(), "AUCTION_SHOULD_BE_SUCCESSFUL");
    require(!USER_RECEIVED_INSTANT_TOKENS[msg.sender], "USER_ALREADY_RECEIVED_INSTANT_TOKENS");

    uint256 amount = getEstInstantClaimToken(msg.sender);
    USER_RECEIVED_INSTANT_TOKENS[msg.sender] = true;
    INSTANT_TOKEN_CLAIMED[msg.sender] = INSTANT_TOKEN_CLAIMED[msg.sender].add(amount);

    IERC20(AUCTION_TOKEN).safeTransfer(msg.sender, amount);

    emit InstantTokenClaimed(msg.sender, amount, COMMITMENTS[msg.sender]);
  }

  function claimVestedBPT(bool _stake) external {
    require(auctionData.endTime < block.timestamp, "AUCTION_NOT_ENDED");
    require(isClaimablePeriodValid(), "CLIAMABLE_PERIOD_EXPIRED");
    require(COMMITMENTS[msg.sender] > 0, "NO_COMMITMENTS");
    require(isAuctionSuccessful(), "AUCTION_SHOULD_BE_SUCCESSFUL");
    require(isAuctionFinalized(), "AUCTION_SHOULD_BE_FINALIZED");

    uint256 amount = getEstVestedBPT(msg.sender).sub(VESTED_BPT_CLAIMED[msg.sender]);
    require(amount > 0, "NOT_ENOUGH_VESTED_BPT_TO_CLAIM");

    VESTED_BPT_CLAIMED[msg.sender] = VESTED_BPT_CLAIMED[msg.sender].add(amount);

    // if _stake flag is true, then transaction sender wants to claim & stake directly
    if (_stake) {
      require(isStakingAvailable(), 'STAKING_IS_NOT_AVAILABLE');
      IERC20(BALANCER_BPT).safeApprove(STAKING_CONTRACT_ADDRESS, 0);
      IERC20(BALANCER_BPT).safeApprove(STAKING_CONTRACT_ADDRESS, type(uint256).max);
      IStakingRewards(STAKING_CONTRACT_ADDRESS).stake(amount);
    } else {
      IERC20(BALANCER_BPT).safeTransfer(msg.sender, amount);
    }

    emit VestedBPTClaimed(msg.sender, amount);
  }

  /// withdraw unclaimed token, transferring to TREASURY
  // only owner (admin) can execute this 
  function withdrawUnclaimedToken() private onlyOwner nonReentrant {
    require(isClaimablePeriodValid(), "CLIAMABLE_PERIOD_EXPIRED");
    require(IERC20(AUCTION_TOKEN).balanceOf(address(this)) > 0, "NOT_ENOUGH_AUCTION_TOKEN");

    uint256 amount = getAuctionTokenBalance();

    IERC20(AUCTION_TOKEN).safeTransfer(AUCTION_TREASURY, amount);

    emit UnclaimedTokenWithdrawan(AUCTION_TREASURY, amount);
  }

  // claim commitment when project failed (after auction finished and finalized)
  function claimCommitBack() public nonReentrant {
    require(block.timestamp > auctionData.endTime, "AUCTION_NOT_ENDED");
    require(isAuctionFinalized(), "AUCTION_SHOULD_BE_FINALIZED"); 
    require(!isAuctionSuccessful(), "AUCTION_SHOULD_BE_FAILED");
    require(COMMITMENTS[msg.sender] > 0, "NO_COMMITMENTS");
    require(COMMIT_CURRENCY != address(0), "INVALID_COMMIT_CURRENCY");

    uint256 userCommited = COMMITMENTS[msg.sender];
    COMMITMENTS[msg.sender] = 0; 
    ACCUMULATED[msg.sender] = 0;

    if(COMMIT_CURRENCY == ETH_ADDRESS) {
      safeTransferETH(payable(msg.sender), userCommited);
    } else { // ERC20 Token
      IERC20(COMMIT_CURRENCY).safeTransfer(msg.sender, userCommited);
    }

    emit ClaimedCommitmentBack(msg.sender, userCommited);
  }

  // TODO: update comment
  // finalize the auction, and sends 20% funds to DEX, 80% to the project owner wallet
  function finalizeAuction() public onlyOwner nonReentrant {
    require(auctionData.totalOfferingTokens > 0, "NOT_INITIALIZED");
    // TODO: remove commented
    // TODO
    // TODO
    //require(auctionData.endTime < block.timestamp, "AUCTION_NOT_ENDED");
    require(!isAuctionFinalized(), "AUCTION_ALREADY_FINALIZED");

    if (isAuctionSuccessful()) {
      /// @dev The auction was sucessful
      /// @dev Transfer contributed tokens to wallet.
      uint256 transferAmount = auctionData.totalCommitments.mul(4).div(5);

      // 80% of funds goes to the AUCTION_WALLET
      if(COMMIT_CURRENCY == ETH_ADDRESS) {
        safeTransferETH(AUCTION_WALLET, transferAmount);
      } else {
        IERC20(COMMIT_CURRENCY).safeTransfer(AUCTION_WALLET, transferAmount);
      }

      // 20% of funds & 80% of AUCTION_TOKEN instantly goes to DEX POOL
      uint256 token80Amount = auctionData.totalOfferingTokens.mul(4).div(5);
      uint256 token20Amount = auctionData.totalCommitments.div(5);

      // TODO: uncomment
      // TODO:
      // TODO:
      // TODO:
      auctionData.totalBPTAmount = setupBalancerPool(AUCTION_TOKEN, token80Amount, COMMIT_CURRENCY, token20Amount);
      require(auctionData.totalBPTAmount > 0, "INVALID_BPT_AMOUNT");

      emit AuctionFinalizedWithSuccess(transferAmount, token80Amount, token20Amount, auctionData.totalBPTAmount);

    } else { /// @dev auction was not sucessful.
      /// @dev The auction did not meet the minimum commitments amount
      /// @dev Return auction tokens back to wallet.
      IERC20(AUCTION_TOKEN).safeTransfer(AUCTION_TOKEN_VAULT, auctionData.totalOfferingTokens);

      emit AuctionFinalizedWithFailure(auctionData.totalOfferingTokens);
    }
    
    auctionData.finalized = true;
  }

  function safeTransferETH(address payable to, uint value) internal onlyOwner {
    (bool success,) = to.call{value:value}(new bytes(0));
    require(success, 'ETH_TRANSFER_FAILED');
  }

  // token80 amount: 1000000000000000
  // token20 amount: 1000000000000000
  function setupBalancerPool(
    IERC20 _token80,
    uint256 _token80Amount,
    address _token20,
    uint256 _token20Amount
  ) public onlyOwner returns (uint256) {
    require(_token80Amount > 0, "INVALID_TOKEN80_AMOUNT");
    require(_token20Amount > 0, "INVALID_TOKEN20_AMOUNT");

    // TODO: unblock these
    // TODO: unblock these
    // TODO: unblock these
    //require(auctionData.endTime < block.timestamp, "AUCTION_NOT_ENDED");
    require(isAuctionSuccessful(), "AUCTION_SHOULD_BE_SUCCESSFUL");

    IAsset[] memory tokens = new IAsset[](BALANCER_POOL_NUM_OF_TOKEN);
    uint256[] memory weights = new uint256[](BALANCER_POOL_NUM_OF_TOKEN);
    uint256[] memory amountsIn = new uint256[](BALANCER_POOL_NUM_OF_TOKEN);

    tokens[0] = IAsset(address(_token80));
    tokens[1] = IAsset(_token20);
    amountsIn[0] = _token80Amount;
    amountsIn[1] = _token20Amount;
    weights[0] = BALANCER_POOL_WEIGHT_80;
    weights[1] = BALANCER_POOL_WEIGHT_20;

    if (address(_token80) >= _token20) {
      (tokens[0], tokens[1]) = (tokens[1], tokens[0]);
      (amountsIn[0], amountsIn[1]) = (amountsIn[1], amountsIn[0]);
      (weights[0], weights[1]) = (weights[1], weights[0]);
    }

    string memory left = string.concat("80", IERC20Symbol(address(_token80)).symbol());
    string memory right;

    if(_token20 == ETH_ADDRESS) {
      right = string.concat("20", "WETH");
    } else {
      right = string.concat("20", IERC20Symbol(_token20).symbol());
    }

    string memory poolSymbol = string.concat(left, "-", right);

    BALANCER_POOL_ADDRESS = balancerWeightedPoolFactory.create(
      poolSymbol, // pool name will be the same as pool symbol
      poolSymbol,
      tokens,
      weights,
      BALANCER_POOL_SWAP_FEE_PERCENTAGE,
      BALANCER_POOL_OWNER_ADDRESS
    );

    BALANCER_BPT = IBalancerPool(BALANCER_POOL_ADDRESS);
    BALANCER_POOL_ID = BALANCER_BPT.getPoolId();

    bytes memory userData = abi.encode(IBalancerVault.JoinKind.INIT, amountsIn, 0);
    IBalancerVault.JoinPoolRequest memory request = IBalancerVault.JoinPoolRequest({
      assets: tokens,
      maxAmountsIn: amountsIn,
      userData: userData,
      fromInternalBalance: false
    });

    if(_token20 == ETH_ADDRESS) {
      BALANCER_VAULT.joinPool {value: _token20Amount} (BALANCER_POOL_ID, address(this), address(this), request);
    } else {
      BALANCER_VAULT.joinPool(BALANCER_POOL_ID, address(this), address(this), request);
    }

    BALANCER_BPT_AMOUNT = getBPTBalance();
    require(BALANCER_BPT_AMOUNT > 0, "INVALID_BPT_AMOUNT");

    emit BalancerWeightedPoolCreatedAndJoined(
      poolSymbol,
      tokens,
      weights,
      amountsIn,
      BALANCER_POOL_SWAP_FEE_PERCENTAGE,
      BALANCER_POOL_OWNER_ADDRESS,
      BALANCER_BPT_AMOUNT
    );

    return BALANCER_BPT_AMOUNT;
  }
  
  /// @notice Returns bpt token amount
  function getBPTBalance() public view returns (uint256) {
    require(address(BALANCER_BPT) != address(0), "BALANCER_POOL_NOT_INITIALIZED");
    return IERC20(BALANCER_BPT).balanceOf(address(this));
  }

  // TODO: 
  function isClaimablePeriodValid() internal view returns (bool) {
    return block.timestamp < uint256(auctionData.endTime).add(CLIAMABLE_PERIOD);
  }

  /**
   * @dev Calculate the amount of ETH that can be withdrawn by user
   */
  function getWithdrawableAmount(address _user) public view returns (uint256) {
    uint256 userAccumulated = ACCUMULATED[_user];
    uint256 lockedAmount = getLockedAmount(_user);
    return Math.min(withdrawCap(userAccumulated), COMMITMENTS[_user].sub(lockedAmount));
  }

  /**
   * @dev Get total locked ether of a user
   */
  function getLockedAmount(address _user) public view returns (uint256) {
    uint256 userAccumulated = ACCUMULATED[_user];
    return userAccumulated.sub(withdrawCap(userAccumulated));
  }
 
  /**
   * @dev Calculate withdrawCap based on accumulated ether
   */
  function withdrawCap(uint256 _userAccumulated) internal view returns (uint256) {
    require(COMMIT_CURRENCY != address(0), "INVALID_COMMIT_CURRENCY");
    if (_userAccumulated <= WITHDRAW_CAP_MIN_THRESHOLD) {
      return _userAccumulated;
    } else if (_userAccumulated <= WITHDRAW_CAP_MAX_THRESHOLD) {
      uint256 accumulatedTotal = _userAccumulated.div(10**uint256(PRECISION));
      return accumulatedTotal.mul(WITHDRAW_CAP_INTERCEPT).add(WITHDRAW_CAP_INTERCEPT_PLUS);
    } else {
      return WITHDRAW_CAP_LIMIT;
    }
  }

  /* ========== EXTERNAL VIEWS ========== */
  function getAuctionData() external view returns (AuctionData memory) {
    return auctionData;
  }

  /* ========== EXTERNAL VIEWS ========== */
  /* ========== EXTERNAL VIEWS ========== */
  /* ========== EXTERNAL VIEWS ========== */
  /**
   * @dev Calculate locked amount after deposit
   */
  function getLockAmountAfterDeposit(address _user, uint256 _amount) private view returns (uint256) {
    uint256 userAccumulated = Math.max(COMMITMENTS[_user] + _amount, ACCUMULATED[_user]);
    return userAccumulated.sub(withdrawCap(userAccumulated));
  }

  /**
   * @dev Get user's accumulated amount after deposit
   */
  function getAccumulatedAfterDeposit(address _user, uint256 _amount) private view returns (uint256) {
    return Math.max(COMMITMENTS[_user] + _amount, ACCUMULATED[_user]);
  }

  /**
   * @dev Get estimated amount of tokens without vesting
   */
  // user can claim 20% of tokens instantly, without vesting
  function getEstInstantClaimToken(address _user) public view returns (uint256) {
    require(auctionData.endTime < block.timestamp, "AUCTION_NOT_ENDED");
    uint256 userShare = COMMITMENTS[_user].div(5); // div(5) is equal to 20%
    return auctionData.totalOfferingTokens
            .mul(userShare)
            .div(auctionData.totalCommitments);
  }

  /**
   * @dev Get estimated amount with vesting
   */
  // user can claim 80% worth of tokens with 30 days of vesting
  // TODO: callable from Front
  function getEstVestedBPT(address _user) public view returns (uint256) {
    require(auctionData.endTime < block.timestamp, "AUCTION_NOT_ENDED");
    require(isClaimablePeriodValid(), "CLIAMABLE_PERIOD_EXPIRED");
    require(isAuctionSuccessful(), "AUCTION_SHOULD_BE_SUCCESSFUL");
    require(isAuctionFinalized(), "AUCTION_SHOULD_BE_FINALIZED");

    uint256 vestingTimeElapsed = block.timestamp.sub(auctionData.endTime);
    if (vestingTimeElapsed >= VESTING_PERIOD) {
      vestingTimeElapsed = VESTING_PERIOD;
    }

    uint256 userShare = COMMITMENTS[_user].div(5).mul(4); // div(5).mul(4) == 0.8 == 80%
    return auctionData.totalBPTAmount
            .mul(userShare)
            .mul(vestingTimeElapsed)
            .div(VESTING_PERIOD)
            .div(auctionData.totalCommitments);
  }

  /**
   * @notice Calculates the price of each token from all commitments.
   * @return Token price
   */
  function getTokenPrice() public view returns (uint256) {
    return uint256(auctionData.totalCommitments)
            .mul(1e18).div(uint256(auctionData.totalOfferingTokens));
  }

  /**
   * @notice Checks if the auction was successful
   * @return True if tokens sold greater than or equals to the minimum commitment amount
   */
  function isAuctionSuccessful() internal view returns (bool) {
    return auctionData.totalCommitments > 0 
      && (auctionData.totalCommitments >= auctionData.minCommitmentsAmount); 
  }

  /**
   * @dev Checks if the auction has ended or not
   * @return True if current time is greater than auction end time
   */
  function isAuctionEnded() private view returns (bool) {
    return block.timestamp > auctionData.endTime;
  }

  /**
   * @dev Checks if the auction has been finalized or not
   * @return True if auction has been finalized
   */
  function isAuctionFinalized() internal view returns (bool) {
    return auctionData.finalized;
  }

  /**
   * @dev admin func
   */
  function setStakingContractAddress(address _addr) external onlyOwner {
    STAKING_CONTRACT_ADDRESS = _addr;
    emit StakingContractAddressSet(_addr);
  }

  /**
   * @dev test
   * @return True
   */
  function isStakingAvailable() internal view returns (bool) {
    return STAKING_CONTRACT_ADDRESS != address(0);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Deposit Token Interface for BAL Reward Pool
 */
interface IDepositToken is IERC20 {
    function mint(address, uint256) external;
    function burn(address, uint256) external;
}

/**
 * @dev BAL Reward Pool
 */
interface IBALRewardPool {    
    function earned(address) external view returns (uint256);
    function stakeFor(address, uint256) external;
    function withdrawFor(address, uint256) external;
    function getReward(address) external;
    function getRewardRate() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function processIdleRewards() external;
    function queueNewRewards(uint256) external;    
}

/**
 * @dev Asset Data
 */
struct AssetData {
    uint128 emissionPerSecond;
    uint128 lastUpdateTimestamp; 
    uint256 index;
    mapping(address => uint256) users;
}

/**
 * @dev Auction Data
 */
struct AuctionData {
  uint128 startTime;
  uint128 endTime;
  uint256 totalOfferingTokens;
  uint256 totalBPTAmount; // balancer pool token amount
  uint256 minCommitmentsAmount;
  uint256 totalCommitments;
  bool instantClaimClosed;
  bool finalized;
}

interface IERC20Symbol is IERC20 {
  function symbol() external view returns (string memory s);
}

struct TokenInfo {
  address addr;
  uint256 amount;
  uint256 weight;
}

interface IAsset {
     // solhint-disable-previous-line no-empty-blocks
}

interface IBalancerPool is IERC20 {
    function getPoolId() external view returns (bytes32 poolId);
    function symbol() external view returns (string memory s);
}

interface IWeightedPoolFactory {
    function create(
        string memory name,
        string memory symbol,
        IAsset[] memory tokens,
        uint256[] memory weights,
        uint256 swapFeePercentage,
        address owner
    ) external returns (address);
}

interface IBalancerVault {
    enum JoinKind {INIT, EXACT_TOKENS_IN_FOR_BPT_OUT, TOKEN_IN_FOR_EXACT_BPT_OUT, ALL_TOKENS_IN_FOR_EXACT_BPT_OUT}

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;
}

interface IStakingRewards {
  function stake(uint256 _amount) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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