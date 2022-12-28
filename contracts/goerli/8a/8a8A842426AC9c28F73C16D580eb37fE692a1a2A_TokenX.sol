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

pragma solidity ^0.8.10;

interface IMasterPool {
    struct AuctionInfo {
        uint256 auctionAmount;
        uint256 stakeDuration;
        bool claimed;
    }

    struct StakingPool {
        address staker;
        uint256 stakeAmount;
        uint256 stakeDuration;
        uint256 stakeTimestamp;
        bool claimed;
    }

    struct PendingRewards {
        uint256 claimableRewards;
        uint256 stakableRewards;
        uint256 dividendsRewards;
    }

    struct UserInfo {
        uint256 dividendsRewards;
        uint256 totalBidAmount;
        mapping(uint256 => uint256) bidAmountPerAuction;
        mapping(uint256 => uint256) stakeDuration;
        uint256 totalStakedAmount;
    }

    struct StakingHistory {
        uint256 stakingId;
        uint256 stakeAmount;
        uint256 leftDuration;
        uint256 totalDuration;
        bool finished;
    }

    struct AuctionHistory {
        uint256 auctionId;
        uint256 tokenXPool;
        uint256 totalBUSDDividens;
        uint256 totalBidAmount;
        uint256 bidAmount;
        uint256 stakeDuration;
        uint256 participantsCnt;
        uint256 auctionPrice;
        bool claimed;
        bool finished;
    }

    event Auction(address indexed user, uint256 amount, uint256 stakeDuration);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITokenX is IERC20 {
    function mint(
        address account_,
        uint256 amount_
    ) external;

    function burn(uint256 amount_) external;

    function leftDays() external view returns (uint256);

    function launchedAt() external view returns (uint256);
    
    function supplyAmount(uint256 auctionId) external pure returns (uint256);

    function getLiquidAmount() external view returns (uint256);

    function getLiquidAmount(address user_) external view returns (uint256);
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.10;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./interfaces/ITokenX.sol";
import "./interfaces/IMasterPool.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Factory.sol";

contract TokenX is ITokenX {
    uint256 public launchedAt;

    uint256 private _totalSupply;
    uint256 private constant INITIAL_SUPPLY_AMOUNT = 10**7 * 1e18;
    uint256 private constant INITIAL_TAX_FEE = 50; // 50%
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    IUniswapV2Router02 private router;
    IERC20 private BUSD;
    address private poolAddress;
    address private owner;
    address private pair;
    address constant deadWallet = 0x000000000000000000000000000000000000dEaD;

    string private constant _name = "tokenX";
    string private constant _symbol = "TOKENX";
    uint8 private constant _decimals = 18;

    modifier onlyPoolOwner() {
        require(
            msg.sender == poolAddress || msg.sender == owner,
            "no permission"
        );
        _;
    }

    constructor(
        address routerAddress_,
        address poolAddress_,
        address pairTokenAddress_
    ) {
        BUSD = IERC20(pairTokenAddress_);
        poolAddress = poolAddress_;
        router = IUniswapV2Router02(routerAddress_);
        pair = IUniswapV2Factory(router.factory()).createPair(
            address(BUSD),
            address(this)
        );
        launchedAt = block.timestamp;
        owner = msg.sender;
        _balances[owner] = INITIAL_SUPPLY_AMOUNT;
        _totalSupply= INITIAL_SUPPLY_AMOUNT;
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account_)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account_];
    }

    function transfer(address to_, uint256 amount_)
        external
        override
        returns (bool)
    {
        address owner_ = msg.sender;
        _transfer(owner_, to_, amount_);
        return true;
    }

    function allowance(address owner_, address spender_)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner_][spender_];
    }

    function approve(address spender_, uint256 amount_)
        external
        override
        returns (bool)
    {
        address owner_ = msg.sender;
        _approve(owner_, spender_, amount_);
        return true;
    }

    function transferFrom(
        address from_,
        address to_,
        uint256 amount_
    ) external override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from_, spender, amount_);
        _transfer(from_, to_, amount_);
        return true;
    }

    function mint(address account_, uint256 amount_) external onlyPoolOwner {
        _balances[account_] += amount_;
        _totalSupply += amount_;
    }

    function burn(uint256 amount_) external override onlyPoolOwner {
        _transfer(msg.sender, deadWallet, amount_);
    }

    function getLiquidAmount() external view override returns (uint256) {
        return _balances[pair];
    }

    function getLiquidAmount(address user_)
        external
        view
        override
        returns (uint256)
    {
        require(user_ != address(0), "zero address");
        uint256 userAmount = IERC20(pair).balanceOf(user_);
        uint256 totalAmount = IERC20(pair).totalSupply();
        uint256 totalTokenX = _balances[pair];
        return totalAmount == 0 ? 0 : (totalTokenX * userAmount) / totalAmount;
    }

    function leftDays() external view override returns (uint256) {
        uint256 current = block.timestamp;
        if (current <= launchedAt) {
            return 0;
        }

        return (current - launchedAt) / 30;
    }

    function supplyAmount(uint256 auctionId_)
        external
        pure
        override
        returns (uint256)
    {
        uint256 sAmount = INITIAL_SUPPLY_AMOUNT;
        for (uint256 i = 0; i < auctionId_; i++) {
            sAmount = sAmount * 9 / 10; 
        }
        return sAmount;
    }

    function _transfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal {
        require(from_ != address(0), "ERC20: transfer from the zero address");
        require(to_ != address(0), "ERC20: transfer to the zero address");
        require(amount_ > 0, "ERC20: invalid amount");

        uint256 fromBalance = _balances[from_];
        uint256 fee = 0;
        require(
            fromBalance >= amount_,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from_] = fromBalance - amount_;
        }

        if (to_ == pair) {
            fee = (amount_ * INITIAL_TAX_FEE) / 100;
        }

        amount_ -= fee;
        if (fee > 0) {
            _balances[address(this)] += fee;
        }
        _balances[to_] += amount_;

        emit Transfer(from_, to_, amount_);
    }

    function _spendAllowance(
        address owner_,
        address spender_,
        uint256 amount_
    ) internal virtual {
        uint256 currentAllowance = allowance(owner_, spender_);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount_,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner_, spender_, currentAllowance - amount_);
            }
        }
    }

    function _approve(
        address owner_,
        address spender_,
        uint256 amount_
    ) internal virtual {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender_ != address(0), "ERC20: approve to the zero address");

        _allowances[owner_][spender_] = amount_;
        emit Approval(owner_, spender_, amount_);
    }
}