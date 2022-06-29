/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

enum JBBallotState {
  Active,
  Approved,
  Failed
}

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

interface IJBFundingCycleBallot is IERC165 {
  function duration() external view returns (uint256);

  function stateOf(
    uint256 _projectId,
    uint256 _configuration,
    uint256 _start
  ) external view returns (JBBallotState);
}

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
  @member ballotRedemptionRate The ballot redemption rate of the funding cycle during which the redemption is being made.
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
  uint256 ballotRedemptionRate;
  string memo;
  bytes metadata;
}

/** 
  @member payer The address from which the payment originated.
  @member projectId The ID of the project for which the payment was made.
  @member currentFundingCycleConfiguration The configuration of the funding cycle during which the payment is being made.
  @member amount The amount of the payment. Includes the token being paid, the value, the number of decimals included, and the currency of the amount.
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
  uint256 projectTokenCount;
  address beneficiary;
  bool preferClaimedTokens;
  string memo;
  bytes metadata;
}

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
                  uint256 projectTokenCount;
                  address beneficiary;
                  bool preferClaimedTokens;
                  string memo;
                  bytes metadata;
  */
  function didPay(JBDidPayData calldata _data) external;
}

/** 
  @member holder The holder of the tokens being redeemed.
  @member projectId The ID of the project with which the redeemed tokens are associated.
  @member currentFundingCycleConfiguration The configuration of the funding cycle during which the redemption is being made.
  @member projectTokenCount The number of project tokens being redeemed.
  @member reclaimedAmount The amount reclaimed from the treasury. Includes the token being reclaimed, the value, the number of decimals included, and the currency of the amount.
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
  address payable beneficiary;
  string memo;
  bytes metadata;
}

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
                address payable beneficiary;
                string memo;
                bytes metadata;
  */
  function didRedeem(JBDidRedeemData calldata _data) external;
}

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
    @return delegate the address of the pay delegate (might or might not be the same contract)
  */
  function payParams(JBPayParamsData calldata _data)
    external
    returns (
      uint256 weight,
      string memory memo,
      IJBPayDelegate delegate
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

    @return reclaimAmount the amount to claim, overriding the terminal logic
    @return memo the memo to override the redeemTokensOf(..) memo
    @return delegate the address of the redemption delegate (might or might not be the same contract)
  */
  function redeemParams(JBRedeemParamsData calldata _data)
    external
    returns (
      uint256 reclaimAmount,
      string memory memo,
      IJBRedemptionDelegate delegate
    );
}

/** 
  @member allowSetTerminals A flag indicating if setting terminals should be allowed during this funding cycle.
  @member allowSetController A flag indicating if setting a new controller should be allowed during this funding cycle.
*/
struct JBGlobalFundingCycleMetadata {
  bool allowSetTerminals;
  bool allowSetController;
}

/** 
  @member global Data used globally in non-migratable ecosystem contracts.
  @member reservedRate The reserved rate of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_RESERVED_RATE`.
  @member redemptionRate The redemption rate of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_REDEMPTION_RATE`.
  @member ballotRedemptionRate The redemption rate to use during an active ballot of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_REDEMPTION_RATE`.
  @member pausePay A flag indicating if the pay functionality should be paused during the funding cycle.
  @member pauseDistributions A flag indicating if the distribute functionality should be paused during the funding cycle.
  @member pauseRedeem A flag indicating if the redeem functionality should be paused during the funding cycle.
  @member pauseBurn A flag indicating if the burn functionality should be paused during the funding cycle.
  @member allowMinting A flag indicating if the mint functionality should be allowed during the funding cycle.
  @member allowChangeToken A flag indicating if changing tokens should be allowed during this funding cycle.
  @member allowTerminalMigration A flag indicating if migrating terminals should be allowed during this funding cycle.
  @member allowControllerMigration A flag indicating if migrating controllers should be allowed during this funding cycle.
  @member holdFees A flag indicating if fees should be held during this funding cycle.
  @member useTotalOverflowForRedemptions A flag indicating if redemptions should use the project's balance held in all terminals instead of the project's local terminal balance from which the redemption is being fulfilled.
  @member useDataSourceForPay A flag indicating if the data source should be used for pay transactions during this funding cycle.
  @member useDataSourceForRedeem A flag indicating if the data source should be used for redeem transactions during this funding cycle.
  @member dataSource The data source to use during this funding cycle.
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
  bool allowChangeToken;
  bool allowTerminalMigration;
  bool allowControllerMigration;
  bool holdFees;
  bool useTotalOverflowForRedemptions;
  bool useDataSourceForPay;
  bool useDataSourceForRedeem;
  address dataSource;
}

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

/** 
  @member group The group indentifier.
  @member splits The splits to associate with the group.
*/
struct JBGroupedSplits {
  uint256 group;
  JBSplit[] splits;
}

