/**
 *Submitted for verification at Etherscan.io on 2022-12-21
*/

//SPDX-License-Identifier: MIT

/**
▄▄▄▄· ▄• ▄▌▪  ▄▄▌  ·▄▄▄▄      ▄▄▄▄▄ ▄ .▄▄▄▄ .    ▄▄▄▄· ▄▄▄ . ▄▄▄· ▄▄▄
▐█ ▀█▪█▪██▌██ ██•  ██▪ ██     •██  ██▪▐█▀▄.▀·    ▐█ ▀█▪▀▄.▀·▐█ ▀█ ▀▄ █·
▐█▀▀█▄█▌▐█▌▐█·██▪  ▐█· ▐█▌     ▐█.▪██▀▐█▐▀▀▪▄    ▐█▀▀█▄▐▀▀▪▄▄█▀▀█ ▐▀▀▄
██▄▪▐█▐█▄█▌▐█▌▐█▌▐▌██. ██      ▐█▌·██▌▐▀▐█▄▄▌    ██▄▪▐█▐█▄▄▌▐█ ▪▐▌▐█•█▌
·▀▀▀▀  ▀▀▀ ▀▀▀.▀▀▀ ▀▀▀▀▀•      ▀▀▀ ▀▀▀ · ▀▀▀     ·▀▀▀▀  ▀▀▀  ▀  ▀ .▀  ▀
           -... ..- .. .-.. -..    - .... .    -... . .- .-.

buildthebear.market, buildthebear.online
t.me/buildthebear, twitter.com/buildingthebear
*/

pragma solidity ^0.8.17;

/* - INTERFACES - */

// Uniswap V2 Factory
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;

    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);
}

// Uniswap V2 Pair
interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
    function kLast() external view returns (uint256);
    function mint(address to) external returns (uint256 liquidity);
    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}

// Uniswap V1 Router
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
        uint256 deadline)
    external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

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

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountOut);
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountIn);
    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
}

// Uniswap V2 Router
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

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// ERC-20
interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// ERC-20 Metadata
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
}


/* - CONTRACTS - */

// ERC-20
contract ERC20 is IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    string private contractName;
    string private contractSymbol;

    uint8 private constant DECIMALS = 9;
    uint256 private constant SUPPLY = 1000000 gwei;

    constructor(string memory n, string memory s) {
        contractName = n;
        contractSymbol = s;

        _balances[msg.sender] = SUPPLY;

        emit Transfer(address(0), msg.sender, SUPPLY);
    }

    function symbol() external view virtual override returns (string memory) { return contractSymbol; }
    function name() external view virtual override returns (string memory) { return contractName; }
    function balanceOf(address account) public view virtual override returns (uint256) { return _balances[account]; }
    function decimals() public pure virtual override returns (uint8) { return DECIMALS; }
    function totalSupply() external view virtual override returns (uint256) { return SUPPLY; }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        address owner = msg.sender;

        uint256 currentAllowance = allowance(owner, spender);

        require(currentAllowance >= subtractedValue, "Allowance cannot be less than zero");

        unchecked { _approve(owner, spender, currentAllowance - subtractedValue); }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        address owner = msg.sender;

        _approve(owner, spender, allowance(owner, spender) + addedValue);

        return true;
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);

        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "Insufficient allowance");

            unchecked { _approve(owner, spender, currentAllowance - amount); }
        }
    }

    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        address owner = msg.sender;

        _approve(owner, spender, amount);

        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "Cannot approve from the zero address");
        require(spender != address(0), "Cannot approve to the zero address");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function transfer(address to, uint256 amount) external virtual override returns (bool) {
        _transfer(msg.sender, to, amount);

        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        unchecked {
            _balances[from] -= amount;
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) external virtual override returns (bool) {
        address spender = msg.sender;

        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);

        return true;
    }
}

