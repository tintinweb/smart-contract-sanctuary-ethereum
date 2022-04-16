/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

/**

888 88e       e Y8b     Y88b Y88   e88'Y88    e88 88e   
888 888b     d8b Y8b     Y88b Y8  d888  'Y   d888 888b  
888 8888D   d888b Y8b   b Y88b Y C8888 eeee C8888 8888D 
888 888P   d888888888b  8b Y88b   Y888 888P  Y888 888P  
888 88"   d8888888b Y8b 88b Y88b   "88 88"    "88 88"   

DANGO - a delicious ERC20 memecoin

https://t.me/DANGOerc

https://dangotoken.com
                                                        
* TOKENOMICS
 * 1,000,000,000,000 token supply
 * FIRST TWO MINUTES: 5,000,000,000 max buy / 30-second buy cooldown (lifted automatically two minutes post-launch)
 * 15-second cooldown to sell after a buy
 * 9% tax on buys and 11% tax on sells
 * 16% fee on sells within first (1) hour post-launch
 * 10% of fee ETH sent to pair, increasing paired value without creating new LP tokens
 * Max wallet of 3% of total supply (can be disabled after stabilization)
 * No team tokens, no presale

SPDX-License-Identifier: UNLICENSED 
*/
pragma solidity ^0.8.13;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}  

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Pair {
    event Sync(uint112 reserve0, uint112 reserve1);
    function sync() external;
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
}

