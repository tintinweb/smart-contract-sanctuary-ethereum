// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma abicoder v2;

interface IGovernanceStrategy {
  /**
   * @dev Returns the Proposition Power of a user at a specific block number.
   * @param user Address of the user.
   * @param blockNumber Blocknumber at which to fetch Proposition Power
   * @return Power number
   **/
  function getPropositionPowerAt(address user, uint256 blockNumber)
    external
    view
    returns (uint256);

  /**
   * @dev Returns the total supply of Outstanding Proposition Tokens
   * @param blockNumber Blocknumber at which to evaluate
   * @return total supply at blockNumber
   **/
  function getTotalPropositionSupplyAt(uint256 blockNumber)
    external
    view
    returns (uint256);

  /**
   * @dev Returns the total supply of Outstanding Voting Tokens
   * @param blockNumber Blocknumber at which to evaluate
   * @return total supply at blockNumber
   **/
  function getTotalVotingSupplyAt(uint256 blockNumber)
    external
    view
    returns (uint256);

  /**
   * @dev Returns the Vote Power of a user at a specific block number.
   * @param user Address of the user.
   * @param blockNumber Blocknumber at which to fetch Vote Power
   * @return Vote number
   **/
  function getVotingPowerAt(address user, uint256 blockNumber)
    external
    view
    returns (uint256);
}

interface IExecutorWithTimelock {
  /**
   * @dev emitted when a new pending admin is set
   * @param newPendingAdmin address of the new pending admin
   **/
  event NewPendingAdmin(address newPendingAdmin);

  /**
   * @dev emitted when a new admin is set
   * @param newAdmin address of the new admin
   **/
  event NewAdmin(address newAdmin);

  /**
   * @dev emitted when a new delay (between queueing and execution) is set
   * @param delay new delay
   **/
  event NewDelay(uint256 delay);

  /**
   * @dev emitted when a new (trans)action is Queued.
   * @param actionHash hash of the action
   * @param target address of the targeted contract
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   **/
  event QueuedAction(
    bytes32 actionHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 executionTime,
    bool withDelegatecall
  );

  /**
   * @dev emitted when an action is Cancelled
   * @param actionHash hash of the action
   * @param target address of the targeted contract
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   **/
  event CancelledAction(
    bytes32 actionHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 executionTime,
    bool withDelegatecall
  );

  /**
   * @dev emitted when an action is Cancelled
   * @param actionHash hash of the action
   * @param target address of the targeted contract
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   * @param resultData the actual callData used on the target
   **/
  event ExecutedAction(
    bytes32 actionHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 executionTime,
    bool withDelegatecall,
    bytes resultData
  );

  /**
   * @dev Getter of the current admin address (should be governance)
   * @return The address of the current admin
   **/
  function getAdmin() external view returns (address);

  /**
   * @dev Getter of the current pending admin address
   * @return The address of the pending admin
   **/
  function getPendingAdmin() external view returns (address);

  /**
   * @dev Getter of the delay between queuing and execution
   * @return The delay in seconds
   **/
  function getDelay() external view returns (uint256);

  /**
   * @dev Returns whether an action (via actionHash) is queued
   * @param actionHash hash of the action to be checked
   * keccak256(abi.encode(target, value, signature, data, executionTime, withDelegatecall))
   * @return true if underlying action of actionHash is queued
   **/
  function isActionQueued(bytes32 actionHash) external view returns (bool);

  /**
   * @dev Checks whether a proposal is over its grace period
   * @param governance Governance contract
   * @param proposalId Id of the proposal against which to test
   * @return true of proposal is over grace period
   **/
  function isProposalOverGracePeriod(
    IAaveGovernanceV2 governance,
    uint256 proposalId
  ) external view returns (bool);

  /**
   * @dev Getter of grace period constant
   * @return grace period in seconds
   **/
  function GRACE_PERIOD() external view returns (uint256);

  /**
   * @dev Getter of minimum delay constant
   * @return minimum delay in seconds
   **/
  function MINIMUM_DELAY() external view returns (uint256);

  /**
   * @dev Getter of maximum delay constant
   * @return maximum delay in seconds
   **/
  function MAXIMUM_DELAY() external view returns (uint256);

  /**
   * @dev Function, called by Governance, that queue a transaction, returns action hash
   * @param target smart contract target
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   **/
  function queueTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) external returns (bytes32);

  /**
   * @dev Function, called by Governance, that cancels a transaction, returns the callData executed
   * @param target smart contract target
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   **/
  function executeTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) external payable returns (bytes memory);

  /**
   * @dev Function, called by Governance, that cancels a transaction, returns action hash
   * @param target smart contract target
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   **/
  function cancelTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) external returns (bytes32);
}

interface IAaveGovernanceV2 {
  enum ProposalState {
    Pending,
    Canceled,
    Active,
    Failed,
    Succeeded,
    Queued,
    Expired,
    Executed
  }

  struct Vote {
    bool support;
    uint248 votingPower;
  }

  struct Proposal {
    uint256 id;
    address creator;
    IExecutorWithTimelock executor;
    address[] targets;
    uint256[] values;
    string[] signatures;
    bytes[] calldatas;
    bool[] withDelegatecalls;
    uint256 startBlock;
    uint256 endBlock;
    uint256 executionTime;
    uint256 forVotes;
    uint256 againstVotes;
    bool executed;
    bool canceled;
    address strategy;
    bytes32 ipfsHash;
    mapping(address => Vote) votes;
  }

  struct ProposalWithoutVotes {
    uint256 id;
    address creator;
    IExecutorWithTimelock executor;
    address[] targets;
    uint256[] values;
    string[] signatures;
    bytes[] calldatas;
    bool[] withDelegatecalls;
    uint256 startBlock;
    uint256 endBlock;
    uint256 executionTime;
    uint256 forVotes;
    uint256 againstVotes;
    bool executed;
    bool canceled;
    address strategy;
    bytes32 ipfsHash;
  }

  /**
   * @dev emitted when a new proposal is created
   * @param id Id of the proposal
   * @param creator address of the creator
   * @param executor The ExecutorWithTimelock contract that will execute the proposal
   * @param targets list of contracts called by proposal's associated transactions
   * @param values list of value in wei for each propoposal's associated transaction
   * @param signatures list of function signatures (can be empty) to be used when created the callData
   * @param calldatas list of calldatas: if associated signature empty, calldata ready, else calldata is arguments
   * @param withDelegatecalls boolean, true = transaction delegatecalls the taget, else calls the target
   * @param startBlock block number when vote starts
   * @param endBlock block number when vote ends
   * @param strategy address of the governanceStrategy contract
   * @param ipfsHash IPFS hash of the proposal
   **/
  event ProposalCreated(
    uint256 id,
    address indexed creator,
    IExecutorWithTimelock indexed executor,
    address[] targets,
    uint256[] values,
    string[] signatures,
    bytes[] calldatas,
    bool[] withDelegatecalls,
    uint256 startBlock,
    uint256 endBlock,
    address strategy,
    bytes32 ipfsHash
  );

  /**
   * @dev emitted when a proposal is canceled
   * @param id Id of the proposal
   **/
  event ProposalCanceled(uint256 id);

  /**
   * @dev emitted when a proposal is queued
   * @param id Id of the proposal
   * @param executionTime time when proposal underlying transactions can be executed
   * @param initiatorQueueing address of the initiator of the queuing transaction
   **/
  event ProposalQueued(
    uint256 id,
    uint256 executionTime,
    address indexed initiatorQueueing
  );
  /**
   * @dev emitted when a proposal is executed
   * @param id Id of the proposal
   * @param initiatorExecution address of the initiator of the execution transaction
   **/
  event ProposalExecuted(uint256 id, address indexed initiatorExecution);
  /**
   * @dev emitted when a vote is registered
   * @param id Id of the proposal
   * @param voter address of the voter
   * @param support boolean, true = vote for, false = vote against
   * @param votingPower Power of the voter/vote
   **/
  event VoteEmitted(
    uint256 id,
    address indexed voter,
    bool support,
    uint256 votingPower
  );

  event GovernanceStrategyChanged(
    address indexed newStrategy,
    address indexed initiatorChange
  );

  event VotingDelayChanged(
    uint256 newVotingDelay,
    address indexed initiatorChange
  );

  event ExecutorAuthorized(address executor);

  event ExecutorUnauthorized(address executor);

  /**
   * @dev Creates a Proposal (needs Proposition Power of creator > Threshold)
   * @param executor The ExecutorWithTimelock contract that will execute the proposal
   * @param targets list of contracts called by proposal's associated transactions
   * @param values list of value in wei for each propoposal's associated transaction
   * @param signatures list of function signatures (can be empty) to be used when created the callData
   * @param calldatas list of calldatas: if associated signature empty, calldata ready, else calldata is arguments
   * @param withDelegatecalls if true, transaction delegatecalls the taget, else calls the target
   * @param ipfsHash IPFS hash of the proposal
   **/
  function create(
    IExecutorWithTimelock executor,
    address[] memory targets,
    uint256[] memory values,
    string[] memory signatures,
    bytes[] memory calldatas,
    bool[] memory withDelegatecalls,
    bytes32 ipfsHash
  ) external returns (uint256);

  /**
   * @dev Cancels a Proposal,
   * either at anytime by guardian
   * or when proposal is Pending/Active and threshold no longer reached
   * @param proposalId id of the proposal
   **/
  function cancel(uint256 proposalId) external;

  /**
   * @dev Queue the proposal (If Proposal Succeeded)
   * @param proposalId id of the proposal to queue
   **/
  function queue(uint256 proposalId) external;

  /**
   * @dev Execute the proposal (If Proposal Queued)
   * @param proposalId id of the proposal to execute
   **/
  function execute(uint256 proposalId) external payable;

  /**
   * @dev Function allowing msg.sender to vote for/against a proposal
   * @param proposalId id of the proposal
   * @param support boolean, true = vote for, false = vote against
   **/
  function submitVote(uint256 proposalId, bool support) external;

