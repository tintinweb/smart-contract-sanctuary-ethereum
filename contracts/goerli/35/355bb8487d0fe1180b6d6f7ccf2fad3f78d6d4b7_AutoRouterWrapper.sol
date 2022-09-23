//SPDX-License-Identifier: BSD 3-Clause
pragma solidity 0.8.13;

import { ISwapWrapper } from "../interfaces/ISwapWrapper.sol";
import { ISwapRouter } from "../lib/ISwapRouter02.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { IWETH9 } from "../lib/IWETH9.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import "../lib/uniswap/Path.sol";

contract AutoRouterWrapper is ISwapWrapper {
  using SafeTransferLib for ERC20;
  using BytesLib for bytes;

  /// @notice A deployed SwapRouter02(1.1.0). See https://docs.uniswap.org/protocol/reference/deployments.
  ISwapRouter public immutable swapRouter;

  /// @notice WETH contract.
  IWETH9 public immutable weth;

  /// @notice SwapWrapper name.
  string public name;

  /// @dev Address we use to represent ETH.
  address internal constant eth = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  error TxFailed();
  error OnlyMulticallsAllowed();
  error PathMismatch();
  error UnhandledFunction(bytes4 selector);
  error ETHAmountInMismatch();
  error TotalAmountMismatch();
  error RecipientMismatch(bytes4 selector);
  error TokenInMismatch(bytes4 selector);
  error TokenOutMismatch(bytes4 selector);

  /**
   * @param _name SwapWrapper name.
   * @param _uniV3SwapRouter Deployed Uniswap v3 SwapRouter.
   */
  constructor(string memory _name, address _uniV3SwapRouter) {
    name = _name;
    swapRouter = ISwapRouter(_uniV3SwapRouter);
    weth = IWETH9(swapRouter.WETH9());

    ERC20(address(weth)).safeApprove(address(swapRouter), type(uint256).max);
  }

  function swap(
    address _tokenIn,
    address _tokenOut,
    address _recipient,
    uint256 _amount,
    bytes calldata _data
  ) external payable returns (uint256) {
    // If token is ETH and value was sent, ensure the value matches the swap input amount.
    bool _isInputEth = _tokenIn == eth;
    if ((_isInputEth && msg.value != _amount) || (!_isInputEth && msg.value > 0)) {
      revert ETHAmountInMismatch();
    }
    uint256 _prevBalance = getBalance(_tokenOut, _recipient);

    if (_isInputEth) {
      weth.deposit{ value: _amount }();
      _tokenIn = address(weth);
    } else if (!_isInputEth) {
    // If caller isn't sending ETH, we need to transfer in tokens and approve the router
      ERC20(_tokenIn).safeTransferFrom(msg.sender, address(this), _amount);
      ERC20(_tokenIn).safeApprove(address(swapRouter), 0);
      ERC20(_tokenIn).safeApprove(address(swapRouter), _amount);
    }

    uint256 _totalAmountIn = _validateData(_tokenIn, _tokenOut, _recipient, _data);
    // totalAmountIn has been modified by the various `check...()` methods, and should now sum to _amount
    if(_totalAmountIn != _amount) revert TotalAmountMismatch();

    (bool _success, ) = address(swapRouter).call(_data);
    if(!_success) revert TxFailed();

    // Unwrap WETH for ETH if needed.
    if (_tokenOut == address(eth)) {
      transferEth(_recipient);
    }

    return getBalance(_tokenOut, _recipient) - _prevBalance;
  }

  function _validateData(
    address _tokenIn,
    address _tokenOut,
    address _recipient,
    bytes calldata _data
    ) internal view returns (uint256 _totalAmountIn) {

    bytes4 _selector = bytes4(_data[:4]);
    // Check that it's the multicall function that's being called.
    if(_selector != ISwapRouter.multicall.selector) revert OnlyMulticallsAllowed();

    (/*uint256 deadline*/, bytes[] memory _calls) = abi.decode(
      _data[4:],
      (uint256, bytes[])
    );

    uint256 _callsLength = _calls.length;
    for (uint256 i = 0; i < _callsLength; i++) {
      bytes memory _call = _calls[i];
      // Get the selector
      _selector = bytes4(_call.slice(0, 4));
      // Remove the selector
      bytes memory _callWithoutSelector = _call.slice(4, _call.length-4);

      // check TokenIn if it's the first call of a multicall
      bool _checkTokenIn = i == 0;
      // check TokenOut if it's the last call of a multicall
      bool _checkTokenOut = i == _callsLength - 1;

      // Check that selector is an approved selector and validate its arguments.
      if (_selector == ISwapRouter.exactInputSingle.selector) {
        _totalAmountIn += checkExactInputSingle(
          _callWithoutSelector,
          _tokenIn,
          _tokenOut,
          _recipient,
          _checkTokenIn,
          _checkTokenOut
        );
      } else if (_selector == ISwapRouter.exactInput.selector) {
        _totalAmountIn += checkExactInput(
          _callWithoutSelector,
          _tokenIn,
          _tokenOut,
          _recipient,
          _checkTokenIn,
          _checkTokenOut
        );
      } else if (_selector == ISwapRouter.sweepToken.selector) {
        checkSweepToken(
          _callWithoutSelector,
          _tokenOut,
          _recipient
        );
      } else if (_selector == ISwapRouter.swapExactTokensForTokens.selector) {
        _totalAmountIn += checkSwapExactTokensForTokens(
          _callWithoutSelector,
          _tokenIn,
          _tokenOut,
          _recipient,
          _checkTokenIn,
          _checkTokenOut
        );
      } else {
        revert UnhandledFunction(_selector);
      }
    }
  }

  function checkExactInputSingle(
    bytes memory _data,
    address _tokenInExpected,
    address _tokenOutExpected,
    address _recipientExpected,
    bool _checkTokenIn,
    bool _checkTokenOut
    ) internal view returns(uint256) {
    (
      address _tokenIn,
      address _tokenOut,
      /*uint24 _fee*/,
      address _recipient,
      uint256 _amountIn,
      /*uint256 _amountOutMinimum*/,
      /*uint160 _sqrtPriceLimitX96*/
    ) = abi.decode(
        _data,
        (address, address, uint24, address, uint256, uint256, uint160)
      );

    if(_checkTokenIn) {
      bool _tokensMatch = checkTokens(_tokenIn, _tokenInExpected);
      if (!_tokensMatch) revert TokenInMismatch(ISwapRouter.exactInputSingle.selector);
    }
    if(_checkTokenOut) {
      bool _tokensMatch = checkTokens(_tokenOut, _tokenOutExpected);
      if (!_tokensMatch) revert TokenOutMismatch(ISwapRouter.exactInputSingle.selector);
    }

    // address(2) is a flag for identifying address(this).
    // See https://github.com/Uniswap/swap-router-contracts/blob/9dc4a9cce101be984e148e1af6fe605ebcfa658a/contracts/libraries/Constants.sol#L14
    if(_recipient != _recipientExpected && _recipient != address(2)) revert RecipientMismatch(ISwapRouter.exactInputSingle.selector);

    return _amountIn;
  }

  function checkExactInput(
    bytes memory _data,
    address _tokenInExpected,
    address _tokenOutExpected,
    address _recipientExpected,
    bool _checkTokenIn,
    bool _checkTokenOut
  ) internal view returns(uint256){
    (
      bytes memory _path,
      address _recipient,
      uint256 _amountIn,
      /*uint256 amountOutMinimum*/
      // First 32 bytes point to the location of dynamic bytes _path
    ) = abi.decode(_data.slice(32, _data.length-32), (bytes, address, uint256, uint256));

    if(_checkTokenIn)
    {
      (address _tokenA, /*address _tokenB*/, ) = Path.decodeFirstPool(_path);
      bool _tokensMatch = checkTokens(_tokenA, _tokenInExpected);
      if(!_tokensMatch) revert TokenInMismatch(ISwapRouter.exactInput.selector);
    }

    if(_checkTokenOut) {
      (/*address _tokenA*/, address _tokenB, ) = Path.decodeLastPool(_path);
      bool _tokensMatch = checkTokens(_tokenB, _tokenOutExpected);
      if (!_tokensMatch) revert TokenOutMismatch(ISwapRouter.exactInput.selector);
    }

    // address(2) is a flag for identifying address(this).
    // See https://github.com/Uniswap/swap-router-contracts/blob/9dc4a9cce101be984e148e1af6fe605ebcfa658a/contracts/libraries/Constants.sol#L14
    if(_recipient != _recipientExpected && _recipient != address(2)) revert RecipientMismatch(ISwapRouter.exactInput.selector);

    return _amountIn;
  }

  function checkSweepToken(
    bytes memory _data,
    address _tokenOutExpected,
    address _recipientExpected
  ) internal view {
    (address _token, /*uint256 _amountMinimum*/, address _recipient) = abi.decode(
      _data,
      (address, uint256, address)
    );
    bool _tokensMatch = checkTokens(_token, _tokenOutExpected);
    if(!_tokensMatch) {
      revert TokenOutMismatch(ISwapRouter.sweepToken.selector);
    }
    if(_recipient != _recipientExpected) revert RecipientMismatch(ISwapRouter.sweepToken.selector);
  }

  function checkSwapExactTokensForTokens(
    bytes memory _data,
    address _tokenInExpected,
    address _tokenOutExpected,
    address _recipientExpected,
    bool _checkTokenIn,
    bool _checkTokenOut
  ) internal view returns(uint256) {
    (
      uint256 _amountIn,
      /*uint256 amountOutMin*/,
      address[] memory _path,
      address _to
    ) = abi.decode(_data, (uint256, uint256, address[], address));

    if(_checkTokenIn) {
      bool _tokensMatch = checkTokens(_path[0], _tokenInExpected);
      if (!_tokensMatch) revert TokenInMismatch(ISwapRouter.swapExactTokensForTokens.selector);
    }
    if(_checkTokenOut) {
      bool _tokensMatch = checkTokens(_path[_path.length - 1], _tokenOutExpected);
      if (!_tokensMatch) revert TokenOutMismatch(ISwapRouter.swapExactTokensForTokens.selector);
    }

    // address(2) is a flag for identifying address(this).
    // See https://github.com/Uniswap/swap-router-contracts/blob/9dc4a9cce101be984e148e1af6fe605ebcfa658a/contracts/libraries/Constants.sol#L14
    if(_to != _recipientExpected && _to != address(2)) revert RecipientMismatch(ISwapRouter.swapExactTokensForTokens.selector);

    return _amountIn;
  }

  function transferEth(address _recipient) internal {
    weth.withdraw(weth.balanceOf(address(this)));
    payable(_recipient).transfer(address(this).balance);
  }

  function getBalance(address _tokenOut, address _recipient) internal view returns (uint256) {
    if(_tokenOut == address(eth)) {
      return address(_recipient).balance;
    } else {
      return ERC20(_tokenOut).balanceOf(address(_recipient));
    }
  }

  // Return true if two tokens match, OR if _tokenExpected is eth, token must be weth.
  function checkTokens(address _token, address _tokenExpected) internal view returns (bool) {
    // `TokenIn` should never == eth by the time this check is reached.
    return _token == _tokenExpected || (_tokenExpected == eth ? _token == address(weth) : false);
  }

  /// @notice Required to receive ETH on `weth.withdraw()`
  receive() external payable {}
}

