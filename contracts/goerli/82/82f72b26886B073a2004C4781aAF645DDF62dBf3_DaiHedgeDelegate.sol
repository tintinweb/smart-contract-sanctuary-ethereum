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
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountIn The desired input amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountOut The desired output amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../interfaces/IJBOperatable.sol';

/** 
  @notice
  Modifiers to allow access to functions based on the message sender's operator status.

  @dev
  Adheres to -
  IJBOperatable: General interface for the methods in this contract that interact with the blockchain's state according to the protocol's rules.
*/
abstract contract JBOperatable is IJBOperatable {
  //*********************************************************************//
  // --------------------------- custom errors -------------------------- //
  //*********************************************************************//
  error UNAUTHORIZED();

  //*********************************************************************//
  // ---------------------------- modifiers ---------------------------- //
  //*********************************************************************//

  /** 
    @notice
    Only allows the speficied account or an operator of the account to proceed. 

    @param _account The account to check for.
    @param _domain The domain namespace to look for an operator within. 
    @param _permissionIndex The index of the permission to check for. 
  */
  modifier requirePermission(
    address _account,
    uint256 _domain,
    uint256 _permissionIndex
  ) {
    _requirePermission(_account, _domain, _permissionIndex);
    _;
  }

  /** 
    @notice
    Only allows the speficied account, an operator of the account to proceed, or a truthy override flag. 

    @param _account The account to check for.
    @param _domain The domain namespace to look for an operator within. 
    @param _permissionIndex The index of the permission to check for. 
    @param _override A condition to force allowance for.
  */
  modifier requirePermissionAllowingOverride(
    address _account,
    uint256 _domain,
    uint256 _permissionIndex,
    bool _override
  ) {
    _requirePermissionAllowingOverride(_account, _domain, _permissionIndex, _override);
    _;
  }

  //*********************************************************************//
  // ---------------- public immutable stored properties --------------- //
  //*********************************************************************//

  /** 
    @notice 
    A contract storing operator assignments.
  */
  IJBOperatorStore public override operatorStore;

  //*********************************************************************//
  // -------------------------- internal views ------------------------- //
  //*********************************************************************//

  /** 
    @notice
    Require the message sender is either the account or has the specified permission.

    @param _account The account to allow.
    @param _domain The domain namespace within which the permission index will be checked.
    @param _permissionIndex The permission index that an operator must have within the specified domain to be allowed.
  */
  function _requirePermission(
    address _account,
    uint256 _domain,
    uint256 _permissionIndex
  ) internal view {
    if (
      msg.sender != _account &&
      !operatorStore.hasPermission(msg.sender, _account, _domain, _permissionIndex) &&
      !operatorStore.hasPermission(msg.sender, _account, 0, _permissionIndex)
    ) revert UNAUTHORIZED();
  }

  /** 
    @notice
    Require the message sender is either the account, has the specified permission, or the override condition is true.

    @param _account The account to allow.
    @param _domain The domain namespace within which the permission index will be checked.
    @param _domain The permission index that an operator must have within the specified domain to be allowed.
    @param _override The override condition to allow.
  */
  function _requirePermissionAllowingOverride(
    address _account,
    uint256 _domain,
    uint256 _permissionIndex,
    bool _override
  ) internal view {
    if (
      !_override &&
      msg.sender != _account &&
      !operatorStore.hasPermission(msg.sender, _account, _domain, _permissionIndex) &&
      !operatorStore.hasPermission(msg.sender, _account, 0, _permissionIndex)
    ) revert UNAUTHORIZED();
  }
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

import '../abstract/JBOperatable.sol';

import '../interfaces/IJBDirectory.sol';
import '../interfaces/IJBFundingCycleDataSource.sol';
import '../interfaces/IJBOperatorStore.sol';
import '../interfaces/IJBPayDelegate.sol';
import '../interfaces/IJBPaymentTerminal.sol';
import '../interfaces/IJBRedemptionDelegate.sol';
import '../interfaces/IJBSingleTokenPaymentTerminalStore.sol';
import '../libraries/JBCurrencies.sol';
import '../libraries/JBOperations.sol';
import '../libraries/JBTokens.sol';
import '../structs/JBDidPayData.sol';

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

interface IWETH9 is IERC20 {
  function deposit() external payable;

  function withdraw(uint256) external;
}

interface IDaiHedgeDelegate {
  function setHedgeParameters(
    uint256 _projectId,
    bool _applyHedge,
    uint256 _ethShare,
    uint256 _balanceThreshold,
    uint256 _ethThreshold,
    uint256 _usdThreshold,
    HedgeFlags memory _flags
  ) external;
}

struct HedgeFlags {
  bool liveQuote;
  /**
   * @dev Use default Ether payment terminal, otherwise JBDirectory will be queries.
   */
  bool defaultEthTerminal;
  /**
   * @dev Use default DAI payment terminal, otherwise JBDirectory will be queries.
   */
  bool defaultUsdTerminal;
}

struct HedgeSettings {
  uint256 ethThreshold;
  uint256 usdThreshold;
  /**
   * @dev Bit-packed value: uint16: eth share bps, uint16: balance threshold bps (<< 16), bool: live quote (<< 32), bool: default eth terminal (<< 33), bool: default eth terminal (<< 34)
   */
  uint256 settings;
}

/**
 * @title Automated DAI treasury
 *
 * @notice Converts ether sent to it into WETH and swaps it for DAI, then `pay`s the DAI into the platform DAI sink with the beneficiary being the owner of the original target project.
 *
 */
contract DaiHedgeDelegate is
  JBOperatable,
  IDaiHedgeDelegate,
  IJBFundingCycleDataSource,
  IJBPayDelegate,
  IJBRedemptionDelegate
{
  //*********************************************************************//
  // ------------------------------ errors ----------------------------- //
  //*********************************************************************//
  error REDEEM_NOT_SUPPORTED();

  //*********************************************************************//
  // -------------------- private stored properties -------------------- //
  //*********************************************************************//

  IJBDirectory private immutable jbxDirectory;

  IERC721 private immutable jbxProjects;

  /**
   * @notice Balance token, in this case DAI, that is held by the delegate on behalf of depositors.
   */
  IERC20Metadata private constant _dai = IERC20Metadata(0x6B175474E89094C44Da98b954EedeAC495271d0F); // DAI mainnet
  // IERC20Metadata private constant _dai = IERC20Metadata(0xdc31Ee1784292379Fbb2964b3B9C4124D8F89C60); // DAI goerli

  /**
   * @notice Uniswap v3 router.
   */
  ISwapRouter private constant _swapRouter =
    ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564); // TODO: this should be abstracted into a SwapProvider that can offer interfaces other than just uniswap

  /**
   * @notice Uniswap v3 quoter.
   */
  IQuoter public constant _swapQuoter = IQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);

  /**
   * @notice Hardwired WETH address for use as "cash" in the swaps.
   */
  IWETH9 private constant _weth = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

  uint24 public constant poolFee = 3000;

  IJBSingleTokenPaymentTerminal public defaultEthTerminal;
  IJBSingleTokenPaymentTerminal public defaultUsdTerminal;
  IJBSingleTokenPaymentTerminalStore public terminalStore;
  uint256 public recentPrice;
  uint256 public recentPriceTimestamp;

  /**
   * @dev Maps project ids to hedging configuration.
   */
  mapping(uint256 => HedgeSettings) public projectHedgeSettings;

  uint256 private constant bps = 10_000;
  uint256 private constant SettingsOffsetEthShare = 0;
  uint256 private constant SettingsOffsetBalanceThreshold = 16;
  uint256 private constant SettingsOffsetLiveQuote = 32;
  uint256 private constant SettingsOffsetDefaultEthTerminal = 33;
  uint256 private constant SettingsOffsetDefaultUsdTerminal = 34;
  uint256 private constant SettingsOffsetApplyHedge = 35;

  /**
   * @notice Funding cycle datasource implementation that keeps contributions split between Ether and DAI according to pre-defined params. This contract stores per-project configuration so only a single instance is needed for the platform. Usage of this contract is optional for projects.
   *
   * @param _jbxOperatorStore Juicebox OperatorStore to manage per-project permissions.
   * @param _jbxDirectory Juicebox Directory for terminal lookup.
   * @param _jbxProjects Juicebox Projects ownership NFT.
   * @param _defaultEthTerminal Default Eth terminal.
   * @param _defaultUsdTerminal Default DAI terminal.
   * @param _terminalStore Juicebox TerminalStore to track token balances.
   */
  constructor(
    IJBOperatorStore _jbxOperatorStore,
    IJBDirectory _jbxDirectory,
    IERC721 _jbxProjects,
    IJBSingleTokenPaymentTerminal _defaultEthTerminal,
    IJBSingleTokenPaymentTerminal _defaultUsdTerminal,
    IJBSingleTokenPaymentTerminalStore _terminalStore
  ) {
    operatorStore = _jbxOperatorStore; // JBOperatable

    jbxDirectory = _jbxDirectory;
    jbxProjects = _jbxProjects;

    defaultEthTerminal = _defaultEthTerminal;
    defaultUsdTerminal = _defaultUsdTerminal;
    terminalStore = _terminalStore;
  }

  //*********************************************************************//
  // ------------------------ external functions ----------------------- //
  //*********************************************************************//

  /**
   * @notice Sets project params. This function requires `MANAGE_PAYMENTS` operation privilege.
   *
   * @dev Multiple conditions need to be met for this delegate to attempt swaps between Ether and DAI. Eth/DAI ratio must be away from desired (_ethShare) by at least (_balanceThreshold). Incoming contribution amount must be larger than either _ethThreshold or _usdThreshold depending on denomination.
   *
   * @dev Rather than setting _ethShare to 10_000 (100%), disable hedging or remove the datasource delegate from the funding cycle config to save gas. Similarly setting _ethShare to 0 is more cheaply accomplished by removing the Eth terminal from the project to require contributions in DAI only.
   *
   * @param _projectId Project id to modify settings for.
   * @param _applyHedge Enable hedging.
   * @param _ethShare Target Ether share of the total. Expressed in basis points, setting it to 6000 will make the targer 60% Ether, 40% DAI.
   * @param _balanceThreshold Distance from targer threshold at which to take action.
   * @param _ethThreshold Ether contribution threshold, below this number trandes won't be attempted.
   * @param _usdThreshold Dai contribution threshold, below this number trandes won't be attempted.
   * @param _flags Sets flags requiring live quotes, and allowing use of default token terminals instead of performing look ups to save gas.
   */
  function setHedgeParameters(
    uint256 _projectId,
    bool _applyHedge,
    uint256 _ethShare,
    uint256 _balanceThreshold,
    uint256 _ethThreshold,
    uint256 _usdThreshold,
    HedgeFlags memory _flags
  )
    external
    requirePermissionAllowingOverride(
      jbxProjects.ownerOf(_projectId),
      _projectId,
      JBOperations.MANAGE_PAYMENTS,
      (msg.sender == address(jbxDirectory.controllerOf(_projectId)))
    )
  {
    uint256 settings = uint16(_ethShare);
    settings |= uint256(uint16(_balanceThreshold)) << SettingsOffsetBalanceThreshold;
    settings = setBoolean(settings, SettingsOffsetLiveQuote, _flags.liveQuote);
    settings = setBoolean(settings, SettingsOffsetDefaultEthTerminal, _flags.defaultEthTerminal);
    settings = setBoolean(settings, SettingsOffsetDefaultUsdTerminal, _flags.defaultUsdTerminal);
    settings = setBoolean(settings, SettingsOffsetApplyHedge, _applyHedge);

    projectHedgeSettings[_projectId] = HedgeSettings(_ethThreshold, _usdThreshold, settings);
  }

  /**
   * @notice IJBPayDelegate implementation
   *
   * @notice Will swap ether to DAI or the reverse subject to project-defined constraints. See setHedgeParameters() for requirements.
   */
  function didPay(JBDidPayData calldata _data) public payable override {
    HedgeSettings memory settings = projectHedgeSettings[_data.projectId];

    if (!getBoolean(settings.settings, SettingsOffsetApplyHedge)) {
      return; // TODO: may retain funds, needs tests
    }

    if (_data.amount.token == JBTokens.ETH) {
      // eth -> dai

      IJBSingleTokenPaymentTerminal ethTerminal = getProjectTerminal(
        JBCurrencies.ETH,
        getBoolean(settings.settings, SettingsOffsetDefaultEthTerminal),
        _data.projectId
      );

      if (uint16(settings.settings) == 10_000) {
        // 100% eth
        ethTerminal.addToBalanceOf{value: msg.value}(
          _data.projectId,
          msg.value,
          JBTokens.ETH,
          _data.memo,
          _data.metadata
        );

        return;
      }

      if (uint16(settings.settings) == 0) {
        // 0% eth

        IJBSingleTokenPaymentTerminal daiTerminal = getProjectTerminal(
          JBCurrencies.USD,
          getBoolean(settings.settings, SettingsOffsetDefaultUsdTerminal),
          _data.projectId
        );

        _weth.deposit{value: _data.forwardedAmount.value}();
        _weth.approve(address(_swapRouter), _data.forwardedAmount.value);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
          tokenIn: address(_weth),
          tokenOut: address(_dai),
          fee: poolFee,
          recipient: address(this),
          deadline: block.timestamp,
          amountIn: _data.forwardedAmount.value,
          amountOutMinimum: 0, // TODO: consider setting amount
          sqrtPriceLimitX96: 0
        });

        uint256 amountOut = _swapRouter.exactInputSingle(params);
        _weth.approve(address(_swapRouter), 0);

        _dai.approve(address(daiTerminal), amountOut);
        daiTerminal.addToBalanceOf(
          _data.projectId,
          amountOut,
          address(_dai),
          _data.memo,
          _data.metadata
        );
        _dai.approve(address(daiTerminal), 0);

        return;
      }

      // (depositEth - x + currentEth) / (currentUsdEth + x) = ethShare/usdShare
      // x = (depositEth + currentEth - currentUsdEth * ethShare/usdShare) / (ethShare/usdShare + 1)
      // NOTE: in this case this should be the same as msg.value
      if (_data.forwardedAmount.value >= settings.ethThreshold) {
        uint256 projectEthBalance = terminalStore.balanceOf(ethTerminal, _data.projectId);

        (uint256 projectUsdBalance, IJBPaymentTerminal daiTerminal) = getProjectBalance(
          JBCurrencies.USD,
          getBoolean(settings.settings, SettingsOffsetDefaultUsdTerminal),
          _data.projectId
        );

        uint256 projectUsdBalanceEthValue;
        if (
          getBoolean(settings.settings, SettingsOffsetLiveQuote) ||
          recentPriceTimestamp < block.timestamp - 43_200
        ) {
          recentPrice = _swapQuoter.quoteExactOutputSingle(
            address(_dai),
            address(_weth),
            poolFee,
            1000000000000000000,
            0
          );
          recentPriceTimestamp = block.timestamp;
        }
        projectUsdBalanceEthValue = (projectUsdBalance * (10 ** 18)) / recentPrice;
        // value of the project's eth balance after adding current contribution
        uint256 newEthBalance;
        uint256 newEthShare;
        {
          newEthBalance = projectEthBalance + _data.forwardedAmount.value;
          uint256 totalEthBalance = newEthBalance + projectUsdBalanceEthValue;
          newEthShare = (newEthBalance * bps) / totalEthBalance;
        }

        if (
          newEthShare > uint16(settings.settings) &&
          newEthShare - uint16(settings.settings) >
          uint16(settings.settings >> SettingsOffsetBalanceThreshold)
        ) {
          uint256 ratio;
          {
            ratio = ((projectUsdBalanceEthValue * uint16(settings.settings)) /
              (bps - uint16(settings.settings)));
          }
          uint256 swapAmount;
          if (newEthBalance < ratio) {
            swapAmount = _data.forwardedAmount.value;
          } else {
            uint256 numerator = newEthBalance - ratio;
            uint256 denominator = (uint16(settings.settings) * bps) /
              (bps - uint16(settings.settings)) +
              bps;
            swapAmount = (numerator / denominator) * bps;
          }

          {
            _weth.deposit{value: swapAmount}();
            _weth.approve(address(_swapRouter), swapAmount);

            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
              tokenIn: address(_weth),
              tokenOut: address(_dai),
              fee: poolFee,
              recipient: address(this),
              deadline: block.timestamp,
              amountIn: swapAmount,
              amountOutMinimum: 0, // TODO: consider setting amount
              sqrtPriceLimitX96: 0
            });

            uint256 amountOut = _swapRouter.exactInputSingle(params);
            _weth.approve(address(_swapRouter), 0);

            _dai.approve(address(daiTerminal), amountOut);
            daiTerminal.addToBalanceOf(_data.projectId, amountOut, address(_dai), '', '');
            _dai.approve(address(daiTerminal), 0);
          }
          {
            uint256 remainingEth = _data.forwardedAmount.value - swapAmount;
            ethTerminal.addToBalanceOf{value: remainingEth}(
              _data.projectId,
              remainingEth,
              JBTokens.ETH,
              '',
              ''
            );
          }
        } else {
          ethTerminal.addToBalanceOf{value: msg.value}(
            _data.projectId,
            msg.value,
            JBTokens.ETH,
            '',
            ''
          );
        }
      } else {
        ethTerminal.addToBalanceOf{value: msg.value}(
          _data.projectId,
          msg.value,
          JBTokens.ETH,
          '',
          ''
        );
      }
    } else if (_data.amount.token == address(_dai)) {
      // dai -> eth

      // (currentEth + x) / (currentUsdEth + depositUsdEth - x) = ethShare/usdShare
      // x = (ethShare/usdShare * (currentUsdEth + depositUsdEth) - currentEth) / (1 + ethShare/usdShare)
      IJBSingleTokenPaymentTerminal daiTerminal = getProjectTerminal(
        JBCurrencies.USD,
        getBoolean(settings.settings, SettingsOffsetDefaultUsdTerminal),
        _data.projectId
      );

      if (uint16(settings.settings) == 10_000) {
        // 100% eth

        IJBSingleTokenPaymentTerminal ethTerminal = getProjectTerminal(
          JBCurrencies.ETH,
          getBoolean(settings.settings, SettingsOffsetDefaultEthTerminal),
          _data.projectId
        );

        _dai.transferFrom(msg.sender, address(this), _data.forwardedAmount.value);
        _dai.approve(address(_swapRouter), _data.forwardedAmount.value);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
          tokenIn: address(_dai),
          tokenOut: address(_weth),
          fee: poolFee,
          recipient: address(this),
          deadline: block.timestamp,
          amountIn: _data.forwardedAmount.value,
          amountOutMinimum: 0, // TODO: consider setting amount
          sqrtPriceLimitX96: 0
        });

        uint256 amountOut = _swapRouter.exactInputSingle(params);
        _dai.approve(address(_swapRouter), 0);
        _weth.withdraw(amountOut);

        ethTerminal.addToBalanceOf{value: amountOut}(
          _data.projectId,
          amountOut,
          JBTokens.ETH,
          _data.memo,
          _data.metadata
        );

        return;
      }

      if (uint16(settings.settings) == 0) {
        // 0% eth
        _dai.transferFrom(msg.sender, address(this), _data.forwardedAmount.value);
        _dai.approve(address(daiTerminal), _data.forwardedAmount.value);
        daiTerminal.addToBalanceOf(
          _data.projectId,
          _data.forwardedAmount.value,
          address(_dai),
          _data.memo,
          _data.metadata
        );
        _dai.approve(address(daiTerminal), 0);

        return;
      }

      if (_data.forwardedAmount.value >= settings.usdThreshold) {
        (uint256 projectEthBalance, IJBPaymentTerminal ethTerminal) = getProjectBalance(
          JBCurrencies.ETH,
          getBoolean(settings.settings, SettingsOffsetDefaultEthTerminal),
          _data.projectId
        );
        (uint256 projectUsdBalance, ) = getProjectBalance(
          JBCurrencies.USD,
          getBoolean(settings.settings, SettingsOffsetDefaultUsdTerminal),
          _data.projectId
        );

        if (
          getBoolean(settings.settings, SettingsOffsetLiveQuote) ||
          recentPriceTimestamp < block.timestamp - 43200
        ) {
          recentPrice = _swapQuoter.quoteExactOutputSingle(
            address(_dai),
            address(_weth),
            poolFee,
            1000000000000000000,
            0
          );
          recentPriceTimestamp = block.timestamp;
        }
        // value of the project's dai balance in terms of eth after adding current contribution
        uint256 projectUsdBalanceEthValue = ((projectUsdBalance + _data.forwardedAmount.value) *
          10 ** 18) / recentPrice;
        uint256 totalEthBalance = projectEthBalance + projectUsdBalanceEthValue;
        uint256 newEthShare = (projectEthBalance * bps) / totalEthBalance;

        if (
          newEthShare < uint16(settings.settings) &&
          uint16(settings.settings) - newEthShare >
          uint16(settings.settings >> SettingsOffsetBalanceThreshold)
        ) {
          uint256 ratio = (bps * uint16(settings.settings)) / (bps - uint16(settings.settings));
          uint256 swapAmount;

          if ((projectEthBalance * bps) > ratio * projectUsdBalanceEthValue) {
            swapAmount = _data.forwardedAmount.value;
          } else {
            uint256 numerator = ratio * projectUsdBalanceEthValue - (projectEthBalance * bps);
            uint256 denominator = bps + ratio;

            swapAmount = numerator / denominator;
            swapAmount = (swapAmount * recentPrice) / 10 ** 18;
          }

          uint256 amountOut;
          {
            _dai.transferFrom(msg.sender, address(this), _data.forwardedAmount.value);
            _dai.approve(address(_swapRouter), swapAmount);

            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
              tokenIn: address(_dai),
              tokenOut: address(_weth),
              fee: poolFee,
              recipient: address(this),
              deadline: block.timestamp,
              amountIn: swapAmount,
              amountOutMinimum: 0, // TODO: consider setting amount
              sqrtPriceLimitX96: 0
            });

            amountOut = _swapRouter.exactInputSingle(params);

            _dai.approve(address(_swapRouter), 0);

            _weth.withdraw(amountOut);
          }
          ethTerminal.addToBalanceOf{value: amountOut}(
            _data.projectId,
            amountOut,
            JBTokens.ETH,
            '',
            ''
          );

          uint256 remainder = _data.forwardedAmount.value - swapAmount;

          _dai.approve(address(daiTerminal), remainder);
          daiTerminal.addToBalanceOf(_data.projectId, remainder, address(_dai), '', '');
          _dai.approve(address(daiTerminal), 0);
        } else {
          _dai.transferFrom(msg.sender, address(this), _data.forwardedAmount.value);
          _dai.approve(address(daiTerminal), _data.forwardedAmount.value);
          daiTerminal.addToBalanceOf(
            _data.projectId,
            _data.forwardedAmount.value,
            address(_dai),
            _data.memo,
            _data.metadata
          );
          _dai.approve(address(daiTerminal), 0);
        }
      } else {
        _dai.transferFrom(msg.sender, address(this), _data.forwardedAmount.value);
        _dai.approve(address(daiTerminal), _data.forwardedAmount.value);
        daiTerminal.addToBalanceOf(
          _data.projectId,
          _data.forwardedAmount.value,
          address(_dai),
          _data.memo,
          _data.metadata
        );
        _dai.approve(address(daiTerminal), 0);
      }
    }
  }

  /**
   * @notice IJBRedemptionDelegate implementation
   *
   * @notice NOT SUPPORTED, set fundingCycleMetadata.useDataSourceForRedeem to false when deploying.
   */
  function didRedeem(JBDidRedeemData calldata) public payable override {
    revert REDEEM_NOT_SUPPORTED();
  }

  /**
   * @notice IJBFundingCycleDataSource implementation
   *
   * @dev This function will pass through the weight and amount parameters from the incoming data argument but will add self as the delegate address.
   */
  function payParams(
    JBPayParamsData calldata _data
  )
    public
    view
    override
    returns (
      uint256 weight,
      string memory memo,
      JBPayDelegateAllocation[] memory delegateAllocations
    )
  {
    weight = _data.weight;
    memo = _data.memo;
    delegateAllocations = new JBPayDelegateAllocation[](1);
    delegateAllocations[0] = JBPayDelegateAllocation({
      delegate: IJBPayDelegate(address(this)),
      amount: _data.amount.value
    });
  }

  /**
   * @notice IJBFundingCycleDataSource implementation
   *
   * @notice NOT SUPPORTED, set fundingCycleMetadata.useDataSourceForRedeem to false when deploying.
   */
  function redeemParams(
    JBRedeemParamsData calldata _data
  )
    public
    pure
    override
    returns (
      uint256 reclaimAmount,
      string memory memo,
      JBRedemptionDelegateAllocation[] memory delegateAllocations
    )
  {
    revert REDEEM_NOT_SUPPORTED();
  }

  /**
   * @notice IERC165 implementation
   */
  function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
    return
      interfaceId == type(IJBFundingCycleDataSource).interfaceId ||
      interfaceId == type(IJBPayDelegate).interfaceId ||
      interfaceId == type(IJBRedemptionDelegate).interfaceId;
  }

  /**
   * @dev WETH withdraw() payment is sent here before execution proceeds in the original function.
   */
  // solhint-disable-next-line no-empty-blocks
  receive() external payable {}

  //*********************************************************************//
  // ------------------------ internal functions ----------------------- //
  //*********************************************************************//
  function getProjectBalance(
    uint256 _currency,
    bool _useDefaultTerminal,
    uint256 _projectId
  ) internal view returns (uint256 balance, IJBSingleTokenPaymentTerminal terminal) {
    if (_currency == JBCurrencies.ETH) {
      terminal = IJBSingleTokenPaymentTerminal(defaultEthTerminal);
      if (!_useDefaultTerminal) {
        terminal = IJBSingleTokenPaymentTerminal(
          address(jbxDirectory.primaryTerminalOf(_projectId, JBTokens.ETH))
        );
      }

      balance = terminalStore.balanceOf(terminal, _projectId);
    } else if (_currency == JBCurrencies.USD) {
      terminal = defaultUsdTerminal;
      if (!_useDefaultTerminal) {
        terminal = IJBSingleTokenPaymentTerminal(
          address(jbxDirectory.primaryTerminalOf(_projectId, address(_dai)))
        );
      }
      balance = terminalStore.balanceOf(terminal, _projectId);
    }
  }

  function getProjectTerminal(
    uint256 _currency,
    bool _useDefaultTerminal,
    uint256 _projectId
  ) internal view returns (IJBSingleTokenPaymentTerminal terminal) {
    if (_currency == JBCurrencies.ETH) {
      terminal = IJBSingleTokenPaymentTerminal(defaultEthTerminal);
      if (!_useDefaultTerminal) {
        terminal = IJBSingleTokenPaymentTerminal(
          address(jbxDirectory.primaryTerminalOf(_projectId, JBTokens.ETH))
        );
      }
    } else if (_currency == JBCurrencies.USD) {
      terminal = defaultUsdTerminal;
      if (!_useDefaultTerminal) {
        terminal = IJBSingleTokenPaymentTerminal(
          address(jbxDirectory.primaryTerminalOf(_projectId, address(_dai)))
        );
      }
    }
  }

  //*********************************************************************//
  // ------------------------------ utils ------------------------------ //
  //*********************************************************************//

  function getBoolean(uint256 _source, uint256 _index) internal pure returns (bool) {
    uint256 flag = (_source >> _index) & uint256(1);
    return (flag == 1 ? true : false);
  }

  function setBoolean(
    uint256 _source,
    uint256 _index,
    bool _value
  ) internal pure returns (uint256 update) {
    if (_value) {
      update = _source | (uint256(1) << _index);
    } else {
      update = _source & ~(uint256(1) << _index);
    }
  }
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