/** 
  @member content The metadata content.
  @member domain The domain within which the metadata applies.
*/
struct JBProjectMetadata {
  string content;
  uint256 domain;
}

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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

interface IJBTokenUriResolver {
  function getUri(uint256 _projectId) external view returns (string memory tokenUri);
}

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

interface IJBMigratable {
  function prepForMigrationOf(uint256 _projectId, address _from) external;
}

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

interface IJBToken {
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

  function transferOwnership(uint256 _projectId, address _newOwner) external;
}

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

  event ShouldRequireClaim(uint256 indexed projectId, bool indexed flag, address caller);

  event Change(
    uint256 indexed projectId,
    IJBToken indexed newToken,
    IJBToken indexed oldToken,
    address owner,
    address caller
  );

  event Transfer(
    address indexed holder,
    uint256 indexed projectId,
    address indexed recipient,
    uint256 amount,
    address caller
  );

  function tokenOf(uint256 _projectId) external view returns (IJBToken);

  function projectOf(IJBToken _token) external view returns (uint256);

  function projects() external view returns (IJBProjects);

  function unclaimedBalanceOf(address _holder, uint256 _projectId) external view returns (uint256);

  function unclaimedTotalSupplyOf(uint256 _projectId) external view returns (uint256);

  function totalSupplyOf(uint256 _projectId) external view returns (uint256);

  function balanceOf(address _holder, uint256 _projectId) external view returns (uint256 _result);

  function requireClaimFor(uint256 _projectId) external view returns (bool);

  function issueFor(
    uint256 _projectId,
    string calldata _name,
    string calldata _symbol
  ) external returns (IJBToken token);

  function changeFor(
    uint256 _projectId,
    IJBToken _token,
    address _newOwner
  ) external returns (IJBToken oldToken);

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

  function shouldRequireClaimingFor(uint256 _projectId, bool _flag) external;

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

  function issueTokenFor(
    uint256 _projectId,
    string calldata _name,
    string calldata _symbol
  ) external returns (IJBToken token);

  function changeTokenOf(
    uint256 _projectId,
    IJBToken _token,
    address _newOwner
  ) external;

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

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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

interface IDirectPaymentAddress {
    event Forward(
        address indexed payer,
        uint256 indexed projectId,
        address beneficiary,
        uint256 value,
        string memo,
        bool preferUnstakedTickets
    );

    function terminalDirectory() external returns (ITerminalDirectory);

    function projectId() external returns (uint256);

    function memo() external returns (string memory);
}

interface ITerminalDirectory {
    event DeployAddress(
        uint256 indexed projectId,
        string memo,
        address indexed caller
    );

    event SetTerminal(
        uint256 indexed projectId,
        ITerminal indexed terminal,
        address caller
    );

    event SetPayerPreferences(
        address indexed account,
        address beneficiary,
        bool preferUnstakedTickets
    );

    function projects() external view returns (IProjects);

    function terminalOf(uint256 _projectId) external view returns (ITerminal);

    function beneficiaryOf(address _account) external returns (address);

    function unstakedTicketsPreferenceOf(address _account)
        external
        returns (bool);

