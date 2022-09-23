// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "v3-periphery/interfaces/IQuoter.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/IERC20Decimals.sol";
import "./interfaces/IERC20Old.sol";

contract USDH is IERC20, ReentrancyGuard {
    uint256 internal constant max256 = type(uint256).max;

    string private constant _name = "Hoard Dollar";
    string private constant _symbol = "USDH";
    uint8 private constant _decimals = 18;

    uint256 public _totalSupply;

    mapping (address => bool) public wasCollateral;
    mapping (address => bool) public collateralWhitelist;
    mapping (address => address) public collateralPairings;
    mapping (address => uint256) public collateralPairingsDecimals;
    mapping (address => uint24) public collateralFeeTiers;

    uint256 public constant minimumCollateralPriceMin = 990;
    uint256 public constant minimumCollateralPriceMax = 1005;
    uint256 public minimumCollateralPrice = 990;

    address[] public collateralTypes;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    IQuoter private constant quoter = IQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);
    ISwapRouter private constant router = ISwapRouter(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);

    address public governance;

    event Mint(address indexed _from, address indexed _collateral, uint256 _amount);
    event Redeem(address indexed _from, address[] indexed _collateral, uint256 _amount);

    modifier onlyGovernance() {
        require(msg.sender == governance);
        _;
    }

    constructor() {
        governance = msg.sender;
        _balances[address(this)] = 0;
        emit Transfer(address(0), address(this), 0);
    }

    function mint(address _collateral, uint256 _amount, bool _exactOutput) external nonReentrant {
        require(collateralWhitelist[_collateral]);
        require(_amount > 0);

        uint256 _quote = quoter.quoteExactInputSingle(_collateral, collateralPairings[_collateral], collateralFeeTiers[_collateral], 10 ** 18, 0);
        require(_quote >= minimumCollateralPrice * (10 ** collateralPairingsDecimals[_collateral]), "Peg Unstable");
        uint256 _peg = (1000 * (10 ** collateralPairingsDecimals[_collateral]));
        if (_peg > _quote) _amount = _exactOutput ? (_amount * ((_peg * (10 ** 18)) / _quote)) / (10 ** 18) : (_amount * (10 ** 18)) / ((_peg * (10 ** 18)) / _quote);

        IERC20 _Collateral = IERC20(_collateral);
        require(_Collateral.balanceOf(msg.sender) >= _amount);
        require(_Collateral.allowance(msg.sender, address(this)) >= _amount);
        uint256 _balance = _Collateral.balanceOf(address(this));
        require(_Collateral.transferFrom(msg.sender, address(this), _amount), "TF");
        require(_Collateral.balanceOf(address(this)) >= _balance + _amount, "TF");

        uint256 _newSupply = _totalSupply + _amount;
        require(_newSupply > _totalSupply);
        _totalSupply = _newSupply;
        _balances[msg.sender] = _balances[msg.sender] + _amount;
        emit Transfer(address(0), msg.sender, _amount);
        emit Mint(msg.sender, _collateral, _amount);
    }

    function redeem(uint256 _amount) external nonReentrant returns (address[] memory) {
        require(_amount > 0);
        require(_balances[msg.sender] >= _amount && _totalSupply >= _amount);
        _balances[msg.sender] = _balances[msg.sender] - _amount;
        emit Transfer(msg.sender, address(0), _amount);
        _totalSupply = _totalSupply - _amount;

        address[] memory _collateralTypes = new address[](9);

        uint256 _amountStablecoin = _amount;
        uint256 _amountStablecoinPaid;
        uint256 _i;
        while (_amountStablecoin > _amountStablecoinPaid) {
            (address _largestCollateral, uint256 _largestBalance) = getLargestBalance();
            uint256 _amountStablecoinRemaining = _amountStablecoin - _amountStablecoinPaid;
            uint256 _amountCollateral = _amountStablecoinRemaining > _largestBalance ? _largestBalance : _amountStablecoinRemaining;
            try IERC20(_largestCollateral).transfer(msg.sender, _amountCollateral) {} catch {}
            _amountStablecoinPaid = _amountStablecoinPaid + _amountCollateral;
            if (_i < 9) {
                _collateralTypes[_i] = _largestCollateral;
                _i = _i + 1;
            }
        }

        emit Redeem(msg.sender, _collateralTypes, _amount);
        return _collateralTypes;
    }

    function getLargestBalance() public view returns (address, uint256) {
        address _largestCollateral;
        uint256 _largestBalance;

        uint256 collateralTypesNum = collateralTypes.length;

        for (uint256 _i = 0; _i < collateralTypesNum; _i++) {
            address _collateral = collateralTypes[_i];
            uint256 _balance = IERC20(_collateral).balanceOf(address(this));
            if (_balance > _largestBalance) {
                _largestCollateral = _collateral;
                _largestBalance = _balance;
            }
        }

        return (_largestCollateral, _largestBalance);
    }

    function getCollateral(address _collateral) external view returns (bool, uint256, address, uint256, uint24) {
        return (collateralWhitelist[_collateral], IERC20(_collateral).balanceOf(address(this)), collateralPairings[_collateral], collateralPairingsDecimals[_collateral], collateralFeeTiers[_collateral]);
    }

    function getCollateralPrice(address _collateral) external returns (uint256) {
        return collateralPairings[_collateral] != address(0) ? quoter.quoteExactInputSingle(_collateral, collateralPairings[_collateral], collateralFeeTiers[_collateral], 10 ** 18, 0) : 0;
    }

    function getMintCost(address _collateral, uint256 _amount, bool _exactOutput) public returns (uint256, bool) {
        uint256 _quote = quoter.quoteExactInputSingle(_collateral, collateralPairings[_collateral], collateralFeeTiers[_collateral], 10 ** 18, 0);
        uint256 _peg = (1000 * (10 ** collateralPairingsDecimals[_collateral]));
        if (_peg > _quote) _amount = _exactOutput ? (_amount * ((_peg * (10 ** 18)) / _quote)) / (10 ** 18) : (_amount * (10 ** 18)) / ((_peg * (10 ** 18)) / _quote);
        return (_amount, _quote >= minimumCollateralPrice * (10 ** collateralPairingsDecimals[_collateral]));
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

    function owner() external view returns (address) {
        return governance;
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
        return approve(spender, max256);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != max256) {
            require(_allowances[sender][msg.sender] >= amount, "Insufficient allowance");
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(_balances[sender] >= amount, "Insufficient balance");
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function rescue(address token) external onlyGovernance {
        if (token == 0x0000000000000000000000000000000000000000) {
            payable(msg.sender).call{value: address(this).balance}("");
        } else {
            require(!wasCollateral[token], "Can't withdraw collateral");
            IERC20 Token = IERC20(token);
            Token.transfer(msg.sender, Token.balanceOf(address(this)));
        }
    }

    function whitelistCollateral(address _newCollateral, address _quotePairing, uint24 _quoteFeeTier) external nonReentrant onlyGovernance {
        require(_quoteFeeTier == 100 || _quoteFeeTier == 500 || _quoteFeeTier == 3000 || _quoteFeeTier == 10000);
        require(IERC20Decimals(_newCollateral).decimals() == 18);
        uint256 _pairingDecimals = IERC20Decimals(_quotePairing).decimals();
        require(_pairingDecimals > 3);
        collateralWhitelist[_newCollateral] = true;
        collateralPairings[_newCollateral] = _quotePairing;
        collateralPairingsDecimals[_newCollateral] = _pairingDecimals - 3;
        collateralFeeTiers[_newCollateral] = _quoteFeeTier;
        if (!wasCollateral[_newCollateral]) {
            collateralTypes.push(_newCollateral);
            wasCollateral[_newCollateral] = true;
        }
    }

    function blacklistCollateral(address _oldCollateral, address _newCollateral, bool _liquidateOldCollateral, uint24 _feeTier, address _tokenSwapThrough, uint24 _feeTierSwapThrough) external nonReentrant onlyGovernance {
        collateralWhitelist[_oldCollateral] = false;
        if (_liquidateOldCollateral) {
            if (collateralWhitelist[_oldCollateral]) {
                if (IERC20(_oldCollateral).balanceOf(address(this)) > 0) {
                    require((_feeTier == 100 || _feeTier == 500 || _feeTier == 3000 || _feeTier == 10000));
                    if (_tokenSwapThrough != address(0)) {
                        require(_feeTierSwapThrough == 100 || _feeTierSwapThrough == 500 || _feeTierSwapThrough == 3000 || _feeTierSwapThrough == 10000);
                        IERC20Old(_oldCollateral).approve(address(router), max256);
                        router.exactInputSingle(ISwapRouter.ExactInputSingleParams({tokenIn: _oldCollateral, tokenOut: _tokenSwapThrough, fee: _feeTierSwapThrough, recipient: address(this), amountIn: IERC20(_oldCollateral).balanceOf(address(this)), amountOutMinimum: 0, sqrtPriceLimitX96: 0}));
                        _oldCollateral = _tokenSwapThrough;
                    }
                    IERC20Old(_oldCollateral).approve(address(router), max256);
                    router.exactInputSingle(ISwapRouter.ExactInputSingleParams({tokenIn: _oldCollateral, tokenOut: _newCollateral, fee: _feeTier, recipient: address(this), amountIn: IERC20(_oldCollateral).balanceOf(address(this)), amountOutMinimum: 0, sqrtPriceLimitX96: 0}));
                }
            }
        }
    }

    function setMinimumCollateralPrice(uint256 _newMinimumCollateralPrice) external nonReentrant onlyGovernance {
        require(_newMinimumCollateralPrice >= minimumCollateralPriceMin && _newMinimumCollateralPrice <= minimumCollateralPriceMax);
        minimumCollateralPrice = _newMinimumCollateralPrice;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountIn The desired input amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountOut The desired output amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
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

interface IERC20Decimals {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface IERC20Old {
    function approve(address spender, uint256 amount) external;
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