/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

// SPDX-License-Identifier: MIT

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

// Context
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

// Ownable
contract Ownable is Context {
    address public owner;

    constructor() { owner = msg.sender;  }

    modifier onlyOwner() { require(msg.sender == owner, "Function can only be called by the contract owner"); _; }

    function setOwner(address newOwner) external onlyOwner { owner = newOwner; }
}

// ERC-20
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory contractName, string memory contractSymbol) {
        _name = contractName;
        _symbol = contractSymbol;
    }

    function symbol() external view virtual override returns (string memory) { return _symbol; }
    function name() external view virtual override returns (string memory) { return _name; }
    function balanceOf(address account) public view virtual override returns (uint256) { return _balances[account]; }
    function decimals() public view virtual override returns (uint8) { return 9; }
    function totalSupply() external view virtual override returns (uint256) { return _totalSupply; }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function transfer(address to, uint256 amount) external virtual override returns (bool) {
        address owner = _msgSender();

        _transfer(owner, to, amount);

        return true;
    }

    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        address owner = _msgSender();

        _approve(owner, spender, amount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external virtual override returns (bool) {
        address spender = _msgSender();

        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);

        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        address owner = _msgSender();

        uint256 currentAllowance = allowance(owner, spender);

        require(currentAllowance >= subtractedValue, "Allowance cannot be less than zero");

        unchecked { _approve(owner, spender, currentAllowance - subtractedValue); }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        address owner = _msgSender();

        _approve(owner, spender, allowance(owner, spender) + addedValue);

        return true;
    }

    function createInitialSupply(address account, uint256 amount) internal virtual {
        require(account != address(0), "Cannot mint to the zero address");

        _totalSupply += amount;

        unchecked { _balances[account] += amount; }

        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "Cannot approve from the zero address");
        require(spender != address(0), "Cannot approve to the zero address");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);

        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "Insufficient allowance");

            unchecked { _approve(owner, spender, currentAllowance - amount); }
        }
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "Cannot transfer from the zero address");
        require(to != address(0), "Cannot transfer to the zero address");
        require(_balances[from] >= amount, "Transfer exceeds account balance");

        unchecked {
            _balances[from] -= amount;

            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }
}

// BBBB
contract BBBB is ERC20, Ownable {
    string private _name = "BBBB";
    string private _symbol = "BBBB";

    uint8 private _decimals = 9;
    uint256 private _supply = 1000000 * 10 ** _decimals;
    uint256 private contractThresholdForLiquidity = 5000 * 10 ** _decimals;
    uint256 private contractThresholdForETH = 1000 * 10 ** _decimals;

    uint8 public liquidityFee = 0;
    uint8 public developmentFee = 3;
    uint256 public maximumHold = 10000 * 10 ** _decimals;

    IUniswapV2Router02 public immutable uniswapV2Router;

    address public immutable uniswapV2Pair;

    uint256 private contractBalance = 0;

    mapping(address => bool) private isExcludedFromFee;

    bool inContractLiquify;

    event contractLiquification(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);

    modifier lockTheSwap() { inContractLiquify = true; _; inContractLiquify = false; }

    // Create the contract and Uniswap pair (BBBB/WETH), exclude router and owner from fees
    constructor() ERC20(_name, _symbol) {
        createInitialSupply(msg.sender, (_supply));

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;

        isExcludedFromFee[address(uniswapV2Router)] = true;
        isExcludedFromFee[msg.sender] = true;
    }

    // On transfer of BBBB tokens
    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "Cannot transfer from the zero address");
        require(to != address(0), "Cannot transfer to the zero address");
        require(balanceOf(from) >= amount, "Transfer exceeds account balance");

        // Regular swap
        if ((from == uniswapV2Pair || to == uniswapV2Pair) && !inContractLiquify) {
            // Determine if contract tokens should be swapped
            if (from != uniswapV2Pair) {
                uint256 contractLiquidityBalance = balanceOf(address(this));

                if (contractLiquidityBalance >= contractThresholdForLiquidity) {
                    contractLiquify(contractThresholdForLiquidity);
                }

                if (contractBalance >= contractThresholdForETH) {
                    contractSwapTokensForEth(contractThresholdForETH);
                    contractBalance -= contractThresholdForETH;

                    bool sent = payable(owner).send(address(this).balance);

                    require(sent, "Failed to send ETH");
                }
            }

            uint256 transferAmount;

            // Determine if participants are excluded from swap fees or not
            if (isExcludedFromFee[from] || isExcludedFromFee[to]) {
                transferAmount = amount;
            } else {
                require(amount <= maximumHold, "Transfer exceeds maximum hold");

                if (from == uniswapV2Pair) {
                    require((amount + balanceOf(to)) <= maximumHold, "Transfer exceeds maximum hold");
                }

                uint256 devFee = ((amount * developmentFee) / 100);
                uint256 liqFee = ((amount * liquidityFee) / 100);

                transferAmount = amount - (devFee + liqFee);
                contractBalance += devFee;

                super._transfer(from, address(this), (devFee + liqFee));
            }

            super._transfer(from, to, transferAmount);
        } else {
            super._transfer(from, to, amount);
        }
    }

    // Contract will swap and liquify BBBB collected from fees when the threshold is met
    function contractLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 half = (contractTokenBalance / 2);
        uint256 otherHalf = (contractTokenBalance - half);
        uint256 initialBalance = address(this).balance;

        contractSwapTokensForEth(half);

        uint256 newBalance = (address(this).balance - initialBalance);

        contractAddLiquidity(otherHalf, newBalance);

        emit contractLiquification(half, newBalance, otherHalf);
    }

    function contractSwapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);

        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), (block.timestamp + 300));
    }

    function contractAddLiquidity(uint256 tokenAmount, uint256 ethAmount) private lockTheSwap {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value : ethAmount}(address(this), tokenAmount, 0, 0, owner, block.timestamp);
    }

    // Update contract variables
    function updateFees(uint8 newLiquidityFee, uint8 newDevelopmentFee) public onlyOwner {
        liquidityFee = newLiquidityFee;
        developmentFee = newDevelopmentFee;
    }

    function updateMaximumHold(uint256 newMaximumHold) public onlyOwner {
        maximumHold = newMaximumHold;
    }

    function changeSwapThresholds(uint256 newContractThresholdForLiquidity, uint256 newContractThresholdForETH) public onlyOwner {
        contractThresholdForLiquidity = newContractThresholdForLiquidity;
        contractThresholdForETH = newContractThresholdForETH;
    }

    // Allow owner to claim misdirected Ξ
    function claimEther() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {}
}