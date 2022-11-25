// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import './interfaces/ISliceCore.sol';
import './interfaces/IBluntDelegate.sol';
import './interfaces/IPriceFeed.sol';

/// @title Blunt Round data source for Juicebox projects, based on Slice protocol.
/// @author jacopo <[email protected]>
/// @author jango <jango.eth>
/// @notice Funding rounds with pre-defined rules which reward contributors with tokens and slices.
contract BluntDelegate is IBluntDelegate {
  //*********************************************************************//
  // --------------------------- custom errors ------------------------- //
  //*********************************************************************//
  error INVALID_PAYMENT_EVENT();
  error CAP_REACHED();
  error SLICER_NOT_YET_CREATED();
  error VALUE_NOT_EXACT();
  error ROUND_CLOSED();
  error ROUND_NOT_CLOSED();
  error NOT_PROJECT_OWNER();
  error ALREADY_QUEUED();
  error TOKEN_NOT_SET();
  error CANNOT_ACCEPT_ERC1155();
  error CANNOT_ACCEPT_ERC721();

  //*********************************************************************//
  // ------------------------------ events ----------------------------- //
  //*********************************************************************//
  event RoundCreated(
    DeployBluntDelegateData deployBluntDelegateData,
    uint256 projectId,
    uint256 duration,
    uint256 currentFundingCycle
  );
  event ClaimedSlices(address beneficiary, uint256 amount);
  event ClaimedSlicesBatch(address[] beneficiaries, uint256[] amounts);
  event Queued();
  event TokenMetadataSet(string tokenName_, string tokenSymbol_);
  event RoundClosed();
  event SlicerCreated(uint256 slicerId_, address slicerAddress);

  //*********************************************************************//
  // ------------------------ immutable storage ------------------------ //
  //*********************************************************************//

  /**
    @notice
    Ratio between amount of tokens contributed and slices minted
  */
  uint64 public constant TOKENS_PER_SLICE = 1e15; /// 1 slice every 0.001 ETH

  /**
    @notice
    Max total contribution allowed, calculated from `TOKENS_PER_SLICE * type(uint32).max`
  */
  uint88 public constant MAX_CONTRIBUTION = 4.2e6 ether;

  /**
    @notice
    Price feed instance
  */
  IPriceFeed public constant priceFeed = IPriceFeed(0xf2E8176c0b67232b20205f4dfbCeC3e74bca471F);

  /**
    @notice
    The directory of terminals and controllers for projects.
  */
  IJBDirectory public immutable directory;

  IJBFundingCycleStore public immutable fundingCycleStore;

  IJBController public immutable controller;

  /**
    @notice
    SliceCore instance
  */
  ISliceCore public immutable sliceCore;

  /**
    @notice
    WETH address on Uniswap
  */
  address public immutable ethAddress;

  /**
    @notice
    USDC address on Uniswap
  */
  address public immutable usdcAddress;

  /**
    @notice
    The ID of the project.
  */
  uint256 public immutable projectId;

  /** 
    @notice
    The owner of the project once the blunt round is concluded successfully.
  */
  address private immutable projectOwner;

  /** 
    @notice
    The minimum amount of contributions while this data source is in effect.
    When `isTargetUsd` is enabled, it is a 6 point decimal number.
    @dev uint88 is sufficient as it cannot be higher than `MAX_CONTRIBUTION`
  */
  uint88 private immutable target;

  /** 
    @notice
    The maximum amount of contributions while this data source is in effect. 
    When `isHardcapUsd` is enabled, it is a 6 point decimal number.
    @dev uint88 is sufficient as it cannot be higher than `MAX_CONTRIBUTION`
  */
  uint88 private immutable hardcap;

  /**  
    @notice
    The timestamp when the slicer becomes releasable.
  */
  uint40 private immutable releaseTimelock;

  /** 
    @notice
    The timestamp when the slicer becomes transferable.
  */
  uint40 private immutable transferTimelock;

  /** 
    @notice
    The number of the funding cycle related to the blunt round.
    @dev uint40 is sufficient and saves gas with bit packing
  */
  uint40 private immutable fundingCycleRound;

  /** 
    @notice
    Reserved rate to be set in case of a successful round
  */
  uint16 private immutable afterRoundReservedRate;

  /**
    @notice
    True if a target is expressed in USD
  */
  bool private immutable isTargetUsd;

  /**
    @notice
    True if a hardcap is expressed in USD
  */
  bool private immutable isHardcapUsd;

  /**
    @notice
    True if a slicer is created when round closes successfully
  */
  bool private immutable isSlicerToBeCreated;

  //*********************************************************************//
  // ------------------------- mutable storage ------------------------- //
  //*********************************************************************//

  /**
    @notice
    ID of the slicer related to the blunt round
    
    @dev Assumes ID 0 is not created, since it's generally taken by the protocol.
    uint144 is sufficient and saves gas by bit packing efficiently.
  */
  uint144 private slicerId;

  /**
    @notice
    Total contributions received during round
    @dev uint88 is sufficient as it cannot be higher than `MAX_CONTRIBUTION`
  */
  uint88 private totalContributions;

  /**
    @notice
    True if the round has been closed 
  */
  bool private isRoundClosed;

  /**
    @notice
    True if the round has been queued
  */
  bool private isQueued;

  /** 
    @notice
    Name of the token to be issued in case of a successful round
  */
  string private tokenName;

  /** 
    @notice
    Symbol of the token to be issued in case of a successful round
  */
  string private tokenSymbol;

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
    @param _controller JBController address
    @param _projectId The ID of the project 
    @param _duration Blunt round duration
    @param _ethAddress WETH address on Uniswap
    @param _usdcAddress USDC address on Uniswap
    @param _deployBluntDelegateData Data required for deployment
  */
  constructor(
    IJBController _controller,
    uint256 _projectId,
    uint256 _duration,
    address _ethAddress,
    address _usdcAddress,
    DeployBluntDelegateData memory _deployBluntDelegateData
  ) {
    if (_deployBluntDelegateData.projectOwner.code.length != 0)
      _doSafeTransferAcceptanceCheckERC721(_deployBluntDelegateData.projectOwner);

    projectId = _projectId;
    ethAddress = _ethAddress;
    usdcAddress = _usdcAddress;
    controller = _controller;
    directory = _deployBluntDelegateData.directory;
    fundingCycleStore = _deployBluntDelegateData.fundingCycleStore;
    sliceCore = _deployBluntDelegateData.sliceCore;
    projectOwner = _deployBluntDelegateData.projectOwner;
    releaseTimelock = _deployBluntDelegateData.releaseTimelock;
    transferTimelock = _deployBluntDelegateData.transferTimelock;
    afterRoundReservedRate = _deployBluntDelegateData.afterRoundReservedRate;
    target = _deployBluntDelegateData.target;
    isTargetUsd = _deployBluntDelegateData.isTargetUsd;
    hardcap = _deployBluntDelegateData.hardcap;
    isHardcapUsd = _deployBluntDelegateData.isHardcapUsd;

    /// Set `isSlicerToBeCreated` if the first split is reserved to the slicer
    isSlicerToBeCreated =
      _deployBluntDelegateData.enforceSlicerCreation ||
      (_deployBluntDelegateData.afterRoundSplits.length != 0 &&
        _deployBluntDelegateData.afterRoundSplits[0].beneficiary == address(0));

    /// Set token name and symbol
    if (bytes(_deployBluntDelegateData.tokenName).length != 0)
      tokenName = _deployBluntDelegateData.tokenName;
    if (bytes(_deployBluntDelegateData.tokenSymbol).length != 0)
      tokenSymbol = _deployBluntDelegateData.tokenSymbol;

    /// Set `isQueued` if FC duration is zero
    if (_duration == 0) isQueued = true;

    /// Store afterRoundSplits
    for (uint256 i; i < _deployBluntDelegateData.afterRoundSplits.length; ) {
      afterRoundSplits.push(_deployBluntDelegateData.afterRoundSplits[i]);

      unchecked {
        ++i;
      }
    }

    uint256 currentFundingCycle;
    unchecked {
      currentFundingCycle =
        _deployBluntDelegateData.fundingCycleStore.currentOf(_projectId).number +
        1;
    }
    /// Store current funding cycle
    fundingCycleRound = uint40(currentFundingCycle);

    emit RoundCreated(_deployBluntDelegateData, _projectId, _duration, currentFundingCycle);
  }

  //*********************************************************************//
  // ---------------------- external transactions ---------------------- //
  //*********************************************************************//

  /**
    @notice 
    Part of IJBPayDelegate, this function gets called when the project receives a payment. 
    It will update storage for the slices mint if conditions are met.

    @dev 
    This function will revert if the contract calling is not one of the project's terminals. 
    Value sent must be a multiple of 0.001 ETH.

    @param _data The Juicebox standard project payment data.
  */
  function didPay(JBDidPayData calldata _data) external payable virtual override {
    /// Require that
    /// - The caller is a terminal of the project
    /// - The call is being made on behalf of an interaction with the correct project
    /// - The funding cycle related to the round hasn't ended
    /// - The blunt round hasn't been closed
    if (
      !directory.isTerminalOf(projectId, IJBPaymentTerminal(msg.sender)) ||
      _data.projectId != projectId ||
      fundingCycleStore.currentOf(projectId).number != fundingCycleRound ||
      isRoundClosed
    ) revert INVALID_PAYMENT_EVENT();

    /// Ensure contributed amount is a multiple of `TOKENS_PER_SLICE`
    if (_data.amount.value % TOKENS_PER_SLICE != 0) revert VALUE_NOT_EXACT();
    if (_data.amount.value > type(uint88).max) revert CAP_REACHED();

    /// Update totalContributions and contributions with amount paid
    totalContributions += uint88(_data.amount.value);

    /// Revert if `totalContributions` exceeds `hardcap` or `MAX_CONTRIBUTION`
    _hardcapCheck();

    /// If a slicer is to be created when round closes
    if (isSlicerToBeCreated) {
      /// If it's the first contribution of the beneficiary, and it is a contract
      if (contributions[_data.beneficiary] == 0 && _data.beneficiary.code.length != 0) {
        /// Revert if beneficiary doesn't accept ERC1155
        _doSafeTransferAcceptanceCheckERC1155(_data.beneficiary);
      }

      /// Cannot overflow as totalContributions would overflow first
      unchecked {
        contributions[_data.beneficiary] += _data.amount.value;
      }
    }
  }

  /**
    @notice 
    Part of IJBRedemptionDelegate, this function gets called when the beneficiary redeems tokens. 
    It will update storage for the slices mint if conditions are met.

    @dev 
    This function will revert if the contract calling is not one of the project's terminals. 
    Value redeemed must be a multiple of 0.001 ETH.

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

    /// Revert if round has been closed successfully
    if (isRoundClosed && isTargetReached()) revert ROUND_CLOSED();

    /// If round is open, execute logic to keep track of slices to issue
    if (!isRoundClosed) {
      /// Ensure contributed amount is a multiple of `TOKENS_PER_SLICE`
      if (_data.reclaimedAmount.value % TOKENS_PER_SLICE != 0) revert VALUE_NOT_EXACT();

      /// @dev Cannot underflow as `_data.reclaimedAmount.value` cannot be higher than `contributions[_data.beneficiary]`
      /// contributions can be inside unchecked as token transfers are disabled during round
      unchecked {
        /// Update totalContributions and contributions with amount redeemed
        totalContributions -= uint88(_data.reclaimedAmount.value);

        /// If a slicer is to be created when round closes
        if (isSlicerToBeCreated) {
          contributions[_data.beneficiary] -= _data.reclaimedAmount.value;
        }
      }
    }
  }

  /**
    @notice 
    Transfer any unclaimed slices to `beneficiaries` in batch.

    @dev 
    This function will revert if the slicer hasn't been created yet.
  */
  function transferUnclaimedSlicesTo(address[] calldata beneficiaries) external override {
    if (slicerId == 0) revert SLICER_NOT_YET_CREATED();

    /// Add reference for slices amounts of each beneficiary
    uint256[] memory amounts = new uint256[](beneficiaries.length);

    uint256 contribution;
    /// Loop over beneficiaries
    for (uint256 i; i < beneficiaries.length; ) {
      contribution = contributions[beneficiaries[i]];
      if (contribution != 0) {
        /// Calculate slices to claim and set the beneficiary amount in amounts array
        amounts[i] = contribution / TOKENS_PER_SLICE;
        /// Update storage
        contributions[beneficiaries[i]] = 0;
      }
      unchecked {
        ++i;
      }
    }

    /// Send slices to beneficiaries along with any earnings
    sliceCore.slicerBatchTransfer(address(this), beneficiaries, slicerId, amounts, false);

    emit ClaimedSlicesBatch(beneficiaries, amounts);
  }

  /**
    @notice 
    Allows a beneficiary to get any unclaimed slices to itself.

    @dev 
    This function will revert if the slicer hasn't been created yet.
  */
  function claimSlices() external override {
    if (slicerId == 0) revert SLICER_NOT_YET_CREATED();

    /// Calculate amount to claim
    uint256 amount = contributions[msg.sender] / TOKENS_PER_SLICE;

    if (amount != 0) {
      /// Update storage
      contributions[msg.sender] = 0;

      /// Send slices to beneficiary along with a proportional amount of tokens accrued
      sliceCore.safeTransferFromUnreleased(address(this), msg.sender, slicerId, amount, '');
    }

    emit ClaimedSlices(msg.sender, amount);
  }

  /**
    @notice 
    Configure next FC to have 0 duration in order for `closeRound` to have immediate effect
  */
  function queueNextPhase() external override {
    if (isQueued) revert ALREADY_QUEUED();
    isQueued = true;

    /// Get current FC data and metadata
    (, JBFundingCycleMetadata memory metadata) = controller.currentFundingCycleOf(projectId);

    /// Set JBFundingCycleData with duration 0 and null params
    JBFundingCycleData memory data = JBFundingCycleData({
      duration: 0,
      weight: 1,
      discountRate: 0,
      ballot: IJBFundingCycleBallot(address(0))
    });

    /// Configure next FC
    controller.reconfigureFundingCyclesOf(
      projectId,
      data,
      metadata,
      0,
      new JBGroupedSplits[](0),
      new JBFundAccessConstraints[](0),
      ''
    );

    emit Queued();
  }

  /**
    @notice 
    Update token metadata related to the project

    @dev
    Non null token name and symbol are required to close a round successfully
  */
  function setTokenMetadata(
    string memory tokenName_,
    string memory tokenSymbol_
  ) external override {
    if (msg.sender != projectOwner) revert NOT_PROJECT_OWNER();
    if (isRoundClosed) revert ROUND_CLOSED();

    tokenName = tokenName_;
    tokenSymbol = tokenSymbol_;

    emit TokenMetadataSet(tokenName_, tokenSymbol_);
  }

  /**
    @notice 
    Transfers the entire balance of an ERC20 token from this contract to the slicer if the round 
    was closed successfully, otherwise the project owner.
    Acts as safeguard if ERC20 tokens are mistakenly sent to this address, preventing them to end up locked.
    
    @dev Reverts if round is not closed.
  */
  function transferToken(IERC20 token) external override {
    if (!isRoundClosed) revert ROUND_NOT_CLOSED();
    uint256 slicerId_ = slicerId;

    address to = isTargetReached() && slicerId_ != 0 ? sliceCore.slicers(slicerId_) : projectOwner;
    token.transfer(to, token.balanceOf(address(this)));
  }

  /**
    @notice 
    Close blunt round if target has been reached. 
    Consists in minting slices to blunt delegate, reconfiguring next FC and transferring project NFT to projectOwner.
    If called when totalContributions hasn't reached the target, disables payments and keeps full redemptions enabled.

    @dev 
    Can only be called once by the appointed project owner.
  */
  function closeRound() external override {
    if (msg.sender != projectOwner) revert NOT_PROJECT_OWNER();
    if (isRoundClosed) revert ROUND_CLOSED();
    isRoundClosed = true;

    if (isTargetReached()) {
      /// Get current JBFundingCycleMetadata
      (, JBFundingCycleMetadata memory metadata) = controller.currentFundingCycleOf(projectId);

      /// Edit current metadata to:
      /// Set reservedRate from `afterRoundReservedRate`
      metadata.reservedRate = afterRoundReservedRate;
      /// Disable redemptions
      delete metadata.redemptionRate;
      /// Enable transfers
      delete metadata.global.pauseTransfers;
      /// Pause pay, to allow projectOwner to reconfig as needed before re-enabling
      metadata.pausePay = true;
      /// Detach dataSource
      delete metadata.useDataSourceForPay;
      delete metadata.useDataSourceForRedeem;
      delete metadata.dataSource;

      /// Set JBFundingCycleData
      JBFundingCycleData memory data = JBFundingCycleData({
        duration: 0,
        weight: 1e24, /// token issuance 1M
        discountRate: 0,
        ballot: IJBFundingCycleBallot(address(0))
      });

      address currency;
      string memory tokenName_ = tokenName;
      string memory tokenSymbol_ = tokenSymbol;
      /// If token name and symbol have been set
      if (bytes(tokenName_).length != 0 && bytes(tokenSymbol_).length != 0) {
        /// Issue ERC20 project token and get contract address
        currency = address(controller.tokenStore().issueFor(projectId, tokenName_, tokenSymbol_));
      }

      if (isSlicerToBeCreated) {
        /// Revert if currency hasn't been issued
        if (currency == address(0)) revert TOKEN_NOT_SET();

        /// Create slicer and mint slices to bluntDelegate
        address slicerAddress = _mintSlicesToDelegate(currency);

        if (afterRoundSplits.length != 0 && afterRoundSplits[0].beneficiary == address(0)) {
          /// Update split with slicer address
          afterRoundSplits[0].beneficiary = payable(slicerAddress);
          afterRoundSplits[0].preferClaimed = true;
        }
      }

      /// Format splits
      JBGroupedSplits[] memory splits = new JBGroupedSplits[](1);
      splits[0] = JBGroupedSplits(2, afterRoundSplits);

      /// Reconfigure Funding Cycle
      controller.reconfigureFundingCyclesOf(
        projectId,
        data,
        metadata,
        0,
        splits,
        new JBFundAccessConstraints[](0),
        ''
      );

      /// Transfer project ownership to projectOwner
      directory.projects().safeTransferFrom(address(this), projectOwner, projectId);
    }

    emit RoundClosed();
  }

  /**
    @notice 
    Creates project's token, slicer and issues `slicesToMint` to this contract.
  */
  function _mintSlicesToDelegate(address currency) private returns (address slicerAddress) {
    /// Calculate `slicesToMint`
    /// @dev Cannot overflow uint32 as totalContributions <= MAX_CONTRIBUTION
    uint32 slicesToMint = uint32(totalContributions / TOKENS_PER_SLICE);

    /// Add references for sliceParams
    Payee[] memory payees = new Payee[](1);
    payees[0] = Payee(address(this), slicesToMint, true);
    address[] memory acceptedCurrencies = new address[](1);
    acceptedCurrencies[0] = currency;

    /// Create slicer and mint all slices to this address
    uint256 slicerId_;
    (slicerId_, slicerAddress) = sliceCore.slice(
      SliceParams(
        payees,
        slicesToMint, /// 100% superowner slices
        acceptedCurrencies,
        releaseTimelock,
        transferTimelock,
        address(0),
        0,
        0
      )
    );

    slicerId = uint144(slicerId_);

    emit SlicerCreated(slicerId_, slicerAddress);
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
    Indicates if this contract adheres to the specified interface.

    @dev
    See {IERC165-supportsInterface}.

    @param _interfaceId The ID of the interface to check for adherance to.
  */
  function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
    return
      _interfaceId == type(IJBFundingCycleDataSource).interfaceId ||
      _interfaceId == type(IJBPayDelegate).interfaceId;
  }

  /**
    @notice
    Returns info related to round.
  */
  function getRoundInfo() external view override returns (RoundInfo memory roundInfo) {
    roundInfo = RoundInfo(
      totalContributions,
      target,
      hardcap,
      releaseTimelock,
      transferTimelock,
      projectOwner,
      fundingCycleRound,
      afterRoundReservedRate,
      afterRoundSplits,
      tokenName,
      tokenSymbol,
      isRoundClosed,
      isQueued,
      isTargetUsd,
      isHardcapUsd,
      isSlicerToBeCreated,
      slicerId
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
    Revert if total contributions received surpass the round hardcap.
    Used in `didPay`
  */
  function _hardcapCheck() private view {
    uint256 hardcap_ = hardcap;
    if (hardcap_ != 0) {
      if (isHardcapUsd) {
        hardcap_ = priceFeed.getQuote(uint128(hardcap_), usdcAddress, ethAddress, 30 minutes);
      }
    } else {
      hardcap_ = MAX_CONTRIBUTION;
    }

    if (totalContributions > hardcap_) revert CAP_REACHED();
  }

  /**
    @notice
    See {ERC1155:_doSafeTransferAcceptanceCheck}
  */
  function _doSafeTransferAcceptanceCheckERC1155(address to) private {
    try IERC1155Receiver(to).onERC1155Received(address(this), address(this), 1, 1, '') returns (
      bytes4 response
    ) {
      if (response != this.onERC1155Received.selector) {
        revert CANNOT_ACCEPT_ERC1155();
      }
    } catch Error(string memory reason) {
      revert(reason);
    } catch {
      revert CANNOT_ACCEPT_ERC1155();
    }
  }

  /**
    @notice
    See {ERC721:_checkOnERC721Received}
  */
  function _doSafeTransferAcceptanceCheckERC721(address to) private {
    try IERC721Receiver(to).onERC721Received(address(this), address(this), 1, '') returns (
      bytes4 response
    ) {
      if (response != this.onERC721Received.selector) {
        revert CANNOT_ACCEPT_ERC721();
      }
    } catch Error(string memory reason) {
      revert(reason);
    } catch {
      revert CANNOT_ACCEPT_ERC721();
    }
  }

  //*********************************************************************//
  // ------------------------------ hooks ------------------------------ //
  //*********************************************************************//

  /**
   * @dev See `ERC1155Receiver`
   */
  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes memory
  ) public view override returns (bytes4) {
    if (msg.sender != address(sliceCore)) revert('NOT_SUPPORTED');
    return this.onERC1155Received.selector;
  }

  /**
   * @dev See `ERC1155Receiver`
   */
  function onERC1155BatchReceived(
    address,
    address,
    uint256[] memory,
    uint256[] memory,
    bytes memory
  ) public view override returns (bytes4) {
    if (msg.sender != address(sliceCore)) revert('NOT_SUPPORTED');
    return this.onERC1155BatchReceived.selector;
  }

  /**
   * @dev See `ERC721Receiver`
   */
  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) public pure override returns (bytes4) {
    return this.onERC721Received.selector;
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

    @param _controller JBController address
    @param _projectId The ID of the project for which the data source should apply.
    @param _duration Blunt round duration
    @param _ethAddress WETH address on Uniswap
    @param _usdcAddress USDC address on Uniswap
    @param _deployBluntDelegateData Data necessary to fulfill the transaction to deploy a BluntDelegate data source.

    @return newDelegate The address of the newly deployed data source.
  */
  function deployDelegateFor(
    IJBController _controller,
    uint256 _projectId,
    uint256 _duration,
    address _ethAddress,
    address _usdcAddress,
    DeployBluntDelegateData memory _deployBluntDelegateData
  ) external returns (address newDelegate) {
    newDelegate = address(
      new BluntDelegate(
        _controller,
        _projectId,
        _duration,
        _ethAddress,
        _usdcAddress,
        _deployBluntDelegateData
      )
    );

    emit DelegateDeployed(_projectId, newDelegate);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBFundingCycleDataSource.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBController.sol';
import '../structs/DeployBluntDelegateData.sol';
import '../structs/RoundInfo.sol';

interface IBluntDelegate is
  IJBFundingCycleDataSource,
  IJBPayDelegate,
  IJBRedemptionDelegate,
  IERC1155Receiver,
  IERC721Receiver
{
  function getRoundInfo() external view returns (RoundInfo memory roundInfo);

  function transferUnclaimedSlicesTo(address[] calldata beneficiaries) external;

  function claimSlices() external;

  function setTokenMetadata(string memory tokenName_, string memory tokenSymbol_) external;

  function transferToken(IERC20 token) external;

  function queueNextPhase() external;

  function closeRound() external;

  function isTargetReached() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBController.sol';
import '../structs/DeployBluntDelegateData.sol';

interface IBluntDelegateDeployer {
  event DelegateDeployed(uint256 indexed projectId, address newDelegate);

  function deployDelegateFor(
    IJBController _controller,
    uint256 _projectId,
    uint256 _duration,
    address _ethAddress,
    address _usdcAddress,
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
pragma solidity ^0.8.0;

import './ISlicer.sol';
import './ISlicerManager.sol';
import '@openzeppelin/contracts/interfaces/IERC1155.sol';
import '@openzeppelin/contracts/interfaces/IERC2981.sol';

interface ISliceCore is IERC1155, IERC2981 {
  function slicerManager() external view returns (ISlicerManager slicerManagerAddress);

  function slice(
    SliceParams calldata params
  ) external returns (uint256 slicerId, address slicerAddress);

  function reslice(
    uint256 tokenId,
    address payable[] calldata accounts,
    int32[] calldata tokensDiffs
  ) external;

  function slicerBatchTransfer(
    address from,
    address[] memory recipients,
    uint256 id,
    uint256[] memory amounts,
    bool release
  ) external;

  function safeTransferFromUnreleased(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) external;

  function setController(uint256 id, address newController) external;

  function setRoyalty(
    uint256 tokenId,
    bool isSlicer,
    bool isActive,
    uint256 royaltyPercentage
  ) external;

  function _slicers(
    uint256 id
  ) external view returns (ISlicer, address, uint40, uint32, uint8, uint8, uint8);

  function slicers(uint256 id) external view returns (address);

  function controller(uint256 id) external view returns (address);

  function totalSupply(uint256 id) external view returns (uint256);

  function supply() external view returns (uint256);

  function exists(uint256 id) external view returns (bool);

  function owner() external view returns (address owner);

  function _setBasePath(string calldata basePath_) external;

  function _togglePause() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../structs/DepositAmount.sol';
import '../structs/AccountAmount.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';

interface ISlicer is IERC721Receiver, IERC1155Receiver {
  function release(address account, address currency, bool withdraw) external;

  function batchReleaseAccounts(
    address[] memory accounts,
    address currency,
    bool withdraw
  ) external;

  function depositFromVault(DepositAmount[] memory deposits, address currency) external;

  function disperseFromVault(AccountAmount[] memory distributions, address currency) external;

  function unreleased(
    address account,
    address currency
  ) external view returns (uint256 unreleasedAmount);

  function getFee() external view returns (uint256 fee);

  function getFeeForAccount(address account) external view returns (uint256 fee);

  function slicerInfo()
    external
    view
    returns (
      uint256 tokenId,
      uint256 minimumShares,
      address creator,
      bool isImmutable,
      bool currenciesControlled,
      bool productsControlled,
      bool acceptsAllCurrencies,
      address[] memory currencies
    );

  function isPayeeAllowed(address payee) external view returns (bool);

  function acceptsCurrency(address currency) external view returns (bool);

  function _updatePayees(
    address payable sender,
    address receiver,
    bool toRelease,
    uint256 senderShares,
    uint256 transferredShares
  ) external;

  function _updatePayeesReslice(
    address payable[] memory accounts,
    int32[] memory tokensDiffs,
    uint32 totalSupply
  ) external;

  function _setChildSlicer(uint256 id, bool addChildSlicerMode) external;

  function _setTotalShares(uint256 totalShares) external;

  function _addCurrencies(address[] memory currencies) external;

  function _setCustomFee(bool customFeeActive, uint256 customFee) external;

  function _releaseFromSliceCore(address account, address currency, uint256 accountSlices) external;

  function _releaseFromFundsModule(
    address account,
    address currency
  ) external returns (uint256 amount, uint256 protocolPayment);

  function _handle721Purchase(address buyer, address contractAddress, uint256 tokenId) external;

  function _handle1155Purchase(
    address buyer,
    address contractAddress,
    uint256 quantity,
    uint256 tokenId
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import '../structs/SliceParams.sol';

interface ISlicerManager {
  function implementation() external view returns (address);

  function _createSlicer(
    address creator,
    uint256 id,
    SliceParams calldata params
  ) external returns (address);

  function _upgradeSlicers(address newLogicImpl) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct AccountAmount {
  address account;
  uint256 amount;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '../interfaces/ISliceCore.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBDirectory.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBFundingCycleStore.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/structs/JBSplit.sol';

struct DeployBluntDelegateData {
  IJBDirectory directory;
  IJBFundingCycleStore fundingCycleStore;
  ISliceCore sliceCore;
  address projectOwner;
  uint88 hardcap;
  uint88 target;
  uint40 releaseTimelock;
  uint40 transferTimelock;
  uint16 afterRoundReservedRate;
  JBSplit[] afterRoundSplits;
  string tokenName;
  string tokenSymbol;
  bool enforceSlicerCreation;
  bool isTargetUsd;
  bool isHardcapUsd;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct DepositAmount {
  address account;
  uint256 amount;
  uint256 protocolPayment;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Payee {
  address account;
  uint32 shares;
  bool transfersAllowedWhileLocked;
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
  uint40 releaseTimelock;
  uint40 transferTimelock;
  address projectOwner;
  uint40 fundingCycleRound;
  uint16 afterRoundReservedRate;
  JBSplit[] afterRoundSplits;
  string tokenName;
  string tokenSymbol;
  bool isRoundClosed;
  bool isQueued;
  bool isTargetUsd;
  bool isHardcapUsd;
  bool isSlicerToBeCreated;
  uint256 slicerId;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Payee.sol';

/**
 * @param payees Addresses and shares of the initial payees
 * @param minimumShares Amount of shares that gives an account access to restricted
 * @param currencies Array of tokens accepted by the slicer
 * @param releaseTimelock The timestamp when the slicer becomes releasable
 * @param transferTimelock The timestamp when the slicer becomes transferable
 * @param controller The address of the slicer controller
 * @param slicerFlags See `_flags` in {Slicer}
 * @param sliceCoreFlags See `flags` in {SlicerParams} struct
 */
struct SliceParams {
  Payee[] payees;
  uint256 minimumShares;
  address[] currencies;
  uint256 releaseTimelock;
  uint40 transferTimelock;
  address controller;
  uint8 slicerFlags;
  uint8 sliceCoreFlags;
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

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