    function addressesOf(uint256 _projectId)
        external
        view
        returns (IDirectPaymentAddress[] memory);

    function deployAddress(uint256 _projectId, string calldata _memo) external;

    function setTerminal(uint256 _projectId, ITerminal _terminal) external;

    function setPayerPreferences(
        address _beneficiary,
        bool _preferUnstakedTickets
    ) external;
}

interface ITerminal {
  function terminalDirectory() external view returns (ITerminalDirectory);

  function migrationIsAllowed(ITerminal _terminal) external view returns (bool);

  function pay(
    uint256 _projectId,
    address _beneficiary,
    string calldata _memo,
    bool _preferUnstakedTickets
  ) external payable returns (uint256 fundingCycleId);

  function addToBalance(uint256 _projectId) external payable;

  function allowMigration(ITerminal _contract) external;

  function migrate(uint256 _projectId, ITerminal _to) external;
}

interface IOperatorStore {
    event SetOperator(
        address indexed operator,
        address indexed account,
        uint256 indexed domain,
        uint256[] permissionIndexes,
        uint256 packed
    );

    function permissionsOf(
        address _operator,
        address _account,
        uint256 _domain
    ) external view returns (uint256);

    function hasPermission(
        address _operator,
        address _account,
        uint256 _domain,
        uint256 _permissionIndex
    ) external view returns (bool);

    function hasPermissions(
        address _operator,
        address _account,
        uint256 _domain,
        uint256[] calldata _permissionIndexes
    ) external view returns (bool);

    function setOperator(
        address _operator,
        uint256 _domain,
        uint256[] calldata _permissionIndexes
    ) external;

    function setOperators(
        address[] calldata _operators,
        uint256[] calldata _domains,
        uint256[][] calldata _permissionIndexes
    ) external;
}

interface IProjects is IERC721 {
    event Create(
        uint256 indexed projectId,
        address indexed owner,
        bytes32 indexed handle,
        string uri,
        ITerminal terminal,
        address caller
    );

    event SetHandle(
        uint256 indexed projectId,
        bytes32 indexed handle,
        address caller
    );

    event SetUri(uint256 indexed projectId, string uri, address caller);

    event TransferHandle(
        uint256 indexed projectId,
        address indexed to,
        bytes32 indexed handle,
        bytes32 newHandle,
        address caller
    );

    event ClaimHandle(
        address indexed account,
        uint256 indexed projectId,
        bytes32 indexed handle,
        address caller
    );

    event ChallengeHandle(
        bytes32 indexed handle,
        uint256 challengeExpiry,
        address caller
    );

    event RenewHandle(
        bytes32 indexed handle,
        uint256 indexed projectId,
        address caller
    );

    function count() external view returns (uint256);

    function uriOf(uint256 _projectId) external view returns (string memory);

    function handleOf(uint256 _projectId) external returns (bytes32 handle);

    function projectFor(bytes32 _handle) external returns (uint256 projectId);

    function transferAddressFor(bytes32 _handle)
        external
        returns (address receiver);

    function challengeExpiryOf(bytes32 _handle) external returns (uint256);

    function exists(uint256 _projectId) external view returns (bool);

    function create(
        address _owner,
        bytes32 _handle,
        string calldata _uri,
        ITerminal _terminal
    ) external returns (uint256 id);

    function setHandle(uint256 _projectId, bytes32 _handle) external;

    function setUri(uint256 _projectId, string calldata _uri) external;

    function transferHandle(
        uint256 _projectId,
        address _to,
        bytes32 _newHandle
    ) external returns (bytes32 _handle);

    function claimHandle(
        bytes32 _handle,
        address _for,
        uint256 _projectId
    ) external;
}

interface ITickets is IERC20 {
    function print(address _account, uint256 _amount) external;

    function redeem(address _account, uint256 _amount) external;
}

interface ITicketBooth {
    event Issue(
        uint256 indexed projectId,
        string name,
        string symbol,
        address caller
    );
    event Print(
        address indexed holder,
        uint256 indexed projectId,
        uint256 amount,
        bool convertedTickets,
        bool preferUnstakedTickets,
        address controller
    );

