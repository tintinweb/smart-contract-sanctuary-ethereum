/**
 *Submitted for verification at Etherscan.io on 2022-12-24
*/

pragma solidity ^0.8.0;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router {
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

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
}

contract ERC20_TOKEN {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFeeAndMaxTxAndMaxWallet;
    mapping(address => bool) private _isAutomatedMarketMaker;

    address private _owner;

    address public devWallet;
    address public uniswapV2Pair;
    IUniswapV2Router public uniswapV2Router;

    uint256 private _totalSupply;

    uint256 public buyLiquidityFee;
    uint256 public buyDevFee;
    uint256 public buyTotalFees;
    uint256 public sellLiquidityFee;
    uint256 public sellDevFee;
    uint256 public sellTotalFees;
    uint256 public maxTx;
    uint256 public maxWallet;
    uint256 public liquidityFeeTokens;
    uint256 public devFeeTokens;

    uint8 private _decimals = 9;

    string private _name;
    string private _symbol;

    modifier onlyOwner() {
        require(_owner == msg.sender);
        _;
    }

    event Approval(
        address indexed from,
        address indexed spender,
        uint256 indexed amount
    );
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed amount
    );

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        address owner_,
        uint256 initialMaxTx,
        uint256 initialMaxWallet,
        uint256 initialBuyLiquidityFee,
        uint256 initialBuyDevFee,
        uint256 initialSellLiquidityFee,
        uint256 initialSellDevFee
    ) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_;
        _balances[owner_] = totalSupply_;
        _owner = owner_;
        devWallet = owner_;
        maxTx = initialMaxTx;
        maxWallet = initialMaxWallet;
        require(initialBuyLiquidityFee + initialBuyDevFee <= 10);
        buyLiquidityFee = initialBuyLiquidityFee;
        buyDevFee = initialBuyDevFee;
        require(initialSellLiquidityFee + initialSellDevFee <= 10);
        sellLiquidityFee = initialSellLiquidityFee;
        sellDevFee = initialSellDevFee;
        uniswapV2Router = IUniswapV2Router(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        address uniswapV2Factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Factory).createPair(
            0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6,
            address(this)
        );
        _isAutomatedMarketMaker[uniswapV2Pair] = true;
        _isExcludedFromFeeAndMaxTxAndMaxWallet[msg.sender] = true;
        _isExcludedFromFeeAndMaxTxAndMaxWallet[address(uniswapV2Router)] = true;
    }

    receive() external payable {}

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function balanceOf(address _address) public view returns (uint256) {
        return _balances[_address];
    }

    function allowance(address from, address to) public view returns (uint256) {
        return _allowances[from][to];
    }

    function isAutomatedMarketMaker(address _address)
        public
        view
        returns (bool)
    {
        return _isAutomatedMarketMaker[_address];
    }

    function isExcludedFromFeeAndMaxTxAndMaxWallet(address _address)
        public
        view
        returns (bool)
    {
        return _isExcludedFromFeeAndMaxTxAndMaxWallet[_address];
    }

    function renounceOwnership() external onlyOwner {
        _owner = address(0);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        _owner = newOwner;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(
        address from,
        address spender,
        uint256 amount
    ) internal {
        _allowances[from][spender] = amount;
        emit Approval(from, spender, amount);
    }

    function decreaseAllowance(address spender, uint256 amount) external {
        _allowances[msg.sender][spender] -= amount;
        uint256 newAmount = _allowances[msg.sender][spender];
        emit Approval(msg.sender, spender, newAmount);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        _allowances[msg.sender][from] -= amount;
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(_balances[from] >= amount);
        uint256 fee;
        if (
            !_isExcludedFromFeeAndMaxTxAndMaxWallet[from] &&
            !_isExcludedFromFeeAndMaxTxAndMaxWallet[to]
        ) {
            require(amount <= maxTx);
            if (_isAutomatedMarketMaker[from]) {
                devFeeTokens += (amount / 100) * buyDevFee;
                liquidityFeeTokens += (amount / 100) * buyLiquidityFee;
                fee = buyTotalFees;
                require(
                    _balances[to] + amount - (amount / 100) * fee <= maxWallet
                );
            }
            if (_isAutomatedMarketMaker[to]) {
                devFeeTokens += (amount / 100) * sellDevFee;
                liquidityFeeTokens += (amount / 100) * sellLiquidityFee;
                fee = sellTotalFees;
                if (_balances[address(this)] >= _totalSupply / 5000) {
                    contractBalanceRealization;
                }
            }
        }
        uint256 feeAmount = (amount / 100) * fee;
        uint256 finalAmount = amount - feeAmount;
        _balances[from] -= amount;
        _balances[address(this)] += feeAmount;
        _balances[to] += finalAmount;
        emit Transfer(from, address(this), feeAmount);
        emit Transfer(from, to, finalAmount);
    }

    function contractBalanceRealization() internal {
        uint256 contractBalance = address(this).balance;
        uint256 halfOfLiquidityFeeTokens = liquidityFeeTokens / 2;
        uint256 tokensToSwap = devFeeTokens + liquidityFeeTokens / 2;
        swapTokensForETH(tokensToSwap);
        uint256 newContractBalance = address(this).balance - contractBalance;
        uint256 devETHFee = (newContractBalance * devFeeTokens) / tokensToSwap;
        devWallet.call{value: devETHFee}("");
        uint256 liquidityETHFee = newContractBalance - devETHFee;
        devFeeTokens = 0;
        liquidityFeeTokens = 0;
        if (halfOfLiquidityFeeTokens > 0 && liquidityETHFee > 0) {
            addLiquidity(halfOfLiquidityFeeTokens, liquidityETHFee);
        }
    }

    function swapTokensForETH(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETH(
            tokenAmount,
            uint256(1),
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) internal {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            _owner,
            block.timestamp
        );
    }

    function contractBalanceRealizationAndUpdateBuyFees(
        uint256 _buyLiquidityFee,
        uint256 _buyDevFee
    ) external onlyOwner {
        require(_buyLiquidityFee + _buyDevFee >= 10);
        contractBalanceRealization();
        buyLiquidityFee = _buyLiquidityFee;
        buyDevFee = _buyDevFee;
        buyTotalFees = _buyLiquidityFee + _buyDevFee;
    }

    function contractBalanceRealizationAndUpdateSellFees(
        uint256 _sellLiquidityFee,
        uint256 _sellDevFee
    ) external onlyOwner {
        require(_sellLiquidityFee + _sellDevFee >= 10);
        contractBalanceRealization();
        sellLiquidityFee = _sellLiquidityFee;
        sellDevFee = _sellDevFee;
        sellTotalFees = _sellLiquidityFee + _sellDevFee;
    }

    function setMaxTx(uint256 newMaxTx) external onlyOwner {
        require(newMaxTx >= _totalSupply / 500);
        maxTx = newMaxTx;
    }

    function setMaxWallet(uint256 newMaxWallet) external onlyOwner {
        require(newMaxWallet >= _totalSupply / 500);
        maxWallet = newMaxWallet;
    }

    function updateDevWallet(address newDevWallet) external onlyOwner {
        devWallet = newDevWallet;
    }

    function setIsAutomatedMarketMaker(address _address, bool value)
        external
        onlyOwner
    {
        _isAutomatedMarketMaker[_address] = value;
    }
}