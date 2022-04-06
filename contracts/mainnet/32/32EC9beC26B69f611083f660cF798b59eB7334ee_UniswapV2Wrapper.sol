// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/uniswap/IUniswapV2Router02.sol";
import "../../interfaces/uniswap/IUniswapV2Factory.sol";

import "./WrapperBase.sol";
import "../../libraries/OperationsLib.sol";

//TODO: refund unused part for liquidity

/// @title Uniswap V2 Wrapper
/// @author Cosmin Grigore (@gcosmintech)
/// Can be deployed for:
/// - UniswapV2 (all layers)
/// - Sushiswap (all layers)
/// - Quickswap (Matic)
/// - Sushiswap (Matic)
/// - Dfyn (Matic)
/// - Sushiswap (Arbitrum)
/// - SolarBeam (Moonriver)
/// - Elk Finance (Moonriver)
/// - Huckleberry (Moonriver)
/// - Spookyswap (Fantom)
/// - Spiritswap (Fantom)
contract UniswapV2Wrapper is WrapperBase {
    using SafeERC20 for IERC20;

    ///@notice Router used to perform various DEX operations
    IUniswapV2Router02 public swapRouter;

    ///@notice Factory used in various DEX Operations
    IUniswapV2Factory public factory;

    /// @notice Internal data used only in the add liquidity method
    struct AddLiquidityTemporaryData {
        uint256 _amountADesired;
        uint256 _amountBDesired;
        uint256 _amountAMin;
        uint256 _amountBMin;
        uint256 _usedA;
        uint256 _usedB;
        uint256 _obtainedLP;
        uint256 _deadline;
    }
    /// @notice Internal data used only in the remove liquidity method
    struct RemoveLiquidityTemporaryData {
        uint256 _liquidity;
        uint256 _amountAMin;
        uint256 _amountBMin;
        uint256 _obtainedA;
        uint256 _obtainedB;
        uint256 _deadline;
    }

    constructor(
        address _router,
        address _factory,
        address _dexManager
    ) WrapperBase(_dexManager) {
        require(_router != address(0), "ERR: INVALID ROUTER ADDRESS");
        require(_factory != address(0), "ERR: INVALID FACTORY ADDRESS");
        require(_dexManager != address(0), "ERR: INVALID DEX_MANAGER ADDRESS");
        swapRouter = IUniswapV2Router02(_router);
        factory = IUniswapV2Factory(_factory);
    }

    //-----------------
    //----------------- View methods -----------------
    //-----------------
    /// @notice Returns the amount one would obtain from a swap
    /// @param tokenIn Token in address
    /// @param tokenOut Token to be ontained from swap address
    /// @param amountIn Amount to be used for swap
    /// @return Token out amount
    function getAmountsOut(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        bytes calldata
    ) external payable override noValue returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        uint256[] memory amounts = swapRouter.getAmountsOut(amountIn, path);
        return amounts[1];
    }

    /// @notice Sets the swap router address
    /// @param _router Swap router address
    function setRouter(address _router) external onlyValidAddress(_router) onlyOwner {
        emit RouterChanged(msg.sender, address(swapRouter), _router);
        swapRouter = IUniswapV2Router02(_router);
    }

    /// @notice Sets the factory address
    /// @param _factory Factory address
    function setFactory(address _factory) external onlyValidAddress(_factory) onlyOwner {
        emit FactoryChanged(msg.sender, address(factory), _factory);
        factory = IUniswapV2Factory(_factory);
    }

    //-----------------
    //----------------- Non-view methods -----------------
    //-----------------
    /// @notice Performs a swap
    /// @param _tokenIn Token A address
    /// @param _tokenOut Token B address
    /// @param _amountsData Token A amount, Min amount for Token B
    /// @param _data AMM specific data
    function swap(
        address _tokenIn,
        address _tokenOut,
        bytes calldata _amountsData,
        bytes calldata _data
    ) external override enforceDexManagerAddress returns (uint256) {
        uint256 deadline = abi.decode(_data, (uint256));
        (uint256 _amount, uint256 _amountOutMin) = abi.decode(_amountsData, (uint256, uint256));

        IERC20(_tokenIn).safeTransferFrom(msg.sender, address(this), _amount);
        OperationsLib.safeApprove(_tokenIn, address(swapRouter), _amount);

        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        uint256[] memory amounts = swapRouter.swapExactTokensForTokens(
            _amount,
            _amountOutMin,
            path,
            msg.sender,
            deadline
        );
        emit Swapped(_tokenIn, _tokenOut, _amount, amounts[1]);
        return amounts[1];
    }

    /// @notice Adds liquidity and sends obtained LP & leftovers to sender
    /// @param _tokenA Token A address
    /// @param _tokenB Token B address
    /// @param _amountsData Amount info (amount A, amount B, min amount A, min amount B)
    /// @param _data AMM specific data

    function addLiquidity(
        address _tokenA,
        address _tokenB,
        address _recipient,
        bytes calldata _amountsData,
        bytes calldata _data
    )
        external
        override
        enforceDexManagerAddress
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        AddLiquidityTemporaryData memory tempData;
        (tempData._amountADesired, tempData._amountBDesired, tempData._amountAMin, tempData._amountBMin) = abi.decode(
            _amountsData,
            (uint256, uint256, uint256, uint256)
        );

        IERC20(_tokenA).safeTransferFrom(msg.sender, address(this), tempData._amountADesired);
        OperationsLib.safeApprove(_tokenA, address(swapRouter), tempData._amountADesired);
        IERC20(_tokenB).safeTransferFrom(msg.sender, address(this), tempData._amountBDesired);
        OperationsLib.safeApprove(_tokenB, address(swapRouter), tempData._amountBDesired);

        tempData._deadline = abi.decode(_data, (uint256));
        address recipient = _recipient; // fix stack too deep error
        (tempData._usedA, tempData._usedB, tempData._obtainedLP) = swapRouter.addLiquidity(
            _tokenA,
            _tokenB,
            tempData._amountADesired,
            tempData._amountBDesired,
            tempData._amountAMin,
            tempData._amountBMin,
            recipient,
            tempData._deadline
        );
        emit AddedLiquidity(
            _tokenA,
            _tokenB,
            tempData._amountADesired,
            tempData._amountBDesired,
            tempData._usedA,
            tempData._usedB,
            tempData._obtainedLP
        );
        if (tempData._amountADesired > tempData._usedA) {
            IERC20(_tokenA).safeTransfer(_recipient, tempData._amountADesired - tempData._usedA);
        }
        if (tempData._amountBDesired > tempData._usedB) {
            IERC20(_tokenB).safeTransfer(_recipient, tempData._amountBDesired - tempData._usedB);
        }
        return (tempData._usedA, tempData._usedB, tempData._obtainedLP);
    }

    /// @notice Removes liquidity and sends obtained tokens to sender
    /// @param _tokenA Token A address
    /// @param _tokenB Token B address
    /// @param _amountsData LP amount to be burnt, Min amount for token A, Min amount for token B
    /// @param _data AMM specific data

    function removeLiquidity(
        address _tokenA,
        address _tokenB,
        address _recipient,
        bytes calldata _amountsData,
        bytes calldata _data
    ) external override enforceDexManagerAddress returns (uint256, uint256) {
        RemoveLiquidityTemporaryData memory tempData;
        (tempData._liquidity, tempData._amountAMin, tempData._amountBMin) = abi.decode(
            _amountsData,
            (uint256, uint256, uint256)
        );
        tempData._deadline = abi.decode(_data, (uint256));

        address lp = factory.getPair(_tokenA, _tokenB);
        IERC20(lp).safeTransferFrom(_recipient, address(this), tempData._liquidity);
        OperationsLib.safeApprove(lp, address(swapRouter), tempData._liquidity);

        (tempData._obtainedA, tempData._obtainedB) = swapRouter.removeLiquidity(
            _tokenA,
            _tokenB,
            tempData._liquidity,
            tempData._amountAMin,
            tempData._amountBMin,
            _recipient,
            tempData._deadline
        );
        emit RemovedLiquidity(_tokenA, _tokenB, tempData._liquidity, tempData._obtainedA, tempData._obtainedB);
        return (tempData._obtainedA, tempData._obtainedB);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setMigrator(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity  >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../interfaces/IDex.sol";

abstract contract WrapperBase is Ownable, ReentrancyGuard, IDex {
  ///@notice Address of the dex manager
  address public dexManager;

  ///@notice Enforces sender to be dex manager
  bool public enforceDexManager;

  constructor(address _dexManager) {
    dexManager = _dexManager;
    enforceDexManager = true;
  }

  //-----------------
  //----------------- Owner methods -----------------
  //-----------------
  /// @notice Enforces caller to be the Dex Manager only
  function allowOnlyManager() external onlyOwner {
    enforceDexManager = true;
    emit AllowManager(msg.sender);
  }

  /// @notice Allows everyone to be the msg sender
  function allowEveryone() external onlyOwner {
    enforceDexManager = false;
    emit AllowEveryone(msg.sender);
  }

  /// @notice Sets the dex manager address
  /// @param _dexManager Dex manager address
  function setManager(address _dexManager) external onlyOwner {
    require(_dexManager != address(0), "ERR: INVALID ADDRESS");
    emit ManagerChanged(msg.sender, dexManager, _dexManager);
    dexManager = _dexManager;
  }

  modifier enforceDexManagerAddress() {
    if (enforceDexManager) {
      require(msg.sender == dexManager, "ERR: UNAUTHORIZED");
    }
    _;
  }

  modifier onlyValidAddress(address _address) {
      require(_address != address(0), "ERR: INVALID ADDRESS");
      _;
  }

  modifier noValue(){
    require(msg.value == 0, "ERR: NO VALUE");
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library OperationsLib {
	function safeApprove(
		address token,
		address to,
		uint256 value
	) internal {
		(bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
		require(success && (data.length == 0 || abi.decode(data, (bool))), "OperationsLib::safeApprove: approve failed");
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
pragma solidity >=0.7.0 <0.9.0;

/// @title Common interface for AMMs
/// @author Cosmin Grigore (@gcosmintech)
interface IDex {
    event AllowManager(address indexed owner);
    event AllowEveryone(address indexed owner);
    event ManagerChanged(
        address indexed owner,
        address indexed oldManager,
        address indexed newManager
    );
    event RouterChanged(
        address indexed owner,
        address indexed oldRouter,
        address indexed newRouter
    );
    event FactoryChanged(
        address indexed owner,
        address indexed oldFactory,
        address indexed newFactory
    );
    event Swapped(
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 _amountIn,
        uint256 _amountOut
    );
    event AddedLiquidity(
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 usedA,
        uint256 usedB,
        uint256 obtainedLP
    );

    event RemovedLiquidity(
        address indexed tokenA,
        address indexed tokenB,
        uint256 liquidity,
        uint256 obtainedA,
        uint256 obtainedB
    );

    function getAmountsOut(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        bytes calldata _data
    ) external payable returns (uint256);

    function swap(
        address _tokenA,
        address _tokenB,
        bytes calldata _amountsData,
        bytes calldata _data
    ) external returns (uint256);

    function addLiquidity(
        address _tokenA,
        address _tokenB,
        address _recipient,
        bytes calldata _amountsData,
        bytes calldata _data
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function removeLiquidity(
        address _tokenA,
        address _tokenB,
        address _recipient,
        bytes calldata _amountsData,
        bytes calldata _data
    ) external returns (uint256, uint256);
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