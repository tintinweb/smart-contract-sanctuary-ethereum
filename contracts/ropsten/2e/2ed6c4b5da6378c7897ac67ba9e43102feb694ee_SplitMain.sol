// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import {ISplitMain} from 'contracts/interfaces/ISplitMain.sol';
import {SplitWallet} from 'contracts/SplitWallet.sol';
import {Clones} from 'contracts/libraries/Clones.sol';
import {ERC20} from '@rari-capital/solmate/src/tokens/ERC20.sol';
import {SafeTransferLib} from '@rari-capital/solmate/src/utils/SafeTransferLib.sol';

/**

                                             █████████
                                          ███████████████                  █████████
                                         █████████████████               █████████████                 ███████
                                        ███████████████████             ███████████████               █████████
                                        ███████████████████             ███████████████              ███████████
                                        ███████████████████             ███████████████               █████████
                                         █████████████████               █████████████                 ███████
                                          ███████████████                  █████████
                                             █████████

                             ███████████
                          █████████████████                 █████████
                         ███████████████████             ███████████████                  █████████
                        █████████████████████           █████████████████               █████████████                ███████
                       ███████████████████████         ███████████████████             ███████████████              █████████
                       ███████████████████████         ███████████████████             ███████████████             ███████████
                       ███████████████████████         ███████████████████             ███████████████              █████████
                        █████████████████████           █████████████████               █████████████                ███████
                         ███████████████████              █████████████                   █████████
                          █████████████████                 █████████
                             ███████████

           ███████████
       ███████████████████                  ███████████
     ███████████████████████              ███████████████                  █████████
    █████████████████████████           ███████████████████             ███████████████               █████████
   ███████████████████████████         █████████████████████           █████████████████            █████████████              ███████
   ███████████████████████████        ███████████████████████         ███████████████████          ███████████████            █████████
   ███████████████████████████        ███████████████████████         ███████████████████          ███████████████           ███████████
   ███████████████████████████        ███████████████████████         ███████████████████          ███████████████            █████████
   ███████████████████████████         █████████████████████           █████████████████            █████████████              ███████
    █████████████████████████           ███████████████████              █████████████                █████████
      █████████████████████               ███████████████                  █████████
        █████████████████                   ███████████
           ███████████

                             ███████████
                          █████████████████                 █████████
                         ███████████████████             ███████████████                  █████████
                        █████████████████████           █████████████████               █████████████                ███████
                       ███████████████████████         ███████████████████             ███████████████              █████████
                       ███████████████████████         ███████████████████             ███████████████             ███████████
                       ███████████████████████         ███████████████████             ███████████████              █████████
                        █████████████████████           █████████████████               █████████████                ███████
                         ███████████████████              █████████████                   █████████
                          █████████████████                 █████████
                             ███████████

                                             █████████
                                          ███████████████                  █████████
                                         █████████████████               █████████████                 ███████
                                        ███████████████████             ███████████████               █████████
                                        ███████████████████             ███████████████              ███████████
                                        ███████████████████             ███████████████               █████████
                                         █████████████████               █████████████                 ███████
                                          ███████████████                  █████████
                                             █████████

 */

/**
 * ERRORS
 */

/// @notice Unauthorized sender `sender`
/// @param sender Transaction sender
error Unauthorized(address sender);
/// @notice Invalid number of accounts `accountsLength`, must have at least 2
/// @param accountsLength Length of accounts array
error InvalidSplit__TooFewAccounts(uint256 accountsLength);
/// @notice Array lengths of accounts & percentAllocations don't match (`accountsLength` != `allocationsLength`)
/// @param accountsLength Length of accounts array
/// @param allocationsLength Length of percentAllocations array
error InvalidSplit__AccountsAndAllocationsMismatch(
  uint256 accountsLength,
  uint256 allocationsLength
);
/// @notice Invalid percentAllocations sum `allocationsSum` must equal `PERCENTAGE_SCALE`
/// @param allocationsSum Sum of percentAllocations array
error InvalidSplit__InvalidAllocationsSum(uint32 allocationsSum);
/// @notice Invalid accounts ordering at `index`
/// @param index Index of out-of-order account
error InvalidSplit__AccountsOutOfOrder(uint256 index);
/// @notice Invalid percentAllocation of zero at `index`
/// @param index Index of zero percentAllocation
error InvalidSplit__AllocationMustBePositive(uint256 index);
/// @notice Invalid distributorFee `distributorFee` cannot be greater than 10% (1e5)
/// @param distributorFee Invalid distributorFee amount
error InvalidSplit__InvalidDistributorFee(uint32 distributorFee);
/// @notice Invalid hash `hash` from split data (accounts, percentAllocations, distributorFee)
/// @param hash Invalid hash
error InvalidSplit__InvalidHash(bytes32 hash);
/// @notice Invalid new controlling address `newController` for mutable split
/// @param newController Invalid new controller
error InvalidNewController(address newController);

/**
 * @title SplitMain
 * @author 0xSplits <[email protected]>
 * @notice A composable and gas-efficient protocol for deploying splitter contracts.
 * @dev Split recipients, ownerships, and keeper fees are stored onchain as calldata & re-passed as args / validated
 * via hashing when needed. Each split gets its own address & proxy for maximum composability with other contracts onchain.
 * For these proxies, we extended EIP-1167 Minimal Proxy Contract to avoid `DELEGATECALL` inside `receive()` to accept
 * hard gas-capped `sends` & `transfers`.
 */
