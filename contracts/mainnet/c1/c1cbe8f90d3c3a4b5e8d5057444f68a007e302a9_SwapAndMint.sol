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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "./utils/ownable.sol";
import "./interfaces/IFactory.sol";
import "v3-periphery/interfaces/ISwapRouter.sol";
import "v3-periphery/libraries/TransferHelper.sol";

contract SwapAndMint {
  ISwapRouter public immutable router;
  FactoryInterface public immutable factory;
  IERC20 public immutable weth;
  IERC20 public immutable usdc;
  IERC20 public immutable amkt;
  string public constant depositAddress = "forge";

  address public swapper;
  address public admin;
  address public proposedAdmin;

  uint24 public constant poolFee = 3000;

  modifier only(address who) {
    require(msg.sender == who, "invalid permissions");
    _;
  }

  constructor(
    address _router,
    address _factory,
    address _usdc,
    address _weth,
    address _amkt,
    address _swapper,
    address _admin
  ) {
    router = ISwapRouter(_router);
    factory = FactoryInterface(_factory);
    weth = IERC20(_weth);
    usdc = IERC20(_usdc);
    amkt = IERC20(_amkt);
    swapper = _swapper;
    admin = _admin;
  }

  function swapAndMint(
    uint256 amountIn,
    uint256 amountOutMin,
    string calldata txid
  ) external only(swapper) {
    swapExactInput(amountIn, amountOutMin);
    addRequest(amountIn, txid);
  }

  function swapAndBurn(
    uint256 amountInMax,
    uint256 amountOut,
    string calldata txid
  ) external only(swapper) {
    swapExactOutput(amountInMax, amountOut);
    burnRequest(amountOut, txid);
  }

  ///////////////////////////// INTERNAL ///////////////////////////////////

  function swapExactInput(uint256 amountIn, uint256 amountOutMin)
    internal
    returns (uint256 amountOut)
  {
    ISwapRouter.ExactInputParams memory params;
    amkt.approve(address(router), amountIn);

    params = ISwapRouter.ExactInputParams({
      path: abi.encodePacked(
        address(amkt),
        poolFee,
        address(weth),
        poolFee,
        address(usdc)
      ),
      recipient: address(this),
      deadline: block.timestamp,
      amountIn: amountIn,
      amountOutMinimum: amountOutMin
    });

    // Executes the swap.
    amountOut = router.exactInput(params);
  }

  function swapExactOutput(uint256 amountInMax, uint256 amountOut)
    internal
    returns (uint256 amountIn)
  {
    ISwapRouter.ExactOutputParams memory params;
    usdc.approve(address(router), amountInMax);

    // exact output path is encoded backwards!
    // read the docs nerd
    params = ISwapRouter.ExactOutputParams({
      path: abi.encodePacked(
        address(amkt),
        poolFee,
        address(weth),
        poolFee,
        address(usdc)
      ),
      recipient: address(this),
      deadline: block.timestamp,
      amountOut: amountOut,
      amountInMaximum: amountInMax
    });

    // Executes the swap.
    amountIn = router.exactOutput(params);
  }

  function addRequest(uint256 amount, string memory txid) internal {
    factory.addMintRequest(amount, txid, depositAddress);
  }

  function burnRequest(uint256 amount, string memory txid) internal {
    amkt.approve(address(factory), amount);
    factory.burn(amount, txid);
  }

  ///////////////////////////// ADMIN ///////////////////////////////////

  function removeTokens(
    uint256 amount,
    address dst,
    bool _amkt
  ) external only(admin) {
    if (_amkt) {
      amkt.transfer(dst, amount);
    } else {
      usdc.transfer(dst, amount);
    }
  }

  function arbitraryCall(
    address to,
    bytes calldata data,
    uint256 _value
  ) external only(admin) returns (bytes memory) {
    (bool success, bytes memory data) = to.call{value: _value}(data);
    require(success, "call failed");
    return data;
  }

  ///////////////////////////// SETTERS ///////////////////////////////////

  function setSwapper(address _swapper) external only(admin) {
    swapper = _swapper;
  }

  function proposeAdmin(address _proposedAdmin) external only(admin) {
    proposedAdmin = _proposedAdmin;
  }

  function takeAdmin() external only(proposedAdmin) {
    admin = proposedAdmin;
  }

  function setMerchantDepositAddress() external {
    factory.setMerchantDepositAddress("forge");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface FactoryInterface {
  event IssuerDepositAddressSet(
    address indexed merchant,
    address indexed sender,
    string depositAddress
  );

  event MerchantDepositAddressSet(
    address indexed merchant,
    string depositAddress
  );

  event MintRequestAdd(
    uint256 indexed nonce,
    address indexed requester,
    uint256 amount,
    string depositAddress,
    string txid,
    uint256 timestamp,
    bytes32 requestHash
  );

  event MintRequestCancel(
    uint256 indexed nonce,
    address indexed requester,
    bytes32 requestHash
  );

  event MintConfirmed(
    uint256 indexed nonce,
    address indexed requester,
    uint256 amount,
    string depositAddress,
    string txid,
    uint256 timestamp,
    bytes32 requestHash
  );

  event MintRejected(
    uint256 indexed nonce,
    address indexed requester,
    uint256 amount,
    string depositAddress,
    string txid,
    uint256 timestamp,
    bytes32 requestHash
  );

  event Burned(
    uint256 indexed nonce,
    address indexed requester,
    uint256 amount,
    string depositAddress,
    uint256 timestamp,
    bytes32 requestHash
  );

  event BurnConfirmed(
    uint256 indexed nonce,
    address indexed requester,
    uint256 amount,
    string depositAddress,
    string txid,
    uint256 timestamp,
    bytes32 inputRequestHash
  );

  ///=============================================================================================
  /// Data Structres
  ///=============================================================================================

  enum RequestStatus {
    NULL,
    PENDING,
    CANCELED,
    APPROVED,
    REJECTED
  }

  struct Request {
    address requester; // sender of the request.
    uint256 amount; // amount of token to mint/burn.
    string depositAddress; // issuer's asset address in mint, merchant's asset address in burn.
    string txid; // asset txid for sending/redeeming asset in the mint/burn process.
    uint256 nonce; // serial number allocated for each request.
    uint256 timestamp; // time of the request creation.
    RequestStatus status; // status of the request.
  }

  function pause() external;

  function unpause() external;

  function setIssuerDepositAddress(
    address merchant,
    string memory depositAddress
  ) external returns (bool);

  function setMerchantDepositAddress(string memory depositAddress)
    external
    returns (bool);

  function setMerchantMintLimit(address merchant, uint256 amount)
    external
    returns (bool);

  function setMerchantBurnLimit(address merchant, uint256 amount)
    external
    returns (bool);

  function addMintRequest(
    uint256 amount,
    string memory txid,
    string memory depositAddress
  ) external returns (uint256);

  function cancelMintRequest(bytes32 requestHash) external returns (bool);

  function confirmMintRequest(bytes32 requestHash) external returns (bool);

  function rejectMintRequest(bytes32 requestHash) external returns (bool);

  function burn(uint256 amount, string memory txid) external returns (bool);

  function confirmBurnRequest(bytes32 requestHash) external returns (bool);

  function getMintRequestsLength() external view returns (uint256 length);

  function getBurnRequestsLength() external view returns (uint256 length);

  function getBurnRequest(uint256 nonce)
    external
    view
    returns (
      uint256 requestNonce,
      address requester,
      uint256 amount,
      string memory depositAddress,
      string memory txid,
      uint256 timestamp,
      string memory status,
      bytes32 requestHash
    );

  function getMintRequest(uint256 nonce)
    external
    view
    returns (
      uint256 requestNonce,
      address requester,
      uint256 amount,
      string memory depositAddress,
      string memory txid,
      uint256 timestamp,
      string memory status,
      bytes32 requestHash
    );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

/// @title Owner
/// @notice Transferrable owner authorization pattern.
abstract contract Owner {

    ///===========================
    /// STATE
    ///===========================

    /// @notice Emitted when the ownership is changed
    /// @param previousOwner Previous owner of the contract.
    /// @param newOwner New owner of the contract.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Current owner of the contract.
    address public owner;

    ///@notice Modifier to verify that the sender is the owner of the contract.
    modifier onlyOwner() {
        require (msg.sender == owner, "NOT_OWNER");
        _;
    }

    ///===========================
    /// INIT
    ///===========================

    ///@notice Initially set the owner as the contract deployer.
    constructor() {
        _transferOwnership(msg.sender);
    }

    ///===========================
    /// FUNCTIONS
    ///===========================

    /// @notice Transfer the ownership of the contract.
    /// @param newOwner Address ownership is to be transferred to.
    function transferOwnership(address newOwner) public virtual onlyOwner {
        _transferOwnership(newOwner);
    }

    ///===========================
    /// INTERNAL
    ///===========================

    /// @notice Transfer the ownership of the contract.
    /// @param newOwner Address ownership is to be transferred to.
    function _transferOwnership(address newOwner) internal {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}