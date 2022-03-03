// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/security/Pausable.sol';

import './interfaces/ISherlock.sol';

/// @title Sherlock core interface for stakers
/// @author Evert Kors
// This is the contract that manages staking actions

contract Sherlock is ISherlock, ERC721, Ownable, Pausable {
  using SafeERC20 for IERC20;

  // The minimal amount needed to mint a position
  uint256 public constant MIN_STAKE = 10**6; // 1 USDC

  // The initial period for a staker to restake/withdraw without being auto-restaked
  uint256 public constant ARB_RESTAKE_WAIT_TIME = 2 weeks;

  // The period during which the reward for restaking an account (after the inital period) grows
  uint256 public constant ARB_RESTAKE_GROWTH_TIME = 1 weeks;

  // Anyone who gets auto-restaked is restaked for this period (26 weeks)
  uint256 public constant ARB_RESTAKE_PERIOD = 26 weeks;

  // The percentage of someone's stake that can be paid to an arb for restaking
  uint256 public constant ARB_RESTAKE_MAX_PERCENTAGE = (10**18 / 100) * 20; // 20%

  // USDC address
  IERC20 public immutable token;

  // SHER token address
  IERC20 public immutable sher;

  // Key is the staking period (3 months, 6 months, etc.), value will be whether it is allowed or not
  mapping(uint256 => bool) public override stakingPeriods;

  // Key is a specific position ID (NFT ID), value represents the timestamp at which the position can be unstaked/restaked
  mapping(uint256 => uint256) internal lockupEnd_;

  // Key is NFT ID, value is the amount of SHER rewards owed to that NFT position
  mapping(uint256 => uint256) internal sherRewards_;

  // Key is NFT ID, value is the amount of shares representing the USDC owed to this position (includes principal, interest, etc.)
  mapping(uint256 => uint256) internal stakeShares;

  // Total amount of shares that have been issued to all NFT positions
  uint256 internal totalStakeShares;

  // Contract representing the current yield strategy (deposits staker funds into Aave, etc.)
  IStrategyManager public override yieldStrategy;

  // Instances of relevant Sherlock contracts
  ISherDistributionManager public override sherDistributionManager;
  ISherlockProtocolManager public override sherlockProtocolManager;
  ISherlockClaimManager public override sherlockClaimManager;

  // Address to which nonstaker payments are made
  // This will start out as a multi-sig address, then become a contract address later
  address public override nonStakersAddress;

  // Stores the ID of the most recently created NFT
  // This variable is incremented by 1 to create a new NFT ID
  uint256 internal nftCounter;

  string private constant baseURI = 'https://nft.sherlock.xyz/api/mainnet/';

  // Even though `_sherDistributionManager` can be removed once deployed, every initial deployment will have an active instance.
  constructor(
    IERC20 _token, // USDC address
    IERC20 _sher, // SHER token address
    string memory _name, // Token collection name (see ERC-721 docs)
    string memory _symbol, // Token collection symbol (see ERC-721 docs)
    IStrategyManager _yieldStrategy, // The active yield strategy contract
    ISherDistributionManager _sherDistributionManager, // The active DistributionManager contract
    address _nonStakersAddress, // The address to which nonstakers payments go
    ISherlockProtocolManager _sherlockProtocolManager, // The address for the ProtocolManager contract
    ISherlockClaimManager _sherlockClaimManager, // The address for the ClaimManager contract
    uint256[] memory _initialstakingPeriods // The initial periods (3m, 6m, etc.) that someone can stake for
  ) ERC721(_name, _symbol) {
    if (address(_token) == address(0)) revert ZeroArgument();
    if (address(_sher) == address(0)) revert ZeroArgument();
    if (address(_yieldStrategy) == address(0)) revert ZeroArgument();
    if (address(_sherDistributionManager) == address(0)) revert ZeroArgument();
    if (_nonStakersAddress == address(0)) revert ZeroArgument();
    if (address(_sherlockProtocolManager) == address(0)) revert ZeroArgument();
    if (address(_sherlockClaimManager) == address(0)) revert ZeroArgument();

    token = _token;
    sher = _sher;
    yieldStrategy = _yieldStrategy;
    sherDistributionManager = _sherDistributionManager;
    nonStakersAddress = _nonStakersAddress;
    sherlockProtocolManager = _sherlockProtocolManager;
    sherlockClaimManager = _sherlockClaimManager;

    // Enabling the first set of staking periods that were provided in constructor args
    for (uint256 i; i < _initialstakingPeriods.length; i++) {
      enableStakingPeriod(_initialstakingPeriods[i]);
    }

    emit YieldStrategyUpdated(IStrategyManager(address(0)), _yieldStrategy);
    emit SherDistributionManagerUpdated(
      ISherDistributionManager(address(0)),
      _sherDistributionManager
    );
    emit NonStakerAddressUpdated(address(0), _nonStakersAddress);
    emit ProtocolManagerUpdated(ISherlockProtocolManager(address(0)), _sherlockProtocolManager);
    emit ClaimManagerUpdated(ISherlockClaimManager(address(0)), _sherlockClaimManager);
  }

  //
  // View functions
  //

  // Returns the timestamp at which the position represented by _tokenID can first be unstaked/restaked
  /// @notice View the current lockup end timestamp of `_tokenID`
  /// @return Timestamp when NFT position unlocks
  function lockupEnd(uint256 _tokenID) public view override returns (uint256) {
    if (!_exists(_tokenID)) revert NonExistent();

    return lockupEnd_[_tokenID];
  }

  // Returns the SHER rewards owed to this position
  /// @notice View the current SHER reward of `_tokenID`
  /// @return Amount of SHER rewarded to owner upon reaching the end of the lockup
  function sherRewards(uint256 _tokenID) public view override returns (uint256) {
    if (!_exists(_tokenID)) revert NonExistent();

    return sherRewards_[_tokenID];
  }

  // Returns the tokens (USDC) owed to a position
  /// @notice View the current token balance claimable upon reaching end of the lockup
  /// @return Amount of tokens assigned to owner when unstaking position
  function tokenBalanceOf(uint256 _tokenID) public view override returns (uint256) {
    if (!_exists(_tokenID)) revert NonExistent();
    // Finds the fraction of total shares owed to this position and multiplies by the total amount of tokens (USDC) owed to stakers
    return (stakeShares[_tokenID] * totalTokenBalanceStakers()) / totalStakeShares;
  }

  // Gets the total amount of tokens (USDC) owed to stakers
  // Adds this contract's balance, the tokens in the yield strategy, and the claimable premiums in the protocol manager contract
  /// @notice View the current TVL for all stakers
  /// @return Total amount of tokens staked
  /// @dev Adds principal + strategy + premiums
  /// @dev Will calculate the most up to date value for each piece
  function totalTokenBalanceStakers() public view override returns (uint256) {
    return
      token.balanceOf(address(this)) +
      yieldStrategy.balanceOf() +
      sherlockProtocolManager.claimablePremiums();
  }

  //
  // Gov functions
  //

  // Allows governance to add a new staking period (4 months, etc.)
  /// @notice Allows stakers to stake for `_period` of time
  /// @param _period Period of time, in seconds,
  /// @dev should revert if already enabled
  function enableStakingPeriod(uint256 _period) public override onlyOwner {
    if (_period == 0) revert ZeroArgument();
    // Revert if staking period is already active
    if (stakingPeriods[_period]) revert InvalidArgument();

    // Sets the staking period to true
    stakingPeriods[_period] = true;
    emit StakingPeriodEnabled(_period);
  }

  // Allows governance to remove a staking period (4 months, etc.)
  /// @notice Disallow stakers to stake for `_period` of time
  /// @param _period Period of time, in seconds,
  /// @dev should revert if already disabled
  function disableStakingPeriod(uint256 _period) external override onlyOwner {
    // Revert if staking period is already inactive
    if (!stakingPeriods[_period]) revert InvalidArgument();

    // Sets the staking period to false
    stakingPeriods[_period] = false;
    emit StakingPeriodDisabled(_period);
  }

  // Sets a new contract to be the active SHER distribution manager
  /// @notice Update SHER distribution manager contract
  /// @param _sherDistributionManager New adddress of the manager
  /// @dev After updating the contract, call setSherlockCoreAddress() on the new contract
  function updateSherDistributionManager(ISherDistributionManager _sherDistributionManager)
    external
    override
    onlyOwner
  {
    if (address(_sherDistributionManager) == address(0)) revert ZeroArgument();
    if (sherDistributionManager == _sherDistributionManager) revert InvalidArgument();

    emit SherDistributionManagerUpdated(sherDistributionManager, _sherDistributionManager);
    sherDistributionManager = _sherDistributionManager;
  }

  /// @notice Deletes the SHER distribution manager altogether (if Sherlock decides to no longer pay out SHER rewards)
  function removeSherDistributionManager() external override onlyOwner {
    if (address(sherDistributionManager) == address(0)) revert InvalidConditions();

    emit SherDistributionManagerUpdated(
      sherDistributionManager,
      ISherDistributionManager(address(0))
    );
    delete sherDistributionManager;
  }

  // Sets a new address for nonstakers payments
  /// @notice Update address eligible for non staker rewards from protocol premiums
  /// @param _nonStakers Address eligible for non staker rewards
  function updateNonStakersAddress(address _nonStakers) external override onlyOwner {
    if (address(_nonStakers) == address(0)) revert ZeroArgument();
    if (nonStakersAddress == _nonStakers) revert InvalidArgument();

    emit NonStakerAddressUpdated(nonStakersAddress, _nonStakers);
    nonStakersAddress = _nonStakers;
  }

  // Sets a new protocol manager contract
  /// @notice Transfer protocol manager implementation address
  /// @param _protocolManager new implementation address
  /// @dev After updating the contract, call setSherlockCoreAddress() on the new contract
  function updateSherlockProtocolManager(ISherlockProtocolManager _protocolManager)
    external
    override
    onlyOwner
  {
    if (address(_protocolManager) == address(0)) revert ZeroArgument();
    if (sherlockProtocolManager == _protocolManager) revert InvalidArgument();

    emit ProtocolManagerUpdated(sherlockProtocolManager, _protocolManager);
    sherlockProtocolManager = _protocolManager;
  }

  // Sets a new claim manager contract
  /// @notice Transfer claim manager role to different address
  /// @param _claimManager New address of claim manager
  /// @dev After updating the contract, call setSherlockCoreAddress() on the new contract
  function updateSherlockClaimManager(ISherlockClaimManager _claimManager)
    external
    override
    onlyOwner
  {
    if (address(_claimManager) == address(0)) revert ZeroArgument();
    if (sherlockClaimManager == _claimManager) revert InvalidArgument();

    emit ClaimManagerUpdated(sherlockClaimManager, _claimManager);
    sherlockClaimManager = _claimManager;
  }

  // Sets a new yield strategy manager contract
  /// @notice Update yield strategy
  /// @param _yieldStrategy New address of the strategy
  /// @dev Call will fail if underlying withdrawAll call fails
  /// @dev After updating the contract, call setSherlockCoreAddress() on the new contract
  function updateYieldStrategy(IStrategyManager _yieldStrategy) external override onlyOwner {
    if (address(_yieldStrategy) == address(0)) revert ZeroArgument();
    if (yieldStrategy == _yieldStrategy) revert InvalidArgument();

    yieldStrategy.withdrawAll();

    emit YieldStrategyUpdated(yieldStrategy, _yieldStrategy);
    yieldStrategy = _yieldStrategy;
  }

  // Sets a new yield strategy manager contract
  /// @notice Update yield strategy ignoring state of current strategy
  /// @param _yieldStrategy New address of the strategy
  /// @dev tries a yieldStrategyWithdrawAll() on old strategy, ignore failure
  function updateYieldStrategyForce(IStrategyManager _yieldStrategy) external override onlyOwner {
    if (address(_yieldStrategy) == address(0)) revert ZeroArgument();
    if (yieldStrategy == _yieldStrategy) revert InvalidArgument();

    // This call is surrounded with a try catch as there is a non-zero chance the underlying yield protocol(s) will fail
    // For example; the Aave V2 withdraw can fail in case there is not enough liquidity available for whatever reason.
    // In case this happens. We still want the yield strategy to be updated.
    // As the worst case could be that the Aave V2 withdraw will never work again, forcing us to never use a yield strategy ever again.
    try yieldStrategy.withdrawAll() {} catch (bytes memory reason) {
      emit YieldStrategyUpdateWithdrawAllError(reason);
    }

    emit YieldStrategyUpdated(yieldStrategy, _yieldStrategy);
    yieldStrategy = _yieldStrategy;
  }

  // Deposits a chosen amount of tokens (USDC) into the active yield strategy
  /// @notice Deposit `_amount` into active strategy
  /// @param _amount Amount of tokens
  /// @dev gov only
  function yieldStrategyDeposit(uint256 _amount) external override onlyOwner {
    if (_amount == 0) revert ZeroArgument();

    // Transfers any tokens owed to stakers from the protocol manager contract to this contract first
    sherlockProtocolManager.claimPremiumsForStakers();
    // Transfers the amount of tokens to the yield strategy contract
    token.safeTransfer(address(yieldStrategy), _amount);
    // Deposits all tokens in the yield strategy contract into the actual yield strategy
    yieldStrategy.deposit();
  }

  // Withdraws a chosen amount of tokens (USDC) from the yield strategy back into this contract
  /// @notice Withdraw `_amount` from active strategy
  /// @param _amount Amount of tokens
  /// @dev gov only
  function yieldStrategyWithdraw(uint256 _amount) external override onlyOwner {
    if (_amount == 0) revert ZeroArgument();

    yieldStrategy.withdraw(_amount);
  }

  // Withdraws all tokens from the yield strategy back into this contract
  /// @notice Withdraw all funds from active strategy
  /// @dev gov only
  function yieldStrategyWithdrawAll() external override onlyOwner {
    yieldStrategy.withdrawAll();
  }

  /// @notice Pause external functions in all contracts
  /// @dev A manager can still be replaced with a new contract in a `paused` state
  /// @dev To ensure we are still able to pause all contracts, we check if the manager is unpaused
  function pause() external onlyOwner {
    _pause();
    if (!Pausable(address(yieldStrategy)).paused()) yieldStrategy.pause();
    // sherDistributionManager can be 0, pause isn't needed in that case
    if (
      address(sherDistributionManager) != address(0) &&
      !Pausable(address(sherDistributionManager)).paused()
    ) {
      sherDistributionManager.pause();
    }
    if (!Pausable(address(sherlockProtocolManager)).paused()) sherlockProtocolManager.pause();
    if (!Pausable(address(sherlockClaimManager)).paused()) sherlockClaimManager.pause();
  }

  /// @notice Unpause external functions in all contracts
  /// @dev A manager can still be replaced with a new contract in an `unpaused` state
  /// @dev To ensure we are still able to unpause all contracts, we check if the manager is paused
  function unpause() external onlyOwner {
    _unpause();
    if (Pausable(address(yieldStrategy)).paused()) yieldStrategy.unpause();
    // sherDistributionManager can be 0, unpause isn't needed in that case
    if (
      address(sherDistributionManager) != address(0) &&
      Pausable(address(sherDistributionManager)).paused()
    ) {
      sherDistributionManager.unpause();
    }
    if (Pausable(address(sherlockProtocolManager)).paused()) sherlockProtocolManager.unpause();
    if (Pausable(address(sherlockClaimManager)).paused()) sherlockClaimManager.unpause();
  }

  //
  // Access control functions
  //
  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256 _tokenID
  ) internal override whenNotPaused {}

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // Transfers specified amount of tokens to the address specified by the claim creator (protocol agent)
  // This function is called by the Sherlock claim manager contract if a claim is approved
  /// @notice Initiate a payout of `_amount` to `_receiver`
  /// @param _receiver Receiver of payout
  /// @param _amount Amount to send
  /// @dev only payout manager should call this
  /// @dev should pull money out of strategy
  function payoutClaim(address _receiver, uint256 _amount) external override whenNotPaused {
    // Can only be called by the Sherlock claim manager contract
    if (msg.sender != address(sherlockClaimManager)) revert Unauthorized();

    if (_amount != 0) {
      // Sends the amount of tokens to the receiver address (specified by the protocol agent who created the claim)
      _transferTokensOut(_receiver, _amount);
    }
    emit ClaimPayout(_receiver, _amount);
  }

  //
  // Non-access control functions
  //

  // Helper function for initial staking and restaking
  // Sets the unlock period, mints and transfers SHER tokens to this contract, assigns SHER tokens to this NFT position
  /// @notice Stakes `_amount` of tokens and locks up the `_id` position for `_period` seconds
  /// @param _amount Amount of tokens to stake
  /// @param _period Period of time for which funds get locked
  /// @param _id ID for this NFT position
  /// @param _receiver Address that will be linked to this position
  /// @return _sher Amount of SHER tokens awarded to this position after `_period` ends
  /// @dev `_period` needs to be whitelisted
  function _stake(
    uint256 _amount,
    uint256 _period,
    uint256 _id,
    address _receiver
  ) internal returns (uint256 _sher) {
    // Sets the timestamp at which this position can first be unstaked/restaked
    lockupEnd_[_id] = block.timestamp + _period;

    if (address(sherDistributionManager) == address(0)) return 0;
    // Does not allow restaking of 0 tokens
    if (_amount == 0) return 0;

    // Checks this amount of SHER tokens in this contract before we transfer new ones
    uint256 before = sher.balanceOf(address(this));

    // pullReward() calcs then actually transfers the SHER tokens to this contract
    // in case this call fails, whole (re)staking transaction fails
    _sher = sherDistributionManager.pullReward(_amount, _period, _id, _receiver);

    // actualAmount should represent the amount of SHER tokens transferred to this contract for the current stake position
    uint256 actualAmount = sher.balanceOf(address(this)) - before;
    if (actualAmount != _sher) revert InvalidSherAmount(_sher, actualAmount);
    // Assigns the newly created SHER tokens to the current stake position
    if (_sher != 0) sherRewards_[_id] = _sher;
  }

  // Checks to see if the NFT owner is the caller and that the position is unlockable
  function _verifyUnlockableByOwner(uint256 _id) internal view {
    if (ownerOf(_id) != msg.sender) revert Unauthorized();
    if (lockupEnd_[_id] > block.timestamp) revert InvalidConditions();
  }

  // Sends the SHER tokens associated with this NFT ID to the address of the NFT owner
  function _sendSherRewardsToOwner(uint256 _id, address _nftOwner) internal {
    uint256 sherReward = sherRewards_[_id];
    if (sherReward == 0) return;

    // Deletes the SHER reward mapping for this NFT ID
    delete sherRewards_[_id];

    // Transfers the SHER tokens associated with this NFT ID to the address of the NFT owner
    sher.safeTransfer(_nftOwner, sherReward);
  }

  // Transfers an amount of tokens to the receiver address
  // This is the logic for a payout AND for an unstake (used by the payoutClaim() function above and in _redeemShares() below)
  function _transferTokensOut(address _receiver, uint256 _amount) internal {
    // Transfers any premiums owed to stakers from the protocol manager to this contract
    sherlockProtocolManager.claimPremiumsForStakers();

    // The amount of tokens in this contract
    uint256 mainBalance = token.balanceOf(address(this));

    // If the amount to transfer out is still greater than the amount of tokens in this contract,
    // Withdraw yield strategy tokens to make up the difference
    if (_amount > mainBalance) {
      yieldStrategy.withdraw(_amount - mainBalance);
    }

    token.safeTransfer(_receiver, _amount);
  }

  // Returns the amount of USDC owed to this amount of stakeShares
  function _redeemSharesCalc(uint256 _stakeShares) internal view returns (uint256) {
    // Finds fraction that the given amount of stakeShares represents of the total
    // Then multiplies it by the total amount of tokens (USDC) owed to all stakers
    return (_stakeShares * totalTokenBalanceStakers()) / totalStakeShares;
  }

  // Transfers USDC to the receiver (arbitrager OR NFT owner) based on the stakeShares inputted
  // Also burns the requisite amount of shares associated with this NFT position
  // Returns the amount of USDC owed to these shares
  function _redeemShares(
    uint256 _id,
    uint256 _stakeShares,
    address _receiver
  ) internal returns (uint256 _amount) {
    // Returns the amount of USDC owed to this amount of stakeShares
    _amount = _redeemSharesCalc(_stakeShares);
    // Transfers _amount of tokens to _receiver address
    if (_amount != 0) _transferTokensOut(_receiver, _amount);

    // Subtracts this amount of stakeShares from the NFT position
    stakeShares[_id] -= _stakeShares;
    // Subtracts this amount of stakeShares from the total amount of stakeShares outstanding
    totalStakeShares -= _stakeShares;
  }

  // Helper function to restake an eligible NFT position on behalf of the NFT owner OR an arbitrager
  // Restakes an NFT position (_id) for a given period (_period) and
  // Sends any previously earned SHER rewards to the _nftOwner address
  function _restake(
    uint256 _id,
    uint256 _period,
    address _nftOwner
  ) internal returns (uint256 _sher) {
    // Sends the SHER tokens previously earned by this NFT ID to the address of the NFT owner
    // NOTE This function deletes the SHER reward mapping for this NFT ID
    _sendSherRewardsToOwner(_id, _nftOwner);

    // tokenBalanceOf() returns the USDC amount owed to this NFT ID
    // _stake() restakes that amount of USDC for the period inputted
    // We use the same ID that we just deleted the SHER rewards mapping for
    // Resets the lockupEnd mapping and SHER token rewards mapping for this ID
    // Note stakeShares for this position do not change so no need to update
    _sher = _stake(tokenBalanceOf(_id), _period, _id, _nftOwner);

    emit Restaked(_id);
  }

  // This function is called in the UI by anyone who is staking for the first time (not restaking a previous position)
  /// @notice Stakes `_amount` of tokens and locks up for `_period` seconds, `_receiver` will receive the NFT receipt
  /// @param _amount Amount of tokens to stake
  /// @param _period Period of time, in seconds, to lockup your funds
  /// @param _receiver Address that will receive the NFT representing the position
  /// @return _id ID of the position
  /// @return _sher Amount of SHER tokens to be released to this ID after `_period` ends
  /// @dev `_period` needs to be whitelisted
  function initialStake(
    uint256 _amount,
    uint256 _period,
    address _receiver
  ) external override whenNotPaused returns (uint256 _id, uint256 _sher) {
    if (_amount == 0) revert ZeroArgument();
    if (_amount < MIN_STAKE) revert InvalidArgument();
    // Makes sure the period is a whitelisted period
    if (!stakingPeriods[_period]) revert InvalidArgument();
    if (address(_receiver) == address(0)) revert ZeroArgument();
    // Adds 1 to the ID of the last NFT created for the new NFT ID
    _id = ++nftCounter;

    // Transfers the USDC from the msg.sender to this contract for the amount specified (this is the staking action)
    token.safeTransferFrom(msg.sender, address(this), _amount);

    uint256 stakeShares_;
    uint256 totalStakeShares_ = totalStakeShares;
    // _amount of tokens divided by the "before" total amount of tokens, multiplied by the "before" amount of stake shares
    if (totalStakeShares_ != 0)
      stakeShares_ = (_amount * totalStakeShares_) / (totalTokenBalanceStakers() - _amount);
      // If this is the first stake ever, we just mint stake shares equal to the amount of USDC staked
    else stakeShares_ = _amount;

    // Assigns this NFT ID the calc'd amount of stake shares above
    stakeShares[_id] = stakeShares_;
    // Adds the newly created stake shares to the total amount of stake shares
    totalStakeShares += stakeShares_;

    // Locks up the USDC amount and calcs the SHER token amount to receive on unstake
    _sher = _stake(_amount, _period, _id, _receiver);

    // This is an ERC-721 function that creates an NFT and sends it to the receiver
    _safeMint(_receiver, _id);
  }

  // This is how a staker unstakes and cashes out on their position
  /// @notice Redeem NFT `_id` and receive `_amount` of tokens
  /// @param _id TokenID of the position
  /// @return _amount Amount of tokens (USDC) owed to NFT ID
  /// @dev Only the owner of `_id` will be able to redeem their position
  /// @dev The SHER rewards are sent to the NFT owner
  /// @dev Can only be called after lockup `_period` has ended
  function redeemNFT(uint256 _id) external override whenNotPaused returns (uint256 _amount) {
    // Checks to make sure caller is the owner of the NFT position, and that the lockup period is over
    _verifyUnlockableByOwner(_id);

    // This is the ERC-721 function to destroy an NFT (with owner's approval)
    _burn(_id);

    // Transfers USDC to the NFT owner based on the stake shares associated with this NFT ID
    // Also burns the requisite amount of shares associated with this NFT position
    // Returns the amount of USDC owed to these shares
    _amount = _redeemShares(_id, stakeShares[_id], msg.sender);

    // Sends the SHER tokens associated with this NFT ID to the NFT owner
    _sendSherRewardsToOwner(_id, msg.sender);

    // Removes the unlock deadline associated with this NFT
    delete lockupEnd_[_id];
  }

  // This is how a staker restakes an expired position
  /// @notice Owner restakes position with ID: `_id` for `_period` seconds
  /// @param _id ID of the position
  /// @param _period Period of time, in seconds, to lockup your funds
  /// @return _sher Amount of SHER tokens to be released to owner address after `_period` ends
  /// @dev Only the owner of `_id` will be able to restake their position using this call
  /// @dev `_period` needs to be whitelisted
  /// @dev Can only be called after lockup `_period` has ended
  function ownerRestake(uint256 _id, uint256 _period)
    external
    override
    whenNotPaused
    returns (uint256 _sher)
  {
    // Checks to make sure caller is the owner of the NFT position, and that the lockup period is over
    _verifyUnlockableByOwner(_id);

    // Checks to make sure the staking period is a whitelisted one
    if (!stakingPeriods[_period]) revert InvalidArgument();

    // Sends the previously earned SHER token rewards to the owner and restakes the USDC value of the position
    _sher = _restake(_id, _period, msg.sender);
  }

  // Calcs the reward (in stake shares) an arb would get for restaking a position
  // Takes the NFT ID as a param and outputs the stake shares (which can be redeemed for USDC) for the arb
  function _calcSharesForArbRestake(uint256 _id) internal view returns (uint256, bool) {
    // this is the first point at which an arb can restake a position (i.e. two weeks after the initial lockup ends)
    uint256 initialArbTime = lockupEnd_[_id] + ARB_RESTAKE_WAIT_TIME;

    // If the initialArbTime has not passed, return 0 for the stake shares and false for whether an arb can restake the position
    if (initialArbTime > block.timestamp) return (0, false);

    // The max rewards (as a % of the position's shares) for the arb are available at this timestamp
    uint256 maxRewardArbTime = initialArbTime + ARB_RESTAKE_GROWTH_TIME;

    // Caps the timestamp at the maxRewardArbTime so the calc below never goes above 100%
    uint256 targetTime = block.timestamp < maxRewardArbTime ? block.timestamp : maxRewardArbTime;

    // Scaled by 10**18
    // Represents the max amount of stake shares that an arb could get from restaking this position
    uint256 maxRewardScaled = ARB_RESTAKE_MAX_PERCENTAGE * stakeShares[_id];

    // Calcs what % of the max reward an arb gets based on the timestamp at which they call this function
    // If targetTime == maxRewardArbTime, then the arb gets 100% of the maxRewardScaled
    return (
      ((targetTime - initialArbTime) * maxRewardScaled) / (ARB_RESTAKE_GROWTH_TIME) / 10**18,
      true
    );
  }

  /// @notice Calculates the reward in tokens (USDC) that an arb would get for calling restake on a position
  /// @return profit How much profit an arb would make in USDC
  /// @return able If the transaction can be executed (the current timestamp is during an arb period, etc.)
  function viewRewardForArbRestake(uint256 _id) external view returns (uint256 profit, bool able) {
    if (!_exists(_id)) revert NonExistent();
    // Returns the stake shares that an arb would get, and whether the position can currently be arbed
    // `profit` variable is used to store the amount of shares
    (profit, able) = _calcSharesForArbRestake(_id);
    // Calculates the tokens (USDC) represented by that amount of stake shares
    // Amount of shares stored in `profit` is used to calculate the reward in USDC, which is stored in `profit`
    profit = _redeemSharesCalc(profit);
  }

  /// @notice Allows someone who doesn't own the position (an arbitrager) to restake the position for 26 weeks (ARB_RESTAKE_PERIOD)
  /// @param _id ID of the position
  /// @return _sher Amount of SHER tokens to be released to position owner on expiry of the 26 weeks lockup
  /// @return _arbReward Amount of tokens (USDC) sent to caller (the arbitrager) in return for calling the function
  /// @dev Can only be called after lockup `_period` is more than 2 weeks in the past (assuming ARB_RESTAKE_WAIT_TIME is 2 weeks)
  /// @dev Max 20% (ARB_RESTAKE_MAX_PERCENTAGE) of tokens associated with a position are used to incentivize arbs (x)
  /// @dev During a 2 week period the reward ratio will move from 0% to 100% (* x)
  function arbRestake(uint256 _id)
    external
    override
    whenNotPaused
    returns (uint256 _sher, uint256 _arbReward)
  {
    address nftOwner = ownerOf(_id);

    // Returns the stake shares that an arb would get, and whether the position can currently be arbed
    (uint256 arbRewardShares, bool able) = _calcSharesForArbRestake(_id);
    // Revert if not able to be arbed
    if (!able) revert InvalidConditions();

    // Transfers USDC to the arbitrager based on the stake shares associated with the arb reward
    // Also burns the requisite amount of shares associated with this NFT position
    // Returns the amount of USDC paid to the arbitrager
    _arbReward = _redeemShares(_id, arbRewardShares, msg.sender);

    // Restakes the tokens (USDC) associated with this position for the ARB_RESTAKE_PERIOD (26 weeks)
    // Sends previously earned SHER rewards to the NFT owner address
    _sher = _restake(_id, ARB_RESTAKE_PERIOD, nftOwner);

    emit ArbRestaked(_id, _arbReward);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import './ISherlockStake.sol';
import './ISherlockGov.sol';
import './ISherlockPayout.sol';
import './ISherlockStrategy.sol';

interface ISherlock is ISherlockStake, ISherlockGov, ISherlockPayout, ISherlockStrategy, IERC721 {
  // msg.sender is not authorized to call this function
  error Unauthorized();

  // An address or other value passed in is equal to zero (and shouldn't be)
  error ZeroArgument();

  // Occurs when a value already holds the desired property, or is not whitelisted
  error InvalidArgument();

  // Required conditions are not true/met
  error InvalidConditions();

  // If the SHER tokens held in a contract are not the value they are supposed to be
  error InvalidSherAmount(uint256 expected, uint256 actual);

  // Checks the ERC-721 functions _exists() to see if an NFT ID actually exists and errors if not
  error NonExistent();

  event ArbRestaked(uint256 indexed tokenID, uint256 reward);

  event Restaked(uint256 indexed tokenID);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

/// @title Sherlock core interface for stakers
/// @author Evert Kors
interface ISherlockStake {
  /// @notice View the current lockup end timestamp of `_tokenID`
  /// @return Timestamp when NFT position unlocks
  function lockupEnd(uint256 _tokenID) external view returns (uint256);

  /// @notice View the current SHER reward of `_tokenID`
  /// @return Amount of SHER rewarded to owner upon reaching the end of the lockup
  function sherRewards(uint256 _tokenID) external view returns (uint256);

  /// @notice View the current token balance claimable upon reaching end of the lockup
  /// @return Amount of tokens assigned to owner when unstaking position
  function tokenBalanceOf(uint256 _tokenID) external view returns (uint256);

  /// @notice View the current TVL for all stakers
  /// @return Total amount of tokens staked
  /// @dev Adds principal + strategy + premiums
  /// @dev Will calculate the most up to date value for each piece
  function totalTokenBalanceStakers() external view returns (uint256);

  /// @notice Stakes `_amount` of tokens and locks up for `_period` seconds, `_receiver` will receive the NFT receipt
  /// @param _amount Amount of tokens to stake
  /// @param _period Period of time, in seconds, to lockup your funds
  /// @param _receiver Address that will receive the NFT representing the position
  /// @return _id ID of the position
  /// @return _sher Amount of SHER tokens to be released to this ID after `_period` ends
  /// @dev `_period` needs to be whitelisted
  function initialStake(
    uint256 _amount,
    uint256 _period,
    address _receiver
  ) external returns (uint256 _id, uint256 _sher);

  /// @notice Redeem NFT `_id` and receive `_amount` of tokens
  /// @param _id TokenID of the position
  /// @return _amount Amount of tokens (USDC) owed to NFT ID
  /// @dev Only the owner of `_id` will be able to redeem their position
  /// @dev The SHER rewards are sent to the NFT owner
  /// @dev Can only be called after lockup `_period` has ended
  function redeemNFT(uint256 _id) external returns (uint256 _amount);

  /// @notice Owner restakes position with ID: `_id` for `_period` seconds
  /// @param _id ID of the position
  /// @param _period Period of time, in seconds, to lockup your funds
  /// @return _sher Amount of SHER tokens to be released to owner address after `_period` ends
  /// @dev Only the owner of `_id` will be able to restake their position using this call
  /// @dev `_period` needs to be whitelisted
  /// @dev Can only be called after lockup `_period` has ended
  function ownerRestake(uint256 _id, uint256 _period) external returns (uint256 _sher);

  /// @notice Allows someone who doesn't own the position (an arbitrager) to restake the position for 26 weeks (ARB_RESTAKE_PERIOD)
  /// @param _id ID of the position
  /// @return _sher Amount of SHER tokens to be released to position owner on expiry of the 26 weeks lockup
  /// @return _arbReward Amount of tokens (USDC) sent to caller (the arbitrager) in return for calling the function
  /// @dev Can only be called after lockup `_period` is more than 2 weeks in the past (assuming ARB_RESTAKE_WAIT_TIME is 2 weeks)
  /// @dev Max 20% (ARB_RESTAKE_MAX_PERCENTAGE) of tokens associated with a position are used to incentivize arbs (x)
  /// @dev During a 2 week period the reward ratio will move from 0% to 100% (* x)
  function arbRestake(uint256 _id) external returns (uint256 _sher, uint256 _arbReward);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import './managers/ISherDistributionManager.sol';
import './managers/ISherlockProtocolManager.sol';
import './managers/ISherlockClaimManager.sol';
import './managers/IStrategyManager.sol';

/// @title Sherlock core interface for governance
/// @author Evert Kors
interface ISherlockGov {
  event ClaimPayout(address receiver, uint256 amount);
  event YieldStrategyUpdateWithdrawAllError(bytes error);
  event YieldStrategyUpdated(IStrategyManager previous, IStrategyManager current);
  event ProtocolManagerUpdated(ISherlockProtocolManager previous, ISherlockProtocolManager current);
  event ClaimManagerUpdated(ISherlockClaimManager previous, ISherlockClaimManager current);
  event NonStakerAddressUpdated(address previous, address current);
  event SherDistributionManagerUpdated(
    ISherDistributionManager previous,
    ISherDistributionManager current
  );

  event StakingPeriodEnabled(uint256 period);

  event StakingPeriodDisabled(uint256 period);

  /// @notice Allows stakers to stake for `_period` of time
  /// @param _period Period of time, in seconds,
  /// @dev should revert if already enabled
  function enableStakingPeriod(uint256 _period) external;

  /// @notice Disallow stakers to stake for `_period` of time
  /// @param _period Period of time, in seconds,
  /// @dev should revert if already disabled
  function disableStakingPeriod(uint256 _period) external;

  /// @notice View if `_period` is a valid period
  /// @return Boolean indicating if period is valid
  function stakingPeriods(uint256 _period) external view returns (bool);

  /// @notice Update SHER distribution manager contract
  /// @param _sherDistributionManager New adddress of the manager
  function updateSherDistributionManager(ISherDistributionManager _sherDistributionManager)
    external;

  /// @notice Deletes the SHER distribution manager altogether (if Sherlock decides to no longer pay out SHER rewards)
  function removeSherDistributionManager() external;

  /// @notice Read SHER distribution manager
  /// @return Address of current SHER distribution manager
  function sherDistributionManager() external view returns (ISherDistributionManager);

  /// @notice Update address eligible for non staker rewards from protocol premiums
  /// @param _nonStakers Address eligible for non staker rewards
  function updateNonStakersAddress(address _nonStakers) external;

  /// @notice View current non stakers address
  /// @return Current non staker address
  /// @dev Is able to pull funds out of the contract
  function nonStakersAddress() external view returns (address);

  /// @notice View current address able to manage protocols
  /// @return Protocol manager implemenation
  function sherlockProtocolManager() external view returns (ISherlockProtocolManager);

  /// @notice Transfer protocol manager implementation address
  /// @param _protocolManager new implementation address
  function updateSherlockProtocolManager(ISherlockProtocolManager _protocolManager) external;

  /// @notice View current address able to pull payouts
  /// @return Address able to pull payouts
  function sherlockClaimManager() external view returns (ISherlockClaimManager);

  /// @notice Transfer claim manager role to different address
  /// @param _claimManager New address of claim manager
  function updateSherlockClaimManager(ISherlockClaimManager _claimManager) external;

  /// @notice Update yield strategy
  /// @param _yieldStrategy New address of the strategy
  /// @dev try a yieldStrategyWithdrawAll() on old, ignore failure
  function updateYieldStrategy(IStrategyManager _yieldStrategy) external;

  /// @notice Update yield strategy ignoring current state
  /// @param _yieldStrategy New address of the strategy
  /// @dev tries a yieldStrategyWithdrawAll() on old strategy, ignore failure
  function updateYieldStrategyForce(IStrategyManager _yieldStrategy) external;

  /// @notice Read current strategy
  /// @return Address of current strategy
  /// @dev can never be address(0)
  function yieldStrategy() external view returns (IStrategyManager);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

/// @title Sherlock interface for payout manager
/// @author Evert Kors
interface ISherlockPayout {
  /// @notice Initiate a payout of `_amount` to `_receiver`
  /// @param _receiver Receiver of payout
  /// @param _amount Amount to send
  /// @dev only payout manager should call this
  /// @dev should pull money out of strategy
  function payoutClaim(address _receiver, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import './managers/IStrategyManager.sol';

/// @title Sherlock core interface for yield strategy
/// @author Evert Kors
interface ISherlockStrategy {
  /// @notice Deposit `_amount` into active strategy
  /// @param _amount Amount of tokens
  /// @dev gov only
  function yieldStrategyDeposit(uint256 _amount) external;

  /// @notice Withdraw `_amount` from active strategy
  /// @param _amount Amount of tokens
  /// @dev gov only
  function yieldStrategyWithdraw(uint256 _amount) external;

  /// @notice Withdraw all funds from active strategy
  /// @dev gov only
  function yieldStrategyWithdrawAll() external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './IManager.sol';

interface ISherDistributionManager is IManager {
  // anyone can just send token to this contract to fund rewards

  event Initialized(uint256 maxRewardsEndTVL, uint256 zeroRewardsStartTVL, uint256 maxRewardRate);

  /// @notice Caller will receive `_sher` SHER tokens based on `_amount` and `_period`
  /// @param _amount Amount of tokens (in USDC) staked
  /// @param _period Period of time for stake, in seconds
  /// @param _id ID for this NFT position
  /// @param _receiver Address that will be linked to this position
  /// @return _sher Amount of SHER tokens sent to Sherlock core contract
  /// @dev Calling contract will depend on before + after balance diff and return value
  /// @dev INCLUDES stake in calculation, function expects the `_amount` to be deposited already
  /// @dev If tvl=50 and amount=50, this means it is calculating SHER rewards for the first 50 tokens going in
  function pullReward(
    uint256 _amount,
    uint256 _period,
    uint256 _id,
    address _receiver
  ) external returns (uint256 _sher);

  /// @notice Calculates how many `_sher` SHER tokens are owed to a stake position based on `_amount` and `_period`
  /// @param _tvl TVL to use for reward calculation (pre-stake TVL)
  /// @param _amount Amount of tokens (USDC) staked
  /// @param _period Stake period (in seconds)
  /// @return _sher Amount of SHER tokens owed to this stake position
  /// @dev EXCLUDES `_amount` of stake, this will be added on top of TVL (_tvl is excluding _amount)
  /// @dev If tvl=0 and amount=50, it would calculate for the first 50 tokens going in (different from pullReward())
  function calcReward(
    uint256 _tvl,
    uint256 _amount,
    uint256 _period
  ) external view returns (uint256 _sher);

  /// @notice Function used to check if this is the current active distribution manager
  /// @return Boolean indicating it's active
  /// @dev If inactive the owner can pull all ERC20s and ETH
  /// @dev Will be checked by calling the sherlock contract
  function isActive() external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import './IManager.sol';

/// @title Sherlock core interface for protocols
/// @author Evert Kors
interface ISherlockProtocolManager is IManager {
  // msg.sender is not authorized to call this function
  error Unauthorized();

  // If a protocol was never instantiated or was removed and the claim deadline has passed, this error is returned
  error ProtocolNotExists(bytes32 protocol);

  // When comparing two arrays and the lengths are not equal (but are supposed to be equal)
  error UnequalArrayLength();

  // If there is not enough balance in the contract for the amount requested (after any requirements are met), this is returned
  error InsufficientBalance(bytes32 protocol);

  event MinBalance(uint256 previous, uint256 current);

  event AccountingError(bytes32 indexed protocol, uint256 amount, uint256 insufficientTokens);

  event ProtocolAdded(bytes32 indexed protocol);

  event ProtocolRemovedByArb(bytes32 indexed protocol, address arb, uint256 profit);

  event ProtocolRemoved(bytes32 indexed protocol);

  event ProtocolUpdated(
    bytes32 indexed protocol,
    bytes32 coverage,
    uint256 nonStakers,
    uint256 coverageAmount
  );

  event ProtocolAgentTransfer(bytes32 indexed protocol, address from, address to);

  event ProtocolBalanceDeposited(bytes32 indexed protocol, uint256 amount);

  event ProtocolBalanceWithdrawn(bytes32 indexed protocol, uint256 amount);

  event ProtocolPremiumChanged(bytes32 indexed protocol, uint256 oldPremium, uint256 newPremium);

  /// @notice View current amount of all premiums that are owed to stakers
  /// @return Premiums claimable
  /// @dev Will increase every block
  /// @dev base + (now - last_settled) * ps
  function claimablePremiums() external view returns (uint256);

  /// @notice Transfer current claimable premiums (for stakers) to core Sherlock address
  /// @dev Callable by everyone
  /// @dev Funds will be transferred to Sherlock core contract
  function claimPremiumsForStakers() external;

  /// @notice View current protocolAgent of `_protocol`
  /// @param _protocol Protocol identifier
  /// @return Address able to submit claims
  function protocolAgent(bytes32 _protocol) external view returns (address);

  /// @notice View current premium of protocol
  /// @param _protocol Protocol identifier
  /// @return Amount of premium `_protocol` pays per second
  function premium(bytes32 _protocol) external view returns (uint256);

  /// @notice View current active balance of covered protocol
  /// @param _protocol Protocol identifier
  /// @return Active balance
  /// @dev Accrued debt is subtracted from the stored active balance
  function activeBalance(bytes32 _protocol) external view returns (uint256);

  /// @notice View seconds of coverage left for `_protocol` before it runs out of active balance
  /// @param _protocol Protocol identifier
  /// @return Seconds of coverage left
  function secondsOfCoverageLeft(bytes32 _protocol) external view returns (uint256);

  /// @notice Add a new protocol to Sherlock
  /// @param _protocol Protocol identifier
  /// @param _protocolAgent Address able to submit a claim on behalf of the protocol
  /// @param _coverage Hash referencing the active coverage agreement
  /// @param _nonStakers Percentage of premium payments to nonstakers, scaled by 10**18
  /// @param _coverageAmount Max amount claimable by this protocol
  /// @dev Adding a protocol allows the `_protocolAgent` to submit a claim
  /// @dev Coverage is not started yet as the protocol doesn't pay a premium at this point
  /// @dev `_nonStakers` is scaled by 10**18
  /// @dev Only callable by governance
  function protocolAdd(
    bytes32 _protocol,
    address _protocolAgent,
    bytes32 _coverage,
    uint256 _nonStakers,
    uint256 _coverageAmount
  ) external;

  /// @notice Update info regarding a protocol
  /// @param _protocol Protocol identifier
  /// @param _coverage Hash referencing the active coverage agreement
  /// @param _nonStakers Percentage of premium payments to nonstakers, scaled by 10**18
  /// @param _coverageAmount Max amount claimable by this protocol
  /// @dev Only callable by governance
  function protocolUpdate(
    bytes32 _protocol,
    bytes32 _coverage,
    uint256 _nonStakers,
    uint256 _coverageAmount
  ) external;

  /// @notice Remove a protocol from coverage
  /// @param _protocol Protocol identifier
  /// @dev Before removing a protocol the premium must be 0
  /// @dev Removing a protocol basically stops the `_protocolAgent` from being active (can still submit claims until claim deadline though)
  /// @dev Pays off debt + sends remaining balance to protocol agent
  /// @dev This call should be subject to a timelock
  /// @dev Only callable by governance
  function protocolRemove(bytes32 _protocol) external;

  /// @notice Remove a protocol with insufficient active balance
  /// @param _protocol Protocol identifier
  function forceRemoveByActiveBalance(bytes32 _protocol) external;

  /// @notice Removes a protocol with insufficent seconds of coverage left
  /// @param _protocol Protocol identifier
  function forceRemoveBySecondsOfCoverage(bytes32 _protocol) external;

  /// @notice View minimal balance needed before liquidation can start
  /// @return Minimal balance needed
  function minActiveBalance() external view returns (uint256);

  /// @notice Sets the minimum active balance before an arb can remove a protocol
  /// @param _minActiveBalance Minimum balance needed (in USDC)
  /// @dev Only gov
  function setMinActiveBalance(uint256 _minActiveBalance) external;

  /// @notice Set premium of `_protocol` to `_premium`
  /// @param _protocol Protocol identifier
  /// @param _premium Amount of premium `_protocol` pays per second
  /// @dev The value 0 would mean inactive coverage
  /// @dev Only callable by governance
  function setProtocolPremium(bytes32 _protocol, uint256 _premium) external;

  /// @notice Set premium of multiple protocols
  /// @param _protocol Array of protocol identifiers
  /// @param _premium Array of premium amounts protocols pay per second
  /// @dev The value 0 would mean inactive coverage
  /// @dev Only callable by governance
  function setProtocolPremiums(bytes32[] calldata _protocol, uint256[] calldata _premium) external;

  /// @notice Deposits `_amount` of token to the active balance of `_protocol`
  /// @param _protocol Protocol identifier
  /// @param _amount Amount of tokens to deposit
  /// @dev Approval should be made before calling
  function depositToActiveBalance(bytes32 _protocol, uint256 _amount) external;

  /// @notice Withdraws `_amount` of token from the active balance of `_protocol`
  /// @param _protocol Protocol identifier
  /// @param _amount Amount of tokens to withdraw
  /// @dev Only protocol agent is able to withdraw
  /// @dev Balance can be withdrawn up until 7 days worth of active balance
  function withdrawActiveBalance(bytes32 _protocol, uint256 _amount) external;

  /// @notice Transfer protocol agent role
  /// @param _protocol Protocol identifier
  /// @param _protocolAgent Account able to submit a claim on behalf of the protocol
  /// @dev Only the active protocolAgent is able to transfer the role
  function transferProtocolAgent(bytes32 _protocol, address _protocolAgent) external;

  /// @notice View the amount nonstakers can claim from this protocol
  /// @param _protocol Protocol identifier
  /// @return Amount of tokens claimable by nonstakers
  /// @dev this reads from a storage variable + (now-lastsettled) * premiums
  function nonStakersClaimable(bytes32 _protocol) external view returns (uint256);

  /// @notice Choose an `_amount` of tokens that nonstakers (`_receiver` address) will receive from `_protocol`
  /// @param _protocol Protocol identifier
  /// @param _amount Amount of tokens
  /// @param _receiver Address to receive tokens
  /// @dev Only callable by nonstakers role
  function nonStakersClaim(
    bytes32 _protocol,
    uint256 _amount,
    address _receiver
  ) external;

  /// @param _protocol Protocol identifier
  /// @return current and previous are the current and previous coverage amounts for this protocol
  function coverageAmounts(bytes32 _protocol)
    external
    view
    returns (uint256 current, uint256 previous);

  /// @notice Function used to check if this is the current active protocol manager
  /// @return Boolean indicating it's active
  /// @dev If inactive the owner can pull all ERC20s and ETH
  /// @dev Will be checked by calling the sherlock contract
  function isActive() external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './callbacks/ISherlockClaimManagerCallbackReceiver.sol';
import '../UMAprotocol/OptimisticRequester.sol';
import './IManager.sol';

interface ISherlockClaimManager is IManager, OptimisticRequester {
  // Doesn't allow a new claim to be submitted by a protocol agent if a claim is already active for that protocol
  error ClaimActive();

  // If the current state of a claim does not match the expected state, this error is thrown
  error InvalidState();

  event ClaimCreated(
    uint256 claimID,
    bytes32 indexed protocol,
    uint256 amount,
    address receiver,
    bool previousCoverageUsed
  );

  event CallbackAdded(ISherlockClaimManagerCallbackReceiver callback);

  event CallbackRemoved(ISherlockClaimManagerCallbackReceiver callback);

  event ClaimStatusChanged(uint256 indexed claimID, State previousState, State currentState);

  event ClaimPayout(uint256 claimID, address receiver, uint256 amount);

  event ClaimHalted(uint256 claimID);

  event UMAHORenounced();

  enum State {
    NonExistent, // Claim doesn't exist (this is the default state on creation)
    SpccPending, // Claim is created, SPCC is able to set state to valid
    SpccApproved, // Final state, claim is valid
    SpccDenied, // Claim denied by SPCC, claim can be escalated within 4 weeks
    UmaPriceProposed, // Price is proposed but not escalated
    ReadyToProposeUmaDispute, // Price is proposed, callback received, ready to submit dispute
    UmaDisputeProposed, // Escalation is done, waiting for confirmation
    UmaPending, // Claim is escalated, in case Spcc denied or didn't act within 7 days.
    UmaApproved, // Final state, claim is valid, claim can be enacted after 1 day, umaHaltOperator has 1 day to change to denied
    UmaDenied, // Final state, claim is invalid
    Halted, // UMAHO can halt claim if state is UmaApproved
    Cleaned // Claim is removed by protocol agent
  }

  struct Claim {
    uint256 created;
    uint256 updated;
    address initiator;
    bytes32 protocol;
    uint256 amount;
    address receiver;
    uint32 timestamp;
    State state;
    bytes ancillaryData;
  }

  // requestAndProposePriceFor() --> proposer = sherlockCore (address to receive BOND if UMA denies claim)
  // disputePriceFor() --> disputer = protocolAgent
  // priceSettled will be the the callback that contains the main data

  // Assume BOND = 9600, UMA's final fee = 1500.
  // Claim initiator (Sherlock) has to pay 22.2k to dispute a claim,
  // so we will execute a safeTransferFrom(claimInitiator, address(this), 22.2k).
  // We need to approve the contract 22.2k as it will be transferred from address(this).

  // The 22.2k consists of 2 * (BOND + final fee charged by UMA), as follows:
  // 1. On requestAndProposePriceFor(), the fee will be 10k: 9600 BOND + 1500 UMA's final fee;
  // 2. On disputePriceFor(), the fee will be the same 10k.
  // note that half of the BOND (4800) + UMA's final fee (1500) is "burnt" and sent to UMA

  // UMA's final fee can be changed in the future, which may result in lower or higher required staked amounts for escalating a claim.

  // On settle, either the protocolAgent (dispute success) or sherlockCore (dispute failure)
  // will receive 9600 + 4800 + 1500 = 15900. In addition, the protocolAgent will be entitled to
  // the claimAmount if the dispute is successful/

  // lastClaimID <-- starts with 0, so initial id = 1
  // have claim counter, easy to identify certain claims by their number
  // but use hash(callback.request.propose + callback.timestamp) as the internal UUID to handle the callbacks

  // So SPCC and UMAHO are hardcoded (UMAHO can be renounced)
  // In case these need to be updated, deploy different contract and upgrade it on the sherlock gov side.

  // On price proposed callback --> call disputePriceFor with callbackdata + sherlock.strategyManager() and address(this)

  /// @notice `SHERLOCK_CLAIM` in utf8
  function UMA_IDENTIFIER() external view returns (bytes32);

  function sherlockProtocolClaimsCommittee() external view returns (address);

  /// @notice operator is able to deny approved UMA claims
  function umaHaltOperator() external view returns (address);

  /// @notice gov is able to renounce the role
  function renounceUmaHaltOperator() external;

  function claim(uint256 _claimID) external view returns (Claim memory);

  /// @notice Initiate a claim for a specific protocol as the protocol agent
  /// @param _protocol protocol ID (different from the internal or public claim ID fields)
  /// @param _amount amount of USDC which is being claimed by the protocol
  /// @param _receiver address to receive the amount of USDC being claimed
  /// @param _timestamp timestamp at which the exploit first occurred
  /// @param ancillaryData other data associated with the claim, such as the coverage agreement
  /// @dev The protocol agent that starts a claim will be the protocol agent during the claims lifecycle
  /// @dev Even if the protocol agent role is tranferred during the lifecycle
  function startClaim(
    bytes32 _protocol,
    uint256 _amount,
    address _receiver,
    uint32 _timestamp,
    bytes memory ancillaryData
  ) external;

  function spccApprove(uint256 _claimID) external;

  function spccRefuse(uint256 _claimID) external;

  /// @notice Callable by protocol agent
  /// @param _claimID Public claim ID
  /// @param _amount Bond amount sent by protocol agent
  /// @dev Use hardcoded USDC address
  /// @dev Use hardcoded bond amount
  /// @dev Use hardcoded liveness 7200 (2 hours)
  /// @dev proposedPrice = _amount
  function escalate(uint256 _claimID, uint256 _amount) external;

  /// @notice Execute claim, storage will be removed after
  /// @param _claimID Public ID of the claim
  /// @dev Needs to be SpccApproved or UmaApproved && >UMAHO_TIME
  /// @dev Funds will be pulled from core
  function payoutClaim(uint256 _claimID) external;

  /// @notice UMAHO is able to execute a halt if the state is UmaApproved and state was updated less than UMAHO_TIME ago
  function executeHalt(uint256 _claimID) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import './IManager.sol';

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IStrategyManager is IManager {
  /// @return Returns the token type being deposited into a strategy
  function want() external view returns (IERC20);

  /// @notice Withdraws all USDC from the strategy back into the Sherlock core contract
  /// @dev Only callable by the Sherlock core contract
  /// @return The final amount withdrawn
  function withdrawAll() external returns (uint256);

  /// @notice Withdraws a specific amount of USDC from the strategy back into the Sherlock core contract
  /// @param _amount Amount of USDC to withdraw
  function withdraw(uint256 _amount) external;

  /// @notice Deposits all USDC held in this contract into the strategy
  function deposit() external;

  /// @return Returns the USDC balance in this contract
  function balanceOf() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '../ISherlock.sol';

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IManager {
  // An address or other value passed in is equal to zero (and shouldn't be)
  error ZeroArgument();

  // Occurs when a value already holds the desired property, or is not whitelisted
  error InvalidArgument();

  // If a required condition for executing the function is not met, it reverts and throws this error
  error InvalidConditions();

  // Throws if the msg.sender is not the required address
  error InvalidSender();

  event SherlockCoreSet(ISherlock sherlock);

  /// @notice Set sherlock core address where premiums should be send too
  /// @param _sherlock Current core contract
  /// @dev Only deployer is able to set core address on all chains except Hardhat network
  /// @dev One time function, will revert once `sherlock` != address(0)
  /// @dev This contract will be deployed first, passed on as argument in core constuctor
  /// @dev ^ that's needed for tvl accounting, once core is deployed this function is called
  /// @dev emits `SherlockCoreSet`
  function setSherlockCoreAddress(ISherlock _sherlock) external;

  /// @notice Pause external functions in contract
  function pause() external;

  /// @notice Unpause external functions in contract
  function unpause() external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

interface ISherlockClaimManagerCallbackReceiver {
  /// @notice Calls this function on approved contracts and passes args
  /// @param _protocol The protocol that is receiving the payout
  /// @param _claimID The claim ID that is receiving the payout
  /// @param _amount The amount of USDC being paid out for this claim
  function PreCorePayoutCallback(
    bytes32 _protocol,
    uint256 _claimID,
    uint256 _amount
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import './SkinnyOptimisticOracleInterface.sol';

/**
 * @title Optimistic Requester.
 * @notice Optional interface that requesters can implement to receive callbacks.
 * @dev This contract does _not_ work with ERC777 collateral currencies or any others that call into the receiver on
 * transfer(). Using an ERC777 token would allow a user to maliciously grief other participants (while also losing
 * money themselves).
 */
interface OptimisticRequester {
  /**
   * @notice Callback for proposals.
   * @param identifier price identifier being requested.
   * @param timestamp timestamp of the price being requested.
   * @param ancillaryData ancillary data of the price being requested.
   * @param request request params after proposal.
   */
  function priceProposed(
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    SkinnyOptimisticOracleInterface.Request memory request
  ) external;

  /**
   * @notice Callback for disputes.
   * @param identifier price identifier being requested.
   * @param timestamp timestamp of the price being requested.
   * @param ancillaryData ancillary data of the price being requested.
   * @param request request params after dispute.
   */
  function priceDisputed(
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    SkinnyOptimisticOracleInterface.Request memory request
  ) external;

  /**
   * @notice Callback for settlement.
   * @param identifier price identifier being requested.
   * @param timestamp timestamp of the price being requested.
   * @param ancillaryData ancillary data of the price being requested.
   * @param request request params after settlement.
   */
  function priceSettled(
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    SkinnyOptimisticOracleInterface.Request memory request
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './OptimisticOracleInterface.sol';

/**
 * @title Interface for the gas-cost-reduced version of the OptimisticOracle.
 * @notice Differences from normal OptimisticOracle:
 * - refundOnDispute: flag is removed, by default there are no refunds on disputes.
 * - customizing request parameters: In the OptimisticOracle, parameters like `bond` and `customLiveness` can be reset
 *   after a request is already made via `requestPrice`. In the SkinnyOptimisticOracle, these parameters can only be
 *   set in `requestPrice`, which has an expanded input set.
 * - settleAndGetPrice: Replaced by `settle`, which can only be called once per settleable request. The resolved price
 *   can be fetched via the `Settle` event or the return value of `settle`.
 * - general changes to interface: Functions that interact with existing requests all require the parameters of the
 *   request to modify to be passed as input. These parameters must match with the existing request parameters or the
 *   function will revert. This change reflects the internal refactor to store hashed request parameters instead of the
 *   full request struct.
 * @dev Interface used by financial contracts to interact with the Oracle. Voters will use a different interface.
 */
abstract contract SkinnyOptimisticOracleInterface {
  event RequestPrice(
    address indexed requester,
    bytes32 indexed identifier,
    uint32 timestamp,
    bytes ancillaryData,
    Request request
  );
  event ProposePrice(
    address indexed requester,
    bytes32 indexed identifier,
    uint32 timestamp,
    bytes ancillaryData,
    Request request
  );
  event DisputePrice(
    address indexed requester,
    bytes32 indexed identifier,
    uint32 timestamp,
    bytes ancillaryData,
    Request request
  );
  event Settle(
    address indexed requester,
    bytes32 indexed identifier,
    uint32 timestamp,
    bytes ancillaryData,
    Request request
  );
  // Struct representing a price request. Note that this differs from the OptimisticOracleInterface's Request struct
  // in that refundOnDispute is removed.
  struct Request {
    address proposer; // Address of the proposer.
    address disputer; // Address of the disputer.
    IERC20 currency; // ERC20 token used to pay rewards and fees.
    bool settled; // True if the request is settled.
    int256 proposedPrice; // Price that the proposer submitted.
    int256 resolvedPrice; // Price resolved once the request is settled.
    uint256 expirationTime; // Time at which the request auto-settles without a dispute.
    uint256 reward; // Amount of the currency to pay to the proposer on settlement.
    uint256 finalFee; // Final fee to pay to the Store upon request to the DVM.
    uint256 bond; // Bond that the proposer and disputer must pay on top of the final fee.
    uint256 customLiveness; // Custom liveness value set by the requester.
  }

  // This value must be <= the Voting contract's `ancillaryBytesLimit` value otherwise it is possible
  // that a price can be requested to this contract successfully, but cannot be disputed because the DVM refuses
  // to accept a price request made with ancillary data length over a certain size.
  uint256 public constant ancillaryBytesLimit = 8192;

  /**
   * @notice Requests a new price.
   * @param identifier price identifier being requested.
   * @param timestamp timestamp of the price being requested.
   * @param ancillaryData ancillary data representing additional args being passed with the price request.
   * @param currency ERC20 token used for payment of rewards and fees. Must be approved for use with the DVM.
   * @param reward reward offered to a successful proposer. Will be pulled from the caller. Note: this can be 0,
   *               which could make sense if the contract requests and proposes the value in the same call or
   *               provides its own reward system.
   * @param bond custom proposal bond to set for request. If set to 0, defaults to the final fee.
   * @param customLiveness custom proposal liveness to set for request.
   * @return totalBond default bond + final fee that the proposer and disputer will be required to pay.
   */
  function requestPrice(
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    IERC20 currency,
    uint256 reward,
    uint256 bond,
    uint256 customLiveness
  ) external virtual returns (uint256 totalBond);

  /**
   * @notice Proposes a price value on another address' behalf. Note: this address will receive any rewards that come
   * from this proposal. However, any bonds are pulled from the caller.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param request price request parameters whose hash must match the request that the caller wants to
   * propose a price for.
   * @param proposer address to set as the proposer.
   * @param proposedPrice price being proposed.
   * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
   * the proposer once settled if the proposal is correct.
   */
  function proposePriceFor(
    address requester,
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    Request memory request,
    address proposer,
    int256 proposedPrice
  ) public virtual returns (uint256 totalBond);

  /**
   * @notice Proposes a price value where caller is the proposer.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param request price request parameters whose hash must match the request that the caller wants to
   * propose a price for.
   * @param proposedPrice price being proposed.
   * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
   * the proposer once settled if the proposal is correct.
   */
  function proposePrice(
    address requester,
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    Request memory request,
    int256 proposedPrice
  ) external virtual returns (uint256 totalBond);

  /**
   * @notice Combines logic of requestPrice and proposePrice while taking advantage of gas savings from not having to
   * overwrite Request params that a normal requestPrice() => proposePrice() flow would entail. Note: The proposer
   * will receive any rewards that come from this proposal. However, any bonds are pulled from the caller.
   * @dev The caller is the requester, but the proposer can be customized.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param currency ERC20 token used for payment of rewards and fees. Must be approved for use with the DVM.
   * @param reward reward offered to a successful proposer. Will be pulled from the caller. Note: this can be 0,
   *               which could make sense if the contract requests and proposes the value in the same call or
   *               provides its own reward system.
   * @param bond custom proposal bond to set for request. If set to 0, defaults to the final fee.
   * @param customLiveness custom proposal liveness to set for request.
   * @param proposer address to set as the proposer.
   * @param proposedPrice price being proposed.
   * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
   * the proposer once settled if the proposal is correct.
   */
  function requestAndProposePriceFor(
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    IERC20 currency,
    uint256 reward,
    uint256 bond,
    uint256 customLiveness,
    address proposer,
    int256 proposedPrice
  ) external virtual returns (uint256 totalBond);

  /**
   * @notice Disputes a price request with an active proposal on another address' behalf. Note: this address will
   * receive any rewards that come from this dispute. However, any bonds are pulled from the caller.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param request price request parameters whose hash must match the request that the caller wants to
   * dispute.
   * @param disputer address to set as the disputer.
   * @param requester sender of the initial price request.
   * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
   * the disputer once settled if the dispute was valid (the proposal was incorrect).
   */
  function disputePriceFor(
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    Request memory request,
    address disputer,
    address requester
  ) public virtual returns (uint256 totalBond);

  /**
   * @notice Disputes a price request with an active proposal where caller is the disputer.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param request price request parameters whose hash must match the request that the caller wants to
   * dispute.
   * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
   * the disputer once settled if the dispute was valid (the proposal was incorrect).
   */
  function disputePrice(
    address requester,
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    Request memory request
  ) external virtual returns (uint256 totalBond);

  /**
   * @notice Attempts to settle an outstanding price request. Will revert if it isn't settleable.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param request price request parameters whose hash must match the request that the caller wants to
   * settle.
   * @return payout the amount that the "winner" (proposer or disputer) receives on settlement. This amount includes
   * the returned bonds as well as additional rewards.
   * @return resolvedPrice the price that the request settled to.
   */
  function settle(
    address requester,
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    Request memory request
  ) external virtual returns (uint256 payout, int256 resolvedPrice);

  /**
   * @notice Computes the current state of a price request. See the State enum for more details.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param request price request parameters.
   * @return the State.
   */
  function getState(
    address requester,
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    Request memory request
  ) external virtual returns (OptimisticOracleInterface.State);

  /**
   * @notice Checks if a given request has resolved, expired or been settled (i.e the optimistic oracle has a price).
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param request price request parameters. The hash of these parameters must match with the request hash that is
   * associated with the price request unique ID {requester, identifier, timestamp, ancillaryData}, or this method
   * will revert.
   * @return boolean indicating true if price exists and false if not.
   */
  function hasPrice(
    address requester,
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    Request memory request
  ) public virtual returns (bool);

  /**
   * @notice Generates stamped ancillary data in the format that it would be used in the case of a price dispute.
   * @param ancillaryData ancillary data of the price being requested.
   * @param requester sender of the initial price request.
   * @return the stamped ancillary bytes.
   */
  function stampAncillaryData(bytes memory ancillaryData, address requester)
    public
    pure
    virtual
    returns (bytes memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @title Financial contract facing Oracle interface.
 * @dev Interface used by financial contracts to interact with the Oracle. Voters will use a different interface.
 */
abstract contract OptimisticOracleInterface {
  // Struct representing the state of a price request.
  enum State {
    Invalid, // Never requested.
    Requested, // Requested, no other actions taken.
    Proposed, // Proposed, but not expired or disputed yet.
    Expired, // Proposed, not disputed, past liveness.
    Disputed, // Disputed, but no DVM price returned yet.
    Resolved, // Disputed and DVM price is available.
    Settled // Final price has been set in the contract (can get here from Expired or Resolved).
  }

  // Struct representing a price request.
  struct Request {
    address proposer; // Address of the proposer.
    address disputer; // Address of the disputer.
    IERC20 currency; // ERC20 token used to pay rewards and fees.
    bool settled; // True if the request is settled.
    bool refundOnDispute; // True if the requester should be refunded their reward on dispute.
    int256 proposedPrice; // Price that the proposer submitted.
    int256 resolvedPrice; // Price resolved once the request is settled.
    uint256 expirationTime; // Time at which the request auto-settles without a dispute.
    uint256 reward; // Amount of the currency to pay to the proposer on settlement.
    uint256 finalFee; // Final fee to pay to the Store upon request to the DVM.
    uint256 bond; // Bond that the proposer and disputer must pay on top of the final fee.
    uint256 customLiveness; // Custom liveness value set by the requester.
  }

  // This value must be <= the Voting contract's `ancillaryBytesLimit` value otherwise it is possible
  // that a price can be requested to this contract successfully, but cannot be disputed because the DVM refuses
  // to accept a price request made with ancillary data length over a certain size.
  uint256 public constant ancillaryBytesLimit = 8192;

  /**
   * @notice Requests a new price.
   * @param identifier price identifier being requested.
   * @param timestamp timestamp of the price being requested.
   * @param ancillaryData ancillary data representing additional args being passed with the price request.
   * @param currency ERC20 token used for payment of rewards and fees. Must be approved for use with the DVM.
   * @param reward reward offered to a successful proposer. Will be pulled from the caller. Note: this can be 0,
   *               which could make sense if the contract requests and proposes the value in the same call or
   *               provides its own reward system.
   * @return totalBond default bond (final fee) + final fee that the proposer and disputer will be required to pay.
   * This can be changed with a subsequent call to setBond().
   */
  function requestPrice(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData,
    IERC20 currency,
    uint256 reward
  ) external virtual returns (uint256 totalBond);

  /**
   * @notice Set the proposal bond associated with a price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param bond custom bond amount to set.
   * @return totalBond new bond + final fee that the proposer and disputer will be required to pay. This can be
   * changed again with a subsequent call to setBond().
   */
  function setBond(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData,
    uint256 bond
  ) external virtual returns (uint256 totalBond);

  /**
   * @notice Sets the request to refund the reward if the proposal is disputed. This can help to "hedge" the caller
   * in the event of a dispute-caused delay. Note: in the event of a dispute, the winner still receives the other's
   * bond, so there is still profit to be made even if the reward is refunded.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   */
  function setRefundOnDispute(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) external virtual;

  /**
   * @notice Sets a custom liveness value for the request. Liveness is the amount of time a proposal must wait before
   * being auto-resolved.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param customLiveness new custom liveness.
   */
  function setCustomLiveness(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData,
    uint256 customLiveness
  ) external virtual;

  /**
   * @notice Proposes a price value on another address' behalf. Note: this address will receive any rewards that come
   * from this proposal. However, any bonds are pulled from the caller.
   * @param proposer address to set as the proposer.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param proposedPrice price being proposed.
   * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
   * the proposer once settled if the proposal is correct.
   */
  function proposePriceFor(
    address proposer,
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData,
    int256 proposedPrice
  ) public virtual returns (uint256 totalBond);

  /**
   * @notice Proposes a price value for an existing price request.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param proposedPrice price being proposed.
   * @return totalBond the amount that's pulled from the proposer's wallet as a bond. The bond will be returned to
   * the proposer once settled if the proposal is correct.
   */
  function proposePrice(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData,
    int256 proposedPrice
  ) external virtual returns (uint256 totalBond);

  /**
   * @notice Disputes a price request with an active proposal on another address' behalf. Note: this address will
   * receive any rewards that come from this dispute. However, any bonds are pulled from the caller.
   * @param disputer address to set as the disputer.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
   * the disputer once settled if the dispute was value (the proposal was incorrect).
   */
  function disputePriceFor(
    address disputer,
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) public virtual returns (uint256 totalBond);

  /**
   * @notice Disputes a price value for an existing price request with an active proposal.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @return totalBond the amount that's pulled from the disputer's wallet as a bond. The bond will be returned to
   * the disputer once settled if the dispute was valid (the proposal was incorrect).
   */
  function disputePrice(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) external virtual returns (uint256 totalBond);

  /**
   * @notice Retrieves a price that was previously requested by a caller. Reverts if the request is not settled
   * or settleable. Note: this method is not view so that this call may actually settle the price request if it
   * hasn't been settled.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @return resolved price.
   */
  function settleAndGetPrice(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) external virtual returns (int256);

  /**
   * @notice Attempts to settle an outstanding price request. Will revert if it isn't settleable.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @return payout the amount that the "winner" (proposer or disputer) receives on settlement. This amount includes
   * the returned bonds as well as additional rewards.
   */
  function settle(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) external virtual returns (uint256 payout);

  /**
   * @notice Gets the current data structure containing all information about a price request.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @return the Request data structure.
   */
  function getRequest(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) public view virtual returns (Request memory);

  /**
   * @notice Returns the state of a price request.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @return the State enum value.
   */
  function getState(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) public view virtual returns (State);

  /**
   * @notice Checks if a given request has resolved or been settled (i.e the optimistic oracle has a price).
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @return true if price has resolved or settled, false otherwise.
   */
  function hasPrice(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) public view virtual returns (bool);

  function stampAncillaryData(bytes memory ancillaryData, address requester)
    public
    view
    virtual
    returns (bytes memory);
}