//SPDX-License-Identifier: BSD 3-Clause
pragma solidity >=0.8.0;

error ETHAmountInMismatch();

/**
 * @notice ISwapWrapper is the interface that all swap wrappers should implement.
 * This will be used to support swap protocols like Uniswap V2 and V3, Sushiswap, 1inch, etc.
 */
interface ISwapWrapper {

    /// @notice Event emitted after a successful swap.
    event WrapperSwapExecuted(address indexed tokenIn, address indexed tokenOut, address sender, address indexed recipient, uint256 amountIn, uint256 amountOut);

    /// @notice Name of swap wrapper for UX readability.
    function name() external returns (string memory);

    /**
     * @notice Swap function. Generally we expect the implementer to call some exactAmountIn-like swap method, and so the documentation
     * is written with this in mind. However, the method signature is general enough to support exactAmountOut swaps as well.
     * @param _tokenIn Token to be swapped (or 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE for ETH).
     * @param _tokenOut Token to receive (or 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE for ETH).
     * @param _recipient Receiver of `_tokenOut`.
     * @param _amount Amount of `_tokenIn` that should be swapped.
     * @param _data Additional data that the swap wrapper may require to execute the swap.
     * @return Amount of _tokenOut received.
     */
    function swap(address _tokenIn, address _tokenOut, address _recipient, uint256 _amount, bytes calldata _data) external payable returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

import "./IUniswapV3SwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
  struct ExactInputSingleParams {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    address recipient;
    uint256 amountIn;
    uint256 amountOutMinimum;
    uint160 sqrtPriceLimitX96;
  }
  struct ExactInputParams {
    bytes path;
    address recipient;
    uint256 amountIn;
    uint256 amountOutMinimum;
  }