import './IJBOperatorStore.sol';

interface IJBOperatable {
  function operatorStore() external view returns (IJBOperatorStore);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

interface IJBPriceFeed {
  function currentPrice(uint256 _targetDecimals) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

import './IJBPaymentTerminal.sol';

interface IJBSingleTokenPaymentTerminal is IJBPaymentTerminal {
  function token() external view returns (address);

  function currency() external view returns (uint256);

  function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../structs/JBFundingCycle.sol';
import './../structs/JBPayDelegateAllocation.sol';
import './../structs/JBRedemptionDelegateAllocation.sol';
import './../structs/JBTokenAmount.sol';
import './IJBDirectory.sol';
import './IJBFundingCycleStore.sol';
import './IJBPrices.sol';
import './IJBSingleTokenPaymentTerminal.sol';

interface IJBSingleTokenPaymentTerminalStore {
  function fundingCycleStore() external view returns (IJBFundingCycleStore);

  function directory() external view returns (IJBDirectory);

  function prices() external view returns (IJBPrices);

  function balanceOf(IJBSingleTokenPaymentTerminal _terminal, uint256 _projectId)
    external
    view
    returns (uint256);

  function usedDistributionLimitOf(
    IJBSingleTokenPaymentTerminal _terminal,
    uint256 _projectId,
    uint256 _fundingCycleNumber
  ) external view returns (uint256);

