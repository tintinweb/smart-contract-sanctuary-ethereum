//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SomeToken is IERC20 {
    // token data
    string constant _name = "Token420";
    string constant _symbol = "T420";
    uint8 constant _decimals = 9;
    // 1 Trillion Max Supply
    uint256 _totalSupply = 1 * 10**12 * (10**_decimals);
    uint256 public _maxTxAmount = _totalSupply / 100; // 1% or 10 Billion
    // balances
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    // exemptions
    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isTxLimitExempt;
    // fees
    uint256 public burnFee = 150;
    uint256 public reflectionFee = 150;
    uint256 public marketingFeeSell = 300;
    uint256 public marketingFeeBuy = 400;
    uint256 public liquidityFee = 300;
    uint256 public teamFee = 100;
    // total fees
    uint256 totalFeeSells = 1000;
    uint256 totalFeeBuys = 500;
    uint256 feeDenominator = 10000;

    //fee trackers
    address marketingAddress = 0xdeF3914eFf4194944Cef65744c68B8B4D1e0A57F;
    address teamAddress = 0x358192e4A600B07376532938f0EC8a379E088e11;
    uint256 tokenLiquidityStored;
    // Marketing Funds Receiver

    // minimum bnb needed for distribution
    uint256 public minimumToDistribute = 1 * 10**16; //0.01 eth
    // Pancakeswap V2 Router
    IUniswapV2Router02 router;
    address public pair;

    bool public allowTransferToMarketing = true;
    // gas for distributor

    // in charge of swapping
    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 30; // 3,33% = 33,33 Billion
    uint256 public burnTreshold = _totalSupply / 300;
    bool public swapThresholdMet = swapThreshold <= _balances[address(this)]; //temp
    // true if our threshold decreases with circulating supply
    bool public canChangeSwapThreshold = false;
    uint256 public swapThresholdPercentOfCirculatingSupply = 300;
    bool inSwap;
    // false to stop the burn
    bool burnEnabled = true;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }
    // Uniswap Router V2
    address private _dexRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    // initialize some stuff
    constructor() {
        // Pancakeswap V2 Router
        router = IUniswapV2Router02(_dexRouter);
        // Liquidity Pool Address for BNB -> Vault
        pair = IUniswapV2Factory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        _allowances[address(this)][address(router)] = _totalSupply;
        // our dividend Distributor
        // exempt deployer and contract from fees

        // approve router of total supply
        approve(_dexRouter, _totalSupply);
        approve(address(pair), _totalSupply);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function internalApprove() private {
        _allowances[address(this)][address(router)] = _totalSupply;
        _allowances[address(this)][address(pair)] = _totalSupply;
    }

    /** Approve Total Supply */
    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    /** Transfer Function */
    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transferFrom(msg.sender, recipient, amount);
    }

    /** Transfer Function */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != _totalSupply) {
            _allowances[sender][msg.sender] -= amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    /** Internal Transfer */
    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        // make standard checks
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        // check if we have reached the transaction limit
        require(
            amount <= _maxTxAmount || isTxLimitExempt[sender],
            "TX Limit Exceeded"
        );
        // whether transfer succeeded
        bool success;
        // amount of tokens received by recipient
        uint256 amountReceived;
        // if we're in swap perform a basic transfer
        if (inSwap) {
            (amountReceived, success) = handleTransferBody(
                sender,
                recipient,
                amount
            );
            emit Transfer(sender, recipient, amountReceived);
            return success;
        }

        // limit gas consumption by splitting up operations
        if (shouldSwapBack()) {
            swapBack();
            (amountReceived, success) = handleTransferBody(
                sender,
                recipient,
                amount
            );
        } else {
            (amountReceived, success) = handleTransferBody(
                sender,
                recipient,
                amount
            );
        }

        emit Transfer(sender, recipient, amountReceived);
        return success;
    }

    /** Takes Associated Fees and sets holders' new Share for the Safemoon Distributor */
    function handleTransferBody(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256, bool) {
        // subtract balance from sender
        _balances[sender] -= amount;
        // amount receiver should receive
        uint256 amountReceived = shouldTakeFee(sender)
            ? takeFee(recipient, amount)
            : amount;
        // add amount to recipient
        _balances[recipient] += amountReceived;
        // set shares for distributors
        // return the amount received by receiver
        return (amountReceived, true);
    }

    /** False if sender is Fee Exempt, True if not */
    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    /** Takes Proper Fee (8% buys / transfers, 20% on sells) and stores in contract */
    function takeFee(address receiver, uint256 amount)
        internal
        returns (uint256)
    {
        uint256 feeAmount = getTotalFee(receiver == pair);
        if (feeAmount == totalFeeSells) {
            _balances[address(this)] +=
                ((totalFeeSells * 6) / 10) /
                feeDenominator;
            _balances[marketingAddress] +=
                amount *
                (marketingFeeSell / feeDenominator);
            _balances[teamAddress] += amount * (teamFee / feeDenominator);
        } else if (feeAmount == totalFeeBuys) {
            _balances[teamAddress] += amount * (teamFee / feeDenominator);
            _balances[marketingAddress] +=
                amount *
                (marketingFeeBuy / feeDenominator);
        }

        feeAmount = amount * (getTotalFee(receiver == pair) / feeDenominator);
        return amount - feeAmount;
    }

    /** True if we should swap from ERC20 => BNB */
    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != pair &&
            !inSwap &&
            swapEnabled &&
            _balances[address(this)] >= swapThreshold;
    }

    /**
     *  Swaps SafeAffinity for BNB if threshold is reached and the swap is enabled
     *  Burns 20% of SafeAffinity in Contract
     *  Swaps The Rest For BNB
     */
    function swapBack() private swapping {
        //half of the liquidity taxes get swapped for the native token on your network, the other half is added in the form of this contract's token
        // tokens allocated to reflections (1.5% tax on sell/25% total contract balance) + nativeLiquidity (another 25% contract balance)
        uint256 swapAmount = _balances[address(this)] / 4;
        //tokens automatically allocated to the liquidity pool (3%tax on sell/50% total contract balance)
        // tokens allocated to burning (1.5% tax on sell/25% total contract balance)
        uint256 burnAmount = _balances[address(this)] / 2;
        burnTokens(burnAmount);
        emit Burn(burnAmount);

        // path from token -> BNB
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        try
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                swapAmount,
                0,
                path,
                address(this),
                block.timestamp
            )
        {} catch {
            return;
        }
        addLiquidity(_balances[address(this)], address(this).balance);
        // Tell The Blockchain
    }

    function getTotalFee(bool selling) public view returns (uint256) {
        if (selling) {
            return totalFeeSells;
        }
        return totalFeeBuys;
    }

    function burnTokens(uint256 tokenAmount) private returns (bool) {
        if (!burnEnabled) {
            return false;
        }
        // update balance of contract
        _balances[address(this)] -= tokenAmount;
        // update Total Supply
        _totalSupply -= tokenAmount;
        // approve Router for total supply
        internalApprove();
        // change Swap Threshold if we should
        if (canChangeSwapThreshold) {
            swapThreshold =
                _totalSupply /
                swapThresholdPercentOfCirculatingSupply;
        }
        // emit Transfer to Blockchain
        emit Transfer(address(this), address(0), tokenAmount);
        return true;
    }

    function addLiquidity(uint256 tokens, uint256 native) public {
        _approve(address(this), address(router), tokens);
        router.addLiquidityETH{value: native}(
            address(this),
            tokens,
            0, // slippage unavoidable
            0, // slippage unavoidable
            pair,
            block.timestamp
        );
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    event Burn(uint256 amountBurnt);
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity ^0.8.0;

import './IUniswapV2Router01.sol';

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