  /**
   * @dev Function to register the vote of user that has voted offchain via signature
   * @param proposalId id of the proposal
   * @param support boolean, true = vote for, false = vote against
   * @param v v part of the voter signature
   * @param r r part of the voter signature
   * @param s s part of the voter signature
   **/
  function submitVoteBySignature(
    uint256 proposalId,
    bool support,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @dev Set new GovernanceStrategy
   * Note: owner should be a timelocked executor, so needs to make a proposal
   * @param governanceStrategy new Address of the GovernanceStrategy contract
   **/
  function setGovernanceStrategy(address governanceStrategy) external;

  /**
   * @dev Set new Voting Delay (delay before a newly created proposal can be voted on)
   * Note: owner should be a timelocked executor, so needs to make a proposal
   * @param votingDelay new voting delay in seconds
   **/
  function setVotingDelay(uint256 votingDelay) external;

  /**
   * @dev Add new addresses to the list of authorized executors
   * @param executors list of new addresses to be authorized executors
   **/
  function authorizeExecutors(address[] memory executors) external;

  /**
   * @dev Remove addresses to the list of authorized executors
   * @param executors list of addresses to be removed as authorized executors
   **/
  function unauthorizeExecutors(address[] memory executors) external;

  /**
   * @dev Let the guardian abdicate from its priviledged rights
   **/
  function __abdicate() external;

  /**
   * @dev Getter of the current GovernanceStrategy address
   * @return The address of the current GovernanceStrategy contracts
   **/
  function getGovernanceStrategy() external view returns (address);

  /**
   * @dev Getter of the current Voting Delay (delay before a created proposal can be voted on)
   * Different from the voting duration
   * @return The voting delay in seconds
   **/
  function getVotingDelay() external view returns (uint256);

  /**
   * @dev Returns whether an address is an authorized executor
   * @param executor address to evaluate as authorized executor
   * @return true if authorized
   **/
  function isExecutorAuthorized(address executor) external view returns (bool);

  /**
   * @dev Getter the address of the guardian, that can mainly cancel proposals
   * @return The address of the guardian
   **/
  function getGuardian() external view returns (address);

  /**
   * @dev Getter of the proposal count (the current number of proposals ever created)
   * @return the proposal count
   **/
  function getProposalsCount() external view returns (uint256);

  /**
   * @dev Getter of a proposal by id
   * @param proposalId id of the proposal to get
   * @return the proposal as ProposalWithoutVotes memory object
   **/
  function getProposalById(uint256 proposalId)
    external
    view
    returns (ProposalWithoutVotes memory);

  /**
   * @dev Getter of the Vote of a voter about a proposal
   * Note: Vote is a struct: ({bool support, uint248 votingPower})
   * @param proposalId id of the proposal
   * @param voter address of the voter
   * @return The associated Vote memory object
   **/
  function getVoteOnProposal(uint256 proposalId, address voter)
    external
    view
    returns (Vote memory);

  /**
   * @dev Get the current state of a proposal
   * @param proposalId id of the proposal
   * @return The current state if the proposal
   **/
  function getProposalState(uint256 proposalId)
    external
    view
    returns (ProposalState);
}

library AaveGovernanceV2 {
  IAaveGovernanceV2 internal constant GOV =
    IAaveGovernanceV2(0xEC568fffba86c094cf06b22134B23074DFE2252c);

  address public constant SHORT_EXECUTOR =
    0xEE56e2B3D491590B5b31738cC34d5232F378a8D5;

  address public constant LONG_EXECUTOR =
    0x79426A1c24B2978D90d7A5070a46C65B07bC4299;

  address public constant ARC_TIMELOCK =
    0xAce1d11d836cb3F51Ef658FD4D353fFb3c301218;

  // https://github.com/aave/governance-crosschain-bridges
  address internal constant POLYGON_BRIDGE_EXECUTOR =
    0xdc9A35B16DB4e126cFeDC41322b3a36454B1F772;

  address internal constant OPTIMISM_BRIDGE_EXECUTOR =
    0x7d9103572bE58FfE99dc390E8246f02dcAe6f611;

  address internal constant ARBITRUM_BRIDGE_EXECUTOR =
    0x7d9103572bE58FfE99dc390E8246f02dcAe6f611;

  // https://github.com/bgd-labs/aave-v3-crosschain-listing-template/tree/master/src/contracts
  address internal constant CROSSCHAIN_FORWARDER_POLYGON =
    0x158a6bC04F0828318821baE797f50B0A1299d45b;

  address internal constant CROSSCHAIN_FORWARDER_OPTIMISM =
    0x5f5C02875a8e9B5A26fbd09040ABCfDeb2AA6711;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

library DataTypes {
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    //timestamp of last update
    uint40 lastUpdateTimestamp;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint16 id;
    //aToken address
    address aTokenAddress;
    //stableDebtToken address
    address stableDebtTokenAddress;
    //variableDebtToken address
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the current treasury balance, scaled
    uint128 accruedToTreasury;
    //the outstanding unbacked aTokens minted through the bridging feature
    uint128 unbacked;
    //the outstanding debt borrowed against this asset in isolation mode
    uint128 isolationModeTotalDebt;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60: asset is paused
    //bit 61: borrowing in isolation mode is enabled
    //bit 62-63: reserved
    //bit 64-79: reserve factor
    //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
    //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
    //bit 152-167 liquidation protocol fee
    //bit 168-175 eMode category
    //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
    //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
    //bit 252-255 unused

    uint256 data;
  }

  struct UserConfigurationMap {
    /**
     * @dev Bitmap of the users collaterals and borrows. It is divided in pairs of bits, one pair per asset.
     * The first bit indicates if an asset is used as collateral by the user, the second whether an
     * asset is borrowed by the user.
     */
    uint256 data;
  }

  struct EModeCategory {
    // each eMode category has a custom ltv and liquidation threshold
    uint16 ltv;
    uint16 liquidationThreshold;
    uint16 liquidationBonus;
    // each eMode category may or may not have a custom oracle to override the individual assets price oracles
    address priceSource;
    string label;
  }

  enum InterestRateMode {
    NONE,
    STABLE,
    VARIABLE
  }

  struct ReserveCache {
    uint256 currScaledVariableDebt;
    uint256 nextScaledVariableDebt;
    uint256 currPrincipalStableDebt;
    uint256 currAvgStableBorrowRate;
    uint256 currTotalStableDebt;
    uint256 nextAvgStableBorrowRate;
    uint256 nextTotalStableDebt;
    uint256 currLiquidityIndex;
    uint256 nextLiquidityIndex;
    uint256 currVariableBorrowIndex;
    uint256 nextVariableBorrowIndex;
    uint256 currLiquidityRate;
    uint256 currVariableBorrowRate;
    uint256 reserveFactor;
    ReserveConfigurationMap reserveConfiguration;
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    uint40 reserveLastUpdateTimestamp;
    uint40 stableDebtLastUpdateTimestamp;
  }

  struct ExecuteLiquidationCallParams {
    uint256 reservesCount;
    uint256 debtToCover;
    address collateralAsset;
    address debtAsset;
    address user;
    bool receiveAToken;
    address priceOracle;
    uint8 userEModeCategory;
    address priceOracleSentinel;
  }

  struct ExecuteSupplyParams {
    address asset;
    uint256 amount;
    address onBehalfOf;
    uint16 referralCode;
  }

  struct ExecuteBorrowParams {
    address asset;
    address user;
    address onBehalfOf;
    uint256 amount;
    InterestRateMode interestRateMode;
    uint16 referralCode;
    bool releaseUnderlying;
    uint256 maxStableRateBorrowSizePercent;
    uint256 reservesCount;
    address oracle;
    uint8 userEModeCategory;
    address priceOracleSentinel;
  }

  struct ExecuteRepayParams {
    address asset;
    uint256 amount;
    InterestRateMode interestRateMode;
    address onBehalfOf;
    bool useATokens;
  }

  struct ExecuteWithdrawParams {
    address asset;
    uint256 amount;
    address to;
    uint256 reservesCount;
    address oracle;
    uint8 userEModeCategory;
  }

  struct ExecuteSetUserEModeParams {
    uint256 reservesCount;
    address oracle;
    uint8 categoryId;
  }

  struct FinalizeTransferParams {
    address asset;
    address from;
    address to;
    uint256 amount;
    uint256 balanceFromBefore;
    uint256 balanceToBefore;
    uint256 reservesCount;
    address oracle;
    uint8 fromEModeCategory;
  }

  struct FlashloanParams {
    address receiverAddress;
    address[] assets;
    uint256[] amounts;
    uint256[] interestRateModes;
    address onBehalfOf;
    bytes params;
    uint16 referralCode;
    uint256 flashLoanPremiumToProtocol;
    uint256 flashLoanPremiumTotal;
    uint256 maxStableRateBorrowSizePercent;
    uint256 reservesCount;
    address addressesProvider;
    uint8 userEModeCategory;
    bool isAuthorizedFlashBorrower;
  }

  struct FlashloanSimpleParams {
    address receiverAddress;
    address asset;
    uint256 amount;
    bytes params;
    uint16 referralCode;
    uint256 flashLoanPremiumToProtocol;
    uint256 flashLoanPremiumTotal;
  }

  struct FlashLoanRepaymentParams {
    uint256 amount;
    uint256 totalPremium;
    uint256 flashLoanPremiumToProtocol;
    address asset;
    address receiverAddress;
    uint16 referralCode;
  }

  struct CalculateUserAccountDataParams {
    UserConfigurationMap userConfig;
    uint256 reservesCount;
    address user;
    address oracle;
    uint8 userEModeCategory;
  }

  struct ValidateBorrowParams {
    ReserveCache reserveCache;
    UserConfigurationMap userConfig;
    address asset;
    address userAddress;
    uint256 amount;
    InterestRateMode interestRateMode;
    uint256 maxStableLoanPercent;
    uint256 reservesCount;
    address oracle;
    uint8 userEModeCategory;
    address priceOracleSentinel;
    bool isolationModeActive;
    address isolationModeCollateralAddress;
    uint256 isolationModeDebtCeiling;
  }

  struct ValidateLiquidationCallParams {
    ReserveCache debtReserveCache;
    uint256 totalDebt;
    uint256 healthFactor;
    address priceOracleSentinel;
  }

  struct CalculateInterestRatesParams {
    uint256 unbacked;
    uint256 liquidityAdded;
    uint256 liquidityTaken;
    uint256 totalStableDebt;
    uint256 totalVariableDebt;
    uint256 averageStableBorrowRate;
    uint256 reserveFactor;
    address reserve;
    address aToken;
  }

  struct InitReserveParams {
    address asset;
    address aTokenAddress;
    address stableDebtAddress;
    address variableDebtAddress;
    address interestRateStrategyAddress;
    uint16 reservesCount;
    uint16 maxNumberReserves;
  }
}

library ConfiguratorInputTypes {
  struct InitReserveInput {
    address aTokenImpl;
    address stableDebtTokenImpl;
    address variableDebtTokenImpl;
    uint8 underlyingAssetDecimals;
    address interestRateStrategyAddress;
    address underlyingAsset;
    address treasury;
    address incentivesController;
    string aTokenName;
    string aTokenSymbol;
    string variableDebtTokenName;
    string variableDebtTokenSymbol;
    string stableDebtTokenName;
    string stableDebtTokenSymbol;
    bytes params;
  }

  struct UpdateATokenInput {
    address asset;
    address treasury;
    address incentivesController;
    string name;
    string symbol;
    address implementation;
    bytes params;
  }

  struct UpdateDebtTokenInput {
    address asset;
    address incentivesController;
    string name;
    string symbol;
    address implementation;
    bytes params;
  }
}

interface IPoolAddressesProvider {
  /**
   * @dev Emitted when the market identifier is updated.
   * @param oldMarketId The old id of the market
   * @param newMarketId The new id of the market
   */
  event MarketIdSet(string indexed oldMarketId, string indexed newMarketId);

  /**
   * @dev Emitted when the pool is updated.
   * @param oldAddress The old address of the Pool
   * @param newAddress The new address of the Pool
   */
  event PoolUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the pool configurator is updated.
   * @param oldAddress The old address of the PoolConfigurator
   * @param newAddress The new address of the PoolConfigurator
   */
  event PoolConfiguratorUpdated(
    address indexed oldAddress,
    address indexed newAddress
  );

  /**
   * @dev Emitted when the price oracle is updated.
   * @param oldAddress The old address of the PriceOracle
   * @param newAddress The new address of the PriceOracle
   */
  event PriceOracleUpdated(
    address indexed oldAddress,
    address indexed newAddress
  );

  /**
   * @dev Emitted when the ACL manager is updated.
   * @param oldAddress The old address of the ACLManager
   * @param newAddress The new address of the ACLManager
   */
  event ACLManagerUpdated(
    address indexed oldAddress,
    address indexed newAddress
  );

  /**
   * @dev Emitted when the ACL admin is updated.
   * @param oldAddress The old address of the ACLAdmin
   * @param newAddress The new address of the ACLAdmin
   */
  event ACLAdminUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the price oracle sentinel is updated.
   * @param oldAddress The old address of the PriceOracleSentinel
   * @param newAddress The new address of the PriceOracleSentinel
   */
  event PriceOracleSentinelUpdated(
    address indexed oldAddress,
    address indexed newAddress
  );

  /**
   * @dev Emitted when the pool data provider is updated.
   * @param oldAddress The old address of the PoolDataProvider
   * @param newAddress The new address of the PoolDataProvider
   */
  event PoolDataProviderUpdated(
    address indexed oldAddress,
    address indexed newAddress
  );

  /**
   * @dev Emitted when a new proxy is created.
   * @param id The identifier of the proxy
   * @param proxyAddress The address of the created proxy contract
   * @param implementationAddress The address of the implementation contract
   */
  event ProxyCreated(
    bytes32 indexed id,
    address indexed proxyAddress,
    address indexed implementationAddress
  );

  /**
   * @dev Emitted when a new non-proxied contract address is registered.
   * @param id The identifier of the contract
   * @param oldAddress The address of the old contract
   * @param newAddress The address of the new contract
   */
  event AddressSet(
    bytes32 indexed id,
    address indexed oldAddress,
    address indexed newAddress
  );

  /**
   * @dev Emitted when the implementation of the proxy registered with id is updated
   * @param id The identifier of the contract
   * @param proxyAddress The address of the proxy contract
   * @param oldImplementationAddress The address of the old implementation contract
   * @param newImplementationAddress The address of the new implementation contract
   */
  event AddressSetAsProxy(
    bytes32 indexed id,
    address indexed proxyAddress,
    address oldImplementationAddress,
    address indexed newImplementationAddress
  );

  /**
   * @notice Returns the id of the Aave market to which this contract points to.
   * @return The market id
   **/
  function getMarketId() external view returns (string memory);

  /**
   * @notice Associates an id with a specific PoolAddressesProvider.
   * @dev This can be used to create an onchain registry of PoolAddressesProviders to
   * identify and validate multiple Aave markets.
   * @param newMarketId The market id
   */
  function setMarketId(string calldata newMarketId) external;

  /**
   * @notice Returns an address by its identifier.
   * @dev The returned address might be an EOA or a contract, potentially proxied
   * @dev It returns ZERO if there is no registered address with the given id
   * @param id The id
   * @return The address of the registered for the specified id
   */
  function getAddress(bytes32 id) external view returns (address);

  /**
   * @notice General function to update the implementation of a proxy registered with
   * certain `id`. If there is no proxy registered, it will instantiate one and
   * set as implementation the `newImplementationAddress`.
   * @dev IMPORTANT Use this function carefully, only for ids that don't have an explicit
   * setter function, in order to avoid unexpected consequences
   * @param id The id
   * @param newImplementationAddress The address of the new implementation
   */
  function setAddressAsProxy(bytes32 id, address newImplementationAddress)
    external;

  /**
   * @notice Sets an address for an id replacing the address saved in the addresses map.
   * @dev IMPORTANT Use this function carefully, as it will do a hard replacement
   * @param id The id
   * @param newAddress The address to set
   */
  function setAddress(bytes32 id, address newAddress) external;

  /**
   * @notice Returns the address of the Pool proxy.
   * @return The Pool proxy address
   **/
  function getPool() external view returns (address);

  /**
   * @notice Updates the implementation of the Pool, or creates a proxy
   * setting the new `pool` implementation when the function is called for the first time.
   * @param newPoolImpl The new Pool implementation
   **/
  function setPoolImpl(address newPoolImpl) external;

  /**
   * @notice Returns the address of the PoolConfigurator proxy.
   * @return The PoolConfigurator proxy address
   **/
  function getPoolConfigurator() external view returns (address);

  /**
   * @notice Updates the implementation of the PoolConfigurator, or creates a proxy
   * setting the new `PoolConfigurator` implementation when the function is called for the first time.
   * @param newPoolConfiguratorImpl The new PoolConfigurator implementation
   **/
  function setPoolConfiguratorImpl(address newPoolConfiguratorImpl) external;

  /**
   * @notice Returns the address of the price oracle.
   * @return The address of the PriceOracle
   */
  function getPriceOracle() external view returns (address);

  /**
   * @notice Updates the address of the price oracle.
   * @param newPriceOracle The address of the new PriceOracle
   */
  function setPriceOracle(address newPriceOracle) external;