contract DANGO is Context, IERC20, Ownable { ////
    mapping (address => uint) private _owned;
    mapping (address => mapping (address => uint)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => User) private cooldown;
    uint private constant _totalSupply = 1e12 * 10**9;

    string public constant name = unicode"Dango"; ////
    string public constant symbol = unicode"DANGO"; ////
    uint8 public constant decimals = 9;

    IUniswapV2Router02 private uniswapV2Router;
    IUniswapV2Pair private interfacePair;

    address payable public _FeeAddress1;
    address payable public _FeeAddress2;
    address public uniswapV2Pair;
    uint public _buyFee = 9;
    uint public _sellFee = 11;
    uint private _lpAddAmt = 10;
    uint public _maxBuyAmount;
    uint public _maxHeldTokens;
    uint public _launchedAt;
    bool public _maxHeldLimit;
    bool public _tradingOpen;
    bool private _inSwap;

    struct User {
        uint buy;
        bool exists;
    }

    event FeesUpdated(uint _buy, uint _sell);
    event LpAddAmtUpdated(uint _percent);
    event maxHeldLimitSwitched(bool toggle);
    event FeeAddress1Updated(address _feewallet1);
    event FeeAddress2Updated(address _feewallet2);
    
    modifier lockTheSwap {
        _inSwap = true;
        _;
        _inSwap = false;
    }
    constructor (address payable FeeAddress1, address payable FeeAddress2) {
        _FeeAddress1 = FeeAddress1;
        _FeeAddress2 = FeeAddress2;
        _owned[address(this)] = _totalSupply;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[FeeAddress1] = true;
        _isExcludedFromFee[FeeAddress2] = true;
        emit Transfer(address(0), address(this), _totalSupply);
    }

    function balanceOf(address account) public view override returns (uint) {
        return _owned[account];
    }

    function transfer(address recipient, uint amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function totalSupply() public pure override returns (uint) {
        return _totalSupply;
    }

    function allowance(address owner, address spender) public view override returns (uint) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public override returns (bool) {
        if(_tradingOpen && !_isExcludedFromFee[recipient] && sender == uniswapV2Pair){
            require (recipient == tx.origin, "pls no bot");
        }
        _transfer(sender, recipient, amount);
        uint allowedAmount = _allowances[sender][_msgSender()] - amount;
        _approve(sender, _msgSender(), allowedAmount);
        return true;
    }

    function _approve(address owner, address spender, uint amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        bool isBuy = false;
        if(from != owner() && to != owner()) {
            // buy
            if(from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) {
                require(_tradingOpen, "Trading not yet enabled.");
                require(block.timestamp != _launchedAt, "pls no snip");
                if(_maxHeldLimit) {
                    require((amount + balanceOf(address(to))) <= _maxHeldTokens, "Max held limit."); //// 3%
                }
                if(!cooldown[to].exists) {
                    cooldown[to] = User(0,true);
                }
                if((_launchedAt + (120 seconds)) > block.timestamp) {
                    require(amount <= _maxBuyAmount, "Exceeds maximum buy amount.");
                    require(cooldown[to].buy < block.timestamp + (30 seconds), "Cooldown hasn't expired.");
                }
                cooldown[to].buy = block.timestamp;
                isBuy = true;
            }
            // sell
            if(!_inSwap && _tradingOpen && from != uniswapV2Pair) {
                require(cooldown[from].buy < block.timestamp + (15 seconds), "Cooldown hasn't expired.");
                uint contractTokenBalance = balanceOf(address(this));
                if(contractTokenBalance > 0) {
                    swapTokensForEth(contractTokenBalance);
                }
                uint contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(contractETHBalance);
                }
                isBuy = false;
            }
        }
        bool takeFee = true;
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        _tokenTransfer(from,to,amount,takeFee,isBuy);
    }

    function swapTokensForEth(uint tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
        
    function sendETHToFee(uint amount) private {
            uint fee1;
            uint fee2;
        if(_lpAddAmt > 0) {
            uint pool = (amount * _lpAddAmt) / 100; //// 10% WETH sent to LP
            IWETH(uniswapV2Router.WETH()).deposit{value: pool}();
            IWETH(uniswapV2Router.WETH()).transfer(uniswapV2Pair, IERC20(uniswapV2Router.WETH()).balanceOf(address(this)));

            uint remainder = amount - pool;
            fee1 = remainder / 2;
            fee2 = remainder - fee1;

            _FeeAddress1.transfer(fee1);
            _FeeAddress2.transfer(fee2);
            
            interfacePair.sync();
        } else {
            fee1 = amount / 2;
            fee2 = amount - fee1;
            _FeeAddress1.transfer(fee1);
            _FeeAddress2.transfer(fee2);
        }
    }
    
    function _tokenTransfer(address sender, address recipient, uint amount, bool takefee, bool buy) private {
        (uint fee) = _getFee(takefee, buy);
        _transferStandard(sender, recipient, amount, fee);
    }

    function _getFee(bool takefee, bool buy) private view returns (uint) {
        uint fee = 0;
        if(takefee) {
            if(buy) {
                fee = _buyFee;
            } else {
                fee = _sellFee;
                if(block.timestamp < _launchedAt + (1 hours)) {
                    fee += 5;
                }
            }
        }
        return fee;
    }

    function _transferStandard(address sender, address recipient, uint amount, uint fee) private {
        (uint transferAmount, uint team) = _getValues(amount, fee);
        _owned[sender] = _owned[sender] - amount;
        _owned[recipient] = _owned[recipient] + transferAmount; 
        _takeTeam(team);
        emit Transfer(sender, recipient, transferAmount);
    }

    function _getValues(uint amount, uint teamFee) private pure returns (uint, uint) {
        uint team = (amount * teamFee) / 100;
        uint transferAmount = amount - team;
        return (transferAmount, team);
    }

    function _takeTeam(uint team) private {
        _owned[address(this)] = _owned[address(this)] + team;
    }

    receive() external payable {}
    
    // external functions
    function addLiquidity() external onlyOwner() {
        require(!_tradingOpen, "Trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _totalSupply);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
        interfacePair = pair;
    }

    function openTrading() external onlyOwner() {
        require(!_tradingOpen, "Trading is already open");
        _maxHeldLimit = true;
        _tradingOpen = true;
        _launchedAt = block.timestamp;
        _maxBuyAmount = 5000000001 * 10**9; //// .5%
        _maxHeldTokens = 30000000000 * 10**9; //// 3%
    }

    function manualswap() external {
        require(_msgSender() == _FeeAddress1);
        uint contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }
    
    function manualsend() external {
        require(_msgSender() == _FeeAddress1);
        uint contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function setFees(uint buy, uint sell) external {
        require(_msgSender() == _FeeAddress1);
        require(buy <= 11 && sell <= 11, "Don't be greedy.");
        _buyFee = buy;
        _sellFee = sell;
        emit FeesUpdated(_buyFee, _sellFee);
    }

    function setLpAddAmt(uint percent) external {
        require(_msgSender() == _FeeAddress1);
        require(percent <= 100);
        _lpAddAmt = percent; // the percent of fee ETH sent to LP, can be any value (has no effect on tax)
        emit LpAddAmtUpdated(percent);
    }

    function toggleMaxHeldLimit() external {
        require(_msgSender() == _FeeAddress1);
        _maxHeldLimit = !_maxHeldLimit;
        emit maxHeldLimitSwitched(_maxHeldLimit);
    }

    function updateFeeAddress1(address newAddress) external {
        require(_msgSender() == _FeeAddress1);
        _FeeAddress1 = payable(newAddress);
        emit FeeAddress1Updated(_FeeAddress1);
    }

    function updateFeeAddress2(address newAddress) external {
        require(_msgSender() == _FeeAddress2);
        _FeeAddress2 = payable(newAddress);
        emit FeeAddress2Updated(_FeeAddress2);
    }
}