  function usedOverflowAllowanceOf(
    IJBSingleTokenPaymentTerminal _terminal,
    uint256 _projectId,
    uint256 _fundingCycleConfiguration
  ) external view returns (uint256);

  function currentOverflowOf(IJBSingleTokenPaymentTerminal _terminal, uint256 _projectId)
    external
    view
    returns (uint256);

  function currentTotalOverflowOf(
    uint256 _projectId,
    uint256 _decimals,
    uint256 _currency
  ) external view returns (uint256);

  function currentReclaimableOverflowOf(
    IJBSingleTokenPaymentTerminal _terminal,
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
    address _beneficiary,
    string calldata _memo,
    bytes calldata _metadata
  )
    external
    returns (
      JBFundingCycle memory fundingCycle,
      uint256 tokenCount,
      JBPayDelegateAllocation[] memory delegateAllocations,
      string memory memo
    );

  function recordRedemptionFor(
    address _holder,
    uint256 _projectId,
    uint256 _tokenCount,
    string calldata _memo,
    bytes calldata _metadata
  )
    external
    returns (
      JBFundingCycle memory fundingCycle,
      uint256 reclaimAmount,
      JBRedemptionDelegateAllocation[] memory delegateAllocations,
      string memory memo
    );

  function recordDistributionFor(
    uint256 _projectId,
    uint256 _amount,
    uint256 _currency
  ) external returns (JBFundingCycle memory fundingCycle, uint256 distributedAmount);