  /**
   * @notice Returns the address of the ACL manager.
   * @return The address of the ACLManager
   */
  function getACLManager() external view returns (address);

  /**
   * @notice Updates the address of the ACL manager.
   * @param newAclManager The address of the new ACLManager
   **/
  function setACLManager(address newAclManager) external;

  /**
   * @notice Returns the address of the ACL admin.
   * @return The address of the ACL admin
   */
  function getACLAdmin() external view returns (address);

  /**
   * @notice Updates the address of the ACL admin.
   * @param newAclAdmin The address of the new ACL admin
   */
  function setACLAdmin(address newAclAdmin) external;

  /**
   * @notice Returns the address of the price oracle sentinel.
   * @return The address of the PriceOracleSentinel
   */
  function getPriceOracleSentinel() external view returns (address);

  /**
   * @notice Updates the address of the price oracle sentinel.
   * @param newPriceOracleSentinel The address of the new PriceOracleSentinel
   **/
  function setPriceOracleSentinel(address newPriceOracleSentinel) external;

  /**
   * @notice Returns the address of the data provider.
   * @return The address of the DataProvider
   */
  function getPoolDataProvider() external view returns (address);

  /**
   * @notice Updates the address of the data provider.
   * @param newDataProvider The address of the new DataProvider
   **/
  function setPoolDataProvider(address newDataProvider) external;
}

interface IPool {
  /**
   * @dev Emitted on mintUnbacked()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the supply
   * @param onBehalfOf The beneficiary of the supplied assets, receiving the aTokens
   * @param amount The amount of supplied assets
   * @param referralCode The referral code used
   **/
  event MintUnbacked(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referralCode
  );

  /**
   * @dev Emitted on backUnbacked()
   * @param reserve The address of the underlying asset of the reserve
   * @param backer The address paying for the backing
   * @param amount The amount added as backing
   * @param fee The amount paid in fees
   **/
  event BackUnbacked(
    address indexed reserve,
    address indexed backer,
    uint256 amount,
    uint256 fee
  );

  /**
   * @dev Emitted on supply()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the supply
   * @param onBehalfOf The beneficiary of the supply, receiving the aTokens
   * @param amount The amount supplied
   * @param referralCode The referral code used
   **/
  event Supply(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referralCode
  );

  /**
   * @dev Emitted on withdraw()
   * @param reserve The address of the underlying asset being withdrawn
   * @param user The address initiating the withdrawal, owner of aTokens
   * @param to The address that will receive the underlying
   * @param amount The amount to be withdrawn
   **/
  event Withdraw(
    address indexed reserve,
    address indexed user,
    address indexed to,
    uint256 amount
  );

  /**
   * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
   * @param reserve The address of the underlying asset being borrowed
   * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
   * initiator of the transaction on flashLoan()
   * @param onBehalfOf The address that will be getting the debt
   * @param amount The amount borrowed out
   * @param interestRateMode The rate mode: 1 for Stable, 2 for Variable
   * @param borrowRate The numeric rate at which the user has borrowed, expressed in ray
   * @param referralCode The referral code used
   **/
  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    DataTypes.InterestRateMode interestRateMode,
    uint256 borrowRate,
    uint16 indexed referralCode
  );

  /**
   * @dev Emitted on repay()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The beneficiary of the repayment, getting his debt reduced
   * @param repayer The address of the user initiating the repay(), providing the funds
   * @param amount The amount repaid
   * @param useATokens True if the repayment is done using aTokens, `false` if done with underlying asset directly
   **/
  event Repay(
    address indexed reserve,
    address indexed user,
    address indexed repayer,
    uint256 amount,
    bool useATokens
  );

  /**
   * @dev Emitted on swapBorrowRateMode()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user swapping his rate mode
   * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
   **/
  event SwapBorrowRateMode(
    address indexed reserve,
    address indexed user,
    DataTypes.InterestRateMode interestRateMode
  );

  /**
   * @dev Emitted on borrow(), repay() and liquidationCall() when using isolated assets
   * @param asset The address of the underlying asset of the reserve
   * @param totalDebt The total isolation mode debt for the reserve
   */
  event IsolationModeTotalDebtUpdated(address indexed asset, uint256 totalDebt);

  /**
   * @dev Emitted when the user selects a certain asset category for eMode
   * @param user The address of the user
   * @param categoryId The category id
   **/
  event UserEModeSet(address indexed user, uint8 categoryId);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralEnabled(
    address indexed reserve,
    address indexed user
  );

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralDisabled(
    address indexed reserve,
    address indexed user
  );

  /**
   * @dev Emitted on rebalanceStableBorrowRate()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user for which the rebalance has been executed
   **/
  event RebalanceStableBorrowRate(
    address indexed reserve,
    address indexed user
  );

  /**
   * @dev Emitted on flashLoan()
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param asset The address of the asset being flash borrowed
   * @param amount The amount flash borrowed
   * @param interestRateMode The flashloan mode: 0 for regular flashloan, 1 for Stable debt, 2 for Variable debt
   * @param premium The fee flash borrowed
   * @param referralCode The referral code used
   **/
  event FlashLoan(
    address indexed target,
    address initiator,
    address indexed asset,
    uint256 amount,
    DataTypes.InterestRateMode interestRateMode,
    uint256 premium,
    uint16 indexed referralCode
  );

  /**
   * @dev Emitted when a borrower is liquidated.
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param liquidatedCollateralAmount The amount of collateral received by the liquidator
   * @param liquidator The address of the liquidator
   * @param receiveAToken True if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    address indexed user,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receiveAToken
  );

  /**
   * @dev Emitted when the state of a reserve is updated.
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The next liquidity rate
   * @param stableBorrowRate The next stable borrow rate
   * @param variableBorrowRate The next variable borrow rate
   * @param liquidityIndex The next liquidity index
   * @param variableBorrowIndex The next variable borrow index
   **/
  event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 stableBorrowRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  /**
   * @dev Emitted when the protocol treasury receives minted aTokens from the accrued interest.
   * @param reserve The address of the reserve
   * @param amountMinted The amount minted to the treasury
   **/
  event MintedToTreasury(address indexed reserve, uint256 amountMinted);

  /**
   * @dev Mints an `amount` of aTokens to the `onBehalfOf`
   * @param asset The address of the underlying asset to mint
   * @param amount The amount to mint
   * @param onBehalfOf The address that will receive the aTokens
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function mintUnbacked(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Back the current unbacked underlying with `amount` and pay `fee`.
   * @param asset The address of the underlying asset to back
   * @param amount The amount to back
   * @param fee The amount paid in fees
   **/
  function backUnbacked(
    address asset,
    uint256 amount,
    uint256 fee
  ) external;

