// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../PaymentProcessor.sol';
import '../../../interfaces/IJBDirectory.sol';
import '../../../interfaces/IJBOperatorStore.sol';
import '../../../interfaces/IJBProjects.sol';
import '../../TokenLiquidator.sol';

/**
 * @notice Creates an instance of PaymentProcessor contract
 */
library PaymentProcessorFactory {
  /**
   * @notice Deploys a PaymentProcessor.
   */
  function createPaymentProcessor(
    IJBDirectory _jbxDirectory,
    IJBOperatorStore _jbxOperatorStore,
    IJBProjects _jbxProjects,
    ITokenLiquidator _liquidator,
    uint256 _jbxProjectId,
    bool _ignoreFailures,
    bool _defaultLiquidation
  ) external returns (address paymentProcessor) {
    PaymentProcessor p = new PaymentProcessor(
      _jbxDirectory,
      _jbxOperatorStore,
      _jbxProjects,
      _liquidator,
      _jbxProjectId,
      _ignoreFailures,
      _defaultLiquidation
    );

    return address(p);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

import '../abstract/JBOperatable.sol';
import '../interfaces/IJBDirectory.sol';
import '../interfaces/IJBOperatorStore.sol';
import '../interfaces/IJBProjects.sol';
import '../interfaces/IJBPaymentTerminal.sol';
import '../libraries/JBOperations.sol';
import '../libraries/JBTokens.sol';
import './TokenLiquidator.sol';

/**
 * @notice Project payment collection contract.
 *
 * This contract is functionally similar to JBETHERC20ProjectPayer, but it adds several useful features. This contract can accept a token and liquidate it on Uniswap if an appropriate terminal doesn't exist. This contract can be configured accept and retain the payment if certain failures occur, like funding cycle misconfiguration. This contract expects to have access to a project terminal for Eth and WETH. WETH terminal will be used to submit liquidation proceeds.
 */
contract PaymentProcessor is JBOperatable, ReentrancyGuard {
  error PAYMENT_FAILURE();
  error INVALID_ADDRESS();
  error INVALID_AMOUNT();

  struct TokenSettings {
    bool accept;
    bool liquidate;
  }

  address public constant WETH9 = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  ISwapRouter public constant uniswapRouter =
    ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

  IJBDirectory jbxDirectory;
  IJBProjects jbxProjects;
  ITokenLiquidator liquidator;
  uint256 jbxProjectId;
  bool ignoreFailures;
  bool defaultLiquidation;

  mapping(IERC20 => TokenSettings) tokenPreferences;

  /**
   * @notice This contract serves as a proxy between the payer and the Juicebox platform. It allows payment acceptance in case of Juicebox project misconfiguration. It allows acceptance of ERC20 tokens via liquidation even if there is no corresponding Juicebox payment terminal.
   *
   * @param _jbxDirectory Juicebox directory.
   * @param _jbxOperatorStore Juicebox operator store.
   * @param _jbxProjects Juicebox project registry.
   * @param _liquidator Platform liquidator contract.
   * @param _jbxProjectId Juicebox project id to pay into.
   * @param _ignoreFailures If payment forwarding to the Juicebox terminal fails, Ether will be retained in this contract and ERC20 tokens will be processed per stored instructions. Setting this to false will `revert` failed payment operations.
   * @param _defaultLiquidation Setting this to true will automatically attempt to convert the incoming ERC20 tokens into WETH via Uniswap unless there are specific settings for the given token. Setting it to false will attempt to send the tokens to an appropriate Juicebox terminal, on failure, _ignoreFailures will be followed.
   */
  constructor(
    IJBDirectory _jbxDirectory,
    IJBOperatorStore _jbxOperatorStore,
    IJBProjects _jbxProjects,
    ITokenLiquidator _liquidator,
    uint256 _jbxProjectId,
    bool _ignoreFailures,
    bool _defaultLiquidation
  ) {
    operatorStore = _jbxOperatorStore;

    jbxDirectory = _jbxDirectory;
    jbxProjects = _jbxProjects;
    liquidator = _liquidator;
    jbxProjectId = _jbxProjectId;
    ignoreFailures = _ignoreFailures;
    defaultLiquidation = _defaultLiquidation;
  }

  //*********************************************************************//
  // ----------------------- public transactions ----------------------- //
  //*********************************************************************//

  /**
   * @notice Forwards incoming Ether to Juicebox terminal.
   */
  receive() external payable {
    _processPayment(jbxProjectId, '', new bytes(0));
  }

  /**
   * @notice Forwards incoming Ether to Juicebox terminal.
   *
   * @param _memo Memo for the payment, can be blank, will be forwarded to the Juicebox terminal for event publication.
   * @param _metadata Metadata for the payment, can be blank, will be forwarded to the Juicebox terminal for event publication.
   */
  function processPayment(
    string memory _memo,
    bytes memory _metadata
  ) external payable nonReentrant {
    _processPayment(jbxProjectId, _memo, _metadata);
  }

  /**
   * @notice Forwards incoming tokens to a Juicebox terminal, optionally liquidates them.
   *
   * @dev Tokens for the given amount must already be approved for this contract.
   *
   * @dev If the incoming token is explicitly listed via `setTokenPreferences`, `accept` setting will be applied. Otherwise, if `defaultLiquidation` is enabled, that will be used. Otherwise if ignoreFailures is enabled, token amount will be transferred and stored in this contract. If none of the previous conditions are met, the function will revert.
   *
   * @param _token ERC20 token.
   * @param _amount Token amount to withdraw from the sender.
   * @param _minValue Optional minimum Ether liquidation value.
   * @param _memo Memo for the payment, can be blank, will be forwarded to the Juicebox terminal for event publication.
   * @param _metadata Metadata for the payment, can be blank, will be forwarded to the Juicebox terminal for event publication.
   */
  function processPayment(
    IERC20 _token,
    uint256 _amount,
    uint256 _minValue,
    string memory _memo,
    bytes memory _metadata
  ) external nonReentrant {
    TokenSettings memory settings = tokenPreferences[_token];
    if (settings.accept) {
      _processPayment(
        _token,
        _amount,
        _minValue,
        jbxProjectId,
        _memo,
        _metadata,
        settings.liquidate
      );
    } else if (defaultLiquidation) {
      _processPayment(_token, _amount, _minValue, jbxProjectId, _memo, _metadata, true);
    } else if (ignoreFailures) {
      _token.transferFrom(msg.sender, address(this), _amount);
    } else {
      revert PAYMENT_FAILURE();
    }
  }

  function canProcess(IERC20 _token) external view returns (bool accept) {
    accept = tokenPreferences[_token].accept || defaultLiquidation;
  }

  //*********************************************************************//
  // --------------------- privileged transactions --------------------- //
  //*********************************************************************//

  /**
   * @notice Registers specific preferences for a given token. This feature is optional. If no tokens are explicitly set as "acceptable" and defaultLiquidate is set to false, token payments into this contract will be rejected.
   *
   * @param _token Token to accept.
   * @param _acceptToken Acceptance flag, setting it to false removes the associated record from the registry.
   * @param _liquidateToken Liquidation flag, it's possible to accept a token and forward it as is to a terminal, accept it and retain it in this contract or accept it and liduidate it for WETH via Uniswap.
   */
  function setTokenPreferences(
    IERC20 _token,
    bool _acceptToken,
    bool _liquidateToken
  )
    external
    requirePermissionAllowingOverride(
      jbxProjects.ownerOf(jbxProjectId),
      jbxProjectId,
      JBOperations.MANAGE_PAYMENTS,
      (msg.sender == address(jbxDirectory.controllerOf(jbxProjectId)))
    )
  {
    if (!_acceptToken) {
      delete tokenPreferences[_token];
    } else {
      tokenPreferences[_token] = TokenSettings(_acceptToken, _liquidateToken);
    }
  }

  /**
   * @notice Allows the contract manager (an account with JBOperations.MANAGE_PAYMENTS permission for this project) to set operation parameters. The most-restrictive more is false-false, in which case only the tokens explicitly set as `accept` via setTokenPreferences will be processed.
   *
   * @param _ignoreFailures Ignore some payment failures, this results in processPayment() calls succeeding in more cases and the contract accumulating an Ether or token balance.
   * @param _defaultLiquidation If a given token doesn't have a specific configuration, the payment would still be accepted and liquidated into WETH as part of the payment transaction.
   */
  function setDefaults(
    bool _ignoreFailures,
    bool _defaultLiquidation
  )
    external
    requirePermissionAllowingOverride(
      jbxProjects.ownerOf(jbxProjectId),
      jbxProjectId,
      JBOperations.MANAGE_PAYMENTS,
      (msg.sender == address(jbxDirectory.controllerOf(jbxProjectId)))
    )
  {
    ignoreFailures = _ignoreFailures;
    defaultLiquidation = _defaultLiquidation;
  }

  /**
   * @notice Allows a caller with JBOperations.MANAGE_PAYMENTS permission for the given project, or the project controller to transfer an Ether balance held in this contract.
   */
  function transferBalance(
    address payable _destination,
    uint256 _amount
  )
    external
    nonReentrant
    requirePermissionAllowingOverride(
      jbxProjects.ownerOf(jbxProjectId),
      jbxProjectId,
      JBOperations.MANAGE_PAYMENTS,
      (msg.sender == address(jbxDirectory.controllerOf(jbxProjectId)))
    )
  {
    if (_destination == address(0)) {
      revert INVALID_ADDRESS();
    }

    if (_amount == 0 || _amount > (payable(address(this))).balance) {
      revert INVALID_AMOUNT();
    }

    _destination.transfer(_amount);
  }

  /**
   * @notice Allows a caller with JBOperations.MANAGE_PAYMENTS permission for the given project, or the project controller to transfer an ERC20 token balance associated with this contract.
   *
   * @param _destination Account to assign token balance to.
   * @param _token ERC20 token to operate on.
   * @param _amount Token amount to transfer.
   *
   * @return ERC20 transfer function result.
   */
  function transferTokens(
    address _destination,
    IERC20 _token,
    uint256 _amount
  )
    external
    nonReentrant
    requirePermissionAllowingOverride(
      jbxProjects.ownerOf(jbxProjectId),
      jbxProjectId,
      JBOperations.MANAGE_PAYMENTS,
      (msg.sender == address(jbxDirectory.controllerOf(jbxProjectId)))
    )
    returns (bool)
  {
    if (_destination == address(0)) {
      revert INVALID_ADDRESS();
    }

    return _token.transfer(_destination, _amount);
  }

  //*********************************************************************//
  // ---------------------- internal transactions ---------------------- //
  //*********************************************************************//

  /**
   * @notice Ether payment processing.
   */
  function _processPayment(
    uint256 _jbxProjectId,
    string memory _memo,
    bytes memory _metadata
  ) internal virtual {
    IJBPaymentTerminal terminal = jbxDirectory.primaryTerminalOf(_jbxProjectId, JBTokens.ETH);

    if (address(terminal) == address(0) && !ignoreFailures) {
      revert PAYMENT_FAILURE();
    }

    if (address(terminal) != address(0)) {
      (bool success, ) = address(terminal).call{value: msg.value}(
        abi.encodeWithSelector(
          terminal.pay.selector,
          _jbxProjectId,
          msg.value,
          JBTokens.ETH,
          msg.sender,
          0,
          false,
          _memo,
          _metadata
        )
      );

      if (!success) {
        revert PAYMENT_FAILURE();
      }
    }
  }

  /**
     * @notice Token payment processing that optionally liquidates incoming tokens for Ether.
     * 
     * @dev The result of this function depends on existence of a `tokenPreferences` record for the given token, `ignoreFailures` and
    `defaultLiquidation` global settings.
     *
     * @dev This function will still revert, regardless of `ignoreFailures`, if there is a liquidation event and the ether proceeds are below `_minValue`, unless that parameter is `0`.
     * 
     * @param _token ERC20 token to accept.
     * @param _amount Amount of token to expect.
     * @param _minValue Minimum required Ether value for token amount. Receiving less than this from Uniswap will cause a revert even is ignoreFailures is set.
     * @param _jbxProjectId Juicebox project id.
     * @param _memo IJBPaymentTerminal memo.
     * @param _metadata IJBPaymentTerminal metadata.
     * @param _liquidateToken Liquidation flag, if set the token will be converted into Ether and deposited into the project's Ether terminal.
     */
  function _processPayment(
    IERC20 _token,
    uint256 _amount,
    uint256 _minValue,
    uint256 _jbxProjectId,
    string memory _memo,
    bytes memory _metadata,
    bool _liquidateToken
  ) internal {
    if (_liquidateToken) {
      _liquidate(_token, _amount, _minValue, _jbxProjectId, _memo, _metadata);
      return;
    }

    IJBPaymentTerminal terminal = jbxDirectory.primaryTerminalOf(_jbxProjectId, address(_token));

    if (address(terminal) == address(0) && !ignoreFailures) {
      revert PAYMENT_FAILURE();
    }

    if (address(terminal) == address(0) && defaultLiquidation) {
      _liquidate(_token, _amount, _minValue, _jbxProjectId, _memo, _metadata);
      return;
    }

    if (!_token.transferFrom(msg.sender, address(this), _amount)) {
      revert PAYMENT_FAILURE();
    }

    _token.approve(address(terminal), _amount);

    (bool success, ) = address(terminal).call(
      abi.encodeWithSelector(
        terminal.pay.selector,
        jbxProjectId,
        _amount,
        address(_token),
        msg.sender,
        0,
        false,
        _memo,
        _metadata
      )
    );

    _token.approve(address(terminal), 0);

    if (success) {
      return;
    }

    if (!ignoreFailures) {
      revert PAYMENT_FAILURE();
    }

    if (ignoreFailures && defaultLiquidation) {
      _liquidate(_token, _amount, _minValue, _jbxProjectId, _memo, _metadata);

      return;
    }
  }

  /**
   * @dev Liquidates tokens for Eth or WETH from the transaction sender.
   */
  function _liquidate(
    IERC20 _token,
    uint256 _amount,
    uint256 _minValue,
    uint256 _jbxProjectId,
    string memory _memo,
    bytes memory _metadata
  ) internal {
    _token.transferFrom(msg.sender, address(this), _amount);
    _token.approve(address(liquidator), _amount);

    uint256 remainingAmount = liquidator.liquidateTokens(
      _token,
      _amount,
      _minValue,
      _jbxProjectId,
      msg.sender,
      _memo,
      _metadata
    );
    if (remainingAmount != 0) {
      _token.transfer(msg.sender, remainingAmount);
    }

    _token.approve(address(liquidator), 0);
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

import '../abstract/JBOperatable.sol';
import '../interfaces/IJBDirectory.sol';
import '../interfaces/IJBOperatorStore.sol';
import '../interfaces/IJBProjects.sol';
import '../interfaces/IJBPaymentTerminal.sol';
import '../libraries/JBOperations.sol';
import '../libraries/JBTokens.sol';

interface IWETH9 is IERC20 {
  function deposit() external payable;

  function withdraw(uint256) external;
}

enum TokenLiquidatorError {
  NO_TERMINALS_FOUND,
  INPUT_TOKEN_BLOCKED,
  INPUT_TOKEN_TRANSFER_FAILED,
  INPUT_TOKEN_APPROVAL_FAILED,
  ETH_TRANSFER_FAILED
}

interface ITokenLiquidator {
  receive() external payable;

  function liquidateTokens(
    IERC20 _token,
    uint256 _amount,
    uint256 _minValue,
    uint256 _jbxProjectId,
    address _beneficiary,
    string memory _memo,
    bytes memory _metadata
  ) external returns (uint256);

  function withdrawFees() external;

  function setProtocolFee(uint256 _feeBps) external;

  function setUniswapPoolFee(uint24 _uniswapPoolFee) external;

  function blockToken(IERC20 _token) external;

  function unblockToken(IERC20 _token) external;
}

contract TokenLiquidator is ITokenLiquidator, JBOperatable {
  enum TokenLiquidatorPaymentType {
    ETH_TO_SENDER, // TODO
    ETH_TO_TERMINAL,
    WETH_TO_TERMINAL
  }

  error LIQUIDATION_FAILURE(TokenLiquidatorError _errorCode);

  event AllowTokenLiquidation(IERC20 token);
  event PreventLiquidation(IERC20 token);

  address public constant WETH9 = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  ISwapRouter public constant uniswapRouter =
    ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

  uint256 internal constant FEE_CAP_BPS = 500; // 5%
  uint256 internal constant PROTOCOL_PROJECT_ID = 1;

  IJBDirectory public jbxDirectory;
  IJBProjects public jbxProjects;
  uint256 public feeBps;
  mapping(IERC20 => bool) blockedTokens;
  uint24 public uniswapPoolFee;

  IJBPaymentTerminal transientTerminal;
  uint256 transientProjectId;
  address transientBeneficiary;
  string transientMemo;
  bytes transientMetadata;
  address transientSender;

  /**
   * @param _jbxDirectory Juicebox directory for payment terminal lookup.
   * @param _feeBps Protocol swap fee.
   * @param  _uniswapPoolFee Uniswap pool fee.
   */
  constructor(
    IJBDirectory _jbxDirectory,
    IJBOperatorStore _jbxOperatorStore,
    IJBProjects _jbxProjects,
    uint256 _feeBps,
    uint24 _uniswapPoolFee
  ) {
    if (_feeBps > FEE_CAP_BPS) {
      revert();
    }

    operatorStore = _jbxOperatorStore;

    jbxDirectory = _jbxDirectory;
    jbxProjects = _jbxProjects;
    feeBps = _feeBps;
    uniswapPoolFee = _uniswapPoolFee;
  }

  receive() external payable override {}

  /**
   * @notice Swap incoming token for Ether/WETH and deposit the proceeeds into the appropriate Juicebox terminal.
   *
   * @dev If _minValue is specified, will call exactOutputSingle, otherwise exactInputSingle on uniswap v3.
   * @dev msg.sender here is expected to be an instance of PaymentProcessor which would retain the sale proceeds if they cannot be forwarded to the Ether or WETH terminal for the given project.
   *
   * @param _token Token to liquidate
   * @param _amount Token amount to liquidate.
   * @param _minValue Minimum required Ether/WETH value for the incoming token amount.
   * @param _jbxProjectId Juicebox project ID to pay into.
   * @param _beneficiary IJBPaymentTerminal beneficiary argument.
   * @param _memo IJBPaymentTerminal memo argument.
   * @param _metadata IJBPaymentTerminal metadata argument.
   */
  function liquidateTokens(
    IERC20 _token,
    uint256 _amount,
    uint256 _minValue,
    uint256 _jbxProjectId,
    address _beneficiary,
    string memory _memo,
    bytes memory _metadata
  ) external override returns (uint256 remainingAmount) {
    if (blockedTokens[_token]) {
      revert LIQUIDATION_FAILURE(TokenLiquidatorError.INPUT_TOKEN_BLOCKED);
    }

    if (!_token.transferFrom(msg.sender, address(this), _amount)) {
      revert LIQUIDATION_FAILURE(TokenLiquidatorError.INPUT_TOKEN_TRANSFER_FAILED);
    }

    TokenLiquidatorPaymentType paymentDestination;

    IJBPaymentTerminal ethTerminal = jbxDirectory.primaryTerminalOf(_jbxProjectId, JBTokens.ETH);

    if (ethTerminal != IJBPaymentTerminal(address(0))) {
      transientTerminal = ethTerminal;
      transientProjectId = _jbxProjectId;
      transientBeneficiary = _beneficiary;
      transientMemo = _memo;
      transientMetadata = _metadata;
      transientSender = msg.sender;

      paymentDestination = TokenLiquidatorPaymentType.ETH_TO_TERMINAL;
    } else {
      IJBPaymentTerminal wethTerminal = jbxDirectory.primaryTerminalOf(_jbxProjectId, WETH9);

      if (wethTerminal != IJBPaymentTerminal(address(0))) {
        transientTerminal = wethTerminal; // NOTE: transfers to a WETH terminal happen here, no need to set transient state
        paymentDestination = TokenLiquidatorPaymentType.WETH_TO_TERMINAL;
      }
    }

    if (transientTerminal == IJBPaymentTerminal(address(0))) {
      revert LIQUIDATION_FAILURE(TokenLiquidatorError.NO_TERMINALS_FOUND);
    }

    if (!_token.approve(address(uniswapRouter), _amount)) {
      revert LIQUIDATION_FAILURE(TokenLiquidatorError.INPUT_TOKEN_APPROVAL_FAILED);
    }

    uint256 swapProceeds;
    if (_minValue == 0) {
      ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
        tokenIn: address(_token),
        tokenOut: WETH9,
        fee: uniswapPoolFee,
        recipient: address(this),
        deadline: block.timestamp,
        amountIn: _amount,
        amountOutMinimum: 0,
        sqrtPriceLimitX96: 0
      });

      swapProceeds = uniswapRouter.exactInputSingle(params);
    } else {
      ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams({
        tokenIn: address(_token),
        tokenOut: WETH9,
        fee: uniswapPoolFee,
        recipient: address(this),
        deadline: block.timestamp,
        amountOut: _minValue,
        amountInMaximum: _amount,
        sqrtPriceLimitX96: 0
      });

      uint256 amountSpent = uniswapRouter.exactOutputSingle(params); // NOTE: this will revert if _minValue is not received
      swapProceeds = _minValue;

      if (amountSpent < _amount) {
        remainingAmount = _amount - amountSpent;
        _token.transfer(msg.sender, remainingAmount);
      }
    }

    _token.approve(address(uniswapRouter), 0);

    uint256 fee = (swapProceeds * feeBps) / 10_000;
    uint256 projectProceeds = swapProceeds - fee;

    if (paymentDestination == TokenLiquidatorPaymentType.ETH_TO_TERMINAL) {
      IWETH9(WETH9).withdraw(projectProceeds); // NOTE: will end up in receive()
      transientTerminal.pay{value: projectProceeds}(
        transientProjectId,
        projectProceeds,
        JBTokens.ETH,
        transientBeneficiary,
        0,
        false,
        transientMemo,
        transientMetadata
      );
    } else if (paymentDestination == TokenLiquidatorPaymentType.WETH_TO_TERMINAL) {
      IERC20(WETH9).approve(address(transientTerminal), projectProceeds);

      transientTerminal.pay(
        _jbxProjectId,
        projectProceeds,
        WETH9,
        _beneficiary,
        0,
        false,
        _memo,
        _metadata
      );

      IERC20(WETH9).approve(address(transientTerminal), 0);
      transientTerminal = IJBPaymentTerminal(address(0));
    }
  }

  /**
   * @notice A trustless way for withdraw WETH and Ether balances from this contract into the platform (project 1) terminal.
   */
  function withdrawFees() external override {
    IJBPaymentTerminal protocolTerminal = jbxDirectory.primaryTerminalOf(
      PROTOCOL_PROJECT_ID,
      WETH9
    );

    uint256 wethBalance = IERC20(WETH9).balanceOf(address(this));
    IERC20(WETH9).approve(address(protocolTerminal), wethBalance);

    protocolTerminal.pay(
      PROTOCOL_PROJECT_ID,
      wethBalance,
      WETH9,
      address(0),
      0,
      false,
      'TokenLiquidator fees',
      ''
    );

    IERC20(WETH9).approve(address(protocolTerminal), 0);

    if (address(this).balance != 0) {
      protocolTerminal = jbxDirectory.primaryTerminalOf(PROTOCOL_PROJECT_ID, JBTokens.ETH);
      protocolTerminal.pay{value: address(this).balance}(
        transientProjectId,
        address(this).balance,
        JBTokens.ETH,
        address(0),
        0,
        false,
        'TokenLiquidator fees',
        ''
      );
    }
  }

  /**
   * @notice Set protocol liquidation fee. This share of the swap proceeds will be taken out and kept for the protocol. Expressed in basis points.
   */
  function setProtocolFee(
    uint256 _feeBps
  )
    external
    override
    requirePermissionAllowingOverride(
      jbxProjects.ownerOf(PROTOCOL_PROJECT_ID),
      PROTOCOL_PROJECT_ID,
      JBOperations.MANAGE_PAYMENTS,
      (msg.sender == address(jbxDirectory.controllerOf(PROTOCOL_PROJECT_ID)))
    )
  {
    if (_feeBps > FEE_CAP_BPS) {
      revert();
    }

    feeBps = _feeBps;
  }

  /**
   * @notice Set Uniswap pool fee.
   */
  function setUniswapPoolFee(
    uint24 _uniswapPoolFee
  )
    external
    override
    requirePermissionAllowingOverride(
      jbxProjects.ownerOf(PROTOCOL_PROJECT_ID),
      PROTOCOL_PROJECT_ID,
      JBOperations.MANAGE_PAYMENTS,
      (msg.sender == address(jbxDirectory.controllerOf(PROTOCOL_PROJECT_ID)))
    )
  {
    uniswapPoolFee = _uniswapPoolFee;
  }

  /**
   * @notice Prevent liquidation of a specific token through the contract.
   */
  function blockToken(
    IERC20 _token
  )
    external
    override
    requirePermissionAllowingOverride(
      jbxProjects.ownerOf(PROTOCOL_PROJECT_ID),
      PROTOCOL_PROJECT_ID,
      JBOperations.MANAGE_PAYMENTS,
      (msg.sender == address(jbxDirectory.controllerOf(PROTOCOL_PROJECT_ID)))
    )
  {
    blockedTokens[_token] = true;
    emit PreventLiquidation(_token);
  }

  /**
   * @notice Remove a previously blocked token from the block list.
   */
  function unblockToken(
    IERC20 _token
  )
    external
    override
    requirePermissionAllowingOverride(
      jbxProjects.ownerOf(PROTOCOL_PROJECT_ID),
      PROTOCOL_PROJECT_ID,
      JBOperations.MANAGE_PAYMENTS,
      (msg.sender == address(jbxDirectory.controllerOf(PROTOCOL_PROJECT_ID)))
    )
  {
    if (blockedTokens[_token]) {
      delete blockedTokens[_token];
      emit AllowTokenLiquidation(_token);
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

interface IJBTokenUriResolver {
  function getUri(uint256 _projectId) external view returns (string memory tokenUri);
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

/** 
  @member content The metadata content.
  @member domain The domain within which the metadata applies.
*/
struct JBProjectMetadata {
  string content;
  uint256 domain;
}