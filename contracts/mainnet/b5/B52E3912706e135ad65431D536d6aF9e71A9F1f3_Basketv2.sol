// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./../interface/ILiquidCryptoBridge_v1.sol";
import "./../interface/IUniswapRouterETH.sol";
import "./../interface/ILiquidCZapUniswapV2.sol";
import "./../interface/IWETH.sol";

import "./../interface/stargate/IStargateRouter.sol";

contract Basketv2 is Ownable {
  address public bridge;

  mapping (address => bool) public managers;
  // vault -> account -> amount
  mapping (address => mapping (address => uint256)) public xlpSupply;

  address public stargaterouter;
  address public unirouter;
  address[] public nativeToStargateInput;
  address[] public stargateInputToNative;
  address public native;
  address public stargateInput;
  uint256 public stargateSourcePoolId;
  uint256 public stargateSwapFeeMultipler = 1400;
  uint256 public stargateSwapFeeDivider = 1000;

  struct PoolInfo {
    address liquidCZap;
    address vault;
    address router;
    address[] path;
    uint256 amount; // deposit - reserved  withdraw - specific amount
  }

  struct StragateSwapInfo {
    uint16 chain;
    address basketAddress;
    uint256 srcPoolID;
    uint256 dstPoolID;
    uint256 poolCnts;
  }

  struct Swaper {
    address router;
    address[] path0;
    address[] path1;
  }

  constructor(
    address _bridge,
    address _unirouter,
    address _stargaterouter,
    uint256 _stargateSourcePoolId,
    address[] memory _nativeToStargateInput,
    address[] memory _stargateInputToNative
  ) {
    managers[msg.sender] = true;
    bridge = _bridge;
    stargaterouter = _stargaterouter;
    unirouter = _unirouter;
    nativeToStargateInput = _nativeToStargateInput;
    stargateInputToNative = _stargateInputToNative;
    native = _nativeToStargateInput[0];
    stargateInput = _nativeToStargateInput[_nativeToStargateInput.length - 1];
    stargateSourcePoolId = _stargateSourcePoolId;

    _approveTokenIfNeeded(native, unirouter);
    _approveTokenIfNeeded(stargateInput, unirouter);
    _approveTokenIfNeeded(stargateInput, stargaterouter);
  }

  modifier onlyManager() {
    require(managers[msg.sender], "!manager");
    _;
  }

  receive() external payable {
  }

  function depositWithStargate(address account, PoolInfo[] memory pools, StragateSwapInfo[] memory swaps, uint256 itokenAmount, uint256 fee) public payable {
    uint256 inputAmount = msg.value;
    if (fee > 0) {
      if (inputAmount > fee) {
        inputAmount = inputAmount - fee;
        (bool success2, ) = msg.sender.call{value: fee}("");
        require(success2, "Failed to refund fee");
      }
      else if(itokenAmount > 0) {
        inputAmount = itokenAmount;
        uint256 requireFee = fee > address(this).balance ? fee - address(this).balance : 0;
        if (requireFee > 0) {
          uint256 iTokenBalance = IERC20(stargateInput).balanceOf(address(this));
          require(inputAmount <= iTokenBalance, "LiquidC Basket: stargate bridge not completed");
          uint256[] memory amounts = IUniswapRouterETH(unirouter).swapExactTokensForTokens(inputAmount, 0, stargateInputToNative, address(this), block.timestamp);
          uint256 nativeBalance = IERC20(native).balanceOf(address(this));
          if (nativeBalance > requireFee) {
            inputAmount = inputAmount - requireFee * amounts[0] / amounts[amounts.length-1];
            IWETH(native).withdraw(requireFee);
          }
          else {
            inputAmount = 0;
          }
        }
        (bool success2, ) = msg.sender.call{value: fee}("");
        require(success2, "Failed to refund fee");
      }
    }

    uint256 poolLen = pools.length;
    uint256 swapLen = swaps.length;
    uint256 totalNum = poolLen + swapLen;
    if (swapLen > 0) {
      uint256 otherChainAmount = inputAmount * swapLen / totalNum;
      _stargateSwap(swaps, otherChainAmount);
    }

    if (poolLen > 0) {
      if (address(this).balance > 0) {
        IWETH(native).deposit{value: address(this).balance}();
      }
      uint256 nativeBalance = IERC20(native).balanceOf(address(this));
      uint256 amount = nativeBalance / poolLen;
      for (uint256 i=0; i<poolLen; i++) {
        _deposit(account, pools[i].liquidCZap, pools[i].vault, pools[i].router, pools[i].path, amount);
      }
    }
  }

  function withdrawWithStargate(address account, PoolInfo[] memory pools, StragateSwapInfo memory swap, uint256 fee) public onlyManager {
    uint256 poolLen = pools.length;
    if (poolLen > 0) {
      for (uint256 i=0; i<poolLen; i++) {
        require(xlpSupply[pools[i].vault][account] >= pools[i].amount, "LiquidC Basket: Not enough xlpbalance");
        _approveTokenIfNeeded(pools[i].vault, pools[i].liquidCZap);
        ILiquidCZapUniswapV2(pools[i].liquidCZap).LiquidCOutAndSwap(pools[i].vault, pools[i].amount, pools[i].path[0], 0);

        xlpSupply[pools[i].vault][account] = xlpSupply[pools[i].vault][account] - pools[i].amount;

        if (pools[i].path.length > 1) {
          _approveTokenIfNeeded(pools[i].path[0], pools[i].router);
          uint256 t0amount = IERC20(pools[i].path[0]).balanceOf(address(this));
          IUniswapRouterETH(pools[i].router).swapExactTokensForTokens(t0amount, 0, pools[i].path, address(this), block.timestamp);
        }
      }
    }

    if (fee > 0) {
      uint256 nativeBalance = IERC20(native).balanceOf(address(this));
      if (nativeBalance > 0) {
        IWETH(native).withdraw(nativeBalance);
      }
      uint256 requireFee = fee > address(this).balance ? fee - address(this).balance : 0;
      if (requireFee > 0) {
        uint256 iTokenBalance = IERC20(stargateInput).balanceOf(address(this));
        IUniswapRouterETH(unirouter).swapTokensForExactTokens(requireFee, iTokenBalance, stargateInputToNative, address(this), block.timestamp);
        nativeBalance = IERC20(native).balanceOf(address(this));
        IWETH(native).withdraw(nativeBalance);
      }
      (bool success2, ) = msg.sender.call{value: fee}("");
      require(success2, "Failed to refund fee");
    }

    
    if (swap.poolCnts > 0) {
      (uint256 swFee, ) = IStargateRouter(stargaterouter).quoteLayerZeroFee(
        swap.chain,
        1,
        bytes("0x"),
        bytes("0x"),
        IStargateRouter.lzTxObj(0, 0, "0x")
      );
      swFee = swFee * stargateSwapFeeMultipler / stargateSwapFeeDivider;

      IWETH(native).deposit{value: address(this).balance - swFee}();

      uint256 nativeBalance = IERC20(native).balanceOf(address(this));
      IUniswapRouterETH(unirouter).swapExactTokensForTokens(nativeBalance, 0, nativeToStargateInput, address(this), block.timestamp);
      uint256 iTokenBalance = IERC20(stargateInput).balanceOf(address(this));
      _bridgeSwap(swap, swFee, iTokenBalance);
    }
    else {
      (bool success2, ) = payable(account).call{value: address(this).balance}("");
      require(success2, "Failed to refund fee");
    }
  }

  function _stargateSwap(StragateSwapInfo[] memory swaps, uint256 otherChainAmount) internal {
    uint256 swapLen = swaps.length;
    uint256 totalSwfee = 0;
    uint256[] memory swFees = new uint256[](swapLen);
    for (uint256 i=0; i<swapLen; i++) {
      (uint256 swFee, ) = IStargateRouter(stargaterouter).quoteLayerZeroFee(
        swaps[i].chain,
        1,
        bytes("0x"),
        bytes("0x"),
        IStargateRouter.lzTxObj(0, 0, "0x")
      );
      swFee = swFee * stargateSwapFeeMultipler / stargateSwapFeeDivider;
      swFees[i] = swFee;
      totalSwfee = totalSwfee + swFee;
    }

    if (totalSwfee <= otherChainAmount) {
      IWETH(native).deposit{value: otherChainAmount - totalSwfee}();
    }
    uint256 nativeBalance = IERC20(native).balanceOf(address(this));
    if (nativeBalance > 0) {
      IUniswapRouterETH(unirouter).swapExactTokensForTokens(nativeBalance, 0, nativeToStargateInput, address(this), block.timestamp);
    }

    uint256 stargateInputBalance = IERC20(stargateInput).balanceOf(address(this));
    if (stargateInputBalance > 0) {
      for (uint256 i=0; i<swapLen; i++) {
        uint256 iamount = stargateInputBalance * swaps[i].poolCnts / swapLen;
        if (iamount > 0) {
          _bridgeSwap(swaps[i], swFees[i], iamount);
        }
      }
    }
  }

  function _bridgeSwap(StragateSwapInfo memory swap, uint256 _swfee, uint256 _iamount) internal {
    IStargateRouter(stargaterouter).swap{value: _swfee}(
      swap.chain,
      stargateSourcePoolId,
      swap.dstPoolID,
      payable(address(this)),
      _iamount,
      0,
      IStargateRouter.lzTxObj(0, 0, "0x"),
      abi.encodePacked(swap.basketAddress),
      bytes("")
    );
  }

  function deposit(address account, address liquidCZap, address vault, address router, address[] memory path) public payable {
    IWETH(path[0]).deposit{value: msg.value}();
    _deposit(account, liquidCZap, vault, router, path, msg.value);
  }

  function depositViaBridge(uint256 withdrawAmount, uint256 fee, address account, address liquidCZap, address vault, address router, address[] memory path) public {
    ILiquidCryptoBridge_v1(bridge).withdrawForUser(address(this), true, withdrawAmount, fee);
    uint256 amount = IERC20(path[0]).balanceOf(address(this));
    _deposit(account, liquidCZap, vault, router, path, amount);
  }

  function _deposit(address account, address liquidCZap, address vault, address router, address[] memory path, uint256 amount) private {
    _approveTokenIfNeeded(path[0], router);
    if (path.length > 1) {
      IUniswapRouterETH(router).swapExactTokensForTokens(amount, 0, path, address(this), block.timestamp);
    }
    
    uint256 tokenbalance = IERC20(path[path.length-1]).balanceOf(address(this));
    _approveTokenIfNeeded(path[path.length-1], liquidCZap);

    uint256 oldxlpbalance = IERC20(vault).balanceOf(address(this));
    ILiquidCZapUniswapV2(liquidCZap).LiquidCIn(vault, 0, path[path.length-1], tokenbalance);
    uint256 xlpbalance = IERC20(vault).balanceOf(address(this));
    xlpSupply[vault][account] = xlpSupply[vault][account] + xlpbalance - oldxlpbalance;
    // IERC20(vault).transfer(account, xlpbalance);
  }

  function moveBasket2Pool(address vault, uint256 amount) public {
    require(amount <= xlpSupply[vault][msg.sender], "Your balance is not enough");
    xlpSupply[vault][msg.sender] = xlpSupply[vault][msg.sender] - amount;
    IERC20(vault).transfer(msg.sender, amount);
  }

  function withdraw(address account, address liquidCZap, address vault, Swaper memory swper, uint256 amount, uint256 fee) public onlyManager {
    _withdraw(liquidCZap, vault, swper, amount);
    uint256 outAmount = address(this).balance;
    outAmount = outAmount - fee;

    (bool success1, ) = account.call{value: outAmount}("");
    require(success1, "Failed to withdraw");

    if (fee > 0) {
      (bool success2, ) = msg.sender.call{value: outAmount}("");
      require(success2, "Failed to refund fee");
    }

    xlpSupply[vault][account] = xlpSupply[vault][account] - amount;
  }

  function withdrawToBridge(address account, address liquidCZap, address vault, Swaper memory swper, uint256 amount, uint256 fee) public onlyManager {
    _withdraw(liquidCZap, vault, swper, amount);
    uint256 inAmount = address(this).balance;
    
    ILiquidCryptoBridge_v1(bridge).depositForUser{value: inAmount}(fee);

    xlpSupply[vault][account] = xlpSupply[vault][account] - amount;
  }

  function _withdraw(address liquidCZap, address vault, Swaper memory swper, uint256 amount) private {
    _approveTokenIfNeeded(vault, liquidCZap);
    ILiquidCZapUniswapV2(liquidCZap).LiquidCOut(vault, amount);

    if (swper.path0.length > 1) {
      _approveTokenIfNeeded(swper.path0[0], swper.router);
      uint256 t0amount = IERC20(swper.path0[0]).balanceOf(address(this));
      IUniswapRouterETH(swper.router).swapExactTokensForTokens(t0amount, 0, swper.path0, address(this), block.timestamp);
    }
    if (swper.path1.length > 1) {
      _approveTokenIfNeeded(swper.path1[0], swper.router);
      uint256 t1amount = IERC20(swper.path1[0]).balanceOf(address(this));
      IUniswapRouterETH(swper.router).swapExactTokensForTokens(t1amount, 0, swper.path1, address(this), block.timestamp);
    }

    address weth = swper.path0[swper.path0.length-1];
    uint256 wethBalance = IERC20(weth).balanceOf(address(this));
    IWETH(weth).withdraw(wethBalance);
  }

  function setBridge(address addr) public onlyManager {
    bridge = addr;
  }

  function setStargateSwapFeeMultipler(uint256 _stargateSwapFeeMultipler) public onlyManager {
    stargateSwapFeeMultipler = _stargateSwapFeeMultipler;
  }

  function setStargateSwapFeeDivider(uint256 _stargateSwapFeeDivider) public onlyManager {
    stargateSwapFeeDivider = _stargateSwapFeeDivider;
  }

  function setManager(address account, bool access) public onlyOwner {
    managers[account] = access;
  }

  function withdrawStargateRefundFee(uint256 fee) public onlyOwner {
    (bool success1, ) = payable(msg.sender).call{value: fee}("");
    require(success1, "Failed to withdraw");
  }

  function _approveTokenIfNeeded(address token, address spender) private {
    if (IERC20(token).allowance(address(this), spender) == 0) {
      IERC20(token).approve(spender, type(uint256).max);
    }
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
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

interface ILiquidCryptoBridge_v1 {
  struct SwapVoucher {
    address account;
    uint256 inChain;
    uint256 inAmount;
    uint256 outChain;
    uint256 outAmount;
  }

  function depositForUser(uint256 fee) external payable;
  function withdrawForUser(address account, bool isContract, uint256 outAmount, uint256 fee) external;
  function refundFaildVoucher(uint256 index, uint256 amount, uint256 fee) external;
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