  /**
   * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function supply(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @notice Supply with transfer approval of asset to be supplied done via permit function
   * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param deadline The deadline timestamp that the permit is valid
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param permitV The V parameter of ERC712 permit sig
   * @param permitR The R parameter of ERC712 permit sig
   * @param permitS The S parameter of ERC712 permit sig
   **/
  function supplyWithPermit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode,
    uint256 deadline,
    uint8 permitV,
    bytes32 permitR,
    bytes32 permitS
  ) external;

  /**
   * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to The address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @notice Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already supplied enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf The address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   **/
  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf The address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @return The final amount repaid
   **/
  function repay(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    address onBehalfOf
  ) external returns (uint256);

  /**
   * @notice Repay with transfer approval of asset to be repaid done via permit function
   * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @param deadline The deadline timestamp that the permit is valid
   * @param permitV The V parameter of ERC712 permit sig
   * @param permitR The R parameter of ERC712 permit sig
   * @param permitS The S parameter of ERC712 permit sig
   * @return The final amount repaid
   **/
  function repayWithPermit(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    address onBehalfOf,
    uint256 deadline,
    uint8 permitV,
    bytes32 permitR,
    bytes32 permitS
  ) external returns (uint256);

  /**
   * @notice Repays a borrowed `amount` on a specific reserve using the reserve aTokens, burning the
   * equivalent debt tokens
   * - E.g. User repays 100 USDC using 100 aUSDC, burning 100 variable/stable debt tokens
   * @dev  Passing uint256.max as amount will clean up any residual aToken dust balance, if the user aToken
   * balance is not enough to cover the whole debt
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @return The final amount repaid
   **/
  function repayWithATokens(
    address asset,
    uint256 amount,
    uint256 interestRateMode
  ) external returns (uint256);

  /**
   * @notice Allows a borrower to swap his debt between stable and variable mode, or vice versa
   * @param asset The address of the underlying asset borrowed
   * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
   **/
  function swapBorrowRateMode(address asset, uint256 interestRateMode) external;

  /**
   * @notice Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
   * - Users can be rebalanced if the following conditions are satisfied:
   *     1. Usage ratio is above 95%
   *     2. the current supply APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too
   *        much has been borrowed at a stable rate and suppliers are not earning enough
   * @param asset The address of the underlying asset borrowed
   * @param user The address of the user to be rebalanced
   **/
  function rebalanceStableBorrowRate(address asset, address user) external;

  /**
   * @notice Allows suppliers to enable/disable a specific supplied asset as collateral
   * @param asset The address of the underlying asset supplied
   * @param useAsCollateral True if the user wants to use the supply as collateral, false otherwise
   **/
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral)
    external;

  /**
   * @notice Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receiveAToken True if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) external;

  /**
   * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
   * into consideration. For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanReceiver interface
   * @param assets The addresses of the assets being flash-borrowed
   * @param amounts The amounts of the assets being flash-borrowed
   * @param interestRateModes Types of the debt to open if the flash loan is not returned:
   *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
   *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata interestRateModes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
   * into consideration. For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanSimpleReceiver interface
   * @param asset The address of the asset being flash-borrowed
   * @param amount The amount of the asset being flash-borrowed
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function flashLoanSimple(
    address receiverAddress,
    address asset,
    uint256 amount,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @notice Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateralBase The total collateral of the user in the base currency used by the price feed
   * @return totalDebtBase The total debt of the user in the base currency used by the price feed
   * @return availableBorrowsBase The borrowing power left of the user in the base currency used by the price feed
   * @return currentLiquidationThreshold The liquidation threshold of the user
   * @return ltv The loan to value of The user
   * @return healthFactor The current health factor of the user
   **/
  function getUserAccountData(address user)
    external
    view
    returns (
      uint256 totalCollateralBase,
      uint256 totalDebtBase,
      uint256 availableBorrowsBase,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );

  /**
   * @notice Initializes a reserve, activating it, assigning an aToken and debt tokens and an
   * interest rate strategy
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param aTokenAddress The address of the aToken that will be assigned to the reserve
   * @param stableDebtAddress The address of the StableDebtToken that will be assigned to the reserve
   * @param variableDebtAddress The address of the VariableDebtToken that will be assigned to the reserve
   * @param interestRateStrategyAddress The address of the interest rate strategy contract
   **/
  function initReserve(
    address asset,
    address aTokenAddress,
    address stableDebtAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external;

  /**
   * @notice Drop a reserve
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   **/
  function dropReserve(address asset) external;

  /**
   * @notice Updates the address of the interest rate strategy contract
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param rateStrategyAddress The address of the interest rate strategy contract
   **/
  function setReserveInterestRateStrategyAddress(
    address asset,
    address rateStrategyAddress
  ) external;

  /**
   * @notice Sets the configuration bitmap of the reserve as a whole
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param configuration The new configuration bitmap
   **/
  function setConfiguration(
    address asset,
    DataTypes.ReserveConfigurationMap calldata configuration
  ) external;

  /**
   * @notice Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getConfiguration(address asset)
    external
    view
    returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @notice Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   **/
  function getUserConfiguration(address user)
    external
    view
    returns (DataTypes.UserConfigurationMap memory);

  /**
   * @notice Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset)
    external
    view
    returns (uint256);

  /**
   * @notice Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset)
    external
    view
    returns (uint256);

  /**
   * @notice Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state and configuration data of the reserve
   **/
  function getReserveData(address asset)
    external
    view
    returns (DataTypes.ReserveData memory);

  /**
   * @notice Validates and finalizes an aToken transfer
   * @dev Only callable by the overlying aToken of the `asset`
   * @param asset The address of the underlying asset of the aToken
   * @param from The user from which the aTokens are transferred
   * @param to The user receiving the aTokens
   * @param amount The amount being transferred/withdrawn
   * @param balanceFromBefore The aToken balance of the `from` user before the transfer
   * @param balanceToBefore The aToken balance of the `to` user before the transfer
   */
  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromBefore,
    uint256 balanceToBefore
  ) external;

  /**
   * @notice Returns the list of the underlying assets of all the initialized reserves
   * @dev It does not include dropped reserves
   * @return The addresses of the underlying assets of the initialized reserves
   **/
  function getReservesList() external view returns (address[] memory);

  /**
   * @notice Returns the address of the underlying asset of a reserve by the reserve id as stored in the DataTypes.ReserveData struct
   * @param id The id of the reserve as stored in the DataTypes.ReserveData struct
   * @return The address of the reserve associated with id
   **/
  function getReserveAddressById(uint16 id) external view returns (address);

  /**
   * @notice Returns the PoolAddressesProvider connected to this contract
   * @return The address of the PoolAddressesProvider
   **/
  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  /**
   * @notice Updates the protocol fee on the bridging
   * @param bridgeProtocolFee The part of the premium sent to the protocol treasury
   */
  function updateBridgeProtocolFee(uint256 bridgeProtocolFee) external;

  /**
   * @notice Updates flash loan premiums. Flash loan premium consists of two parts:
   * - A part is sent to aToken holders as extra, one time accumulated interest
   * - A part is collected by the protocol treasury
   * @dev The total premium is calculated on the total borrowed amount
   * @dev The premium to protocol is calculated on the total premium, being a percentage of `flashLoanPremiumTotal`
   * @dev Only callable by the PoolConfigurator contract
   * @param flashLoanPremiumTotal The total premium, expressed in bps
   * @param flashLoanPremiumToProtocol The part of the premium sent to the protocol treasury, expressed in bps
   */
  function updateFlashloanPremiums(
    uint128 flashLoanPremiumTotal,
    uint128 flashLoanPremiumToProtocol
  ) external;

  /**
   * @notice Configures a new category for the eMode.
   * @dev In eMode, the protocol allows very high borrowing power to borrow assets of the same category.
   * The category 0 is reserved as it's the default for volatile assets
   * @param id The id of the category
   * @param config The configuration of the category
   */
  function configureEModeCategory(
    uint8 id,
    DataTypes.EModeCategory memory config
  ) external;

  /**
   * @notice Returns the data of an eMode category
   * @param id The id of the category
   * @return The configuration data of the category
   */
  function getEModeCategoryData(uint8 id)
    external
    view
    returns (DataTypes.EModeCategory memory);

  /**
   * @notice Allows a user to use the protocol in eMode
   * @param categoryId The id of the category
   */
  function setUserEMode(uint8 categoryId) external;

  /**
   * @notice Returns the eMode the user is using
   * @param user The address of the user
   * @return The eMode id
   */
  function getUserEMode(address user) external view returns (uint256);

  /**
   * @notice Resets the isolation mode total debt of the given asset to zero
   * @dev It requires the given asset has zero debt ceiling
   * @param asset The address of the underlying asset to reset the isolationModeTotalDebt
   */
  function resetIsolationModeTotalDebt(address asset) external;

  /**
   * @notice Returns the percentage of available liquidity that can be borrowed at once at stable rate
   * @return The percentage of available liquidity to borrow, expressed in bps
   */
  function MAX_STABLE_RATE_BORROW_SIZE_PERCENT()
    external
    view
    returns (uint256);

  /**
   * @notice Returns the total fee on flash loans
   * @return The total fee on flashloans
   */
  function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint128);

  /**
   * @notice Returns the part of the bridge fees sent to protocol
   * @return The bridge fee sent to the protocol treasury
   */
  function BRIDGE_PROTOCOL_FEE() external view returns (uint256);

  /**
   * @notice Returns the part of the flashloan fees sent to protocol
   * @return The flashloan fee sent to the protocol treasury
   */
  function FLASHLOAN_PREMIUM_TO_PROTOCOL() external view returns (uint128);

  /**
   * @notice Returns the maximum number of reserves supported to be listed in this Pool
   * @return The maximum number of reserves supported
   */
  function MAX_NUMBER_RESERVES() external view returns (uint16);

  /**
   * @notice Mints the assets accrued through the reserve factor to the treasury in the form of aTokens
   * @param assets The list of reserves for which the minting needs to be executed
   **/
  function mintToTreasury(address[] calldata assets) external;

  /**
   * @notice Rescue and transfer tokens locked in this contract
   * @param token The address of the token
   * @param to The address of the recipient
   * @param amount The amount of token to transfer
   */
  function rescueTokens(
    address token,
    address to,
    uint256 amount
  ) external;

  /**
   * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
   * @dev Deprecated: Use the `supply` function instead
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;
}

interface IPoolConfigurator {
  /**
   * @dev Emitted when a reserve is initialized.
   * @param asset The address of the underlying asset of the reserve
   * @param aToken The address of the associated aToken contract
   * @param stableDebtToken The address of the associated stable rate debt token
   * @param variableDebtToken The address of the associated variable rate debt token
   * @param interestRateStrategyAddress The address of the interest rate strategy for the reserve
   **/
  event ReserveInitialized(
    address indexed asset,
    address indexed aToken,
    address stableDebtToken,
    address variableDebtToken,
    address interestRateStrategyAddress
  );

  /**
   * @dev Emitted when borrowing is enabled or disabled on a reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param enabled True if borrowing is enabled, false otherwise
   **/
  event ReserveBorrowing(address indexed asset, bool enabled);

  /**
   * @dev Emitted when the collateralization risk parameters for the specified asset are updated.
   * @param asset The address of the underlying asset of the reserve
   * @param ltv The loan to value of the asset when used as collateral
   * @param liquidationThreshold The threshold at which loans using this asset as collateral will be considered undercollateralized
   * @param liquidationBonus The bonus liquidators receive to liquidate this asset
   **/
  event CollateralConfigurationChanged(
    address indexed asset,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus
  );

  /**
   * @dev Emitted when stable rate borrowing is enabled or disabled on a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param enabled True if stable rate borrowing is enabled, false otherwise
   **/
  event ReserveStableRateBorrowing(address indexed asset, bool enabled);

  /**
   * @dev Emitted when a reserve is activated or deactivated
   * @param asset The address of the underlying asset of the reserve
   * @param active True if reserve is active, false otherwise
   **/
  event ReserveActive(address indexed asset, bool active);

  /**
   * @dev Emitted when a reserve is frozen or unfrozen
   * @param asset The address of the underlying asset of the reserve
   * @param frozen True if reserve is frozen, false otherwise
   **/
  event ReserveFrozen(address indexed asset, bool frozen);

  /**
   * @dev Emitted when a reserve is paused or unpaused
   * @param asset The address of the underlying asset of the reserve
   * @param paused True if reserve is paused, false otherwise
   **/
  event ReservePaused(address indexed asset, bool paused);

  /**
   * @dev Emitted when a reserve is dropped.
   * @param asset The address of the underlying asset of the reserve
   **/
  event ReserveDropped(address indexed asset);

  /**
   * @dev Emitted when a reserve factor is updated.
   * @param asset The address of the underlying asset of the reserve
   * @param oldReserveFactor The old reserve factor, expressed in bps
   * @param newReserveFactor The new reserve factor, expressed in bps
   **/
  event ReserveFactorChanged(
    address indexed asset,
    uint256 oldReserveFactor,
    uint256 newReserveFactor
  );

  /**
   * @dev Emitted when the borrow cap of a reserve is updated.
   * @param asset The address of the underlying asset of the reserve
   * @param oldBorrowCap The old borrow cap
   * @param newBorrowCap The new borrow cap
   **/
  event BorrowCapChanged(
    address indexed asset,
    uint256 oldBorrowCap,
    uint256 newBorrowCap
  );

  /**
   * @dev Emitted when the supply cap of a reserve is updated.
   * @param asset The address of the underlying asset of the reserve
   * @param oldSupplyCap The old supply cap
   * @param newSupplyCap The new supply cap
   **/
  event SupplyCapChanged(
    address indexed asset,
    uint256 oldSupplyCap,
    uint256 newSupplyCap
  );

  /**
   * @dev Emitted when the liquidation protocol fee of a reserve is updated.
   * @param asset The address of the underlying asset of the reserve
   * @param oldFee The old liquidation protocol fee, expressed in bps
   * @param newFee The new liquidation protocol fee, expressed in bps
   **/
  event LiquidationProtocolFeeChanged(
    address indexed asset,
    uint256 oldFee,
    uint256 newFee
  );

  /**
   * @dev Emitted when the unbacked mint cap of a reserve is updated.
   * @param asset The address of the underlying asset of the reserve
   * @param oldUnbackedMintCap The old unbacked mint cap
   * @param newUnbackedMintCap The new unbacked mint cap
   */
  event UnbackedMintCapChanged(
    address indexed asset,
    uint256 oldUnbackedMintCap,
    uint256 newUnbackedMintCap
  );

  /**
   * @dev Emitted when the category of an asset in eMode is changed.
   * @param asset The address of the underlying asset of the reserve
   * @param oldCategoryId The old eMode asset category
   * @param newCategoryId The new eMode asset category
   **/
  event EModeAssetCategoryChanged(
    address indexed asset,
    uint8 oldCategoryId,
    uint8 newCategoryId
  );

  /**
   * @dev Emitted when a new eMode category is added.
   * @param categoryId The new eMode category id
   * @param ltv The ltv for the asset category in eMode
   * @param liquidationThreshold The liquidationThreshold for the asset category in eMode
   * @param liquidationBonus The liquidationBonus for the asset category in eMode
   * @param oracle The optional address of the price oracle specific for this category
   * @param label A human readable identifier for the category
   **/
  event EModeCategoryAdded(
    uint8 indexed categoryId,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus,
    address oracle,
    string label
  );

  /**
   * @dev Emitted when a reserve interest strategy contract is updated.
   * @param asset The address of the underlying asset of the reserve
   * @param oldStrategy The address of the old interest strategy contract
   * @param newStrategy The address of the new interest strategy contract
   **/
  event ReserveInterestRateStrategyChanged(
    address indexed asset,
    address oldStrategy,
    address newStrategy
  );

  /**
   * @dev Emitted when an aToken implementation is upgraded.
   * @param asset The address of the underlying asset of the reserve
   * @param proxy The aToken proxy address
   * @param implementation The new aToken implementation
   **/
  event ATokenUpgraded(
    address indexed asset,
    address indexed proxy,
    address indexed implementation
  );

  /**
   * @dev Emitted when the implementation of a stable debt token is upgraded.
   * @param asset The address of the underlying asset of the reserve
   * @param proxy The stable debt token proxy address
   * @param implementation The new aToken implementation
   **/
  event StableDebtTokenUpgraded(
    address indexed asset,
    address indexed proxy,
    address indexed implementation
  );

  /**
   * @dev Emitted when the implementation of a variable debt token is upgraded.
   * @param asset The address of the underlying asset of the reserve
   * @param proxy The variable debt token proxy address
   * @param implementation The new aToken implementation
   **/
  event VariableDebtTokenUpgraded(
    address indexed asset,
    address indexed proxy,
    address indexed implementation
  );

  /**
   * @dev Emitted when the debt ceiling of an asset is set.
   * @param asset The address of the underlying asset of the reserve
   * @param oldDebtCeiling The old debt ceiling
   * @param newDebtCeiling The new debt ceiling
   **/
  event DebtCeilingChanged(
    address indexed asset,
    uint256 oldDebtCeiling,
    uint256 newDebtCeiling
  );

  /**
   * @dev Emitted when the the siloed borrowing state for an asset is changed.
   * @param asset The address of the underlying asset of the reserve
   * @param oldState The old siloed borrowing state
   * @param newState The new siloed borrowing state
   **/
  event SiloedBorrowingChanged(
    address indexed asset,
    bool oldState,
    bool newState
  );

  /**
   * @dev Emitted when the bridge protocol fee is updated.
   * @param oldBridgeProtocolFee The old protocol fee, expressed in bps
   * @param newBridgeProtocolFee The new protocol fee, expressed in bps
   */
  event BridgeProtocolFeeUpdated(
    uint256 oldBridgeProtocolFee,
    uint256 newBridgeProtocolFee
  );

  /**
   * @dev Emitted when the total premium on flashloans is updated.
   * @param oldFlashloanPremiumTotal The old premium, expressed in bps
   * @param newFlashloanPremiumTotal The new premium, expressed in bps
   **/
  event FlashloanPremiumTotalUpdated(
    uint128 oldFlashloanPremiumTotal,
    uint128 newFlashloanPremiumTotal
  );

  /**
   * @dev Emitted when the part of the premium that goes to protocol is updated.
   * @param oldFlashloanPremiumToProtocol The old premium, expressed in bps
   * @param newFlashloanPremiumToProtocol The new premium, expressed in bps
   **/
  event FlashloanPremiumToProtocolUpdated(
    uint128 oldFlashloanPremiumToProtocol,
    uint128 newFlashloanPremiumToProtocol
  );

  /**
   * @dev Emitted when the reserve is set as borrowable/non borrowable in isolation mode.
   * @param asset The address of the underlying asset of the reserve
   * @param borrowable True if the reserve is borrowable in isolation, false otherwise
   **/
  event BorrowableInIsolationChanged(address asset, bool borrowable);

  /**
   * @notice Initializes multiple reserves.
   * @param input The array of initialization parameters
   **/
  function initReserves(
    ConfiguratorInputTypes.InitReserveInput[] calldata input
  ) external;

  /**
   * @dev Updates the aToken implementation for the reserve.
   * @param input The aToken update parameters
   **/
  function updateAToken(ConfiguratorInputTypes.UpdateATokenInput calldata input)
    external;

  /**
   * @notice Updates the stable debt token implementation for the reserve.
   * @param input The stableDebtToken update parameters
   **/
  function updateStableDebtToken(
    ConfiguratorInputTypes.UpdateDebtTokenInput calldata input
  ) external;

  /**
   * @notice Updates the variable debt token implementation for the asset.
   * @param input The variableDebtToken update parameters
   **/
  function updateVariableDebtToken(
    ConfiguratorInputTypes.UpdateDebtTokenInput calldata input
  ) external;

  /**
   * @notice Configures borrowing on a reserve.
   * @dev Can only be disabled (set to false) if stable borrowing is disabled
   * @param asset The address of the underlying asset of the reserve
   * @param enabled True if borrowing needs to be enabled, false otherwise
   **/
  function setReserveBorrowing(address asset, bool enabled) external;

  /**
   * @notice Configures the reserve collateralization parameters.
   * @dev All the values are expressed in bps. A value of 10000, results in 100.00%
   * @dev The `liquidationBonus` is always above 100%. A value of 105% means the liquidator will receive a 5% bonus
   * @param asset The address of the underlying asset of the reserve
   * @param ltv The loan to value of the asset when used as collateral
   * @param liquidationThreshold The threshold at which loans using this asset as collateral will be considered undercollateralized
   * @param liquidationBonus The bonus liquidators receive to liquidate this asset
   **/
  function configureReserveAsCollateral(
    address asset,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus
  ) external;

  /**
   * @notice Enable or disable stable rate borrowing on a reserve.
   * @dev Can only be enabled (set to true) if borrowing is enabled
   * @param asset The address of the underlying asset of the reserve
   * @param enabled True if stable rate borrowing needs to be enabled, false otherwise
   **/
  function setReserveStableRateBorrowing(address asset, bool enabled) external;

  /**
   * @notice Activate or deactivate a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param active True if the reserve needs to be active, false otherwise
   **/
  function setReserveActive(address asset, bool active) external;

  /**
   * @notice Freeze or unfreeze a reserve. A frozen reserve doesn't allow any new supply, borrow
   * or rate swap but allows repayments, liquidations, rate rebalances and withdrawals.
   * @param asset The address of the underlying asset of the reserve
   * @param freeze True if the reserve needs to be frozen, false otherwise
   **/
  function setReserveFreeze(address asset, bool freeze) external;

  /**
   * @notice Sets the borrowable in isolation flag for the reserve.
   * @dev When this flag is set to true, the asset will be borrowable against isolated collaterals and the
   * borrowed amount will be accumulated in the isolated collateral's total debt exposure
   * @dev Only assets of the same family (e.g. USD stablecoins) should be borrowable in isolation mode to keep
   * consistency in the debt ceiling calculations
   * @param asset The address of the underlying asset of the reserve
   * @param borrowable True if the asset should be borrowable in isolation, false otherwise
   **/
  function setBorrowableInIsolation(address asset, bool borrowable) external;

  /**
   * @notice Pauses a reserve. A paused reserve does not allow any interaction (supply, borrow, repay,
   * swap interest rate, liquidate, atoken transfers).
   * @param asset The address of the underlying asset of the reserve
   * @param paused True if pausing the reserve, false if unpausing
   **/
  function setReservePause(address asset, bool paused) external;

  /**
   * @notice Updates the reserve factor of a reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param newReserveFactor The new reserve factor of the reserve
   **/
  function setReserveFactor(address asset, uint256 newReserveFactor) external;

  /**
   * @notice Sets the interest rate strategy of a reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param newRateStrategyAddress The address of the new interest strategy contract
   **/
  function setReserveInterestRateStrategyAddress(
    address asset,
    address newRateStrategyAddress
  ) external;

  /**
   * @notice Pauses or unpauses all the protocol reserves. In the paused state all the protocol interactions
   * are suspended.
   * @param paused True if protocol needs to be paused, false otherwise
   **/
  function setPoolPause(bool paused) external;

  /**
   * @notice Updates the borrow cap of a reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param newBorrowCap The new borrow cap of the reserve
   **/
  function setBorrowCap(address asset, uint256 newBorrowCap) external;

  /**
   * @notice Updates the supply cap of a reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param newSupplyCap The new supply cap of the reserve
   **/
  function setSupplyCap(address asset, uint256 newSupplyCap) external;

  /**
   * @notice Updates the liquidation protocol fee of reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param newFee The new liquidation protocol fee of the reserve, expressed in bps
   **/
  function setLiquidationProtocolFee(address asset, uint256 newFee) external;

  /**
   * @notice Updates the unbacked mint cap of reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param newUnbackedMintCap The new unbacked mint cap of the reserve
   **/
  function setUnbackedMintCap(address asset, uint256 newUnbackedMintCap)
    external;

  /**
   * @notice Assign an efficiency mode (eMode) category to asset.
   * @param asset The address of the underlying asset of the reserve
   * @param newCategoryId The new category id of the asset
   **/
  function setAssetEModeCategory(address asset, uint8 newCategoryId) external;

  /**
   * @notice Adds a new efficiency mode (eMode) category.
   * @dev If zero is provided as oracle address, the default asset oracles will be used to compute the overall debt and
   * overcollateralization of the users using this category.
   * @dev The new ltv and liquidation threshold must be greater than the base
   * ltvs and liquidation thresholds of all assets within the eMode category
   * @param categoryId The id of the category to be configured
   * @param ltv The ltv associated with the category
   * @param liquidationThreshold The liquidation threshold associated with the category
   * @param liquidationBonus The liquidation bonus associated with the category
   * @param oracle The oracle associated with the category
   * @param label A label identifying the category
   **/
  function setEModeCategory(
    uint8 categoryId,
    uint16 ltv,
    uint16 liquidationThreshold,
    uint16 liquidationBonus,
    address oracle,
    string calldata label
  ) external;

  /**
   * @notice Drops a reserve entirely.
   * @param asset The address of the reserve to drop
   **/
  function dropReserve(address asset) external;

  /**
   * @notice Updates the bridge fee collected by the protocol reserves.
   * @param newBridgeProtocolFee The part of the fee sent to the protocol treasury, expressed in bps
   */
  function updateBridgeProtocolFee(uint256 newBridgeProtocolFee) external;

  /**
   * @notice Updates the total flash loan premium.
   * Total flash loan premium consists of two parts:
   * - A part is sent to aToken holders as extra balance
   * - A part is collected by the protocol reserves
   * @dev Expressed in bps
   * @dev The premium is calculated on the total amount borrowed
   * @param newFlashloanPremiumTotal The total flashloan premium
   */
  function updateFlashloanPremiumTotal(uint128 newFlashloanPremiumTotal)
    external;

  /**
   * @notice Updates the flash loan premium collected by protocol reserves
   * @dev Expressed in bps
   * @dev The premium to protocol is calculated on the total flashloan premium
   * @param newFlashloanPremiumToProtocol The part of the flashloan premium sent to the protocol treasury
   */
  function updateFlashloanPremiumToProtocol(
    uint128 newFlashloanPremiumToProtocol
  ) external;

  /**
   * @notice Sets the debt ceiling for an asset.
   * @param newDebtCeiling The new debt ceiling
   */
  function setDebtCeiling(address asset, uint256 newDebtCeiling) external;

  /**
   * @notice Sets siloed borrowing for an asset
   * @param siloed The new siloed borrowing state
   */
  function setSiloedBorrowing(address asset, bool siloed) external;
}

