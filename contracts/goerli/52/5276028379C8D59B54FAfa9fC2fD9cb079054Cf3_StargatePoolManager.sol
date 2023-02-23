// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IStargateRouter} from "../interfaces/IStargateRouter.sol";
import {IStargatePoolManager} from "../interfaces/IStargatePoolManager.sol";
import {IStargateEthVault} from "../interfaces/IStargateEthVault.sol";

contract StargatePoolManager is IStargatePoolManager, Ownable {
  uint8 internal constant TYPE_SWAP_REMOTE = 1;   // from Bridge.sol
  uint256 internal constant MIN_AMOUNT_LD = 1e4;  // the min amount you would accept on the destination when swapping using stargate

  address public immutable stargateEthVault;
  // IERC20 => dst chain id => pool id
  mapping (address => mapping (uint16 => PoolID)) public poolIds;
  IStargateRouter public stargateRouter;
  uint256 public gasForSgReceive = 350000;
  uint16 public ETH_POOL_ID = 13;

  constructor(address stargateRouter_, address stargateEthVault_) {
    stargateRouter = IStargateRouter(stargateRouter_);
    stargateEthVault = stargateEthVault_;
  }

  function setStargateRouter(address stargateRouter_) external onlyOwner {
    stargateRouter = IStargateRouter(stargateRouter_);
  }

  function setGasForSgReceive(uint256 gas) external onlyOwner {
    gasForSgReceive = gas;
  }

  /**
    * @notice set ERC20 token pool informations
    * @param token ERC20 token address
    * @param dstChainId destination chain id in layerZero
    * @param srcPoolId src pool id for ERC20 token
    * @param dstPoolId dst pool id for ERC20 token
   */
  function setPoolId(address token, uint16 dstChainId, uint256 srcPoolId, uint256 dstPoolId) public override onlyOwner {
    poolIds[token][dstChainId].srcPoolId = srcPoolId;
    poolIds[token][dstChainId].dstPoolId = dstPoolId;
  }

  /**
    * @notice get ERC20 token pool informations
    * @param token ERC20 token address
    * @param dstChainId destination chain id in layerZero
    * @return pool structure contains srcPoolId, dstPoolId
   */
  function getPoolId(address token, uint16 dstChainId) public view override returns (PoolID memory) {
    return poolIds[token][dstChainId];
  }

  /**
    * @notice check if ERC20 token is swappable using Stargate
    * @param token ERC20 token address
    * @param dstChainId destination chain id in layerZero
   */
  function isSwappable(address token, uint16 dstChainId) public view override returns (bool) {
    PoolID storage poolId = poolIds[token][dstChainId];

    if (poolId.srcPoolId == 0 || poolId.dstPoolId == 0) {
      return false;
    }

    return true;
  }

  /**
    * @notice get swap fee of stargate
    * @param dstChainId address of the execution strategy
    * @param to seller's recipient
    */
  function getSwapFee(
    uint16 dstChainId,
    address to,
    bytes memory payload
  ) public view override returns (uint256, uint256) {
    IStargateRouter.lzTxObj memory lzTxParams = IStargateRouter.lzTxObj(gasForSgReceive, 0, "0x");
    bytes memory toAddress = abi.encodePacked(to);

    (uint256 fee, uint256 lzFee) = stargateRouter.quoteLayerZeroFee(
      dstChainId,
      TYPE_SWAP_REMOTE,
      toAddress,
      payload,
      lzTxParams
    );

    return (fee, lzFee);
  }

  /**
    * @notice swap ERC20 token to 
    * @param dstChainId address of the execution strategy
    * @param refundAddress non fungible token address for the transfer
    * @param amount tokenId
    * @param to seller's recipient
    */
  function swap(
    address token,
    uint16 dstChainId,
    address payable refundAddress,
    uint256 amount,
    address from,
    address to,
    bytes memory payload
  ) external payable override {
    IStargateRouter.lzTxObj memory lzTxParams = IStargateRouter.lzTxObj(gasForSgReceive, 0, "0x");
    bytes memory toAddress = abi.encodePacked(to);
    PoolID memory poolId = getPoolId(token, dstChainId);

    IERC20(token).transferFrom(from, address(this), amount);
    IERC20(token).approve(address(stargateRouter), amount);

    stargateRouter.swap{value: msg.value}(
      dstChainId,
      poolId.srcPoolId,
      poolId.dstPoolId,
      refundAddress,
      amount,
      MIN_AMOUNT_LD,
      lzTxParams,
      toAddress,
      payload
    );
  }

  /**
    * @notice get WETH swap fee
    * @param dstChainId address of the execution strategy
    * @param to seller's recipient
    */
  function getSwapFeeETH(
    uint16 dstChainId,
    address to
  ) public view override returns (uint256, uint256) {
    return getSwapFee(dstChainId, to, bytes(""));
  }

  /**
    * @notice swap WETH
    * @param dstChainId address of the execution strategy
    * @param refundAddress non fungible token address for the transfer
    * @param amount tokenId
    * @param to seller's recipient
    */
  function swapETH(
    uint16 dstChainId,
    address payable refundAddress,
    uint256 amount,
    address to,
    bytes memory payload
  ) external payable override {
    require (address(stargateEthVault) != address(0), "invalid router eth");
    require(msg.value > amount, "Stargate: msg.value must be > _amountLD");
    
    bytes memory toAddress = abi.encodePacked(to);

    // wrap the ETH into WETH
    IStargateEthVault(stargateEthVault).deposit{value: amount}();
    IStargateEthVault(stargateEthVault).approve(address(stargateRouter), amount);

    // messageFee is the remainder of the msg.value after wrap
    uint256 messageFee = msg.value - amount;
    IStargateRouter.lzTxObj memory lzTxParams = IStargateRouter.lzTxObj(gasForSgReceive, 0, "0x");

    // compose a stargate swap() using the WETH that was just wrapped
    stargateRouter.swap{value: messageFee}(
        dstChainId, // destination Stargate chainId
        ETH_POOL_ID, // WETH Stargate poolId on source
        ETH_POOL_ID, // WETH Stargate poolId on destination
        refundAddress, // message refund address if overpaid
        amount, // the amount in Local Decimals to swap()
        MIN_AMOUNT_LD, // the minimum amount swap()er would allow to get out (ie: slippage)
        lzTxParams,
        toAddress, // address on destination to send to
        payload // empty payload, since sending to EOA
    );
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;
pragma abicoder v2;

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function addLiquidity(
        uint256 _poolId,
        uint256 _amountLD,
        address _to
    ) external;

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

    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function instantRedeemLocal(
        uint16 _srcPoolId,
        uint256 _amountLP,
        address _to
    ) external returns (uint256);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendCredits(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress
    ) external payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;
pragma abicoder v2;

interface IStargatePoolManager {
    struct PoolID {
        uint256 srcPoolId;
        uint256 dstPoolId;
    }
    
    function getSwapFee(
        uint16 dstChainId,
        address to,
        bytes memory payload
    ) external view returns (uint256, uint256);

    function swap(
        address token,
        uint16 dstChainId,
        address payable refundAddress,
        uint256 amount,
        address from,
        address to,
        bytes memory payload
    ) external payable;

    function getSwapFeeETH(
        uint16 dstChainId,
        address to
    ) external view returns (uint256, uint256);

    function swapETH(
        uint16 dstChainId,
        address payable refundAddress,
        uint256 amount,
        address to,
        bytes memory payload
    ) external payable;

    function setPoolId(address token, uint16 dstChainId, uint256 srcPoolId, uint256 dstPoolId) external;
    function getPoolId(address token, uint16 dstChainId) external view returns (PoolID memory);
    function isSwappable(address token, uint16 dstChainId) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IStargateEthVault {
    function deposit() external payable;

    function transfer(address to, uint value) external returns (bool);

    function withdraw(uint) external;

    function approve(address guy, uint wad) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint wad
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