  function recordUsedAllowanceOf(
    uint256 _projectId,
    uint256 _amount,
    uint256 _currency
  ) external returns (JBFundingCycle memory fundingCycle, uint256 withdrawnAmount);

  function recordAddedBalanceFor(uint256 _projectId, uint256 _amount) external;

  function recordMigration(uint256 _projectId) external returns (uint256 balance);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBTokenUriResolver {
  function getUri(uint256 _projectId) external view returns (string memory tokenUri);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library JBCurrencies {
  uint256 public constant ETH = 1;
  uint256 public constant USD = 2;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice Defines permissions as indicies in a uint256, as such, must be between 1 and 255.
 */
library JBOperations {
  uint256 public constant RECONFIGURE = 1;
  uint256 public constant REDEEM = 2;
  uint256 public constant MIGRATE_CONTROLLER = 3;
  uint256 public constant MIGRATE_TERMINAL = 4;
  uint256 public constant PROCESS_FEES = 5;
  uint256 public constant SET_METADATA = 6;
  uint256 public constant ISSUE = 7;
  uint256 public constant SET_TOKEN = 8;
  uint256 public constant MINT = 9;
  uint256 public constant BURN = 10;
  uint256 public constant CLAIM = 11;
  uint256 public constant TRANSFER = 12;
  uint256 public constant REQUIRE_CLAIM = 13; // unused in v3
  uint256 public constant SET_CONTROLLER = 14;
  uint256 public constant SET_TERMINALS = 15;
  uint256 public constant SET_PRIMARY_TERMINAL = 16;
  uint256 public constant USE_ALLOWANCE = 17;
  uint256 public constant SET_SPLITS = 18;
  uint256 public constant MANAGE_PAYMENTS = 254;
  uint256 public constant MANAGE_ROLES = 255;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library JBTokens {
  /** 
    @notice 
    The ETH token address in Juicebox is represented by 0x000000000000000000000000000000000000EEEe.
  */
  address public constant ETH = address(0x000000000000000000000000000000000000EEEe);
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

/** 
  @member operator The address of the operator.
  @member domain The domain within which the operator is being given permissions. A domain of 0 is a wildcard domain, which gives an operator access to all domains.
  @member permissionIndexes The indexes of the permissions the operator is being given.
*/
struct JBOperatorData {
  address operator;
  uint256 domain;
  uint256[] permissionIndexes;
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