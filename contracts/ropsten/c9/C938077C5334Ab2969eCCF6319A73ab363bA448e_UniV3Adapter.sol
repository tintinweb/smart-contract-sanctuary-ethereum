// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

import '../token/IERC20.sol';
import '../token/IWETH.sol';

/// @title Brink UniV3Adapter
/// @notice Deployed once and used by Brink executors to fulfill swaps. Uses V3SwapRouter from Uniswap.
contract UniV3Adapter {
  IWETH public weth;
  bool public initialized;

  /// @dev Contract Address of the Uniswap V3SwapRouter
  address constant V3_SWAP_ROUTER_ADDRESS = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;

  /// @dev Max uint
  uint256 MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

  /// @dev Adapter Owner
  address payable ADAPTER_OWNER = payable(0x71795b2d53Ffbe5b1805FE725538E4f8fBD29e26);

  /// @dev Ethereum address representations
  IERC20 private constant _ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
  IERC20 private constant _ZERO_ADDRESS = IERC20(0x0000000000000000000000000000000000000000);

  error NotEnoughETH();

  /// @dev initialize the contract with WETH address
  /// @param _weth Address of weth
  function initialize (IWETH _weth) external {
    require(!initialized, 'INITIALIZED');
    initialized = true;
    weth = _weth;
  }

  /// @dev Makes a call to the Uniswap V3SwapRouter with swap byte data
  /// @dev returns the requested tokenOutAmount to Account and keeps the rest
  /// @param data swap byte data for Uniswap V3SwapRouter
  /// @param tokenIn Address of the token to be swapped
  /// @param tokenOut Address of the token to be returned from the swap
  /// @param tokenOutAmount Amount of tokenOut to transfer to account
  /// @param account Address of the account to receive the tokenOut
  function uniV3Swap(bytes memory data, IERC20 tokenIn, IERC20 tokenOut, uint tokenOutAmount, address payable account) external payable {
    if (isETH(tokenIn)) {
      tokenIn = IERC20(address(weth));
      weth.deposit{ value: address(this).balance }();
    }
    _routerApproveMax(tokenIn);

    assembly {
      let result := call(gas(), V3_SWAP_ROUTER_ADDRESS, 0, add(data, 0x20), mload(data), 0, 0)
      if eq(result, 0) {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }

    if (isETH(tokenOut)) {
      uint wethBal = weth.balanceOf(address(this));
      weth.withdraw(wethBal);
      if (wethBal < tokenOutAmount) {
        revert NotEnoughETH();
      }
      account.transfer(tokenOutAmount);
      ADAPTER_OWNER.transfer(address(this).balance);
    } else {
      tokenOut.transfer(account, tokenOutAmount);
      tokenOut.transfer(ADAPTER_OWNER, tokenOut.balanceOf(address(this)));
    }

    uint tokenInBalRemaining = tokenIn.balanceOf(address(this));
    if (tokenInBalRemaining > 0) {
      tokenIn.transfer(ADAPTER_OWNER, tokenInBalRemaining);
    }
  }

  function _routerApproveMax(IERC20 token) internal {
    if (token.allowance(address(this), V3_SWAP_ROUTER_ADDRESS) < MAX_INT) {
      token.approve(V3_SWAP_ROUTER_ADDRESS, MAX_INT);
    }
  }

  /// @dev Checks if IERC20 token address is an ETH representation
  /// @param token address of a token
  function isETH(IERC20 token) internal pure returns (bool) {
    return (token == _ZERO_ADDRESS || token == _ETH_ADDRESS);
  }

  receive() external payable { }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;

interface IWETH {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint);

    function allowance(address, address) external view returns (uint);

    receive() external payable;

    function deposit() external payable;

    function withdraw(uint wad) external;

    function totalSupply() external view returns (uint);

    function approve(address guy, uint wad) external returns (bool);

    function transfer(address dst, uint wad) external returns (bool);

    function transferFrom(address src, address dst, uint wad)
    external
    returns (bool);
}