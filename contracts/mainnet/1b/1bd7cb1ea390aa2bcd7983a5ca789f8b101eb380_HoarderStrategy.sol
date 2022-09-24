// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./interfaces/IHoarderStrategy.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IHoarderRewards.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/IClearpoolPool.sol";
import "./interfaces/IUSDT.sol";
import "./interfaces/IUSDH.sol";
import "./interfaces/IRouter.sol";
import "v3-periphery/interfaces/external/IWETH9.sol";

contract HoarderStrategy is IHoarderStrategy, ReentrancyGuard {
    uint256 private constant max = type(uint256).max;

    address private constant _tokenDeposit = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;// USDC
    address private constant _token = 0xCb288b6d30738db7E3998159d192615769794B5b;// cpWIN-USDC
    uint24 private constant _feeTier = 100;
    string private constant _name = "Clearpool cpWIN-USDC";

    address public immutable hoarder;
    IHoarderRewards public immutable hoarderRewards;

    IUSDT public constant TokenDeposit = IUSDT(_tokenDeposit);
    IUSDT public constant Token = IUSDT(_token);

    address private constant _tokenRewards = 0x66761Fa41377003622aEE3c7675Fc7b5c1C2FaC5;
    IUSDT private constant TokenRewards = IUSDT(_tokenRewards);

    ISwapRouter private constant router = ISwapRouter(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
    IRouter private constant routerV2 = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    IClearpoolPool private clearpoolPool = IClearpoolPool(_token);

    IUSDH public immutable usdh;
    IUSDT public immutable Usdh;
    address private constant hrd = 0x461B71cff4d4334BbA09489acE4b5Dc1A1813445;

    address public collateral = 0x99D8a9C45b2ecA8864373A26D1459e3Dff1e17F3;// MIM
    IUSDT public Collateral = IUSDT(collateral);

    uint256 public deposits;

    address private constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IWETH9 private constant Weth = IWETH9(weth);

    address public strategist;

    modifier onlyHoarder {
        require(msg.sender == hoarder);
        _;
    }

    modifier onlyStrategist {
        require(msg.sender == strategist);
        _;
    }

    constructor (address _hoarder, address _hoarderRewards, address _usdh, address _strategist) {
        hoarder = _hoarder;
        hoarderRewards = IHoarderRewards(_hoarderRewards);
        usdh = IUSDH(_usdh);
        Usdh = IUSDT(_usdh);
        strategist = _strategist;
    }

    function _swap(uint256 _amountIn, address _tokenIn, address _tokenOut, uint24 _fee) private {
        try router.exactInputSingle(ISwapRouter.ExactInputSingleParams({tokenIn: _tokenIn, tokenOut: _tokenOut, fee: _fee, recipient: address(this), amountIn: _amountIn, amountOutMinimum: 0, sqrtPriceLimitX96: 0})) {} catch {
            try router.exactInputSingle(ISwapRouter.ExactInputSingleParams({tokenIn: _tokenIn, tokenOut: _tokenOut, fee: 100, recipient: address(this), amountIn: _amountIn, amountOutMinimum: 0, sqrtPriceLimitX96: 0})) {} catch {
                try router.exactInputSingle(ISwapRouter.ExactInputSingleParams({tokenIn: _tokenIn, tokenOut: _tokenOut, fee: 500, recipient: address(this), amountIn: _amountIn, amountOutMinimum: 0, sqrtPriceLimitX96: 0})) {} catch {
                    try router.exactInputSingle(ISwapRouter.ExactInputSingleParams({tokenIn: _tokenIn, tokenOut: _tokenOut, fee: 3000, recipient: address(this), amountIn: _amountIn, amountOutMinimum: 0, sqrtPriceLimitX96: 0})) {} catch {
                        router.exactInputSingle(ISwapRouter.ExactInputSingleParams({tokenIn: _tokenIn, tokenOut: _tokenOut, fee: 10000, recipient: address(this), amountIn: _amountIn, amountOutMinimum: 0, sqrtPriceLimitX96: 0}));
                    }
                }
            }
        }
    }

    function _pool(uint256 _amount) private {
        deposits = deposits + _amount;
        clearpoolPool.provide(_amount);
    }

    function _supplyDeficitFund() private {
        uint256 yield = Collateral.balanceOf(address(this));
        usdh.mint(collateral, yield * 7000 / 10000, false);
        try Usdh.transfer(0x000000000000000000000000000000000000dEaD, yield * 500 / 10000) {} catch { Usdh.transfer(0x000000000000000000000000000000000000dEaD, Usdh.balanceOf(address(this)) * 500 / 10000); }
    }

    function _buyback() private {
        _swap(Collateral.balanceOf(address(this)), collateral, weth, 10000);
        Weth.withdraw(Weth.balanceOf(address(this)));
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = 0x461B71cff4d4334BbA09489acE4b5Dc1A1813445;
        routerV2.swapExactETHForTokensSupportingFeeOnTransferTokens{value: address(this).balance}(0, path, 0x000000000000000000000000000000000000dEaD, block.timestamp);
    }

    function _depositRewards() private {
        hoarderRewards.deposit(Usdh.balanceOf(address(this)));
    }

    function _unpool() private {
        clearpoolPool.redeem(max);
        uint256 balance = TokenDeposit.balanceOf(address(this));
        if ((balance > deposits) && (deposits > 0)) {
            _swap((balance - deposits), _tokenDeposit, collateral, 500);
            _supplyDeficitFund();
            _buyback();
            _depositRewards();
            deposits = 0;
        }
        uint256 rewards = TokenRewards.balanceOf(address(this));
        if (rewards > 0) {
            balance = TokenDeposit.balanceOf(address(this));
            _swap(rewards, _tokenRewards, _tokenDeposit, 10000);
            uint256 toSwap = TokenDeposit.balanceOf(address(this)) - balance;
            if (toSwap > 0) {
                _swap(toSwap, _tokenDeposit, collateral, 500);
                _supplyDeficitFund();
                _buyback();
                _depositRewards();
            }
        }
    }

    function _deposit(uint256 amount) private {
        _pool(amount);
    }

    function _withdraw(uint256 amount) private returns (uint256) {
        _unpool();
        if ((TokenDeposit.balanceOf(address(this)) > 0) && (amount > 0)) _swap(amount > TokenDeposit.balanceOf(address(this)) ? TokenDeposit.balanceOf(address(this)) : amount, _tokenDeposit, collateral, 500);
        uint256 withdrawn;
        if (Collateral.balanceOf(address(this)) > 0) {
            uint256 balance = Usdh.balanceOf(address(this));
            usdh.mint(collateral, Collateral.balanceOf(address(this)), false);
            withdrawn = Usdh.balanceOf(address(this)) - balance;
            Usdh.transfer(msg.sender, withdrawn);
        }
        _pool(TokenDeposit.balanceOf(address(this)));
        return withdrawn;
    }

    function init(address tokenDepositOld, uint256 amount) external override nonReentrant onlyHoarder {
        TokenDeposit.approve(address(router), max);
        Token.approve(address(router), max);
        TokenDeposit.approve(_token, max);
        Usdh.approve(address(hoarderRewards), max);
        Collateral.approve(address(usdh), max);
        Collateral.approve(address(router), max);
        TokenRewards.approve(address(router), max);
        if (amount > 0) {
            IUSDT TokenDepositOld = IUSDT(tokenDepositOld);
            require(TokenDepositOld.balanceOf(msg.sender) >= amount);
            require(TokenDepositOld.allowance(msg.sender, address(this)) >= amount);
            uint256 snapshot = TokenDepositOld.balanceOf(address(this));
            TokenDepositOld.transferFrom(msg.sender, address(this), amount);
            require(TokenDepositOld.balanceOf(address(this)) == snapshot + amount);
            if (tokenDepositOld != tokenDeposit()) {
                TokenDepositOld.approve(address(router), max);
                _swap(TokenDepositOld.balanceOf(address(this)), tokenDepositOld, tokenDeposit(), 100);
            }
            _deposit(TokenDeposit.balanceOf(address(this)));
        }
    }

    function deposit(uint256 amount) external override nonReentrant onlyHoarder {
        require(TokenDeposit.balanceOf(msg.sender) >= amount);
        require(TokenDeposit.allowance(msg.sender, address(this)) >= amount);
        uint256 snapshot = TokenDeposit.balanceOf(address(this));
        TokenDeposit.transferFrom(msg.sender, address(this), amount);
        require(TokenDeposit.balanceOf(address(this)) == snapshot + amount);
        _deposit(amount);
    }

    function withdraw(uint256 amount) external override nonReentrant onlyHoarder returns (uint256) {
        return _withdraw(amount / (10 ** 12));
    }

    function end() external override nonReentrant onlyHoarder {
        _unpool();
        TokenDeposit.transfer(hoarder, TokenDeposit.balanceOf(address(this)));
    }

    function setStrategist(address _strategist) external nonReentrant onlyStrategist {
        strategist = _strategist;
    }

    function getStrategist() external view override returns (address) {
        return strategist;
    }

    function tokenDeposit() public pure override returns (address) {
        return _tokenDeposit;
    }

    function token() external pure override returns (address) {
        return _token;
    }

    function feeTier() external pure override returns (uint24) {
        return _feeTier;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface IHoarderStrategy {
    function init(address tokenDepositOld, uint256 amount) external;
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external returns (uint256);
    function end() external;
    function getStrategist() external view returns (address);
    function tokenDeposit() external view returns (address);
    function token() external view returns (address);
    function feeTier() external view returns (uint24);
    function name() external pure returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface IHoarderRewards {
    function setBalance(address shareholder, uint256 amount) external;
    function deposit(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
        //uint256 deadline;
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
        //uint256 deadline;
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
        //uint256 deadline;
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
        //uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface IClearpoolPool {
    function provide(uint256 currencyAmount) external;
    function redeem(uint256 tokens) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface IUSDT {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface IUSDH {
    function increaseLiquidity(uint256 _amount0) external returns (uint256);
    function decreaseLiquidity(uint256 _amount) external returns (bool);
    function mint(address _collateral, uint256 _amount, bool _exactOutput) external;
    function redeem(uint256 _amount) external returns (address[] memory);
    function getLargestBalance() external returns (address, uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface IRouter {
    function factory() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
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