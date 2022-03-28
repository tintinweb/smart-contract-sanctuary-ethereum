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

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "prb-math/contracts/PRBMath.sol";

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@paulrberg/contracts/math/PRBMath.sol';
import './interfaces/IJBPaymentTerminalStore.sol';
import './libraries/JBConstants.sol';
import './libraries/JBCurrencies.sol';
import './libraries/JBOperations.sol';
import './libraries/JBSplitsGroups.sol';
import './libraries/JBFundingCycleMetadataResolver.sol';
import './libraries/JBFixedPointNumber.sol';

//*********************************************************************//
// --------------------------- custom errors ------------------------- //
//*********************************************************************//
error CURRENCY_MISMATCH();
error DISTRIBUTION_AMOUNT_LIMIT_REACHED();
error FUNDING_CYCLE_PAYMENT_PAUSED();
error FUNDING_CYCLE_DISTRIBUTION_PAUSED();
error FUNDING_CYCLE_REDEEM_PAUSED();
error INADEQUATE_CONTROLLER_ALLOWANCE();
error INADEQUATE_PAYMENT_TERMINAL_STORE_BALANCE();
error INSUFFICIENT_TOKENS();
error INVALID_FUNDING_CYCLE();
error PAYMENT_TERMINAL_MIGRATION_NOT_ALLOWED();
error PAYMENT_TERMINAL_UNAUTHORIZED();
error STORE_ALREADY_CLAIMED();