// ʕ •ᴥ•ʔ Build the Bear, Bring the Bull
contract BuildtheBear is ERC20 {
    IUniswapV2Router02 public immutable uniswapV2Router;

    address public owner;
    address public immutable uniswapV2Pair;

    mapping(address => bool) private isExcludedFromFee;

    // 99% tax at launch to prevent snipers, gradually lowered to 4%
    uint8 public preLaunchFee = 99;
    uint8 public swapInFee = preLaunchFee;
    uint8 public swapOutFee = preLaunchFee;
    uint256 public maximumHold = 10000 gwei;
    // Thresholds that trigger liquidity additions and contract swaps
    uint256 public thresholdForLiquidityAdd = 2000 gwei;
    uint256 public amountForLiquidityAdd = 500 gwei;
    uint256 public thresholdForETHSwap = 3000 gwei;
    uint256 public amountForETHSwap = 500 gwei;

    bool contractSwapping;

    event ContractSwappedTokens(uint256 tokensSwapped);

    modifier contractSwap() { contractSwapping = true; _; contractSwapping = false; }
    modifier onlyOwner() { require(msg.sender == owner, "Function can only be called by the contract owner"); _; }

    // Create the contract and Uniswap pair (BTB/WETH), exclude router, contract, and owner from swap fees
    constructor() ERC20("Build the Bear", "BTB") {
        owner = msg.sender;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;

        isExcludedFromFee[address(uniswapV2Router)] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[msg.sender] = true;

        _approve(address(this), address(uniswapV2Router), type(uint256).max);
    }

    // On transfer of BTB tokens
    function _transfer(address from, address to, uint256 amount) internal override {
        require(balanceOf(from) >= amount, "Transfer exceeds account balance");

        uint256 transferAmount;
        uint8 swapFee = swapOutFee;

        // Determine if transferring to or from liquidity pair, calculate fee & transferAmount
        if (from == uniswapV2Pair || to == uniswapV2Pair && !contractSwapping) {
            if (from != uniswapV2Pair) {
                uint256 contractTokenBalance = balanceOf(address(this));

                swapFee = swapInFee;

                // Determine if contract's token balance exceeds the threshold for swapping tokens
                if (contractTokenBalance >= thresholdForETHSwap) {
                    contractSwapTokens();
                } else if (contractTokenBalance >= thresholdForLiquidityAdd) {
                    // Or if contract's token balance exceeds the threshold for adding liquidity
                    super._transfer(address(this), uniswapV2Pair, amountForLiquidityAdd);
                }
            }

            if (isExcludedFromFee[from] || isExcludedFromFee[to]) {
                transferAmount = amount;
            } else {
                require(amount <= maximumHold, "Transfer exceeds maximum amount");

                if (from == uniswapV2Pair) {
                    require((amount + balanceOf(to)) <= maximumHold, "Transfer exceeds maximum hold");

                    swapFee = swapOutFee;
                }

                uint256 fee;

                unchecked {
                    swapFee > 0 ? fee = ((amount * swapFee) / 100) : fee = 0;
                    transferAmount = amount - fee;
                }

                if (fee > 0) { super._transfer(from, address(this), fee); }
            }

            super._transfer(from, to, transferAmount);
        } else {
            super._transfer(from, to, amount);
        }
    }

    // Swap a portion of the contract's token balance collected from marketing and development fees
    function contractSwapTokens() private contractSwap {
        address[] memory path = new address[](2);

        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        try uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountForETHSwap, 0, path, address(this), (block.timestamp + 300)) {
            emit ContractSwappedTokens(amountForETHSwap);
        } catch {}
    }

    function updateOwner(address newOwner) external onlyOwner {
        require (newOwner != address(0), "New owner cannot be the zero address");

        owner = newOwner;
    }

    function updateMaximumHold(uint256 newMaximumHold) external onlyOwner {
        require (newMaximumHold >= 10000 gwei && newMaximumHold <= 50000 gwei, "Maximum hold must be between 1% and 5%");

        maximumHold = newMaximumHold;
    }

    function updateSwapFees(uint8 newSwapInFee, uint8 newSwapOutFee) external onlyOwner {
        require (newSwapInFee <= 25 && newSwapOutFee <= 25, "Fees cannot exceed 25%");

        swapInFee = newSwapInFee;
        swapOutFee = newSwapOutFee;
    }

    function updateContractLiquidityAdd(uint256 newThresholdForLiquidityAdd, uint256 newAmountForLiquidityAdd) external onlyOwner {
        require ((newThresholdForLiquidityAdd >= 500 gwei && newThresholdForLiquidityAdd <= 20000 gwei) &&
            newAmountForLiquidityAdd <= 10000 gwei, "newThresholdForLiquidityAdd must be between 0.05% and 2% supply");
        require (newThresholdForLiquidityAdd >= (newAmountForLiquidityAdd * 2), "newThresholdForLiquidityAdd must be at least 2x greater than newAmountForLiquidityAdd");

        thresholdForLiquidityAdd = newThresholdForLiquidityAdd;
        amountForLiquidityAdd = newAmountForLiquidityAdd;
    }

    function updateContractETHSwap(uint256 newThresholdForETHSwap, uint256 newAmountForETHSwap) external onlyOwner {
        require ((newThresholdForETHSwap > thresholdForLiquidityAdd) && newAmountForETHSwap <= 10000 gwei, "newAmountForETHSwap must be 1% supply or less");
        require (newThresholdForETHSwap >= (newAmountForETHSwap * 2), "newThresholdForETHSwap must be at least 2x greater than newAmountForETHSwap");

        thresholdForETHSwap = newThresholdForETHSwap;
        amountForETHSwap = newAmountForETHSwap;
    }

    // Allow owner to claim misdirected tokens
    function claimEther() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function claimContractTokens() external onlyOwner {
        _transfer(address(this), owner, balanceOf(address(this)));
    }

    receive() external payable {}
}

/** 01000010 01110101 01101001 01101100 01100100  01110100 01101000 01100101  01000010 01100101 01100001 01110010 */