interface IPriceOracleGetter {
  /**
   * @notice Returns the base currency address
   * @dev Address 0x0 is reserved for USD as base currency.
   * @return Returns the base currency address.
   **/
  function BASE_CURRENCY() external view returns (address);

  /**
   * @notice Returns the base currency unit
   * @dev 1 ether for ETH, 1e8 for USD.
   * @return Returns the base currency unit.
   **/
  function BASE_CURRENCY_UNIT() external view returns (uint256);

  /**
   * @notice Returns the asset price in the base currency
   * @param asset The address of the asset
   * @return The price of the asset
   **/
  function getAssetPrice(address asset) external view returns (uint256);
}

interface IAaveOracle is IPriceOracleGetter {
  /**
   * @dev Emitted after the base currency is set
   * @param baseCurrency The base currency of used for price quotes
   * @param baseCurrencyUnit The unit of the base currency
   */
  event BaseCurrencySet(address indexed baseCurrency, uint256 baseCurrencyUnit);

  /**
   * @dev Emitted after the price source of an asset is updated
   * @param asset The address of the asset
   * @param source The price source of the asset
   */
  event AssetSourceUpdated(address indexed asset, address indexed source);

  /**
   * @dev Emitted after the address of fallback oracle is updated
   * @param fallbackOracle The address of the fallback oracle
   */
  event FallbackOracleUpdated(address indexed fallbackOracle);

  /**
   * @notice Returns the PoolAddressesProvider
   * @return The address of the PoolAddressesProvider contract
   */
  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  /**
   * @notice Sets or replaces price sources of assets
   * @param assets The addresses of the assets
   * @param sources The addresses of the price sources
   */
  function setAssetSources(
    address[] calldata assets,
    address[] calldata sources
  ) external;

  /**
   * @notice Sets the fallback oracle
   * @param fallbackOracle The address of the fallback oracle
   */
  function setFallbackOracle(address fallbackOracle) external;

  /**
   * @notice Returns a list of prices from a list of assets addresses
   * @param assets The list of assets addresses
   * @return The prices of the given assets
   */
  function getAssetsPrices(address[] calldata assets)
    external
    view
    returns (uint256[] memory);

  /**
   * @notice Returns the address of the source for an asset address
   * @param asset The address of the asset
   * @return The address of the source
   */
  function getSourceOfAsset(address asset) external view returns (address);

  /**
   * @notice Returns the address of the fallback oracle
   * @return The address of the fallback oracle
   */
  function getFallbackOracle() external view returns (address);
}

struct TokenData {
  string symbol;
  address tokenAddress;
}

// TODO: add better documentation
interface IAaveProtocolDataProvider {
  function getAllReservesTokens() external view returns (TokenData[] memory);

  function getAllATokens() external view returns (TokenData[] memory);

  function getReserveConfigurationData(address asset)
    external
    view
    returns (
      uint256 decimals,
      uint256 ltv,
      uint256 liquidationThreshold,
      uint256 liquidationBonus,
      uint256 reserveFactor,
      bool usageAsCollateralEnabled,
      bool borrowingEnabled,
      bool stableBorrowRateEnabled,
      bool isActive,
      bool isFrozen
    );

  function getReserveEModeCategory(address asset)
    external
    view
    returns (uint256);

  function getReserveCaps(address asset)
    external
    view
    returns (uint256 borrowCap, uint256 supplyCap);

  function getPaused(address asset) external view returns (bool isPaused);

  function getSiloedBorrowing(address asset) external view returns (bool);

  function getLiquidationProtocolFee(address asset)
    external
    view
    returns (uint256);

  function getUnbackedMintCap(address asset) external view returns (uint256);

  function getDebtCeiling(address asset) external view returns (uint256);

  function getDebtCeilingDecimals() external pure returns (uint256);

  /**
   * @notice Returns the reserve data
   * @param asset The address of the underlying asset of the reserve
   * @return unbacked The amount of unbacked tokens
   * @return accruedToTreasuryScaled The scaled amount of tokens accrued to treasury that is to be minted
   * @return totalAToken The total supply of the aToken
   * @return totalStableDebt The total stable debt of the reserve
   * @return totalVariableDebt The total variable debt of the reserve
   * @return liquidityRate The liquidity rate of the reserve
   * @return variableBorrowRate The variable borrow rate of the reserve
   * @return stableBorrowRate The stable borrow rate of the reserve
   * @return averageStableBorrowRate The average stable borrow rate of the reserve
   * @return liquidityIndex The liquidity index of the reserve
   * @return variableBorrowIndex The variable borrow index of the reserve
   * @return lastUpdateTimestamp The timestamp of the last update of the reserve
   **/
  function getReserveData(address asset)
    external
    view
    returns (
      uint256 unbacked,
      uint256 accruedToTreasuryScaled,
      uint256 totalAToken,
      uint256 totalStableDebt,
      uint256 totalVariableDebt,
      uint256 liquidityRate,
      uint256 variableBorrowRate,
      uint256 stableBorrowRate,
      uint256 averageStableBorrowRate,
      uint256 liquidityIndex,
      uint256 variableBorrowIndex,
      uint40 lastUpdateTimestamp
    );

  /**
   * @notice Returns the total supply of aTokens for a given asset
   * @param asset The address of the underlying asset of the reserve
   * @return The total supply of the aToken
   **/
  function getATokenTotalSupply(address asset) external view returns (uint256);

  /**
   * @notice Returns the total debt for a given asset
   * @param asset The address of the underlying asset of the reserve
   * @return The total debt for asset
   **/
  function getTotalDebt(address asset) external view returns (uint256);

  function getUserReserveData(address asset, address user)
    external
    view
    returns (
      uint256 currentATokenBalance,
      uint256 currentStableDebt,
      uint256 currentVariableDebt,
      uint256 principalStableDebt,
      uint256 scaledVariableDebt,
      uint256 stableBorrowRate,
      uint256 liquidityRate,
      uint40 stableRateLastUpdated,
      bool usageAsCollateralEnabled
    );

  function getReserveTokensAddresses(address asset)
    external
    view
    returns (
      address aTokenAddress,
      address stableDebtTokenAddress,
      address variableDebtTokenAddress
    );

  function getInterestRateStrategyAddress(address asset)
    external
    view
    returns (address irStrategyAddress);
}

/**
 * @title IACLManager
 * @author Aave
 * @notice Defines the basic interface for the ACL Manager
 **/
interface IACLManager {
  /**
   * @notice Returns the contract address of the PoolAddressesProvider
   * @return The address of the PoolAddressesProvider
   */
  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  /**
   * @notice Returns the identifier of the PoolAdmin role
   * @return The id of the PoolAdmin role
   */
  function POOL_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the EmergencyAdmin role
   * @return The id of the EmergencyAdmin role
   */
  function EMERGENCY_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the RiskAdmin role
   * @return The id of the RiskAdmin role
   */
  function RISK_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the FlashBorrower role
   * @return The id of the FlashBorrower role
   */
  function FLASH_BORROWER_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the Bridge role
   * @return The id of the Bridge role
   */
  function BRIDGE_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the AssetListingAdmin role
   * @return The id of the AssetListingAdmin role
   */
  function ASSET_LISTING_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Set the role as admin of a specific role.
   * @dev By default the admin role for all roles is `DEFAULT_ADMIN_ROLE`.
   * @param role The role to be managed by the admin role
   * @param adminRole The admin role
   */
  function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

  /**
   * @notice Adds a new admin as PoolAdmin
   * @param admin The address of the new admin
   */
  function addPoolAdmin(address admin) external;

  /**
   * @notice Removes an admin as PoolAdmin
   * @param admin The address of the admin to remove
   */
  function removePoolAdmin(address admin) external;

