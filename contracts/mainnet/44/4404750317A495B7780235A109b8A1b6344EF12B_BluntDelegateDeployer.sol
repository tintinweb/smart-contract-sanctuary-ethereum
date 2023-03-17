// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import './interfaces/IBluntDelegate.sol';
import './interfaces/IPriceFeed.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPayoutTerminal3_1.sol';

/// @title Base Blunt Finance data source for Juicebox projects.
/// @author jacopo <[email protected]>
/// @notice Permissionless funding rounds with target, hardcap, deadline and a set of pre-defined rules.
contract BluntDelegate is IBluntDelegate {
  //*********************************************************************//
  // --------------------------- custom errors ------------------------- //
  //*********************************************************************//
  error INVALID_PAYMENT_EVENT();
  error CAP_REACHED();
  error ROUND_ENDED();
  error ROUND_NOT_ENDED();
  error ROUND_CLOSED();
  error ROUND_NOT_CLOSED();
  error DEADLINE_SET();
  error INVALID_DEADLINE();
  error NOT_PROJECT_OWNER();

  //*********************************************************************//
  // ------------------------------ events ----------------------------- //
  //*********************************************************************//
  event RoundCreated(
    DeployBluntDelegateData deployBluntDelegateData,
    uint256 projectId,
    uint256 duration
  );
  event RoundClosed();
  event DeadlineSet(uint256 deadline);

  //*********************************************************************//
  // ------------------------ immutable storage ------------------------ //
  //*********************************************************************//

  /** 
    @notice 
    The ETH token address in Juicebox. See `JBConstants`
  */
  address private constant ETH = address(0x000000000000000000000000000000000000EEEe);

  /**
    @notice
    Price feed instance
  */
  IPriceFeed private constant priceFeed = IPriceFeed(0xf2E8176c0b67232b20205f4dfbCeC3e74bca471F);

  /**
    @notice
    The directory of terminals and controllers for projects.
  */
  IJBDirectory private immutable directory;

  /**
    @notice
    The controller with which new projects should be deployed.
  */
  IJBController3_1 private immutable controller;

  /**
    @notice
    The ID of the JB project that collects fees.
  */
  uint256 public immutable feeProjectId;

  /**
    @notice
    The ID of the project conducting a round.
  */
  uint256 public immutable projectId;

  /**
    @notice
    Constants used to calculate Blunt Finance fee

    @dev MAX_K: The max percentage of the total contributions that can be taken as a fee
    @dev MIN_K: The min percentage of the total contributions that can be taken as a fee
    @dev UPPER_FUNDRAISE_BOUNDARY_USD: The upper boundary of the fundraising in USD, after which the percentage is fixed at MIN_K
    @dev LOWER_FUNDRAISE_BOUNDARY_USD: The lower boundary of the fundraising in USD, before which the percentage is fixed at MAX_K
  */
  uint256 public immutable MAX_K;
  uint256 public immutable MIN_K;
  uint256 public immutable UPPER_FUNDRAISE_BOUNDARY_USD;
  uint256 public immutable LOWER_FUNDRAISE_BOUNDARY_USD;

  /**
    @notice
    WETH address on Uniswap
  */
  address private immutable ethAddress;

  /**
    @notice
    USDC address on Uniswap
  */
  address private immutable usdcAddress;

  /** 
    @notice
    The owner of the project if the round is concluded successfully.
  */
  address private immutable projectOwner;

  /** 
    @notice
    The minimum amount of contributions to deem the round successful.
    When `isTargetUsd` is enabled it is a 6 point decimal number, else 18.
  */
  uint256 private immutable target;

  /** 
    @notice
    The maximum amount of contributions while the round is in effect. 
    When `isHardcapUsd` is enabled it is a 6 point decimal number, else 18.
  */
  uint256 private immutable hardcap;

  /** 
    @notice
    Reserved rate to be set in case of a successful round
  */
  uint256 private immutable afterRoundReservedRate;

  /**
    @notice
    True if a target is expressed in USD. False if ETH.
  */
  bool private immutable isTargetUsd;

  /**
    @notice
    True if a hardcap is expressed in USD. False if ETH.
  */
  bool private immutable isHardcapUsd;

  //*********************************************************************//
  // ------------------------- mutable storage ------------------------- //
  //*********************************************************************//

  /**
    @notice
    Total contributions received during round
  */
  uint208 private totalContributions;

  /**
    @notice
    The timestamp after which the round can be closed successfully. If zero, the round can be closed anytime.
  */
  uint40 private deadline;

  /**
    @notice
    True if the round has been closed 
  */
  bool private isRoundClosed;

  /** 
    @notice
    Project metadata splits to be enabled when a successful round is closed.
  */
  JBSplit[] private afterRoundSplits;

  /**
    @notice
    Mapping from beneficiary to contributions
  */
  mapping(address => uint256) public contributions;

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  /**
    @param _deployBluntDelegateDeployerData Deployment data sent by deployer contract
    @param _deployBluntDelegateData Deployment data sent by user
  */
  constructor(
    DeployBluntDelegateDeployerData memory _deployBluntDelegateDeployerData,
    DeployBluntDelegateData memory _deployBluntDelegateData
  ) {
    MAX_K = _deployBluntDelegateDeployerData.maxK;
    MIN_K = _deployBluntDelegateDeployerData.minK;
    UPPER_FUNDRAISE_BOUNDARY_USD = _deployBluntDelegateDeployerData.upperFundraiseBoundary;
    LOWER_FUNDRAISE_BOUNDARY_USD = _deployBluntDelegateDeployerData.lowerFundraiseBoundary;
    feeProjectId = _deployBluntDelegateDeployerData.feeProjectId;
    projectId = _deployBluntDelegateDeployerData.projectId;
    ethAddress = _deployBluntDelegateDeployerData.ethAddress;
    usdcAddress = _deployBluntDelegateDeployerData.usdcAddress;
    controller = _deployBluntDelegateDeployerData.controller;

    directory = _deployBluntDelegateData.directory;
    projectOwner = _deployBluntDelegateData.projectOwner;
    afterRoundReservedRate = _deployBluntDelegateData.afterRoundReservedRate;
    target = _deployBluntDelegateData.target;
    isTargetUsd = _deployBluntDelegateData.isTargetUsd;
    hardcap = _deployBluntDelegateData.hardcap;
    isHardcapUsd = _deployBluntDelegateData.isHardcapUsd;

    /// Set deadline based on round duration
    if (_deployBluntDelegateDeployerData.duration != 0)
      deadline = uint40(block.timestamp + _deployBluntDelegateDeployerData.duration);

    /// Store afterRoundSplits
    for (uint256 i; i < _deployBluntDelegateData.afterRoundSplits.length; ) {
      afterRoundSplits.push(_deployBluntDelegateData.afterRoundSplits[i]);

      unchecked {
        ++i;
      }
    }

    emit RoundCreated(
      _deployBluntDelegateData,
      _deployBluntDelegateDeployerData.projectId,
      _deployBluntDelegateDeployerData.duration
    );
  }

  //*********************************************************************//
  // ---------------------- external transactions ---------------------- //
  //*********************************************************************//

  /**
    @notice 
    Part of IJBPayDelegate, this function gets called when the project receives a payment. 
    It checks if blunt round hasn't been closed and hasn't reached the deadline.

    @dev 
    This function will revert if the contract calling is not one of the project's terminals. 

    @param _data The Juicebox standard project payment data.
  */
  function didPay(JBDidPayData calldata _data) external payable virtual override {
    /// Require that
    /// - The caller is a terminal of the project
    /// - The call is being made on behalf of an interaction with the correct project
    if (
      !directory.isTerminalOf(projectId, IJBPaymentTerminal(msg.sender)) ||
      _data.projectId != projectId
    ) revert INVALID_PAYMENT_EVENT();

    /// Make sure the round hasn't ended.
    if (isRoundClosed || (deadline != 0 && block.timestamp > deadline)) revert ROUND_ENDED();

    /// Update totalContributions and contributions with amount paid
    if (_data.amount.value > type(uint208).max) revert CAP_REACHED();
    totalContributions += uint208(_data.amount.value);

    /// Revert if `totalContributions` exceeds `hardcap`
    uint256 hardcap_ = hardcap;
    if (hardcap_ != 0) {
      if (isHardcapUsd) {
        hardcap_ = priceFeed.getQuote(uint128(hardcap_), usdcAddress, ethAddress, 30 minutes);
      }
      if (totalContributions > hardcap_) revert CAP_REACHED();
    }

    /// Cannot overflow as totalContributions would overflow first
    unchecked {
      contributions[_data.beneficiary] += _data.amount.value;
    }
  }

  /**
    @notice 
    Part of IJBRedemptionDelegate, this function gets called when the beneficiary redeems tokens. 
    It will update storage if conditions are met. 

    @dev 
    This function will revert if the contract calling is not one of the project's terminals. 

    @param _data The Juicebox standard project payment data.
  */
  function didRedeem(JBDidRedeemData calldata _data) external payable virtual override {
    /// Require that
    /// - The caller is a terminal of the project
    /// - The call is being made on behalf of an interaction with the correct project
    if (
      !directory.isTerminalOf(projectId, IJBPaymentTerminal(msg.sender)) ||
      _data.projectId != projectId
    ) revert INVALID_PAYMENT_EVENT();

    unchecked {
      /// Decrease contributions based on amount redeemed
      /// @dev Cannot underflow as `_data.reclaimedAmount.value` cannot be higher than `contributions[_data.beneficiary]`
      /// contributions can be inside unchecked as token transfers are disabled during round
      contributions[_data.beneficiary] -= _data.reclaimedAmount.value;

      // Only if round is open
      if (!isRoundClosed) {
        /// Decrease totalContributions by amount redeemed
        totalContributions -= uint208(_data.reclaimedAmount.value);
      }
    }
  }

  /**
    @notice 
    Close round if target has been reached. If called when totalContributions hasn't reached the target, 
    disable payments and keep full redemptions enabled.

    @dev 
    Can only be called once by the appointed project owner.
  */
  function closeRound() external override {
    if (msg.sender != projectOwner) revert NOT_PROJECT_OWNER();
    if (isRoundClosed) revert ROUND_CLOSED();
    isRoundClosed = true;

    if (isTargetReached()) {
      // Prevent successful rounds to be closed before the deadline
      if (deadline != 0 && block.timestamp < deadline) revert ROUND_NOT_ENDED();

      (
        address terminal,
        uint256 fee,
        JBFundingCycleData memory data,
        JBFundingCycleMetadata memory metadata,
        JBGroupedSplits[] memory splits,
        JBFundAccessConstraints[] memory fundAccessConstraints
      ) = _formatReconfigData();

      /// Reconfigure Funding Cycle
      controller.reconfigureFundingCyclesOf(
        projectId,
        data,
        metadata,
        0,
        splits,
        fundAccessConstraints,
        'Blunt round completed'
      );

      // Distribute payout fee to Blunt Finance
      string memory projectIdString = _toString(projectId);
      IJBPayoutTerminal3_1(terminal).distributePayoutsOf({
        _projectId: projectId,
        _amount: fee,
        _currency: 1, // JBCurrencies.ETH
        _token: ETH,
        _minReturnedTokens: 0,
        _metadata: 
          abi.encodePacked(
            'Fee from [Project #',
            projectIdString,
            '](https://juicebox.money/v2/p/',
            projectIdString,
            ')'
          )
      });

      /// Transfer project ownership to projectOwner
      directory.projects().safeTransferFrom(address(this), projectOwner, projectId);
    }

    emit RoundClosed();
  }

  /**
    @notice 
    Set a deadline for rounds with no duration set.

    @param deadline_ The new deadline for the round.

    @dev 
    Can only be called once by the appointed project owner.
  */
  function setDeadline(uint256 deadline_) external override {
    if (msg.sender != projectOwner) revert NOT_PROJECT_OWNER();
    if (isRoundClosed) revert ROUND_CLOSED();
    if (deadline != 0) revert DEADLINE_SET();
    if (uint40(deadline_) < block.timestamp) revert INVALID_DEADLINE();

    deadline = uint40(deadline_);
    emit DeadlineSet(deadline_);
  }

  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  /**
    @notice 
    Part of IJBFundingCycleDataSource, this function gets called when the project receives a payment. It will set itself as the delegate to get a callback from the terminal.

    @dev 
    This function will revert if the contract calling it is not the store of one of the project's terminals. 

    @param _data The Juicebox standard project payment data.

    @return weight The weight that tokens should get minted in accordance to 
    @return memo The memo that should be forwarded to the event.
    @return delegateAllocations The amount to send to delegates instead of adding to the local balance.
  */
  function payParams(
    JBPayParamsData calldata _data
  )
    external
    view
    override
    returns (
      uint256 weight,
      string memory memo,
      JBPayDelegateAllocation[] memory delegateAllocations
    )
  {
    JBPayDelegateAllocation[] memory allocations = new JBPayDelegateAllocation[](1);
    allocations[0] = JBPayDelegateAllocation(IJBPayDelegate(address(this)), 0);

    /// Forward the recieved weight and memo, and use this contract as a pay delegate.
    return (_data.weight, _data.memo, allocations);
  }

  /**
    @notice 
    Part of IJBFundingCycleDataSource, this function gets called when a project's token holders redeem. It will return the standard properties.

    @param _data The Juicebox standard project redemption data.

    @return reclaimAmount The amount that should be reclaimed from the treasury.
    @return memo The memo that should be forwarded to the event.
    @return delegateAllocations The amount to send to delegates instead of adding to the beneficiary.
  */
  function redeemParams(
    JBRedeemParamsData calldata _data
  )
    external
    view
    override
    returns (
      uint256 reclaimAmount,
      string memory memo,
      JBRedemptionDelegateAllocation[] memory delegateAllocations
    )
  {
    JBRedemptionDelegateAllocation[] memory allocations = new JBRedemptionDelegateAllocation[](1);
    allocations[0] = JBRedemptionDelegateAllocation(IJBRedemptionDelegate(address(this)), 0);

    /// Forward the recieved weight and memo, and use this contract as a redeem delegate.
    return (_data.reclaimAmount.value, _data.memo, allocations);
  }

  /**
    @notice
    Returns info related to round.
  */
  function getRoundInfo() external view override returns (RoundInfo memory) {
    return
      RoundInfo(
        totalContributions,
        target,
        hardcap,
        projectOwner,
        afterRoundReservedRate,
        afterRoundSplits,
        isRoundClosed,
        deadline,
        isTargetUsd,
        isHardcapUsd
      );
  }

  /**
    @notice
    Returns true if total contributions received surpass the round target.
  */
  function isTargetReached() public view override returns (bool) {
    uint256 target_ = target;
    if (target_ != 0) {
      if (isTargetUsd) {
        target_ = priceFeed.getQuote(uint128(target_), usdcAddress, ethAddress, 30 minutes);
      }
    }
    return totalContributions > target_;
  }

  //*********************************************************************//
  // ----------------------- private functions ------------------------- //
  //*********************************************************************//

  /**
    @notice
    Format data to reconfig project and pay Blunt Finance fee
  */
  function _formatReconfigData()
    private
    view
    returns (
      address terminal,
      uint256 fee,
      JBFundingCycleData memory data,
      JBFundingCycleMetadata memory metadata,
      JBGroupedSplits[] memory splits,
      JBFundAccessConstraints[] memory fundAccessConstraints
    )
  {
    /// Set funding cycle data
    data = JBFundingCycleData({
      duration: 0,
      weight: 1e24, /// token issuance 1M
      discountRate: 0,
      ballot: IJBFundingCycleBallot(address(0))
    });

    /// Edit funding cycle metadata:
    /// Get current funding cycle metadata
    (, metadata) = controller.currentFundingCycleOf(projectId);
    /// Set reservedRate from `afterRoundReservedRate`
    metadata.reservedRate = afterRoundReservedRate;
    /// Disable redemptions
    metadata.pauseRedeem = true;
    delete metadata.redemptionRate;
    delete metadata.ballotRedemptionRate;
    /// Enable transfers
    metadata.global.pauseTransfers = false;
    /// Pause pay, to allow projectOwner to reconfig as needed before re-enabling
    metadata.pausePay = true;
    /// Ensure distributions are enabled
    metadata.pauseDistributions = false;
    /// Detach dataSource
    delete metadata.useDataSourceForPay;
    delete metadata.useDataSourceForRedeem;
    delete metadata.dataSource;

    // Calculate BF fee
    fee = _calculateFee(totalContributions);

    /// Format fee splits
    JBSplit[] memory feeSplits = new JBSplit[](1);
    feeSplits[0] = JBSplit({
      preferClaimed: false,
      preferAddToBalance: false,
      percent: 1_000_000_000, // JBConstants.SPLITS_TOTAL_PERCENT
      projectId: feeProjectId,
      beneficiary: payable(projectOwner),
      lockedUntil: 0,
      allocator: IJBSplitAllocator(address(0))
    });

    // Format splits
    splits = new JBGroupedSplits[](2);
    splits[0] = JBGroupedSplits(1, feeSplits); // Payout distribution
    splits[1] = JBGroupedSplits(2, afterRoundSplits); // Reserved rate

    // Get JB ETH terminal
    IJBPaymentTerminal jbEthTerminal = directory.primaryTerminalOf(projectId, ETH);
    terminal = address(jbEthTerminal);

    // Format fundAccessConstraints
    fundAccessConstraints = new JBFundAccessConstraints[](1);
    fundAccessConstraints[0] = JBFundAccessConstraints({
      terminal: jbEthTerminal,
      token: ETH,
      distributionLimit: fee,
      distributionLimitCurrency: 1, // JBCurrencies.ETH
      overflowAllowance: 0,
      overflowAllowanceCurrency: 0
    });
  }

  /**
    @notice
    Calculate fee for successful rounds. Used in `_formatReconfigData`
  */
  function _calculateFee(uint256 raised) private view returns (uint256 fee) {
    unchecked {
      uint256 raisedUsd = priceFeed.getQuote(uint128(raised), ethAddress, usdcAddress, 30 minutes);
      uint256 k;
      if (raisedUsd < LOWER_FUNDRAISE_BOUNDARY_USD) {
        k = MAX_K;
      } else if (raisedUsd > UPPER_FUNDRAISE_BOUNDARY_USD) {
        k = MIN_K;
      } else {
        /** @dev 
          - [(MAX_K - MIN_K) * (raisedUsd - LOWER_FUNDRAISE_BOUNDARY_USD)] cannot overflow since raisedUsd < UPPER_FUNDRAISE_BOUNDARY_USD
          - k cannot underflow since MAX_K > (MAX_K - MIN_K)
        */
        // prettier-ignore
        k = MAX_K - (
          ((MAX_K - MIN_K) * (raisedUsd - LOWER_FUNDRAISE_BOUNDARY_USD)) /
          (UPPER_FUNDRAISE_BOUNDARY_USD - LOWER_FUNDRAISE_BOUNDARY_USD)
        );
      }

      /// @dev overflows for [raised > 2^256 / MIN_K], which practically cannot be reached
      fee = (k * raised) / 10000;
    }
  }

  /**
   * @dev Converts a uint256 to its ASCII string decimal representation.
   */
  function _toString(uint256 value) internal pure virtual returns (string memory str) {
    assembly {
      // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
      // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
      // We will need 1 word for the trailing zeros padding, 1 word for the length,
      // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
      let m := add(mload(0x40), 0xa0)
      // Update the free memory pointer to allocate.
      mstore(0x40, m)
      // Assign the `str` to the end.
      str := sub(m, 0x20)
      // Zeroize the slot after the string.
      mstore(str, 0)

      // Cache the end of the memory to calculate the length later.
      let end := str

      // We write the string from rightmost digit to leftmost digit.
      // The following is essentially a do-while loop that also handles the zero case.
      // prettier-ignore
      for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

      let length := sub(end, str)
      // Move the pointer 32 bytes leftwards to make room for the length.
      str := sub(str, 0x20)
      // Store the length.
      mstore(str, length)
    }
  }

  //*********************************************************************//
  // ------------------------ hooks and others ------------------------- //
  //*********************************************************************//

  /**
   * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
   * by `operator` from `from`, this function is called.
   *
   * It must return its Solidity selector to confirm the token transfer.
   * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
   *
   * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
   */
  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external pure override returns (bytes4) {
    return this.onERC721Received.selector;
  }

  /**
    @notice
    Indicates if this contract adheres to the specified interface.

    @dev
    See {IERC165-supportsInterface}.

    @param _interfaceId The ID of the interface to check for adherance to.
  */
  function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
    return
      _interfaceId == type(IERC165).interfaceId ||
      _interfaceId == type(IJBFundingCycleDataSource).interfaceId ||
      _interfaceId == type(IJBPayDelegate).interfaceId ||
      _interfaceId == type(IJBRedemptionDelegate).interfaceId;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import './BluntDelegate.sol';
import './interfaces/IBluntDelegateDeployer.sol';

contract BluntDelegateDeployer is IBluntDelegateDeployer {
  //*********************************************************************//
  // ---------------------- external transactions ---------------------- //
  //*********************************************************************//

  /** 
    @notice
    Deploys a BluntDelegate data source.

    @param _deployBluntDelegateDeployerData Data sent from the BluntDelegateProjectDeployer contract
    @param _deployBluntDelegateData Data necessary to fulfill the transaction to deploy a BluntDelegate data source.
    
    @return newDelegate The address of the newly deployed data source.
  */
  function deployDelegateFor(
    DeployBluntDelegateDeployerData memory _deployBluntDelegateDeployerData,
    DeployBluntDelegateData memory _deployBluntDelegateData
  ) external returns (address newDelegate) {
    newDelegate = address(
      new BluntDelegate(_deployBluntDelegateDeployerData, _deployBluntDelegateData)
    );

    emit DelegateDeployed(_deployBluntDelegateDeployerData.projectId, newDelegate);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBFundingCycleDataSource.sol';
import '../structs/DeployBluntDelegateDeployerData.sol';
import '../structs/DeployBluntDelegateData.sol';
import '../structs/RoundInfo.sol';

interface IBluntDelegate is
  IJBFundingCycleDataSource,
  IJBPayDelegate,
  IJBRedemptionDelegate,
  IERC721Receiver
{
  function getRoundInfo() external view returns (RoundInfo memory roundInfo);

  function closeRound() external;

  function setDeadline(uint256 deadline_) external;

  function isTargetReached() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '../structs/DeployBluntDelegateData.sol';
import '../structs/DeployBluntDelegateDeployerData.sol';

interface IBluntDelegateDeployer {
  event DelegateDeployed(uint256 indexed projectId, address newDelegate);

  function deployDelegateFor(
    DeployBluntDelegateDeployerData memory _deployBluntDelegateDeployerData,
    DeployBluntDelegateData memory _deployBluntDelegateData
  ) external returns (address newDelegate);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import '../structs/PoolData.sol';

interface IPriceFeed {
  function uniswapV3Factory() external view returns (address uniswapV3Factory);

  function activeFees(uint24 index) external view returns (bool);

  function fees(uint256 index) external view returns (uint24 fee);

  function pools(
    address token0,
    address token1
  )
    external
    view
    returns (
      address poolAddress,
      uint24 fee,
      uint48 lastUpdatedTimestamp,
      uint16 lastUpdatedCardinality
    );

  function getPool(address tokenA, address tokenB) external view returns (PoolData memory pool);

  function getQuote(
    uint128 baseAmount,
    address baseToken,
    address quoteToken,
    uint32 secondsTwapInterval
  ) external view returns (uint256 quoteAmount);

  function getUpdatedPool(
    address tokenA,
    address tokenB,
    uint256 secondsUpdateInterval,
    uint8 cardinalityNextIncrease
  ) external returns (PoolData memory pool, int56[] memory tickCumulatives, uint160 sqrtPriceX96);

  function getQuoteAndUpdatePool(
    uint128 baseAmount,
    address baseToken,
    address quoteToken,
    uint32 secondsTwapInterval,
    uint256 secondsUpdateInterval,
    uint8 cardinalityNextIncrease
  ) external returns (uint256 quoteAmount);

  function updatePool(
    address tokenA,
    address tokenB,
    uint8 cardinalityNextIncrease
  )
    external
    returns (
      PoolData memory highestLiquidityPool,
      int56[] memory tickCumulatives,
      uint160 sqrtPriceX96
    );

  function addFee(uint24 fee) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBDirectory.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/structs/JBSplit.sol';

struct DeployBluntDelegateData {
  IJBDirectory directory;
  address projectOwner;
  uint88 hardcap;
  uint88 target;
  uint16 afterRoundReservedRate;
  JBSplit[] afterRoundSplits;
  bool isTargetUsd;
  bool isHardcapUsd;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBController3_1.sol';

struct DeployBluntDelegateDeployerData {
  IJBController3_1 controller;
  uint48 feeProjectId;
  uint48 projectId;
  uint40 duration;
  address ethAddress;
  address usdcAddress;
  uint16 maxK;
  uint16 minK;
  uint56 upperFundraiseBoundary;
  uint56 lowerFundraiseBoundary;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

struct PoolData {
  address poolAddress;
  uint24 fee;
  uint48 lastUpdatedTimestamp;
  uint16 lastUpdatedCardinality;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@jbx-protocol/juice-contracts-v3/contracts/structs/JBSplit.sol';

struct RoundInfo {
  uint256 totalContributions;
  uint256 target;
  uint256 hardcap;
  address projectOwner;
  uint256 afterRoundReservedRate;
  JBSplit[] afterRoundSplits;
  bool isRoundClosed;
  uint256 deadline;
  bool isTargetUsd;
  bool isHardcapUsd;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum JBBallotState {
  Active,
  Approved,
  Failed
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../structs/JBFundAccessConstraints.sol';
import './../structs/JBFundingCycleData.sol';
import './../structs/JBFundingCycleMetadata.sol';
import './../structs/JBGroupedSplits.sol';
import './../structs/JBProjectMetadata.sol';
import './IJBDirectory.sol';
import './IJBFundingCycleStore.sol';
import './IJBMigratable.sol';
import './IJBPaymentTerminal.sol';
import './IJBSplitsStore.sol';
import './IJBTokenStore.sol';

interface IJBController is IERC165 {
  event LaunchProject(uint256 configuration, uint256 projectId, string memo, address caller);

  event LaunchFundingCycles(uint256 configuration, uint256 projectId, string memo, address caller);

  event ReconfigureFundingCycles(
    uint256 configuration,
    uint256 projectId,
    string memo,
    address caller
  );

  event SetFundAccessConstraints(
    uint256 indexed fundingCycleConfiguration,
    uint256 indexed fundingCycleNumber,
    uint256 indexed projectId,
    JBFundAccessConstraints constraints,
    address caller
  );

  event DistributeReservedTokens(
    uint256 indexed fundingCycleConfiguration,
    uint256 indexed fundingCycleNumber,
    uint256 indexed projectId,
    address beneficiary,
    uint256 tokenCount,
    uint256 beneficiaryTokenCount,
    string memo,
    address caller
  );

  event DistributeToReservedTokenSplit(
    uint256 indexed projectId,
    uint256 indexed domain,
    uint256 indexed group,
    JBSplit split,
    uint256 tokenCount,
    address caller
  );

  event MintTokens(
    address indexed beneficiary,
    uint256 indexed projectId,
    uint256 tokenCount,
    uint256 beneficiaryTokenCount,
    string memo,
    uint256 reservedRate,
    address caller
  );

  event BurnTokens(
    address indexed holder,
    uint256 indexed projectId,
    uint256 tokenCount,
    string memo,
    address caller
  );

  event Migrate(uint256 indexed projectId, IJBMigratable to, address caller);

  event PrepMigration(uint256 indexed projectId, address from, address caller);

  function projects() external view returns (IJBProjects);

  function fundingCycleStore() external view returns (IJBFundingCycleStore);

  function tokenStore() external view returns (IJBTokenStore);

  function splitsStore() external view returns (IJBSplitsStore);

  function directory() external view returns (IJBDirectory);

  function reservedTokenBalanceOf(uint256 _projectId, uint256 _reservedRate)
    external
    view
    returns (uint256);

  function distributionLimitOf(
    uint256 _projectId,
    uint256 _configuration,
    IJBPaymentTerminal _terminal,
    address _token
  ) external view returns (uint256 distributionLimit, uint256 distributionLimitCurrency);

  function overflowAllowanceOf(
    uint256 _projectId,
    uint256 _configuration,
    IJBPaymentTerminal _terminal,
    address _token
  ) external view returns (uint256 overflowAllowance, uint256 overflowAllowanceCurrency);

  function totalOutstandingTokensOf(uint256 _projectId, uint256 _reservedRate)
    external
    view
    returns (uint256);

  function getFundingCycleOf(uint256 _projectId, uint256 _configuration)
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBFundingCycleMetadata memory metadata);

  function latestConfiguredFundingCycleOf(uint256 _projectId)
    external
    view
    returns (
      JBFundingCycle memory,
      JBFundingCycleMetadata memory metadata,
      JBBallotState
    );

  function currentFundingCycleOf(uint256 _projectId)
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBFundingCycleMetadata memory metadata);

  function queuedFundingCycleOf(uint256 _projectId)
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBFundingCycleMetadata memory metadata);

  function launchProjectFor(
    address _owner,
    JBProjectMetadata calldata _projectMetadata,
    JBFundingCycleData calldata _data,
    JBFundingCycleMetadata calldata _metadata,
    uint256 _mustStartAtOrAfter,
    JBGroupedSplits[] memory _groupedSplits,
    JBFundAccessConstraints[] memory _fundAccessConstraints,
    IJBPaymentTerminal[] memory _terminals,
    string calldata _memo
  ) external returns (uint256 projectId);

  function launchFundingCyclesFor(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    JBFundingCycleMetadata calldata _metadata,
    uint256 _mustStartAtOrAfter,
    JBGroupedSplits[] memory _groupedSplits,
    JBFundAccessConstraints[] memory _fundAccessConstraints,
    IJBPaymentTerminal[] memory _terminals,
    string calldata _memo
  ) external returns (uint256 configuration);

  function reconfigureFundingCyclesOf(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    JBFundingCycleMetadata calldata _metadata,
    uint256 _mustStartAtOrAfter,
    JBGroupedSplits[] memory _groupedSplits,
    JBFundAccessConstraints[] memory _fundAccessConstraints,
    string calldata _memo
  ) external returns (uint256);

  function mintTokensOf(
    uint256 _projectId,
    uint256 _tokenCount,
    address _beneficiary,
    string calldata _memo,
    bool _preferClaimedTokens,
    bool _useReservedRate
  ) external returns (uint256 beneficiaryTokenCount);

  function burnTokensOf(
    address _holder,
    uint256 _projectId,
    uint256 _tokenCount,
    string calldata _memo,
    bool _preferClaimedTokens
  ) external;

  function distributeReservedTokensOf(uint256 _projectId, string memory _memo)
    external
    returns (uint256);

  function migrate(uint256 _projectId, IJBMigratable _to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../structs/JBFundAccessConstraints.sol';
import './../structs/JBFundingCycleData.sol';
import './../structs/JBFundingCycleMetadata.sol';
import './../structs/JBGroupedSplits.sol';
import './../structs/JBProjectMetadata.sol';
import './IJBController.sol';
import './IJBDirectory.sol';
import './IJBFundingCycleStore.sol';
import './IJBMigratable.sol';
import './IJBPaymentTerminal.sol';
import './IJBSplitsStore.sol';
import './IJBTokenStore.sol';

interface IJBController3_0_1 {
  function reservedTokenBalanceOf(uint256 _projectId) external view returns (uint256);
  function totalOutstandingTokensOf(uint256 _projectId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../structs/JBFundAccessConstraints.sol';
import './../structs/JBFundingCycleData.sol';
import './../structs/JBFundingCycleMetadata.sol';
import './../structs/JBGroupedSplits.sol';
import './../structs/JBProjectMetadata.sol';
import './IJBController3_0_1.sol';
import './IJBDirectory.sol';
import './IJBFundAccessConstraintsStore.sol';
import './IJBFundingCycleStore.sol';
import './IJBMigratable.sol';
import './IJBPaymentTerminal.sol';
import './IJBSplitsStore.sol';
import './IJBTokenStore.sol';

interface IJBController3_1 is IJBController3_0_1, IERC165 {
  event LaunchProject(uint256 configuration, uint256 projectId, string memo, address caller);

  event LaunchFundingCycles(uint256 configuration, uint256 projectId, string memo, address caller);

  event ReconfigureFundingCycles(
    uint256 configuration,
    uint256 projectId,
    string memo,
    address caller
  );

  event DistributeReservedTokens(
    uint256 indexed fundingCycleConfiguration,
    uint256 indexed fundingCycleNumber,
    uint256 indexed projectId,
    address beneficiary,
    uint256 tokenCount,
    uint256 beneficiaryTokenCount,
    string memo,
    address caller
  );

  event DistributeToReservedTokenSplit(
    uint256 indexed projectId,
    uint256 indexed domain,
    uint256 indexed group,
    JBSplit split,
    uint256 tokenCount,
    address caller
  );

  event MintTokens(
    address indexed beneficiary,
    uint256 indexed projectId,
    uint256 tokenCount,
    uint256 beneficiaryTokenCount,
    string memo,
    uint256 reservedRate,
    address caller
  );

  event BurnTokens(
    address indexed holder,
    uint256 indexed projectId,
    uint256 tokenCount,
    string memo,
    address caller
  );

  event Migrate(uint256 indexed projectId, IJBMigratable to, address caller);

  event PrepMigration(uint256 indexed projectId, address from, address caller);

  function projects() external view returns (IJBProjects);

  function fundingCycleStore() external view returns (IJBFundingCycleStore);

  function tokenStore() external view returns (IJBTokenStore);

  function splitsStore() external view returns (IJBSplitsStore);

  function fundAccessConstraintsStore() external view returns (IJBFundAccessConstraintsStore);

  function directory() external view returns (IJBDirectory);

  function reservedTokenBalanceOf(uint256 _projectId) external view returns (uint256);

  function totalOutstandingTokensOf(uint256 _projectId) external view returns (uint256);

  function getFundingCycleOf(uint256 _projectId, uint256 _configuration)
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBFundingCycleMetadata memory metadata);

  function latestConfiguredFundingCycleOf(uint256 _projectId)
    external
    view
    returns (
      JBFundingCycle memory,
      JBFundingCycleMetadata memory metadata,
      JBBallotState
    );

  function currentFundingCycleOf(uint256 _projectId)
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBFundingCycleMetadata memory metadata);

  function queuedFundingCycleOf(uint256 _projectId)
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBFundingCycleMetadata memory metadata);

  function launchProjectFor(
    address _owner,
    JBProjectMetadata calldata _projectMetadata,
    JBFundingCycleData calldata _data,
    JBFundingCycleMetadata calldata _metadata,
    uint256 _mustStartAtOrAfter,
    JBGroupedSplits[] memory _groupedSplits,
    JBFundAccessConstraints[] memory _fundAccessConstraints,
    IJBPaymentTerminal[] memory _terminals,
    string calldata _memo
  ) external returns (uint256 projectId);

  function launchFundingCyclesFor(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    JBFundingCycleMetadata calldata _metadata,
    uint256 _mustStartAtOrAfter,
    JBGroupedSplits[] memory _groupedSplits,
    JBFundAccessConstraints[] memory _fundAccessConstraints,
    IJBPaymentTerminal[] memory _terminals,
    string calldata _memo
  ) external returns (uint256 configuration);

  function reconfigureFundingCyclesOf(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    JBFundingCycleMetadata calldata _metadata,
    uint256 _mustStartAtOrAfter,
    JBGroupedSplits[] memory _groupedSplits,
    JBFundAccessConstraints[] memory _fundAccessConstraints,
    string calldata _memo
  ) external returns (uint256);

  function mintTokensOf(
    uint256 _projectId,
    uint256 _tokenCount,
    address _beneficiary,
    string calldata _memo,
    bool _preferClaimedTokens,
    bool _useReservedRate
  ) external returns (uint256 beneficiaryTokenCount);

  function burnTokensOf(
    address _holder,
    uint256 _projectId,
    uint256 _tokenCount,
    string calldata _memo,
    bool _preferClaimedTokens
  ) external;

  function distributeReservedTokensOf(uint256 _projectId, string memory _memo)
    external
    returns (uint256);

  function migrate(uint256 _projectId, IJBMigratable _to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IJBFundingCycleStore.sol';
import './IJBPaymentTerminal.sol';
import './IJBProjects.sol';

interface IJBDirectory {
  event SetController(uint256 indexed projectId, address indexed controller, address caller);

  event AddTerminal(uint256 indexed projectId, IJBPaymentTerminal indexed terminal, address caller);

  event SetTerminals(uint256 indexed projectId, IJBPaymentTerminal[] terminals, address caller);

  event SetPrimaryTerminal(
    uint256 indexed projectId,
    address indexed token,
    IJBPaymentTerminal indexed terminal,
    address caller
  );

  event SetIsAllowedToSetFirstController(address indexed addr, bool indexed flag, address caller);

  function projects() external view returns (IJBProjects);

  function fundingCycleStore() external view returns (IJBFundingCycleStore);

  function controllerOf(uint256 _projectId) external view returns (address);

  function isAllowedToSetFirstController(address _address) external view returns (bool);

  function terminalsOf(uint256 _projectId) external view returns (IJBPaymentTerminal[] memory);

  function isTerminalOf(uint256 _projectId, IJBPaymentTerminal _terminal)
    external
    view
    returns (bool);

  function primaryTerminalOf(uint256 _projectId, address _token)
    external
    view
    returns (IJBPaymentTerminal);

  function setControllerOf(uint256 _projectId, address _controller) external;

  function setTerminalsOf(uint256 _projectId, IJBPaymentTerminal[] calldata _terminals) external;

  function setPrimaryTerminalOf(
    uint256 _projectId,
    address _token,
    IJBPaymentTerminal _terminal
  ) external;

  function setIsAllowedToSetFirstController(address _address, bool _flag) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../structs/JBFundAccessConstraints.sol';
import './IJBPaymentTerminal.sol';

interface IJBFundAccessConstraintsStore is IERC165 {
  event SetFundAccessConstraints(
    uint256 indexed fundingCycleConfiguration,
    uint256 indexed projectId,
    JBFundAccessConstraints constraints,
    address caller
  );

  function distributionLimitOf(
    uint256 _projectId,
    uint256 _configuration,
    IJBPaymentTerminal _terminal,
    address _token
  ) external view returns (uint256 distributionLimit, uint256 distributionLimitCurrency);

  function overflowAllowanceOf(
    uint256 _projectId,
    uint256 _configuration,
    IJBPaymentTerminal _terminal,
    address _token
  ) external view returns (uint256 overflowAllowance, uint256 overflowAllowanceCurrency);

  function setFor(
    uint256 _projectId,
    uint256 _configuration,
    JBFundAccessConstraints[] memory _fundAccessConstaints
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../enums/JBBallotState.sol';

interface IJBFundingCycleBallot is IERC165 {
  function duration() external view returns (uint256);

  function stateOf(
    uint256 _projectId,
    uint256 _configuration,
    uint256 _start
  ) external view returns (JBBallotState);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../structs/JBPayDelegateAllocation.sol';
import './../structs/JBPayParamsData.sol';
import './../structs/JBRedeemParamsData.sol';
import './../structs/JBRedemptionDelegateAllocation.sol';

/**
  @title
  Datasource

  @notice
  The datasource is called by JBPaymentTerminal on pay and redemption, and provide an extra layer of logic to use 
  a custom weight, a custom memo and/or a pay/redeem delegate

  @dev
  Adheres to:
  IERC165 for adequate interface integration
*/
interface IJBFundingCycleDataSource is IERC165 {
  /**
    @notice
    The datasource implementation for JBPaymentTerminal.pay(..)

    @param _data the data passed to the data source in terminal.pay(..), as a JBPayParamsData struct:
                  IJBPaymentTerminal terminal;
                  address payer;
                  JBTokenAmount amount;
                  uint256 projectId;
                  uint256 currentFundingCycleConfiguration;
                  address beneficiary;
                  uint256 weight;
                  uint256 reservedRate;
                  string memo;
                  bytes metadata;

    @return weight the weight to use to override the funding cycle weight
    @return memo the memo to override the pay(..) memo
    @return delegateAllocations The amount to send to delegates instead of adding to the local balance.
  */
  function payParams(JBPayParamsData calldata _data)
    external
    returns (
      uint256 weight,
      string memory memo,
      JBPayDelegateAllocation[] memory delegateAllocations
    );

  /**
    @notice
    The datasource implementation for JBPaymentTerminal.redeemTokensOf(..)

    @param _data the data passed to the data source in terminal.redeemTokensOf(..), as a JBRedeemParamsData struct:
                    IJBPaymentTerminal terminal;
                    address holder;
                    uint256 projectId;
                    uint256 currentFundingCycleConfiguration;
                    uint256 tokenCount;
                    uint256 totalSupply;
                    uint256 overflow;
                    JBTokenAmount reclaimAmount;
                    bool useTotalOverflow;
                    uint256 redemptionRate;
                    uint256 ballotRedemptionRate;
                    string memo;
                    bytes metadata;

    @return reclaimAmount The amount to claim, overriding the terminal logic.
    @return memo The memo to override the redeemTokensOf(..) memo.
    @return delegateAllocations The amount to send to delegates instead of adding to the beneficiary.
  */
  function redeemParams(JBRedeemParamsData calldata _data)
    external
    returns (
      uint256 reclaimAmount,
      string memory memo,
      JBRedemptionDelegateAllocation[] memory delegateAllocations
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../enums/JBBallotState.sol';
import './../structs/JBFundingCycle.sol';
import './../structs/JBFundingCycleData.sol';

interface IJBFundingCycleStore {
  event Configure(
    uint256 indexed configuration,
    uint256 indexed projectId,
    JBFundingCycleData data,
    uint256 metadata,
    uint256 mustStartAtOrAfter,
    address caller
  );

  event Init(uint256 indexed configuration, uint256 indexed projectId, uint256 indexed basedOn);

  function latestConfigurationOf(uint256 _projectId) external view returns (uint256);

  function get(uint256 _projectId, uint256 _configuration)
    external
    view
    returns (JBFundingCycle memory);

  function latestConfiguredOf(uint256 _projectId)
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBBallotState ballotState);

  function queuedOf(uint256 _projectId) external view returns (JBFundingCycle memory fundingCycle);

  function currentOf(uint256 _projectId) external view returns (JBFundingCycle memory fundingCycle);

  function currentBallotStateOf(uint256 _projectId) external view returns (JBBallotState);

  function configureFor(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    uint256 _metadata,
    uint256 _mustStartAtOrAfter
  ) external returns (JBFundingCycle memory fundingCycle);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBMigratable {
  function prepForMigrationOf(uint256 _projectId, address _from) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../structs/JBDidPayData.sol';

/**
  @title
  Pay delegate

  @notice
  Delegate called after JBTerminal.pay(..) logic completion (if passed by the funding cycle datasource)

  @dev
  Adheres to:
  IERC165 for adequate interface integration
*/
interface IJBPayDelegate is IERC165 {
  /**
    @notice
    This function is called by JBPaymentTerminal.pay(..), after the execution of its logic

    @dev
    Critical business logic should be protected by an appropriate access control
    
    @param _data the data passed by the terminal, as a JBDidPayData struct:
                  address payer;
                  uint256 projectId;
                  uint256 currentFundingCycleConfiguration;
                  JBTokenAmount amount;
                  JBTokenAmount forwardedAmount;
                  uint256 projectTokenCount;
                  address beneficiary;
                  bool preferClaimedTokens;
                  string memo;
                  bytes metadata;
  */
  function didPay(JBDidPayData calldata _data) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

interface IJBPaymentTerminal is IERC165 {
  function acceptsToken(address _token, uint256 _projectId) external view returns (bool);

  function currencyForToken(address _token) external view returns (uint256);

  function decimalsForToken(address _token) external view returns (uint256);

  // Return value must be a fixed point number with 18 decimals.
  function currentEthOverflowOf(uint256 _projectId) external view returns (uint256);

  function pay(
    uint256 _projectId,
    uint256 _amount,
    address _token,
    address _beneficiary,
    uint256 _minReturnedTokens,
    bool _preferClaimedTokens,
    string calldata _memo,
    bytes calldata _metadata
  ) external payable returns (uint256 beneficiaryTokenCount);

  function addToBalanceOf(
    uint256 _projectId,
    uint256 _amount,
    address _token,
    string calldata _memo,
    bytes calldata _metadata
  ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBPayoutTerminal3_1 {
  function distributePayoutsOf(
    uint256 _projectId,
    uint256 _amount,
    uint256 _currency,
    address _token,
    uint256 _minReturnedTokens,
    bytes calldata _metadata
  ) external returns (uint256 netLeftoverDistributionAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import './../structs/JBProjectMetadata.sol';
import './IJBTokenUriResolver.sol';

interface IJBProjects is IERC721 {
  event Create(
    uint256 indexed projectId,
    address indexed owner,
    JBProjectMetadata metadata,
    address caller
  );

  event SetMetadata(uint256 indexed projectId, JBProjectMetadata metadata, address caller);

  event SetTokenUriResolver(IJBTokenUriResolver indexed resolver, address caller);

  function count() external view returns (uint256);

  function metadataContentOf(uint256 _projectId, uint256 _domain)
    external
    view
    returns (string memory);

  function tokenUriResolver() external view returns (IJBTokenUriResolver);

  function createFor(address _owner, JBProjectMetadata calldata _metadata)
    external
    returns (uint256 projectId);

  function setMetadataOf(uint256 _projectId, JBProjectMetadata calldata _metadata) external;

  function setTokenUriResolver(IJBTokenUriResolver _newResolver) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../structs/JBDidRedeemData.sol';

/**
  @title
  Redemption delegate

  @notice
  Delegate called after JBTerminal.redeemTokensOf(..) logic completion (if passed by the funding cycle datasource)

  @dev
  Adheres to:
  IERC165 for adequate interface integration
*/
interface IJBRedemptionDelegate is IERC165 {
  /**
    @notice
    This function is called by JBPaymentTerminal.redeemTokensOf(..), after the execution of its logic

    @dev
    Critical business logic should be protected by an appropriate access control
    
    @param _data the data passed by the terminal, as a JBDidRedeemData struct:
                address holder;
                uint256 projectId;
                uint256 currentFundingCycleConfiguration;
                uint256 projectTokenCount;
                JBTokenAmount reclaimedAmount;
                JBTokenAmount forwardedAmount;
                address payable beneficiary;
                string memo;
                bytes metadata;
  */
  function didRedeem(JBDidRedeemData calldata _data) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import '../structs/JBSplitAllocationData.sol';

/**
  @title
  Split allocator

  @notice
  Provide a way to process a single split with extra logic

  @dev
  Adheres to:
  IERC165 for adequate interface integration

  @dev
  The contract address should be set as an allocator in the adequate split
*/
interface IJBSplitAllocator is IERC165 {
  /**
    @notice
    This function is called by JBPaymentTerminal.distributePayoutOf(..), during the processing of the split including it

    @dev
    Critical business logic should be protected by an appropriate access control. The token and/or eth are optimistically transfered
    to the allocator for its logic.
    
    @param _data the data passed by the terminal, as a JBSplitAllocationData struct:
                  address token;
                  uint256 amount;
                  uint256 decimals;
                  uint256 projectId;
                  uint256 group;
                  JBSplit split;
  */
  function allocate(JBSplitAllocationData calldata _data) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../structs/JBGroupedSplits.sol';
import './../structs/JBSplit.sol';
import './IJBDirectory.sol';
import './IJBProjects.sol';

interface IJBSplitsStore {
  event SetSplit(
    uint256 indexed projectId,
    uint256 indexed domain,
    uint256 indexed group,
    JBSplit split,
    address caller
  );

  function projects() external view returns (IJBProjects);

  function directory() external view returns (IJBDirectory);

  function splitsOf(
    uint256 _projectId,
    uint256 _domain,
    uint256 _group
  ) external view returns (JBSplit[] memory);

  function set(
    uint256 _projectId,
    uint256 _domain,
    JBGroupedSplits[] memory _groupedSplits
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBToken {
  function projectId() external view returns (uint256);

  function decimals() external view returns (uint8);

  function totalSupply(uint256 _projectId) external view returns (uint256);

  function balanceOf(address _account, uint256 _projectId) external view returns (uint256);

  function mint(
    uint256 _projectId,
    address _account,
    uint256 _amount
  ) external;

  function burn(
    uint256 _projectId,
    address _account,
    uint256 _amount
  ) external;

  function approve(
    uint256,
    address _spender,
    uint256 _amount
  ) external;

  function transfer(
    uint256 _projectId,
    address _to,
    uint256 _amount
  ) external;

  function transferFrom(
    uint256 _projectId,
    address _from,
    address _to,
    uint256 _amount
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IJBFundingCycleStore.sol';
import './IJBProjects.sol';
import './IJBToken.sol';

interface IJBTokenStore {
  event Issue(
    uint256 indexed projectId,
    IJBToken indexed token,
    string name,
    string symbol,
    address caller
  );

  event Mint(
    address indexed holder,
    uint256 indexed projectId,
    uint256 amount,
    bool tokensWereClaimed,
    bool preferClaimedTokens,
    address caller
  );

  event Burn(
    address indexed holder,
    uint256 indexed projectId,
    uint256 amount,
    uint256 initialUnclaimedBalance,
    uint256 initialClaimedBalance,
    bool preferClaimedTokens,
    address caller
  );

  event Claim(
    address indexed holder,
    uint256 indexed projectId,
    uint256 initialUnclaimedBalance,
    uint256 amount,
    address caller
  );

  event Set(uint256 indexed projectId, IJBToken indexed newToken, address caller);

  event Transfer(
    address indexed holder,
    uint256 indexed projectId,
    address indexed recipient,
    uint256 amount,
    address caller
  );

  function tokenOf(uint256 _projectId) external view returns (IJBToken);

  function projects() external view returns (IJBProjects);

  function fundingCycleStore() external view returns (IJBFundingCycleStore);

  function unclaimedBalanceOf(address _holder, uint256 _projectId) external view returns (uint256);

  function unclaimedTotalSupplyOf(uint256 _projectId) external view returns (uint256);

  function totalSupplyOf(uint256 _projectId) external view returns (uint256);

  function balanceOf(address _holder, uint256 _projectId) external view returns (uint256 _result);

  function issueFor(
    uint256 _projectId,
    string calldata _name,
    string calldata _symbol
  ) external returns (IJBToken token);

  function setFor(uint256 _projectId, IJBToken _token) external;

  function burnFrom(
    address _holder,
    uint256 _projectId,
    uint256 _amount,
    bool _preferClaimedTokens
  ) external;

  function mintFor(
    address _holder,
    uint256 _projectId,
    uint256 _amount,
    bool _preferClaimedTokens
  ) external;

  function claimFor(
    address _holder,
    uint256 _projectId,
    uint256 _amount
  ) external;

  function transferFrom(
    address _holder,
    uint256 _projectId,
    address _recipient,
    uint256 _amount
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBTokenUriResolver {
  function getUri(uint256 _projectId) external view returns (string memory tokenUri);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './JBTokenAmount.sol';

/** 
  @member payer The address from which the payment originated.
  @member projectId The ID of the project for which the payment was made.
  @member currentFundingCycleConfiguration The configuration of the funding cycle during which the payment is being made.
  @member amount The amount of the payment. Includes the token being paid, the value, the number of decimals included, and the currency of the amount.
  @member forwardedAmount The amount of the payment that is being sent to the delegate. Includes the token being paid, the value, the number of decimals included, and the currency of the amount.
  @member projectTokenCount The number of project tokens minted for the beneficiary.
  @member beneficiary The address to which the tokens were minted.
  @member preferClaimedTokens A flag indicating whether the request prefered to mint project tokens into the beneficiaries wallet rather than leaving them unclaimed. This is only possible if the project has an attached token contract.
  @member memo The memo that is being emitted alongside the payment.
  @member metadata Extra data to send to the delegate.
*/
struct JBDidPayData {
  address payer;
  uint256 projectId;
  uint256 currentFundingCycleConfiguration;
  JBTokenAmount amount;
  JBTokenAmount forwardedAmount;
  uint256 projectTokenCount;
  address beneficiary;
  bool preferClaimedTokens;
  string memo;
  bytes metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './JBTokenAmount.sol';

/** 
  @member holder The holder of the tokens being redeemed.
  @member projectId The ID of the project with which the redeemed tokens are associated.
  @member currentFundingCycleConfiguration The configuration of the funding cycle during which the redemption is being made.
  @member projectTokenCount The number of project tokens being redeemed.
  @member reclaimedAmount The amount reclaimed from the treasury. Includes the token being reclaimed, the value, the number of decimals included, and the currency of the amount.
  @member forwardedAmount The amount of the payment that is being sent to the delegate. Includes the token being paid, the value, the number of decimals included, and the currency of the amount.
  @member beneficiary The address to which the reclaimed amount will be sent.
  @member memo The memo that is being emitted alongside the redemption.
  @member metadata Extra data to send to the delegate.
*/
struct JBDidRedeemData {
  address holder;
  uint256 projectId;
  uint256 currentFundingCycleConfiguration;
  uint256 projectTokenCount;
  JBTokenAmount reclaimedAmount;
  JBTokenAmount forwardedAmount;
  address payable beneficiary;
  string memo;
  bytes metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../interfaces/IJBPaymentTerminal.sol';

/** 
  @member terminal The terminal within which the distribution limit and the overflow allowance applies.
  @member token The token for which the fund access constraints apply.
  @member distributionLimit The amount of the distribution limit, as a fixed point number with the same number of decimals as the terminal within which the limit applies.
  @member distributionLimitCurrency The currency of the distribution limit.
  @member overflowAllowance The amount of the allowance, as a fixed point number with the same number of decimals as the terminal within which the allowance applies.
  @member overflowAllowanceCurrency The currency of the overflow allowance.
*/
struct JBFundAccessConstraints {
  IJBPaymentTerminal terminal;
  address token;
  uint256 distributionLimit;
  uint256 distributionLimitCurrency;
  uint256 overflowAllowance;
  uint256 overflowAllowanceCurrency;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../interfaces/IJBFundingCycleBallot.sol';

/** 
  @member number The funding cycle number for the cycle's project. Each funding cycle has a number that is an increment of the cycle that directly preceded it. Each project's first funding cycle has a number of 1.
  @member configuration The timestamp when the parameters for this funding cycle were configured. This value will stay the same for subsequent funding cycles that roll over from an originally configured cycle.
  @member basedOn The `configuration` of the funding cycle that was active when this cycle was created.
  @member start The timestamp marking the moment from which the funding cycle is considered active. It is a unix timestamp measured in seconds.
  @member duration The number of seconds the funding cycle lasts for, after which a new funding cycle will start. A duration of 0 means that the funding cycle will stay active until the project owner explicitly issues a reconfiguration, at which point a new funding cycle will immediately start with the updated properties. If the duration is greater than 0, a project owner cannot make changes to a funding cycle's parameters while it is active – any proposed changes will apply to the subsequent cycle. If no changes are proposed, a funding cycle rolls over to another one with the same properties but new `start` timestamp and a discounted `weight`.
  @member weight A fixed point number with 18 decimals that contracts can use to base arbitrary calculations on. For example, payment terminals can use this to determine how many tokens should be minted when a payment is received.
  @member discountRate A percent by how much the `weight` of the subsequent funding cycle should be reduced, if the project owner hasn't configured the subsequent funding cycle with an explicit `weight`. If it's 0, each funding cycle will have equal weight. If the number is 90%, the next funding cycle will have a 10% smaller weight. This weight is out of `JBConstants.MAX_DISCOUNT_RATE`.
  @member ballot An address of a contract that says whether a proposed reconfiguration should be accepted or rejected. It can be used to create rules around how a project owner can change funding cycle parameters over time.
  @member metadata Extra data that can be associated with a funding cycle.
*/
struct JBFundingCycle {
  uint256 number;
  uint256 configuration;
  uint256 basedOn;
  uint256 start;
  uint256 duration;
  uint256 weight;
  uint256 discountRate;
  IJBFundingCycleBallot ballot;
  uint256 metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../interfaces/IJBFundingCycleBallot.sol';

/** 
  @member duration The number of seconds the funding cycle lasts for, after which a new funding cycle will start. A duration of 0 means that the funding cycle will stay active until the project owner explicitly issues a reconfiguration, at which point a new funding cycle will immediately start with the updated properties. If the duration is greater than 0, a project owner cannot make changes to a funding cycle's parameters while it is active – any proposed changes will apply to the subsequent cycle. If no changes are proposed, a funding cycle rolls over to another one with the same properties but new `start` timestamp and a discounted `weight`.
  @member weight A fixed point number with 18 decimals that contracts can use to base arbitrary calculations on. For example, payment terminals can use this to determine how many tokens should be minted when a payment is received.
  @member discountRate A percent by how much the `weight` of the subsequent funding cycle should be reduced, if the project owner hasn't configured the subsequent funding cycle with an explicit `weight`. If it's 0, each funding cycle will have equal weight. If the number is 90%, the next funding cycle will have a 10% smaller weight. This weight is out of `JBConstants.MAX_DISCOUNT_RATE`.
  @member ballot An address of a contract that says whether a proposed reconfiguration should be accepted or rejected. It can be used to create rules around how a project owner can change funding cycle parameters over time.
*/
struct JBFundingCycleData {
  uint256 duration;
  uint256 weight;
  uint256 discountRate;
  IJBFundingCycleBallot ballot;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './JBGlobalFundingCycleMetadata.sol';

/** 
  @member global Data used globally in non-migratable ecosystem contracts.
  @member reservedRate The reserved rate of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_RESERVED_RATE`.
  @member redemptionRate The redemption rate of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_REDEMPTION_RATE`.
  @member ballotRedemptionRate The redemption rate to use during an active ballot of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_REDEMPTION_RATE`.
  @member pausePay A flag indicating if the pay functionality should be paused during the funding cycle.
  @member pauseDistributions A flag indicating if the distribute functionality should be paused during the funding cycle.
  @member pauseRedeem A flag indicating if the redeem functionality should be paused during the funding cycle.
  @member pauseBurn A flag indicating if the burn functionality should be paused during the funding cycle.
  @member allowMinting A flag indicating if minting tokens should be allowed during this funding cycle.
  @member allowTerminalMigration A flag indicating if migrating terminals should be allowed during this funding cycle.
  @member allowControllerMigration A flag indicating if migrating controllers should be allowed during this funding cycle.
  @member holdFees A flag indicating if fees should be held during this funding cycle.
  @member preferClaimedTokenOverride A flag indicating if claimed tokens should always be prefered to unclaimed tokens when minting.
  @member useTotalOverflowForRedemptions A flag indicating if redemptions should use the project's balance held in all terminals instead of the project's local terminal balance from which the redemption is being fulfilled.
  @member useDataSourceForPay A flag indicating if the data source should be used for pay transactions during this funding cycle.
  @member useDataSourceForRedeem A flag indicating if the data source should be used for redeem transactions during this funding cycle.
  @member dataSource The data source to use during this funding cycle.
  @member metadata Metadata of the metadata, up to uint8 in size.
*/
struct JBFundingCycleMetadata {
  JBGlobalFundingCycleMetadata global;
  uint256 reservedRate;
  uint256 redemptionRate;
  uint256 ballotRedemptionRate;
  bool pausePay;
  bool pauseDistributions;
  bool pauseRedeem;
  bool pauseBurn;
  bool allowMinting;
  bool allowTerminalMigration;
  bool allowControllerMigration;
  bool holdFees;
  bool preferClaimedTokenOverride;
  bool useTotalOverflowForRedemptions;
  bool useDataSourceForPay;
  bool useDataSourceForRedeem;
  address dataSource;
  uint256 metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** 
  @member allowSetTerminals A flag indicating if setting terminals should be allowed during this funding cycle.
  @member allowSetController A flag indicating if setting a new controller should be allowed during this funding cycle.
  @member pauseTransfers A flag indicating if the project token transfer functionality should be paused during the funding cycle.
*/
struct JBGlobalFundingCycleMetadata {
  bool allowSetTerminals;
  bool allowSetController;
  bool pauseTransfers;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './JBSplit.sol';

/** 
  @member group The group indentifier.
  @member splits The splits to associate with the group.
*/
struct JBGroupedSplits {
  uint256 group;
  JBSplit[] splits;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../interfaces/IJBPayDelegate.sol';

/** 
 @member delegate A delegate contract to use for subsequent calls.
 @member amount The amount to send to the delegate.
*/
struct JBPayDelegateAllocation {
  IJBPayDelegate delegate;
  uint256 amount;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../interfaces/IJBPaymentTerminal.sol';
import './JBTokenAmount.sol';

/** 
  @member terminal The terminal that is facilitating the payment.
  @member payer The address from which the payment originated.
  @member amount The amount of the payment. Includes the token being paid, the value, the number of decimals included, and the currency of the amount.
  @member projectId The ID of the project being paid.
  @member currentFundingCycleConfiguration The configuration of the funding cycle during which the payment is being made.
  @member beneficiary The specified address that should be the beneficiary of anything that results from the payment.
  @member weight The weight of the funding cycle during which the payment is being made.
  @member reservedRate The reserved rate of the funding cycle during which the payment is being made.
  @member memo The memo that was sent alongside the payment.
  @member metadata Extra data provided by the payer.
*/
struct JBPayParamsData {
  IJBPaymentTerminal terminal;
  address payer;
  JBTokenAmount amount;
  uint256 projectId;
  uint256 currentFundingCycleConfiguration;
  address beneficiary;
  uint256 weight;
  uint256 reservedRate;
  string memo;
  bytes metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** 
  @member content The metadata content.
  @member domain The domain within which the metadata applies.
*/
struct JBProjectMetadata {
  string content;
  uint256 domain;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../interfaces/IJBPaymentTerminal.sol';
import './JBTokenAmount.sol';

/** 
  @member terminal The terminal that is facilitating the redemption.
  @member holder The holder of the tokens being redeemed.
  @member projectId The ID of the project whos tokens are being redeemed.
  @member currentFundingCycleConfiguration The configuration of the funding cycle during which the redemption is being made.
  @member tokenCount The proposed number of tokens being redeemed, as a fixed point number with 18 decimals.
  @member totalSupply The total supply of tokens used in the calculation, as a fixed point number with 18 decimals.
  @member overflow The amount of overflow used in the reclaim amount calculation.
  @member reclaimAmount The amount that should be reclaimed by the redeemer using the protocol's standard bonding curve redemption formula. Includes the token being reclaimed, the reclaim value, the number of decimals included, and the currency of the reclaim amount.
  @member useTotalOverflow If overflow across all of a project's terminals is being used when making redemptions.
  @member redemptionRate The redemption rate of the funding cycle during which the redemption is being made.
  @member memo The proposed memo that is being emitted alongside the redemption.
  @member metadata Extra data provided by the redeemer.
*/
struct JBRedeemParamsData {
  IJBPaymentTerminal terminal;
  address holder;
  uint256 projectId;
  uint256 currentFundingCycleConfiguration;
  uint256 tokenCount;
  uint256 totalSupply;
  uint256 overflow;
  JBTokenAmount reclaimAmount;
  bool useTotalOverflow;
  uint256 redemptionRate;
  string memo;
  bytes metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../interfaces/IJBRedemptionDelegate.sol';

/** 
 @member delegate A delegate contract to use for subsequent calls.
 @member amount The amount to send to the delegate.
*/
struct JBRedemptionDelegateAllocation {
  IJBRedemptionDelegate delegate;
  uint256 amount;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../interfaces/IJBSplitAllocator.sol';

/** 
  @member preferClaimed A flag that only has effect if a projectId is also specified, and the project has a token contract attached. If so, this flag indicates if the tokens that result from making a payment to the project should be delivered claimed into the beneficiary's wallet, or unclaimed to save gas.
  @member preferAddToBalance A flag indicating if a distribution to a project should prefer triggering it's addToBalance function instead of its pay function.
  @member percent The percent of the whole group that this split occupies. This number is out of `JBConstants.SPLITS_TOTAL_PERCENT`.
  @member projectId The ID of a project. If an allocator is not set but a projectId is set, funds will be sent to the protocol treasury belonging to the project who's ID is specified. Resulting tokens will be routed to the beneficiary with the claimed token preference respected.
  @member beneficiary An address. The role the of the beneficary depends on whether or not projectId is specified, and whether or not an allocator is specified. If allocator is set, the beneficiary will be forwarded to the allocator for it to use. If allocator is not set but projectId is set, the beneficiary is the address to which the project's tokens will be sent that result from a payment to it. If neither allocator or projectId are set, the beneficiary is where the funds from the split will be sent.
  @member lockedUntil Specifies if the split should be unchangeable until the specified time, with the exception of extending the locked period.
  @member allocator If an allocator is specified, funds will be sent to the allocator contract along with all properties of this split.
*/
struct JBSplit {
  bool preferClaimed;
  bool preferAddToBalance;
  uint256 percent;
  uint256 projectId;
  address payable beneficiary;
  uint256 lockedUntil;
  IJBSplitAllocator allocator;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './JBSplit.sol';

/** 
  @member token The token being sent to the split allocator.
  @member amount The amount being sent to the split allocator, as a fixed point number.
  @member decimals The number of decimals in the amount.
  @member projectId The project to which the split belongs.
  @member group The group to which the split belongs.
  @member split The split that caused the allocation.
*/
struct JBSplitAllocationData {
  address token;
  uint256 amount;
  uint256 decimals;
  uint256 projectId;
  uint256 group;
  JBSplit split;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* 
  @member token The token the payment was made in.
  @member value The amount of tokens that was paid, as a fixed point number.
  @member decimals The number of decimals included in the value fixed point number.
  @member currency The expected currency of the value.
**/
struct JBTokenAmount {
  address token;
  uint256 value;
  uint256 decimals;
  uint256 currency;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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