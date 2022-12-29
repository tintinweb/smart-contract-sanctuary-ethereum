/**
 *Submitted for verification at Etherscan.io on 2022-12-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

contract Izanami {

    address private _owner;

    string private _name = "Izanami";
    string private _symbol = "IZANAMI";
    uint8 private _decimals = 9;

    uint private _totalSupply = 1000000 * 10 ** _decimals;

    uint256 public _maxTxAmount =  (_totalSupply * 20) / 1000;     //2%
    uint256 public _walletMax = (_totalSupply * 20) / 1000;    //2%

    bool public EnableTxLimit = true;
    bool public checkWalletLimit = true;

    mapping (address => bool) public isWalletLimitExempt;
    mapping (address => bool) public isTxLimitExempt;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;  
    
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {

        IUniswapV2Router _uniswapV2Router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 

        address uniswapPair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        _allowances[address(this)][address(_uniswapV2Router)] = ~uint256(0);

        _owner = msg.sender;
        
        isWalletLimitExempt[msg.sender] = true;
        isWalletLimitExempt[address(this)] = true;
        isWalletLimitExempt[address(uniswapPair)] = true;
        
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[address(this)] = true;

        _balances[msg.sender] = _totalSupply;

        emit OwnershipTransferred(address(0), msg.sender);
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

     function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if(!isTxLimitExempt[from] && !isTxLimitExempt[to] && EnableTxLimit) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        _balances[from] = fromBalance - amount;

        if(checkWalletLimit && !isWalletLimitExempt[to]) {
            require(balanceOf(to) + amount <= _walletMax,"Max Wallet Limit Exceeded!!");
        }

        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }
    
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
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

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function totalCirculationSupply() public view returns (uint256) {
        return _totalSupply - _balances[DEAD] - _balances[ZERO];
    }

    function contractOwner() public view returns (address) {
        return _owner;
    } 

    function renouncedOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function ExcludeWalletLimit(address _adr,bool _status) public onlyOwner {
        require(isWalletLimitExempt[_adr] != _status,"Not Changed!!");
        isWalletLimitExempt[_adr] = _status;
    }

    function ExcludeTxLimit(address _adr,bool _status) public onlyOwner {
        require(isTxLimitExempt[_adr] != _status,"Not Changed!!");
        isTxLimitExempt[_adr] = _status;
    }

    function setMaxWalletLimit(uint256 newLimit) external onlyOwner {
        _walletMax = newLimit;
    }

    function setTxLimit(uint256 newLimit) external onlyOwner {
        _maxTxAmount = newLimit;
    }

}