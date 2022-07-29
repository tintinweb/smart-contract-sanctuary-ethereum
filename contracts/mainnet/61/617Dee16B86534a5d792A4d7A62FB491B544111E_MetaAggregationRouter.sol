// SPDX-License-Identifier: MIT

/// Copyright (c) 2019-2021 1inch
/// Permission is hereby granted, free of charge, to any person obtaining a copy of this software
/// and associated documentation files (the "Software"), to deal in the Software without restriction,
/// including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
/// and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
/// subject to the following conditions:
/// The above copyright notice and this permission notice shall be included in all copies or
/// substantial portions of the Software.
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
/// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE
/// AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
/// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
/// OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE

pragma solidity 0.8.9;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import './dependency/Permitable.sol';
import './interfaces/IAggregationExecutor.sol';
import './interfaces/IAggregationExecutor1Inch.sol';
import './libraries/TransferHelper.sol';
import './libraries/RevertReasonParser.sol';

contract MetaAggregationRouter is Permitable, Ownable {
  using SafeERC20 for IERC20;

  address public immutable WETH;
  address private constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

  uint256 private constant _PARTIAL_FILL = 0x01;
  uint256 private constant _REQUIRES_EXTRA_ETH = 0x02;
  uint256 private constant _SHOULD_CLAIM = 0x04;
  uint256 private constant _BURN_FROM_MSG_SENDER = 0x08;
  uint256 private constant _BURN_FROM_TX_ORIGIN = 0x10;
  uint256 private constant _SIMPLE_SWAP = 0x20;

  mapping(address => bool) public isWhitelist;

  struct SwapDescription {
    IERC20 srcToken;
    IERC20 dstToken;
    address[] srcReceivers;
    uint256[] srcAmounts;
    address dstReceiver;
    uint256 amount;
    uint256 minReturnAmount;
    uint256 flags;
    bytes permit;
  }

  struct SimpleSwapData {
    address[] firstPools;
    uint256[] firstSwapAmounts;
    bytes[] swapDatas;
    uint256 deadline;
    bytes destTokenFeeData;
  }

  event Swapped(
    address sender,
    IERC20 srcToken,
    IERC20 dstToken,
    address dstReceiver,
    uint256 spentAmount,
    uint256 returnAmount
  );

  event ClientData(bytes clientData);

  event Exchange(address pair, uint256 amountOut, address output);

  constructor(address _WETH) {
    WETH = _WETH;
  }

  receive() external payable {
    assert(msg.sender == WETH);
    // only accept ETH via fallback from the WETH contract
  }

  function rescueFunds(address token, uint256 amount) external onlyOwner {
    if (_isETH(IERC20(token))) {
      TransferHelper.safeTransferETH(msg.sender, amount);
    } else {
      TransferHelper.safeTransfer(token, msg.sender, amount);
    }
  }

  function updateWhitelist(address addr, bool value) external onlyOwner {
    isWhitelist[addr] = value;
  }

  function swapRouter1Inch(
    address router1Inch,
    bytes calldata router1InchData,
    SwapDescription calldata desc,
    bytes calldata clientData
  ) external payable returns (uint256 returnAmount, uint256 gasUsed) {
    uint256 gasBefore = gasleft();
    require(isWhitelist[router1Inch], 'not whitelist router');
    require(desc.minReturnAmount > 0, 'Min return should not be 0');
    require(
      desc.srcReceivers.length == desc.srcAmounts.length && desc.srcAmounts.length <= 1,
      'Invalid lengths for receiving src tokens'
    );

    uint256 val = msg.value;
    if (!_isETH(desc.srcToken)) {
      // transfer token to kyber router
      _permit(desc.srcToken, desc.amount, desc.permit);
      TransferHelper.safeTransferFrom(address(desc.srcToken), msg.sender, address(this), desc.amount);

      // approve token to 1inch router
      uint256 amount = _getBalance(desc.srcToken, address(this));
      desc.srcToken.safeIncreaseAllowance(router1Inch, amount);

      // transfer fee to feeTaker
      for (uint256 i = 0; i < desc.srcReceivers.length; i++) {
        TransferHelper.safeTransferFrom(address(desc.srcToken), msg.sender, desc.srcReceivers[i], desc.srcAmounts[i]);
      }
    } else {
      for (uint256 i = 0; i < desc.srcReceivers.length; i++) {
        val -= desc.srcAmounts[i];
        TransferHelper.safeTransferETH(desc.srcReceivers[i], desc.srcAmounts[i]);
      }
    }

    address dstReceiver = (desc.dstReceiver == address(0)) ? msg.sender : desc.dstReceiver;
    uint256 initialSrcBalance = (desc.flags & _PARTIAL_FILL != 0) ? _getBalance(desc.srcToken, msg.sender) : 0;
    uint256 initialDstBalance = _getBalance(desc.dstToken, dstReceiver);
    {
      // call to 1inch router contract
      (bool success, ) = router1Inch.call{value: val}(router1InchData);
      require(success, 'call to 1inch router fail');
    }

    // 1inch router return to msg.sender (mean fund will return to this address)
    uint256 stuckAmount = _getBalance(desc.dstToken, address(this));
    _doTransferERC20(desc.dstToken, dstReceiver, stuckAmount);

    // safe check here
    returnAmount = _getBalance(desc.dstToken, dstReceiver) - initialDstBalance;
    uint256 spentAmount = desc.amount;
    if (desc.flags & _PARTIAL_FILL != 0) {
      spentAmount = initialSrcBalance + desc.amount - _getBalance(desc.srcToken, msg.sender);
      require(returnAmount * desc.amount >= desc.minReturnAmount * spentAmount, 'Return amount is not enough');
    } else {
      require(returnAmount >= desc.minReturnAmount, 'Return amount is not enough');
    }

    emit Swapped(msg.sender, desc.srcToken, desc.dstToken, dstReceiver, spentAmount, returnAmount);
    emit Exchange(router1Inch, returnAmount, _isETH(desc.dstToken) ? WETH : address(desc.dstToken));
    emit ClientData(clientData);
    unchecked {
      gasUsed = gasBefore - gasleft();
    }
  }

  function swapExecutor1Inch(
    IAggregationExecutor1Inch caller,
    SwapDescriptionExecutor1Inch calldata desc,
    bytes calldata executor1InchData,
    bytes calldata clientData
  ) external payable returns (uint256 returnAmount, uint256 gasUsed) {
    uint256 gasBefore = gasleft();
    require(desc.minReturnAmount > 0, 'Min return should not be 0');
    require(executor1InchData.length > 0, 'data should not be empty');
    require(desc.srcReceivers.length == desc.srcAmounts.length, 'invalid src receivers length');

    bool srcETH = _isETH(desc.srcToken);
    if (desc.flags & _REQUIRES_EXTRA_ETH != 0) {
      require(msg.value > (srcETH ? desc.amount : 0), 'Invalid msg.value');
    } else {
      require(msg.value == (srcETH ? desc.amount : 0), 'Invalid msg.value');
    }
    uint256 val = msg.value;
    if (!srcETH) {
      _permit(desc.srcToken, desc.amount, desc.permit);

      // transfer to fee taker
      uint256 srcReceiversLength = desc.srcReceivers.length;
      for (uint256 i = 0; i < srcReceiversLength; ) {
        TransferHelper.safeTransferFrom(address(desc.srcToken), msg.sender, desc.srcReceivers[i], desc.srcAmounts[i]);
        unchecked {
          ++i;
        }
      }

      // transfer to 1inch srcReceiver
      TransferHelper.safeTransferFrom(address(desc.srcToken), msg.sender, desc.srcReceiver1Inch, desc.amount);
    } else {
      // transfer to 1inch srcReceiver
      uint256 srcReceiversLength = desc.srcReceivers.length;
      for (uint256 i = 0; i < srcReceiversLength; ) {
        val -= desc.srcAmounts[i];
        TransferHelper.safeTransferETH(desc.srcReceivers[i], desc.srcAmounts[i]);
        unchecked {
          ++i;
        }
      }
    }

    {
      bytes memory callData = abi.encodePacked(caller.callBytes.selector, bytes12(0), msg.sender, executor1InchData);
      // solhint-disable-next-line avoid-low-level-calls
      (bool success, bytes memory result) = address(caller).call{value: val}(callData);
      if (!success) {
        revert(RevertReasonParser.parse(result, 'callBytes failed: '));
      }
    }

    uint256 spentAmount = desc.amount;
    returnAmount = _getBalance(desc.dstToken, address(this));

    if (desc.flags & _PARTIAL_FILL != 0) {
      uint256 unspentAmount = _getBalance(desc.srcToken, address(this));
      if (unspentAmount > 0) {
        spentAmount = spentAmount - unspentAmount;
        _doTransferERC20(desc.srcToken, msg.sender, unspentAmount);
      }

      require(returnAmount * desc.amount >= desc.minReturnAmount * spentAmount, 'Return amount is not enough');
    } else {
      require(returnAmount >= desc.minReturnAmount, 'Return amount is not enough');
    }

    address dstReceiver = (desc.dstReceiver == address(0)) ? msg.sender : desc.dstReceiver;
    _doTransferERC20(desc.dstToken, dstReceiver, returnAmount);

    emit Swapped(msg.sender, desc.srcToken, desc.dstToken, dstReceiver, spentAmount, returnAmount);
    emit Exchange(address(caller), returnAmount, _isETH(desc.dstToken) ? WETH : address(desc.dstToken));
    emit ClientData(clientData);
    unchecked {
      gasUsed = gasBefore - gasleft();
    }
  }

  function swap(
    IAggregationExecutor caller,
    SwapDescription calldata desc,
    bytes calldata executorData,
    bytes calldata clientData
  ) external payable returns (uint256 returnAmount, uint256 gasUsed) {
    uint256 gasBefore = gasleft();
    require(desc.minReturnAmount > 0, 'Min return should not be 0');
    require(executorData.length > 0, 'executorData should be not zero');

    uint256 flags = desc.flags;

    // simple mode swap
    if (flags & _SIMPLE_SWAP != 0) return swapSimpleMode(caller, desc, executorData, clientData);

    {
      IERC20 srcToken = desc.srcToken;
      if (flags & _REQUIRES_EXTRA_ETH != 0) {
        require(msg.value > (_isETH(srcToken) ? desc.amount : 0), 'Invalid msg.value');
      } else {
        require(msg.value == (_isETH(srcToken) ? desc.amount : 0), 'Invalid msg.value');
      }

      require(desc.srcReceivers.length == desc.srcAmounts.length, 'Invalid lengths for receiving src tokens');

      if (flags & _SHOULD_CLAIM != 0) {
        require(!_isETH(srcToken), 'Claim token is ETH');
        _permit(srcToken, desc.amount, desc.permit);
        for (uint256 i = 0; i < desc.srcReceivers.length; i++) {
          TransferHelper.safeTransferFrom(address(srcToken), msg.sender, desc.srcReceivers[i], desc.srcAmounts[i]);
        }
      }

      if (_isETH(srcToken)) {
        // normally in case taking fee in srcToken and srcToken is the native token
        for (uint256 i = 0; i < desc.srcReceivers.length; i++) {
          TransferHelper.safeTransferETH(desc.srcReceivers[i], desc.srcAmounts[i]);
        }
      }
    }

    {
      address dstReceiver = (desc.dstReceiver == address(0)) ? msg.sender : desc.dstReceiver;
      uint256 initialSrcBalance = (flags & _PARTIAL_FILL != 0) ? _getBalance(desc.srcToken, msg.sender) : 0;
      IERC20 dstToken = desc.dstToken;
      uint256 initialDstBalance = _getBalance(dstToken, dstReceiver);

      _callWithEth(caller, executorData);

      uint256 spentAmount = desc.amount;
      returnAmount = _getBalance(dstToken, dstReceiver) - initialDstBalance;

      if (flags & _PARTIAL_FILL != 0) {
        spentAmount = initialSrcBalance + desc.amount - _getBalance(desc.srcToken, msg.sender);
        require(returnAmount * desc.amount >= desc.minReturnAmount * spentAmount, 'Return amount is not enough');
      } else {
        require(returnAmount >= desc.minReturnAmount, 'Return amount is not enough');
      }

      emit Swapped(msg.sender, desc.srcToken, dstToken, dstReceiver, spentAmount, returnAmount);
      emit Exchange(address(caller), returnAmount, _isETH(dstToken) ? WETH : address(dstToken));
      emit ClientData(clientData);
    }

    unchecked {
      gasUsed = gasBefore - gasleft();
    }
  }

  function swapSimpleMode(
    IAggregationExecutor caller,
    SwapDescription calldata desc,
    bytes calldata executorData,
    bytes calldata clientData
  ) public returns (uint256 returnAmount, uint256 gasUsed) {
    uint256 gasBefore = gasleft();

    require(!_isETH(desc.srcToken), 'src is eth, should use normal swap');
    _permit(desc.srcToken, desc.amount, desc.permit);

    uint256 totalSwapAmount = desc.amount;
    if (desc.srcReceivers.length > 0) {
      // take fee in tokenIn
      require(
        desc.srcReceivers.length == 1 && desc.srcReceivers.length == desc.srcAmounts.length,
        'Wrong number of src receivers'
      );
      TransferHelper.safeTransferFrom(address(desc.srcToken), msg.sender, desc.srcReceivers[0], desc.srcAmounts[0]);
      require(desc.srcAmounts[0] <= totalSwapAmount, 'invalid fee amount in src token');
      totalSwapAmount -= desc.srcAmounts[0];
    }
    address dstReceiver = (desc.dstReceiver == address(0)) ? msg.sender : desc.dstReceiver;
    uint256 initialDstBalance = _getBalance(desc.dstToken, dstReceiver);

    _swapMultiSequencesWithSimpleMode(
      caller,
      address(desc.srcToken),
      totalSwapAmount,
      address(desc.dstToken),
      dstReceiver,
      executorData
    );

    returnAmount = _getBalance(desc.dstToken, dstReceiver) - initialDstBalance;

    require(returnAmount >= desc.minReturnAmount, 'Return amount is not enough');
    emit Swapped(msg.sender, desc.srcToken, desc.dstToken, dstReceiver, desc.amount, returnAmount);
    emit Exchange(address(caller), returnAmount, _isETH(desc.dstToken) ? WETH : address(desc.dstToken));
    emit ClientData(clientData);

    unchecked {
      gasUsed = gasBefore - gasleft();
    }
  }

  function _doTransferERC20(
    IERC20 token,
    address to,
    uint256 amount
  ) internal {
    if (amount > 0) {
      if (_isETH(token)) {
        TransferHelper.safeTransferETH(to, amount);
      } else {
        TransferHelper.safeTransfer(address(token), to, amount);
      }
    }
  }

  // Only use this mode if the first pool of each sequence can receive tokenIn directly into the pool
  function _swapMultiSequencesWithSimpleMode(
    IAggregationExecutor caller,
    address tokenIn,
    uint256 totalSwapAmount,
    address tokenOut,
    address dstReceiver,
    bytes calldata data
  ) internal {
    SimpleSwapData memory swapData = abi.decode(data, (SimpleSwapData));
    require(swapData.deadline >= block.timestamp, 'ROUTER: Expired');
    require(
      swapData.firstPools.length == swapData.firstSwapAmounts.length &&
        swapData.firstPools.length == swapData.swapDatas.length,
      'invalid swap data length'
    );
    uint256 numberSeq = swapData.firstPools.length;
    for (uint256 i = 0; i < numberSeq; i++) {
      // collect amount to the first pool
      TransferHelper.safeTransferFrom(tokenIn, msg.sender, swapData.firstPools[i], swapData.firstSwapAmounts[i]);
      require(swapData.firstSwapAmounts[i] <= totalSwapAmount, 'invalid swap amount');
      totalSwapAmount -= swapData.firstSwapAmounts[i];
      {
        // solhint-disable-next-line avoid-low-level-calls
        // may take some native tokens for commission fee
        (bool success, bytes memory result) = address(caller).call(
          abi.encodeWithSelector(caller.swapSingleSequence.selector, swapData.swapDatas[i])
        );
        if (!success) {
          revert(RevertReasonParser.parse(result, 'swapSingleSequence failed: '));
        }
      }
    }
    {
      // solhint-disable-next-line avoid-low-level-calls
      // may take some native tokens for commission fee
      (bool success, bytes memory result) = address(caller).call(
        abi.encodeWithSelector(
          caller.finalTransactionProcessing.selector,
          tokenIn,
          tokenOut,
          dstReceiver,
          swapData.destTokenFeeData
        )
      );
      if (!success) {
        revert(RevertReasonParser.parse(result, 'finalTransactionProcessing failed: '));
      }
    }
  }

  function _getBalance(IERC20 token, address account) internal view returns (uint256) {
    if (_isETH(token)) {
      return account.balance;
    } else {
      return token.balanceOf(account);
    }
  }

  function _isETH(IERC20 token) internal pure returns (bool) {
    return (address(token) == ETH_ADDRESS);
  }

  function _callWithEth(IAggregationExecutor caller, bytes calldata executorData) internal {
    // solhint-disable-next-line avoid-low-level-calls
    // may take some native tokens for commission fee
    uint256 ethAmount = _getBalance(IERC20(ETH_ADDRESS), address(this));
    if (ethAmount > msg.value) ethAmount = msg.value;
    (bool success, bytes memory result) = address(caller).call{value: ethAmount}(
      abi.encodeWithSelector(caller.callBytes.selector, executorData)
    );
    if (!success) {
      revert(RevertReasonParser.parse(result, 'callBytes failed: '));
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol';

import '../libraries/RevertReasonParser.sol';

/*
“Copyright (c) 2019-2021 1inch 
Permission is hereby granted, free of charge, to any person obtaining a copy of this software
and associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions: 
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software. 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE”.
*/

contract Permitable {
  event Error(string reason);

  function _permit(
    IERC20 token,
    uint256 amount,
    bytes calldata permit
  ) internal {
    if (permit.length == 32 * 7) {
      // solhint-disable-next-line avoid-low-level-calls
      (bool success, bytes memory result) = address(token).call(
        abi.encodePacked(IERC20Permit.permit.selector, permit)
      );
      if (!success) {
        string memory reason = RevertReasonParser.parse(result, 'Permit call failed: ');
        if (token.allowance(msg.sender, address(this)) < amount) {
          revert(reason);
        } else {
          emit Error(reason);
        }
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

interface IAggregationExecutor {
  function callBytes(bytes calldata data) external payable; // 0xd9c45357

  // callbytes per swap sequence
  function swapSingleSequence(bytes calldata data) external;

  function finalTransactionProcessing(
    address tokenIn,
    address tokenOut,
    address to,
    bytes calldata destTokenFeeData
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import '@openzeppelin/contracts/interfaces/IERC20.sol';

interface IAggregationExecutor1Inch {
  function callBytes(address msgSender, bytes calldata data) external payable; // 0x2636f7f8
}

interface IAggregationRouter1InchV4 {
  function swap(
    IAggregationExecutor1Inch caller,
    SwapDescription1Inch calldata desc,
    bytes calldata data
  ) external payable returns (uint256 returnAmount, uint256 gasLeft);
}

struct SwapDescription1Inch {
  IERC20 srcToken;
  IERC20 dstToken;
  address payable srcReceiver;
  address payable dstReceiver;
  uint256 amount;
  uint256 minReturnAmount;
  uint256 flags;
  bytes permit;
}

struct SwapDescriptionExecutor1Inch {
  IERC20 srcToken;
  IERC20 dstToken;
  address payable srcReceiver1Inch;
  address payable dstReceiver;
  address[] srcReceivers;
  uint256[] srcAmounts;
  uint256 amount;
  uint256 minReturnAmount;
  uint256 flags;
  bytes permit;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.5.16;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
  function safeApprove(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('approve(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
  }

  function safeTransfer(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transfer(address,uint256)')));
    if (value == 0) return;
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
  }

  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    if (value == 0) return;
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
  }

  function safeTransferETH(address to, uint256 value) internal {
    if (value == 0) return;
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.6;

/*
“Copyright (c) 2019-2021 1inch 
Permission is hereby granted, free of charge, to any person obtaining a copy of this software
and associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions: 
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software. 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE”.
*/

library RevertReasonParser {
  function parse(bytes memory data, string memory prefix) internal pure returns (string memory) {
    // https://solidity.readthedocs.io/en/latest/control-structures.html#revert
    // We assume that revert reason is abi-encoded as Error(string)

    // 68 = 4-byte selector 0x08c379a0 + 32 bytes offset + 32 bytes length
    if (data.length >= 68 && data[0] == '\x08' && data[1] == '\xc3' && data[2] == '\x79' && data[3] == '\xa0') {
      string memory reason;
      // solhint-disable no-inline-assembly
      assembly {
        // 68 = 32 bytes data length + 4-byte selector + 32 bytes offset
        reason := add(data, 68)
      }
      /*
                revert reason is padded up to 32 bytes with ABI encoder: Error(string)
                also sometimes there is extra 32 bytes of zeros padded in the end:
                https://github.com/ethereum/solidity/issues/10170
                because of that we can't check for equality and instead check
                that string length + extra 68 bytes is less than overall data length
            */
      require(data.length >= 68 + bytes(reason).length, 'Invalid revert reason');
      return string(abi.encodePacked(prefix, 'Error(', reason, ')'));
    }
    // 36 = 4-byte selector 0x4e487b71 + 32 bytes integer
    else if (data.length == 36 && data[0] == '\x4e' && data[1] == '\x48' && data[2] == '\x7b' && data[3] == '\x71') {
      uint256 code;
      // solhint-disable no-inline-assembly
      assembly {
        // 36 = 32 bytes data length + 4-byte selector
        code := mload(add(data, 36))
      }
      return string(abi.encodePacked(prefix, 'Panic(', _toHex(code), ')'));
    }

    return string(abi.encodePacked(prefix, 'Unknown(', _toHex(data), ')'));
  }

  function _toHex(uint256 value) private pure returns (string memory) {
    return _toHex(abi.encodePacked(value));
  }

  function _toHex(bytes memory data) private pure returns (string memory) {
    bytes16 alphabet = 0x30313233343536373839616263646566;
    bytes memory str = new bytes(2 + data.length * 2);
    str[0] = '0';
    str[1] = 'x';
    for (uint256 i = 0; i < data.length; i++) {
      str[2 * i + 2] = alphabet[uint8(data[i] >> 4)];
      str[2 * i + 3] = alphabet[uint8(data[i] & 0x0f)];
    }
    return string(str);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";