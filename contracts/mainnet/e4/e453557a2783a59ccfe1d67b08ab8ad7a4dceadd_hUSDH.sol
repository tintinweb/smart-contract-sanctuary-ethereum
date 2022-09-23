// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./HoarderRewards.sol";
import "./interfaces/IUSDH.sol";
import "./interfaces/IHoarderStrategy.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/IUSDT.sol";

contract hUSDH is IERC20, ReentrancyGuard {
    uint256 private constant max = type(uint256).max;

    string constant _name = "Hoarder USDH";
    string constant _symbol = "hUSDH";
    uint8 constant _decimals = 18;

    uint256 _totalSupply;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) public rewardExempt;

    HoarderRewards rewards;

    address public immutable usdh;
    IUSDH public immutable Usdh;
    IERC20 public immutable USDH;

    address public strategy;

    IHoarderStrategy public Strategy;

    ISwapRouter private constant router = ISwapRouter(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);

    address public swapThrough = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    address public governance;

    bool public disabled;
    bool public canDisable = true;

    modifier onlyGovernance() {
        require(msg.sender == governance);
        _;
    }

    constructor (address _usdh) {
        rewards = new HoarderRewards(_usdh, msg.sender);
        governance = msg.sender;

        rewardExempt[address(this)] = true;
        rewardExempt[address(0)] = true;
        rewardExempt[0x000000000000000000000000000000000000dEaD] = true;

        usdh = _usdh;
        Usdh = IUSDH(_usdh);
        USDH = IERC20(_usdh);

        approve(address(this), _totalSupply);
        approve(_usdh, _totalSupply);
        _balances[address(this)] = _totalSupply;
        emit Transfer(address(0), address(this), _totalSupply);
    }

    function _swap(address _tokenIn, address _tokenOut, uint24 _feeTier) private {
        if (_tokenIn != swapThrough) {
            IUSDT(_tokenIn).approve(address(router), max);
            try router.exactInputSingle(ISwapRouter.ExactInputSingleParams({tokenIn: _tokenIn, tokenOut: swapThrough, fee: 100, recipient: address(this), amountIn: IUSDT(_tokenIn).balanceOf(address(this)), amountOutMinimum: 0, sqrtPriceLimitX96: 0})) {} catch {
                try router.exactInputSingle(ISwapRouter.ExactInputSingleParams({tokenIn: _tokenIn, tokenOut: swapThrough, fee: 500, recipient: address(this), amountIn: IUSDT(_tokenIn).balanceOf(address(this)), amountOutMinimum: 0, sqrtPriceLimitX96: 0})) {} catch {
                    try router.exactInputSingle(ISwapRouter.ExactInputSingleParams({tokenIn: _tokenIn, tokenOut: swapThrough, fee: 3000, recipient: address(this), amountIn: IUSDT(_tokenIn).balanceOf(address(this)), amountOutMinimum: 0, sqrtPriceLimitX96: 0})) {} catch {
                        router.exactInputSingle(ISwapRouter.ExactInputSingleParams({ tokenIn: _tokenIn, tokenOut: swapThrough, fee: 10000, recipient: address(this), amountIn: IUSDT(_tokenIn).balanceOf(address(this)), amountOutMinimum: 0, sqrtPriceLimitX96: 0}));
                    }
                }
            }
            if (_tokenOut != swapThrough) {
                IUSDT(swapThrough).approve(address(router), max);
                router.exactInputSingle(ISwapRouter.ExactInputSingleParams({tokenIn: swapThrough, tokenOut: _tokenOut, fee: _feeTier,recipient: address(this), amountIn: IUSDT(swapThrough).balanceOf(address(this)), amountOutMinimum: 0, sqrtPriceLimitX96: 0}));
            }
        }
    }

    function deposit(uint256 amount) external nonReentrant {
        require(!disabled);
        require(amount > 0);
        require(USDH.balanceOf(msg.sender) >= amount, "Insufficient Balance");
        require(USDH.allowance(msg.sender, address(this)) >= amount, "Insufficient Allowance");
        uint256 balance = USDH.balanceOf(address(this));
        USDH.transferFrom(msg.sender, address(this), amount);
        require(USDH.balanceOf(address(this)) == balance + amount, "Transfer Failed");

        USDH.approve(usdh, amount);
        address[] memory _withdrawnCollateral = Usdh.redeem(amount);

        for (uint256 i = 0; i < _withdrawnCollateral.length; i++) {
            if (_withdrawnCollateral[i] == address(0)) break;
            if (_withdrawnCollateral[i] != Strategy.token()) _swap(_withdrawnCollateral[i], Strategy.tokenDeposit(), Strategy.feeTier());
        }

        Strategy.deposit(IERC20(Strategy.tokenDeposit()).balanceOf(address(this)));

        _totalSupply = _totalSupply + amount;
        _balances[address(this)] = _balances[address(this)] + amount;
        emit Transfer(address(0), address(this), amount);
        _transferFrom(address(this), msg.sender, amount);
    }

    function withdraw(uint256 amount) external nonReentrant returns (uint256) {
        require(!disabled);
        require(amount > 0);
        require(_balances[msg.sender] >= amount, "Insufficent Balance");
        require(_allowances[msg.sender][address(this)] >= amount, "Insufficient Allowance");
        uint256 balance = balanceOf(address(this));
        _transferFrom(msg.sender, address(this), amount);
        require(balanceOf(address(this)) == balance + amount, "Transfer Failed");

        uint256 withdrawn = Strategy.withdraw(amount);

        _totalSupply = _totalSupply - withdrawn;
        _balances[address(this)] = _balances[address(this)] - withdrawn;
        emit Transfer(address(this), address(0), withdrawn);
        USDH.transfer(msg.sender, withdrawn);
        return withdrawn;
    }

    function claim() external nonReentrant {
        require(!disabled);
        rewards.claimUSDH(msg.sender);
    }

    function checkStrategy() external view returns (address) {
        return strategy;
    }

    function checkRewardExempt(address staker) external view returns (bool) {
        return rewardExempt[staker];
    }

    function getHoarderRewardsAddress() external view returns (address) {
        return address(rewards);
    }

    function getDisabled() external view returns (bool) {
        return disabled;
    }

    function getCanDisable() external view returns (bool) {
        return canDisable;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != max) {
            require(_allowances[sender][msg.sender] >= amount, "Insufficient allowance");
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) private returns (bool) {
        require(_balances[sender] >= amount, "Insufficient balance");
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;

        if (!rewardExempt[sender]) rewards.setBalance(sender, _balances[sender]);
        if (!rewardExempt[recipient]) rewards.setBalance(recipient, _balances[recipient]);

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function rescue(address token) external onlyGovernance {
        if (token == 0x0000000000000000000000000000000000000000) {
            payable(msg.sender).call{value: address(this).balance}("");
        } else {
            require(token != address(this) && token != usdh);
            IERC20 Token = IERC20(token);
            Token.transfer(msg.sender, Token.balanceOf(address(this)));
        }
    }

    function setStrategy(address strategyNew) external nonReentrant onlyGovernance {
        IHoarderStrategy _Strategy = IHoarderStrategy(strategyNew);
        IUSDT(_Strategy.tokenDeposit()).approve(strategyNew, type(uint256).max);
        if (strategy != address(0)) {
            Strategy.end();
            address tokenDeposit = Strategy.tokenDeposit();
            Strategy = _Strategy;
            IUSDT(tokenDeposit).approve(strategyNew, type(uint256).max);
            Strategy.init(tokenDeposit, IERC20(tokenDeposit).balanceOf(address(this)));
        } else {
            Strategy = _Strategy;
            Strategy.init(Strategy.tokenDeposit(), 0);
        }
        strategy = strategyNew;
        rewardExempt[strategy] = true;
    }

    function setSwapThrough(address _newSwapThrough) external nonReentrant onlyGovernance {
        swapThrough = _newSwapThrough;
    }

    function disable() external nonReentrant onlyGovernance {
        require(!disabled && canDisable);
        Strategy.end();
        if (USDH.balanceOf(address(this)) > 0) USDH.transfer(msg.sender, USDH.balanceOf(address(this)));
        if (IERC20(Strategy.tokenDeposit()).balanceOf(address(this)) > 0) IERC20(Strategy.tokenDeposit()).transfer(msg.sender, IERC20(Strategy.tokenDeposit()).balanceOf(address(this)));
        disabled = true;
    }

    function renounce() external nonReentrant onlyGovernance {
        require(!disabled && canDisable);
        canDisable = false;
    }

    function setGovernance(address _newGovernanceContract) external nonReentrant onlyGovernance {
        governance = _newGovernanceContract;
    }

    receive() external payable {}
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

import "./interfaces/IHoarderRewards.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IhUSDH.sol";
import "./interfaces/IUSDH.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract HoarderRewards is IHoarderRewards, ReentrancyGuard {
    struct Share {
        uint256 amount;
        uint256 uncounted;
        uint256 counted;
    }

    mapping (address => uint256) hoarderClaims;

    mapping (address => uint256) public totalRewardsToHoarder;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalRewards;
    uint256 public totalDistributed;
    uint256 public rewardsPerShare;
    uint256 public constant decimals = 10 ** 36;

    IhUSDH public immutable hoarder;
    IUSDH public immutable usdh;
    IERC20 public immutable Usdh;

    address public governance;

    modifier onlyHoarder {
        require(msg.sender == hoarder.checkStrategy() || msg.sender == address(hoarder));
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance);
        _;
    }

    constructor (address _usdh, address _governance) {
        hoarder = IhUSDH(msg.sender);
        usdh = IUSDH(_usdh);
        Usdh = IERC20(_usdh);
        governance = _governance;
    }

    function _getCumulativeUSDH(uint256 _share) private view returns (uint256) {
        return _share * rewardsPerShare / decimals;
    }

    function setBalance(address _hoarder, uint256 _amount) external override onlyHoarder {
        if (shares[_hoarder].amount > 0) _claimUSDH(_hoarder);
        totalShares = totalShares - shares[_hoarder].amount + _amount;
        shares[_hoarder].amount = _amount;
        shares[_hoarder].uncounted = _getCumulativeUSDH(shares[_hoarder].amount);
    }

    function _claimUSDH(address _hoarder) private {
        if (shares[_hoarder].amount == 0) return;
        uint256 _amount = getUnclaimedUSDH(_hoarder);
        if (_amount > 0) {
            hoarderClaims[_hoarder] = block.timestamp;
            shares[_hoarder].counted = shares[_hoarder].counted + _amount;
            shares[_hoarder].uncounted = _getCumulativeUSDH(shares[_hoarder].amount);
            Usdh.transfer(_hoarder, _amount);
            totalDistributed = totalDistributed + _amount;
            totalRewardsToHoarder[_hoarder] = totalRewardsToHoarder[_hoarder] + _amount;
        }
    }

    function claimUSDH(address _hoarder) external onlyHoarder {
        _claimUSDH(_hoarder);
    }

    function deposit(uint256 _amount) external override onlyHoarder {
        require(Usdh.balanceOf(msg.sender) >= _amount);
        require(Usdh.allowance(msg.sender, address(this)) >= _amount);
        uint256 balance = Usdh.balanceOf(address(this));
        Usdh.transferFrom(msg.sender, address(this), _amount);
        require(Usdh.balanceOf(address(this)) == balance + _amount);
        totalRewards = totalRewards + _amount;
        rewardsPerShare = rewardsPerShare + (decimals * _amount / totalShares);
    }

    function getUnclaimedUSDH(address _hoarder) public view returns (uint256) {
        if (shares[_hoarder].amount == 0) return 0;
        uint256 _hoarderRewards = _getCumulativeUSDH(shares[_hoarder].amount);
        uint256 _hoarderUncounted = shares[_hoarder].uncounted;
        if (_hoarderRewards <= _hoarderUncounted) return 0;
        return _hoarderRewards - _hoarderUncounted;
    }

    function getClaimedRewardsTotal() external view returns (uint256) {
        return totalDistributed;
    }

    function getClaimedRewards(address _hoarder) external view returns (uint256) {
        return totalRewardsToHoarder[_hoarder];
    }

    function getLastClaim(address _hoarder) external view returns (uint256) {
        return hoarderClaims[_hoarder];
    }

    function rescue(address token) external onlyGovernance {
        if (token == 0x0000000000000000000000000000000000000000) {
            payable(msg.sender).call{value: address(this).balance}("");
        } else {
            require(token != address(usdh));
            IERC20 Token = IERC20(token);
            Token.transfer(msg.sender, Token.balanceOf(address(this)));
        }
    }

    function setGovernance(address _newGovernanceContract) external nonReentrant onlyGovernance {
        governance = _newGovernanceContract;
    }

    receive() external payable {}
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

interface IHoarderRewards {
    function setBalance(address shareholder, uint256 amount) external;
    function deposit(uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface IhUSDH {
    function checkStrategy() external returns (address);
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