/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from,address to,uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IFactory{
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
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
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}

library Address{
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

contract ERC20Standard_Taxed is Context, IERC20, IERC20Metadata,Ownable {
    using Address for address payable;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public _isExcludedFromFees;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    address public treasuryWallet;
    uint8 public buyTax;
    uint8 public sellTax;

    IRouter public router;
    address public pair;
    
    uint256 public swapTokensAmount;
    bool private _swapping;

    modifier lockTheSwap {
        _swapping = true;
        _;
        _swapping = false;
    }

    event TreasuryPaid(address receiver);

    constructor(
    uint256 totalSupply_, string memory name_, string memory symbol_,uint8 decimals_, 
    address treasuryWallet_,uint8 buyTax_,uint8 sellTax_,address routerAddress_) 
    {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply += totalSupply_ * (10**_decimals);
        buyTax = buyTax_;
        sellTax = sellTax_;
        treasuryWallet = treasuryWallet_;
        swapTokensAmount = _totalSupply * 5 / 1000;  //0.05% of the total supply

        IRouter _router = IRouter(routerAddress_);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router;
        pair = _pair;
        _approve(address(this), address(router), ~uint256(0));

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[treasuryWallet_] = true;

        _balances[owner()] += _totalSupply;
        emit Transfer(address(0),owner(), _totalSupply);
    }

    function name() external view virtual override returns (string memory) {
        return _name;
    }

    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() external view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) external virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(address from,address to,uint256 amount) external virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address from,address to,uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        if(_balances[address(this)] >= swapTokensAmount && !_swapping && from != pair)
            _swapAndLiquify();

        _balances[from] = fromBalance - amount;

        uint256 fAmount = amount;
        if(!_isExcludedFromFees[from] && !_isExcludedFromFees[to]){
           fAmount = _getTaxes(amount, from, to == pair);
        }

        _balances[to] += fAmount;
        emit Transfer(from, to, fAmount);
    }

    function _approve(address owner,address spender,uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner,address spender,uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _getTaxes(uint256 amount,address from,bool isSell) private returns(uint256){
        uint8 tmpTax = buyTax;
        if(isSell)
            tmpTax = sellTax;

        uint256 taxAmount = amount * tmpTax / 100;
        _balances[address(this)] += taxAmount;
        emit Transfer(from, address(this), taxAmount);
        return amount - taxAmount;
    }

    function _swapAndLiquify() private lockTheSwap{
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(swapTokensAmount, 0, path, treasuryWallet, block.timestamp);
        emit TreasuryPaid(treasuryWallet);
    }

    
    //safe functions for emegency purposes

    //exclude CEX or any important contract
    function setIsExcludedFromFee(address account, bool isExcluded) external onlyOwner{
        _isExcludedFromFees[account] = isExcluded;
    }
    //rescue ETH that might have been accidentally sent to the contract
    function rescueETH(uint256 weiAmount) external onlyOwner{
        require(address(this).balance >= weiAmount, "Insufficient Balance");
        payable(msg.sender).transfer(weiAmount);
    }
    //rescue any ERC20 tokens that might have been accidentally send to the contract
    function rescueAnyERC20Tokens(address tokenAddress, address to, uint amountExact, uint decimals_) external onlyOwner {
        IERC20(tokenAddress).transfer(to, amountExact *10**decimals_);
    }
    
    receive() external payable{
    }

}