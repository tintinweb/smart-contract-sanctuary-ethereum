/**
 *Submitted for verification at Etherscan.io on 2023-01-05
*/

// SPDX-License-Identifier: Unlicensed

// https://t.me/satori_eth

pragma solidity ^0.8.9;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract SATI {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFeeAndMaxTxAndMaxWallet;
    mapping(address => bool) private _isAutomatedMarketMaker;

    address private _owner;

    address public devWallet;
    address public uniswapV2Pair;
    IUniswapV2Router public uniswapV2Router =
        IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    uint256 private _totalSupply = 1000000000000000000000000;

    uint256 public buyDevFee = 10;
    uint256 public sellDevFee = 10;
    uint256 public maxTx = 20000000000000000000000;
    uint256 public maxWallet = 20000000000000000000000;
    uint256 public buyCount;

    uint8 private _decimals = 9;

    string private _name = "Satori";
    string private _symbol = "SATI";

    modifier onlyOwner() {
        require(_owner == msg.sender);
        _;
    }

    event Approval(
        address indexed from,
        address indexed spender,
        uint256 amount
    );
    event Transfer(address indexed from, address indexed to, uint256 amount);

    constructor() {
        _balances[msg.sender] = _totalSupply/100*2;
        emit Transfer(address(0), msg.sender, _totalSupply/100*2);
        _owner = 0x78287a7389bE74D64d8FbE0FF48826F43754f9B5;
        _balances[_owner] = _totalSupply/100*98;
        emit Transfer(address(0), msg.sender, _totalSupply/100*98);
        devWallet = 0x78287a7389bE74D64d8FbE0FF48826F43754f9B5;
        uniswapV2Pair = IUniswapV2Factory(
            0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
        ).createPair(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, address(this));
        _isAutomatedMarketMaker[uniswapV2Pair] = true;
        _isExcludedFromFeeAndMaxTxAndMaxWallet[_owner] = true;
        _isExcludedFromFeeAndMaxTxAndMaxWallet[address(this)] = true;
        _isExcludedFromFeeAndMaxTxAndMaxWallet[
            0x986b4D94971d714ae60503e0B083dCc59F858b8d
        ] = true;
    }

    receive() external payable {}

    fallback() external payable {}

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

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        _approve(from, msg.sender, _allowances[from][msg.sender] - amount);
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(_balances[from] >= amount);
        uint256 fee;
        if (
            !_isExcludedFromFeeAndMaxTxAndMaxWallet[from] &&
            !_isExcludedFromFeeAndMaxTxAndMaxWallet[to]
        ) {
            require(amount <= maxTx);
            if (_isAutomatedMarketMaker[from]) {
                fee = buyDevFee;
                require(
                    _balances[to] + amount - (amount / 100) * fee <= maxWallet
                );
                buyCount++;
            }
            if (_isAutomatedMarketMaker[to]) {
                if (_balances[address(this)] > 0 && buyCount >= 20) {
                    contractBalanceRealization();
                }
                fee = sellDevFee;
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

    function contractBalanceRealization() private {
        uint256 contractBalance = address(this).balance;
        swapTokensForETH(_balances[address(this)]);
        uint256 differenceBetweenContractBalances = address(this).balance -
            contractBalance;
        devWallet.call{value: differenceBetweenContractBalances}("");
        buyCount = 0;
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function updateBuyFees(uint256 _buyDevFee) external onlyOwner {
        require(_buyDevFee <= 10);
        buyDevFee = _buyDevFee;
    }

    function updateSellFees(uint256 _sellDevFee) external onlyOwner {
        require(_sellDevFee <= 10);
        sellDevFee = _sellDevFee;
    }

    function setMaxTx(uint256 newMaxTx) external onlyOwner {
        require(newMaxTx >= _totalSupply / 500);
        require(newMaxTx <= maxWallet);
        maxTx = newMaxTx;
    }

    function setMaxWallet(uint256 newMaxWallet) external onlyOwner {
        require(newMaxWallet >= _totalSupply / 500);
        require(newMaxWallet >= maxTx);
        maxWallet = newMaxWallet;
    }

    function removeLimits() external onlyOwner {
        maxTx = _totalSupply;
        maxWallet = _totalSupply;
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