  function exactInput(ExactInputParams memory params)
    external
    payable
    returns (uint256 amountOut);

  function exactInputSingle(ExactInputSingleParams calldata params)
    external
    payable
    returns (uint256 amountOut);

  function multicall(uint256 deadline, bytes[] calldata data)
    external
    payable
    returns (bytes[] memory);

  function sweepToken(
    address token,
    uint256 amountMinimum,
    address recipient
  ) external payable;

  function unwrapWETH9WithFee(
    uint256 amountMinimum,
    address recipient,
    uint256 feeBips,
    address feeRecipient
  ) external payable;

  function wrapETH(uint256 value) external payable;

  function unwrapWETH9(uint256 amountMinimum) external payable;

  function WETH9() external view returns (address payable);

  //V2 Periphery
  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to
  ) external payable returns (uint256 amountOut);
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

// SPDX-License-Identifier: BSD-2-Clause
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.2. SEE SOURCE BELOW. !!
pragma solidity 0.8.13;

interface IWETH9 {
    function name() external view returns (string memory);

    function approve(address guy, uint256 wad) external returns (bool);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function withdraw(uint256 wad) external;

    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint256);

    function symbol() external view returns (string memory);

    function transfer(address dst, uint256 wad) external returns (bool);

    function deposit() external payable;

    function allowance(address, address) external view returns (uint256);

    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"name":"guy","type":"address"},{"name":"wad","type":"uint256"}],"name":"approve","outputs":[{"name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"name":"src","type":"address"},{"name":"dst","type":"address"},{"name":"wad","type":"uint256"}],"name":"transferFrom","outputs":[{"name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"name":"wad","type":"uint256"}],"name":"withdraw","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"name":"","type":"address"}],"name":"balanceOf","outputs":[{"name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"name":"dst","type":"address"},{"name":"wad","type":"uint256"}],"name":"transfer","outputs":[{"name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"deposit","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"name":"","type":"address"},{"name":"","type":"address"}],"name":"allowance","outputs":[{"name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"stateMutability":"payable","type":"fallback"},{"anonymous":false,"inputs":[{"indexed":true,"name":"src","type":"address"},{"indexed":true,"name":"guy","type":"address"},{"indexed":false,"name":"wad","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"src","type":"address"},{"indexed":true,"name":"dst","type":"address"},{"indexed":false,"name":"wad","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"dst","type":"address"},{"indexed":false,"name":"wad","type":"uint256"}],"name":"Deposit","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"src","type":"address"},{"indexed":false,"name":"wad","type":"uint256"}],"name":"Withdrawal","type":"event"}]