  /**
   * @notice Returns true if the address is PoolAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is PoolAdmin, false otherwise
   */
  function isPoolAdmin(address admin) external view returns (bool);

  /**
   * @notice Adds a new admin as EmergencyAdmin
   * @param admin The address of the new admin
   */
  function addEmergencyAdmin(address admin) external;

  /**
   * @notice Removes an admin as EmergencyAdmin
   * @param admin The address of the admin to remove
   */
  function removeEmergencyAdmin(address admin) external;

  /**
   * @notice Returns true if the address is EmergencyAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is EmergencyAdmin, false otherwise
   */
  function isEmergencyAdmin(address admin) external view returns (bool);

  /**
   * @notice Adds a new admin as RiskAdmin
   * @param admin The address of the new admin
   */
  function addRiskAdmin(address admin) external;

  /**
   * @notice Removes an admin as RiskAdmin
   * @param admin The address of the admin to remove
   */
  function removeRiskAdmin(address admin) external;

  /**
   * @notice Returns true if the address is RiskAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is RiskAdmin, false otherwise
   */
  function isRiskAdmin(address admin) external view returns (bool);

  /**
   * @notice Adds a new address as FlashBorrower
   * @param borrower The address of the new FlashBorrower
   */
  function addFlashBorrower(address borrower) external;

  /**
   * @notice Removes an admin as FlashBorrower
   * @param borrower The address of the FlashBorrower to remove
   */
  function removeFlashBorrower(address borrower) external;

  /**
   * @notice Returns true if the address is FlashBorrower, false otherwise
   * @param borrower The address to check
   * @return True if the given address is FlashBorrower, false otherwise
   */
  function isFlashBorrower(address borrower) external view returns (bool);

  /**
   * @notice Adds a new address as Bridge
   * @param bridge The address of the new Bridge
   */
  function addBridge(address bridge) external;

  /**
   * @notice Removes an address as Bridge
   * @param bridge The address of the bridge to remove
   */
  function removeBridge(address bridge) external;

  /**
   * @notice Returns true if the address is Bridge, false otherwise
   * @param bridge The address to check
   * @return True if the given address is Bridge, false otherwise
   */
  function isBridge(address bridge) external view returns (bool);

  /**
   * @notice Adds a new admin as AssetListingAdmin
   * @param admin The address of the new admin
   */
  function addAssetListingAdmin(address admin) external;

  /**
   * @notice Removes an admin as AssetListingAdmin
   * @param admin The address of the admin to remove
   */
  function removeAssetListingAdmin(address admin) external;

  /**
   * @notice Returns true if the address is AssetListingAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is AssetListingAdmin, false otherwise
   */
  function isAssetListingAdmin(address admin) external view returns (bool);

  /**
   * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
   *
   * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
   * {RoleAdminChanged} not being emitted signaling this.
   *
   * _Available since v3.1._
   */
  event RoleAdminChanged(
    bytes32 indexed role,
    bytes32 indexed previousAdminRole,
    bytes32 indexed newAdminRole
  );

  /**
   * @dev Emitted when `account` is granted `role`.
   *
   * `sender` is the account that originated the contract call, an admin role
   * bearer except when using {AccessControl-_setupRole}.
   */
  event RoleGranted(
    bytes32 indexed role,
    address indexed account,
    address indexed sender
  );

  // Parent Access Control Interface
  /**
   * @dev Emitted when `account` is revoked `role`.
   *
   * `sender` is the account that originated the contract call:
   *   - if using `revokeRole`, it is the admin role bearer
   *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
   */
  event RoleRevoked(
    bytes32 indexed role,
    address indexed account,
    address indexed sender
  );

  /**
   * @dev Returns `true` if `account` has been granted `role`.
   */
  function hasRole(bytes32 role, address account) external view returns (bool);

  /**
   * @dev Returns the admin role that controls `role`. See {grantRole} and
   * {revokeRole}.
   *
   * To change a role's admin, use {AccessControl-_setRoleAdmin}.
   */
  function getRoleAdmin(bytes32 role) external view returns (bytes32);

  /**
   * @dev Grants `role` to `account`.
   *
   * If `account` had not been already granted `role`, emits a {RoleGranted}
   * event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   */
  function grantRole(bytes32 role, address account) external;

  /**
   * @dev Revokes `role` from `account`.
   *
   * If `account` had been granted `role`, emits a {RoleRevoked} event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   */
  function revokeRole(bytes32 role, address account) external;

  /**
   * @dev Revokes `role` from the calling account.
   *
   * Roles are often managed via {grantRole} and {revokeRole}: this function's
   * purpose is to provide a mechanism for accounts to lose their privileges
   * if they are compromised (such as when a trusted device is misplaced).
   *
   * If the calling account had been granted `role`, emits a {RoleRevoked}
   * event.
   *
   * Requirements:
   *
   * - the caller must be `account`.
   */
  function renounceRole(bytes32 role, address account) external;
}

interface IInterestRateStrategy {
  /**
   * @dev This constant represents the usage ratio at which the pool aims to obtain most competitive borrow rates.
   * Expressed in ray
   */
  function OPTIMAL_USAGE_RATIO() external view returns (uint256);

  /**
   * @dev This constant represents the optimal stable debt to total debt ratio of the reserve.
   * Expressed in ray
   */
  function OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO() external view returns (uint256);

  /**
   * @dev This constant represents the excess usage ratio above the optimal. It's always equal to
   * 1-optimal usage ratio. Added as a constant here for gas optimizations.
   * Expressed in ray
   */
  function MAX_EXCESS_USAGE_RATIO() external view returns (uint256);

  /**
   * @dev This constant represents the excess stable debt ratio above the optimal. It's always equal to
   * 1-optimal stable to total debt ratio. Added as a constant here for gas optimizations.
   * Expressed in ray
   */
  function MAX_EXCESS_STABLE_TO_TOTAL_DEBT_RATIO()
    external
    view
    returns (uint256);

  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  /**
   * @notice Returns the variable rate slope below optimal usage ratio
   * @dev Its the variable rate when usage ratio > 0 and <= OPTIMAL_USAGE_RATIO
   * @return The variable rate slope
   */
  function getVariableRateSlope1() external view returns (uint256);

  /**
   * @notice Returns the variable rate slope above optimal usage ratio
   * @dev Its the variable rate when usage ratio > OPTIMAL_USAGE_RATIO
   * @return The variable rate slope
   */
  function getVariableRateSlope2() external view returns (uint256);

  /**
   * @notice Returns the stable rate slope below optimal usage ratio
   * @dev Its the stable rate when usage ratio > 0 and <= OPTIMAL_USAGE_RATIO
   * @return The stable rate slope
   */
  function getStableRateSlope1() external view returns (uint256);

  /**
   * @notice Returns the stable rate slope above optimal usage ratio
   * @dev Its the variable rate when usage ratio > OPTIMAL_USAGE_RATIO
   * @return The stable rate slope
   */
  function getStableRateSlope2() external view returns (uint256);

  /**
   * @notice Returns the stable rate excess offset
   * @dev An additional premium applied to the stable when stable debt > OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO
   * @return The stable rate excess offset
   */
  function getStableRateExcessOffset() external view returns (uint256);

  /**
   * @notice Returns the base stable borrow rate
   * @return The base stable borrow rate
   */
  function getBaseStableBorrowRate() external view returns (uint256);

  /**
   * @notice Returns the base variable borrow rate
   * @return The base variable borrow rate, expressed in ray
   */
  function getBaseVariableBorrowRate() external view returns (uint256);

  /**
   * @notice Returns the maximum variable borrow rate
   * @return The maximum variable borrow rate, expressed in ray
   */
  function getMaxVariableBorrowRate() external view returns (uint256);

  /**
   * @notice Calculates the interest rates depending on the reserve's state and configurations
   * @param params The parameters needed to calculate interest rates
   * @return liquidityRate The liquidity rate expressed in rays
   * @return stableBorrowRate The stable borrow rate expressed in rays
   * @return variableBorrowRate The variable borrow rate expressed in rays
   */
  function calculateInterestRates(
    DataTypes.CalculateInterestRatesParams memory params
  )
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );
}

/**
 * @title ICollector
 * @notice Defines the interface of the Collector contract
 * @author Aave
 **/
interface ICollector {
  /**
   * @dev Emitted during the transfer of ownership of the funds administrator address
   * @param fundsAdmin The new funds administrator address
   **/
  event NewFundsAdmin(address indexed fundsAdmin);

  /**
   * @dev Retrieve the current implementation Revision of the proxy
   * @return The revision version
   */
  function REVISION() external view returns (uint256);

  /**
   * @dev Retrieve the current funds administrator
   * @return The address of the funds administrator
   */
  function getFundsAdmin() external view returns (address);

  /**
   * @dev Approve an amount of tokens to be pulled by the recipient.
   * @param token The address of the asset
   * @param recipient The address of the entity allowed to pull tokens
   * @param amount The amount allowed to be pulled. If zero it will revoke the approval.
   */
  function approve(
    // IERC20 token,
    address token,
    address recipient,
    uint256 amount
  ) external;

  /**
   * @dev Transfer an amount of tokens to the recipient.
   * @param token The address of the asset
   * @param recipient The address of the entity to transfer the tokens.
   * @param amount The amount to be transferred.
   */
  function transfer(
    // IERC20 token,
    address token,
    address recipient,
    uint256 amount
  ) external;

  /**
   * @dev Transfer the ownership of the funds administrator role.
          This function should only be callable by the current funds administrator.
   * @param admin The address of the new funds administrator
   */
  function setFundsAdmin(address admin) external;
}

// SPDX-License-Identifier: MIT
// AUTOGENERATED - DON'T MANUALLY CHANGE
pragma solidity >=0.6.0;

import {IPoolAddressesProvider, IPool, IPoolConfigurator, IAaveOracle, IAaveProtocolDataProvider, IACLManager, ICollector} from "./AaveV3.sol";

