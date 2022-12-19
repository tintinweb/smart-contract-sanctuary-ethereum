// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./../interface/basket/IBasketLedger.sol";
import "./../interface/bridge/ILiquidCryptoBridge_v2.sol";
import "./../interface/IUniswapRouterETH.sol";
import "./../interface/ILiquidCZapUniswapV2.sol";
import "./../interface/IWETH.sol";

import "./../interface/stargate/IStargateRouter.sol";

contract Basketv3 is Ownable {
  address public ledger;
  address public bridge;
  address public treasury;

  mapping (address => bool) public managers;

  address public stargaterouter;
  address public unirouter;
  address[] public nativeToStargateInput;
  address[] public stargateInputToNative;
  address public native;
  address public stargateInput;
  uint256 public stargateSourcePoolId;
  uint256 public stargateSwapFeeMultipler = 1400000;
  uint256 public stargateSwapFeeDivider = 1000000;
  uint256 public stargateSwapFee = 600;

  struct PoolInfo {
    address liquidCZap;
    address vault;
    address router;
    address[] path;
    uint256 amount; // deposit - reserved  withdraw - specific amount
  }

  struct BridgeSwapInfo {
    uint256 chain;
    address bridgeAddress;
    uint256 poolCnts;
  }

  struct StragateSwapInfo {
    uint16 chain;
    address basketAddress;
    uint256 srcPoolID;
    uint256 dstPoolID;
    uint256 poolCnts;
  }

  constructor(
    address _ledger,
    address _bridge,
    address _unirouter,
    address _stargaterouter,
    uint256 _stargateSourcePoolId,
    address[] memory _nativeToStargateInput,
    address[] memory _stargateInputToNative,
    address _treasury
  ) {
    managers[msg.sender] = true;
    ledger = _ledger;
    bridge = _bridge;
    treasury = _treasury;
    stargaterouter = _stargaterouter;
    unirouter = _unirouter;
    nativeToStargateInput = _nativeToStargateInput;
    stargateInputToNative = _stargateInputToNative;
    native = _nativeToStargateInput[0];
    stargateInput = _nativeToStargateInput[_nativeToStargateInput.length - 1];
    stargateSourcePoolId = _stargateSourcePoolId;

    _approveTokenIfNeeded(native, unirouter);
    _approveTokenIfNeeded(stargateInput, stargaterouter);
  }

  modifier onlyManager() {
    require(managers[msg.sender], "LiquidC Basket v3: !manager");
    _;
  }

  receive() external payable {
  }

  function deposit(address _account, PoolInfo[] calldata _pools, StragateSwapInfo[] calldata _sgSwaps, BridgeSwapInfo[] calldata _lcbrgSwaps) public payable {
    uint256 inputAmount = msg.value;
    uint256 sgSwapNum = 0;
    uint256 lcbrgSwapNum = 0;
    for (uint256 i=0; i<_sgSwaps.length; i++) {
      sgSwapNum += _sgSwaps[i].poolCnts;
    }
    for (uint256 i=0; i<_lcbrgSwaps.length; i++) {
      lcbrgSwapNum += _lcbrgSwaps[i].poolCnts;
    }
    uint256 totalNum = _pools.length + sgSwapNum + lcbrgSwapNum;

    if (sgSwapNum > 0) {
      _stargateSwap(_sgSwaps, inputAmount * sgSwapNum / totalNum, sgSwapNum);
    }
    if (lcbrgSwapNum > 0) {
      _lcBridgeSwap(_account, _lcbrgSwaps, inputAmount * lcbrgSwapNum / totalNum, lcbrgSwapNum);
    }
    if (_pools.length > 0) {
      if (address(this).balance > 0) {
        IWETH(native).deposit{value: address(this).balance}();
      }
      uint256 nativeBalance = IERC20(native).balanceOf(address(this));
      for (uint256 i=0; i<_pools.length; i++) {
        _deposit(_account, _pools[i], nativeBalance / _pools.length, false);
      }
    }

    if (address(this).balance > 0) {
      (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
      require(success, "Failed refund change");
    }
  }

  function depositFromBridge(address _account, PoolInfo[] calldata _pools, uint256 _itokenAmount, uint256 _fee, uint8 _bridge) public onlyManager {
    uint256 nativeBalance = 0;
    if (_bridge == 0) { // Stargate
      uint256 iTokenBalance = IERC20(stargateInput).balanceOf(address(this));
      require(_itokenAmount <= iTokenBalance, "LiquidC Basket v3: stargate bridge not completed");
      _approveTokenIfNeeded(stargateInput, unirouter);
      uint256[] memory amounts = IUniswapRouterETH(unirouter).swapExactTokensForTokens(_itokenAmount, 0, stargateInputToNative, address(this), block.timestamp);
      _removeAllowances(stargateInput, unirouter);
      nativeBalance = amounts[amounts.length - 1];
    }
    else if (_bridge == 1) { // LCBridge
      nativeBalance = ILiquidCryptoBridge_v2(bridge).redeem(_itokenAmount, address(this), 0, true);
    }
    if (_fee > 0 && nativeBalance > _fee) {
      nativeBalance -= _fee;
      IWETH(native).withdraw(_fee);
      (bool success, ) = msg.sender.call{value: _fee}("");
      require(success, "LiquidC Basket v3: Failed cut operator fee");
    }

    if (nativeBalance > 0) {
      uint256 poolLen = _pools.length;
      uint256 amount = nativeBalance / poolLen;
      for (uint256 i=0; i<poolLen; i++) {
        _deposit(_account, _pools[i], amount, false);
      }
    }
  }

  function withdraw(address _account, PoolInfo[] calldata _pools, StragateSwapInfo calldata _stgSwap, BridgeSwapInfo calldata _lcbrgSwap, uint256 _fee) public onlyManager {
    uint256 poolLen = _pools.length;
    if (poolLen > 0) {
      for (uint256 i=0; i<poolLen; i++) {
        uint256 ledgerBalance = IBasketLedger(ledger).xlpSupply(_pools[i].vault, _account);
        uint256 amount = _pools[i].amount;
        if (ledgerBalance < amount) {
          amount = ledgerBalance;
        }
        if (amount > 0) {
          uint256 xlpOut = IBasketLedger(ledger).withdraw(_account, _pools[i].vault, amount);
          if (xlpOut > 0) {
            _approveTokenIfNeeded(_pools[i].vault, _pools[i].liquidCZap);
            ILiquidCZapUniswapV2(_pools[i].liquidCZap).LiquidCOutAndSwap(_pools[i].vault, xlpOut, _pools[i].path[0], 0);

            if (_pools[i].path.length > 1) {
              _approveTokenIfNeeded(_pools[i].path[0], _pools[i].router);
              uint256 t0amount = IERC20(_pools[i].path[0]).balanceOf(address(this));
              IUniswapRouterETH(_pools[i].router).swapExactTokensForTokens(t0amount, 0, _pools[i].path, address(this), block.timestamp);
            }
          }
        }
      }
    }

    uint256 nativeBalance = IERC20(native).balanceOf(address(this));
    if (nativeBalance > 0) {
      IWETH(native).withdraw(nativeBalance);
    }
    if (_fee > 0 && nativeBalance > _fee) {
      (bool success, ) = msg.sender.call{value: _fee}("");
      require(success, "LiquidC Basket v3: Failed cut operator fee");
    }

    uint256 coinAmount = address(this).balance;
    uint256 totalBrgCnt = _stgSwap.poolCnts + _lcbrgSwap.poolCnts;
    if (_stgSwap.poolCnts > 0) {
      uint256 stgAmount = coinAmount * _stgSwap.poolCnts / totalBrgCnt;
      (uint256 swFee, ) = IStargateRouter(stargaterouter).quoteLayerZeroFee(
        _stgSwap.chain,
        1,
        bytes("0x"),
        bytes("0x"),
        IStargateRouter.lzTxObj(0, 0, "0x")
      );
      swFee = swFee * stargateSwapFeeMultipler / stargateSwapFeeDivider;
      if (stgAmount > swFee) {
        stgAmount -= swFee;
        IWETH(native).deposit{value: stgAmount}();

        uint256[] memory amounts = IUniswapRouterETH(unirouter).swapExactTokensForTokens(stgAmount, 0, nativeToStargateInput, address(this), block.timestamp);
        _stgBridgeSwap(_stgSwap, swFee, amounts[amounts.length-1]);
      }
    }
    if (_lcbrgSwap.poolCnts > 0) {
      uint256 lcbAmount = coinAmount * _lcbrgSwap.poolCnts / totalBrgCnt;
      ILiquidCryptoBridge_v2(bridge).swap{value: lcbAmount}(_account, _account, _lcbrgSwap.chain);
    }
    if (address(this).balance > 0) {
      (bool success, ) = payable(_account).call{value: address(this).balance}("");
      require(success, "LiquidC Basket v3: Failed wirhdraw");
    }
  }

  function _stargateSwap(StragateSwapInfo[] calldata _swaps, uint256 _amount, uint256 _totalPools) internal {
    uint256 totalSwfee = 0;
    uint256 swapLen = _swaps.length;
    uint256[] memory swFees = new uint256[](swapLen);
    for (uint256 i=0; i<swapLen; i++) {
      (uint256 swFee, ) = IStargateRouter(stargaterouter).quoteLayerZeroFee(
        _swaps[i].chain,
        1,
        bytes("0x"),
        bytes("0x"),
        IStargateRouter.lzTxObj(0, 0, "0x")
      );
      swFee = swFee * stargateSwapFeeMultipler / stargateSwapFeeDivider;
      swFees[i] = swFee;
      totalSwfee = totalSwfee + swFee;
    }

    if (totalSwfee <= _amount) {
      _amount -= totalSwfee;
      IWETH(native).deposit{value: _amount}();
      uint256[] memory amounts = IUniswapRouterETH(unirouter).swapExactTokensForTokens(_amount, 0, nativeToStargateInput, address(this), block.timestamp);
      for (uint256 i=0; i<swapLen; i++) {
        uint256 iamount = amounts[amounts.length - 1] * _swaps[i].poolCnts / _totalPools;
        if (iamount > 0) {
          _stgBridgeSwap(_swaps[i], swFees[i], iamount);
        }
      }
    }
  }

  function _stgBridgeSwap(StragateSwapInfo calldata _swap, uint256 _swfee, uint256 _iamount) internal {
    uint256 iamount = _cutBridgingFee(_iamount);
    IStargateRouter(stargaterouter).swap{value: _swfee}(
      _swap.chain,
      stargateSourcePoolId,
      _swap.dstPoolID,
      payable(address(this)),
      iamount,
      0,
      IStargateRouter.lzTxObj(0, 0, "0x"),
      abi.encodePacked(_swap.basketAddress),
      bytes("")
    );
  }

  function _lcBridgeSwap(address _account, BridgeSwapInfo[] calldata _swaps, uint256 _coinAmount, uint256 _totalPools) internal {
    uint256 swLen = _swaps.length;
    for (uint256 i=0; i<swLen; i++) {
      uint256 amount = _coinAmount * _swaps[i].poolCnts / _totalPools;
      if (amount > 0) {
        ILiquidCryptoBridge_v2(bridge).swap{value: amount}(_swaps[i].bridgeAddress, _account, _swaps[i].chain);
      }
    }
  }

  function _deposit(address account, PoolInfo calldata pool, uint256 amount, bool move) private {
    if (pool.path.length > 1) {
      uint256[] memory amounts = IUniswapRouterETH(pool.router).swapExactTokensForTokens(amount, 0, pool.path, address(this), block.timestamp);
      amount = amounts[amounts.length - 1];
    }
    _approveTokenIfNeeded(pool.path[pool.path.length-1], pool.liquidCZap);
    ILiquidCZapUniswapV2(pool.liquidCZap).LiquidCIn(pool.vault, 0, pool.path[pool.path.length-1], amount);
    uint256 xlpbalance = IERC20(pool.vault).balanceOf(address(this));
    if (move) {
      IERC20(pool.vault).transfer(account, xlpbalance);
    }
    else {
      _approveTokenIfNeeded(pool.vault, ledger);
      IBasketLedger(ledger).deposit(account, pool.vault, xlpbalance);
    }
  }

  function setLedger(address _ledger) public onlyManager {
    ledger = _ledger;
  }

  function setBridge(address _bridge) public onlyManager {
    bridge = _bridge;
  }

  function setTreasury(address _treasury) public onlyManager {
    treasury = _treasury;
  }
  
  function setStargateSwapFee(uint256 _stargateSwapFee) public onlyManager {
    stargateSwapFee = _stargateSwapFee;
  }

  function setStargateSwapFeeMultipler(uint256 _stargateSwapFeeMultipler) public onlyManager {
    stargateSwapFeeMultipler = _stargateSwapFeeMultipler;
  }

  function setStargateSwapFeeDivider(uint256 _stargateSwapFeeDivider) public onlyManager {
    stargateSwapFeeDivider = _stargateSwapFeeDivider;
  }

  function setManager(address _account, bool _access) public onlyOwner {
    managers[_account] = _access;
  }

  function withdrawBridgeRefundFee(uint256 _fee) public onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: _fee}("");
    require(success, "Failed to withdraw");
  }

  function _approveTokenIfNeeded(address token, address spender) private {
    if (IERC20(token).allowance(address(this), spender) == 0) {
      IERC20(token).approve(spender, type(uint256).max);
    }
  }

  function _removeAllowances(address token, address spender) private {
    if (IERC20(token).allowance(address(this), spender) > 0) {
      IERC20(token).approve(spender, 0);
    }
  }

  function _cutBridgingFee(uint256 _amount) internal returns(uint256) {
    if (_amount > 0) {
      uint256 fee = _amount * stargateSwapFee / stargateSwapFeeDivider;
      if (fee > 0) {
        _approveTokenIfNeeded(stargateInput, unirouter);
        uint256[] memory amounts = IUniswapRouterETH(unirouter).swapExactTokensForTokens(fee, 0, stargateInputToNative, address(this), block.timestamp);
        _removeAllowances(stargateInput, unirouter);
        IWETH(native).withdraw(amounts[amounts.length-1]);
        (bool success2, ) = payable(treasury).call{value: amounts[amounts.length-1]}("");
        require(success2, "Failed to refund fee");
      }
      return _amount - fee;
    }
    return 0;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function addLiquidity(uint256 _poolId, uint256 _amountLD, address to) external payable;
    function instantRedeemLocal(uint16 _srcPoolId, uint256 _amountLD, address to) external payable;

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

interface ILiquidCryptoBridge_v2 {
  function swap(address _to, address _refund, uint256 _outChainID) external payable returns(uint256);
  function redeem(uint256 _amount, address _to, uint256 _fee, bool wrapped) external returns(uint256);
  function refund(uint256 _index, uint256 _fee) external;
  
  function getAmountsIn(uint256 _amount) external view returns(uint256 coin);
  function getAmountsOut(uint256 _amount) external view returns(uint256 stableAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

interface IBasketLedger {
  function xlpSupply(address _vault, address _account) external returns(uint256);
  function deposit(address _account, address _vault, uint256 _amount) external;
  function withdraw(address _account, address _vault, uint256 _amount) external returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IUniswapRouterETH {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

interface ILiquidCZapUniswapV2 {
    function LiquidCIn (address beefyVault, uint256 tokenAmountOutMin, address tokenIn, uint256 tokenInAmount) external;
    function LiquidCInETH (address beefyVault, uint256 tokenAmountOutMin) external payable;
    function LiquidCOut (address beefyVault, uint256 withdrawAmount) external;
    function LiquidCOutAndSwap(address liquidCVault, uint256 withdrawAmount, address desiredToken, uint256 desiredTokenOutMin) external;
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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