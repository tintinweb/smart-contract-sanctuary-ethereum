/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// Sources flattened with hardhat v2.9.0 https://hardhat.org

// File @uniswap/v2-periphery/contracts/interfaces/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
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
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


// File @uniswap/v2-periphery/contracts/interfaces/[email protected]

pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File contracts/interfaces/IAdmin.sol

pragma solidity >=0.5.0;

interface IAdmin {
    function rootAdmin() external view returns (address);

    function changeRootAdmin(address _newRootAdmin) external;
}


// File contracts/abstracts/Admin.sol

pragma solidity 0.8.11;

contract Admin is IAdmin {
    address public override rootAdmin;

    event RootAdminChanged(address indexed oldRoot, address indexed newRoot);

    constructor(address _rootAdmin) {
        rootAdmin = _rootAdmin;
    }

    modifier onlyRootAdmin() {
        require(msg.sender == rootAdmin, "must be root admin");
        _;
    }

    function changeRootAdmin(address _newRootAdmin) public onlyRootAdmin {
        address oldRoot = rootAdmin;
        rootAdmin = _newRootAdmin;
        emit RootAdminChanged(oldRoot, rootAdmin);
    }
}


// File contracts/interfaces/IFeeCollector.sol

pragma solidity >=0.5.0;

interface IFeeCollector {
    function feeClaimer() external returns (address);

    function feeDecimals() external returns (uint256);

    function shifter() external returns (uint256);

    function fee() external returns (uint256);

    function tokenFeeReserves(address token) external returns (uint256);

    function collectFee(
        address token,
        uint256 amount,
        address beneficiary
    ) external;

    function setFeeClaimer(
        address newFeeClaimer
    ) external;

    function setFee(uint256 newFee) external;
}


// File contracts/abstracts/FeeCollector.sol

pragma solidity 0.8.11;


abstract contract FeeCollector is IFeeCollector {
    uint256 public constant override feeDecimals = 4;
    uint256 public constant override shifter = 10**feeDecimals;
    uint256 public override fee = 100; // 4 decimals => 0.01 * 10^4
    address public override feeClaimer;

    mapping(address => uint256) public override tokenFeeReserves;

    event FeeCollected(
        address indexed beneficiary,
        address indexed token,
        uint256 amount
    );
    event FeeClaimerChanged(
        address indexed oldFeeClaimer,
        address indexed newFeeClaimer
    );
    event FeeChanged(uint256 oldFee, uint256 newFee);

    modifier onlyFeeCalimer() {
        require(msg.sender == feeClaimer, "Only fee claimer");
        _;
    }

    constructor(address feeClaimer_) {
        feeClaimer = feeClaimer_;
    }

    function deductFee(address token, uint256 amount)
        internal
        returns (uint256, uint256)
    {
        uint256 collectedFee = (amount * fee) / shifter;
        uint256 output = amount - collectedFee;
        tokenFeeReserves[token] += collectedFee;
        return (output, collectedFee);
    }

    function collectFee(
        address token,
        uint256 amount,
        address beneficiary
    ) external override onlyFeeCalimer {
        uint256 withdrewAmount = amount >= tokenFeeReserves[token]
            ? tokenFeeReserves[token]
            : amount;
        IERC20(token).transfer(beneficiary, withdrewAmount);
        tokenFeeReserves[token] -= withdrewAmount;
        emit FeeCollected(beneficiary, token, withdrewAmount);
    }

    function _setFeeClaimer(address newFeeClaimer) internal {
        address oldFeeCalimer = feeClaimer;
        feeClaimer = newFeeClaimer;
        emit FeeClaimerChanged(oldFeeCalimer, feeClaimer);
    }

    function _setFee(uint256 newFee) internal {
        uint256 oldFee = fee;
        fee = newFee;
        emit FeeChanged(oldFee, fee);
    }
}


// File contracts/interfaces/IBridge.sol

pragma solidity >=0.5.0;

interface IBridge {
    function bridge(
        IERC20 _token,
        uint256 _amount,
        uint256 _destChainID,
        address _to
    ) external;
}


// File contracts/Broker.sol

pragma solidity 0.8.11;





contract Broker is Admin, FeeCollector {
    uint256 private constant _NEW = 0;
    uint256 private constant _COMPLETED = 1;

    mapping(uint256 => uint256) public orderStatus;
    address public swapRouter;
    address public bridge;

    event Purchased(
        uint256 orderId,
        address indexed payer,
        address indexed merchant,
        address inputToken,
        address indexed outputToken,
        uint256 amountIn,
        uint256 amountOut,
        uint256 fee,
        uint256 destChainId
    );

    event SwapRouterChanged(address oldSwapRouter, address newSwapRouter);
    event BridgeChanged(address oldBridge, address newBridge);

    constructor(
        address _router,
        address _bridge,
        address _rootAdmin,
        address _feeClaimer
    ) Admin(_rootAdmin) FeeCollector(_feeClaimer) {
        swapRouter = _router;
        bridge = _bridge;
    }

    function purchase(
        uint256 orderId,
        address merchant,
        address inputToken,
        address outputToken,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline,
        uint256 destChainID
    ) public {
        require(orderStatus[orderId] == _NEW, "Order was completed");

        uint256 amountOut;
        uint256 deductedFee;

        if (inputToken == outputToken) {
            (amountOut, deductedFee) = deductFee(inputToken, amountIn);

            IERC20(inputToken).transferFrom(
                msg.sender,
                address(this),
                amountOut
            );
        } else {
            uint256 swapOutput = swapTokensForExactTokens(
                inputToken,
                outputToken,
                amountOutMin,
                amountIn,
                address(this),
                deadline
            );

            (amountOut, deductedFee) = deductFee(outputToken, swapOutput);
        }

        if (getChainID() != destChainID) {
            IERC20(outputToken).approve(bridge, amountOut);
            IBridge(bridge).bridge(
                IERC20(outputToken),
                amountOut,
                destChainID,
                merchant
            );
        } else {
            IERC20(outputToken).transfer(merchant, amountOut);
        }

        orderStatus[orderId] = _COMPLETED;

        emit Purchased(
            orderId,
            msg.sender,
            merchant,
            inputToken,
            outputToken,
            amountIn,
            amountOut,
            deductedFee,
            destChainID
        );
    }

    function swapTokensForExactTokens(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountOut,
        uint256 _amountInMax,
        address _to,
        uint256 _deadline
    ) private returns (uint256) {
        IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountInMax);
        IERC20(_tokenIn).approve(swapRouter, _amountInMax);

        address[] memory path = new address[](2);

        path[0] = _tokenIn;
        path[1] = _tokenOut;

        // Receive an exact amount of output tokens for as few input tokens as possible
        uint256[] memory amounts = IUniswapV2Router02(swapRouter)
            .swapTokensForExactTokens(
                _amountOut,
                _amountInMax,
                path,
                _to,
                _deadline
            );

        return amounts[amounts.length - 1];
    }

    function setFee(uint256 newFee) external onlyRootAdmin {
        _setFee(newFee);
    }

    function setFeeClaimer(address newFeeClaimer) external onlyRootAdmin {
        _setFeeClaimer(newFeeClaimer);
    }

    function setSwapRouter(address newSwapRouter) external onlyRootAdmin {
        address oldSwapRouter = swapRouter;
        swapRouter = newSwapRouter;
        emit SwapRouterChanged(oldSwapRouter, newSwapRouter);
    }

    function setBridge(address newBridge) external onlyRootAdmin {
        address oldBridge = bridge;
        bridge = newBridge;
        emit BridgeChanged(oldBridge, newBridge);
    }

    function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}