    event Redeem(
        address indexed holder,
        uint256 indexed projectId,
        uint256 amount,
        uint256 stakedTickets,
        bool preferUnstaked,
        address controller
    );

    event Stake(
        address indexed holder,
        uint256 indexed projectId,
        uint256 amount,
        address caller
    );

    event Unstake(
        address indexed holder,
        uint256 indexed projectId,
        uint256 amount,
        address caller
    );

    event Lock(
        address indexed holder,
        uint256 indexed projectId,
        uint256 amount,
        address caller
    );

    event Unlock(
        address indexed holder,
        uint256 indexed projectId,
        uint256 amount,
        address caller
    );

    event Transfer(
        address indexed holder,
        uint256 indexed projectId,
        address indexed recipient,
        uint256 amount,
        address caller
    );

    function ticketsOf(uint256 _projectId) external view returns (ITickets);

    function projects() external view returns (IProjects);

    function lockedBalanceOf(address _holder, uint256 _projectId)
        external
        view
        returns (uint256);

    function lockedBalanceBy(
        address _operator,
        address _holder,
        uint256 _projectId
    ) external view returns (uint256);

    function stakedBalanceOf(address _holder, uint256 _projectId)
        external
        view
        returns (uint256);

    function stakedTotalSupplyOf(uint256 _projectId)
        external
        view
        returns (uint256);

    function totalSupplyOf(uint256 _projectId) external view returns (uint256);

    function balanceOf(address _holder, uint256 _projectId)
        external
        view
        returns (uint256 _result);

    function issue(
        uint256 _projectId,
        string calldata _name,
        string calldata _symbol
    ) external;

    function print(
        address _holder,
        uint256 _projectId,
        uint256 _amount,
        bool _preferUnstakedTickets
    ) external;

    function redeem(
        address _holder,
        uint256 _projectId,
        uint256 _amount,
        bool _preferUnstaked
    ) external;

    function stake(
        address _holder,
        uint256 _projectId,
        uint256 _amount
    ) external;

    function unstake(
        address _holder,
        uint256 _projectId,
        uint256 _amount
    ) external;

    function lock(
        address _holder,
        uint256 _projectId,
        uint256 _amount
    ) external;

    function unlock(
        address _holder,
        uint256 _projectId,
        uint256 _amount
    ) external;

    function transfer(
        address _holder,
        uint256 _projectId,
        uint256 _amount,
        address _recipient
    ) external;
}

interface IJBV1TokenPaymentTerminal {
  event SetV1ProjectId(uint256 indexed projectId, uint256 indexed v1ProjectId, address caller);

  event Pay(
    uint256 indexed projectId,
    address payer,
    address beneficiary,
    uint256 amount,
    uint256 beneficiaryTokenCount,
    string memo,
    address caller
  );

  event ReleaseV1TokensOf(
    uint256 indexed projectId,
    address indexed beneficiary,
    uint256 unclaimedBalance,
    uint256 claimedBalance,
    address caller
  );

  function ticketBooth() external view returns (ITicketBooth);

  function directory() external view returns (IJBDirectory);

  function projects() external view returns (IJBProjects);

  function v1ProjectIdOf(uint256 _projectId) external view returns (uint256);

  function finalized(uint256 _projectId) external view returns (bool);

  function setV1ProjectIdOf(uint256 _projectId, uint256 _v1ProjectId) external;

  function releaseV1TokensOf(uint256 _projectId, address _beneficiary) external;
}