/**
  @notice
  Manages all bookkeeping for inflows and outflows of funds from any IJBPaymentTerminal.

  @dev
  Adheres to:
  IJBPaymentTerminalStore: General interface for the methods in this contract that interact with the blockchain's state according to the protocol's rules.

  @dev
  Inherits from:
  ReentrancyGuard: Contract module that helps prevent reentrant calls to a function.
*/
contract JBPaymentTerminalStore is IJBPaymentTerminalStore, ReentrancyGuard {
  // A library that parses the packed funding cycle metadata into a friendlier format.
  using JBFundingCycleMetadataResolver for JBFundingCycle;

  /**
    @notice
    Ensures a maximum number of decimal points of persisted fidelity on mulDiv operations of fixed point numbers. 
  */
  uint256 private constant _MAX_FIXED_POINT_FIDELITY = 18;

  //*********************************************************************//
  // ---------------- public immutable stored properties --------------- //
  //*********************************************************************//

  /**
    @notice
    The directory of terminals and controllers for projects.
  */
  IJBDirectory public immutable override directory;

  /**
    @notice
    The contract storing all funding cycle configurations.
  */
  IJBFundingCycleStore public immutable override fundingCycleStore;

  /**
    @notice
    The contract that exposes price feeds.
  */
  IJBPrices public immutable override prices;

  //*********************************************************************//
  // --------------------- public stored properties -------------------- //
  //*********************************************************************//

  /**
    @notice
    The amount of tokens that each project has for each terminal, in terms of the terminal's token.

    @dev
    The used distribution limit is represented as a fixed point number with the same amount of decimals as its relative terminal.

    _terminal The terminal to which the balance applies.
    _projectId The ID of the project to get the balance of.
  */
  mapping(IJBPaymentTerminal => mapping(uint256 => uint256)) public override balanceOf;

  /**
    @notice
    The amount of funds that a project has distributed from its limit during the current funding cycle for each terminal, in terms of the distribution limit's currency.

    @dev
    Increases as projects use their preconfigured distribution limits.

    @dev
    The used distribution limit is represented as a fixed point number with the same amount of decimals as its relative terminal.

    _terminal The terminal to which the used distribution limit applies.
    _projectId The ID of the project to get the used distribution limit of.
    _fundingCycleNumber The number of the funding cycle during which the distribution limit was used.
  */
  mapping(IJBPaymentTerminal => mapping(uint256 => mapping(uint256 => uint256)))
    public
    override usedDistributionLimitOf;

  /**
    @notice
    The amount of funds that a project has used from its allowance during the current funding cycle configuration for each terminal, in terms of the overflow allowance's currency.

    @dev
    Increases as projects use their allowance.

    @dev
    The used allowance limit is represented as a fixed point number with the same amount of decimals as its relative terminal.

    _terminal The terminal to which the overflow allowance applies.
    _projectId The ID of the project to get the used overflow allowance of.
    _configuration The configuration of the during which the allowance was used.
  */
  mapping(IJBPaymentTerminal => mapping(uint256 => mapping(uint256 => uint256)))
    public
    override usedOverflowAllowanceOf;

  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  /**
    @notice
    Gets the current overflowed amount in a terminal for a specified project.

    @dev
    The current overflow is represented as a fixed point number with the same amount of decimals as the specified terminal.

    @param _terminal The terminal for which the overflow is being calculated.
    @param _projectId The ID of the project to get overflow for.

    @return The current amount of overflow that project has in the specified terminal.
  */
  function currentOverflowOf(IJBPaymentTerminal _terminal, uint256 _projectId)
    external
    view
    override
    returns (uint256)
  {
    // Return the overflow during the project's current funding cycle.
    return
      _overflowDuring(
        _terminal,
        _projectId,
        fundingCycleStore.currentOf(_projectId),
        _terminal.currency()
      );
  }

  /**
    @notice
    Gets the current overflowed amount for a specified project across all terminals.

    @param _projectId The ID of the project to get total overflow for.
    @param _decimals The number of decimals that the fixed point overflow should include.
    @param _currency The currency that the total overflow should be in terms of.

    @return The current total amount of overflow that project has across all terminals.
  */
  function currentTotalOverflowOf(
    uint256 _projectId,
    uint256 _decimals,
    uint256 _currency
  ) external view override returns (uint256) {
    return _currentTotalOverflowOf(_projectId, _decimals, _currency);
  }

  /**
    @notice
    The current amount of overflowed tokens from a terminal that can be reclaimed by the specified number of tokens, using the total token supply and overflow in the ecosystem.

    @dev 
    If the project has an active funding cycle reconfiguration ballot, the project's ballot redemption rate is used.

    @dev
    The current reclaimable overflow is returned in terms of the specified terminal's currency.

    @dev
    The reclaimable overflow is represented as a fixed point number with the same amount of decimals as the specified terminal.

    @param _terminal The terminal from which the reclaimable amount would come.
    @param _projectId The ID of the project to get the reclaimable overflow amount for.
    @param _tokenCount The number of tokens to make the calculation with, as a fixed point number with 18 decimals.
    @param _useTotalOverflow A flag indicating whether the overflow used in the calculation should be summed from all of the project's terminals. If false, overflow should be limited to the amount in the specified `_terminal`.

    @return The amount of overflowed tokens that can be reclaimed, as a fixed point number with the same number of decimals as the provided `_terminal`.
  */
  function currentReclaimableOverflowOf(
    IJBPaymentTerminal _terminal,
    uint256 _projectId,
    uint256 _tokenCount,
    bool _useTotalOverflow
  ) external view override returns (uint256) {
    // Get a reference to the project's current funding cycle.
    JBFundingCycle memory _fundingCycle = fundingCycleStore.currentOf(_projectId);

    // Get the amount of current overflow.
    // Use the project's total overflow across all of its terminals if the flag species specifies so. Otherwise, use the overflow local to the specified terminal.
    uint256 _currentOverflow = _useTotalOverflow
      ? _currentTotalOverflowOf(_projectId, _terminal.decimals(), _terminal.currency())
      : _overflowDuring(_terminal, _projectId, _fundingCycle, _terminal.currency());

    // If there's no overflow, there's no reclaimable overflow.
    if (_currentOverflow == 0) return 0;

    // Get the number of outstanding tokens the project has.
    uint256 _totalSupply = directory.controllerOf(_projectId).totalOutstandingTokensOf(
      _projectId,
      _fundingCycle.reservedRate()
    );

    // Return the reclaimable overflow amount.
    return
      _reclaimableOverflowDuring(
        _projectId,
        _fundingCycle,
        _tokenCount,
        _totalSupply,
        _currentOverflow
      );
  }

  /**
    @notice
    The current amount of overflowed tokens from a terminal that can be reclaimed by the specified number of tokens, using the specified total token supply and overflow amounts.

    @dev 
    If the project has an active funding cycle reconfiguration ballot, the project's ballot redemption rate is used.

    @param _projectId The ID of the project to get the reclaimable overflow amount for.
    @param _tokenCount The number of tokens to make the calculation with, as a fixed point number with 18 decimals.
    @param _totalSupply The total number of tokens to make the calculation with, as a fixed point number with 18 decimals.
    @param _overflow The amount of overflow to make the calculation with, as a fixed point number.

    @return The amount of overflowed tokens that can be reclaimed, as a fixed point number with the same number of decimals as the provided `_overflow`.
  */
  function currentReclaimableOverflowOf(
    uint256 _projectId,
    uint256 _tokenCount,
    uint256 _totalSupply,
    uint256 _overflow
  ) external view override returns (uint256) {
    // If there's no overflow, there's no reclaimable overflow.
    if (_overflow == 0) return 0;

    // Get a reference to the project's current funding cycle.
    JBFundingCycle memory _fundingCycle = fundingCycleStore.currentOf(_projectId);

    // Return the reclaimable overflow amount.
    return
      _reclaimableOverflowDuring(_projectId, _fundingCycle, _tokenCount, _totalSupply, _overflow);
  }

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  /**
    @param _prices A contract that exposes price feeds.
    @param _directory A contract storing directories of terminals and controllers for each project.
    @param _fundingCycleStore A contract storing all funding cycle configurations.
  */
  constructor(
    IJBPrices _prices,
    IJBDirectory _directory,
    IJBFundingCycleStore _fundingCycleStore
  ) {
    prices = _prices;
    directory = _directory;
    fundingCycleStore = _fundingCycleStore;
  }

  //*********************************************************************//
  // ---------------------- external transactions ---------------------- //
  //*********************************************************************//

  /**
    @notice
    Records newly contributed tokens to a project.

    @dev
    Mint's the project's tokens according to values provided by a configured data source. If no data source is configured, mints tokens proportional to the amount of the contribution.

    @dev
    The msg.sender must be an IJBPaymentTerminal. The amount specified in the params is in terms of the msg.sender's tokens.

    @param _payer The original address that sent the payment to the terminal.
    @param _amount The amount of tokens being paid. Includes the token being paid, the value, the number of decimals included, and the currency of the amount.
    @param _projectId The ID of the project being paid.
    @param _baseWeightCurrency The currency to base token issuance on.
    @param _memo A memo to pass along to the emitted event, and passed along to the funding cycle's data source.
    @param _metadata Bytes to send along to the data source, if one is provided.

    @return fundingCycle The project's funding cycle during which payment was made.
    @return tokenCount The number of project tokens that were minted, as a fixed point number with 18 decimals.
    @return delegate A delegate contract to use for subsequent calls.
    @return memo A memo that should be passed along to the emitted event.
  */
  function recordPaymentFrom(
    address _payer,
    JBTokenAmount calldata _amount,
    uint256 _projectId,
    uint256 _baseWeightCurrency,
    string calldata _memo,
    bytes calldata _metadata
  )
    external
    override
    nonReentrant
    returns (
      JBFundingCycle memory fundingCycle,
      uint256 tokenCount,
      IJBPayDelegate delegate,
      string memory memo
    )
  {
    // Get a reference to the current funding cycle for the project.
    fundingCycle = fundingCycleStore.currentOf(_projectId);

    // The project must have a funding cycle configured.
    if (fundingCycle.number == 0) revert INVALID_FUNDING_CYCLE();

    // Must not be paused.
    if (fundingCycle.payPaused()) revert FUNDING_CYCLE_PAYMENT_PAUSED();

    // The weight according to which new token supply is to be minted, as a fixed point number with 18 decimals.
    uint256 _weight;

    // If the funding cycle has configured a data source, use it to derive a weight and memo.
    if (fundingCycle.useDataSourceForPay()) {
      // Create the params that'll be sent to the data source.
      JBPayParamsData memory _data = JBPayParamsData(
        IJBPaymentTerminal(msg.sender),
        _payer,
        _amount,
        _projectId,
        fundingCycle.weight,
        fundingCycle.reservedRate(),
        _memo,
        _metadata
      );
      (_weight, memo, delegate) = fundingCycle.dataSource().payParams(_data);
    }
    // Otherwise use the funding cycle's weight
    else {
      _weight = fundingCycle.weight;
      memo = _memo;
    }

    // If there's no amount being recorded, there's nothing left to do.
    if (_amount.value == 0) return (fundingCycle, 0, delegate, memo);

    // Add the amount to the token balance of the project.
    balanceOf[IJBPaymentTerminal(msg.sender)][_projectId] =
      balanceOf[IJBPaymentTerminal(msg.sender)][_projectId] +
      _amount.value;

    // If there's no weight, token count must be 0 so there's nothing left to do.
    if (_weight == 0) return (fundingCycle, 0, delegate, memo);

    // Get a reference to the number of decimals in the amount. (prevents stack too deep).
    uint256 _decimals = _amount.decimals;

    // If the terminal should base its weight on a different currency from the terminal's currency, determine the factor.
    // The weight is always a fixed point mumber with 18 decimals. To ensure this, the ratio should use the same number of decimals as the `_amount`.
    uint256 _weightRatio = _amount.currency == _baseWeightCurrency
      ? 10**_decimals
      : prices.priceFor(_amount.currency, _baseWeightCurrency, _decimals);

    // Find the number of tokens to mint, as a fixed point number with as many decimals as `weight` has.
    tokenCount = PRBMath.mulDiv(_amount.value, _weight, _weightRatio);
  }

  /**
    @notice
    Records newly redeemed tokens of a project.

    @dev
    Redeems the project's tokens according to values provided by a configured data source. If no data source is configured, redeems tokens along a redemption bonding curve that is a function of the number of tokens being burned.

    @dev
    The msg.sender must be an IJBPaymentTerminal. The amount specified in the params is in terms of the msg.senders tokens.

    @param _holder The account that is having its tokens redeemed.
    @param _projectId The ID of the project to which the tokens being redeemed belong.
    @param _tokenCount The number of project tokens to redeem, as a fixed point number with 18 decimals.
    @param _balanceDecimals The amount of decimals expected in the returned `reclaimAmount`.
    @param _balanceCurrency The currency that the returned `reclaimAmount` is expected to be in terms of.
    @param _memo A memo to pass along to the emitted event.
    @param _metadata Bytes to send along to the data source, if one is provided.

    @return fundingCycle The funding cycle during which the redemption was made.
    @return reclaimAmount The amount of terminal tokens reclaimed, as a fixed point number with 18 decimals.
    @return delegate A delegate contract to use for subsequent calls.
    @return memo A memo that should be passed along to the emitted event.
  */
  function recordRedemptionFor(
    address _holder,
    uint256 _projectId,
    uint256 _tokenCount,
    uint256 _balanceDecimals,
    uint256 _balanceCurrency,
    string memory _memo,
    bytes memory _metadata
  )
    external
    override
    nonReentrant
    returns (
      JBFundingCycle memory fundingCycle,
      uint256 reclaimAmount,
      IJBRedemptionDelegate delegate,
      string memory memo
    )
  {
    // Get a reference to the project's current funding cycle.
    fundingCycle = fundingCycleStore.currentOf(_projectId);

    // The current funding cycle must not be paused.
    if (fundingCycle.redeemPaused()) revert FUNDING_CYCLE_REDEEM_PAUSED();

    // Scoped section prevents stack too deep. `_currentOverflow`, `_totalSupply`, and `_data` only used within scope.
    {
      // Get the amount of current overflow.
      // Use the local overflow if the funding cycle specifies that it should be used. Otherwise, use the project's total overflow across all of its terminals.
      uint256 _currentOverflow = fundingCycle.useTotalOverflowForRedemptions()
        ? _currentTotalOverflowOf(_projectId, _balanceDecimals, _balanceCurrency)
        : _overflowDuring(
          IJBPaymentTerminal(msg.sender),
          _projectId,
          fundingCycle,
          _balanceCurrency
        );

      // Get the number of outstanding tokens the project has.
      uint256 _totalSupply = directory.controllerOf(_projectId).totalOutstandingTokensOf(
        _projectId,
        fundingCycle.reservedRate()
      );

      if (_currentOverflow > 0)
        // Calculate reclaim amount using the current overflow amount.
        reclaimAmount = _reclaimableOverflowDuring(
          _projectId,
          fundingCycle,
          _tokenCount,
          _totalSupply,
          _currentOverflow
        );

      // If the funding cycle has configured a data source, use it to derive a claim amount and memo.
      if (fundingCycle.useDataSourceForRedeem()) {
        // Create the params that'll be sent to the data source.
        JBRedeemParamsData memory _data = JBRedeemParamsData(
          IJBPaymentTerminal(msg.sender),
          _holder,
          _projectId,
          _tokenCount,
          _totalSupply,
          _currentOverflow,
          _balanceDecimals,
          _balanceCurrency,
          reclaimAmount,
          fundingCycle.useTotalOverflowForRedemptions(),
          fundingCycle.redemptionRate(),
          fundingCycle.ballotRedemptionRate(),
          _memo,
          _metadata
        );
        (reclaimAmount, memo, delegate) = fundingCycle.dataSource().redeemParams(_data);
      } else {
        memo = _memo;
      }
    }

    // The amount being reclaimed must be within the project's balance.
    if (reclaimAmount > balanceOf[IJBPaymentTerminal(msg.sender)][_projectId])
      revert INADEQUATE_PAYMENT_TERMINAL_STORE_BALANCE();

    // Remove the reclaimed funds from the project's balance.
    if (reclaimAmount > 0)
      balanceOf[IJBPaymentTerminal(msg.sender)][_projectId] =
        balanceOf[IJBPaymentTerminal(msg.sender)][_projectId] -
        reclaimAmount;
  }

  /**
    @notice
    Records newly distributed funds for a project.

    @dev
    The msg.sender must be an IJBPaymentTerminal. 

    @param _projectId The ID of the project that is having funds distributed.
    @param _amount The amount to use from the distribution limit, as a fixed point number.
    @param _currency The currency of the `_amount`. This must match the project's current funding cycle's currency.
    @param _balanceCurrency The currency that the balance is expected to be in terms of.

    @return fundingCycle The funding cycle during which the distribution was made.
    @return distributedAmount The amount of terminal tokens distributed, as a fixed point number with the same amount of decimals as its relative terminal.
  */
  function recordDistributionFor(
    uint256 _projectId,
    uint256 _amount,
    uint256 _currency,
    uint256 _balanceCurrency
  )
    external
    override
    nonReentrant
    returns (JBFundingCycle memory fundingCycle, uint256 distributedAmount)
  {
    // Get a reference to the project's current funding cycle.
    fundingCycle = fundingCycleStore.currentOf(_projectId);

    // The funding cycle must not be configured to have distributions paused.
    if (fundingCycle.distributionsPaused()) revert FUNDING_CYCLE_DISTRIBUTION_PAUSED();

    // The new total amount that has been distributed during this funding cycle.
    uint256 _newUsedDistributionLimitOf = usedDistributionLimitOf[IJBPaymentTerminal(msg.sender)][
      _projectId
    ][fundingCycle.number] + _amount;

    // Amount must be within what is still distributable.
    (uint256 _distributionLimitOf, uint256 _distributionLimitCurrencyOf) = directory
      .controllerOf(_projectId)
      .distributionLimitOf(_projectId, fundingCycle.configuration, IJBPaymentTerminal(msg.sender));

    // Make sure the new used amount is within the distribution limit.
    if (_newUsedDistributionLimitOf > _distributionLimitOf || _distributionLimitOf == 0)
      revert DISTRIBUTION_AMOUNT_LIMIT_REACHED();

    // Make sure the currencies match.
    if (_currency != _distributionLimitCurrencyOf) revert CURRENCY_MISMATCH();

    // Convert the amount to the balance's currency.
    distributedAmount = (_currency == _balanceCurrency) ? _amount : distributedAmount = PRBMath
      .mulDiv(
        _amount,
        10**_MAX_FIXED_POINT_FIDELITY, // Use _MAX_FIXED_POINT_FIDELITY to keep as much of the `_amount.value`'s fidelity as possible when converting.
        prices.priceFor(_currency, _balanceCurrency, _MAX_FIXED_POINT_FIDELITY)
      );

    // The amount being distributed must be available.
    if (distributedAmount > balanceOf[IJBPaymentTerminal(msg.sender)][_projectId])
      revert INADEQUATE_PAYMENT_TERMINAL_STORE_BALANCE();

    // Store the new amount.
    usedDistributionLimitOf[IJBPaymentTerminal(msg.sender)][_projectId][
      fundingCycle.number
    ] = _newUsedDistributionLimitOf;

    // Removed the distributed funds from the project's token balance.
    balanceOf[IJBPaymentTerminal(msg.sender)][_projectId] =
      balanceOf[IJBPaymentTerminal(msg.sender)][_projectId] -
      distributedAmount;
  }

  /**
    @notice
    Records newly used allowance funds of a project.

    @dev
    The msg.sender must be an IJBPaymentTerminal. 

    @param _projectId The ID of the project to use the allowance of.
    @param _amount The amount to use from the allowance, as a fixed point number. 
    @param _currency The currency of the `_amount`. Must match the currency of the overflow allowance.
    @param _balanceCurrency The currency that the balance is expected to be in terms of.

    @return fundingCycle The funding cycle during which the overflow allowance is being used.
    @return usedAmount The amount of terminal tokens used, as a fixed point number with the same amount of decimals as its relative terminal.
  */
  function recordUsedAllowanceOf(
    uint256 _projectId,
    uint256 _amount,
    uint256 _currency,
    uint256 _balanceCurrency
  )
    external
    override
    nonReentrant
    returns (JBFundingCycle memory fundingCycle, uint256 usedAmount)
  {
    // Get a reference to the project's current funding cycle.
    fundingCycle = fundingCycleStore.currentOf(_projectId);

    // Get a reference to the new used overflow allowance.
    uint256 _newUsedOverflowAllowanceOf = usedOverflowAllowanceOf[IJBPaymentTerminal(msg.sender)][
      _projectId
    ][fundingCycle.configuration] + _amount;

    // There must be sufficient allowance available.
    (uint256 _overflowAllowanceOf, uint256 _overflowAllowanceCurrency) = directory
      .controllerOf(_projectId)
      .overflowAllowanceOf(_projectId, fundingCycle.configuration, IJBPaymentTerminal(msg.sender));

    // Make sure the new used amount is within the allowance.
    if (_newUsedOverflowAllowanceOf > _overflowAllowanceOf || _overflowAllowanceOf == 0)
      revert INADEQUATE_CONTROLLER_ALLOWANCE();

    // Make sure the currencies match.
    if (_currency != _overflowAllowanceCurrency) revert CURRENCY_MISMATCH();

    // Convert the amount to this store's terminal's token.
    usedAmount = (_currency == _balanceCurrency)
      ? _amount
      : PRBMath.mulDiv(
        _amount,
        10**_MAX_FIXED_POINT_FIDELITY, // Use _MAX_FIXED_POINT_FIDELITY to keep as much of the `_amount.value`'s fidelity as possible when converting.
        prices.priceFor(_currency, _balanceCurrency, _MAX_FIXED_POINT_FIDELITY)
      );

    // The amount being withdrawn must be available in the overflow.
    if (
      usedAmount >
      _overflowDuring(IJBPaymentTerminal(msg.sender), _projectId, fundingCycle, _balanceCurrency)
    ) revert INADEQUATE_PAYMENT_TERMINAL_STORE_BALANCE();

    // Store the incremented value.
    usedOverflowAllowanceOf[IJBPaymentTerminal(msg.sender)][_projectId][
      fundingCycle.configuration
    ] = _newUsedOverflowAllowanceOf;

    // Update the project's balance.
    balanceOf[IJBPaymentTerminal(msg.sender)][_projectId] =
      balanceOf[IJBPaymentTerminal(msg.sender)][_projectId] -
      usedAmount;
  }

  /**
    @notice
    Records newly added funds for the project.

    @dev
    The msg.sender must be an IJBPaymentTerminal. 

    @param _projectId The ID of the project to which the funds being added belong.
    @param _amount The amount of temrinal tokens added, as a fixed point number with the same amount of decimals as its relative terminal.
  */
  function recordAddedBalanceFor(uint256 _projectId, uint256 _amount)
    external
    override
    nonReentrant
  {
    // Increment the balance.
    balanceOf[IJBPaymentTerminal(msg.sender)][_projectId] =
      balanceOf[IJBPaymentTerminal(msg.sender)][_projectId] +
      _amount;
  }

  /**
    @notice
    Records the migration of funds from this store.

    @dev
    The msg.sender must be an IJBPaymentTerminal. The amount returned is in terms of the msg.senders tokens.

    @param _projectId The ID of the project being migrated.

    @return balance The project's migrated balance, as a fixed point number with the same amount of decimals as its relative terminal.
  */
  function recordMigration(uint256 _projectId)
    external
    override
    nonReentrant
    returns (uint256 balance)
  {
    // Get a reference to the project's current funding cycle.
    JBFundingCycle memory _fundingCycle = fundingCycleStore.currentOf(_projectId);

    // Migration must be allowed.
    if (!_fundingCycle.terminalMigrationAllowed()) revert PAYMENT_TERMINAL_MIGRATION_NOT_ALLOWED();

    // Return the current balance.
    balance = balanceOf[IJBPaymentTerminal(msg.sender)][_projectId];

    // Set the balance to 0.
    balanceOf[IJBPaymentTerminal(msg.sender)][_projectId] = 0;
  }

  //*********************************************************************//
  // --------------------- private helper functions -------------------- //
  //*********************************************************************//

  /**
    @notice
    The amount of overflowed tokens from a terminal that can be reclaimed by the specified number of tokens when measured from the specified.

    @dev 
    If the project has an active funding cycle reconfiguration ballot, the project's ballot redemption rate is used.

    @param _projectId The ID of the project to get the reclaimable overflow amount for.
    @param _fundingCycle The funding cycle during which reclaimable overflow is being calculated.
    @param _tokenCount The number of tokens to make the calculation with, as a fixed point number with 18 decimals.
    @param _totalSupply The total supply of tokens to make the calculation with, as a fixed point number with 18 decimals.
    @param _overflow The amount of overflow to make the calculation with.

    @return The amount of overflowed tokens that can be reclaimed.
  */
  function _reclaimableOverflowDuring(
    uint256 _projectId,
    JBFundingCycle memory _fundingCycle,
    uint256 _tokenCount,
    uint256 _totalSupply,
    uint256 _overflow
  ) private view returns (uint256) {
    // If the amount being redeemed is the total supply, return the rest of the overflow.
    if (_tokenCount == _totalSupply) return _overflow;

    // Use the ballot redemption rate if the queued cycle is pending approval according to the previous funding cycle's ballot.
    uint256 _redemptionRate = fundingCycleStore.currentBallotStateOf(_projectId) ==
      JBBallotState.Active
      ? _fundingCycle.ballotRedemptionRate()
      : _fundingCycle.redemptionRate();

    // If the redemption rate is 0, nothing is claimable.
    if (_redemptionRate == 0) return 0;

    // Get a reference to the linear proportion.
    uint256 _base = PRBMath.mulDiv(_overflow, _tokenCount, _totalSupply);

    // These conditions are all part of the same curve. Edge conditions are separated because fewer operation are necessary.
    if (_redemptionRate == JBConstants.MAX_REDEMPTION_RATE) return _base;

    return
      PRBMath.mulDiv(
        _base,
        _redemptionRate +
          PRBMath.mulDiv(
            _tokenCount,
            JBConstants.MAX_REDEMPTION_RATE - _redemptionRate,
            _totalSupply
          ),
        JBConstants.MAX_REDEMPTION_RATE
      );
  }

  /**
    @notice
    Gets the amount that is overflowing when measured from the specified funding cycle.

    @dev
    This amount changes as the value of the balance changes in relation to the currency being used to measure the distribution limit.

    @param _terminal The terminal for which the overflow is being calculated.
    @param _projectId The ID of the project to get overflow for.
    @param _fundingCycle The ID of the funding cycle to base the overflow on.
    @param _balanceCurrency The currency that the stored balance is expected to be in terms of.

    @return overflow The overflow of funds, as a fixed point number with 18 decimals.
  */
  function _overflowDuring(
    IJBPaymentTerminal _terminal,
    uint256 _projectId,
    JBFundingCycle memory _fundingCycle,
    uint256 _balanceCurrency
  ) private view returns (uint256) {
    // Get the current balance of the project.
    uint256 _balanceOf = balanceOf[_terminal][_projectId];

    // If there's no balance, there's no overflow.
    if (_balanceOf == 0) return 0;

    // Get a reference to the distribution limit during the funding cycle.
    (uint256 _distributionLimit, uint256 _distributionLimitCurrency) = directory
      .controllerOf(_projectId)
      .distributionLimitOf(_projectId, _fundingCycle.configuration, _terminal);

    // Get a reference to the amount still distributable during the funding cycle.
    uint256 _distributionLimitRemaining = _distributionLimit -
      usedDistributionLimitOf[_terminal][_projectId][_fundingCycle.number];

    // Convert the _distributionRemaining to be in terms of the provided currency.
    if (_distributionLimitRemaining != 0 && _distributionLimitCurrency != _balanceCurrency)
      _distributionLimitRemaining = PRBMath.mulDiv(
        _distributionLimitRemaining,
        10**_MAX_FIXED_POINT_FIDELITY, // Use _MAX_FIXED_POINT_FIDELITY to keep as much of the `_amount.value`'s fidelity as possible when converting.
        prices.priceFor(_distributionLimitCurrency, _balanceCurrency, _MAX_FIXED_POINT_FIDELITY)
      );

    // Overflow is the balance of this project minus the amount that can still be distributed.
    return _balanceOf > _distributionLimitRemaining ? _balanceOf - _distributionLimitRemaining : 0;
  }

  /**
    @notice
    Gets the amount that is currently overflowing across all of a project's terminals. 

    @dev
    This amount changes as the value of the balances changes in relation to the currency being used to measure the project's distribution limits.

    @param _projectId The ID of the project to get the total overflow for.
    @param _decimals The number of decimals that the fixed point overflow should include.
    @param _currency The currency that the overflow should be in terms of.

    @return overflow The total overflow of a project's funds.
  */
  function _currentTotalOverflowOf(
    uint256 _projectId,
    uint256 _decimals,
    uint256 _currency
  ) private view returns (uint256) {
    // Get a reference to the project's terminals.
    IJBPaymentTerminal[] memory _terminals = directory.terminalsOf(_projectId);

    // Keep a reference to the ETH overflow across all terminals, as a fixed point number with 18 decimals.
    uint256 _ethOverflow;

    // Add the current ETH overflow for each terminal.
    for (uint256 _i = 0; _i < _terminals.length; _i++)
      _ethOverflow = _ethOverflow + _terminals[_i].currentEthOverflowOf(_projectId);

    // Convert the ETH overflow to the specified currency if needed, maintaining a fixed point number with 18 decimals.
    uint256 _totalOverflow18Decimal = _currency == JBCurrencies.ETH
      ? _ethOverflow
      : PRBMath.mulDiv(_ethOverflow, 10**18, prices.priceFor(JBCurrencies.ETH, _currency, 18));

    // Adjust the decimals of the fixed point number if needed to match the target decimals.
    return
      (_decimals == 18)
        ? _totalOverflow18Decimal
        : JBFixedPointNumber.adjustDecimals(_totalOverflow18Decimal, 18, _decimals);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

enum JBBallotState {
  Approved,
  Active,
  Failed
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../structs/JBFundingCycleData.sol';
import './../structs/JBFundingCycleMetadata.sol';
import './../structs/JBProjectMetadata.sol';
import './../structs/JBGroupedSplits.sol';
import './../structs/JBFundAccessConstraints.sol';
import './IJBDirectory.sol';
import './IJBToken.sol';
import './IJBPaymentTerminal.sol';
import './IJBFundingCycleStore.sol';
import './IJBTokenStore.sol';
import './IJBSplitsStore.sol';

interface IJBController {
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
    uint256 indexed fundingCycleConfiguration,
    uint256 indexed fundingCycleNumber,
    uint256 indexed projectId,
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

  event Migrate(uint256 indexed projectId, IJBController to, address caller);

  event PrepMigration(uint256 indexed projectId, IJBController from, address caller);

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
    IJBPaymentTerminal _terminal
  ) external view returns (uint256 distributionLimit, uint256 distributionLimitCurrency);

  function overflowAllowanceOf(
    uint256 _projectId,
    uint256 _configuration,
    IJBPaymentTerminal _terminal
  ) external view returns (uint256 overflowAllowance, uint256 overflowAllowanceCurrency);

  function totalOutstandingTokensOf(uint256 _projectId, uint256 _reservedRate)
    external
    view
    returns (uint256);

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

  function prepForMigrationOf(uint256 _projectId, IJBController _from) external;

  function migrate(uint256 _projectId, IJBController _to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBPaymentTerminal.sol';
import './IJBProjects.sol';
import './IJBController.sol';

interface IJBDirectory {
  event SetController(uint256 indexed projectId, IJBController indexed controller, address caller);

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

  function controllerOf(uint256 _projectId) external view returns (IJBController);

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

  function setControllerOf(uint256 _projectId, IJBController _controller) external;

  function setTerminalsOf(uint256 _projectId, IJBPaymentTerminal[] calldata _terminals) external;

  function setPrimaryTerminalOf(uint256 _projectId, IJBPaymentTerminal _terminal) external;

  function setIsAllowedToSetFirstController(address _address, bool _flag) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../enums/JBBallotState.sol';

interface IJBFundingCycleBallot {
  function duration() external view returns (uint256);

  function stateOf(uint256 _projectId, uint256 _configuration)
    external
    view
    returns (JBBallotState);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBFundingCycleStore.sol';

import './IJBPayDelegate.sol';
import './IJBRedemptionDelegate.sol';

import './../structs/JBPayParamsData.sol';
import './../structs/JBRedeemParamsData.sol';

interface IJBFundingCycleDataSource {
  function payParams(JBPayParamsData calldata _data)
    external
    view
    returns (
      uint256 weight,
      string memory memo,
      IJBPayDelegate delegate
    );

  function redeemParams(JBRedeemParamsData calldata _data)
    external
    view
    returns (
      uint256 reclaimAmount,
      string memory memo,
      IJBRedemptionDelegate delegate
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBFundingCycleBallot.sol';
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

  function queuedOf(uint256 _projectId) external view returns (JBFundingCycle memory);

  function currentOf(uint256 _projectId) external view returns (JBFundingCycle memory);

  function currentBallotStateOf(uint256 _projectId) external view returns (JBBallotState);

  function configureFor(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    uint256 _metadata,
    uint256 _mustStartAtOrAfter
  ) external returns (JBFundingCycle memory fundingCycle);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../structs/JBOperatorData.sol';

interface IJBOperatorStore {
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

  function setOperator(JBOperatorData calldata _operatorData) external;

  function setOperators(JBOperatorData[] calldata _operatorData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../structs/JBDidPayData.sol';

interface IJBPayDelegate {
  function didPay(JBDidPayData calldata _data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBDirectory.sol';

interface IJBPaymentTerminal {
  function token() external view returns (address);

  function currency() external view returns (uint256);

  function decimals() external view returns (uint256);

  // Return value must be a fixed point number with 18 decimals.
  function currentEthOverflowOf(uint256 _projectId) external view returns (uint256);

  function pay(
    uint256 _amount,
    uint256 _projectId,
    address _beneficiary,
    uint256 _minReturnedTokens,
    bool _preferClaimedTokens,
    string calldata _memo,
    bytes calldata _metadata
  ) external payable;

  function addToBalanceOf(
    uint256 _amount,
    uint256 _projectId,
    string calldata _memo
  ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBPaymentTerminal.sol';
import './IJBPayDelegate.sol';
import './IJBRedemptionDelegate.sol';
import './IJBTokenStore.sol';
import './IJBSplitsStore.sol';
import './IJBPrices.sol';
import './../structs/JBTokenAmount.sol';
import './../structs/JBFundingCycle.sol';

interface IJBPaymentTerminalStore {
  function fundingCycleStore() external view returns (IJBFundingCycleStore);

  function directory() external view returns (IJBDirectory);

  function prices() external view returns (IJBPrices);

  function balanceOf(IJBPaymentTerminal _terminal, uint256 _projectId)
    external
    view
    returns (uint256);

  function usedDistributionLimitOf(
    IJBPaymentTerminal _terminal,
    uint256 _projectId,
    uint256 _fundingCycleNumber
  ) external view returns (uint256);

  function usedOverflowAllowanceOf(
    IJBPaymentTerminal _terminal,
    uint256 _projectId,
    uint256 _fundingCycleConfiguration
  ) external view returns (uint256);

  function currentOverflowOf(IJBPaymentTerminal _terminal, uint256 _projectId)
    external
    view
    returns (uint256);

  function currentTotalOverflowOf(
    uint256 _projectId,
    uint256 _decimals,
    uint256 _currency
  ) external view returns (uint256);

  function currentReclaimableOverflowOf(
    IJBPaymentTerminal _terminal,
    uint256 _projectId,
    uint256 _tokenCount,
    bool _useTotalOverflow
  ) external view returns (uint256);

  function currentReclaimableOverflowOf(
    uint256 _projectId,
    uint256 _tokenCount,
    uint256 _totalSupply,
    uint256 _overflow
  ) external view returns (uint256);

  function recordPaymentFrom(
    address _payer,
    JBTokenAmount memory _amount,
    uint256 _projectId,
    uint256 _baseWeightCurrency,
    string calldata _memo,
    bytes calldata _metadata
  )
    external
    returns (
      JBFundingCycle memory fundingCycle,
      uint256 tokenCount,
      IJBPayDelegate delegate,
      string memory memo
    );

  function recordRedemptionFor(
    address _holder,
    uint256 _projectId,
    uint256 _tokenCount,
    uint256 _balanceDecimals,
    uint256 _balanceCurrency,
    string calldata _memo,
    bytes calldata _metadata
  )
    external
    returns (
      JBFundingCycle memory fundingCycle,
      uint256 reclaimAmount,
      IJBRedemptionDelegate delegate,
      string memory memo
    );

  function recordDistributionFor(
    uint256 _projectId,
    uint256 _amount,
    uint256 _currency,
    uint256 _balanceCurrency
  ) external returns (JBFundingCycle memory fundingCycle, uint256 distributedAmount);

  function recordUsedAllowanceOf(
    uint256 _projectId,
    uint256 _amount,
    uint256 _currency,
    uint256 _balanceCurrency
  ) external returns (JBFundingCycle memory fundingCycle, uint256 withdrawnAmount);

  function recordAddedBalanceFor(uint256 _projectId, uint256 _amount) external;

  function recordMigration(uint256 _projectId) external returns (uint256 balance);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IJBPriceFeed {
  function currentPrice(uint256 _targetDecimals) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBPriceFeed.sol';

interface IJBPrices {
  event AddFeed(uint256 indexed currency, uint256 indexed base, IJBPriceFeed feed);

  function feedFor(uint256 _currency, uint256 _base) external view returns (IJBPriceFeed);

  function priceFor(
    uint256 _currency,
    uint256 _base,
    uint256 _decimals
  ) external view returns (uint256);

  function addFeedFor(
    uint256 _currency,
    uint256 _base,
    IJBPriceFeed _priceFeed
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

import './IJBPaymentTerminal.sol';
import './IJBTokenUriResolver.sol';

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

  event SetTokenUriResolver(IJBTokenUriResolver resolver, address caller);

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
pragma solidity 0.8.6;

import './IJBFundingCycleStore.sol';

import './../structs/JBDidRedeemData.sol';

interface IJBRedemptionDelegate {
  function didRedeem(JBDidRedeemData calldata _data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '../structs/JBSplitAllocationData.sol';

interface IJBSplitAllocator {
  function allocate(JBSplitAllocationData calldata _data) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBOperatorStore.sol';
import './IJBProjects.sol';
import './IJBDirectory.sol';
import './IJBSplitAllocator.sol';

import './../structs/JBSplit.sol';

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
    uint256 _group,
    JBSplit[] memory _splits
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

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

  function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IJBTokenUriResolver {
  function getUri(uint256 _projectId) external view returns (string memory tokenUri);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
  @notice
  Global constants used across multiple Juicebox contracts.
*/
library JBConstants {
  /** 
    @notice
    Maximum value for reserved, redemption, and ballot redemption rates. Does not include discount rate.
  */
  uint256 public constant MAX_RESERVED_RATE = 10000;

  /**
    @notice
    Maximum token redemption rate.  
    */
  uint256 public constant MAX_REDEMPTION_RATE = 10000;

  /** 
    @notice
    A funding cycle's discount rate is expressed as a percentage out of 1000000000.
  */
  uint256 public constant MAX_DISCOUNT_RATE = 1000000000;

  /** 
    @notice
    Maximum splits percentage.
  */
  uint256 public constant SPLITS_TOTAL_PERCENT = 1000000000;

  /** 
    @notice
    Maximum fee rate as a percentage out of 1000000000
  */
  uint256 public constant MAX_FEE = 1000000000;

  /** 
    @notice
    Maximum discount on fee granted by a gauge.
  */
  uint256 public constant MAX_FEE_DISCOUNT = 1000000000;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

library JBCurrencies {
  uint256 public constant ETH = 1;
  uint256 public constant USD = 2;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './JBConstants.sol';
import './../interfaces/IJBFundingCycleStore.sol';
import './../interfaces/IJBFundingCycleDataSource.sol';
import './../structs/JBFundingCycleMetadata.sol';

library JBFixedPointNumber {
  function adjustDecimals(
    uint256 _value,
    uint256 _decimals,
    uint256 _targetDecimals
  ) internal pure returns (uint256) {
    // If decimals need adjusting, multiply or divide the price by the decimal adjuster to get the normalized result.
    if (_targetDecimals == _decimals) return _value;
    else if (_targetDecimals > _decimals) return _value * 10**(_targetDecimals - _decimals);
    else return _value / 10**(_decimals - _targetDecimals);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './JBConstants.sol';
import './../interfaces/IJBFundingCycleStore.sol';
import './../interfaces/IJBFundingCycleDataSource.sol';
import './../structs/JBFundingCycleMetadata.sol';

library JBFundingCycleMetadataResolver {
  function reservedRate(JBFundingCycle memory _fundingCycle) internal pure returns (uint256) {
    return uint256(uint16(_fundingCycle.metadata >> 8));
  }

  function redemptionRate(JBFundingCycle memory _fundingCycle) internal pure returns (uint256) {
    // Redemption rate is a number 0-10000. It's inverse was stored so the most common case of 100% results in no storage needs.
    return JBConstants.MAX_REDEMPTION_RATE - uint256(uint16(_fundingCycle.metadata >> 24));
  }

  function ballotRedemptionRate(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (uint256)
  {
    // Redemption rate is a number 0-10000. It's inverse was stored so the most common case of 100% results in no storage needs.
    return JBConstants.MAX_REDEMPTION_RATE - uint256(uint16(_fundingCycle.metadata >> 40));
  }

  function payPaused(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 56) & 1) == 1;
  }

  function distributionsPaused(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 57) & 1) == 1;
  }

  function redeemPaused(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 58) & 1) == 1;
  }

  function mintPaused(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 59) & 1) == 1;
  }

  function burnPaused(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 60) & 1) == 1;
  }

  function changeTokenAllowed(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 61) & 1) == 1;
  }

  function terminalMigrationAllowed(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (bool)
  {
    return ((_fundingCycle.metadata >> 62) & 1) == 1;
  }

  function controllerMigrationAllowed(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (bool)
  {
    return ((_fundingCycle.metadata >> 63) & 1) == 1;
  }

  function setTerminalsAllowed(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 64) & 1) == 1;
  }

  function setControllerAllowed(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 65) & 1) == 1;
  }

  function shouldHoldFees(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 66) & 1) == 1;
  }

  function useTotalOverflowForRedemptions(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (bool)
  {
    return ((_fundingCycle.metadata >> 67) & 1) == 1;
  }

  function useDataSourceForPay(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return (_fundingCycle.metadata >> 68) & 1 == 1;
  }

  function useDataSourceForRedeem(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (bool)
  {
    return (_fundingCycle.metadata >> 69) & 1 == 1;
  }

  function dataSource(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (IJBFundingCycleDataSource)
  {
    return IJBFundingCycleDataSource(address(uint160(_fundingCycle.metadata >> 70)));
  }

  /**
    @notice
    Pack the funding cycle metadata.

    @param _metadata The metadata to validate and pack.

    @return packed The packed uint256 of all metadata params. The first 8 bits specify the version.
  */
  function packFundingCycleMetadata(JBFundingCycleMetadata memory _metadata)
    internal
    pure
    returns (uint256 packed)
  {
    // version 1 in the bits 0-7 (8 bits).
    packed = 1;
    // reserved rate in bits 8-23 (16 bits).
    packed |= _metadata.reservedRate << 8;
    // redemption rate in bits 24-39 (16 bits).
    // redemption rate is a number 0-10000. Store the reverse so the most common case of 100% results in no storage needs.
    packed |= (JBConstants.MAX_REDEMPTION_RATE - _metadata.redemptionRate) << 24;
    // ballot redemption rate rate in bits 40-55 (16 bits).
    // ballot redemption rate is a number 0-10000. Store the reverse so the most common case of 100% results in no storage needs.
    packed |= (JBConstants.MAX_REDEMPTION_RATE - _metadata.ballotRedemptionRate) << 40;
    // pause pay in bit 56.
    if (_metadata.pausePay) packed |= 1 << 56;
    // pause tap in bit 57.
    if (_metadata.pauseDistributions) packed |= 1 << 57;
    // pause redeem in bit 58.
    if (_metadata.pauseRedeem) packed |= 1 << 58;
    // pause mint in bit 59.
    if (_metadata.pauseMint) packed |= 1 << 59;
    // pause mint in bit 60.
    if (_metadata.pauseBurn) packed |= 1 << 60;
    // pause change token in bit 61.
    if (_metadata.allowChangeToken) packed |= 1 << 61;
    // allow terminal migration in bit 62.
    if (_metadata.allowTerminalMigration) packed |= 1 << 62;
    // allow controller migration in bit 63.
    if (_metadata.allowControllerMigration) packed |= 1 << 63;
    // allow set terminals in bit 64.
    if (_metadata.allowSetTerminals) packed |= 1 << 64;
    // allow set controller in bit 65.
    if (_metadata.allowSetController) packed |= 1 << 65;
    // hold fees in bit 66.
    if (_metadata.holdFees) packed |= 1 << 66;
    // useTotalOverflowForRedemptions in bit 67.
    if (_metadata.useTotalOverflowForRedemptions) packed |= 1 << 67;
    // use pay data source in bit 68.
    if (_metadata.useDataSourceForPay) packed |= 1 << 68;
    // use redeem data source in bit 69.
    if (_metadata.useDataSourceForRedeem) packed |= 1 << 69;
    // data source address in bits 70-229.
    packed |= uint256(uint160(address(_metadata.dataSource))) << 70;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

library JBOperations {
  uint256 public constant RECONFIGURE = 1;
  uint256 public constant REDEEM = 2;
  uint256 public constant MIGRATE_CONTROLLER = 3;
  uint256 public constant MIGRATE_TERMINAL = 4;
  uint256 public constant PROCESS_FEES = 5;
  uint256 public constant SET_METADATA = 6;
  uint256 public constant ISSUE = 7;
  uint256 public constant CHANGE_TOKEN = 8;
  uint256 public constant MINT = 9;
  uint256 public constant BURN = 10;
  uint256 public constant CLAIM = 11;
  uint256 public constant TRANSFER = 12;
  uint256 public constant REQUIRE_CLAIM = 13;
  uint256 public constant SET_CONTROLLER = 14;
  uint256 public constant SET_TERMINALS = 15;
  uint256 public constant SET_PRIMARY_TERMINAL = 16;
  uint256 public constant USE_ALLOWANCE = 17;
  uint256 public constant SET_SPLITS = 18;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

library JBSplitsGroups {
  uint256 public constant ETH_PAYOUT = 1;
  uint256 public constant RESERVED_TOKENS = 2;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './JBTokenAmount.sol';

struct JBDidPayData {
  // The address from which the payment originated.
  address payer;
  // The ID of the project for which the payment was made.
  uint256 projectId;
  // The amount of the payment. Includes the token being paid, the value, the number of decimals included, and the currency of the amount.
  JBTokenAmount amount;
  // The number of project tokens minted for the beneficiary.
  uint256 projectTokenCount;
  // The address to which the tokens were minted.
  address beneficiary;
  // The memo that is being emitted alongside the payment.
  string memo;
  // Metadata to send to the delegate.
  bytes metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './JBTokenAmount.sol';

struct JBDidRedeemData {
  // The holder of the tokens being redeemed.
  address holder;
  // The project to which the redeemed tokens are associated.
  uint256 projectId;
  // The number of project tokens being redeemed.
  uint256 projectTokenCount;
  // The reclaimed amount. Includes the token being paid, the value, the number of decimals included, and the currency of the amount.
  JBTokenAmount reclaimedAmount;
  // The address to which the reclaimed amount will be sent.
  address payable beneficiary;
  // The memo that is being emitted alongside the redemption.
  string memo;
  // Metadata to send to the delegate.
  bytes metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBPaymentTerminal.sol';

struct JBFundAccessConstraints {
  // The terminal within which the distribution limit and the overflow allowance applies.
  IJBPaymentTerminal terminal;
  // The amount of the distribution limit, as a fixed point number with the same number of decimals as the terminal within which the limit applies.
  uint256 distributionLimit;
  // The currency of the distribution limit.
  uint256 distributionLimitCurrency;
  // The amount of the allowance, as a fixed point number with the same number of decimals as the terminal within which the allowance applies.
  uint256 overflowAllowance;
  // The currency of the overflow allowance.
  uint256 overflowAllowanceCurrency;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBFundingCycleBallot.sol';

struct JBFundingCycle {
  // The funding cycle number for each project.
  // Each funding cycle has a number that is an increment of the cycle that directly preceded it.
  // Each project's first funding cycle has a number of 1.
  uint256 number;
  // The timestamp when the parameters for this funding cycle were configured.
  // This value will stay the same for subsequent funding cycles that roll over from an originally configured cycle.
  uint256 configuration;
  // The `configuration` of the funding cycle that was active when this cycle was created.
  uint256 basedOn;
  // The timestamp marking the moment from which the funding cycle is considered active.
  // It is a unix timestamp measured in seconds.
  uint256 start;
  // The number of seconds the funding cycle lasts for, after which a new funding cycle will start.
  // A duration of 0 means that the funding cycle will stay active until the project owner explicitly issues a reconfiguration, at which point a new funding cycle will immediately start with the updated properties.
  // If the duration is greater than 0, a project owner cannot make changes to a funding cycle's parameters while it is active – any proposed changes will apply to the subsequent cycle.
  // If no changes are proposed, a funding cycle rolls over to another one with the same properties but new `start` timestamp and a discounted `weight`.
  uint256 duration;
  // A fixed point number with 18 decimals that contracts can use to base arbitrary calculations on.
  // For example, payment terminals can use this to determine how many tokens should be minted when a payment is received.
  uint256 weight;
  // A percent by how much the `weight` of the subsequent funding cycle should be reduced, if the project owner hasn't configured the subsequent funding cycle with an explicit `weight`.
  // If it's 0, each funding cycle will have equal weight.
  // If the number is 90%, the next funding cycle will have a 10% smaller weight.
  // This weight is out of `JBConstants.MAX_DISCOUNT_RATE`.
  uint256 discountRate;
  // An address of a contract that says whether a proposed reconfiguration should be accepted or rejected.
  // It can be used to create rules around how a project owner can change funding cycle parameters over time.
  IJBFundingCycleBallot ballot;
  // Extra data that can be associated with a funding cycle.
  uint256 metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBFundingCycleBallot.sol';

struct JBFundingCycleData {
  // The number of seconds the funding cycle lasts for, after which a new funding cycle will start.
  // A duration of 0 means that the funding cycle will stay active until the project owner explicitly issues a reconfiguration, at which point a new funding cycle will immediately start with the updated properties.
  // If the duration is greater than 0, a project owner cannot make changes to a funding cycle's parameters while it is active – any proposed changes will apply to the subsequent cycle.
  // If no changes are proposed, a funding cycle rolls over to another one with the same properties but new `start` timestamp and a discounted `weight`.
  uint256 duration;
  // A fixed point number with 18 decimals that contracts can use to base arbitrary calculations on.
  // For example, payment terminals can use this to determine how many tokens should be minted when a payment is received.
  uint256 weight;
  // A percent by how much the `weight` of the subsequent funding cycle should be reduced, if the project owner hasn't configured the subsequent funding cycle with an explicit `weight`.
  // If it's 0, each funding cycle will have equal weight.
  // If the number is 90%, the next funding cycle will have a 10% smaller weight.
  // This weight is out of `JBConstants.MAX_DISCOUNT_RATE`.
  uint256 discountRate;
  // An address of a contract that says whether a proposed reconfiguration should be accepted or rejected.
  // It can be used to create rules around how a project owner can change funding cycle parameters over time.
  IJBFundingCycleBallot ballot;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBFundingCycleDataSource.sol';

struct JBFundingCycleMetadata {
  // The reserved rate of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_RESERVED_RATE`.
  uint256 reservedRate;
  // The redemption rate of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_REDEMPTION_RATE`.
  uint256 redemptionRate;
  // The redemption rate to use during an active ballot of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_REDEMPTION_RATE`.
  uint256 ballotRedemptionRate;
  // If the pay functionality should be paused during the funding cycle.
  bool pausePay;
  // If the distribute functionality should be paused during the funding cycle.
  bool pauseDistributions;
  // If the redeem functionality should be paused during the funding cycle.
  bool pauseRedeem;
  // If the mint functionality should be paused during the funding cycle.
  bool pauseMint;
  // If the burn functionality should be paused during the funding cycle.
  bool pauseBurn;
  // If changing tokens should be allowed during this funding cycle.
  bool allowChangeToken;
  // If migrating terminals should be allowed during this funding cycle.
  bool allowTerminalMigration;
  // If migrating controllers should be allowed during this funding cycle.
  bool allowControllerMigration;
  // If setting terminals should be allowed during this funding cycle.
  bool allowSetTerminals;
  // If setting a new controller should be allowed during this funding cycle.
  bool allowSetController;
  // If fees should be held during this funding cycle.
  bool holdFees;
  // If redemptions should use the project's balance held in all terminals instead of the project's local terminal balance from which the redemption is being fulfilled.
  bool useTotalOverflowForRedemptions;
  // If the data source should be used for pay transactions during this funding cycle.
  bool useDataSourceForPay;
  // If the data source should be used for redeem transactions during this funding cycle.
  bool useDataSourceForRedeem;
  // The data source to use during this funding cycle.
  IJBFundingCycleDataSource dataSource;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './JBSplit.sol';
import '../libraries/JBSplitsGroups.sol';

struct JBGroupedSplits {
  // The group indentifier.
  uint256 group;
  // The splits to associate with the group.
  JBSplit[] splits;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

struct JBOperatorData {
  // The address of the operator.
  address operator;
  // The domain within which the operator is being given permissions.
  // A domain of 0 is a wildcard domain, which gives an operator access to all domains.
  uint256 domain;
  // The indexes of the permissions the operator is being given.
  uint256[] permissionIndexes;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBPaymentTerminal.sol';

import './JBTokenAmount.sol';

struct JBPayParamsData {
  // The terminal that is facilitating the payment.
  IJBPaymentTerminal terminal;
  // The address from which the payment originated.
  address payer;
  // The amount of the payment. Includes the token being paid, the value, the number of decimals included, and the currency of the amount.
  JBTokenAmount amount;
  // The ID of the project being paid.
  uint256 projectId;
  // The weight of the funding cycle during which the payment is being made.
  uint256 weight;
  // The reserved rate of the funding cycle during which the payment is being made.
  uint256 reservedRate;
  // The memo that was sent alongside the payment.
  string memo;
  // Arbitrary metadata provided by the payer.
  bytes metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

struct JBProjectMetadata {
  // Metadata content.
  string content;
  // The domain within which the metadata applies.
  uint256 domain;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBPaymentTerminal.sol';

struct JBRedeemParamsData {
  // The terminal that is facilitating the redemption.
  IJBPaymentTerminal terminal;
  // The holder of the tokens being redeemed.
  address holder;
  // The ID of the project whos tokens are being redeemed.
  uint256 projectId;
  // The proposed number of tokens being redeemed, as a fixed point number with 18 decimals.
  uint256 tokenCount;
  // The total supply of tokens used in the calculation, as a fixed point number with 18 decimals.
  uint256 totalSupply;
  // The amount of overflow used in the reclaim amount calculation.
  uint256 overflow;
  // The number of decimals included in the reclaim amount fixed point number.
  uint256 decimals;
  // The currency that the reclaim amount is expected to be in terms of.
  uint256 currency;
  // The amount that should be reclaimed by the redeemer using the protocol's standard bonding curve redemption formula.
  uint256 reclaimAmount;
  // If overflow across all of a project's terminals is being used when making redemptions.
  bool useTotalOverflow;
  // The redemption rate of the funding cycle during which the redemption is being made.
  uint256 redemptionRate;
  // The ballot redemption rate of the funding cycle during which the redemption is being made.
  uint256 ballotRedemptionRate;
  // The proposed memo that is being emitted alongside the redemption.
  string memo;
  // Arbitrary metadata provided by the redeemer.
  bytes metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBSplitAllocator.sol';

struct JBSplit {
  // A flag that only has effect if a projectId is also specified, and the project has a token contract attached.
  // If so, this flag indicates if the tokens that result from making a payment to the project should be delivered claimed into the beneficiary's wallet, or unclaimed to save gas.
  bool preferClaimed;
  // The percent of the whole group that this split occupies. This number is out of `JBConstants.SPLITS_TOTAL_PERCENT`.
  uint256 percent;
  // If an allocator is not set but a projectId is set, funds will be sent to the protocol treasury belonging to the project who's ID is specified.
  // Resulting tokens will be routed to the beneficiary with the claimed token preference respected.
  uint256 projectId;
  // The role the of the beneficary depends on whether or not projectId is specified, and whether or not an allocator is specified.
  // If allocator is set, the beneficiary will be forwarded to the allocator for it to use.
  // If allocator is not set but projectId is set, the beneficiary is the address to which the project's tokens will be sent that result from a payment to it.
  // If neither allocator or projectId are set, the beneficiary is where the funds from the split will be sent.
  address payable beneficiary;
  // Specifies if the split should be unchangeable until the specified time, with the exception of extending the locked period.
  uint256 lockedUntil;
  // If an allocator is specified, funds will be sent to the allocator contract along with all properties of this split.
  IJBSplitAllocator allocator;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './JBSplit.sol';
import './JBTokenAmount.sol';

struct JBSplitAllocationData {
  // The amount being sent to the split allocator, as a fixed point number.
  uint256 amount;
  // The number of decimals in the amount.
  uint256 decimals;
  // The project to which the split belongs.
  uint256 projectId;
  // The group to which the split belongs.
  uint256 group;
  // The split that caused the allocation.
  JBSplit split;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

struct JBTokenAmount {
  // The token the payment was made in.
  address token;
  // The amount of tokens that was paid, as a fixed point number.
  uint256 value;
  // The number of decimals included in the value fixed point number.
  uint256 decimals;
  // The expected currency of the value.
  uint256 currency;
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivFixedPointOverflow(uint256 prod1);

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivOverflow(uint256 prod1, uint256 denominator);

/// @notice Emitted when one of the inputs is type(int256).min.
error PRBMath__MulDivSignedInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows int256.
error PRBMath__MulDivSignedOverflow(uint256 rAbs);

/// @notice Emitted when the input is MIN_SD59x18.
error PRBMathSD59x18__AbsInputTooSmall();

/// @notice Emitted when ceiling a number overflows SD59x18.
error PRBMathSD59x18__CeilOverflow(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__DivInputTooSmall();

/// @notice Emitted when one of the intermediary unsigned results overflows SD59x18.
error PRBMathSD59x18__DivOverflow(uint256 rAbs);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathSD59x18__ExpInputTooBig(int256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathSD59x18__Exp2InputTooBig(int256 x);

/// @notice Emitted when flooring a number underflows SD59x18.
error PRBMathSD59x18__FloorUnderflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format overflows SD59x18.
error PRBMathSD59x18__FromIntOverflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format underflows SD59x18.
error PRBMathSD59x18__FromIntUnderflow(int256 x);

/// @notice Emitted when the product of the inputs is negative.
error PRBMathSD59x18__GmNegativeProduct(int256 x, int256 y);

/// @notice Emitted when multiplying the inputs overflows SD59x18.
error PRBMathSD59x18__GmOverflow(int256 x, int256 y);

/// @notice Emitted when the input is less than or equal to zero.
error PRBMathSD59x18__LogInputTooSmall(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__MulInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__MulOverflow(uint256 rAbs);

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__PowuOverflow(uint256 rAbs);

/// @notice Emitted when the input is negative.
error PRBMathSD59x18__SqrtNegativeInput(int256 x);

/// @notice Emitted when the calculating the square root overflows SD59x18.
error PRBMathSD59x18__SqrtOverflow(int256 x);

/// @notice Emitted when addition overflows UD60x18.
error PRBMathUD60x18__AddOverflow(uint256 x, uint256 y);

/// @notice Emitted when ceiling a number overflows UD60x18.
error PRBMathUD60x18__CeilOverflow(uint256 x);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathUD60x18__ExpInputTooBig(uint256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathUD60x18__Exp2InputTooBig(uint256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format format overflows UD60x18.
error PRBMathUD60x18__FromUintOverflow(uint256 x);

/// @notice Emitted when multiplying the inputs overflows UD60x18.
error PRBMathUD60x18__GmOverflow(uint256 x, uint256 y);

/// @notice Emitted when the input is less than 1.
error PRBMathUD60x18__LogInputTooSmall(uint256 x);

/// @notice Emitted when the calculating the square root overflows UD60x18.
error PRBMathUD60x18__SqrtOverflow(uint256 x);

/// @notice Emitted when subtraction underflows UD60x18.
error PRBMathUD60x18__SubUnderflow(uint256 x, uint256 y);

/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
/// representation. When it does not, it is explicitly mentioned in the NatSpec documentation.
library PRBMath {
    /// STRUCTS ///

    struct SD59x18 {
        int256 value;
    }

    struct UD60x18 {
        uint256 value;
    }

    /// STORAGE ///

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @dev Largest power of two divisor of SCALE.
    uint256 internal constant SCALE_LPOTD = 262144;

    /// @dev SCALE inverted mod 2^256.
    uint256 internal constant SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661_508869554232690281;

    /// FUNCTIONS ///

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    /// @dev Has to use 192.64-bit fixed-point numbers.
    /// See https://ethereum.stackexchange.com/a/96594/24693.
    /// @param x The exponent as an unsigned 192.64-bit fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // Start from 0.5 in the 192.64-bit fixed-point format.
            result = 0x800000000000000000000000000000000000000000000000;

            // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
            // because the initial result is 2^191 and all magic factors are less than 2^65.
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            // We're doing two things at the same time:
            //
            //   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
            //      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
            //      rather than 192.
            //   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
            //
            // This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
            result *= SCALE;
            result >>= (191 - (x >> 64));
        }
    }

    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The multiplicand as an uint256.
    /// @param y The multiplier as an uint256.
    /// @param denominator The divisor as an uint256.
    /// @return result The result as an uint256.
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2^256 + prod0.
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division.
        if (prod1 == 0) {
            unchecked {
                result = prod0 / denominator;
            }
            return result;
        }

        // Make sure the result is less than 2^256. Also prevents denominator == 0.
        if (prod1 >= denominator) {
            revert PRBMath__MulDivOverflow(prod1, denominator);
        }

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0].
        uint256 remainder;
        assembly {
            // Compute remainder using mulmod.
            remainder := mulmod(x, y, denominator)

            // Subtract 256 bit number from 512 bit number.
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
        // See https://cs.stackexchange.com/q/138556/92363.
        unchecked {
            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by lpotdod.
                denominator := div(denominator, lpotdod)

                // Divide [prod1 prod0] by lpotdod.
                prod0 := div(prod0, lpotdod)

                // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * lpotdod;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /// @notice Calculates floor(x*y÷1e18) with full precision.
    ///
    /// @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
    /// final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
    /// being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
    ///
    /// Requirements:
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    /// - It is assumed that the result can never be type(uint256).max when x and y solve the following two equations:
    ///     1. x * y = type(uint256).max * SCALE
    ///     2. (x * y) % SCALE >= SCALE / 2
    ///
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mulDivFixedPoint(uint256 x, uint256 y) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert PRBMath__MulDivFixedPointOverflow(prod1);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(x, y, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            unchecked {
                result = (prod0 / SCALE) + roundUpUnit;
                return result;
            }
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev An extension of "mulDiv" for signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - None of the inputs can be type(int256).min.
    /// - The result must fit within int256.
    ///
    /// @param x The multiplicand as an int256.
    /// @param y The multiplier as an int256.
    /// @param denominator The divisor as an int256.
    /// @return result The result as an int256.
    function mulDivSigned(
        int256 x,
        int256 y,
        int256 denominator
    ) internal pure returns (int256 result) {
        if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
            revert PRBMath__MulDivSignedInputTooSmall();
        }

        // Get hold of the absolute values of x, y and the denominator.
        uint256 ax;
        uint256 ay;
        uint256 ad;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
            ad = denominator < 0 ? uint256(-denominator) : uint256(denominator);
        }

        // Compute the absolute value of (x*y)÷denominator. The result must fit within int256.
        uint256 rAbs = mulDiv(ax, ay, ad);
        if (rAbs > uint256(type(int256).max)) {
            revert PRBMath__MulDivSignedOverflow(rAbs);
        }

        // Get the signs of x, y and the denominator.
        uint256 sx;
        uint256 sy;
        uint256 sd;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
            sd := sgt(denominator, sub(0, 1))
        }

        // XOR over sx, sy and sd. This is checking whether there are one or three negative signs in the inputs.
        // If yes, the result should be negative.
        result = sx ^ sy ^ sd == 0 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the closest power of two that is higher than x.
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }
}