/**
 *Submitted for verification at Etherscan.io on 2023-02-19
*/

/**
 *Submitted for verification at Etherscan.io on 2023-02-17

 https://t.me/HalfinchBoy
 https://halfinchboy.online/
 
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract Ownable is Context {
    address private _owner;
    
    address private _previousOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {

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
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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
contract IssunBoshi is Context, IERC20, Ownable {
 
    using SafeMath for uint256;
    mapping(address => uint256) private _sets;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply = 100000000000 * 10**9;
    mapping(address => uint256) private setCooldown;
    string private constant _name = "Issun-Boshi";
    string private constant _symbol = "Half Inch Boy";
    uint8 private constant _decimals = 9;
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private _isTrading;
    bool private inSwapandLiquidify = false;
    bool private swapAndLiquifyEnabled = false;
    bool private _isCooldownEnabled = false;
 
    uint256 private _maxTx = _totalSupply;
    uint256 private _maxWallet = _totalSupply;
    constructor() {
        _sets[_msgSender()] = _totalSupply;
   
        emit Transfer(address(0), _msgSender(), _totalSupply);
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
 
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
 
    function balanceOf(address account) public view override returns (uint256) {
        return _sets[account];
    }
 
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
 
    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }
 
    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }
 
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (from != owner() && to != owner()) {
            require(amount <= _maxTx, "Exceed max transaction amount");
            if (to == uniswapV2Pair && from != address(uniswapV2Router)) {
                _transferToken(from, to, amount);
            } else {
                uint256 currentBalanceAvailable = balanceOf(to);
                require(
                    currentBalanceAvailable + amount < _maxWallet,
                    "Exceed max wallet amount"
                );
                if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
                    if (_isCooldownEnabled) {
                        require(setCooldown[to] < block.timestamp);
                    }
                    setCooldown[to] = block.timestamp + (30 seconds);
                    _transferToken(from, to, amount);
                } else {
                    _transferToken(from, to, amount);
                }
            }
        } else {
           _transferToken(from, to, amount);
        }
    }
    function setTrading() external onlyOwner {
        require(!_isTrading, "trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router; 
        _approve(address(this), address(uniswapV2Router), _totalSupply);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        swapAndLiquifyEnabled = true;
        _isCooldownEnabled = true;
        _maxTx = 20000000* 10**9;
        _maxWallet = 20000000 * 10**9;
        _isTrading = true;
        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );
    }
    function _transferToken(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        _sets[sender] = _sets[sender].sub(amount);
        _sets[recipient] = _sets[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
     function updateMaxTX(uint256 _amt) public onlyOwner {
        _maxTx = _amt;
    }
     function updateMaxWallet(uint256 _amt) public onlyOwner {
        _maxWallet = _amt;
    }
    receive() external payable {}
}