/** 
  @title 
  JBV1TokenPaymentTerminal

  @notice 
  Allows project owners to specify the v1 project token that they are willing to accept from holders in exchange for their v2 project token. 

  @dev
  Project owners must add this terminal to their list of set terminals in the JBDirectory so that it can mint tokens on the project's behalf.

  @dev
  Project owners must initialize their v1 token they are willing to swap at a rate of 1:1.

  @dev
  Project owners can finalize and stop v1 to v2 token swaps at any time, at which point they can withdraw the v1 tokens locked in this contract.

  @dev
  Adheres to -
  IJBV1TokenPaymentTerminal: General interface for the methods in this contract that interact with the blockchain's state according to the protocol's rules.
  IJBPaymentTerminal: Standardized interface for project to receive payments.

  @dev
  Inherits from -
  ERC165: Introspection on interface adherance. 
*/
contract JBV1TokenPaymentTerminal is IJBV1TokenPaymentTerminal, IJBPaymentTerminal, ERC165 {
  //*********************************************************************//
  // --------------------------- custom errors ------------------------- //
  //*********************************************************************//
  error INSUFFICIENT_FUNDS();
  error INVALID_AMOUNT();
  error MIGRATION_TERMINATED();
  error NO_MSG_VALUE_ALLOWED();
  error NOT_ALLOWED();
  error NOT_SUPPORTED();
  error PROJECT_TERMINAL_MISMATCH();
  error UNEXPECTED_AMOUNT();
  error V1_PROJECT_NOT_SET();

  //*********************************************************************//
  // ---------------------------- modifiers ---------------------------- //
  //*********************************************************************//

  /** 
    @notice 
    A modifier that verifies this terminal is a terminal of provided project ID.
  */
  modifier isTerminalOf(uint256 _projectId) {
    if (!directory.isTerminalOf(_projectId, this)) revert PROJECT_TERMINAL_MISMATCH();
    _;
  }

  //*********************************************************************//
  // ---------------- public immutable stored properties --------------- //
  //*********************************************************************//

  /**
    @notice
    Mints ERC-721's that represent project ownership and transfers.
  */
  IJBProjects public immutable override projects;

  /**
    @notice
    The directory of terminals and controllers for projects.
  */
  IJBDirectory public immutable override directory;

  /**
    @notice
    The V1 contract where token balances are stored.
  */
  ITicketBooth public immutable override ticketBooth;

  //*********************************************************************//
  // --------------------- public stored properties -------------------- //
  //*********************************************************************//

  /** 
    @notice 
    The v1 project ID for a v2 project.

    _projectId The ID of the v2 project to exchange tokens for. 
  */
  mapping(uint256 => uint256) public override v1ProjectIdOf;

  /** 
    @notice 
    A flag indicating if a project's migration has finished.

    _projectId The ID of the project to check the migration status.
  */
  mapping(uint256 => bool) public override finalized;

  /** 
    @notice
    A flag indicating if this terminal accepts the specified token.

    @param _token The token to check if this terminal accepts or not.
    @param _projectId The project ID to check for token acceptance.

    @return The flag.
  */
  function acceptsToken(address _token, uint256 _projectId) external view override returns (bool) {
    _token; // Prevents unused var compiler and natspec complaints.
    _projectId; // Prevents unused var compiler and natspec complaints.

    // Get a reference to the V1 project for the provided project ID.
    uint256 _v1ProjectId = v1ProjectIdOf[_projectId];

    // Accept the token if it has been set and the exchange hasn't yet finalized.
    return address(ticketBooth.ticketsOf(_v1ProjectId)) == _token && !finalized[_v1ProjectId];
  }

  /** 
    @notice
    The decimals that should be used in fixed number accounting for the specified token.

    @param _token The token to check for the decimals of.

    @return The number of decimals for the token.
  */
  function decimalsForToken(address _token) external pure override returns (uint256) {
    _token; // Prevents unused var compiler and natspec complaints.

    // V1 tokens are always 18 decimals.
    return 18;
  }

  /** 
    @notice
    The currency that should be used for the specified token.

    @param _token The token to check for the currency of.

    @return The currency index.
  */
  function currencyForToken(address _token) external pure override returns (uint256) {
    _token; // Prevents unused var compiler and natspec complaints.

    // There's no currency for the token.
    return 0;
  }

  /**
    @notice
    Gets the current overflowed amount in this terminal for a specified project, in terms of ETH.

    @dev
    The current overflow is represented as a fixed point number with 18 decimals.

    @param _projectId The ID of the project to get overflow for.

    @return The current amount of ETH overflow that project has in this terminal, as a fixed point number with 18 decimals.
  */
  function currentEthOverflowOf(uint256 _projectId) external pure override returns (uint256) {
    _projectId; // Prevents unused var compiler and natspec complaints.

    // This terminal has no overflow.
    return 0;
  }

  /**
    @notice
    Indicates if this contract adheres to the specified interface.

    @dev 
    See {IERC165-supportsInterface}.

    @param _interfaceId The ID of the interface to check for adherance to.
  */
  function supportsInterface(bytes4 _interfaceId)
    public
    view
    override(ERC165, IERC165)
    returns (bool)
  {
    return
      _interfaceId == type(IJBPaymentTerminal).interfaceId ||
      _interfaceId == type(IJBV1TokenPaymentTerminal).interfaceId ||
      super.supportsInterface(_interfaceId);
  }

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  /**
    @param _projects A contract which mints ERC-721's that represent project ownership and transfers.
    @param _directory A contract storing directories of terminals and controllers for each project.
    @param _ticketBooth The V1 contract where tokens are stored.
  */
  constructor(
    IJBProjects _projects,
    IJBDirectory _directory,
    ITicketBooth _ticketBooth
  ) {
    projects = _projects;
    directory = _directory;
    ticketBooth = _ticketBooth;
  }

  //*********************************************************************//
  // ---------------------- external transactions ---------------------- //
  //*********************************************************************//

  /** 
    @notice 
    Allows a project owner to initialize the acceptance of a v1 project's tokens in exchange for its v2 project token.

    @dev
    Only a project owner can initiate token migration.

    @param _projectId The ID of the v2 project to set a v1 project ID for.
    @param _v1ProjectId The ID of the v1 project to set.
  */
  function setV1ProjectIdOf(uint256 _projectId, uint256 _v1ProjectId) external override {
    // Can't set the v1 project ID if it isn't owned by the same address who owns the v2 project.
    if (
      msg.sender != projects.ownerOf(_projectId) ||
      msg.sender != ticketBooth.projects().ownerOf(_v1ProjectId)
    ) revert NOT_ALLOWED();

    // Store the mapping.
    v1ProjectIdOf[_projectId] = _v1ProjectId;

    emit SetV1ProjectId(_projectId, _v1ProjectId, msg.sender);
  }

  /** 
    @notice 
    Allows a v1 project token holder to pay into this terminal to get commensurate about of its v2 token.

    @param _projectId The ID of the v2 project to pay towards.
    @param _amount The amount of v1 project tokens being paid, as a fixed point number with the same amount of decimals as this terminal.
    @param _token The token being paid. This terminal ignores this property since it only manages v1 tokens preset by the project being paid. 
    @param _beneficiary The address to mint v2 project tokens for.
    @param _minReturnedTokens The minimum number of v2 project tokens expected in return, as a fixed point number with 18 decimals.
    @param _preferClaimedTokens A flag indicating whether the request prefers to mint v2 project tokens into the beneficiaries wallet rather than leaving them unclaimed. This is only possible if the project has an attached token contract. Leaving them unclaimed saves gas.
    @param _memo A memo to pass along to the emitted event. 
    @param _metadata Bytes to send along to the data source, delegate, and emitted event, if provided. This terminal ignores this property because there's no data source.

    @return beneficiaryTokenCount The number of v2 tokens minted for the beneficiary, as a fixed point number with 18 decimals.
  */
  function pay(
    uint256 _projectId,
    uint256 _amount,
    address _token,
    address _beneficiary,
    uint256 _minReturnedTokens,
    bool _preferClaimedTokens,
    string calldata _memo,
    bytes calldata _metadata
  ) external payable override isTerminalOf(_projectId) returns (uint256 beneficiaryTokenCount) {
    _token; // Prevents unused var compiler and natspec complaints.
    _metadata; // Prevents unused var compiler and natspec complaints.

    // Make sure the migration hasn't already been finalized.
    if (finalized[_projectId]) revert MIGRATION_TERMINATED();

    // Make sure an amount is specified.
    if (_amount == 0) revert INVALID_AMOUNT();

    // Make sure no ETH was sent.
    if (msg.value > 0) revert NO_MSG_VALUE_ALLOWED();

    return _pay(_projectId, _amount, _beneficiary, _minReturnedTokens, _preferClaimedTokens, _memo);
  }

  /** 
    @notice
    Allows a project owner to gain custody of all the v1 tokens that have been paid, after they have finalized the ability for v1 token holders to convert to v2 tokens via this contract.

    @param _v1ProjectId The ID of the v1 project whose tokens are being released.
    @param _beneficiary The address that the tokens are being sent to.
  */
  function releaseV1TokensOf(uint256 _v1ProjectId, address _beneficiary) external override {
    // Make sure only the v1 project owner can retrieve the tokens.
    if (msg.sender != ticketBooth.projects().ownerOf(_v1ProjectId)) revert NOT_ALLOWED();

    // Make sure v1 token conversion has not yet finalized.
    if (finalized[_v1ProjectId]) revert MIGRATION_TERMINATED();

    // Get a reference to the v1 project's ERC20 tokens.
    ITickets _v1Token = ticketBooth.ticketsOf(_v1ProjectId);

    // Get a reference to this terminal's unclaimed balance.
    uint256 _unclaimedBalance = ticketBooth.stakedBalanceOf(address(this), _v1ProjectId);

    // Get a reference to this terminal's ERC20 balance.
    uint256 _erc20Balance = _v1Token == ITickets(address(0))
      ? 0
      : _v1Token.balanceOf(address(this));

    // Store the finalized state.
    finalized[_v1ProjectId] = true;

    // Transfer ERC20 v1 tokens to the beneficiary.
    if (_erc20Balance != 0) _v1Token.transfer(_beneficiary, _erc20Balance);

    // Transfer unclaimed v1 tokens to the beneficiary.
    if (_unclaimedBalance != 0)
      ticketBooth.transfer(address(this), _v1ProjectId, _unclaimedBalance, _beneficiary);

    emit ReleaseV1TokensOf(
      _v1ProjectId,
      _beneficiary,
      _unclaimedBalance,
      _erc20Balance,
      msg.sender
    );
  }

  /**
    @notice
    Receives funds belonging to the specified project.

    @dev 
    This terminal does not allow adding directly to a project's balance.

    @param _projectId The ID of the project to which the funds received belong. This is ignored since this terminal doesn't allow this function.
    @param _amount The amount of tokens to add, as a fixed point number with the same number of decimals as this terminal. This is ignored since this terminal doesn't allow this function.
    @param _token The token being paid. This terminal ignores this property since it only manages one currency. This is ignored since this terminal doesn't allow this function.
    @param _memo A memo to pass along to the emitted event. This is ignored since this terminal doesn't allow this function.
    @param _metadata Extra data to pass along to the emitted event. This is ignored since this terminal doesn't allow this function.
  */
  function addToBalanceOf(
    uint256 _projectId,
    uint256 _amount,
    address _token,
    string calldata _memo,
    bytes calldata _metadata
  ) external payable override {
    _projectId; // Prevents unused var compiler and natspec complaints.
    _amount; // Prevents unused var compiler and natspec complaints.
    _token; // Prevents unused var compiler and natspec complaints.
    _memo; // Prevents unused var compiler and natspec complaints.
    _metadata; // Prevents unused var compiler and natspec complaints.

    revert NOT_SUPPORTED();
  }

  //*********************************************************************//
  // ------------------------ internal functions ----------------------- //
  //*********************************************************************//

  /** 
    @notice 
    Allows a v1 project token holder to pay into this terminal to get commensurate about of its v2 token.

    @param _projectId The ID of the v2 project to pay towards.
    @param _amount The amount of v1 project tokens being paid, as a fixed point number with the same amount of decimals as this terminal.
    @param _beneficiary The address to mint tokens for.
    @param _minReturnedTokens The minimum number of v2 project tokens expected in return, as a fixed point number with the same amount of decimals as this terminal.
    @param _preferClaimedTokens A flag indicating whether the request prefers to mint v2 project tokens into the beneficiaries wallet rather than leaving them unclaimed. This is only possible if the project has an attached token contract. Leaving them unclaimed saves gas.
    @param _memo A memo to pass along to the emitted event. 

    @return beneficiaryTokenCount The number of v2 tokens minted for the beneficiary, as a fixed point number with 18 decimals.
  */
  function _pay(
    uint256 _projectId,
    uint256 _amount,
    address _beneficiary,
    uint256 _minReturnedTokens,
    bool _preferClaimedTokens,
    string calldata _memo
  ) internal returns (uint256 beneficiaryTokenCount) {
    // Get the v1 project for the v2 project being paid.
    uint256 _v1ProjectId = v1ProjectIdOf[_projectId];

    // Make sure the v1 project has been set.
    if (_v1ProjectId == 0) revert V1_PROJECT_NOT_SET();

    // Get a reference to the v1 project's ERC20 tokens.
    ITickets _v1Token = ticketBooth.ticketsOf(_v1ProjectId);

    // Define variables that will be needed outside the scoped section below.
    // Keep a reference to the amount of v2 tokens to mint from the message sender's v1 ERC20 balance.
    uint256 _tokensToMintFromERC20s;

    {
      // Get a reference to the migrator's unclaimed balance.
      uint256 _unclaimedBalance = ticketBooth.stakedBalanceOf(msg.sender, _v1ProjectId);

      // Get a reference to the migrator's ERC20 balance.
      uint256 _erc20Balance = _v1Token == ITickets(address(0)) ? 0 : _v1Token.balanceOf(msg.sender);

      // There must be enough v1 tokens to migrate.
      if (_amount > _erc20Balance + _unclaimedBalance) revert INSUFFICIENT_FUNDS();

      // If there's no ERC20 balance, theres no tokens to mint as a result of the ERC20 balance.
      if (_erc20Balance == 0)
        _tokensToMintFromERC20s = 0;
        // If prefer claimed tokens, exchange ERC20 tokens before exchanging unclaimed tokens.
      else if (_preferClaimedTokens)
        _tokensToMintFromERC20s = _erc20Balance < _amount ? _erc20Balance : _amount;
        // Otherwise, exchange unclaimed tokens before ERC20 tokens.
      else _tokensToMintFromERC20s = _unclaimedBalance < _amount ? _amount - _unclaimedBalance : 0;
    }

    // The amount of unclaimed tokens to migrate.
    uint256 _tokensToMintFromUnclaimedBalance = _amount - _tokensToMintFromERC20s;

    // Transfer v1 ERC20 tokens to this terminal from the msg sender if needed.
    if (_tokensToMintFromERC20s != 0)
      IERC20(_v1Token).transferFrom(msg.sender, address(this), _tokensToMintFromERC20s);

    // Transfer v1 unclaimed tokens to this terminal from the msg sender if needed.
    if (_tokensToMintFromUnclaimedBalance != 0)
      ticketBooth.transfer(
        msg.sender,
        _v1ProjectId,
        _tokensToMintFromUnclaimedBalance,
        address(this)
      );

    // Mint the v2 tokens for the beneficary.
    beneficiaryTokenCount = IJBController(directory.controllerOf(_projectId)).mintTokensOf(
      _projectId,
      _amount,
      _beneficiary,
      '',
      _preferClaimedTokens,
      false
    );

    // Make sure the token amount is the same as the v1 token amount and is at least what is expected.
    if (beneficiaryTokenCount != _amount || beneficiaryTokenCount < _minReturnedTokens)
      revert UNEXPECTED_AMOUNT();

    emit Pay(
      _projectId,
      msg.sender,
      _beneficiary,
      _amount,
      beneficiaryTokenCount,
      _memo,
      msg.sender
    );
  }
}