*/

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import "./BytesLib.sol";

/// @title MODIFIED FILE: Functions for manipulating path data for multihop swaps
/// @notice Additional `decodeLastPool` method was added to the orignal file linked below.
/// @notice Link: https://github.com/Uniswap/v3-periphery/blob/b325bb0905d922ae61fcc7df85ee802e8df5e96c/contracts/libraries/Path.sol
library Path {
  using BytesLib for bytes;

  /// @dev The length of the bytes encoded address
  uint256 private constant ADDR_SIZE = 20;
  /// @dev The length of the bytes encoded fee
  uint256 private constant FEE_SIZE = 3;

  /// @dev The offset of a single token address and pool fee
  uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;
  /// @dev The offset of an encoded pool key
  uint256 private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;
  /// @dev The minimum length of an encoding that contains 2 or more pools
  uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POP_OFFSET + NEXT_OFFSET;

  /// @notice Returns true iff the path contains two or more pools
  /// @param path The encoded swap path
  /// @return True if path contains two or more pools, otherwise false
  function hasMultiplePools(bytes memory path) internal pure returns (bool) {
    return path.length >= MULTIPLE_POOLS_MIN_LENGTH;
  }

  /// @notice Returns the number of pools in the path
  /// @param path The encoded swap path
  /// @return The number of pools in the path
  function numPools(bytes memory path) internal pure returns (uint256) {
    // Ignore the first token address. From then on every fee and token offset indicates a pool.
    return ((path.length - ADDR_SIZE) / NEXT_OFFSET);
  }

  /// @notice Decodes the first pool in path
  /// @param path The bytes encoded swap path
  /// @return tokenA The first token of the given pool
  /// @return tokenB The second token of the given pool
  /// @return fee The fee level of the pool
  function decodeFirstPool(bytes memory path)
    internal
    pure
    returns (
      address tokenA,
      address tokenB,
      uint24 fee
    )
  {
    tokenA = path.toAddress(0);
    fee = path.toUint24(ADDR_SIZE);
    tokenB = path.toAddress(NEXT_OFFSET);
  }

  /// @notice Gets the segment corresponding to the first pool in the path
  /// @param path The bytes encoded swap path
  /// @return The segment containing all data necessary to target the first pool in the path
  function getFirstPool(bytes memory path)
    internal
    pure
    returns (bytes memory)
  {
    return path.slice(0, POP_OFFSET);
  }

  /// @notice Skips a token + fee element from the buffer and returns the remainder
  /// @param path The swap path
  /// @return The remaining token + fee elements in the path
  function skipToken(bytes memory path) internal pure returns (bytes memory) {
    return path.slice(NEXT_OFFSET, path.length - NEXT_OFFSET);
  }

  /// @notice Custom method we've added: Decodes the last pool in path
  /// @param path The bytes encoded swap path
  /// @return tokenA The first token of the given pool
  /// @return tokenB The second token of the given pool
  /// @return fee The fee level of the pool
  function decodeLastPool(bytes memory path)
    internal
    pure
    returns (
      address tokenA,
      address tokenB,
      uint24 fee
    )
  {
    path = path.slice(path.length - POP_OFFSET, POP_OFFSET);
    tokenA = path.toAddress(0);
    fee = path.toUint24(ADDR_SIZE);
    tokenB = path.toAddress(NEXT_OFFSET);
  }

}