contract SplitMain is ISplitMain {
  using SafeTransferLib for address;
  using SafeTransferLib for ERC20;

  /**
   * STRUCTS
   */

  /// @notice holds Split metadata
  struct Split {
    bytes32 hash;
    address controller;
    address newPotentialController;
  }

  /**
   * STORAGE
   */

  /**
   * STORAGE - CONSTANTS & IMMUTABLES
   */

  /// @notice constant to scale uints into percentages (1e6 == 100%)
  uint256 public constant PERCENTAGE_SCALE = 1e6;
  /// @notice maximum distributor fee; 1e5 = 10% * PERCENTAGE_SCALE
  uint256 internal constant MAX_DISTRIBUTOR_FEE = 1e5;
  /// @notice address of wallet implementation for split proxies
  address public immutable override walletImplementation;

  /**
   * STORAGE - VARIABLES - PRIVATE & INTERNAL
   */

  /// @notice mapping to account ETH balances
  mapping(address => uint256) internal ethBalances;
  /// @notice mapping to account ERC20 balances
  mapping(ERC20 => mapping(address => uint256)) internal erc20Balances;
  /// @notice mapping to Split metadata
  mapping(address => Split) internal splits;

  /**
   * MODIFIERS
   */

  /** @notice Reverts if the sender doesn't own the split `split`
   *  @param split Address to check for control
   */
  modifier onlySplitController(address split) {
    if (msg.sender != splits[split].controller) revert Unauthorized(msg.sender);
    _;
  }

  /** @notice Reverts if the sender isn't the new potential controller of split `split`
   *  @param split Address to check for new potential control
   */
  modifier onlySplitNewPotentialController(address split) {
    if (msg.sender != splits[split].newPotentialController)
      revert Unauthorized(msg.sender);
    _;
  }

  /** @notice Reverts if the split with recipients represented by `accounts` and `percentAllocations` is malformed
   *  @param accounts Ordered, unique list of addresses with ownership in the split
   *  @param percentAllocations Percent allocations associated with each address
   *  @param distributorFee Keeper fee paid by split to cover gas costs of distribution
   */
  modifier validSplit(
    address[] memory accounts,
    uint32[] memory percentAllocations,
    uint32 distributorFee
  ) {
    if (accounts.length < 2)
      revert InvalidSplit__TooFewAccounts(accounts.length);
    if (accounts.length != percentAllocations.length)
      revert InvalidSplit__AccountsAndAllocationsMismatch(
        accounts.length,
        percentAllocations.length
      );
    // _getSum should overflow if any percentAllocation[i] < 0
    if (_getSum(percentAllocations) != PERCENTAGE_SCALE)
      revert InvalidSplit__InvalidAllocationsSum(_getSum(percentAllocations));
    unchecked {
      // overflow should be impossible in for-loop index
      // cache accounts length to save gas
      uint256 loopLength = accounts.length - 1;
      for (uint256 i = 0; i < loopLength; ++i) {
        // overflow should be impossible in array access math
        if (accounts[i] >= accounts[i + 1])
          revert InvalidSplit__AccountsOutOfOrder(i);
        if (percentAllocations[i] == uint32(0))
          revert InvalidSplit__AllocationMustBePositive(i);
      }
      // overflow should be impossible in array access math with validated equal array lengths
      if (percentAllocations[loopLength] == uint32(0))
        revert InvalidSplit__AllocationMustBePositive(loopLength);
    }
    if (distributorFee > MAX_DISTRIBUTOR_FEE)
      revert InvalidSplit__InvalidDistributorFee(distributorFee);
    _;
  }

  /** @notice Reverts if `newController` is the zero address
   *  @param newController Proposed new controlling address
   */
  modifier validNewController(address newController) {
    if (newController == address(0)) revert InvalidNewController(newController);
    _;
  }

  /**
   * CONSTRUCTOR
   */

  constructor() {
    walletImplementation = address(new SplitWallet());
  }

  /**
   * FUNCTIONS
   */

  /**
   * FUNCTIONS - PUBLIC & EXTERNAL
   */

  /** @notice Receive ETH
   *  @dev Used by split proxies in `distributeETH` to transfer ETH to `SplitMain`
   *  Funds sent outside of `distributeETH` will be unrecoverable
   */
  receive() external payable {}

  /** @notice Creates a new split with recipients `accounts` with ownerships `percentAllocations`, a keeper fee for splitting of `distributorFee` and the controlling address `controller`
   *  @param accounts Ordered, unique list of addresses with ownership in the split
   *  @param percentAllocations Percent allocations associated with each address
   *  @param distributorFee Keeper fee paid by split to cover gas costs of distribution
   *  @param controller Controlling address (0x0 if immutable)
   *  @return split Address of newly created split
   */
  function createSplit(
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address controller
  )
    external
    override
    validSplit(accounts, percentAllocations, distributorFee)
    returns (address split)
  {
    bytes32 splitHash = _hashSplit(
      accounts,
      percentAllocations,
      distributorFee
    );
    if (controller == address(0)) {
      // create immutable split
      split = Clones.cloneDeterministic(walletImplementation, splitHash);
    } else {
      // create mutable split
      split = Clones.clone(walletImplementation);
      splits[split].controller = controller;
    }
    // store split's hash in storage for future verification
    splits[split].hash = splitHash;
    emit CreateSplit(split);
  }

  /** @notice Predicts the address for an immutable split created with recipients `accounts` with ownerships `percentAllocations` and a keeper fee for splitting of `distributorFee`
   *  @param accounts Ordered, unique list of addresses with ownership in the split
   *  @param percentAllocations Percent allocations associated with each address
   *  @param distributorFee Keeper fee paid by split to cover gas costs of distribution
   *  @return split Predicted address of such an immutable split
   */
  function predictImmutableSplitAddress(
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee
  )
    external
    view
    override
    validSplit(accounts, percentAllocations, distributorFee)
    returns (address split)
  {
    bytes32 splitHash = _hashSplit(
      accounts,
      percentAllocations,
      distributorFee
    );
    split = Clones.predictDeterministicAddress(walletImplementation, splitHash);
  }

  /** @notice Updates an existing split with recipients `accounts` with ownerships `percentAllocations` and a keeper fee for splitting of `distributorFee`
   *  @param split Address of mutable split to update
   *  @param accounts Ordered, unique list of addresses with ownership in the split
   *  @param percentAllocations Percent allocations associated with each address
   *  @param distributorFee Keeper fee paid by split to cover gas costs of distribution
   */
  function updateSplit(
    address split,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee
  )
    external
    override
    onlySplitController(split)
    validSplit(accounts, percentAllocations, distributorFee)
  {
    _updateSplit(split, accounts, percentAllocations, distributorFee);
  }

  /** @notice Begins transfer of the controlling address of mutable split `split` to `newController`
   *  @dev Two-step control transfer inspired by [dharma](https://github.com/dharma-eng/dharma-smart-wallet/blob/master/contracts/helpers/TwoStepOwnable.sol)
   *  @param split Address of mutable split to transfer control for
   *  @param newController Address to begin transferring control to
   */
  function transferControl(address split, address newController)
    external
    override
    onlySplitController(split)
    validNewController(newController)
  {
    splits[split].newPotentialController = newController;
    emit InitiateControlTransfer(split, newController);
  }

  /** @notice Cancels transfer of the controlling address of mutable split `split`
   *  @param split Address of mutable split to cancel control transfer for
   */
  function cancelControlTransfer(address split)
    external
    override
    onlySplitController(split)
  {
    delete splits[split].newPotentialController;
    emit CancelControlTransfer(split);
  }

  /** @notice Accepts transfer of the controlling address of mutable split `split`
   *  @param split Address of mutable split to accept control transfer for
   */
  function acceptControl(address split)
    external
    override
    onlySplitNewPotentialController(split)
  {
    delete splits[split].newPotentialController;
    emit ControlTransfer(split, splits[split].controller, msg.sender);
    splits[split].controller = msg.sender;
  }

  /** @notice Turns mutable split `split` immutable
   *  @param split Address of mutable split to turn immutable
   */
  function makeSplitImmutable(address split)
    external
    override
    onlySplitController(split)
  {
    delete splits[split].newPotentialController;
    emit ControlTransfer(split, splits[split].controller, address(0));
    splits[split].controller = address(0);
  }

  /** @notice Distributes the ETH balance for split `split`
   *  @dev `accounts`, `percentAllocations`, and `distributorFee` are verified by hashing
   *  & comparing to the hash in storage associated with split `split`
   *  @param split Address of split to distribute balance for
   *  @param accounts Ordered, unique list of addresses with ownership in the split
   *  @param percentAllocations Percent allocations associated with each address
   *  @param distributorFee Keeper fee paid by split to cover gas costs of distribution
   *  @param distributorAddress Address to pay `distributorFee` to
   */
  function distributeETH(
    address split,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) external override validSplit(accounts, percentAllocations, distributorFee) {
    // use internal fn instead of modifier to avoid stack depth compiler errors
    _validSplitHash(split, accounts, percentAllocations, distributorFee);
    _distributeETH(
      split,
      accounts,
      percentAllocations,
      distributorFee,
      distributorAddress
    );
  }

  /** @notice Updates & distributes the ETH balance for split `split`
   *  @dev only callable by SplitController
   *  @param split Address of split to distribute balance for
   *  @param accounts Ordered, unique list of addresses with ownership in the split
   *  @param percentAllocations Percent allocations associated with each address
   *  @param distributorFee Keeper fee paid by split to cover gas costs of distribution
   *  @param distributorAddress Address to pay `distributorFee` to
   */
  function updateAndDistributeETH(
    address split,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  )
    external
    override
    onlySplitController(split)
    validSplit(accounts, percentAllocations, distributorFee)
  {
    _updateSplit(split, accounts, percentAllocations, distributorFee);
    // know splitHash is valid immediately after updating; only accessible via controller
    _distributeETH(
      split,
      accounts,
      percentAllocations,
      distributorFee,
      distributorAddress
    );
  }

  /** @notice Distributes the ERC20 `token` balance for split `split`
   *  @dev `accounts`, `percentAllocations`, and `distributorFee` are verified by hashing
   *  & comparing to the hash in storage associated with split `split`
   *  @dev pernicious ERC20s may cause overflow in this function inside
   *  _scaleAmountByPercentage, but results do not affect ETH & other ERC20 balances
   *  @param split Address of split to distribute balance for
   *  @param token Address of ERC20 to distribute balance for
   *  @param accounts Ordered, unique list of addresses with ownership in the split
   *  @param percentAllocations Percent allocations associated with each address
   *  @param distributorFee Keeper fee paid by split to cover gas costs of distribution
   *  @param distributorAddress Address to pay `distributorFee` to
   */
  function distributeERC20(
    address split,
    ERC20 token,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) external override validSplit(accounts, percentAllocations, distributorFee) {
    // use internal fn instead of modifier to avoid stack depth compiler errors
    _validSplitHash(split, accounts, percentAllocations, distributorFee);
    _distributeERC20(
      split,
      token,
      accounts,
      percentAllocations,
      distributorFee,
      distributorAddress
    );
  }

  /** @notice Updates & distributes the ERC20 `token` balance for split `split`
   *  @dev only callable by SplitController
   *  @dev pernicious ERC20s may cause overflow in this function inside
   *  _scaleAmountByPercentage, but results do not affect ETH & other ERC20 balances
   *  @param split Address of split to distribute balance for
   *  @param token Address of ERC20 to distribute balance for
   *  @param accounts Ordered, unique list of addresses with ownership in the split
   *  @param percentAllocations Percent allocations associated with each address
   *  @param distributorFee Keeper fee paid by split to cover gas costs of distribution
   *  @param distributorAddress Address to pay `distributorFee` to
   */
  function updateAndDistributeERC20(
    address split,
    ERC20 token,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  )
    external
    override
    onlySplitController(split)
    validSplit(accounts, percentAllocations, distributorFee)
  {
    _updateSplit(split, accounts, percentAllocations, distributorFee);
    // know splitHash is valid immediately after updating; only accessible via controller
    _distributeERC20(
      split,
      token,
      accounts,
      percentAllocations,
      distributorFee,
      distributorAddress
    );
  }

  /** @notice Withdraw ETH &/ ERC20 balances for account `account`
   *  @param account Address to withdraw on behalf of
   *  @param withdrawETH Withdraw all ETH if nonzero
   *  @param tokens Addresses of ERC20s to withdraw
   */
  function withdraw(
    address account,
    uint256 withdrawETH,
    ERC20[] calldata tokens
  ) external override {
    uint256[] memory tokenAmounts = new uint256[](tokens.length);
    uint256 ethAmount;
    if (withdrawETH != 0) {
      ethAmount = _withdraw(account);
    }
    unchecked {
      // overflow should be impossible in for-loop index
      for (uint256 i = 0; i < tokens.length; ++i) {
        // overflow should be impossible in array length math
        tokenAmounts[i] = _withdrawERC20(account, tokens[i]);
      }
      emit Withdrawal(account, ethAmount, tokens, tokenAmounts);
    }
  }

  /**
   * FUNCTIONS - VIEWS
   */

  /** @notice Returns the current hash of split `split`
   *  @param split Split to return hash for
   *  @return Split's hash
   */
  function getHash(address split) external view returns (bytes32) {
    return splits[split].hash;
  }

  /** @notice Returns the current controller of split `split`
   *  @param split Split to return controller for
   *  @return Split's controller
   */
  function getController(address split) external view returns (address) {
    return splits[split].controller;
  }

  /** @notice Returns the current newPotentialController of split `split`
   *  @param split Split to return newPotentialController for
   *  @return Split's newPotentialController
   */
  function getNewPotentialController(address split)
    external
    view
    returns (address)
  {
    return splits[split].newPotentialController;
  }

  /** @notice Returns the current ETH balance of account `account`
   *  @param account Account to return ETH balance for
   *  @return Account's balance of ETH
   */
  function getETHBalance(address account) external view returns (uint256) {
    return
      ethBalances[account] + (splits[account].hash != 0 ? account.balance : 0);
  }

  /** @notice Returns the ERC20 balance of token `token` for account `account`
   *  @param account Account to return ERC20 `token` balance for
   *  @param token Token to return balance for
   *  @return Account's balance of `token`
   */
  function getERC20Balance(address account, ERC20 token)
    external
    view
    returns (uint256)
  {
    return
      erc20Balances[token][account] +
      (splits[account].hash != 0 ? token.balanceOf(account) : 0);
  }

  /**
   * FUNCTIONS - PRIVATE & INTERNAL
   */

  /** @notice Sums array of uint32s
   *  @param numbers Array of uint32s to sum
   *  @return sum Sum of `numbers`.
   */
  function _getSum(uint32[] memory numbers) internal pure returns (uint32 sum) {
    // overflow should be impossible in for-loop index
    uint256 numbersLength = numbers.length;
    for (uint256 i = 0; i < numbersLength; ) {
      sum += numbers[i];
      unchecked {
        // overflow should be impossible in for-loop index
        ++i;
      }
    }
  }

  /** @notice Hashes a split
   *  @param accounts Ordered, unique list of addresses with ownership in the split
   *  @param percentAllocations Percent allocations associated with each address
   *  @param distributorFee Keeper fee paid by split to cover gas costs of distribution
   *  @return computedHash Hash of the split.
   */
  function _hashSplit(
    address[] memory accounts,
    uint32[] memory percentAllocations,
    uint32 distributorFee
  ) internal pure returns (bytes32) {
    return
      keccak256(abi.encodePacked(accounts, percentAllocations, distributorFee));
  }

  /** @notice Updates an existing split with recipients `accounts` with ownerships `percentAllocations` and a keeper fee for splitting of `distributorFee`
   *  @param split Address of mutable split to update
   *  @param accounts Ordered, unique list of addresses with ownership in the split
   *  @param percentAllocations Percent allocations associated with each address
   *  @param distributorFee Keeper fee paid by split to cover gas costs of distribution
   */
  function _updateSplit(
    address split,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee
  ) internal {
    bytes32 splitHash = _hashSplit(
      accounts,
      percentAllocations,
      distributorFee
    );
    // store new hash in storage for future verification
    splits[split].hash = splitHash;
    emit UpdateSplit(split);
  }

  /** @notice Checks hash from `accounts`, `percentAllocations`, and `distributorFee` against the hash stored for `split`
   *  @param split Address of hash to check
   *  @param accounts Ordered, unique list of addresses with ownership in the split
   *  @param percentAllocations Percent allocations associated with each address
   *  @param distributorFee Keeper fee paid by split to cover gas costs of distribution
   */
  function _validSplitHash(
    address split,
    address[] memory accounts,
    uint32[] memory percentAllocations,
    uint32 distributorFee
  ) internal view {
    bytes32 hash = _hashSplit(accounts, percentAllocations, distributorFee);
    if (splits[split].hash != hash) revert InvalidSplit__InvalidHash(hash);
  }

  /** @notice Distributes the ETH balance for split `split`
   *  @dev `accounts`, `percentAllocations`, and `distributorFee` must be verified before calling
   *  @param split Address of split to distribute balance for
   *  @param accounts Ordered, unique list of addresses with ownership in the split
   *  @param percentAllocations Percent allocations associated with each address
   *  @param distributorFee Keeper fee paid by split to cover gas costs of distribution
   *  @param distributorAddress Address to pay `distributorFee` to
   */
  function _distributeETH(
    address split,
    address[] memory accounts,
    uint32[] memory percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) internal {
    uint256 mainBalance = ethBalances[split];
    uint256 proxyBalance = split.balance;
    // if mainBalance is positive, leave 1 in SplitMain for gas efficiency
    uint256 amountToSplit;
    unchecked {
      // underflow should be impossible
      if (mainBalance > 0) mainBalance -= 1;
      // overflow should be impossible
      amountToSplit = mainBalance + proxyBalance;
    }
    if (mainBalance > 0) ethBalances[split] = 1;
    // emit event with gross amountToSplit (before deducting distributorFee)
    emit DistributeETH(split, amountToSplit, distributorAddress);
    if (distributorFee != 0) {
      // given `amountToSplit`, calculate keeper fee
      uint256 distributorFeeAmount = _scaleAmountByPercentage(
        amountToSplit,
        distributorFee
      );
      unchecked {
        // credit keeper with fee
        // overflow should be impossible with validated distributorFee
        ethBalances[
          distributorAddress != address(0) ? distributorAddress : msg.sender
        ] += distributorFeeAmount;
        // given keeper fee, calculate how much to distribute to split recipients
        // underflow should be impossible with validated distributorFee
        amountToSplit -= distributorFeeAmount;
      }
    }
    unchecked {
      // distribute remaining balance
      // overflow should be impossible in for-loop index
      // cache accounts length to save gas
      uint256 accountsLength = accounts.length;
      for (uint256 i = 0; i < accountsLength; ++i) {
        // overflow should be impossible with validated allocations
        ethBalances[accounts[i]] += _scaleAmountByPercentage(
          amountToSplit,
          percentAllocations[i]
        );
      }
    }
    // flush proxy ETH balance to SplitMain
    // split proxy should be guaranteed to exist at this address after validating splitHash
    // (attacker can't deploy own contract to address with high balance & empty sendETHToMain
    // to drain ETH from SplitMain)
    // could technically check if (change in proxy balance == change in SplitMain balance)
    // before/after external call, but seems like extra gas for no practical benefit
    if (proxyBalance > 0) SplitWallet(split).sendETHToMain(proxyBalance);
  }

  /** @notice Distributes the ERC20 `token` balance for split `split`
   *  @dev `accounts`, `percentAllocations`, and `distributorFee` must be verified before calling
   *  @dev pernicious ERC20s may cause overflow in this function inside
   *  _scaleAmountByPercentage, but results do not affect ETH & other ERC20 balances
   *  @param split Address of split to distribute balance for
   *  @param token Address of ERC20 to distribute balance for
   *  @param accounts Ordered, unique list of addresses with ownership in the split
   *  @param percentAllocations Percent allocations associated with each address
   *  @param distributorFee Keeper fee paid by split to cover gas costs of distribution
   *  @param distributorAddress Address to pay `distributorFee` to
   */
  function _distributeERC20(
    address split,
    ERC20 token,
    address[] memory accounts,
    uint32[] memory percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) internal {
    uint256 amountToSplit;
    uint256 mainBalance = erc20Balances[token][split];
    uint256 proxyBalance = token.balanceOf(split);
    unchecked {
      // if mainBalance &/ proxyBalance are positive, leave 1 for gas efficiency
      // underflow should be impossible
      if (proxyBalance > 0) proxyBalance -= 1;
      // underflow should be impossible
      if (mainBalance > 0) {
        mainBalance -= 1;
      }
      // overflow should be impossible
      amountToSplit = mainBalance + proxyBalance;
    }
    if (mainBalance > 0) erc20Balances[token][split] = 1;
    // emit event with gross amountToSplit (before deducting distributorFee)
    emit DistributeERC20(split, token, amountToSplit, distributorAddress);
    if (distributorFee != 0) {
      // given `amountToSplit`, calculate keeper fee
      uint256 distributorFeeAmount = _scaleAmountByPercentage(
        amountToSplit,
        distributorFee
      );
      // overflow should be impossible with validated distributorFee
      unchecked {
        // credit keeper with fee
        erc20Balances[token][
          distributorAddress != address(0) ? distributorAddress : msg.sender
        ] += distributorFeeAmount;
        // given keeper fee, calculate how much to distribute to split recipients
        amountToSplit -= distributorFeeAmount;
      }
    }
    // distribute remaining balance
    // overflows should be impossible in for-loop with validated allocations
    unchecked {
      // cache accounts length to save gas
      uint256 accountsLength = accounts.length;
      for (uint256 i = 0; i < accountsLength; ++i) {
        erc20Balances[token][accounts[i]] += _scaleAmountByPercentage(
          amountToSplit,
          percentAllocations[i]
        );
      }
    }
    // split proxy should be guaranteed to exist at this address after validating splitHash
    // (attacker can't deploy own contract to address with high ERC20 balance & empty
    // sendERC20ToMain to drain ERC20 from SplitMain)
    // doesn't support rebasing or fee-on-transfer tokens
    // flush extra proxy ERC20 balance to SplitMain
    if (proxyBalance > 0)
      SplitWallet(split).sendERC20ToMain(token, proxyBalance);
  }

  /** @notice Multiplies an amount by a scaled percentage
   *  @param amount Amount to get `scaledPercentage` of
   *  @param scaledPercent Percent scaled by PERCENTAGE_SCALE
   *  @return scaledAmount Percent of `amount`.
   */
  function _scaleAmountByPercentage(uint256 amount, uint256 scaledPercent)
    internal
    pure
    returns (uint256 scaledAmount)
  {
    // use assembly to bypass checking for overflow & division by 0
    // scaledPercent has been validated to be < PERCENTAGE_SCALE)
    // & PERCENTAGE_SCALE will never be 0
    // pernicious ERC20s may cause overflow, but results do not affect ETH & other ERC20 balances
    assembly {
      /* eg (100 * 2*1e4) / (1e6) */
      scaledAmount := div(mul(amount, scaledPercent), PERCENTAGE_SCALE)
    }
  }

  /** @notice Withdraw ETH for account `account`
   *  @param account Account to withdrawn ETH for
   *  @return withdrawn Amount of ETH withdrawn
   */
  function _withdraw(address account) internal returns (uint256 withdrawn) {
    // leave balance of 1 for gas efficiency
    // underflow if ethBalance is 0
    withdrawn = ethBalances[account] - 1;
    ethBalances[account] = 1;
    account.safeTransferETH(withdrawn);
  }

  /** @notice Withdraw ERC20 `token` for account `account`
   *  @param account Account to withdrawn ERC20 `token` for
   *  @return withdrawn Amount of ERC20 `token` withdrawn
   */
  function _withdrawERC20(address account, ERC20 token)
    internal
    returns (uint256 withdrawn)
  {
    // leave balance of 1 for gas efficiency
    // underflow if erc20Balance is 0
    withdrawn = erc20Balances[token][account] - 1;
    erc20Balances[token][account] = 1;
    token.safeTransfer(account, withdrawn);
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import {ERC20} from '@rari-capital/solmate/src/tokens/ERC20.sol';

/**
 * @title ISplitMain
 * @author 0xSplits <[email protected]>
 */
interface ISplitMain {
  /**
   * FUNCTIONS
   */

  function walletImplementation() external returns (address);

  function createSplit(
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address controller
  ) external returns (address);

  function predictImmutableSplitAddress(
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee
  ) external view returns (address);

  function updateSplit(
    address split,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee
  ) external;

  function transferControl(address split, address newController) external;

  function cancelControlTransfer(address split) external;

  function acceptControl(address split) external;

  function makeSplitImmutable(address split) external;

  function distributeETH(
    address split,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) external;

  function updateAndDistributeETH(
    address split,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) external;

  function distributeERC20(
    address split,
    ERC20 token,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) external;

  function updateAndDistributeERC20(
    address split,
    ERC20 token,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) external;

  function withdraw(
    address account,
    uint256 withdrawETH,
    ERC20[] calldata tokens
  ) external;

  /**
   * EVENTS
   */

  /** @notice emitted after each successful split creation
   *  @param split Address of the created split
   */
  event CreateSplit(address indexed split);

  /** @notice emitted after each successful split update
   *  @param split Address of the updated split
   */
  event UpdateSplit(address indexed split);

  /** @notice emitted after each initiated split control transfer
   *  @param split Address of the split control transfer was initiated for
   *  @param newPotentialController Address of the split's new potential controller
   */
  event InitiateControlTransfer(
    address indexed split,
    address indexed newPotentialController
  );

  /** @notice emitted after each canceled split control transfer
   *  @param split Address of the split control transfer was canceled for
   */
  event CancelControlTransfer(address indexed split);

  /** @notice emitted after each successful split control transfer
   *  @param split Address of the split control was transferred for
   *  @param previousController Address of the split's previous controller
   *  @param newController Address of the split's new controller
   */
  event ControlTransfer(
    address indexed split,
    address indexed previousController,
    address indexed newController
  );

  /** @notice emitted after each successful ETH balance split
   *  @param split Address of the split that distributed its balance
   *  @param amount Amount of ETH distributed
   *  @param distributorAddress Address to credit distributor fee to
   */
  event DistributeETH(
    address indexed split,
    uint256 amount,
    address indexed distributorAddress
  );

  /** @notice emitted after each successful ERC20 balance split
   *  @param split Address of the split that distributed its balance
   *  @param token Address of ERC20 distributed
   *  @param amount Amount of ERC20 distributed
   *  @param distributorAddress Address to credit distributor fee to
   */
  event DistributeERC20(
    address indexed split,
    ERC20 indexed token,
    uint256 amount,
    address indexed distributorAddress
  );

  /** @notice emitted after each successful withdrawal
   *  @param account Address that funds were withdrawn to
   *  @param ethAmount Amount of ETH withdrawn
   *  @param tokens Addresses of ERC20s withdrawn
   *  @param tokenAmounts Amounts of corresponding ERC20s withdrawn
   */
  event Withdrawal(
    address indexed account,
    uint256 ethAmount,
    ERC20[] tokens,
    uint256[] tokenAmounts
  );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import {ISplitMain} from './interfaces/ISplitMain.sol';
import {ERC20} from '@rari-capital/solmate/src/tokens/ERC20.sol';
import {SafeTransferLib} from '@rari-capital/solmate/src/utils/SafeTransferLib.sol';

/**
 * ERRORS
 */

/// @notice Unauthorized sender
error Unauthorized();

/**
 * @title SplitWallet
 * @author 0xSplits <[email protected]>
 * @notice The implementation logic for `SplitProxy`.
 * @dev `SplitProxy` handles `receive()` itself to avoid the gas cost with `DELEGATECALL`.
 */
contract SplitWallet {
  using SafeTransferLib for address;
  using SafeTransferLib for ERC20;

  /**
   * EVENTS
   */

  /** @notice emitted after each successful ETH transfer to proxy
   *  @param split Address of the split that received ETH
   *  @param amount Amount of ETH received
   */
  event ReceiveETH(address indexed split, uint256 amount);

  /**
   * STORAGE
   */

  /**
   * STORAGE - CONSTANTS & IMMUTABLES
   */

  /// @notice address of SplitMain for split distributions & EOA/SC withdrawals
  ISplitMain public immutable splitMain;

  /**
   * MODIFIERS
   */

  /// @notice Reverts if the sender isn't SplitMain
  modifier onlySplitMain() {
    if (msg.sender != address(splitMain)) revert Unauthorized();
    _;
  }

  /**
   * CONSTRUCTOR
   */

  constructor() {
    splitMain = ISplitMain(msg.sender);
  }

  /**
   * FUNCTIONS - PUBLIC & EXTERNAL
   */

  /** @notice Sends amount `amount` of ETH in proxy to SplitMain
   *  @dev payable reduces gas cost; no vulnerability to accidentally lock
   *  ETH introduced since fn call is restricted to SplitMain
   *  @param amount Amount to send
   */
  function sendETHToMain(uint256 amount) external payable onlySplitMain() {
    address(splitMain).safeTransferETH(amount);
  }

  /** @notice Sends amount `amount` of ERC20 `token` in proxy to SplitMain
   *  @dev payable reduces gas cost; no vulnerability to accidentally lock
   *  ETH introduced since fn call is restricted to SplitMain
   *  @param token Token to send
   *  @param amount Amount to send
   */
  function sendERC20ToMain(ERC20 token, uint256 amount)
    external
    payable
    onlySplitMain()
  {
    token.safeTransfer(address(splitMain), amount);
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

/// @notice create opcode failed
error CreateError();
/// @notice create2 opcode failed
error Create2Error();

library Clones {
  /**
   * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`
   * except when someone calls `receive()` and then it emits an event matching
   * `SplitWallet.ReceiveETH(indexed address, amount)`
   * Inspired by OZ & 0age's minimal clone implementations based on eip 1167 found at
   * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/proxy/Clones.sol
   * and https://medium.com/coinmonks/the-more-minimal-proxy-5756ae08ee48
   *
   * This function uses the create2 opcode and a `salt` to deterministically deploy
   * the clone. Using the same `implementation` and `salt` multiple time will revert, since
   * the clones cannot be deployed twice at the same address.
   *
   * init: 0x3d605d80600a3d3981f3
   * 3d   returndatasize  0
   * 605d push1 0x5d      0x5d 0
   * 80   dup1            0x5d 0x5d 0
   * 600a push1 0x0a      0x0a 0x5d 0x5d 0
   * 3d   returndatasize  0 0x0a 0x5d 0x5d 0
   * 39   codecopy        0x5d 0                      destOffset offset length     memory[destOffset:destOffset+length] = address(this).code[offset:offset+length]       copy executing contracts bytecode
   * 81   dup2            0 0x5d 0
   * f3   return          0                           offset length                return memory[offset:offset+length]                                                   returns from this contract call
   *
   * contract: 0x36603057343d52307f830d2d700a97af574b186c80d40429385d24241565b08a7c559ba283a964d9b160203da23d3df35b3d3d3d3d363d3d37363d73bebebebebebebebebebebebebebebebebebebebe5af43d3d93803e605b57fd5bf3
   *     0x000     36       calldatasize      cds
   *     0x001     6030     push1 0x30        0x30 cds
   * ,=< 0x003     57       jumpi
   * |   0x004     34       callvalue         cv
   * |   0x005     3d       returndatasize    0 cv
   * |   0x006     52       mstore
   * |   0x007     30       address           addr
   * |   0x008     7f830d.. push32 0x830d..   id addr
   * |   0x029     6020     push1 0x20        0x20 id addr
   * |   0x02b     3d       returndatasize    0 0x20 id addr
   * |   0x02c     a2       log2
   * |   0x02d     3d       returndatasize    0
   * |   0x02e     3d       returndatasize    0 0
   * |   0x02f     f3       return
   * `-> 0x030     5b       jumpdest
   *     0x031     3d       returndatasize    0
   *     0x032     3d       returndatasize    0 0
   *     0x033     3d       returndatasize    0 0 0
   *     0x034     3d       returndatasize    0 0 0 0
   *     0x035     36       calldatasize      cds 0 0 0 0
   *     0x036     3d       returndatasize    0 cds 0 0 0 0
   *     0x037     3d       returndatasize    0 0 cds 0 0 0 0
   *     0x038     37       calldatacopy      0 0 0 0
   *     0x039     36       calldatasize      cds 0 0 0 0
   *     0x03a     3d       returndatasize    0 cds 0 0 0 0
   *     0x03b     73bebe.. push20 0xbebe..   0xbebe 0 cds 0 0 0 0
   *     0x050     5a       gas               gas 0xbebe 0 cds 0 0 0 0
   *     0x051     f4       delegatecall      suc 0 0
   *     0x052     3d       returndatasize    rds suc 0 0
   *     0x053     3d       returndatasize    rds rds suc 0 0
   *     0x054     93       swap4             0 rds suc 0 rds
   *     0x055     80       dup1              0 0 rds suc 0 rds
   *     0x056     3e       returndatacopy    suc 0 rds
   *     0x057     605b     push1 0x5b        0x5b suc 0 rds
   * ,=< 0x059     57       jumpi             0 rds
   * |   0x05a     fd       revert
   * `-> 0x05b     5b       jumpdest          0 rds
   *     0x05c     f3       return
   *
   */
  function clone(address implementation) internal returns (address instance) {
    assembly {
      let ptr := mload(0x40)
      mstore(
        ptr,
        0x3d605d80600a3d3981f336603057343d52307f00000000000000000000000000
      )
      mstore(
        add(ptr, 0x13),
        0x830d2d700a97af574b186c80d40429385d24241565b08a7c559ba283a964d9b1
      )
      mstore(
        add(ptr, 0x33),
        0x60203da23d3df35b3d3d3d3d363d3d37363d7300000000000000000000000000
      )
      mstore(add(ptr, 0x46), shl(0x60, implementation))
      mstore(
        add(ptr, 0x5a),
        0x5af43d3d93803e605b57fd5bf300000000000000000000000000000000000000
      )
      instance := create(0, ptr, 0x67)
    }
    if (instance == address(0)) revert CreateError();
  }

  function cloneDeterministic(address implementation, bytes32 salt)
    internal
    returns (address instance)
  {
    assembly {
      let ptr := mload(0x40)
      mstore(
        ptr,
        0x3d605d80600a3d3981f336603057343d52307f00000000000000000000000000
      )
      mstore(
        add(ptr, 0x13),
        0x830d2d700a97af574b186c80d40429385d24241565b08a7c559ba283a964d9b1
      )
      mstore(
        add(ptr, 0x33),
        0x60203da23d3df35b3d3d3d3d363d3d37363d7300000000000000000000000000
      )
      mstore(add(ptr, 0x46), shl(0x60, implementation))
      mstore(
        add(ptr, 0x5a),
        0x5af43d3d93803e605b57fd5bf300000000000000000000000000000000000000
      )
      instance := create2(0, ptr, 0x67, salt)
    }
    if (instance == address(0)) revert Create2Error();
  }

  /**
   * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
   */
  function predictDeterministicAddress(
    address implementation,
    bytes32 salt,
    address deployer
  ) internal pure returns (address predicted) {
    assembly {
      let ptr := mload(0x40)
      mstore(
        ptr,
        0x3d605d80600a3d3981f336603057343d52307f00000000000000000000000000
      )
      mstore(
        add(ptr, 0x13),
        0x830d2d700a97af574b186c80d40429385d24241565b08a7c559ba283a964d9b1
      )
      mstore(
        add(ptr, 0x33),
        0x60203da23d3df35b3d3d3d3d363d3d37363d7300000000000000000000000000
      )
      mstore(add(ptr, 0x46), shl(0x60, implementation))
      mstore(
        add(ptr, 0x5a),
        0x5af43d3d93803e605b57fd5bf3ff000000000000000000000000000000000000
      )
      mstore(add(ptr, 0x68), shl(0x60, deployer))
      mstore(add(ptr, 0x7c), salt)
      mstore(add(ptr, 0x9c), keccak256(ptr, 0x67))
      predicted := keccak256(add(ptr, 0x67), 0x55)
    }
  }

  /**
   * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
   */
  function predictDeterministicAddress(address implementation, bytes32 salt)
    internal
    view
    returns (address predicted)
  {
    return predictDeterministicAddress(implementation, salt, address(this));
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }
}