/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

// SPDX-License-Identifier: MIT

// Socials

/*  

    Official Telegram Chat: 
    [Telegram Chat URL]

    Twitter:
    [Twitter URL]

*/

pragma solidity 0.8.0;

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
    event Burn(address indexed burner, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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

contract GHOST is Context, IERC20, Ownable {
    using SafeMath for uint256;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _bots;
    
    address payable private _taxWallet;
    uint256 private _firstBlock;
    uint256 private _initialBuyTax = 20;
    uint256 private _initialSellTax = 20;
    uint256 private _finalBuyTax = 3;
    uint256 private _finalSellTax = 3;
    uint256 private _reduceBuyTaxAt = 20;
    uint256 private _reduceSellTaxAt = 20;
    uint256 private _preventSwapBefore = 20;
    uint256 private _buyCount = 0;
    
    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 100000000000 * 10**_decimals;
    string private constant _name = unicode"GHOST COIN";
    string private constant _symbol = unicode"GHOST";
    uint256 public _maxTxAmount = 2000000000 * 10**_decimals;
    uint256 public _maxWalletSize = 2000000000 * 10**_decimals;
    uint256 public _taxSwapThreshold = 2000000000 * 10**_decimals;
    uint256 public _maxTaxSwap = 1000000000 * 10**_decimals;
    
    IUniswapV2Router02 private _uniswapV2Router;
    address private _uniswapV2Pair;
    bool private _tradingOpen;
    bool private _inSwap = true;
    bool private _swapEnabled = true;
    
    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    
    modifier lockTheSwap() {
        bool inSwap = _inSwap;
        _inSwap = true;
        _;
        _inSwap = inSwap;
    }
    
    constructor () {
        address msgSender = _msgSender();
        _taxWallet = payable(msgSender);
        _balances[msgSender] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;
        _tradingOpen = false; // Set tradingOpen to false initially
        emit Transfer(address(0), msgSender, _tTotal);
        emit OwnershipTransferred(address(0), msgSender);
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
    
    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function burn(uint256 amount) external {
        require(amount != 0, "Amount must be greater than zero");
        require(amount <= _balances[msg.sender], "Insufficient balance");
        _balances[msg.sender] -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount = 0;
        
        if (from != owner() && to != owner()) {
            require(!_bots[from] && !_bots[to]);
            taxAmount = amount.mul((_buyCount > _reduceBuyTaxAt) ? _finalBuyTax : _initialBuyTax).div(100);
            
            if (from == _uniswapV2Pair && to != address(_uniswapV2Router) && !_isExcludedFromFee[to]) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                
                if (_firstBlock + 1 > block.number) {
                    require(!isContract(to));
                }
                _buyCount++;
            }
            
            if (to != _uniswapV2Pair && !_isExcludedFromFee[to]) {
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
            }
            
            if (to == _uniswapV2Pair && from != address(this)) {
                // Check if the recipient is a bot
                if (_bots[to]) {
                    taxAmount = amount.mul(99).div(100); // Set 99% sell tax for bots
                } else {
                    taxAmount = amount.mul((_buyCount > _reduceSellTaxAt) ? _finalSellTax : _initialSellTax).div(100);
                }
            }
            
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!_inSwap && to == _uniswapV2Pair && _swapEnabled && contractTokenBalance > _taxSwapThreshold && _buyCount > _preventSwapBefore) {
                swapTokensForEth(min(amount, min(contractTokenBalance, _maxTaxSwap)));
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }
        
        if (taxAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(taxAmount);
            emit Transfer(from, address(this), taxAmount);
        }
        
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? b : a;
    }
    
    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    
    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();
        _approve(address(this), address(_uniswapV2Router), tokenAmount);
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    function removeLimits() external onlyOwner {
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
        emit MaxTxAmountUpdated(_tTotal);
    }
    
    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }
    
    function addBots(address[] memory bots_) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            _bots[bots_[i]] = true;
        }
    }
    
    function delBots(address[] memory notbot) public onlyOwner {
        for (uint i = 0; i < notbot.length; i++) {
            _bots[notbot[i]] = false;
        }
    }
    
    function isBot(address a) public view onlyOwner returns (bool) {
        return _bots[a];
    }
    
    address[] private _botAddresses;
    
    function addBot(address bot) external onlyOwner {
        _bots[bot] = true;
        _botAddresses.push(bot);
    }
    
    function getBotList() public view returns (address[] memory) {
        address[] memory botList = new address[](_botAddresses.length);
        uint256 botCount = 0;
        
        for (uint256 i = 0; i < _botAddresses.length; i++) {
            if (_bots[_botAddresses[i]]) {
                botList[botCount] = _botAddresses[i];
                botCount++;
            }
        }
        
        // Resize the botList array to remove any empty slots
        assembly {
            mstore(botList, botCount)
        }
        
        return botList;
    }
    
    function openTrading() external onlyOwner() {
        require(_tradingOpen == false, "Trading is already open"); // Require trading to be closed before opening it
        _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_uniswapV2Router), _tTotal);
        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        _uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this), balanceOf(address(this)), 0, 0, owner(), block.timestamp);
        IERC20(_uniswapV2Pair).approve(address(_uniswapV2Router), type(uint).max);
        _swapEnabled = true;
        _tradingOpen = true; // Set tradingOpen to true after everything is set up
        _firstBlock = block.number;
    }
    
    function _reduceBuyTax(uint256 _newBuyFee) external onlyOwner {
        require(_newBuyFee <= _initialBuyTax && _newBuyFee <= _finalBuyTax, "Invalid buy fee value");
        _finalBuyTax = _newBuyFee;
    }
    
    function reduceSellTax(uint256 _newSellFee) external onlyOwner {
        require(_newSellFee <= _initialSellTax && _newSellFee <= _finalSellTax, "Invalid sell fee value");
        _finalSellTax = _newSellFee;
    }
    
    function increaseBuyTax(uint256 _newBuyFee) external onlyOwner {
        require(_newBuyFee >= _initialBuyTax && _newBuyFee >= _finalBuyTax, "Invalid buy fee value");
        _finalBuyTax = _newBuyFee;
    }
    
    function increaseSellTax(uint256 _newSellFee) external onlyOwner {
        require(_newSellFee >= _initialSellTax && _newSellFee >= _finalSellTax, "Invalid sell fee value");
        _finalSellTax = _newSellFee;
    }
    
    function getBuyTax() public view returns (uint256) {
        return _finalBuyTax;
    }
    
    function getSellTax() public view returns (uint256) {
        return _finalSellTax;
    }
    
    receive() external payable {}
    
    function manualSwap() external {
        require(_msgSender() == _taxWallet);
        uint256 tokenBalance = balanceOf(address(this));
        if (tokenBalance > 0) {
            swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            sendETHToFee(ethBalance);
        }
    }
    
    function withdraw() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        bool success = true;
        (success, ) = payable(owner()).call{value: contractBalance}("");
        require(success, "Transfer failed");
    }
}