// Sourced from https://github.com/Uniswap/v3-core/blob/ed88be38ab2032d82bf10ac6f8d03aa631889d48/contracts/interfaces/callback/IUniswapV3SwapCallback.sol
// Modified solidity pragma.

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.13;

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
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 * @notice Link: https://github.com/Uniswap/v3-periphery/blob/b325bb0905d922ae61fcc7df85ee802e8df5e96c/contracts/libraries/BytesLib.sol
 */
pragma solidity >=0.8.0 <0.9.0;

library BytesLib {
  function slice(
    bytes memory _bytes,
    uint256 _start,
    uint256 _length
  ) internal pure returns (bytes memory) {
    require(_length + 31 >= _length, "slice_overflow");
    require(_bytes.length >= _start + _length, "slice_outOfBounds");

    bytes memory tempBytes;

    assembly {
      switch iszero(_length)
      case 0 {
        // Get a location of some free memory and store it in tempBytes as
        // Solidity does for memory variables.
        tempBytes := mload(0x40)

        // The first word of the slice result is potentially a partial
        // word read from the original array. To read it, we calculate
        // the length of that partial word and start copying that many
        // bytes into the array. The first word we copy will start with
        // data we don't care about, but the last `lengthmod` bytes will
        // land at the beginning of the contents of the new array. When
        // we're done copying, we overwrite the full first word with
        // the actual length of the slice.
        let lengthmod := and(_length, 31)

        // The multiplication in the next line is necessary
        // because when slicing multiples of 32 bytes (lengthmod == 0)
        // the following copy loop was copying the origin's length
        // and then ending prematurely not copying everything it should.
        let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
        let end := add(mc, _length)

        for {
          // The multiplication in the next line has the same exact purpose
          // as the one above.
          let cc := add(
            add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))),
            _start
          )
        } lt(mc, end) {
          mc := add(mc, 0x20)
          cc := add(cc, 0x20)
        } {
          mstore(mc, mload(cc))
        }

        mstore(tempBytes, _length)

        //update free-memory pointer
        //allocating the array padded to 32 bytes like the compiler does now
        mstore(0x40, and(add(mc, 31), not(31)))
      }
      //if we want a zero-length slice let's just return a zero-length array
      default {
        tempBytes := mload(0x40)
        //zero out the 32 bytes slice we are about to return
        //we need to do it because Solidity does not garbage collect
        mstore(tempBytes, 0)

        mstore(0x40, add(tempBytes, 0x20))
      }
    }

    return tempBytes;
  }

  function toAddress(bytes memory _bytes, uint256 _start)
    internal
    pure
    returns (address)
  {
    require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
    address tempAddress;

    assembly {
      tempAddress := div(
        mload(add(add(_bytes, 0x20), _start)),
        0x1000000000000000000000000
      )
    }

    return tempAddress;
  }

  function toUint24(bytes memory _bytes, uint256 _start)
    internal
    pure
    returns (uint24)
  {
    require(_start + 3 >= _start, "toUint24_overflow");
    require(_bytes.length >= _start + 3, "toUint24_outOfBounds");
    uint24 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x3), _start))
    }

    return tempUint;
  }
}