library AaveV3Arbitrum {
    IPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
        IPoolAddressesProvider(0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb);

    IPool internal constant POOL =
        IPool(0x794a61358D6845594F94dc1DB02A252b5b4814aD);

    IPoolConfigurator internal constant POOL_CONFIGURATOR =
        IPoolConfigurator(0x8145eddDf43f50276641b55bd3AD95944510021E);

    IAaveOracle internal constant ORACLE =
        IAaveOracle(0xb56c2F0B653B2e0b10C9b928C8580Ac5Df02C7C7);

    IAaveProtocolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
        IAaveProtocolDataProvider(0x69FA688f1Dc47d4B5d8029D5a35FB7a548310654);

    IACLManager internal constant ACL_MANAGER =
        IACLManager(0xa72636CbcAa8F5FF95B2cc47F3CDEe83F3294a0B);

    address internal constant ACL_ADMIN =
        0xbbd9f90699c1FA0D7A65870D241DD1f1217c96Eb;

    address internal constant COLLECTOR =
        0x053D55f9B5AF8694c503EB288a1B7E552f590710;

    ICollector internal constant COLLECTOR_CONTROLLER =
        ICollector(0xC3301b30f4EcBfd59dE0d74e89690C1a70C6f21B);

    address internal constant DEFAULT_INCENTIVES_CONTROLLER =
        0x929EC64c34a17401F460460D4B9390518E5B473e;

    address internal constant DEFAULT_A_TOKEN_IMPL_REV_1 =
        0xa5ba6E5EC19a1Bf23C857991c857dB62b2Aa187B;

    address internal constant DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_1 =
        0x81387c40EB75acB02757C1Ae55D5936E78c9dEd3;

    address internal constant DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_1 =
        0x52A1CeB68Ee6b7B5D13E0376A1E0E4423A8cE26e;

    address internal constant EMISSION_MANAGER =
        0x048f2228D7Bf6776f99aB50cB1b1eaB4D1d4cA73;
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

import './IOwnable.sol';

interface IBridge {
  event MessageDelivered(
    uint256 indexed messageIndex,
    bytes32 indexed beforeInboxAcc,
    address inbox,
    uint8 kind,
    address sender,
    bytes32 messageDataHash,
    uint256 baseFeeL1,
    uint64 timestamp
  );

  event BridgeCallTriggered(address indexed outbox, address indexed to, uint256 value, bytes data);

  event InboxToggle(address indexed inbox, bool enabled);

  event OutboxToggle(address indexed outbox, bool enabled);

  event SequencerInboxUpdated(address newSequencerInbox);

  function allowedDelayedInboxList(uint256) external returns (address);

  function allowedOutboxList(uint256) external returns (address);

  /// @dev Accumulator for delayed inbox messages; tail represents hash of the current state; each element represents the inclusion of a new message.
  function delayedInboxAccs(uint256) external view returns (bytes32);

  /// @dev Accumulator for sequencer inbox messages; tail represents hash of the current state; each element represents the inclusion of a new message.
  function sequencerInboxAccs(uint256) external view returns (bytes32);

  function rollup() external view returns (IOwnable);

  function sequencerInbox() external view returns (address);

  function activeOutbox() external view returns (address);

  function allowedDelayedInboxes(address inbox) external view returns (bool);

  function allowedOutboxes(address outbox) external view returns (bool);

  /**
   * @dev Enqueue a message in the delayed inbox accumulator.
   *      These messages are later sequenced in the SequencerInbox, either
   *      by the sequencer as part of a normal batch, or by force inclusion.
   */
  function enqueueDelayedMessage(
    uint8 kind,
    address sender,
    bytes32 messageDataHash
  ) external payable returns (uint256);

  function executeCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success, bytes memory returnData);

  function delayedMessageCount() external view returns (uint256);

  function sequencerMessageCount() external view returns (uint256);

  // ---------- onlySequencerInbox functions ----------

  function enqueueSequencerMessage(bytes32 dataHash, uint256 afterDelayedMessagesRead)
    external
    returns (
      uint256 seqMessageIndex,
      bytes32 beforeAcc,
      bytes32 delayedAcc,
      bytes32 acc
    );

  /**
   * @dev Allows the sequencer inbox to submit a delayed message of the batchPostingReport type
   *      This is done through a separate function entrypoint instead of allowing the sequencer inbox
   *      to call `enqueueDelayedMessage` to avoid the gas overhead of an extra SLOAD in either
   *      every delayed inbox or every sequencer inbox call.
   */
  function submitBatchSpendingReport(address batchPoster, bytes32 dataHash)
    external
    returns (uint256 msgNum);

  // ---------- onlyRollupOrOwner functions ----------

  function setSequencerInbox(address _sequencerInbox) external;

  function setDelayedInbox(address inbox, bool enabled) external;

  function setOutbox(address inbox, bool enabled) external;

  // ---------- initializer ----------

  function initialize(IOwnable rollup_) external;
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

interface IDelayedMessageProvider {
  /// @dev event emitted when a inbox message is added to the Bridge's delayed accumulator
  event InboxMessageDelivered(uint256 indexed messageNum, bytes data);

  /// @dev event emitted when a inbox message is added to the Bridge's delayed accumulator
  /// same as InboxMessageDelivered but the batch data is available in tx.input
  event InboxMessageDeliveredFromOrigin(uint256 indexed messageNum);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

import './IBridge.sol';
import './IDelayedMessageProvider.sol';
import './ISequencerInbox.sol';

interface IInbox is IDelayedMessageProvider {
  function bridge() external view returns (IBridge);

  function sequencerInbox() external view returns (ISequencerInbox);

  /**
   * @notice Send a generic L2 message to the chain
   * @dev This method is an optimization to avoid having to emit the entirety of the messageData in a log. Instead validators are expected to be able to parse the data from the transaction's input
   * @param messageData Data of the message being sent
   */
  function sendL2MessageFromOrigin(bytes calldata messageData) external returns (uint256);

  /**
   * @notice Send a generic L2 message to the chain
   * @dev This method can be used to send any type of message that doesn't require L1 validation
   * @param messageData Data of the message being sent
   */
  function sendL2Message(bytes calldata messageData) external returns (uint256);

  function sendL1FundedUnsignedTransaction(
    uint256 gasLimit,
    uint256 maxFeePerGas,
    uint256 nonce,
    address to,
    bytes calldata data
  ) external payable returns (uint256);

  function sendL1FundedContractTransaction(
    uint256 gasLimit,
    uint256 maxFeePerGas,
    address to,
    bytes calldata data
  ) external payable returns (uint256);

  function sendUnsignedTransaction(
    uint256 gasLimit,
    uint256 maxFeePerGas,
    uint256 nonce,
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (uint256);

  function sendContractTransaction(
    uint256 gasLimit,
    uint256 maxFeePerGas,
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (uint256);

  /**
   * @notice Get the L1 fee for submitting a retryable
   * @dev This fee can be paid by funds already in the L2 aliased address or by the current message value
   * @dev This formula may change in the future, to future proof your code query this method instead of inlining!!
   * @param dataLength The length of the retryable's calldata, in bytes
   * @param baseFee The block basefee when the retryable is included in the chain, if 0 current block.basefee will be used
   */
  function calculateRetryableSubmissionFee(uint256 dataLength, uint256 baseFee)
    external
    view
    returns (uint256);

  /**
   * @notice Deposit eth from L1 to L2
   * @dev This does not trigger the fallback function when receiving in the L2 side.
   *      Look into retryable tickets if you are interested in this functionality.
   * @dev This function should not be called inside contract constructors
   */
  function depositEth() external payable returns (uint256);

  /**
   * @notice Put a message in the L2 inbox that can be reexecuted for some fixed amount of time if it reverts
   * @dev all msg.value will deposited to callValueRefundAddress on L2
   * @dev Gas limit and maxFeePerGas should not be set to 1 as that is used to trigger the RetryableData error
   * @param to destination L2 contract address
   * @param l2CallValue call value for retryable L2 message
   * @param maxSubmissionCost Max gas deducted from user's L2 balance to cover base submission fee
   * @param excessFeeRefundAddress gasLimit x maxFeePerGas - execution cost gets credited here on L2 balance
   * @param callValueRefundAddress l2Callvalue gets credited here on L2 if retryable txn times out or gets cancelled
   * @param gasLimit Max gas deducted from user's L2 balance to cover L2 execution. Should not be set to 1 (magic value used to trigger the RetryableData error)
   * @param maxFeePerGas price bid for L2 execution. Should not be set to 1 (magic value used to trigger the RetryableData error)
   * @param data ABI encoded data of L2 message
   * @return unique message number of the retryable transaction
   */
  function createRetryableTicket(
    address to,
    uint256 l2CallValue,
    uint256 maxSubmissionCost,
    address excessFeeRefundAddress,
    address callValueRefundAddress,
    uint256 gasLimit,
    uint256 maxFeePerGas,
    bytes calldata data
  ) external payable returns (uint256);

  /**
   * @notice Put a message in the L2 inbox that can be reexecuted for some fixed amount of time if it reverts
   * @dev Same as createRetryableTicket, but does not guarantee that submission will succeed by requiring the needed funds
   * come from the deposit alone, rather than falling back on the user's L2 balance
   * @dev Advanced usage only (does not rewrite aliases for excessFeeRefundAddress and callValueRefundAddress).
   * createRetryableTicket method is the recommended standard.
   * @dev Gas limit and maxFeePerGas should not be set to 1 as that is used to trigger the RetryableData error
   * @param to destination L2 contract address
   * @param l2CallValue call value for retryable L2 message
   * @param maxSubmissionCost Max gas deducted from user's L2 balance to cover base submission fee
   * @param excessFeeRefundAddress gasLimit x maxFeePerGas - execution cost gets credited here on L2 balance
   * @param callValueRefundAddress l2Callvalue gets credited here on L2 if retryable txn times out or gets cancelled
   * @param gasLimit Max gas deducted from user's L2 balance to cover L2 execution. Should not be set to 1 (magic value used to trigger the RetryableData error)
   * @param maxFeePerGas price bid for L2 execution. Should not be set to 1 (magic value used to trigger the RetryableData error)
   * @param data ABI encoded data of L2 message
   * @return unique message number of the retryable transaction
   */
  function unsafeCreateRetryableTicket(
    address to,
    uint256 l2CallValue,
    uint256 maxSubmissionCost,
    address excessFeeRefundAddress,
    address callValueRefundAddress,
    uint256 gasLimit,
    uint256 maxFeePerGas,
    bytes calldata data
  ) external payable returns (uint256);

  // ---------- onlyRollupOrOwner functions ----------

  /// @notice pauses all inbox functionality
  function pause() external;

  /// @notice unpauses all inbox functionality
  function unpause() external;

  // ---------- initializer ----------

  /**
   * @dev function to be called one time during the inbox upgrade process
   *      this is used to fix the storage slots
   */
  function postUpgradeInit(IBridge _bridge) external;

  function initialize(IBridge _bridge, ISequencerInbox _sequencerInbox) external;
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.21 <0.9.0;

interface IOwnable {
  function owner() external view returns (address);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;
pragma experimental ABIEncoderV2;

import '../libraries/IGasRefunder.sol';
import './IDelayedMessageProvider.sol';
import './IBridge.sol';

interface ISequencerInbox is IDelayedMessageProvider {
  struct MaxTimeVariation {
    uint256 delayBlocks;
    uint256 futureBlocks;
    uint256 delaySeconds;
    uint256 futureSeconds;
  }

  struct TimeBounds {
    uint64 minTimestamp;
    uint64 maxTimestamp;
    uint64 minBlockNumber;
    uint64 maxBlockNumber;
  }

  enum BatchDataLocation {
    TxInput,
    SeparateBatchEvent,
    NoData
  }

  event SequencerBatchDelivered(
    uint256 indexed batchSequenceNumber,
    bytes32 indexed beforeAcc,
    bytes32 indexed afterAcc,
    bytes32 delayedAcc,
    uint256 afterDelayedMessagesRead,
    TimeBounds timeBounds,
    BatchDataLocation dataLocation
  );

  event OwnerFunctionCalled(uint256 indexed id);

  /// @dev a separate event that emits batch data when this isn't easily accessible in the tx.input
  event SequencerBatchData(uint256 indexed batchSequenceNumber, bytes data);

  /// @dev a valid keyset was added
  event SetValidKeyset(bytes32 indexed keysetHash, bytes keysetBytes);

  /// @dev a keyset was invalidated
  event InvalidateKeyset(bytes32 indexed keysetHash);

  function totalDelayedMessagesRead() external view returns (uint256);

  function bridge() external view returns (IBridge);

  /// @dev The size of the batch header
  // solhint-disable-next-line func-name-mixedcase
  function HEADER_LENGTH() external view returns (uint256);

  /// @dev If the first batch data byte after the header has this bit set,
  ///      the sequencer inbox has authenticated the data. Currently not used.
  // solhint-disable-next-line func-name-mixedcase
  function DATA_AUTHENTICATED_FLAG() external view returns (bytes1);

  function rollup() external view returns (IOwnable);

  function isBatchPoster(address) external view returns (bool);

  struct DasKeySetInfo {
    bool isValidKeyset;
    uint64 creationBlock;
  }

  // https://github.com/ethereum/solidity/issues/11826
  // function maxTimeVariation() external view returns (MaxTimeVariation calldata);
  // function dasKeySetInfo(bytes32) external view returns (DasKeySetInfo calldata);

  /// @notice Force messages from the delayed inbox to be included in the chain
  ///         Callable by any address, but message can only be force-included after maxTimeVariation.delayBlocks and
  ///         maxTimeVariation.delaySeconds has elapsed. As part of normal behaviour the sequencer will include these
  ///         messages so it's only necessary to call this if the sequencer is down, or not including any delayed messages.
  /// @param _totalDelayedMessagesRead The total number of messages to read up to
  /// @param kind The kind of the last message to be included
  /// @param l1BlockAndTime The l1 block and the l1 timestamp of the last message to be included
  /// @param baseFeeL1 The l1 gas price of the last message to be included
  /// @param sender The sender of the last message to be included
  /// @param messageDataHash The messageDataHash of the last message to be included
  function forceInclusion(
    uint256 _totalDelayedMessagesRead,
    uint8 kind,
    uint64[2] calldata l1BlockAndTime,
    uint256 baseFeeL1,
    address sender,
    bytes32 messageDataHash
  ) external;

  function inboxAccs(uint256 index) external view returns (bytes32);

  function batchCount() external view returns (uint256);

  function isValidKeysetHash(bytes32 ksHash) external view returns (bool);

  /// @notice the creation block is intended to still be available after a keyset is deleted
  function getKeysetCreationBlock(bytes32 ksHash) external view returns (uint256);

  // ---------- BatchPoster functions ----------

  function addSequencerL2BatchFromOrigin(
    uint256 sequenceNumber,
    bytes calldata data,
    uint256 afterDelayedMessagesRead,
    IGasRefunder gasRefunder
  ) external;

  function addSequencerL2Batch(
    uint256 sequenceNumber,
    bytes calldata data,
    uint256 afterDelayedMessagesRead,
    IGasRefunder gasRefunder
  ) external;

  // ---------- onlyRollupOrOwner functions ----------

  /**
   * @notice Set max delay for sequencer inbox
   * @param maxTimeVariation_ the maximum time variation parameters
   */
  function setMaxTimeVariation(MaxTimeVariation memory maxTimeVariation_) external;

  /**
   * @notice Updates whether an address is authorized to be a batch poster at the sequencer inbox
   * @param addr the address
   * @param isBatchPoster_ if the specified address should be authorized as a batch poster
   */
  function setIsBatchPoster(address addr, bool isBatchPoster_) external;

  /**
   * @notice Makes Data Availability Service keyset valid
   * @param keysetBytes bytes of the serialized keyset
   */
  function setValidKeyset(bytes calldata keysetBytes) external;

  /**
   * @notice Invalidates a Data Availability Service keyset
   * @param ksHash hash of the keyset
   */
  function invalidateKeysetHash(bytes32 ksHash) external;

  // ---------- initializer ----------

  function initialize(IBridge bridge_, MaxTimeVariation calldata maxTimeVariation_) external;
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

interface IGasRefunder {
  function onGasSpent(
    address payable spender,
    uint256 gasUsed,
    uint256 calldataSize
  ) external returns (bool success);
}

abstract contract GasRefundEnabled {
  /// @dev this refunds the sender for execution costs of the tx
  /// calldata costs are only refunded if `msg.sender == tx.origin` to guarantee the value refunded relates to charging
  /// for the `tx.input`. this avoids a possible attack where you generate large calldata from a contract and get over-refunded
  modifier refundsGas(IGasRefunder gasRefunder) {
    uint256 startGasLeft = gasleft();
    _;
    if (address(gasRefunder) != address(0)) {
      uint256 calldataSize = 0;
      // if triggered in a contract call, the spender may be overrefunded by appending dummy data to the call
      // so we check if it is a top level call, which would mean the sender paid calldata as part of tx.input
      // solhint-disable-next-line avoid-tx-origin
      if (msg.sender == tx.origin) {
        assembly {
          calldataSize := calldatasize()
        }
      }
      gasRefunder.onGasSpent(payable(msg.sender), startGasLeft - gasleft(), calldataSize);
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

/**
 * @title IExecutorBase
 * @author Aave
 * @notice Defines the basic interface for the ExecutorBase abstract contract
 */
interface IExecutorBase {
  error InvalidInitParams();
  error NotGuardian();
  error OnlyCallableByThis();
  error MinimumDelayTooLong();
  error MaximumDelayTooShort();
  error GracePeriodTooShort();
  error DelayShorterThanMin();
  error DelayLongerThanMax();
  error OnlyQueuedActions();
  error TimelockNotFinished();
  error InvalidActionsSetId();
  error EmptyTargets();
  error InconsistentParamsLength();
  error DuplicateAction();
  error InsufficientBalance();
  error FailedActionExecution();

  /**
   * @notice This enum contains all possible actions set states
   */
  enum ActionsSetState {
    Queued,
    Executed,
    Canceled,
    Expired
  }

  /**
   * @notice This struct contains the data needed to execute a specified set of actions
   * @param targets Array of targets to call
   * @param values Array of values to pass in each call
   * @param signatures Array of function signatures to encode in each call (can be empty)
   * @param calldatas Array of calldatas to pass in each call, appended to the signature at the same array index if not empty
   * @param withDelegateCalls Array of whether to delegatecall for each call
   * @param executionTime Timestamp starting from which the actions set can be executed
   * @param executed True if the actions set has been executed, false otherwise
   * @param canceled True if the actions set has been canceled, false otherwise
   */
  struct ActionsSet {
    address[] targets;
    uint256[] values;
    string[] signatures;
    bytes[] calldatas;
    bool[] withDelegatecalls;
    uint256 executionTime;
    bool executed;
    bool canceled;
  }

  /**
   * @dev Emitted when an ActionsSet is queued
   * @param id Id of the ActionsSet
   * @param targets Array of targets to be called by the actions set
   * @param values Array of values to pass in each call by the actions set
   * @param signatures Array of function signatures to encode in each call by the actions set
   * @param calldatas Array of calldata to pass in each call by the actions set
   * @param withDelegatecalls Array of whether to delegatecall for each call of the actions set
   * @param executionTime The timestamp at which this actions set can be executed
   **/
  event ActionsSetQueued(
    uint256 indexed id,
    address[] targets,
    uint256[] values,
    string[] signatures,
    bytes[] calldatas,
    bool[] withDelegatecalls,
    uint256 executionTime
  );

  /**
   * @dev Emitted when an ActionsSet is successfully executed
   * @param id Id of the ActionsSet
   * @param initiatorExecution The address that triggered the ActionsSet execution
   * @param returnedData The returned data from the ActionsSet execution
   **/
  event ActionsSetExecuted(
    uint256 indexed id,
    address indexed initiatorExecution,
    bytes[] returnedData
  );

  /**
   * @dev Emitted when an ActionsSet is cancelled by the guardian
   * @param id Id of the ActionsSet
   **/
  event ActionsSetCanceled(uint256 indexed id);

  /**
   * @dev Emitted when a new guardian is set
   * @param oldGuardian The address of the old guardian
   * @param newGuardian The address of the new guardian
   **/
  event GuardianUpdate(address oldGuardian, address newGuardian);

  /**
   * @dev Emitted when the delay (between queueing and execution) is updated
   * @param oldDelay The value of the old delay
   * @param newDelay The value of the new delay
   **/
  event DelayUpdate(uint256 oldDelay, uint256 newDelay);

  /**
   * @dev Emitted when the grace period (between executionTime and expiration) is updated
   * @param oldGracePeriod The value of the old grace period
   * @param newGracePeriod The value of the new grace period
   **/
  event GracePeriodUpdate(uint256 oldGracePeriod, uint256 newGracePeriod);

  /**
   * @dev Emitted when the minimum delay (lower bound of delay) is updated
   * @param oldMinimumDelay The value of the old minimum delay
   * @param newMinimumDelay The value of the new minimum delay
   **/
  event MinimumDelayUpdate(uint256 oldMinimumDelay, uint256 newMinimumDelay);

  /**
   * @dev Emitted when the maximum delay (upper bound of delay)is updated
   * @param oldMaximumDelay The value of the old maximum delay
   * @param newMaximumDelay The value of the new maximum delay
   **/
  event MaximumDelayUpdate(uint256 oldMaximumDelay, uint256 newMaximumDelay);

  /**
   * @notice Execute the ActionsSet
   * @param actionsSetId The id of the ActionsSet to execute
   **/
  function execute(uint256 actionsSetId) external payable;

  /**
   * @notice Cancel the ActionsSet
   * @param actionsSetId The id of the ActionsSet to cancel
   **/
  function cancel(uint256 actionsSetId) external;

  /**
   * @notice Update guardian
   * @param guardian The address of the new guardian
   **/
  function updateGuardian(address guardian) external;

  /**
   * @notice Update the delay, time between queueing and execution of ActionsSet
   * @dev It does not affect to actions set that are already queued
   * @param delay The value of the delay (in seconds)
   **/
  function updateDelay(uint256 delay) external;

  /**
   * @notice Update the grace period, the period after the execution time during which an actions set can be executed
   * @param gracePeriod The value of the grace period (in seconds)
   **/
  function updateGracePeriod(uint256 gracePeriod) external;

  /**
   * @notice Update the minimum allowed delay
   * @param minimumDelay The value of the minimum delay (in seconds)
   **/
  function updateMinimumDelay(uint256 minimumDelay) external;

  /**
   * @notice Update the maximum allowed delay
   * @param maximumDelay The maximum delay (in seconds)
   **/
  function updateMaximumDelay(uint256 maximumDelay) external;

  /**
   * @notice Allows to delegatecall a given target with an specific amount of value
   * @dev This function is external so it allows to specify a defined msg.value for the delegate call, reducing
   * the risk that a delegatecall gets executed with more value than intended
   * @return True if the delegate call was successful, false otherwise
   * @return The bytes returned by the delegate call
   **/
  function executeDelegateCall(address target, bytes calldata data)
    external
    payable
    returns (bool, bytes memory);

  /**
   * @notice Allows to receive funds into the executor
   * @dev Useful for actionsSet that needs funds to gets executed
   */
  function receiveFunds() external payable;

  /**
   * @notice Returns the delay (between queuing and execution)
   * @return The value of the delay (in seconds)
   **/
  function getDelay() external view returns (uint256);

  /**
   * @notice Returns the grace period
   * @return The value of the grace period (in seconds)
   **/
  function getGracePeriod() external view returns (uint256);

  /**
   * @notice Returns the minimum delay
   * @return The value of the minimum delay (in seconds)
   **/
  function getMinimumDelay() external view returns (uint256);

  /**
   * @notice Returns the maximum delay
   * @return The value of the maximum delay (in seconds)
   **/
  function getMaximumDelay() external view returns (uint256);

  /**
   * @notice Returns the address of the guardian
   * @return The address of the guardian
   **/
  function getGuardian() external view returns (address);

  /**
   * @notice Returns the total number of actions sets of the executor
   * @return The number of actions sets
   **/
  function getActionsSetCount() external view returns (uint256);

  /**
   * @notice Returns the data of an actions set
   * @param actionsSetId The id of the ActionsSet
   * @return The data of the ActionsSet
   **/
  function getActionsSetById(uint256 actionsSetId) external view returns (ActionsSet memory);

  /**
   * @notice Returns the current state of an actions set
   * @param actionsSetId The id of the ActionsSet
   * @return The current state of theI ActionsSet
   **/
  function getCurrentState(uint256 actionsSetId) external view returns (ActionsSetState);

  /**
   * @notice Returns whether an actions set (by actionHash) is queued
   * @dev actionHash = keccak256(abi.encode(target, value, signature, data, executionTime, withDelegatecall))
   * @param actionHash hash of the action to be checked
   * @return True if the underlying action of actionHash is queued, false otherwise
   **/
  function isActionQueued(bytes32 actionHash) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {IExecutorBase} from './IExecutorBase.sol';

/**
 * @title IL2BridgeExecutorBase
 * @author Aave
 * @notice Defines the basic interface for the L2BridgeExecutor abstract contract
 */
interface IL2BridgeExecutor is IExecutorBase {
  error UnauthorizedEthereumExecutor();

  /**
   * @dev Emitted when the Ethereum Governance Executor is updated
   * @param oldEthereumGovernanceExecutor The address of the old EthereumGovernanceExecutor
   * @param newEthereumGovernanceExecutor The address of the new EthereumGovernanceExecutor
   **/
  event EthereumGovernanceExecutorUpdate(
    address oldEthereumGovernanceExecutor,
    address newEthereumGovernanceExecutor
  );

  /**
   * @notice Queue an ActionsSet
   * @dev If a signature is empty, calldata is used for the execution, calldata is appended to signature otherwise
   * @param targets Array of targets to be called by the actions set
   * @param values Array of values to pass in each call by the actions set
   * @param signatures Array of function signatures to encode in each call by the actions (can be empty)
   * @param calldatas Array of calldata to pass in each call by the actions set
   * @param withDelegatecalls Array of whether to delegatecall for each call of the actions set
   **/
  function queue(
    address[] memory targets,
    uint256[] memory values,
    string[] memory signatures,
    bytes[] memory calldatas,
    bool[] memory withDelegatecalls
  ) external;

  /**
   * @notice Update the address of the Ethereum Governance Executor
   * @param ethereumGovernanceExecutor The address of the new EthereumGovernanceExecutor
   **/
  function updateEthereumGovernanceExecutor(address ethereumGovernanceExecutor) external;

  /**
   * @notice Returns the address of the Ethereum Governance Executor
   * @return The address of the EthereumGovernanceExecutor
   **/
  function getEthereumGovernanceExecutor() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {AaveV3Arbitrum} from 'aave-address-book/AaveV3Arbitrum.sol';
import {IInbox} from 'governance-crosschain-bridges/contracts/dependencies/arbitrum/interfaces/IInbox.sol';
import {IL2BridgeExecutor} from 'governance-crosschain-bridges/contracts/interfaces/IL2BridgeExecutor.sol';

/**
 * @title A generic executor for proposals targeting the arbitrum v3 pool
 * @author BGD Labs
 * @notice You can **only** use this executor when the arbitrum payload has a `execute()` signature without parameters
 * @notice You can **only** use this executor when the arbitrum payload is expected to be executed via `DELEGATECALL`
 * @notice This contract assumes to be called via AAVE Governance V2
 * @notice This contract will assume the SHORT_EXECUTOR will be topped up with enough funds to fund the short executor
 * @dev This executor is a generic wrapper to be used with Arbitrum Inbox (https://developer.offchainlabs.com/arbos/l1-to-l2-messaging)
 * It encodes a parameterless `execute()` with delegate calls and a specified target.
 * This encoded abi is then send to the Inbox to be synced executed on the arbitrum network.
 * Once synced the ARBITRUM_BRIDGE_EXECUTOR will queue the execution of the payload.
 */
contract CrosschainForwarderArbitrum {
  IInbox public constant INBOX =
    IInbox(0x4Dbd4fc535Ac27206064B68FfCf827b0A60BAB3f);
  address public constant ARBITRUM_BRIDGE_EXECUTOR =
    AaveGovernanceV2.ARBITRUM_BRIDGE_EXECUTOR;
  address public constant ARBITRUM_GUARDIAN =
    0xbbd9f90699c1FA0D7A65870D241DD1f1217c96Eb;

  // amount of gwei to overpay on basefee for fast submission
  uint256 public constant BASE_FEE_MARGIN = 10 gwei;

  /**
   * @dev returns the amount of gas needed for relaying the message based on current basefee
   * @param bytesLength the payload bytes length (usually 580)
   */
  function getRequiredGas(uint256 bytesLength) public view returns (uint256) {
    return
      INBOX.calculateRetryableSubmissionFee(
        bytesLength,
        block.basefee + BASE_FEE_MARGIN
      );
  }

  /**
   * @dev checks if the short executor is topped up with enough eth for proposal execution
   * with current basefee
   * @param bytesLength the payload bytes length (usually 580)
   */
  function hasSufficientGasForExecution(uint256 bytesLength)
    public
    view
    returns (bool)
  {
    return (AaveGovernanceV2.SHORT_EXECUTOR.balance >=
      getRequiredGas(bytesLength));
  }

  /**
   * @dev encodes the queue call which is forwarded to arbitrum
   * @param l2PayloadContract the address of the arbitrum payload
   */
  function getEncodedPayload(address l2PayloadContract)
    public
    pure
    returns (bytes memory)
  {
    address[] memory targets = new address[](1);
    targets[0] = l2PayloadContract;
    uint256[] memory values = new uint256[](1);
    values[0] = 0;
    string[] memory signatures = new string[](1);
    signatures[0] = 'execute()';
    bytes[] memory calldatas = new bytes[](1);
    calldatas[0] = '';
    bool[] memory withDelegatecalls = new bool[](1);
    withDelegatecalls[0] = true;
    return
      abi.encodeWithSelector(
        IL2BridgeExecutor.queue.selector,
        targets,
        values,
        signatures,
        calldatas,
        withDelegatecalls
      );
  }

  /**
   * @dev this function will be executed once the proposal passes the mainnet vote.
   * @param l2PayloadContract the arbitrum contract containing the `execute()` signature.
   */
  function execute(address l2PayloadContract) public {
    bytes memory queue = getEncodedPayload(l2PayloadContract);
    uint256 maxSubmission = getRequiredGas(queue.length);
    INBOX.unsafeCreateRetryableTicket{value: maxSubmission}(
      ARBITRUM_BRIDGE_EXECUTOR,
      0, // l2CallValue
      maxSubmission, // maxSubmissionCost
      address(ARBITRUM_BRIDGE_EXECUTOR), // excessFeeRefundAddress
      address(ARBITRUM_GUARDIAN), // callValueRefundAddress
      0, // gasLimit
      0, // maxFeePerGas
      queue
    );
  }
}